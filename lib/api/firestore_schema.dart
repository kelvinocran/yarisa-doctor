import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreCollections {
  static const doctors = 'Doctors';
  static const patients = 'Patients';
  static const appointments = 'Appointments';
  static const conversations = 'Conversations';
  static const secondOpinions = 'SecondOpinions';
}

class DoctorSubcollections {
  static const patients = 'Patients';
  static const availability = 'Availability';
  static const availabilityDays = 'AvailabilityDays';
  static const slots = 'Slots';
}

class FirestoreSchema {
  static FirebaseFirestore get db => FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>> doctorDoc(String doctorId) {
    return db.collection(FirestoreCollections.doctors).doc(doctorId);
  }

  static CollectionReference<Map<String, dynamic>> appointments() {
    return db.collection(FirestoreCollections.appointments);
  }

  static CollectionReference<Map<String, dynamic>> secondOpinions() {
    return db.collection(FirestoreCollections.secondOpinions);
  }

  static DocumentReference<Map<String, dynamic>> availabilityDay(
    String doctorId,
    DateTime date,
  ) {
    return doctorDoc(doctorId)
        .collection(DoctorSubcollections.availabilityDays)
        .doc(dateKey(date));
  }

  static DocumentReference<Map<String, dynamic>> availabilitySlot(
    String doctorId,
    DateTime date,
    String slotLabel,
  ) {
    return availabilityDay(doctorId, date)
        .collection(DoctorSubcollections.slots)
        .doc(slotId(slotLabel));
  }

  static String dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static String slotId(String slotLabel) {
    return slotLabel
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  static String conversationId(String firstUserId, String secondUserId) {
    final participantIds = [firstUserId, secondUserId]..sort();
    return participantIds.join('_');
  }

  static DocumentReference<Map<String, dynamic>> conversation(
    String firstUserId,
    String secondUserId,
  ) {
    return db
        .collection(FirestoreCollections.conversations)
        .doc(conversationId(firstUserId, secondUserId));
  }
}
