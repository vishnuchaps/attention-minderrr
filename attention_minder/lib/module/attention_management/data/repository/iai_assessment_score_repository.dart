import 'package:attention_minder/module/attention_management/data/model/ai_assessment_score_request.dart';

abstract interface class IAiAssessmentScoreRepository {
  Future<Map<String, dynamic>> saveScore(AiAssessmentScoreRequest request);
}
