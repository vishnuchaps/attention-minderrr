class ManagementHistoryResponse {
  final bool? status;
  final int? statusCode;
  final String? message;
  final ManagementHistoryData? data;
  final Map<String, dynamic>? errors;

  ManagementHistoryResponse({
    this.status,
    this.statusCode,
    this.message,
    this.data,
    this.errors,
  });

  factory ManagementHistoryResponse.fromJson(Map<String, dynamic> json) {
    return ManagementHistoryResponse(
      status: json['status'] as bool?,
      statusCode: json['status_code'] as int?,
      message: json['message'] as String?,
      data: json['data'] is Map<String, dynamic>
          ? ManagementHistoryData.fromJson(json['data'])
          : null,
      errors: json['errors'] is Map<String, dynamic>
          ? json['errors'] as Map<String, dynamic>
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
}

class ManagementHistoryData {
  final int? count;
  final List<ManagementResult>? results;

  ManagementHistoryData({this.count, this.results});

  factory ManagementHistoryData.fromJson(Map<String, dynamic> json) {
    return ManagementHistoryData(
      count: json['count'] as int?,
      results: (json['results'] as List?)
          ?.whereType<Map>()
          .map((e) => ManagementResult.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'results': results?.map((e) => e.toJson()).toList(),
    };
  }
}

class ManagementResult {
  final int? id;
  final String? user;
  final String? result;
  final int? rawTotal;
  final double? tenScore;
  final double? readFocusTotal;
  final double? visualTrackingTotal;
  final double? audioListeningTotal;
  final int? programDuration;
  final bool? isCompleted;
  final DateTime? createdAt;
  final DateTime? completedAt;

  ManagementResult({
    this.id,
    this.user,
    this.result,
    this.rawTotal,
    this.tenScore,
    this.readFocusTotal,
    this.visualTrackingTotal,
    this.audioListeningTotal,
    this.programDuration,
    this.isCompleted,
    this.createdAt,
    this.completedAt,
  });

  factory ManagementResult.fromJson(Map<String, dynamic> json) {
    return ManagementResult(
      id: _asInt(json['id']),
      user: _asText(json['user']),
      result: _asText(json['result']),
      rawTotal: _asInt(json['raw_total']),
      tenScore: _asDouble(json['tenscore']),
      readFocusTotal: _asDouble(json['read_focus_total']),
      visualTrackingTotal: _asDouble(json['visual_tracking_total']),
      audioListeningTotal: _asDouble(json['audio_listening_total']),
      programDuration: _asInt(json['program_duration']),
      isCompleted: _asBool(json['is_completed']),
      createdAt: _asDateTime(json['created_at']),
      completedAt: _asDateTime(json['completed_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user,
      'result': result,
      'raw_total': rawTotal,
      'tenscore': tenScore,
      'read_focus_total': readFocusTotal,
      'visual_tracking_total': visualTrackingTotal,
      'audio_listening_total': audioListeningTotal,
      'program_duration': programDuration,
      'is_completed': isCompleted,
      'created_at': createdAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }
}

int? _asInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

double? _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

bool? _asBool(dynamic value) {
  if (value is bool) return value;
  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;
  return null;
}

String? _asText(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

DateTime? _asDateTime(dynamic value) {
  if (value is DateTime) return value;
  return DateTime.tryParse(value?.toString() ?? '');
}
