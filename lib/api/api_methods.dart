import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:yarisa_doctor/models/appointment_model.dart';

import 'package:yarisa_doctor/models/personal_patients_model.dart';
import 'package:yarisa_doctor/screens/authentication/welcome_screen.dart';
import 'package:yarisa_doctor/screens/main/base.dart';

import '../models/user_model.dart';

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
      final userA = await getUserProfile();

      userAccount = userA;
      notifyListeners();
      Navigator.pushAndRemoveUntil(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (context) => const BaseScreen()),
          (route) => false);
    } else {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (route) => false);
    }
  }

  Future<UserCredential?> signInUserAccount(
      {required String email,
      required String password,
      void Function(UserCredential)? onSuccess,
      void Function(UserCredential)? onFailed}) async {
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
      return null;
    } catch (e) {
      user = null;
      authenticating = false;
      notifyListeners();
      Logger().e(e);
      return null;
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

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> getAvailability(
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

      loading = false;
      notifyListeners();
      onSuccess?.call(data.docs.firstOrNull);
      return data.docs.firstOrNull;
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
      void Function(QueryDocumentSnapshot<Map<String, dynamic>>?)? onSuccess,
      void Function()? onFailed}) async {
    try {
      final data = await checkAvailability(
        date: date,
      );
      if (data != null) {
        await db
            .collection("Doctors")
            .doc(auth.currentUser?.uid)
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
            .doc(auth.currentUser?.uid)
            .collection("Availability")
            .add(
          {
            'date': date,
            'status': status,
            'slots': FieldValue.arrayUnion([timeSlots])
          },
        );
      }

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
      void Function(QueryDocumentSnapshot<Map<String, dynamic>>?)? onSuccess,
      void Function()? onFailed}) async {
    try {
      final data = await checkAvailability(
        date: date,
      );
      if (data != null) {
        await db
            .collection("Doctors")
            .doc(auth.currentUser?.uid)
            .collection("Availability")
            .doc(data.id)
            .update(
          {
            'slots': FieldValue.arrayRemove([timeSlots])
          },
        );
      }

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
      final appointments = await db
          .collection("Doctors")
          .doc(auth.currentUser?.uid)
          .collection('Appointments')
          .get();

      final data =
          appointments.docs.map((e) => (AppointmentModel.fromMap(e))).toList();
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
      final patients = await db
          .collection("Doctors")
          .doc(auth.currentUser?.uid)
          .collection("Patients")
          .get();
      if (patients.docs.isNotEmpty) {
        final data = patients.docs
            .map((e) => PersonalPatientsModel.fromMap(e.data()))
            .toList();
        if (kDebugMode) {
          print(data);
        }
        data.sort((a, b) => a.patientName!.compareTo(b.patientName!));
        mypatients = data;
        authenticating = false;
        notifyListeners();
        onSuccess?.call(data);
        return data;
      } else {
        onFailed?.call([]);
        mypatients = [];
        authenticating = false;
        notifyListeners();

        return [];
      }
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
