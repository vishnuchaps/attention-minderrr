import 'package:attention_minder/Config/widgets/loading_widget.dart';
import 'package:attention_minder/constant/asset_path.dart';
import 'package:attention_minder/dependency_injection/injection_container.dart';
import 'package:attention_minder/module/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:attention_minder/module/authentication/presentation/screens/login_screen.dart';
import 'package:attention_minder/module/authentication/presentation/screens/welcome_attention_screen.dart';
import 'package:attention_minder/utils/validators/validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final AuthenticationBloc authenticationBloc = getIt<AuthenticationBloc>();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _RegisterMetrics.of(context);

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
                  builder: (context) => WelcomeAttentionScreen(),
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
                                      _RegisterIllustration(metrics: metrics),
                                      SizedBox(height: metrics.heroGap),
                                      Expanded(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.topCenter,
                                          child: SizedBox(
                                            width:
                                                constraints.maxWidth -
                                                (metrics.pagePadding * 2),
                                            child: _RegisterCard(
                                              metrics: metrics,
                                              state: state,
                                              nameController: nameController,
                                              emailController: emailController,
                                              passwordController:
                                                  passwordController,
                                              confirmPasswordController:
                                                  confirmPasswordController,
                                              obscurePassword: _obscurePassword,
                                              obscureConfirmPassword:
                                                  _obscureConfirmPassword,
                                              onTogglePassword: () {
                                                setState(() {
                                                  _obscurePassword =
                                                      !_obscurePassword;
                                                });
                                              },
                                              onToggleConfirmPassword: () {
                                                setState(() {
                                                  _obscureConfirmPassword =
                                                      !_obscureConfirmPassword;
                                                });
                                              },
                                              onRegister: _handleRegister,
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
                                              onSignIn: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        LoginScreen(),
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

  void _handleRegister() {
    if (_formKey.currentState!.validate()) {
      authenticationBloc.add(
        RegisterEvent(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
          name: nameController.text.trim(),
          conformPassword: confirmPasswordController.text.trim(),
        ),
      );
    }
  }
}

class _RegisterMetrics {
  final double width;
  final double height;
  final double scale;
  final double heightScale;
  final double safeBottom;

  const _RegisterMetrics({
    required this.width,
    required this.height,
    required this.scale,
    required this.heightScale,
    required this.safeBottom,
  });

  factory _RegisterMetrics.of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return _RegisterMetrics(
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
  double get topPadding => tinyHeight ? v(3) : v(7);
  double get bottomPadding => safeBottom + (tinyHeight ? v(3) : v(8));
  double get heroGap => tinyHeight ? v(1) : v(5);
  double get cardPadding => tinyHeight ? s(18) : s(22);
  double get cardVerticalPadding => tinyHeight ? v(17) : v(23);
  double get fieldHeight => tinyHeight ? 45 : (shortHeight ? 48 : 52);
  double get buttonHeight => tinyHeight ? 45 : (shortHeight ? 48 : 53);
  double get socialHeight => tinyHeight ? 40 : (shortHeight ? 43 : 47);

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

class _RegisterIllustration extends StatelessWidget {
  final _RegisterMetrics metrics;

  const _RegisterIllustration({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final height = metrics.tinyHeight
        ? metrics.v(84)
        : metrics.shortHeight
        ? metrics.v(108)
        : metrics.v(150);

    return SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(
        painter: _RegisterBackgroundPainter(),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: height * .08,
              child: Container(
                width: metrics.s(metrics.tinyHeight ? 88 : 128),
                height: metrics.s(metrics.tinyHeight ? 88 : 128),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .58),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: -height * .02,
              child: Image.asset(
                onBoardingImage,
                width: metrics.s(metrics.tinyHeight ? 154 : 210),
                height: height,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              right: metrics.s(63),
              top: height * .38,
              child: Icon(
                Icons.auto_awesome_rounded,
                color: const Color(0xFFF6B739),
                size: metrics.s(metrics.tinyHeight ? 15 : 19),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegisterBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final loopPaint = Paint()
      ..color = const Color(0xFFF5B941)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final loop = Path()
      ..moveTo(-size.width * .13, size.height * .5)
      ..cubicTo(
        size.width * .06,
        size.height * .18,
        size.width * .38,
        size.height * .22,
        size.width * .31,
        size.height * .58,
      )
      ..cubicTo(
        size.width * .18,
        size.height * .9,
        -size.width * .12,
        size.height * .74,
        -size.width * .02,
        size.height * .45,
      );
    canvas.drawPath(loop, loopPaint);

    final dotPaint = Paint()
      ..color = const Color(0xFFF6B739)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * .83, size.height * .42), 2, dotPaint);
    canvas.drawCircle(Offset(size.width * .39, size.height * .72), 2, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RegisterCard extends StatelessWidget {
  final _RegisterMetrics metrics;
  final AuthenticationState state;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final VoidCallback onRegister;
  final VoidCallback onFacebookLogin;
  final VoidCallback onGoogleLogin;
  final VoidCallback onSignIn;

  const _RegisterCard({
    required this.metrics,
    required this.state,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onRegister,
    required this.onFacebookLogin,
    required this.onGoogleLogin,
    required this.onSignIn,
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
            'Create account',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunitoSans(
              color: const Color(0xFF10162F),
              fontSize: metrics.font(26),
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          SizedBox(height: metrics.gap(8, short: 6, tiny: 4)),
          Text(
            'Start your attention journey',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunitoSans(
              color: const Color(0xFF737A94),
              fontSize: metrics.font(15),
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
          SizedBox(height: metrics.gap(22, short: 15, tiny: 11)),
          _RegisterTextField(
            metrics: metrics,
            controller: nameController,
            hintText: 'Name',
            icon: Icons.person_outline_rounded,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Name is required';
              }
              return null;
            },
          ),
          SizedBox(height: metrics.gap(12, short: 9, tiny: 7)),
          _RegisterTextField(
            metrics: metrics,
            controller: emailController,
            hintText: 'Email',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: validateEmail,
          ),
          SizedBox(height: metrics.gap(12, short: 9, tiny: 7)),
          _RegisterTextField(
            metrics: metrics,
            controller: passwordController,
            hintText: 'Password',
            icon: Icons.lock_outline_rounded,
            obscureText: obscurePassword,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
            suffix: IconButton(
              onPressed: onTogglePassword,
              splashRadius: metrics.s(21),
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: const Color(0xFF11162E),
                size: metrics.s(22),
              ),
            ),
          ),
          SizedBox(height: metrics.gap(12, short: 9, tiny: 7)),
          _RegisterTextField(
            metrics: metrics,
            controller: confirmPasswordController,
            hintText: 'Confirm Password',
            icon: Icons.lock_reset_rounded,
            obscureText: obscureConfirmPassword,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Confirm Password is required';
              }
              if (value != passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
            suffix: IconButton(
              onPressed: onToggleConfirmPassword,
              splashRadius: metrics.s(21),
              icon: Icon(
                obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: const Color(0xFF11162E),
                size: metrics.s(22),
              ),
            ),
          ),
          if (errorMessage != null) ...[
            SizedBox(height: metrics.gap(10, short: 8, tiny: 6)),
            _RegisterErrorMessage(metrics: metrics, message: errorMessage),
          ],
          SizedBox(height: metrics.gap(18, short: 12, tiny: 9)),
          _RegisterPrimaryButton(metrics: metrics, onTap: onRegister),
          SizedBox(height: metrics.gap(15, short: 10, tiny: 7)),
          _RegisterDividerLabel(metrics: metrics),
          SizedBox(height: metrics.gap(15, short: 10, tiny: 7)),
          _RegisterSocialButton(
            metrics: metrics,
            iconPath: facebookIcon,
            label: 'Continue with Facebook',
            onTap: onFacebookLogin,
          ),
          SizedBox(height: metrics.gap(11, short: 8, tiny: 6)),
          _RegisterSocialButton(
            metrics: metrics,
            iconPath: googleIcon,
            label: 'Continue with Google',
            onTap: onGoogleLogin,
          ),
          SizedBox(height: metrics.gap(22, short: 14, tiny: 10)),
          _SignInPrompt(metrics: metrics, onTap: onSignIn),
        ],
      ),
    );
  }
}

class _RegisterTextField extends StatelessWidget {
  final _RegisterMetrics metrics;
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final Widget? suffix;

  const _RegisterTextField({
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
        fontSize: metrics.font(15),
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.nunitoSans(
          color: const Color(0xFF7B8298),
          fontSize: metrics.font(15),
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Padding(
          padding: EdgeInsets.only(left: metrics.s(15), right: metrics.s(12)),
          child: Icon(
            icon,
            color: const Color(0xFF0F79FF),
            size: metrics.s(22),
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

class _RegisterErrorMessage extends StatelessWidget {
  final _RegisterMetrics metrics;
  final String message;

  const _RegisterErrorMessage({required this.metrics, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(metrics.s(11)),
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
                fontSize: metrics.font(12.2),
                fontWeight: FontWeight.w600,
                height: 1.32,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterPrimaryButton extends StatelessWidget {
  final _RegisterMetrics metrics;
  final VoidCallback onTap;

  const _RegisterPrimaryButton({required this.metrics, required this.onTap});

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
              'Register',
              style: GoogleFonts.nunitoSans(
                color: Colors.white,
                fontSize: metrics.font(17),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterDividerLabel extends StatelessWidget {
  final _RegisterMetrics metrics;

  const _RegisterDividerLabel({required this.metrics});

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
              fontSize: metrics.font(14.5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFD8DDE8), thickness: 1)),
      ],
    );
  }
}

class _RegisterSocialButton extends StatelessWidget {
  final _RegisterMetrics metrics;
  final String iconPath;
  final String label;
  final VoidCallback onTap;

  const _RegisterSocialButton({
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
                width: metrics.s(24),
                height: metrics.s(24),
              ),
              SizedBox(width: metrics.s(18)),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunitoSans(
                    color: const Color(0xFF11162E),
                    fontSize: metrics.font(15),
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

class _SignInPrompt extends StatelessWidget {
  final _RegisterMetrics metrics;
  final VoidCallback onTap;

  const _SignInPrompt({required this.metrics, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: GoogleFonts.nunitoSans(
            color: const Color(0xFF737A94),
            fontSize: metrics.font(14),
            fontWeight: FontWeight.w500,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            'Sign In',
            style: GoogleFonts.nunitoSans(
              color: const Color(0xFF0F79FF),
              fontSize: metrics.font(14),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
