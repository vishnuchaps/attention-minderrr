import 'package:attention_minder/Config/widgets/loading_widget.dart';
import 'package:attention_minder/constant/asset_path.dart';
import 'package:attention_minder/dependency_injection/injection_container.dart';
import 'package:attention_minder/module/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:attention_minder/module/authentication/presentation/screens/forgot_screen.dart';
import 'package:attention_minder/module/authentication/presentation/screens/registration_screen.dart';
import 'package:attention_minder/module/profile/presentation/screens/profile_gate_screen.dart';
import 'package:attention_minder/utils/validators/validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthenticationBloc authenticationBloc = getIt<AuthenticationBloc>();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _LoginMetrics.of(context);

    return BlocProvider.value(
      value: authenticationBloc,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7FBFF),
        resizeToAvoidBottomInset: false,
        body: BlocListener<AuthenticationBloc, AuthenticationState>(
          listener: (context, state) {
            if (state is AuthenticationSuccess) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileGateScreen(),
                ),
              );
            } else if (state is AuthenticationError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 4),
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.only(
                    bottom: metrics.height * 0.7,
                    left: metrics.width * 0.04,
                    right: metrics.width * 0.04,
                  ),
                ),
              );
            }
          },
          child: BlocBuilder<AuthenticationBloc, AuthenticationState>(
            builder: (context, state) {
              final isLoading = state is AuthenticationLoading;

              return Stack(
                children: [
                  Form(
                    key: _formKey,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFFFF8E8),
                            Color(0xFFFFFFFF),
                            Color(0xFFEAF6FF),
                          ],
                          stops: [0, .54, 1],
                        ),
                      ),
                      child: SafeArea(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    metrics.pagePadding,
                                    metrics.topPadding,
                                    metrics.pagePadding,
                                    metrics.bottomPadding,
                                  ),
                                  child: Column(
                                    children: [
                                      _LoginIllustration(metrics: metrics),
                                      SizedBox(height: metrics.heroGap),
                                      Expanded(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.topCenter,
                                          child: SizedBox(
                                            width:
                                                constraints.maxWidth -
                                                (metrics.pagePadding * 2),
                                            child: _LoginCard(
                                              metrics: metrics,
                                              state: state,
                                              emailController: emailController,
                                              passwordController:
                                                  passwordController,
                                              obscurePassword: _obscurePassword,
                                              onTogglePassword: () {
                                                setState(() {
                                                  _obscurePassword =
                                                      !_obscurePassword;
                                                });
                                              },
                                              onLogin: _handleLogin,
                                              onForgotPassword: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        ForgotPasswordScreen(),
                                                  ),
                                                );
                                              },
                                              onFacebookLogin: () {
                                                authenticationBloc.add(
                                                  LoginWithFacebookEvent(),
                                                );
                                              },
                                              onGoogleLogin: () {
                                                authenticationBloc.add(
                                                  LoginWithGoogleEvent(),
                                                );
                                              },
                                              onRegister: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        RegistrationScreen(),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (isLoading) const LoadingWidget(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      authenticationBloc.add(
        LoginEvent(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        ),
      );
    }
  }
}

class _LoginMetrics {
  final double width;
  final double height;
  final double scale;
  final double heightScale;
  final double safeBottom;

  const _LoginMetrics({
    required this.width,
    required this.height,
    required this.scale,
    required this.heightScale,
    required this.safeBottom,
  });

  factory _LoginMetrics.of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return _LoginMetrics(
      width: size.width,
      height: size.height,
      scale: (size.width / 430).clamp(.82, 1.0).toDouble(),
      heightScale: (size.height / 844).clamp(.72, 1.0).toDouble(),
      safeBottom: MediaQuery.paddingOf(context).bottom,
    );
  }

  bool get shortHeight => height < 720;
  bool get tinyHeight => height < 640;
  double get pagePadding => s(width < 360 ? 14 : 18);
  double get topPadding => tinyHeight ? v(4) : v(8);
  double get bottomPadding => safeBottom + (tinyHeight ? v(4) : v(10));
  double get heroGap => tinyHeight ? v(2) : v(7);
  double get cardPadding => s(22);
  double get cardVerticalPadding => tinyHeight ? v(21) : v(28);
  double get fieldHeight => tinyHeight ? 50 : (shortHeight ? 53 : 56);
  double get buttonHeight => tinyHeight ? 50 : (shortHeight ? 53 : 58);
  double get socialHeight => tinyHeight ? 46 : (shortHeight ? 48 : 51);

  double gap(double regular, {double? short, double? tiny}) {
    if (tinyHeight) return v(tiny ?? short ?? regular);
    if (shortHeight) return v(short ?? regular);
    return v(regular);
  }

  double s(double value) => value * scale;
  double v(double value) => value * heightScale;

  double font(double value) {
    final scaled = value * scale;
    return scaled.clamp(value * .84, value).toDouble();
  }
}

class _LoginIllustration extends StatelessWidget {
  final _LoginMetrics metrics;

  const _LoginIllustration({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final height = metrics.tinyHeight
        ? metrics.v(112)
        : metrics.shortHeight
        ? metrics.v(148)
        : metrics.v(206);

    return SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(
        painter: _LoginBackgroundPainter(),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: height * .14,
              child: Container(
                width: metrics.s(metrics.tinyHeight ? 112 : 158),
                height: metrics.s(metrics.tinyHeight ? 112 : 158),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .58),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: height * .04,
              child: Image.asset(
                onBoardingImage,
                width: metrics.s(metrics.tinyHeight ? 174 : 232),
                height: height * .94,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              right: metrics.s(58),
              top: height * .45,
              child: Icon(
                Icons.auto_awesome_rounded,
                color: const Color(0xFFF6B739),
                size: metrics.s(metrics.tinyHeight ? 17 : 22),
              ),
            ),
            Positioned(
              left: metrics.s(101),
              bottom: height * .14,
              child: Container(
                width: metrics.s(metrics.tinyHeight ? 7 : 9),
                height: metrics.s(metrics.tinyHeight ? 7 : 9),
                decoration: const BoxDecoration(
                  color: Color(0xFFF5B73D),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final loopPaint = Paint()
      ..color = const Color(0xFFF5B941)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    final loop = Path()
      ..moveTo(-size.width * .1, size.height * .46)
      ..cubicTo(
        size.width * .08,
        size.height * .18,
        size.width * .44,
        size.height * .24,
        size.width * .34,
        size.height * .59,
      )
      ..cubicTo(
        size.width * .2,
        size.height * .9,
        -size.width * .12,
        size.height * .76,
        -size.width * .02,
        size.height * .44,
      )
      ..cubicTo(
        size.width * .06,
        size.height * .2,
        size.width * .36,
        size.height * .12,
        size.width * .34,
        size.height * .02,
      );
    canvas.drawPath(loop, loopPaint);

    final dotPaint = Paint()
      ..color = const Color(0xFFF6B739)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * .83, size.height * .37),
      2.2,
      dotPaint,
    );
    canvas.drawCircle(
      Offset(size.width * .39, size.height * .68),
      2.1,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LoginCard extends StatelessWidget {
  final _LoginMetrics metrics;
  final AuthenticationState state;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;
  final VoidCallback onForgotPassword;
  final VoidCallback onFacebookLogin;
  final VoidCallback onGoogleLogin;
  final VoidCallback onRegister;

  const _LoginCard({
    required this.metrics,
    required this.state,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.onLogin,
    required this.onForgotPassword,
    required this.onFacebookLogin,
    required this.onGoogleLogin,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    final authState = state;
    final errorMessage = authState is AuthenticationError
        ? authState.message
        : null;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        metrics.cardPadding,
        metrics.cardVerticalPadding,
        metrics.cardPadding,
        metrics.cardVerticalPadding,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(metrics.s(26)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9DBBDA).withValues(alpha: .15),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Welcome',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunitoSans(
              color: const Color(0xFF10162F),
              fontSize: metrics.font(27),
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          SizedBox(height: metrics.gap(9, short: 7, tiny: 6)),
          Text(
            'Sign in to continue your journey',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunitoSans(
              color: const Color(0xFF737A94),
              fontSize: metrics.font(15.5),
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
          SizedBox(height: metrics.gap(30, short: 21, tiny: 18)),
          _LoginTextField(
            metrics: metrics,
            controller: emailController,
            hintText: 'Email',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: validateEmail,
          ),
          SizedBox(height: metrics.gap(16, short: 12, tiny: 10)),
          _LoginTextField(
            metrics: metrics,
            controller: passwordController,
            hintText: 'Password',
            icon: Icons.lock_outline_rounded,
            obscureText: obscurePassword,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              return null;
            },
            suffix: IconButton(
              onPressed: onTogglePassword,
              splashRadius: metrics.s(22),
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: const Color(0xFF11162E),
                size: metrics.s(23),
              ),
            ),
          ),
          if (errorMessage != null) ...[
            SizedBox(height: metrics.gap(14, short: 9, tiny: 7)),
            _ErrorMessage(metrics: metrics, message: errorMessage),
          ],
          SizedBox(height: metrics.gap(22, short: 16, tiny: 14)),
          _PrimaryLoginButton(metrics: metrics, onTap: onLogin),
          SizedBox(height: metrics.gap(11, short: 7, tiny: 4)),
          TextButton(
            onPressed: onForgotPassword,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF0F79FF),
              padding: EdgeInsets.symmetric(
                horizontal: metrics.s(12),
                vertical: metrics.v(4),
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Forgot Password?',
              style: GoogleFonts.nunitoSans(
                fontSize: metrics.font(16),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: metrics.gap(12, short: 8, tiny: 5)),
          _DividerLabel(metrics: metrics),
          SizedBox(height: metrics.gap(22, short: 16, tiny: 13)),
          _SocialButton(
            metrics: metrics,
            iconPath: facebookIcon,
            label: 'Continue with Facebook',
            onTap: onFacebookLogin,
          ),
          SizedBox(height: metrics.gap(14, short: 10, tiny: 8)),
          _SocialButton(
            metrics: metrics,
            iconPath: googleIcon,
            label: 'Continue with Google',
            onTap: onGoogleLogin,
          ),
          SizedBox(height: metrics.gap(31, short: 22, tiny: 18)),
          _RegisterPrompt(metrics: metrics, onTap: onRegister),
        ],
      ),
    );
  }
}

class _LoginTextField extends StatelessWidget {
  final _LoginMetrics metrics;
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final Widget? suffix;

  const _LoginTextField({
    required this.metrics,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.validator,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: GoogleFonts.nunitoSans(
        color: const Color(0xFF11162E),
        fontSize: metrics.font(15.5),
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.nunitoSans(
          color: const Color(0xFF7B8298),
          fontSize: metrics.font(15.5),
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Padding(
          padding: EdgeInsets.only(left: metrics.s(15), right: metrics.s(12)),
          child: Icon(
            icon,
            color: const Color(0xFF0F79FF),
            size: metrics.s(23),
          ),
        ),
        prefixIconConstraints: BoxConstraints(
          minWidth: metrics.s(51),
          minHeight: metrics.fieldHeight,
        ),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: metrics.s(17),
          vertical: 0,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(metrics.s(12)),
          borderSide: const BorderSide(color: Color(0xFFD8DDE8), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(metrics.s(12)),
          borderSide: const BorderSide(color: Color(0xFF0F79FF), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(metrics.s(12)),
          borderSide: const BorderSide(color: Color(0xFFE25B5B), width: 1.3),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(metrics.s(12)),
          borderSide: const BorderSide(color: Color(0xFFE25B5B), width: 1.3),
        ),
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  final _LoginMetrics metrics;
  final String message;

  const _ErrorMessage({required this.metrics, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(metrics.s(12)),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(metrics.s(11)),
        border: Border.all(color: const Color(0xFFF3B6B6)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: const Color(0xFFC73E3E),
            size: metrics.s(20),
          ),
          SizedBox(width: metrics.s(8)),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.nunitoSans(
                color: const Color(0xFFC73E3E),
                fontSize: metrics.font(12.5),
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryLoginButton extends StatelessWidget {
  final _LoginMetrics metrics;
  final VoidCallback onTap;

  const _PrimaryLoginButton({required this.metrics, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0F79FF),
      borderRadius: BorderRadius.circular(metrics.s(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(metrics.s(12)),
        onTap: onTap,
        child: SizedBox(
          width: double.infinity,
          height: metrics.buttonHeight,
          child: Center(
            child: Text(
              'Log in',
              style: GoogleFonts.nunitoSans(
                color: Colors.white,
                fontSize: metrics.font(18),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DividerLabel extends StatelessWidget {
  final _LoginMetrics metrics;

  const _DividerLabel({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFD8DDE8), thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: metrics.s(18)),
          child: Text(
            'or',
            style: GoogleFonts.nunitoSans(
              color: const Color(0xFF777E94),
              fontSize: metrics.font(15),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFD8DDE8), thickness: 1)),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final _LoginMetrics metrics;
  final String iconPath;
  final String label;
  final VoidCallback onTap;

  const _SocialButton({
    required this.metrics,
    required this.iconPath,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(metrics.s(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(metrics.s(12)),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: metrics.socialHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(metrics.s(12)),
            border: Border.all(color: const Color(0xFFD8DDE8), width: 1.4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                iconPath,
                width: metrics.s(25),
                height: metrics.s(25),
              ),
              SizedBox(width: metrics.s(18)),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunitoSans(
                    color: const Color(0xFF11162E),
                    fontSize: metrics.font(15.5),
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegisterPrompt extends StatelessWidget {
  final _LoginMetrics metrics;
  final VoidCallback onTap;

  const _RegisterPrompt({required this.metrics, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: GoogleFonts.nunitoSans(
            color: const Color(0xFF737A94),
            fontSize: metrics.font(14.5),
            fontWeight: FontWeight.w500,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            'Register',
            style: GoogleFonts.nunitoSans(
              color: const Color(0xFF0F79FF),
              fontSize: metrics.font(14.5),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
