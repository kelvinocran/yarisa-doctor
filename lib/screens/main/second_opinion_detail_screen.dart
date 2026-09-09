import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../api/firestore_schema.dart';
import '../../constants/yarisa_constants.dart';
import '../../services/call_permissions.dart';
import '../../services/call_session_service.dart';
import '../../services/jitsi_call_service.dart';
import '../../ui/doctor_ui.dart';
import '../../widgets/app_snack.dart';
import '../../widgets/in_app_media_viewers.dart';
import 'chat_inbox_screen.dart';

class SecondOpinionDetailScreen extends StatelessWidget {
  const SecondOpinionDetailScreen({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context) {
    final doctorId = FirebaseAuth.instance.currentUser?.uid;
    final stream = doctorId == null
        ? FirestoreSchema.secondOpinions().doc(requestId).snapshots()
        : FirestoreSchema.doctorDoc(doctorId)
            .collection('SecondOpinions')
            .doc(requestId)
            .snapshots();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        var data = snapshot.data?.data();
        return DoctorScaffold(
          title: 'Request details',
          subtitle: data?['patientName']?.toString() ?? 'Second opinion',
          body: snapshot.connectionState == ConnectionState.waiting &&
                  data == null
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2.2))
              : data == null
                  ? StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: FirestoreSchema.secondOpinions()
                          .doc(requestId)
                          .snapshots(),
                      builder: (context, topSnap) {
                        final top = topSnap.data?.data();
                        if (top == null) {
                          return const DoctorEmptyState(
                            icon: EneftyIcons.health_outline,
                            title: 'Request not found',
                            message:
                                'This second opinion may have been removed.',
                          );
                        }
                        return _SecondOpinionDetailBody(
                          requestId: requestId,
                          data: top,
                        );
                      },
                    )
                  : _SecondOpinionDetailBody(
                      requestId: requestId,
                      data: data,
                    ),
        );
      },
    );
  }
}

class _SecondOpinionDetailBody extends StatefulWidget {
  const _SecondOpinionDetailBody({
    required this.requestId,
    required this.data,
  });

  final String requestId;
  final Map<String, dynamic> data;

  @override
  State<_SecondOpinionDetailBody> createState() =>
      _SecondOpinionDetailBodyState();
}

class _SecondOpinionDetailBodyState extends State<_SecondOpinionDetailBody> {
  String get requestId => widget.requestId;
  Map<String, dynamic> get data => widget.data;
  late String _status;

  @override
  void initState() {
    super.initState();
    _status = _normalizedStatus(data['status']);
  }

  @override
  void didUpdateWidget(covariant _SecondOpinionDetailBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _normalizedStatus(widget.data['status']);
    if (next != _status) {
      _status = next;
    }
  }

  String _normalizedStatus(dynamic value) {
    return (value ?? 'pending')
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll(' ', '_');
  }

  String _fmt(dynamic ts) {
    if (ts is Timestamp) {
      return DateFormat.yMMMd().add_jm().format(ts.toDate());
    }
    if (ts is DateTime) return DateFormat.yMMMd().add_jm().format(ts);
    return '';
  }

  bool _isPdf(Map<String, dynamic> map) {
    final type = map['type']?.toString().toLowerCase() ?? '';
    final name = map['name']?.toString().toLowerCase() ?? '';
    final url = map['url']?.toString().toLowerCase() ?? '';
    return type.contains('pdf') ||
        name.endsWith('.pdf') ||
        url.contains('.pdf');
  }

  bool _isImage(Map<String, dynamic> map) {
    final type = map['type']?.toString().toLowerCase() ?? '';
    final name = map['name']?.toString().toLowerCase() ?? '';
    if (type.contains('image') || type.contains('photo')) return true;
    return name.endsWith('.png') ||
        name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.webp') ||
        name.endsWith('.heic');
  }

  void _openAttachment(BuildContext context, Map<String, dynamic> map) {
    final url = map['url']?.toString() ?? '';
    final name = map['name']?.toString() ?? 'Attachment';
    if (url.isEmpty || url.startsWith('Error')) {
      AppSnack.info(context, 'This file is not available yet.');
      return;
    }
    if (_isImage(map)) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DoctorImageViewer(url: url)),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DoctorPdfViewer(url: url, title: name),
      ),
    );
  }

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
    try {
      await batch.commit();
    } catch (e) {
      if (context.mounted) {
        AppSnack.error(context, 'Could not update this request.');
      }
      rethrow;
    }

    if (updates['status'] != null) {
      final next = _normalizedStatus(updates['status']);
      if (mounted && next != _status) {
        setState(() => _status = next);
      }
    }

    if (context.mounted) {
      final status = updates['status']?.toString();
      AppSnack.success(
        context,
        status == 'in_review'
            ? 'Marked in review. The patient will be notified.'
            : status == 'completed'
                ? 'Response sent. The patient will be notified.'
                : 'Second opinion updated.',
      );
    }
  }

  Future<void> _showResponseSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: DoctorUi.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _ResponseSheet(
        initialText: data['doctorResponse']?.toString() ?? '',
        onSave: (response) async {
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
            extra: {
              'secondOpinionId': requestId,
              'contextType': 'second_opinion',
            },
          );
        },
      ),
    );
  }

  Future<void> _startCall(BuildContext context, String type) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final patientId = data['patientId']?.toString() ?? '';
    if (currentUser == null || patientId.isEmpty) return;

    final permitted = await CallPermissions.ensureBeforeCall(
      video: type.toLowerCase() == 'video',
    );
    if (!permitted) return;

    final room = YarisaJitsiCallService.secondOpinionRoom(requestId);
    final patientName = data['patientName']?.toString() ?? 'Patient';
    final patientImage = data['patientImage']?.toString() ?? '';

    await writeDoctorChatMessage(
      patientId: patientId,
      patientName: patientName,
      patientImage: patientImage,
      message: '',
      type: 'call',
      room: room,
      extra: {
        'start_time': Timestamp.now(),
        'type': type,
        'room': room,
        'secondOpinionId': requestId,
        'contextType': 'second_opinion',
      },
    );

    await CallSessionService.start(
      room: room,
      peerId: patientId,
      callType: type,
      direction: 'outbound',
      peerName: patientName,
    );

    await YarisaJitsiCallService.join(
      room: room,
      type: type,
      subject: 'Second Opinion',
      displayName: currentUser.displayName ?? 'Doctor',
      avatarUrl: currentUser.photoURL ?? '',
      email: currentUser.email ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final patientId = data['patientId']?.toString() ?? '';
    final patientName = data['patientName']?.toString() ?? 'Patient';
    final patientImage = data['patientImage']?.toString() ?? '';
    final status = _status;
    final concern = data['concern']?.toString() ?? '';
    final diagnosis = data['currentDiagnosis']?.toString() ?? '';
    final medication = data['currentMedication']?.toString() ?? '';
    final question = data['patientQuestion']?.toString() ?? '';
    final response = data['doctorResponse']?.toString().trim() ?? '';
    final urgency = data['urgency']?.toString() ?? 'standard';
    final attachments = (data['attachments'] as List<dynamic>?) ?? [];
    final created = _fmt(data['createdAt']);
    final isUrgent = urgency == 'urgent';
    final isOpen = status != 'completed' && status != 'declined';
    final inReview = status == 'in_review' ||
        status == 'in-progress' ||
        status == 'in_progress';

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            children: [
              _DetailHeroCard(
                patientName: patientName,
                patientImage: patientImage,
                createdLabel: created,
                status: status,
                isUrgent: isUrgent,
              ),
              const SizedBox(height: 12),
              if (response.isNotEmpty)
                _DetailCard(
                  icon: EneftyIcons.message_text_outline,
                  title: 'Your response',
                  trailing: 'Edit',
                  onTrailing: () => _showResponseSheet(context),
                  child: Text(
                    response,
                    style: theme.bodyMedium?.copyWith(height: 1.45),
                  ),
                )
              else
                _DetailCard(
                  icon: EneftyIcons.timer_outline,
                  title: inReview
                      ? 'In review'
                      : 'Waiting for your review',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inReview
                            ? 'The patient has been notified that you are reviewing this request. Add your opinion when you are ready.'
                            : 'Write a clinical opinion for this patient. They will see it on their request and in chat.',
                        style: theme.bodyMedium?.copyWith(
                          height: 1.4,
                          color: DoctorUi.muted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: FilledButton.icon(
                          onPressed: () => _showResponseSheet(context),
                          icon: const Icon(
                            EneftyIcons.document_text_outline,
                            size: 16,
                          ),
                          label: const Text('Respond'),
                        ),
                      ),
                      if (isOpen && !inReview) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              try {
                                await _updateRequest(
                                  context,
                                  {'status': 'in_review'},
                                );
                              } catch (_) {}
                            },
                            icon: const Icon(
                              EneftyIcons.tick_circle_outline,
                              size: 16,
                            ),
                            label: const Text('Mark in review'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              _DetailCard(
                icon: EneftyIcons.health_outline,
                title: 'Patient request',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldBlock(label: 'Concern', value: concern),
                    _FieldBlock(
                      label: 'Current diagnosis',
                      value: diagnosis,
                    ),
                    _FieldBlock(
                      label: 'Current medication',
                      value: medication,
                    ),
                    _FieldBlock(
                      label: 'Patient question',
                      value: question,
                      last: true,
                    ),
                  ],
                ),
              ),
              if (attachments.isNotEmpty) ...[
                const SizedBox(height: 12),
                _DetailCard(
                  icon: EneftyIcons.document_text_outline,
                  title: 'Attachments',
                  trailing: '${attachments.length}',
                  child: Column(
                    children: [
                      for (var i = 0; i < attachments.length; i++) ...[
                        if (i > 0) const SizedBox(height: 8),
                        _DetailAttachmentTile(
                          map: attachments[i] is Map
                              ? Map<String, dynamic>.from(
                                  attachments[i] as Map,
                                )
                              : const {},
                          isPdf: _isPdf,
                          isImage: _isImage,
                          onOpen: (map) => _openAttachment(context, map),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (patientId.isNotEmpty)
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                color: DoctorUi.surface,
                border: Border(
                  top: BorderSide(color: DoctorUi.border),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DoctorMessageThreadScreen(
                            patientId: patientId,
                            patientName: patientName,
                            patientImage: patientImage,
                            roomId: YarisaJitsiCallService.secondOpinionRoom(
                              requestId,
                            ),
                            contextLabel: 'Second opinion',
                            secondOpinionId: requestId,
                          ),
                        ),
                      ),
                      icon: const Icon(EneftyIcons.message_2_outline, size: 16),
                      label: const Text('Chat'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _startCall(context, 'voice'),
                      icon: const Icon(EneftyIcons.call_outline, size: 16),
                      label: const Text('Call'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'Video call',
                    onPressed: () => _startCall(context, 'video'),
                    icon: const Icon(EneftyIcons.video_outline, size: 18),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ResponseSheet extends StatefulWidget {
  const _ResponseSheet({
    required this.initialText,
    required this.onSave,
  });

  final String initialText;
  final Future<void> Function(String response) onSave;

  @override
  State<_ResponseSheet> createState() => _ResponseSheetState();
}

class _ResponseSheetState extends State<_ResponseSheet> {
  late final TextEditingController _controller;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final response = _controller.text.trim();
    if (response.isEmpty) {
      AppSnack.info(context, 'Write your clinical opinion first.');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSave(response);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your response',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'The patient will see this on their request and in chat.',
            style: TextStyle(color: DoctorUi.muted, fontSize: 12.5),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            minLines: 5,
            maxLines: 10,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Write your clinical opinion and next steps',
              filled: true,
              fillColor: DoctorUi.fieldBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: DoctorUi.border),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save response'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailHeroCard extends StatelessWidget {
  const _DetailHeroCard({
    required this.patientName,
    required this.patientImage,
    required this.createdLabel,
    required this.status,
    required this.isUrgent,
  });

  final String patientName;
  final String patientImage;
  final String createdLabel;
  final String status;
  final bool isUrgent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return DoctorCard(
      child: Row(
        children: [
          CircleImage(size: 56, image: patientImage),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patientName,
                  style: theme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                if (createdLabel.isNotEmpty)
                  Text(
                    createdLabel,
                    style: theme.bodySmall?.copyWith(
                      color: DoctorUi.muted,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _StatusPill(status: status),
              if (isUrgent) ...[
                const SizedBox(height: 6),
                Text(
                  'Urgent',
                  style: theme.bodySmall?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
    this.onTrailing,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final String? trailing;
  final VoidCallback? onTrailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return DoctorCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: DoctorUi.primary.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: DoctorUi.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              if (trailing != null)
                onTrailing == null
                    ? Text(
                        trailing!,
                        style: theme.bodySmall?.copyWith(
                          color: DoctorUi.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : TextButton(
                        onPressed: onTrailing,
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          trailing!,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _FieldBlock extends StatelessWidget {
  const _FieldBlock({
    required this.label,
    required this.value,
    this.last = false,
  });

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.bodySmall?.copyWith(
              color: DoctorUi.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: theme.bodyMedium?.copyWith(height: 1.4)),
        ],
      ),
    );
  }
}

class _DetailAttachmentTile extends StatelessWidget {
  const _DetailAttachmentTile({
    required this.map,
    required this.isPdf,
    required this.isImage,
    required this.onOpen,
  });

  final Map<String, dynamic> map;
  final bool Function(Map<String, dynamic>) isPdf;
  final bool Function(Map<String, dynamic>) isImage;
  final void Function(Map<String, dynamic>) onOpen;

  @override
  Widget build(BuildContext context) {
    final name = map['name']?.toString() ?? 'Attachment';
    final url = map['url']?.toString() ?? '';
    final pdf = isPdf(map);
    final image = isImage(map);
    final ready = url.isNotEmpty && !url.startsWith('Error');

    return Material(
      color: DoctorUi.fieldBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: ready ? () => onOpen(map) : null,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: image && ready
                      ? CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Icon(
                            EneftyIcons.gallery_outline,
                            color: DoctorUi.primary,
                          ),
                        )
                      : ColoredBox(
                          color: DoctorUi.primary.withValues(alpha: .1),
                          child: Icon(
                            pdf
                                ? EneftyIcons.document_text_outline
                                : EneftyIcons.document_outline,
                            color: DoctorUi.primary,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      !ready
                          ? 'Unavailable'
                          : image
                              ? 'Tap to view photo'
                              : pdf
                                  ? 'Tap to view PDF'
                                  : 'Tap to open',
                      style: TextStyle(
                        fontSize: 12,
                        color: DoctorUi.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                ready
                    ? EneftyIcons.eye_outline
                    : EneftyIcons.info_circle_outline,
                size: 18,
                color: DoctorUi.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'completed' => Colors.green,
      'in_review' => Colors.blue,
      'declined' => Colors.red,
      _ => Colors.amber.shade800,
    };
    final label = status.replaceAll('_', ' ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        label.isEmpty
            ? 'Pending'
            : '${label[0].toUpperCase()}${label.substring(1)}',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
