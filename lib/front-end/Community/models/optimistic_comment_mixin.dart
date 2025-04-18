import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import '../models/comment_model.dart';

mixin OptimisticCommentMixin<T extends StatefulWidget> on State<T> {
  List<CommentModel> _optimisticComments = [];

  List<CommentModel> get optimisticComments => _optimisticComments;

  void addOptimisticComment({
    required String commentId,
    required String userId,
    required String userName,
    required String commentText,
  }) {
    final optimisticComment = CommentModel(
      commentId: commentId,
      userId: userId,
      userName: userName,
      commentText: commentText,
      timestamp: Timestamp.now(),
    );
    setState(() {
      _optimisticComments.add(optimisticComment);
    });
  }

  void removeOptimisticComment(String commentId) {
    setState(() {
      _optimisticComments.removeWhere((c) => c.commentId == commentId);
    });
  }

  void clearOptimisticComments() {
    setState(() {
      _optimisticComments = [];
    });
  }
}