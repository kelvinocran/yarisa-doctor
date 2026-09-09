import 'package:enefty_icons/enefty_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:yarisa_doctor/api/api_methods.dart';
import 'package:yarisa_doctor/components/home/home_widgets.dart';
import 'package:yarisa_doctor/constants/yarisa_constants.dart';
import 'package:yarisa_doctor/constants/yarisa_enums.dart';
import 'package:yarisa_doctor/models/personal_patients_model.dart';
import 'package:yarisa_doctor/screens/main/appointment_screen.dart';
import 'package:yarisa_doctor/screens/main/lab_requests_screen.dart';
import 'package:yarisa_doctor/screens/main/patient_detail.dart';
import 'package:yarisa_doctor/screens/main/patients_screen.dart';
import 'package:yarisa_doctor/screens/main/prescriptions_screen.dart';
import 'package:yarisa_doctor/screens/main/second_opinions_screen.dart';
import 'package:yarisa_doctor/ui/doctor_ui.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshHome();
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
    final api = ref.watch(apimethods);
    final theme = Theme.of(context).textTheme;
    final doctorName = api.userAccount?.fullname ??
        FirebaseAuth.instance.currentUser?.displayName ??
        'Doctor';
    final now = DateTime.now();
    final upcoming = api.userAppointments.where((a) {
      final date = appointmentStartsAt(a);
      final status = a.status ?? AppointmentStatus.pending;
      return date != null &&
          date.isAfter(now) &&
          (status == AppointmentStatus.pending ||
              status == AppointmentStatus.approved);
    }).length;
    final pending = api.userAppointments
        .where((a) =>
            (a.status ?? AppointmentStatus.pending) == AppointmentStatus.pending)
        .length;
    final today = api.userAppointments.where((a) {
      final date = appointmentStartsAt(a);
      return date != null && _sameDay(date, now);
    }).length;

    final isSearching = _query.trim().isNotEmpty;
    final results = isSearching
        ? api.mypatients
            .where((p) => (p.patientName ?? '')
                .toLowerCase()
                .contains(_query.toLowerCase()))
            .toList()
        : <PersonalPatientsModel>[];

    return Scaffold(
      backgroundColor: DoctorUi.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  CircleImage(size: 48, image: api.userAccount?.pic),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting(),
                          style: theme.bodySmall?.copyWith(
                            color: DoctorUi.muted,
                          ),
                        ),
                        Text(
                          doctorName,
                          style: theme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: DoctorUi.primary,
                onRefresh: _refreshHome,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  children: [
                    DoctorSearchField(
                      controller: _searchController,
                      hint: 'Search patients',
                      onChanged: (v) => setState(() => _query = v),
                    ),
                    const SizedBox(height: 18),
                    if (isSearching) ...[
                      Text(
                        results.isEmpty
                            ? 'No patients match "$_query"'
                            : '${results.length} result${results.length == 1 ? '' : 's'}',
                        style: theme.bodySmall?.copyWith(color: DoctorUi.muted),
                      ),
                      const SizedBox(height: 10),
                      ...results.map(
                        (patient) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: DoctorCard(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PatientDetailScreen(patient: patient),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                CircleImage(
                                  size: 44,
                                  image: patient.patientImage,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    patient.patientName ?? 'Patient',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      const DoctorSectionHeader(title: 'Practice summary'),
                      HomeStatGrid(
                        patients: api.mypatients.length,
                        upcoming: upcoming,
                        pending: pending,
                        today: today,
                      ),
                      const SizedBox(height: 20),
                      const HomeRecentPatients(),
                      const SizedBox(height: 20),
                      HomeRecentBookings(appointments: api.userAppointments),
                      const SizedBox(height: 20),
                      const HomeRecentSecondOpinions(),
                      const SizedBox(height: 20),
                      const DoctorSectionHeader(title: 'Shortcuts'),
                      HomeQuickActions(
                        items: [
                          HomeQuickAction(
                            title: 'Patients',
                            subtitle: 'Your patient list',
                            icon: EneftyIcons.profile_2user_bold,
                            color: Colors.purple,
                            onTap: () => Get.to(() => const PatientsScreen()),
                          ),
                          HomeQuickAction(
                            title: 'Appointments',
                            subtitle: '$upcoming upcoming',
                            icon: EneftyIcons.calendar_2_bold,
                            color: Colors.blue,
                            onTap: () =>
                                Get.to(() => const AppointmentScreen()),
                          ),
                          HomeQuickAction(
                            title: 'Prescriptions',
                            subtitle: 'Write & review',
                            icon: EneftyIcons.health_bold,
                            color: Colors.amber.shade700,
                            onTap: () =>
                                Get.to(() => const PrescriptionsScreen()),
                          ),
                          HomeQuickAction(
                            title: 'Lab requests',
                            subtitle: 'Order tests',
                            icon: EneftyIcons.bucket_bold,
                            color: Colors.green,
                            onTap: () =>
                                Get.to(() => const LabRequestsScreen()),
                          ),
                          HomeQuickAction(
                            title: 'Second opinions',
                            subtitle: 'Review requests',
                            icon: EneftyIcons.document_text_bold,
                            color: Colors.teal,
                            onTap: () =>
                                Get.to(() => const SecondOpinionsScreen()),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
