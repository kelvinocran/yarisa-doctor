import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:yarisa_doctor/services/firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class FcmService {
  static const int _maxApnsTokenRetries = 5;

  static String? _userCollection;
  static int _apnsTokenRetryCount = 0;
  static bool _apnsTokenRetryScheduled = false;

  static Future<void> initialize({required String userCollection}) async {
    _userCollection = userCollection;
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    await _saveCurrentToken();

    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        await _saveCurrentToken();
      }
    });

    messaging.onTokenRefresh.listen((token) async {
      await _saveToken(token);
    });

    FirebaseMessaging.onMessage.listen((message) {
      if (kDebugMode) {
        debugPrint('FCM foreground message: ${message.messageId}');
      }
    });
  }

  static Future<void> _saveCurrentToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsToken = await messaging.getAPNSToken();
        if (apnsToken == null) {
          if (kDebugMode) {
            debugPrint('FCM APNS token is not ready yet.');
          }
          _scheduleApnsTokenRetry();
          return;
        }
        _apnsTokenRetryCount = 0;
        _apnsTokenRetryScheduled = false;
      }

      final token = await messaging.getToken();
      if (token != null) {
        await _saveToken(token);
      }
    } on FirebaseException catch (error) {
      if (kDebugMode) {
        debugPrint('Unable to get FCM token: ${error.code}');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Unable to get FCM token: $error');
      }
    }
  }

  static void _scheduleApnsTokenRetry() {
    if (_apnsTokenRetryScheduled ||
        _apnsTokenRetryCount >= _maxApnsTokenRetries) {
      return;
    }

    _apnsTokenRetryCount += 1;
    _apnsTokenRetryScheduled = true;
    Future<void>.delayed(const Duration(seconds: 2), () async {
      _apnsTokenRetryScheduled = false;
      await _saveCurrentToken();
    });
  }

  static Future<void> _saveToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    final collection = _userCollection;
    if (user == null || collection == null) return;

    try {
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(user.uid)
          .set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Unable to save FCM token: $error');
      }
    }
  }
}
