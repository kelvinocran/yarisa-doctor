import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enefty_icons/enefty_icons.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yarisa_doctor/constants/yarisa_widgets.dart';
import 'package:yarisa_doctor/models/personal_patients_model.dart';
import 'package:yarisa_doctor/screens/main/chat_inbox_screen.dart';
import 'package:yarisa_doctor/screens/main/lab_requests_screen.dart';
import 'package:yarisa_doctor/screens/main/prescriptions_screen.dart';
import 'package:yarisa_doctor/services/jitsi_call_service.dart';

class PatientDetailScreen extends ConsumerStatefulWidget {
  const PatientDetailScreen({super.key, required this.patient});

  final PersonalPatientsModel patient;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _PatientDetailScreenState();
}

class _PatientDetailScreenState extends ConsumerState<PatientDetailScreen> {
  void _openPrescriptions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrescriptionsScreen(patient: widget.patient),
      ),
    );
  }

  void _openLabRequests() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LabRequestsScreen(patient: widget.patient),
      ),
    );
  }

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
            final patientData = patient?.data();
            final personalInfo = patientData?['personal_info'] is Map
                ? Map<String, dynamic>.from(
                    patientData?['personal_info'] as Map)
                : patientData?['personalInfo'] is Map
                    ? Map<String, dynamic>.from(
                        patientData?['personalInfo'] as Map)
                    : <String, dynamic>{};
            final patientPic = validNetworkImageUrl(
                (patientData?['pic'] ?? patientData?['photo'])?.toString());
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
                        child: patientPic == null
                            ? _patientImageFallback()
                            : CachedNetworkImage(
                                imageUrl: patientPic,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) {
                                  return _patientImageFallback();
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
                              final patientId =
                                  widget.patient.patientId ?? patient?.id;
                              if (patientId == null || patientId.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Patient details are missing.'),
                                  ),
                                );
                                return;
                              }
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          DoctorMessageThreadScreen(
                                            patientId: patientId,
                                            patientName: patient?['name']
                                                    ?.toString() ??
                                                widget.patient.patientName ??
                                                'Patient',
                                            patientImage: patientPic ??
                                                widget.patient.patientImage ??
                                                '',
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
                        OutlinedButton.icon(
                            style: const ButtonStyle(
                                side: WidgetStatePropertyAll(
                                    BorderSide(color: Colors.green)),
                                foregroundColor:
                                    WidgetStatePropertyAll(Colors.green)),
                            icon: const Icon(Icons.medication_outlined),
                            onPressed: _openPrescriptions,
                            label: const Text("Prescriptions")),
                        OutlinedButton.icon(
                            style: const ButtonStyle(
                                side: WidgetStatePropertyAll(
                                    BorderSide(color: Colors.teal)),
                                foregroundColor:
                                    WidgetStatePropertyAll(Colors.teal)),
                            icon: const Icon(Icons.science_outlined),
                            onPressed: _openLabRequests,
                            label: const Text("Labs")),
                      ],
                    ),
                  ),
                  Divider(color: Colors.grey.withValues(alpha: .2), height: 50),
                  Wrap(spacing: 10, runSpacing: 10, children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: .2),
                          borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_patientValue(patientData, personalInfo, 'age'),
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
                          color: Colors.grey.withValues(alpha: .2),
                          borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                              _patientValue(
                                  patientData, personalInfo, 'bloodtype',
                                  alternatives: const ['bloodgroup']),
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
                          color: Colors.grey.withValues(alpha: .2),
                          borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                              _patientValue(
                                  patientData, personalInfo, 'genotype'),
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
                          color: Colors.grey.withValues(alpha: .2),
                          borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                              _patientValue(
                                  patientData, personalInfo, 'height'),
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
                          color: Colors.grey.withValues(alpha: .2),
                          borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                              _patientValue(
                                  patientData, personalInfo, 'weight'),
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

  Widget _patientImageFallback() {
    return Container(
      decoration: BoxDecoration(color: Colors.grey.withValues(alpha: .2)),
      child: const Center(
        child: Icon(
          EneftyIcons.user_bold,
          size: 20,
        ),
      ),
    );
  }
}

String _patientValue(
  Map<String, dynamic>? patientData,
  Map<String, dynamic> personalInfo,
  String key, {
  List<String> alternatives = const [],
}) {
  for (final candidate in [key, ...alternatives]) {
    final value = personalInfo[candidate] ?? patientData?[candidate];
    final text = value?.toString().trim();
    if (text != null && text.isNotEmpty && text.toLowerCase() != 'null') {
      return text;
    }
  }
  return 'Not set';
}

joinMeeting(
    String type, String email, String name, String id, String image) async {
  await YarisaJitsiCallService.join(
    room: id,
    type: type,
    subject: "Patient Appointment",
    displayName: name,
    avatarUrl: image,
    email: email,
  );
}
