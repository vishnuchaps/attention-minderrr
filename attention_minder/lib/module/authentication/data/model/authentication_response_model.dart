class AuthenticationResponseModel {
  final String refresh;
  final String access;
  final String message;

  AuthenticationResponseModel({
    required this.refresh,
    required this.access,
    required this.message,
  });

  factory AuthenticationResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthenticationResponseModel(
      refresh: json['refresh'],
      access: json['access'],
      message: json['message'],
    );
  }
}
