import 'package:cached_network_image/cached_network_image.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yarisa_doctor/api/api_methods.dart';
import 'package:yarisa_doctor/screens/main/patient_detail.dart';

import '../../constants/yarisa_strings.dart';
import '../../constants/yarisa_widgets.dart';

class PatientsScreen extends ConsumerStatefulWidget {
  const PatientsScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends ConsumerState<PatientsScreen> {
  @override
  Widget build(BuildContext context) {
    final mypatients = ref.watch(apimethods).mypatients;
    return Scaffold(
        appBar: yarisaAppBar(
          context,
          title: AppStrings.patients,
        ),
        body: mypatients.isEmpty
            ? const Center(child: Text("No Patients"))
            : ListView.separated(
                separatorBuilder: (context, index) => const Divider(),
                itemCount: mypatients.length,
                shrinkWrap: true,
                padding: const EdgeInsets.all(20),
                itemBuilder: (context, index) {
                  final patient = mypatients[index];
                  return ListTile(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context)=> PatientDetailScreen(
                        patient: patient
                      )));
                    },
                    contentPadding: EdgeInsets.zero,
                    tileColor: Colors.transparent,
                    leading: CircleAvatar(
                      backgroundImage: patient.patientImage != null ||
                              patient.patientImage != ""
                          ? CachedNetworkImageProvider(
                              "${patient.patientImage}")
                          : null,
                      child: const Icon(EneftyIcons.profile_bold),
                    ),
                    title: Text("${patient.patientName}"),
                    trailing: const Icon(Icons.navigate_next_rounded),
                  );
                }));
  }
}
