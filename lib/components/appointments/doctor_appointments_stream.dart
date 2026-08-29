import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:yarisa_doctor/models/appointment_model.dart';
import 'package:yarisa_doctor/ui/doctor_ui.dart';
import 'package:yarisa_doctor/widgets/skeleton_loader.dart';

/// Merges legacy `doctor_id`, canonical `doctorId`, and `providerId` streams.
/// If one query is denied, the others still drive the UI.
class DoctorAppointmentsStream extends StatelessWidget {
  const DoctorAppointmentsStream({super.key, required this.builder});

  final Widget Function(
    BuildContext context,
    List<AppointmentModel> appointments,
  ) builder;

  @override
  Widget build(BuildContext context) {
    final doctorId = FirebaseAuth.instance.currentUser?.uid;
    if (doctorId == null) {
      return const DoctorEmptyState(
        icon: EneftyIcons.calendar_2_outline,
        title: 'Sign in required',
        message: 'Sign in again to view your appointments.',
      );
    }

    final ref = FirebaseFirestore.instance.collection('Appointments');

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: ref.where('doctorId', isEqualTo: doctorId).snapshots(),
      builder: (context, canonical) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: ref.where('doctor_id', isEqualTo: doctorId).snapshots(),
          builder: (context, legacy) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream:
                  ref.where('providerId', isEqualTo: doctorId).snapshots(),
              builder: (context, provider) {
                final waiting = canonical.connectionState ==
                        ConnectionState.waiting &&
                    legacy.connectionState == ConnectionState.waiting &&
                    provider.connectionState == ConnectionState.waiting;
                if (waiting) {
                  return const AppointmentSkeletonList();
                }

                final allFailed = canonical.hasError &&
                    legacy.hasError &&
                    provider.hasError;
                if (allFailed) {
                  return const DoctorEmptyState(
                    icon: EneftyIcons.warning_2_outline,
                    title: 'Unable to load appointments',
                    message:
                        'Check your connection or pull to refresh. If this persists, your account may need updated permissions.',
                  );
                }

                final docs = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{
                  if (!canonical.hasError)
                    for (final d in canonical.data?.docs ?? []) d.id: d,
                  if (!legacy.hasError)
                    for (final d in legacy.data?.docs ?? []) d.id: d,
                  if (!provider.hasError)
                    for (final d in provider.data?.docs ?? []) d.id: d,
                };

                if (docs.isEmpty) {
                  return const DoctorEmptyState(
                    icon: EneftyIcons.calendar_2_outline,
                    title: 'No appointments yet',
                    message: 'New patient bookings will appear here.',
                  );
                }

                final appointments = docs.values
                    .map(AppointmentModel.fromSnapshot)
                    .toList();
                return builder(context, appointments);
              },
            );
          },
        );
      },
    );
  }
}
