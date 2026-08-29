import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _generalChannel = AndroidNotificationChannel(
    'yarisa_doctor_general',
    'General Notifications',
    description: 'Appointments, messages, and updates',
    importance: Importance.high,
  );

  static const _callChannel = AndroidNotificationChannel(
    'yarisa_doctor_calls',
    'Incoming Calls',
    description: 'Voice and video call alerts',
    importance: Importance.max,
    playSound: true,
  );

  static Future<void> initialize({
    required void Function(Map<String, dynamic> data) onTap,
  }) async {
    if (_initialized) {
      return;
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) {
          onTap({});
          return;
        }

        try {
          final decoded = jsonDecode(payload);
          if (decoded is Map<String, dynamic>) {
            onTap(decoded);
            return;
          }
          if (decoded is Map) {
            onTap(Map<String, dynamic>.from(decoded));
            return;
          }
        } catch (_) {}
        onTap({});
      },
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_generalChannel);
    await android?.createNotificationChannel(_callChannel);

    _initialized = true;
  }

  static bool _isCall(Map<String, dynamic> data, String? title, String? body) {
    final type = (data['type'] ??
            data['notificationType'] ??
            data['messageType'] ??
            '')
        .toString()
        .toLowerCase();
    if (type.contains('call')) return true;
    final t = (title ?? '').toLowerCase();
    final b = (body ?? '').toLowerCase();
    return t.contains('call') || b.contains('calling');
  }

  static Future<void> showRemoteMessage(RemoteMessage message) async {
    if (!_initialized || kIsWeb) {
      return;
    }

    final data = Map<String, dynamic>.from(message.data);
    final notification = message.notification;
    var title = notification?.title;
    var body = notification?.body;

    // Prefer data payload when present (call-aware titles from functions).
    if ((data['title']?.toString().isNotEmpty ?? false)) {
      title = data['title'].toString();
    }
    if ((data['body']?.toString().isNotEmpty ?? false)) {
      body = data['body'].toString();
    }

    final isCall = _isCall(data, title, body);
    if (isCall) {
      final peer = (data['peerName'] ??
              data['senderName'] ??
              data['patientName'] ??
              data['name'] ??
              'Someone')
          .toString();
      final callType =
          (data['callType'] ?? data['extra_type'] ?? 'voice').toString();
      title = callType.toLowerCase() == 'video'
          ? 'Incoming video call'
          : 'Incoming voice call';
      body = '$peer is calling you';
    }

    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        isCall ? _callChannel.id : _generalChannel.id,
        isCall ? _callChannel.name : _generalChannel.name,
        channelDescription: isCall
            ? _callChannel.description
            : _generalChannel.description,
        importance: isCall ? Importance.max : Importance.high,
        priority: isCall ? Priority.max : Priority.high,
        category: isCall ? AndroidNotificationCategory.call : null,
        fullScreenIntent: isCall,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: isCall
            ? InterruptionLevel.timeSensitive
            : InterruptionLevel.active,
      ),
    );

    // Stable id from messageId when available to avoid duplicate stacks.
    final id = message.messageId?.hashCode ?? message.hashCode;

    await _plugin.show(
      id: id.abs() % 100000,
      title: title ?? 'Yarisa Doctor',
      body: body ?? '',
      notificationDetails: details,
      payload: jsonEncode(data),
    );
  }
}
