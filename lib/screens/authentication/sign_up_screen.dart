import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:yarisa_doctor/constants/yarisa_strings.dart';
import 'package:yarisa_doctor/extensions/yarisa_extensions.dart';
import 'package:yarisa_doctor/screens/authentication/complete_profile.dart';

import '../../components/formtextfield.dart';
import '../../constants/yarisa_constants.dart';
import '../../constants/yarisa_enums.dart';
import '../../constants/yarisa_widgets.dart';

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
  @override
  Widget build(BuildContext context) {
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
                    text: AppStrings.joinyarisa,
                    type: TextType.heading,
                    weight: FontWeight.w600,
                    spacing: -1,
                    height: 1.1,
                    size: YarisaDimens.headlineMedium + 3,
                  ),
                  10.hgap,
                  const YarisaText(
                    text: AppStrings.createaccountsubtitle,
                    type: TextType.bodySmall,
                    // spacing: 0,
                    color: Colors.grey,
                  ),
                  50.hgap,
                  FormTextField(
                    radius: 100,
                    controller: name,
                    inputType: TextInputType.name,
                    capitalization: TextCapitalization.words,
                    validator: (p0) {
                      if (p0!.isEmpty) {
                        return AppStrings.providename;
                      }

                      return null;
                    },
                    label: AppStrings.name,
                    hint: AppStrings.nameexample,
                  ),
                  10.hgap,
                  FormTextField(
                    radius: 100,
                    controller: email,
                    inputType: TextInputType.emailAddress,
                    validator: (p0) {
                      if (p0!.isEmpty) {
                        return AppStrings.provideemail;
                      }
                      if (!p0.isEmail) {
                        return AppStrings.validemail;
                      }
                      return null;
                    },
                    label: AppStrings.email,
                    hint: AppStrings.emailexample,
                  ),
                  10.hgap,
                  FormTextField(
                    radius: 100,
                    controller: password,
                    inputType: TextInputType.visiblePassword,
                    validator: (p0) {
                      if (p0!.isEmpty) {
                        return AppStrings.providepassword;
                      }
                      if (p0.length < 6) {
                        return AppStrings.invalidpassword;
                      }

                      return null;
                    },
                    hint: AppStrings.password,
                  ),
                  20.hgap,
                  ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const CompleteProfile()));
                      },
                      style: const ButtonStyle(
                          elevation: WidgetStatePropertyAll(0),
                          minimumSize: WidgetStatePropertyAll(
                              Size(double.infinity, 50))),
                      icon: const Icon(Icons.mark_email_read_outlined),
                      label: const Text(AppStrings.signupwithemail)),
                ],
              ),
            ),
          ),
        ));
  }
}
