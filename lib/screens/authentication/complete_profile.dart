import 'package:country_picker/country_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:enefty_icons/enefty_icons.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'package:yarisa_doctor/extensions/yarisa_extensions.dart';
import 'package:yarisa_doctor/screens/main/base.dart';

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
  Country? countryValue;
  String? speciality;
  final country = TextEditingController();
  final bio = TextEditingController();
  final phone = TextEditingController();

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
                activeDotColor: Theme.of(context).primaryColor,
                dotWidth: 15,
                dotColor: Colors.grey.withOpacity(.3)),
          ),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const BaseScreen()),
                      (route) => false);
                },
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
            physics: const NeverScrollableScrollPhysics(),
            controller: controller,
            scrollDirection: Axis.horizontal,
            children: [
              aboutYourself(context),
              aboutCareer(),
              addProfilePhoto()
            ],
          ),
        ));
  }

  SingleChildScrollView aboutCareer() {
    return SingleChildScrollView(
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
          DropdownButtonHideUnderline(
            child: DropdownButton2(
                hint: Text(
                  AppStrings.specialize,
                  style: context.bodySmall,
                ),
                buttonStyleData: ButtonStyleData(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(.2)),
                        color: Colors.grey.withOpacity(.2),
                        borderRadius: BorderRadius.circular(100))),
                dropdownStyleData: DropdownStyleData(
                    useSafeArea: true,
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Theme.of(context).dialogBackgroundColor)),
                items: specialities
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e, style: context.bodyMedium),
                        ))
                    .toList(),
                value: speciality,
                onChanged: (value) {
                  speciality = value;
                  setState(() {});
                }),
          ),
          15.hgap,
          FormTextField(
            radius: 100,
            controller: TextEditingController(),
            hint: AppStrings.clinic,
            labeled: false,
          ),
          15.hgap,
          FormTextField(
              radius: 100,
              controller: TextEditingController(),
              labeled: false,
              hint: AppStrings.licenseCode),
          15.hgap,
          FormTextField(
              radius: 100,
              controller: TextEditingController(),
              labeled: false,
              hint: AppStrings.experience),
          20.hgap,
          Row(
            children: [
              FloatingActionButton(
                  foregroundColor: context.bodyLarge?.color,
                  backgroundColor: Colors.grey.withOpacity(.2),
                  elevation: 0,
                  shape: const CircleBorder(),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    size: 20,
                  ),
                  onPressed: () {
                    controller.previousPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut);
                  }),
              10.wgap,
              Expanded(
                child: ElevatedButton(
                    onPressed: () async {
                      controller.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeIn);
                    },
                    style: const ButtonStyle(
                        elevation: WidgetStatePropertyAll(0),
                        minimumSize:
                            WidgetStatePropertyAll(Size(double.infinity, 50))),
                    child: const Text(AppStrings.next)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget addProfilePhoto() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const YarisaText(
            text: AppStrings.addprofilephoto,
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
          10.hgap,
          const Spacer(),
          Align(
              alignment: Alignment.center,
              child: DottedBorder(
                color: Colors.grey.withOpacity(.6),
                strokeWidth: 1,
                borderType: BorderType.Circle,
                dashPattern: const [10, 10],
                // padding: const EdgeInsets.all(20),
                radius: const Radius.circular(100),
                child: Center(
                  child: InkWell(
                    onTap: () {},
                    customBorder: const CircleBorder(),
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      height: 150,
                      width: 150,
                      child: Icon(
                        EneftyIcons.gallery_add_outline,
                        size: 50,
                        color: Colors.grey.withOpacity(.3),
                      ),
                    ),
                  ),
                ),
              )),
          20.hgap,
          const Center(
            child: YarisaText(
              text: AppStrings.taptoaddphoto,
              type: TextType.bodySmall,
              size: 12,
            ),
          ),
          const Center(
            child: YarisaText(
              align: TextAlign.center,
              text: AppStrings.addphotonote,
              type: TextType.bodySmall,
              size: 11,
              color: Colors.grey,
            ),
          ),
          20.hgap,
          const Spacer(
            flex: 2,
          ),
          Row(
            children: [
              FloatingActionButton(
                  foregroundColor: context.bodyLarge?.color,
                  backgroundColor: Colors.grey.withOpacity(.2),
                  elevation: 0,
                  shape: const CircleBorder(),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    size: 20,
                  ),
                  onPressed: () {
                    controller.previousPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut);
                  }),
              10.wgap,
              Expanded(
                child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const BaseScreen()),
                          (route) => false);
                    },
                    style: const ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(Colors.green),
                        foregroundColor: WidgetStatePropertyAll(Colors.white),
                        elevation: WidgetStatePropertyAll(0),
                        minimumSize:
                            WidgetStatePropertyAll(Size(double.infinity, 50))),
                    // icon: const Icon(Icons.check),
                    child: const Text(AppStrings.complete)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  SingleChildScrollView aboutYourself(BuildContext context) {
    return SingleChildScrollView(
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
          InkWell(
            onTap: () {
              showCountryPicker(
                  context: context,
                  onSelect: (value) {
                    setState(() {
                      countryValue = value;
                      country.text = value.displayNameNoCountryCode;
                    });
                  });
            },
            child: FormTextField(
                radius: 100,
                controller: country,
                iconSize: 20,
                endicon: countryValue != null
                    ? CircleAvatar(
                        backgroundColor: Colors.grey.withOpacity(.3),
                        child: Text(
                          countryValue!.flagEmoji,
                          style: context.titleLarge?.copyWith(fontSize: 24),
                        ))
                    : null,
                labeled: false,
                enabled: false,
                hint: AppStrings.country),
          ),
          15.hgap,
          FormTextField(
              radius: 100,
              controller: phone,
              inputType: TextInputType.phone,
              action: TextInputAction.next,
              // icon: EneftyIcons.call_outline,
              // iconSize: 20,
              labeled: false,
              hint: AppStrings.phonenumber),
          15.hgap,
          FormTextField(
              radius: 20,
              controller: bio,
              // icon: (EneftyIcons.information_outline),
              // iconSize: 20,
              labeled: false,
              lines: 10,
              hint: AppStrings.bio),
          20.hgap,
          ElevatedButton(
              onPressed: () async {
                controller.nextPage(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeIn);
              },
              style: const ButtonStyle(
                  elevation: WidgetStatePropertyAll(0),
                  minimumSize:
                      WidgetStatePropertyAll(Size(double.infinity, 50))),
              child: const Text(AppStrings.next)),
        ],
      ),
    );
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
                  ? Theme.of(context).primaryColor.withOpacity(.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                  width: isSelected ? 2 : 1,
                  color: isSelected
                      ? Theme.of(context).primaryColor
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

final List<String> specialities = [
  "Cardiologist",
  "Physician",
  "Oncologist",
  "Dermatologist",
  "Dietician",
  "Fitness trainer",
  "Nutritionist",
  "Surgeon"
];
