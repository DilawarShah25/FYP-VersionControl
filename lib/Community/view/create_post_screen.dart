import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/app_theme.dart';
import '../controllers/community_controller.dart';
import '../models/post_model.dart';
import '../services/community_firebase_service.dart';

class CreatePostScreen extends StatefulWidget {
  final PostModel? post;

  const CreatePostScreen({super.key, this.post});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final CommunityController _controller = CommunityController();
  final CommunityFirebaseService _service = CommunityFirebaseService();
  final TextEditingController _textController = TextEditingController();
  XFile? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String? _errorMessage;
  static const int _maxTextLength = 500;

  @override
  void initState() {
    super.initState();
    if (widget.post != null) {
      _textController.text = widget.post!.textContent;
    }
    _textController.addListener(() {
      setState(() {}); // Update character count
    });
  }

  Future<void> _pickImage() async {
    try {
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Image Source'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, ImageSource.gallery),
              child: const Text('Gallery'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, ImageSource.camera),
              child: const Text('Camera'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (source == null) return;

      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        if (bytes.length > 2 * 1024 * 1024) {
          setState(() {
            _errorMessage = 'Image size exceeds 2MB';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image size exceeds 2MB'),
              backgroundColor: Color(0xFFD32F2F),
            ),
          );
          return;
        }
        setState(() {
          _image = pickedFile;
          _errorMessage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image selected'),
            backgroundColor: Color(0xFFFF6D00),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      setState(() {
        _errorMessage = 'Error picking image';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error picking image'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
    }
  }

  Future<void> _removeImage() async {
    setState(() {
      _image = null;
      _errorMessage = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image removed'),
        backgroundColor: Color(0xFFFF6D00),
      ),
    );
  }

  Future<String?> _fetchUserName() async {
    try {
      final profile = await _service.getUserProfile(FirebaseAuth.instance.currentUser!.uid);
      return profile?.username?.trim() ?? profile?.name.trim();
    } catch (e) {
      debugPrint('Error fetching user name: $e');
      return null;
    }
  }

  Future<void> _submitPost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    final trimmedText = _textController.text.trim();
    if (trimmedText.isEmpty && _image == null && widget.post == null) {
      setState(() {
        _errorMessage = 'Please add text or an image';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add text or an image'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userName = await _fetchUserName();
      if (userName == null || userName.isEmpty) {
        throw Exception('User name not set. Please update your profile.');
      }

      if (widget.post == null) {
        await _controller.createPost(
          textContent: trimmedText.isEmpty ? ' ' : trimmedText,
          image: _image,
          userName: userName,
          userProfileImage: user.photoURL,
        );
      } else {
        await _controller.updatePost(
          widget.post!.postId,
          trimmedText.isEmpty ? ' ' : trimmedText,
          _image,
        );
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.post == null ? 'Post created successfully' : 'Post updated successfully'),
          backgroundColor: const Color(0xFFFF6D00),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to ${widget.post == null ? 'create' : 'update'} post: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to ${widget.post == null ? 'create' : 'update'} post: $e'),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTextField(),
                          const SizedBox(height: 16),
                          _buildImagePreview(),
                          const SizedBox(height: 16),
                          _buildPickImageButton(),
                          const SizedBox(height: 16),
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Color(0xFFD32F2F),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          _buildSubmitButton(),
                        ],
                      ),
                    ),
                  ),
                ],
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
          Text(
            widget.post == null ? 'Create Post' : 'Edit Post',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 48), // Spacer for symmetry
        ],
      ),
    );
  }

  Widget _buildTextField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          TextField(
            controller: _textController,
            maxLines: 5,
            maxLength: _maxTextLength,
            decoration: const InputDecoration(
              hintText: 'What’s on your mind?',
              hintStyle: TextStyle(color: Color(0xFF757575), fontSize: 16),
              border: InputBorder.none,
              contentPadding: EdgeInsets.fromLTRB(16, 12, 16, 40),
              counterText: '', // Hide default counter
            ),
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF212121),
            ),
            textInputAction: TextInputAction.done,
          ),
          Positioned(
            bottom: 8,
            right: 16,
            child: Text(
              '${_textController.text.length}/$_maxTextLength',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF757575),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_image != null) {
      return Stack(
        alignment: Alignment.topRight,
        children: [
          Semantics(
            label: 'Selected Image Preview',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(_image!.path),
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Image load error: $error');
                  return const Icon(
                    Icons.error_outline,
                    color: Color(0xFFD32F2F),
                    size: 32,
                  );
                },
              ),
            ),
          ),
          Semantics(
            label: 'Remove Image Button',
            child: IconButton(
              icon: const Icon(Icons.cancel, color: Color(0xFFD32F2F)),
              onPressed: _removeImage,
              tooltip: 'Remove Image',
            ),
          ),
        ],
      );
    } else if (widget.post?.imageBase64 != null && _image == null) {
      return Stack(
        alignment: Alignment.topRight,
        children: [
          Semantics(
            label: 'Existing Post Image Preview',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                base64Decode(widget.post!.imageBase64!),
                width: double.infinity,
                fit: BoxFit.cover,
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
          ),
          Semantics(
            label: 'Remove Image Button',
            child: IconButton(
              icon: const Icon(Icons.cancel, color: Color(0xFFD32F2F)),
              onPressed: _removeImage,
              tooltip: 'Remove Image',
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildPickImageButton() {
    return Semantics(
      label: 'Add Image Button',
      child: ElevatedButton.icon(
        onPressed: _pickImage,
        icon: const Icon(Icons.image, color: Colors.white),
        label: const Text(
          'Add Image',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6D00),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return _isLoading
        ? const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6D00)),
      ),
    )
        : Semantics(
      label: widget.post == null ? 'Create Post Button' : 'Update Post Button',
      child: ElevatedButton.icon(
        onPressed: _submitPost,
        icon: const Icon(Icons.publish, color: Colors.white),
        label: Text(
          widget.post == null ? 'Post' : 'Update',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6D00),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}