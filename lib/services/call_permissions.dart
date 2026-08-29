import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

/// Request mic / camera / notification permissions before starting a call.
class CallPermissions {
  CallPermissions._();

  static bool _isUsable(PermissionStatus status) {
    // limited = iOS partial grant; treat as ok for calls.
    return status.isGranted || status.isLimited || status.isProvisional;
  }

  /// Returns true when required permissions are granted.
  static Future<bool> ensureBeforeCall({
    required bool video,
    BuildContext? context,
  }) async {
    // Android-only extras (no-op / soft-fail on iOS).
    if (Platform.isAndroid) {
      try {
        await FlutterCallkitIncoming.requestNotificationPermission({
          'title': 'Notification permission',
          'rationaleMessagePermission':
              'Notifications are required for incoming call alerts.',
          'postNotificationMessageRequired':
              'Please allow notifications so you can receive call alerts.',
        });
      } catch (_) {}

      try {
        final canFull = await FlutterCallkitIncoming.canUseFullScreenIntent();
        if (canFull != true) {
          await FlutterCallkitIncoming.requestFullIntentPermission();
        }
      } catch (e) {
        if (kDebugMode) debugPrint('Full-screen intent permission: $e');
      }
    }

    // Mic is required for all calls.
    var micStatus = await Permission.microphone.status;
    if (!_isUsable(micStatus)) {
      micStatus = await Permission.microphone.request();
    }
    final micOk = _isUsable(micStatus);

    // Camera only for video.
    var camOk = true;
    if (video) {
      var camStatus = await Permission.camera.status;
      if (!_isUsable(camStatus)) {
        camStatus = await Permission.camera.request();
      }
      camOk = _isUsable(camStatus);
    }

    // Notifications are best-effort (do not block the call on iOS if denied).
    try {
      final notif = await Permission.notification.status;
      if (!_isUsable(notif)) {
        await Permission.notification.request();
      }
    } catch (_) {}

    if (!micOk || !camOk) {
      final msg = !micOk
          ? 'Microphone access is needed for calls. Enable it in Settings → Yarisa Doctor → Microphone.'
          : 'Camera access is needed for video calls. Enable it in Settings → Yarisa Doctor → Camera.';
      try {
        Get.snackbar(
          'Permission needed',
          msg,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
          mainButton: TextButton(
            onPressed: openAppSettings,
            child: const Text('Open Settings'),
          ),
        );
      } catch (_) {
        if (kDebugMode) debugPrint(msg);
      }
      return false;
    }
    return true;
  }
}
