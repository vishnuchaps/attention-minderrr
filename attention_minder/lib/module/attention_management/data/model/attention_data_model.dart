class AttentionProgramModel {
  final bool status;
  final int statusCode;
  final String message;
  final ProgramData data;

  AttentionProgramModel({
    required this.status,
    required this.statusCode,
    required this.message,
    required this.data,
  });

  factory AttentionProgramModel.fromJson(Map<String, dynamic> json) {
    return AttentionProgramModel(
      status: json['status'] ?? false,
      statusCode: json['statusCode'] ?? 0,
      message: json['message'] ?? '',
      data: ProgramData.fromJson(json['data'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'statusCode': statusCode,
      'message': message,
      'data': data.toJson(),
    };
  }
}

class ProgramData {
  final int totalDays;
  final int completedDays;
  final double progress;
  final Doctor doctor;
  final List<DailySession> sessions;

  ProgramData({
    required this.totalDays,
    required this.completedDays,
    required this.progress,
    required this.doctor,
    required this.sessions,
  });

  factory ProgramData.fromJson(Map<String, dynamic> json) {
    return ProgramData(
      totalDays: json['totalDays'] ?? 30,
      completedDays: json['completedDays'] ?? 0,
      progress: (json['progress'] ?? 0.0).toDouble(),
      doctor: Doctor.fromJson(json['doctor'] ?? {}),
      sessions: (json['sessions'] as List<dynamic>?)
              ?.map((e) => DailySession.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalDays': totalDays,
      'completedDays': completedDays,
      'progress': progress,
      'doctor': doctor.toJson(),
      'sessions': sessions.map((e) => e.toJson()).toList(),
    };
  }
}

class Doctor {
  final String name;
  final String specialty;
  final String? imageUrl;

  Doctor({
    required this.name,
    required this.specialty,
    this.imageUrl,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      name: json['name'] ?? 'Dr. Harry Simon',
      specialty: json['specialty'] ?? 'ADHD / Attention Specialist',
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'specialty': specialty,
      'imageUrl': imageUrl,
    };
  }
}

class DailySession {
  final int day;
  final String title;
  final String duration;
  final bool isCompleted;
  final List<SessionContent> contents;

  DailySession({
    required this.day,
    required this.title,
    required this.duration,
    required this.isCompleted,
    required this.contents,
  });

  factory DailySession.fromJson(Map<String, dynamic> json) {
    return DailySession(
      day: json['day'] ?? 1,
      title: json['title'] ?? '',
      duration: json['duration'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
      contents: (json['contents'] as List<dynamic>?)
              ?.map((e) => SessionContent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'title': title,
      'duration': duration,
      'isCompleted': isCompleted,
      'contents': contents.map((e) => e.toJson()).toList(),
    };
  }
}

class SessionContent {
  final String type; // "video", "article", "cbt"
  final String title;
  final String? description;
  final String? url;
  final int? duration; // in minutes

  SessionContent({
    required this.type,
    required this.title,
    this.description,
    this.url,
    this.duration,
  });

  factory SessionContent.fromJson(Map<String, dynamic> json) {
    return SessionContent(
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      url: json['url'],
      duration: json['duration'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'description': description,
      'url': url,
      'duration': duration,
    };
  }
}

class AssessmentQuestionModel {
  final bool status;
  final int statusCode;
  final String message;
  final List<AssessmentQuestion> questions;

  AssessmentQuestionModel({
    required this.status,
    required this.statusCode,
    required this.message,
    required this.questions,
  });

  factory AssessmentQuestionModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return AssessmentQuestionModel(
      status: json['status'] ?? false,
      statusCode: json['status_code'] ?? 0,
      message: json['message'] ?? '',
      questions: data != null && data['questions'] != null
          ? (data['questions'] as List<dynamic>)
              .map((e) => AssessmentQuestion.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'status_code': statusCode,
      'message': message,
      'data': {
        'questions': questions.map((e) => e.toJson()).toList(),
      },
    };
  }
}

class AssessmentQuestion {
  final int id;
  final String questionText;
  final String category;

  AssessmentQuestion({
    required this.id,
    required this.questionText,
    required this.category,
  });

  factory AssessmentQuestion.fromJson(Map<String, dynamic> json) {
    return AssessmentQuestion(
      id: json['id'] ?? 0,
      questionText: json['question_text'] ?? '',
      category: json['category'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_text': questionText,
      'category': category,
    };
  }

  // Default rating scale options for all questions
  static const List<String> ratingOptions = [
    'Never',
    'Rarely',
    'Sometimes',
    'Often',
    'Always'
  ];
}
