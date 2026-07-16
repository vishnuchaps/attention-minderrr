import 'package:attention_minder/module/attention_management/data/model/goal_submission.dart';
import 'package:attention_minder/module/attention_management/presentation/bloc/goals_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

Future<bool> showPersonalGoalsDialog(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierColor: const Color(0xFF101936).withValues(alpha: .52),
        builder: (_) => BlocProvider.value(
          value: context.read<GoalsBloc>(),
          child: const PersonalGoalsDialog(),
        ),
      ) ??
      false;
}

class PersonalGoalsDialog extends StatefulWidget {
  const PersonalGoalsDialog({super.key});

  @override
  State<PersonalGoalsDialog> createState() => _PersonalGoalsDialogState();
}

class _PersonalGoalsDialogState extends State<PersonalGoalsDialog> {
  static const _ink = Color(0xFF101B3B);
  static const _muted = Color(0xFF66708A);
  static const _blue = Color(0xFF246BFD);
  static const _border = Color(0xFFD8E2F5);
  final _formKey = GlobalKey<FormState>();
  final _goalOneController = TextEditingController();
  final _goalTwoController = TextEditingController();
  bool _submitting = false;

  bool get _hasAtLeastOneGoal =>
      _goalOneController.text.trim().isNotEmpty ||
      _goalTwoController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _goalOneController.addListener(_onGoalChanged);
    _goalTwoController.addListener(_onGoalChanged);
  }

  void _onGoalChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _goalOneController.removeListener(_onGoalChanged);
    _goalTwoController.removeListener(_onGoalChanged);
    _goalOneController.dispose();
    _goalTwoController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_hasAtLeastOneGoal || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final goals = <GoalSubmission>[
      GoalSubmission(goal: _goalOneController.text, rating: 0),
      GoalSubmission(goal: _goalTwoController.text, rating: 0),
    ].where((goal) => goal.goal.trim().isNotEmpty).toList(growable: false);
    setState(() => _submitting = true);
    context.read<GoalsBloc>().add(GoalsSet(goals));
  }

  void _showResultSnackBar({required String message, required bool success}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          backgroundColor: success
              ? const Color(0xFF176B3A)
              : const Color(0xFF9F2D35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle_rounded : Icons.error_rounded,
                color: Colors.white,
                size: 21,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: _style(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  String _friendlyFailureMessage(String message) {
    final normalized = message.replaceFirst('Exception: ', '').trim();
    return normalized.isEmpty
        ? 'We could not save your goals. Please try again.'
        : normalized;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final compact = media.size.width < 380 || media.size.height < 700;

    return BlocListener<GoalsBloc, GoalsState>(
      listener: (context, state) {
        if (state is GoalsSetInProgress) {
          if (!_submitting) setState(() => _submitting = true);
        } else if (state is GoalsSetSuccess && _submitting) {
          _showResultSnackBar(message: state.message, success: true);
          Navigator.of(context).pop(true);
        } else if (state is GoalsSetFailure && _submitting) {
          setState(() => _submitting = false);
          _showResultSnackBar(
            message: _friendlyFailureMessage(state.message),
            success: false,
          );
        }
      },
      child: Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: media.size.width < 380 ? 12 : 22,
          vertical: compact ? 14 : 24,
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: media.size.height - (compact ? 28 : 48),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFFCFDFF),
              borderRadius: BorderRadius.circular(compact ? 22 : 26),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF244080).withValues(alpha: .18),
                  blurRadius: 42,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(compact ? 22 : 26),
              child: Stack(
                children: [
                  const Positioned.fill(child: _GoalDialogBackdrop()),
                  SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      compact ? 16 : 24,
                      compact ? 16 : 20,
                      compact ? 16 : 24,
                      16 + media.viewInsets.bottom,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _header(compact),
                          SizedBox(height: compact ? 14 : 18),
                          Text(
                            'Set Your Personal Goals',
                            style: _style(
                              fontSize: compact ? 22 : 26,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                              height: 1.12,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            'What would you like to achieve during this program? Setting specific goals will help you track your progress.',
                            style: _style(
                              fontSize: compact ? 13 : 14,
                              fontWeight: FontWeight.w500,
                              color: _muted,
                              height: 1.45,
                            ),
                          ),
                          SizedBox(height: compact ? 16 : 21),
                          _goalField(
                            number: 1,
                            title: 'Goal 1',
                            prompt: 'What’s one thing you want to improve?',
                            example:
                                'e.g., “I want to improve my focus at work.”',
                            controller: _goalOneController,
                            accent: _blue,
                            tint: const Color(0xFFEAF1FF),
                          ),
                          SizedBox(height: compact ? 15 : 19),
                          _goalField(
                            number: 2,
                            title: 'Goal 2',
                            prompt: 'What’s another goal?',
                            example: 'e.g., “I want to manage my time better.”',
                            controller: _goalTwoController,
                            accent: const Color(0xFF8C43DF),
                            tint: const Color(0xFFF3E9FF),
                          ),
                          SizedBox(height: compact ? 16 : 20),
                          _submitButton(compact),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(bool compact) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: compact ? 46 : 52,
          width: compact ? 46 : 52,
          decoration: const BoxDecoration(
            color: Color(0xFFE9F2FF),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.track_changes_rounded,
            size: compact ? 26 : 30,
            color: _blue,
          ),
        ),
        const Spacer(),
        const _GoalFlagIllustration(),
        const SizedBox(width: 4),
        Semantics(
          label: 'Close goals dialog',
          button: true,
          child: IconButton(
            onPressed: _submitting ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
            color: _muted,
            tooltip: 'Close',
          ),
        ),
      ],
    );
  }

  Widget _goalField({
    required int number,
    required String title,
    required String prompt,
    required String example,
    required TextEditingController controller,
    required Color accent,
    required Color tint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$number',
                style: _style(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: _style(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    prompt,
                    style: _style(fontSize: 12, color: _muted, height: 1.28),
                  ),
                  Text(
                    example,
                    style: _style(
                      fontSize: 11,
                      color: _muted.withValues(alpha: .85),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        TextFormField(
          controller: controller,
          enabled: !_submitting,
          maxLength: 60,
          maxLines: 2,
          minLines: 2,
          textAlignVertical: TextAlignVertical.center,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.newline,
          inputFormatters: [LengthLimitingTextInputFormatter(60)],
          validator: (value) {
            if (value != null && value.trim().length > 60) {
              return 'Goals can contain up to 60 characters.';
            }
            return null;
          },
          style: _style(fontSize: 14, color: _ink, height: 1.3),
          decoration: InputDecoration(
            hintText: 'Type your goal here…',
            hintStyle: _style(
              fontSize: 14,
              color: _muted.withValues(alpha: .8),
              height: 1.2,
            ),
            counterStyle: _style(fontSize: 11, color: _muted),
            isDense: true,
            constraints: const BoxConstraints(minHeight: 86),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.fromLTRB(14, 17, 14, 14),
            border: _fieldBorder(_border),
            enabledBorder: _fieldBorder(_border),
            focusedBorder: _fieldBorder(_blue, width: 1.7),
            errorBorder: _fieldBorder(const Color(0xFFE05252)),
            focusedErrorBorder: _fieldBorder(
              const Color(0xFFE05252),
              width: 1.7,
            ),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _fieldBorder(Color color, {double width = 1.25}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: BorderSide(color: color, width: width),
      );

  Widget _submitButton(bool compact) => SizedBox(
    width: double.infinity,
    height: compact ? 48 : 52,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: _hasAtLeastOneGoal
            ? const LinearGradient(
                colors: [Color(0xFF347CFF), Color(0xFF1D5FEF)],
              )
            : const LinearGradient(
                colors: [Color(0xFFB8C4D8), Color(0xFFAAB7CB)],
              ),
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: _hasAtLeastOneGoal
                ? _blue.withValues(alpha: .28)
                : Colors.transparent,
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _submitting || !_hasAtLeastOneGoal ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        child: _submitting
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Save goals',
                    style: _style(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 19),
                ],
              ),
      ),
    ),
  );

  TextStyle _style({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w500,
    required Color color,
    double? height,
  }) => GoogleFonts.inter(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
  );
}

class _GoalDialogBackdrop extends StatelessWidget {
  const _GoalDialogBackdrop();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _BackdropPainter());
}

class _BackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader =
          const RadialGradient(
            colors: [Color(0xFFEAF3FF), Color(0x00FFFFFF)],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width, 0),
              radius: size.width * .8,
            ),
          );
    canvas.drawCircle(Offset(size.width, 0), size.width * .8, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GoalFlagIllustration extends StatelessWidget {
  const _GoalFlagIllustration();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 66,
    height: 50,
    child: Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Positioned(
          bottom: 0,
          child: Icon(
            Icons.landscape_rounded,
            size: 58,
            color: const Color(0xFFDCE7FF).withValues(alpha: .9),
          ),
        ),
        const Positioned(
          top: 1,
          right: 10,
          child: Icon(Icons.flag_rounded, size: 35, color: Color(0xFF347CFF)),
        ),
        const Positioned(
          top: 3,
          left: 4,
          child: Icon(
            Icons.auto_awesome_rounded,
            size: 12,
            color: Color(0xFFFFC64A),
          ),
        ),
      ],
    ),
  );
}
