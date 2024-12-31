import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enefty_icons/enefty_icons.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omni_jitsi_meet/jitsi_meet.dart';
import 'package:yarisa_doctor/models/personal_patients_model.dart';
import 'package:yarisa_doctor/screens/chat_view.dart';

class PatientDetailScreen extends ConsumerStatefulWidget {
  const PatientDetailScreen({super.key, required this.patient});

  final PersonalPatientsModel patient;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _PatientDetailScreenState();
}

class _PatientDetailScreenState extends ConsumerState<PatientDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection("Patients")
              .doc(widget.patient.patientId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData) {
              return const Text("No Patient");
            }

            final patient = snapshot.data;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          shape: BoxShape.circle),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: CachedNetworkImage(
                          imageUrl: patient?['pic'],
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) {
                            return Container(
                                decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(.2)),
                                child: const Center(
                                  child: Icon(
                                    EneftyIcons.user_bold,
                                    size: 20,
                                  ),
                                ));
                          },
                          placeholder: (context, url) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      '${patient?["name"]}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Center(
                    child: Text(
                      '${patient?["email"]}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: Wrap(
                      spacing: 10,
                      alignment: WrapAlignment.spaceEvenly,
                      children: [
                        OutlinedButton.icon(
                            style: const ButtonStyle(
                                side: WidgetStatePropertyAll(
                                    BorderSide(color: Colors.red)),
                                foregroundColor:
                                    WidgetStatePropertyAll(Colors.red)),
                            icon: const Icon(EneftyIcons.message_2_bold),
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => ChatView(
                                            patientId: patient!.id,
                                            patientName: patient['name'],
                                          )));
                            },
                            label: const Text("Chat")),
                        OutlinedButton.icon(
                            style: const ButtonStyle(
                                side: WidgetStatePropertyAll(
                                    BorderSide(color: Colors.blue)),
                                foregroundColor:
                                    WidgetStatePropertyAll(Colors.blue)),
                            icon: const Icon(EneftyIcons.call_bold),
                            onPressed: () {
                              joinMeeting(
                                  "voice",
                                  "${patient?['email']}",
                                  "${patient?['name']}",
                                  "${patient?.id}",
                                  "${patient?['pic']}");
                            },
                            label: const Text("Audio")),
                        OutlinedButton.icon(
                            style: const ButtonStyle(
                                side: WidgetStatePropertyAll(
                                    BorderSide(color: Colors.purple)),
                                foregroundColor:
                                    WidgetStatePropertyAll(Colors.purple)),
                            icon: const Icon(EneftyIcons.video_bold),
                            onPressed: () {
                              joinMeeting(
                                  "video",
                                  "${patient?['email']}",
                                  "${patient?['name']}",
                                  "${patient?.id}",
                                  "${patient?['pic']}");
                            },
                            label: const Text("Video")),
                      ],
                    ),
                  ),
                  Divider(color: Colors.grey.withOpacity(.2), height: 50),
                  Wrap(spacing: 10, runSpacing: 10, children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(.2),
                          borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("${patient?['age']}",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          Text("Age",
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(.2),
                          borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("${patient?['bloodtype']}",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          Text("Blood Group",
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(.2),
                          borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("${patient?['genotype']}",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          Text("Genotype",
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(.2),
                          borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("${patient?['height']}",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          Text("Height",
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(.2),
                          borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("${patient?['weight']}",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          Text("Weight",
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    )
                  ]),
                ],
              ),
            );
          }),
    );
  }
}

joinMeeting(
    String type, String email, String name, String id, String image) async {
  try {
    Map<FeatureFlagEnum, Object> features = {
      FeatureFlagEnum.ADD_PEOPLE_ENABLED: false,
      FeatureFlagEnum.CHAT_ENABLED: false,
      FeatureFlagEnum.LOBBY_MODE_ENABLED: false,
      FeatureFlagEnum.WELCOME_PAGE_ENABLED: false,
      FeatureFlagEnum.INVITE_ENABLED: false,
      FeatureFlagEnum.CAR_MODE_ENABLED: false,
      FeatureFlagEnum.LIVE_STREAMING_ENABLED: false,
      FeatureFlagEnum.FILMSTRIP_ENABLED: false,
      FeatureFlagEnum.FULLSCREEN_ENABLED: true,
      FeatureFlagEnum.PREJOIN_PAGE_ENABLED: false,
      FeatureFlagEnum.SECURITY_OPTIONS_ENABLED: false,
      FeatureFlagEnum.VIDEO_SHARE_BUTTON_ENABLED: false,
      FeatureFlagEnum.RECORDING_ENABLED: false,
      FeatureFlagEnum.REACTIONS_ENABLED: false,
      FeatureFlagEnum.SETTINGS_ENABLED: false,
      FeatureFlagEnum.RAISE_HAND_ENABLED: false,
      FeatureFlagEnum.CLOSE_CAPTIONS_ENABLED: false,
    };

    var options = JitsiMeetingOptions(
        room: id,
        serverURL: "",
        subject: "Patient Appointment",
        userDisplayName: name,
        userAvatarURL: image,
        userEmail: "",
        audioOnly: type == "video" ? false : true,
        audioMuted: false,
        videoMuted: type == "video" ? false : true,
        featureFlags: features);

    await JitsiMeet.joinMeeting(options,
        listener: JitsiMeetingListener(onConferenceWillJoin: (message) {
          debugPrint("${options.room} will join with message: $message");
        }, onConferenceJoined: (message) {
          debugPrint("${options.room} joined with message: $message");
        }, onConferenceTerminated: (message, error) {
          debugPrint("${options.room} terminated with message: $message");
          debugPrint("${options.room} terminated with error: $error");
        }, onChatMessageReceived: (senderId, message, isPrivate, _) {
          debugPrint(
            "onChatMessageReceived: senderId: $senderId, message: $message, "
            "isPrivate: $isPrivate",
          );
        })).whenComplete(() {
      // sendCallMessage(
      //     FirebaseFirestore.instance
      //         .collection("Messages")
      //         .doc(FirebaseAuth.instance.currentUser?.uid),
      //     MessageType.call,
      //     callType: type,
      //     id: id,
      //     image: image,
      //     message: "",
      //     name: name);
    });
  } catch (error) {
    debugPrint("error: $error");
  }
}
