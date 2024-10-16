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
      fullname: map['fullname'] != null ? map['fullname'] as String : null,
      speciality:
          map['speciality'] != null ? map['speciality'] as String : null,
      bio: map['bio'] != null ? map['bio'] as String : null,
      location: map['location'] != null ? map['location'] as String : null,
      phone: map['phone'] != null ? map['phone'] as String : null,
      clinic: map['clinic'] != null ? map['clinic'] as String : null,
      licenseCode:
          map['licenseCode'] != null ? map['licenseCode'] as String : null,
      email: map['email'] != null ? map['email'] as String : null,
      id: map['doctorid'] != null ? map['doctorid'] as String : null,
      nationality:
          map['nationality'] != null ? map['nationality'] as String : null,
      pic: map['pic'] != null ? map['pic'] as String : null,
      experience: map['experience'] != null ? map['experience'] as int : null,
      loggedIn: map['loggedIn'] != null ? map['loggedIn'] as bool : null,
      online: map['online'] != null ? map['online'] as bool : null,
    );
  }

  factory UserModel.fromDocumentSnapshot(
      DocumentSnapshot<Map<String, dynamic>> map) {
    return UserModel(
      fullname: map['fullname'] != null ? map['fullname'] as String : null,
      speciality:
          map['speciality'] != null ? map['speciality'] as String : null,
      bio: map['bio'] != null ? map['bio'] as String : null,
      location: map['location'] != null ? map['location'] as String : null,
      phone: map['phone'] != null ? map['phone'] as String : null,
      clinic: map['clinic'] != null ? map['clinic'] as String : null,
      licenseCode:
          map['licenseCode'] != null ? map['licenseCode'] as String : null,
      email: map['email'] != null ? map['email'] as String : null,
      id: map['doctorid'] != null ? map['doctorid'] as String : null,
      nationality:
          map['nationality'] != null ? map['nationality'] as String : null,
      pic: map['pic'] != null ? map['pic'] as String : null,
      // token: map['token'] != null ? map['token'] as String : null,
      experience: map['experience'] != null ? map['experience'] as int : null,
      loggedIn: map['loggedIn'] != null ? map['loggedIn'] as bool : null,
      online: map['online'] != null ? map['online'] as bool : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
