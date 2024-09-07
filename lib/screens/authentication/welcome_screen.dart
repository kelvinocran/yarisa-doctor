import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

import 'package:uicons_brands/uicons_brands.dart';
import 'package:yarisa_doctor/api/config.dart';
import 'package:yarisa_doctor/constants/yarisa_assets.dart';
import 'package:yarisa_doctor/constants/yarisa_constants.dart';
import 'package:yarisa_doctor/constants/yarisa_strings.dart';
import 'package:yarisa_doctor/extensions/yarisa_extensions.dart';
import 'package:yarisa_doctor/screens/authentication/sign_in_screen.dart';

import 'sign_up_screen.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: 20,
          left: -100,
          child: Opacity(
            opacity: .05,
            child: SvgPicture.asset(
              YarisaAssets.heartbeaticon,
              height: 500,
              // ignore: deprecated_member_use
              color: Colors.blueGrey,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.appname,
                style: context.headlineSmall,
              ),
              const Spacer(),
              RichText(
                  text: TextSpan(
                      text: "Offer ",
                      children: [
                        TextSpan(
                            text: "Medical Consultation ",
                            style: context.headlineMedium),
                        const TextSpan(text: "& "),
                        TextSpan(text: "Help ", style: context.headlineMedium),
                        const TextSpan(text: "to patients across the Globe.")
                      ],
                      style: context.headlineMedium?.copyWith(
                          color: Colors.purple.shade300.withOpacity(.7)))),
              50.hgap,
              if (Platform.isAndroid)
                ElevatedButton.icon(
                    onPressed: () {},
                    icon: Icon(
                      const UIconsBrands().google,
                      size: 20,
                    ),
                    label: const Text(AppStrings.signupwithgoogle)),
              if (Platform.isIOS)
                ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final cred =
                            await ref.read(authConfig).signInWithApple();
                        print(cred);
                      } catch (e) {
                        Logger().e(e);
                      }
                    },
                    icon: const Icon(Icons.apple_outlined),
                    label: const Text(AppStrings.signupwithapple)),
              10.hgap,
              ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SignUpScreen()));
                  },
                  style: ButtonStyle(
                      elevation: const WidgetStatePropertyAll(0),
                      foregroundColor: WidgetStatePropertyAll(
                          !Get.isDarkMode ? Colors.white : Colors.black),
                      backgroundColor: WidgetStateColor.resolveWith((states) {
                        if (states.contains(WidgetState.pressed)) {
                          return Colors.grey.withOpacity(.5);
                        }
                        if (Get.isDarkMode) {
                          return Colors.white;
                        } else {
                          return Colors.black;
                        }
                      })),
                  icon: const Icon(Icons.mark_email_read_outlined),
                  label: const Text(AppStrings.signupwithemail)),
              15.hgap,
              TextButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SignInScreen()));
                  },
                  style: ButtonStyle(
                    elevation: const WidgetStatePropertyAll(0),
                    foregroundColor: WidgetStatePropertyAll(
                        Get.isDarkMode ? Colors.white : Colors.black),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(AppStrings.ihaveanaccount),
                      10.wgap,
                      const Icon(Icons.navigate_next_rounded)
                    ],
                  )),
              50.hgap,
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                    text: "By continuing you confirm that you agree to our ",
                    children: [
                      TextSpan(
                          text: "Terms of Service",
                          style: context.bodyMedium?.copyWith(
                              decoration: TextDecoration.underline,
                              fontSize: YarisaDimens.bodySmall)),
                      const TextSpan(text: " and "),
                      TextSpan(
                          text: "Privacy Policy",
                          style: context.bodyMedium?.copyWith(
                              decoration: TextDecoration.underline,
                              fontSize: YarisaDimens.bodySmall))
                    ],
                    style: context.bodySmall),
              )
            ],
          ),
        ),
      ],
    )));
  }
}
