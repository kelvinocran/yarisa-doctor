import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class MedicineModel {
  String? id;
  String? unit;
  String? dosage;
  String? pic;
  String? type;
  String? medicine;
  MedicineModel({
    this.id,
    this.unit,
    this.dosage,
    this.pic,
    this.type,
    this.medicine,
  });

  MedicineModel copyWith({
    String? unit,
    String? dosage,
    String? pic,
    String? type,
    String? medicine,
  }) {
    return MedicineModel(
      unit: unit ?? this.unit,
      dosage: dosage ?? this.dosage,
      pic: pic ?? this.pic,
      type: type ?? this.type,
      medicine: medicine ?? this.medicine,
    );
  }

  @override
  String toString() {
    return 'MedicineModel(id: $id, unit: $unit, dosage: $dosage, pic: $pic, type: $type, medicine: $medicine)';
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'unit': unit,
      'dosage': dosage,
      'pic': pic,
      'type': type,
      'medicine': medicine,
    };
  }

  factory MedicineModel.fromMap(Map<String, dynamic> map) {
    return MedicineModel(
      unit: map['unit'] != null ? map['unit'] as String : null,
      dosage: map['dosage'] != null ? map['dosage'] as String : null,
      pic: map['pic'] != null ? map['pic'] as String : null,
      type: map['type'] != null ? map['type'] as String : null,
      medicine: map['medicine'] != null ? map['medicine'] as String : null,
    );
  }

  factory MedicineModel.fromFirestore(
      QueryDocumentSnapshot<Map<String, dynamic>> map) {
    return MedicineModel(
      id: map.id,
      unit: map['unit'] != null ? map['unit'] as String : null,
      dosage: map['dosage'] != null ? map['dosage'] as String : null,
      pic: map['pic'] != null ? map['pic'] as String : null,
      type: map['type'] != null ? map['type'] as String : null,
      medicine: map['medicine'] != null ? map['medicine'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory MedicineModel.fromJson(String source) =>
      MedicineModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
