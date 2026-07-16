import 'package:attention_minder/module/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:attention_minder/module/authentication/presentation/screens/otp_verification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const _ink = Color(0xFF061A4D);
  static const _muted = Color(0xFF667394);
  static const _blue = Color(0xFF246BFD);
  static const _fieldBorder = Color(0xFFD7E1FA);

  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email address';
    final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailPattern.hasMatch(email)) return 'Enter a valid email address';
    return null;
  }

  void _requestPasswordReset(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<AuthenticationBloc>().add(
      ForgotPasswordRequested(email: _emailController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: BlocConsumer<AuthenticationBloc, AuthenticationState>(
        listener: (context, state) {
          if (state is ForgotPasswordSuccess) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    state.message.isEmpty
                        ? 'Password reset instructions sent.'
                        : state.message,
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    OtpVerificationScreen(email: _emailController.text.trim()),
              ),
            );
          } else if (state is ForgotPasswordError) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  behavior: SnackBarBehavior.floating,
                ),
              );
          }
        },
        builder: (context, state) {
          final isLoading = state is ForgotPasswordLoading;
          return SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compactHeight = constraints.maxHeight < 720;
                final veryCompactHeight = constraints.maxHeight < 620;
                final horizontalPadding = (constraints.maxWidth * .05)
                    .clamp(16.0, 24.0)
                    .toDouble();

                return AutofillGroup(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      compactHeight ? 12 : 18,
                      horizontalPadding,
                      24 + MediaQuery.viewInsetsOf(context).bottom,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight:
                            constraints.maxHeight - (compactHeight ? 36 : 42),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: _BackButton(
                                onPressed: isLoading
                                    ? null
                                    : () => Navigator.maybePop(context),
                              ),
                            ),
                            SizedBox(height: veryCompactHeight ? 8 : 12),
                            _SecurityIllustration(
                              size: veryCompactHeight
                                  ? 104
                                  : compactHeight
                                  ? 130
                                  : 164,
                            ),
                            SizedBox(height: compactHeight ? 12 : 20),
                            Text(
                              'Forgot Password?',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: compactHeight ? 24 : 27,
                                fontWeight: FontWeight.w700,
                                color: _ink,
                                height: 1.15,
                                letterSpacing: -.7,
                              ),
                            ),
                            SizedBox(height: compactHeight ? 8 : 12),
                            Text(
                              'No worries! Enter your email and we’ll send you '
                              'instructions to reset your password.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: compactHeight ? 12.5 : 13.5,
                                fontWeight: FontWeight.w400,
                                color: _muted,
                                height: 1.55,
                              ),
                            ),
                            SizedBox(height: compactHeight ? 20 : 30),
                            Text(
                              'Email Address',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _ink,
                              ),
                            ),
                            const SizedBox(height: 9),
                            TextFormField(
                              controller: _emailController,
                              focusNode: _emailFocusNode,
                              enabled: !isLoading,
                              validator: _validateEmail,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.email],
                              autocorrect: false,
                              enableSuggestions: false,
                              inputFormatters: [
                                FilteringTextInputFormatter.deny(RegExp(r'\s')),
                              ],
                              onFieldSubmitted: (_) {
                                if (!isLoading) {
                                  _requestPasswordReset(context);
                                }
                              },
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _ink,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter your email address',
                                hintStyle: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF8A94AE),
                                ),
                                prefixIcon: const Icon(
                                  Icons.mail_outline_rounded,
                                  color: Color(0xFF77829B),
                                  size: 20,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 17,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: _fieldOutline(_fieldBorder),
                                enabledBorder: _fieldOutline(_fieldBorder),
                                focusedBorder: _fieldOutline(_blue, width: 1.7),
                                errorBorder: _fieldOutline(
                                  const Color(0xFFCB3A31),
                                ),
                                focusedErrorBorder: _fieldOutline(
                                  const Color(0xFFCB3A31),
                                  width: 1.7,
                                ),
                              ),
                            ),
                            SizedBox(height: compactHeight ? 14 : 18),
                            const _InformationBanner(),
                            SizedBox(height: compactHeight ? 18 : 22),
                            SizedBox(
                              height: 56,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: isLoading
                                      ? const LinearGradient(
                                          colors: [
                                            Color(0xFF79A3FF),
                                            Color(0xFF79A3FF),
                                          ],
                                        )
                                      : const LinearGradient(
                                          colors: [
                                            Color(0xFF2C76FF),
                                            Color(0xFF1E5FF0),
                                          ],
                                        ),
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: isLoading
                                      ? null
                                      : [
                                          BoxShadow(
                                            color: _blue.withValues(alpha: .22),
                                            blurRadius: 18,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                ),
                                child: ElevatedButton(
                                  onPressed: isLoading
                                      ? null
                                      : () => _requestPasswordReset(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    disabledBackgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    disabledForegroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 180),
                                    child: isLoading
                                        ? const SizedBox(
                                            key: ValueKey('loading'),
                                            width: 23,
                                            height: 23,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.4,
                                            ),
                                          )
                                        : Row(
                                            key: const ValueKey('label'),
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Reset Password',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              const Icon(
                                                Icons.arrow_forward_rounded,
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: compactHeight ? 20 : 28),
                            Text(
                              'Remember your password?',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w400,
                                color: _muted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () => Navigator.maybePop(context),
                              style: TextButton.styleFrom(
                                foregroundColor: _blue,
                                minimumSize: const Size(48, 44),
                              ),
                              child: Text(
                                'Back to Sign In',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  OutlineInputBorder _fieldOutline(Color color, {double width = 1.35}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback? onPressed;

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
              color: _ForgotPasswordScreenState._ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _InformationBanner extends StatelessWidget {
  const _InformationBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FF),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: _ForgotPasswordScreenState._blue,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'We’ll send password reset instructions to your registered '
              'email address.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _ForgotPasswordScreenState._muted,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityIllustration extends StatelessWidget {
  final double size;

  const _SecurityIllustration({required this.size});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: size * .83,
              height: size * .83,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFE8EEFF),
                    const Color(0xFFF5F7FF).withValues(alpha: .35),
                  ],
                ),
              ),
            ),
            Positioned(
              top: size * .17,
              child: Container(
                width: size * .37,
                height: size * .38,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFF92AEFF),
                    width: size * .095,
                  ),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(size * .2),
                  ),
                ),
              ),
            ),
            Positioned(
              top: size * .39,
              child: Container(
                width: size * .61,
                height: size * .42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFC8D7FF), Color(0xFFAFC2FB)],
                  ),
                  borderRadius: BorderRadius.circular(size * .1),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF577BE8).withValues(alpha: .14),
                      blurRadius: 18,
                      offset: const Offset(0, 9),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.key_rounded,
                  color: const Color(0xFF2C5DE0),
                  size: size * .2,
                ),
              ),
            ),
            Positioned(
              right: size * .08,
              bottom: size * .13,
              child: Container(
                width: size * .32,
                height: size * .36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF367CFF), Color(0xFF1556E8)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(size * .07),
                    topRight: Radius.circular(size * .07),
                    bottomLeft: Radius.circular(size * .16),
                    bottomRight: Radius.circular(size * .16),
                  ),
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: size * .19,
                ),
              ),
            ),
            _Sparkle(
              alignment: const Alignment(-.88, -.55),
              color: const Color(0xFFFFBC18),
              size: size * .12,
            ),
            _Sparkle(
              alignment: const Alignment(.88, -.24),
              color: const Color(0xFF8854F6),
              size: size * .1,
            ),
            _Sparkle(
              alignment: const Alignment(-.96, .48),
              color: const Color(0xFF5487F7),
              size: size * .08,
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
