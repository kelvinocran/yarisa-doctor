import 'package:flutter/material.dart';
import 'package:yarisa_doctor/models/personal_patients_model.dart';
import 'package:yarisa_doctor/screens/main/appointment_screen.dart';
import 'package:yarisa_doctor/screens/main/chat_inbox_screen.dart';
import 'package:yarisa_doctor/screens/main/lab_requests_screen.dart';
import 'package:yarisa_doctor/screens/main/patient_detail.dart';
import 'package:yarisa_doctor/screens/main/prescriptions_screen.dart';
import 'package:yarisa_doctor/screens/main/second_opinions_screen.dart';
import 'package:yarisa_doctor/services/callkit_service.dart';

/// Queues notification taps until the navigator is ready (post-auth).
class DeepLinkRouter {
  DeepLinkRouter._();

  static GlobalKey<NavigatorState>? navigatorKey;
  static Map<String, dynamic>? _pending;
  static bool _ready = false;

  static void attach(GlobalKey<NavigatorState> key) {
    navigatorKey = key;
  }

  /// Call once user is on the main shell (BaseScreen).
  static void markReady() {
    _ready = true;
    flush();
  }

  static void reset() {
    _ready = false;
    _pending = null;
  }

  static void handle(Map<String, dynamic> data) {
    if (data.isEmpty) return;
    // Always queue if shell not ready — never drop cold-start / bg taps.
    if (!_ready || navigatorKey?.currentState == null) {
      _pending = Map<String, dynamic>.from(data);
      return;
    }
    _navigate(navigatorKey!.currentState!, data);
  }

  static void flush() {
    final pending = _pending;
    if (!_ready || pending == null) return;
    _pending = null;
    // Delay so BaseScreen is mounted after auth.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final n = navigatorKey?.currentState;
      if (n != null) {
        _navigate(n, pending);
      } else {
        // Retry once more next frame if navigator not ready yet.
        _pending = pending;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final n2 = navigatorKey?.currentState;
          final p = _pending;
          if (n2 != null && p != null) {
            _pending = null;
            _navigate(n2, p);
          }
        });
      }
    });
  }

  static void openChat({
    required String patientId,
    required String patientName,
    required String patientImage,
  }) {
    final nav = navigatorKey?.currentState;
    if (nav == null || patientId.isEmpty) {
      handle({
        'type': 'message_created',
        'senderId': patientId,
        'senderName': patientName,
        'senderImage': patientImage,
      });
      return;
    }
    nav.push(
      MaterialPageRoute(
        builder: (_) => DoctorMessageThreadScreen(
          patientId: patientId,
          patientName: patientName,
          patientImage: patientImage,
        ),
      ),
    );
  }

  static void _navigate(NavigatorState nav, Map<String, dynamic> data) {
    final type = (data['type'] ?? data['notificationType'] ?? '')
        .toString()
        .toLowerCase();
    final patientId = (data['patientId'] ??
            data['senderId'] ??
            data['peerId'] ??
            data['conversationPeerId'] ??
            data['id'] ??
            '')
        .toString();
    final patientName = (data['patientName'] ??
            data['senderName'] ??
            data['peerName'] ??
            data['name'] ??
            'Patient')
        .toString();
    final patientImage = (data['patientImage'] ??
            data['senderImage'] ??
            data['peerImage'] ??
            data['image'] ??
            '')
        .toString();

    if (type.contains('call')) {
      // Notification tap on a call: show native UI if still ringing, else chat.
      CallKitService.showIncoming(data);
      if (patientId.isNotEmpty) {
        nav.push(
          MaterialPageRoute(
            builder: (_) => DoctorMessageThreadScreen(
              patientId: patientId,
              patientName: patientName,
              patientImage: patientImage,
            ),
          ),
        );
      }
      return;
    }

    if (type.contains('message') ||
        type.contains('chat') ||
        type.contains('conversation') ||
        type.contains('incoming_call')) {
      if (patientId.isNotEmpty) {
        nav.push(
          MaterialPageRoute(
            builder: (_) => DoctorMessageThreadScreen(
              patientId: patientId,
              patientName: patientName,
              patientImage: patientImage,
            ),
          ),
        );
        return;
      }
      nav.push(
        MaterialPageRoute(builder: (_) => const DoctorChatInboxScreen()),
      );
      return;
    }

    if (type.contains('clinical_note') ||
        type.contains('recommendation') ||
        type.contains('care_note') ||
        data['clinicalNoteId'] != null) {
      if (patientId.isNotEmpty) {
        nav.push(
          MaterialPageRoute(
            builder: (_) => PatientDetailScreen(
              patient: PersonalPatientsModel(
                patientId: patientId,
                patientName: patientName,
                patientImage: patientImage,
                status: 'active',
              ),
            ),
          ),
        );
      }
      return;
    }

    if (type.contains('prescription') ||
        data['prescriptionId'] != null ||
        data['sourceCollection']?.toString() == 'Prescriptions') {
      nav.push(
        MaterialPageRoute(
          builder: (_) => PrescriptionsScreen(
            patient: patientId.isEmpty
                ? null
                : PersonalPatientsModel(
                    patientId: patientId,
                    patientName: patientName,
                    patientImage: patientImage,
                    status: 'active',
                  ),
          ),
        ),
      );
      return;
    }

    if (type.contains('lab_request') ||
        data['labRequestId'] != null ||
        data['sourceCollection']?.toString() == 'LabRequests') {
      nav.push(
        MaterialPageRoute(
          builder: (_) => LabRequestsScreen(
            patient: patientId.isEmpty
                ? null
                : PersonalPatientsModel(
                    patientId: patientId,
                    patientName: patientName,
                    patientImage: patientImage,
                    status: 'active',
                  ),
          ),
        ),
      );
      return;
    }

    if (type.contains('second') ||
        type.contains('opinion') ||
        data['secondOpinionId'] != null ||
        data['sourceCollection']?.toString() == 'SecondOpinions') {
      final requestId = (data['secondOpinionId'] ??
              data['sourceId'] ??
              '')
          .toString();
      if (requestId.isNotEmpty) {
        nav.push(
          MaterialPageRoute(
            builder: (_) => SecondOpinionDetailScreen(requestId: requestId),
          ),
        );
      } else {
        nav.push(
          MaterialPageRoute(builder: (_) => const SecondOpinionsScreen()),
        );
      }
      return;
    }

    if (type.contains('appointment') ||
        data['appointmentId'] != null ||
        data['appointment_id'] != null) {
      nav.push(
        MaterialPageRoute(builder: (_) => const AppointmentScreen()),
      );
      return;
    }

    // Already on app — no-op rather than resetting stack.
  }
}
