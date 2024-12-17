import 'dart:convert';
import 'dart:io';
// import 'dart:io';

import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_pdf_viewer/easy_pdf_viewer.dart';

import 'package:enefty_icons/enefty_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:images_picker/images_picker.dart';
import 'package:lottie/lottie.dart';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:path/path.dart';
import 'package:uicons/uicons.dart';
import 'package:yarisa_doctor/constants/yarisa_assets.dart';
import 'package:yarisa_doctor/constants/yarisa_colors.dart';
import 'package:yarisa_doctor/providers/app_provider.dart';
import 'package:yarisa_doctor/screens/add_prescription.dart';

import '../../components/formtextfield.dart';
import '../models/chat_model.dart';
import '../providers/chat_provider.dart';
import '../services/mqtt_listener.dart';
import '../services/mqtt_service.dart';

final isSendingFile = ValueNotifier<bool>(false);

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

    AppProvider().getMedicines();
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
    return ValueListenableBuilder(
        valueListenable: isSendingFile,
        builder: (context, isUploading, _) {
          return Scaffold(
            appBar: AppBar(
                bottom: isUploading
                    ? PreferredSize(
                        preferredSize: const Size(double.infinity, 30),
                        child: FadeIn(
                          child: Container(
                            height: 30,
                            width: double.infinity,
                            alignment: Alignment.center,
                            child: Column(children: [
                              Text(
                                "Uploading File...",
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const Spacer(),
                              const LinearProgressIndicator(
                                minHeight: 2,
                              )
                            ]),
                          ),
                        ))
                    : null,
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
                title: Text(
                  "${widget.patientName}",
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontSize: 16),
                )),
            bottomNavigationBar: SafeArea(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Row(
                  children: [
                    ValueListenableBuilder(
                        valueListenable: meds,
                        builder: (context, medicines, _) {
                          return IconButton(
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
                                                  await FilePicker.platform
                                                      .pickFiles(
                                                          allowedExtensions: [
                                                    "pdf"
                                                  ],
                                                          type:
                                                              FileType.custom);

                                              if (result != null) {
                                                File file = File(
                                                    result.files.single.path!);

                                                await sendMedia(
                                                    MessageType.file,
                                                    result.files.single.path!,
                                                    file);
                                              } else {
                                                // User canceled the picker
                                              }
                                            },
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(15)),
                                            tileColor: Colors.transparent,
                                            leading: Icon(
                                                UIcons.regularRounded.document),
                                            title: const Text("Send Report"),
                                          ),
                                          ListTile(
                                            onTap: () async {
                                              Navigator.pop(context);
                                              final data = await Get.to(() =>
                                                  const AddPrescription());

                                              print(data);
                                              await sendPrescription(
                                                  MessageType.prescription,
                                                  data);
                                            },
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(15)),
                                            tileColor: Colors.transparent,
                                            leading: Icon(
                                                UIcons.regularRounded.medicine),
                                            title: const Text("Prescribe Drug"),
                                          ),
                                          ListTile(
                                            onTap: () async {
                                              List<Media>? res =
                                                  await ImagesPicker.pick(
                                                      count: 1,
                                                      pickType: PickType.image,
                                                      cropOpt: CropOption());
                                              if (res != null) {
                                                File file =
                                                    File(res.first.path);

                                                await sendMedia(
                                                    MessageType.image,
                                                    res.first.path,
                                                    file);
                                              }
                                            },
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(15)),
                                            tileColor: Colors.transparent,
                                            leading: Icon(
                                                UIcons.regularRounded.picture),
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
                          );
                        }),
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
                                "sender_id":
                                    FirebaseAuth.instance.currentUser?.uid,
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
                                "sender_id":
                                    FirebaseAuth.instance.currentUser?.uid,
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
                                        WidgetStateProperty.resolveWith(
                                            (states) {
                                      if (states
                                          .contains(WidgetState.disabled)) {
                                        return Colors.grey;
                                      }
                                      return Theme.of(context).primaryColor;
                                    }),
                                    foregroundColor:
                                        WidgetStateProperty.resolveWith(
                                            (states) {
                                      if (states
                                          .contains(WidgetState.disabled)) {
                                        return Colors.grey;
                                      }
                                      return Colors.white;
                                    }),
                                    shape: const WidgetStatePropertyAll(
                                        CircleBorder())),
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
                        stream:
                            ref.read(chatconfig).chatStream(widget.patientId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox.shrink();
                          }
                          if (!snapshot.hasData ||
                              snapshot.data?.exists == false) {
                            return const SizedBox.shrink();
                          }

                          final chatList =
                              snapshot.data?["chat"] as List<dynamic>;

                          final chats =
                              chatList.map((e) => Chat.fromMap(e)).toList();

                          return ListView.separated(
                            separatorBuilder: (context, index) =>
                                const SizedBox(
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
                                    child: switch (convo.type) {
                                      MessageType.image =>
                                        ImageMessageItem(convo: convo),
                                      MessageType.file =>
                                        FileMessageItem(convo: convo),
                                      MessageType.text =>
                                        TextMessageItem(convo: convo),
                                      MessageType.prescription =>
                                        PrescriptionMessageItem(convo: convo),
                                      null => const SizedBox(),
                                    },
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
        });
  }

  Future sendMedia(MessageType type, String path, File file) async {
    try {
      isSendingFile.value = true;
      final stats = await file.readAsBytes();
      final byte = stats.lengthInBytes;
      final kilobyte = (stats.lengthInBytes / 1000);
      final megabyte = ((stats.lengthInBytes / 1000) / 1000);
      final gigabyte = (((stats.lengthInBytes / 1000) / 1000) / 1000);
      String filesize = (byte > 1000 && kilobyte < 1000)
          ? "${kilobyte.round()} KB"
          : (kilobyte > 1000)
              ? "${megabyte.toStringAsFixed(1)} MB"
              : (megabyte > 999)
                  ? "${gigabyte.toStringAsFixed(1)} GB"
                  : "${stats.lengthInBytes} Bytes";

      String filename = basename(file.path);
      String fileext = file.path.split(".").last;
      final map = {
        'message': "",
        'recipientId': widget.patientId,
        'senderId': FirebaseAuth.instance.currentUser?.uid,
        'senderName': "",
        'recipientName': widget.patientName,
        'date': DateTime.now().millisecondsSinceEpoch,
        'isMe': true,
        'type': type.name,
        "extra": {
          "file_name": filename,
          'file_type': fileext,
          "file_size": filesize
        }
      };
      final fileurl = await uploadImage(File(path), "Messages");
      map.update("message", (val) => fileurl);
      //   final chat = Chat.fromMQTT(map);
      final builder = MqttClientPayloadBuilder();
      builder.addString(jsonEncode({"data_type": "chat", "data": map}));
      MQTTService.instance.client.publishMessage(
          "${MQTTService.MQTT_UNIQUE_TOPIC_NAME}/chats/${widget.patientId}",
          MqttQos.atLeastOnce,
          builder.payload!);

      await ref.read(chatconfig).saveOtherChat(widget.patientId, map);
      isSendingFile.value = false;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      isSendingFile.value = false;
    }
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
      'type': MessageType.text.name,
      'recipientName': widget.patientName,
      'date': DateTime.now().millisecondsSinceEpoch,
      'isMe': true,
    };

    final chat = Chat.fromMQTT(map);

    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode({"data_type": "chat", "data": map}));
    MQTTService.instance.client.publishMessage(
        "${MQTTService.MQTT_UNIQUE_TOPIC_NAME}/chats/${widget.patientId}",
        MqttQos.atLeastOnce,
        builder.payload!);
    messageBox.clear();
    await ref.read(chatconfig).saveChat(widget.patientId, chat);
  }

  Future<void> sendPrescription(
      MessageType type, List<PrescriptionItem> prescriptions) async {
    final map = {
      'message': "",
      'recipientId': widget.patientId,
      'senderId': FirebaseAuth.instance.currentUser?.uid,
      'senderName': "",
      'recipientName': widget.patientName,
      'date': DateTime.now().millisecondsSinceEpoch,
      'isMe': true,
      'type': type.name,
      "prescription": {"data": prescriptions.map((e) => e.toMap()).toList()}
    };

    // final builder = MqttClientPayloadBuilder();
    // builder.addString(jsonEncode({"data_type": "chat", "data": map}));

    // MQTTService.instance.client.publishMessage(
    //     "${MQTTService.MQTT_UNIQUE_TOPIC_NAME}/chats/${widget.patientId}",
    //     MqttQos.atLeastOnce,
    //     builder.payload!);

    await ref.read(chatconfig).saveOtherChat(widget.patientId, map);
  }
}

class TextMessageItem extends StatelessWidget {
  const TextMessageItem({
    super.key,
    required this.convo,
  });

  final Chat convo;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 15),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: convo.senderId != FirebaseAuth.instance.currentUser?.uid
              ? Colors.grey.withOpacity(.2)
              : Theme.of(context).primaryColor),
      child: Text(
        "${convo.message}",
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: convo.senderId != FirebaseAuth.instance.currentUser?.uid
                ? null
                : Colors.white),
      ),
    );
  }
}

class ImageMessageItem extends StatelessWidget {
  const ImageMessageItem({
    super.key,
    required this.convo,
  });

  final Chat convo;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      constraints: const BoxConstraints(maxWidth: 300, maxHeight: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
      ),
      child: GestureDetector(
        onTap: () {
          showDialog(
              context: context,
              builder: (context) {
                return Dialog.fullscreen(
                  backgroundColor: Colors.transparent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                foregroundColor: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
                                backgroundColor:
                                    Theme.of(context).scaffoldBackgroundColor),
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Close")),
                      ),
                      CachedNetworkImage(
                        imageUrl: "${convo.message}",
                        placeholder: (context, url) => const Center(
                          child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              )),
                        ),
                      ),
                    ],
                  ),
                );
              });
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: CachedNetworkImage(
            imageUrl: "${convo.message}",
            placeholder: (context, url) => const Center(
              child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  )),
            ),
          ),
        ),
      ),
    );
  }
}

class FileMessageItem extends StatefulWidget {
  const FileMessageItem({
    super.key,
    required this.convo,
  });

  final Chat convo;

  @override
  State<FileMessageItem> createState() => _FileMessageItemState();
}

class _FileMessageItemState extends State<FileMessageItem> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        PDFDocument doc = await PDFDocument.fromURL('${widget.convo.message}');
        showDialog(
            // ignore: use_build_context_synchronously
            context: context,
            builder: (context) {
              return Dialog.fullscreen(
                backgroundColor: Colors.transparent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              foregroundColor:
                                  Theme.of(context).textTheme.bodyLarge?.color,
                              backgroundColor:
                                  Theme.of(context).scaffoldBackgroundColor),
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Close")),
                    ),
                    Expanded(child: PDFViewer(document: doc))
                  ],
                ),
              );
            });
      },
      child: Container(
          constraints: const BoxConstraints(maxWidth: 250),
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Health Report",
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Tap to open and view report",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                EneftyIcons.health_bold,
                size: 40,
                color: YarisaColors.primaryColor.withOpacity(.3),
              )
            ],
          )),
    );
  }
}

class PrescriptionMessageItem extends StatefulWidget {
  const PrescriptionMessageItem({
    super.key,
    required this.convo,
  });

  final Chat convo;

  @override
  State<PrescriptionMessageItem> createState() =>
      _PrescriptionMessageItemState();
}

class _PrescriptionMessageItemState extends State<PrescriptionMessageItem> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
            context: context,
            builder: (context) {
              return Dialog.fullscreen(
                backgroundColor: Colors.transparent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              foregroundColor:
                                  Theme.of(context).textTheme.bodyLarge?.color,
                              backgroundColor:
                                  Theme.of(context).scaffoldBackgroundColor),
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Close")),
                    ),
                    Expanded(
                        child: Container(
                      padding: const EdgeInsets.all(20),
                      color: Colors.white,
                      child: ListView.builder(
                          itemCount: widget.convo.prescription?.length ?? 0,
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            final medicine =
                                (widget.convo.prescription ?? [])[index];
                            return ExpansionTile(
                              title: Text(
                                "${medicine.medicine?.medicine}",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              childrenPadding: const EdgeInsets.all(20),
                              children: [
                                ListTile(
                                  title: const Text("Dosage"),
                                  trailing: Text(
                                      "${medicine.medicine?.dosage}${medicine.medicine?.unit}"),
                                ),
                                ListTile(
                                  title: const Text("Type"),
                                  trailing: Text("${medicine.medicine?.type}"),
                                ),
                                ListTile(
                                  title: Text(
                                    "Instructions",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Colors.grey),
                                  ),
                                  subtitle: Text(
                                    "${medicine.controller}",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(),
                                  ),
                                )
                              ],
                            );
                          }),
                    ))
                  ],
                ),
              );
            });
      },
      child: Container(
          constraints: const BoxConstraints(maxWidth: 250),
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Prescription",
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Tap to open and view ",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                EneftyIcons.document_bold,
                size: 40,
                color: YarisaColors.primaryColor.withOpacity(.3),
              )
            ],
          )),
    );
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

enum MessageType { file, text, image, prescription }
