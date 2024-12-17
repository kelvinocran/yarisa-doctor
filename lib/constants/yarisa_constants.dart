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

  final String image;
  final double size, radius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: Colors.green.withOpacity(.2))),
            child: CachedNetworkImage(
              imageUrl: image,
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
              progressIndicatorBuilder: (context, url, progress) => ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: CircleAvatar(
                  backgroundColor: Colors.grey.withOpacity(.3),
                  child: const Icon(
                    EneftyIcons.profile_bold,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: CircleAvatar(
                  backgroundColor: Colors.grey.withOpacity(.3),
                  child: const Icon(
                    EneftyIcons.profile_outline,
                  ),
                ),
              ),
              fit: BoxFit.cover,
            ),
          )),
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
    return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("Appointments")
            .where("doctor_id",
                isEqualTo: FirebaseAuth.instance.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const SizedBox.shrink();
          }
          if (!snapshot.hasData) {
            return const SizedBox.shrink();
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox.shrink();
          }
          final appointments = (snapshot.data?.docs ?? [])
              .map((e) => AppointmentModel.fromSnapshot(e))
              .where((appoint) {
            final date = appoint.date?.toDate().copyWith(
                hour: int.parse(
                    appoint.time!.split("-").first.trim().split(":").first),
                minute: int.parse(
                    appoint.time!.split("-").first.trim().split(":").last));

            return (date!.isAfter(DateTime.now()) &&
                appoint.status == AppointmentStatus.approved);
          }).toList();

          if (appointments.isEmpty) {
            return const SizedBox.shrink();
          }

          appointments.sort((a, b) => (a.date as Timestamp)
              .toDate()
              .compareTo((b.date as Timestamp).toDate()));
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
                  TextButton(onPressed: () {}, child: const Text("See All"))
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
        });
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
      onTap: () {},
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
                  image: "${appointment.patient?.photo}",
                ),
                15.wgap,
                Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      YarisaText(
                        text: "${appointment.patient?.name}",
                        type: TextType.bodyBig,
                        color: Colors.white,
                        spacing: 0,
                        weight: FontWeight.w600,
                      ),
                      YarisaText(
                        text: "${appointment.purpose}",
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
                            text: DateFormat.MMMMEEEEd()
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
                            text: "${appointment.time}",
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
