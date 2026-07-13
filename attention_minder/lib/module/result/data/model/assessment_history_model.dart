class AssessmentHistoryResponse {
  final bool? status;
  final String? message;
  final int count;
  final List<AssessmentHistoryItem> results;
  final Map<String, dynamic> rawData;

  const AssessmentHistoryResponse({
    this.status,
    this.message,
    this.count = 0,
    this.results = const [],
    this.rawData = const {},
  });

  factory AssessmentHistoryResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final rawResults = _extractResults(json);

    return AssessmentHistoryResponse(
      status: json['status'] is bool ? json['status'] as bool : null,
      message: json['message'] is String ? json['message'] as String : null,
      count: _countFrom(json, rawResults.length),
      rawData: data is Map<String, dynamic> ? data : json,
      results: rawResults
          .whereType<Map>()
          .map(
            (item) =>
                AssessmentHistoryItem.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
    );
  }

  static int _countFrom(Map<String, dynamic> json, int fallback) {
    final data = json['data'];
    final value = data is Map ? data['count'] : json['count'];
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static List<dynamic> _extractResults(Map<String, dynamic> json) {
    for (final key in const ['results', 'items']) {
      final value = json[key];
      if (value is List) return value;
    }

    final data = json['data'];
    if (data is List) return data;
    if (data is Map) {
      for (final key in const ['results', 'items', 'data']) {
        final value = data[key];
        if (value is List) return value;
      }
    }

    return const [];
  }
}

class AssessmentHistoryItem {
  final String? type;
  final String? title;
  final DateTime? createdAt;
  final int score;
  final Map<String, dynamic> rawData;

  const AssessmentHistoryItem({
    this.type,
    this.title,
    this.createdAt,
    this.score = 0,
    this.rawData = const {},
  });

  factory AssessmentHistoryItem.fromJson(Map<String, dynamic> json) {
    return AssessmentHistoryItem(
      type: _firstString(json, const ['type', 'assessment_type', 'category']),
      title: _firstString(json, const ['title', 'name']),
      createdAt: _dateFrom(json),
      score: _scoreFrom(json),
      rawData: json,
    );
  }

  static String? _firstString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  static DateTime? _dateFrom(Map<String, dynamic> json) {
    final value = json['created_at'] ?? json['date'] ?? json['submitted_at'];
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static int _scoreFrom(Map<String, dynamic> json) {
    final value = json['score'] ?? json['overall_score'] ?? json['total_score'];
    if (value is num) return value.round();
    if (value is String) return num.tryParse(value)?.round() ?? 0;
    return 0;
  }
}
