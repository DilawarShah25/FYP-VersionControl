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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), // Change back button color to white
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(top: 5.0), // Remove padding between appbar and content
            child: Container(
              width: double.infinity, // Ensure full width
              decoration: const BoxDecoration(
                color: Colors.white, // Set background color to white
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title with a larger size and bold style
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0), // Ensure left and right padding
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24, // Larger title size
                      ),
                    ),
                  ),
                  const SizedBox(height: 5.0), // Space between title and image
                  // Image below the title
                  Center(
                    child: SizedBox(
                      // width: double.infinity,
                      width: 330,
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20), // Space between image and content
                  // Markdown formatted content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0), // Add padding to content
                    child: MarkdownBody(
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
