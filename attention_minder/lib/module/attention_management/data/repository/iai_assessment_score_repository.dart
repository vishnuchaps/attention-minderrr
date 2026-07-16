import 'package:attention_minder/module/attention_management/data/model/ai_assessment_score_request.dart';
import 'package:attention_minder/module/attention_management/data/model/goal_submission.dart';
import 'package:attention_minder/module/attention_management/data/model/goals_model.dart';

abstract interface class IAiAssessmentScoreRepository {
  Future<Map<String, dynamic>> saveScore(AiAssessmentScoreRequest request);

  Future<GoalsResponse> getGoalsResponse();

  Future<Map<String, dynamic>> setGoals({required List<GoalSubmission> goals});

  Future<Map<String, dynamic>> updateGoalRatings({
    required List<GoalSubmission> goals,
  });
}
