import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
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
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('Error: User not logged in');
      throw Exception('User not logged in');
    }
    final trimmedText = textContent.trim();
    final trimmedUserName = userName.trim();
    if (trimmedText.isEmpty && image == null) {
      debugPrint('Error: Post content is empty');
      throw Exception('Post content cannot be empty');
    }
    if (trimmedUserName.isEmpty) {
      debugPrint('Error: User name is empty');
      throw Exception('User name cannot be empty');
    }
    String? base64Image;
    if (image != null) {
      try {
        final imageBytes = await File(image.path).readAsBytes();
        base64Image = base64Encode(imageBytes);
      } catch (e) {
        debugPrint('Error encoding image: $e');
        throw Exception('Failed to encode image');
      }
    }
    final post = PostModel(
      postId: '',
      userId: user.uid,
      userName: trimmedUserName,
      userProfileImage: userProfileImage,
      textContent: trimmedText.isEmpty ? ' ' : trimmedText,
      imageBase64: base64Image,
      timestamp: Timestamp.now(),
      likes: [],
      comments: [],
    );
    final postData = post.toFirestore();
    debugPrint('Post data to Firestore: $postData');
    try {
      await _firestore.collection('posts').add(postData);
      debugPrint('Post created successfully for user: ${user.uid}');
    } catch (e) {
      debugPrint('Firestore error creating post: $e');
      throw Exception('Failed to create post: $e');
    }
  }

  Future<void> deletePost(String postId) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('Error: User not logged in');
      throw Exception('User not logged in');
    }
    try {
      final postRef = _firestore.collection('posts').doc(postId);
      final post = await postRef.get();
      if (!post.exists) {
        debugPrint('Error: Post not found: $postId');
        throw Exception('Post not found');
      }
      if (post.data()?['userId'] != user.uid) {
        debugPrint('Error: User not authorized to delete post: $postId');
        throw Exception('Not authorized to delete this post');
      }
      await postRef.delete();
      debugPrint('Post deleted successfully: $postId');
    } catch (e) {
      debugPrint('Error deleting post: $e');
      throw Exception('Failed to delete post: $e');
    }
  }

  Stream<List<PostModel>> getPosts({int limit = 10}) {
    debugPrint('Fetching posts with limit: $limit');
    return _firestore
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      debugPrint('Received ${snapshot.docs.length} posts');
      return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
    }).handleError((error) {
      debugPrint('Error fetching posts: $error');
      throw error;
    });
  }

  Future<void> toggleLike(String postId, String userId) async {
    debugPrint('Toggling like for post: $postId, user: $userId');
    try {
      await _firestore.runTransaction((transaction) async {
        final postRef = _firestore.collection('posts').doc(postId);
        final post = await transaction.get(postRef);
        if (!post.exists) {
          debugPrint('Error: Post not found: $postId');
          throw Exception('Post not found');
        }
        final likes = List<String>.from(post.data()?['likes'] ?? []);
        if (likes.contains(userId)) {
          likes.remove(userId);
          debugPrint('Removing like for user: $userId');
        } else {
          likes.add(userId);
          debugPrint('Adding like for user: $userId');
        }
        transaction.update(postRef, {'likes': likes});
      });
      debugPrint('Like updated successfully');
    } catch (e) {
      debugPrint('Error toggling like: $e');
      throw Exception('Failed to update like: $e');
    }
  }

  Future<void> addComment(String postId, String commentText, String userName) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('Error: User not logged in');
      throw Exception('User not logged in');
    }
    final trimmedComment = commentText.trim();
    final trimmedUserName = userName.trim();
    if (trimmedComment.isEmpty) {
      debugPrint('Error: Comment is empty');
      throw Exception('Comment cannot be empty');
    }
    if (trimmedUserName.isEmpty) {
      debugPrint('Error: User name is empty');
      throw Exception('User name cannot be empty');
    }
    try {
      await _firestore.collection('posts').doc(postId).collection('comments').add({
        'userId': user.uid,
        'userName': trimmedUserName,
        'commentText': trimmedComment,
        'timestamp': Timestamp.now(),
      });
      debugPrint('Comment added successfully to post: $postId');
    } catch (e) {
      debugPrint('Error adding comment: $e');
      throw Exception('Failed to add comment: $e');
    }
  }

  Stream<List<CommentModel>> getComments(String postId) {
    debugPrint('Fetching comments for post: $postId');
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) {
      debugPrint('Received ${snapshot.docs.length} comments');
      return snapshot.docs.map((doc) => CommentModel.fromFirestore(doc)).toList();
    }).handleError((error) {
      debugPrint('Error fetching comments: $error');
      throw error;
    });
  }

  Future<void> reportPost(String postId) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('Error: User not logged in');
      throw Exception('User not logged in');
    }
    try {
      await _firestore.collection('reports').add({
        'postId': postId,
        'userId': user.uid,
        'timestamp': Timestamp.now(),
      });
      debugPrint('Post reported successfully: $postId');
    } catch (e) {
      debugPrint('Error reporting post: $e');
      throw Exception('Failed to report post: $e');
    }
  }

  Future<void> sendMessage(String receiverId, String text) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('Error: No authenticated user for sendMessage');
      throw Exception('No authenticated user');
    }
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      debugPrint('Error: Message text is empty');
      throw Exception('Message text cannot be empty');
    }
    if (receiverId.trim().isEmpty) {
      debugPrint('Error: receiverId is empty');
      throw Exception('receiverId cannot be empty');
    }
    // Validate receiverId exists in users collection
    final userDoc = await _firestore.collection('users').doc(receiverId).get();
    if (!userDoc.exists) {
      debugPrint('Error: receiverId $receiverId does not exist in users collection');
      throw Exception('Invalid recipient ID');
    }
    final message = MessageModel(
      messageId: _firestore.collection('chats').doc().id,
      senderId: user.uid,
      receiverId: receiverId,
      text: trimmedText,
      timestamp: Timestamp.now(),
    );
    debugPrint('Sending message to $receiverId: $text, messageId: ${message.messageId}, senderId: ${user.uid}');
    try {
      await _firestore.collection('chats').doc(message.messageId).set(message.toFirestore());
      debugPrint('Message sent successfully: ${message.messageId}');
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (e.toString().contains('permission-denied')) {
        debugPrint('Permission denied when sending message. Check Firestore rules and receiverId: $receiverId');
      }
      throw Exception('Failed to send message: $e');
    }
  }

  Stream<List<MessageModel>> getMessages(String otherUserId) {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('Error: No authenticated user for getMessages');
      return Stream.error('No authenticated user');
    }
    if (otherUserId.trim().isEmpty) {
      debugPrint('Error: otherUserId is empty');
      return Stream.error('otherUserId cannot be empty');
    }
    // Validate otherUserId exists in users collection
    _firestore.collection('users').doc(otherUserId).get().then((doc) {
      if (!doc.exists) {
        debugPrint('Warning: otherUserId $otherUserId does not exist in users collection');
      } else {
        debugPrint('Validated otherUserId $otherUserId exists in users collection');
      }
    });
    debugPrint('Fetching messages for user: ${user.uid}, otherUser: $otherUserId');
    try {
      final query = _firestore
          .collection('chats')
          .where('senderId', whereIn: [user.uid, otherUserId])
          .where('receiverId', whereIn: [user.uid, otherUserId])
          .orderBy('timestamp', descending: false);
      debugPrint('Executing query: collection=chats, senderId in [${user.uid}, $otherUserId], receiverId in [${user.uid}, $otherUserId], orderBy=timestamp');
      return query.snapshots().map((snapshot) {
        debugPrint('Received snapshot with ${snapshot.docs.length} documents');
        if (snapshot.docs.isEmpty) {
          debugPrint('No messages found for user: ${user.uid}, otherUser: $otherUserId');
        }
        return snapshot.docs.map((doc) {
          try {
            debugPrint('Processing document: ${doc.id}, data: ${doc.data()}');
            return MessageModel.fromFirestore(doc);
          } catch (e) {
            debugPrint('Error deserializing document ${doc.id}: $e');
            throw e;
          }
        }).toList();
      }).handleError((error) {
        debugPrint('Error in messages stream: $error');
        if (error.toString().contains('permission-denied')) {
          debugPrint('Permission denied when fetching messages. Check Firestore rules, user: ${user.uid}, otherUser: $otherUserId');
        }
        throw Exception('Failed to load messages: $error');
      });
    } catch (e) {
      debugPrint('Error setting up messages stream: $e');
      return Stream.error('Failed to load messages: $e');
    }
  }

  // Debug method to inspect chats collection
  Future<void> debugChatsCollection({required String otherUserId}) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('Error: No authenticated user for debugChatsCollection');
      return;
    }
    try {
      final snapshot = await _firestore.collection('chats').get();
      debugPrint('Total chats documents: ${snapshot.docs.length}');
      for (var doc in snapshot.docs) {
        final data = doc.data();
        debugPrint('Document ${doc.id}: $data');
        if (data['senderId'] == user.uid || data['receiverId'] == user.uid) {
          debugPrint('Accessible document ${doc.id} for user ${user.uid}: $data');
        }
      }
    } catch (e) {
      debugPrint('Error debugging chats collection: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        debugPrint('No profile found for user: $userId');
        return null;
      }
      final data = doc.data();
      if (data?['showContactDetails'] == false && userId != _auth.currentUser?.uid) {
        return {
          'name': data?['name'],
          'image_base64': data?['image_base64'],
          'role': data?['role'],
          'showContactDetails': false,
        };
      }
      debugPrint('Fetched user profile for: $userId');
      return data;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  Future<void> updateUserProfile({
    required String userId,
    required String name,
    required String email,
    required String phoneCountryCode,
    required String phoneNumberPart,
    required String role,
    String? imageBase64,
    required bool showContactDetails,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.uid != userId) {
      debugPrint('Error: Invalid user for update');
      throw Exception('User not authorized');
    }
    try {
      final data = {
        'name': name.trim(),
        'email': email.trim(),
        'phoneCountryCode': phoneCountryCode.trim(),
        'phoneNumberPart': phoneNumberPart.trim(),
        'role': role.trim(),
        'image_base64': imageBase64 ?? '',
        'showContactDetails': showContactDetails,
        'updatedAt': Timestamp.now(),
      };
      debugPrint('Updating user profile: $data');
      await _firestore.collection('users').doc(userId).set(data, SetOptions(merge: true));
      await user.updateDisplayName(name.trim());
      await user.updateEmail(email.trim());
      if (imageBase64 != null) await user.updatePhotoURL(imageBase64);
      debugPrint('User profile updated successfully');
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      throw Exception('Failed to update profile: $e');
    }
  }
}