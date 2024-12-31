// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swipe_to_action/swipe_to_action.dart';

import 'package:yarisa_doctor/components/formtextfield.dart';
import 'package:yarisa_doctor/models/medicine_model.dart';

class AddPrescription extends ConsumerStatefulWidget {
  const AddPrescription({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _AddPrescriptionState();
}

class _AddPrescriptionState extends ConsumerState<AddPrescription> {
  List<PrescriptionItem> prescriptions = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> medicines = [];

  @override
  void initState() {
    super.initState();
    getMedicines();
  }

  getMedicines() async {
    final data = await FirebaseFirestore.instance.collection("Medicine").get();
    medicines = data.docs;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            prescriptions.add(PrescriptionItem(
                controller: TextEditingController(), medicine: {}));
            setState(() {});
          },
          child: const Icon(Icons.add),
        ),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          actions: [
            TextButton(
                onPressed: prescriptions.isEmpty
                    ? null
                    : () {
                        Navigator.pop(context, prescriptions);
                      },
                child: const Text("Save"))
          ],
          title: Text(
            "Add Drug Prescription",
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        body: SafeArea(
            child: SingleChildScrollView(
          child: Column(
            children: [
              if (prescriptions.isNotEmpty)
                Center(
                  child: Text(
                    "Swipe left to delete",
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontSize: 11),
                  ),
                ),
              const SizedBox(
                height: 10,
              ),
              ListView.builder(
                itemCount: prescriptions.length,
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  final data = prescriptions[index];
                  return Swipeable(
                    key: ValueKey(data),
                    onSwipe: (direction) {
                      if (direction == SwipeDirection.endToStart) {
                        prescriptions.remove(data);
                        setState(() {});
                      }
                    },
                    child: ExpansionTile(
                      backgroundColor: Colors.transparent,
                      childrenPadding: const EdgeInsets.all(15),
                      title: Text("Prescription #${index + 1}"),
                      subtitle: data.medicine['medicine'] != null
                          ? Text(
                              data.medicine['medicine'],
                              style: Theme.of(context).textTheme.bodySmall,
                            )
                          : null,
                      children: [
                        ListTile(
                          title: Text(
                              data.medicine['medicine'] ?? "Select a medicine"),
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              scrollControlDisabledMaxHeightRatio: .9,
                              builder: (context) {
                                return Container(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    children: [
                                      AppBar(
                                        backgroundColor: Colors.transparent,
                                      ),
                                      Expanded(
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: medicines.length,
                                          itemBuilder: (context, indx) {
                                            final medicine = medicines[indx];
                                            return ListTile(
                                              onTap: () {
                                                prescriptions[index] =
                                                    data.copyWith(
                                                        medicine:
                                                            medicine.data());
                                                setState(() {});

                                                Navigator.pop(context);
                                              },
                                              tileColor: Colors.transparent,
                                              trailing: const Icon(
                                                Icons.navigate_next_rounded,
                                                size: 20,
                                              ),
                                              title: Text(medicine['medicine']),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        FormTextField(
                            controller: data.controller, hint: "Instuctions")
                      ],
                    ),
                  );
                },
              )
            ],
          ),
        )));
  }
}

class PrescriptionItem {
  final TextEditingController controller;
  Map<String, dynamic> medicine;
  PrescriptionItem({
    required this.controller,
    required this.medicine,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'controller': controller.text.trim(),
      'medicine': medicine,
    };
  }

  String toJson() => json.encode(toMap());

  PrescriptionItem copyWith({
    TextEditingController? controller,
    Map<String, dynamic>? medicine,
  }) {
    return PrescriptionItem(
      controller: controller ?? this.controller,
      medicine: medicine ?? this.medicine,
    );
  }
}

class Prescription {
  String? controller;
  MedicineModel? medicine;
  Prescription({
    this.controller,
    this.medicine,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'controller': controller,
      'medicine': medicine,
    };
  }

  String toJson() => json.encode(toMap());

  Prescription copyWith({
    String? controller,
    MedicineModel? medicine,
  }) {
    return Prescription(
      controller: controller ?? this.controller,
      medicine: medicine ?? this.medicine,
    );
  }

  factory Prescription.fromMap(Map<String, dynamic> map) {
    return Prescription(
      controller:
          map['controller'] != null ? map['controller'] as String : null,
      medicine: map['medicine'] != null
          ? MedicineModel.fromMap(map['medicine'] as Map<String, dynamic>)
          : null,
    );
  }

  factory Prescription.fromJson(String source) =>
      Prescription.fromMap(json.decode(source) as Map<String, dynamic>);
}
