// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yarisa_doctor/models/patient_model.dart';
import 'package:yarisa_doctor/models/user_model.dart';


import '../constants/yarisa_enums.dart';

class AppointmentModel {
  String? id;
  String? purpose;
  String? type;
  UserModel? doctor;
  Patient? patient;
  Timestamp? date;
  String? time;
  Timestamp? createdOn;
  AppointmentStatus? status;
  AppointmentModel(
      {this.purpose,
      this.doctor,
      this.patient,
      this.date,
      this.time,
      this.createdOn,
      this.status,
      this.type,this.id});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'type': type,
      'purpose': purpose,
      'time': time,
      'doctor': doctor?.toMap(),
      'patient': patient?.toMap(),
      'date': date?.millisecondsSinceEpoch,
      'date_created': createdOn?.millisecondsSinceEpoch,
      'status': status?.name,
    };
  }

  factory AppointmentModel.fromSnapshot(QueryDocumentSnapshot<Map<String, dynamic>> map) {
    return AppointmentModel(
      id: map.id,
      type: map["type"],
      purpose: map['purpose'],
      time: map['time'],
      doctor: map['doctor'] != null
          ? UserModel.fromMap(map['doctor'] as Map<String, dynamic>)
          : null,
      patient: map['patient'] != null
          ? Patient.fromMap(map['patient'] as Map<String, dynamic>)
          : null,
      date: map['date'] != null
          ? map['date'] is int
              ? (Timestamp.fromMillisecondsSinceEpoch(map['date']))
              : (map['date'] as Timestamp)
          : null,
      createdOn: map['date_created'] != null
          ? map['date_created'] is int
              ? (Timestamp.fromMillisecondsSinceEpoch(map['date_created']))
              : (map['date_created'] as Timestamp)
          : null,
      status:
          AppointmentStatus.values.firstWhere((e) => e.name == map['status']),
    );
  }


  factory AppointmentModel.fromMap(Map<String, dynamic> map) {
    return AppointmentModel(
      type: map["type"],
      purpose: map['purpose'],
      time: map['time'],
      doctor: map['doctor'] != null
          ? UserModel.fromMap(map['doctor'] as Map<String, dynamic>)
          : null,
      patient: map['patient'] != null
          ? Patient.fromMap(map['patient'] as Map<String, dynamic>)
          : null,
      date: map['date'] != null
          ? map['date'] is int
              ? (Timestamp.fromMillisecondsSinceEpoch(map['date']))
              : (map['date'] as Timestamp)
          : null,
      createdOn: map['date_created'] != null
          ? map['date_created'] is int
              ? (Timestamp.fromMillisecondsSinceEpoch(map['date_created']))
              : (map['date_created'] as Timestamp)
          : null,
      status:
          AppointmentStatus.values.firstWhere((e) => e.name == map['status']),
    );
  }

  String toJson() => json.encode(toMap());

  factory AppointmentModel.fromJson(String source) =>
      AppointmentModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
