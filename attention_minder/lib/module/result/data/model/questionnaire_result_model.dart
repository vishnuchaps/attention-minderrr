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
      id: json['id'] as int?,
      user: json['user'] as String?,
      result: json['result'] as String?,
      rawTotal: json['raw_total'] as int?,
      tenScore: (json['tenscore'] as num?)?.toDouble(),
      readFocusTotal: (json['read_focus_total'] as num?)?.toDouble(),
      visualTrackingTotal: (json['visual_tracking_total'] as num?)?.toDouble(),
      audioListeningTotal: (json['audio_listening_total'] as num?)?.toDouble(),
      programDuration: json['program_duration'] as int?,
      isCompleted: json['is_completed'] as bool?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'])
          : null,
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
