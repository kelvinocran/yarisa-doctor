import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/formtextfield.dart';
import '../../constants/yarisa_constants.dart';
import '../../constants/yarisa_enums.dart';
import '../../constants/yarisa_widgets.dart';
import '../../services/jitsi_call_service.dart';
import '../../widgets/skeleton_loader.dart';

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
      return const Scaffold(
        body: Center(child: Text("Sign in again to view chats.")),
      );
    }

    return Scaffold(
      appBar: yarisaAppBar(context, title: "Chats"),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: FormTextField(
              controller: _searchController,
              hint: 'Search chats',
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
                  .collection("Messages")
                  .doc(doctorId)
                  .collection("messages")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AppointmentSkeletonList();
                }
                if (snapshot.hasError) {
                  return const _ChatStateMessage(
                    title: "Unable to load chats",
                    message: "Please check your connection and try again.",
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
                    _chatPreview(data),
                  ].whereType<Object>().join(' ').toLowerCase().contains(query);
                }).toList();
                if (chats.isEmpty) {
                  return _ChatStateMessage(
                    title: snapshot.data?.docs.isEmpty == true
                        ? "No chats yet"
                        : "No chats found",
                    message: snapshot.data?.docs.isEmpty == true
                        ? "Patient conversations will appear here."
                        : 'No conversations match "$_query".',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: chats.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection("Patients")
          .doc(chatSummary.id)
          .snapshots(),
      builder: (context, patientSnapshot) {
        final patientData = patientSnapshot.data?.data();
        final summary = chatSummary.data();
        final patientName = patientData?["name"]?.toString() ??
            summary["patientName"]?.toString() ??
            summary["name"]?.toString() ??
            "Patient";
        final patientImage = patientData?["photo"]?.toString() ??
            patientData?["pic"]?.toString() ??
            summary["patientImage"]?.toString() ??
            summary["image"]?.toString() ??
            "";
        final lastMessage = _chatPreview(summary);

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          leading: CircleImage(size: 48, image: patientImage),
          title: Text(
            patientName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DoctorMessageThreadScreen(
                  patientId: chatSummary.id,
                  patientName: patientName,
                  patientImage: patientImage,
                ),
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
        body: Center(child: Text("Sign in again to view this chat.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleImage(size: 38, image: widget.patientImage),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.patientName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          Tooltip(
            message: "Voice call",
            child: IconButton(
              onPressed: () => _startCall("voice"),
              icon: const Icon(EneftyIcons.call_outline),
            ),
          ),
          Tooltip(
            message: "Video call",
            child: IconButton(
              onPressed: () => _startCall("video"),
              icon: const Icon(EneftyIcons.video_outline),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection("Messages")
                  .doc(doctorId)
                  .collection("messages")
                  .doc(widget.patientId)
                  .collection("all")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AppointmentSkeletonList();
                }
                final messages = snapshot.data?.docs ?? [];
                if (messages.isEmpty) {
                  return const _ChatStateMessage(
                    title: "No messages yet",
                    message: "Send a message to start the conversation.",
                  );
                }
                return ListView.separated(
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return _DoctorMessageBubble(data: messages[index].data());
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: "Write a message...",
                        filled: true,
                        fillColor: Colors.grey.withValues(alpha: .12),
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _sendMessage,
                    icon: _sending
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.arrow_upward_rounded),
                  ),
                ],
              ),
            ),
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
        type: "text",
      );
      _messageController.clear();
    } catch (error) {
      Get.snackbar(
        "Message failed",
        "Unable to send this message.",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _startCall(String type) async {
    final doctor = await _doctorChatProfile();
    final joined = await YarisaJitsiCallService.join(
      room: widget.roomId ?? widget.patientId,
      type: type,
      subject: "Patient Appointment",
      displayName: doctor.name,
      avatarUrl: doctor.image,
      email: doctor.email,
    );
    if (!joined) return;

    await writeDoctorChatMessage(
      patientId: widget.patientId,
      patientName: widget.patientName,
      patientImage: widget.patientImage,
      message: "",
      type: "call",
      extra: {"start_time": Timestamp.now(), "type": type},
    );
  }
}

class _DoctorMessageBubble extends StatelessWidget {
  const _DoctorMessageBubble({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final isMe = data["sender"]?.toString() == "recipient";
    final type = data["type"]?.toString() ?? "text";
    final message = type == "call" ? _chatPreview(data) : data["message"];

    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Flexible(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 300),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isMe
                  ? Theme.of(context).primaryColor
                  : Colors.grey.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (type == "call") ...[
                  Icon(
                    EneftyIcons.call_outline,
                    size: 18,
                    color: isMe ? Colors.white : null,
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    message?.toString() ?? "",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isMe ? Colors.white : null,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatStateMessage extends StatelessWidget {
  const _ChatStateMessage({required this.title, required this.message});

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
            Icon(
              EneftyIcons.message_2_outline,
              size: 42,
              color: Colors.grey.withValues(alpha: .8),
            ),
            const SizedBox(height: 12),
            YarisaText(
              text: title,
              type: TextType.bodyBig,
              weight: FontWeight.w600,
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

String _chatPreview(Map<String, dynamic> data) {
  final type = data["type"]?.toString();
  if (type == "call") {
    final callType = data["extra"] is Map
        ? (data["extra"] as Map)["type"]?.toString()
        : null;
    return "${callType == "video" ? "Video" : "Voice"} call";
  }
  final message = data["message"]?.toString().trim();
  if (message == null || message.isEmpty) return "Attachment";
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

  final doctor = await _doctorChatProfile();
  final timestamp = Timestamp.fromDate(DateTime.now());
  final doctorSideMessage = {
    "timestamp": timestamp,
    "sender": "recipient",
    "message": message,
    "id": patientId,
    "name": patientName,
    "image": patientImage,
    "type": type,
    "extra": extra ?? {"file_name": "", "file_type": "", "file_size": ""},
  };
  final patientSideMessage = {
    ...doctorSideMessage,
    "id": doctorId,
    "name": doctor.name,
    "image": doctor.image,
  };

  final doctorThread = FirebaseFirestore.instance
      .collection("Messages")
      .doc(doctorId)
      .collection("messages")
      .doc(patientId);
  final patientThread = FirebaseFirestore.instance
      .collection("Messages")
      .doc(patientId)
      .collection("messages")
      .doc(doctorId);
  final conversationRef = FirebaseFirestore.instance
      .collection("Conversations")
      .doc(_conversationId(patientId, doctorId));
  final canonicalMessageRef = conversationRef.collection("Messages").doc();

  final batch = FirebaseFirestore.instance.batch();
  batch.set(doctorThread, doctorSideMessage, SetOptions(merge: true));
  batch.set(patientThread, patientSideMessage, SetOptions(merge: true));
  batch.set(doctorThread.collection("all").doc(), doctorSideMessage);
  batch.set(patientThread.collection("all").doc(), patientSideMessage);
  batch.set(
    conversationRef,
    {
      "conversationId": conversationRef.id,
      "participants": [patientId, doctorId],
      "patientId": patientId,
      "doctorId": doctorId,
      "lastMessage": type == "call" ? _chatPreview(doctorSideMessage) : message,
      "lastMessageAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    },
    SetOptions(merge: true),
  );
  batch.set(canonicalMessageRef, {
    ...doctorSideMessage,
    "senderId": doctorId,
    "messageId": canonicalMessageRef.id,
    "conversationId": conversationRef.id,
    "createdAt": FieldValue.serverTimestamp(),
  });
  await batch.commit();
}

Future<_DoctorChatProfile> _doctorChatProfile() async {
  final user = FirebaseAuth.instance.currentUser;
  final doctorId = user?.uid ?? "";
  var name = user?.displayName ?? "Doctor";
  var image = user?.photoURL ?? "";
  var email = user?.email ?? "";

  if (doctorId.isNotEmpty) {
    final snapshot = await FirebaseFirestore.instance
        .collection("Doctors")
        .doc(doctorId)
        .get();
    final data = snapshot.data();
    name = data?["fullname"]?.toString() ?? name;
    image = data?["pic"]?.toString() ?? image;
    email = data?["email"]?.toString() ?? email;
  }

  return _DoctorChatProfile(name: name, image: image, email: email);
}

String _conversationId(String firstUserId, String secondUserId) {
  final participantIds = [firstUserId, secondUserId]..sort();
  return participantIds.join('_');
}

class _DoctorChatProfile {
  const _DoctorChatProfile({
    required this.name,
    required this.image,
    required this.email,
  });

  final String name;
  final String image;
  final String email;
}
