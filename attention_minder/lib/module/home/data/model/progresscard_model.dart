class AssessmentResultResponse {
  final bool? status;
  final int? statusCode;
  final String? message;
  final AssessmentResultData? data;
  final Map<String, dynamic>? errors;

  AssessmentResultResponse({
    this.status,
    this.statusCode,
    this.message,
    this.data,
    this.errors,
  });

  factory AssessmentResultResponse.fromJson(Map<String, dynamic>? json) {
    if (json == null) return AssessmentResultResponse();

    return AssessmentResultResponse(
      status: json['status'] as bool?,
      statusCode: json['status_code'] as int?,
      message: json['message'] as String?,
      data: json['data'] != null
          ? AssessmentResultData.fromJson(json['data'])
          : null,
      errors: json['errors'] as Map<String, dynamic>?,
    );
  }
}

class AssessmentResultData {
  final int? resultId;
  final int? totalQuestions;
  final int? answeredQuestions;
  final int? pendingQuestions;
  final double? completedPercentage;
  final List<AssessmentQuestion>? questions;

  AssessmentResultData({
    this.resultId,
    this.totalQuestions,
    this.answeredQuestions,
    this.pendingQuestions,
    this.completedPercentage,
    this.questions,
  });

  factory AssessmentResultData.fromJson(Map<String, dynamic>? json) {
    if (json == null) return AssessmentResultData();

    return AssessmentResultData(
      resultId: json['result_id'] as int?,
      totalQuestions: json['total_questions'] as int?,
      answeredQuestions: json['answered_questions'] as int?,
      pendingQuestions: json['pending_questions'] as int?,
      completedPercentage: (json['completed_percentage'] as num?)?.toDouble(),
      questions: (json['questions'] as List?)
          ?.map((e) => AssessmentQuestion.fromJson(e))
          .toList(),
    );
  }
}

class AssessmentQuestion {
  final int? position;
  final int? questionId;
  final String? questionText;
  final String? category;
  final bool? isAnswered;
  final String? status;
  final int? responseId;
  final dynamic answer;
  final String? textResponse;

  AssessmentQuestion({
    this.position,
    this.questionId,
    this.questionText,
    this.category,
    this.isAnswered,
    this.status,
    this.responseId,
    this.answer,
    this.textResponse,
  });

  factory AssessmentQuestion.fromJson(Map<String, dynamic>? json) {
    if (json == null) return AssessmentQuestion();

    return AssessmentQuestion(
      position: json['position'] as int?,
      questionId: json['question_id'] as int?,
      questionText: json['question_text'] as String?,
      category: json['category'] as String?,
      isAnswered: json['is_answered'] as bool?,
      status: json['status'] as String?,
      responseId: json['response_id'] as int?,
      answer: json['answer'],
      textResponse: json['text_response'] as String?,
    );
  }
}
