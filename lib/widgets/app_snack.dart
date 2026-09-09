import 'dart:async';

import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yarisa_doctor/ui/doctor_ui.dart';

enum AppSnackKind { success, error, info }

/// Floating in-app toast. Prefer this over [SnackBar] / [Get.snackbar].
class AppSnack {
  AppSnack._();

  static OverlayEntry? _entry;
  static Timer? _timer;

  static void success(BuildContext? context, String message) =>
      show(context, message, kind: AppSnackKind.success);

  static void error(BuildContext? context, String message) =>
      show(context, message, kind: AppSnackKind.error);

  static void info(BuildContext? context, String message) =>
      show(context, message, kind: AppSnackKind.info);

  static void show(
    BuildContext? context,
    String message, {
    AppSnackKind kind = AppSnackKind.info,
  }) {
    final overlay = _overlay(context);
    if (overlay == null) return;

    _timer?.cancel();
    _entry?.remove();
    _entry = null;

    final color = switch (kind) {
      AppSnackKind.success => const Color(0xFF15803D),
      AppSnackKind.error => const Color(0xFFB91C1C),
      AppSnackKind.info => DoctorUi.primary,
    };
    final icon = switch (kind) {
      AppSnackKind.success => EneftyIcons.tick_circle_bold,
      AppSnackKind.error => EneftyIcons.warning_2_bold,
      AppSnackKind.info => EneftyIcons.notification_bold,
    };

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        final bottom = MediaQuery.of(context).viewPadding.bottom;
        return Positioned(
          left: 16,
          right: 16,
          bottom: bottom + 18,
          child: IgnorePointer(
            child: Material(
              color: Colors.transparent,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .18),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: Colors.white, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(entry);
    _entry = entry;
    _timer = Timer(const Duration(milliseconds: 2800), hide);
  }

  static void hide() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }

  static OverlayState? _overlay(BuildContext? context) {
    if (context != null && context.mounted) {
      final found = Overlay.maybeOf(context, rootOverlay: true);
      if (found != null) return found;
    }
    final overlayContext = Get.overlayContext;
    if (overlayContext != null && overlayContext.mounted) {
      return Overlay.maybeOf(overlayContext, rootOverlay: true);
    }
    return null;
  }
}
