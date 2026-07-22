import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:yarisa_doctor/models/appointment_model.dart';

import 'package:yarisa_doctor/api/firestore_schema.dart';
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

    final profile = await FirestoreSchema.doctorDoc(currentUser.uid).get();
    final profileData = profile.data();
    if (profile.exists && profileData != null) {
      userAccount = UserModel.fromDocumentSnapshot(profile);
      notifyListeners();
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

    if (profileData['isVerified'] == true) {
      return const BaseScreen();
    }

    return DoctorVerificationPendingScreen(initialProfileData: profileData);
  }

  bool _doctorProfileComplete(Map<String, dynamic> profileData) {
    if (profileData['profileComplete'] == true) return true;
    if (profileData['onboardingStep'] == 'complete') return true;
    if (profileData['profileComplete'] == false) return false;

    return _hasProfileValue(profileData['speciality']) &&
        _hasProfileValue(profileData['licenseCode']) &&
        _hasProfileValue(profileData['clinic']);
  }

  bool _hasProfileValue(dynamic value) {
    return value?.toString().trim().isNotEmpty == true;
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
        final slots = await canonicalDay.reference
            .collection(DoctorSubcollections.slots)
            .where("status", isEqualTo: true)
            .get();
        final data = {
          ...canonicalDay.data()!,
          "date": canonicalDay.data()!["date"] ?? date,
          "slots": slots.docs
              .map((doc) => doc.data()["label"]?.toString())
              .whereType<String>()
              .toList(),
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
      loading = false;
      notifyListeners();
      onSuccess?.call(legacyData);
      return legacyData;
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
            .toList();
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

        schedule.putIfAbsent(
          FirestoreSchema.dateKey(date),
          () => AvailabilityDaySummary(
            date: DateTime(date.year, date.month, date.day),
            status: data['status'] == true,
            slots: List<dynamic>.from(data['slots'] ?? [])
                .map((slot) => slot.toString())
                .where((slot) => slot.trim().isNotEmpty)
                .toList(),
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
    try {
      final data = await checkAvailability(
        date: date,
      );
      final doctorId = auth.currentUser?.uid;
      if (doctorId == null) return;
      if (!await _isDoctorVerified(doctorId)) {
        loading = false;
        notifyListeners();
        onFailed?.call();
        return;
      }
      if (data != null) {
        await db
            .collection("Doctors")
            .doc(doctorId)
            .collection("Availability")
            .doc(data.id)
            .update(
              timeSlots.trim().isEmpty
                  ? {
                      'status': status,
                    }
                  : {
                      'status': status,
                      'slots': FieldValue.arrayUnion([timeSlots])
                    },
            );
      } else {
        await db
            .collection("Doctors")
            .doc(doctorId)
            .collection("Availability")
            .add(
          {
            'date': date,
            'status': status,
            'slots': FieldValue.arrayUnion([timeSlots])
          },
        );
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
          SetOptions(merge: true));
      if (timeSlots.trim().isNotEmpty) {
        batch.set(
            FirestoreSchema.availabilitySlot(doctorId, date, timeSlots),
            {
              "doctorId": doctorId,
              "dateKey": FirestoreSchema.dateKey(date),
              "slotId": FirestoreSchema.slotId(timeSlots),
              "label": timeSlots,
              "status": status,
              "createdAt": FieldValue.serverTimestamp(),
              "updatedAt": FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true));
      }
      await batch.commit();

      final newData = await getAvailability(
        date: date,
      );

      onSuccess?.call(newData);
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

  Future<void> removeTimeSlot(
      {required DateTime date,
      required String timeSlots,
      void Function(Map<String, dynamic>?)? onSuccess,
      void Function()? onFailed}) async {
    try {
      final data = await checkAvailability(
        date: date,
      );
      final doctorId = auth.currentUser?.uid;
      if (doctorId == null) return;
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

      final newData = await getAvailability(
        date: date,
      );

      onSuccess?.call(newData);
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
      final legacyAppointments = await FirestoreSchema.appointments()
          .where("doctor_id", isEqualTo: doctorId)
          .get();
      final canonicalAppointments = await FirestoreSchema.appointments()
          .where("doctorId", isEqualTo: doctorId)
          .get();
      final appointmentDocs = {
        for (final doc in legacyAppointments.docs) doc.id: doc,
        for (final doc in canonicalAppointments.docs) doc.id: doc,
      }.values.toList();

      final data = appointmentDocs
          .map((e) => (AppointmentModel.fromSnapshot(e)))
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
      final patients = await db
          .collection("Doctors")
          .doc(doctorId)
          .collection("Patients")
          .get();
      final patientMap = <String, PersonalPatientsModel>{
        for (final patient in patients.docs)
          (patient.data()['patientId']?.toString() ?? patient.id):
              PersonalPatientsModel.fromMap({
            ...patient.data(),
            'patientId': patient.data()['patientId'] ?? patient.id,
          })
      };

      final appointmentsSnapshot = await FirestoreSchema.appointments()
          .where("doctorId", isEqualTo: doctorId)
          .get();
      final appointmentDocs = appointmentsSnapshot.docs;

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

      final data = patientMap.values.toList()
        ..sort((first, second) => (first.patientName ?? '')
            .toLowerCase()
            .compareTo((second.patientName ?? '').toLowerCase()));
      if (kDebugMode) {
        print(data);
      }
      mypatients = data;
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
