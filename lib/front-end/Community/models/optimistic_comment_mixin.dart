import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/comment_model.dart';

mixin OptimisticCommentMixin<T extends StatefulWidget> on State<T> {
  final List<CommentModel> _optimisticComments = [];

  List<CommentModel> get optimisticComments => List.unmodifiable(_optimisticComments);

  @override
  void dispose() {
    _optimisticComments.clear();
    super.dispose();
  }

  void addOptimisticComment({
    required String commentId,
    required String userId,
    required String userName,
    required String commentText,
  }) {
    if (!mounted) return;

    debugPrint('Adding optimistic comment: $commentId');
    final optimisticComment = CommentModel(
      commentId: commentId,
      userId: userId,
      userName: userName,
      commentText: commentText,
      timestamp: Timestamp.fromDate(DateTime.now()),
    );

    setState(() {
      _optimisticComments.add(optimisticComment);
    });
  }

  void removeOptimisticComment(String commentId) {
    if (!mounted) return;

    debugPrint('Removing optimistic comment: $commentId');
    setState(() {
      _optimisticComments.removeWhere((c) => c.commentId == commentId);
    });
  }

  void clearOptimisticComments() {
    if (!mounted) return;

    debugPrint('Clearing optimistic comments');
    setState(() {
      _optimisticComments.clear();
    });
  }
}