class QuestionResponse {
  bool status;
  int statusCode;
  String message;
  Data data;
  Errors errors;

  QuestionResponse({
    required this.status,
    required this.statusCode,
    required this.message,
    required this.data,
    required this.errors,
  });

  factory QuestionResponse.fromJson(Map<String, dynamic> json) {
    return QuestionResponse(
      status: json['status'] ?? false,
      statusCode: json['status_code'] ?? 0,
      message: json['message'] ?? '',
      data: Data.fromJson(json['data'] ?? {}),
      errors: Errors.fromJson(json['errors'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'status_code': statusCode,
      'message': message,
      'data': data.toJson(),
      'errors': errors.toJson(),
    };
  }
}

class Data {
  List<Question> questions;
  List<dynamic> parentsChecklist;

  Data({
    required this.questions,
    required this.parentsChecklist,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      questions: (json['questions'] as List<dynamic>?)
              ?.map((question) => Question.fromJson(question as Map<String, dynamic>))
              .toList() ??
          [],
      parentsChecklist: json['parents_checklist'] != null
          ? List<dynamic>.from(json['parents_checklist'] as List)
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questions': questions.map((question) => question.toJson()).toList(),
      'parents_checklist': parentsChecklist,
    };
  }
}

class Question {
  int id;
  String questionText;
  String category;

  Question({
    required this.id,
    required this.questionText,
    required this.category,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
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
}

class Errors {
  Errors();

  factory Errors.fromJson(Map<String, dynamic> json) {
    return Errors();
  }

  Map<String, dynamic> toJson() {
    return {};
  }
}
