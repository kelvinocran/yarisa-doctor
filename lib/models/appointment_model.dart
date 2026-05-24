// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yarisa_doctor/models/patient_model.dart';
import 'package:yarisa_doctor/models/user_model.dart';

import '../constants/yarisa_enums.dart';

class AppointmentModel {
  String? appointmentId;
  String? id;
  String? purpose;
  String? doctorId;
  String? patientId;
  String? providerId;
  String? dateKey;
  String? slotId;
  String? doctorNote;
  String? type;
  UserModel? doctor;
  Patient? patient;
  Timestamp? date;
  String? time;
  Timestamp? createdOn;
  AppointmentStatus? status;
  AppointmentModel(
      {this.appointmentId,
      this.purpose,
      this.doctor,
      this.patient,
      this.doctorId,
      this.patientId,
      this.providerId,
      this.dateKey,
      this.slotId,
      this.doctorNote,
      this.date,
      this.time,
      this.createdOn,
      this.status,
      this.type,
      this.id});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'type': type,
      'appointmentId': appointmentId,
      'purpose': purpose,
      'doctorId': doctorId,
      'patientId': patientId,
      'providerId': providerId,
      'dateKey': dateKey,
      'slotId': slotId,
      'doctorNote': doctorNote,
      'time': time,
      'doctor': doctor?.toMap(),
      'patient': patient?.toMap(),
      'date': date?.millisecondsSinceEpoch,
      'date_created': createdOn?.millisecondsSinceEpoch,
      'status': status?.name,
    };
  }

  factory AppointmentModel.fromSnapshot(
      QueryDocumentSnapshot<Map<String, dynamic>> snapshot) {
    final appointment = AppointmentModel.fromMap(snapshot.data());
    appointment.id = snapshot.id;
    return appointment;
  }

  factory AppointmentModel.fromMap(Map<String, dynamic> map) {
    return AppointmentModel(
      id: (map['id'] ?? map['appointmentId'])?.toString(),
      appointmentId: (map['appointmentId'] ?? map['id'])?.toString(),
      type: map['type']?.toString(),
      purpose: (map['purpose'] ?? map['note'])?.toString(),
      doctorId: (map['doctorId'] ?? map['doctor_id'] ?? map['providerId'])
          ?.toString(),
      patientId: (map['patientId'] ?? map['patient_id'])?.toString(),
      providerId: map['providerId']?.toString(),
      dateKey: map['dateKey']?.toString(),
      slotId: map['slotId']?.toString(),
      doctorNote:
          (map['doctorNote'] ?? map['doctorNotes'] ?? map['notes'])?.toString(),
      time: (map['time'] ?? map['timeLabel'] ?? map['appointment_time'])
          ?.toString(),
      doctor: map['doctor'] is Map
          ? UserModel.fromMap(Map<String, dynamic>.from(map['doctor'] as Map))
          : null,
      patient: _patientFromMap(map),
      date: _timestampFromValue(
          map['startAt'] ?? map['date'] ?? map['appointment_date']),
      createdOn: _timestampFromValue(
        map['date_created'] ?? map['createdAt'] ?? map['createdOn'],
      ),
      status: _appointmentStatusFromValue(map['status']),
    );
  }

  String toJson() => json.encode(toMap());

  factory AppointmentModel.fromJson(String source) =>
      AppointmentModel.fromMap(json.decode(source) as Map<String, dynamic>);
}

Patient? _patientFromMap(Map<String, dynamic> map) {
  if (map['patient'] is Map) {
    final patient = Patient.fromMap(
      Map<String, dynamic>.from(map['patient'] as Map),
    );
    patient.id ??= (map['patientId'] ?? map['patient_id'])?.toString();
    return patient;
  }

  final hasFlatPatientFields = map['patient_name'] != null ||
      map['patient_image'] != null ||
      map['patient_id'] != null;
  if (!hasFlatPatientFields) return null;

  return Patient(
    id: map['patient_id']?.toString(),
    name: map['patient_name']?.toString(),
    photo: map['patient_image']?.toString(),
  );
}

Timestamp? _timestampFromValue(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value;
  if (value is DateTime) return Timestamp.fromDate(value);
  if (value is int) return Timestamp.fromMillisecondsSinceEpoch(value);
  return null;
}

AppointmentStatus _appointmentStatusFromValue(dynamic value) {
  final status = value?.toString();
  return AppointmentStatus.values.firstWhere(
    (item) => item.name == status,
    orElse: () => AppointmentStatus.pending,
  );
}
