import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:yarisa_doctor/api/api_methods.dart';
import 'package:yarisa_doctor/components/auth/auth_widgets.dart';
import 'package:yarisa_doctor/components/formtextfield.dart';
import 'package:yarisa_doctor/constants/yarisa_strings.dart';
import 'package:yarisa_doctor/screens/authentication/complete_profile.dart';
import 'package:yarisa_doctor/ui/doctor_ui.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final key = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!key.currentState!.validate()) return;
    final api = ref.read(apimethods);
    await api.signUpUserAccount(
      email: email.text.trim(),
      password: password.text.trim(),
      fullname: name.text.trim(),
      onSuccess: (credential) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CompleteProfile(
              email: email.text.trim(),
              fullname: name.text.trim(),
            ),
          ),
        );
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
            title: AppStrings.joinyarisa,
            subtitle: AppStrings.createaccountsubtitle,
            icon: Icons.person_add_alt_1_rounded,
          ),
          const SizedBox(height: 28),
          DoctorAuthCard(
            child: Form(
              key: key,
              child: Column(
                children: [
                  FormTextField(
                    radius: 14,
                    controller: name,
                    autoFocus: false,
                    filled: true,
                    fillColor: DoctorUi.fieldBg,
                    inputType: TextInputType.name,
                    capitalization: TextCapitalization.words,
                    action: TextInputAction.next,
                    enabled: !authenticating,
                    validator: (p0) {
                      if (p0 == null || p0.isEmpty) {
                        return AppStrings.providename;
                      }
                      return null;
                    },
                    label: AppStrings.name,
                    hint: AppStrings.nameexample,
                  ),
                  const SizedBox(height: 12),
                  FormTextField(
                    radius: 14,
                    controller: email,
                    autoFocus: false,
                    filled: true,
                    fillColor: DoctorUi.fieldBg,
                    inputType: TextInputType.emailAddress,
                    capitalization: TextCapitalization.none,
                    action: TextInputAction.next,
                    enabled: !authenticating,
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
                  const SizedBox(height: 12),
                  FormTextField(
                    radius: 14,
                    controller: password,
                    autoFocus: false,
                    filled: true,
                    fillColor: DoctorUi.fieldBg,
                    inputType: TextInputType.visiblePassword,
                    capitalization: TextCapitalization.none,
                    action: TextInputAction.done,
                    enabled: !authenticating,
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
                    hint: AppStrings.password,
                    label: AppStrings.password,
                  ),
                  const SizedBox(height: 20),
                  DoctorAuthPrimaryButton(
                    label: AppStrings.signupwithemail,
                    loading: authenticating,
                    icon: Icons.mail_outline_rounded,
                    onPressed: _signUp,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'After signing up you will complete your professional profile for verification.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: DoctorUi.muted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
