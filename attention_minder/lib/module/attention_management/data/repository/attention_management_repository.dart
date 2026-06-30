import 'package:attention_minder/constant/app_constant.dart';
import 'package:attention_minder/module/attention_management/data/repository/iattention_management_repository.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@Injectable(as: IAttentionManagementRepository)
class AttentionManagementRepository implements IAttentionManagementRepository {
  final Dio _dio = Dio();

  Future<String?> _getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  @override
  Future<Map<String, dynamic>> getProgramData() async {
    try {
      final headers = await _getHeaders();
      final response = await _dio.get(
        programDataUrl,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to fetch program data');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching program data: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getAssessmentQuestions() async {
    try {
      final headers = await _getHeaders();
      final response = await _dio.get(
        attentionAssessmentUrl,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to fetch assessment questions');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching assessment questions: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> submitAssessment({
    required List<Map<String, dynamic>> answers,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await _dio.post(
        submitAttentionAssessmentUrl,
        data: {'answers': answers},
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to submit assessment');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error submitting assessment: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getDailySession({required int day}) async {
    try {
      final headers = await _getHeaders();
      final response = await _dio.get(
        dailySessionUrl,
        queryParameters: {'day': day},
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to fetch daily session');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching daily session: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> completeSession({
    required int day,
    required Map<String, dynamic> sessionData,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await _dio.post(
        completeSessionUrl,
        data: {
          'day': day,
          'sessionData': sessionData,
        },
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to complete session');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error completing session: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> saveGoals({required List<String> goals}) async {
    try {
      final headers = await _getHeaders();
      final response = await _dio.post(
        saveGoalsUrl,
        data: {'goals': goals},
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to save goals');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error saving goals: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getProgressData() async {
    try {
      final headers = await _getHeaders();
      final response = await _dio.get(
        progressDataUrl,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to fetch progress data');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching progress data: $e');
    }
  }
}
