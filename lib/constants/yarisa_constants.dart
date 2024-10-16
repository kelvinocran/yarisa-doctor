import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yarisa_doctor/screens/main/appointment_screen.dart';
import 'package:yarisa_doctor/screens/main/availability_screen.dart';
import 'package:yarisa_doctor/screens/main/home_screen.dart';
import 'package:yarisa_doctor/screens/main/patients_screen.dart';

import 'yarisa_strings.dart';

class YarisaConstants {
  static const visueltPro = "VisueltPro";
  static const poppins = "Poppins";
  static final font = GoogleFonts.poppins();

  static final List<Widget> basePages = [
    const HomeScreen(),
    const AppointmentScreen(),
    const AvailabilityScreen(),
    const PatientsScreen()
  ];
}

class Loader extends StatelessWidget {
  const Loader({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const CircleAvatar(
      radius: 25,
      child: SizedBox(
          height: 30,
          width: 30,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            strokeCap: StrokeCap.round,
          )),
    );
  }
}

String greeting() {
  var hour = DateTime.now().hour;
  if (hour < 12) {
    return AppStrings.morning;
  } else if (hour < 17) {
    return AppStrings.afternoon;
  } else if (hour < 21) {
    return AppStrings.evening;
  } else {
    return AppStrings.night;
  }
}

class YarisaDimens {
  static const bodyLarge = 16.0;
  static const bodyMedium = 14.0;
  static const bodySmall = 12.0;
  static const headlineLarge = 40.0;
  static const headlineMedium = 32.0;
  static const headlineSmall = 25.0;
  static const titleLarge = 20.0;
  static const titleMedium = 18.0;
  static const titleSmall = 16.0;
  static const displayLarge = 70.0;
  static const displayMedium = 60.0;
  static const displaySmall = 50.0;
  static const labelLarge = 16.0;
  static const labelMedium = 14.0;
  static const labelSmall = 12.0;
}
