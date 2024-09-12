import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get/get.dart';
import 'package:yarisa_doctor/extensions/yarisa_extensions.dart';

// import '../theme/colors.dart';

class FormTextField extends StatelessWidget {
  const FormTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.icon,
    this.endicon,
    this.isDense = false,
    this.labeled = true,
    this.autoFocus = true,
    this.enabled,
    this.label,
    this.filled,
    this.inputType,
    this.capitalization,
    this.action,
    this.lines,
    this.minlines,
    this.radius,
    this.fontSize,
    this.iconSize,
    this.spacing,
    this.leading,
    this.obscure,
    this.validator,
    this.color,
    this.textColor,
    this.endIconFunction,
    this.vpadding = 18,
    this.hpadding = 12,
    this.formatters,
    this.onChanged,
    this.onSubmitted,
    this.autoHints,
    this.fillColor,
    this.outlineColor,
    this.focusNode,
    this.initialValue,
  });

  final TextEditingController? controller;
  final String hint;
  final List<String>? autoHints;
  final String? label, initialValue;
  final IconData? icon;
  final Widget? endicon;
  final bool? filled, enabled;
  final bool labeled, isDense, autoFocus;
  final TextInputType? inputType;
  final TextCapitalization? capitalization;
  final TextInputAction? action;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged, onSubmitted;
  final Function()? endIconFunction;
  final FocusNode? focusNode;
  final int? lines, minlines;
  final double? radius, fontSize, spacing, iconSize;
  final double vpadding, hpadding;
  final Widget? leading;
  final List<TextInputFormatter>? formatters;

  final bool? obscure;
  final Color? color, textColor, fillColor, outlineColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextFormField(
      autofocus: autoFocus,
      // expands: true,
      validator: validator,
      controller: controller,
      autofillHints: autoHints,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      enableSuggestions: true,
      onChanged: onChanged,
      focusNode: focusNode,
      onFieldSubmitted: onSubmitted,
      enabled: enabled,
      enableIMEPersonalizedLearning: true,
      enableInteractiveSelection: true,
      keyboardType: inputType,
      textCapitalization: capitalization ?? TextCapitalization.words,
      maxLines: lines,
      minLines: minlines,
      obscureText: obscure ?? false,
      inputFormatters: formatters,
      style: context.bodySmall?.copyWith(
          color: textColor ??
              (Get.isDarkMode ? textColor ?? Colors.white : Colors.black),
          fontSize: fontSize,
          letterSpacing: spacing,
          fontWeight: FontWeight.w600),
      textInputAction: action,
      textAlignVertical: TextAlignVertical.top,
      decoration: InputDecoration(
        
        contentPadding:
            EdgeInsets.symmetric(horizontal: hpadding, vertical: vpadding),
        isDense: isDense,
        filled: filled ?? true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius ?? 10.0),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius ?? 10.0),
          borderSide: BorderSide(
              color: Get.isDarkMode
                  ? color ?? Colors.grey.withOpacity(.1)
                  : color ?? Colors.grey.withOpacity(.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
              color: Get.isDarkMode
                  ? outlineColor ?? Colors.grey.withOpacity(.0)
                  : outlineColor ?? Colors.grey.withOpacity(.0)),
          borderRadius: BorderRadius.circular(radius ?? 10.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Get.isDarkMode
                ? outlineColor ?? Theme.of(context).focusColor
                : outlineColor ?? Theme.of(context).focusColor,
          ),
          borderRadius: BorderRadius.circular(radius ?? 10.0),
        ),
        prefixIcon: icon != null
            ? Padding(
                padding: const EdgeInsets.only(
                  left: 10,
                  right: 10,
                ),
                child: Icon(icon, size: iconSize, color: Colors.grey),
              )
            : leading,
        suffixIcon: endicon != null
            ? SizedBox(
                width: 50,
                child: Center(
                  child: InkWell(
                    onTap: endIconFunction,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      child: Column(
                        children: [
                          endicon!,
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : null,
        labelText: labeled ? label ?? hint : null,
        alignLabelWithHint: true,
        labelStyle:
            context.bodySmall?.copyWith(color: Colors.grey, fontSize: fontSize),
        hintText: hint,
        hintStyle:
            context.bodySmall?.copyWith(color: Colors.grey, fontSize: fontSize),
        fillColor: fillColor ?? theme.listTileTheme.tileColor,
      ),
    );
  }
}
