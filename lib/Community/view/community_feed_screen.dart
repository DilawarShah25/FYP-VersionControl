import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
        const SnackBar(
          content: Text('Please log in to like posts'),
          backgroundColor: Color(0xFFD32F2F),
          duration: Duration(seconds: 3),
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
          const SnackBar(
            content: Text('Post unliked'),
            backgroundColor: Color(0xFFFF6D00),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        await _controller.likePost(postId, user.uid);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post liked'),
            backgroundColor: Color(0xFFFF6D00),
            duration: Duration(seconds: 2),
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
          content: Text(errorMsg),
          backgroundColor: const Color(0xFFD32F2F),
          duration: const Duration(seconds: 5),
        ),
      );
      debugPrint('Error toggling like for post $postId by user ${user.uid}: $e');
    }
  }

  Future<void> _refreshFeed() async {
    setState(() => _errorMessage = null);
    // StreamBuilder will automatically refresh the feed via the controller's stream
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        body: Stack(
          children: [
            _buildBackground(),
            SafeArea(
              child: Column(
                children: [
                  _buildAppBar(),
                  if (_errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      color: const Color(0xFFD32F2F),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _refreshFeed,
                      color: const Color(0xFFFF6D00),
                      child: StreamBuilder<List<PostModel>>(
                        stream: _controller.getPosts(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6D00)),
                              ),
                            );
                          }
                          if (snapshot.hasError) {
                            debugPrint('Error fetching posts: ${snapshot.error}');
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Color(0xFFD32F2F),
                                    size: 48,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Error loading posts: ${snapshot.error}',
                                    style: const TextStyle(
                                      color: Color(0xFFD32F2F),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  Semantics(
                                    label: 'Retry Button',
                                    child: ElevatedButton(
                                      onPressed: _refreshFeed,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFF6D00),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                      ),
                                      child: const Text(
                                        'Retry',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          final posts = snapshot.data ?? [];
                          if (posts.isEmpty) {
                            return const Center(
                              child: Text(
                                'No posts available.\nBe the first to share!',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: posts.length,
                            itemBuilder: (context, index) {
                              final post = posts[index];
                              return _buildPostCard(post);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: Semantics(
          label: 'Create New Post Button',
          child: FloatingActionButton(
            backgroundColor: const Color(0xFFFF6D00),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreatePostScreen()),
              );
            },
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE6E0), Color(0xFFFFF3F0)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            left: -50,
            child: CircleAvatar(
              radius: 100,
              backgroundColor: const Color(0xFFFFD6CC).withOpacity(0.5),
            ),
          ),
          Positioned(
            bottom: -70,
            right: -70,
            child: CircleAvatar(
              radius: 120,
              backgroundColor: const Color(0xFFFFD6CC).withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF6D00), Color(0xFFFF8A50)],
        ),
      ),
      child: const Row(
        // mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Share Your Experience',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(PostModel post) {
    final user = FirebaseAuth.instance.currentUser;
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Semantics(
                    label: 'View User Profile',
                    child: GestureDetector(
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
                        backgroundColor: const Color(0xFFE0E0E0),
                        backgroundImage: post.userProfileImage != null && post.userProfileImage!.isNotEmpty
                            ? MemoryImage(base64Decode(post.userProfileImage!))
                            : null,
                        child: post.userProfileImage == null || post.userProfileImage!.isEmpty
                            ? Text(
                          post.userName.isNotEmpty ? post.userName[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            color: Color(0xFF212121),
                            fontWeight: FontWeight.bold,
                          ),
                        )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      post.userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF212121),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                post.textContent,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF212121),
                ),
              ),
              if (post.imageBase64 != null && post.imageBase64!.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    base64Decode(post.imageBase64!),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('Image decode error: $error');
                      return const Icon(
                        Icons.error_outline,
                        color: Color(0xFFD32F2F),
                        size: 32,
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
                      StreamBuilder<bool>(
                        stream: user != null
                            ? _controller.hasLikedPostStream(post.postId, user.uid)
                            : Stream.value(false),
                        builder: (context, snapshot) {
                          final isLiked = snapshot.data ?? false;
                          return Semantics(
                            label: isLiked ? 'Unlike Post' : 'Like Post',
                            child: IconButton(
                              icon: Icon(
                                isLiked ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined,
                                color: isLiked ? const Color(0xFFD32F2F) : Colors.black54,
                              ),
                              onPressed: () => _toggleLike(post.postId),
                            ),
                          );
                        },
                      ),
                      StreamBuilder<int>(
                        stream: _controller.getLikeCountStream(post.postId),
                        builder: (context, snapshot) {
                          final likeCount = snapshot.data ?? 0;
                          return Text(
                            '$likeCount',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF212121),
                            ),
                          );
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
  }
}