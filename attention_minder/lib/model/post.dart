import 'package:hive/hive.dart';

part 'post.g.dart';

@HiveType(typeId: 0)
class Post {
  @HiveField(0)
  final int userId;

  @HiveField(1)
  final int id;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String body;

  @HiveField(4)
  final String link;

  @HiveField(5)
  final int commentCount;

  Post({
    required this.userId,
    required this.id,
    required this.title,
    required this.body,
    required this.link,
    required this.commentCount,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      userId: json['userId'],
      id: json['id'],
      title: json['title'],
      body: json['body'],
      link: json['link'],
      commentCount: json['comment_count'],
    );
  }
}
