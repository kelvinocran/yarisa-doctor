import 'dart:io';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_model.dart';

class ChatConfig extends ChangeNotifier {
  List<Chat> conversation = [];
  bool istyping = false;
  final db = FirebaseFirestore.instance
      .collection("Chats")
      .doc(FirebaseAuth.instance.currentUser?.uid)
      .collection("all");

  Stream<DocumentSnapshot<Map<String, dynamic>>> chatStream(String userId) {
    return db.doc(userId).snapshots();
  }

  Future<void> saveChat(String userId, Chat chatData) async {
    await db.doc(userId).set({
      "chat": FieldValue.arrayUnion([chatData.toMap()])
    }, SetOptions(merge: true));
  }

  Future<void> saveOtherChat(String userId, Map<String, dynamic> chatData) async {
    await db.doc(userId).set({
      "chat": FieldValue.arrayUnion([chatData])
    }, SetOptions(merge: true));
  }

  Future<void> updateChat(String userId, Chat chatData) async {
    await db.doc(userId).set({
      "chat": FieldValue.arrayUnion([chatData.toMap()])
    }, SetOptions(merge: true));
  }

  Future<void> removeChat(String? userId) async {
    await db.doc(userId).delete();
  }

  Future changeTyingStatus(bool status) async {
    istyping = status;
    notifyListeners();
  }
}

final chatconfig = ChangeNotifierProvider<ChatConfig>((ref) {
  return ChatConfig();
});

Future<String> uploadImage(File file, String location) async {
  try {
    final index = math.Random().nextInt(100000);
    final ref = FirebaseStorage.instance
        .ref()
        .child("${FirebaseAuth.instance.currentUser!.uid}/$location")
        .child("${location.toLowerCase()}$index");
    final downloadUrl = ref
        .putFile(file)
        .then((p0) => p0.ref.getDownloadURL())
        .onError((error, stackTrace) => "Error: $error")
        .catchError((error) {
      return "Error: There was an error. While uploading image.";
    });
    return downloadUrl;
  } catch (e) {
    throw Exception("Error: There was an error. While uploading image.");
  }
}
