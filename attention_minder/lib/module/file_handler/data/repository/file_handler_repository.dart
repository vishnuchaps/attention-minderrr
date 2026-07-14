import 'package:attention_minder/constant/app_constant.dart';
import 'package:attention_minder/module/file_handler/data/repository/ifile_handler_repository.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@Injectable(as: IFileHandlerRepository)
class FileHandlerRepository extends IFileHandlerRepository {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  @override
  Future<Map<String, dynamic>> getFiles({bool isManagement = true}) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('accessToken');

      print("Request URL: $getFilesUrl");
      print("Authorization: Bearer $accessToken");
      print("is_management: $isManagement");

      Response response = await _dio.get(
        getFilesEndpoint,
        queryParameters: {'is_management': isManagement},
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
        e.response?.data['message'] ?? "Failed to fetch files from S3.",
      );
    }
  }

  @override
  Future<Map<String, dynamic>> saveFeedback({required String feedback}) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('accessToken');

      print("Request URL: $saveFeedbackUrl");
      print("Authorization: Bearer $accessToken");
      print("Feedback: $feedback");

      Response response = await _dio.get(
        saveFeedbackEndpoint,
        queryParameters: {'feedback': feedback},
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
        e.response?.data['message'] ?? "Failed to save feedback.",
      );
    }
  }
}
