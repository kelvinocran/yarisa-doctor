import 'dart:convert';
import 'dart:io';

import 'package:enefty_icons/enefty_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:images_picker/images_picker.dart';
import 'package:lottie/lottie.dart';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:uicons/uicons.dart';
import 'package:yarisa_doctor/constants/yarisa_assets.dart';

import '../../components/formtextfield.dart';
import '../models/chat_model.dart';
import '../providers/chat_provider.dart';
import '../services/mqtt_listener.dart';
import '../services/mqtt_service.dart';

class ChatView extends ConsumerStatefulWidget {
  const ChatView({
    super.key,
    required this.patientId,
    this.patientName,
  });

  final String patientId;
  final String? patientName;

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView>
    implements MQTTMessageListener {
  final messageBox = TextEditingController();

  @override
  void initState() {
    super.initState();
    mqttForUser();
  }

  @override
  void dispose() {
    MQTTService.instance.unregisterListener(this);
    super.dispose();
  }

  @override
  Future<void> onMessageReceived(String payloadJson) async {
    final data = jsonDecode(payloadJson);
    if (mounted) {
      if (data['data_type'] == 'chat') {
        final chat = Chat.fromMQTT((data['data']));

        if (chat.senderId != FirebaseAuth.instance.currentUser?.uid) {
          await ref.read(chatconfig).saveChat(chat.senderId!, chat);
        }
      } else {
        if (data['sender_id'] != FirebaseAuth.instance.currentUser?.uid) {
          ref.read(chatconfig).changeTyingStatus(data['status']);
        }
      }
    }
  }

  mqttForUser() async {
    MQTTService.instance.registerListener(this);

    try {
      await MQTTService.instance.connect();
    } on NoConnectionException catch (e) {
      debugPrint(e.toString());
      MQTTService.instance.connect();
    }
  }

  final isTyping = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          actions: [
            IconButton(
              icon: const Icon(EneftyIcons.video_outline),
              // style: IconButton.styleFrom(
              //     shape: const StadiumBorder(),
              //     iconSize: 20,
              //     backgroundColor: Get.isDarkMode
              //         ? Colors.grey.shade800
              //         : Colors.grey.shade200),
              onPressed: () {
                // _joinMeeting("video");
              },
            ),
            IconButton(
              icon: const Icon(EneftyIcons.call_outline),
              // style: IconButton.styleFrom(
              //     iconSize: 20,
              //     shape: const StadiumBorder(),
              //     backgroundColor: Get.isDarkMode
              //         ? Colors.grey.shade800
              //         : Colors.grey.shade200),
              onPressed: () {
                // _joinMeeting("voice");
              },
            ),
            const SizedBox(
              width: 8,
            )
          ],
          // leading: IconButton(
          //     onPressed: () async {
          //       Navigator.pop(context);
          //     },
          //     icon: const Icon(Icons.close)),
          title: Text(
            "${widget.patientName}",
            style:
                Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
          )),
      bottomNavigationBar: SafeArea(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Row(
            children: [
              IconButton(
                onPressed: () async {
                  showModalBottomSheet(
                      context: context,
                      builder: (context) {
                        return SafeArea(
                            child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: OverflowBar(
                            // overflowSpacing: 10,
                            // mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                onTap: () async {
                                  FilePickerResult? result =
                                      await FilePicker.platform.pickFiles(
                                          allowedExtensions: ["pdf"],
                                          type: FileType.custom);

                                  if (result != null) {
                                    File file = File(result.files.single.path!);

                                    // await sendMedia(MessageType.file,
                                    //     result.files.single.path!, file);
                                  } else {
                                    // User canceled the picker
                                  }
                                },
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15)),
                                tileColor: Colors.transparent,
                                leading: Icon(UIcons.regularRounded.document),
                                title: const Text("Send Report"),
                              ),
                              ListTile(
                                onTap: () async {
                                  //select medicine, add instructions
                                },
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15)),
                                tileColor: Colors.transparent,
                                leading: Icon(UIcons.regularRounded.medicine),
                                title: const Text("Prescribe Drug"),
                              ),
                              ListTile(
                                onTap: () async {
                                  List<Media>? res = await ImagesPicker.pick(
                                      count: 1,
                                      pickType: PickType.image,
                                      cropOpt: CropOption());
                                  if (res != null) {
                                    File file = File(res.first.path);

                                    // await sendMedia(MessageType.image,
                                    //     res.first.path, file);
                                  }
                                },
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15)),
                                tileColor: Colors.transparent,
                                leading: Icon(UIcons.regularRounded.picture),
                                title: const Text("Send a photo"),
                              )
                            ],
                          ),
                        ));
                      });
                },
                icon: const Icon(
                  EneftyIcons.paperclip_outline,
                  color: Colors.grey,
                ),
              ),
              Expanded(
                child: FormTextField(
                    labeled: false,
                    radius: 20,
                    isDense: true,
                    vpadding: 17,
                    onChanged: (p0) {
                      if (p0.isNotEmpty) {
                        isTyping.value = true;
                        final builder = MqttClientPayloadBuilder();
                        builder.addString(jsonEncode({
                          "type": "typing",
                          "sender_id": FirebaseAuth.instance.currentUser?.uid,
                          "status": true
                        }));
                        MQTTService.instance.client.publishMessage(
                            "${MQTTService.MQTT_UNIQUE_TOPIC_NAME}/chats/${widget.patientId}",
                            MqttQos.atLeastOnce,
                            builder.payload!);
                      } else {
                        isTyping.value = false;
                        final builder = MqttClientPayloadBuilder();
                        builder.addString(jsonEncode({
                          "type": "typing",
                          "sender_id": FirebaseAuth.instance.currentUser?.uid,
                          "status": false
                        }));
                        MQTTService.instance.client.publishMessage(
                            "${MQTTService.MQTT_UNIQUE_TOPIC_NAME}/chats/${widget.patientId}",
                            MqttQos.atLeastOnce,
                            builder.payload!);
                      }
                    },
                    action: TextInputAction.send,
                    capitalization: TextCapitalization.sentences,
                    outlineColor: Colors.transparent,
                    controller: messageBox,
                    hint: "Write a message..."),
              ),
              ValueListenableBuilder(
                  valueListenable: isTyping,
                  builder: (context, istyping, _) {
                    return AnimatedCrossFade(
                        crossFadeState: !istyping
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 200),
                        firstChild: IconButton(
                          // padding: EdgeInsets.zero,
                          style: ButtonStyle(
                              backgroundColor:
                                  WidgetStateProperty.resolveWith((states) {
                                if (states.contains(WidgetState.disabled)) {
                                  return Colors.grey;
                                }
                                return Theme.of(context).primaryColor;
                              }),
                              foregroundColor:
                                  WidgetStateProperty.resolveWith((states) {
                                if (states.contains(WidgetState.disabled)) {
                                  return Colors.grey;
                                }
                                return Colors.white;
                              }),
                              shape:
                                  const WidgetStatePropertyAll(CircleBorder())),
                          onPressed: () {
                            if (messageBox.text.trim().isNotEmpty) {
                              sendMessage();
                            }
                          },
                          icon: const Icon(
                            Icons.arrow_upward_rounded,
                            color: Colors.white,
                          ),
                        ),
                        secondChild: const SizedBox(
                          width: 10,
                        ));
                  }),
            ],
          ).paddingSymmetric(horizontal: 5, vertical: 5),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: StreamBuilder(
                  stream: ref.read(chatconfig).chatStream(widget.patientId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox.shrink();
                    }
                    if (!snapshot.hasData || snapshot.data?.exists == false) {
                      return const SizedBox.shrink();
                    }

                    final chatList = snapshot.data?["chat"] as List<dynamic>;

                    final chats = chatList.map((e) => Chat.fromMap(e)).toList();

                    return ListView.separated(
                      separatorBuilder: (context, index) => const SizedBox(
                        height: 5,
                      ),
                      reverse: true,
                      padding: const EdgeInsets.all(10),
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        final convo = chats.reversed.toList()[index];
                        return Row(
                          mainAxisAlignment: convo.senderId !=
                                  FirebaseAuth.instance.currentUser?.uid
                              ? MainAxisAlignment.start
                              : MainAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Container(
                                constraints:
                                    const BoxConstraints(maxWidth: 300),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15.0, vertical: 15),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: convo.senderId !=
                                            FirebaseAuth
                                                .instance.currentUser?.uid
                                        ? Colors.grey.withOpacity(.2)
                                        : Theme.of(context).primaryColor),
                                child: Text(
                                  "${convo.message}",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          color: convo.senderId !=
                                                  FirebaseAuth
                                                      .instance.currentUser?.uid
                                              ? null
                                              : Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  }),
            ),
            Consumer(
              builder: (context, ref, _) {
                final chat = ref.watch(chatconfig);
                if (chat.istyping) {
                  return Container(
                      margin: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.grey.withOpacity(.2)),
                      child: Lottie.asset(YarisaAssets.typinganim,
                          width: 50, height: 50));
                }
                return const SizedBox.shrink();
              },
            )
          ],
        ),
      ),
    );
  }

  Future<void> sendMessage() async {
    final builders = MqttClientPayloadBuilder();
    builders.addString(jsonEncode({
      "data_type": "typing",
      "sender_id": FirebaseAuth.instance.currentUser?.uid,
      "status": false
    }));
    MQTTService.instance.client.publishMessage(
        "${MQTTService.MQTT_UNIQUE_TOPIC_NAME}/chats/${widget.patientId}",
        MqttQos.atLeastOnce,
        builders.payload!);

    final map = {
      'message': Uint8List.fromList(utf8.encode(messageBox.text.trim())),
      'recipientId': widget.patientId,
      'senderId': FirebaseAuth.instance.currentUser?.uid,
      'senderName': "",
      'recipientName': widget.patientName,
      'date': DateTime.now().millisecondsSinceEpoch,
      'isMe': true,
    };

    final chat = Chat.fromMQTT(map);

    // await ref.read(chatconfig).getChat("Rider ID");
    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode({"data_type": "chat", "data": map}));
    MQTTService.instance.client.publishMessage(
        "${MQTTService.MQTT_UNIQUE_TOPIC_NAME}/chats/${widget.patientId}",
        MqttQos.atLeastOnce,
        builder.payload!);
    messageBox.clear();
    await ref.read(chatconfig).saveChat(widget.patientId, chat);
  }
}

Future<void> showPopupMenu(
    BuildContext context, details, List<PopupMenuEntry> items) async {
  double left = details.globalPosition.dx;
  double top = details.globalPosition.dy;
  await showMenu(
      context: context,
      position:
          RelativeRect.fromLTRB(left, top, Get.width - left, Get.height - top),
      elevation: 10,
      color: Get.isDarkMode ? Colors.grey.shade900 : Colors.white,
      surfaceTintColor: Get.isDarkMode ? Colors.grey.shade900 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      items: items);
}
