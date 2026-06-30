import 'dart:convert';

import 'package:attention_minder/module/profile/data/model/user_data_model.dart';
import 'package:attention_minder/module/profile/data/repository/iprofile_repository.dart';
import 'package:attention_minder/constant/app_constant.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'profile_event.dart';
part 'profile_state.dart';

@injectable
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final IProfileRepository _profileRepository;
  UserData? _profile;
  String? _profileImageUrl;

  UserData? get profile => _profile;
  String? get profileImageUrl => _profileImageUrl ?? _profile?.profileImageUrl;

  ProfileBloc(this._profileRepository) : super(ProfileInitial()) {
    on<GetTheProfileEvent>(_onFetchingProfile);
    on<UpdateProfileEvent>(_onUpdatingProfile);
    on<UpdateProfilePictureEvent>(_onUpdatingProfilePicture);
  }

  void _onFetchingProfile(
    GetTheProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userId = _resolveUserId(prefs);
    try {
      if (userId == null) {
        throw Exception('Unable to identify logged in user.');
      }

      final response = await _profileRepository.getUserProfile(userId: userId);
      final UserData userData = UserData.fromJson(response['data']);
      await _cacheProfile(userData);

      emit(FetchProfileSuccess(userData));
    } catch (e) {
      emit(FetchProfileFailed(e.toString()));
    }
  }

  void _onUpdatingProfile(
    UpdateProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());

    try {
      final response = await _profileRepository.updateUserProfile(
        userData: event.userData,
      );
      emit(UpdateProfileSuccess(response['message']));
    } catch (e) {
      emit(UpdateProfileFailed(e.toString()));
    }
  }

  void _onUpdatingProfilePicture(
    UpdateProfilePictureEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());

    try {
      final response = await _profileRepository.updateUserProfilePicture(
        formData: event.formData,
      );
      final profileImageUrl = _extractProfileImageUrl(response);
      if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
        await _cacheProfileImageUrl(profileImageUrl);
      }

      emit(
        UpdateProfilePictureSuccess(
          response['message'],
          profileImageUrl: profileImageUrl,
        ),
      );
    } catch (e) {
      emit(UpdateProfilePictureFailed(e.toString()));
    }
  }

  Future<void> _cacheProfile(UserData userData) async {
    _profile = userData;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userId', userData.id);
    await prefs.setString('username', userData.username);
    await prefs.setString('email', userData.email);
    await prefs.setBool('isProfileCompleted', userData.isCompleted);

    if (userData.profileImageUrl != null &&
        userData.profileImageUrl!.isNotEmpty) {
      await _cacheProfileImageUrl(userData.profileImageUrl!);
    }
  }

  int? _resolveUserId(SharedPreferences prefs) {
    final cachedUserId = prefs.getInt('userId');
    if (cachedUserId != null) return cachedUserId;

    final accessToken = prefs.getString('accessToken');
    if (accessToken == null || accessToken.isEmpty) return null;

    try {
      final parts = accessToken.split('.');
      if (parts.length != 3) return null;

      final normalized = base64Url.normalize(parts[1]);
      final payload = json.decode(utf8.decode(base64Url.decode(normalized)));
      if (payload is Map<String, dynamic>) {
        final userId = payload['user_id'];
        if (userId is int) {
          prefs.setInt('userId', userId);
          return userId;
        }
        return int.tryParse(userId?.toString() ?? '');
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  Future<void> _cacheProfileImageUrl(String profileImageUrl) async {
    final normalizedProfileImageUrl = _normalizeProfileImageUrl(
      profileImageUrl,
    );
    _profileImageUrl = normalizedProfileImageUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profileImageUrl', normalizedProfileImageUrl);
  }

  String? _extractProfileImageUrl(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      final profileImageUrl = data['profile_image_url'];
      if (profileImageUrl is String && profileImageUrl.isNotEmpty) {
        return profileImageUrl;
      }

      final profileImage = data['profile_image'];
      if (profileImage is String && profileImage.isNotEmpty) {
        return profileImage;
      }
    }

    final profileImageUrl = response['profile_image_url'];
    if (profileImageUrl is String && profileImageUrl.isNotEmpty) {
      return profileImageUrl;
    }

    return null;
  }

  String _normalizeProfileImageUrl(String profileImageUrl) {
    if (profileImageUrl.startsWith('http') ||
        profileImageUrl.startsWith('asset/')) {
      return profileImageUrl;
    }

    return Uri.parse(baseUrl).resolve(profileImageUrl).toString();
  }
}
