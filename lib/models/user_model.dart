import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String? fullname;
  String? speciality;
  String? bio;
  String? location;
  String? phone;
  String? clinic;
  String? licenseCode;
  String? email;
  String? id;
  String? nationality;
  String? pic;
  int? experience;
  bool? loggedIn;
  bool? online;

  UserModel({
    this.fullname,
    this.speciality,
    this.bio,
    this.location,
    this.phone,
    this.clinic,
    this.licenseCode,
    this.email,
    this.id,
    this.nationality,
    this.pic,
    this.experience,
    this.loggedIn,
    this.online,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'fullname': fullname,
      'speciality': speciality,
      'bio': bio,
      'location': location,
      'phone': phone,
      'clinic': clinic,
      'licenseCode': licenseCode,
      'email': email,
      'doctorid': id,
      'nationality': nationality,
      'pic': pic,
      'experience': experience,
      'loggedIn': loggedIn,
      'online': online,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      fullname: _stringValue(map['fullname']),
      speciality: _stringValue(map['speciality']),
      bio: _stringValue(map['bio']),
      location: _stringValue(map['location']),
      phone: _stringValue(map['phone']),
      clinic: _stringValue(map['clinic']),
      licenseCode: _stringValue(map['licenseCode']),
      email: _stringValue(map['email']),
      id: _stringValue(map['doctorid'] ?? map['doctorId']),
      nationality: _stringValue(map['nationality']),
      pic: _stringValue(map['pic']),
      experience: _intValue(map['experience']),
      loggedIn: _boolValue(map['loggedIn']),
      online: _boolValue(map['online']),
    );
  }

  factory UserModel.fromDocumentSnapshot(
      DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return UserModel.fromMap({
      ...data,
      'doctorid': data['doctorid'] ?? data['doctorId'] ?? snapshot.id,
    });
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source) as Map<String, dynamic>);
}

String? _stringValue(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text.toLowerCase() == 'null') return null;
  return text;
}

int? _intValue(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString().trim() ?? '');
}

bool? _boolValue(dynamic value) {
  if (value is bool) return value;
  final text = value?.toString().toLowerCase().trim();
  if (text == 'true') return true;
  if (text == 'false') return false;
  return null;
}
