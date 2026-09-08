import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:omni_jitsi_meet/jitsi_meet.dart';
import 'package:yarisa_doctor/services/active_call_controller.dart';
import 'package:yarisa_doctor/services/call_session_service.dart';

/// Voice/video via embedded Jitsi Meet SDK ([omni_jitsi_meet]).
class YarisaJitsiCallService {
  static String serverURL = 'https://169.58.215.253.sslip.io';
  static String? jwtToken;

  static String conversationRoom(String firstUserId, String secondUserId) {
    final ids = [firstUserId, secondUserId]..sort();
    return 'yarisa_chat_${ids.join('_')}';
  }

  static String appointmentRoom(String appointmentId) =>
      'yarisa_appt_$appointmentId';

  static String secondOpinionRoom(String requestId) => 'yarisa_so_$requestId';

  static Future<void> close() async {
    try {
      await JitsiMeet.closeMeeting();
    } catch (_) {}
  }

  static Future<bool> join({
    required String room,
    required String type,
    required String subject,
    required String displayName,
    required String avatarUrl,
    required String email,
    String? token,
    bool trackSession = true,
    String? peerId,
    String? peerName,
  }) async {
    try {
      final features = <FeatureFlagEnum, Object>{
        FeatureFlagEnum.ADD_PEOPLE_ENABLED: false,
        FeatureFlagEnum.CHAT_ENABLED: false,
        FeatureFlagEnum.LOBBY_MODE_ENABLED: false,
        FeatureFlagEnum.WELCOME_PAGE_ENABLED: false,
        FeatureFlagEnum.INVITE_ENABLED: false,
        FeatureFlagEnum.CAR_MODE_ENABLED: false,
        FeatureFlagEnum.LIVE_STREAMING_ENABLED: false,
        FeatureFlagEnum.FILMSTRIP_ENABLED: false,
        FeatureFlagEnum.PREJOIN_PAGE_ENABLED: false,
        FeatureFlagEnum.SECURITY_OPTIONS_ENABLED: false,
        FeatureFlagEnum.VIDEO_SHARE_BUTTON_ENABLED: false,
        FeatureFlagEnum.RECORDING_ENABLED: false,
        FeatureFlagEnum.REACTIONS_ENABLED: false,
        FeatureFlagEnum.SETTINGS_ENABLED: false,
        FeatureFlagEnum.RAISE_HAND_ENABLED: false,
        FeatureFlagEnum.CLOSE_CAPTIONS_ENABLED: false,
        FeatureFlagEnum.MEETING_PASSWORD_ENABLED: false,
        FeatureFlagEnum.NOTIFICATIONS_ENABLED: false,
        FeatureFlagEnum.CALL_INTEGRATION_ENABLED: false,
        FeatureFlagEnum.ANDROID_SCREENSHARING_ENABLED: false,
        FeatureFlagEnum.PIP_ENABLED: true,
        FeatureFlagEnum.TOOLBOX_ALWAYS_VISIBLE: true,
      };

      final configOverrides = <String, Object?>{
        'prejoinPageEnabled': false,
        'prejoinConfig': {'enabled': false},
        'enableLobbyChat': false,
        'hideConferenceSubject': false,
        'disableDeepLinking': true,
        'startWithAudioMuted': false,
        'startWithVideoMuted': type != 'video',
        'disableModeratorIndicator': true,
        'enableNoisyMicDetection': true,
        'requireDisplayName': false,
        'enableWelcomePage': false,
        'enableClosePage': false,
        'p2p': {'enabled': true},
      };

      final effectiveToken = token ?? jwtToken;
      final myId = FirebaseAuth.instance.currentUser?.uid;
      final active = ActiveCallController.instance;

      if (peerId != null && peerId.isNotEmpty) {
        active.bindOutgoing(
          room: room,
          callType: type,
          peerId: peerId,
          peerName: peerName,
        );
      } else if (active.room != room) {
        active.bindOutgoing(
          room: room,
          callType: type,
          peerId: active.peerId ?? '',
          peerName: active.peerName,
        );
      }

      final options = JitsiMeetingOptions(
        room: room,
        serverURL: serverURL,
        subject: subject,
        token: effectiveToken,
        userDisplayName:
            displayName.trim().isEmpty ? 'Doctor' : displayName.trim(),
        userAvatarURL: avatarUrl,
        userEmail: email,
        audioOnly: type != 'video',
        audioMuted: false,
        videoMuted: type != 'video',
        featureFlags: features,
        configOverrides: configOverrides,
      );

      if (kDebugMode) {
        debugPrint(
          'Jitsi join room=$room server=$serverURL token=${effectiveToken != null}',
        );
      }

      final listener = JitsiMeetingListener(
        onConferenceJoined: (_) {
          active.onJoined();
          if (!trackSession) return;
          CallSessionService.markAnswered();
          if (myId != null) {
            CallSessionService.markParticipantJoined(userId: myId);
          }
        },
        onParticipantJoined: (email, name, role, participantId) {
          active.onRemoteJoined();
          if (!trackSession) return;
          CallSessionService.markAnswered();
        },
        onParticipantLeft: (participantId) {
          active.onRemoteLeft();
        },
        onConferenceTerminated: (_, __) {
          active.onTerminated(userEnded: false);
          if (!trackSession) return;
          CallSessionService.end(status: 'ended');
        },
        onClosed: () {
          active.onTerminated(userEnded: false);
          if (!trackSession) return;
          CallSessionService.end(status: 'ended');
        },
      );

      await JitsiMeet.joinMeeting(options, listener: listener);
      return true;
    } on MissingPluginException catch (_) {
      _showUnavailableMessage();
      return false;
    } on PlatformException catch (error) {
      _snack(
        'Call unavailable',
        error.message ??
            'Unable to start the call on this device (simulators often lack the Jitsi plugin).',
      );
      return false;
    } catch (error) {
      debugPrint('Jitsi call failed: $error');
      final text = error.toString();
      if (text.contains('MissingPluginException') ||
          text.contains('jitsi_meet')) {
        _showUnavailableMessage();
        return false;
      }
      _snack('Call unavailable', 'Unable to start the call right now.');
      return false;
    }
  }

  static void _showUnavailableMessage() {
    _snack(
      'Call unavailable on this device',
      'Voice/video needs a full native rebuild. Use a physical device or Android emulator — iOS Simulator often cannot run Jitsi.',
    );
  }

  static void _snack(String title, String message) {
    try {
      Get.snackbar(title, message, snackPosition: SnackPosition.BOTTOM);
    } catch (_) {
      debugPrint('$title: $message');
    }
  }
}
