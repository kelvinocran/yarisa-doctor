import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yarisa_doctor/constants/yarisa_colors.dart';
import 'package:yarisa_doctor/constants/yarisa_enums.dart';

/// Shared chrome + design tokens for doctor-app redesigned screens.
/// Keep this file under ~250 lines — extract specialized widgets elsewhere.
class DoctorUi {
  DoctorUi._();

  static bool get isDark => Get.isDarkMode;

  static Color get primary => YarisaColors.primaryColor;

  static Color get scaffoldBg =>
      isDark ? const Color(0xFF050505) : const Color(0xFFF6F4F8);

  static Color get surface => isDark ? const Color(0xFF151515) : Colors.white;

  static Color get fieldBg =>
      isDark ? Colors.white.withValues(alpha: .06) : const Color(0xFFF1ECF5);

  static Color get border =>
      isDark ? Colors.white.withValues(alpha: .08) : Colors.grey.shade200;

  static Color get muted => Colors.grey.shade600;

  static Color statusColor(AppointmentStatus? status) {
    switch (status) {
      case AppointmentStatus.approved:
        return Colors.green;
      case AppointmentStatus.pending:
        return Colors.amber.shade800;
      case AppointmentStatus.canceled:
        return Colors.red;
      case AppointmentStatus.declined:
        return Colors.pink;
      case null:
        return Colors.grey;
    }
  }
}

class DoctorScaffold extends StatelessWidget {
  const DoctorScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.actions,
    this.leading,
    this.floatingActionButton,
    this.showBack = true,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? floatingActionButton;
  final bool showBack;

  void _handleBack(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    if (Get.key.currentState?.canPop() == true) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final isDark = DoctorUi.isDark;

    return Scaffold(
      backgroundColor: DoctorUi.scaffoldBg,
      floatingActionButton: floatingActionButton,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: DoctorUi.scaffoldBg,
        surfaceTintColor: DoctorUi.scaffoldBg,
        centerTitle: false,
        automaticallyImplyLeading: false,
        leading: showBack
            ? IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: () => _handleBack(context),
              )
            : leading,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.bodyMedium?.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: theme.bodySmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: DoctorUi.muted,
                ),
              ),
            ],
          ],
        ),
        actions: actions,
      ),
      body: SafeArea(top: false, child: body),
    );
  }
}

class DoctorSectionHeader extends StatelessWidget {
  const DoctorSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.count,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          if (count != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: DoctorUi.primary.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                '$count',
                style: theme.bodySmall?.copyWith(
                  color: DoctorUi.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: DoctorUi.primary,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

class DoctorCard extends StatelessWidget {
  const DoctorCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    final decoration = BoxDecoration(
      color: DoctorUi.surface,
      borderRadius: radius,
      border: Border.all(color: DoctorUi.border),
    );

    if (onTap == null) {
      return Container(padding: padding, decoration: decoration, child: child);
    }

    return Material(
      color: DoctorUi.surface,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: DoctorUi.border),
          ),
          child: child,
        ),
      ),
    );
  }
}

class DoctorEmptyState extends StatelessWidget {
  const DoctorEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: DoctorUi.primary.withValues(alpha: .1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: DoctorUi.primary, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.bodySmall?.copyWith(
                color: DoctorUi.muted,
                height: 1.4,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class DoctorStatusPill extends StatelessWidget {
  const DoctorStatusPill({super.key, required this.status});

  final AppointmentStatus? status;

  @override
  Widget build(BuildContext context) {
    final color = DoctorUi.statusColor(status);
    final label = (status?.name ?? 'pending').capitalize ?? 'Pending';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class DoctorSearchField extends StatelessWidget {
  const DoctorSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: DoctorUi.fieldBg,
        prefixIcon: Icon(Icons.search_rounded, color: DoctorUi.muted, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
