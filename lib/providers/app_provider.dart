import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:yarisa_doctor/models/medicine_model.dart';

final meds = ValueNotifier<List<MedicineModel>>([]);

class AppProvider {
  Future<void> getMedicines() async {
    final data = await FirebaseFirestore.instance.collection("Medicine").get();

    final medicines =
        data.docs.map((e) => MedicineModel.fromFirestore(e)).toList();
    meds.value = medicines;
  }
}
