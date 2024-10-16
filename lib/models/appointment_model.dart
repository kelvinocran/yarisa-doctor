// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentModel {
  String? appointmentTime;
  String? patientImage;
  String? patientName;
  String? patientId;
  String? id;
  Timestamp? dateCreated;
  Timestamp? appointmentDate;
  AppointmentModel({
    this.appointmentTime,
    this.patientImage,
    this.patientName,
    this.patientId,
    this.id,
    this.dateCreated,
    this.appointmentDate,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'appointment_time': appointmentTime,
      'patient_image': patientImage,
      'patient_name': patientName,
      'patient_id': patientId,
      // 'id': id,
      'date_created': dateCreated?.millisecondsSinceEpoch,
      'appointment_date': appointmentDate?.millisecondsSinceEpoch,
    };
  }

  factory AppointmentModel.fromMap(QueryDocumentSnapshot<Map<String, dynamic>> map) {
    return AppointmentModel(
      appointmentTime: map['appointment_time'] != null ? map['appointment_time'] as String : null,
      patientImage: map['patient_image'] != null ? map['patient_image'] as String : null,
      patientName: map['patient_name'] != null ? map['patient_name'] as String : null,
      patientId: map['patient_id'] != null ? map['patient_id'] as String : null,
      id: map.id,
      dateCreated: map['date_created'] != null ? Timestamp.fromMillisecondsSinceEpoch(map['date_created'] as int) : null,
      appointmentDate: map['appointmentDate'] != null ? Timestamp.fromMillisecondsSinceEpoch(map['appointment_date'] as int) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory AppointmentModel.fromJson(String source) => AppointmentModel.fromMap(json.decode(source) as QueryDocumentSnapshot<Map<String, dynamic>>);

  @override
  String toString() {
    return 'AppointmentModel(appointmentTime: $appointmentTime, patientImage: $patientImage, patientName: $patientName, patientId: $patientId, id: $id, dateCreated: $dateCreated, appointmentDate: $appointmentDate)';
  }
}
