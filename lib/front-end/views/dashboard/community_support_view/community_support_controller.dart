import 'package:image_picker/image_picker.dart';
import 'community_support_service.dart';
import 'community_support_model.dart';

class ChatController {
  final ChatService _chatService = ChatService();
  final ImagePicker _picker = ImagePicker();

  List<ChatMessage> get messages => _chatService.messages;

  void sendMessage(String userName, String message, bool isCurrentUser, {List<String>? imageUrls}) {
    final newMessage = ChatMessage(
      userName: userName,
      message: message,
      time: DateTime.now(),
      isCurrentUser: isCurrentUser,
      imageUrls: imageUrls,
    );
    _chatService.addMessage(newMessage);
  }

  Future<List<String>> pickImages() async {
    final List<XFile>? pickedFiles = await _picker.pickMultiImage();
    return pickedFiles?.map((file) => file.path).toList() ?? [];
  }
}
