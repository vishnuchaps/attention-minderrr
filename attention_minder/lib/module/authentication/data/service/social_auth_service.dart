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
      await _googleSignIn.initialize(
        serverClientId:
            '908828655450-tnfd4g2tn7s037j3hkt02skclv8f642u.apps.googleusercontent.com',
      );
      _googleSignInInitialized = true;
    }
  }

  /// Sign in with Google
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      await _ensureGoogleSignInInitialized();
      final googleUser = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      return {'credential': userCredential, 'idToken': googleAuth.idToken};
    } on GoogleSignInException catch (e) {
      print("Code: ${e.code}");
      print("Description: ${e.description}");
      print("Details: ${e.details}");

      throw Exception('Google Sign-In failed: ${e.code} - ${e.description}');
    } catch (e) {
      throw Exception('Google Sign-In failed: $e');
    }
  }

  /// Sign in with Facebook
  Future<UserCredential?> signInWithFacebook() async {
    try {
      final LoginResult result = await _facebookAuth.login();

      if (result.status == LoginStatus.success) {
        final OAuthCredential credential = FacebookAuthProvider.credential(
          result.accessToken!.tokenString,
        );

        return await _firebaseAuth.signInWithCredential(credential);
      } else if (result.status == LoginStatus.cancelled) {
        return null;
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
