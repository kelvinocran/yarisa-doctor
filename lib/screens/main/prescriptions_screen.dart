import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yarisa_doctor/api/api_methods.dart';
import 'package:yarisa_doctor/constants/yarisa_constants.dart';
import 'package:yarisa_doctor/models/personal_patients_model.dart';
import 'package:yarisa_doctor/screens/add_prescription.dart';
import 'package:yarisa_doctor/services/care_team_service.dart';
import 'package:yarisa_doctor/ui/doctor_ui.dart';
import 'package:yarisa_doctor/widgets/app_snack.dart';

class PrescriptionsScreen extends ConsumerStatefulWidget {
  const PrescriptionsScreen({super.key, this.patient});

  final PersonalPatientsModel? patient;

  @override
  ConsumerState<PrescriptionsScreen> createState() =>
      _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends ConsumerState<PrescriptionsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _saving = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<PersonalPatientsModel?> _resolvePatient() async {
    final existing = widget.patient;
    if (existing != null && (existing.patientId ?? '').isNotEmpty) {
      return existing;
    }
    final patients = ref.read(apimethods).mypatients;
    if (patients.isEmpty) {
      await ref.read(apimethods).getMyPatients();
    }
    final options = ref.read(apimethods).mypatients;
    if (!mounted) return null;
    if (options.isEmpty) {
      AppSnack.info(context, 'No patients yet. Accept an appointment first.');
      return null;
    }
    return showModalBottomSheet<PersonalPatientsModel>(
      context: context,
      backgroundColor: DoctorUi.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Select patient',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final patient = options[index];
                  return ListTile(
                    leading: CircleImage(
                      size: 40,
                      image: patient.patientImage,
                    ),
                    title: Text(patient.patientName ?? 'Patient'),
                    onTap: () => Navigator.pop(context, patient),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addPrescription() async {
    final patient = await _resolvePatient();
    if (!mounted || patient == null || (patient.patientId ?? '').isEmpty) {
      return;
    }

    final prescriptions = await Navigator.push<List<PrescriptionItem>>(
      context,
      MaterialPageRoute(builder: (context) => const AddPrescription()),
    );
    if (prescriptions == null || prescriptions.isEmpty) return;

    setState(() => _saving = true);
    try {
      final doctor = ref.read(apimethods).userAccount;
      final firebaseUser = FirebaseAuth.instance.currentUser;
      final doctorId = doctor?.id ?? firebaseUser?.uid;
      final patientId = patient.patientId!;
      final prescriptionRef =
          FirebaseFirestore.instance.collection('Prescriptions').doc();
      final prescriptionData = {
        'id': prescriptionRef.id,
        'prescriptionId': prescriptionRef.id,
        'patientId': patientId,
        'patientName': patient.patientName,
        'patientImage': patient.patientImage,
        'doctorId': doctorId,
        'doctorName': doctor?.fullname ?? firebaseUser?.displayName,
        'doctorImage': doctor?.pic ?? firebaseUser?.photoURL,
        'items': prescriptions.map((item) => item.toMap()).toList(),
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'createdOn': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      final batch = FirebaseFirestore.instance.batch();
      batch.set(prescriptionRef, prescriptionData);
      batch.set(
        FirebaseFirestore.instance
            .collection('Patients')
            .doc(patientId)
            .collection('Prescriptions')
            .doc(prescriptionRef.id),
        prescriptionData,
        SetOptions(merge: true),
      );
      await batch.commit();
      await CareTeamService.ensureTreatingLink(
        patientId: patientId,
        patientName: patient.patientName ?? 'Patient',
        patientImage: patient.patientImage ?? '',
      );
      if (!mounted) return;
      AppSnack.success(context, 'Prescription saved');
    } catch (e) {
      if (!mounted) return;
      AppSnack.error(context, 'Failed to save prescription.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _stream(String doctorId) {
    final patientId = widget.patient?.patientId;
    if (patientId != null && patientId.isNotEmpty) {
      // Patient subcollection is always readable by treating doctor when
      // doctorId matches; also works offline of top-level list rules.
      return FirebaseFirestore.instance
          .collection('Patients')
          .doc(patientId)
          .collection('Prescriptions')
          .where('doctorId', isEqualTo: doctorId)
          .snapshots();
    }
    return FirebaseFirestore.instance
        .collection('Prescriptions')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final doctorId = FirebaseAuth.instance.currentUser?.uid;
    final patient = widget.patient;
    final title = patient == null
        ? 'Prescriptions'
        : '${patient.patientName ?? 'Patient'} Rx';

    if (doctorId == null) {
      return DoctorScaffold(
        title: title,
        body: const DoctorEmptyState(
          icon: Icons.medication_outlined,
          title: 'Sign in required',
          message: 'Sign in again to view prescriptions.',
        ),
      );
    }

    return DoctorScaffold(
      title: title,
      subtitle: patient == null
          ? 'Medicines you prescribe'
          : 'For this patient',
      floatingActionButton: FloatingActionButton(
        onPressed: _saving ? null : _addPrescription,
        backgroundColor: DoctorUi.primary,
        foregroundColor: Colors.white,
        child: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: DoctorSearchField(
              controller: _searchController,
              hint: 'Search prescriptions',
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _stream(doctorId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  );
                }
                if (snapshot.hasError) {
                  return DoctorEmptyState(
                    icon: Icons.medication_outlined,
                    title: 'Unable to load prescriptions',
                    message:
                        'Check your connection and try again. If this persists, pull to refresh after a full restart.',
                    actionLabel: 'Retry',
                    onAction: () => setState(() {}),
                  );
                }

                final query = _query.toLowerCase();
                final docs = (snapshot.data?.docs ?? []).where((doc) {
                  final data = doc.data();
                  if (query.isEmpty) return true;
                  return _matchesPrescription(data, query);
                }).toList()
                  ..sort((a, b) => _dateValue(
                        b.data()['createdOn'] ?? b.data()['createdAt'],
                      ).compareTo(_dateValue(
                        a.data()['createdOn'] ?? a.data()['createdAt'],
                      )));

                if (docs.isEmpty) {
                  return DoctorEmptyState(
                    icon: Icons.medication_outlined,
                    title: 'No prescriptions yet',
                    message: patient == null
                        ? 'Tap + to write a prescription for a patient.'
                        : 'Add a prescription for this patient when needed.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return _PrescriptionCard(document: docs[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  const _PrescriptionCard({required this.document});

  final QueryDocumentSnapshot<Map<String, dynamic>> document;

  @override
  Widget build(BuildContext context) {
    final data = document.data();
    final items = data['items'] is List ? data['items'] as List : const [];
    final patientName = data['patientName']?.toString() ?? 'Patient';
    final createdOn = _dateValue(data['createdOn'] ?? data['createdAt']);
    final status = data['status']?.toString() ?? 'active';

    return DoctorCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(14, 4, 10, 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          leading: CircleImage(
            size: 42,
            image: data['patientImage']?.toString(),
          ),
          title: Text(
            patientName,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            '${items.length} item${items.length == 1 ? '' : 's'} · ${_formatDate(createdOn)}',
            style: TextStyle(color: DoctorUi.muted, fontSize: 12),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: DoctorUi.primary.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: DoctorUi.primary,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
          children: [
            if (items.isEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'No medicines listed.',
                  style: TextStyle(color: DoctorUi.muted),
                ),
              )
            else
              ...items.map((item) {
                final map = item is Map
                    ? Map<String, dynamic>.from(item)
                    : <String, dynamic>{};
                final medicine = map['medicine'] is Map
                    ? Map<String, dynamic>.from(map['medicine'] as Map)
                    : <String, dynamic>{};
                final medicineName =
                    medicine['medicine']?.toString() ?? 'Medicine';
                final dosage = [medicine['dosage'], medicine['unit']]
                    .where((v) => v != null && v.toString().isNotEmpty)
                    .join('');
                final instruction = map['controller']?.toString() ?? '';
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DoctorUi.fieldBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicineName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (dosage.isNotEmpty || instruction.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (dosage.isNotEmpty) dosage,
                            if (instruction.isNotEmpty) instruction,
                          ].join(' · '),
                          style: TextStyle(
                            color: DoctorUi.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

bool _matchesPrescription(Map<String, dynamic> data, String query) {
  final haystack = StringBuffer()
    ..write(' ${data['patientName'] ?? ''}')
    ..write(' ${data['doctorName'] ?? ''}')
    ..write(' ${data['status'] ?? ''}');
  final items = data['items'];
  if (items is List) {
    for (final item in items) {
      if (item is Map) {
        haystack
          ..write(' ${item['controller'] ?? ''}')
          ..write(' ${item['medicine'] ?? ''}');
      }
    }
  }
  return haystack.toString().toLowerCase().contains(query);
}

DateTime _dateValue(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.fromMillisecondsSinceEpoch(0);
}

String _formatDate(DateTime date) {
  if (date.millisecondsSinceEpoch == 0) return 'Date pending';
  return '${date.day}/${date.month}/${date.year}';
}
