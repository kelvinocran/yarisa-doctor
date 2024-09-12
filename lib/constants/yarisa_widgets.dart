import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:yarisa_doctor/constants/yarisa_enums.dart';
import 'package:yarisa_doctor/extensions/yarisa_extensions.dart';
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
                onPressed: () {},
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
