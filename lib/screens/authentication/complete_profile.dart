import 'package:chips_choice/chips_choice.dart';
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
  Gender gender = Gender.male;
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
          child: PageView(
            controller: controller,
            scrollDirection: Axis.horizontal,
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
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
                    50.hgap,
                    Row(
                      children: [
                        ChipWidget(
                          onSelected: () {
                            gender = Gender.male;
                            setState(() {});
                          },
                          label: "Male",
                          icon: "🙋🏽‍♂️",
                          isSelected: gender == Gender.male,
                        ),
                        ChipWidget(
                          onSelected: () {
                            gender = Gender.female;
                            setState(() {});
                          },
                          label: "Female",
                          icon: "🙋🏽‍♀️",
                          isSelected: gender == Gender.female,
                        ),
                        ChipWidget(
                          onSelected: () {
                            gender = Gender.other;
                            setState(() {});
                          },
                          label: "Other",
                          icon: "✨",
                          isSelected: gender == Gender.other,
                        ),
                      ],
                    ),
                    30.hgap,
                    FormTextField(
                        radius: 100,
                        controller: TextEditingController(),
                        labeled: false,
                        hint: "Email Address"),
                    15.hgap,
                    FormTextField(
                        radius: 100,
                        controller: TextEditingController(),
                        labeled: false,
                        hint: "Email Address"),
                    15.hgap,
                    FormTextField(
                        radius: 100,
                        controller: TextEditingController(),
                        labeled: false,
                        hint: "Email Address"),
                    15.hgap,
                    FormTextField(
                        radius: 100,
                        controller: TextEditingController(),
                        labeled: false,
                        hint: "Email Address"),
                  ],
                ),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const YarisaText(
                      text: AppStrings.tellusaboutcareer,
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
                    50.hgap,
                    FormTextField(
                      radius: 100,
                      controller: TextEditingController(),
                      hint: "name@example.com",
                      labeled: false,
                    ),
                    15.hgap,
                    FormTextField(
                        radius: 100,
                        controller: TextEditingController(),
                        labeled: false,
                        hint: "Email Address"),
                    15.hgap,
                    FormTextField(
                        radius: 100,
                        controller: TextEditingController(),
                        labeled: false,
                        hint: "Email Address"),
                    15.hgap,
                    FormTextField(
                        radius: 100,
                        controller: TextEditingController(),
                        labeled: false,
                        hint: "Email Address"),
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}

class ChipWidget extends StatelessWidget {
  const ChipWidget({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onSelected,
  });

  final String label, icon;
  final bool isSelected;
  final Function() onSelected;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onSelected,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 5),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: isSelected
                  ? YarisaColors.primaryColor.withOpacity(.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                  width: isSelected ? 2 : 1,
                  color: isSelected
                      ? YarisaColors.primaryColor
                      : Colors.grey.withOpacity(.2))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              YarisaText(text: icon, type: TextType.title),
              10.wgap,
              Flexible(
                child: YarisaText(
                  text: label,
                  type: TextType.bodySmall,
                  weight: FontWeight.w500,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
