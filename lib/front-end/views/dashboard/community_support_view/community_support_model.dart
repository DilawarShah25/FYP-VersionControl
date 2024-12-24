import 'dart:io';

class Post {
  final String username;
  final String content;
  final List<File> images;
  final DateTime timestamp;

  Post({required this.username, required this.content, required this.images, required this.timestamp});

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      username: json['username'],
      content: json['content'],
      images: (json['images'] as List).map((imagePath) => File(imagePath)).toList(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'content': content,
      'images': images.map((file) => file.path).toList(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
