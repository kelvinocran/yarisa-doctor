import 'package:flutter/material.dart';

import '../constants/yarisa_colors.dart';
import '../constants/yarisa_constants.dart';

class YarisaTheme {
  static ThemeData lightThemeData(BuildContext context) {
    return ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: YarisaConstants.poppins,
        primaryColor: YarisaColors.primaryColor,
        textTheme: TextTheme(
            bodyLarge: const TextStyle(
              color: Colors.black,
              fontSize: YarisaDimens.bodyLarge,
            ),
            bodyMedium: const TextStyle(
              color: Colors.black,
              fontSize: YarisaDimens.bodyMedium,
            ),
            bodySmall: TextStyle(
              color: Colors.grey.shade700,
              fontSize: YarisaDimens.bodySmall,
            ),
            labelLarge: const TextStyle(
              color: Colors.black,
              fontSize: YarisaDimens.labelLarge,
            ),
            labelMedium: const TextStyle(
              fontSize: YarisaDimens.labelMedium,
              color: Colors.black,
            ),
            labelSmall: const TextStyle(
              fontSize: YarisaDimens.labelSmall,
              color: Colors.black,
            ),
            titleMedium: const TextStyle(
              fontSize: YarisaDimens.titleMedium,
              color: Colors.black,
            ),
            titleSmall: const TextStyle(
                fontSize: YarisaDimens.titleSmall, color: Colors.black),
            displayLarge: const TextStyle(
              fontSize: YarisaDimens.displayLarge,
              color: Colors.black,
              fontWeight: FontWeight.w900,
            ),
            displayMedium: const TextStyle(
              fontSize: YarisaDimens.displayMedium,
              color: Colors.black,
              fontWeight: FontWeight.w900,
            ),
            displaySmall: const TextStyle(
              fontSize: YarisaDimens.displaySmall,
              color: Colors.black,
              fontWeight: FontWeight.w800,
            ),
            headlineLarge: const TextStyle(
              fontSize: YarisaDimens.headlineLarge,
              color: Colors.black,
              fontWeight: FontWeight.w800,
            ),
            headlineMedium: const TextStyle(
              fontSize: YarisaDimens.headlineMedium,
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
            headlineSmall: const TextStyle(
              letterSpacing: -1,
              fontSize: YarisaDimens.headlineSmall,
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
            titleLarge: const TextStyle(
              fontSize: YarisaDimens.titleLarge,
              color: Colors.black,
              fontWeight: FontWeight.w600,
            )),
        focusColor: YarisaColors.primaryColor,
        colorScheme: ColorScheme.fromSeed(
            seedColor: YarisaColors.primaryColor,
            brightness: Brightness.light,
            surfaceContainerLow: Colors.white),
        dialogBackgroundColor: const Color(0xFFF5F5F5),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
            shape: const CircleBorder(),
            backgroundColor: YarisaColors.primaryColor,
            foregroundColor: Colors.white),
        appBarTheme: AppBarTheme(
            titleTextStyle: const TextStyle(
                fontFamily: YarisaConstants.poppins,
                fontSize: YarisaDimens.bodyLarge,
                color: Colors.black,
                fontWeight: FontWeight.w500),
            backgroundColor: YarisaColors.lightBackgroundColor,
            surfaceTintColor: YarisaColors.lightBackgroundColor,
            iconTheme: IconThemeData(color: YarisaColors.textLightBodyColor)),
        scaffoldBackgroundColor: YarisaColors.lightBackgroundColor,
        listTileTheme: ListTileThemeData(tileColor: Colors.grey.shade200),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: const Color(0xFFFFFFFF),
            selectedItemColor: YarisaColors.primaryColor),
        dividerTheme: DividerThemeData(color: Colors.grey.withOpacity(.2)),
        outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
          textStyle: const TextStyle(
              fontSize: YarisaDimens.bodyMedium,
              fontWeight: FontWeight.w500,
              fontFamily: YarisaConstants.poppins),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          // side: const BorderSide(color: Colors.grey),
        )),
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ButtonStyle(
                padding: const WidgetStatePropertyAll(EdgeInsets.all(15)),
                shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100))),
                elevation:
                    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
                  if (states.contains(WidgetState.hovered)) {
                    return 5.0;
                  } else {
                    return 0.0;
                  }
                }),
                backgroundColor:
                    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
                  if (states.contains(WidgetState.disabled)) {
                    return YarisaColors.disabledLightColor;
                  } else if (states.contains(WidgetState.hovered)) {
                    return YarisaColors.hoverColor;
                  } else {
                    return YarisaColors.primaryColor;
                  }
                }),
                surfaceTintColor:
                    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
                  if (states.contains(WidgetState.disabled)) {
                    return Colors.blue.shade500;
                  } else if (states.contains(WidgetState.hovered)) {
                    return YarisaColors.hoverColor;
                  } else {
                    return YarisaColors.primaryColor;
                  }
                }),
                shadowColor:
                    WidgetStateProperty.all<Color>(YarisaColors.shadowColor),
                textStyle: WidgetStateProperty.all(const TextStyle(
                    fontSize: YarisaDimens.bodyMedium,
                    fontWeight: FontWeight.w500,
                    fontFamily: YarisaConstants.poppins)),
                foregroundColor:
                    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
                  if (states.contains(WidgetState.disabled)) {
                    return Colors.grey.shade500;
                  } else {
                    return YarisaColors.whiteColor;
                  }
                }))),
        textButtonTheme: TextButtonThemeData(
            style: ButtonStyle(
                shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100))),
                padding: const WidgetStatePropertyAll(EdgeInsets.all(15)),
                textStyle: const WidgetStatePropertyAll(TextStyle(
                    fontSize: YarisaDimens.bodyMedium,
                    fontWeight: FontWeight.w500,
                    fontFamily: YarisaConstants.poppins)),
                foregroundColor:
                    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
                  if (states.contains(WidgetState.disabled)) {
                    return Colors.grey.shade600;
                  } else if (states.contains(WidgetState.hovered)) {
                    return Colors.black;
                  } else {
                    return YarisaColors.primaryColor;
                  }
                }))));
  }

  static ThemeData darkThemeData(BuildContext context) {
    return ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: YarisaConstants.poppins,
        primaryColor: YarisaColors.alternateColor,
        textTheme: const TextTheme(
            bodyLarge: TextStyle(
              color: Colors.white,
              fontSize: YarisaDimens.bodyLarge,
            ),
            bodyMedium: TextStyle(
                color: Colors.white, fontSize: YarisaDimens.bodyMedium),
            bodySmall:
                TextStyle(color: Colors.grey, fontSize: YarisaDimens.bodySmall),
            labelLarge: TextStyle(
              color: Colors.white,
              fontSize: YarisaDimens.labelLarge,
            ),
            labelMedium: TextStyle(
              fontSize: YarisaDimens.labelMedium,
              color: Colors.white,
            ),
            labelSmall: TextStyle(
              fontSize: YarisaDimens.labelSmall,
              color: Colors.white,
            ),
            titleMedium: TextStyle(
              fontSize: YarisaDimens.titleMedium,
              color: Colors.white,
            ),
            titleSmall: TextStyle(
                fontSize: YarisaDimens.titleSmall, color: Colors.white),
            displayLarge: TextStyle(
              fontSize: YarisaDimens.displayLarge,
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
            displayMedium: TextStyle(
              fontSize: YarisaDimens.displayMedium,
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
            displaySmall: TextStyle(
              fontSize: YarisaDimens.displaySmall,
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
            headlineLarge: TextStyle(
              fontSize: YarisaDimens.headlineLarge,
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
            headlineMedium: TextStyle(
              fontSize: YarisaDimens.headlineMedium,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
            headlineSmall: TextStyle(
              letterSpacing: -1,
              fontSize: YarisaDimens.headlineSmall,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            titleLarge: TextStyle(
              fontSize: YarisaDimens.titleLarge,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            )),
        scaffoldBackgroundColor: YarisaColors.darkBackgroundColor,
        listTileTheme: ListTileThemeData(
          tileColor: Colors.grey.shade900,
        ),
        colorScheme: ColorScheme.fromSeed(
            seedColor: YarisaColors.alternateColor,
            surfaceContainerLow: const Color(0xFF181818),
            brightness: Brightness.dark),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
            shape: const CircleBorder(),
            backgroundColor: YarisaColors.alternateColor,
            foregroundColor: Colors.white),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
            selectedItemColor: YarisaColors.alternateColor,
            backgroundColor: const Color(0xff0e0e0e)),
        dividerColor: Colors.grey.withOpacity(.2),
        focusColor: YarisaColors.alternateColor,
        dialogBackgroundColor: const Color(0xFF252525),
        dropdownMenuTheme: DropdownMenuThemeData(
            inputDecorationTheme: InputDecorationTheme(
                filled: true, fillColor: Colors.grey.withOpacity(.2)),
            menuStyle: const MenuStyle(
                surfaceTintColor: WidgetStatePropertyAll(Color(0xFF222222)),
                backgroundColor: WidgetStatePropertyAll(Color(0xFF222222)))),
        appBarTheme: AppBarTheme(
            titleTextStyle: const TextStyle(
                fontFamily: YarisaConstants.poppins,
                fontSize: YarisaDimens.bodyLarge,
                color: Colors.white,
                fontWeight: FontWeight.w500),
            backgroundColor: YarisaColors.darkBackgroundColor,
            surfaceTintColor: YarisaColors.darkBackgroundColor,
            iconTheme: IconThemeData(color: YarisaColors.textDarkBodyColor)),
        outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
                textStyle: const TextStyle(
                    fontSize: YarisaDimens.bodyMedium,
                    fontWeight: FontWeight.w500,
                    fontFamily: YarisaConstants.poppins),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100)),
                side: BorderSide(color: Colors.grey.shade700),
                foregroundColor: Colors.white)),
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ButtonStyle(
                padding: const WidgetStatePropertyAll(EdgeInsets.all(15)),
                shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100))),
                backgroundColor:
                    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
                  if (states.contains(WidgetState.disabled)) {
                    return YarisaColors.disabledDarkColor;
                  } else if (states.contains(WidgetState.hovered)) {
                    return YarisaColors.hoverColor;
                  } else {
                    return YarisaColors.alternateColor;
                  }
                }),
                surfaceTintColor:
                    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
                  if (states.contains(WidgetState.disabled)) {
                    return Colors.grey.shade900;
                  } else if (states.contains(WidgetState.hovered)) {
                    return YarisaColors.shadowColor;
                  } else {
                    return YarisaColors.alternateColor;
                  }
                }),
                shadowColor:
                    WidgetStateProperty.all<Color>(YarisaColors.shadowColor),
                textStyle: WidgetStateProperty.all(const TextStyle(
                    fontSize: YarisaDimens.bodyMedium,
                    fontWeight: FontWeight.w500,
                    fontFamily: YarisaConstants.poppins)),
                foregroundColor:
                    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
                  if (states.contains(WidgetState.disabled)) {
                    return Colors.grey.shade600;
                  } else {
                    return Colors.white;
                  }
                }))),
        textButtonTheme: TextButtonThemeData(
            style: ButtonStyle(
                shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100))),
                padding: const WidgetStatePropertyAll(EdgeInsets.all(15)),
                textStyle: const WidgetStatePropertyAll(
                    TextStyle(fontSize: YarisaDimens.bodyMedium, fontWeight: FontWeight.w500, fontFamily: YarisaConstants.poppins)),
                foregroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
                  if (states.contains(WidgetState.disabled)) {
                    return Colors.grey.shade600;
                  } else if (states.contains(WidgetState.hovered)) {
                    return Colors.white;
                  } else {
                    return YarisaColors.alternateColor;
                  }
                }))));
  }
}

ThemeData themeData(int index, BuildContext context) {
  if (index == 0) {
    return YarisaTheme.lightThemeData(context);
  } else {
    return YarisaTheme.darkThemeData(context);
  }
}

ThemeMode themeModeData(int index) {
  switch (index) {
    case 0:
      return ThemeMode.system;
    case 1:
      return ThemeMode.light;
    case 2:
      return ThemeMode.dark;

    default:
      return ThemeMode.system;
  }
}
