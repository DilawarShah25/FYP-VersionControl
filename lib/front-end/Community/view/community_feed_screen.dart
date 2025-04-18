import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import '../../views/dashboard/other_dashboard/profile_view.dart';
import '../controllers/community_controller.dart';
import '../models/comment_model.dart';
import '../models/optimistic_comment_mixin.dart';
import '../models/post_model.dart';
import 'create_post_screen.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen>
    with OptimisticCommentMixin<CommunityFeedScreen> {
  final CommunityController _controller = CommunityController();
  Map<String, bool> _localLikeState = {}; // Track local like state for immediate UI feedback

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('User not authenticated, redirecting to login');
      Navigator.pushReplacementNamed(context, '/login');
      return const SizedBox();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Share Your Experience',
          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.white),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.secondaryColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppTheme.white, size: 28),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreatePostScreen()),
            ),
            tooltip: 'Create Post',
          ),
        ],
      ),
      body: Container(
        color: AppTheme.backgroundColor,
        child: StreamBuilder<List<PostModel>>(
          stream: _controller.getPosts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor));
            }
            if (snapshot.hasError) {
              debugPrint('Error loading posts: ${snapshot.error}');
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 60, color: AppTheme.errorColor),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading posts: ${snapshot.error}',
                      style: GoogleFonts.poppins(fontSize: 16, color: AppTheme.errorColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Retry',
                        style: GoogleFonts.poppins(fontSize: 16, color: AppTheme.white),
                      ),
                    ),
                  ],
                ),
              );
            }
            final posts = snapshot.data ?? [];
            if (posts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.chat_bubble_outline, size: 60, color: AppTheme.primaryColor),
                    const SizedBox(height: 16),
                    Text(
                      'No posts yet. Be the first to share!',
                      style: GoogleFonts.poppins(fontSize: 18, color: Colors.black54),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(AppTheme.paddingMedium),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return FutureBuilder<Map<String, dynamic>?>(
                  future: _controller.service.getUserProfile(post.userId),
                  builder: (context, userSnapshot) {
                    final userData = userSnapshot.data;
                    final updatedUserName = userData?['name'] ?? post.userName;
                    return _buildPostCard(post, updatedUserName, user!.uid);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildPostCard(PostModel post, String updatedUserName, String currentUserId) {
    // Use local like state if available, otherwise fall back to post.likes
    final isLiked = _localLikeState[post.postId] ?? post.likes.contains(currentUserId);
    final isOwnPost = post.userId == currentUserId;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: AppTheme.paddingMedium),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileView(
                            userId: post.userId,
                            userName: updatedUserName,
                          ),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.accentColor,
                      backgroundImage: post.userProfileImage != null && post.userProfileImage!.isNotEmpty
                          ? MemoryImage(base64Decode(post.userProfileImage!))
                          : null,
                      child: post.userProfileImage == null || post.userProfileImage!.isEmpty
                          ? Text(
                        updatedUserName.isNotEmpty ? updatedUserName[0].toUpperCase() : 'U',
                        style: GoogleFonts.poppins(fontSize: 20, color: AppTheme.primaryColor),
                      )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          updatedUserName,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          _formatTimestamp(post.timestamp),
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.report_problem_outlined, color: AppTheme.errorColor),
                        onPressed: () async {
                          try {
                            await _controller.reportPost(post.postId);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Post reported', style: GoogleFonts.poppins()),
                                backgroundColor: AppTheme.secondaryColor,
                              ),
                            );
                          } catch (e) {
                            debugPrint('Failed to report post: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to report post: $e', style: GoogleFonts.poppins()),
                                backgroundColor: AppTheme.errorColor,
                              ),
                            );
                          }
                        },
                        tooltip: 'Report Post',
                      ),
                      if (isOwnPost)
                        IconButton(
                          icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                          onPressed: () async {
                            try {
                              await _controller.service.deletePost(post.postId);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Post deleted', style: GoogleFonts.poppins()),
                                  backgroundColor: AppTheme.secondaryColor,
                                ),
                              );
                            } catch (e) {
                              debugPrint('Failed to delete post: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to delete post: $e', style: GoogleFonts.poppins()),
                                  backgroundColor: AppTheme.errorColor,
                                ),
                              );
                            }
                          },
                          tooltip: 'Delete Post',
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                post.textContent,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
              ),
              if (post.imageBase64 != null && post.imageBase64!.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    base64Decode(post.imageBase64!),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 200,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('Image decode error: $error');
                      return Container(
                        height: 200,
                        color: AppTheme.accentColor,
                        child: const Icon(Icons.error, color: AppTheme.errorColor),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? AppTheme.errorColor : Colors.black54,
                      size: 24,
                    ),
                    onPressed: () async {
                      try {
                        // Update local state for immediate feedback
                        setState(() {
                          _localLikeState[post.postId] = !isLiked;
                        });
                        await _controller.toggleLike(post.postId, currentUserId);
                        debugPrint('Like toggled for post: ${post.postId}');
                      } catch (e) {
                        // Revert local state on error
                        setState(() {
                          _localLikeState.remove(post.postId);
                        });
                        debugPrint('Failed to toggle like: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to update like: $e', style: GoogleFonts.poppins()),
                            backgroundColor: AppTheme.errorColor,
                          ),
                        );
                      }
                    },
                    tooltip: isLiked ? 'Unlike' : 'Like',
                  ),
                  Text(
                    _formatCount(post.likes.length, 'like'),
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.comment_outlined, color: AppTheme.primaryColor, size: 24),
                    onPressed: () => _showCommentsDialog(post),
                    tooltip: 'Comment',
                  ),
                  Text(
                    _formatCount(post.comments.length, 'comment'),
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCount(int count, String type) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M $type${count == 1 ? '' : 's'}';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k $type${count == 1 ? '' : 's'}';
    }
    return '$count $type${count == 1 ? '' : 's'}';
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);
    String relativeTime;

    if (diff.inDays > 0) {
      relativeTime = '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      relativeTime = '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      relativeTime = '${diff.inMinutes}m ago';
    } else {
      relativeTime = 'Just now';
    }

    final formattedDateTime = DateFormat('MMMM dd, yyyy \'at\' hh:mm a').format(date);
    return '$formattedDateTime ($relativeTime)';
  }

  void _showCommentsDialog(PostModel post) {
    final commentController = TextEditingController();
    clearOptimisticComments(); // Reset optimistic comments

    showDialog(
      context: context,
      builder: (context) {
        try {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 5,
            backgroundColor: AppTheme.white,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
                minWidth: 280,
                maxWidth: 400,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.paddingMedium),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comments',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: StreamBuilder<List<CommentModel>>(
                        stream: _controller.getComments(post.postId),
                        initialData: optimisticComments,
                        builder: (context, snapshot) {
                          debugPrint(
                              'Comments StreamBuilder state: ${snapshot.connectionState}, '
                                  'hasError: ${snapshot.hasError}, hasData: ${snapshot.hasData}, '
                                  'error: ${snapshot.error}');
                          if (snapshot.connectionState == ConnectionState.waiting && optimisticComments.isEmpty) {
                            return const Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor));
                          }
                          if (snapshot.hasError) {
                            debugPrint('Comments StreamBuilder error: ${snapshot.error}');
                            String errorMessage = 'Failed to load comments';
                            if (snapshot.error.toString().contains('permission-denied')) {
                              errorMessage = 'Permission denied. Try again or check your authentication.';
                            }
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.error_outline, size: 40, color: AppTheme.errorColor),
                                  const SizedBox(height: 8),
                                  Text(
                                    errorMessage,
                                    style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.errorColor),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () => setState(() {}),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.secondaryColor,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: Text(
                                      'Retry',
                                      style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.white),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          final comments = [...(snapshot.data ?? []), ...optimisticComments];
                          debugPrint('Loaded ${comments.length} comments for post: ${post.postId}');
                          return comments.isEmpty
                              ? Center(
                            child: Text(
                              'No comments yet',
                              style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
                            ),
                          )
                              : ListView.builder(
                            shrinkWrap: true,
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              final comment = comments[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppTheme.accentColor,
                                  child: Text(
                                    comment.userName.isNotEmpty ? comment.userName[0].toUpperCase() : 'U',
                                    style: GoogleFonts.poppins(color: AppTheme.primaryColor),
                                  ),
                                ),
                                title: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProfileView(
                                          userId: comment.userId,
                                          userName: comment.userName,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    comment.userName.isNotEmpty ? comment.userName : 'Anonymous',
                                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                subtitle: Text(
                                  comment.commentText.isNotEmpty ? comment.commentText : 'No comment text',
                                  style: GoogleFonts.poppins(fontSize: 14),
                                ),
                                trailing: Text(
                                  _formatTimestamp(comment.timestamp),
                                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: commentController,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: GoogleFonts.poppins(),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: AppTheme.accentColor.withOpacity(0.3),
                        prefixIcon: const Icon(Icons.comment, color: AppTheme.primaryColor),
                      ),
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () async {
                          final text = commentController.text.trim();
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) {
                            debugPrint('No authenticated user');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please log in to comment', style: GoogleFonts.poppins()),
                                backgroundColor: AppTheme.errorColor,
                              ),
                            );
                            Navigator.of(context).pop();
                            Navigator.pushReplacementNamed(context, '/login');
                            return;
                          }
                          if (text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Comment cannot be empty', style: GoogleFonts.poppins()),
                                backgroundColor: AppTheme.errorColor,
                              ),
                            );
                            return;
                          }
                          final commentId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
                          try {
                            addOptimisticComment(
                              commentId: commentId,
                              userId: user.uid,
                              userName: user.displayName ?? 'User',
                              commentText: text,
                            );
                            await _controller.addComment(
                              post.postId,
                              text,
                              user.displayName ?? 'User',
                            );
                            commentController.clear();
                            removeOptimisticComment(commentId); // This should now be recognized
                            // Force UI refresh to update comment count
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Comment posted successfully', style: GoogleFonts.poppins()),
                                backgroundColor: AppTheme.secondaryColor,
                              ),
                            );
                          } catch (e) {
                            debugPrint('Failed to post comment: $e');
                            removeOptimisticComment(commentId); // This should now be recognized
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to post comment: $e', style: GoogleFonts.poppins()),
                                backgroundColor: AppTheme.errorColor,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: Text(
                          'Post Comment',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        } catch (e) {
          debugPrint('Error rendering comment dialog: $e');
          return AlertDialog(
            title: Text('Error', style: GoogleFonts.poppins()),
            content: Text('Failed to load comments: $e', style: GoogleFonts.poppins()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK', style: GoogleFonts.poppins()),
              ),
            ],
          );
        }
      },
    ).catchError((error) {
      debugPrint('Dialog error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open comments: $error', style: GoogleFonts.poppins()),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    });
  }
}