import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  void initState() {
    super.initState();
    if (widget.post != null) {
      _textController.text = widget.post!.textContent;
      if (widget.post!.imageBase64 != null) {
        // Note: Editing existing image requires re-uploading
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = pickedFile);
    }
  }

  Future<String?> _fetchUserName() async {
    try {
      final profile = await _service.getUserProfile(FirebaseAuth.instance.currentUser!.uid);
      return profile?.username?.trim() ?? profile?.name?.trim();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please add text or an image', style: GoogleFonts.poppins()),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userName = await _fetchUserName();
      if (userName == null || userName.isEmpty) {
        throw Exception('User name not set');
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
          content: Text(widget.post == null ? 'Post created successfully' : 'Post updated successfully',
              style: GoogleFonts.poppins()),
          backgroundColor: AppTheme.secondaryColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to ${widget.post == null ? 'create' : 'update'} post: $e',
              style: GoogleFonts.poppins()),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.post == null ? 'Create Post' : 'Edit Post',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.white),
          onPressed: () => Navigator.pop(context),
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
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _textController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'What’s on your mind?',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                style: GoogleFonts.poppins(fontSize: 16),
              ),
              const SizedBox(height: AppTheme.paddingMedium),
              if (_image != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_image!.path),
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('Image load error: $error');
                      return const Icon(Icons.error, color: AppTheme.errorColor);
                    },
                  ),
                ),
              if (widget.post?.imageBase64 != null && _image == null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    base64Decode(widget.post!.imageBase64!),
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('Image decode error: $error');
                      return const Icon(Icons.error, color: AppTheme.errorColor);
                    },
                  ),
                ),
              const SizedBox(height: AppTheme.paddingMedium),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image, color: AppTheme.white),
                label: const Text('Add Image'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: AppTheme.paddingMedium),
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor))
                  : ElevatedButton.icon(
                onPressed: _submitPost,
                icon: const Icon(Icons.publish, color: AppTheme.white),
                label: Text(widget.post == null ? 'Post' : 'Update'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
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