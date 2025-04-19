import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/app_theme.dart';
import '../controllers/community_controller.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final CommunityController _controller = CommunityController();
  final TextEditingController _textController = TextEditingController();
  XFile? _image;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = pickedFile);
    }
  }

  Future<String?> _fetchUserNameFromFirestore(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['name']?.toString().trim();
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user name from Firestore: $e');
      return null;
    }
  }

  Future<void> _updateUserProfileName(String name, String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': name,
        'email': FirebaseAuth.instance.currentUser?.email ?? '',
        'role': 'User',
        'showContactDetails': true,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('User profile name updated in Firestore: $name');
    } catch (e) {
      debugPrint('Failed to update user profile name: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update name: $e', style: GoogleFonts.poppins()),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      throw e;
    }
  }

  Future<bool> _promptForName() async {
    final nameController = TextEditingController();
    bool nameSet = false;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Set Your Name', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              hintText: 'Enter your full name',
              hintStyle: GoogleFonts.poppins(),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.poppins(color: AppTheme.primaryColor)),
            ),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  try {
                    await _updateUserProfileName(name, FirebaseAuth.instance.currentUser!.uid);
                    nameSet = true;
                    Navigator.pop(context);
                  } catch (e) {
                    // Error handling is done in _updateUserProfileName
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter a valid name', style: GoogleFonts.poppins()),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              },
              child: Text('Save', style: GoogleFonts.poppins(color: AppTheme.primaryColor)),
            ),
          ],
        );
      },
    );

    return nameSet;
  }

  Future<void> _submitPost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('Redirecting to login: User not authenticated');
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    final trimmedText = _textController.text.trim();
    String? userName = await _fetchUserNameFromFirestore(user.uid);

    if (trimmedText.isEmpty && _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please add text or an image', style: GoogleFonts.poppins()),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (userName == null || userName.isEmpty) {
      bool nameSet = await _promptForName();
      if (!nameSet) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please set your name in profile to create a post', style: GoogleFonts.poppins()),
            backgroundColor: AppTheme.errorColor,
            action: SnackBarAction(
              label: 'Go to Profile',
              onPressed: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
          ),
        );
        return;
      }
      userName = await _fetchUserNameFromFirestore(user.uid) ?? '';
    }

    try {
      await _controller.createPost(
        textContent: trimmedText.isEmpty ? ' ' : trimmedText,
        image: _image,
        userName: userName,
        userProfileImage: user.photoURL,
      );
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Post created successfully', style: GoogleFonts.poppins()),
          backgroundColor: AppTheme.secondaryColor,
        ),
      );
    } catch (e) {
      debugPrint('Failed to create post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create post: $e', style: GoogleFonts.poppins()),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Create Post',
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
        elevation: 0,
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
                decoration: const InputDecoration(
                  hintText: 'What’s on your mind?',
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppTheme.paddingMedium),
              if (_image != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_image!.path),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('Image load error: $error');
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
                  foregroundColor: AppTheme.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: AppTheme.paddingMedium),
              ElevatedButton.icon(
                onPressed: _submitPost,
                icon: const Icon(Icons.publish, color: AppTheme.white),
                label: const Text('Post'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppTheme.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
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