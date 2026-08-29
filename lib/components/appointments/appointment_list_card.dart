import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:yarisa_doctor/constants/yarisa_constants.dart';
import 'package:yarisa_doctor/constants/yarisa_enums.dart';
import 'package:yarisa_doctor/models/appointment_model.dart';
import 'package:yarisa_doctor/ui/doctor_ui.dart';

class AppointmentListCard extends StatelessWidget {
  const AppointmentListCard({
    super.key,
    required this.appointment,
    required this.onTap,
    this.onMore,
    this.compact = false,
  });

  final AppointmentModel appointment;
  final VoidCallback onTap;
  final VoidCallback? onMore;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final start = appointmentStartsAt(appointment);
    final status = appointment.status ?? AppointmentStatus.pending;

    return DoctorCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleImage(size: compact ? 44 : 50, image: appointment.patient?.photo),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointmentPatientName(appointment),
                      style: theme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      appointmentPurposeText(appointment),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.bodySmall?.copyWith(color: DoctorUi.muted),
                    ),
                  ],
                ),
              ),
              DoctorStatusPill(status: status),
              if (onMore != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  onPressed: onMore,
                  icon: const Icon(Icons.more_horiz_rounded),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: DoctorUi.fieldBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(EneftyIcons.calendar_2_outline,
                      size: 16, color: DoctorUi.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      start == null
                          ? 'Date not set'
                          : '${timeOfDay(start)} · ${appointmentTimeText(appointment)}',
                      style: theme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if ((appointment.doctorNote ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                appointment.doctorNote!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.bodySmall?.copyWith(color: DoctorUi.muted),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class AppointmentUpcomingChip extends StatelessWidget {
  const AppointmentUpcomingChip({
    super.key,
    required this.appointment,
    required this.onTap,
  });

  final AppointmentModel appointment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final start = appointmentStartsAt(appointment);

    return SizedBox(
      width: 220,
      child: DoctorCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleImage(size: 40, image: appointment.patient?.photo),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    appointmentPatientName(appointment),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              appointmentPurposeText(appointment),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.bodySmall?.copyWith(color: DoctorUi.muted),
            ),
            const SizedBox(height: 6),
            Text(
              start == null ? 'Time TBD' : timeOfDay(start),
              style: theme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: DoctorUi.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
