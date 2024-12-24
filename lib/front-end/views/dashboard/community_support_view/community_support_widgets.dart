import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'community_support_model.dart';

class PostInputField extends StatelessWidget {
  final TextEditingController controller;
  final Future<void> Function() onImageUpload;
  final List<File> images;

  const PostInputField({super.key, required this.controller, required this.onImageUpload, required this.images});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Write your post here...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: onImageUpload,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Upload Images',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (images.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.file(
                    images[index],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class PostList extends StatelessWidget {
  final List<Post> posts;
  final String currentUser;

  const PostList({super.key, required this.posts, required this.currentUser});

  String _formatTimestamp(DateTime timestamp) {
    return "${timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12}:${timestamp.minute.toString().padLeft(2, '0')} ${timestamp.hour >= 12 ? 'PM' : 'AM'}";
  }

  @override
  Widget build(BuildContext context) {
    return posts.isNotEmpty
        ? ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final bool isCurrentUser = post.username == currentUser;
        return Container(
          alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Stack(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isCurrentUser ? Colors.lightGreen[100] : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 5,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isCurrentUser)
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Text(
                              post.username[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            post.username,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    if (!isCurrentUser) const SizedBox(height: 10),
                    Text(post.content),
                    if (post.images.isNotEmpty)
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: post.images.length,
                          itemBuilder: (context, imgIndex) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.file(
                                post.images[imgIndex],
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            );
                          },
                        ),
                      ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        _formatTimestamp(post.timestamp),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: -10,
                left: isCurrentUser ? null : 10,
                right: isCurrentUser ? 10 : null,
                child: CustomPaint(
                  painter: ChatBubbleArrowPainter(isCurrentUser: isCurrentUser),
                ),
              ),
            ],
          ),
        );
      },
    )
        : const Center(
      child: Text(
        'No posts yet. Be the first to post!',
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }
}

class ChatBubbleArrowPainter extends CustomPainter {
  final bool isCurrentUser;

  ChatBubbleArrowPainter({required this.isCurrentUser});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isCurrentUser ? Colors.lightGreen[100]! : Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    if (isCurrentUser) {
      path.moveTo(size.width, size.height);
      path.lineTo(size.width - 10, size.height - 10);
      path.lineTo(size.width, size.height - 20);
    } else {
      path.moveTo(0, size.height);
      path.lineTo(10, size.height - 10);
      path.lineTo(0, size.height - 20);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
