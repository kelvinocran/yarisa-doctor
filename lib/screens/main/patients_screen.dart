import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yarisa_doctor/api/api_methods.dart';
import 'package:yarisa_doctor/components/formtextfield.dart';
import 'package:yarisa_doctor/screens/main/patient_detail.dart';

import '../../constants/yarisa_strings.dart';
import '../../constants/yarisa_widgets.dart';

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
      if (!mounted) return;
      _refreshPatients();
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
    final filteredPatients = query.isEmpty
        ? mypatients
        : mypatients.where((patient) {
            return [
              patient.patientName,
              patient.patientId,
              patient.status,
            ].whereType<String>().join(' ').toLowerCase().contains(query);
          }).toList();
    return Scaffold(
        appBar: yarisaAppBar(
          context,
          title: AppStrings.patients,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: FormTextField(
                controller: _searchController,
                hint: 'Search patients',
                radius: 100,
                labeled: false,
                autoFocus: false,
                icon: EneftyIcons.search_normal_2_outline,
                onChanged: (value) => setState(() => _query = value.trim()),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshPatients,
                child: filteredPatients.isEmpty
                    ? ListView(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 80),
                            child: Text(
                              mypatients.isEmpty
                                  ? "No Patients"
                                  : 'No patients match "$_query"',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        separatorBuilder: (context, index) => const Divider(),
                        itemCount: filteredPatients.length,
                        padding: const EdgeInsets.all(20),
                        itemBuilder: (context, index) {
                          final patient = filteredPatients[index];
                          return ListTile(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => PatientDetailScreen(
                                          patient: patient)));
                            },
                            contentPadding: EdgeInsets.zero,
                            tileColor: Colors.transparent,
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
                          );
                        }),
              ),
            ),
          ],
        ));
  }
}
