import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class MessageModel {
  final String messageId;
  final String senderId;
  final String receiverId;
  final String text;
  final Timestamp timestamp;
  final Timestamp? editedAt;

  MessageModel({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    this.editedAt,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      debugPrint('Error: Firestore document data is null for doc: ${doc.id}');
      throw Exception('Firestore document data is null');
    }
    return MessageModel(
      messageId: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      text: data['text'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      editedAt: data['editedAt'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'senderId': senderId,
    'receiverId': receiverId,
    'text': text,
    'timestamp': timestamp,
    'editedAt': editedAt,
  };
}