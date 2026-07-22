import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_picker/country_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:yarisa_doctor/api/api_methods.dart';
import 'package:yarisa_doctor/extensions/yarisa_extensions.dart';
import 'package:yarisa_doctor/models/user_model.dart';

import '../../components/formtextfield.dart';
import '../../constants/yarisa_constants.dart';
import '../../constants/yarisa_enums.dart';
import '../../constants/yarisa_strings.dart';
import '../../constants/yarisa_widgets.dart';

class CompleteProfile extends ConsumerStatefulWidget {
  final String? email;
  final String? fullname;

  const CompleteProfile({
    super.key,
    this.email,
    this.fullname,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CompleteProfileState();
}

class _CompleteProfileState extends ConsumerState<CompleteProfile> {
  final controller = PageController();
  Gender gender = Gender.male;
  Country? countryValue;
  String? speciality;
  int _currentStep = 0;
  bool _loadingSpecialities = true;
  String? _pickedPicPath;
  bool _uploadingPic = false;
  List<String> _specialityOptions = fallbackSpecialities;
  final country = TextEditingController();
  final bio = TextEditingController();
  final phone = TextEditingController();
  final fullname = TextEditingController();
  final email = TextEditingController();
  final specialityController = TextEditingController();
  final clinic = TextEditingController();
  final licenseCode = TextEditingController();
  final experience = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-populate fields if data is passed
    if (widget.fullname != null) {
      fullname.text = widget.fullname!;
    }
    if (widget.email != null) {
      email.text = widget.email!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(apimethods).ensureDoctorProfileSeed(
            fullname: widget.fullname,
            email: widget.email,
          );
      _loadSpecialityOptions();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    country.dispose();
    bio.dispose();
    phone.dispose();
    fullname.dispose();
    email.dispose();
    specialityController.dispose();
    clinic.dispose();
    licenseCode.dispose();
    experience.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto() async {
    try {
      final res = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (res != null) {
        setState(() => _pickedPicPath = res.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _uploadProfilePhoto(String uid) async {
    if (_pickedPicPath == null) return null;
    setState(() => _uploadingPic = true);
    try {
      final file = File(_pickedPicPath!);
      final ref =
          FirebaseStorage.instance.ref().child('doctor_profiles/$uid.jpg');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } finally {
      if (mounted) setState(() => _uploadingPic = false);
    }
  }

  Future<void> _loadSpecialityOptions() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Specialities')
          .doc('categories')
          .get();
      final options = _specialitiesFromFirestore(snapshot.data()?['main']);

      if (!mounted) return;
      setState(() {
        _specialityOptions = options.isEmpty ? fallbackSpecialities : options;
        if (!_specialityOptions.contains(speciality)) {
          speciality = null;
          specialityController.clear();
        }
        _loadingSpecialities = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _specialityOptions = fallbackSpecialities;
        if (!_specialityOptions.contains(speciality)) {
          speciality = null;
          specialityController.clear();
        }
        _loadingSpecialities = false;
      });
    }
  }

  List<String> _specialitiesFromFirestore(dynamic value) {
    final options = <String>{};
    if (value is List) {
      for (final item in value) {
        _collectSearchableSpecialities(item, options);
      }
    }

    return options.toList()..sort((first, second) => first.compareTo(second));
  }

  void _collectSearchableSpecialities(dynamic item, Set<String> options) {
    if (item is! Map) return;
    final data = Map<String, dynamic>.from(item);
    final subCategories = data['sub_category'];

    if (subCategories is List) {
      for (final subCategory in subCategories) {
        if (subCategory is! Map) continue;
        final subCategoryData = Map<String, dynamic>.from(subCategory);
        final leafCategories = subCategoryData['list'];

        if (leafCategories is List && leafCategories.isNotEmpty) {
          for (final leafCategory in leafCategories) {
            final title = _titleFromCategory(leafCategory);
            if (title != null) options.add(title);
          }
        } else {
          final title = _titleFromCategory(subCategoryData);
          if (title != null) options.add(title);
        }
      }
      return;
    }

    final title = _titleFromCategory(data);
    if (title != null) options.add(title);
  }

  String? _titleFromCategory(dynamic item) {
    if (item is! Map) return null;
    final title = item['title']?.toString().trim();
    return title == null || title.isEmpty ? null : title;
  }

  void _showOnboardingError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _showSpecialityPicker() async {
    if (_loadingSpecialities) {
      _showOnboardingError('Please wait while specialties load.');
      return;
    }

    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _SpecialityPickerSheet(
        options: _specialityOptions,
        selected: speciality,
      ),
    );

    if (!mounted || selected == null) return;
    setState(() {
      speciality = selected;
      specialityController.text = selected;
    });
  }

  bool _hasValue(TextEditingController controller) {
    return controller.text.trim().isNotEmpty;
  }

  bool _validateAboutYourself() {
    if (!_hasValue(country)) {
      _showOnboardingError('Please select your country.');
      return false;
    }
    if (!_hasValue(phone)) {
      _showOnboardingError('Please provide your phone number.');
      return false;
    }
    if (!_hasValue(bio)) {
      _showOnboardingError('Please add a short bio.');
      return false;
    }
    return true;
  }

  bool _validateCareer() {
    if (speciality == null || speciality!.trim().isEmpty) {
      _showOnboardingError('Please select your specialty.');
      return false;
    }
    if (!_hasValue(clinic)) {
      _showOnboardingError('Please provide your clinic or workplace.');
      return false;
    }
    if (!_hasValue(licenseCode)) {
      _showOnboardingError('Please provide your license code.');
      return false;
    }
    if (int.tryParse(experience.text.trim()) == null) {
      _showOnboardingError('Please enter your years of experience.');
      return false;
    }
    return true;
  }

  Future<bool> _saveAboutYourself() async {
    if (!_validateAboutYourself()) return false;

    try {
      await ref.read(apimethods).updateDoctorProfile({
        'gender': gender.name,
        'nationality': country.text.trim(),
        'phone': phone.text.trim(),
        'bio': bio.text.trim(),
        'profileComplete': false,
        'onboardingStep': 'about_yourself',
      });
      return true;
    } catch (error) {
      if (mounted) {
        _showOnboardingError('Failed to save your details: $error');
      }
      return false;
    }
  }

  Future<bool> _saveCareer() async {
    if (_loadingSpecialities) {
      _showOnboardingError('Please wait while specialties load.');
      return false;
    }
    if (!_validateCareer()) return false;

    try {
      await ref.read(apimethods).updateDoctorProfile({
        'speciality': speciality,
        'clinic': clinic.text.trim(),
        'licenseCode': licenseCode.text.trim(),
        'experience': int.parse(experience.text.trim()),
        'profileComplete': false,
        'onboardingStep': 'career',
      });
      return true;
    } catch (error) {
      if (mounted) {
        _showOnboardingError('Failed to save your career details: $error');
      }
      return false;
    }
  }

  Future<void> _completeProfile() async {
    final loading = ref.read(apimethods).loading;
    if (loading || _uploadingPic) return;
    if (!_validateAboutYourself() || !_validateCareer()) return;

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      String? picUrl;
      if (uid != null && _pickedPicPath != null) {
        try {
          picUrl = await _uploadProfilePhoto(uid);
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Profile photo could not be uploaded. You can add it later.'),
              ),
            );
          }
        }
      }

      final user = UserModel(
        fullname: fullname.text.trim().isNotEmpty
            ? fullname.text.trim()
            : widget.fullname,
        email: email.text.trim().isNotEmpty ? email.text.trim() : widget.email,
        speciality: speciality,
        bio: bio.text.trim(),
        phone: phone.text.trim(),
        clinic: clinic.text.trim(),
        licenseCode: licenseCode.text.trim(),
        experience: int.parse(experience.text.trim()),
        nationality: country.text.trim(),
        id: uid,
        pic: picUrl,
        loggedIn: true,
        online: true,
      );

      await ref.read(apimethods).createDoctorProfile(user);

      if (mounted) {
        await ref.read(apimethods).openDoctorLanding(
              context,
              email: email.text.trim().isNotEmpty ? email.text.trim() : null,
              fullname:
                  fullname.text.trim().isNotEmpty ? fullname.text.trim() : null,
            );
      }
    } catch (error) {
      if (mounted) {
        _showOnboardingError('Failed to save profile: $error');
      }
    }
  }

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
                dotColor: Colors.grey.withValues(alpha: .3)),
          ),
          actions: [
            if (_currentStep == 2)
              TextButton(
                  onPressed: _completeProfile,
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
            onPageChanged: (index) => setState(() => _currentStep = index),
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
          InkWell(
            onTap: _showSpecialityPicker,
            borderRadius: BorderRadius.circular(100),
            child: FormTextField(
              radius: 100,
              controller: specialityController,
              hint: _loadingSpecialities
                  ? 'Loading specialties...'
                  : AppStrings.specialize,
              labeled: false,
              enabled: false,
              icon: EneftyIcons.search_normal_2_outline,
              iconSize: 20,
              endicon: const Icon(Icons.keyboard_arrow_down_rounded),
            ),
          ),
          15.hgap,
          FormTextField(
            radius: 100,
            controller: clinic,
            hint: AppStrings.clinic,
            labeled: false,
          ),
          15.hgap,
          FormTextField(
              radius: 100,
              controller: licenseCode,
              labeled: false,
              hint: AppStrings.licenseCode),
          15.hgap,
          FormTextField(
              radius: 100,
              controller: experience,
              inputType: TextInputType.number,
              labeled: false,
              hint: AppStrings.experience),
          20.hgap,
          Row(
            children: [
              FloatingActionButton(
                  heroTag: 'complete_profile_career_back',
                  foregroundColor: context.bodyLarge?.color,
                  backgroundColor: Colors.grey.withValues(alpha: .2),
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
                      final saved = await _saveCareer();
                      if (saved) {
                        controller.nextPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeIn);
                      }
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
                color: Colors.grey.withValues(alpha: .6),
                strokeWidth: 1,
                borderType: BorderType.Circle,
                dashPattern: const [10, 10],
                // padding: const EdgeInsets.all(20),
                radius: const Radius.circular(100),
                child: Center(
                  child: InkWell(
                    onTap: _uploadingPic ? null : _pickProfilePhoto,
                    customBorder: const CircleBorder(),
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      height: 150,
                      width: 150,
                      decoration: _pickedPicPath != null
                          ? BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: FileImage(File(_pickedPicPath!)),
                                fit: BoxFit.cover,
                              ),
                            )
                          : null,
                      child: _pickedPicPath != null
                          ? null
                          : Icon(
                              EneftyIcons.gallery_add_outline,
                              size: 50,
                              color: Colors.grey.withValues(alpha: .3),
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
                  heroTag: 'complete_profile_photo_back',
                  foregroundColor: context.bodyLarge?.color,
                  backgroundColor: Colors.grey.withValues(alpha: .2),
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
                    onPressed: _completeProfile,
                    style: const ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(Colors.green),
                        foregroundColor: WidgetStatePropertyAll(Colors.white),
                        elevation: WidgetStatePropertyAll(0),
                        minimumSize:
                            WidgetStatePropertyAll(Size(double.infinity, 50))),
                    child: ref.watch(apimethods).loading || _uploadingPic
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(AppStrings.complete)),
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
                        backgroundColor: Colors.grey.withValues(alpha: .3),
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
                final saved = await _saveAboutYourself();
                if (saved) {
                  controller.nextPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeIn);
                }
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
                  ? Theme.of(context).primaryColor.withValues(alpha: .2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                  width: isSelected ? 2 : 1,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey.withValues(alpha: .2))),
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

class _SpecialityPickerSheet extends StatefulWidget {
  const _SpecialityPickerSheet({
    required this.options,
    required this.selected,
  });

  final List<String> options;
  final String? selected;

  @override
  State<_SpecialityPickerSheet> createState() => _SpecialityPickerSheetState();
}

class _SpecialityPickerSheetState extends State<_SpecialityPickerSheet> {
  final searchController = TextEditingController();
  String query = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredOptions = widget.options
        .where((option) => option.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 18,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Select specialty',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search specialties',
                prefixIcon: const Icon(EneftyIcons.search_normal_2_outline),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => query = value.trim()),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * .55,
              ),
              child: filteredOptions.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: Center(child: Text('No specialty found')),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: filteredOptions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final option = filteredOptions[index];
                        final selected = option == widget.selected;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            option,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: selected
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: Theme.of(context).primaryColor,
                                )
                              : null,
                          onTap: () => Navigator.pop(context, option),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

const List<String> fallbackSpecialities = [
  "Cardiologist",
  "Physician",
  "Oncologist",
  "Dermatologist",
  "Dietitian",
  "Fitness Trainer",
  "Nutritionist",
  "Surgeon"
];
