import 'dart:convert';

import 'package:yarisa_doctor/screens/add_prescription.dart';
import 'package:yarisa_doctor/screens/chat_view.dart';

class Chat {
  String? message;
  String? recipientId;
  String? senderId;
  String? senderName;
  String? recipientName;
  DateTime? date;
  bool? isMe;
  MessageType? type;
  List<Prescription>? prescription;
  Chat(
      {this.message,
      this.recipientId,
      this.senderId,
      this.senderName,
      this.recipientName,
      this.date,
      this.isMe,
      this.type,
      this.prescription});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'message': """$message""",
      'recipientId': recipientId,
      'senderId': senderId,
      'senderName': senderName,
      'recipientName': recipientName,
      'date': date?.millisecondsSinceEpoch,
      'isMe': isMe,
      'type': type?.name,
      'prescription': prescription
    };
  }

  factory Chat.fromMap(Map<String, dynamic> map) {
    return Chat(
        message: map['message'] != null ? map['message'] as String : null,
        type: map['type'] != null
            ? MessageType.values.firstWhere((e) => e.name == map['type'])
            : MessageType.text,
        recipientId:
            map['recipientId'] != null ? map['recipientId'] as String : null,
        senderId: map['senderId'] != null ? map['senderId'] as String : null,
        senderName:
            map['senderName'] != null ? map['senderName'] as String : null,
        recipientName: map['recipientName'] != null
            ? map['recipientName'] as String
            : null,
        date: map['date'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['date'] as int)
            : null,
        isMe: map['isMe'] != null ? map['isMe'] as bool : null,
        prescription: map['prescription'] != null
            ? (map['prescription']['data'] as List<dynamic>)
                .map((e) => Prescription.fromMap(e))
                .toList()
            : null);
  }

  factory Chat.fromMQTT(Map<String, dynamic> map) {
    return Chat(
      message: map['message'] != null
          ? map['message'].runtimeType == String
              ? map['message']
              : utf8.decode((map['message'].cast<int>()))
          : null,
      type: map['type'] != null
          ? MessageType.values.firstWhere((e) => e.name == map['type'])
          : MessageType.text,
      recipientId:
          map['recipientId'] != null ? map['recipientId'] as String : null,
      senderId: map['senderId'] != null ? map['senderId'] as String : null,
      senderName:
          map['senderName'] != null ? map['senderName'] as String : null,
      recipientName:
          map['recipientName'] != null ? map['recipientName'] as String : null,
      date: map['date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['date'] as int)
          : null,
      isMe: map['isMe'] != null ? map['isMe'] as bool : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Chat.fromJson(String source) =>
      Chat.fromMap(json.decode(source) as Map<String, dynamic>);
}
