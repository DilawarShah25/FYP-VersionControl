import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/profile_data.dart';
import '../models/comment_model.dart';
import '../models/message_model.dart';
import '../models/post_model.dart';

class CommunityFirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> createUserProfile({
    required String userId,
    required String name,
    String? email,
    String? phone,
    String? phoneCountryCode,
    String? imageBase64,
    bool showContactDetails = true,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) throw Exception('Name cannot be empty');
    if (userId.isEmpty) throw Exception('User ID cannot be empty');

    final profileData = ProfileData(
      id: userId,
      name: trimmedName,
      email: email?.trim() ?? '',
      phoneCountryCode: phoneCountryCode ?? '+1',
      phoneNumberPart: phone?.trim() ?? '',
      role: 'User',
      imageBase64: imageBase64,
      showContactDetails: showContactDetails,
      showEmail: showContactDetails,
      showPhone: showContactDetails,
    );

    final userData = profileData.toMap();
    final existingUser = await _firestore.collection('users').doc(userId).get();
    if (!existingUser.exists || existingUser.data()?['username'] == null) {
      userData['username'] = '@${trimmedName.toLowerCase().replaceAll(' ', '')}';
    }

    userData['createdAt'] = Timestamp.now();
    userData['phone'] = phone != null && phone.trim().isNotEmpty && phoneCountryCode != null
        ? '$phoneCountryCode${phone.trim()}'
        : null;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .set(userData, SetOptions(merge: true));
      debugPrint('User profile created/updated for userId: $userId');
    } catch (e) {
      debugPrint('Error creating/updating user profile for userId: $userId: $e');
      rethrow;
    }
  }

  Future<ProfileData?> getUserProfile(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        debugPrint('User profile not found for userId: $userId');
        return null;
      }
      final data = userDoc.data()!;
      debugPrint('Fetched profile for userId: $userId, data: $data');
      return ProfileData.fromMap(data);
    } catch (e) {
      debugPrint('Error fetching user profile for userId: $userId: $e');
      return null;
    }
  }

  Future<void> updateUserPrivacy(
      String userId, bool showEmail, bool showPhone) async {
    final user = _auth.currentUser;
    if (user == null || user.uid != userId) throw Exception('Not authorized');
    try {
      await _firestore.collection('users').doc(userId).update({
        'showEmail': showEmail,
        'showPhone': showPhone,
        'showContactDetails': showEmail && showPhone,
      });
      debugPrint('Privacy settings updated for userId: $userId');
    } catch (e) {
      debugPrint('Error updating privacy settings for userId: $userId: $e');
      rethrow;
    }
  }

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
    if (trimmedText.isEmpty && image == null)
      throw Exception('Post content cannot be empty');
    if (trimmedUserName.isEmpty) throw Exception('User name cannot be empty');
    if (user.uid != _auth.currentUser!.uid)
      throw Exception(
          'User ID mismatch: Provided ${user.uid} does not match authenticated user ${_auth.currentUser!.uid}');

    String? imageBase64;
    if (image != null) {
      final file = File(image.path);
      if (!await file.exists()) throw Exception('Image file not found');
      final imageBytes = await file.readAsBytes();
      if (imageBytes.length > 2 * 1024 * 1024)
        throw Exception('Image size exceeds 2MB');
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
      shares: [],
      location: location,
      tags: tags ?? [],
    );

    try {
      final docRef = await _firestore.collection('posts').add(post.toFirestore());
      await docRef.update({'postId': docRef.id});
      debugPrint('Post created for user: ${user.uid}, postId: ${docRef.id}');
    } catch (e) {
      debugPrint('Error creating post for user: ${user.uid}: $e');
      rethrow;
    }
  }

  Future<void> updatePost(String postId, String textContent, XFile? image) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    final postRef = _firestore.collection('posts').doc(postId);
    final post = await postRef.get();
    if (!post.exists) throw Exception('Post not found');
    if (post.data()?['userId'] != user.uid) throw Exception('Not authorized');

    String? imageBase64;
    if (image != null) {
      final file = File(image.path);
      if (!await file.exists()) throw Exception('Image file not found');
      final imageBytes = await file.readAsBytes();
      if (imageBytes.length > 2 * 1024 * 1024)
        throw Exception('Image size exceeds 2MB');
      imageBase64 = base64Encode(imageBytes);
    }

    try {
      await postRef.update({
        'textContent': textContent.trim().isEmpty ? ' ' : textContent.trim(),
        'imageBase64': imageBase64,
        'lastEdited': Timestamp.now(),
      });
      debugPrint('Post updated: $postId');
    } catch (e) {
      debugPrint('Error updating post $postId: $e');
      rethrow;
    }
  }

  Future<void> deletePost(String postId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    final postRef = _firestore.collection('posts').doc(postId);
    final post = await postRef.get();
    if (!post.exists) throw Exception('Post not found');
    if (post.data()?['userId'] != user.uid) throw Exception('Not authorized');

    try {
      final comments = await postRef.collection('comments').get();
      for (var comment in comments.docs) {
        await comment.reference.delete();
      }
      final likes = await postRef.collection('likes').get();
      for (var like in likes.docs) {
        await like.reference.delete();
      }
      await postRef.delete();
      debugPrint('Post deleted: $postId');
    } catch (e) {
      debugPrint('Error deleting post $postId: $e');
      rethrow;
    }
  }

  Stream<List<PostModel>> getPosts({int limit = 20, DocumentSnapshot? startAfter}) {
    Query query = _firestore
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList());
  }

  Future<void> likePost(String postId, String userId) async {
    if (userId != _auth.currentUser!.uid)
      throw Exception(
          'User ID mismatch: Provided $userId does not match authenticated user ${_auth.currentUser!.uid}');
    try {
      final postRef = _firestore.collection('posts').doc(postId);
      final post = await postRef.get();
      if (!post.exists) throw Exception('Post not found: $postId');
      final likeRef = postRef.collection('likes').doc(userId);
      final likeDoc = await likeRef.get();
      if (likeDoc.exists)
        throw Exception('User $userId already liked post $postId');
      await likeRef.set({
        'userId': userId,
        'createdAt': Timestamp.now(),
      });
      debugPrint('Post liked: $postId, user: $userId');
    } catch (e) {
      debugPrint('Error liking post $postId for user $userId: $e');
      rethrow;
    }
  }

  Future<void> unlikePost(String postId, String userId) async {
    if (userId != _auth.currentUser!.uid)
      throw Exception(
          'User ID mismatch: Provided $userId does not match authenticated user ${_auth.currentUser!.uid}');
    try {
      final postRef = _firestore.collection('posts').doc(postId);
      final post = await postRef.get();
      if (!post.exists) throw Exception('Post not found: $postId');
      final likeRef = postRef.collection('likes').doc(userId);
      final likeDoc = await likeRef.get();
      if (!likeDoc.exists)
        throw Exception('User $userId has not liked post $postId');
      await likeRef.delete();
      debugPrint('Post unliked: $postId, user: $userId');
    } catch (e) {
      debugPrint('Error unliking post $postId for user $userId: $e');
      rethrow;
    }
  }

  Future<bool> hasLikedPost(String postId, String userId) async {
    try {
      final doc = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(userId)
          .get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking like status for post $postId, user $userId: $e');
      return false;
    }
  }

  Future<int> getLikeCount(String postId) async {
    try {
      final snapshot = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting like count for post $postId: $e');
      return 0;
    }
  }

  Stream<int> getLikeCountStream(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<bool> hasLikedPostStream(String postId, String userId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .doc(userId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  Future<void> sharePost(String postId, String userId) async {
    if (userId != _auth.currentUser!.uid)
      throw Exception(
          'User ID mismatch: Provided $userId does not match authenticated user ${_auth.currentUser!.uid}');
    try {
      final postRef = _firestore.collection('posts').doc(postId);
      await _firestore.runTransaction((transaction) async {
        final post = await transaction.get(postRef);
        if (!post.exists) throw Exception('Post not found: $postId');
        final shares = List<String>.from(post.data()?['shares'] ?? []);
        if (!shares.contains(userId)) {
          shares.add(userId);
          transaction.update(postRef, {'shares': shares});
        }
      });
      debugPrint('Post shared: $postId, user: $userId');
    } catch (e) {
      debugPrint('Error sharing post $postId for user $userId: $e');
      rethrow;
    }
  }

  Future<void> addComment(
      String postId, String commentText, String userName, String userId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    final trimmedComment = commentText.trim();
    final trimmedUserName = userName.trim();
    if (trimmedComment.isEmpty) throw Exception('Comment cannot be empty');
    if (trimmedUserName.isEmpty) throw Exception('User name cannot be empty');
    if (userId.isEmpty) throw Exception('User ID cannot be empty');
    if (userId != user.uid)
      throw Exception(
          'User ID mismatch: Provided $userId does not match authenticated user ${user.uid}');

    try {
      final postRef = _firestore.collection('posts').doc(postId);
      final post = await postRef.get();
      if (!post.exists) throw Exception('Post not found: $postId');

      final commentRef = postRef.collection('comments').doc();
      final comment = CommentModel(
        commentId: commentRef.id,
        userId: userId,
        userName: trimmedUserName,
        commentText: trimmedComment,
        timestamp: Timestamp.now(),
      );
      await commentRef.set(comment.toFirestore());
      debugPrint('Comment added to post: $postId by user: $userId, text: $trimmedComment');
    } catch (e) {
      debugPrint('Error adding comment to post $postId by user $userId: $e');
      if (e.toString().contains('permission-denied')) {
        throw Exception('Permission denied: Check Firestore rules for /posts/$postId/comments');
      } else if (e.toString().contains('Post not found')) {
        throw Exception('Post not found: $postId. It may have been deleted.');
      } else if (e.toString().contains('network')) {
        throw Exception('Network error: Please check your internet connection.');
      }
      rethrow;
    }
  }

  Future<void> updateComment(String postId, String commentId, String commentText) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    try {
      final commentRef = _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId);
      final comment = await commentRef.get();
      if (!comment.exists) throw Exception('Comment not found: $commentId');
      if (comment.data()?['userId'] != user.uid) throw Exception('Not authorized');

      await commentRef.update({
        'commentText': commentText.trim(),
        'editedAt': Timestamp.now(),
      });
      debugPrint('Comment updated: $commentId in post $postId');
    } catch (e) {
      debugPrint('Error updating comment $commentId for post $postId: $e');
      rethrow;
    }
  }

  Future<void> deleteComment(String postId, String commentId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    try {
      final commentRef = _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId);
      final comment = await commentRef.get();
      if (!comment.exists) throw Exception('Comment not found: $commentId');
      if (comment.data()?['userId'] != user.uid) throw Exception('Not authorized');

      await commentRef.delete();
      debugPrint('Comment deleted: $commentId from post $postId');
    } catch (e) {
      debugPrint('Error deleting comment $commentId for post $postId: $e');
      rethrow;
    }
  }

  Stream<List<CommentModel>> getComments(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => CommentModel.fromFirestore(doc)).toList());
  }

  Future<void> reportPost(String postId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    try {
      final postRef = _firestore.collection('posts').doc(postId);
      final post = await postRef.get();
      if (!post.exists) throw Exception('Post not found: $postId');

      await _firestore.collection('reports').add({
        'postId': postId,
        'userId': user.uid,
        'timestamp': Timestamp.now(),
        'status': 'pending',
      });
      debugPrint('Post reported: $postId by user: ${user.uid}');
    } catch (e) {
      debugPrint('Error reporting post $postId: $e');
      rethrow;
    }
  }

  Future<void> sendMessage(String receiverId, String text) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) throw Exception('Message cannot be empty');
    if (receiverId.trim().isEmpty) throw Exception('Receiver ID cannot be empty');
    if (receiverId == user.uid) throw Exception('Cannot send message to self');

    try {
      final receiverDoc = await _firestore.collection('users').doc(receiverId).get();
      if (!receiverDoc.exists) throw Exception('Recipient not found: $receiverId');

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
      await _firestore.runTransaction((transaction) async {
        final conversation = await transaction.get(conversationRef);
        if (!conversation.exists) {
          transaction.set(conversationRef, {
            'participants': userIds,
            'lastMessage': trimmedText,
            'timestamp': Timestamp.now(),
          });
          debugPrint('Created new conversation: $conversationId with participants: $userIds');
        } else {
          final participants = List<String>.from(conversation.data()?['participants'] ?? []);
          if (!participants.contains(user.uid) || !participants.contains(receiverId)) {
            throw Exception('Invalid conversation participants: $conversationId');
          }
          transaction.update(conversationRef, {
            'lastMessage': trimmedText,
            'timestamp': Timestamp.now(),
          });
          debugPrint('Updated conversation: $conversationId');
        }
        final messageRef = conversationRef.collection('messages').doc();
        transaction.set(messageRef, message.toFirestore()..['messageId'] = messageRef.id);
      });
      debugPrint('Message sent to: $receiverId, conversation: $conversationId, text: $trimmedText');
    } catch (e) {
      debugPrint('Error sending message to $receiverId: $e');
      if (e.toString().contains('permission-denied')) {
        throw Exception('Permission denied: Check Firestore rules for conversations');
      } else if (e.toString().contains('Recipient not found')) {
        throw Exception('Recipient profile not found: $receiverId');
      } else if (e.toString().contains('network')) {
        throw Exception('Network error: Please check your internet connection.');
      }
      rethrow;
    }
  }

  Future<void> updateMessage(String conversationId, String messageId, String text) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    try {
      final messageRef = _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId);
      final message = await messageRef.get();
      if (!message.exists) throw Exception('Message not found: $messageId');
      if (message.data()?['senderId'] != user.uid) throw Exception('Not authorized');

      await messageRef.update({
        'text': text.trim(),
        'editedAt': Timestamp.now(),
      });
      debugPrint('Message updated: $messageId in conversation $conversationId');
    } catch (e) {
      debugPrint('Error updating message $messageId in conversation $conversationId: $e');
      rethrow;
    }
  }

  Future<void> deleteMessage(String conversationId, String messageId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    try {
      final messageRef = _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId);
      final message = await messageRef.get();
      if (!message.exists) throw Exception('Message not found: $messageId');
      if (message.data()?['senderId'] != user.uid) throw Exception('Not authorized');

      await messageRef.delete();
      debugPrint('Message deleted: $messageId from conversation $conversationId');
    } catch (e) {
      debugPrint('Error deleting message $messageId in conversation $conversationId: $e');
      rethrow;
    }
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
        .map((snapshot) =>
        snapshot.docs.map((doc) => MessageModel.fromFirestore(doc)).toList());
  }
}