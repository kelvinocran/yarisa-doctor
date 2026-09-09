import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../api/firestore_schema.dart';
import '../../components/formtextfield.dart';
import '../../constants/yarisa_constants.dart';
import '../../constants/yarisa_enums.dart';
import '../../constants/yarisa_widgets.dart';
import '../../widgets/skeleton_loader.dart';
import 'second_opinion_detail_screen.dart';

export 'second_opinion_detail_screen.dart';

class SecondOpinionsScreen extends StatefulWidget {
  const SecondOpinionsScreen({super.key});

  @override
  State<SecondOpinionsScreen> createState() => _SecondOpinionsScreenState();
}

class _SecondOpinionsScreenState extends State<SecondOpinionsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctorId = FirebaseAuth.instance.currentUser?.uid;
    if (doctorId == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in again to view requests.')),
      );
    }

    return Scaffold(
      appBar: yarisaAppBar(context, title: 'Second Opinions'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: FormTextField(
              controller: _searchController,
              hint: 'Search second opinions',
              radius: 100,
              labeled: false,
              autoFocus: false,
              icon: EneftyIcons.search_normal_2_outline,
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              // Prefer doctor-owned subcollection (always readable by owner).
              stream: FirestoreSchema.doctorDoc(doctorId)
                  .collection('SecondOpinions')
                  .snapshots(),
              builder: (context, doctorSnap) {
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  // Top-level collection as fallback / dual-write path.
                  // No orderBy here — avoids composite-index failures; sort client-side.
                  stream: FirestoreSchema.secondOpinions()
                      .where('doctorId', isEqualTo: doctorId)
                      .snapshots(),
                  builder: (context, topSnap) {
                    final waiting =
                        doctorSnap.connectionState == ConnectionState.waiting &&
                            topSnap.connectionState == ConnectionState.waiting;
                    if (waiting) {
                      return const AppointmentSkeletonList();
                    }

                    final bothFailed =
                        doctorSnap.hasError && topSnap.hasError;
                    if (bothFailed) {
                      return const _SecondOpinionState(
                        title: 'Unable to load requests',
                        message:
                            'Check your connection and try again after a full restart.',
                      );
                    }

                    final docs =
                        <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
                    if (!doctorSnap.hasError) {
                      for (final d in doctorSnap.data?.docs ?? []) {
                        docs[d.id] = d;
                      }
                    }
                    if (!topSnap.hasError) {
                      for (final d in topSnap.data?.docs ?? []) {
                        docs[d.id] = d;
                      }
                    }

                    final query = _query.toLowerCase();
                    final requests = docs.values.where((doc) {
                      if (query.isEmpty) return true;
                      final data = doc.data();
                      return [
                        data['patientName'],
                        data['concern'],
                        data['currentDiagnosis'],
                        data['status'],
                        data['urgency'],
                      ]
                          .whereType<Object>()
                          .join(' ')
                          .toLowerCase()
                          .contains(query);
                    }).toList()
                      ..sort((a, b) {
                        final aAt = _soDate(a.data()['createdAt']);
                        final bAt = _soDate(b.data()['createdAt']);
                        return bAt.compareTo(aAt);
                      });

                    if (requests.isEmpty) {
                      return _SecondOpinionState(
                        title: docs.isEmpty
                            ? 'No second opinions yet'
                            : 'No matching requests',
                        message: docs.isEmpty
                            ? 'Patient second opinion requests will appear here.'
                            : 'Try another search term.',
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      itemCount: requests.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) =>
                          _SecondOpinionCard(snapshot: requests[index]),
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
}

class _SecondOpinionCard extends StatelessWidget {
  const _SecondOpinionCard({required this.snapshot});

  final QueryDocumentSnapshot<Map<String, dynamic>> snapshot;

  @override
  Widget build(BuildContext context) {
    final data = snapshot.data();
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              SecondOpinionDetailScreen(requestId: snapshot.id),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withValues(alpha: .2)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleImage(size: 48, image: data['patientImage']?.toString()),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      YarisaText(
                        text: data['patientName']?.toString() ?? 'Patient',
                        type: TextType.bodyBig,
                        weight: FontWeight.w700,
                      ),
                      YarisaText(
                        text: _createdAtText(data['createdAt']),
                        type: TextType.bodySmall,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: data['status']?.toString() ?? 'pending'),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              data['concern']?.toString() ?? '',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (data['urgency']?.toString() == 'urgent') ...[
              const SizedBox(height: 10),
              const Text(
                'Urgent',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
              ),
            ],
            _attachmentCount(data['attachments']),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'completed' => Colors.green,
      'in_review' => Colors.blue,
      'declined' => Colors.red,
      _ => Colors.amber.shade800,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        status.replaceAll('_', ' ').capitalizeFirst ?? status,
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SecondOpinionState extends StatelessWidget {
  const _SecondOpinionState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              EneftyIcons.health_outline,
              size: 46,
              color: Colors.grey.withValues(alpha: .8),
            ),
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
              align: TextAlign.center,
              lines: 3,
            ),
          ],
        ),
      ),
    );
  }
}

DateTime _soDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.fromMillisecondsSinceEpoch(0);
}

String _createdAtText(dynamic value) {
  final createdAt = _soDate(value);
  if (createdAt.millisecondsSinceEpoch == 0) return 'Date pending';
  return DateFormat('MMM d, y • h:mm a').format(createdAt);
}

Widget _attachmentCount(dynamic attachments) {
  final count = attachments is List ? attachments.length : 0;
  if (count == 0) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      children: [
        const Icon(Icons.attach_file, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          '$count attachment${count == 1 ? '' : 's'}',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    ),
  );
}
