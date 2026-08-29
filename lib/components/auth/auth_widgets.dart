import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yarisa_doctor/ui/doctor_ui.dart';

/// Shared chrome for doctor auth screens (welcome / sign-in / sign-up / forgot).
class DoctorAuthScaffold extends StatelessWidget {
  const DoctorAuthScaffold({
    super.key,
    required this.child,
    this.showBack = true,
    this.scrollable = true,
  });

  final Widget child;
  final bool showBack;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final isDark = DoctorUi.isDark;
    return Scaffold(
      backgroundColor: DoctorUi.scaffoldBg,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [Color(0xFF12081A), Color(0xFF050505)]
                : [
                    DoctorUi.primary.withValues(alpha: .10),
                    DoctorUi.scaffoldBg,
                    DoctorUi.scaffoldBg,
                  ],
            stops: const [0, 0.35, 1],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showBack)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    tooltip: 'Back',
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else if (Get.key.currentState?.canPop() == true) {
                        Get.back();
                      }
                    },
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                )
              else
                const SizedBox(height: 8),
              Expanded(
                child: scrollable
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        child: child,
                      )
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        child: child,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DoctorAuthHeader extends StatelessWidget {
  const DoctorAuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.medical_services_outlined,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final isDark = DoctorUi.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            color: DoctorUi.primary.withValues(alpha: isDark ? .22 : .12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: DoctorUi.primary.withValues(alpha: .18),
            ),
          ),
          child: Icon(icon, color: DoctorUi.primary, size: 26),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: theme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.15,
            letterSpacing: -0.6,
            fontSize: 28,
            color: isDark ? Colors.white : const Color(0xFF1A1024),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: theme.bodyMedium?.copyWith(
            color: DoctorUi.muted,
            height: 1.45,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class DoctorAuthCard extends StatelessWidget {
  const DoctorAuthCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DoctorUi.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DoctorUi.border),
        boxShadow: DoctorUi.isDark
            ? null
            : [
                BoxShadow(
                  color: DoctorUi.primary.withValues(alpha: .06),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: child,
    );
  }
}

class DoctorAuthPrimaryButton extends StatelessWidget {
  const DoctorAuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: DoctorUi.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: DoctorUi.primary.withValues(alpha: .5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: loading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class DoctorAuthSecondaryButton extends StatelessWidget {
  const DoctorAuthSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final isDark = DoctorUi.isDark;
    final bg = backgroundColor ??
        (isDark ? Colors.white.withValues(alpha: .08) : Colors.white);
    final fg = foregroundColor ?? (isDark ? Colors.white : Colors.black87);

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          elevation: 0,
          backgroundColor: bg,
          foregroundColor: fg,
          side: BorderSide(color: DoctorUi.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 10),
            ],
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class DoctorAuthOrDivider extends StatelessWidget {
  const DoctorAuthOrDivider({super.key, this.label = 'OR'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: DoctorUi.border, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            label,
            style: TextStyle(
              color: DoctorUi.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
        ),
        Expanded(child: Divider(color: DoctorUi.border, thickness: 1)),
      ],
    );
  }
}

void showDoctorAuthSnack(
  BuildContext context,
  String message, {
  bool success = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: success ? Colors.green.shade700 : Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ),
  );
}
