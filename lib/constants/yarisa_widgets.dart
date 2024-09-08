import 'package:flutter/material.dart';
import 'package:yarisa_doctor/constants/yarisa_enums.dart';
import 'package:yarisa_doctor/extensions/yarisa_extensions.dart';

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
      this.lines});

  final String text;
  final TextType type;
  final FontWeight? weight;
  final Color? color;

  final double? size, height, spacing;
  final int? lines;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        maxLines: lines,
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
        });
  }
}
