import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:omni_jitsi_meet/jitsi_meet.dart';

class YarisaJitsiCallService {
  static Future<bool> join({
    required String room,
    required String type,
    required String subject,
    required String displayName,
    required String avatarUrl,
    required String email,
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
        FeatureFlagEnum.FULLSCREEN_ENABLED: true,
        FeatureFlagEnum.PREJOIN_PAGE_ENABLED: false,
        FeatureFlagEnum.SECURITY_OPTIONS_ENABLED: false,
        FeatureFlagEnum.VIDEO_SHARE_BUTTON_ENABLED: false,
        FeatureFlagEnum.RECORDING_ENABLED: false,
        FeatureFlagEnum.REACTIONS_ENABLED: false,
        FeatureFlagEnum.SETTINGS_ENABLED: false,
        FeatureFlagEnum.RAISE_HAND_ENABLED: false,
        FeatureFlagEnum.CLOSE_CAPTIONS_ENABLED: false,
      };

      final options = JitsiMeetingOptions(
        room: room,
        serverURL: "https://meet.jit.si",
        subject: subject,
        userDisplayName: displayName,
        userAvatarURL: avatarUrl,
        userEmail: email,
        audioOnly: type != "video",
        audioMuted: false,
        videoMuted: type != "video",
        featureFlags: features,
      );

      await JitsiMeet.joinMeeting(options);
      return true;
    } on MissingPluginException catch (_) {
      _showUnavailableMessage();
      return false;
    } on PlatformException catch (error) {
      Get.snackbar(
        "Call unavailable",
        error.message ?? "Unable to start the call on this device.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } catch (error) {
      debugPrint("Jitsi call failed: $error");
      Get.snackbar(
        "Call unavailable",
        "Unable to start the call right now.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  static void _showUnavailableMessage() {
    Get.snackbar(
      "Call unavailable",
      "Video and voice calls need a native Jitsi build. Run a full rebuild on Android or a physical iOS device.",
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
