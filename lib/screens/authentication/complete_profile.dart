import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_picker/country_picker.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yarisa_doctor/api/api_methods.dart';
import 'package:yarisa_doctor/api/firestore_schema.dart';
import 'package:yarisa_doctor/components/auth/auth_widgets.dart';
import 'package:yarisa_doctor/components/auth/onboarding_widgets.dart';
import 'package:yarisa_doctor/components/auth/picker_sheets.dart';
import 'package:yarisa_doctor/components/formtextfield.dart';
import 'package:yarisa_doctor/constants/yarisa_enums.dart';
import 'package:yarisa_doctor/constants/yarisa_strings.dart';
import 'package:yarisa_doctor/models/user_model.dart';
import 'package:yarisa_doctor/ui/doctor_ui.dart';

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
  bool _savingStep = false;
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
    if (widget.fullname != null) fullname.text = widget.fullname!;
    if (widget.email != null) email.text = widget.email!;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Safety net: if Firestore already marks this doctor complete, leave
      // onboarding instead of showing "Tell us about you" again.
      final api = ref.read(apimethods);
      final uid = api.auth.currentUser?.uid;
      if (uid != null && mounted) {
        try {
          final snap = await FirestoreSchema.doctorDoc(uid).get(
            const GetOptions(source: Source.server),
          );
          final data = snap.data();
          final complete = data != null &&
              (data['profileComplete'] == true ||
                  data['profileComplete']?.toString() == 'true' ||
                  data['onboardingStep']?.toString() == 'complete');
          if (complete && mounted) {
            await api.openDoctorLanding(
              context,
              email: widget.email,
              fullname: widget.fullname,
            );
            return;
          }
        } catch (_) {
          // Fall through to normal onboarding seed/load.
        }
      }
      if (!mounted) return;
      api.ensureDoctorProfileSeed(
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
      if (res != null) setState(() => _pickedPicPath = res.path);
    } catch (e) {
      if (mounted) {
        showDoctorAuthSnack(context, 'Could not pick image: $e');
      }
    }
  }

  Future<String?> _uploadProfilePhoto(String uid) async {
    if (_pickedPicPath == null) return null;
    setState(() => _uploadingPic = true);
    try {
      final file = File(_pickedPicPath!);
      final storageRef =
          FirebaseStorage.instance.ref().child('doctor_profiles/$uid.jpg');
      await storageRef.putFile(file);
      return await storageRef.getDownloadURL();
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
    return options.toList()..sort();
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

  Future<void> _showSpecialityPicker() async {
    if (_loadingSpecialities) {
      showDoctorAuthSnack(context, 'Please wait while specialties load.');
      return;
    }
    final selected = await DoctorSpecialtyPickerSheet.show(
      context,
      options: _specialityOptions,
      selected: speciality,
    );
    if (!mounted || selected == null) return;
    setState(() {
      speciality = selected;
      specialityController.text = selected;
    });
  }

  Future<void> _showCountryPicker() async {
    final selected = await DoctorCountryPickerSheet.show(
      context,
      selectedCountryCode: countryValue?.countryCode,
    );
    if (!mounted || selected == null) return;
    setState(() {
      countryValue = selected;
      country.text = selected.displayNameNoCountryCode;
    });
  }

  bool _hasValue(TextEditingController c) => c.text.trim().isNotEmpty;

  bool _validateAboutYourself() {
    if (!_hasValue(country)) {
      showDoctorAuthSnack(context, 'Please select your country.');
      return false;
    }
    if (!_hasValue(phone)) {
      showDoctorAuthSnack(context, 'Please provide your phone number.');
      return false;
    }
    if (!_hasValue(bio)) {
      showDoctorAuthSnack(context, 'Please add a short bio.');
      return false;
    }
    return true;
  }

  bool _validateCareer() {
    if (speciality == null || speciality!.trim().isEmpty) {
      showDoctorAuthSnack(context, 'Please select your specialty.');
      return false;
    }
    if (!_hasValue(clinic)) {
      showDoctorAuthSnack(context, 'Please provide your clinic or workplace.');
      return false;
    }
    if (!_hasValue(licenseCode)) {
      showDoctorAuthSnack(context, 'Please provide your license code.');
      return false;
    }
    if (int.tryParse(experience.text.trim()) == null) {
      showDoctorAuthSnack(context, 'Please enter your years of experience.');
      return false;
    }
    return true;
  }

  Future<void> _goNextFromAbout() async {
    if (_savingStep) return;
    if (!_validateAboutYourself()) return;
    setState(() => _savingStep = true);
    try {
      await ref.read(apimethods).updateDoctorProfile({
        'gender': gender.name,
        'nationality': country.text.trim(),
        'phone': phone.text.trim(),
        'bio': bio.text.trim(),
        'profileComplete': false,
        'onboardingStep': 'about_yourself',
      });
      if (!mounted) return;
      await controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } catch (error) {
      if (mounted) {
        showDoctorAuthSnack(context, 'Failed to save your details: $error');
      }
    } finally {
      if (mounted) setState(() => _savingStep = false);
    }
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _goNextFromCareer() async {
    _dismissKeyboard();
    if (_savingStep) return;
    if (_loadingSpecialities) {
      showDoctorAuthSnack(context, 'Please wait while specialties load.');
      return;
    }
    if (!_validateCareer()) return;
    setState(() => _savingStep = true);
    try {
      await ref.read(apimethods).updateDoctorProfile({
        'speciality': speciality,
        'clinic': clinic.text.trim(),
        'licenseCode': licenseCode.text.trim(),
        'experience': int.parse(experience.text.trim()),
        'profileComplete': false,
        'onboardingStep': 'career',
      });
      if (!mounted) return;
      await controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } catch (error) {
      if (mounted) {
        showDoctorAuthSnack(
          context,
          'Failed to save your career details: $error',
        );
      }
    } finally {
      if (mounted) setState(() => _savingStep = false);
    }
  }

  Future<void> _completeProfile() async {
    final loading = ref.read(apimethods).loading;
    if (loading || _uploadingPic || _savingStep) return;
    if (!_validateAboutYourself() || !_validateCareer()) return;

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      String? picUrl;
      if (uid != null && _pickedPicPath != null) {
        try {
          picUrl = await _uploadProfilePhoto(uid);
        } catch (_) {
          if (mounted) {
            showDoctorAuthSnack(
              context,
              'Profile photo could not be uploaded. You can add it later.',
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
      if (!mounted) return;
      await ref.read(apimethods).openDoctorLanding(
            context,
            email: email.text.trim().isNotEmpty ? email.text.trim() : null,
            fullname:
                fullname.text.trim().isNotEmpty ? fullname.text.trim() : null,
          );
    } catch (error) {
      if (mounted) {
        showDoctorAuthSnack(context, 'Failed to save profile: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final completing = ref.watch(apimethods).loading || _uploadingPic;

    return DoctorAuthScaffold(
      showBack: false,
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DoctorOnboardingProgress(currentStep: _currentStep),
          const SizedBox(height: 16),
          if (_currentStep == 2)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: completing ? null : _completeProfile,
                child: Text(
                  AppStrings.skip,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: DoctorUi.muted,
                  ),
                ),
              ),
            ),
          Expanded(
            child: PageView(
              physics: const NeverScrollableScrollPhysics(),
              controller: controller,
              onPageChanged: (i) => setState(() => _currentStep = i),
              children: [
                _buildAboutStep(),
                _buildCareerStep(),
                _buildPhotoStep(completing),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DoctorAuthHeader(
            title: AppStrings.tellusabout,
            subtitle: AppStrings.tellusaboutsubtitle,
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 22),
          DoctorAuthCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Gender',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: DoctorUi.muted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                DoctorGenderPicker(
                  value: gender,
                  onChanged: (g) => setState(() => gender = g),
                ),
                const SizedBox(height: 16),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _showCountryPicker,
                    child: FormTextField(
                      radius: 14,
                      controller: country,
                      autoFocus: false,
                      filled: true,
                      fillColor: DoctorUi.fieldBg,
                      endicon: countryValue != null
                          ? Text(countryValue!.flagEmoji,
                              style: const TextStyle(fontSize: 22))
                          : Icon(Icons.public_rounded,
                              color: DoctorUi.muted, size: 20),
                      labeled: true,
                      label: AppStrings.country,
                      enabled: false,
                      hint: AppStrings.country,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FormTextField(
                  radius: 14,
                  controller: phone,
                  autoFocus: false,
                  filled: true,
                  fillColor: DoctorUi.fieldBg,
                  inputType: TextInputType.phone,
                  action: TextInputAction.next,
                  label: AppStrings.phonenumber,
                  hint: AppStrings.phonenumber,
                ),
                const SizedBox(height: 12),
                FormTextField(
                  radius: 14,
                  controller: bio,
                  autoFocus: false,
                  filled: true,
                  fillColor: DoctorUi.fieldBg,
                  labeled: true,
                  lines: 5,
                  label: AppStrings.bio,
                  hint: 'Short professional bio for patients',
                ),
                const SizedBox(height: 20),
                DoctorOnboardingNav(
                  primaryLabel: AppStrings.next,
                  loading: _savingStep,
                  onPrimary: _goNextFromAbout,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCareerStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DoctorAuthHeader(
            title: AppStrings.tellusaboutcareer,
            subtitle: AppStrings.tellusaboutsubtitle,
            icon: Icons.work_outline_rounded,
          ),
          const SizedBox(height: 22),
          DoctorAuthCard(
            child: Column(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _showSpecialityPicker,
                    child: FormTextField(
                      radius: 14,
                      controller: specialityController,
                      autoFocus: false,
                      filled: true,
                      fillColor: DoctorUi.fieldBg,
                      hint: _loadingSpecialities
                          ? 'Loading specialties...'
                          : AppStrings.specialize,
                      label: 'Specialty',
                      enabled: false,
                      icon: EneftyIcons.search_normal_2_outline,
                      iconSize: 20,
                      endicon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: DoctorUi.muted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FormTextField(
                  radius: 14,
                  controller: clinic,
                  autoFocus: false,
                  filled: true,
                  fillColor: DoctorUi.fieldBg,
                  action: TextInputAction.next,
                  label: 'Clinic / Hospital',
                  hint: AppStrings.clinic,
                ),
                const SizedBox(height: 12),
                FormTextField(
                  radius: 14,
                  controller: licenseCode,
                  autoFocus: false,
                  filled: true,
                  fillColor: DoctorUi.fieldBg,
                  action: TextInputAction.next,
                  label: 'License code',
                  hint: AppStrings.licenseCode,
                ),
                const SizedBox(height: 12),
                FormTextField(
                  radius: 14,
                  controller: experience,
                  autoFocus: false,
                  filled: true,
                  fillColor: DoctorUi.fieldBg,
                  inputType: TextInputType.number,
                  action: TextInputAction.done,
                  onSubmitted: (_) => _goNextFromCareer(),
                  label: 'Years of experience',
                  hint: AppStrings.experience,
                ),
                const SizedBox(height: 20),
                DoctorOnboardingNav(
                  primaryLabel: AppStrings.next,
                  loading: _savingStep,
                  onBack: () {
                    _dismissKeyboard();
                    controller.previousPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                    );
                  },
                  onPrimary: _goNextFromCareer,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPhotoStep(bool completing) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DoctorAuthHeader(
            title: AppStrings.addprofilephoto,
            subtitle:
                'A professional photo helps patients recognize and trust you.',
            icon: Icons.photo_camera_outlined,
          ),
          const SizedBox(height: 22),
          DoctorAuthCard(
            child: Column(
              children: [
                DoctorPhotoPicker(
                  imagePath: _pickedPicPath,
                  uploading: _uploadingPic,
                  onTap: _pickProfilePhoto,
                ),
                const SizedBox(height: 28),
                DoctorOnboardingNav(
                  primaryLabel: AppStrings.complete,
                  loading: completing,
                  onBack: completing
                      ? null
                      : () {
                          controller.previousPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutCubic,
                          );
                        },
                  onPrimary: _completeProfile,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

const List<String> fallbackSpecialities = [
  'Cardiologist',
  'Physician',
  'Oncologist',
  'Dermatologist',
  'Dietitian',
  'Fitness Trainer',
  'Nutritionist',
  'Surgeon',
];
