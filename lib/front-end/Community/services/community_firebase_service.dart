import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/comment_model.dart';
import '../models/message_model.dart';
import '../models/post_model.dart';

class CommunityFirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> createPost({
    required String textContent,
    XFile? image,
    required String userName,
    String? userProfileImage,
    String? location,
    List<String>? tags,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    final trimmedText = textContent.trim();
    final trimmedUserName = userName.trim();
    if (trimmedText.isEmpty && image == null) throw Exception('Post content cannot be empty');
    if (trimmedUserName.isEmpty) throw Exception('User name cannot be empty');

    String? imageBase64;
    if (image != null) {
      final file = File(image.path);
      if (!await file.exists()) throw Exception('Image file not found');
      final imageBytes = await file.readAsBytes();
      if (imageBytes.length > 2 * 1024 * 1024) throw Exception('Image size exceeds 2MB');
      imageBase64 = base64Encode(imageBytes);
    }

    final post = PostModel(
      postId: '',
      userId: user.uid,
      userName: trimmedUserName,
      userProfileImage: userProfileImage,
      textContent: trimmedText.isEmpty ? ' ' : trimmedText,
      imageBase64: imageBase64,
      timestamp: Timestamp.now(),
      likes: [],
      comments: [],
      shares: [],
      location: location,
      tags: tags ?? [],
    );

    await _firestore.collection('posts').add(post.toFirestore());
  }

  Future<void> deletePost(String postId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    final postRef = _firestore.collection('posts').doc(postId);
    final post = await postRef.get();
    if (!post.exists) throw Exception('Post not found');
    if (post.data()?['userId'] != user.uid) throw Exception('Not authorized');

    // Delete associated comments
    final comments = await postRef.collection('comments').get();
    for (var comment in comments.docs) {
      await comment.reference.delete();
    }

    await postRef.delete();
  }

  Stream<List<PostModel>> getPosts({int limit = 20}) {
    return _firestore
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList());
  }

  Future<void> toggleLike(String postId, String userId) async {
    final postRef = _firestore.collection('posts').doc(postId);
    await _firestore.runTransaction((transaction) async {
      final post = await transaction.get(postRef);
      if (!post.exists) throw Exception('Post not found');
      final likes = List<String>.from(post.data()?['likes'] ?? []);
      if (likes.contains(userId)) {
        likes.remove(userId);
      } else {
        likes.add(userId);
      }
      transaction.update(postRef, {'likes': likes});
    });
  }

  Future<void> sharePost(String postId, String userId) async {
    final postRef = _firestore.collection('posts').doc(postId);
    await _firestore.runTransaction((transaction) async {
      final post = await transaction.get(postRef);
      if (!post.exists) throw Exception('Post not found');
      final shares = List<String>.from(post.data()?['shares'] ?? []);
      if (!shares.contains(userId)) {
        shares.add(userId);
        transaction.update(postRef, {'shares': shares});
      }
    });
  }

  Future<void> addComment(String postId, String commentText, String userName) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    final trimmedComment = commentText.trim();
    final trimmedUserName = userName.trim();
    if (trimmedComment.isEmpty) throw Exception('Comment cannot be empty');
    if (trimmedUserName.isEmpty) throw Exception('User name cannot be empty');

    await _firestore.runTransaction((transaction) async {
      final postRef = _firestore.collection('posts').doc(postId);
      final post = await transaction.get(postRef);
      if (!post.exists) throw Exception('Post not found');

      final commentRef = postRef.collection('comments').doc();
      final comment = CommentModel(
        commentId: commentRef.id,
        userId: user.uid,
        userName: trimmedUserName,
        commentText: trimmedComment,
        timestamp: Timestamp.now(),
      );
      transaction.set(commentRef, comment.toFirestore());

      final comments = List<String>.from(post.data()?['comments'] ?? []);
      comments.add(commentRef.id);
      transaction.update(postRef, {'comments': comments});
    });
  }

  Stream<List<CommentModel>> getComments(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => CommentModel.fromFirestore(doc)).toList());
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final publicDoc = await _firestore.collection('public_profiles').doc(userId).get();
      final userDoc = _auth.currentUser?.uid == userId
          ? await _firestore.collection('users').doc(userId).get()
          : null;
      final profileData = <String, dynamic>{};

      if (publicDoc.exists) {
        profileData.addAll(publicDoc.data()!);
      }
      if (userDoc != null && userDoc.exists) {
        profileData.addAll(userDoc.data()!);
      }

      return profileData.isNotEmpty ? profileData : null;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  Future<void> createUserProfile({
    required String userId,
    required String name,
    String? imageBase64,
    bool showContactDetails = true,
  }) async {
    if (userId.trim().isEmpty) throw Exception('User ID cannot be empty');
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) throw Exception('Name cannot be empty');

    if (imageBase64 != null && imageBase64.isNotEmpty) {
      final bytes = base64Decode(imageBase64);
      if (bytes.length > 500 * 1024) throw Exception('Profile image size exceeds 500KB');
    }

    final publicProfile = {
      'name': trimmedName,
      'showContactDetails': showContactDetails,
      if (showContactDetails && imageBase64 != null && imageBase64.isNotEmpty) 'image_base64': imageBase64,
    };

    await _firestore.collection('public_profiles').doc(userId).set(publicProfile, SetOptions(merge: true));
  }

  Future<void> reportPost(String postId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    final postRef = _firestore.collection('posts').doc(postId);
    final post = await postRef.get();
    if (!post.exists) throw Exception('Post not found');

    await _firestore.collection('reports').add({
      'postId': postId,
      'userId': user.uid,
      'timestamp': Timestamp.now(),
      'status': 'pending',
    });
  }

  Future<void> sendMessage(String receiverId, String text) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) throw Exception('Message cannot be empty');
    if (receiverId.trim().isEmpty) throw Exception('Receiver ID cannot be empty');

    final receiverDoc = await _firestore.collection('users').doc(receiverId).get();
    if (!receiverDoc.exists) throw Exception('Invalid recipient ID');

    final userIds = [user.uid, receiverId]..sort();
    final conversationId = userIds.join('_');

    final message = MessageModel(
      messageId: '',
      senderId: user.uid,
      receiverId: receiverId,
      text: trimmedText,
      timestamp: Timestamp.now(),
    );

    final conversationRef = _firestore.collection('conversations').doc(conversationId);
    await conversationRef.set({'participants': userIds, 'lastMessage': trimmedText, 'timestamp': Timestamp.now()}, SetOptions(merge: true));
    await conversationRef.collection('messages').add(message.toFirestore());
  }

  Stream<List<MessageModel>> getMessages(String otherUserId) {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');
    if (otherUserId.trim().isEmpty) throw Exception('Invalid otherUserId');

    final userIds = [user.uid, otherUserId]..sort();
    final conversationId = userIds.join('_');

    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => MessageModel.fromFirestore(doc)).toList());
  }
}