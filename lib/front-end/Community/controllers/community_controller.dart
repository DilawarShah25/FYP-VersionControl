import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import '../models/comment_model.dart';
import '../models/post_model.dart';
import '../services/community_firebase_service.dart';

class CommunityController {
  final CommunityFirebaseService _service = CommunityFirebaseService();

  CommunityFirebaseService get service => _service;

  Future<void> createPost({
    required String textContent,
    XFile? image,
    required String userName,
    String? userProfileImage,
  }) async {
    if (userName.trim().isEmpty) {
      debugPrint('Error: User name cannot be empty');
      throw Exception('User name cannot be empty');
    }
    debugPrint('Creating post for user: $userName, text: $textContent');
    try {
      await _service.createPost(
        textContent: textContent,
        image: image,
        userName: userName,
        userProfileImage: userProfileImage,
      );
      debugPrint('Post created successfully');
    } catch (e) {
      debugPrint('Error creating post: $e');
      throw e;
    }
  }

  Future<void> deletePost(String postId) async {
    debugPrint('Deleting post: $postId');
    try {
      await _service.deletePost(postId);
      debugPrint('Post deleted successfully');
    } catch (e) {
      debugPrint('Error deleting post: $e');
      throw e;
    }
  }

  Stream<List<PostModel>> getPosts({int limit = 10}) {
    debugPrint('Fetching posts with limit: $limit');
    return _service.getPosts(limit: limit).handleError((error) {
      debugPrint('Error fetching posts: $error');
      throw error;
    });
  }

  Future<void> toggleLike(String postId, String userId) async {
    debugPrint('Toggling like for post: $postId, user: $userId');
    try {
      await _service.toggleLike(postId, userId);
      debugPrint('Like toggled successfully');
    } catch (e) {
      debugPrint('Error toggling like: $e');
      throw e;
    }
  }

  Future<void> addComment(String postId, String commentText, String userName) async {
    if (userName.trim().isEmpty) {
      debugPrint('Error: User name cannot be empty');
      throw Exception('User name cannot be empty');
    }
    if (commentText.trim().isEmpty) {
      debugPrint('Error: Comment text cannot be empty');
      throw Exception('Comment text cannot be empty');
    }
    debugPrint('Adding comment to post: $postId, user: $userName, text: $commentText');
    try {
      await _service.addComment(postId, commentText, userName);
      debugPrint('Comment added successfully');
    } catch (e) {
      debugPrint('Error adding comment: $e');
      throw e;
    }
  }

  Stream<List<CommentModel>> getComments(String postId) {
    debugPrint('Fetching comments for post: $postId');
    return _service.getComments(postId).handleError((error) {
      debugPrint('Error fetching comments: $error');
      throw error;
    });
  }

  Future<void> reportPost(String postId) async {
    debugPrint('Reporting post: $postId');
    try {
      await _service.reportPost(postId);
      debugPrint('Post reported successfully');
    } catch (e) {
      debugPrint('Error reporting post: $e');
      throw e;
    }
  }
}