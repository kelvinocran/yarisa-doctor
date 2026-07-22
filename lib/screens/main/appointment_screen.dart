import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:yarisa_doctor/extensions/yarisa_extensions.dart';

import '../../api/firestore_schema.dart';
import '../../api/api_methods.dart';
import '../../components/formtextfield.dart';
import '../../constants/yarisa_constants.dart';
import '../../constants/yarisa_enums.dart';
import '../../constants/yarisa_strings.dart';
import '../../constants/yarisa_widgets.dart';
import '../../services/jitsi_call_service.dart';
import '../../models/appointment_model.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/skeleton_loader.dart';
import 'chat_inbox_screen.dart';

class AppointmentScreen extends ConsumerStatefulWidget {
  const AppointmentScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _AppointmentScreenState();
}

class _AppointmentScreenState extends ConsumerState<AppointmentScreen> {
  final _searchController = TextEditingController();
  bool _showAllUpcoming = false;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: yarisaAppBar(
        context,
        title: AppStrings.appointments,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(apimethods).getAppointments();
        },
        child: _DoctorAppointmentsStream(builder: (context, appointments) {
          final query = _query.toLowerCase();
          final filteredAppointments = query.isEmpty
              ? appointments
              : appointments.where((appointment) {
                  return [
                    appointmentPatientName(appointment),
                    appointmentPurposeText(appointment),
                    appointmentTimeText(appointment),
                    appointment.status?.name,
                    appointment.doctorNote,
                  ].whereType<String>().join(' ').toLowerCase().contains(query);
                }).toList();
          final upcomingappointments = filteredAppointments.where((appoint) {
            final date = appointmentStartsAt(appoint);

            return date != null &&
                date.isAfter(DateTime.now()) &&
                _isActiveAppointmentStatus(appoint.status);
          }).toList();

          upcomingappointments.sort(compareAppointmentsByStart);
          filteredAppointments.sort(compareAppointmentsByStart);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                FormTextField(
                  controller: _searchController,
                  hint: 'Search appointments',
                  radius: 100,
                  labeled: false,
                  autoFocus: false,
                  icon: EneftyIcons.search_normal_2_outline,
                  onChanged: (value) => setState(() => _query = value.trim()),
                ),
                20.hgap,
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
                              onPressed: () {
                                setState(() {
                                  _showAllUpcoming = !_showAllUpcoming;
                                });
                              },
                              child: Text(
                                  _showAllUpcoming ? "Show Less" : "See All"))
                        ],
                      ),
                    if (upcomingappointments.isNotEmpty)
                      _showAllUpcoming
                          ? ListView.separated(
                              separatorBuilder: (context, index) => 10.hgap,
                              itemCount: upcomingappointments.length,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (BuildContext context, int index) {
                                final item = upcomingappointments[index];
                                return AppointmentItem(appointment: item);
                              },
                            )
                          : ConstrainedBox(
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
                    if (filteredAppointments.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: YarisaText(
                          text: appointments.isEmpty
                              ? "No appointments"
                              : 'No appointments match "$_query"',
                          type: TextType.bodySmall,
                          color: Colors.grey,
                          align: TextAlign.center,
                        ),
                      )
                    else ...[
                      Divider(
                        height: 40,
                        color: Colors.grey.withValues(alpha: .2),
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
                          itemCount: filteredAppointments.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            final appointment = filteredAppointments[index];
                            return InkWell(
                              onTap: () => openDoctorAppointmentDetail(
                                context,
                                appointment,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                    border: Border.all(
                                        color:
                                            Colors.grey.withValues(alpha: .2)),
                                    color: Colors.white.withValues(alpha: .1),
                                    borderRadius: BorderRadius.circular(20)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleImage(
                                          size: 50,
                                          image: appointment.patient?.photo,
                                        ),
                                        15.wgap,
                                        Expanded(
                                          child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                YarisaText(
                                                  text: appointmentPatientName(
                                                      appointment),
                                                  type: TextType.bodyBig,
                                                  spacing: 0,
                                                  weight: FontWeight.w600,
                                                ),
                                                YarisaText(
                                                  text: appointmentPurposeText(
                                                      appointment),
                                                  type: TextType.bodySmall,
                                                  // spacing: 0,
                                                ),
                                              ]),
                                        ),
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
                                      color: Colors.grey.withValues(alpha: .2),
                                    ),
                                    10.hgap,
                                    RichText(
                                      text: TextSpan(
                                          text: appointmentStartsAt(
                                                      appointment) ==
                                                  null
                                              ? "Date not set"
                                              : timeOfDay(appointmentStartsAt(
                                                  appointment)!),
                                          children: [
                                            TextSpan(
                                                text:
                                                    " -> ${appointmentTimeText(appointment)}",
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
                                    if (_hasAppointmentNote(appointment)) ...[
                                      10.hgap,
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey
                                              .withValues(alpha: .08),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: YarisaText(
                                          text: appointment.doctorNote!,
                                          type: TextType.bodySmall,
                                          lines: 3,
                                        ),
                                      ),
                                    ],
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
                                              text: (appointment.status?.name ??
                                                      AppointmentStatus
                                                          .pending.name)
                                                  .capitalize!,
                                              color: Colors.white,
                                              type: TextType.subtitle),
                                        ),
                                        GestureDetector(
                                          onTapDown: (details) async {
                                            final action =
                                                await _showAppointmentActionMenu(
                                              context,
                                              details,
                                              appointment,
                                            );
                                            if (!context.mounted ||
                                                action == null) {
                                              return;
                                            }

                                            switch (action) {
                                              case _AppointmentAction.approve:
                                                await _updateAppointmentStatus(
                                                  context,
                                                  appointment,
                                                  AppointmentStatus.approved,
                                                );
                                                break;
                                              case _AppointmentAction.decline:
                                                await _updateAppointmentStatus(
                                                  context,
                                                  appointment,
                                                  AppointmentStatus.declined,
                                                );
                                                break;
                                              case _AppointmentAction
                                                    .reschedule:
                                                await _showRescheduleSheet(
                                                    context, appointment);
                                                break;
                                              case _AppointmentAction.note:
                                                await _showAppointmentNoteSheet(
                                                    context, appointment);
                                                break;
                                              case _AppointmentAction.delete:
                                                await _deleteAppointment(
                                                    context, appointment);
                                                break;
                                            }
                                          },
                                          child: Icon(
                                            Icons.more_vert,
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.color,
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
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
      ),
    );
  }
}

bool _isActiveAppointmentStatus(AppointmentStatus? status) {
  final currentStatus = status ?? AppointmentStatus.pending;
  return currentStatus == AppointmentStatus.pending ||
      currentStatus == AppointmentStatus.approved;
}

void openDoctorAppointmentDetail(
  BuildContext context,
  AppointmentModel appointment,
) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => DoctorAppointmentDetailScreen(
        appointment: appointment,
      ),
    ),
  );
}

class DoctorAppointmentDetailScreen extends StatelessWidget {
  const DoctorAppointmentDetailScreen({
    super.key,
    required this.appointment,
  });

  final AppointmentModel appointment;

  @override
  Widget build(BuildContext context) {
    final appointmentId = appointment.id;
    if (appointmentId == null || appointmentId.isEmpty) {
      return _DoctorAppointmentDetailBody(appointment: appointment);
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirestoreSchema.appointments().doc(appointmentId).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final currentAppointment = data == null
            ? appointment
            : (AppointmentModel.fromMap(data)..id = snapshot.data?.id);
        return _DoctorAppointmentDetailBody(appointment: currentAppointment);
      },
    );
  }
}

class _DoctorAppointmentDetailBody extends StatelessWidget {
  const _DoctorAppointmentDetailBody({required this.appointment});

  final AppointmentModel appointment;

  @override
  Widget build(BuildContext context) {
    final patientId = _appointmentPatientId(appointment);
    final startAt = appointmentStartsAt(appointment);
    final status = appointment.status ?? AppointmentStatus.pending;

    return Scaffold(
      appBar: yarisaAppBar(context, title: "Appointment Details"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleImage(size: 64, image: appointment.patient?.photo),
                14.wgap,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      YarisaText(
                        text: appointmentPatientName(appointment),
                        type: TextType.bodyBig,
                        weight: FontWeight.w700,
                      ),
                      YarisaText(
                        text: appointment.patient?.email ?? "Patient",
                        type: TextType.bodySmall,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
                _AppointmentStatusPill(status: status),
              ],
            ),
            24.hgap,
            _AppointmentDetailTile(
              icon: EneftyIcons.calendar_2_outline,
              label: "Date",
              value: startAt == null
                  ? "Date not set"
                  : DateFormat.yMMMMEEEEd().format(startAt),
            ),
            _AppointmentDetailTile(
              icon: EneftyIcons.clock_2_outline,
              label: "Time",
              value: appointmentTimeText(appointment),
            ),
            _AppointmentDetailTile(
              icon: Icons.description_outlined,
              label: "Purpose",
              value: appointmentPurposeText(appointment),
            ),
            if (_hasAppointmentNote(appointment))
              _AppointmentDetailTile(
                icon: Icons.note_alt_outlined,
                label: "Doctor note",
                value: appointment.doctorNote!,
              ),
            24.hgap,
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: patientId == null
                      ? null
                      : () => _openAppointmentChat(context, appointment),
                  icon: const Icon(EneftyIcons.message_2_outline, size: 18),
                  label: const Text("Chat"),
                ),
                OutlinedButton.icon(
                  onPressed: patientId == null
                      ? null
                      : () => _startAppointmentCall(
                            context,
                            appointment,
                            "voice",
                          ),
                  icon: const Icon(EneftyIcons.call_outline, size: 18),
                  label: const Text("Voice"),
                ),
                OutlinedButton.icon(
                  onPressed: patientId == null
                      ? null
                      : () => _startAppointmentCall(
                            context,
                            appointment,
                            "video",
                          ),
                  icon: const Icon(EneftyIcons.video_outline, size: 18),
                  label: const Text("Video"),
                ),
              ],
            ),
            24.hgap,
            if (status == AppointmentStatus.pending) ...[
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _updateAppointmentStatus(
                        context,
                        appointment,
                        AppointmentStatus.approved,
                      ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text("Approve"),
                    ),
                  ),
                  10.wgap,
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateAppointmentStatus(
                        context,
                        appointment,
                        AppointmentStatus.declined,
                      ),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text("Decline"),
                    ),
                  ),
                ],
              ),
              10.hgap,
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRescheduleSheet(context, appointment),
                    icon: const Icon(EneftyIcons.calendar_search_outline),
                    label: const Text("Reschedule"),
                  ),
                ),
                10.wgap,
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showAppointmentNoteSheet(
                      context,
                      appointment,
                    ),
                    icon: const Icon(EneftyIcons.edit_2_outline),
                    label: const Text("Notes"),
                  ),
                ),
              ],
            ),
            10.hgap,
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => _deleteAppointment(context, appointment),
                icon: const Icon(EneftyIcons.trash_outline),
                label: const Text("Delete appointment"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentDetailTile extends StatelessWidget {
  const _AppointmentDetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withValues(alpha: .18)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          12.wgap,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                YarisaText(
                  text: label,
                  type: TextType.bodySmall,
                  color: Colors.grey,
                ),
                4.hgap,
                YarisaText(
                  text: value,
                  type: TextType.bodySmall,
                  weight: FontWeight.w600,
                  lines: 5,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentStatusPill extends StatelessWidget {
  const _AppointmentStatusPill({required this.status});

  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      AppointmentStatus.approved => Colors.green,
      AppointmentStatus.pending => Colors.amber.shade800,
      AppointmentStatus.canceled => Colors.red,
      AppointmentStatus.declined => Colors.pink,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(100),
      ),
      child: YarisaText(
        text: status.name.capitalize!,
        type: TextType.subtitle,
        color: Colors.white,
      ),
    );
  }
}

void _openAppointmentChat(
  BuildContext context,
  AppointmentModel appointment,
) {
  final patientId = _appointmentPatientId(appointment);
  if (patientId == null) return;
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => DoctorMessageThreadScreen(
        patientId: patientId,
        patientName: appointmentPatientName(appointment),
        patientImage: appointment.patient?.photo ?? "",
        roomId: appointment.id,
      ),
    ),
  );
}

Future<void> _startAppointmentCall(
  BuildContext context,
  AppointmentModel appointment,
  String type,
) async {
  final patientId = _appointmentPatientId(appointment);
  if (patientId == null) return;
  final doctor = FirebaseAuth.instance.currentUser;
  final joined = await YarisaJitsiCallService.join(
    room: appointment.id ?? patientId,
    type: type,
    subject: "Patient Appointment",
    displayName: doctor?.displayName ?? "Doctor",
    avatarUrl: doctor?.photoURL ?? "",
    email: doctor?.email ?? "",
  );
  if (!joined) return;

  await writeDoctorChatMessage(
    patientId: patientId,
    patientName: appointmentPatientName(appointment),
    patientImage: appointment.patient?.photo ?? "",
    message: "",
    type: "call",
    extra: {"start_time": Timestamp.now(), "type": type},
  );
}

enum _AppointmentAction { approve, decline, reschedule, note, delete }

Future<_AppointmentAction?> _showAppointmentActionMenu(
  BuildContext context,
  TapDownDetails details,
  AppointmentModel appointment,
) {
  final left = details.globalPosition.dx;
  final top = details.globalPosition.dy;
  final isPending = (appointment.status ?? AppointmentStatus.pending) ==
      AppointmentStatus.pending;
  final items = <PopupMenuEntry<_AppointmentAction>>[
    if (isPending)
      const PopupMenuItem(
        height: 40,
        value: _AppointmentAction.approve,
        child: _AppointmentMenuRow(
          icon: Icons.check_circle_outline,
          label: "Approve",
        ),
      ),
    if (isPending)
      const PopupMenuItem(
        height: 40,
        value: _AppointmentAction.decline,
        child: _AppointmentMenuRow(
          icon: Icons.cancel_outlined,
          label: "Decline",
        ),
      ),
    const PopupMenuItem(
      height: 40,
      value: _AppointmentAction.reschedule,
      child: _AppointmentMenuRow(
        icon: EneftyIcons.calendar_search_outline,
        label: "Reschedule",
      ),
    ),
    const PopupMenuItem(
      height: 40,
      value: _AppointmentAction.note,
      child: _AppointmentMenuRow(
        icon: EneftyIcons.edit_2_outline,
        label: "Notes",
      ),
    ),
    const PopupMenuItem(
      height: 40,
      value: _AppointmentAction.delete,
      child: _AppointmentMenuRow(
        icon: EneftyIcons.trash_outline,
        label: "Delete",
      ),
    ),
  ];

  return showMenu<_AppointmentAction>(
    context: context,
    position:
        RelativeRect.fromLTRB(left, top, Get.width - left, Get.height - top),
    elevation: 10,
    color: Get.isDarkMode ? Colors.grey.shade900 : Colors.white,
    surfaceTintColor: Get.isDarkMode ? Colors.grey.shade900 : Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    items: items,
  );
}

class _AppointmentMenuRow extends StatelessWidget {
  const _AppointmentMenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 10),
        Text(label),
      ],
    );
  }
}

Future<void> _updateAppointmentStatus(
  BuildContext context,
  AppointmentModel appointment,
  AppointmentStatus status,
) async {
  if (appointment.id == null) return;

  if (status == AppointmentStatus.approved) {
    final confirmed = await showYarisaConfirmationDialog(
      context,
      title: "Approve appointment?",
      message: "The patient will be notified that their booking is confirmed.",
      confirmLabel: "Approve",
      icon: Icons.check_circle_outline,
    );
    if (!confirmed) return;
  } else if (status == AppointmentStatus.declined) {
    final confirmed = await showYarisaConfirmationDialog(
      context,
      title: "Decline appointment?",
      message:
          "This will release the selected slot so another patient can book it.",
      confirmLabel: "Decline",
      icon: Icons.cancel_outlined,
      isDestructive: true,
    );
    if (!confirmed) return;
  }

  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.maybeOf(context);
  void notify(String message) {
    if (messenger != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } else {
      Get.snackbar(
        "Appointment",
        message,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  try {
    final batch = FirebaseFirestore.instance.batch();
    final appointmentRef = FirestoreSchema.appointments().doc(appointment.id);
    batch.update(appointmentRef, {
      "status": status.name,
      "updatedAt": FieldValue.serverTimestamp(),
      if (status == AppointmentStatus.approved)
        "approvedAt": FieldValue.serverTimestamp(),
      if (status == AppointmentStatus.declined)
        "declinedAt": FieldValue.serverTimestamp(),
    });
    _setPatientAppointmentRef(batch, appointment, {
      "status": status.name,
      "updatedAt": FieldValue.serverTimestamp(),
    });
    if (status == AppointmentStatus.declined) {
      await _releaseAppointmentSlotIfPresent(batch, appointment);
    }
    await batch.commit();
    notify("Appointment ${status.name}");
  } catch (e) {
    notify("Failed to update appointment: $e");
  }
}

Future<void> _showAppointmentNoteSheet(
  BuildContext context,
  AppointmentModel appointment,
) async {
  final noteCtrl = TextEditingController(text: appointment.doctorNote ?? "");
  var saving = false;

  try {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Appointment Notes",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  labelText: "Private doctor note",
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (appointment.id == null) return;
                          setSheetState(() => saving = true);
                          try {
                            await FirestoreSchema.appointments()
                                .doc(appointment.id)
                                .update({
                              "doctorNote": noteCtrl.text.trim(),
                              "doctorNotes": noteCtrl.text.trim(),
                              "notesUpdatedAt": FieldValue.serverTimestamp(),
                              "updatedAt": FieldValue.serverTimestamp(),
                            });
                            if (ctx.mounted) Navigator.pop(ctx);
                            Get.snackbar(
                              "Saved",
                              "Appointment note saved",
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          } catch (e) {
                            Get.snackbar(
                              "Error",
                              "Failed to save note: $e",
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          } finally {
                            if (ctx.mounted) {
                              setSheetState(() => saving = false);
                            }
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Save"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  } finally {
    noteCtrl.dispose();
  }
}

Future<void> _showRescheduleSheet(
  BuildContext context,
  AppointmentModel appointment,
) async {
  final doctorId =
      appointment.doctorId ?? FirebaseAuth.instance.currentUser?.uid;
  if (doctorId == null) {
    Get.snackbar(
      "Reschedule unavailable",
      "Doctor session is not available.",
      snackPosition: SnackPosition.BOTTOM,
    );
    return;
  }

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _DoctorRescheduleSheet(
      appointment: appointment,
      doctorId: doctorId,
    ),
  );
}

class _DoctorRescheduleSheet extends StatefulWidget {
  const _DoctorRescheduleSheet({
    required this.appointment,
    required this.doctorId,
  });

  final AppointmentModel appointment;
  final String doctorId;

  @override
  State<_DoctorRescheduleSheet> createState() => _DoctorRescheduleSheetState();
}

class _DoctorRescheduleSheetState extends State<_DoctorRescheduleSheet> {
  bool _loading = true;
  bool _saving = false;
  List<_AvailabilityDay> _days = const [];
  DateTime? _selectedDate;
  String? _selectedSlot;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    setState(() => _loading = true);
    try {
      final daysSnap = await FirestoreSchema.doctorDoc(widget.doctorId)
          .collection(DoctorSubcollections.availabilityDays)
          .where("status", isEqualTo: true)
          .get();

      final result = <_AvailabilityDay>[];
      for (final dayDoc in daysSnap.docs) {
        final data = dayDoc.data();
        final raw = data["date"];
        DateTime? date;
        if (raw is Timestamp) {
          date = raw.toDate();
        } else {
          final parts = dayDoc.id.split("-");
          if (parts.length == 3) {
            final y = int.tryParse(parts[0]);
            final m = int.tryParse(parts[1]);
            final d = int.tryParse(parts[2]);
            if (y != null && m != null && d != null) {
              date = DateTime(y, m, d);
            }
          }
        }
        if (date == null) continue;
        final dayOnly = DateTime(date.year, date.month, date.day);
        if (dayOnly
            .isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
          continue;
        }

        final slotsSnap =
            await dayDoc.reference.collection(DoctorSubcollections.slots).get();

        final slots = <String>[];
        for (final slotDoc in slotsSnap.docs) {
          final slotData = slotDoc.data();
          final label = slotData["label"]?.toString();
          if (label == null || label.trim().isEmpty) continue;
          final booked = slotData["booked"] == true ||
              slotData["bookedBy"] != null ||
              slotData["bookedAppointmentId"] != null;
          final available = slotData["status"] == true && !booked;
          // Allow the appointment's own current slot to remain selectable.
          final isOwnCurrent =
              slotData["bookedAppointmentId"] == widget.appointment.id;
          if (available || isOwnCurrent) slots.add(label);
        }
        if (slots.isEmpty) continue;
        slots.sort();
        result.add(_AvailabilityDay(date: dayOnly, slots: slots));
      }
      result.sort((a, b) => a.date.compareTo(b.date));

      if (!mounted) return;
      setState(() {
        _days = result;
        _loading = false;
        if (result.isNotEmpty) {
          final currentDate = widget.appointment.date?.toDate();
          final match = currentDate == null
              ? result.first
              : result.firstWhere(
                  (d) =>
                      d.date.year == currentDate.year &&
                      d.date.month == currentDate.month &&
                      d.date.day == currentDate.day,
                  orElse: () => result.first,
                );
          _selectedDate = match.date;
          _selectedSlot = match.slots.contains(widget.appointment.time)
              ? widget.appointment.time
              : null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _days = const [];
        _loading = false;
      });
      Get.snackbar(
        "Error",
        "Failed to load availability: $e",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _save() async {
    final date = _selectedDate;
    final slot = _selectedSlot;
    if (date == null || slot == null) {
      Get.snackbar(
        "Slot required",
        "Pick an available date and time slot.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await _saveAppointmentReschedule(widget.appointment, date, slot);
      if (!mounted) return;
      Navigator.pop(context);
      messenger?.showSnackBar(
        const SnackBar(content: Text("Appointment rescheduled")),
      );
    } on _AppointmentActionException catch (e) {
      if (mounted) setState(() => _saving = false);
      Get.snackbar(
        "Slot unavailable",
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      Get.snackbar(
        "Error",
        "Failed to reschedule: $e",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDay = _selectedDate == null
        ? null
        : _days.firstWhere(
            (d) =>
                d.date.year == _selectedDate!.year &&
                d.date.month == _selectedDate!.month &&
                d.date.day == _selectedDate!.day,
            orElse: () =>
                _AvailabilityDay(date: _selectedDate!, slots: const []),
          );

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Reschedule Appointment",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            "Pick a new slot from your published availability.",
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_days.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                "You don't have any open availability slots. Publish availability first, then reschedule.",
              ),
            )
          else ...[
            SizedBox(
              height: 86,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _days.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final day = _days[i];
                  final selected = _selectedDate != null &&
                      day.date.year == _selectedDate!.year &&
                      day.date.month == _selectedDate!.month &&
                      day.date.day == _selectedDate!.day;
                  final primary = Theme.of(context).primaryColor;
                  return InkWell(
                    onTap: () => setState(() {
                      _selectedDate = day.date;
                      _selectedSlot = null;
                    }),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 72,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: selected ? primary : null,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? primary
                              : Colors.grey.withValues(alpha: .25),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat.E().format(day.date),
                            style: TextStyle(
                              color: selected ? Colors.white : null,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat.d().format(day.date),
                            style: TextStyle(
                              color: selected ? Colors.white : null,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            DateFormat.MMM().format(day.date),
                            style: TextStyle(
                              color: selected ? Colors.white : null,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            if (selectedDay != null && selectedDay.slots.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedDay.slots.map((slot) {
                  final selected = _selectedSlot == slot;
                  return ChoiceChip(
                    label: Text(slot),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedSlot = slot),
                  );
                }).toList(),
              )
            else
              Text(
                "No open slots for this day.",
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Reschedule"),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AvailabilityDay {
  const _AvailabilityDay({required this.date, required this.slots});

  final DateTime date;
  final List<String> slots;
}

Future<void> _saveAppointmentReschedule(
  AppointmentModel appointment,
  DateTime selectedDate,
  String slotLabel,
) async {
  final appointmentId = appointment.id;
  final doctorId =
      appointment.doctorId ?? FirebaseAuth.instance.currentUser?.uid;
  final patientId = _appointmentPatientId(appointment);
  if (appointmentId == null || doctorId == null) return;

  final date =
      DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
  final startAt = _appointmentStartAt(date, slotLabel);
  final appointmentRef = FirestoreSchema.appointments().doc(appointmentId);
  final newSlotRef =
      FirestoreSchema.availabilitySlot(doctorId, date, slotLabel);
  final oldDate = appointment.date?.toDate();
  final oldSlot = appointment.time;
  final oldSlotRef =
      oldDate == null || oldSlot == null || oldSlot.trim().isEmpty
          ? null
          : FirestoreSchema.availabilitySlot(doctorId, oldDate, oldSlot);

  await FirebaseFirestore.instance.runTransaction((transaction) async {
    final newSlotSnapshot = await transaction.get(newSlotRef);
    final oldSlotSnapshot =
        oldSlotRef == null || oldSlotRef.path == newSlotRef.path
            ? null
            : await transaction.get(oldSlotRef);
    final newSlot = newSlotSnapshot.data();
    final bookedAppointmentId = newSlot?["bookedAppointmentId"]?.toString();
    final bookedBy = newSlot?["bookedBy"]?.toString();
    final booked = newSlot?["booked"] == true ||
        bookedAppointmentId != null ||
        bookedBy != null;

    if (booked && bookedAppointmentId != appointmentId) {
      throw const _AppointmentActionException(
        "That slot has already been booked.",
      );
    }
    if (newSlotSnapshot.exists && newSlot?["status"] == false && !booked) {
      throw const _AppointmentActionException(
        "That slot is currently closed.",
      );
    }

    if (oldSlotRef != null && oldSlotSnapshot?.exists == true) {
      transaction.set(
          oldSlotRef,
          {
            "status": true,
            "booked": false,
            "bookedBy": FieldValue.delete(),
            "bookedAppointmentId": FieldValue.delete(),
            "releasedAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));
    }

    transaction.set(
        FirestoreSchema.availabilityDay(doctorId, date),
        {
          "doctorId": doctorId,
          "date": Timestamp.fromDate(date),
          "dateKey": FirestoreSchema.dateKey(date),
          "status": true,
          "updatedAt": FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true));
    transaction.set(
        newSlotRef,
        {
          "doctorId": doctorId,
          "dateKey": FirestoreSchema.dateKey(date),
          "slotId": FirestoreSchema.slotId(slotLabel),
          "label": slotLabel,
          "status": false,
          "booked": true,
          if (patientId != null) "bookedBy": patientId,
          "bookedAppointmentId": appointmentId,
          "bookedAt": FieldValue.serverTimestamp(),
          "updatedAt": FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true));
    transaction.update(appointmentRef, {
      "date": Timestamp.fromDate(date),
      "startAt": Timestamp.fromDate(startAt),
      "dateKey": FirestoreSchema.dateKey(date),
      "slotId": FirestoreSchema.slotId(slotLabel),
      "time": slotLabel,
      "timeLabel": slotLabel,
      "updatedAt": FieldValue.serverTimestamp(),
      "rescheduledAt": FieldValue.serverTimestamp(),
    });
    if (patientId != null) {
      transaction.set(
        _patientAppointmentRef(patientId, appointmentId),
        {
          "appointmentId": appointmentId,
          "providerId": doctorId,
          "providerType": "doctor",
          "startAt": Timestamp.fromDate(startAt),
          "dateKey": FirestoreSchema.dateKey(date),
          "slotId": FirestoreSchema.slotId(slotLabel),
          "timeLabel": slotLabel,
          "updatedAt": FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
  });
}

Future<void> _deleteAppointment(
  BuildContext context,
  AppointmentModel appointment,
) async {
  final confirmed = await showYarisaConfirmationDialog(
    context,
    title: "Delete appointment?",
    message:
        "This will permanently delete the appointment with ${appointment.patient?.name ?? 'this patient'} and release the slot.",
    confirmLabel: "Delete",
    icon: EneftyIcons.trash_outline,
    isDestructive: true,
  );
  if (!confirmed || appointment.id == null) return;

  try {
    final batch = FirebaseFirestore.instance.batch();
    batch.delete(FirestoreSchema.appointments().doc(appointment.id));
    final patientId = _appointmentPatientId(appointment);
    if (patientId != null) {
      batch.delete(_patientAppointmentRef(patientId, appointment.id!));
    }
    await _releaseAppointmentSlotIfPresent(batch, appointment);
    await batch.commit();
    Get.snackbar(
      "Deleted",
      "Appointment removed",
      snackPosition: SnackPosition.BOTTOM,
    );
  } catch (e) {
    Get.snackbar(
      "Error",
      "Failed to delete: $e",
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}

void _setPatientAppointmentRef(
  WriteBatch batch,
  AppointmentModel appointment,
  Map<String, dynamic> data,
) {
  final patientId = _appointmentPatientId(appointment);
  final appointmentId = appointment.id;
  if (patientId == null || appointmentId == null) return;
  batch.set(
    _patientAppointmentRef(patientId, appointmentId),
    data,
    SetOptions(merge: true),
  );
}

Future<void> _releaseAppointmentSlotIfPresent(
  WriteBatch batch,
  AppointmentModel appointment,
) async {
  final doctorId =
      appointment.doctorId ?? FirebaseAuth.instance.currentUser?.uid;
  final date = appointment.date?.toDate();
  final slot = appointment.time;
  if (doctorId == null || date == null || slot == null || slot.trim().isEmpty) {
    return;
  }

  final slotRef = FirestoreSchema.availabilitySlot(doctorId, date, slot);
  final slotSnapshot = await slotRef.get();
  if (!slotSnapshot.exists) return;
  batch.set(
      slotRef,
      {
        "status": true,
        "booked": false,
        "bookedBy": FieldValue.delete(),
        "bookedAppointmentId": FieldValue.delete(),
        "releasedAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true));
}

DocumentReference<Map<String, dynamic>> _patientAppointmentRef(
  String patientId,
  String appointmentId,
) {
  return FirebaseFirestore.instance
      .collection("Patients")
      .doc(patientId)
      .collection("AppointmentRefs")
      .doc(appointmentId);
}

String? _appointmentPatientId(AppointmentModel appointment) {
  final value = appointment.patientId ?? appointment.patient?.id;
  if (value == null || value.trim().isEmpty || value == "null") return null;
  return value;
}

bool _hasAppointmentNote(AppointmentModel appointment) {
  final note = appointment.doctorNote?.trim();
  return note != null && note.isNotEmpty && note.toLowerCase() != "null";
}

DateTime _appointmentStartAt(DateTime date, String slotLabel) {
  final rawTime = slotLabel.split("-").first.trim();
  final match =
      RegExp(r'^(\d{1,2}):(\d{2})\s*([AaPp][Mm])?').firstMatch(rawTime);
  if (match == null) return date;

  var hour = int.tryParse(match.group(1)!);
  final minute = int.tryParse(match.group(2)!);
  if (hour == null || minute == null || minute > 59) return date;

  final meridiem = match.group(3)?.toLowerCase();
  if (meridiem == "pm" && hour < 12) {
    hour += 12;
  } else if (meridiem == "am" && hour == 12) {
    hour = 0;
  }
  if (hour > 23) return date;
  return DateTime(date.year, date.month, date.day, hour, minute);
}

class _AppointmentActionException implements Exception {
  const _AppointmentActionException(this.message);

  final String message;
}

class _DoctorAppointmentsStream extends StatelessWidget {
  const _DoctorAppointmentsStream({required this.builder});

  final Widget Function(
      BuildContext context, List<AppointmentModel> appointments) builder;

  @override
  Widget build(BuildContext context) {
    final doctorId = FirebaseAuth.instance.currentUser?.uid;
    if (doctorId == null) {
      return const _AppointmentStateMessage(
        title: "No Appointments",
        message: "Sign in again to view your bookings.",
      );
    }

    final appointmentsRef =
        FirebaseFirestore.instance.collection("Appointments");
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream:
          appointmentsRef.where("doctor_id", isEqualTo: doctorId).snapshots(),
      builder: (context, legacySnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: appointmentsRef
              .where("doctorId", isEqualTo: doctorId)
              .snapshots(),
          builder: (context, canonicalSnapshot) {
            if (legacySnapshot.connectionState == ConnectionState.waiting &&
                canonicalSnapshot.connectionState == ConnectionState.waiting) {
              return const AppointmentSkeletonList();
            }
            if (legacySnapshot.hasError || canonicalSnapshot.hasError) {
              return const _AppointmentStateMessage(
                title: "Unable to load appointments",
                message: "Please check your connection and try again.",
              );
            }

            final docs = {
              for (final doc in legacySnapshot.data?.docs ?? []) doc.id: doc,
              for (final doc in canonicalSnapshot.data?.docs ?? []) doc.id: doc,
            };
            if (docs.isEmpty) {
              return const _AppointmentStateMessage(
                title: "No Appointments",
                message: "New patient bookings will appear here.",
              );
            }

            final appointments = docs.values
                .map((doc) => AppointmentModel.fromSnapshot(doc))
                .toList();
            return builder(context, appointments);
          },
        );
      },
    );
  }
}

class _AppointmentStateMessage extends StatelessWidget {
  const _AppointmentStateMessage({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              EneftyIcons.calendar_2_outline,
              size: 42,
              color: Colors.grey.withValues(alpha: .8),
            ),
            12.hgap,
            YarisaText(
              text: title,
              type: TextType.bodyBig,
              weight: FontWeight.w600,
              align: TextAlign.center,
            ),
            6.hgap,
            YarisaText(
              text: message,
              type: TextType.bodySmall,
              color: Colors.grey,
              align: TextAlign.center,
              lines: 3,
            ),
          ],
        ),
      ),
    );
  }
}
