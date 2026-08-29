import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yarisa_doctor/api/api_methods.dart';
import 'package:yarisa_doctor/components/patients/patient_widgets.dart';
import 'package:yarisa_doctor/screens/main/patient_detail.dart';
import 'package:yarisa_doctor/ui/doctor_ui.dart';

class PatientsScreen extends ConsumerStatefulWidget {
  const PatientsScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends ConsumerState<PatientsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshPatients();
    });
  }

  Future<void> _refreshPatients() async {
    await ref.read(apimethods).getMyPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mypatients = ref.watch(apimethods).mypatients;
    final query = _query.toLowerCase();
    final filtered = query.isEmpty
        ? mypatients
        : mypatients.where((patient) {
            return [
              patient.patientName,
              patient.patientId,
              patient.status,
            ].whereType<String>().join(' ').toLowerCase().contains(query);
          }).toList();

    // Auto: back when pushed, hidden in bottom-nav (avoids hot-reload null on fields).
    final showBack = Navigator.of(context).canPop();

    return DoctorScaffold(
      title: 'Patients',
      subtitle: mypatients.isEmpty
          ? 'People who book with you'
          : '${mypatients.length} patient${mypatients.length == 1 ? '' : 's'}',
      showBack: showBack,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: DoctorSearchField(
              controller: _searchController,
              hint: 'Search by name',
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: DoctorUi.primary,
              onRefresh: _refreshPatients,
              child: filtered.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.45,
                          child: PatientsEmptyState(
                            title: mypatients.isEmpty
                                ? 'No patients yet'
                                : 'No matches',
                            message: mypatients.isEmpty
                                ? 'Patients appear here when they book an appointment or add you as their doctor.'
                                : 'No patients match "$_query".',
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final patient = filtered[index];
                        return PatientListTileCard(
                          patient: patient,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PatientDetailScreen(patient: patient),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
