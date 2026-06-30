part of 'profile_bloc.dart';

abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class FetchProfileSuccess extends ProfileState {
  final UserData data;

  FetchProfileSuccess(this.data);
}

class FetchProfileFailed extends ProfileState {
  final String message;

  FetchProfileFailed(this.message);
}

class UpdateProfileSuccess extends ProfileState {
  final String message;
  UpdateProfileSuccess(this.message);
}

class UpdateProfileFailed extends ProfileState {
  final String error;
  UpdateProfileFailed(this.error);
}

class UpdateProfilePictureSuccess extends ProfileState {
  final String message;
  final String? profileImageUrl;

  UpdateProfilePictureSuccess(this.message, {this.profileImageUrl});
}

class UpdateProfilePictureFailed extends ProfileState {
  final String error;
  UpdateProfilePictureFailed(this.error);
}
