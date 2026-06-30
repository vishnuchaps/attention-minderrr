import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../model/post.dart';
import '../service/api_service.dart';

class PostProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final String boxName = 'postsBox';

  List<Post> posts = [];
  bool loading = false;

  Future<void> loadPosts() async {
    loading = true;
    notifyListeners();

    final box = Hive.box<Post>(boxName);

    if (box.isNotEmpty) {
      posts = box.values.toList();
    } else {
      final apiData = await _api.fetchPosts();
      for (var post in apiData) {
        box.put(post.id, post);
      }
      posts = apiData;
    }

    loading = false;
    notifyListeners();
  }

  Future<void> clearDbAndReload() async {
    final box = Hive.box<Post>(boxName);
    await box.clear();
    await loadPosts();
  }
}
