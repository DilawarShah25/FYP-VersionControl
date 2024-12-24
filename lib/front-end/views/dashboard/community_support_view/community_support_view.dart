import 'package:flutter/material.dart';
import 'community_support_controller.dart';
import 'community_support_widgets.dart';

class CommunitySupportView extends StatefulWidget {
  const CommunitySupportView({super.key});

  @override
  _CommunitySupportViewState createState() => _CommunitySupportViewState();
}

class _CommunitySupportViewState extends State<CommunitySupportView> {
  final CommunitySupportController _controller = CommunitySupportController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Support'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Text Input for Post
            PostInputField(
              controller: _controller.postController,
              onImageUpload: _controller.addImages,
              images: _controller.images,
            ),
            const SizedBox(height: 10),
            // Submit Button
            ElevatedButton(
              onPressed: _controller.addPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Post',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // List of Posts
            Expanded(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return PostList(posts: _controller.posts, currentUser: _controller.currentUser);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
