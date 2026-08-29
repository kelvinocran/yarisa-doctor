import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

/// Tracks doctor online presence + availability-for-calls toggle.
class PresenceService with WidgetsBindingObserver {
  PresenceService._();
  static final PresenceService instance = PresenceService._();

  static const _collection = 'Doctors';
  bool _attached = false;

  /// When false, doctor appears offline to patients even if app is open.
  bool availableForCalls = true;

  void attach() {
    if (_attached) return;
    _attached = true;
    WidgetsBinding.instance.addObserver(this);
    _write(online: true);
  }

  void detach() {
    if (!_attached) return;
    WidgetsBinding.instance.removeObserver(this);
    _attached = false;
    _write(online: false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _write(online: true);
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _write(online: false);
        break;
    }
  }

  Future<void> setAvailableForCalls(bool value) async {
    availableForCalls = value;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection(_collection).doc(uid).set({
      'online': value ? true : false,
      'availableForCalls': value,
      'presence': {
        'online': value,
        'availableForCalls': value,
        'lastSeen': FieldValue.serverTimestamp(),
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> loadToggle() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final snap =
        await FirebaseFirestore.instance.collection(_collection).doc(uid).get();
    final data = snap.data();
    final v = data?['availableForCalls'];
    if (v is bool) {
      availableForCalls = v;
    } else if (data?['presence'] is Map) {
      final p = Map<String, dynamic>.from(data!['presence'] as Map);
      if (p['availableForCalls'] is bool) {
        availableForCalls = p['availableForCalls'] as bool;
      }
    }
  }

  Future<void> _write({required bool online}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final effective = online && availableForCalls;
    try {
      await FirebaseFirestore.instance.collection(_collection).doc(uid).set({
        'online': effective,
        'availableForCalls': availableForCalls,
        'presence': {
          'online': effective,
          'availableForCalls': availableForCalls,
          'lastSeen': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Live stream of a peer's online flag (Patients / Users / Doctors).
  static Stream<bool> watchOnline({
    required String collection,
    required String userId,
  }) {
    if (userId.isEmpty) {
      return Stream.value(false);
    }
    return FirebaseFirestore.instance
        .collection(collection)
        .doc(userId)
        .snapshots()
        .map((snap) {
      final data = snap.data();
      if (data == null) return false;
      if (data['availableForCalls'] == false) return false;
      if (data['online'] == true) return true;
      final p = data['presence'];
      if (p is Map && p['online'] == true) {
        if (p['availableForCalls'] == false) return false;
        return true;
      }
      return false;
    });
  }
}
