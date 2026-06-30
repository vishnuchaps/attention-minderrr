import 'package:attention_minder/constant/app_constant.dart';
import 'package:attention_minder/module/home/data/model/progresscard_model.dart';
import 'package:attention_minder/module/home/data/repository/iprogress_repository.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@Injectable(as: IProgressRepository)
class ProgressRepository extends IProgressRepository {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  @override
  Future<AssessmentResultResponse> getProgressCard() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('accessToken');
      String endpoint = progressCardUrl;
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
      return AssessmentResultResponse.fromJson(response.data);
    } on DioException catch (e) {
      print("Dio Error: ${e.response?.statusCode} - ${e.response?.data}");
      throw Exception(
        e.response?.data['message'] ?? "Failed to fetch assessment results.",
      );
    }
  }
}
