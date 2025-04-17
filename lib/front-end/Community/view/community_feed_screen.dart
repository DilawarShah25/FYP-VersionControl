import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';
import '../controllers/community_controller.dart';
import '../models/comment_model.dart';
import '../models/post_model.dart';
import 'create_post_screen.dart';
import 'chat_screen.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  final CommunityController _controller = CommunityController();

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
        title: Text('GrowTogether', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.white)),
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
                child: Text(
                  'Error loading posts',
                  style: GoogleFonts.poppins(fontSize: 16, color: AppTheme.errorColor),
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
    final isLiked = post.likes.contains(currentUserId);
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
                      if (post.userId.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              otherUserId: post.userId,
                              otherUserName: updatedUserName,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Cannot message this user', style: GoogleFonts.poppins()),
                            backgroundColor: AppTheme.errorColor,
                          ),
                        );
                      }
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
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? AppTheme.errorColor : Colors.black54,
                          size: 24,
                        ),
                        onPressed: () async {
                          try {
                            await _controller.toggleLike(post.postId, currentUserId);
                            setState(() {}); // Force UI refresh
                          } catch (e) {
                            debugPrint('Failed to update like: $e');
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
                        '${post.likes.length}',
                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.comment_outlined, color: AppTheme.primaryColor, size: 24),
                        onPressed: () => _showCommentsDialog(post),
                        tooltip: 'Comment',
                      ),
                      Text(
                        '${post.comments.length}',
                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.secondaryColor, size: 24),
                    onPressed: () {
                      if (post.userId.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              otherUserId: post.userId,
                              otherUserName: updatedUserName,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Cannot message this user', style: GoogleFonts.poppins()),
                            backgroundColor: AppTheme.errorColor,
                          ),
                        );
                      }
                    },
                    tooltip: 'Message',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCommentsDialog(PostModel post) {
    showDialog(
      context: context,
      builder: (context) {
        final commentController = TextEditingController();
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.paddingMedium),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                StreamBuilder<List<CommentModel>>(
                  stream: _controller.getComments(post.postId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor));
                    }
                    if (snapshot.hasError) {
                      debugPrint('Error loading comments: ${snapshot.error}');
                      return Text(
                        'Error loading comments',
                        style: GoogleFonts.poppins(color: AppTheme.errorColor),
                      );
                    }
                    final comments = snapshot.data!;
                    return SizedBox(
                      height: 200,
                      child: comments.isEmpty
                          ? Center(
                        child: Text(
                          'No comments yet',
                          style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
                        ),
                      )
                          : ListView.builder(
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
                            title: Text(
                              comment.userName,
                              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              comment.commentText,
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),
                            trailing: Text(
                              _formatTimestamp(comment.timestamp),
                              style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: commentController,
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    hintStyle: GoogleFonts.poppins(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppTheme.accentColor.withOpacity(0.3),
                    prefixIcon: const Icon(Icons.comment, color: AppTheme.primaryColor),
                  ),
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    final text = commentController.text.trim();
                    if (text.isNotEmpty) {
                      try {
                        await _controller.addComment(
                          post.postId,
                          text,
                          FirebaseAuth.instance.currentUser?.displayName ?? 'User',
                        );
                        commentController.clear();
                        Navigator.of(context).pop();
                      } catch (e) {
                        debugPrint('Failed to post comment: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to post comment: $e', style: GoogleFonts.poppins()),
                            backgroundColor: AppTheme.errorColor,
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Comment cannot be empty', style: GoogleFonts.poppins()),
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
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}