class BlogResponse {
  final bool? status;
  final int? statusCode;
  final String? message;
  final BlogData? data;
  final Map<String, dynamic>? errors;

  BlogResponse({
    this.status,
    this.statusCode,
    this.message,
    this.data,
    this.errors,
  });

  factory BlogResponse.fromJson(Map<String, dynamic> json) {
    return BlogResponse(
      status: json['status'],
      statusCode: json['status_code'],
      message: json['message'],
      data: json['data'] != null ? BlogData.fromJson(json['data']) : null,
      errors: json['errors'],
    );
  }
}

class BlogData {
  final Links? links;
  final int? count;
  final List<Blog>? results;
  final Map<String, dynamic>? heading;

  BlogData({this.links, this.count, this.results, this.heading});

  factory BlogData.fromJson(Map<String, dynamic> json) {
    return BlogData(
      links: json['links'] != null ? Links.fromJson(json['links']) : null,
      count: json['count'],
      results: (json['results'] as List?)
          ?.map((e) => Blog.fromJson(e))
          .toList(),
      heading: json['heading'],
    );
  }
}

class Links {
  final String? next;
  final String? previous;

  Links({this.next, this.previous});

  factory Links.fromJson(Map<String, dynamic> json) {
    return Links(next: json['next'], previous: json['previous']);
  }
}

class Blog {
  final int? id;
  final String? title;
  final String? slug;
  final String? shortDescription;
  final String? content;
  final String? featuredImage;
  final int? author;
  final String? authorName;
  final String? status;
  final bool? isFeatured;
  final int? viewsCount;
  final String? publishedAt;
  final String? createdAt;
  final String? updatedAt;

  Blog({
    this.id,
    this.title,
    this.slug,
    this.shortDescription,
    this.content,
    this.featuredImage,
    this.author,
    this.authorName,
    this.status,
    this.isFeatured,
    this.viewsCount,
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Blog.fromJson(Map<String, dynamic> json) {
    return Blog(
      id: json['id'],
      title: json['title'],
      slug: json['slug'],
      shortDescription: json['short_description'],
      content: json['content'],
      featuredImage: json['featured_image'],
      author: json['author'],
      authorName: json['author_name'],
      status: json['status'],
      isFeatured: json['is_featured'],
      viewsCount: json['views_count'],
      publishedAt: json['published_at'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}
