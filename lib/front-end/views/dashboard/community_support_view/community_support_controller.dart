import 'package:flutter/material.dart';
import 'community_support_model.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CommunitySupportController extends ChangeNotifier {
  final TextEditingController postController = TextEditingController();
  final List<Post> posts = [];
  final List<File> images = [];
  final String currentUser = "currentUser"; // Placeholder for the current user

  void addPost() {
    if (postController.text.isNotEmpty || images.isNotEmpty) {
      posts.add(Post(
        username: currentUser,
        content: postController.text,
        images: images,
        timestamp: DateTime.now(),
      ));
      postController.clear();
      images.clear();
      notifyListeners();
    }
  }

  Future<void> addImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? pickedFiles = await picker.pickMultiImage();

    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      images.addAll(pickedFiles.map((xfile) => File(xfile.path)).toList());
      notifyListeners();
    }
  }
}
