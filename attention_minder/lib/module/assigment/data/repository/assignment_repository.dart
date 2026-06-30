import 'package:attention_minder/constant/app_constant.dart';
import 'package:attention_minder/module/assigment/data/model/article_model.dart';
import 'package:attention_minder/module/assigment/data/repository/iassignment_repository.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@Injectable(as: IAssignmentRepository)
class AssignmentRepository extends IAssignmentRepository {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  @override
  Future<Map<String, dynamic>> getUserQuestion() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('accessToken');

      Response response = await _dio.get(
        getQuestionEndPoint,
        options: Options(
          headers: {
            'accept': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      return response.data;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ??
            "Failed to fetch user Self Assignment Questions .",
      );
    }
  }

  @override
  @override
  Future<Map<String, dynamic>> saveQuestionResponse({
    required Map<String, dynamic> answers,
  }) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('accessToken');

      // Debugging: Print URL, headers, and data before making the request
      print("Request URL: ${baseUrl}$saveQuestionEndPoint");
      print("Authorization: Bearer $accessToken");
      print("Request Data: ${answers}");

      Response response = await _dio.post(
        "${baseUrl}$saveQuestionEndPoint",
        data: answers, // Use the corrected parameter name
        options: Options(
          headers: {
            'accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
          validateStatus: (status) => true,
        ),
      );

      // Debugging: Print full response
      print("Response Status: ${response.statusCode}");
      print("Response Data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception("Error: ${response.statusCode} - ${response.data}");
      }
    } on DioException catch (e) {
      print("Dio Error: ${e.response?.statusCode} - ${e.response?.data}");
      throw Exception(
        e.response?.data['message'] ?? "Failed to update profile.",
      );
    }
  }

  @override
  Future<Map<String, dynamic>> fetchAssessmentResult({int? page}) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('accessToken');

      String endpoint = fetchResultEndpoint;
      if (page != null) {
        endpoint += '?page=$page';
      }

      print("Request URL: $baseUrl$endpoint");
      print("Authorization: Bearer $accessToken");

      Response response = await _dio.get(
        endpoint,
        options: Options(
          headers: {
            'accept': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      print("Response Status: ${response.statusCode}");
      print("Response Data: ${response.data}");

      return response.data;
    } on DioException catch (e) {
      print("Dio Error: ${e.response?.statusCode} - ${e.response?.data}");
      throw Exception(
        e.response?.data['message'] ?? "Failed to fetch assessment results.",
      );
    }
  }

  @override
  Future<BlogResponse> getArticles({int? page}) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('accessToken');
      String endpoint = getArticlesUrl;
      if (page != null && page > 1) {
        endpoint = '$getArticlesUrl?page=$page';
      }
      Response response = await _dio.get(
        endpoint,
        options: Options(
          headers: {
            'accept': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      return BlogResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? "Failed to fetch assessment results.",
      );
    }
  }
}
