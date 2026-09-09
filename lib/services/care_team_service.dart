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
      await ref.set(
        {
          'patientId': patientId,
          'patientName': patientName,
          'patientImage': patientImage,
          'status': 'active',
          'updatedAt': FieldValue.serverTimestamp(),
          if (currentSource != 'personal_doctor')
            'source': (currentSource != null && currentSource.isNotEmpty)
                ? currentSource
                : 'treating',
          if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  static bool isPersonalDoctor(Map<String, dynamic>? link) {
    return (link?['source'] ?? '').toString() == 'personal_doctor';
  }
}
