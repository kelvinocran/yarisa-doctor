import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:get/get.dart';
import 'package:yarisa_doctor/main.dart' show appNavigatorKey;
import 'package:yarisa_doctor/services/call_permissions.dart';
import 'package:yarisa_doctor/services/call_session_service.dart';
import 'package:yarisa_doctor/services/jitsi_call_service.dart';
import 'package:yarisa_doctor/ui/doctor_ui.dart';

/// Native CallKit (iOS) / full-screen incoming call UI (Android).
class CallKitService {
  CallKitService._();

  static StreamSubscription<CallEvent?>? _sub;
  static bool _initialized = false;
  static bool _fallbackShowing = false;
  static bool _joining = false;
  static String? _lastAcceptedCallId;
  static Map<String, dynamic> _activePayload = {};
  static String? _activeCallId;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await FlutterCallkitIncoming.requestNotificationPermission({
        'title': 'Notification permission',
        'rationaleMessagePermission':
            'Notifications are required to show incoming call alerts.',
        'postNotificationMessageRequired':
            'Please allow notifications so patients can reach you for calls.',
      });
    } catch (_) {}

    try {
      final canFull = await FlutterCallkitIncoming.canUseFullScreenIntent();
      if (canFull != true) {
        await FlutterCallkitIncoming.requestFullIntentPermission();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CallKit full-screen intent permission: $e');
      }
    }

    _sub?.cancel();
    _sub = FlutterCallkitIncoming.onEvent.listen((event) async {
      if (event == null) return;
      if (kDebugMode) {
        debugPrint('CallKit event: ${event.runtimeType}');
      }
      switch (event) {
        case CallEventActionCallAccept(:final callKitParams):
          final data = _payloadFromParams(callKitParams);
          _dismissFallback();
          await _handleAccept(callKitParams.id, data);
        case CallEventActionCallCallback():
          _dismissFallback();
          await _handleAccept(
            _activeCallId ?? _uuidV4(),
            Map<String, dynamic>.from(_activePayload),
          );
        case CallEventActionCallDecline():
          _dismissFallback();
          if (!_joining) {
            await CallSessionService.end(status: 'declined');
            _activePayload = {};
            _activeCallId = null;
          }
        case CallEventActionCallTimeout():
          _dismissFallback();
          if (!_joining) {
            await CallSessionService.end(status: 'missed');
            _activePayload = {};
            _activeCallId = null;
          }
        case CallEventActionCallEnded():
          _dismissFallback();
          // Don't clear mid-join; only when not joining.
          if (!_joining) {
            await CallSessionService.end(status: 'ended');
            _activePayload = {};
            _activeCallId = null;
          }
        case CallEventActionDidUpdateDevicePushTokenVoip():
          await persistVoipToken();
        default:
          break;
      }
    });

    // Best-effort: pick up VoIP token if PushKit already registered.
    Future<void>.delayed(const Duration(seconds: 2), persistVoipToken);
  }

  /// Persist iOS PushKit VoIP token onto the signed-in doctor profile.
  static Future<void> persistVoipToken() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      final token = await FlutterCallkitIncoming.getDevicePushTokenVoIP();
      if (token == null || token.isEmpty) return;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await FirebaseFirestore.instance.collection('Doctors').doc(user.uid).set({
        'voipToken': token,
        'voipTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (kDebugMode) debugPrint('Saved doctor voipToken');
    } catch (e) {
      if (kDebugMode) debugPrint('persistVoipToken failed: $e');
    }
  }

  /// Shared accept path: debounce triple-fire + avoid CallKit error 6.
  static Future<void> _handleAccept(
    String callId,
    Map<String, dynamic> data,
  ) async {
    if (_joining) {
      if (kDebugMode) debugPrint('CallKit accept ignored (already joining)');
      return;
    }
    if (_lastAcceptedCallId == callId) {
      if (kDebugMode) debugPrint('CallKit accept ignored (duplicate id=$callId)');
      return;
    }
    _joining = true;
    _lastAcceptedCallId = callId;
    try {
      final callType =
          (data['callType'] ?? data['extra_type'] ?? 'voice').toString();
      final permitted = await CallPermissions.ensureBeforeCall(
        video: callType.toLowerCase() == 'video',
      );
      if (!permitted) {
        try {
          await FlutterCallkitIncoming.endCall(callId);
        } catch (_) {}
        return;
      }

      try {
        await FlutterCallkitIncoming.setCallConnected(callId);
      } catch (e) {
        if (kDebugMode) debugPrint('setCallConnected: $e');
      }

      // Tear down CallKit UI/FGS before Jitsi so no ongoing notification races.
      try {
        await FlutterCallkitIncoming.endCall(callId);
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 300));

      await _joinFromPayload(data);
    } finally {
      _joining = false;
    }
  }

  static Map<String, dynamic> _payloadFromParams(CallKitParams params) {
    final extra = params.extra;
    if (extra != null && extra.isNotEmpty) {
      return Map<String, dynamic>.from(extra);
    }
    return Map<String, dynamic>.from(_activePayload);
  }

  static bool isCallPayload(Map<String, dynamic> data) {
    final type = (data['type'] ??
            data['notificationType'] ??
            data['messageType'] ??
            '')
        .toString()
        .toLowerCase();
    if (type.contains('call')) return true;
    final title = (data['title'] ?? '').toString().toLowerCase();
    final body = (data['body'] ?? '').toString().toLowerCase();
    return title.contains('call') || body.contains('calling');
  }

  static Future<void> showIncoming(Map<String, dynamic> data) async {
    if (!isCallPayload(data)) return;

    try {
      await FlutterCallkitIncoming.endAllCalls();
    } catch (_) {}

    final peerName = (data['peerName'] ??
            data['senderName'] ??
            data['patientName'] ??
            data['name'] ??
            'Patient')
        .toString();
    final peerImage = (data['peerImage'] ??
            data['senderImage'] ??
            data['patientImage'] ??
            data['image'] ??
            '')
        .toString();
    final callType =
        (data['callType'] ?? data['extra_type'] ?? 'voice').toString();
    final isVideo = callType.toLowerCase() == 'video';
    final id = (data['callId'] ?? data['uuid'] ?? _uuidV4()).toString();
    _activeCallId = id;
    _lastAcceptedCallId = null;
    _activePayload = Map<String, dynamic>.from(data);

    final params = CallKitParams(
      id: id,
      nameCaller: peerName,
      appName: 'Yarisa Doctor',
      avatar: peerImage.isNotEmpty ? peerImage : null,
      handle: peerName,
      type: isVideo ? 1 : 0,
      duration: 60000,
      extra: {
        ...data,
        'callId': id,
      },
      // Critical on Android 14+: ongoing "calling" FGS uses IMPORTANCE_LOW /
      // CallStyle and throws CannotPostForegroundServiceNotificationException
      // on Accept. Disable it — Jitsi owns the in-call UI.
      callingNotification: const NotificationParams(
        showNotification: false,
      ),
      missedCallNotification: const NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: 'Missed call',
        callbackText: 'Call back',
      ),
      android: const AndroidParams(
        isCustomNotification: false,
        isCustomSmallExNotification: false,
        isShowLogo: false,
        isShowCallID: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0A7C66',
        actionColor: '#4CAF50',
        textColor: '#ffffff',
        textAccept: 'Accept',
        textDecline: 'Decline',
        isFullScreen: true,
        isShowFullLockedScreen: true,
        isImportant: true,
        incomingCallNotificationChannelName: 'Incoming Call',
        missedCallNotificationChannelName: 'Missed Call',
      ),
      ios: const IOSParams(
        iconName: 'CallKitLogo',
        handleType: 'generic',
        supportsVideo: true,
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
        audioSessionActive: true,
        supportsDTMF: true,
        supportsHolding: false,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: 'system_ringtone_default',
      ),
    );

    try {
      await FlutterCallkitIncoming.showCallkitIncoming(params);
      if (kDebugMode) {
        debugPrint('CallKit showIncoming ok id=$id caller=$peerName');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CallKit showIncoming failed: $e');
      }
    }

    final state = WidgetsBinding.instance.lifecycleState;
    if (state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive) {
      await _showInAppFallback(
        peerName: peerName,
        isVideo: isVideo,
        data: data,
        callId: id,
      );
    }
  }

  static Future<void> _showInAppFallback({
    required String peerName,
    required bool isVideo,
    required Map<String, dynamic> data,
    required String callId,
  }) async {
    if (_fallbackShowing) return;
    final ctx = appNavigatorKey.currentContext ?? Get.context;
    if (ctx == null) return;

    _fallbackShowing = true;
    try {
      final action = await showModalBottomSheet<String>(
        context: ctx,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: DoctorUi.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetCtx) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: DoctorUi.border,
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: DoctorUi.primary.withValues(alpha: .12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                      color: DoctorUi.primary,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isVideo ? 'Incoming video call' : 'Incoming voice call',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    peerName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: DoctorUi.muted,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.pop(sheetCtx, 'decline'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Decline',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () =>
                              Navigator.pop(sheetCtx, 'accept'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Accept',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (action == 'accept') {
        await _handleAccept(callId, data);
      } else if (action == 'decline') {
        try {
          await FlutterCallkitIncoming.endCall(callId);
        } catch (_) {
          try {
            await FlutterCallkitIncoming.endAllCalls();
          } catch (_) {}
        }
        _activePayload = {};
        _activeCallId = null;
      }
    } finally {
      _fallbackShowing = false;
    }
  }

  static void _dismissFallback() {
    if (!_fallbackShowing) return;
    final nav = appNavigatorKey.currentState;
    if (nav != null && nav.canPop()) {
      nav.pop();
    }
    _fallbackShowing = false;
  }

  static Future<void> endAll() async {
    try {
      await FlutterCallkitIncoming.endAllCalls();
    } catch (_) {}
    _activePayload = {};
    _activeCallId = null;
  }

  static Future<void> _joinFromPayload(Map<String, dynamic> data) async {
    final peerId = (data['peerId'] ??
            data['senderId'] ??
            data['patientId'] ??
            data['id'] ??
            '')
        .toString();
    final callType =
        (data['callType'] ?? data['extra_type'] ?? 'voice').toString();
    final isVideo = callType.toLowerCase() == 'video';
    final me = FirebaseAuth.instance.currentUser;
    final myId = me?.uid ?? '';
    if (peerId.isEmpty || myId.isEmpty) {
      if (kDebugMode) {
        debugPrint('CallKit join skipped: peerId=$peerId myId=$myId');
      }
      try {
        Get.snackbar(
          'Call',
          'Could not join — missing caller id.',
          snackPosition: SnackPosition.BOTTOM,
        );
      } catch (_) {}
      return;
    }

    final rawRoom =
        (data['room'] ?? data['roomId'])?.toString().trim() ?? '';
    final room = rawRoom.isNotEmpty
        ? rawRoom
        : YarisaJitsiCallService.conversationRoom(myId, peerId);

    await CallSessionService.start(
      room: room,
      peerId: peerId,
      callType: isVideo ? 'video' : 'voice',
      direction: 'inbound',
      peerName: (data['peerName'] ?? data['senderName'] ?? data['patientName'])
          ?.toString(),
    );

    await YarisaJitsiCallService.join(
      room: room,
      type: isVideo ? 'video' : 'voice',
      subject: isVideo ? 'Video call' : 'Voice call',
      displayName: me?.displayName ?? 'Doctor',
      avatarUrl: me?.photoURL ?? '',
      email: me?.email ?? '',
      peerId: peerId,
      peerName: (data['peerName'] ?? data['senderName'] ?? data['patientName'])
          ?.toString(),
    );
  }

  static String _uuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int b) => b.toRadixString(16).padLeft(2, '0');
    final h = bytes.map(hex).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-'
        '${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }
}
