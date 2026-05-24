import 'package:enefty_icons/enefty_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/yarisa_enums.dart';
import '../constants/yarisa_strings.dart';
import '../constants/yarisa_widgets.dart';
import 'authentication/welcome_screen.dart';
import '../widgets/confirmation_dialog.dart';

class MoreScreen extends ConsumerStatefulWidget {
  const MoreScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MoreScreenState();
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
        title: Text(title),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Close'))
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
          (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const YarisaText(
          text: AppStrings.more,
          type: TextType.appbar,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            Text('SUPPORT',
                style: theme.bodySmall
                    ?.copyWith(color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            ListTile(
              onTap: () => _launch('tel:+233XXXXXXXXX'),
              leading: const Icon(EneftyIcons.call_outline),
              trailing: const Icon(Icons.chevron_right_rounded),
              title: const Text('Call Support'),
              subtitle: const Text('+233 XX XXX XXXX'),
            ),
            ListTile(
              onTap: () => _launch(
                  'mailto:support@yarisa.health?subject=Support%20Request'),
              leading: const Icon(EneftyIcons.sms_outline),
              trailing: const Icon(Icons.chevron_right_rounded),
              title: const Text('Email Support'),
              subtitle: const Text('support@yarisa.health'),
            ),
            ListTile(
              onTap: () => _launch('https://wa.me/233XXXXXXXXX'),
              leading: const Icon(EneftyIcons.message_outline),
              trailing: const Icon(Icons.chevron_right_rounded),
              title: const Text('WhatsApp Support'),
              subtitle: const Text('Chat with us on WhatsApp'),
            ),
            ListTile(
              onTap: () => _launch('https://yarisa.health'),
              leading: const Icon(EneftyIcons.global_outline),
              trailing: const Icon(Icons.chevron_right_rounded),
              title: const Text('Visit Website'),
              subtitle: const Text('yarisa.health'),
            ),
            const SizedBox(height: 24),
            Text('LEGAL',
                style: theme.bodySmall
                    ?.copyWith(color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            ListTile(
              onTap: () => _showTextDialog(
                'Terms & Conditions',
                'These terms and conditions govern your use of the Yarisa Healthcare platform. '
                    'By using this app, you agree to these terms. '
                    'For the full terms, visit yarisa.health/terms.',
              ),
              leading: const Icon(EneftyIcons.document_outline),
              trailing: const Icon(Icons.chevron_right_rounded),
              title: const Text('Terms & Conditions'),
            ),
            ListTile(
              onTap: () => _showTextDialog(
                'Privacy Policy',
                'Yarisa Healthcare is committed to protecting your privacy. '
                    'We collect and use your data only to provide healthcare services. '
                    'For the full policy, visit yarisa.health/privacy.',
              ),
              leading: const Icon(EneftyIcons.shield_outline),
              trailing: const Icon(Icons.chevron_right_rounded),
              title: const Text('Privacy Policy'),
            ),
            const SizedBox(height: 24),
            Text('APP',
                style: theme.bodySmall
                    ?.copyWith(color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            const ListTile(
              leading: Icon(EneftyIcons.info_circle_outline),
              title: Text('About Yarisa Healthcare'),
              subtitle: Text(
                  'Connecting patients and doctors seamlessly.\nVersion 1.0.1 (build 2)'),
            ),
            const SizedBox(height: 40),
            ListTile(
              tileColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              onTap: _signOut,
              trailing:
                  const Icon(Icons.chevron_right_rounded, color: Colors.white),
              leading:
                  const Icon(EneftyIcons.logout_outline, color: Colors.white),
              title: Text('Sign Out',
                  style: theme.bodyMedium?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
