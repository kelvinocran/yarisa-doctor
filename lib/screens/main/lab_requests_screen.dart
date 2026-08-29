import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yarisa_doctor/api/api_methods.dart';
import 'package:yarisa_doctor/constants/yarisa_constants.dart';
import 'package:yarisa_doctor/models/personal_patients_model.dart';
import 'package:yarisa_doctor/ui/doctor_ui.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No patients yet. Accept an appointment first.'),
        ),
      );
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

  Future<void> _createLabRequest() async {
    final patient = await _resolvePatient();
    if (!mounted || patient == null || (patient.patientId ?? '').isEmpty) {
      return;
    }

    final request = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DoctorUi.surface,
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

  Stream<QuerySnapshot<Map<String, dynamic>>> _stream(String doctorId) {
    final patientId = widget.patient?.patientId;
    if (patientId != null && patientId.isNotEmpty) {
      return FirebaseFirestore.instance
          .collection('Patients')
          .doc(patientId)
          .collection('LabRequests')
          .where('doctorId', isEqualTo: doctorId)
          .snapshots();
    }
    return FirebaseFirestore.instance
        .collection('LabRequests')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final doctorId = FirebaseAuth.instance.currentUser?.uid;
    final patient = widget.patient;
    final title = patient == null
        ? 'Lab requests'
        : '${patient.patientName ?? 'Patient'} labs';

    if (doctorId == null) {
      return DoctorScaffold(
        title: title,
        body: const DoctorEmptyState(
          icon: Icons.science_outlined,
          title: 'Sign in required',
          message: 'Sign in again to view lab requests.',
        ),
      );
    }

    return DoctorScaffold(
      title: title,
      subtitle: patient == null
          ? 'Tests you order for patients'
          : 'Orders for this patient',
      floatingActionButton: FloatingActionButton(
        onPressed: _saving ? null : _createLabRequest,
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
            : const Icon(Icons.science_outlined),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: DoctorSearchField(
              controller: _searchController,
              hint: 'Search lab requests',
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
                    icon: Icons.science_outlined,
                    title: 'Unable to load lab requests',
                    message:
                        'Check your connection and try again after a full restart.',
                    actionLabel: 'Retry',
                    onAction: () => setState(() {}),
                  );
                }

                final query = _query.toLowerCase();
                final docs = (snapshot.data?.docs ?? []).where((doc) {
                  if (query.isEmpty) return true;
                  return _matchesLabRequest(doc.data(), query);
                }).toList()
                  ..sort((a, b) => _dateValue(b.data()['createdAt'])
                      .compareTo(_dateValue(a.data()['createdAt'])));

                if (docs.isEmpty) {
                  return DoctorEmptyState(
                    icon: Icons.science_outlined,
                    title: 'No lab requests yet',
                    message: patient == null
                        ? 'Tap the lab icon to order a test for a patient.'
                        : 'Create a lab request for this patient when needed.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return _LabRequestCard(document: docs[index]);
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

class _LabRequestCard extends StatelessWidget {
  const _LabRequestCard({required this.document});

  final QueryDocumentSnapshot<Map<String, dynamic>> document;

  @override
  Widget build(BuildContext context) {
    final data = document.data();
    final testName = data['testName']?.toString() ?? 'Lab test';
    final patientName = data['patientName']?.toString() ?? 'Patient';
    final labName = data['labName']?.toString() ?? '';
    final priority = data['priority']?.toString() ?? 'routine';
    final status = data['status']?.toString() ?? 'requested';
    final notes = data['notes']?.toString() ?? '';
    final created = _dateValue(data['createdAt']);

    return DoctorCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleImage(size: 42, image: data['patientImage']?.toString()),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      testName,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      patientName,
                      style: TextStyle(color: DoctorUi.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _pill(status, DoctorUi.primary),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (labName.isNotEmpty) _metaChip(Icons.science_outlined, labName),
              _metaChip(Icons.flag_outlined, priority),
              _metaChip(
                Icons.calendar_today_outlined,
                _formatDate(created),
              ),
            ],
          ),
          if (notes.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              notes,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: DoctorUi.muted, fontSize: 12, height: 1.35),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _metaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: DoctorUi.fieldBg,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: DoctorUi.muted),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: DoctorUi.muted,
            ),
          ),
        ],
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
  final _testName = TextEditingController();
  final _labName = TextEditingController();
  final _notes = TextEditingController();
  String _priority = 'routine';

  @override
  void dispose() {
    _testName.dispose();
    _labName.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: .3),
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
              const Text(
                'New lab request',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _testName,
                textCapitalization: TextCapitalization.words,
                decoration: _dec('Test name *'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _labName,
                textCapitalization: TextCapitalization.words,
                decoration: _dec('Preferred lab (optional)'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: _dec('Priority'),
                items: const [
                  DropdownMenuItem(value: 'routine', child: Text('Routine')),
                  DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                  DropdownMenuItem(value: 'stat', child: Text('STAT')),
                ],
                onChanged: (v) => setState(() => _priority = v ?? 'routine'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _notes,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: _dec('Notes (optional)'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_testName.text.trim().isEmpty) return;
                    Navigator.pop(context, {
                      'testName': _testName.text.trim(),
                      'labName': _labName.text.trim(),
                      'priority': _priority,
                      'notes': _notes.text.trim(),
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DoctorUi.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Create request'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: DoctorUi.fieldBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}

bool _matchesLabRequest(Map<String, dynamic> data, String query) {
  return [
    data['testName'],
    data['patientName'],
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

String _formatDate(DateTime date) {
  if (date.millisecondsSinceEpoch == 0) return 'Pending';
  return '${date.day}/${date.month}/${date.year}';
}
