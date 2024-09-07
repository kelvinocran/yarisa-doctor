import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:yarisa_doctor/constants/yarisa_colors.dart';
import 'package:yarisa_doctor/extensions/yarisa_extensions.dart';

import '../../components/formtextfield.dart';
import '../../constants/yarisa_constants.dart';
import '../../constants/yarisa_enums.dart';
import '../../constants/yarisa_strings.dart';
import '../../constants/yarisa_widgets.dart';

class CompleteProfile extends ConsumerStatefulWidget {
  const CompleteProfile({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CompleteProfileState();
}

class _CompleteProfileState extends ConsumerState<CompleteProfile> {
  final controller = PageController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: false,
          title: SmoothPageIndicator(
            count: 3,
            controller: controller,
            effect: ExpandingDotsEffect(
                dotHeight: 6,
                activeDotColor: YarisaColors.primaryColor,
                dotWidth: 15,
                dotColor: Colors.grey.withOpacity(.3)),
          ),
          actions: [
            TextButton(
                onPressed: () {},
                style: ButtonStyle(
                  elevation: const WidgetStatePropertyAll(0),
                  foregroundColor:
                      WidgetStatePropertyAll(context.bodyMedium?.color),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(AppStrings.skip),
                    10.wgap,
                    const Icon(Icons.navigate_next_rounded)
                  ],
                )),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const YarisaText(
                text: AppStrings.tellusabout,
                type: TextType.heading,
                weight: FontWeight.w600,
                spacing: -1,
                height: 1.1,
                size: YarisaDimens.headlineMedium + 3,
              ),
              10.hgap,
              const YarisaText(
                text: AppStrings.tellusaboutsubtitle,
                type: TextType.bodySmall,
                // spacing: 0,
                color: Colors.grey,
              ),
              20.hgap,
              Expanded(
                child: PageView(
                  controller: controller,
                  scrollDirection: Axis.horizontal,
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Column(
                        children: [
                          FormTextField(
                              controller: TextEditingController(),
                              hint: "name@example.com",
                              label: "Email Address"),
                        ],
                      ),
                    ),
                    SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          vertical: 30, horizontal: 10),
                      child: Column(
                        children: [
                          FormTextField(
                              controller: TextEditingController(),
                              hint: "name@example.com",
                              label: "Email Address"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}
