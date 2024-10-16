import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  Future<void> removeChat(String? userId) async {
    await db.doc(userId).delete();
  }

  Future changeTyingStatus(bool status)async{
    istyping = status;
    notifyListeners();
  }
}

final chatconfig = ChangeNotifierProvider<ChatConfig>((ref) {
  return ChatConfig();
});
