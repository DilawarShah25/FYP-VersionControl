import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../services/community_firebase_service.dart';
import '../models/comment_model.dart';
import '../models/post_model.dart';

class CommunityController {
  final CommunityFirebaseService _service = CommunityFirebaseService();

  Future<void> createPost({
    required String textContent,
    XFile? image,
    required String userName,
    String? userProfileImage,
    String? location,
    List<String>? tags,
  }) async {
    await _service.createPost(
      textContent: textContent,
      image: image,
      userName: userName,
      userProfileImage: userProfileImage,
      location: location,
      tags: tags,
    );
  }

  Future<void> updatePost(String postId, String textContent, XFile? image) async {
    await _service.updatePost(postId, textContent, image);
  }

  Future<void> deletePost(String postId) async {
    await _service.deletePost(postId);
  }

  Stream<List<PostModel>> getPosts({int limit = 20, DocumentSnapshot? startAfter}) {
    return _service.getPosts(limit: limit, startAfter: startAfter);
  }

  Stream<List<CommentModel>> getComments(String postId) {
    return _service.getComments(postId);
  }

  Future<void> addComment({
    required String postId,
    required String commentText,
    required String userName,
    required String userId,
  }) async {
    await _service.addComment(postId, commentText, userName, userId);
  }

  Future<void> updateComment(String postId, String commentId, String commentText) async {
    await _service.updateComment(postId, commentId, commentText);
  }

  Future<void> deleteComment(String postId, String commentId) async {
    await _service.deleteComment(postId, commentId);
  }

  Future<void> likePost(String postId, String userId) async {
    await _service.likePost(postId, userId);
  }

  Future<void> unlikePost(String postId, String userId) async {
    await _service.unlikePost(postId, userId);
  }

  Future<bool> hasLikedPost(String postId, String userId) async {
    return await _service.hasLikedPost(postId, userId);
  }

  Future<int> getLikeCount(String postId) async {
    return await _service.getLikeCount(postId);
  }

  Stream<int> getLikeCountStream(String postId) {
    return _service.getLikeCountStream(postId);
  }

  Stream<bool> hasLikedPostStream(String postId, String userId) {
    return _service.hasLikedPostStream(postId, userId);
  }
}