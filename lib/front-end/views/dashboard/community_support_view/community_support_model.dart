class ChatMessage {
  final String userName;
  final String message;
  final DateTime time;
  final bool isCurrentUser;
  final List<String>? imageUrls;

  ChatMessage({
    required this.userName,
    required this.message,
    required this.time,
    required this.isCurrentUser,
    this.imageUrls,
  });
}
