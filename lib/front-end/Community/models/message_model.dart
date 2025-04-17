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
      debugPrint('Error: Firestore document data is null for doc: ${doc.id}');
      throw Exception('Firestore document data is null');
    }
    if (!data.containsKey('senderId') || data['senderId'] == null || (data['senderId'] as String).isEmpty) {
      debugPrint('Error: Missing or invalid senderId in doc: ${doc.id}');
      throw Exception('Missing or invalid senderId');
    }
    if (!data.containsKey('receiverId') || data['receiverId'] == null || (data['receiverId'] as String).isEmpty) {
      debugPrint('Error: Missing or invalid receiverId in doc: ${doc.id}');
      throw Exception('Missing or invalid receiverId');
    }
    if (!data.containsKey('text') || data['text'] == null || (data['text'] as String).isEmpty) {
      debugPrint('Error: Missing or invalid text in doc: ${doc.id}');
      throw Exception('Missing or invalid text');
    }
    if (!data.containsKey('timestamp') || data['timestamp'] == null) {
      debugPrint('Error: Missing or invalid timestamp in doc: ${doc.id}');
      throw Exception('Missing or invalid timestamp');
    }
    debugPrint('Deserialized MessageModel from doc: ${doc.id}');
    return MessageModel(
      messageId: doc.id,
      senderId: data['senderId'] as String,
      receiverId: data['receiverId'] as String,
      text: data['text'] as String,
      timestamp: data['timestamp'] as Timestamp,
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