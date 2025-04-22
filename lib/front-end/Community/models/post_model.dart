import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String postId;
  final String userId;
  final String userName;
  final String? userProfileImage;
  final String textContent;
  final String? imageBase64;
  final Timestamp timestamp;
  final List<String>? comments; // Made optional
  final List<String> shares;
  final String? location;
  final List<String> tags;
  final Timestamp? lastEdited;

  PostModel({
    required this.postId,
    required this.userId,
    required this.userName,
    this.userProfileImage,
    required this.textContent,
    this.imageBase64,
    required this.timestamp,
    this.comments, // Made optional
    required this.shares,
    this.location,
    required this.tags,
    this.lastEdited,
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
      comments: data['comments'] != null ? List<String>.from(data['comments']) : null, // Handle null
      shares: List<String>.from(data['shares'] ?? []),
      location: data['location'],
      tags: List<String>.from(data['tags'] ?? []),
      lastEdited: data['lastEdited'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'postId': postId,
    'userId': userId,
    'userName': userName,
    'userProfileImage': userProfileImage,
    'textContent': textContent,
    'imageBase64': imageBase64,
    'timestamp': timestamp,
    if (comments != null) 'comments': comments, // Only include if not null
    'shares': shares,
    'location': location,
    'tags': tags,
    'lastEdited': lastEdited,
  };

  PostModel copyWith({
    String? postId,
    String? userId,
    String? userName,
    String? userProfileImage,
    String? textContent,
    String? imageBase64,
    Timestamp? timestamp,
    List<String>? comments,
    List<String>? shares,
    String? location,
    List<String>? tags,
    Timestamp? lastEdited,
  }) {
    return PostModel(
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfileImage: userProfileImage ?? this.userProfileImage,
      textContent: textContent ?? this.textContent,
      imageBase64: imageBase64 ?? this.imageBase64,
      timestamp: timestamp ?? this.timestamp,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      location: location ?? this.location,
      tags: tags ?? this.tags,
      lastEdited: lastEdited ?? this.lastEdited,
    );
  }
}