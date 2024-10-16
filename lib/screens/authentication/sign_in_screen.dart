import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:uicons_brands/uicons_brands.dart';
import 'package:yarisa_doctor/api/api_methods.dart';
import 'package:yarisa_doctor/components/formtextfield.dart';
import 'package:yarisa_doctor/constants/yarisa_constants.dart';
import 'package:yarisa_doctor/constants/yarisa_enums.dart';
import 'package:yarisa_doctor/constants/yarisa_strings.dart';
import 'package:yarisa_doctor/constants/yarisa_widgets.dart';
import 'package:yarisa_doctor/extensions/yarisa_extensions.dart';
import 'package:yarisa_doctor/screens/authentication/complete_profile.dart';
import 'package:yarisa_doctor/screens/main/base.dart';

import '../../api/config.dart';
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
  @override
  Widget build(BuildContext context) {
    final authenticating = ref.watch(apimethods).authenticating;
    return Scaffold(
        appBar: AppBar(),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: key,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const YarisaText(
                    text: AppStrings.signintoaccount,
                    type: TextType.heading,
                    weight: FontWeight.w600,
                    spacing: -1,
                    height: 1.1,
                    size: YarisaDimens.headlineMedium + 3,
                  ),
                  10.hgap,
                  const YarisaText(
                    text: AppStrings.signinsubtitle,
                    type: TextType.bodySmall,
                    // spacing: 0,
                    color: Colors.grey,
                  ),
                  50.hgap,
                  // if (Platform.isAndroid)
                  ElevatedButton.icon(
                      onPressed: authenticating ? null : () {},
                      icon: Icon(
                        const UIconsBrands().google,
                        size: 20,
                      ),
                      style: ButtonStyle(
                          elevation: const WidgetStatePropertyAll(0),
                          foregroundColor:
                              const WidgetStatePropertyAll(Colors.white),
                          backgroundColor:
                              WidgetStateColor.resolveWith((states) {
                            if (states.contains(WidgetState.pressed)) {
                              return Colors.grey.withOpacity(.5);
                            }

                            return Colors.red;
                          }),
                          minimumSize: const WidgetStatePropertyAll(
                              Size(double.infinity, 50))),
                      label: const Text(AppStrings.signinwithgoogle)),
                  10.hgap,
                  if (Platform.isIOS)
                    ElevatedButton.icon(
                        onPressed: authenticating
                            ? null
                            : () async {
                                try {
                                  final cred = await ref
                                      .read(authConfig)
                                      .signInWithApple();
                                  print(cred);
                                } catch (e) {
                                  Logger().e(e);
                                }
                              },
                        style: ButtonStyle(
                            elevation: const WidgetStatePropertyAll(0),
                            foregroundColor: WidgetStatePropertyAll(
                                !Get.isDarkMode ? Colors.white : Colors.black),
                            backgroundColor:
                                WidgetStateColor.resolveWith((states) {
                              if (states.contains(WidgetState.pressed)) {
                                return Colors.grey.withOpacity(.5);
                              }
                              if (Get.isDarkMode) {
                                return Colors.white;
                              } else {
                                return Colors.black;
                              }
                            }),
                            minimumSize: const WidgetStatePropertyAll(
                                Size(double.infinity, 50))),
                        icon: const Icon(Icons.apple_outlined),
                        label: const Text(AppStrings.signinwithapple)),
                  20.hgap,
                  const Row(
                    children: [
                      Expanded(
                        child: Divider(
                          endIndent: 15,
                        ),
                      ),
                      YarisaText(text: "OR", type: TextType.bodySmall),
                      Expanded(
                        child: Divider(
                          indent: 15,
                        ),
                      )
                    ],
                  ),
                  30.hgap,
                  FormTextField(
                      radius: 100,
                      controller: email,
                      enabled: !authenticating,
                      capitalization: TextCapitalization.none,
                      inputType: TextInputType.emailAddress,
                      validator: (p0) {
                        if (p0!.isEmpty) {
                          return AppStrings.provideemail;
                        }
                        if (!p0.isEmail) {
                          return AppStrings.invalidemail;
                        }
                        return null;
                      },
                      hint: AppStrings.emailexample,
                      label: AppStrings.email),
                  10.hgap,
                  FormTextField(
                    radius: 100,
                    enabled: !authenticating,
                    controller: password,
                    hint: AppStrings.password,
                    capitalization: TextCapitalization.none,
                    inputType: TextInputType.visiblePassword,
                    validator: (p0) {
                      if (p0!.isEmpty) {
                        return AppStrings.providepassword;
                      }
                      if (p0.length < 7) {
                        return AppStrings.invalidpassword;
                      }
                      return null;
                    },
                  ),
                  20.hgap,
                  Visibility(
                    visible: !authenticating,
                    replacement: const Center(
                      child: Loader(),
                    ),
                    child: ElevatedButton.icon(
                        onPressed: authenticating
                            ? null
                            : () async {
                                if (key.currentState!.validate()) {
                                  final api = ref.read(apimethods);
                                  api.signInUserAccount(
                                      email: email.text.trim(),
                                      password: password.text.trim(),
                                      onSuccess: (credential) async {
                                        await api.getUserProfile(
                                            onSuccess: (user) {
                                          Navigator.pushAndRemoveUntil(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      const BaseScreen()),
                                              (route) => false);
                                        }, onFailed: (user) {
                                          Navigator.pushAndRemoveUntil(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      const CompleteProfile()),
                                              (route) => false);
                                        });
                                      });
                                }
                              },
                        style: const ButtonStyle(
                            elevation: WidgetStatePropertyAll(0),
                            minimumSize: WidgetStatePropertyAll(
                                Size(double.infinity, 50))),
                        icon: const Icon(Icons.mark_email_read_outlined),
                        label: const Text(AppStrings.signinwithemail)),
                  ),
                  15.hgap,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const ForgotPasswordScreen()));
                          },
                          style: const ButtonStyle(
                            elevation: WidgetStatePropertyAll(0),
                          ),
                          child: const Text(AppStrings.forgotpassword)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}


