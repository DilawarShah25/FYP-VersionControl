class ChatMessage {
  final String id; // Firestore document ID
  final String senderId; // Firebase Auth UID
  final String text;
  final int timestamp;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  factory ChatMessage.fromFirestore(Map<String, dynamic> data, String id) {
    return ChatMessage(
      id: id,
      senderId: data['senderId'],
      text: data['text'],
      timestamp: data['timestamp'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'senderId': senderId,
    'text': text,
    'timestamp': timestamp,
  };
}