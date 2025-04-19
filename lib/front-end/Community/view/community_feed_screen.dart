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
import '../models/post_model.dart';
import 'create_post_screen.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  final CommunityController _controller = CommunityController();
  Map<String, bool> _localLikeState = {};

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.white)),
        backgroundColor: AppTheme.errorColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  ImageProvider? _buildProfileImage(String base64String) {
    try {
      if (base64String.isEmpty || !RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(base64String)) {
        debugPrint('Invalid Base64 string for profile image: $base64String');
        return null;
      }
      final bytes = base64Decode(base64String);
      return MemoryImage(bytes);
    } catch (e) {
      debugPrint('Error decoding profile image: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('User not authenticated, redirecting to login');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSnackBar('Please log in.');
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const SizedBox();
    }

    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
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
              debugPrint('Posts StreamBuilder: connectionState=${snapshot.connectionState}, hasError=${snapshot.hasError}, error=${snapshot.error}');
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
                      return _buildPostCard(post, updatedUserName, user.uid);
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard(PostModel post, String updatedUserName, String currentUserId) {
    final isLiked = _localLikeState[post.postId] ?? post.likes.contains(currentUserId);
    final isOwnPost = post.userId == currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.paddingMedium),
      decoration: AppTheme.cardDecoration,
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
                        builder: (_) => ProfileView(userId: post.userId, userName: updatedUserName),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.accentColor,
                    backgroundImage: post.userProfileImage != null && post.userProfileImage!.isNotEmpty
                        ? _buildProfileImage(post.userProfileImage!)
                        : null,
                    child: post.userProfileImage == null || post.userProfileImage!.isEmpty
                        ? Text(
                      updatedUserName.isNotEmpty ? updatedUserName[0].toUpperCase() : 'U',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.primaryColor),
                    )
                        : null,
                  ),
                ),
                const SizedBox(width: AppTheme.paddingSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        updatedUserName,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                          DateFormat('MMMM dd, yyyy \'at\' \nhh:mm a').format(post.timestamp.toDate()),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                if (isOwnPost)
                  IconButton(
                    icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                    onPressed: () async {
                      try {
                        await _controller.deletePost(post.postId);
                        _showSnackBar('Post deleted');
                      } catch (e) {
                        _showSnackBar('Error: $e');
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            Text(
              post.textContent,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (post.imageBase64 != null && post.imageBase64!.isNotEmpty) ...[
              const SizedBox(height: AppTheme.paddingSmall),
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
            const SizedBox(height: AppTheme.paddingSmall),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? AppTheme.errorColor : Colors.black54,
                  ),
                  onPressed: () async {
                    try {
                      setState(() => _localLikeState[post.postId] = !isLiked);
                      await _controller.toggleLike(post.postId, currentUserId);
                    } catch (e) {
                      setState(() => _localLikeState.remove(post.postId));
                      _showSnackBar('Error liking post: $e');
                    }
                  },
                ),
                Text(
                  '${post.likes.length}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: AppTheme.paddingMedium),
                IconButton(
                  icon: const Icon(Icons.comment, color: Colors.black54),
                  onPressed: () => _showCommentsDialog(post),
                ),
                Text(
                  '${post.comments.length}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCommentsDialog(PostModel post) {
    final commentController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppTheme.white,
        title: Text('Comments', style: Theme.of(context).textTheme.headlineMedium),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder<List<CommentModel>>(
                  stream: _controller.getComments(post.postId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.errorColor),
                        ),
                      );
                    }
                    final comments = snapshot.data ?? [];
                    return ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: AppTheme.accentColor,
                            child: Text(
                              comment.userName.isNotEmpty ? comment.userName[0].toUpperCase() : 'U',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppTheme.primaryColor),
                            ),
                          ),
                          title: Text(
                            comment.userName,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            comment.commentText,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  hintText: 'Add a comment...',
                ),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.primaryColor),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = commentController.text.trim();
              if (text.isEmpty) return;
              try {
                final user = FirebaseAuth.instance.currentUser!;
                final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                final userName = userDoc.data()?['name'] ?? 'Anonymous';
                await _controller.addComment(post.postId, text, userName);
                commentController.clear();
                Navigator.pop(context);
              } catch (e) {
                _showSnackBar('Error posting comment: $e');
              }
            },
            child: Text('Post'),
          ),
        ],
      ),
    );
  }
}