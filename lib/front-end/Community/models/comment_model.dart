import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String commentId;
  final String userId;
  final String userName;
  final String commentText;
  final Timestamp timestamp;

  CommentModel({
    required this.commentId,
    required this.userId,
    required this.userName,
    required this.commentText,
    required this.timestamp,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      commentId: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      commentText: data['commentText'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }
}