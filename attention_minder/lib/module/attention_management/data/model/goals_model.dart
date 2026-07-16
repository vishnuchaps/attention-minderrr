class GoalsResponse {
  final int? statusCode;
  final bool? status;
  final String? message;
  final bool? isFirst;
  final bool? isLast;
  final int? rating;
  final List<GoalData>? data;

  const GoalsResponse({
    this.statusCode,
    this.status,
    this.message,
    this.isFirst,
    this.isLast,
    this.rating,
    this.data,
  });

  factory GoalsResponse.fromJson(Map<String, dynamic> json) {
    return GoalsResponse(
      statusCode: json['status_code'] as int?,
      status: json['status'] as bool?,
      message: json['message'] as String?,
      isFirst: json['is_first'] as bool?,
      isLast: json['is_last'] as bool?,
      rating: json['rating'] as int?,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => GoalData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status_code': statusCode,
      'status': status,
      'message': message,
      'is_first': isFirst,
      'is_last': isLast,
      'rating': rating,
      'data': data?.map((e) => e.toJson()).toList(),
    };
  }
}

class GoalData {
  final int? id;
  final String? goal;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const GoalData({
    this.id,
    this.goal,
    this.createdAt,
    this.updatedAt,
  });

  factory GoalData.fromJson(Map<String, dynamic> json) {
    return GoalData(
      id: json['id'] as int?,
      goal: json['goal'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'goal': goal,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}