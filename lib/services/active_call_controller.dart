import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:yarisa_doctor/services/call_session_service.dart';
import 'package:yarisa_doctor/services/jitsi_call_service.dart';

enum ActiveCallStatus { idle, inCall, disconnected }

/// Tracks the current / last Jitsi call for floating chip + rejoin + alone timer.
class ActiveCallController extends ChangeNotifier {
  ActiveCallController._();
  static final ActiveCallController instance = ActiveCallController._();

  ActiveCallStatus status = ActiveCallStatus.idle;
  String? room;
  String callType = 'voice';
  String? peerId;
  String? peerName;
  DateTime? startedAt;
  int remoteParticipants = 0;

  Timer? _aloneTimer;
  Timer? _rejoinExpiry;
  Timer? _tick;
  static const aloneTimeout = Duration(seconds: 60);
  static const rejoinWindow = Duration(minutes: 12);

  Duration get elapsed {
    final start = startedAt;
    if (start == null) return Duration.zero;
    return DateTime.now().difference(start);
  }

  String get elapsedLabel {
    final s = elapsed.inSeconds;
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final r = (s % 60).toString().padLeft(2, '0');
    return '$m:$r';
  }

  void bindOutgoing({
    required String room,
    required String callType,
    required String peerId,
    String? peerName,
  }) {
    this.room = room;
    this.callType = callType;
    this.peerId = peerId;
    this.peerName = peerName;
    startedAt = DateTime.now();
    remoteParticipants = 0;
    status = ActiveCallStatus.inCall;
    _startTick();
    _rejoinExpiry?.cancel();
    notifyListeners();
  }

  void onJoined() {
    status = ActiveCallStatus.inCall;
    startedAt ??= DateTime.now();
    _startTick();
    _armAloneTimer();
    notifyListeners();
  }

  void onRemoteJoined() {
    remoteParticipants += 1;
    _aloneTimer?.cancel();
    notifyListeners();
  }

  void onRemoteLeft() {
    remoteParticipants = (remoteParticipants - 1).clamp(0, 99);
    _armAloneTimer();
    notifyListeners();
  }

  void onTerminated({bool userEnded = false}) {
    final wasInCall = status == ActiveCallStatus.inCall;
    if (userEnded || !wasInCall) {
      clear();
      return;
    }
    status = ActiveCallStatus.disconnected;
    _aloneTimer?.cancel();
    _tick?.cancel();
    _rejoinExpiry?.cancel();
    _rejoinExpiry = Timer(rejoinWindow, clear);
    notifyListeners();
  }

  Future<void> rejoin() async {
    final r = room;
    if (r == null || r.isEmpty) return;
    status = ActiveCallStatus.inCall;
    _startTick();
    notifyListeners();
    await YarisaJitsiCallService.join(
      room: r,
      type: callType,
      subject: callType == 'video' ? 'Video call' : 'Voice call',
      displayName: 'Doctor',
      avatarUrl: '',
      email: '',
      trackSession: true,
    );
  }

  Future<void> hangUp({String reason = 'ended'}) async {
    try {
      await YarisaJitsiCallService.close();
    } catch (_) {}
    await CallSessionService.end(status: reason);
    clear();
  }

  void clear() {
    _aloneTimer?.cancel();
    _rejoinExpiry?.cancel();
    _tick?.cancel();
    status = ActiveCallStatus.idle;
    room = null;
    peerId = null;
    peerName = null;
    startedAt = null;
    remoteParticipants = 0;
    notifyListeners();
  }

  void _startTick() {
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (status == ActiveCallStatus.inCall) notifyListeners();
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
}
