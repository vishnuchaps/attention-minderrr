abstract class IAttentionManagementRepository {
  Future<Map<String, dynamic>> getProgramData();
  Future<Map<String, dynamic>> getAssessmentQuestions();
  Future<Map<String, dynamic>> submitAssessment({
    required List<Map<String, dynamic>> answers,
  });
  Future<Map<String, dynamic>> getDailySession({required int day});
  Future<Map<String, dynamic>> completeSession({
    required int day,
    required Map<String, dynamic> sessionData,
  });
  Future<Map<String, dynamic>> saveGoals({required List<String> goals});
  Future<Map<String, dynamic>> getProgressData();
}
