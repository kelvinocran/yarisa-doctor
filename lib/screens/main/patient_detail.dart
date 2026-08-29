import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yarisa_doctor/components/patients/patient_widgets.dart';
import 'package:yarisa_doctor/constants/yarisa_widgets.dart';
import 'package:yarisa_doctor/models/personal_patients_model.dart';
import 'package:yarisa_doctor/screens/main/chat_inbox_screen.dart';
import 'package:yarisa_doctor/screens/main/lab_requests_screen.dart';
import 'package:yarisa_doctor/screens/main/prescriptions_screen.dart';
import 'package:yarisa_doctor/services/jitsi_call_service.dart';
import 'package:yarisa_doctor/ui/doctor_ui.dart';

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

  Future<void> _startCall(
    BuildContext context, {
    required String type,
    required String patientId,
  }) async {
    final ok = await joinMeeting(type, '', '', patientId, '');
    if (!context.mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          type == 'video'
              ? 'Video calls need a full app build on a real device or Android emulator with native plugins. Simulators often cannot start Jitsi.'
              : 'Voice calls need a full app build on a real device or Android emulator with native plugins. Simulators often cannot start Jitsi.',
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _openChat({
    required String patientId,
    required String name,
    required String image,
  }) {
    if (patientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient details are missing.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorMessageThreadScreen(
          patientId: patientId,
          patientName: name,
          patientImage: image,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fallbackName = widget.patient.patientName?.trim().isNotEmpty == true
        ? widget.patient.patientName!
        : 'Patient';
    final patientId = widget.patient.patientId ?? '';

    return DoctorScaffold(
      title: 'Patient',
      subtitle: fallbackName,
      body: patientId.isEmpty
          ? PatientsEmptyState(
              title: fallbackName,
              message: 'This patient record is missing an ID.',
            )
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('Patients')
            .doc(patientId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2.2),
            );
          }

          if (snapshot.hasError) {
            return DoctorEmptyState(
              icon: EneftyIcons.warning_2_outline,
              title: 'Unable to load patient',
              message:
                  'Check your connection and try again. You can still open care tools below with the saved profile.',
              actionLabel: 'Retry',
              onAction: () => setState(() {}),
            );
          }

          final patientData = snapshot.data?.data();
          final personalInfo = _personalInfo(patientData);
          final name = patientData?['name']?.toString().trim().isNotEmpty == true
              ? patientData!['name'].toString()
              : fallbackName;
          final email = patientData?['email']?.toString() ?? '';
          final pic = validNetworkImageUrl(
                (patientData?['pic'] ?? patientData?['photo'])?.toString(),
              ) ??
              widget.patient.patientImage;
          final id = snapshot.data?.id ?? patientId;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              PatientHeroHeader(
                name: name,
                email: email,
                imageUrl: pic,
              ),
              const SizedBox(height: 16),
              const DoctorSectionHeader(title: 'Care actions'),
              PatientActionGrid(
                actions: [
                  PatientActionItem(
                    label: 'Chat',
                    icon: EneftyIcons.message_2_bold,
                    color: Colors.red.shade400,
                    onTap: () => _openChat(
                      patientId: id,
                      name: name,
                      image: pic ?? '',
                    ),
                  ),
                  PatientActionItem(
                    label: 'Voice call',
                    icon: EneftyIcons.call_bold,
                    color: Colors.blue,
                    onTap: () => _startCall(
                      context,
                      type: 'voice',
                      patientId: id,
                    ),
                  ),
                  PatientActionItem(
                    label: 'Video call',
                    icon: EneftyIcons.video_bold,
                    color: Colors.purple,
                    onTap: () => _startCall(
                      context,
                      type: 'video',
                      patientId: id,
                    ),
                  ),
                  PatientActionItem(
                    label: 'Prescriptions',
                    icon: Icons.medication_outlined,
                    color: Colors.green,
                    onTap: _openPrescriptions,
                  ),
                  PatientActionItem(
                    label: 'Lab requests',
                    icon: Icons.science_outlined,
                    color: Colors.teal,
                    onTap: _openLabRequests,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const DoctorSectionHeader(title: 'Health profile'),
              if (patientData == null)
                DoctorCard(
                  child: Text(
                    'Full profile is not available yet. The patient may still be setting up their account.',
                    style: TextStyle(color: DoctorUi.muted, height: 1.4),
                  ),
                )
              else
                PatientMetricGrid(
                  metrics: [
                    PatientMetric(
                      label: 'Age',
                      value: _patientValue(patientData, personalInfo, 'age'),
                    ),
                    PatientMetric(
                      label: 'Blood',
                      value: _patientValue(
                        patientData,
                        personalInfo,
                        'bloodtype',
                        alternatives: const ['bloodgroup', 'blood_group'],
                      ),
                    ),
                    PatientMetric(
                      label: 'Genotype',
                      value: _patientValue(
                        patientData,
                        personalInfo,
                        'genotype',
                      ),
                    ),
                    PatientMetric(
                      label: 'Height',
                      value: _patientValue(
                        patientData,
                        personalInfo,
                        'height',
                      ),
                    ),
                    PatientMetric(
                      label: 'Weight',
                      value: _patientValue(
                        patientData,
                        personalInfo,
                        'weight',
                      ),
                    ),
                    PatientMetric(
                      label: 'Gender',
                      value: _patientValue(
                        patientData,
                        personalInfo,
                        'gender',
                        alternatives: const ['sex'],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 18),
              DoctorCard(
                child: Row(
                  children: [
                    Icon(Icons.badge_outlined, size: 18, color: DoctorUi.muted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Patient ID · $id',
                        style: TextStyle(
                          color: DoctorUi.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

Map<String, dynamic> _personalInfo(Map<String, dynamic>? patientData) {
  if (patientData == null) return {};
  if (patientData['personal_info'] is Map) {
    return Map<String, dynamic>.from(patientData['personal_info'] as Map);
  }
  if (patientData['personalInfo'] is Map) {
    return Map<String, dynamic>.from(patientData['personalInfo'] as Map);
  }
  return {};
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

Future<bool> joinMeeting(
  String type,
  String email,
  String name,
  String id,
  String image,
) async {
  final doctor = FirebaseAuth.instance.currentUser;
  final doctorId = doctor?.uid ?? '';
  if (doctorId.isEmpty || id.isEmpty) return false;
  return YarisaJitsiCallService.join(
    room: YarisaJitsiCallService.conversationRoom(doctorId, id),
    type: type,
    subject: 'Patient Appointment',
    displayName: doctor?.displayName ?? 'Doctor',
    avatarUrl: doctor?.photoURL ?? '',
    email: doctor?.email ?? '',
  );
}
