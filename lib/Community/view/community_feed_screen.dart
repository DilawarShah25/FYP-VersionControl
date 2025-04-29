import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';
import '../../views/dashboard/profile_view.dart';
import '../controllers/community_controller.dart';
import '../models/post_model.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  final CommunityController _controller = CommunityController();
  String? _errorMessage;

  Future<void> _toggleLike(String postId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please log in to like posts', style: GoogleFonts.poppins()),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    try {
      setState(() => _errorMessage = null);
      final isLiked = await _controller.hasLikedPost(postId, user.uid);
      if (isLiked) {
        await _controller.unlikePost(postId, user.uid);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Post unliked', style: GoogleFonts.poppins()),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      } else {
        await _controller.likePost(postId, user.uid);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Post liked', style: GoogleFonts.poppins()),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    } catch (e) {
      String errorMsg;
      if (e.toString().contains('Post not found')) {
        errorMsg = 'Post no longer exists. Refresh the feed.';
      } else {
        errorMsg = 'Error liking/unliking post: $e';
      }
      setState(() => _errorMessage = errorMsg);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg, style: GoogleFonts.poppins()),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 5),
        ),
      );
      debugPrint('Error toggling like for post $postId by user ${user.uid}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
        ),
        body: Column(
          children: [
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(AppTheme.paddingSmall),
                color: AppTheme.errorColor,
                child: Text(
                  _errorMessage!,
                  style: GoogleFonts.poppins(color: AppTheme.white),
                ),
              ),
            Expanded(
              child: StreamBuilder<List<PostModel>>(
                stream: _controller.getPosts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
                  }
                  if (snapshot.hasError) {
                    debugPrint('Error fetching posts: ${snapshot.error}');
                    return Center(
                      child: Text(
                        'Error loading posts: ${snapshot.error}',
                        style: GoogleFonts.poppins(color: AppTheme.errorColor),
                      ),
                    );
                  }
                  final posts = snapshot.data ?? [];
                  if (posts.isEmpty) {
                    return Center(
                      child: Text(
                        'No posts available.',
                        style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PostDetailScreen(post: post, userName: post.userName),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: AppTheme.paddingMedium,
                            vertical: AppTheme.paddingSmall,
                          ),
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
                                            builder: (_) => ProfileView(
                                              userId: post.userId,
                                              userName: post.userName,
                                            ),
                                          ),
                                        );
                                      },
                                      child: CircleAvatar(
                                        radius: 20,
                                        backgroundColor: AppTheme.accentColor,
                                        backgroundImage: post.userProfileImage != null &&
                                            post.userProfileImage!.isNotEmpty
                                            ? MemoryImage(base64Decode(post.userProfileImage!))
                                            : null,
                                        child: post.userProfileImage == null || post.userProfileImage!.isEmpty
                                            ? Text(
                                          post.userName.isNotEmpty ? post.userName[0].toUpperCase() : 'U',
                                          style: GoogleFonts.poppins(color: AppTheme.primaryColor),
                                        )
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: AppTheme.paddingSmall),
                                    Expanded(
                                      child: Text(
                                        post.userName,
                                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppTheme.paddingSmall),
                                Text(
                                  post.textContent,
                                  style: GoogleFonts.poppins(fontSize: 16),
                                ),
                                if (post.imageBase64 != null && post.imageBase64!.isNotEmpty) ...[
                                  const SizedBox(height: AppTheme.paddingSmall),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.memory(
                                      base64Decode(post.imageBase64!),
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      errorBuilder: (context, error, stackTrace) {
                                        debugPrint('Image decode error: $error');
                                        return const Icon(Icons.error, color: AppTheme.errorColor);
                                      },
                                    ),
                                  ),
                                ],
                                const SizedBox(height: AppTheme.paddingSmall),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        StreamBuilder<bool>(
                                          stream: user != null
                                              ? _controller.hasLikedPostStream(post.postId, user.uid)
                                              : Stream.value(false),
                                          builder: (context, snapshot) {
                                            final isLiked = snapshot.data ?? false;
                                            return IconButton(
                                              icon: Icon(
                                                isLiked ? Icons.favorite : Icons.favorite_border,
                                                color: isLiked ? AppTheme.errorColor : Colors.black54,
                                              ),
                                              onPressed: () => _toggleLike(post.postId),
                                            );
                                          },
                                        ),
                                        StreamBuilder<int>(
                                          stream: _controller.getLikeCountStream(post.postId),
                                          builder: (context, snapshot) {
                                            final likeCount = snapshot.data ?? 0;
                                            return Text('$likeCount', style: GoogleFonts.poppins());
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppTheme.secondaryColor,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreatePostScreen()),
            );
          },
          child: const Icon(Icons.add, color: AppTheme.white),
        ),
      ),
    );
  }
}