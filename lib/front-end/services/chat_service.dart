import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendMessage(String groupId, ChatMessage message) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .add(message.toFirestore());
  }

  Stream<List<ChatMessage>> getMessages(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ChatMessage.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  Future<bool> isUserInGroup(String groupId, String userId) async {
    final groupDoc = await _firestore.collection('groups').doc(groupId).get();
    if (!groupDoc.exists) return false;
    final members = groupDoc.data()?['members'] as List<dynamic>? ?? [];
    return members.contains(userId);
  }
}