import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yarisa_doctor/components/chat/chat_widgets.dart';
import 'package:yarisa_doctor/constants/yarisa_constants.dart';
import 'package:yarisa_doctor/services/call_permissions.dart';
import 'package:yarisa_doctor/services/jitsi_call_service.dart';
import 'package:yarisa_doctor/services/presence_service.dart';
import 'package:yarisa_doctor/ui/doctor_ui.dart';
import 'package:yarisa_doctor/widgets/skeleton_loader.dart';

class DoctorChatInboxScreen extends StatefulWidget {
  const DoctorChatInboxScreen({super.key});

  @override
  State<DoctorChatInboxScreen> createState() => _DoctorChatInboxScreenState();
}

class _DoctorChatInboxScreenState extends State<DoctorChatInboxScreen> {
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
      return const DoctorScaffold(
        title: 'Chats',
        // Always pushed from FAB / deep links — keep back visible.
        showBack: true,
        body: DoctorEmptyState(
          icon: EneftyIcons.message_2_outline,
          title: 'Sign in required',
          message: 'Sign in again to view chats.',
        ),
      );
    }

    return DoctorScaffold(
      title: 'Chats',
      subtitle: 'Patient conversations',
      showBack: true,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: DoctorSearchField(
              controller: _searchController,
              hint: 'Search chats',
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('Messages')
                  .doc(doctorId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AppointmentSkeletonList();
                }
                if (snapshot.hasError) {
                  return const DoctorEmptyState(
                    icon: EneftyIcons.warning_2_outline,
                    title: 'Unable to load chats',
                    message: 'Check your connection and try again.',
                  );
                }

                final query = _query.toLowerCase();
                final chats = (snapshot.data?.docs ?? []).where((doc) {
                  if (query.isEmpty) return true;
                  final data = doc.data();
                  return [
                    doc.id,
                    data['patientName'],
                    data['name'],
                    data['message'],
                    doctorChatPreview(data),
                  ].whereType<Object>().join(' ').toLowerCase().contains(query);
                }).toList();

                if (chats.isEmpty) {
                  return DoctorEmptyState(
                    icon: EneftyIcons.message_2_outline,
                    title: snapshot.data?.docs.isEmpty == true
                        ? 'No chats yet'
                        : 'No chats found',
                    message: snapshot.data?.docs.isEmpty == true
                        ? 'Patient conversations will appear here.'
                        : 'No conversations match "$_query".',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: chats.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return _PatientChatTile(chatSummary: chats[index]);
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

class _PatientChatTile extends StatelessWidget {
  const _PatientChatTile({required this.chatSummary});

  final QueryDocumentSnapshot<Map<String, dynamic>> chatSummary;

  void _openThread(
    BuildContext context, {
    required String patientName,
    required String patientImage,
  }) {
    final me = FirebaseAuth.instance.currentUser?.uid;
    final peerId = chatSummary.id;

    // Navigate first — never await Firestore before push.
    Get.to(
      () => DoctorMessageThreadScreen(
        patientId: peerId,
        patientName: patientName,
        patientImage: patientImage,
      ),
      transition: Transition.cupertino,
      duration: const Duration(milliseconds: 220),
    );

    if (me != null) {
      FirebaseFirestore.instance
          .collection('Messages')
          .doc(me)
          .collection('messages')
          .doc(peerId)
          .set({
        'unread': false,
        'unreadCount': 0,
      }, SetOptions(merge: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = chatSummary.data();
    final fallbackName = summary['patientName']?.toString() ??
        summary['name']?.toString() ??
        'Patient';
    final fallbackImage = summary['patientImage']?.toString() ??
        summary['image']?.toString() ??
        '';
    final lastMessage = doctorChatPreview(summary);
    final ts = summary['timestamp'];
    final time = ts is Timestamp ? ts.toDate() : null;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('Patients')
          .doc(chatSummary.id)
          .snapshots(),
      builder: (context, patientSnapshot) {
        final patientData = patientSnapshot.data?.data();
        final patientName = patientData?['name']?.toString() ?? fallbackName;
        final patientImage = patientData?['photo']?.toString() ??
            patientData?['pic']?.toString() ??
            fallbackImage;

        return StreamBuilder<bool>(
          stream: PresenceService.watchOnline(
            collection: 'Patients',
            userId: chatSummary.id,
          ),
          builder: (context, onlineSnap) {
            final isOnline = onlineSnap.data == true;
            return ChatThreadTile(
              name: patientName,
              image: patientImage,
              preview: lastMessage,
              timestamp: time,
              isOnline: isOnline,
              onTap: () => _openThread(
                context,
                patientName: patientName,
                patientImage: patientImage,
              ),
            );
          },
        );
      },
    );
  }
}

class DoctorMessageThreadScreen extends StatefulWidget {
  const DoctorMessageThreadScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.patientImage,
    this.roomId,
  });

  final String patientId;
  final String patientName;
  final String patientImage;
  final String? roomId;

  @override
  State<DoctorMessageThreadScreen> createState() =>
      _DoctorMessageThreadScreenState();
}

class _DoctorMessageThreadScreenState extends State<DoctorMessageThreadScreen> {
  final _messageController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctorId = FirebaseAuth.instance.currentUser?.uid;
    if (doctorId == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in again to view this chat.')),
      );
    }

    return Scaffold(
      backgroundColor: DoctorUi.scaffoldBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: DoctorUi.scaffoldBg,
        surfaceTintColor: DoctorUi.scaffoldBg,
        titleSpacing: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Get.back();
            }
          },
        ),
        title: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleImage(size: 38, image: widget.patientImage),
                StreamBuilder<bool>(
                  stream: PresenceService.watchOnline(
                    collection: 'Patients',
                    userId: widget.patientId,
                  ),
                  builder: (context, snap) {
                    if (snap.data != true) return const SizedBox.shrink();
                    return Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: DoctorUi.scaffoldBg,
                            width: 1.5,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.patientName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  StreamBuilder<bool>(
                    stream: PresenceService.watchOnline(
                      collection: 'Patients',
                      userId: widget.patientId,
                    ),
                    builder: (context, snap) {
                      final online = snap.data == true;
                      return Text(
                        online ? 'Online' : 'Patient',
                        style: TextStyle(
                          fontSize: 11,
                          color: online
                              ? const Color(0xFF22C55E)
                              : DoctorUi.muted,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Voice call',
            onPressed: () => _startCall('voice'),
            icon: const Icon(EneftyIcons.call_outline),
          ),
          IconButton(
            tooltip: 'Video call',
            onPressed: () => _startCall('video'),
            icon: const Icon(EneftyIcons.video_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('Messages')
                  .doc(doctorId)
                  .collection('messages')
                  .doc(widget.patientId)
                  .collection('all')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AppointmentSkeletonList();
                }
                final messages = snapshot.data?.docs ?? [];
                if (messages.isEmpty) {
                  return const DoctorEmptyState(
                    icon: EneftyIcons.message_2_outline,
                    title: 'No messages yet',
                    message: 'Send a message to start the conversation.',
                  );
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data();
                    final isMe = data['sender']?.toString() == 'recipient';
                    final type = data['type']?.toString() ?? 'text';
                    final text = type == 'call'
                        ? doctorChatPreview(data)
                        : (data['message']?.toString() ?? '');
                    final ts = data['timestamp'];
                    final time = ts is Timestamp ? ts.toDate() : null;
                    return ChatBubble(
                      text: type == 'call' ? '📞 $text' : text,
                      isMine: isMe,
                      timestamp: time,
                    );
                  },
                );
              },
            ),
          ),
          ChatComposer(
            controller: _messageController,
            sending: _sending,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    try {
      await writeDoctorChatMessage(
        patientId: widget.patientId,
        patientName: widget.patientName,
        patientImage: widget.patientImage,
        message: text,
        type: 'text',
      );
      _messageController.clear();
    } catch (_) {
      Get.snackbar(
        'Message failed',
        'Unable to send this message.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _startCall(String type) async {
    final ok = await CallPermissions.ensureBeforeCall(
      video: type.toLowerCase() == 'video',
    );
    if (!ok) return;

    final doctor = await doctorChatProfile();
    final doctorId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final room = (widget.roomId != null && widget.roomId!.isNotEmpty)
        ? widget.roomId!
        : YarisaJitsiCallService.conversationRoom(doctorId, widget.patientId);

    // Notify patient (FCM + CallKit) before joining Jitsi.
    await writeDoctorChatMessage(
      patientId: widget.patientId,
      patientName: widget.patientName,
      patientImage: widget.patientImage,
      message: '',
      type: 'call',
      extra: {'start_time': Timestamp.now(), 'type': type},
    );

    await YarisaJitsiCallService.join(
      room: room,
      type: type,
      subject: 'Patient Appointment',
      displayName: doctor.name,
      avatarUrl: doctor.image,
      email: doctor.email,
    );
  }
}

String doctorChatPreview(Map<String, dynamic> data) {
  final type = data['type']?.toString();
  if (type == 'call') {
    final callType = data['extra'] is Map
        ? (data['extra'] as Map)['type']?.toString()
        : null;
    return '${callType == 'video' ? 'Video' : 'Voice'} call';
  }
  final message = data['message']?.toString().trim();
  if (message == null || message.isEmpty) return 'Attachment';
  return message;
}

Future<void> writeDoctorChatMessage({
  required String patientId,
  required String patientName,
  required String patientImage,
  required String message,
  required String type,
  Map<String, dynamic>? extra,
}) async {
  final doctorId = FirebaseAuth.instance.currentUser?.uid;
  if (doctorId == null) return;

  final doctor = await doctorChatProfile();
  final timestamp = Timestamp.fromDate(DateTime.now());
  final callKind = extra?['type']?.toString() ?? 'voice';
  final displayMessage = type == 'call'
      ? (callKind == 'video' ? 'Video call' : 'Voice call')
      : message;
  final doctorSideMessage = {
    'timestamp': timestamp,
    'sender': 'recipient',
    'message': displayMessage,
    'id': patientId,
    'name': patientName,
    'image': patientImage,
    'type': type,
    'extra': extra ?? {'file_name': '', 'file_type': '', 'file_size': ''},
  };
  final patientSideMessage = {
    ...doctorSideMessage,
    'id': doctorId,
    'name': doctor.name,
    'image': doctor.image,
  };

  final doctorThread = FirebaseFirestore.instance
      .collection('Messages')
      .doc(doctorId)
      .collection('messages')
      .doc(patientId);
  final patientThread = FirebaseFirestore.instance
      .collection('Messages')
      .doc(patientId)
      .collection('messages')
      .doc(doctorId);
  final conversationRef = FirebaseFirestore.instance
      .collection('Conversations')
      .doc(_conversationId(patientId, doctorId));
  final canonicalMessageRef = conversationRef.collection('Messages').doc();

  final batch = FirebaseFirestore.instance.batch();
  // Sender thread: clear unread for self.
  batch.set(
    doctorThread,
    {
      ...doctorSideMessage,
      'unread': false,
      'unreadCount': 0,
    },
    SetOptions(merge: true),
  );
  // Recipient thread: mark unread for badge.
  batch.set(
    patientThread,
    {
      ...patientSideMessage,
      'unread': true,
      'unreadCount': FieldValue.increment(1),
    },
    SetOptions(merge: true),
  );
  batch.set(doctorThread.collection('all').doc(), doctorSideMessage);
  batch.set(patientThread.collection('all').doc(), patientSideMessage);
  batch.set(
    conversationRef,
    {
      'conversationId': conversationRef.id,
      'participants': [patientId, doctorId],
      'patientId': patientId,
      'doctorId': doctorId,
      'lastMessage': displayMessage,
      'lastMessageType': type,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    },
    SetOptions(merge: true),
  );
  batch.set(canonicalMessageRef, {
    ...doctorSideMessage,
    'senderId': doctorId,
    'doctorId': doctorId,
    'patientId': patientId,
    'messageId': canonicalMessageRef.id,
    'conversationId': conversationRef.id,
    'createdAt': FieldValue.serverTimestamp(),
    if (type == 'call') 'isCall': true,
  });
  await batch.commit();
}

Future<DoctorChatProfile> doctorChatProfile() async {
  final user = FirebaseAuth.instance.currentUser;
  final doctorId = user?.uid ?? '';
  var name = user?.displayName ?? 'Doctor';
  var image = user?.photoURL ?? '';
  var email = user?.email ?? '';

  if (doctorId.isNotEmpty) {
    final snapshot = await FirebaseFirestore.instance
        .collection('Doctors')
        .doc(doctorId)
        .get();
    final data = snapshot.data();
    name = data?['fullname']?.toString() ?? name;
    image = data?['pic']?.toString() ?? image;
    email = data?['email']?.toString() ?? email;
  }

  return DoctorChatProfile(name: name, image: image, email: email);
}

String _conversationId(String firstUserId, String secondUserId) {
  final participantIds = [firstUserId, secondUserId]..sort();
  return participantIds.join('_');
}

class DoctorChatProfile {
  const DoctorChatProfile({
    required this.name,
    required this.image,
    required this.email,
  });

  final String name;
  final String image;
  final String email;
}
