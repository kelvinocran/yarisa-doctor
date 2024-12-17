import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import 'package:yarisa_doctor/extensions/yarisa_extensions.dart';
import 'package:yarisa_doctor/screens/chat_view.dart';

import '../../constants/yarisa_constants.dart';
import '../../constants/yarisa_enums.dart';
import '../../constants/yarisa_strings.dart';
import '../../constants/yarisa_widgets.dart';
import '../../models/appointment_model.dart';

class AppointmentScreen extends ConsumerStatefulWidget {
  const AppointmentScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _AppointmentScreenState();
}

class _AppointmentScreenState extends ConsumerState<AppointmentScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: yarisaAppBar(
        context,
        title: AppStrings.appointments,
      ),
      body: StreamBuilder(
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
              return const Loader();
            }
            final upcomingappointments = (snapshot.data?.docs ?? [])
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

            final appointments = (snapshot.data?.docs ?? [])
                .map((e) => AppointmentModel.fromSnapshot(e))
                //     .where((appoint) {
                //   final date = appoint.date?.toDate().copyWith(
                //       hour: int.parse(
                //           appoint.time!.split("-").first.trim().split(":").first),
                //       minute: int.parse(
                //           appoint.time!.split("-").first.trim().split(":").last));

                //   return (date!.isBefore(DateTime.now()));
                // })
                .toList();

            // if (upcomingappointments.isEmpty) {
            //   return const SizedBox.shrink();
            // }
            // if (appointments.isEmpty) {
            //   return const Center(
            //     child: Text("No Appointments"),
            //   );
            // }

            upcomingappointments.sort((a, b) => (a.date as Timestamp)
                .toDate()
                .compareTo((b.date as Timestamp).toDate()));
            appointments.sort((a, b) => (a.date as Timestamp)
                .toDate()
                .compareTo((b.date as Timestamp).toDate()));

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Column(
                    children: [
                      if (upcomingappointments.isNotEmpty)
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
                                onPressed: () {}, child: const Text("See All"))
                          ],
                        ),
                      if (upcomingappointments.isNotEmpty)
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 180),
                          child: ListView.separated(
                            separatorBuilder: (context, index) => 10.wgap,
                            itemCount: upcomingappointments.length,
                            shrinkWrap: true,
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (BuildContext context, int index) {
                              final item = upcomingappointments[index];
                              return AppointmentItem(appointment: item);
                            },
                          ),
                        ),
                      if (appointments.isEmpty)
                        ...[]
                      else ...[
                        Divider(
                          height: 40,
                          color: Colors.grey.withOpacity(.2),
                        ),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            YarisaText(
                              text: "All Appointments",
                              type: TextType.bodyBig,
                              spacing: 0,
                              weight: FontWeight.w500,
                            ),
                          ],
                        ),
                        15.hgap,
                        ListView.separated(
                            separatorBuilder: (context, index) => 10.hgap,
                            itemCount: appointments.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              final appointment = appointments[index];
                              return Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.grey.withOpacity(.2)),
                                    color: Colors.white.withOpacity(.1),
                                    borderRadius: BorderRadius.circular(20)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleImage(
                                          size: 50,
                                          image:
                                              "${appointment.patient?.photo}",
                                        ),
                                        15.wgap,
                                        Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              YarisaText(
                                                text:
                                                    "${appointment.patient?.name}",
                                                type: TextType.bodyBig,
                                                spacing: 0,
                                                weight: FontWeight.w600,
                                              ),
                                              YarisaText(
                                                text: "${appointment.purpose}",
                                                type: TextType.bodySmall,
                                                // spacing: 0,
                                              ),
                                            ]),
                                        const Spacer(),
                                        const CircleAvatar(
                                            backgroundColor: Colors.white,
                                            child: Icon(
                                              EneftyIcons.call_bold,
                                              size: 20,
                                              color: Color.fromARGB(
                                                  255, 118, 34, 135),
                                            ))
                                      ],
                                    ),
                                    10.hgap,
                                    Divider(
                                      color: Colors.grey.withOpacity(.2),
                                    ),
                                    10.hgap,
                                    RichText(
                                      text: TextSpan(
                                          text: timeOfDay(
                                              (appointment.date)!.toDate()),
                                          children: [
                                            TextSpan(
                                                text: " -> ${appointment.time}",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith())
                                          ],
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                  fontWeight: FontWeight.w600)),
                                    ),
                                    10.hgap,
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                              color: switch (
                                                  appointment.status) {
                                                AppointmentStatus.approved =>
                                                  Colors.green,
                                                null => Colors.grey,
                                                AppointmentStatus.pending =>
                                                  Colors.amber.shade800,
                                                AppointmentStatus.canceled =>
                                                  Colors.red,
                                                AppointmentStatus.declined =>
                                                  Colors.pink,
                                              },
                                              borderRadius:
                                                  BorderRadius.circular(50)),
                                          padding: const EdgeInsets.all(8),
                                          child: YarisaText(
                                              text:
                                                  "${appointment.status?.name}"
                                                      .capitalize!,
                                              color: Colors.white,
                                              type: TextType.subtitle),
                                        ),
                                        GestureDetector(
                                          onTapDown: (details) async {
                                            await showPopupMenu(
                                                context, details, [
                                              const PopupMenuItem(
                                                  height: 40,
                                                  value: 1,
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        EneftyIcons
                                                            .calendar_search_outline,
                                                        size: 18,
                                                      ),
                                                      SizedBox(width: 10),
                                                      Text("Reschedule"),
                                                    ],
                                                  )),
                                              const PopupMenuItem(
                                                  height: 40,
                                                  value: 1,
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        EneftyIcons
                                                            .edit_2_outline,
                                                        size: 18,
                                                      ),
                                                      SizedBox(width: 10),
                                                      Text("Edit"),
                                                    ],
                                                  )),
                                              PopupMenuItem(
                                                  value: 2,
                                                  height: 40,
                                                  onTap: () async {
                                                    // await db
                                                    //     .doc(FirebaseUtil.userAuth.currentUser?.uid)
                                                    //     .update({
                                                    //   "appointments": FieldValue.arrayRemove([item])
                                                    // });
                                                  },
                                                  child: const Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        EneftyIcons
                                                            .trash_outline,
                                                        size: 18,
                                                      ),
                                                      SizedBox(width: 10),
                                                      Text("Delete"),
                                                    ],
                                                  )),
                                            ]);
                                          },
                                          child: IconButton(
                                              onPressed: null,
                                              icon: Icon(
                                                Icons.more_vert,
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.color,
                                              )),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              );
                            })
                      ]
                    ],
                  )
                ],
              ),
            );
          }),
    );
  }
}
