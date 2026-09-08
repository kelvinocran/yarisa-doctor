import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:omni_jitsi_meet/jitsi_meet.dart';
import 'package:yarisa_doctor/services/call_session_service.dart';

/// Voice/video via embedded Jitsi Meet SDK ([omni_jitsi_meet]).
///
/// **Production:** Contabo self-host (see [JITSI_SELF_HOST_DOCKER.md]).
class YarisaJitsiCallService {
  /// Contabo self-hosted Jitsi. Swap to https://meet.yourdomain.com when DNS is ready.
  static String serverURL = 'https://169.58.215.253.sslip.io';

  /// Null for open self-host. Set only for JaaS / secured Prosody.
  static String? jwtToken;

  static String conversationRoom(String firstUserId, String secondUserId) {
    final ids = [firstUserId, secondUserId]..sort();
    return 'yarisa_chat_${ids.join('_')}';
  }

  static String appointmentRoom(String appointmentId) =>
      'yarisa_appt_$appointmentId';

  static String secondOpinionRoom(String requestId) => 'yarisa_so_$requestId';

  static Future<bool> join({
    required String room,
    required String type,
    required String subject,
    required String displayName,
    required String avatarUrl,
    required String email,
    String? token,
    bool trackSession = true,
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
          if (!trackSession) return;
          CallSessionService.markAnswered();
          if (myId != null) {
            CallSessionService.markParticipantJoined(userId: myId);
          }
        },
        onParticipantJoined: (email, name, role, participantId) {
          if (!trackSession) return;
          // Remote participant joined the conference.
          CallSessionService.markAnswered();
        },
        onConferenceTerminated: (_, __) {
          if (!trackSession) return;
          CallSessionService.end(status: 'ended');
        },
        onClosed: () {
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
