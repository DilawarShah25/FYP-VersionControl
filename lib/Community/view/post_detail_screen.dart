import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import '../../views/authentication/login_view.dart';
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
  User? _user; // Class-level variable for the current user
  bool _isLiked = false;
  int _likeCount = 0;
  bool _isLoading = false;
  String? _errorMessage;
  static const int _maxCommentLength = 500;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser; // Initialize user at the class level
    _initialize();
    _commentController.addListener(() {
      setState(() {}); // Update character count
    });
  }

  Future<void> _initialize() async {
    if (_user == null) return;
    setState(() => _isLoading = true);
    try {
      _isLiked = await _controller.hasLikedPost(widget.post.postId, _user!.uid);
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
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        backgroundColor: isError ? const Color(0xFFD32F2F) : const Color(0xFFFF6D00),
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
    if (_user == null) {
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
        await _controller.likePost(widget.post.postId, _user!.uid);
      } else {
        await _controller.unlikePost(widget.post.postId, _user!.uid);
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
        debugPrint('Error toggling like for post ${widget.post.postId} by user ${_user!.uid}: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addComment() async {
    if (_user == null) {
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
    if (commentText.length > _maxCommentLength) {
      if (mounted) {
        _showSnackBar(context, 'Comment exceeds $_maxCommentLength characters.', isError: true);
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String commenterUserName = 'Anonymous';
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
      if (userDoc.exists) {
        commenterUserName = userDoc.data()?['username'] ?? userDoc.data()?['name'] ?? 'Anonymous';
      }
    } catch (e) {
      debugPrint('Error fetching commenter username for user ${_user!.uid}: $e');
      if (mounted) {
        _showSnackBar(context, 'Error fetching username, using default.', isError: true);
      }
    }

    final optimisticComment = CommentModel(
      commentId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      userId: _user!.uid,
      userName: commenterUserName,
      commentText: commentText,
      timestamp: Timestamp.now(),
    );
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
        userId: _user!.uid,
      );
      _commentController.clear();
      if (mounted) {
        _showSnackBar(context, 'Comment added');
      }
      removeOptimisticComment(optimisticComment.commentId);
    } catch (e) {
      setState(() => _errorMessage = 'Error adding comment: $e');
      if (mounted) {
        _showSnackBar(context, 'Error adding comment: $e', isError: true);
        debugPrint('Error adding comment to post ${widget.post.postId} by user ${_user!.uid}: $e');
      }
      removeOptimisticComment(optimisticComment.commentId);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePost() async {
    try {
      await _controller.deletePost(widget.post.postId);
      if (mounted) {
        _showSnackBar(context, 'Post deleted');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(context, 'Error deleting post: $e', isError: true);
        debugPrint('Error deleting post ${widget.post.postId}: $e');
      }
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await _controller.deleteComment(widget.post.postId, commentId);
      if (mounted) {
        _showSnackBar(context, 'Comment deleted');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(context, 'Error deleting comment: $e', isError: true);
        debugPrint('Error deleting comment $commentId: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSnackBar(context, 'Please log in.', isError: true);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginView()));
      });
      return const SizedBox();
    }

    final isOwnPost = widget.post.userId == _user!.uid;

    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        backgroundColor: Colors.white,
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              if (_errorMessage!.contains('like')) {
                                _toggleLike();
                              } else if (_errorMessage!.contains('comment')) {
                                _addComment();
                              }
                            },
                            child: const Text(
                              'Retry',
                              style: TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPostCard(isOwnPost),
                            const SizedBox(height: 16),
                            _buildCommentsSection(),
                            const SizedBox(height: 16),
                            _buildCommentInput(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6D00)),
                  ),
                ),
              ),
          ],
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Semantics(
            label: 'Back Button',
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Back',
            ),
          ),
          const Text(
            'Post Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 48), // Spacer for symmetry
        ],
      ),
    );
  }

  Widget _buildPostCard(bool isOwnPost) {
    return Semantics(
      label: 'Post Content',
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Semantics(
                  label: 'User Profile',
                  child: GestureDetector(
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
                      backgroundColor: const Color(0xFFE0E0E0),
                      backgroundImage: _buildProfileImage(widget.post.userProfileImage),
                      child: widget.post.userProfileImage == null || widget.post.userProfileImage!.isEmpty
                          ? Text(
                        widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Color(0xFFFF6D00),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF212121),
                        ),
                      ),
                      Semantics(
                        label: 'Post Timestamp',
                        child: Text(
                          DateFormat('MMM dd, yyyy, hh:mm a').format(widget.post.timestamp.toDate()),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF757575),
                          ),
                        ),
                      ),
                      if (widget.post.lastEdited != null)
                        Semantics(
                          label: 'Post Edited Timestamp',
                          child: Text(
                            'Edited: ${DateFormat('MMM dd, yyyy, hh:mm a').format(widget.post.lastEdited!.toDate())}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF757575),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (isOwnPost)
                  Semantics(
                    label: 'Post Options',
                    child: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreatePostScreen(post: widget.post),
                            ),
                          );
                        } else if (value == 'delete') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Post'),
                              content: const Text('Are you sure you want to delete this post?'),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete', style: TextStyle(color: Color(0xFFD32F2F))),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await _deletePost();
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                      icon: const Icon(Icons.more_vert, color: Color(0xFF757575)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.post.textContent,
              style: const TextStyle(fontSize: 16, color: Color(0xFF212121)),
            ),
            if (widget.post.imageBase64 != null && widget.post.imageBase64!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Semantics(
                label: 'Post Image',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    base64Decode(widget.post.imageBase64!),
                    fit: BoxFit.contain,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('Image decode error: $error');
                      return Container(
                        height: 200,
                        color: const Color(0xFFE0E0E0),
                        child: const Icon(Icons.error, color: Color(0xFFD32F2F)),
                      );
                    },
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Semantics(
                      label: 'Like Button',
                      child: StreamBuilder<bool>(
                        stream: _controller.hasLikedPostStream(widget.post.postId, _user!.uid),
                        builder: (context, snapshot) {
                          final isLiked = snapshot.data ?? _isLiked;
                          return IconButton(
                            icon: Icon(
                              isLiked ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined,
                              color: isLiked ? const Color(0xFFD32F2F) : const Color(0xFF757575),
                            ),
                            onPressed: _toggleLike,
                          );
                        },
                      ),
                    ),
                    Semantics(
                      label: 'Like Count',
                      child: StreamBuilder<int>(
                        stream: _controller.getLikeCountStream(widget.post.postId),
                        builder: (context, snapshot) {
                          final likeCount = snapshot.data ?? _likeCount;
                          return Text(
                            '$likeCount',
                            style: const TextStyle(fontSize: 14, color: Color(0xFF757575)),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Semantics(
                      label: 'Comment Button',
                      child: IconButton(
                        icon: const Icon(Icons.comment, color: Color(0xFF757575)),
                        onPressed: () {
                          _commentController.clear();
                          FocusScope.of(context).requestFocus(FocusNode());
                        },
                      ),
                    ),
                    Semantics(
                      label: 'Comment Count',
                      child: StreamBuilder<List<CommentModel>>(
                        stream: _controller.getComments(widget.post.postId),
                        builder: (context, snapshot) {
                          final commentCount = (snapshot.data?.length ?? 0) + optimisticComments.length;
                          return Text(
                            '$commentCount',
                            style: const TextStyle(fontSize: 14, color: Color(0xFF757575)),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Semantics(
      label: 'Comments Section',
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<CommentModel>>(
              stream: _controller.getComments(widget.post.postId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6D00)),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  debugPrint('Error fetching comments for post ${widget.post.postId}: ${snapshot.error}');
                  return Column(
                    children: [
                      Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Color(0xFFD32F2F), fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Semantics(
                        label: 'Retry Comments Button',
                        child: ElevatedButton(
                          onPressed: () => setState(() {}),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6D00),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          child: const Text('Retry'),
                        ),
                      ),
                    ],
                  );
                }
                final comments = (snapshot.data ?? []) + optimisticComments;
                if (comments.isEmpty) {
                  return const Text(
                    'No comments yet.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF757575)),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final isOwnComment = comment.userId == _user!.uid;
                    return Semantics(
                      label: 'Comment',
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(0xFFE0E0E0),
                          child: Text(
                            comment.userName.isNotEmpty ? comment.userName[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              color: Color(0xFFFF6D00),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        title: Text(
                          comment.userName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF212121),
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              comment.commentText,
                              style: const TextStyle(fontSize: 14, color: Color(0xFF212121)),
                            ),
                            Semantics(
                              label: 'Comment Timestamp',
                              child: Text(
                                DateFormat('MMM dd, yyyy, hh:mm a').format(comment.timestamp.toDate()),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF757575),
                                ),
                              ),
                            ),
                            if (comment.editedAt != null)
                              Semantics(
                                label: 'Comment Edited Timestamp',
                                child: Text(
                                  'Edited: ${DateFormat('MMM dd, yyyy, hh:mm a').format(comment.editedAt!.toDate())}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF757575),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        trailing: isOwnComment
                            ? Semantics(
                          label: 'Comment Options',
                          child: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                final editController = TextEditingController(text: comment.commentText);
                                await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Edit Comment'),
                                    content: TextField(
                                      controller: editController,
                                      maxLength: _maxCommentLength,
                                      decoration: InputDecoration(
                                        hintText: 'Edit your comment',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        counterText: '',
                                      ),
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          final text = editController.text.trim();
                                          if (text.isNotEmpty) {
                                            try {
                                              await _controller.updateComment(widget.post.postId, comment.commentId, text);
                                              if (mounted) {
                                                Navigator.pop(context);
                                                _showSnackBar(context, 'Comment updated');
                                              }
                                            } catch (e) {
                                              if (mounted) {
                                                _showSnackBar(context, 'Error updating comment: $e', isError: true);
                                                debugPrint('Error updating comment ${comment.commentId}: $e');
                                              }
                                            }
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFFF6D00),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                        ),
                                        child: const Text('Save'),
                                      ),
                                    ],
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                              } else if (value == 'delete') {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Comment'),
                                    content: const Text('Are you sure you want to delete this comment?'),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Delete', style: TextStyle(color: Color(0xFFD32F2F))),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await _deleteComment(comment.commentId);
                                }
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'edit', child: Text('Edit')),
                              const PopupMenuItem(value: 'delete', child: Text('Delete')),
                            ],
                            icon: const Icon(Icons.more_vert, color: Color(0xFF757575)),
                          ),
                        )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInput() {
    return Semantics(
      label: 'Comment Input',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        child: Row(
          children: [
            Expanded(
              child: Stack(
                children: [
                  TextField(
                    controller: _commentController,
                    maxLength: _maxCommentLength,
                    decoration: const InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: TextStyle(color: Color(0xFF757575), fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.fromLTRB(8, 12, 8, 24),
                      counterText: '',
                    ),
                    style: const TextStyle(fontSize: 14, color: Color(0xFF212121)),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (value) => _addComment(),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 8,
                    child: Text(
                      '${_commentController.text.length}/$_maxCommentLength',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Semantics(
              label: 'Send Comment Button',
              child: IconButton(
                icon: const Icon(Icons.send, color: Color(0xFFFF6D00)),
                onPressed: _isLoading ? null : _addComment,
                tooltip: 'Send',
              ),
            ),
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