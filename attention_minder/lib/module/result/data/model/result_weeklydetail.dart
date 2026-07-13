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
          ? WeeklyManagementData.fromJson(
              json['data'] as Map<String, dynamic>,
            )
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
          ? PaginationLinks.fromJson(
              json['links'] as Map<String, dynamic>,
            )
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

  const PaginationLinks({
    this.next,
    this.previous,
  });

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
    return {
      'next': next,
      'previous': previous,
    };
  }

  PaginationLinks copyWith({
    String? next,
    String? previous,
  }) {
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
      days: _parseList(
        json['days'],
        (item) => ManagementDay.fromJson(item),
      ),
      selectedDay: json['selected_day'] is Map<String, dynamic>
          ? ManagementDay.fromJson(
              json['selected_day'] as Map<String, dynamic>,
            )
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
    };
  }

  DateTime? get parsedDate => _parseDateTime(date);

  bool get containsData => hasData ?? false;

  double get safeTotalScore => totalScore ?? 0.0;

  double get safeConcentrationScore => concentrationScore ?? 0.0;

  double get safeAttentionScore => attentionScore ?? 0.0;

  double get safeDurationSeconds => durationSeconds ?? 0.0;

  int get safeSessionsCount => sessionsCount ?? 0;

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
    );
  }
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
      .map(
        (item) => converter(
          Map<String, dynamic>.from(item),
        ),
      )
      .toList();
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