import 'dart:convert';

import 'package:attention_minder/constant/app_constant.dart';
import 'package:attention_minder/module/result/data/model/assessment_history_model.dart';
import 'package:attention_minder/module/result/data/model/dashboard_management.dart';
import 'package:attention_minder/module/result/data/model/questionnaire_result_model.dart';
import 'package:attention_minder/module/result/data/model/result_weeklydetail.dart';
import 'package:attention_minder/module/result/data/repository/iresult_repository.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@Injectable(as: IResultRepository)
class ResultRepository extends IResultRepository {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  @override
  Future<AssessmentHistoryResponse> fetchResult({int? page}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');

      var endpoint = getResultofAiBasedUrl;
      if (page != null) {
        endpoint += '&page=$page';
      }

      final response = await _dio.get(
        endpoint,
        options: Options(
          headers: {
            'accept': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      return AssessmentHistoryResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to fetch assessment results.',
      );
    }
  }

  @override
  Future<WeeklyProgressResponse> fetchManagementDashboard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');

      final response = await _dio.get(
        getManagementDashboardUrl,
        options: Options(
          headers: {
            'accept': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      return WeeklyProgressResponse.fromJson(_responseMap(response.data));
    } on DioException catch (e) {
      throw Exception(
        _errorMessage(
          e.response?.data,
          fallback: 'Failed to fetch management dashboard data.',
        ),
      );
    }
  }

  @override
  Future<WeeklyManagementResponse> fetchResultWeeklyDetail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');

      final response = await _dio.get(
        getweeklyDetailUrl,
        options: Options(
          headers: {
            'accept': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      return WeeklyManagementResponse.fromJson(_responseMap(response.data));
    } on DioException catch (e) {
      throw Exception(
        _errorMessage(
          e.response?.data,
          fallback: 'Failed to fetch management dashboard data.',
        ),
      );
    }
  }

  @override
  Future<ManagementHistoryResponse> fetchQuestionnaireResult({
    int? page,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');

      var endpoint = getResultofQuestionnaireUrl;
      if (page != null) {
        endpoint += '?page=$page';
      }

      final response = await _dio.get(
        endpoint,
        options: Options(
          headers: {
            'accept': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      return ManagementHistoryResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ??
            'Failed to fetch questionnaire assessment results.',
      );
    }
  }
}

Map<String, dynamic> _responseMap(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);

  if (value is String) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } on FormatException {
      // A plain-text or HTML response is not a valid dashboard payload.
    }
  }

  throw const FormatException('Invalid management dashboard response.');
}

String _errorMessage(dynamic value, {required String fallback}) {
  if (value is Map) {
    final message = value['message'];
    if (message != null && message.toString().trim().isNotEmpty) {
      return message.toString();
    }
  }

  if (value is String && value.trim().isNotEmpty) return value.trim();
  return fallback;
}
