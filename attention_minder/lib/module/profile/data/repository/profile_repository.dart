import 'package:attention_minder/constant/app_constant.dart';
import 'package:attention_minder/core/network/base_http_client.dart';
import 'package:attention_minder/module/profile/data/repository/iprofile_repository.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@Injectable(as: IProfileRepository)
class ProfileRepository extends IProfileRepository {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  @override
  Future<Map<String, dynamic>> getUserProfile({required int userId}) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('accessToken');
      print("access token is $accessToken");
      print("$userProfileUrl?id=$userId");
      Response response = await _dio.get(
        "$userProfileUrl?id=$userId",
        options: Options(
          headers: {
            'accept': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      return response.data;
    } on DioException catch (e) {
      print("the error is $e");
      throw Exception(
        e.response?.data['message'] ?? "Failed to fetch user profile.",
      );
    }
  }

  @override
  Future<Map<String, dynamic>> updateUserProfile({
    required Map<String, dynamic> userData,
  }) async {
    try {
      print("bye");
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('accessToken');

      // Debugging: Print URL, headers, and data before making the request
      print("Request URL: $updateProfileUrl");
      print("Authorization: Bearer $accessToken");
      print("Request Data: ${userData}");

      Response response = await _dio.post(
        updateProfileEndpoint,
        data: userData,
        options: Options(
          headers: {
            'accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
          validateStatus: (status) => true, // Allow all responses for debugging
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
  Future<Map<String, dynamic>> updateUserProfilePicture({
    required FormData formData,
  }) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('accessToken');

      // Debugging: Print URL, headers, and data before making the request
      print("Request URL: $updateProfileUrl");
      print("Authorization: Bearer $accessToken");
      print("Request Data: ${formData}");

      Response response = await _dio.post(
        updateProfileEndpoint,
        data: formData,
        options: Options(
          headers: {
            'accept': 'application/json',
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
}
