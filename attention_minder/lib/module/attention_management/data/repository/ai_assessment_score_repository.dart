import 'package:attention_minder/constant/app_constant.dart';
import 'package:attention_minder/module/attention_management/data/model/ai_assessment_score_request.dart';
import 'package:attention_minder/module/attention_management/data/model/goal_submission.dart';
import 'package:attention_minder/module/attention_management/data/model/goals_model.dart';
import 'package:attention_minder/module/attention_management/data/repository/iai_assessment_score_repository.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@Injectable(as: IAiAssessmentScoreRepository)
class AiAssessmentScoreRepository implements IAiAssessmentScoreRepository {
  AiAssessmentScoreRepository(this._preferences) : _dio = Dio();

  final SharedPreferences _preferences;
  final Dio _dio;

  @override
  Future<Map<String, dynamic>> saveScore(
    AiAssessmentScoreRequest request,
  ) async {
    final token = _preferences.getString('accessToken');

    if (token == null || token.isEmpty) {
      throw const AiAssessmentScoreException(
        'Your session has expired. Please sign in again.',
      );
    }

    try {
      final response = await _dio.post<dynamic>(
        saveAiAssessmentScoreUrl,
        data: request.toJson(),
        options: Options(
          headers: <String, String>{
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      final data = response.data;

      if (data is Map<String, dynamic>) {
        return data;
      }

      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      return <String, dynamic>{'message': 'Score saved successfully'};
    } on DioException catch (error) {
      throw AiAssessmentScoreException(_messageFrom(error));
    }
  }

  @override
  Future<GoalsResponse> getGoalsResponse() async {
    final token = _preferences.getString('accessToken');

    if (token == null || token.isEmpty) {
      throw const AiAssessmentScoreException(
        'Your session has expired. Please sign in again.',
      );
    }

    try {
      final response = await _dio.get<dynamic>(
        getGoalsUrl,
        options: Options(
          headers: <String, String>{
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      final data = response.data;

      if (data is Map<String, dynamic>) {
        return GoalsResponse.fromJson(data);
      }

      if (data is Map) {
        return GoalsResponse.fromJson(Map<String, dynamic>.from(data));
      }

      throw const AiAssessmentScoreException(
        'The server returned an invalid goals response.',
      );
    } on DioException catch (error) {
      throw AiAssessmentScoreException(_messageFrom(error));
    }
  }

  @override
  Future<Map<String, dynamic>> setGoals({
    required List<GoalSubmission> goals,
  }) async {
    return _submitGoals(goals: goals, usePatch: false);
  }

  @override
  Future<Map<String, dynamic>> updateGoalRatings({
    required List<GoalSubmission> goals,
  }) async {
    return _submitGoals(goals: goals, usePatch: true);
  }

  Future<Map<String, dynamic>> _submitGoals({
    required List<GoalSubmission> goals,
    required bool usePatch,
  }) async {
    final token = _preferences.getString('accessToken');

    if (token == null || token.isEmpty) {
      throw const AiAssessmentScoreException(
        'Your session has expired. Please sign in again.',
      );
    }

    final normalizedGoals = goals
        .map((goal) => goal.normalized())
        .where((goal) => goal.goal.isNotEmpty)
        .toList(growable: false);

    if (normalizedGoals.isEmpty) {
      throw const AiAssessmentScoreException(
        'Enter at least one goal to continue.',
      );
    }

    if (usePatch && normalizedGoals.any((goal) => goal.id == null)) {
      throw const AiAssessmentScoreException(
        'A saved goal could not be identified. Please refresh and try again.',
      );
    }

    try {
      final requestBody = <String, dynamic>{
        'goals': normalizedGoals.map((goal) => goal.toJson()).toList(),
        if (usePatch) 'is_last': false,
      };
      final options = Options(
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      final response = usePatch
          ? await _dio.patch<dynamic>(
              getGoalsUrl,
              data: requestBody,
              options: options,
            )
          : await _dio.post<dynamic>(
              getGoalsUrl,
              data: requestBody,
              options: options,
            );

      final data = response.data;

      if (data is Map<String, dynamic>) {
        return data;
      }

      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      return <String, dynamic>{'message': 'Goals saved successfully.'};
    } on DioException catch (error) {
      throw AiAssessmentScoreException(_messageFrom(error));
    }
  }

  String _messageFrom(DioException error) {
    final data = error.response?.data;

    if (data is Map) {
      for (final key in const <String>['message', 'detail', 'error']) {
        final value = data[key];

        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString();
        }
      }
    }

    return error.message ??
        'We could not complete your request. Please try again.';
  }
}

class AiAssessmentScoreException implements Exception {
  const AiAssessmentScoreException(this.message);

  final String message;

  @override
  String toString() => message;
}
