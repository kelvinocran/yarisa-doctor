import 'package:enefty_icons/enefty_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yarisa_doctor/screens/authentication/welcome_screen.dart';
import 'package:yarisa_doctor/ui/doctor_ui.dart';
import 'package:yarisa_doctor/widgets/confirmation_dialog.dart';

class MoreScreen extends ConsumerStatefulWidget {
  const MoreScreen({super.key});

  @override
  ConsumerState<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends ConsumerState<MoreScreen> {
  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url')),
      );
    }
  }

  void _showTextDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DoctorUi.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
    return DoctorScaffold(
      title: 'Help & support',
      subtitle: 'Contact us and legal information',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          const DoctorSectionHeader(title: 'Support'),
          DoctorCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _tile(
                  icon: EneftyIcons.sms_outline,
                  title: 'Email support',
                  subtitle: 'support@yarisa.health',
                  onTap: () => _launch(
                    'mailto:support@yarisa.health?subject=Yarisa%20Doctor%20Support',
                  ),
                ),
                Divider(height: 1, color: DoctorUi.border),
                _tile(
                  icon: EneftyIcons.global_outline,
                  title: 'Visit website',
                  subtitle: 'yarisa.health',
                  onTap: () => _launch('https://yarisa.health'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const DoctorSectionHeader(title: 'Legal'),
          DoctorCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _tile(
                  icon: EneftyIcons.document_outline,
                  title: 'Terms & conditions',
                  subtitle: 'How you may use Yarisa',
                  onTap: () => _showTextDialog(
                    'Terms & Conditions',
                    'These terms and conditions govern your use of the Yarisa Healthcare platform. '
                        'By using this app, you agree to these terms. '
                        'For the full terms, visit yarisa.health/terms.',
                  ),
                ),
                Divider(height: 1, color: DoctorUi.border),
                _tile(
                  icon: EneftyIcons.shield_outline,
                  title: 'Privacy policy',
                  subtitle: 'How we protect your data',
                  onTap: () => _showTextDialog(
                    'Privacy Policy',
                    'Yarisa Healthcare is committed to protecting your privacy. '
                        'We collect and use your data only to provide healthcare services. '
                        'For the full policy, visit yarisa.health/privacy.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const DoctorSectionHeader(title: 'About'),
          DoctorCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(EneftyIcons.info_circle_outline, color: DoctorUi.muted),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Yarisa Healthcare connects patients and doctors for appointments, messaging, prescriptions, and labs.',
                    style: TextStyle(
                      color: DoctorUi.muted,
                      height: 1.4,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // const SizedBox(height: 24),
          // Material(
          //   color: Colors.red.shade600,
          //   borderRadius: BorderRadius.circular(16),
          //   child: InkWell(
          //     onTap: _signOut,
          //     borderRadius: BorderRadius.circular(16),
          //     child: const Padding(
          //       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          //       child: Row(
          //         children: [
          //           Icon(EneftyIcons.logout_outline, color: Colors.white),
          //           SizedBox(width: 12),
          //           Expanded(
          //             child: Text(
          //               'Sign out',
          //               style: TextStyle(
          //                 color: Colors.white,
          //                 fontWeight: FontWeight.w800,
          //               ),
          //             ),
          //           ),
          //           Icon(Icons.chevron_right_rounded, color: Colors.white),
          //         ],
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
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
              Icon(Icons.chevron_right_rounded, color: DoctorUi.muted),
            ],
          ),
        ),
      ),
    );
  }
}
