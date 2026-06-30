import 'package:dio/dio.dart';

abstract class IProfileRepository {
  Future<Map<String, dynamic>> getUserProfile({required int userId});

  Future<Map<String, dynamic>> updateUserProfile({
    required Map<String, dynamic> userData,
  });

  Future<Map<String, dynamic>> updateUserProfilePicture({
    required FormData formData,
  });
}
