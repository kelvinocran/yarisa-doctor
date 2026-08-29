import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:yarisa_doctor/components/appointments/appointment_list_card.dart';
import 'package:yarisa_doctor/components/appointments/doctor_appointments_stream.dart';
import 'package:yarisa_doctor/ui/doctor_ui.dart';

import '../../api/firestore_schema.dart';
import '../../api/api_methods.dart';
import '../../constants/yarisa_constants.dart';
import '../../constants/yarisa_enums.dart';
import '../../services/jitsi_call_service.dart';
import '../../models/appointment_model.dart';
import '../../widgets/confirmation_dialog.dart';
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

  Future<void> _runAction(
    BuildContext context,
    AppointmentModel appointment,
    _AppointmentAction action,
  ) async {
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
      case _AppointmentAction.reschedule:
        await _showRescheduleSheet(context, appointment);
        break;
      case _AppointmentAction.note:
        await _showAppointmentNoteSheet(context, appointment);
        break;
      case _AppointmentAction.delete:
        await _deleteAppointment(context, appointment);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DoctorScaffold(
      title: 'Appointments',
      subtitle: 'Review, approve, and manage bookings',
      showBack: false,
      body: RefreshIndicator(
        color: DoctorUi.primary,
        onRefresh: () async {
          await ref.read(apimethods).getAppointments();
        },
        child: DoctorAppointmentsStream(builder: (context, appointments) {
          final query = _query.toLowerCase();
          final filteredAppointments = query.isEmpty
              ? List<AppointmentModel>.from(appointments)
              : appointments.where((appointment) {
                  return [
                    appointmentPatientName(appointment),
                    appointmentPurposeText(appointment),
                    appointmentTimeText(appointment),
                    appointment.status?.name,
                    appointment.doctorNote,
                  ].whereType<String>().join(' ').toLowerCase().contains(query);
                }).toList();
          final upcomingAppointments = filteredAppointments.where((appoint) {
            final date = appointmentStartsAt(appoint);
            return date != null &&
                date.isAfter(DateTime.now()) &&
                _isActiveAppointmentStatus(appoint.status);
          }).toList();

          upcomingAppointments.sort(compareAppointmentsByStart);
          filteredAppointments.sort(compareAppointmentsByStart);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              DoctorSearchField(
                controller: _searchController,
                hint: 'Search appointments',
                onChanged: (value) => setState(() => _query = value.trim()),
              ),
              const SizedBox(height: 16),
              if (upcomingAppointments.isNotEmpty) ...[
                DoctorSectionHeader(
                  title: 'Upcoming',
                  count: upcomingAppointments.length,
                  actionLabel: _showAllUpcoming ? 'Show less' : 'See all',
                  onAction: () =>
                      setState(() => _showAllUpcoming = !_showAllUpcoming),
                ),
                if (_showAllUpcoming)
                  ...upcomingAppointments.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AppointmentListCard(
                        appointment: item,
                        onTap: () =>
                            openDoctorAppointmentDetail(context, item),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 150,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: upcomingAppointments.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final item = upcomingAppointments[index];
                        return AppointmentUpcomingChip(
                          appointment: item,
                          onTap: () =>
                              openDoctorAppointmentDetail(context, item),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
              ],
              DoctorSectionHeader(
                title: 'All appointments',
                count: filteredAppointments.length,
              ),
              if (filteredAppointments.isEmpty)
                DoctorEmptyState(
                  icon: EneftyIcons.calendar_2_outline,
                  title: appointments.isEmpty
                      ? 'No appointments'
                      : 'No matches',
                  message: appointments.isEmpty
                      ? 'New patient bookings will appear here.'
                      : 'No appointments match "$_query".',
                )
              else
                ...filteredAppointments.map(
                  (appointment) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppointmentListCard(
                      appointment: appointment,
                      onTap: () => openDoctorAppointmentDetail(
                        context,
                        appointment,
                      ),
                      onMore: () async {
                        final action = await _showAppointmentActionMenuSimple(
                          context,
                          appointment,
                        );
                        if (!context.mounted || action == null) return;
                        await _runAction(context, appointment, action);
                      },
                    ),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}

Future<_AppointmentAction?> _showAppointmentActionMenuSimple(
  BuildContext context,
  AppointmentModel appointment,
) {
  return showModalBottomSheet<_AppointmentAction>(
    context: context,
    backgroundColor: DoctorUi.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: .3),
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              if ((appointment.status ?? AppointmentStatus.pending) ==
                  AppointmentStatus.pending) ...[
                ListTile(
                  leading: const Icon(Icons.check_circle_outline,
                      color: Colors.green),
                  title: const Text('Approve'),
                  onTap: () =>
                      Navigator.pop(context, _AppointmentAction.approve),
                ),
                ListTile(
                  leading:
                      const Icon(Icons.cancel_outlined, color: Colors.pink),
                  title: const Text('Decline'),
                  onTap: () =>
                      Navigator.pop(context, _AppointmentAction.decline),
                ),
              ],
              ListTile(
                leading: const Icon(EneftyIcons.calendar_search_outline),
                title: const Text('Reschedule'),
                onTap: () =>
                    Navigator.pop(context, _AppointmentAction.reschedule),
              ),
              ListTile(
                leading: const Icon(EneftyIcons.edit_2_outline),
                title: const Text('Add note'),
                onTap: () => Navigator.pop(context, _AppointmentAction.note),
              ),
              ListTile(
                leading: Icon(EneftyIcons.trash_outline,
                    color: Colors.red.shade400),
                title: Text(
                  'Delete',
                  style: TextStyle(color: Colors.red.shade400),
                ),
                onTap: () => Navigator.pop(context, _AppointmentAction.delete),
              ),
            ],
          ),
        ),
      );
    },
  );
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
    final statusColor = DoctorUi.statusColor(status);
    final patientName = appointmentPatientName(appointment);
    final purpose = appointmentPurposeText(appointment);
    final timeLabel = appointmentTimeText(appointment);
    final isPending = status == AppointmentStatus.pending;
    final isActive = status != AppointmentStatus.canceled &&
        status != AppointmentStatus.declined;
    final email = appointment.patient?.email?.trim() ?? '';
    final note = (appointment.doctorNote ?? '').trim();

    return Scaffold(
      backgroundColor: DoctorUi.scaffoldBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: DoctorUi.scaffoldBg,
        surfaceTintColor: DoctorUi.scaffoldBg,
        centerTitle: false,
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Get.back();
            }
          },
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appointment',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            SizedBox(height: 2),
            Text(
              'Visit details & actions',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isPending
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _updateAppointmentStatus(
                          context,
                          appointment,
                          AppointmentStatus.declined,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(
                            color: Colors.red.withValues(alpha: .4),
                          ),
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Decline',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: () => _updateAppointmentStatus(
                          context,
                          appointment,
                          AppointmentStatus.approved,
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Approve visit',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          // ── Patient hero ─────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  DoctorUi.primary,
                  DoctorUi.primary.withValues(alpha: .78),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: DoctorUi.primary.withValues(alpha: .28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                      child: CircleImage(
                        size: 68,
                        image: appointment.patient?.photo,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patientName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              height: 1.15,
                            ),
                          ),
                          if (email.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: .85),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .18),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .25),
                      ),
                    ),
                    child: Text(
                      (status.name).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: .6,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Schedule highlight ───────────────────────────────────
          DoctorCard(
            padding: EdgeInsets.zero,
            child: Row(
              children: [
                Container(
                  width: 88,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: .12),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        startAt == null
                            ? '—'
                            : DateFormat.MMM().format(startAt).toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: .4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        startAt == null
                            ? '—'
                            : DateFormat.d().format(startAt),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 32,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        startAt == null
                            ? ''
                            : DateFormat.E().format(startAt),
                        style: TextStyle(
                          color: statusColor.withValues(alpha: .85),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          startAt == null
                              ? 'Date not set'
                              : DateFormat.yMMMMEEEEd().format(startAt),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: DoctorUi.primary.withValues(alpha: .1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                EneftyIcons.clock_2_outline,
                                size: 16,
                                color: DoctorUi.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                timeLabel,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: DoctorUi.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if ((appointment.type ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            appointment.type!,
                            style: TextStyle(
                              color: DoctorUi.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Purpose & notes ──────────────────────────────────────
          const DoctorSectionHeader(title: 'Visit info'),
          DoctorCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailInfoRow(
                  icon: EneftyIcons.note_2_outline,
                  label: 'Purpose',
                  value: purpose,
                ),
                if (note.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: DoctorUi.border),
                  ),
                  _DetailInfoRow(
                    icon: EneftyIcons.edit_2_outline,
                    label: 'Your note',
                    value: note,
                  ),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: DoctorUi.border),
                  ),
                  Text(
                    'No clinical note yet',
                    style: TextStyle(
                      color: DoctorUi.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () =>
                          _showAppointmentNoteSheet(context, appointment),
                      icon: const Icon(EneftyIcons.edit_2_outline, size: 16),
                      label: const Text('Add note'),
                      style: TextButton.styleFrom(
                        foregroundColor: DoctorUi.primary,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ── Contact ──────────────────────────────────────────────
          const DoctorSectionHeader(title: 'Contact patient'),
          Row(
            children: [
              Expanded(
                child: _ContactTile(
                  icon: EneftyIcons.message_2_bold,
                  label: 'Chat',
                  color: Colors.red.shade400,
                  enabled: patientId != null,
                  onTap: () => _openAppointmentChat(context, appointment),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ContactTile(
                  icon: EneftyIcons.call_bold,
                  label: 'Voice',
                  color: Colors.blue,
                  enabled: patientId != null,
                  onTap: () =>
                      _startAppointmentCall(context, appointment, 'voice'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ContactTile(
                  icon: EneftyIcons.video_bold,
                  label: 'Video',
                  color: Colors.purple,
                  enabled: patientId != null,
                  onTap: () =>
                      _startAppointmentCall(context, appointment, 'video'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ── Manage ───────────────────────────────────────────────
          if (isActive) ...[
            const DoctorSectionHeader(title: 'Manage'),
            DoctorCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _ManageTile(
                    icon: EneftyIcons.calendar_search_outline,
                    title: 'Reschedule',
                    subtitle: 'Move to another open slot',
                    onTap: () => _showRescheduleSheet(context, appointment),
                  ),
                  Divider(height: 1, color: DoctorUi.border),
                  _ManageTile(
                    icon: EneftyIcons.edit_2_outline,
                    title: 'Clinical notes',
                    subtitle: note.isEmpty
                        ? 'Add notes for this visit'
                        : 'Update your notes',
                    onTap: () =>
                        _showAppointmentNoteSheet(context, appointment),
                  ),
                  Divider(height: 1, color: DoctorUi.border),
                  _ManageTile(
                    icon: EneftyIcons.trash_outline,
                    title: 'Cancel appointment',
                    subtitle: 'Release the slot and notify patient',
                    isDestructive: true,
                    onTap: () => _deleteAppointment(context, appointment),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailInfoRow extends StatelessWidget {
  const _DetailInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: DoctorUi.primary.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: DoctorUi.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: DoctorUi.muted,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : .45,
      child: DoctorCard(
        onTap: enabled ? onTap : null,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManageTile extends StatelessWidget {
  const _ManageTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red : DoctorUi.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: isDestructive ? Colors.red : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: DoctorUi.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDestructive ? Colors.red.shade300 : DoctorUi.muted,
              ),
            ],
          ),
        ),
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
  final appointmentId = appointment.id;
  final room = (appointmentId != null && appointmentId.isNotEmpty)
      ? YarisaJitsiCallService.appointmentRoom(appointmentId)
      : YarisaJitsiCallService.conversationRoom(
          doctor?.uid ?? "",
          patientId,
        );
  final joined = await YarisaJitsiCallService.join(
    room: room,
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
    final doctorId =
        appointment.doctorId ?? FirebaseAuth.instance.currentUser?.uid;
    final patientId = _appointmentPatientId(appointment);
    batch.update(appointmentRef, {
      "status": status.name,
      "updatedAt": FieldValue.serverTimestamp(),
      if (status == AppointmentStatus.approved)
        "approvedAt": FieldValue.serverTimestamp(),
      if (status == AppointmentStatus.declined)
        "declinedAt": FieldValue.serverTimestamp(),
    });
    _setPatientAppointmentRef(batch, appointment, {
      "appointmentId": appointment.id,
      if (patientId != null) "patientId": patientId,
      if (doctorId != null) "doctorId": doctorId,
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
    // Rules only allow admin hard-delete — cancel via status update instead.
    final batch = FirebaseFirestore.instance.batch();
    final doctorId =
        appointment.doctorId ?? FirebaseAuth.instance.currentUser?.uid;
    final patientId = _appointmentPatientId(appointment);
    batch.set(
      FirestoreSchema.appointments().doc(appointment.id),
      {
        "status": AppointmentStatus.canceled.name,
        "canceledAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    if (patientId != null) {
      batch.set(
        _patientAppointmentRef(patientId, appointment.id!),
        {
          "appointmentId": appointment.id,
          "patientId": patientId,
          if (doctorId != null) "doctorId": doctorId,
          "status": AppointmentStatus.canceled.name,
          "updatedAt": FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    await _releaseAppointmentSlotIfPresent(batch, appointment);
    await batch.commit();
    Get.snackbar(
      "Cancelled",
      "Appointment cancelled and slot released",
      snackPosition: SnackPosition.BOTTOM,
    );
  } catch (e) {
    Get.snackbar(
      "Error",
      "Failed to cancel: $e",
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
