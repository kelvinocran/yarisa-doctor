import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Links this doctor to a patient so chart reads (allergies, history)
/// pass care-team rules. Never demotes an existing personal-doctor link.
class CareTeamService {
  CareTeamService._();

  static DocumentReference<Map<String, dynamic>> _linkRef(
    String doctorId,
    String patientId,
  ) {
    return FirebaseFirestore.instance
        .collection('Doctors')
        .doc(doctorId)
        .collection('Patients')
        .doc(patientId);
  }

  static bool patientListsDoctor(Map<String, dynamic>? patient, String doctorId) {
    if (patient == null || doctorId.isEmpty) return false;
    final ids = patient['personalDoctorIds'];
    if (ids is List &&
        ids.map((item) => item.toString()).contains(doctorId)) {
      return true;
    }
    final listed = patient['personal_doctors'];
    if (listed is List) {
      for (final entry in listed) {
        if (entry is! Map) continue;
        final id = (entry['doctorid'] ?? entry['doctorId'] ?? entry['id'])
            ?.toString();
        if (id == doctorId) return true;
      }
    }
    return false;
  }

  static bool isPersonalDoctor(
    Map<String, dynamic>? link, {
    Map<String, dynamic>? patient,
    Map<String, dynamic>? user,
    String? doctorId,
  }) {
    if ((link?['source'] ?? '').toString() == 'personal_doctor') return true;
    if (doctorId == null) return false;
    return patientListsDoctor(patient, doctorId) ||
        patientListsDoctor(user, doctorId);
  }

  static Future<void> ensureTreatingLink({
    required String patientId,
    required String patientName,
    String patientImage = '',
  }) async {
    final doctorId = FirebaseAuth.instance.currentUser?.uid;
    if (doctorId == null || patientId.isEmpty) return;

    final ref = _linkRef(doctorId, patientId);
    try {
      final existing = await ref.get();
      final currentSource = existing.data()?['source']?.toString();
      var source = currentSource == 'personal_doctor'
          ? 'personal_doctor'
          : ((currentSource != null && currentSource.isNotEmpty)
              ? currentSource
              : 'treating');
      if (source != 'personal_doctor') {
        final patient = await FirebaseFirestore.instance
            .collection('Patients')
            .doc(patientId)
            .get();
        if (patientListsDoctor(patient.data(), doctorId)) {
          source = 'personal_doctor';
        }
      }
      if (source == 'personal_doctor') {
        try {
          await FirebaseFirestore.instance
              .collection('Patients')
              .doc(patientId)
              .set(
            {
              'personalDoctorIds': FieldValue.arrayUnion([doctorId]),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        } catch (_) {}
      }
      await ref.set(
        {
          'patientId': patientId,
          'patientName': patientName,
          'patientImage': patientImage,
          'status': 'active',
          'source': source,
          'updatedAt': FieldValue.serverTimestamp(),
          if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {}
  }
}
