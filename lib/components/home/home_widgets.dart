import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yarisa_doctor/components/patients/patient_widgets.dart';
import 'package:yarisa_doctor/constants/yarisa_constants.dart';
import 'package:yarisa_doctor/constants/yarisa_enums.dart';
import 'package:yarisa_doctor/constants/yarisa_widgets.dart';
import 'package:yarisa_doctor/models/appointment_model.dart';
import 'package:yarisa_doctor/models/personal_patients_model.dart';
import 'package:yarisa_doctor/screens/main/appointment_screen.dart';
import 'package:yarisa_doctor/screens/main/patient_detail.dart';
import 'package:yarisa_doctor/screens/main/patients_screen.dart';
import 'package:yarisa_doctor/screens/main/second_opinions_screen.dart';
import 'package:yarisa_doctor/ui/doctor_ui.dart';

class HomeStatGrid extends StatelessWidget {
  const HomeStatGrid({
    super.key,
    required this.patients,
    required this.upcoming,
    required this.pending,
    required this.today,
  });

  final int patients;
  final int upcoming;
  final int pending;
  final int today;

  @override
  Widget build(BuildContext context) {
    final items = [
      _Stat('Patients', patients, EneftyIcons.profile_2user_bold, Colors.purple),
      _Stat('Upcoming', upcoming, EneftyIcons.calendar_2_bold, Colors.blue),
      _Stat('Pending', pending, EneftyIcons.timer_2_outline, Colors.orange),
      _Stat('Today', today, EneftyIcons.calendar_tick_bold, Colors.green),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.85,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, i) {
        final s = items[i];
        return DoctorCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: s.color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(s.icon, color: s.color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${s.value}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      s.label,
                      style: TextStyle(
                        color: DoctorUi.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Stat {
  const _Stat(this.label, this.value, this.icon, this.color);
  final String label;
  final int value;
  final IconData icon;
  final Color color;
}

class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({super.key, required this.items});

  final List<HomeQuickAction> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.15,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, i) {
        final item = items[i];
        return DoctorCard(
          onTap: item.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color, size: 20),
              ),
              const Spacer(),
              Text(
                item.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: DoctorUi.muted,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class HomeQuickAction {
  const HomeQuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class HomeRecentPatients extends StatelessWidget {
  const HomeRecentPatients({super.key});

  @override
  Widget build(BuildContext context) {
    final doctorId = FirebaseAuth.instance.currentUser?.uid;
    if (doctorId == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DoctorSectionHeader(
          title: 'Recent patients',
          actionLabel: 'See all',
          onAction: () => Get.to(() => const PatientsScreen()),
        ),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('Doctors')
              .doc(doctorId)
              .collection('Patients')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const DoctorCard(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  ),
                ),
              );
            }
            if (snapshot.hasError) {
              return DoctorCard(
                child: Text(
                  'Unable to load patients right now. Pull to refresh.',
                  style: TextStyle(color: DoctorUi.muted, height: 1.35),
                ),
              );
            }

            final docs = (snapshot.data?.docs ?? []).toList()
              ..sort((a, b) {
                final aAt =
                    _ts(a.data()['createdAt'] ?? a.data()['updatedAt']);
                final bAt =
                    _ts(b.data()['createdAt'] ?? b.data()['updatedAt']);
                return bAt.compareTo(aAt);
              });
            final recent = docs.take(5).toList();
            if (recent.isEmpty) {
              return DoctorCard(
                child: Column(
                  children: [
                    Icon(
                      EneftyIcons.profile_2user_outline,
                      color: DoctorUi.muted,
                      size: 28,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No patients yet',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: DoctorUi.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Patients who book or add you as their doctor show here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: DoctorUi.muted,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: recent.map((doc) {
                final data = doc.data();
                final id = (data['patientId'] ?? doc.id).toString();
                final name =
                    (data['patientName'] ?? data['name'] ?? 'Patient')
                        .toString();
                final image = patientAvatarUrl(data) ??
                    (data['patientImage'] ?? data['photo'] ?? '').toString();
                final source = data['source']?.toString();
                final patient = PersonalPatientsModel(
                  patientId: id,
                  patientName: name,
                  patientImage: image,
                  status: data['status']?.toString() ?? 'active',
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: PatientListTileCard(
                    patient: patient,
                    subtitle: _recentSubtitle(data, source),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PatientDetailScreen(patient: patient),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  static String _recentSubtitle(Map<String, dynamic> data, String? source) {
    final added = _relative(_ts(data['createdAt'] ?? data['updatedAt']));
    final src = (source == null || source.isEmpty)
        ? null
        : source.replaceAll('_', ' ');
    if (src == null) return added;
    return '$added · $src';
  }

  static String _relative(DateTime date) {
    if (date.millisecondsSinceEpoch == 0) return 'Recently added';
    final days = DateTime.now().difference(date).inDays;
    if (days == 0) return 'Added today';
    if (days == 1) return 'Added yesterday';
    if (days < 7) return 'Added $days days ago';
    return 'Added ${date.day}/${date.month}/${date.year}';
  }

  static DateTime _ts(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}

class HomeRecentBookings extends StatelessWidget {
  const HomeRecentBookings({super.key, required this.appointments});

  final List<AppointmentModel> appointments;

  @override
  Widget build(BuildContext context) {
    final recent = appointments.toList()
      ..sort((a, b) {
        final aAt = a.createdOn?.toDate() ??
            appointmentStartsAt(a) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bAt = b.createdOn?.toDate() ??
            appointmentStartsAt(b) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bAt.compareTo(aAt);
      });
    final visible = recent.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DoctorSectionHeader(
          title: 'Recent bookings',
          actionLabel: visible.isEmpty ? null : 'See all',
          onAction: visible.isEmpty
              ? null
              : () => Get.to(() => const AppointmentScreen()),
        ),
        DoctorCard(
          padding: EdgeInsets.zero,
          child: visible.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    'New appointment bookings will show here.',
                    style: TextStyle(color: DoctorUi.muted, height: 1.35),
                  ),
                )
              : Column(
                  children: visible.map((appointment) {
                    final start = appointmentStartsAt(appointment);
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () =>
                            openDoctorAppointmentDetail(context, appointment),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 2,
                          ),
                          leading: CircleImage(
                            size: 42,
                            image: patientAvatarUrl({
                                  'photo': appointment.patient?.photo,
                                  'patientImage': appointment.patient?.photo,
                                }) ??
                                appointment.patient?.photo,
                          ),
                          title: Text(
                            appointmentPatientName(appointment),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            [
                              appointmentPurposeText(appointment),
                              if (start != null) timeOfDay(start),
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: DoctorUi.muted,
                              fontSize: 12,
                            ),
                          ),
                          trailing: DoctorStatusPill(
                            status: appointment.status ??
                                AppointmentStatus.pending,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

class HomeRecentSecondOpinions extends StatelessWidget {
  const HomeRecentSecondOpinions({super.key});

  @override
  Widget build(BuildContext context) {
    final doctorId = FirebaseAuth.instance.currentUser?.uid;
    if (doctorId == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('Doctors')
          .doc(doctorId)
          .collection('SecondOpinions')
          .snapshots(),
      builder: (context, snapshot) {
        final docs = (snapshot.data?.docs ?? []).where((doc) {
          final status =
              (doc.data()['status'] ?? '').toString().toLowerCase();
          return status != 'pending_payment';
        }).toList()
          ..sort((a, b) {
            final aPending = _isOpenStatus(a.data()['status']);
            final bPending = _isOpenStatus(b.data()['status']);
            if (aPending != bPending) return aPending ? -1 : 1;
            return _soTs(b.data()['createdAt'] ?? b.data()['updatedAt'])
                .compareTo(
              _soTs(a.data()['createdAt'] ?? a.data()['updatedAt']),
            );
          });
        final pendingCount =
            docs.where((d) => _isOpenStatus(d.data()['status'])).length;
        final visible = docs.take(4).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DoctorSectionHeader(
              title: pendingCount > 0
                  ? 'Second opinions · $pendingCount pending'
                  : 'Second opinions',
              actionLabel: 'See all',
              onAction: () => Get.to(() => const SecondOpinionsScreen()),
            ),
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData)
              const DoctorCard(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  ),
                ),
              )
            else if (snapshot.hasError)
              DoctorCard(
                child: Text(
                  'Unable to load second opinion requests.',
                  style: TextStyle(color: DoctorUi.muted, height: 1.35),
                ),
              )
            else if (visible.isEmpty)
              DoctorCard(
                onTap: () => Get.to(() => const SecondOpinionsScreen()),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        EneftyIcons.document_text_outline,
                        color: Colors.teal,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'New second opinion requests will show here.',
                        style: TextStyle(color: DoctorUi.muted, height: 1.35),
                      ),
                    ),
                  ],
                ),
              )
            else
              DoctorCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: visible.map((doc) {
                    final data = doc.data();
                    final name = (data['patientName'] ??
                            data['patient_name'] ??
                            'Patient')
                        .toString();
                    final concern = (data['concern'] ??
                            data['patientQuestion'] ??
                            '')
                        .toString();
                    final status = (data['status'] ?? 'pending').toString();
                    final urgent =
                        (data['urgency'] ?? '').toString().toLowerCase() ==
                            'urgent';
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SecondOpinionDetailScreen(
                                requestId: doc.id,
                              ),
                            ),
                          );
                        },
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 2,
                          ),
                          leading: CircleImage(
                            size: 42,
                            image: (data['patientImage'] ??
                                    data['patient_image'] ??
                                    '')
                                .toString(),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            [
                              if (urgent) 'Urgent',
                              if (concern.isNotEmpty) concern,
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: DoctorUi.muted,
                              fontSize: 12,
                            ),
                          ),
                          trailing: _SoStatusChip(status: status),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        );
      },
    );
  }

  static bool _isOpenStatus(dynamic status) {
    final value = (status ?? 'pending').toString().toLowerCase();
    return value == 'pending' ||
        value == 'in_review' ||
        value == 'in-progress' ||
        value == 'in_progress' ||
        value == 'accepted';
  }

  static DateTime _soTs(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}

class _SoStatusChip extends StatelessWidget {
  const _SoStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final value = status.toLowerCase();
    final color = switch (value) {
      'completed' => Colors.green,
      'declined' || 'canceled' || 'cancelled' => Colors.red,
      'in_review' || 'in-progress' || 'in_progress' || 'accepted' =>
        Colors.blue,
      _ => Colors.orange,
    };
    final label = status.isEmpty
        ? 'Pending'
        : '${status[0].toUpperCase()}${status.substring(1).replaceAll('_', ' ')}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}
