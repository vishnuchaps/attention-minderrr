abstract class IAuthenticationRepository {
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  });
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required bool isAdmin,
    required bool isStaff,
  });
  Future<Map<String, dynamic>> requestPasswordReset({required String email});
  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  });
  Future<Map<String, dynamic>> changePassword({
    required String email,
    required String newPassword,
  });

  Future<Map<String, dynamic>> socialLogin({
    required String token,
    required String provider,
    String tokenField = 'id_token',
  });
}
