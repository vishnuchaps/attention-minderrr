import 'package:attention_minder/module/authentication/data/repository/iauthentication_repository.dart';
import 'package:attention_minder/module/authentication/data/service/social_auth_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'authentication_event.dart';

part 'authentication_state.dart';

@injectable
class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  final IAuthenticationRepository _authRepository;
  final SocialAuthService _socialAuthService;

  AuthenticationBloc(this._authRepository, this._socialAuthService)
    : super(AuthenticationInitial()) {
    on<RegisterEvent>(_onRegister);
    on<LoginEvent>(_onLogin);
    on<ForgotPasswordRequested>(_onForgotPasswordRequested);
    on<OtpVerificationRequested>(_onOtpVerify);
    on<ResendPasswordOtpRequested>(_onResendPasswordOtp);
    on<ChangePasswordRequested>(_onChangePassword);
    on<ResetAuthenticationEvent>(_onReset);
    on<LoginWithGoogleEvent>(_onGoogleLogin);
    on<LoginWithFacebookEvent>(_onFacebookLogin);
  }

  void _onReset(
    ResetAuthenticationEvent event,
    Emitter<AuthenticationState> emit,
  ) {
    emit(AuthenticationInitial());
  }

  void _onLogin(LoginEvent event, Emitter<AuthenticationState> emit) async {
    emit(AuthenticationLoading());

    try {
      final response = await _authRepository.login(
        email: event.email,
        password: event.password,
      );
      // Handle authentication success
      emit(AuthenticationSuccess(response));
      saveUserData(response);
    } catch (e) {
      emit(AuthenticationError(e.toString()));
    }
  }

  void _onRegister(
    RegisterEvent event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(AuthenticationLoading());

    try {
      final response = await _authRepository.register(
        username: event.name,
        email: event.email,
        password: event.password,
        isAdmin: false,
        isStaff: true,
      );

      // Handle registration success
      emit(AuthenticationSuccess(response));
      saveUserData(response, showHomeWalkthrough: true);
    } catch (e) {
      emit(AuthenticationError(e.toString()));
    }
  }

  void _onForgotPasswordRequested(
    ForgotPasswordRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(ForgotPasswordLoading());
    try {
      final response = await _authRepository.requestPasswordReset(
        email: event.email,
      );
      emit(
        ForgotPasswordSuccess(
          message:
              response['message'] ??
              'Password reset request sent successfully.',
        ),
      );
      // Optionally navigate or show a success message here
    } catch (e) {
      emit(ForgotPasswordError(error: e.toString()));
    }
  }

  void _onOtpVerify(
    OtpVerificationRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(OtpVerificationLoading());
    try {
      final response = await _authRepository.verifyOtp(
        email: event.email,
        otp: event.otp,
      );
      emit(
        OtpVerificationSuccess(
          message: response['message'] ?? 'OTP verified successfully',
        ),
      );
    } catch (e) {
      emit(OtpVerificationError(error: e.toString()));
    }
  }

  Future<void> _onResendPasswordOtp(
    ResendPasswordOtpRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(ResendPasswordOtpLoading());
    try {
      final response = await _authRepository.requestPasswordReset(
        email: event.email,
      );
      emit(
        ResendPasswordOtpSuccess(
          message: response['message'] ?? 'A new verification code was sent.',
        ),
      );
    } catch (error) {
      emit(ResendPasswordOtpError(error: error.toString()));
    }
  }

  void _onChangePassword(
    ChangePasswordRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(ChangePasswordLoading());

    try {
      final response = await _authRepository.changePassword(
        email: event.email,
        newPassword: event.newPassword,
      );

      emit(
        ChangePasswordSuccess(
          message: response['message'] ?? 'Password updated successfully',
        ),
      );
    } catch (e) {
      emit(ChangePasswordError(error: e.toString()));
    }
  }

  void _onGoogleLogin(
    LoginWithGoogleEvent event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(AuthenticationLoading());
    try {
      final idToken = await _socialAuthService.signInWithGoogle();
      if (idToken != null) {
        final response = await _authRepository.socialLogin(
          token: idToken,
          provider: 'google',
        );
        emit(AuthenticationSuccess(response));
        saveUserData(response);
      } else {
        emit(AuthenticationInitial()); // User cancelled
      }
    } catch (e) {
      emit(AuthenticationError(e.toString()));
    }
  }

  void _onFacebookLogin(
    LoginWithFacebookEvent event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(AuthenticationLoading());
    try {
      final accessToken = await _socialAuthService.signInWithFacebook();
      if (accessToken != null) {
        final response = await _authRepository.socialLogin(
          token: accessToken,
          provider: 'facebook',
        );
        emit(AuthenticationSuccess(response));
        saveUserData(response);
      } else {
        emit(AuthenticationInitial()); // User cancelled
      }
    } catch (e) {
      emit(AuthenticationError(e.toString()));
    }
  }
}

Future<void> saveUserData(
  Map<String, dynamic> response, {
  bool showHomeWalkthrough = false,
}) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  if (response['status'] == true) {
    final userData = response['data'];

    await prefs.setString('accessToken', userData['tokens']['access']);
    await prefs.setString('refreshToken', userData['tokens']['refresh']);
    await prefs.setInt('userId', userData['id']);
    await prefs.setString('username', userData['username']);
    await prefs.setString('email', userData['email']);
    if (showHomeWalkthrough) {
      await prefs.setBool('showHomeWalkthrough', true);
    }
  }
}
