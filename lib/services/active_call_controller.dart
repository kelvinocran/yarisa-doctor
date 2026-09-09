import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:yarisa_doctor/services/call_session_service.dart';
import 'package:yarisa_doctor/services/jitsi_call_service.dart';

enum ActiveCallStatus { idle, inCall, disconnected, peerWaiting }

/// Tracks local + Firestore-backed call state for global banner / rejoin.
class ActiveCallController extends ChangeNotifier {
  ActiveCallController._();
  static final ActiveCallController instance = ActiveCallController._();

  ActiveCallStatus status = ActiveCallStatus.idle;
  String? sessionId;
  String? room;
  String callType = 'voice';
  String? peerId;
  String? peerName;
  DateTime? startedAt;
  int remoteParticipants = 0;
  bool peerPresent = false;

  Timer? _aloneTimer;
  Timer? _heartbeat;
  Timer? _tick;
  StreamSubscription? _watchSub;
  bool _started = false;

  static const aloneTimeout = Duration(seconds: 60);

  Duration get elapsed {
    final start = startedAt;
    if (start == null) return Duration.zero;
    return DateTime.now().difference(start);
  }

  String get elapsedLabel {
    final s = elapsed.inSeconds.clamp(0, 24 * 3600);
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final r = (s % 60).toString().padLeft(2, '0');
    return '$m:$r';
  }

  bool get showBanner =>
      status == ActiveCallStatus.inCall ||
      status == ActiveCallStatus.disconnected ||
      status == ActiveCallStatus.peerWaiting;

  String get bannerLabel {
    final name =
        peerName?.trim().isNotEmpty == true ? peerName! : 'Patient';
    switch (status) {
      case ActiveCallStatus.inCall:
        return 'On call · $name · $elapsedLabel';
      case ActiveCallStatus.disconnected:
        return peerPresent
            ? 'Rejoin · $name is still on the call'
            : 'Rejoin call · $name';
      case ActiveCallStatus.peerWaiting:
        return peerPresent
            ? 'Join · $name is waiting'
            : 'Open call · $name';
      case ActiveCallStatus.idle:
        return '';
    }
  }

  /// Call once after auth (BaseScreen / app ready).
  void startWatching() {
    if (_started) return;
    _started = true;
    _watchSub?.cancel();
    _watchSub = CallSessionService.watchMyActiveSessions().listen((docs) {
      _onSessions(docs);
    }, onError: (e) {
      if (kDebugMode) debugPrint('ActiveCall watch failed: $e');
    });
  }

  void stopWatching() {
    _watchSub?.cancel();
    _watchSub = null;
    _started = false;
  }

  void _onSessions(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me == null) return;

    // Prefer the session we are already bound to.
    QueryDocumentSnapshot<Map<String, dynamic>>? doc;
    if (sessionId != null) {
      for (final d in docs) {
        if (d.id == sessionId) {
          doc = d;
          break;
        }
      }
    }
    doc ??= docs.isEmpty ? null : docs.first;

    if (doc == null) {
      if (status != ActiveCallStatus.inCall) {
        _setIdle();
      }
      return;
    }

    final data = doc.data();
    final roomName = data['room']?.toString() ?? '';
    if (roomName.isEmpty) return;

    final doctorId = data['doctorId']?.toString() ?? '';
    final patientId = data['patientId']?.toString() ?? '';
    final peer = me == doctorId ? patientId : doctorId;
    final peerIsHere = CallSessionService.peerIsPresent(data, peer);

    sessionId = doc.id;
    room = roomName;
    callType = (data['callType'] ?? 'voice').toString();
    peerId = peer;
    peerName = _peerNameFrom(data, peer);
    peerPresent = peerIsHere;

    final started = data['startedAt'];
    if (started is Timestamp) startedAt ??= started.toDate();

    if (status == ActiveCallStatus.inCall) {
      notifyListeners();
      return;
    }

    // Local left but session still active → rejoin.
    final iLeft = _localLeft(data, me);
    if (iLeft && (peerIsHere || _sessionFresh(data))) {
      status = ActiveCallStatus.disconnected;
      notifyListeners();
      return;
    }

    // Never joined / waiting while peer is present.
    if (!iLeft && peerIsHere) {
      status = ActiveCallStatus.peerWaiting;
      notifyListeners();
      return;
    }

    if (_sessionFresh(data)) {
      status = ActiveCallStatus.disconnected;
      notifyListeners();
    }
  }

  bool _sessionFresh(Map<String, dynamic> data) {
    final updated = data['updatedAt'];
    if (updated is! Timestamp) return true;
    return DateTime.now().difference(updated.toDate()) <
        const Duration(minutes: 3);
  }

  bool _localLeft(Map<String, dynamic> data, String me) {
    final list = data['participants'];
    if (list is! List) return false;
    for (final raw in list) {
      if (raw is! Map) continue;
      if (raw['id']?.toString() != me) continue;
      return raw['leftAt'] != null;
    }
    return false;
  }

  String? _peerNameFrom(Map<String, dynamic> data, String peer) {
    final list = data['participants'];
    if (list is List) {
      for (final raw in list) {
        if (raw is! Map) continue;
        if (raw['id']?.toString() == peer) {
          final n = raw['name']?.toString();
          if (n != null && n.trim().isNotEmpty) return n;
        }
      }
    }
    return null;
  }

  void bindOutgoing({
    required String room,
    required String callType,
    required String peerId,
    String? peerName,
    String? sessionId,
  }) {
    this.room = room;
    this.callType = callType;
    this.peerId = peerId;
    this.peerName = peerName;
    this.sessionId = sessionId ?? CallSessionService.activeSessionId;
    CallSessionService.attachSession(this.sessionId);
    startedAt = DateTime.now();
    remoteParticipants = 0;
    peerPresent = false;
    status = ActiveCallStatus.inCall;
    _startTick();
    _startHeartbeat();
    notifyListeners();
  }

  void onJoined() {
    status = ActiveCallStatus.inCall;
    startedAt ??= DateTime.now();
    _startTick();
    _startHeartbeat();
    _armAloneTimer();
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me != null) {
      CallSessionService.markParticipantJoined(userId: me);
      CallSessionService.markAnswered();
    }
    notifyListeners();
  }

  void onRemoteJoined() {
    remoteParticipants += 1;
    peerPresent = true;
    _aloneTimer?.cancel();
    notifyListeners();
  }

  void onRemoteLeft() {
    remoteParticipants = (remoteParticipants - 1).clamp(0, 99);
    if (remoteParticipants == 0) peerPresent = false;
    _armAloneTimer();
    notifyListeners();
  }

  Future<void> onTerminated({bool userEnded = false}) async {
    _heartbeat?.cancel();
    _aloneTimer?.cancel();
    _tick?.cancel();

    if (userEnded) {
      await CallSessionService.end(status: 'ended');
      _setIdle();
      return;
    }

    // Soft leave — keep session joinable for peer.
    await CallSessionService.markLocalLeft();
    status = ActiveCallStatus.disconnected;
    notifyListeners();
  }

  Future<void> rejoin() async {
    final r = room;
    if (r == null || r.isEmpty) return;
    final me = FirebaseAuth.instance.currentUser;
    status = ActiveCallStatus.inCall;
    _startTick();
    _startHeartbeat();
    notifyListeners();
    await YarisaJitsiCallService.join(
      room: r,
      type: callType,
      subject: callType == 'video' ? 'Video call' : 'Voice call',
      displayName: me?.displayName ?? 'Doctor',
      avatarUrl: me?.photoURL ?? '',
      email: me?.email ?? '',
      peerId: peerId,
      peerName: peerName,
      trackSession: true,
    );
  }

  Future<void> hangUp({String reason = 'ended'}) async {
    _heartbeat?.cancel();
    try {
      await YarisaJitsiCallService.close();
    } catch (_) {}
    await CallSessionService.end(status: reason);
    _setIdle();
  }

  void _setIdle() {
    _aloneTimer?.cancel();
    _heartbeat?.cancel();
    _tick?.cancel();
    status = ActiveCallStatus.idle;
    sessionId = null;
    room = null;
    peerId = null;
    peerName = null;
    startedAt = null;
    remoteParticipants = 0;
    peerPresent = false;
    notifyListeners();
  }

  void clear() => _setIdle();

  void _startTick() {
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (status == ActiveCallStatus.inCall) notifyListeners();
    });
  }

  void _startHeartbeat() {
    _heartbeat?.cancel();
    CallSessionService.heartbeat();
    _heartbeat = Timer.periodic(const Duration(seconds: 20), (_) {
      if (status == ActiveCallStatus.inCall) {
        CallSessionService.heartbeat();
      }
    });
  }

  void _armAloneTimer() {
    _aloneTimer?.cancel();
    if (status != ActiveCallStatus.inCall) return;
    if (remoteParticipants > 0) return;
    _aloneTimer = Timer(aloneTimeout, () async {
      if (remoteParticipants > 0 || status != ActiveCallStatus.inCall) return;
      if (kDebugMode) debugPrint('ActiveCall: alone timeout → hang up');
      await hangUp(reason: 'ended_alone');
    });
  }

  @override
  void dispose() {
    stopWatching();
    _aloneTimer?.cancel();
    _heartbeat?.cancel();
    _tick?.cancel();
    super.dispose();
  }
}
