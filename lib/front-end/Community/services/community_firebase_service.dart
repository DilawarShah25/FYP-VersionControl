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
          debugPrint('Removing like for user: $userId, new likes count: ${likes.length}');
        } else {
          likes.add(userId);
          debugPrint('Adding like for user: $userId, new likes count: ${likes.length}');
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
      throw Exception('Please log in to comment');
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
      await _firestore.runTransaction((transaction) async {
        final postRef = _firestore.collection('posts').doc(postId);
        final post = await transaction.get(postRef);
        if (!post.exists) {
          debugPrint('Error: Post not found: $postId');
          throw Exception('Post not found');
        }

        final commentRef = _firestore.collection('posts').doc(postId).collection('comments').doc();
        final commentData = {
          'userId': user.uid,
          'userName': trimmedUserName,
          'commentText': trimmedComment,
          'timestamp': Timestamp.now(),
        };
        transaction.set(commentRef, commentData);

        final comments = List<String>.from(post.data()?['comments'] ?? []);
        comments.add(commentRef.id);
        transaction.update(postRef, {'comments': comments});
      });
      debugPrint('Comment added successfully to post: $postId');
    } catch (e) {
      debugPrint('Error adding comment: $e');
      if (e.toString().contains('PERMISSION_DENIED')) {
        throw Exception('You do not have permission to comment on this post');
      }
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
      debugPrint('Received ${snapshot.docs.length} comments for post: $postId');
      return snapshot.docs.map((doc) {
        debugPrint('Processing comment document: ${doc.id}, data: ${doc.data()}');
        return CommentModel.fromFirestore(doc);
      }).toList();
    }).handleError((error) {
      debugPrint('Error fetching comments: $error');
      throw Exception('Failed to load comments: $error');
    });
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      debugPrint('Fetched user profile for userId: $userId, exists: ${doc.exists}');
      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
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
      debugPrint('Error: User not logged in');
      throw Exception('User not logged in');
    }
    if (text.trim().isEmpty) {
      debugPrint('Error: Message text is empty');
      throw Exception('Message cannot be empty');
    }
    if (receiverId.trim().isEmpty) {
      debugPrint('Error: receiverId is empty');
      throw Exception('Receiver ID cannot be empty');
    }
    try {
      final receiverDoc = await _firestore.collection('users').doc(receiverId).get();
      if (!receiverDoc.exists) {
        debugPrint('Error: Receiver $receiverId does not exist');
        throw Exception('Invalid recipient ID');
      }

      await _firestore.collection('chats').add({
        'senderId': user.uid,
        'receiverId': receiverId,
        'text': text.trim(),
        'timestamp': Timestamp.now(),
      });
      debugPrint('Message sent successfully to: $receiverId');
    } catch (e) {
      debugPrint('Error sending message: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  Stream<List<MessageModel>> getMessages(String otherUserId) {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('Error: No authenticated user for getMessages');
      return Stream.value([]); // Return empty stream instead of error
    }
    if (otherUserId.trim().isEmpty) {
      debugPrint('Error: otherUserId is empty');
      return Stream.value([]);
    }

    return _firestore.collection('users').doc(otherUserId).get().asStream().asyncExpand((userDoc) {
      if (!userDoc.exists) {
        debugPrint('Error: otherUserId $otherUserId does not exist in users collection');
        return Stream.value([]);
      }
      debugPrint('Validated otherUserId $otherUserId exists in users collection');

      final sentMessages = _firestore
          .collection('chats')
          .where('senderId', isEqualTo: user.uid)
          .where('receiverId', isEqualTo: otherUserId)
          .orderBy('timestamp', descending: false)
          .snapshots();

      final receivedMessages = _firestore
          .collection('chats')
          .where('senderId', isEqualTo: otherUserId)
          .where('receiverId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: false)
          .snapshots();

      return Stream<List<MessageModel>>.multi((controller) {
        List<MessageModel> messages = [];
        sentMessages.listen((snapshot) {
          final sent = snapshot.docs.map((doc) {
            try {
              debugPrint('Processing sent document: ${doc.id}, data: ${doc.data()}');
              return MessageModel.fromFirestore(doc);
            } catch (e) {
              debugPrint('Error deserializing sent document ${doc.id}: $e');
              return null;
            }
          }).whereType<MessageModel>().toList();
          messages = [...messages, ...sent];
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          controller.add(messages);
          debugPrint('Updated with ${sent.length} sent messages, total: ${messages.length}');
        }, onError: (error) {
          debugPrint('Error in sent messages stream: $error');
          controller.add(messages); // Continue with current messages
        });

        receivedMessages.listen((snapshot) {
          final received = snapshot.docs.map((doc) {
            try {
              debugPrint('Processing received document: ${doc.id}, data: ${doc.data()}');
              return MessageModel.fromFirestore(doc);
            } catch (e) {
              debugPrint('Error deserializing received document ${doc.id}: $e');
              return null;
            }
          }).whereType<MessageModel>().toList();
          messages = [...messages, ...received];
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          controller.add(messages);
          debugPrint('Updated with ${received.length} received messages, total: ${messages.length}');
        }, onError: (error) {
          debugPrint('Error in received messages stream: $error');
          controller.add(messages); // Continue with current messages
        });
      }).handleError((error) {
        debugPrint('Error in messages stream: $error');
        return <MessageModel>[];
      });
    });
  }

  Future<void> debugChatsCollection({String? otherUserId}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('Debug: No authenticated user');
        return;
      }
      final query = otherUserId != null
          ? _firestore
          .collection('chats')
          .where('senderId', isEqualTo: user.uid)
          .where('receiverId', isEqualTo: otherUserId)
          : _firestore.collection('chats').where('senderId', isEqualTo: user.uid);
      final snapshot = await query.get();
      debugPrint('Debug: Found ${snapshot.docs.length} chat documents');
      for (var doc in snapshot.docs) {
        debugPrint('Debug: Chat document ${doc.id}: ${doc.data()}');
      }
    } catch (e) {
      debugPrint('Debug: Error querying chats collection: $e');
    }
  }
}