import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Clears chat thread unread and related Alerts notifications together.
class ChatUnreadService {
  ChatUnreadService._();

  static Future<void> markThreadRead(String peerId) async {
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me == null || peerId.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('Messages')
          .doc(me)
          .collection('messages')
          .doc(peerId)
          .set({
        'unread': false,
        'unreadCount': 0,
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) debugPrint('markThreadRead failed: $e');
    }
    await markPeerNotificationsRead(peerId);
  }

  static Future<void> markPeerNotificationsRead(String peerId) async {
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me == null || peerId.isEmpty) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('Notifications')
          .where('recipientId', isEqualTo: me)
          .get();
      final batch = FirebaseFirestore.instance.batch();
      var n = 0;
      for (final doc in snap.docs) {
        final data = doc.data();
        if (data['read'] == true) continue;
        if (!_notificationMatchesPeer(data, peerId)) continue;
        batch.set(
          doc.reference,
          {
            'read': true,
            'readAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        n += 1;
        if (n >= 40) break;
      }
      if (n > 0) await batch.commit();
    } catch (e) {
      if (kDebugMode) debugPrint('markPeerNotificationsRead failed: $e');
    }
  }

  static Future<void> markThreadReadFromNotification({
    required String? peerId,
    String? notificationId,
  }) async {
    if (notificationId != null && notificationId.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('Notifications')
            .doc(notificationId)
            .set({
          'read': true,
          'readAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
    final id = peerId?.trim() ?? '';
    if (id.isEmpty) return;
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('Messages')
          .doc(me)
          .collection('messages')
          .doc(id)
          .set({
        'unread': false,
        'unreadCount': 0,
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('markThreadReadFromNotification failed: $e');
      }
    }
  }

  static bool _notificationMatchesPeer(
    Map<String, dynamic> data,
    String peerId,
  ) {
    final nested = data['data'] is Map
        ? Map<String, dynamic>.from(data['data'] as Map)
        : const <String, dynamic>{};
    for (final key in [
      'senderId',
      'peerId',
      'doctorId',
      'patientId',
      'id',
    ]) {
      if (data[key]?.toString() == peerId) return true;
      if (nested[key]?.toString() == peerId) return true;
    }
    return false;
  }
}
