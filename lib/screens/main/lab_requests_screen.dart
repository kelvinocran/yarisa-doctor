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

class LabRequestsScreen extends ConsumerStatefulWidget {
  const LabRequestsScreen({super.key, this.patient});

  final PersonalPatientsModel? patient;

  @override
  ConsumerState<LabRequestsScreen> createState() => _LabRequestsScreenState();
}

class _LabRequestsScreenState extends ConsumerState<LabRequestsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _saving = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createLabRequest() async {
    final patient = widget.patient;
    if (patient == null || (patient.patientId ?? '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Open a patient before requesting labs.')),
      );
      return;
    }

    final request = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _LabRequestForm(),
    );
    if (request == null) return;

    setState(() => _saving = true);
    try {
      final doctor = ref.read(apimethods).userAccount;
      final firebaseUser = FirebaseAuth.instance.currentUser;
      final doctorId = doctor?.id ?? firebaseUser?.uid;
      final requestRef =
          FirebaseFirestore.instance.collection('LabRequests').doc();
      final data = {
        'id': requestRef.id,
        'requestId': requestRef.id,
        'patientId': patient.patientId,
        'patientName': patient.patientName,
        'patientImage': patient.patientImage,
        'doctorId': doctorId,
        'doctorName': doctor?.fullname ?? firebaseUser?.displayName,
        'doctorImage': doctor?.pic ?? firebaseUser?.photoURL,
        'testName': request['testName'],
        'labName': request['labName'],
        'priority': request['priority'],
        'notes': request['notes'],
        'status': 'requested',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      final batch = FirebaseFirestore.instance.batch();
      batch.set(requestRef, data);
      batch.set(
        FirebaseFirestore.instance
            .collection('Patients')
            .doc(patient.patientId)
            .collection('LabRequests')
            .doc(requestRef.id),
        data,
        SetOptions(merge: true),
      );
      await batch.commit();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lab request created')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create lab request: $e')),
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
        ? 'Laboratories'
        : '${patient.patientName ?? 'Patient'} labs';

    if (doctorId == null) {
      return Scaffold(
        appBar: yarisaAppBar(context, title: title),
        body: const Center(child: Text('Sign in again to view lab requests.')),
      );
    }

    return Scaffold(
      appBar: yarisaAppBar(context, title: title),
      floatingActionButton: patient == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _saving ? null : _createLabRequest,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.science_outlined),
              label: const Text('Request'),
            ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: FormTextField(
              controller: _searchController,
              hint: 'Search lab requests',
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
                  .collection('LabRequests')
                  .where('doctorId', isEqualTo: doctorId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const _EmptyState(
                    icon: Icons.science_outlined,
                    title: 'Unable to load lab requests',
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
                  return _matchesLabRequest(data, query);
                }).toList()
                  ..sort((a, b) => _dateValue(b.data()['createdAt'])
                      .compareTo(_dateValue(a.data()['createdAt'])));

                if (docs.isEmpty) {
                  return _EmptyState(
                    icon: Icons.science_outlined,
                    title: 'No lab requests found',
                    message: patient == null
                        ? 'Lab requests you create for patients will appear here.'
                        : 'Create a lab request for this patient when needed.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: docs.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return _LabRequestTile(document: docs[index]);
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

class _LabRequestTile extends StatelessWidget {
  const _LabRequestTile({required this.document});

  final QueryDocumentSnapshot<Map<String, dynamic>> document;

  @override
  Widget build(BuildContext context) {
    final data = document.data();
    final patientName = data['patientName']?.toString() ?? 'Patient';
    final testName = data['testName']?.toString() ?? 'Lab test';
    final labName = data['labName']?.toString();
    final notes = data['notes']?.toString();

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          backgroundImage:
              safeCachedNetworkImageProvider(data['patientImage']?.toString()),
          child: safeCachedNetworkImageProvider(
                      data['patientImage']?.toString()) ==
                  null
              ? const Icon(EneftyIcons.profile_bold)
              : null,
        ),
        title: Text(testName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(patientName),
            if (labName != null && labName.trim().isNotEmpty) Text(labName),
            if (notes != null && notes.trim().isNotEmpty)
              Text(
                notes,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: _StatusChip(label: data['status']?.toString() ?? 'requested'),
      ),
    );
  }
}

class _LabRequestForm extends StatefulWidget {
  const _LabRequestForm();

  @override
  State<_LabRequestForm> createState() => _LabRequestFormState();
}

class _LabRequestFormState extends State<_LabRequestForm> {
  final _testController = TextEditingController();
  final _labController = TextEditingController();
  final _notesController = TextEditingController();
  String _priority = 'routine';

  @override
  void dispose() {
    _testController.dispose();
    _labController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    final testName = _testController.text.trim();
    if (testName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the lab test name.')),
      );
      return;
    }
    Navigator.pop(context, {
      'testName': testName,
      'labName': _labController.text.trim(),
      'notes': _notesController.text.trim(),
      'priority': _priority,
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Request lab test',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _testController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Test name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _labController,
              decoration: const InputDecoration(
                labelText: 'Preferred laboratory',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _priority,
              decoration: const InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'routine', child: Text('Routine')),
                DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _priority = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Clinical notes',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.science_outlined),
                label: const Text('Create request'),
              ),
            ),
          ],
        ),
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

bool _matchesLabRequest(Map<String, dynamic> data, String query) {
  return [
    data['patientName'],
    data['doctorName'],
    data['testName'],
    data['labName'],
    data['priority'],
    data['status'],
    data['notes'],
  ].whereType<Object>().join(' ').toLowerCase().contains(query);
}

DateTime _dateValue(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.fromMillisecondsSinceEpoch(0);
}
