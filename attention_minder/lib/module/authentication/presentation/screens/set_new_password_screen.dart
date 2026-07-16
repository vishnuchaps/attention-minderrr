import 'package:attention_minder/module/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:attention_minder/module/authentication/presentation/screens/password_change_success_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class SetNewPasswordScreen extends StatefulWidget {
  final String email;

  const SetNewPasswordScreen({super.key, required this.email});

  @override
  State<SetNewPasswordScreen> createState() => _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends State<SetNewPasswordScreen> {
  static const _ink = Color(0xFF061A4D);
  static const _muted = Color(0xFF667394);
  static const _blue = Color(0xFF246BFD);
  static const _green = Color(0xFF1FA763);

  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  final _confirmFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  String get _password => _passwordController.text;
  String get _confirmation => _confirmPasswordController.text;
  bool get _hasMinimumLength => _password.length >= 8;
  bool get _hasUppercase => RegExp(r'[A-Z]').hasMatch(_password);
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(_password);
  bool get _hasSpecialCharacter => RegExp(r'[^A-Za-z0-9]').hasMatch(_password);
  bool get _meetsAllRequirements =>
      _hasMinimumLength && _hasUppercase && _hasNumber && _hasSpecialCharacter;
  bool get _passwordsMatch =>
      _confirmation.isNotEmpty && _confirmation == _password;
  bool get _canSubmit => _meetsAllRequirements && _passwordsMatch;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    _confirmFocusNode.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').isEmpty) return 'Enter your new password';
    if (!_meetsAllRequirements) {
      return 'Complete all password requirements';
    }
    return null;
  }

  String? _validateConfirmation(String? value) {
    if ((value ?? '').isEmpty) return 'Confirm your new password';
    if (!_passwordsMatch) return 'Passwords do not match';
    return null;
  }

  void _submit(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false) || !_canSubmit) return;
    TextInput.finishAutofillContext();
    context.read<AuthenticationBloc>().add(
      ChangePasswordRequested(
        email: widget.email.trim(),
        newPassword: _password,
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFB42318),
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
          if (state is ChangePasswordSuccess) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const PasswordChangeSuccessScreen(),
              ),
            );
          } else if (state is ChangePasswordError) {
            _showError(context, state.error);
        
          }
        },
        builder: (context, state) {
          final isLoading = state is ChangePasswordLoading;

          return SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compactHeight = constraints.maxHeight < 760;
                final veryCompactHeight = constraints.maxHeight < 650;
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
                            SizedBox(height: veryCompactHeight ? 4 : 8),
                            _PasswordSecurityIllustration(
                              size: veryCompactHeight
                                  ? 96
                                  : compactHeight
                                  ? 120
                                  : 148,
                            ),
                            SizedBox(height: compactHeight ? 8 : 15),
                            Text(
                              'Set a New Password',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: compactHeight ? 24 : 27,
                                fontWeight: FontWeight.w700,
                                color: _ink,
                                height: 1.15,
                                letterSpacing: -.7,
                              ),
                            ),
                            SizedBox(height: compactHeight ? 7 : 10),
                            Text(
                              'Create a strong password that differs from your '
                              'previous passwords.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: compactHeight ? 12 : 13.5,
                                fontWeight: FontWeight.w400,
                                color: _muted,
                                height: 1.5,
                              ),
                            ),
                            SizedBox(height: compactHeight ? 17 : 25),
                            _PasswordField(
                              label: 'New Password',
                              hint: 'Enter your new password',
                              controller: _passwordController,
                              focusNode: _passwordFocusNode,
                              obscureText: _obscurePassword,
                              enabled: !isLoading,
                              autofillHint: AutofillHints.newPassword,
                              validator: _validatePassword,
                              textInputAction: TextInputAction.next,
                              onVisibilityPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              onChanged: (_) => setState(() {}),
                              onSubmitted: (_) =>
                                  _confirmFocusNode.requestFocus(),
                            ),
                            SizedBox(height: compactHeight ? 12 : 16),
                            _RequirementsCard(
                              minimumLengthMet: _hasMinimumLength,
                              uppercaseMet: _hasUppercase,
                              numberMet: _hasNumber,
                              specialCharacterMet: _hasSpecialCharacter,
                            ),
                            SizedBox(height: compactHeight ? 15 : 21),
                            _PasswordField(
                              label: 'Confirm Password',
                              hint: 'Confirm your new password',
                              controller: _confirmPasswordController,
                              focusNode: _confirmFocusNode,
                              obscureText: _obscureConfirmation,
                              enabled: !isLoading,
                              autofillHint: AutofillHints.newPassword,
                              validator: _validateConfirmation,
                              textInputAction: TextInputAction.done,
                              onVisibilityPressed: () => setState(
                                () => _obscureConfirmation =
                                    !_obscureConfirmation,
                              ),
                              onChanged: (_) => setState(() {}),
                              onSubmitted: (_) {
                                if (_canSubmit && !isLoading) _submit(context);
                              },
                            ),
                            SizedBox(height: compactHeight ? 12 : 16),
                            _MatchBanner(
                              hasConfirmation: _confirmation.isNotEmpty,
                              matches: _passwordsMatch,
                            ),
                            SizedBox(height: compactHeight ? 18 : 25),
                            SizedBox(
                              height: 56,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: !_canSubmit || isLoading
                                      ? const LinearGradient(
                                          colors: [
                                            Color(0xFF91B1F5),
                                            Color(0xFF91B1F5),
                                          ],
                                        )
                                      : const LinearGradient(
                                          colors: [
                                            Color(0xFF2C76FF),
                                            Color(0xFF1E5FF0),
                                          ],
                                        ),
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: !_canSubmit || isLoading
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
                                  onPressed: !_canSubmit || isLoading
                                      ? null
                                      : () => _submit(context),
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
                                                'Update Password',
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
}

class _PasswordField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool obscureText;
  final bool enabled;
  final String autofillHint;
  final FormFieldValidator<String> validator;
  final TextInputAction textInputAction;
  final VoidCallback onVisibilityPressed;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  const _PasswordField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.focusNode,
    required this.obscureText,
    required this.enabled,
    required this.autofillHint,
    required this.validator,
    required this.textInputAction,
    required this.onVisibilityPressed,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _SetNewPasswordScreenState._ink,
          ),
        ),
        const SizedBox(height: 9),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          obscureText: obscureText,
          keyboardType: TextInputType.visiblePassword,
          textInputAction: textInputAction,
          autofillHints: [autofillHint],
          autocorrect: false,
          enableSuggestions: false,
          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _SetNewPasswordScreenState._ink,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF8A94AE),
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(9),
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFFF0F5FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: _SetNewPasswordScreenState._blue,
                size: 19,
              ),
            ),
            suffixIcon: IconButton(
              onPressed: enabled ? onVisibilityPressed : null,
              tooltip: obscureText ? 'Show password' : 'Hide password',
              icon: Icon(
                obscureText
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: const Color(0xFF77829B),
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 17,
            ),
            filled: true,
            fillColor: Colors.white,
            border: _outline(const Color(0xFFD7E1FA)),
            enabledBorder: _outline(const Color(0xFFD7E1FA)),
            focusedBorder: _outline(
              _SetNewPasswordScreenState._blue,
              width: 1.7,
            ),
            errorBorder: _outline(const Color(0xFFCB3A31)),
            focusedErrorBorder: _outline(const Color(0xFFCB3A31), width: 1.7),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _outline(Color color, {double width = 1.35}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _RequirementsCard extends StatelessWidget {
  final bool minimumLengthMet;
  final bool uppercaseMet;
  final bool numberMet;
  final bool specialCharacterMet;

  const _RequirementsCard({
    required this.minimumLengthMet,
    required this.uppercaseMet,
    required this.numberMet,
    required this.specialCharacterMet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECF0F8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF1FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: _SetNewPasswordScreenState._blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Password must contain:',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _SetNewPasswordScreenState._muted,
                  ),
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final length = _Requirement(
                      width: double.infinity,
                      label: 'At least 8 characters',
                      met: minimumLengthMet,
                    );
                    final uppercase = _Requirement(
                      width: double.infinity,
                      label: 'One uppercase letter',
                      met: uppercaseMet,
                    );
                    final number = _Requirement(
                      width: double.infinity,
                      label: 'One number',
                      met: numberMet,
                    );
                    final special = _Requirement(
                      width: double.infinity,
                      label: 'One special character',
                      met: specialCharacterMet,
                    );

                    if (constraints.maxWidth < 250) {
                      return Column(
                        children: [
                          length,
                          const SizedBox(height: 8),
                          uppercase,
                          const SizedBox(height: 8),
                          number,
                          const SizedBox(height: 8),
                          special,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              length,
                              const SizedBox(height: 9),
                              uppercase,
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            children: [
                              number,
                              const SizedBox(height: 9),
                              special,
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Requirement extends StatelessWidget {
  final double width;
  final String label;
  final bool met;

  const _Requirement({
    required this.width,
    required this.label,
    required this.met,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 160),
        style: GoogleFonts.poppins(
          fontSize: 10.5,
          fontWeight: met ? FontWeight.w600 : FontWeight.w400,
          color: met
              ? _SetNewPasswordScreenState._green
              : _SetNewPasswordScreenState._muted,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: met
                    ? _SetNewPasswordScreenState._green
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: met
                      ? _SetNewPasswordScreenState._green
                      : const Color(0xFFB9C2D2),
                ),
              ),
              child: met
                  ? const Icon(
                      Icons.check_rounded,
                      size: 11,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 6),
            Expanded(child: Text(label, maxLines: 1)),
          ],
        ),
      ),
    );
  }
}

class _MatchBanner extends StatelessWidget {
  final bool hasConfirmation;
  final bool matches;

  const _MatchBanner({required this.hasConfirmation, required this.matches});

  @override
  Widget build(BuildContext context) {
    final color = hasConfirmation && matches
        ? _SetNewPasswordScreenState._green
        : hasConfirmation
        ? const Color(0xFFB42318)
        : _SetNewPasswordScreenState._blue;
    final message = hasConfirmation && matches
        ? 'Your passwords match.'
        : hasConfirmation
        ? 'The passwords do not match yet.'
        : 'Make sure both passwords match before updating.';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(
            hasConfirmation && matches
                ? Icons.check_circle_outline_rounded
                : hasConfirmation
                ? Icons.error_outline_rounded
                : Icons.info_outline_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
                height: 1.4,
              ),
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
            color: _SetNewPasswordScreenState._ink,
          ),
        ),
      ),
    );
  }
}

class _PasswordSecurityIllustration extends StatelessWidget {
  final double size;

  const _PasswordSecurityIllustration({required this.size});

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
              width: size * .86,
              height: size * .86,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0xFFE7EEFF), Color(0xFFFAFBFF)],
                ),
              ),
            ),
            Positioned(
              top: size * .16,
              child: Container(
                width: size * .35,
                height: size * .38,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFF7194F5),
                    width: size * .08,
                  ),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(size * .2),
                  ),
                ),
              ),
            ),
            Positioned(
              top: size * .38,
              child: Container(
                width: size * .58,
                height: size * .39,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFC6D5FF), Color(0xFFAEC2FB)],
                  ),
                  borderRadius: BorderRadius.circular(size * .09),
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
                  color: const Color(0xFF315CCF),
                  size: size * .19,
                ),
              ),
            ),
            Positioned(
              right: size * .08,
              bottom: size * .13,
              child: Container(
                width: size * .31,
                height: size * .35,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4B87FF), Color(0xFF245FE8)],
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
                  size: size * .18,
                ),
              ),
            ),
            _Sparkle(
              alignment: const Alignment(-.88, -.55),
              color: const Color(0xFF3478F6),
              size: size * .1,
            ),
            _Sparkle(
              alignment: const Alignment(.82, -.42),
              color: const Color(0xFFFFBC18),
              size: size * .1,
            ),
            _Sparkle(
              alignment: const Alignment(.9, -.05),
              color: const Color(0xFF9B58F5),
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
