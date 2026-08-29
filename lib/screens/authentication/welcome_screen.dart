import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:uicons_brands/uicons_brands.dart';
import 'package:yarisa_doctor/api/api_methods.dart';
import 'package:yarisa_doctor/api/config.dart';
import 'package:yarisa_doctor/components/auth/auth_widgets.dart';
import 'package:yarisa_doctor/constants/yarisa_strings.dart';
import 'package:yarisa_doctor/ui/doctor_ui.dart';

import 'sign_in_screen.dart';
import 'sign_up_screen.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _busy = false;

  Future<void> _socialLanding(
    Future<dynamic> Function() signIn,
    String label,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final userCredential = await signIn();
      if (userCredential == null || !mounted) return;
      await ref.read(apimethods).openDoctorLanding(
            context,
            email: userCredential.user?.email,
            fullname: userCredential.user?.displayName,
          );
    } catch (e) {
      Logger().e(e);
      if (!mounted) return;
      showDoctorAuthSnack(context, '$label sign-in failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final isDark = DoctorUi.isDark;

    return DoctorAuthScaffold(
      showBack: false,
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Text(
            AppStrings.appname,
            style: theme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: DoctorUi.primary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 36),
          Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DoctorUi.primary,
                  DoctorUi.primary.withValues(alpha: .75),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: DoctorUi.primary.withValues(alpha: .28),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.health_and_safety_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Offer medical consultation & help to patients across the globe.',
            style: theme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.2,
              letterSpacing: -0.5,
              fontSize: 28,
              color: isDark ? Colors.white : const Color(0xFF1A1024),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Manage appointments, consultations, and patient care from one place.',
            style: theme.bodyMedium?.copyWith(
              color: DoctorUi.muted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 40),
          DoctorAuthPrimaryButton(
            label: AppStrings.signupwithemail,
            icon: Icons.mail_outline_rounded,
            onPressed: _busy
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SignUpScreen(),
                      ),
                    );
                  },
          ),
          const SizedBox(height: 12),
          DoctorAuthSecondaryButton(
            label: AppStrings.signupwithgoogle,
            icon: const UIconsBrands().google,
            onPressed: _busy
                ? null
                : () => _socialLanding(
                      () => ref.read(authConfig).signInWithGoogle(),
                      'Google',
                    ),
            foregroundColor: Colors.red.shade700,
          ),
          if (Platform.isIOS) ...[
            const SizedBox(height: 10),
            DoctorAuthSecondaryButton(
              label: AppStrings.signupwithapple,
              icon: Icons.apple,
              onPressed: _busy
                  ? null
                  : () => _socialLanding(
                        () => ref.read(authConfig).signInWithApple(),
                        'Apple',
                      ),
              backgroundColor: isDark ? Colors.white : Colors.black,
              foregroundColor: isDark ? Colors.black : Colors.white,
            ),
          ],
          const SizedBox(height: 20),
          TextButton(
            onPressed: _busy
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SignInScreen(),
                      ),
                    );
                  },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppStrings.ihaveanaccount,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: DoctorUi.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'By continuing you confirm that you agree to our Terms of Service and Privacy Policy.',
            textAlign: TextAlign.center,
            style: theme.bodySmall?.copyWith(
              color: DoctorUi.muted,
              height: 1.4,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
