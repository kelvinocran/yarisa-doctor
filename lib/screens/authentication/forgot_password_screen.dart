import 'package:firebase_auth/firebase_auth.dart';
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
  bool isLoading = false;
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
                      if (!p0.isEmail) {
                        return AppStrings.invalidemail;
                      }
                      return null;
                    },
                    label: "Email Address",
                    hint: "name@example.com",
                  ),
                  20.hgap,
                  Visibility(
                    visible: !isLoading,
                    replacement: const Center(child: Loader()),
                    child: ElevatedButton.icon(
                        onPressed: isLoading
                            ? null
                            : () async {
                                if (key.currentState!.validate()) {
                                  setState(() {
                                    isLoading = true;
                                  });

                                  try {
                                    await FirebaseAuth.instance
                                        .sendPasswordResetEmail(
                                      email: email.text.trim(),
                                    );

                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Password reset email sent! Check your inbox.'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      Navigator.pop(context);
                                    }
                                  } on FirebaseAuthException catch (e) {
                                    String message = 'An error occurred';
                                    if (e.code == 'user-not-found') {
                                      message = 'No user found for that email.';
                                    } else if (e.code == 'invalid-email') {
                                      message = 'Invalid email address.';
                                    }

                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(message),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Failed to send reset email. Please try again.'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() {
                                        isLoading = false;
                                      });
                                    }
                                  }
                                }
                              },
                        style: const ButtonStyle(
                            elevation: WidgetStatePropertyAll(0),
                            minimumSize: WidgetStatePropertyAll(
                                Size(double.infinity, 50))),
                        icon: const Icon(Icons.link_outlined),
                        label: const Text(AppStrings.requestlink)),
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}
