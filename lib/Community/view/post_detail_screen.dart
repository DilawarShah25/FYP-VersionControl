import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import '../../views/dashboard/profile_view.dart';
import '../controllers/community_controller.dart';
import '../models/comment_model.dart';
import '../models/optimistic_comment_mixin.dart';
import '../models/post_model.dart';
import 'create_post_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final PostModel post;
  final String userName;

  const PostDetailScreen({super.key, required this.post, required this.userName});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> with OptimisticCommentMixin {
  final CommunityController _controller = CommunityController();
  final TextEditingController _commentController = TextEditingController();
  bool _isLiked = false;
  int _likeCount = 0;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _isLoading = true);
    try {
      _isLiked = await _controller.hasLikedPost(widget.post.postId, user.uid);
      _likeCount = await _controller.getLikeCount(widget.post.postId);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading like status: $e';
        debugPrint('Error initializing likes for post ${widget.post.postId}: $e');
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: AppTheme.white)),
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.primaryColor,
        duration: Duration(seconds: isError ? 5 : 3),
      ),
    );
  }

  ImageProvider? _buildProfileImage(String? base64String) {
    try {
      if (base64String == null || base64String.isEmpty || !RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(base64String)) {
        return null;
      }
      final bytes = base64Decode(base64String);
      return MemoryImage(bytes);
    } catch (e) {
      debugPrint('Error decoding profile image: $e');
      return null;
    }
  }

  Future<void> _toggleLike() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        _showSnackBar(context, 'Please log in to like posts.', isError: true);
      }
      return;
    }
    final wasLiked = _isLiked;
    setState(() {
      _isLoading = true;
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
      _errorMessage = null;
    });
    try {
      if (_isLiked) {
        await _controller.likePost(widget.post.postId, user.uid);
      } else {
        await _controller.unlikePost(widget.post.postId, user.uid);
      }
      if (mounted) {
        _showSnackBar(context, _isLiked ? 'Post liked' : 'Post unliked');
      }
    } catch (e) {
      setState(() {
        _isLiked = wasLiked;
        _likeCount += wasLiked ? 1 : -1;
        _errorMessage = 'Error liking/unliking post: $e';
      });
      if (mounted) {
        _showSnackBar(context, 'Error liking/unliking post: $e', isError: true);
        debugPrint('Error toggling like for post ${widget.post.postId} by user ${user.uid}: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addComment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        _showSnackBar(context, 'Please log in to comment.', isError: true);
      }
      return;
    }
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) {
      if (mounted) {
        _showSnackBar(context, 'Comment cannot be empty.', isError: true);
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Fetch the commenter's username from their profile
    String commenterUserName = 'Anonymous';
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        commenterUserName = userDoc.data()?['username'] ?? userDoc.data()?['name'] ?? 'Anonymous';
      }
    } catch (e) {
      debugPrint('Error fetching commenter username for user ${user.uid}: $e');
      if (mounted) {
        _showSnackBar(context, 'Error fetching username, using default.', isError: true);
      }
    }

    // Optimistic update
    final optimisticComment = CommentModel(
      commentId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      userId: user.uid,
      userName: commenterUserName,
      commentText: commentText,
      timestamp: Timestamp.now(),
    );
    // Use named parameters for addOptimisticComment
    addOptimisticComment(
      commentId: optimisticComment.commentId,
      userId: optimisticComment.userId,
      userName: optimisticComment.userName,
      commentText: optimisticComment.commentText,
    );

    try {
      await _controller.addComment(
        postId: widget.post.postId,
        commentText: commentText,
        userName: commenterUserName,
        userId: user.uid,
      );
      _commentController.clear();
      if (mounted) {
        _showSnackBar(context, 'Comment added');
      }
      removeOptimisticComment(optimisticComment.commentId); // Clear optimistic comment on success
    } catch (e) {
      setState(() => _errorMessage = 'Error adding comment: $e');
      if (mounted) {
        _showSnackBar(context, 'Error adding comment: $e', isError: true);
        debugPrint('Error adding comment to post ${widget.post.postId} by user ${user.uid}: $e');
      }
      removeOptimisticComment(optimisticComment.commentId); // Clear optimistic comment on failure
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSnackBar(context, 'Please log in.', isError: true);
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const SizedBox();
    }

    final isOwnPost = widget.post.userId == user.uid;

    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Post Details',
            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.white),
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.secondaryColor.withAlpha((0.8 * 255).round())],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(AppTheme.paddingSmall),
                        color: AppTheme.errorColor,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.poppins(color: AppTheme.white),
                              ),
                            ),
                            if (_errorMessage!.contains('Network error') ||
                                _errorMessage!.contains('Permission error') ||
                                _errorMessage!.contains('Failed to set username'))
                              TextButton(
                                onPressed: _addComment,
                                child: Text(
                                  'Retry',
                                  style: GoogleFonts.poppins(color: AppTheme.white),
                                ),
                              ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProfileView(userId: widget.post.userId, userName: widget.userName),
                              ),
                            );
                          },
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: AppTheme.accentColor,
                            backgroundImage: _buildProfileImage(widget.post.userProfileImage),
                            child: widget.post.userProfileImage == null || widget.post.userProfileImage!.isEmpty
                                ? Text(
                              widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : 'U',
                              style: GoogleFonts.poppins(color: AppTheme.primaryColor),
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
                                widget.userName,
                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                DateFormat('MMM dd, yyyy, hh:mm a').format(widget.post.timestamp.toDate()),
                                style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
                              ),
                              if (widget.post.lastEdited != null)
                                Text(
                                  'Edited: ${DateFormat('MMM dd, yyyy, hh:mm a').format(widget.post.lastEdited!.toDate())}',
                                  style: GoogleFonts.poppins(fontSize: 10, color: Colors.black54),
                                ),
                            ],
                          ),
                        ),
                        if (isOwnPost)
                          PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CreatePostScreen(post: widget.post),
                                  ),
                                );
                              } else if (value == 'delete') {
                                try {
                                  await _controller.deletePost(widget.post.postId);
                                  Navigator.pop(context);
                                  _showSnackBar(context, 'Post deleted');
                                } catch (e) {
                                  _showSnackBar(context, 'Error deleting post: $e', isError: true);
                                }
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'edit', child: Text('Edit')),
                              const PopupMenuItem(value: 'delete', child: Text('Delete')),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.paddingSmall),
                    Text(
                      widget.post.textContent,
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                    if (widget.post.imageBase64 != null && widget.post.imageBase64!.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.paddingSmall),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          base64Decode(widget.post.imageBase64!),
                          fit: BoxFit.contain,
                          width: double.infinity,
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            StreamBuilder<bool>(
                              stream: _controller.hasLikedPostStream(widget.post.postId, user.uid),
                              builder: (context, snapshot) {
                                final isLiked = snapshot.data ?? _isLiked;
                                return IconButton(
                                  icon: Icon(
                                    isLiked ? Icons.favorite : Icons.favorite_border,
                                    color: isLiked ? AppTheme.errorColor : Colors.black54,
                                  ),
                                  onPressed: _toggleLike,
                                );
                              },
                            ),
                            StreamBuilder<int>(
                              stream: _controller.getLikeCountStream(widget.post.postId),
                              builder: (context, snapshot) {
                                final likeCount = snapshot.data ?? _likeCount;
                                return Text('$likeCount', style: GoogleFonts.poppins());
                              },
                            ),
                            const SizedBox(width: AppTheme.paddingMedium),
                            IconButton(
                              icon: const Icon(Icons.comment, color: Colors.black54),
                              onPressed: () {},
                            ),
                            StreamBuilder<List<CommentModel>>(
                              stream: _controller.getComments(widget.post.postId),
                              builder: (context, snapshot) {
                                final commentCount = (snapshot.data?.length ?? 0) + optimisticComments.length;
                                return Text('$commentCount', style: GoogleFonts.poppins());
                              },
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.share, color: Colors.black54),
                          onPressed: () async {
                            try {
                              await _controller.sharePost(widget.post.postId, user.uid);
                              _showSnackBar(context, 'Post shared');
                            } catch (e) {
                              _showSnackBar(context, 'Error sharing post: $e', isError: true);
                            }
                          },
                        ),
                      ],
                    ),
                    const Divider(),
                    Text(
                      'Comments',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    StreamBuilder<List<CommentModel>>(
                      stream: _controller.getComments(widget.post.postId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
                        }
                        if (snapshot.hasError) {
                          debugPrint('Error fetching comments for post ${widget.post.postId}: ${snapshot.error}');
                          return Text('Error: ${snapshot.error}', style: GoogleFonts.poppins(color: AppTheme.errorColor));
                        }
                        final comments = (snapshot.data ?? []) + optimisticComments;
                        if (comments.isEmpty) {
                          return Text('No comments yet.', style: GoogleFonts.poppins());
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            final comment = comments[index];
                            final isOwnComment = comment.userId == user.uid;
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
                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(comment.commentText, style: GoogleFonts.poppins()),
                                  Text(
                                    DateFormat('MMM dd, yyyy, hh:mm a').format(comment.timestamp.toDate()),
                                    style: GoogleFonts.poppins(fontSize: 10, color: Colors.black54),
                                  ),
                                  if (comment.editedAt != null)
                                    Text(
                                      'Edited: ${DateFormat('MMM dd, yyyy, hh:mm a').format(comment.editedAt!.toDate())}',
                                      style: GoogleFonts.poppins(fontSize: 10, color: Colors.black54),
                                    ),
                                ],
                              ),
                              trailing: isOwnComment
                                  ? PopupMenuButton<String>(
                                onSelected: (value) async {
                                  if (value == 'edit') {
                                    final editController = TextEditingController(text: comment.commentText);
                                    await showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text('Edit Comment', style: GoogleFonts.poppins()),
                                        content: TextField(
                                          controller: editController,
                                          decoration: InputDecoration(
                                            hintText: 'Edit your comment',
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          style: GoogleFonts.poppins(),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: Text('Cancel', style: GoogleFonts.poppins()),
                                          ),
                                          ElevatedButton(
                                            onPressed: () async {
                                              final text = editController.text.trim();
                                              if (text.isNotEmpty) {
                                                try {
                                                  await _controller.updateComment(widget.post.postId, comment.commentId, text);
                                                  Navigator.pop(context);
                                                  _showSnackBar(context, 'Comment updated');
                                                } catch (e) {
                                                  _showSnackBar(context, 'Error updating comment: $e', isError: true);
                                                  debugPrint('Error updating comment ${comment.commentId}: $e');
                                                }
                                              }
                                            },
                                            child: Text('Save', style: GoogleFonts.poppins()),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else if (value == 'delete') {
                                    try {
                                      await _controller.deleteComment(widget.post.postId, comment.commentId);
                                      _showSnackBar(context, 'Comment deleted');
                                    } catch (e) {
                                      _showSnackBar(context, 'Error deleting comment: $e', isError: true);
                                      debugPrint('Error deleting comment ${comment.commentId}: $e');
                                    }
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                ],
                              )
                                  : null,
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: AppTheme.paddingMedium),
                    TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.send, color: AppTheme.primaryColor),
                          onPressed: _addComment,
                        ),
                      ),
                      style: GoogleFonts.poppins(),
                    ),
                    const SizedBox(height: AppTheme.paddingMedium),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}