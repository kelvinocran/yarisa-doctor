import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class Patient {
  String? photo;
  String? phone;
  String? name;
  String? id;
  String? email;
  String? digitalAddress;
  Timestamp? dateCreated;
  List<Allergies>? allergies;
  List<PersonalInfo>? personalInfo;
  Patient({
    this.photo,
    this.phone,
    this.name,
    this.id,
    this.email,
    this.digitalAddress,
    this.dateCreated,
    this.allergies,
    this.personalInfo,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'photo': photo,
      'phone': phone,
      'name': name,
      'id': id,
      'email': email,
      'digital_address': digitalAddress,
      'date_created': dateCreated?.millisecondsSinceEpoch,
      'allergies': allergies?.map((x) => x.toMap()).toList(),
      'personal_info': personalInfo?.map((x) => x.toMap()).toList(),
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      photo: map['photo'] != null ? map['photo'] as String : null,
      phone: map['phone'] != null ? map['phone'] as String : null,
      name: map['name'] != null ? map['name'] as String : null,
      id: map['id'] != null ? map['id'] as String : null,
      email: map['email'] != null ? map['email'] as String : null,
      digitalAddress: map['digital_address'] != null
          ? map['digital_address'] as String
          : null,
      dateCreated: map['date_created'] != null
          ? map['date_created'] is int
              ? (Timestamp.fromMillisecondsSinceEpoch(map['date_created']))
              : (map['date_created'] as Timestamp)
          : null,
      allergies: map['allergies'] != null
          ? List<Allergies>.from(
              (map['allergies']).map<Allergies?>(
                (x) => Allergies.fromMap(x as Map<String, dynamic>),
              ),
            )
          : null,
      personalInfo: map['personal_info'] != null
          ? List<PersonalInfo>.from(
              (map['personal_info']).map<PersonalInfo?>(
                (x) => PersonalInfo.fromMap(x as Map<String, dynamic>),
              ),
            )
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Patient.fromJson(String source) =>
      Patient.fromMap(json.decode(source) as Map<String, dynamic>);
}

class Allergies {
  String? allergy;
  List<dynamic>? symptoms;
  Allergies({
    this.allergy,
    this.symptoms,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'allergy': allergy,
      'symptoms': symptoms,
    };
  }

  factory Allergies.fromMap(Map<String, dynamic> map) {
    return Allergies(
      allergy: map['allergy'] != null ? map['allergy'] as String : null,
      symptoms: map['symptoms'] != null
          ? List<dynamic>.from((map['symptoms'] as List<dynamic>))
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Allergies.fromJson(String source) =>
      Allergies.fromMap(json.decode(source) as Map<String, dynamic>);
}

class PersonalInfo {
  int? age;
  int? height;
  int? weight;
  String? gender;
  String? genotype;
  String? bloodgroup;
  PersonalInfo({
    this.age,
    this.height,
    this.weight,
    this.gender,
    this.genotype,
    this.bloodgroup,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'age': age,
      'height': height,
      'weight': weight,
      'gender': gender,
      'genotype': genotype,
      'bloodgroup': bloodgroup,
    };
  }

  factory PersonalInfo.fromMap(Map<String, dynamic> map) {
    return PersonalInfo(
      age: map['age'] != null ? map['age'] as int : null,
      height: map['height'] != null ? map['height'] as int : null,
      weight: map['weight'] != null ? map['weight'] as int : null,
      gender: map['gender'] != null ? map['gender'] as String : null,
      genotype: map['genotype'] != null ? map['genotype'] as String : null,
      bloodgroup:
          map['bloodgroup'] != null ? map['bloodgroup'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory PersonalInfo.fromJson(String source) =>
      PersonalInfo.fromMap(json.decode(source) as Map<String, dynamic>);
}
