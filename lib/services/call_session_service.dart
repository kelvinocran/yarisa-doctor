import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Persists call metadata: participants, start/end, duration.
class CallSessionService {
  CallSessionService._();

  static final _db = FirebaseFirestore.instance;
  static String? _activeSessionId;
  static DateTime? _startedAt;

  static String? get activeSessionId => _activeSessionId;

  static DocumentReference<Map<String, dynamic>> _sessionRef(String id) =>
      _db.collection('CallSessions').doc(id);

  /// Create a ringing/answered session before or as the call starts.
  static Future<String?> start({
    required String room,
    required String peerId,
    required String callType,
    required String direction, // outbound | inbound
    String? peerName,
  }) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return null;

    final ref = _db.collection('CallSessions').doc();
    final now = DateTime.now();
    _activeSessionId = ref.id;
    _startedAt = now;

    final myId = me.uid;
    final ids = [myId, peerId]..sort();

    try {
      await ref.set({
        'callId': ref.id,
        'room': room,
        'callType': callType,
        'status': 'ringing',
        'direction': direction,
        'callerId': direction == 'outbound' ? myId : peerId,
        'calleeId': direction == 'outbound' ? peerId : myId,
        // Doctor app: current user is always the doctor.
        'doctorId': myId,
        'patientId': peerId,
        'participants': [
          {
            'id': myId,
            'role': 'doctor',
            'name': me.displayName,
            'joinedAt': Timestamp.fromDate(now),
          },
          {
            'id': peerId,
            'role': 'patient',
            'name': peerName,
            'joinedAt': null,
          },
        ],
        'participantIds': ids,
        'startedAt': Timestamp.fromDate(now),
        'endedAt': null,
        'durationSec': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) debugPrint('CallSession start failed: $e');
      _activeSessionId = null;
      _startedAt = null;
      return null;
    }
    return ref.id;
  }

  static Future<void> markAnswered({String? sessionId}) async {
    final id = sessionId ?? _activeSessionId;
    if (id == null) return;
    try {
      await _sessionRef(id).set({
        'status': 'answered',
        'answeredAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) debugPrint('CallSession markAnswered failed: $e');
    }
  }

  static Future<void> markParticipantJoined({
    required String userId,
    String? sessionId,
  }) async {
    final id = sessionId ?? _activeSessionId;
    if (id == null) return;
    try {
      final snap = await _sessionRef(id).get();
      final data = snap.data();
      final list = (data?['participants'] as List?)?.toList() ?? [];
      final updated = list.map((raw) {
        if (raw is! Map) return raw;
        final map = Map<String, dynamic>.from(raw);
        if (map['id']?.toString() == userId && map['joinedAt'] == null) {
          map['joinedAt'] = Timestamp.now();
        }
        return map;
      }).toList();
      await _sessionRef(id).set({
        'participants': updated,
        'status': 'answered',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) debugPrint('CallSession participant join failed: $e');
    }
  }

  static Future<void> end({
    String? sessionId,
    String status = 'ended',
  }) async {
    final id = sessionId ?? _activeSessionId;
    if (id == null) return;
    final started = _startedAt;
    final ended = DateTime.now();
    final durationSec =
        started == null ? null : ended.difference(started).inSeconds;

    try {
      await _sessionRef(id).set({
        'status': status,
        'endedAt': Timestamp.fromDate(ended),
        if (durationSec != null) 'durationSec': durationSec,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) debugPrint('CallSession end failed: $e');
    } finally {
      if (id == _activeSessionId) {
        _activeSessionId = null;
        _startedAt = null;
      }
    }
  }
}
