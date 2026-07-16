import 'package:attention_minder/module/authentication/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PasswordChangeSuccessScreen extends StatelessWidget {
  const PasswordChangeSuccessScreen({super.key});

  static const _ink = Color(0xFF061A4D);
  static const _muted = Color(0xFF667394);
  static const _blue = Color(0xFF246BFD);
  static const _green = Color(0xFF25BE78);

  void _continueToLogin(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compactHeight = constraints.maxHeight < 720;
            final veryCompactHeight = constraints.maxHeight < 620;
            final horizontalPadding = (constraints.maxWidth * .05)
                .clamp(16.0, 24.0)
                .toDouble();

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                compactHeight ? 12 : 18,
                horizontalPadding,
                24 + MediaQuery.paddingOf(context).bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      constraints.maxHeight -
                      (compactHeight ? 36 : 42) -
                      MediaQuery.paddingOf(context).bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _BackButton(
                        onPressed: () => Navigator.maybePop(context),
                      ),
                    ),
                    SizedBox(height: veryCompactHeight ? 12 : 22),
                    _SuccessIllustration(
                      size: veryCompactHeight
                          ? 128
                          : compactHeight
                          ? 154
                          : 184,
                    ),
                    SizedBox(height: compactHeight ? 18 : 28),
                    Text(
                      'Success!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: compactHeight ? 26 : 29,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                        height: 1.15,
                        letterSpacing: -.6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _green,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: compactHeight ? 17 : 23),
                    Text(
                      'Your password has been changed successfully.\n'
                      'You can now sign in with your new password.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: compactHeight ? 12.5 : 13.5,
                        fontWeight: FontWeight.w400,
                        color: _muted,
                        height: 1.6,
                      ),
                    ),
                    SizedBox(height: compactHeight ? 22 : 32),
                    const _SecurityConfirmationCard(),
                    SizedBox(height: compactHeight ? 28 : 54),
                    SizedBox(
                      height: compactHeight ? 52 : 56,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2C76FF), Color(0xFF1E5FF0)],
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: _blue.withValues(alpha: .22),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () => _continueToLogin(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Continue to Login',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SecurityConfirmationCard extends StatelessWidget {
  const _SecurityConfirmationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFF1FBF7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDF5EA)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: PasswordChangeSuccessScreen._green,
              size: 23,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your account is secure',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: PasswordChangeSuccessScreen._ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Your password was updated to keep your account protected.',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                    color: PasswordChangeSuccessScreen._muted,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _BackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Back',
      child: Material(
        color: const Color(0xFFF7F9FD),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: const SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: PasswordChangeSuccessScreen._ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessIllustration extends StatelessWidget {
  final double size;

  const _SuccessIllustration({required this.size});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size * .9,
              height: size * .9,
              decoration: BoxDecoration(
                color: const Color(0xFFE9F9F2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD8F4E8), width: 10),
              ),
            ),
            Container(
              width: size * .66,
              height: size * .66,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF34CE88), Color(0xFF18AF67)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF20B970).withValues(alpha: .2),
                    blurRadius: 20,
                    offset: const Offset(0, 9),
                  ),
                ],
              ),
              child: Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: size * .34,
              ),
            ),
            _Sparkle(
              alignment: const Alignment(-.88, -.42),
              color: const Color(0xFF34C789),
              size: size * .1,
            ),
            _Sparkle(
              alignment: const Alignment(.9, -.37),
              color: const Color(0xFF2ABB78),
              size: size * .11,
            ),
            _Sparkle(
              alignment: const Alignment(.93, .5),
              color: const Color(0xFF8E62EE),
              size: size * .09,
            ),
            _Sparkle(
              alignment: const Alignment(-.96, .1),
              color: const Color(0xFF5A8EF5),
              size: size * .075,
            ),
          ],
        ),
      ),
    );
  }
}

class _Sparkle extends StatelessWidget {
  final Alignment alignment;
  final Color color;
  final double size;

  const _Sparkle({
    required this.alignment,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Icon(Icons.auto_awesome_rounded, color: color, size: size),
    );
  }
}
