import 'package:enefty_icons/enefty_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:yarisa_doctor/api/api_methods.dart';
import 'package:yarisa_doctor/constants/yarisa_constants.dart';
import 'package:yarisa_doctor/models/user_model.dart';
import 'package:yarisa_doctor/screens/authentication/welcome_screen.dart';
import 'package:yarisa_doctor/screens/edit_profile_screen.dart';
import 'package:yarisa_doctor/screens/more_screen.dart';
import 'package:yarisa_doctor/screens/notification_preferences_screen.dart';
import 'package:yarisa_doctor/services/deep_link_router.dart';
import 'package:yarisa_doctor/services/doctor_profile_photo.dart';
import 'package:yarisa_doctor/services/presence_service.dart';
import 'package:yarisa_doctor/ui/doctor_ui.dart';
import 'package:yarisa_doctor/widgets/confirmation_dialog.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _uploadingPic = false;
  String _versionLabel = '…';
  bool _availableForCalls = true;
  bool _togglingAvailability = false;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (!mounted) return;
      setState(() {
        _versionLabel = '${info.version} (${info.buildNumber})';
      });
    }).catchError((_) {});
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    await PresenceService.instance.loadToggle();
    if (!mounted) return;
    setState(() {
      _availableForCalls = PresenceService.instance.availableForCalls;
    });
  }

  Future<void> _setAvailableForCalls(bool value) async {
    setState(() {
      _availableForCalls = value;
      _togglingAvailability = true;
    });
    try {
      await PresenceService.instance.setAvailableForCalls(value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? 'You are available for calls'
                  : 'You appear offline to patients',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _availableForCalls = !value);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update availability: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _togglingAvailability = false);
    }
  }

  Future<void> _updateProfilePic() async {
    if (_uploadingPic) return;
    setState(() => _uploadingPic = true);
    try {
      await DoctorProfilePhoto.pickAndUpload(context, ref);
    } finally {
      if (mounted) setState(() => _uploadingPic = false);
    }
  }

  void _openEditProfile(UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(initialUser: user),
      ),
    );
  }

  Future<void> _sendPasswordReset() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset email sent to $email')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send reset email: $e')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showYarisaConfirmationDialog(
      context,
      title: 'Sign out?',
      message: 'You will need to sign in again to manage your Yarisa account.',
      confirmLabel: 'Sign Out',
      icon: EneftyIcons.logout_outline,
      isDestructive: true,
    );
    if (!confirmed) return;
    PresenceService.instance.detach();
    DeepLinkRouter.reset();
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(apimethods).userAccount;

    return DoctorScaffold(
      title: 'Settings',
      subtitle: 'Account, notifications, and support',
      showBack: Navigator.of(context).canPop(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          DoctorCard(
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleImage(size: 64, image: user?.pic),
                    if (_uploadingPic)
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullname ?? 'Doctor',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      if ((user?.speciality ?? '').isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          user!.speciality!,
                          style: TextStyle(color: DoctorUi.muted, fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        user?.email ??
                            FirebaseAuth.instance.currentUser?.email ??
                            '',
                        style: TextStyle(color: DoctorUi.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const DoctorSectionHeader(title: 'Account'),
          DoctorCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingsTile(
                  icon: EneftyIcons.image_outline,
                  title: 'Update profile photo',
                  subtitle: 'Choose a clear headshot',
                  trailing: _uploadingPic
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  onTap: _updateProfilePic,
                ),
                _divider(),
                _SettingsTile(
                  icon: EneftyIcons.edit_2_outline,
                  title: 'Edit profile',
                  subtitle: 'Name, speciality, bio, clinic',
                  onTap: () {
                    if (user != null) _openEditProfile(user);
                  },
                ),
                _divider(),
                _SettingsTile(
                  icon: EneftyIcons.lock_outline,
                  title: 'Change password',
                  subtitle: 'We will email you a reset link',
                  onTap: _sendPasswordReset,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const DoctorSectionHeader(title: 'Availability'),
          DoctorCard(
            padding: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: DoctorUi.primary.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _availableForCalls
                          ? EneftyIcons.wifi_outline
                          : EneftyIcons.wifi_square_outline,
                      color: DoctorUi.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Available for calls',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _availableForCalls
                              ? 'Patients see you as online'
                              : 'You appear offline even if the app is open',
                          style: TextStyle(
                            color: DoctorUi.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_togglingAvailability)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Switch.adaptive(
                      value: _availableForCalls,
                      activeTrackColor: DoctorUi.primary.withValues(alpha: .45),
                      activeThumbColor: DoctorUi.primary,
                      onChanged: _setAvailableForCalls,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const DoctorSectionHeader(title: 'Preferences'),
          DoctorCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingsTile(
                  icon: EneftyIcons.notification_outline,
                  title: 'Notification preferences',
                  subtitle: 'Choose which alerts you receive',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const DoctorNotificationPreferencesScreen(),
                      ),
                    );
                  },
                ),
                _divider(),
                _SettingsTile(
                  icon: EneftyIcons.message_question_outline,
                  title: 'Help & support',
                  subtitle: 'Contact us and legal info',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MoreScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const DoctorSectionHeader(title: 'About'),
          DoctorCard(
            child: Row(
              children: [
                Icon(EneftyIcons.info_circle_outline, color: DoctorUi.muted),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'App version',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _versionLabel,
                        style: TextStyle(color: DoctorUi.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Material(
            color: Colors.red.shade600,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: _signOut,
              borderRadius: BorderRadius.circular(16),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Icon(EneftyIcons.logout_outline, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sign out',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Log out of your Yarisa doctor account',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(height: 1, color: DoctorUi.border);

}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: DoctorUi.primary.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: DoctorUi.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: DoctorUi.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              trailing ??
                  Icon(Icons.chevron_right_rounded, color: DoctorUi.muted),
            ],
          ),
        ),
      ),
    );
  }
}
