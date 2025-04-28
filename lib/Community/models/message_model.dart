import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class MessageModel {
  final String messageId;
  final String senderId;
  final String receiverId;
  final String text;
  final Timestamp timestamp;

  MessageModel({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      debugPrint('Warning: Firestore document data is null for doc: ${doc.id}');
      return MessageModel(
        messageId: doc.id,
        senderId: '',
        receiverId: '',
        text: 'Invalid message',
        timestamp: Timestamp.now(),
      );
    }

    final senderId = data['senderId'] as String? ?? '';
    final receiverId = data['receiverId'] as String? ?? '';
    final text = data['text'] as String? ?? '';
    final timestamp = data['timestamp'] as Timestamp? ?? Timestamp.now();

    if (senderId.isEmpty || receiverId.isEmpty || text.isEmpty) {
      debugPrint('Warning: Missing or invalid fields in doc: ${doc.id}, data: $data');
      return MessageModel(
        messageId: doc.id,
        senderId: senderId,
        receiverId: receiverId,
        text: text.isEmpty ? 'Invalid message' : text,
        timestamp: timestamp,
      );
    }

    debugPrint('Deserialized MessageModel from doc: ${doc.id}');
    return MessageModel(
      messageId: doc.id,
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      timestamp: timestamp,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': timestamp,
    };
  }
}