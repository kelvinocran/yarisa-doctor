import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yarisa_doctor/ui/doctor_ui.dart';

/// Allergies, medications, medical history, and personal-doctor care notes.
class PatientHealthRecord extends StatelessWidget {
  const PatientHealthRecord({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.isPersonalDoctor,
  });

  final String patientId;
  final String patientName;
  final bool isPersonalDoctor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DoctorCard(
          color: DoctorUi.primary.withValues(alpha: .05),
          borderColor: DoctorUi.primary.withValues(alpha: .14),
          child: Text(
            isPersonalDoctor
                ? 'You are a personal doctor for $patientName. Allergies, history, and care notes are shared with this patient\'s other personal doctors.'
                : 'Allergies and history are available because you are on this patient\'s care team. Care notes are only written by personal doctors.',
            style: TextStyle(
              color: DoctorUi.muted,
              height: 1.4,
              fontSize: 12.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const DoctorSectionHeader(title: 'Allergies'),
        _SubcollectionList(
          collection: 'Allergies',
          patientId: patientId,
          empty: 'No allergies recorded',
          icon: EneftyIcons.warning_2_outline,
          accent: Colors.red,
          titleOf: (data) =>
              (data['allergy'] ?? data['name'] ?? 'Allergy').toString(),
          subtitleOf: (data) {
            final symptoms = data['symptoms'];
            if (symptoms is List) return symptoms.join(', ');
            return (data['reaction'] ?? data['notes'] ?? '').toString();
          },
        ),
        const SizedBox(height: 16),
        const DoctorSectionHeader(title: 'Medications'),
        _SubcollectionList(
          collection: 'Medications',
          patientId: patientId,
          empty: 'No medications recorded',
          icon: Icons.medication_outlined,
          accent: Colors.teal,
          titleOf: (data) {
            final name = (data['medicine'] ?? data['name'] ?? '').toString();
            final dosage = (data['dosage'] ?? '').toString();
            final unit = (data['unit'] ?? '').toString();
            return '$name $dosage$unit'.trim();
          },
          subtitleOf: (data) =>
              (data['period_to_take'] ?? data['medicine_type'] ?? '')
                  .toString(),
        ),
        const SizedBox(height: 16),
        const DoctorSectionHeader(title: 'Medical history'),
        _SubcollectionList(
          collection: 'MedicalHistory',
          patientId: patientId,
          empty: 'No medical history recorded',
          icon: EneftyIcons.document_text_outline,
          accent: Colors.indigo,
          titleOf: (data) =>
              (data['disease'] ?? data['illness'] ?? data['title'] ?? 'Record')
                  .toString(),
          subtitleOf: (data) => _formatDate(
            data['illness_date'] ?? data['date'] ?? data['createdAt'],
          ),
        ),
        const SizedBox(height: 16),
        DoctorSectionHeader(
          title: 'Care notes',
          actionLabel: isPersonalDoctor ? 'Add note' : null,
          onAction: isPersonalDoctor
              ? () => showClinicalNoteComposer(
                    context,
                    patientId: patientId,
                    patientName: patientName,
                  )
              : null,
        ),
        _CareNotesList(
          patientId: patientId,
          canAdd: isPersonalDoctor,
          patientName: patientName,
        ),
      ],
    );
  }
}

class _SubcollectionList extends StatelessWidget {
  const _SubcollectionList({
    required this.collection,
    required this.patientId,
    required this.empty,
    required this.icon,
    required this.accent,
    required this.titleOf,
    required this.subtitleOf,
  });

  final String collection;
  final String patientId;
  final String empty;
  final IconData icon;
  final Color accent;
  final String Function(Map<String, dynamic>) titleOf;
  final String Function(Map<String, dynamic>) subtitleOf;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('Patients')
          .doc(patientId)
          .collection(collection)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return DoctorCard(
            child: Text(
              'Unable to load $collection. You may not have access yet.',
              style: TextStyle(color: DoctorUi.muted, height: 1.35),
            ),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return DoctorCard(
            child: Row(
              children: [
                Icon(icon, color: DoctorUi.muted, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    empty,
                    style: TextStyle(color: DoctorUi.muted),
                  ),
                ),
              ],
            ),
          );
        }
        return DoctorCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: docs.take(8).map((doc) {
              final data = doc.data();
              final title = titleOf(data);
              final subtitle = subtitleOf(data);
              return ListTile(
                dense: true,
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: accent, size: 18),
                ),
                title: Text(
                  title.isEmpty ? 'Record' : title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: subtitle.trim().isEmpty
                    ? null
                    : Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _CareNotesList extends StatelessWidget {
  const _CareNotesList({
    required this.patientId,
    required this.patientName,
    required this.canAdd,
  });

  final String patientId;
  final String patientName;
  final bool canAdd;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('Patients')
          .doc(patientId)
          .collection('Recommendations')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return DoctorCard(
            child: Text(
              canAdd
                  ? 'Unable to load care notes.'
                  : 'Care notes are shared among this patient\'s personal doctors only.',
              style: TextStyle(color: DoctorUi.muted, height: 1.35),
            ),
          );
        }
        final docs = (snapshot.data?.docs ?? []).toList()
          ..sort((a, b) {
            return _ts(b.data()['createdAt'] ??
                    b.data()['timestamp'] ??
                    b.data()['date'])
                .compareTo(
              _ts(a.data()['createdAt'] ??
                  a.data()['timestamp'] ??
                  a.data()['date']),
            );
          });
        if (docs.isEmpty) {
          return DoctorCard(
            onTap: canAdd
                ? () => showClinicalNoteComposer(
                      context,
                      patientId: patientId,
                      patientName: patientName,
                    )
                : null,
            child: Text(
              canAdd
                  ? 'No care notes yet. Add a report or recommendation for this patient.'
                  : 'No care notes from personal doctors yet.',
              style: TextStyle(color: DoctorUi.muted, height: 1.35),
            ),
          );
        }
        return Column(
          children: docs.take(6).map((doc) {
            final data = doc.data();
            final title = (data['title'] ?? 'Care note').toString();
            final body = (data['description'] ??
                    data['recommendations'] ??
                    data['plan'] ??
                    '')
                .toString();
            final author =
                (data['doctorName'] ?? data['recommendedBy'] ?? 'Doctor')
                    .toString();
            final type = (data['type'] ?? 'recommendation').toString();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DoctorCard(
                onTap: () => _showNoteDetail(context, data),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          type.replaceAll('_', ' '),
                          style: TextStyle(
                            color: DoctorUi.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$author · ${_formatDate(data['createdAt'] ?? data['timestamp'] ?? data['date'])}',
                      style: TextStyle(color: DoctorUi.muted, fontSize: 12),
                    ),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(height: 1.35),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _showNoteDetail(BuildContext context, Map<String, dynamic> data) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DoctorUi.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (data['title'] ?? 'Care note').toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${data['doctorName'] ?? data['recommendedBy'] ?? 'Doctor'} · ${_formatDate(data['createdAt'] ?? data['timestamp'])}',
                  style: TextStyle(color: DoctorUi.muted),
                ),
                const SizedBox(height: 16),
                if ((data['description'] ?? '').toString().isNotEmpty) ...[
                  const Text(
                    'Findings',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(data['description'].toString()),
                  const SizedBox(height: 14),
                ],
                if ((data['recommendations'] ?? '').toString().isNotEmpty) ...[
                  const Text(
                    'Recommendations',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(data['recommendations'].toString()),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

Future<void> showClinicalNoteComposer(
  BuildContext context, {
  required String patientId,
  required String patientName,
}) async {
  final titleController = TextEditingController();
  final findingsController = TextEditingController();
  final recsController = TextEditingController();
  var type = 'recommendation';
  var priority = 'medium';
  var saving = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: DoctorUi.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (sheetContext, setSheet) {
          Future<void> save() async {
            final title = titleController.text.trim();
            final findings = findingsController.text.trim();
            final recs = recsController.text.trim();
            if (title.isEmpty || (findings.isEmpty && recs.isEmpty)) {
              ScaffoldMessenger.of(sheetContext).showSnackBar(
                const SnackBar(
                  content: Text('Add a title and findings or recommendations.'),
                ),
              );
              return;
            }
            setSheet(() => saving = true);
            try {
              final doctor = FirebaseAuth.instance.currentUser;
              final doctorId = doctor?.uid ?? '';
              if (doctorId.isEmpty) return;
              var doctorName = doctor?.displayName ?? 'Doctor';
              var doctorImage = doctor?.photoURL ?? '';
              try {
                final profile = await FirebaseFirestore.instance
                    .collection('Doctors')
                    .doc(doctorId)
                    .get();
                final data = profile.data();
                if ((data?['fullname'] ?? '').toString().trim().isNotEmpty) {
                  doctorName = data!['fullname'].toString();
                }
                if ((data?['pic'] ?? '').toString().trim().isNotEmpty) {
                  doctorImage = data!['pic'].toString();
                }
              } catch (_) {}
              final ref = FirebaseFirestore.instance
                  .collection('Patients')
                  .doc(patientId)
                  .collection('Recommendations')
                  .doc();
              await ref.set({
                'id': ref.id,
                'noteId': ref.id,
                'patientId': patientId,
                'patientName': patientName,
                'doctorId': doctorId,
                'doctorName': doctorName,
                'doctorImage': doctorImage,
                'recommendedBy': doctorName,
                'title': title,
                'description': findings,
                'recommendations': recs,
                'type': type,
                'priority': priority,
                'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                'timestamp': FieldValue.serverTimestamp(),
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              });
              if (sheetContext.mounted) Navigator.pop(sheetContext);
            } catch (e) {
              setSheet(() => saving = false);
              if (sheetContext.mounted) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(content: Text('Could not save note: $e')),
                );
              }
            }
          }

          InputDecoration deco(String label) => InputDecoration(
                labelText: label,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              );

          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Care note',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Visible to $patientName and their other personal doctors.',
                    style: TextStyle(color: DoctorUi.muted, fontSize: 12.5),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final option in const [
                        ('recommendation', 'Recommendation'),
                        ('progress_note', 'Progress note'),
                        ('report', 'Report'),
                        ('care_plan', 'Care plan'),
                      ])
                        ChoiceChip(
                          label: Text(option.$2),
                          selected: type == option.$1,
                          onSelected: (_) => setSheet(() => type = option.$1),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: deco('Title'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: findingsController,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: deco('Findings / summary'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: recsController,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: deco('Recommendations / plan'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: priority,
                    decoration: deco('Priority'),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Routine')),
                      DropdownMenuItem(
                        value: 'medium',
                        child: Text('Important'),
                      ),
                      DropdownMenuItem(value: 'high', child: Text('Urgent')),
                    ],
                    onChanged: (value) {
                      if (value != null) setSheet(() => priority = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: saving ? null : save,
                      child: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save note'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

String _formatDate(dynamic value) {
  final date = _ts(value);
  if (date.millisecondsSinceEpoch == 0) return '';
  return DateFormat.yMMMd().format(date);
}

DateTime _ts(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}
