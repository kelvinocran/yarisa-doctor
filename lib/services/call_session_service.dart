import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Persists call metadata: participants, start/end, duration, heartbeats.
class CallSessionService {
  CallSessionService._();

  static final _db = FirebaseFirestore.instance;
  static String? _activeSessionId;
  static DateTime? _startedAt;

  static String? get activeSessionId => _activeSessionId;

  static DocumentReference<Map<String, dynamic>> _sessionRef(String id) =>
      _db.collection('CallSessions').doc(id);

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
        'doctorId': myId,
        'patientId': peerId,
        'participants': [
          {
            'id': myId,
            'role': 'doctor',
            'name': me.displayName,
            'joinedAt': Timestamp.fromDate(now),
            'leftAt': null,
            'lastSeenAt': Timestamp.fromDate(now),
          },
          {
            'id': peerId,
            'role': 'patient',
            'name': peerName,
            'joinedAt': null,
            'leftAt': null,
            'lastSeenAt': null,
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
        'status': 'ongoing',
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
      final now = Timestamp.now();
      final updated = list.map((raw) {
        if (raw is! Map) return raw;
        final map = Map<String, dynamic>.from(raw);
        if (map['id']?.toString() == userId) {
          map['joinedAt'] ??= now;
          map['leftAt'] = null;
          map['lastSeenAt'] = now;
        }
        return map;
      }).toList();
      await _sessionRef(id).set({
        'participants': updated,
        'status': 'ongoing',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) debugPrint('CallSession participant join failed: $e');
    }
  }

  /// Heartbeat so peers know we are still in / waiting on this room.
  static Future<void> heartbeat({String? sessionId}) async {
    final id = sessionId ?? _activeSessionId;
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (id == null || me == null) return;
    try {
      final snap = await _sessionRef(id).get();
      final data = snap.data();
      if (data == null) return;
      final list = (data['participants'] as List?)?.toList() ?? [];
      final now = Timestamp.now();
      final updated = list.map((raw) {
        if (raw is! Map) return raw;
        final map = Map<String, dynamic>.from(raw);
        if (map['id']?.toString() == me) {
          map['lastSeenAt'] = now;
          map['leftAt'] = null;
        }
        return map;
      }).toList();
      await _sessionRef(id).set({
        'participants': updated,
        'status': data['status'] == 'ended' ? 'ended' : 'ongoing',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) debugPrint('CallSession heartbeat failed: $e');
    }
  }

  /// User left the Jitsi UI but session may still be joinable.
  static Future<void> markLocalLeft({String? sessionId}) async {
    final id = sessionId ?? _activeSessionId;
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (id == null || me == null) return;
    try {
      final snap = await _sessionRef(id).get();
      final data = snap.data();
      if (data == null) return;
      final list = (data['participants'] as List?)?.toList() ?? [];
      final now = Timestamp.now();
      final updated = list.map((raw) {
        if (raw is! Map) return raw;
        final map = Map<String, dynamic>.from(raw);
        if (map['id']?.toString() == me) {
          map['leftAt'] = now;
          map['lastSeenAt'] = now;
        }
        return map;
      }).toList();
      await _sessionRef(id).set({
        'participants': updated,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) debugPrint('CallSession markLocalLeft failed: $e');
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

  static void attachSession(String? id) {
    _activeSessionId = id;
    _startedAt ??= DateTime.now();
  }

  /// Live sessions for the signed-in user (client filters stale ones).
  static Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      watchMyActiveSessions() {
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me == null) {
      return Stream.value(const []);
    }
    // Single-field query (no composite index). Sort/filter client-side.
    return _db
        .collection('CallSessions')
        .where('participantIds', arrayContains: me)
        .limit(40)
        .snapshots()
        .map((snap) {
      final now = DateTime.now();
      final docs = snap.docs.where((d) {
        final data = d.data();
        final status = (data['status'] ?? '').toString();
        if (status == 'ended' ||
            status == 'declined' ||
            status == 'missed' ||
            status == 'ended_alone') {
          return false;
        }
        if (data['endedAt'] != null) return false;
        final updated = data['updatedAt'];
        if (updated is Timestamp) {
          if (now.difference(updated.toDate()) > const Duration(minutes: 3)) {
            return false;
          }
        }
        return true;
      }).toList();
      docs.sort((a, b) {
        final ta = a.data()['updatedAt'];
        final tb = b.data()['updatedAt'];
        final da = ta is Timestamp ? ta.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
        final db_ = tb is Timestamp ? tb.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
        return db_.compareTo(da);
      });
      return docs;
    });
  }

  static bool peerIsPresent(Map<String, dynamic> data, String peerId) {
    final list = data['participants'];
    if (list is! List) return false;
    final now = DateTime.now();
    for (final raw in list) {
      if (raw is! Map) continue;
      if (raw['id']?.toString() != peerId) continue;
      if (raw['leftAt'] != null) {
        // Left but maybe rejoined — check lastSeen fresher than leftAt
        final left = raw['leftAt'];
        final seen = raw['lastSeenAt'];
        if (left is Timestamp && seen is Timestamp) {
          if (seen.toDate().isAfter(left.toDate()) &&
              now.difference(seen.toDate()) < const Duration(seconds: 90)) {
            return true;
          }
        }
        return false;
      }
      final seen = raw['lastSeenAt'];
      if (seen is Timestamp) {
        return now.difference(seen.toDate()) < const Duration(seconds: 90);
      }
      return raw['joinedAt'] != null;
    }
    return false;
  }
}
