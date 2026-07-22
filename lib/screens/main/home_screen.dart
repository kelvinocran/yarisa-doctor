import 'package:enefty_icons/enefty_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import 'package:responsive_grid_list/responsive_grid_list.dart';
import 'package:yarisa_doctor/api/api_methods.dart';
import 'package:yarisa_doctor/components/formtextfield.dart';

import 'package:yarisa_doctor/extensions/yarisa_extensions.dart';
import 'package:yarisa_doctor/screens/main/appointment_screen.dart';
import 'package:yarisa_doctor/screens/main/lab_requests_screen.dart';
import 'package:yarisa_doctor/screens/main/patient_detail.dart';
import 'package:yarisa_doctor/screens/main/patients_screen.dart';
import 'package:yarisa_doctor/screens/main/prescriptions_screen.dart';
import 'package:yarisa_doctor/screens/main/second_opinions_screen.dart';

import '../../constants/yarisa_constants.dart';
import '../../constants/yarisa_enums.dart';
import '../../constants/yarisa_strings.dart';
import '../../constants/yarisa_widgets.dart';
import '../../models/appointment_model.dart';
import '../../models/personal_patients_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshHome();
    });
  }

  Future<void> _refreshHome() async {
    await Future.wait([
      ref.read(apimethods).getMyPatients(),
      ref.read(apimethods).getAppointments(),
    ]);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(apimethods);
    final isSearching = _query.trim().isNotEmpty;
    final doctorName = user.userAccount?.fullname ??
        FirebaseAuth.instance.currentUser?.displayName ??
        'Doctor';
    final now = DateTime.now();
    final upcomingAppointmentCount = user.userAppointments.where((appoint) {
      final date = appointmentStartsAt(appoint);
      final status = appoint.status ?? AppointmentStatus.pending;
      return date != null &&
          date.isAfter(now) &&
          (status == AppointmentStatus.pending ||
              status == AppointmentStatus.approved);
    }).length;
    final pendingAppointmentCount = user.userAppointments
        .where((appoint) =>
            (appoint.status ?? AppointmentStatus.pending) ==
            AppointmentStatus.pending)
        .length;
    final todaysAppointmentCount = user.userAppointments.where((appoint) {
      final date = appointmentStartsAt(appoint);
      return date != null && _sameDay(date, now);
    }).length;
    final dashboardItems = <Map<String, dynamic>>[
      {
        "title": "My Patients",
        "description": _countDescription(
          user.mypatients.length,
          singular: 'patient',
          plural: 'patients',
          empty: 'No patients yet',
          prefix: 'You currently have',
        ),
        "icon": EneftyIcons.profile_2user_bold,
        "color": Colors.purple.shade300,
        'slug': 'patients'
      },
      {
        "title": "Appointments",
        "description": _countDescription(
          upcomingAppointmentCount,
          singular: 'upcoming appointment',
          plural: 'upcoming appointments',
          empty: 'No upcoming appointments',
          prefix: 'You have',
        ),
        "icon": EneftyIcons.calendar_2_bold,
        "color": Colors.blue.shade300,
        'slug': 'appointments'
      },
      {
        "title": "Prescriptions",
        "description": "Find all prescriptions here.",
        "icon": EneftyIcons.health_bold,
        "color": Colors.amber.shade300,
        'slug': 'prescriptions'
      },
      {
        "title": "Lab Requests",
        "description": "Create and review lab requests.",
        "icon": EneftyIcons.bucket_bold,
        "color": Colors.green.shade300,
        'slug': 'labs'
      },
      {
        "title": "Second Opinions",
        "description": "Review patient requests and respond.",
        "icon": EneftyIcons.document_text_bold,
        "color": Colors.teal.shade300,
        'slug': 'second-opinions'
      }
    ];
    final results = isSearching
        ? user.mypatients
            .where((p) => (p.patientName ?? '')
                .toLowerCase()
                .contains(_query.toLowerCase()))
            .toList()
        : const [];
    return Scaffold(
      body: Column(
        children: [
          yarisaAppBar(context,
              autoShowBackButton: false,
              title: AppStrings.home,
              titleWidget: Row(
                children: [
                  CircleAvatar(
                    backgroundImage:
                        safeCachedNetworkImageProvider(user.userAccount?.pic),
                    child:
                        safeCachedNetworkImageProvider(user.userAccount?.pic) ==
                                null
                            ? const Icon(EneftyIcons.profile_bold)
                            : null,
                  ),
                  15.wgap,
                  Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        YarisaText(
                          text: greeting(),
                          type: TextType.bodySmall,
                          color: Colors.grey,
                        ),
                        YarisaText(
                          text: doctorName,
                          type: TextType.bodyBig,
                          weight: FontWeight.w600,
                        ),
                      ]),
                ],
              )),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshHome,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FormTextField(
                      controller: _searchController,
                      hint: "Search patients",
                      radius: 100,
                      labeled: false,
                      autoFocus: false,
                      iconSize: 20,
                      icon: EneftyIcons.search_normal_2_outline,
                      onChanged: (value) {
                        setState(() {
                          _query = value;
                        });
                      },
                    ),
                    20.hgap,
                    if (isSearching) ...[
                      YarisaText(
                        text: results.isEmpty
                            ? "No patients match \"$_query\""
                            : "${results.length} result${results.length == 1 ? '' : 's'}",
                        type: TextType.bodySmall,
                        color: Colors.grey,
                      ),
                      10.hgap,
                      ...results.map((patient) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundImage: safeCachedNetworkImageProvider(
                                  patient.patientImage),
                              child: safeCachedNetworkImageProvider(
                                          patient.patientImage) ==
                                      null
                                  ? const Icon(EneftyIcons.profile_bold)
                                  : null,
                            ),
                            title: Text("${patient.patientName}"),
                            trailing: const Icon(Icons.navigate_next_rounded),
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => PatientDetailScreen(
                                            patient: patient,
                                          )));
                            },
                          )),
                    ] else ...[
                      _DoctorStatsSection(
                        totalPatients: user.mypatients.length,
                        upcomingAppointments: upcomingAppointmentCount,
                        pendingAppointments: pendingAppointmentCount,
                        todaysAppointments: todaysAppointmentCount,
                      ),
                      20.hgap,
                      const UpcomingAppointments(),
                      20.hgap,
                      const _RecentPatientsSection(),
                      20.hgap,
                      _RecentAppointmentsSection(
                        appointments: user.userAppointments,
                      ),
                      20.hgap,
                      ResponsiveGridList(
                          horizontalGridSpacing: 10,
                          verticalGridSpacing: 10,
                          minItemWidth: MediaQuery.of(context).size.width / 2,
                          minItemsPerRow: 2,
                          maxItemsPerRow: 4,
                          listViewBuilderOptions: ListViewBuilderOptions(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              padding: EdgeInsets.zero),
                          children: List.generate(
                            dashboardItems.length,
                            (index) =>
                                HomeDashboardItem(data: dashboardItems[index]),
                          ))
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _countDescription(
  int count, {
  required String singular,
  required String plural,
  required String empty,
  required String prefix,
}) {
  if (count == 0) return empty;
  return '$prefix $count ${count == 1 ? singular : plural}';
}

class _DoctorStatsSection extends StatelessWidget {
  const _DoctorStatsSection({
    required this.totalPatients,
    required this.upcomingAppointments,
    required this.pendingAppointments,
    required this.todaysAppointments,
  });

  final int totalPatients;
  final int upcomingAppointments;
  final int pendingAppointments;
  final int todaysAppointments;

  @override
  Widget build(BuildContext context) {
    final stats = [
      _HomeStat(
        label: 'Patients',
        value: totalPatients.toString(),
        icon: EneftyIcons.profile_2user_bold,
        color: Colors.purple,
      ),
      _HomeStat(
        label: 'Upcoming',
        value: upcomingAppointments.toString(),
        icon: EneftyIcons.calendar_2_bold,
        color: Colors.blue,
      ),
      _HomeStat(
        label: 'Pending',
        value: pendingAppointments.toString(),
        icon: EneftyIcons.timer_2_outline,
        color: Colors.orange,
      ),
      _HomeStat(
        label: 'Today',
        value: todaysAppointments.toString(),
        icon: EneftyIcons.calendar_tick_bold,
        color: Colors.green,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const YarisaText(
          text: 'Practice Summary',
          type: TextType.bodyBig,
          spacing: 0,
          weight: FontWeight.w600,
        ),
        10.hgap,
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stats.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.95,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) => _HomeStatTile(stat: stats[index]),
        ),
      ],
    );
  }
}

class _HomeStat {
  const _HomeStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _HomeStatTile extends StatelessWidget {
  const _HomeStatTile({required this.stat});

  final _HomeStat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: stat.color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: stat.color.withValues(alpha: .16)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: stat.color.withValues(alpha: .16),
            child: Icon(stat.icon, color: stat.color, size: 18),
          ),
          10.wgap,
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                YarisaText(
                  text: stat.value,
                  type: TextType.bodyBig,
                  spacing: 0,
                  weight: FontWeight.w700,
                  size: 20,
                ),
                YarisaText(
                  text: stat.label,
                  type: TextType.subtitle,
                  color: Colors.grey,
                  lines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentPatientsSection extends StatelessWidget {
  const _RecentPatientsSection();

  @override
  Widget build(BuildContext context) {
    final doctorId = FirebaseAuth.instance.currentUser?.uid;
    if (doctorId == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('Doctors')
          .doc(doctorId)
          .collection('Patients')
          .snapshots(),
      builder: (context, snapshot) {
        final patients = (snapshot.data?.docs ?? [])
            .map((doc) => _RecentPatient.fromDocument(doc))
            .toList()
          ..sort((first, second) => second.addedAt.compareTo(first.addedAt));
        final recentPatients = patients.take(4).toList();

        return _HomeSection(
          title: 'Recently Added Patients',
          actionLabel: recentPatients.isEmpty ? null : 'See All',
          onAction: recentPatients.isEmpty
              ? null
              : () => Get.to(() => const PatientsScreen()),
          child: snapshot.connectionState == ConnectionState.waiting
              ? const _HomeSectionLoading()
              : recentPatients.isEmpty
                  ? const _HomeEmptyMessage(
                      icon: EneftyIcons.profile_2user_bold,
                      title: 'No recent patients',
                      message:
                          'Patients who add you as their doctor will show here.',
                    )
                  : Column(
                      children: recentPatients
                          .map(
                              (patient) => _RecentPatientTile(patient: patient))
                          .toList(),
                    ),
        );
      },
    );
  }
}

class _RecentPatient {
  const _RecentPatient({
    required this.id,
    required this.name,
    required this.image,
    required this.status,
    required this.source,
    required this.addedAt,
  });

  final String id;
  final String name;
  final String image;
  final String status;
  final String source;
  final DateTime addedAt;

  factory _RecentPatient.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return _RecentPatient(
      id: _stringValue(data['patientId'] ?? document.id, document.id),
      name: _stringValue(data['patientName'] ?? data['name'], 'Patient'),
      image: _stringValue(data['patientImage'] ?? data['photo'], ''),
      status: _stringValue(data['status'], 'active'),
      source: _stringValue(data['source'], 'patient'),
      addedAt: _dateValue(data['createdAt'] ?? data['updatedAt']),
    );
  }

  PersonalPatientsModel toPatientModel() {
    return PersonalPatientsModel(
      patientId: id,
      patientName: name,
      patientImage: image,
      status: status,
    );
  }
}

class _RecentPatientTile extends StatelessWidget {
  const _RecentPatientTile({required this.patient});

  final _RecentPatient patient;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundImage: safeCachedNetworkImageProvider(patient.image),
        child: safeCachedNetworkImageProvider(patient.image) == null
            ? const Icon(EneftyIcons.profile_bold)
            : null,
      ),
      title: Text(patient.name),
      subtitle: Text(
        [_formatRelativeDate(patient.addedAt), patient.source]
            .where((value) => value.trim().isNotEmpty)
            .join(' - '),
      ),
      trailing: const Icon(Icons.navigate_next_rounded),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PatientDetailScreen(
              patient: patient.toPatientModel(),
            ),
          ),
        );
      },
    );
  }
}

class _RecentAppointmentsSection extends StatelessWidget {
  const _RecentAppointmentsSection({required this.appointments});

  final List<AppointmentModel> appointments;

  @override
  Widget build(BuildContext context) {
    final recentAppointments = appointments.toList()
      ..sort((first, second) =>
          _appointmentSortDate(second).compareTo(_appointmentSortDate(first)));
    final visibleAppointments = recentAppointments.take(4).toList();

    return _HomeSection(
      title: 'Recent Bookings',
      actionLabel: visibleAppointments.isEmpty ? null : 'See All',
      onAction: visibleAppointments.isEmpty
          ? null
          : () => Get.to(() => const AppointmentScreen()),
      child: visibleAppointments.isEmpty
          ? const _HomeEmptyMessage(
              icon: EneftyIcons.calendar_2_bold,
              title: 'No recent bookings',
              message: 'New appointment bookings will show here.',
            )
          : Column(
              children: visibleAppointments
                  .map((appointment) =>
                      _RecentAppointmentTile(appointment: appointment))
                  .toList(),
            ),
    );
  }
}

class _RecentAppointmentTile extends StatelessWidget {
  const _RecentAppointmentTile({required this.appointment});

  final AppointmentModel appointment;

  @override
  Widget build(BuildContext context) {
    final startAt = appointmentStartsAt(appointment);
    final status = appointment.status ?? AppointmentStatus.pending;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleImage(size: 44, image: appointment.patient?.photo),
      title: Text(appointmentPatientName(appointment)),
      subtitle: Text(
        [
          appointmentPurposeText(appointment),
          startAt == null ? 'Date pending' : timeOfDay(startAt),
        ].join(' - '),
      ),
      trailing: _CompactStatus(label: status.name),
      onTap: () => openDoctorAppointmentDetail(context, appointment),
    );
  }
}

class _HomeSection extends StatelessWidget {
  const _HomeSection({
    required this.title,
    required this.child,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            YarisaText(
              text: title,
              type: TextType.bodyBig,
              spacing: 0,
              weight: FontWeight.w600,
            ),
            if (actionLabel != null)
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ),
        8.hgap,
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.withValues(alpha: .16)),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _HomeSectionLoading extends StatelessWidget {
  const _HomeSectionLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}

class _HomeEmptyMessage extends StatelessWidget {
  const _HomeEmptyMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          Icon(icon, color: Colors.grey, size: 32),
          8.hgap,
          YarisaText(
            text: title,
            type: TextType.bodySmall,
            weight: FontWeight.w600,
            align: TextAlign.center,
          ),
          4.hgap,
          YarisaText(
            text: message,
            type: TextType.subtitle,
            color: Colors.grey,
            lines: 2,
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CompactStatus extends StatelessWidget {
  const _CompactStatus({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: YarisaText(
        text: label.capitalize ?? label,
        type: TextType.subtitle,
        lines: 1,
      ),
    );
  }
}

bool _sameDay(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

DateTime _appointmentSortDate(AppointmentModel appointment) {
  return appointment.createdOn?.toDate() ??
      appointmentStartsAt(appointment) ??
      DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime _dateValue(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return DateTime.fromMillisecondsSinceEpoch(0);
}

String _formatRelativeDate(DateTime date) {
  if (date.millisecondsSinceEpoch == 0) return 'Recently added';
  final difference = DateTime.now().difference(date);
  if (difference.inDays == 0) return 'Added today';
  if (difference.inDays == 1) return 'Added yesterday';
  if (difference.inDays < 7) return 'Added ${difference.inDays} days ago';
  return 'Added ${date.day}/${date.month}/${date.year}';
}

String _stringValue(dynamic value, String fallback) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text.toLowerCase() == 'null') {
    return fallback;
  }
  return text;
}

class HomeDashboardItem extends StatelessWidget {
  const HomeDashboardItem({
    super.key,
    required this.data,
  });

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        switch (data['slug']) {
          case 'patients':
            Get.to(() => const PatientsScreen());
            break;
          case 'labs':
            Get.to(() => const LabRequestsScreen());
            break;
          case 'prescriptions':
            Get.to(() => const PrescriptionsScreen());
            break;
          case 'appointments':
            Get.to(() => const AppointmentScreen());
            break;
          case 'second-opinions':
            Get.to(() => const SecondOpinionsScreen());
            break;
        }
      },
      splashColor: data['color'].withValues(alpha: .2),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        height: 200,
        decoration: BoxDecoration(
            color: data['color'].withValues(alpha: .1),
            borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
                radius: 24,
                backgroundColor: data['color'].withValues(alpha: .2),
                child: Icon(
                  data['icon'],
                  color: data['color'],
                )),
            10.hgap,
            YarisaText(
              text: data['title'],
              type: TextType.bodyBig,
              spacing: 0,
              size: 18,
              weight: FontWeight.w600,
            ),
            5.hgap,
            YarisaText(
              lines: 3,
              text: data['description'],
              type: TextType.subtitle,
            ),
          ],
        ),
      ),
    );
  }
}
