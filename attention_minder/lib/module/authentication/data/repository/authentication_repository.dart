import 'package:attention_minder/constant/app_constant.dart';
import 'package:attention_minder/core/network/base_http_client.dart';
import 'package:attention_minder/module/authentication/data/repository/iauthentication_repository.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@Injectable(as: IAuthenticationRepository)
class AuthenticationRepository extends IAuthenticationRepository {
  final ApiService _apiService = ApiService(baseUrl);
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      Response response = await _dio.post(
        loginEndpoint,
        options: Options(headers: {'Content-Type': 'application/json'}),
        data: {"email": email, "password": password},
      );

      return response.data;
    } on DioException catch (e) {
      print(e);
      throw Exception(
        e.response?.data['message'] ?? "Login failed. Please try again.",
      );
    }
  }

  @override
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required bool isAdmin,
    required bool isStaff,
  }) async {
    try {
      print("${_dio.options.baseUrl}$registrationEndpoint");
      Response response = await _dio.post(
        registrationEndpoint,
        options: Options(headers: {'Content-Type': 'application/json'}),
        data: {
          "username": username,
          "email": email,
          "password": password,
          "is_admin": isAdmin,
          "is_staff": isStaff,
        },
      );
      print(response.data);
      return response.data;
    } on DioException catch (e) {
      print(e);
      print('Status Code: ${e.response?.statusCode}');
      print('Response Data: ${e.response?.data}');
      print('Response Headers: ${e.response?.headers}');

      throw Exception(
        e.response?.data.toString() ?? "Registration failed. Please try again.",
      );
    }
  }

  @override
  Future<Map<String, dynamic>> requestPasswordReset({
    required String email,
  }) async {
    try {
      Response response = await _dio.post(
        passwordResetRequestEndpoint,
        options: Options(
          headers: {
            'accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
        data: {"email": email},
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ??
            "Failed to request password reset. Please try again.",
      );
    }
  }

  @override
  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      Response response = await _dio.post(
        passwordResetOtpVerifyEndpoint,
        options: Options(
          headers: {
            'accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
        data: {"email": email, "otp": otp},
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ??
            "OTP verification failed. Please try again.",
      );
    }
  }

  @override
  Future<Map<String, dynamic>> changePassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      Response response = await _dio.post(
        passwordResetChangeEndpoint,
        options: Options(
          headers: {
            'accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
        data: {'email': email, 'password': newPassword},
      );

      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Password update failed');
    }
  }

  @override
  Future<Map<String, dynamic>> socialLogin({
    required String token,
    required String provider,
  }) async {
    // Note: Adjust the body based on your actual backend requirement.
    // Usually it sends 'access_token' and 'provider'.
    final data = {'id_token': token, 'provider': provider};

    try {
      Response response = await _dio.post(
        socialLoginEndpoint,
        options: Options(headers: {'Content-Type': 'application/json'}),
        data: data,
      );
      return response.data;
    } on DioException catch (e) {
      print('STATUS: ${e.response?.statusCode}');
      print('DATA: ${e.response?.data}');
      print('ERROR: ${e.message}');
      rethrow;
    }
  }
}
