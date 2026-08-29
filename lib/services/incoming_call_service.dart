import 'package:flutter/material.dart';
import 'package:yarisa_doctor/services/callkit_service.dart';

/// Compatibility wrapper — native CallKit handles incoming calls.
class IncomingCallService {
  static bool isCallPayload(Map<String, dynamic> data) =>
      CallKitService.isCallPayload(data);

  static Future<void> handlePayload(
    Map<String, dynamic> data, {
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    return CallKitService.showIncoming(data);
  }
}
