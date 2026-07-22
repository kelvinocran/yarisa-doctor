import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/firestore_schema.dart';
import '../../components/formtextfield.dart';
import '../../constants/yarisa_constants.dart';
import '../../constants/yarisa_enums.dart';
import '../../constants/yarisa_widgets.dart';
import '../../services/jitsi_call_service.dart';
import '../../widgets/skeleton_loader.dart';
import 'chat_inbox_screen.dart';

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
              stream: FirestoreSchema.secondOpinions()
                  .where('doctorId', isEqualTo: doctorId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AppointmentSkeletonList();
                }
                if (snapshot.hasError) {
                  return const _SecondOpinionState(
                    title: 'Unable to load requests',
                    message: 'Please check your connection and try again.',
                  );
                }

                final query = _query.toLowerCase();
                final requests = (snapshot.data?.docs ?? []).where((doc) {
                  if (query.isEmpty) return true;
                  final data = doc.data();
                  return [
                    data['patientName'],
                    data['concern'],
                    data['currentDiagnosis'],
                    data['status'],
                    data['urgency'],
                  ].whereType<Object>().join(' ').toLowerCase().contains(query);
                }).toList();

                if (requests.isEmpty) {
                  return _SecondOpinionState(
                    title: snapshot.data?.docs.isEmpty == true
                        ? 'No second opinions yet'
                        : 'No matching requests',
                    message: snapshot.data?.docs.isEmpty == true
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

class SecondOpinionDetailScreen extends StatelessWidget {
  const SecondOpinionDetailScreen({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirestoreSchema.secondOpinions().doc(requestId).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        return Scaffold(
          appBar: AppBar(title: const Text('Second Opinion')),
          body: data == null
              ? const Center(child: CircularProgressIndicator())
              : _SecondOpinionDetailBody(requestId: requestId, data: data),
        );
      },
    );
  }
}

class _SecondOpinionDetailBody extends StatelessWidget {
  const _SecondOpinionDetailBody({required this.requestId, required this.data});

  final String requestId;
  final Map<String, dynamic> data;

  Future<void> _updateRequest(
    BuildContext context,
    Map<String, dynamic> updates,
  ) async {
    final patientId = data['patientId']?.toString() ?? '';
    final doctorId = data['doctorId']?.toString() ?? '';
    if (patientId.isEmpty || doctorId.isEmpty) return;

    final updateData = {
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final batch = FirebaseFirestore.instance.batch();
    batch.set(
      FirestoreSchema.secondOpinions().doc(requestId),
      updateData,
      SetOptions(merge: true),
    );
    batch.set(
      FirestoreSchema.db
          .collection('Patients')
          .doc(patientId)
          .collection('SecondOpinions')
          .doc(requestId),
      updateData,
      SetOptions(merge: true),
    );
    batch.set(
      FirestoreSchema.doctorDoc(doctorId)
          .collection('SecondOpinions')
          .doc(requestId),
      updateData,
      SetOptions(merge: true),
    );
    await batch.commit();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Second opinion updated')),
      );
    }
  }

  Future<void> _showResponseSheet(BuildContext context) async {
    final responseController = TextEditingController(
      text: data['doctorResponse']?.toString() ?? '',
    );
    bool saving = false;

    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Future<void> saveResponse() async {
              final response = responseController.text.trim();
              if (response.isEmpty) return;
              setSheetState(() => saving = true);
              await _updateRequest(context, {
                'doctorResponse': response,
                'status': 'completed',
                'completedAt': FieldValue.serverTimestamp(),
              });
              await writeDoctorChatMessage(
                patientId: data['patientId']?.toString() ?? '',
                patientName: data['patientName']?.toString() ?? 'Patient',
                patientImage: data['patientImage']?.toString() ?? '',
                message: response,
                type: 'text',
              );
              if (sheetContext.mounted) Navigator.pop(sheetContext);
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Doctor Response',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: responseController,
                    minLines: 5,
                    maxLines: 10,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Write your clinical opinion and next steps',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: saving ? null : saveResponse,
                      child: saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Response'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    } finally {
      responseController.dispose();
    }
  }

  Future<void> _startCall(BuildContext context, String type) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final patientId = data['patientId']?.toString() ?? '';
    if (currentUser == null || patientId.isEmpty) return;

    final joined = await YarisaJitsiCallService.join(
      room: requestId,
      type: type,
      subject: 'Second Opinion',
      displayName: currentUser.displayName ?? 'Doctor',
      avatarUrl: currentUser.photoURL ?? '',
      email: currentUser.email ?? '',
    );
    if (!joined) return;

    await writeDoctorChatMessage(
      patientId: patientId,
      patientName: data['patientName']?.toString() ?? 'Patient',
      patientImage: data['patientImage']?.toString() ?? '',
      message: '',
      type: 'call',
      extra: {'start_time': Timestamp.now(), 'type': type},
    );
  }

  @override
  Widget build(BuildContext context) {
    final patientId = data['patientId']?.toString() ?? '';
    final patientName = data['patientName']?.toString() ?? 'Patient';
    final patientImage = data['patientImage']?.toString() ?? '';
    final response = data['doctorResponse']?.toString().trim() ?? '';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            CircleImage(size: 58, image: patientImage),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patientName,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(_createdAtText(data['createdAt'])),
                ],
              ),
            ),
            _StatusChip(status: data['status']?.toString() ?? 'pending'),
          ],
        ),
        const SizedBox(height: 24),
        _DetailSection(label: 'Concern', value: data['concern']?.toString()),
        _DetailSection(
          label: 'Current Diagnosis',
          value: data['currentDiagnosis']?.toString(),
        ),
        _DetailSection(
          label: 'Medication / Treatment',
          value: data['currentMedication']?.toString(),
        ),
        _DetailSection(
          label: 'Patient Question',
          value: data['patientQuestion']?.toString(),
        ),
        _AttachmentsSection(attachments: data['attachments']),
        if (response.isNotEmpty)
          _DetailSection(label: 'Your Response', value: response),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: patientId.isEmpty
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DoctorMessageThreadScreen(
                            patientId: patientId,
                            patientName: patientName,
                            patientImage: patientImage,
                            roomId: requestId,
                          ),
                        ),
                      ),
              icon: const Icon(EneftyIcons.message_2_outline),
              label: const Text('Chat'),
            ),
            OutlinedButton.icon(
              onPressed: () => _startCall(context, 'voice'),
              icon: const Icon(EneftyIcons.call_outline),
              label: const Text('Voice'),
            ),
            OutlinedButton.icon(
              onPressed: () => _startCall(context, 'video'),
              icon: const Icon(EneftyIcons.video_outline),
              label: const Text('Video'),
            ),
            OutlinedButton.icon(
              onPressed: () => _updateRequest(context, {'status': 'in_review'}),
              icon: const Icon(EneftyIcons.tick_circle_outline),
              label: const Text('Mark In Review'),
            ),
            FilledButton.icon(
              onPressed: () => _showResponseSheet(context),
              icon: const Icon(EneftyIcons.document_text_outline),
              label: const Text('Respond'),
            ),
          ],
        ),
      ],
    );
  }
}

class _AttachmentsSection extends StatelessWidget {
  const _AttachmentsSection({required this.attachments});

  final dynamic attachments;

  @override
  Widget build(BuildContext context) {
    final list = attachments is List ? attachments as List : <dynamic>[];
    if (list.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attachments',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...list.map((att) {
            if (att is! Map) return const SizedBox.shrink();
            final url = att['url']?.toString() ?? '';
            final name = att['name']?.toString() ?? 'Attachment';
            final type = att['type']?.toString() ?? '';
            if (url.isEmpty) return const SizedBox.shrink();

            if (type == 'image') {
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: .2)),
                ),
                clipBehavior: Clip.antiAlias,
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => SizedBox(
                    height: 200,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.broken_image, color: Colors.grey),
                          const SizedBox(height: 8),
                          Text(name, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: const Text('PDF Document'),
              trailing: FilledButton.tonalIcon(
                onPressed: () => launchUrl(
                  Uri.parse(url),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Open'),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final displayValue = value?.trim();
    if (displayValue == null || displayValue.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(displayValue),
          ),
        ],
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

String _createdAtText(dynamic value) {
  DateTime? createdAt;
  if (value is Timestamp) createdAt = value.toDate();
  if (value is DateTime) createdAt = value;
  if (createdAt == null) return 'Date pending';
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
