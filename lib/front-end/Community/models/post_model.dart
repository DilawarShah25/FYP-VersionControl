import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String postId;
  final String userId;
  final String userName;
  final String? userProfileImage;
  final String textContent;
  final String? imageBase64;
  final Timestamp timestamp;
  final List<String> likes;
  final List<String> comments;

  PostModel({
    required this.postId,
    required this.userId,
    required this.userName,
    this.userProfileImage,
    required this.textContent,
    this.imageBase64,
    required this.timestamp,
    required this.likes,
    required this.comments,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostModel(
      postId: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'User', // Fallback, should not occur
      userProfileImage: data['userProfileImage'],
      textContent: data['textContent'] ?? '',
      imageBase64: data['imageBase64'],
      timestamp: data['timestamp'] ?? Timestamp.now(),
      likes: List<String>.from(data['likes'] ?? []),
      comments: List<String>.from(data['comments'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userProfileImage': userProfileImage,
      'textContent': textContent,
      'imageBase64': imageBase64,
      'timestamp': timestamp,
      'likes': likes,
      'comments': comments,
    };
  }
}