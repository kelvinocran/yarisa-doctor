import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:yarisa_doctor/components/auth/auth_widgets.dart';
import 'package:yarisa_doctor/components/formtextfield.dart';
import 'package:yarisa_doctor/constants/yarisa_strings.dart';
import 'package:yarisa_doctor/ui/doctor_ui.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final key = GlobalKey<FormState>();
  final email = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  Future<void> _requestReset() async {
    if (!key.currentState!.validate()) return;
    setState(() => isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email.text.trim(),
      );
      if (!mounted) return;
      showDoctorAuthSnack(
        context,
        'Password reset email sent! Check your inbox.',
        success: true,
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred';
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address.';
      } else if (e.message != null) {
        message = e.message!;
      }
      if (!mounted) return;
      showDoctorAuthSnack(context, message);
    } catch (_) {
      if (!mounted) return;
      showDoctorAuthSnack(
        context,
        'Failed to send reset email. Please try again.',
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DoctorAuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DoctorAuthHeader(
            title: AppStrings.forgotyourpassword,
            subtitle: AppStrings.forgotpasswordsubtitle,
            icon: Icons.password_rounded,
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
                    autoFocus: false,
                    filled: true,
                    fillColor: DoctorUi.fieldBg,
                    inputType: TextInputType.emailAddress,
                    capitalization: TextCapitalization.none,
                    action: TextInputAction.done,
                    enabled: !isLoading,
                    validator: (p0) {
                      if (p0 == null || p0.isEmpty) {
                        return AppStrings.provideemail;
                      }
                      if (!p0.isEmail) return AppStrings.invalidemail;
                      return null;
                    },
                    label: AppStrings.email,
                    hint: AppStrings.emailexample,
                  ),
                  const SizedBox(height: 20),
                  DoctorAuthPrimaryButton(
                    label: AppStrings.requestlink,
                    loading: isLoading,
                    icon: Icons.link_rounded,
                    onPressed: _requestReset,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: isLoading ? null : () => Navigator.pop(context),
            child: Text(
              'Back to sign in',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: DoctorUi.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
