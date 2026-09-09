import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:yarisa_doctor/models/appointment_model.dart';

import 'package:yarisa_doctor/api/firestore_schema.dart';
import 'package:yarisa_doctor/constants/yarisa_widgets.dart';
import 'package:yarisa_doctor/models/personal_patients_model.dart';
import 'package:yarisa_doctor/screens/authentication/complete_profile.dart';
import 'package:yarisa_doctor/screens/authentication/doctor_verification_pending_screen.dart';
import 'package:yarisa_doctor/screens/authentication/welcome_screen.dart';
import 'package:yarisa_doctor/screens/main/base.dart';

import '../models/user_model.dart';

class AvailabilityDaySummary {
  const AvailabilityDaySummary({
    required this.date,
    required this.status,
    required this.slots,
  });

  final DateTime date;
  final bool status;
  final List<String> slots;

  String get dateKey => FirestoreSchema.dateKey(date);
  bool get hasOpenSlots => status && slots.isNotEmpty;
}

/// Outcome of publishing slots (additive merge).
class AvailabilityWriteResult {
  const AvailabilityWriteResult({
    required this.added,
    required this.skippedExisting,
    required this.skippedBooked,
  });

  final int added;
  final int skippedExisting;
  final int skippedBooked;
}

class SlotBookingInfo {
  const SlotBookingInfo({
    required this.booked,
    this.bookedBy,
    this.appointmentId,
  });

  final bool booked;
  final String? bookedBy;
  final String? appointmentId;
}

class SlotBookedException implements Exception {
  const SlotBookedException({
    required this.slotLabel,
    this.appointmentId,
    this.bookedBy,
  });

  final String slotLabel;
  final String? appointmentId;
  final String? bookedBy;

  @override
  String toString() =>
      'Slot "$slotLabel" is booked and cannot be removed from availability.';
}

/// One published slot for a day (open or booked).
class DoctorAvailabilitySlot {
  const DoctorAvailabilitySlot({
    required this.label,
    required this.open,
    required this.booked,
    this.bookedBy,
    this.appointmentId,
    this.patientName,
  });

  final String label;
  final bool open;
  final bool booked;
  final String? bookedBy;
  final String? appointmentId;
  final String? patientName;

  int get sortMinutes => slotLabelStartMinutes(label) ?? 24 * 60;
}

/// Start minutes from midnight for labels like `9:00 AM - 9:30 AM`.
int? slotLabelStartMinutes(String label) {
  final raw = label.split(RegExp(r'\s*[-–—]\s*')).first.trim().toUpperCase();
  final match = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$').firstMatch(raw);
  if (match == null) return null;
  var hour = int.tryParse(match.group(1)!);
  final minute = int.tryParse(match.group(2)!);
  if (hour == null || minute == null) return null;
  final mer = match.group(3);
  if (mer == 'PM' && hour < 12) hour += 12;
  if (mer == 'AM' && hour == 12) hour = 0;
  if (hour > 23 || minute > 59) return null;
  return hour * 60 + minute;
}

int compareSlotLabelsAscending(String a, String b) {
  final am = slotLabelStartMinutes(a) ?? 24 * 60;
  final bm = slotLabelStartMinutes(b) ?? 24 * 60;
  final c = am.compareTo(bm);
  if (c != 0) return c;
  return a.compareTo(b);
}

class ApiMethods extends ChangeNotifier {
  bool authenticating = false;
  bool loading = false;
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore db = FirebaseFirestore.instance;
  User? user;
  List<PersonalPatientsModel> mypatients = [];
  UserModel? userAccount;
  List<AppointmentModel> userAppointments = [];

  Future<void> checkAuthState(BuildContext context) async {
    if (auth.currentUser != null) {
      await openDoctorLanding(context);
    } else {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (route) => false);
    }
  }

  Future<void> openDoctorLanding(
    BuildContext context, {
    String? email,
    String? fullname,
  }) async {
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (route) => false,
      );
      return;
    }

    // Prefer server so a stale offline cache cannot send completed doctors
    // back to the "Tell us about you" onboarding flow.
    DocumentSnapshot<Map<String, dynamic>> profile;
    try {
      profile = await FirestoreSchema.doctorDoc(currentUser.uid).get(
        const GetOptions(source: Source.server),
      );
    } catch (e) {
      Logger().w(
        'Doctor profile server read failed for ${currentUser.uid}, '
        'falling back to cache: $e',
      );
      profile = await FirestoreSchema.doctorDoc(currentUser.uid).get();
    }

    final profileData = profile.data();
    if (profile.exists && profileData != null) {
      userAccount = UserModel.fromDocumentSnapshot(profile);
      notifyListeners();
    } else {
      Logger().w(
        'No Doctors/${currentUser.uid} document for landing '
        '(exists=${profile.exists}). Showing CompleteProfile.',
      );
    }

    final destination = _doctorLandingScreen(
      profileData,
      email: email ?? currentUser.email,
      fullname: fullname ?? currentUser.displayName,
    );

    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => destination),
      (route) => false,
    );
  }

  Widget _doctorLandingScreen(
    Map<String, dynamic>? profileData, {
    String? email,
    String? fullname,
  }) {
    if (profileData == null || !_doctorProfileComplete(profileData)) {
      return CompleteProfile(
        email: email,
        fullname: fullname,
      );
    }

    if (_asBool(profileData['isVerified']) == true) {
      return const BaseScreen();
    }

    return DoctorVerificationPendingScreen(initialProfileData: profileData);
  }

  bool _doctorProfileComplete(Map<String, dynamic> profileData) {
    if (_asBool(profileData['profileComplete']) == true) return true;
    if (profileData['onboardingStep']?.toString().trim() == 'complete') {
      return true;
    }
    if (_asBool(profileData['profileComplete']) == false) return false;

    // Fallback: career fields present (legacy docs without profileComplete).
    return _hasProfileValue(profileData['speciality']) &&
        _hasProfileValue(profileData['licenseCode']) &&
        _hasProfileValue(profileData['clinic']);
  }

  bool _hasProfileValue(dynamic value) {
    final text = value?.toString().trim();
    return text != null && text.isNotEmpty && text.toLowerCase() != 'null';
  }

  /// Firestore / dashboards sometimes store booleans as strings.
  bool? _asBool(dynamic value) {
    if (value is bool) return value;
    final text = value?.toString().toLowerCase().trim();
    if (text == 'true' || text == '1' || text == 'yes') return true;
    if (text == 'false' || text == '0' || text == 'no') return false;
    return null;
  }

  Future<UserCredential?> signInUserAccount(
      {required String email,
      required String password,
      void Function(UserCredential)? onSuccess,
      void Function(String)? onFailed}) async {
    try {
      authenticating = true;
      notifyListeners();
      final credential = await auth.signInWithEmailAndPassword(
          email: email, password: password);

      user = credential.user;
      authenticating = false;
      notifyListeners();
      onSuccess?.call(credential);
      return credential;
    } on FirebaseAuthException catch (e) {
      user = null;
      authenticating = false;
      notifyListeners();
      Logger().e(e);
      onFailed?.call(e.message ?? 'Sign in failed');
      return null;
    } catch (e) {
      user = null;
      authenticating = false;
      notifyListeners();
      Logger().e(e);
      onFailed?.call('Sign in failed');
      return null;
    }
  }

  Future<UserCredential?> signUpUserAccount({
    required String email,
    required String password,
    required String fullname,
    void Function(UserCredential)? onSuccess,
    void Function(String)? onFailed,
  }) async {
    try {
      authenticating = true;
      notifyListeners();

      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(fullname);

      await ensureDoctorProfileSeed(
        fullname: fullname,
        email: email,
      );

      user = credential.user;
      userAccount = UserModel(
        fullname: fullname.trim(),
        email: email.trim(),
        id: credential.user?.uid,
        loggedIn: true,
        online: true,
      );
      authenticating = false;
      notifyListeners();
      onSuccess?.call(credential);
      return credential;
    } on FirebaseAuthException catch (e) {
      user = null;
      authenticating = false;
      notifyListeners();
      Logger().e(e);
      onFailed?.call(e.message ?? 'Registration failed');
      return null;
    } catch (e) {
      user = null;
      authenticating = false;
      notifyListeners();
      Logger().e(e);
      onFailed?.call('Registration failed');
      return null;
    }
  }

  Future<void> createDoctorProfile(UserModel doctor) async {
    try {
      loading = true;
      notifyListeners();

      final doctorId = auth.currentUser?.uid;
      final existingProfile = doctorId == null
          ? null
          : await FirestoreSchema.doctorDoc(doctorId).get();
      final existingProfileData = existingProfile?.data();

      await updateDoctorProfile({
        ...doctor.toMap(),
        if (existingProfileData?['isVerified'] is! bool) "isVerified": false,
        if (existingProfileData?['verificationStatus'] == null)
          "verificationStatus": "pending",
        "profileComplete": true,
        "onboardingStep": "complete",
      });

      userAccount = doctor;
      loading = false;
      notifyListeners();
    } on FirebaseException catch (e) {
      Logger().e(e);
      loading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      Logger().e(e);
      loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> ensureDoctorProfileSeed(
      {String? fullname, String? email}) async {
    final currentUser = auth.currentUser;
    if (currentUser == null) return;

    final doctorRef = FirestoreSchema.doctorDoc(currentUser.uid);
    final snapshot = await doctorRef.get();
    final profileData = <String, dynamic>{
      "doctorid": currentUser.uid,
      "doctorId": currentUser.uid,
      "fullname": fullname?.trim().isNotEmpty == true
          ? fullname!.trim()
          : currentUser.displayName,
      "email":
          email?.trim().isNotEmpty == true ? email!.trim() : currentUser.email,
      "loggedIn": true,
      "online": true,
      "updatedAt": FieldValue.serverTimestamp(),
    };

    if (!snapshot.exists) {
      profileData.addAll({
        "profileComplete": false,
        "onboardingStep": "signed_up",
        "isVerified": false,
        "verificationStatus": "pending",
        "isAvailable": false,
        "createdAt": FieldValue.serverTimestamp(),
        "notificationPreferences": {
          "appointments": true,
          "messages": true,
          "secondOpinions": true,
          "prescriptions": true,
          "labRequests": true,
          "patientUpdates": true,
          "platformAlerts": true,
          "updatedAt": FieldValue.serverTimestamp(),
        },
      });
    }

    await doctorRef.set(profileData, SetOptions(merge: true));
    final updatedSnapshot = await doctorRef.get();
    if (updatedSnapshot.exists) {
      userAccount = UserModel.fromDocumentSnapshot(updatedSnapshot);
      notifyListeners();
    }
  }

  Future<bool> _isDoctorVerified(String doctorId) async {
    final snapshot = await FirestoreSchema.doctorDoc(doctorId).get();
    return snapshot.data()?['isVerified'] == true;
  }

  Future<void> updateDoctorProfile(Map<String, dynamic> profileData) async {
    final doctorId = auth.currentUser?.uid;
    if (doctorId == null) return;

    final doctorRef = FirestoreSchema.doctorDoc(doctorId);
    await doctorRef.set({
      ...profileData,
      "doctorid": doctorId,
      "doctorId": doctorId,
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final updatedSnapshot = await doctorRef.get();
    if (updatedSnapshot.exists) {
      userAccount = UserModel.fromDocumentSnapshot(updatedSnapshot);
      notifyListeners();
    }
  }

  Future<UserModel?> getUserProfile(
      {void Function(UserModel)? onSuccess,
      void Function(UserModel?)? onFailed}) async {
    try {
      authenticating = true;
      notifyListeners();
      final profile =
          await db.collection("Doctors").doc(auth.currentUser?.uid).get();
      await getMyPatients();
      if (profile.exists) {
        final data = UserModel.fromDocumentSnapshot(profile);
        if (kDebugMode) {
          print(data.toMap());
        }
        userAccount = data;
        authenticating = false;
        notifyListeners();
        onSuccess?.call(data);
        return data;
      } else {
        onFailed?.call(null);
        userAccount = null;
        authenticating = false;
        notifyListeners();

        return null;
      }
    } on FirebaseAuthException catch (e) {
      Logger().e(e);
      userAccount = null;
      authenticating = false;
      notifyListeners();
      onFailed?.call(null);
      return null;
    } catch (e) {
      Logger().e(e);
      userAccount = null;
      authenticating = false;
      notifyListeners();
      onFailed?.call(null);
      return null;
    }
  }

  Future<Map<String, dynamic>?> getAvailability(
      {required DateTime date,
      void Function(Map<String, dynamic>?)? onSuccess,
      void Function()? onFailed}) async {
    try {
      loading = true;
      notifyListeners();
      final doctorId = auth.currentUser?.uid;
      if (doctorId == null) {
        loading = false;
        notifyListeners();
        onFailed?.call();
        return null;
      }

      final canonicalDay = await FirestoreSchema.availabilityDay(
        doctorId,
        date,
      ).get();
      if (canonicalDay.exists) {
        // Load ALL slots (open + booked) so the doctor can manage bookings.
        final slotsSnap = await canonicalDay.reference
            .collection(DoctorSubcollections.slots)
            .get();
        final details = slotsSnap.docs
            .map((doc) => _slotFromDoc(doc.data(), doc.id))
            .whereType<DoctorAvailabilitySlot>()
            .toList()
          ..sort((a, b) => a.sortMinutes.compareTo(b.sortMinutes));
        final openLabels = details
            .where((s) => s.open)
            .map((s) => s.label)
            .toList();
        final data = {
          ...canonicalDay.data()!,
          "date": canonicalDay.data()!["date"] ?? date,
          // Keep legacy string list for callers that only need open times.
          "slots": openLabels,
          "slotDetails": details,
        };
        loading = false;
        notifyListeners();
        onSuccess?.call(data);
        return data;
      }

      final data = await db
          .collection("Doctors")
          .doc(doctorId)
          .collection("Availability")
          .where('date', isEqualTo: date)
          .get();

      final legacyData = data.docs.firstOrNull?.data();
      if (legacyData != null) {
        final labels = List<dynamic>.from(legacyData['slots'] ?? [])
            .map((slot) => slot.toString())
            .where((slot) => slot.trim().isNotEmpty)
            .toList()
          ..sort(compareSlotLabelsAscending);
        final details = labels
            .map(
              (label) => DoctorAvailabilitySlot(
                label: label,
                open: true,
                booked: false,
              ),
            )
            .toList();
        final enriched = {
          ...legacyData,
          'slots': labels,
          'slotDetails': details,
        };
        loading = false;
        notifyListeners();
        onSuccess?.call(enriched);
        return enriched;
      }
      loading = false;
      notifyListeners();
      onSuccess?.call(null);
      return null;
    } on FirebaseAuthException catch (e) {
      Logger().e(e);

      loading = false;
      notifyListeners();
      onFailed?.call();
      return null;
    } catch (e) {
      Logger().e(e);

      loading = false;
      notifyListeners();
      onFailed?.call();
      return null;
    }
  }

  Future<List<AvailabilityDaySummary>> getAvailabilitySchedule({
    DateTime? start,
    DateTime? end,
    void Function(List<AvailabilityDaySummary>)? onSuccess,
    void Function()? onFailed,
  }) async {
    try {
      final doctorId = auth.currentUser?.uid;
      if (doctorId == null) {
        onFailed?.call();
        return [];
      }

      final schedule = <String, AvailabilityDaySummary>{};
      final canonicalDays = await FirestoreSchema.doctorDoc(doctorId)
          .collection(DoctorSubcollections.availabilityDays)
          .get();

      for (final day in canonicalDays.docs) {
        final data = day.data();
        final date = _dateTimeFromValue(data['date']) ?? _dateFromKey(day.id);
        if (date == null || !_dateInRange(date, start, end)) continue;

        final slotDocs = await day.reference
            .collection(DoctorSubcollections.slots)
            .where('status', isEqualTo: true)
            .get();
        final slots = slotDocs.docs
            .map((doc) => doc.data()['label']?.toString())
            .whereType<String>()
            .toList()
          ..sort(compareSlotLabelsAscending);
        schedule[FirestoreSchema.dateKey(date)] = AvailabilityDaySummary(
          date: DateTime(date.year, date.month, date.day),
          status: data['status'] == true,
          slots: slots,
        );
      }

      final legacyDays = await db
          .collection('Doctors')
          .doc(doctorId)
          .collection('Availability')
          .get();
      for (final day in legacyDays.docs) {
        final data = day.data();
        final date = _dateTimeFromValue(data['date']);
        if (date == null || !_dateInRange(date, start, end)) continue;

        final labels = List<dynamic>.from(data['slots'] ?? [])
            .map((slot) => slot.toString())
            .where((slot) => slot.trim().isNotEmpty)
            .toList()
          ..sort(compareSlotLabelsAscending);
        schedule.putIfAbsent(
          FirestoreSchema.dateKey(date),
          () => AvailabilityDaySummary(
            date: DateTime(date.year, date.month, date.day),
            status: data['status'] == true,
            slots: labels,
          ),
        );
      }

      final days = schedule.values.toList()
        ..sort((first, second) => first.date.compareTo(second.date));
      onSuccess?.call(days);
      return days;
    } catch (e) {
      Logger().e(e);
      onFailed?.call();
      return [];
    }
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> checkAvailability(
      {required DateTime date,
      void Function(QueryDocumentSnapshot<Map<String, dynamic>>?)? onSuccess,
      void Function()? onFailed}) async {
    try {
      loading = true;
      notifyListeners();

      final data = await db
          .collection("Doctors")
          .doc(auth.currentUser?.uid)
          .collection("Availability")
          .where('date', isEqualTo: date)
          .get();

      onSuccess?.call(data.docs.firstOrNull);
      return data.docs.firstOrNull;
    } on FirebaseAuthException catch (e) {
      Logger().e(e);

      onFailed?.call();
      return null;
    } catch (e) {
      Logger().e(e);

      onFailed?.call();
      return null;
    }
  }

  Future<void> updateAvailability(
      {required DateTime date,
      required String timeSlots,
      required bool status,
      void Function(Map<String, dynamic>?)? onSuccess,
      void Function()? onFailed}) async {
    final labels = timeSlots.trim().isEmpty
        ? const <String>[]
        : <String>[timeSlots.trim()];
    await updateAvailabilitySlots(
      date: date,
      slotLabels: labels,
      status: status,
      onSuccess: onSuccess,
      onFailed: onFailed,
    );
  }

  /// Publish a day and optionally many slot labels in one write.
  ///
  /// **Policy: additive merge.** Existing slots are kept. Exact-label
  /// duplicates are skipped. Booked slots are never reopened (status stays
  /// closed / booked flags preserved).
  Future<AvailabilityWriteResult> updateAvailabilitySlots({
    required DateTime date,
    required List<String> slotLabels,
    required bool status,
    void Function(Map<String, dynamic>?)? onSuccess,
    void Function()? onFailed,
  }) async {
    try {
      loading = true;
      notifyListeners();
      final data = await checkAvailability(date: date);
      final doctorId = auth.currentUser?.uid;
      if (doctorId == null) {
        loading = false;
        notifyListeners();
        onFailed?.call();
        return const AvailabilityWriteResult(
          added: 0,
          skippedExisting: 0,
          skippedBooked: 0,
        );
      }
      if (!await _isDoctorVerified(doctorId)) {
        loading = false;
        notifyListeners();
        onFailed?.call();
        return const AvailabilityWriteResult(
          added: 0,
          skippedExisting: 0,
          skippedBooked: 0,
        );
      }

      final cleaned = slotLabels
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList();

      // Load existing slot docs to decide merge vs skip.
      final existingSnap = await FirestoreSchema.availabilityDay(doctorId, date)
          .collection(DoctorSubcollections.slots)
          .get();
      final existingById = {
        for (final doc in existingSnap.docs) doc.id: doc.data(),
      };

      final toAdd = <String>[];
      var skippedExisting = 0;
      var skippedBooked = 0;

      for (final label in cleaned) {
        final id = FirestoreSchema.slotId(label);
        final existing = existingById[id];
        if (existing == null) {
          toAdd.add(label);
          continue;
        }
        if (_slotDataIsBooked(existing)) {
          skippedBooked++;
          continue;
        }
        // Already open with same label — nothing to do.
        skippedExisting++;
      }

      if (data != null) {
        await db
            .collection("Doctors")
            .doc(doctorId)
            .collection("Availability")
            .doc(data.id)
            .update(
              toAdd.isEmpty
                  ? {'status': status}
                  : {
                      'status': status,
                      'slots': FieldValue.arrayUnion(toAdd),
                    },
            );
      } else {
        await db
            .collection("Doctors")
            .doc(doctorId)
            .collection("Availability")
            .add({
          'date': date,
          'status': status,
          'slots': toAdd,
        });
      }

      final batch = db.batch();
      batch.set(
        FirestoreSchema.availabilityDay(doctorId, date),
        {
          "doctorId": doctorId,
          "date": date,
          "dateKey": FirestoreSchema.dateKey(date),
          "status": status,
          "updatedAt": FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      for (final label in toAdd) {
        // Create only — do not merge over booked docs.
        batch.set(
          FirestoreSchema.availabilitySlot(doctorId, date, label),
          {
            "doctorId": doctorId,
            "dateKey": FirestoreSchema.dateKey(date),
            "slotId": FirestoreSchema.slotId(label),
            "label": label,
            "status": true,
            "booked": false,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
          },
        );
      }
      await batch.commit();

      final newData = await getAvailability(date: date);
      loading = false;
      notifyListeners();
      onSuccess?.call(newData);
      return AvailabilityWriteResult(
        added: toAdd.length,
        skippedExisting: skippedExisting,
        skippedBooked: skippedBooked,
      );
    } on FirebaseAuthException catch (e) {
      Logger().e(e);
      loading = false;
      notifyListeners();
      onFailed?.call();
      return const AvailabilityWriteResult(
        added: 0,
        skippedExisting: 0,
        skippedBooked: 0,
      );
    } catch (e) {
      Logger().e(e);
      loading = false;
      notifyListeners();
      onFailed?.call();
      return const AvailabilityWriteResult(
        added: 0,
        skippedExisting: 0,
        skippedBooked: 0,
      );
    }
  }

  /// Whether a slot is reserved by a patient booking.
  Future<SlotBookingInfo> getSlotBookingInfo({
    required DateTime date,
    required String timeSlots,
  }) async {
    final doctorId = auth.currentUser?.uid;
    if (doctorId == null) {
      return const SlotBookingInfo(booked: false);
    }
    try {
      final snap = await FirestoreSchema.availabilitySlot(
        doctorId,
        date,
        timeSlots,
      ).get();
      if (!snap.exists) {
        return const SlotBookingInfo(booked: false);
      }
      final data = snap.data() ?? {};
      if (!_slotDataIsBooked(data)) {
        return const SlotBookingInfo(booked: false);
      }
      return SlotBookingInfo(
        booked: true,
        bookedBy: data['bookedBy']?.toString(),
        appointmentId: data['bookedAppointmentId']?.toString(),
      );
    } catch (e) {
      Logger().e(e);
      return const SlotBookingInfo(booked: false);
    }
  }

  /// Removes an **open** slot. Fails with [SlotBookedException] if booked.
  Future<void> removeTimeSlot(
      {required DateTime date,
      required String timeSlots,
      void Function(Map<String, dynamic>?)? onSuccess,
      void Function()? onFailed}) async {
    try {
      final doctorId = auth.currentUser?.uid;
      if (doctorId == null) {
        onFailed?.call();
        return;
      }

      final booking = await getSlotBookingInfo(
        date: date,
        timeSlots: timeSlots,
      );
      if (booking.booked) {
        onFailed?.call();
        throw SlotBookedException(
          slotLabel: timeSlots,
          appointmentId: booking.appointmentId,
          bookedBy: booking.bookedBy,
        );
      }

      final data = await checkAvailability(date: date);
      if (data != null) {
        await db
            .collection("Doctors")
            .doc(doctorId)
            .collection("Availability")
            .doc(data.id)
            .update(
          {
            'slots': FieldValue.arrayRemove([timeSlots])
          },
        );
      }
      await FirestoreSchema.availabilitySlot(doctorId, date, timeSlots)
          .delete();
      await FirestoreSchema.availabilityDay(doctorId, date).set({
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final newData = await getAvailability(date: date);

      onSuccess?.call(newData);
    } on SlotBookedException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      Logger().e(e);

      loading = false;
      notifyListeners();
      onFailed?.call();
    } catch (e) {
      Logger().e(e);

      loading = false;
      notifyListeners();
      onFailed?.call();
    }
  }

  bool _slotDataIsBooked(Map<String, dynamic> data) {
    if (data['booked'] == true) return true;
    final by = data['bookedBy']?.toString();
    if (by != null && by.isNotEmpty) return true;
    final appt = data['bookedAppointmentId']?.toString();
    if (appt != null && appt.isNotEmpty) return true;
    // Patient booking sets status:false while keeping the slot doc.
    if (data['status'] == false &&
        (data['booked'] == true ||
            (data['bookedBy']?.toString().isNotEmpty ?? false))) {
      return true;
    }
    return false;
  }

  DoctorAvailabilitySlot? _slotFromDoc(Map<String, dynamic> data, String id) {
    final label = data['label']?.toString() ?? id;
    if (label.trim().isEmpty) return null;
    final booked = _slotDataIsBooked(data);
    final open = !booked && data['status'] == true;
    return DoctorAvailabilitySlot(
      label: label,
      open: open,
      booked: booked,
      bookedBy: data['bookedBy']?.toString(),
      appointmentId: data['bookedAppointmentId']?.toString(),
    );
  }

  /// Cancel the linked appointment and reopen the slot for booking.
  Future<void> cancelBookedSlotAndFree({
    required DateTime date,
    required String slotLabel,
    void Function()? onSuccess,
    void Function(String message)? onFailed,
  }) async {
    try {
      final doctorId = auth.currentUser?.uid;
      if (doctorId == null) {
        onFailed?.call('Not signed in');
        return;
      }
      final info = await getSlotBookingInfo(date: date, timeSlots: slotLabel);
      if (!info.booked) {
        onFailed?.call('This slot is not booked');
        return;
      }

      final batch = db.batch();
      final appointmentId = info.appointmentId;
      final patientId = info.bookedBy;

      if (appointmentId != null && appointmentId.isNotEmpty) {
        batch.set(
          FirestoreSchema.appointments().doc(appointmentId),
          {
            'status': 'canceled',
            'updatedAt': FieldValue.serverTimestamp(),
            'canceledAt': FieldValue.serverTimestamp(),
            'canceledBy': doctorId,
            'cancelReason': 'Doctor freed the time slot',
          },
          SetOptions(merge: true),
        );
        if (patientId != null && patientId.isNotEmpty) {
          batch.set(
            db
                .collection('Patients')
                .doc(patientId)
                .collection('AppointmentRefs')
                .doc(appointmentId),
            {
              'appointmentId': appointmentId,
              'patientId': patientId,
              'doctorId': doctorId,
              'status': 'canceled',
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }
      }

      batch.set(
        FirestoreSchema.availabilitySlot(doctorId, date, slotLabel),
        {
          'status': true,
          'booked': false,
          'bookedBy': FieldValue.delete(),
          'bookedAppointmentId': FieldValue.delete(),
          'releasedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'label': slotLabel,
          'doctorId': doctorId,
          'dateKey': FirestoreSchema.dateKey(date),
          'slotId': FirestoreSchema.slotId(slotLabel),
        },
        SetOptions(merge: true),
      );
      // Ensure label is on the legacy array too.
      final legacy = await checkAvailability(date: date);
      if (legacy != null) {
        batch.set(
          db
              .collection('Doctors')
              .doc(doctorId)
              .collection('Availability')
              .doc(legacy.id),
          {
            'status': true,
            'slots': FieldValue.arrayUnion([slotLabel]),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();
      onSuccess?.call();
    } catch (e) {
      Logger().e(e);
      onFailed?.call(e.toString());
    }
  }

  Future<List<AppointmentModel>?> getAppointments(
      {void Function(List<AppointmentModel>?)? onSuccess,
      void Function(List<AppointmentModel>?)? onFailed}) async {
    try {
      authenticating = true;
      notifyListeners();
      final doctorId = user?.uid ?? auth.currentUser?.uid;
      if (doctorId == null) {
        authenticating = false;
        notifyListeners();
        onFailed?.call([]);
        return [];
      }
      // Query legacy + canonical fields independently so one rule/index
      // failure does not wipe the whole load.
      final appointmentDocs =
          await _queryDoctorAppointmentDocs(doctorId);

      final data = appointmentDocs
          .map(AppointmentModel.fromSnapshot)
          .toList();
      if (kDebugMode) {
        print(data);
      }
      userAppointments = data;
      authenticating = false;
      notifyListeners();
      onSuccess?.call(data);
      return data;
    } on FirebaseAuthException catch (e) {
      Logger().e(e);
      authenticating = false;
      notifyListeners();
      onFailed?.call(null);
      return null;
    } catch (e) {
      Logger().e(e);
      authenticating = false;
      notifyListeners();
      onFailed?.call(null);
      return null;
    }
  }

  Future<List<PersonalPatientsModel>> getMyPatients(
      {void Function(List<PersonalPatientsModel>)? onSuccess,
      void Function(List<PersonalPatientsModel>?)? onFailed}) async {
    try {
      authenticating = true;
      notifyListeners();
      final doctorId = auth.currentUser?.uid;
      if (doctorId == null) {
        authenticating = false;
        notifyListeners();
        onFailed?.call([]);
        return [];
      }

      final patientMap = <String, PersonalPatientsModel>{};

      try {
        final patients = await db
            .collection("Doctors")
            .doc(doctorId)
            .collection("Patients")
            .get();
        for (final patient in patients.docs) {
          final id =
              patient.data()['patientId']?.toString() ?? patient.id;
          patientMap[id] = PersonalPatientsModel.fromMap({
            ...patient.data(),
            'patientId': patient.data()['patientId'] ?? patient.id,
          });
        }
      } catch (e) {
        Logger().e('Doctors/$doctorId/Patients list failed: $e');
      }

      // Enrich from appointments when allowed; never fail the whole call.
      try {
        final appointmentDocs =
            await _queryDoctorAppointmentDocs(doctorId);
        for (final appointmentDoc in appointmentDocs) {
          final appointment = AppointmentModel.fromSnapshot(appointmentDoc);
          final patientId = appointment.patientId ?? appointment.patient?.id;
          if (patientId == null || patientId.trim().isEmpty) continue;
          patientMap.putIfAbsent(
            patientId,
            () => PersonalPatientsModel(
              patientId: patientId,
              patientName: appointment.patient?.name ?? "Patient",
              patientImage: appointment.patient?.photo ?? "",
              status: "active",
            ),
          );
        }
      } catch (e) {
        Logger().e('getMyPatients appointment enrich failed: $e');
      }

      // Prefer live Patients/{id}.photo over stale Doctors/.../Patients mirrors.
      try {
        final ids = patientMap.keys.take(40).toList();
        final snaps = await Future.wait(
          ids.map((id) => db.collection('Patients').doc(id).get()),
        );
        for (var i = 0; i < ids.length; i++) {
          final snap = snaps[i];
          if (!snap.exists) continue;
          final live = patientAvatarUrl(snap.data());
          if (live == null || live.isEmpty) continue;
          final existing = patientMap[ids[i]];
          if (existing == null) continue;
          patientMap[ids[i]] = existing.copyWith(patientImage: live);
        }
      } catch (e) {
        Logger().e('getMyPatients live photo enrich failed: $e');
      }

      final data = patientMap.values.toList()
        ..sort((first, second) => (first.patientName ?? '')
            .toLowerCase()
            .compareTo((second.patientName ?? '').toLowerCase()));
      if (kDebugMode) {
        print(data);
      }
      mypatients = data;
      try {
        await db.collection('Doctors').doc(doctorId).set({
          'patientCount': data.length,
          'patientsCount': data.length,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        Logger().e('Unable to denormalize patientCount: $e');
      }
      authenticating = false;
      notifyListeners();
      onSuccess?.call(data);
      return data;
    } on FirebaseAuthException catch (e) {
      Logger().e(e);
      mypatients = [];
      authenticating = false;
      notifyListeners();
      onFailed?.call([]);
      return [];
    } catch (e) {
      Logger().e(e);
      mypatients = [];
      authenticating = false;
      notifyListeners();
      onFailed?.call([]);
      return [];
    }
  }

  /// Loads doctor appointments under both field names without failing
  /// the whole request if one query is denied or missing an index.
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      _queryDoctorAppointmentDocs(String doctorId) async {
    final docs = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};

    Future<void> merge(String field) async {
      try {
        final snap = await FirestoreSchema.appointments()
            .where(field, isEqualTo: doctorId)
            .get();
        for (final doc in snap.docs) {
          docs[doc.id] = doc;
        }
      } catch (e) {
        Logger().e('Appointments where $field == $doctorId failed: $e');
      }
    }

    await Future.wait([
      merge('doctorId'),
      merge('doctor_id'),
      merge('providerId'),
    ]);
    return docs.values.toList();
  }
}

final apimethods = ChangeNotifierProvider<ApiMethods>((ref) {
  return ApiMethods();
});

DateTime? _dateTimeFromValue(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return null;
}

DateTime? _dateFromKey(String value) {
  final parts = value.split('-');
  if (parts.length != 3) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return null;
  return DateTime(year, month, day);
}

bool _dateInRange(DateTime date, DateTime? start, DateTime? end) {
  final day = DateTime(date.year, date.month, date.day);
  final startDay =
      start == null ? null : DateTime(start.year, start.month, start.day);
  final endDay = end == null ? null : DateTime(end.year, end.month, end.day);
  if (startDay != null && day.isBefore(startDay)) return false;
  if (endDay != null && day.isAfter(endDay)) return false;
  return true;
}
