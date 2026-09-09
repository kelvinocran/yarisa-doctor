import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yarisa_doctor/ui/doctor_ui.dart';

enum PatientChartSection { allergies, medications, history, notes }

class PatientChartListScreen extends StatefulWidget {
  const PatientChartListScreen({
    super.key,
    required this.section,
    required this.patientId,
    required this.patientName,
    this.canAddNotes = false,
    this.onAddNote,
  });

  final PatientChartSection section;
  final String patientId;
  final String patientName;
  final bool canAddNotes;
  final VoidCallback? onAddNote;

  @override
  State<PatientChartListScreen> createState() => _PatientChartListScreenState();
}

class _PatientChartListScreenState extends State<PatientChartListScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String get _title => switch (widget.section) {
        PatientChartSection.allergies => 'Allergies',
        PatientChartSection.medications => 'Medications',
        PatientChartSection.history => 'Medical history',
        PatientChartSection.notes => 'Care notes',
      };

  String get _collection => switch (widget.section) {
        PatientChartSection.allergies => 'Allergies',
        PatientChartSection.medications => 'Medications',
        PatientChartSection.history => 'MedicalHistory',
        PatientChartSection.notes => 'Recommendations',
      };

  IconData get _icon => switch (widget.section) {
        PatientChartSection.allergies => EneftyIcons.warning_2_outline,
        PatientChartSection.medications => Icons.medication_outlined,
        PatientChartSection.history => EneftyIcons.document_text_outline,
        PatientChartSection.notes => EneftyIcons.note_2_outline,
      };

  Color get _accent => switch (widget.section) {
        PatientChartSection.allergies => Colors.red,
        PatientChartSection.medications => Colors.teal,
        PatientChartSection.history => Colors.indigo,
        PatientChartSection.notes => Colors.deepPurple,
      };

  @override
  Widget build(BuildContext context) {
    return DoctorScaffold(
      title: _title,
      subtitle: widget.patientName,
      floatingActionButton: widget.section == PatientChartSection.notes &&
              widget.canAddNotes
          ? FloatingActionButton.extended(
              onPressed: widget.onAddNote,
              backgroundColor: DoctorUi.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add note'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: DoctorSearchField(
              controller: _search,
              hint: 'Search $_title…',
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('Patients')
                  .doc(widget.patientId)
                  .collection(_collection)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return DoctorEmptyState(
                    icon: _icon,
                    title: 'Unable to load',
                    message: widget.section == PatientChartSection.notes &&
                            !widget.canAddNotes
                        ? 'Care notes are shared among this patient\'s personal doctors only.'
                        : 'Check your connection and try again.',
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  );
                }
                final q = _query.toLowerCase();
                final docs = (snapshot.data?.docs ?? []).where((doc) {
                  if (q.isEmpty) return true;
                  return doc
                      .data()
                      .values
                      .whereType<Object>()
                      .join(' ')
                      .toLowerCase()
                      .contains(q);
                }).toList()
                  ..sort((a, b) {
                    return _ts(b.data()['createdAt'] ??
                            b.data()['timestamp'] ??
                            b.data()['illness_date'] ??
                            b.data()['date'])
                        .compareTo(
                      _ts(a.data()['createdAt'] ??
                          a.data()['timestamp'] ??
                          a.data()['illness_date'] ??
                          a.data()['date']),
                    );
                  });

                if (docs.isEmpty) {
                  return DoctorEmptyState(
                    icon: _icon,
                    title: q.isEmpty ? 'Nothing here yet' : 'No matches',
                    message: q.isEmpty
                        ? 'Records for $_title will show here.'
                        : 'No items match "$_query".',
                    actionLabel: widget.section == PatientChartSection.notes &&
                            widget.canAddNotes
                        ? 'Add note'
                        : null,
                    onAction: widget.section == PatientChartSection.notes &&
                            widget.canAddNotes
                        ? widget.onAddNote
                        : null,
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    return DoctorCard(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PatientChartItemScreen(
                            section: widget.section,
                            title: _itemTitle(data),
                            data: data,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _accent.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(_icon, color: _accent, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _itemTitle(data),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (_itemSubtitle(data).isNotEmpty)
                                  Text(
                                    _itemSubtitle(data),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: DoctorUi.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: DoctorUi.muted,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _itemTitle(Map<String, dynamic> data) {
    return switch (widget.section) {
      PatientChartSection.allergies =>
        (data['allergy'] ?? data['name'] ?? 'Allergy').toString(),
      PatientChartSection.medications =>
        '${data['medicine'] ?? data['name'] ?? ''} ${data['dosage'] ?? ''}${data['unit'] ?? ''}'
            .trim(),
      PatientChartSection.history =>
        (data['disease'] ?? data['illness'] ?? data['title'] ?? 'Record')
            .toString(),
      PatientChartSection.notes =>
        (data['title'] ?? 'Care note').toString(),
    };
  }

  String _itemSubtitle(Map<String, dynamic> data) {
    return switch (widget.section) {
      PatientChartSection.allergies => data['symptoms'] is List
          ? (data['symptoms'] as List).join(', ')
          : (data['reaction'] ?? data['notes'] ?? '').toString(),
      PatientChartSection.medications =>
        (data['period_to_take'] ?? data['medicine_type'] ?? '').toString(),
      PatientChartSection.history => _fmt(
          data['illness_date'] ?? data['date'] ?? data['createdAt'],
        ),
      PatientChartSection.notes =>
        '${data['doctorName'] ?? data['recommendedBy'] ?? 'Doctor'} · ${_fmt(data['createdAt'] ?? data['timestamp'])}',
    };
  }
}

class PatientChartItemScreen extends StatelessWidget {
  const PatientChartItemScreen({
    super.key,
    required this.section,
    required this.title,
    required this.data,
  });

  final PatientChartSection section;
  final String title;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final fields = _fields();
    return DoctorScaffold(
      title: title,
      subtitle: switch (section) {
        PatientChartSection.allergies => 'Allergy',
        PatientChartSection.medications => 'Medication',
        PatientChartSection.history => 'Medical history',
        PatientChartSection.notes => 'Care note',
      },
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          DoctorCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < fields.length; i++) ...[
                  if (i > 0) const SizedBox(height: 14),
                  Text(
                    fields[i].$1,
                    style: TextStyle(
                      color: DoctorUi.muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fields[i].$2,
                    style: const TextStyle(height: 1.4),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<(String, String)> _fields() {
    String text(dynamic value) {
      if (value == null) return '';
      if (value is Timestamp) {
        return DateFormat.yMMMd().add_jm().format(value.toDate());
      }
      if (value is DateTime) return DateFormat.yMMMd().add_jm().format(value);
      if (value is List) return value.join(', ');
      return value.toString().trim();
    }

    final pairs = switch (section) {
      PatientChartSection.allergies => [
          ('Allergy', text(data['allergy'] ?? data['name'])),
          ('Symptoms / reaction', text(data['symptoms'] ?? data['reaction'])),
          ('Notes', text(data['notes'])),
        ],
      PatientChartSection.medications => [
          ('Medicine', text(data['medicine'] ?? data['name'])),
          ('Dosage', '${text(data['dosage'])}${text(data['unit'])}'),
          ('How to take', text(data['period_to_take'])),
          ('Type', text(data['medicine_type'])),
        ],
      PatientChartSection.history => [
          ('Condition', text(data['disease'] ?? data['illness'] ?? data['title'])),
          ('Date', text(data['illness_date'] ?? data['date'])),
          ('Treatment', text(data['medicines'] ?? data['treatment'])),
          ('Notes', text(data['notes'] ?? data['description'])),
        ],
      PatientChartSection.notes => [
          ('Title', text(data['title'])),
          ('Type', text(data['type']).replaceAll('_', ' ')),
          ('Doctor', text(data['doctorName'] ?? data['recommendedBy'])),
          ('Findings', text(data['description'])),
          ('Recommendations', text(data['recommendations'])),
          ('Priority', text(data['priority'])),
          ('Date', text(data['createdAt'] ?? data['timestamp'] ?? data['date'])),
        ],
    };
    return pairs.where((pair) => pair.$2.isNotEmpty).toList();
  }
}

DateTime _ts(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}

String _fmt(dynamic value) {
  final date = _ts(value);
  if (date.millisecondsSinceEpoch == 0) return '';
  return DateFormat.yMMMd().format(date);
}
