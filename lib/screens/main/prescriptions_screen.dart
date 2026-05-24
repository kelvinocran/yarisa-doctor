import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_methods.dart';
import '../../components/formtextfield.dart';
import '../../constants/yarisa_enums.dart';
import '../../constants/yarisa_widgets.dart';
import '../../models/personal_patients_model.dart';
import '../add_prescription.dart';

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

  Future<void> _addPrescription() async {
    final patient = widget.patient;
    if (patient == null || (patient.patientId ?? '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Open a patient before prescribing.')),
      );
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prescription saved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save prescription: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctorId = FirebaseAuth.instance.currentUser?.uid;
    final patient = widget.patient;
    final title = patient == null
        ? 'Prescriptions'
        : '${patient.patientName ?? 'Patient'} prescriptions';

    if (doctorId == null) {
      return Scaffold(
        appBar: yarisaAppBar(context, title: title),
        body: const Center(child: Text('Sign in again to view prescriptions.')),
      );
    }

    return Scaffold(
      appBar: yarisaAppBar(context, title: title),
      floatingActionButton: patient == null
          ? null
          : FloatingActionButton(
              onPressed: _saving ? null : _addPrescription,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
            ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: FormTextField(
              controller: _searchController,
              hint: 'Search prescriptions',
              radius: 100,
              labeled: false,
              autoFocus: false,
              icon: EneftyIcons.search_normal_2_outline,
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('Prescriptions')
                  .where('doctorId', isEqualTo: doctorId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const _EmptyState(
                    icon: Icons.medication_outlined,
                    title: 'Unable to load prescriptions',
                    message: 'Please check your connection and try again.',
                  );
                }

                final query = _query.toLowerCase();
                final docs = (snapshot.data?.docs ?? []).where((doc) {
                  final data = doc.data();
                  if (patient != null &&
                      data['patientId']?.toString() != patient.patientId) {
                    return false;
                  }
                  if (query.isEmpty) return true;
                  return _matchesPrescription(data, query);
                }).toList()
                  ..sort((a, b) => _dateValue(
                        b.data()['createdOn'] ?? b.data()['createdAt'],
                      ).compareTo(_dateValue(
                        a.data()['createdOn'] ?? a.data()['createdAt'],
                      )));

                if (docs.isEmpty) {
                  return _EmptyState(
                    icon: Icons.medication_outlined,
                    title: 'No prescriptions found',
                    message: patient == null
                        ? 'Prescriptions created for your patients will appear here.'
                        : 'Add a prescription for this patient when needed.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: docs.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return _PrescriptionTile(document: docs[index]);
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

class _PrescriptionTile extends StatelessWidget {
  const _PrescriptionTile({required this.document});

  final QueryDocumentSnapshot<Map<String, dynamic>> document;

  @override
  Widget build(BuildContext context) {
    final data = document.data();
    final items = data['items'] is List ? data['items'] as List : const [];
    final patientName = data['patientName']?.toString() ?? 'Patient';
    final createdOn = _dateValue(data['createdOn'] ?? data['createdAt']);

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundImage: safeCachedNetworkImageProvider(
            data['patientImage']?.toString(),
          ),
          child: safeCachedNetworkImageProvider(
                      data['patientImage']?.toString()) ==
                  null
              ? const Icon(EneftyIcons.profile_bold)
              : null,
        ),
        title: Text(patientName),
        subtitle: Text(
          '${items.length} item${items.length == 1 ? '' : 's'} • ${_formatDate(createdOn)}',
        ),
        trailing: _StatusChip(label: data['status']?.toString() ?? 'active'),
        children: [
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('No medicines added.'),
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
                  .where(
                      (value) => value != null && value.toString().isNotEmpty)
                  .join('');
              final instruction = map['controller']?.toString() ?? '';
              return ListTile(
                title: Text(medicineName),
                subtitle: Text(
                  [
                    if (dosage.isNotEmpty) dosage,
                    if (instruction.isNotEmpty) instruction,
                  ].join(' • '),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      labelStyle: Theme.of(context).textTheme.labelSmall,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: Colors.grey),
            const SizedBox(height: 12),
            YarisaText(
              text: title,
              type: TextType.bodyBig,
              weight: FontWeight.w700,
              align: TextAlign.center,
            ),
            const SizedBox(height: 6),
            YarisaText(
              text: message,
              type: TextType.bodySmall,
              color: Colors.grey,
              lines: 3,
              align: TextAlign.center,
            ),
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
