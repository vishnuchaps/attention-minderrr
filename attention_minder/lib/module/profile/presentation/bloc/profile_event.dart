part of 'profile_bloc.dart';

abstract class ProfileEvent {}

class GetTheProfileEvent extends ProfileEvent {}

class UpdateProfileEvent extends ProfileEvent {
  final Map<String, dynamic> userData;
  UpdateProfileEvent(this.userData);
}

class UpdateProfilePictureEvent extends ProfileEvent {
  final FormData formData;
  UpdateProfilePictureEvent(this.formData);
}
 