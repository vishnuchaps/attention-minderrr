part of 'authentication_bloc.dart';

abstract class AuthenticationEvent {}

class RegisterEvent extends AuthenticationEvent {
  final String name;
  final String email;
  final String password;
  final String conformPassword;

  RegisterEvent({
    required this.name,
    required this.email,
    required this.password,
    required this.conformPassword,
  });
}

class LoginEvent extends AuthenticationEvent {
  final String email;
  final String password;

  LoginEvent({required this.email, required this.password});
}

class ForgotPasswordEvent extends AuthenticationEvent {}

class LoginWithGoogleEvent extends AuthenticationEvent {}

class LoginWithFacebookEvent extends AuthenticationEvent {}

class ForgotPasswordRequested extends AuthenticationEvent {
  final String email;

  ForgotPasswordRequested({required this.email});
}

class OtpVerificationRequested extends AuthenticationEvent {
  final String email;
  final String otp;

  OtpVerificationRequested({required this.email, required this.otp});
}

class ResendPasswordOtpRequested extends AuthenticationEvent {
  final String email;

  ResendPasswordOtpRequested({required this.email});
}

class ChangePasswordRequested extends AuthenticationEvent {
  final String email;
  final String newPassword;

  ChangePasswordRequested({required this.email, required this.newPassword});

  @override
  List<Object> get props => [email, newPassword];
}

class ResetAuthenticationEvent extends AuthenticationEvent {}
