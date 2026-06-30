class UserData {
  final int id;
  final String email;
  final String username;
  final String dob;
  final String gender;
  final String? country;
  final double? height;
  final double? weight;
  final String? profileImage;
  final String? profileImageUrl;
  final bool isCompleted;

  UserData({
    required this.id,
    required this.email,
    required this.username,
    required this.dob,
    required this.gender,
    this.country,
    this.height,
    this.weight,
    this.profileImage,
    this.profileImageUrl,
    required this.isCompleted,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      dob: json['dob'] ?? '',
      gender: json['gender'] ?? '',
      country: json['country'],

      height: json['height'] != null
          ? double.tryParse(json['height'].toString())
          : null,

      weight: json['weight'] != null
          ? double.tryParse(json['weight'].toString())
          : null,

      profileImage: json['profile_image'],
      profileImageUrl: json['profile_image_url'],
      isCompleted: json['is_completed'] is bool
          ? json['is_completed'] as bool
          : _hasRequiredProfileFields(json),
    );
  }

  static bool _hasRequiredProfileFields(Map<String, dynamic> json) {
    final height = double.tryParse(json['height']?.toString() ?? '');
    final weight = double.tryParse(json['weight']?.toString() ?? '');
    final country = json['country']?.toString().trim() ?? '';

    return (json['username']?.toString().trim().isNotEmpty ?? false) &&
        (json['email']?.toString().trim().isNotEmpty ?? false) &&
        (json['dob']?.toString().trim().isNotEmpty ?? false) &&
        (json['gender']?.toString().trim().isNotEmpty ?? false) &&
        country.isNotEmpty &&
        country != 'Select country' &&
        height != null &&
        height > 0 &&
        weight != null &&
        weight > 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'dob': dob,
      'gender': gender,
      'country': country,
      'height': height,
      'weight': weight,
      'profile_image': profileImage,
      'profile_image_url': profileImageUrl,
      'is_completed': isCompleted,
    };
  }
}
