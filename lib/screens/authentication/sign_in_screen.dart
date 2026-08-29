import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:uicons_brands/uicons_brands.dart';
import 'package:yarisa_doctor/api/api_methods.dart';
import 'package:yarisa_doctor/api/config.dart';
import 'package:yarisa_doctor/components/auth/auth_widgets.dart';
import 'package:yarisa_doctor/components/formtextfield.dart';
import 'package:yarisa_doctor/constants/yarisa_strings.dart';
import 'package:yarisa_doctor/ui/doctor_ui.dart';

import 'forgot_password_screen.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final key = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    try {
      final userCredential = await ref.read(authConfig).signInWithGoogle();
      if (userCredential == null || !mounted) return;
      await ref.read(apimethods).openDoctorLanding(
            context,
            email: userCredential.user?.email,
            fullname: userCredential.user?.displayName,
          );
    } catch (e) {
      Logger().e(e);
      if (!mounted) return;
      showDoctorAuthSnack(context, 'Google sign-in failed: $e');
    }
  }

  Future<void> _signInWithApple() async {
    try {
      final userCredential = await ref.read(authConfig).signInWithApple();
      if (userCredential == null || !mounted) return;
      await ref.read(apimethods).openDoctorLanding(
            context,
            email: userCredential.user?.email,
            fullname: userCredential.user?.displayName,
          );
    } catch (e) {
      Logger().e(e);
      if (!mounted) return;
      showDoctorAuthSnack(context, 'Apple sign-in failed: $e');
    }
  }

  Future<void> _signInWithEmail() async {
    if (!key.currentState!.validate()) return;
    final api = ref.read(apimethods);
    await api.signInUserAccount(
      email: email.text.trim(),
      password: password.text.trim(),
      onSuccess: (credential) async {
        if (!mounted) return;
        await api.openDoctorLanding(context);
      },
      onFailed: (error) {
        if (!mounted) return;
        showDoctorAuthSnack(context, error);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authenticating = ref.watch(apimethods).authenticating;

    return DoctorAuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DoctorAuthHeader(
            title: AppStrings.signintoaccount,
            subtitle: AppStrings.signinsubtitle,
            icon: Icons.lock_open_rounded,
          ),
          const SizedBox(height: 28),
          DoctorAuthCard(
            child: Form(
              key: key,
              child: Column(
                children: [
                  FormTextField(
                    radius: 14,
                    controller: email,
                    enabled: !authenticating,
                    autoFocus: false,
                    filled: true,
                    fillColor: DoctorUi.fieldBg,
                    capitalization: TextCapitalization.none,
                    inputType: TextInputType.emailAddress,
                    action: TextInputAction.next,
                    validator: (p0) {
                      if (p0 == null || p0.isEmpty) {
                        return AppStrings.provideemail;
                      }
                      if (!p0.isEmail) return AppStrings.invalidemail;
                      return null;
                    },
                    hint: AppStrings.emailexample,
                    label: AppStrings.email,
                  ),
                  const SizedBox(height: 12),
                  FormTextField(
                    radius: 14,
                    enabled: !authenticating,
                    controller: password,
                    hint: AppStrings.password,
                    autoFocus: false,
                    filled: true,
                    fillColor: DoctorUi.fieldBg,
                    capitalization: TextCapitalization.none,
                    inputType: TextInputType.visiblePassword,
                    action: TextInputAction.done,
                    lines: 1,
                    obscure: _obscurePassword,
                    endicon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey,
                      size: 20,
                    ),
                    endIconFunction: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    validator: (p0) {
                      if (p0 == null || p0.isEmpty) {
                        return AppStrings.providepassword;
                      }
                      if (p0.length < 6) return AppStrings.invalidpassword;
                      return null;
                    },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: authenticating
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const ForgotPasswordScreen(),
                                ),
                              );
                            },
                      child: const Text(
                        AppStrings.forgotpassword,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  DoctorAuthPrimaryButton(
                    label: AppStrings.signinwithemail,
                    loading: authenticating,
                    icon: Icons.mail_outline_rounded,
                    onPressed: _signInWithEmail,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          const DoctorAuthOrDivider(),
          const SizedBox(height: 18),
          DoctorAuthSecondaryButton(
            label: AppStrings.signinwithgoogle,
            icon: const UIconsBrands().google,
            onPressed: authenticating ? null : _signInWithGoogle,
            foregroundColor: Colors.red.shade700,
          ),
          if (Platform.isIOS) ...[
            const SizedBox(height: 10),
            DoctorAuthSecondaryButton(
              label: AppStrings.signinwithapple,
              icon: Icons.apple,
              onPressed: authenticating ? null : _signInWithApple,
              backgroundColor: DoctorUi.isDark ? Colors.white : Colors.black,
              foregroundColor: DoctorUi.isDark ? Colors.black : Colors.white,
            ),
          ],
        ],
      ),
    );
  }
}
