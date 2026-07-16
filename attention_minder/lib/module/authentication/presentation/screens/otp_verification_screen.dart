import 'dart:async';

import 'package:attention_minder/module/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:attention_minder/module/authentication/presentation/screens/set_new_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with WidgetsBindingObserver {
  static const _ink = Color(0xFF061A4D);
  static const _muted = Color(0xFF667394);
  static const _blue = Color(0xFF246BFD);
  static const _codeLifetime = Duration(minutes: 10);

  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();
  Timer? _countdownTimer;
  late DateTime _expiresAt;
  Duration _remaining = _codeLifetime;

  bool get _isExpired => _remaining == Duration.zero;
  bool get _isComplete => _otpController.text.length == 6;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restartCountdown();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _otpFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshRemainingTime();
  }

  void _restartCountdown() {
    _countdownTimer?.cancel();
    _expiresAt = DateTime.now().add(_codeLifetime);
    _refreshRemainingTime();
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _refreshRemainingTime(),
    );
  }

  void _refreshRemainingTime() {
    if (!mounted) return;
    final difference = _expiresAt.difference(DateTime.now());
    final next = difference.isNegative ? Duration.zero : difference;
    if (next == _remaining) return;
    setState(() => _remaining = next);
    if (next == Duration.zero) _countdownTimer?.cancel();
  }

  String get _countdownText {
    final totalSeconds = (_remaining.inMilliseconds + 999) ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  void _verifyCode(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_isExpired) {
      _showMessage(context, 'This code has expired. Request a new code.');
      return;
    }
    if (!_isComplete) {
      _showMessage(context, 'Enter the complete 6-digit code.');
      _otpFocusNode.requestFocus();
      return;
    }
    context.read<AuthenticationBloc>().add(
      OtpVerificationRequested(
        email: widget.email.trim(),
        otp: _otpController.text,
      ),
    );
  }

  void _resendCode(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
    context.read<AuthenticationBloc>().add(
      ResendPasswordOtpRequested(email: widget.email.trim()),
    );
  }

  void _showMessage(BuildContext context, String message, {bool error = true}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? const Color(0xFFB42318) : null,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: BlocConsumer<AuthenticationBloc, AuthenticationState>(
        listener: (context, state) {
          if (state is OtpVerificationSuccess) {
            _showMessage(context, state.message, error: false);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => SetNewPasswordScreen(email: widget.email),
              ),
            );
          } else if (state is OtpVerificationError) {
            _showMessage(context, state.error);
         
          } else if (state is ResendPasswordOtpSuccess) {
            _otpController.clear();
            _restartCountdown();
            _otpFocusNode.requestFocus();
            _showMessage(context, state.message, error: false);
          } else if (state is ResendPasswordOtpError) {
            _showMessage(context, state.error);
          }
        },
        builder: (context, state) {
          final isVerifying = state is OtpVerificationLoading;
          final isResending = state is ResendPasswordOtpLoading;
          final interactionsLocked = isVerifying || isResending;

          return SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compactHeight = constraints.maxHeight < 740;
                final veryCompactHeight = constraints.maxHeight < 640;
                final horizontalPadding = (constraints.maxWidth * .05)
                    .clamp(16.0, 24.0)
                    .toDouble();

                return SingleChildScrollView(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _BackButton(
                            onPressed: interactionsLocked
                                ? null
                                : () => Navigator.maybePop(context),
                          ),
                        ),
                        SizedBox(height: veryCompactHeight ? 6 : 10),
                        _EmailSecurityIllustration(
                          size: veryCompactHeight
                              ? 104
                              : compactHeight
                              ? 128
                              : 160,
                        ),
                        SizedBox(height: compactHeight ? 10 : 18),
                        Text(
                          'Check Your Email',
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
                        Text.rich(
                          TextSpan(
                            text: 'We’ve sent a verification code to\n',
                            children: [
                              TextSpan(
                                text: widget.email.trim(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: _ink,
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: compactHeight ? 12.5 : 13.5,
                            fontWeight: FontWeight.w400,
                            color: _muted,
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Enter the 6-digit code from the email',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: compactHeight ? 12.5 : 13,
                            fontWeight: FontWeight.w400,
                            color: _muted,
                          ),
                        ),
                        SizedBox(height: compactHeight ? 18 : 25),
                        _OtpInput(
                          controller: _otpController,
                          focusNode: _otpFocusNode,
                          enabled: !interactionsLocked,
                          onChanged: (_) => setState(() {}),
                          onComplete: () => _verifyCode(context),
                        ),
                        SizedBox(height: compactHeight ? 15 : 20),
                        _CountdownLabel(
                          remainingText: _countdownText,
                          expired: _isExpired,
                        ),
                        SizedBox(height: compactHeight ? 18 : 24),
                        SizedBox(
                          height: 56,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: interactionsLocked || _isExpired
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF82A9FA),
                                        Color(0xFF82A9FA),
                                      ],
                                    )
                                  : const LinearGradient(
                                      colors: [
                                        Color(0xFF2C76FF),
                                        Color(0xFF1E5FF0),
                                      ],
                                    ),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: interactionsLocked || _isExpired
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
                              onPressed: interactionsLocked || _isExpired
                                  ? null
                                  : () => _verifyCode(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                disabledBackgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                disabledForegroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                child: isVerifying
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
                                            'Verify Code',
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
                        SizedBox(height: compactHeight ? 18 : 26),
                        _ResendCard(
                          isResending: isResending,
                          enabled: !interactionsLocked,
                          onResend: () => _resendCode(context),
                        ),
                      ],
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
}

class _OtpInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final VoidCallback onComplete;

  const _OtpInput({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onChanged,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = constraints.maxWidth < 300 ? 5.0 : 8.0;
        final boxWidth = ((constraints.maxWidth - spacing * 5) / 6)
            .clamp(34.0, 56.0)
            .toDouble();
        final boxHeight = (boxWidth * 1.16).clamp(50.0, 64.0).toDouble();
        final value = controller.text;

        return Semantics(
          textField: true,
          label: 'Six digit verification code',
          value: value,
          child: GestureDetector(
            onTap: enabled ? focusNode.requestFocus : null,
            behavior: HitTestBehavior.opaque,
            child: Stack(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (index) {
                    final hasDigit = index < value.length;
                    final isActive = enabled && index == value.length;
                    return Padding(
                      padding: EdgeInsets.only(right: index == 5 ? 0 : spacing),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: boxWidth,
                        height: boxHeight,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: isActive
                                ? _OtpVerificationScreenState._blue
                                : const Color(0xFFDCE3EE),
                            width: isActive ? 1.8 : 1.25,
                          ),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: _OtpVerificationScreenState._blue
                                        .withValues(alpha: .09),
                                    blurRadius: 10,
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          hasDigit ? value[index] : '–',
                          style: GoogleFonts.poppins(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            color: hasDigit
                                ? _OtpVerificationScreenState._ink
                                : const Color(0xFFC3CBD9),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                Positioned.fill(
                  child: Opacity(
                    opacity: .01,
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      enabled: enabled,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      onChanged: (value) {
                        onChanged(value);
                        if (value.length == 6) {
                          TextInput.finishAutofillContext();
                        }
                      },
                      onSubmitted: (_) => onComplete(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CountdownLabel extends StatelessWidget {
  final String remainingText;
  final bool expired;

  const _CountdownLabel({required this.remainingText, required this.expired});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: Color(0xFFF0F5FF),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.timer_outlined,
            color: _OtpVerificationScreenState._blue,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          expired ? 'Code expired' : 'Code expires in ',
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: _OtpVerificationScreenState._muted,
          ),
        ),
        if (!expired)
          Text(
            remainingText,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: _OtpVerificationScreenState._blue,
            ),
          ),
      ],
    );
  }
}

class _ResendCard extends StatelessWidget {
  final bool isResending;
  final bool enabled;
  final VoidCallback onResend;

  const _ResendCard({
    required this.isResending,
    required this.enabled,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FF),
        borderRadius: BorderRadius.circular(16),
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
              Icons.mail_outline_rounded,
              color: _OtpVerificationScreenState._blue,
              size: 21,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Haven’t received the email?',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _OtpVerificationScreenState._ink,
                  ),
                ),
                const SizedBox(height: 3),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Check your spam folder or ',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        color: _OtpVerificationScreenState._muted,
                      ),
                    ),
                    InkWell(
                      onTap: enabled ? onResend : null,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Text(
                          isResending ? 'Sending…' : 'Resend email',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: enabled
                                ? _OtpVerificationScreenState._blue
                                : const Color(0xFF9DA7BA),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
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
  final VoidCallback? onPressed;

  const _BackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
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
            color: _OtpVerificationScreenState._ink,
          ),
        ),
      ),
    );
  }
}

class _EmailSecurityIllustration extends StatelessWidget {
  final double size;

  const _EmailSecurityIllustration({required this.size});

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
              width: size * .88,
              height: size * .88,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0xFFE6EEFF), Color(0xFFF9FAFF)],
                ),
              ),
            ),
            Positioned(
              bottom: size * .16,
              child: Container(
                width: size * .72,
                height: size * .46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFBFD2FF), Color(0xFF92B2F8)],
                  ),
                  borderRadius: BorderRadius.circular(size * .08),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF426BE0).withValues(alpha: .14),
                      blurRadius: 18,
                      offset: const Offset(0, 9),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.mail_rounded,
                  color: Colors.white.withValues(alpha: .28),
                  size: size * .38,
                ),
              ),
            ),
            Positioned(
              top: size * .22,
              child: Container(
                width: size * .49,
                height: size * .48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(size * .06),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7892D0).withValues(alpha: .12),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.verified_user_rounded,
                  color: _OtpVerificationScreenState._blue,
                  size: size * .25,
                ),
              ),
            ),
            _Sparkle(
              alignment: const Alignment(-.85, -.45),
              color: const Color(0xFFFFBC18),
              size: size * .11,
            ),
            _Sparkle(
              alignment: const Alignment(.84, -.1),
              color: const Color(0xFF8A4FF7),
              size: size * .09,
            ),
            _Sparkle(
              alignment: const Alignment(.7, -.68),
              color: const Color(0xFF3478F6),
              size: size * .1,
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
