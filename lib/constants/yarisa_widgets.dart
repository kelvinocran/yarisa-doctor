import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:yarisa_doctor/constants/yarisa_enums.dart';
import 'package:yarisa_doctor/extensions/yarisa_extensions.dart';
import 'package:yarisa_doctor/screens/main/appointment_screen.dart';
import 'package:yarisa_doctor/screens/main/chat_inbox_screen.dart';
import 'package:yarisa_doctor/screens/main/second_opinions_screen.dart';
import 'package:yarisa_doctor/screens/settings_screen.dart';

class YarisaText extends StatelessWidget {
  const YarisaText(
      {super.key,
      required this.text,
      required this.type,
      this.weight,
      this.color,
      this.size,
      this.height,
      this.spacing,
      this.lines,
      this.align});

  final String text;
  final TextAlign? align;
  final TextType type;
  final FontWeight? weight;
  final Color? color;

  final double? size, height, spacing;
  final int? lines;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        maxLines: lines,
        textAlign: align,
        overflow: TextOverflow.ellipsis,
        style: switch (type) {
          TextType.heading => context.headlineMedium?.copyWith(
              fontWeight: weight,
              color: color,
              fontSize: size,
              height: height,
              letterSpacing: spacing),
          TextType.title => context.headlineSmall?.copyWith(
              fontWeight: weight,
              color: color,
              fontSize: size,
              height: height,
              letterSpacing: spacing),
          TextType.bodyBig => context.bodyLarge?.copyWith(
              fontWeight: weight,
              color: color,
              fontSize: size,
              height: height,
              letterSpacing: spacing),
          TextType.bodySmall => context.bodyMedium?.copyWith(
              fontWeight: weight,
              color: color,
              fontSize: size,
              height: height,
              letterSpacing: spacing),
          TextType.subtitle => context.bodySmall?.copyWith(
              fontWeight: weight,
              color: color,
              fontSize: size,
              height: height,
              letterSpacing: spacing),
          TextType.caption => context.titleSmall?.copyWith(
              fontWeight: weight,
              color: color,
              fontSize: size,
              height: height,
              letterSpacing: spacing),
          TextType.headingLarge => context.headlineLarge?.copyWith(
              fontWeight: weight,
              color: color,
              fontSize: size,
              height: height,
              letterSpacing: spacing),
          TextType.appbar => context.titleLarge?.copyWith(
              fontWeight: weight ?? FontWeight.w700,
              color: color,
              fontSize: size ?? 24,
              height: height,
              letterSpacing: spacing),
        });
  }
}

String? validNetworkImageUrl(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty || trimmed.toLowerCase() == 'null') {
    return null;
  }

  final uri = Uri.tryParse(trimmed);
  if (uri == null ||
      (uri.scheme != 'http' && uri.scheme != 'https') ||
      uri.host.isEmpty) {
    return null;
  }

  return trimmed;
}

/// Prefer live patient profile fields (`photo` / `pic`) over stale mirrors.
String? patientAvatarUrl(Map<String, dynamic>? data) {
  if (data == null) return null;
  final nested = data['patient'] is Map
      ? Map<String, dynamic>.from(data['patient'] as Map)
      : const <String, dynamic>{};
  for (final key in ['photo', 'pic', 'patientImage', 'image', 'avatar']) {
    final fromTop = validNetworkImageUrl(data[key]?.toString());
    if (fromTop != null) return fromTop;
    final fromNested = validNetworkImageUrl(nested[key]?.toString());
    if (fromNested != null) return fromNested;
  }
  return null;
}

ImageProvider? safeCachedNetworkImageProvider(String? value) {
  final imageUrl = validNetworkImageUrl(value);
  return imageUrl == null ? null : CachedNetworkImageProvider(imageUrl);
}

AppBar yarisaAppBar(BuildContext context,
        {String? title,
        List<Widget>? actions,
        Widget? titleWidget,
        Widget? leading,
        double? titleSpacing,
        double? fontSize,
        bool autoShowBackButton = true,
        bool centerTitle = false}) =>
    AppBar(
      centerTitle: centerTitle,
      actions: actions ??
          [
            IconButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (sheetContext) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const ListTile(
                            title: Text(
                              'Quick links',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          ListTile(
                            leading:
                                const Icon(EneftyIcons.calendar_2_outline),
                            title: const Text('Appointments'),
                            onTap: () {
                              Navigator.pop(sheetContext);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AppointmentScreen(),
                                ),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(EneftyIcons.message_outline),
                            title: const Text('Messages'),
                            onTap: () {
                              Navigator.pop(sheetContext);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const DoctorChatInboxScreen(),
                                ),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(EneftyIcons.note_2_outline),
                            title: const Text('Second opinions'),
                            onTap: () {
                              Navigator.pop(sheetContext);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const SecondOpinionsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                icon: const Icon(EneftyIcons.notification_outline)),
            IconButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SettingsScreen()));
                },
                icon: const Icon(EneftyIcons.setting_2_outline))
          ],
      leading: leading,
      titleSpacing: titleSpacing,
      automaticallyImplyLeading: autoShowBackButton,
      title: titleWidget ??
          YarisaText(
            text: title ?? "",
            type: TextType.appbar,
            size: fontSize,
          ),
    );
