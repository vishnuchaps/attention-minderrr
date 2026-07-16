part of 'authentication_bloc.dart';

abstract class AuthenticationState {}

class AuthenticationInitial extends AuthenticationState {}

class AuthenticationLoading extends AuthenticationState {}

class AuthenticationSuccess extends AuthenticationState {
  final dynamic data;

  AuthenticationSuccess(this.data);
}

class AuthenticationError extends AuthenticationState {
  final String message;

  AuthenticationError(this.message);
}

class ForgotPasswordLoading extends AuthenticationState {}

class ForgotPasswordSuccess extends AuthenticationState {
  final String message; // Or the response data

  ForgotPasswordSuccess({required this.message});

  @override
  List<Object> get props => [message];
}

class ForgotPasswordError extends AuthenticationState {
  final String error;

  ForgotPasswordError({required this.error});

  @override
  List<Object> get props => [error];
}

class OtpVerificationLoading extends AuthenticationState {}

class OtpVerificationSuccess extends AuthenticationState {
  final String message;
  OtpVerificationSuccess({required this.message});
}

class OtpVerificationError extends AuthenticationState {
  final String error;
  OtpVerificationError({required this.error});
}

class ResendPasswordOtpLoading extends AuthenticationState {}

class ResendPasswordOtpSuccess extends AuthenticationState {
  final String message;

  ResendPasswordOtpSuccess({required this.message});
}

class ResendPasswordOtpError extends AuthenticationState {
  final String error;

  ResendPasswordOtpError({required this.error});
}

class ChangePasswordLoading extends AuthenticationState {}

class ChangePasswordSuccess extends AuthenticationState {
  final String message;
  ChangePasswordSuccess({required this.message});
}

class ChangePasswordError extends AuthenticationState {
  final String error;
  ChangePasswordError({required this.error});
}
