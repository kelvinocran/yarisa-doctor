import 'dart:convert';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class PersonalPatientsModel {
  String? patientId;
  String? patientName;
  String? patientImage;
  String? status;
  PersonalPatientsModel({
    this.patientId,
    this.patientName,
    this.patientImage,
    this.status,
  });


  PersonalPatientsModel copyWith({
    String? patientId,
    String? patientName,
    String? patientImage,
    String? status,
  }) {
    return PersonalPatientsModel(
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientImage: patientImage ?? this.patientImage,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'patientId': patientId,
      'patientName': patientName,
      'patientImage': patientImage,
      'status': status,
    };
  }

  factory PersonalPatientsModel.fromMap(Map<String, dynamic> map) {
    return PersonalPatientsModel(
      patientId: map['patientId'] != null ? map['patientId'] as String : "",
      patientName: map['patientName'] != null ? map['patientName'] as String : "",
      patientImage: map['patientImage'] != null ? map['patientImage'] as String : "",
      status: map['status'] != null ? map['status'] as String : "",
    );
  }

  String toJson() => json.encode(toMap());

  factory PersonalPatientsModel.fromJson(String source) => PersonalPatientsModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
