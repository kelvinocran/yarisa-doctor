import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:yarisa_doctor/extensions/yarisa_extensions.dart';

import '../../components/formtextfield.dart';
import '../../constants/yarisa_constants.dart';
import '../../constants/yarisa_enums.dart';
import '../../constants/yarisa_strings.dart';
import '../../constants/yarisa_widgets.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final key = GlobalKey<FormState>();
  final email = TextEditingController();
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
                    text: AppStrings.forgotyourpassword,
                    type: TextType.heading,
                    weight: FontWeight.w600,
                    spacing: -1,
                    height: 1.1,
                    size: YarisaDimens.headlineMedium + 3,
                  ),
                  10.hgap,
                  const YarisaText(
                    text: AppStrings.forgotpasswordsubtitle,
                    type: TextType.bodySmall,
                    // spacing: 0,
                    color: Colors.grey,
                  ),
                  50.hgap,
                  FormTextField(
                    radius: 100,
                    controller: email,
                    inputType: TextInputType.emailAddress,
                    validator: (p0) {
                      if (p0!.isEmpty) {
                        return AppStrings.provideemail;
                      }
                      if (p0.isEmail) {
                        return AppStrings.invalidemail;
                      }
                      return null;
                    },
                    label: "Email Address",
                    hint: "name@example.com",
                  ),
                  20.hgap,
                  ElevatedButton.icon(
                      onPressed: () async {},
                      style: const ButtonStyle(
                          elevation: WidgetStatePropertyAll(0),
                          minimumSize: WidgetStatePropertyAll(
                              Size(double.infinity, 50))),
                      icon: const Icon(Icons.link_outlined),
                      label: const Text(AppStrings.requestlink)),
                ],
              ),
            ),
          ),
        ));
  }
}
