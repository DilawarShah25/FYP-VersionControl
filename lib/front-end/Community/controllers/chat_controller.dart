import '../models/message_model.dart';
import '../services/community_firebase_service.dart';

class ChatController {
  final CommunityFirebaseService _service = CommunityFirebaseService();

  Future<void> sendMessage(String receiverId, String text) async {
    await _service.sendMessage(receiverId, text);
  }

  Stream<List<MessageModel>> getMessages(String otherUserId) {
    return _service.getMessages(otherUserId);
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    return await _service.getUserProfile(userId);
  }
}