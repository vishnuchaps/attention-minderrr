import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/post.dart';

class ApiService {
  Future<List<Post>> fetchPosts() async {
    final response = await http.get(
      Uri.parse('https://dummy-json.mock.beeceptor.com/posts'),
    );

    final List data = json.decode(response.body);
    return data.map((e) => Post.fromJson(e)).toList();
  }
}
