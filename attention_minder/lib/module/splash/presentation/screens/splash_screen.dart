import 'dart:async';
import 'dart:convert';

import 'package:attention_minder/constant/asset_path.dart';
import 'package:attention_minder/module/authentication/presentation/screens/login_screen.dart';
import 'package:attention_minder/module/on_boarding/presentation/screens/on_boarding_screen.dart';
import 'package:attention_minder/module/profile/presentation/screens/profile_gate_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkTokenAndNavigate();
  }

  Future<void> _checkTokenAndNavigate() async {
    // Add a small delay for branding visibility
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    if (accessToken == null || accessToken.isEmpty) {
      _navigateToOnboarding();

      return;
    }

    if (_isTokenExpired(accessToken)) {
      // Token expired - User must login again
      _navigateToLogin();
    } else {
      // Token valid - check profile completion before entering Home
      _navigateToProfileGate();
    }
  }

  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return true; // Invalid token format
      }

      final payload = _decodeBase64(parts[1]);
      final payloadMap = json.decode(payload);

      if (payloadMap is Map<String, dynamic> && payloadMap.containsKey('exp')) {
        final exp = payloadMap['exp'];
        if (exp is int) {
          final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
          return DateTime.now().isAfter(expiryDate);
        }
      }

      // If no exp claim, assume valid or invalid based on policy.
      // Usually JWTs have exp. If not, we might assume valid.
      return false;
    } catch (e) {
      // Decoding failed
      return true;
    }
  }

  String _decodeBase64(String str) {
    String output = str.replaceAll('-', '+').replaceAll('_', '/');
    switch (output.length % 4) {
      case 0:
        break;
      case 2:
        output += '==';
        break;
      case 3:
        output += '=';
        break;
      default:
        throw Exception('Illegal base64url string!"');
    }
    return utf8.decode(base64Url.decode(output));
  }

  void _navigateToOnboarding() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const OnBoardingScreen()),
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _navigateToProfileGate() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const ProfileGateScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              onBoardingImage,
              height: 200,
              width: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            Text(
              'Attention Minder',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 48),
            // Optional: Loading indicator
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
