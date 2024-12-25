import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // Import the markdown package

class DetailScreen extends StatelessWidget {
  final String title;
  final String imagePath;
  final String content;

  const DetailScreen({
    super.key,
    required this.title,
    required this.imagePath,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF004e92),
                Color(0xFF000428),
              ],
            ),
          ),
        ),
        title: const Text(
          'Blog',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 36,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            color: Colors.white, // Set background color to white
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title with a larger size and bold style
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24, // Larger title size
                  ),
                ),
                const SizedBox(height: 20), // Space between title and image

                // Image below the title
                Image.asset(imagePath),

                const SizedBox(height: 20), // Space between image and content

                // Markdown formatted content
                MarkdownBody(
                  data: content,
                  styleSheet: MarkdownStyleSheet(
                    h1: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    h2: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    h3: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    p: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                    blockquote: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
