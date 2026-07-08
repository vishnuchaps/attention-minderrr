import 'package:attention_minder/constant/app_constant.dart';
import 'package:attention_minder/module/authentication/data/repository/iauthentication_repository.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: IAuthenticationRepository)
class AuthenticationRepository extends IAuthenticationRepository {
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
      return response.data;
    } on DioException catch (e) {
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
    String tokenField = 'id_token',
  }) async {
    try {
      Response response = await _dio.post(
        socialLoginEndpoint,
        options: Options(headers: {'Content-Type': 'application/json'}),
        data: {'provider': provider, tokenField: token},
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Social login failed.'));
    }
  }

  String _extractErrorMessage(DioException error, String fallback) {
    final responseData = error.response?.data;

    if (responseData is Map<String, dynamic>) {
      final message =
          responseData['message'] ??
          responseData['detail'] ??
          responseData['error'] ??
          responseData['non_field_errors'];
      if (message is List && message.isNotEmpty) {
        return message.first.toString();
      }
      if (message != null) {
        return message.toString();
      }
    }

    if (responseData is String && responseData.trim().isNotEmpty) {
      return responseData;
    }

    return fallback;
  }
}
