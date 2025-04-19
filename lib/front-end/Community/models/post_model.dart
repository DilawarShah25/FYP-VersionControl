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
  final List<String> shares; // Added for share functionality
  final String? location; // Added for geotagging
  final List<String> tags; // Added for post categorization

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
    required this.shares,
    this.location,
    required this.tags,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostModel(
      postId: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userProfileImage: data['userProfileImage'],
      textContent: data['textContent'] ?? '',
      imageBase64: data['imageBase64'],
      timestamp: data['timestamp'] ?? Timestamp.now(),
      likes: List<String>.from(data['likes'] ?? []),
      comments: List<String>.from(data['comments'] ?? []),
      shares: List<String>.from(data['shares'] ?? []),
      location: data['location'],
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'userName': userName,
    'userProfileImage': userProfileImage,
    'textContent': textContent,
    'imageBase64': imageBase64,
    'timestamp': timestamp,
    'likes': likes,
    'comments': comments,
    'shares': shares,
    'location': location,
    'tags': tags,
  };

  PostModel copyWith({
    String? postId,
    String? userId,
    String? userName,
    String? userProfileImage,
    String? textContent,
    String? imageBase64,
    Timestamp? timestamp,
    List<String>? likes,
    List<String>? comments,
    List<String>? shares,
    String? location,
    List<String>? tags,
  }) {
    return PostModel(
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfileImage: userProfileImage ?? this.userProfileImage,
      textContent: textContent ?? this.textContent,
      imageBase64: imageBase64 ?? this.imageBase64,
      timestamp: timestamp ?? this.timestamp,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      location: location ?? this.location,
      tags: tags ?? this.tags,
    );
  }
}