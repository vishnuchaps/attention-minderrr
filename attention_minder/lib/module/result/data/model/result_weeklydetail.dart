class WeeklyManagementResponse {
  final bool? status;
  final int? statusCode;
  final String? message;
  final WeeklyManagementData? data;
  final Map<String, dynamic>? errors;

  const WeeklyManagementResponse({
    this.status,
    this.statusCode,
    this.message,
    this.data,
    this.errors,
  });

  factory WeeklyManagementResponse.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const WeeklyManagementResponse();
    }

    return WeeklyManagementResponse(
      status: _parseBool(json['status']),
      statusCode: _parseInt(json['status_code']),
      message: _parseString(json['message']),
      data: json['data'] is Map<String, dynamic>
          ? WeeklyManagementData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      errors: json['errors'] is Map
          ? Map<String, dynamic>.from(json['errors'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'status_code': statusCode,
      'message': message,
      'data': data?.toJson(),
      'errors': errors,
    };
  }

  WeeklyManagementResponse copyWith({
    bool? status,
    int? statusCode,
    String? message,
    WeeklyManagementData? data,
    Map<String, dynamic>? errors,
  }) {
    return WeeklyManagementResponse(
      status: status ?? this.status,
      statusCode: statusCode ?? this.statusCode,
      message: message ?? this.message,
      data: data ?? this.data,
      errors: errors ?? this.errors,
    );
  }
}

class WeeklyManagementData {
  final PaginationLinks? links;
  final int? count;
  final int? page;
  final int? limit;
  final int? totalPages;
  final List<WeeklyResult>? results;

  const WeeklyManagementData({
    this.links,
    this.count,
    this.page,
    this.limit,
    this.totalPages,
    this.results,
  });

  factory WeeklyManagementData.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const WeeklyManagementData();
    }

    return WeeklyManagementData(
      links: json['links'] is Map<String, dynamic>
          ? PaginationLinks.fromJson(json['links'] as Map<String, dynamic>)
          : null,
      count: _parseInt(json['count']),
      page: _parseInt(json['page']),
      limit: _parseInt(json['limit']),
      totalPages: _parseInt(json['total_pages']),
      results: _parseList(
        json['results'],
        (item) => WeeklyResult.fromJson(item),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'links': links?.toJson(),
      'count': count,
      'page': page,
      'limit': limit,
      'total_pages': totalPages,
      'results': results?.map((item) => item.toJson()).toList(),
    };
  }

  WeeklyManagementData copyWith({
    PaginationLinks? links,
    int? count,
    int? page,
    int? limit,
    int? totalPages,
    List<WeeklyResult>? results,
  }) {
    return WeeklyManagementData(
      links: links ?? this.links,
      count: count ?? this.count,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      totalPages: totalPages ?? this.totalPages,
      results: results ?? this.results,
    );
  }
}

class PaginationLinks {
  final String? next;
  final String? previous;

  const PaginationLinks({this.next, this.previous});

  factory PaginationLinks.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const PaginationLinks();
    }

    return PaginationLinks(
      next: _parseString(json['next']),
      previous: _parseString(json['previous']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'next': next, 'previous': previous};
  }

  PaginationLinks copyWith({String? next, String? previous}) {
    return PaginationLinks(
      next: next ?? this.next,
      previous: previous ?? this.previous,
    );
  }
}

class WeeklyResult {
  final int? weekNumber;
  final String? startDate;
  final String? endDate;
  final List<ManagementDay>? days;
  final ManagementDay? selectedDay;

  const WeeklyResult({
    this.weekNumber,
    this.startDate,
    this.endDate,
    this.days,
    this.selectedDay,
  });

  factory WeeklyResult.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const WeeklyResult();
    }

    return WeeklyResult(
      weekNumber: _parseInt(json['week_number']),
      startDate: _parseString(json['start_date']),
      endDate: _parseString(json['end_date']),
      days: _parseList(json['days'], (item) => ManagementDay.fromJson(item)),
      selectedDay: json['selected_day'] is Map<String, dynamic>
          ? ManagementDay.fromJson(json['selected_day'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'week_number': weekNumber,
      'start_date': startDate,
      'end_date': endDate,
      'days': days?.map((item) => item.toJson()).toList(),
      'selected_day': selectedDay?.toJson(),
    };
  }

  DateTime? get parsedStartDate => _parseDateTime(startDate);

  DateTime? get parsedEndDate => _parseDateTime(endDate);

  WeeklyResult copyWith({
    int? weekNumber,
    String? startDate,
    String? endDate,
    List<ManagementDay>? days,
    ManagementDay? selectedDay,
  }) {
    return WeeklyResult(
      weekNumber: weekNumber ?? this.weekNumber,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      days: days ?? this.days,
      selectedDay: selectedDay ?? this.selectedDay,
    );
  }
}

class ManagementDay {
  final String? date;
  final String? dayLabel;
  final int? dayNumber;
  final bool? hasData;
  final String? statusLabel;
  final double? totalScore;
  final double? concentrationScore;
  final double? attentionScore;
  final double? durationSeconds;
  final String? durationLabel;
  final int? sessionsCount;
  final List<ManagementSession> sessions;

  const ManagementDay({
    this.date,
    this.dayLabel,
    this.dayNumber,
    this.hasData,
    this.statusLabel,
    this.totalScore,
    this.concentrationScore,
    this.attentionScore,
    this.durationSeconds,
    this.durationLabel,
    this.sessionsCount,
    this.sessions = const [],
  });

  factory ManagementDay.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ManagementDay();
    }

    return ManagementDay(
      date: _parseString(json['date']),
      dayLabel: _parseString(json['day_label']),
      dayNumber: _parseInt(json['day_number']),
      hasData: _parseBool(json['has_data']),
      statusLabel: _parseString(json['status_label']),
      totalScore: _parseDouble(json['total_score']),
      concentrationScore: _parseDouble(json['concentration_score']),
      attentionScore: _parseDouble(json['attention_score']),
      durationSeconds: _parseDouble(json['duration_seconds']),
      durationLabel: _parseString(json['duration_label']),
      sessionsCount: _parseInt(json['sessions_count']),
      sessions: _parseManagementSessions(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'day_label': dayLabel,
      'day_number': dayNumber,
      'has_data': hasData,
      'status_label': statusLabel,
      'total_score': totalScore,
      'concentration_score': concentrationScore,
      'attention_score': attentionScore,
      'duration_seconds': durationSeconds,
      'duration_label': durationLabel,
      'sessions_count': sessionsCount,
      'sessions': sessions.map((item) => item.toJson()).toList(),
    };
  }

  DateTime? get parsedDate => _parseDateTime(date);

  bool get containsData => sessions.isNotEmpty || (hasData ?? false);

  double get safeTotalScore => totalScore ?? 0.0;

  double get safeConcentrationScore => concentrationScore ?? 0.0;

  double get safeAttentionScore => attentionScore ?? 0.0;

  double get safeDurationSeconds =>
      durationSeconds ??
      sessions.fold<double>(
        0,
        (total, item) => total + item.safeDurationSeconds,
      );

  int get safeSessionsCount =>
      sessions.isNotEmpty ? sessions.length : sessionsCount ?? 0;

  ManagementDay copyWith({
    String? date,
    String? dayLabel,
    int? dayNumber,
    bool? hasData,
    String? statusLabel,
    double? totalScore,
    double? concentrationScore,
    double? attentionScore,
    double? durationSeconds,
    String? durationLabel,
    int? sessionsCount,
    List<ManagementSession>? sessions,
  }) {
    return ManagementDay(
      date: date ?? this.date,
      dayLabel: dayLabel ?? this.dayLabel,
      dayNumber: dayNumber ?? this.dayNumber,
      hasData: hasData ?? this.hasData,
      statusLabel: statusLabel ?? this.statusLabel,
      totalScore: totalScore ?? this.totalScore,
      concentrationScore: concentrationScore ?? this.concentrationScore,
      attentionScore: attentionScore ?? this.attentionScore,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      durationLabel: durationLabel ?? this.durationLabel,
      sessionsCount: sessionsCount ?? this.sessionsCount,
      sessions: sessions ?? this.sessions,
    );
  }
}

class ManagementSession {
  final int? id;
  final String? contentType;
  final String? title;
  final DateTime? createdAt;
  final String? timeLabel;
  final double? score;
  final double? durationSeconds;
  final String? durationLabel;
  final Map<String, dynamic> rawData;

  const ManagementSession({
    this.id,
    this.contentType,
    this.title,
    this.createdAt,
    this.timeLabel,
    this.score,
    this.durationSeconds,
    this.durationLabel,
    this.rawData = const {},
  });

  factory ManagementSession.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ManagementSession();

    final fileData = _mapFromFirstValue(json, const [
      'file',
      'file_details',
      'content',
    ]);
    final rawCreatedAt = _firstValue(json, const [
      'completed_at',
      'created_at',
      'started_at',
      'updated_at',
      'date',
    ]);

    return ManagementSession(
      id: _parseInt(
        _firstValue(json, const ['id', 'score_id', 'management_id']),
      ),
      contentType: _parseString(
        _firstValue(json, const ['content_type', 'media_type', 'type']),
      ),
      title: _parseString(
        _firstValue(json, const [
              'title',
              'file_title',
              'file_name',
              'name',
              'content_name',
            ]) ??
            _firstValue(fileData, const [
              'title',
              'file_title',
              'file_name',
              'name',
            ]),
      ),
      createdAt: rawCreatedAt == null
          ? null
          : DateTime.tryParse(rawCreatedAt.toString()),
      timeLabel: _parseString(json['time_label']),
      score: _parseDouble(
        _firstValue(json, const [
          'final_score',
          'total_score',
          'score',
          'final_attention_score_percent',
        ]),
      ),
      durationSeconds: _parseDouble(
        _firstValue(json, const [
          'session_duration_seconds',
          'duration_seconds',
          'duration',
        ]),
      ),
      durationLabel: _parseString(json['duration_label']),
      rawData: Map<String, dynamic>.unmodifiable(json),
    );
  }

  bool get isPdf => contentType?.trim().toLowerCase() == 'pdf';

  bool get isVideo => contentType?.trim().toLowerCase() == 'video';

  double get safeScore => score ?? 0;

  double get safeDurationSeconds => durationSeconds ?? 0;

  Map<String, dynamic> toJson() => <String, dynamic>{
    ...rawData,
    'id': id,
    'content_type': contentType,
    'title': title,
    'created_at': createdAt?.toIso8601String(),
    'time_label': timeLabel,
    'final_score': score,
    'session_duration_seconds': durationSeconds,
    'duration_label': durationLabel,
  };
}

List<ManagementSession> _parseManagementSessions(Map<String, dynamic> json) {
  final combined = <ManagementSession>[];
  final general = _firstValue(json, const [
    'sessions',
    'managements',
    'management_scores',
    'session_details',
    'results',
  ]);
  combined.addAll(
    _parseList(general, (item) => ManagementSession.fromJson(item)) ?? const [],
  );

  void addTypedSessions(List<String> keys, String type) {
    final rawItems = _firstValue(json, keys);
    if (rawItems is! List) return;
    for (final rawItem in rawItems.whereType<Map>()) {
      final item = Map<String, dynamic>.from(rawItem);
      item.putIfAbsent('content_type', () => type);
      combined.add(ManagementSession.fromJson(item));
    }
  }

  addTypedSessions(const [
    'pdf_sessions',
    'pdf_managements',
    'pdf_results',
  ], 'pdf');
  addTypedSessions(const [
    'video_sessions',
    'video_managements',
    'video_results',
  ], 'video');
  return List<ManagementSession>.unmodifiable(combined);
}

List<T>? _parseList<T>(
  dynamic value,
  T Function(Map<String, dynamic> json) converter,
) {
  if (value is! List) {
    return null;
  }

  return value
      .whereType<Map>()
      .map((item) => converter(Map<String, dynamic>.from(item)))
      .toList();
}

dynamic _firstValue(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null) return value;
  }
  return null;
}

Map<String, dynamic> _mapFromFirstValue(
  Map<String, dynamic> json,
  List<String> keys,
) {
  final value = _firstValue(json, keys);
  return value is Map ? Map<String, dynamic>.from(value) : const {};
}

String? _parseString(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is String) {
    return value;
  }

  return value.toString();
}

int? _parseInt(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString());
}

double? _parseDouble(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is double) {
    return value;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString());
}

bool? _parseBool(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  final normalizedValue = value.toString().toLowerCase().trim();

  if (normalizedValue == 'true' || normalizedValue == '1') {
    return true;
  }

  if (normalizedValue == 'false' || normalizedValue == '0') {
    return false;
  }

  return null;
}

DateTime? _parseDateTime(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }

  return DateTime.tryParse(value);
}
