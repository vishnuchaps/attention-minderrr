import 'package:attention_minder/module/attention_management/data/model/goal_submission.dart';
import 'package:attention_minder/module/attention_management/data/model/goals_model.dart';
import 'package:attention_minder/module/attention_management/presentation/bloc/goals_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

Future<bool> showReviewGoalsDialog(
  BuildContext context, {
  required List<GoalData> goals,
}) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierColor: const Color(0xFF101936).withValues(alpha: .52),
        builder: (_) => BlocProvider.value(
          value: context.read<GoalsBloc>(),
          child: ReviewGoalsDialog(goals: goals),
        ),
      ) ??
      false;
}

class ReviewGoalsDialog extends StatefulWidget {
  const ReviewGoalsDialog({required this.goals, super.key});

  final List<GoalData> goals;

  @override
  State<ReviewGoalsDialog> createState() => _ReviewGoalsDialogState();
}

class _ReviewGoalsDialogState extends State<ReviewGoalsDialog> {
  static const _ink = Color(0xFF101B3B);
  static const _muted = Color(0xFF68738F);
  static const _blue = Color(0xFF246BFD);
  static const _purple = Color(0xFF8C43DF);

  final Map<int, int> _ratings = <int, int>{};
  bool _submitting = false;

  bool get _hasRatedEveryGoal =>
      widget.goals.isNotEmpty && _ratings.length == widget.goals.length;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final compact = media.size.width < 380 || media.size.height < 720;

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
          horizontal: media.size.width < 380 ? 12 : 20,
          vertical: compact ? 14 : 24,
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 580,
            maxHeight: media.size.height - (compact ? 28 : 48),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFFCFDFF),
              borderRadius: BorderRadius.circular(compact ? 22 : 26),
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
                  const Positioned.fill(child: _ReviewBackdrop()),
                  SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.all(compact ? 16 : 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _header(compact),
                        SizedBox(height: compact ? 12 : 16),
                        Text(
                          'Review Your Goals',
                          style: _style(
                            fontSize: compact ? 22 : 26,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                            height: 1.12,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          'See the goals you set and rate how well you’ve achieved each one.',
                          style: _style(
                            fontSize: compact ? 13 : 14,
                            color: _muted,
                            height: 1.42,
                          ),
                        ),
                        SizedBox(height: compact ? 16 : 20),
                        if (widget.goals.isEmpty)
                          _emptyState()
                        else
                          ...widget.goals.asMap().entries.map(
                            (entry) => Padding(
                              padding: EdgeInsets.only(
                                bottom: entry.key == widget.goals.length - 1
                                    ? 0
                                    : 12,
                              ),
                              child: _goalCard(entry.key, entry.value, compact),
                            ),
                          ),
                        SizedBox(height: compact ? 14 : 18),
                        _reflectionNote(compact),
                        const SizedBox(height: 14),
                        _submitButton(compact),
                      ],
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

  Widget _header(bool compact) => Row(
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
          color: _blue,
          size: compact ? 26 : 30,
        ),
      ),
      const Spacer(),
      const _ReviewFlagIllustration(),
      const SizedBox(width: 4),
      IconButton(
        onPressed: _submitting ? null : () => Navigator.pop(context),
        icon: const Icon(Icons.close_rounded),
        color: _muted,
        tooltip: 'Close',
      ),
    ],
  );

  Widget _goalCard(int index, GoalData goal, bool compact) {
    final accent = index.isEven ? _blue : _purple;
    final tint = index.isEven
        ? const Color(0xFFEAF1FF)
        : const Color(0xFFF3E9FF);
    final title = goal.goal?.trim().isNotEmpty == true
        ? _toTitleCase(goal.goal!)
        : 'Personal goal ${index + 1}';

    return Container(
      padding: EdgeInsets.all(compact ? 14 : 17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EDF7)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB7C5DF).withValues(alpha: .18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
                child: Text(
                  '${index + 1}',
                  style: _style(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _style(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                    height: 1.25,
                  ),
                ),
              ),
              if (goal.createdAt != null) ...[
                const SizedBox(width: 8),
                Icon(Icons.calendar_today_rounded, size: 15, color: accent),
                const SizedBox(width: 5),
                Text(
                  _formatDate(goal.createdAt!),
                  style: _style(fontSize: 11, color: _muted),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFE7ECF5)),
          const SizedBox(height: 13),
          Text(
            'How satisfied are you with this goal?',
            style: _style(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final diameter = ((constraints.maxWidth - 30) / 6).clamp(
                34.0,
                43.0,
              );
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (rating) {
                  final selected = _ratings[index] == rating;
                  return Semantics(
                    button: true,
                    selected: selected,
                    label: 'Rate $rating out of 5',
                    child: InkWell(
                      onTap: _submitting
                          ? null
                          : () => setState(() => _ratings[index] = rating),
                      customBorder: const CircleBorder(),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 170),
                        width: diameter,
                        height: diameter,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: selected
                              ? LinearGradient(
                                  colors: [
                                    accent.withValues(alpha: .78),
                                    accent,
                                  ],
                                )
                              : null,
                          color: selected ? null : Colors.white,
                          border: Border.all(
                            color: selected
                                ? Colors.transparent
                                : const Color(0xFFE2E7F0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: selected
                                  ? accent.withValues(alpha: .25)
                                  : const Color(
                                      0xFFB9C2D2,
                                    ).withValues(alpha: .18),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          '$rating',
                          style: _style(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: selected ? Colors.white : _ink,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(height: 9),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Not achieved', style: _style(fontSize: 10, color: _muted)),
              Text(
                _ratings[index] == null
                    ? 'Select a rating'
                    : _ratingLabel(_ratings[index]!),
                style: _style(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
              Text(
                'Fully achieved',
                style: _style(fontSize: 10, color: _muted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE8EDF7)),
    ),
    child: Column(
      children: [
        const Icon(Icons.flag_outlined, color: _blue, size: 30),
        const SizedBox(height: 10),
        Text(
          'No goals to review yet',
          style: _style(fontSize: 14, fontWeight: FontWeight.w700, color: _ink),
        ),
      ],
    ),
  );

  Widget _reflectionNote(bool compact) => Container(
    padding: EdgeInsets.all(compact ? 12 : 14),
    decoration: BoxDecoration(
      color: const Color(0xFFEEF4FF),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        const CircleAvatar(
          radius: 18,
          backgroundColor: Colors.white,
          child: Icon(Icons.lightbulb_outline_rounded, color: _blue, size: 21),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Honest reflection helps you grow!',
                style: _style(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Your feedback is private and helps personalize your experience.',
                style: _style(fontSize: 10.5, color: _muted, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _submitButton(bool compact) => SizedBox(
    width: double.infinity,
    height: compact ? 48 : 52,
    child: ElevatedButton.icon(
      onPressed: !_hasRatedEveryGoal || _submitting ? null : _submitEvaluation,
      icon: _submitting
          ? const SizedBox(
              width: 19,
              height: 19,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.send_rounded, size: 19),
      label: Text(
        'Submit My Evaluation',
        style: _style(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFB8C4D8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
      ),
    ),
  );

  void _submitEvaluation() {
    if (!_hasRatedEveryGoal || _submitting) return;

    final goals = widget.goals
        .asMap()
        .entries
        .where((entry) => entry.value.goal?.trim().isNotEmpty == true)
        .map(
          (entry) => GoalSubmission(
            id: entry.value.id,
            goal: entry.value.goal!.trim(),
            rating: _ratings[entry.key]!,
          ),
        )
        .toList(growable: false);
    if (goals.length != widget.goals.length) return;

    setState(() => _submitting = true);
    context.read<GoalsBloc>().add(GoalsEvaluationSubmitted(goals));
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
        ? 'We could not submit your evaluation. Please try again.'
        : normalized;
  }

  String _ratingLabel(int rating) => switch (rating) {
    0 => 'Not achieved',
    1 => 'Started',
    2 => 'Making progress',
    3 => 'Moderate',
    4 => 'Great',
    _ => 'Fully achieved',
  };

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _toTitleCase(String value) => value
      .trim()
      .split(RegExp(r'\s+'))
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
      )
      .join(' ');

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

class _ReviewBackdrop extends StatelessWidget {
  const _ReviewBackdrop();

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
              radius: size.width * .75,
            ),
          );
    canvas.drawCircle(Offset(size.width, 0), size.width * .75, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ReviewFlagIllustration extends StatelessWidget {
  const _ReviewFlagIllustration();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 64,
    height: 48,
    child: Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Positioned(
          bottom: 0,
          child: Icon(
            Icons.landscape_rounded,
            size: 56,
            color: const Color(0xFFDCE7FF).withValues(alpha: .9),
          ),
        ),
        const Positioned(
          top: 1,
          right: 9,
          child: Icon(Icons.flag_rounded, size: 34, color: Color(0xFF347CFF)),
        ),
      ],
    ),
  );
}
