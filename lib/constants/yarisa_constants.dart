import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yarisa_doctor/screens/main/appointment_screen.dart';
import 'package:yarisa_doctor/screens/main/availability_screen.dart';
import 'package:yarisa_doctor/screens/main/home_screen.dart';
import 'package:yarisa_doctor/screens/main/patients_screen.dart';

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
