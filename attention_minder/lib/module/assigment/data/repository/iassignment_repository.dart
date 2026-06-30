import 'package:attention_minder/module/assigment/data/model/article_model.dart';

abstract class IAssignmentRepository {
  Future<Map<String, dynamic>> getUserQuestion();

  Future<Map<String, dynamic>> saveQuestionResponse({
    required Map<String, dynamic> answers,
  });

  Future<Map<String, dynamic>> fetchAssessmentResult({int? page});
  Future<BlogResponse> getArticles({int? page});
}
