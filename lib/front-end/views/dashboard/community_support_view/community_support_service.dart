import 'package:http/http.dart' as http;
import 'dart:convert';
import 'community_support_model.dart';

class CommunitySupportService {
  final String apiUrl = 'https://api.example.com/posts';

  Future<List<Post>> fetchPosts() async {
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Post.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load posts');
    }
  }

  Future<void> addPost(Post post) async {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(post.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add post');
    }
  }
}
