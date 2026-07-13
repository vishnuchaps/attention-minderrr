class WeeklyProgressResponse {
  final bool? status;
  final int? statusCode;
  final String? message;
  final ManagementDashboardData? data;
  final Map<String, dynamic>? errors;

  const WeeklyProgressResponse({
    this.status,
    this.statusCode,
    this.message,
    this.data,
    this.errors,
  });

  factory WeeklyProgressResponse.fromJson(Map<String, dynamic> json) {
    final rawData = _asMap(json['data']);

    return WeeklyProgressResponse(
      status: _asBool(json['status']),
      statusCode: _asInt(json['status_code']),
      message: json['message']?.toString(),
      data: rawData.isEmpty
          ? null
          : ManagementDashboardData.fromJson(rawData),
      errors: _asMap(json['errors']),
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
}

class ManagementDashboardData {
  final int weeksTracked;
  final double averageTotalScore;
  final double bestWeekScore;
  final double consistency;
  final String metric;
  final int rangeWeeks;
  final double improvement;
  final int? improvementFromWeek;
  final int? improvementToWeek;
  final List<WeeklyProgressPoint> weeklyProgress;

  const ManagementDashboardData({
    required this.weeksTracked,
    required this.averageTotalScore,
    required this.bestWeekScore,
    required this.consistency,
    required this.metric,
    required this.rangeWeeks,
    required this.improvement,
    required this.improvementFromWeek,
    required this.improvementToWeek,
    required this.weeklyProgress,
  });

  factory ManagementDashboardData.fromJson(Map<String, dynamic> json) {
    final overview = _asMap(json['overview']);
    final weeklyProgressData = _asMap(json['weekly_progress']);
    final improvementData = _asMap(weeklyProgressData['improvement']);

    final rawResults = weeklyProgressData['results'];

    final progress = rawResults is List
        ? rawResults
            .whereType<Map>()
            .map(
              (item) => WeeklyProgressPoint.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(growable: false)
        : const <WeeklyProgressPoint>[];

    final calculatedAverage = progress.isEmpty
        ? 0.0
        : progress.fold<double>(
              0.0,
              (sum, item) => sum + item.score,
            ) /
            progress.length;

    final calculatedBest = progress.isEmpty
        ? 0.0
        : progress
            .map((item) => item.score)
            .reduce((a, b) => a > b ? a : b);

    final calculatedImprovement = progress.length < 2
        ? 0.0
        : progress.last.score - progress.first.score;

    return ManagementDashboardData(
      weeksTracked:
          _asInt(overview['weeks_tracked']) ?? progress.length,
      averageTotalScore:
          _asDouble(overview['average_total_score']) ?? calculatedAverage,
      bestWeekScore:
          _asDouble(overview['best_week_score']) ?? calculatedBest,
      consistency:
          _asDouble(overview['consistency_percentage']) ?? 0.0,
      metric: weeklyProgressData['metric']?.toString() ?? '',
      rangeWeeks: _asInt(weeklyProgressData['range_weeks']) ?? 0,
      improvement:
          _asDouble(improvementData['points']) ?? calculatedImprovement,
      improvementFromWeek: _asInt(improvementData['from_week']),
      improvementToWeek: _asInt(improvementData['to_week']),
      weeklyProgress: progress,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overview': {
        'weeks_tracked': weeksTracked,
        'average_total_score': averageTotalScore,
        'best_week_score': bestWeekScore,
        'consistency_percentage': consistency,
      },
      'weekly_progress': {
        'metric': metric,
        'range_weeks': rangeWeeks,
        'results': weeklyProgress.map((item) => item.toJson()).toList(),
        'improvement': {
          'points': improvement,
          'from_week': improvementFromWeek,
          'to_week': improvementToWeek,
        },
      },
    };
  }
}

class WeeklyProgressPoint {
  final int? weekNumber;
  final String label;
  final DateTime? startDate;
  final DateTime? endDate;
  final double score;

  const WeeklyProgressPoint({
    required this.weekNumber,
    required this.label,
    required this.startDate,
    required this.endDate,
    required this.score,
  });

  factory WeeklyProgressPoint.fromJson(Map<String, dynamic> json) {
    final weekNumber = _asInt(json['week_number']);

    final rawLabel = json['label']?.toString().trim();

    return WeeklyProgressPoint(
      weekNumber: weekNumber,
      label: rawLabel != null && rawLabel.isNotEmpty
          ? rawLabel
          : weekNumber != null
              ? 'Wk $weekNumber'
              : '',
      startDate: _asDateTime(json['start_date']),
      endDate: _asDateTime(json['end_date']),
      score: _asDouble(json['total_score']) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'week_number': weekNumber,
      'label': label,
      'start_date': _formatDate(startDate),
      'end_date': _formatDate(endDate),
      'total_score': score,
    };
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return <String, dynamic>{};
}

bool? _asBool(dynamic value) {
  if (value is bool) return value;

  if (value is num) {
    return value != 0;
  }

  if (value is String) {
    final normalized = value.trim().toLowerCase();

    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }

  return null;
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();

  if (value is String) {
    return int.tryParse(value.trim()) ??
        double.tryParse(value.trim())?.toInt();
  }

  return null;
}

double? _asDouble(dynamic value) {
  if (value is num) return value.toDouble();

  if (value is String) {
    final normalized = value
        .trim()
        .replaceAll(',', '')
        .replaceAll(RegExp(r'[^0-9.\-]'), '');

    return double.tryParse(normalized);
  }

  return null;
}

DateTime? _asDateTime(dynamic value) {
  if (value == null) return null;

  final dateString = value.toString().trim();

  if (dateString.isEmpty) return null;

  return DateTime.tryParse(dateString);
}

String? _formatDate(DateTime? value) {
  if (value == null) return null;

  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');

  return '$year-$month-$day';
}