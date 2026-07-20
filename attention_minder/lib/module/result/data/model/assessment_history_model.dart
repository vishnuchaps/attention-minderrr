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
  final int? id;
  final String? type;
  final String? title;
  final DateTime? createdAt;
  final int score;
  final double? concentrationScore;
  final double? averageConcentrationScore;
  final double? attentionEngagementRate;
  final double? averageConfidence;
  final int? totalProcessedFrames;
  final int? sampledFrames;
  final int? sessionDurationSeconds;
  final Map<String, dynamic> rawData;

  const AssessmentHistoryItem({
    this.id,
    this.type,
    this.title,
    this.createdAt,
    this.score = 0,
    this.concentrationScore,
    this.averageConcentrationScore,
    this.attentionEngagementRate,
    this.averageConfidence,
    this.totalProcessedFrames,
    this.sampledFrames,
    this.sessionDurationSeconds,
    this.rawData = const {},
  });

  factory AssessmentHistoryItem.fromJson(Map<String, dynamic> json) {
    final overallScore = _scoreFrom(json);
    final engagementRate = _doubleFrom(json, const [
      'attention_engagement_rate',
      'engagement_rate',
    ]);

    return AssessmentHistoryItem(
      id: _intFrom(json, const ['id', 'assessment_id', 'score_id']),
      type: _firstString(json, const ['type', 'assessment_type', 'category']),
      title: _firstString(json, const ['title', 'name', 'file_name']),
      createdAt: _dateFrom(json),
      score: overallScore,
      concentrationScore:
          _doubleFrom(json, const [
            'concentration_score',
            'raw_concentration_score',
            'attention_score',
          ]) ??
          (overallScore / 10),
      averageConcentrationScore:
          _doubleFrom(json, const [
            'average_concentration_score',
            'avg_concentration_score',
          ]) ??
          (engagementRate == null ? null : engagementRate / 10),
      attentionEngagementRate: engagementRate,
      averageConfidence: _doubleFrom(json, const [
        'average_confidence',
        'avg_confidence',
      ]),
      totalProcessedFrames: _intFrom(json, const [
        'total_processed_frames',
        'total_frames',
        'processed_frames',
      ]),
      sampledFrames: _intFrom(json, const [
        'sampled_frames',
        'metrics_count',
        'stored_metric_samples',
      ]),
      sessionDurationSeconds: _intFrom(json, const [
        'session_duration_seconds',
        'duration_seconds',
        'session_duration',
      ]),
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
    final value = _valueFrom(json, const [
      'created_at',
      'date',
      'submitted_at',
      'completed_at',
    ]);
    if (value is DateTime) return value;
    if (value != null) return DateTime.tryParse(value.toString());
    return null;
  }

  static int _scoreFrom(Map<String, dynamic> json) {
    final value = _valueFrom(json, const [
      'score',
      'overall_score',
      'total_score',
      'final_score',
      'final_attention_score_percent',
    ]);
    if (value is num) return value.round();
    if (value is String) return num.tryParse(value)?.round() ?? 0;
    return 0;
  }

  static int? _intFrom(Map<String, dynamic> json, List<String> keys) {
    final value = _valueFrom(json, keys);
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static double? _doubleFrom(Map<String, dynamic> json, List<String> keys) {
    final value = _valueFrom(json, keys);
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static dynamic _valueFrom(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null) return value;
    }

    for (final containerKey in const [
      'metrics',
      'session_summary',
      'summary',
      'data',
    ]) {
      final nested = json[containerKey];
      if (nested is! Map) continue;
      for (final key in keys) {
        final value = nested[key];
        if (value != null) return value;
      }
    }

    return null;
  }
}
