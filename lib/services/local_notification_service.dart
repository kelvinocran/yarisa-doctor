import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

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
        } catch (_) {
          // Ignore invalid payload and fall back to empty map.
        }
        onTap({});
      },
    );

    const androidChannel = AndroidNotificationChannel(
      'yarisa_doctor_general',
      'General Notifications',
      description: 'Notifications for Yarisa Doctor updates',
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    _initialized = true;
  }

  static Future<void> showRemoteMessage(RemoteMessage message) async {
    if (!_initialized || kIsWeb) {
      return;
    }

    final notification = message.notification;
    if (notification == null) {
      return;
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'yarisa_doctor_general',
        'General Notifications',
        channelDescription: 'Notifications for Yarisa Doctor updates',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    final payload = jsonEncode(message.data);
    await _plugin.show(
      id: message.hashCode,
      title: notification.title ?? 'Yarisa Doctor',
      body: notification.body ?? '',
      notificationDetails: details,
      payload: payload,
    );
  }
}
