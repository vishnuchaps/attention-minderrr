import 'package:flutter/material.dart';

class SocialLoginButton extends StatefulWidget {
  final String label;
  final String iconPath; // Path to the asset image
  final Color activeBorderColor;
  final Color activeBackgroundColor;
  final Color inactiveBackgroundColor;
  final VoidCallback onTap;

  const SocialLoginButton({
    Key? key,
    required this.label,
    required this.iconPath,
    required this.activeBorderColor,
    required this.activeBackgroundColor,
    required this.inactiveBackgroundColor,
    required this.onTap,
  }) : super(key: key);

  @override
  _SocialLoginButtonState createState() => _SocialLoginButtonState();
}

class _SocialLoginButtonState extends State<SocialLoginButton> {
  bool _isSelected = false;

  void _handleTap() {
    setState(() {
      _isSelected = !_isSelected;
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,

      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: _isSelected
              ? widget.activeBackgroundColor
              : widget.inactiveBackgroundColor,
          border: Border.all(
            color: _isSelected ? widget.activeBorderColor : Colors.transparent,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              widget.iconPath,
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 12),
            Text(
              widget.label,
              style: const TextStyle(
                fontFamily: 'Nunito Sans',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                height: 1.5, // line-height: 24px (24 / 16 = 1.5)
                color: Colors.black, // Text color
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SocialLoginDemo extends StatefulWidget {
  @override
  _SocialLoginDemoState createState() => _SocialLoginDemoState();
}

class _SocialLoginDemoState extends State<SocialLoginDemo> {
  String? _selectedButton; // Tracks the currently selected button

  void _handleButtonTap(String buttonLabel) {
    setState(() {
      _selectedButton = buttonLabel;
    });
    print('$buttonLabel tapped!');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SocialLoginButton(
          label: 'Log in with Facebook',
          iconPath: 'assets/facebook_icon.png', // Replace with your asset path
          activeBorderColor: const Color(0xFF4883F7),
          activeBackgroundColor: const Color(0xFFC9D9F9),
          inactiveBackgroundColor: const Color(0xFFF6F7FA),
          onTap: () => _handleButtonTap('Facebook'),
        ),
        const SizedBox(height: 16),
        SocialLoginButton(
          label: 'Log in with Google',
          iconPath: 'assets/google_icon.png', // Replace with your asset path
          activeBorderColor: const Color(0xFF4883F7),
          activeBackgroundColor: const Color(0xFFC9D9F9),
          inactiveBackgroundColor: const Color(0xFFF6F7FA),
          onTap: () => _handleButtonTap('Google'),
        ),
      ],
    );
  }
}
