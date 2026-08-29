import 'dart:io';

import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:yarisa_doctor/components/auth/auth_widgets.dart';
import 'package:yarisa_doctor/constants/yarisa_enums.dart';
import 'package:yarisa_doctor/ui/doctor_ui.dart';

/// Step progress for doctor onboarding (3 steps).
class DoctorOnboardingProgress extends StatelessWidget {
  const DoctorOnboardingProgress({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step ${currentStep + 1} of $totalSteps',
          style: TextStyle(
            color: DoctorUi.muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(totalSteps, (i) {
            final active = i <= currentStep;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i == totalSteps - 1 ? 0 : 8),
                height: 5,
                decoration: BoxDecoration(
                  color: active
                      ? DoctorUi.primary
                      : DoctorUi.border,
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class DoctorGenderPicker extends StatelessWidget {
  const DoctorGenderPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final Gender value;
  final ValueChanged<Gender> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = [
      (Gender.male, 'Male', '👨🏽‍⚕️'),
      (Gender.female, 'Female', '👩🏽‍⚕️'),
      (Gender.other, 'Other', '✨'),
    ];

    return Row(
      children: options.map((opt) {
        final selected = value == opt.$1;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onChanged(opt.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected
                        ? DoctorUi.primary.withValues(alpha: .12)
                        : DoctorUi.fieldBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      width: selected ? 1.5 : 1,
                      color: selected ? DoctorUi.primary : DoctorUi.border,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(opt.$3, style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 6),
                      Text(
                        opt.$2,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: selected
                              ? DoctorUi.primary
                              : (DoctorUi.isDark
                                  ? Colors.white70
                                  : Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class DoctorOnboardingNav extends StatelessWidget {
  const DoctorOnboardingNav({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.onBack,
    this.loading = false,
    this.primaryColor,
  });

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onBack;
  final bool loading;
  final Color? primaryColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onBack != null) ...[
          SizedBox(
            height: 52,
            width: 52,
            child: OutlinedButton(
              onPressed: loading ? null : onBack,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                side: BorderSide(color: DoctorUi.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                backgroundColor: DoctorUi.surface,
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: DoctorUi.isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: DoctorAuthPrimaryButton(
            label: primaryLabel,
            loading: loading,
            onPressed: onPrimary,
          ),
        ),
      ],
    );
  }
}

class DoctorPhotoPicker extends StatelessWidget {
  const DoctorPhotoPicker({
    super.key,
    required this.imagePath,
    required this.onTap,
    this.uploading = false,
  });

  final String? imagePath;
  final VoidCallback? onTap;
  final bool uploading;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: uploading ? null : onTap,
              child: Container(
                height: 160,
                width: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DoctorUi.fieldBg,
                  border: Border.all(
                    color: DoctorUi.primary.withValues(alpha: .25),
                    width: 2,
                  ),
                  image: imagePath != null
                      ? DecorationImage(
                          image: FileImage(File(imagePath!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: DoctorUi.primary.withValues(alpha: .12),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: imagePath == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            EneftyIcons.gallery_add_outline,
                            size: 36,
                            color: DoctorUi.primary.withValues(alpha: .7),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add photo',
                            style: TextStyle(
                              color: DoctorUi.muted,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      )
                    : uploading
                        ? Container(
                            decoration: const BoxDecoration(
                              color: Colors.black45,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            ),
                          )
                        : Align(
                            alignment: Alignment.bottomRight,
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: DoctorUi.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tap to add or change photo',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: DoctorUi.isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Use a clear, professional headshot for your profile.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: DoctorUi.muted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
