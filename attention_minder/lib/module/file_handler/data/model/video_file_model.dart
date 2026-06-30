class VideoFileResponse {
  final String message;
  final bool status;
  final List<VideoFile> data;

  VideoFileResponse({
    required this.message,
    required this.status,
    required this.data,
  });

  factory VideoFileResponse.fromJson(Map<String, dynamic> json) {
    return VideoFileResponse(
      message: json['message']?.toString() ?? '',
      status: json['status'] == true,
      data:
          (json['data'] as List<dynamic>?)?.map((e) {
            if (e is String) return VideoFile.fromUrl(e);
            return VideoFile.fromJson(e as Map<String, dynamic>);
          }).toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'status': status,
      'data': data.map((e) => e.toJson()).toList(),
    };
  }
}

class VideoFile {
  final int? id;
  final bool isLocked;
  final String title;
  final String key;
  final String url;
  final bool isManagement;
  final String ageGroup;
  final int day;
  final String mediaType;
  final int orderNumber;
  final DateTime? createdAt;

  VideoFile({
    this.id,
    required this.isLocked,
    required this.title,
    required this.key,
    required this.url,
    required this.isManagement,
    required this.ageGroup,
    required this.day,
    required this.mediaType,
    required this.orderNumber,
    this.createdAt,
  });

  factory VideoFile.fromUrl(String url) {
    return VideoFile(
      id: null,
      isLocked: false,
      title: '',
      key: url,
      url: url,
      isManagement: false,
      ageGroup: '',
      day: 0,
      mediaType: _isPdfUrl(url) ? 'file' : 'video',
      orderNumber: 0,
      createdAt: null,
    );
  }

  factory VideoFile.fromJson(Map<String, dynamic> json) {
    final url = (json['url'] ?? json['file'] ?? '').toString();
    final key = (json['key'] ?? json['file'] ?? url).toString();

    final mediaType = _resolveMediaType(
      mediaType: json['media_type'],
      fileType: json['file_type'],
      url: url,
      key: key,
    );

    return VideoFile(
      id: _parseNullableInt(json['id']),
      isLocked: json['is_locked'] == true,
      title: json['title']?.toString() ?? '',
      key: key,
      url: url,
      isManagement: json['is_management'] == true,
      ageGroup: json['age_group']?.toString() ?? '',
      day: _parseDay(json['day']),
      mediaType: mediaType,
      orderNumber: _parseDay(json['order_number']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'is_locked': isLocked,
      'title': title,
      'key': key,
      'url': url,
      'file': url,
      'is_management': isManagement,
      'age_group': ageGroup,
      'day': day,
      'file_type': mediaType == 'file' ? 'pdf' : 'video',
      'media_type': mediaType,
      'order_number': orderNumber,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  String get fileName {
    final source = url.isNotEmpty ? url : key;
    final parsedUri = Uri.tryParse(source);

    if (parsedUri != null && parsedUri.pathSegments.isNotEmpty) {
      return parsedUri.pathSegments.last;
    }

    return source.split('?').first.split('/').last;
  }

  bool get isPdf {
    return mediaType == 'file' || _isPdfUrl(url) || _isPdfUrl(key);
  }

  bool get isVideo {
    return mediaType == 'video';
  }

  String get displayTitle {
    if (title.trim().isNotEmpty) return title.trim();

    return fileName
        .split('?')
        .first
        .replaceAll('.mp4', '')
        .replaceAll('.pdf', '')
        .replaceAll('-', ' ')
        .trim();
  }

  String get category {
    final parts = key.split('/');
    if (parts.length > 2) return parts[2];
    return '';
  }
}

bool _isPdfUrl(String value) {
  final parsedUri = Uri.tryParse(value);
  final path = parsedUri?.path ?? value.split('?').first;
  return path.toLowerCase().endsWith('.pdf');
}

int _parseDay(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _parseNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

String _resolveMediaType({
  dynamic mediaType,
  dynamic fileType,
  required String url,
  required String key,
}) {
  final normalizedMediaType = mediaType?.toString().toLowerCase();

  if (normalizedMediaType == 'file' || normalizedMediaType == 'document') {
    return 'file';
  }

  if (normalizedMediaType == 'video') {
    return 'video';
  }

  final normalizedFileType = fileType?.toString().toLowerCase();

  if (normalizedFileType == 'document' ||
      normalizedFileType == 'pdf' ||
      normalizedFileType == 'file') {
    return 'file';
  }

  if (normalizedFileType == 'video') {
    return 'video';
  }

  return _isPdfUrl(url) || _isPdfUrl(key) ? 'file' : 'video';
}
