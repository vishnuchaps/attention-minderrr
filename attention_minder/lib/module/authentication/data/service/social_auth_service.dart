import 'package:attention_minder/constant/app_constant.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';

@injectable
class SocialAuthService {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FacebookAuth _facebookAuth;
  bool _googleSignInInitialized = false;

  SocialAuthService()
    : _firebaseAuth = FirebaseAuth.instance,
      _googleSignIn = GoogleSignIn.instance,
      _facebookAuth = FacebookAuth.instance;

  /// Initialize Google Sign-In (must be called before authentication)
  Future<void> _ensureGoogleSignInInitialized() async {
    if (!_googleSignInInitialized) {
      await _googleSignIn.initialize(serverClientId: googleOAuthServerClientId);
      _googleSignInInitialized = true;
    }
  }

  /// Starts Google Sign-In and returns the Google ID token for backend auth.
  Future<String?> signInWithGoogle() async {
    try {
      await _ensureGoogleSignInInitialized();
      final googleUser = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception('Google did not return an ID token.');
      }

      return idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }

      throw Exception(_googleSignInErrorMessage(e));
    } catch (e) {
      throw Exception('Google Sign-In failed: $e');
    }
  }

  String _googleSignInErrorMessage(GoogleSignInException exception) {
    switch (exception.code) {
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return 'Google Sign-In is not configured correctly. Please verify the OAuth client ID, package name, and SHA fingerprints.';
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'Google Sign-In UI is unavailable on this device.';
      case GoogleSignInExceptionCode.interrupted:
        return 'Google Sign-In was interrupted. Please try again.';
      default:
        final description = exception.description;
        if (description != null &&
            description.toLowerCase().contains('credential')) {
          return 'No Google credential was available. Add a Google account to this device and verify the app package/SHA is configured in Google Cloud.';
        }
        return exception.description ?? 'Google Sign-In failed.';
    }
  }

  /// Starts Facebook Login and returns the Facebook access token for backend auth.
  Future<String?> signInWithFacebook() async {
    try {
      final LoginResult result = await _facebookAuth.login(
        permissions: const ['email', 'public_profile'],
        loginTracking: LoginTracking.enabled,
      );

      if (result.status == LoginStatus.success) {
        final accessToken = result.accessToken?.tokenString;
        if (accessToken == null || accessToken.isEmpty) {
          throw Exception('Facebook did not return an access token.');
        }

        return accessToken;
      } else if (result.status == LoginStatus.cancelled) {
        return null;
      } else if (result.status == LoginStatus.operationInProgress) {
        throw Exception('Facebook Login is already in progress.');
      } else {
        throw Exception('Facebook Sign-In failed: ${result.message}');
      }
    } catch (e) {
      throw Exception('Facebook Sign-In failed: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _facebookAuth.logOut();
    await _firebaseAuth.signOut();
  }
}
