import 'package:attention_minder/constant/app_constant.dart';
import 'package:attention_minder/module/attention_management/data/model/ai_assessment_score_request.dart';
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
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return <String, dynamic>{'message': 'Score saved successfully'};
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
    return error.message ?? 'Unable to save the session score.';
  }
}

class AiAssessmentScoreException implements Exception {
  const AiAssessmentScoreException(this.message);

  final String message;

  @override
  String toString() => message;
}
