import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:yarisa_doctor/extensions/yarisa_extensions.dart';
import 'package:yarisa_doctor/screens/main/appointment_screen.dart';
import 'package:yarisa_doctor/screens/main/availability_screen.dart';
import 'package:yarisa_doctor/screens/main/home_screen.dart';
import 'package:yarisa_doctor/screens/main/patients_screen.dart';

import '../models/appointment_model.dart';
import 'yarisa_enums.dart';
import 'yarisa_strings.dart';
import 'yarisa_widgets.dart';

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

class CircleImage extends StatelessWidget {
  const CircleImage({
    super.key,
    required this.image,
    this.size = 60,
    this.radius = 100,
  });

  final String? image;
  final double size, radius;

  @override
  Widget build(BuildContext context) {
    final imageUrl = validNetworkImageUrl(image);

    return SizedBox(
      height: size,
      width: size,
      child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: Colors.green.withValues(alpha: .2))),
            child: imageUrl == null
                ? _fallback(EneftyIcons.profile_outline)
                : CachedNetworkImage(
                    imageUrl: imageUrl,
                    imageBuilder: (context, imageProvider) => Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(radius),
                        image: DecorationImage(
                          //image size fill
                          image: imageProvider,
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                    ),
                    progressIndicatorBuilder: (context, url, progress) =>
                        _fallback(EneftyIcons.profile_bold),
                    errorWidget: (context, url, error) =>
                        _fallback(EneftyIcons.profile_outline),
                    fit: BoxFit.cover,
                  ),
          )),
    );
  }

  Widget _fallback(IconData icon) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CircleAvatar(
        backgroundColor: Colors.grey.withValues(alpha: .3),
        child: Icon(icon),
      ),
    );
  }
}

class UpcomingAppointments extends StatefulWidget {
  const UpcomingAppointments({
    super.key,
  });

  @override
  State<UpcomingAppointments> createState() => _UpcomingAppointmentsState();
}

class _UpcomingAppointmentsState extends State<UpcomingAppointments> {
  @override
  Widget build(BuildContext context) {
    final doctorId = FirebaseAuth.instance.currentUser?.uid;

    if (doctorId == null) {
      return const SizedBox.shrink();
    }

    final appointmentsRef = FirebaseFirestore.instance.collection(
      "Appointments",
    );

    return StreamBuilder(
      stream:
          appointmentsRef.where("doctor_id", isEqualTo: doctorId).snapshots(),
      builder: (context, legacySnapshot) {
        return StreamBuilder(
          stream: appointmentsRef
              .where("doctorId", isEqualTo: doctorId)
              .snapshots(),
          builder: (context, canonicalSnapshot) {
            if (legacySnapshot.hasError || canonicalSnapshot.hasError) {
              return const SizedBox.shrink();
            }

            final docs = {
              for (final doc in legacySnapshot.data?.docs ?? []) doc.id: doc,
              for (final doc in canonicalSnapshot.data?.docs ?? []) doc.id: doc,
            };

            final appointments = docs.values
                .map((doc) => AppointmentModel.fromSnapshot(doc))
                .where((appoint) {
              final date = appointmentStartsAt(appoint);

              return date != null &&
                  date.isAfter(DateTime.now()) &&
                  _activeAppointmentStatus(appoint.status);
            }).toList()
              ..sort(compareAppointmentsByStart);

            return _buildAppointments(context, appointments);
          },
        );
      },
    );
  }

  Widget _buildAppointments(
    BuildContext context,
    List<AppointmentModel> appointments,
  ) {
    if (appointments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const YarisaText(
              text: "Upcoming Appointments",
              type: TextType.bodyBig,
              spacing: 0,
              weight: FontWeight.w500,
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AppointmentScreen(),
                  ),
                );
              },
              child: const Text("See All"),
            ),
          ],
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 180),
          child: ListView.separated(
            separatorBuilder: (context, index) => 10.wgap,
            itemCount: appointments.length,
            shrinkWrap: true,
            scrollDirection: Axis.horizontal,
            itemBuilder: (BuildContext context, int index) {
              final item = appointments[index];
              return AppointmentItem(appointment: item);
            },
          ),
        ),
        40.hgap,
      ],
    );
  }
}

class AppointmentItem extends StatelessWidget {
  const AppointmentItem({
    super.key,
    required this.appointment,
  });

  final AppointmentModel appointment;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => openDoctorAppointmentDetail(context, appointment),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 350),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
            color: const Color.fromARGB(255, 118, 34, 135),
            borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                CircleImage(
                  size: 40,
                  image: appointment.patient?.photo,
                ),
                15.wgap,
                Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      YarisaText(
                        text: appointmentPatientName(appointment),
                        type: TextType.bodyBig,
                        color: Colors.white,
                        spacing: 0,
                        weight: FontWeight.w600,
                      ),
                      YarisaText(
                        text: appointmentPurposeText(appointment),
                        type: TextType.bodySmall,
                        // spacing: 0,
                        color: Colors.white,
                      ),
                    ]),
                const Spacer(),
                const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(
                      EneftyIcons.call_bold,
                      size: 20,
                      color: Color.fromARGB(255, 118, 34, 135),
                    ))
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color.fromARGB(255, 91, 26, 104)),
              child: OverflowBar(
                children: [
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        const Icon(
                          EneftyIcons.calendar_2_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                        5.wgap,
                        Expanded(
                          child: YarisaText(
                            text: appointment.date == null
                                ? "Date not set"
                                : DateFormat.MMMMEEEEd()
                                    .format(appointment.date!.toDate()),
                            type: TextType.subtitle,
                            color: Colors.white,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  10.hgap,
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          EneftyIcons.clock_2_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                        5.wgap,
                        Flexible(
                          child: YarisaText(
                            text: appointmentTimeText(appointment),
                            type: TextType.subtitle,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool _activeAppointmentStatus(AppointmentStatus? status) {
  final currentStatus = status ?? AppointmentStatus.pending;
  return currentStatus == AppointmentStatus.pending ||
      currentStatus == AppointmentStatus.approved;
}

String appointmentPatientName(AppointmentModel appointment) {
  return nonEmptyAppointmentText(appointment.patient?.name, "Unknown Patient");
}

String appointmentPurposeText(AppointmentModel appointment) {
  return nonEmptyAppointmentText(appointment.purpose, "General appointment");
}

String appointmentTimeText(AppointmentModel appointment) {
  return nonEmptyAppointmentText(appointment.time, "Time not set");
}

String nonEmptyAppointmentText(String? value, String fallback) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty || trimmed.toLowerCase() == 'null') {
    return fallback;
  }
  return trimmed;
}

DateTime? appointmentStartsAt(AppointmentModel appointment) {
  final date = appointment.date?.toDate();
  if (date == null) return null;

  final rawTime = appointment.time?.split('-').first.trim();
  if (rawTime == null || rawTime.isEmpty) return date;

  final match =
      RegExp(r'^(\d{1,2}):(\d{2})\s*([AaPp][Mm])?').firstMatch(rawTime);
  if (match == null) return date;

  var hour = int.tryParse(match.group(1)!);
  final minute = int.tryParse(match.group(2)!);
  if (hour == null || minute == null || minute > 59) return date;

  final meridiem = match.group(3)?.toLowerCase();
  if (meridiem == 'pm' && hour < 12) {
    hour += 12;
  } else if (meridiem == 'am' && hour == 12) {
    hour = 0;
  }

  if (hour > 23) return date;
  return DateTime(date.year, date.month, date.day, hour, minute);
}

int compareAppointmentsByStart(
    AppointmentModel first, AppointmentModel second) {
  final firstDate = appointmentStartsAt(first) ?? DateTime(0);
  final secondDate = appointmentStartsAt(second) ?? DateTime(0);
  return firstDate.compareTo(secondDate);
}

String timeOfDay(DateTime date) {
  int numberOfDays = date.difference(DateTime.now()).inDays + 1;

  if (DateFormat.MMMd().format(DateTime.now()) ==
      DateFormat.MMMd().format(date)) {
    return "Today";
  } else if (DateFormat.MMMd().format(date) ==
      DateFormat.MMMd().format(DateTime.now().add(const Duration(days: 1)))) {
    return "Tomorrow";
  } else if (DateFormat.MMMd().format(date) ==
      DateFormat.MMMd().format(DateTime.now().add(Duration(
          days: numberOfDays < 6 && numberOfDays > 0 ? numberOfDays : 0)))) {
    return "In $numberOfDays Days";
  } else if (DateFormat.MMMd().format(date) ==
      DateFormat.MMMd()
          .format(DateTime.now().subtract(const Duration(days: 1)))) {
    return "Yesterday";
  } else if (DateFormat.MMMd().format(date) ==
      DateFormat.MMMd()
          .format(DateTime.now().subtract(const Duration(days: 7)))) {
    return "A week ago";
  } else {
    return DateFormat.yMMMEd().format(date);
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
