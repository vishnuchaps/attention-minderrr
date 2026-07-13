import 'package:attention_minder/module/assigment/presentation/screens/questionnaire_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProgressCardWidget extends StatefulWidget {
  final int totalQuestions;
  final int answeredQuestions;

  const ProgressCardWidget({
    super.key,
    required this.totalQuestions,
    required this.answeredQuestions,
  });

  @override
  State<ProgressCardWidget> createState() => _ProgressCardWidgetState();
}

class _ProgressCardWidgetState extends State<ProgressCardWidget> {
  static const double _segmentWidth = 42;
  static const double _segmentGap = 8;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToProgress());
  }

  @override
  void didUpdateWidget(covariant ProgressCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.answeredQuestions != widget.answeredQuestions ||
        oldWidget.totalQuestions != widget.totalQuestions) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToProgress());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToProgress() {
    if (!_scrollController.hasClients) {
      return;
    }

    final total = widget.totalQuestions <= 0 ? 0 : widget.totalQuestions;
    final completed = widget.answeredQuestions.clamp(0, total).toInt();

    if (completed <= 1) {
      _scrollController.jumpTo(_scrollController.position.minScrollExtent);
      return;
    }

    final targetOffset = ((completed - 1) * (_segmentWidth + _segmentGap))
        .clamp(
          _scrollController.position.minScrollExtent,
          _scrollController.position.maxScrollExtent,
        )
        .toDouble();

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.totalQuestions <= 0 ? 0 : widget.totalQuestions;
    final completed = widget.answeredQuestions.clamp(0, total).toInt();

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final tight = constraints.maxWidth < 330;

        return Container(
          width: double.infinity,
          margin: EdgeInsets.only(
            top: compact ? 6 : 8,
            bottom: compact ? 8 : 10,
          ),
          padding: EdgeInsets.fromLTRB(
            compact ? 14 : 16,
            compact ? 14 : 16,
            compact ? 14 : 16,
            compact ? 12 : 14,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FBFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFD6E7FF), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB6C9DF).withValues(alpha: .14),
                blurRadius: 18,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _TrendIcon(size: compact ? 42 : 48),
                  SizedBox(width: compact ? 10 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'You are progressing',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _type(
                            fontSize: tight
                                ? 18
                                : compact
                                ? 20
                                : 22,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF071345),
                            height: 1.05,
                          ),
                        ),
                        SizedBox(height: compact ? 4 : 5),
                        Text(
                          'Consistency today, better focus tomorrow.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: _type(
                            fontSize: compact ? 12 : 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF5C6888),
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 16 : 18),
              Row(
                children: [
                  Expanded(
                    child: _SegmentedProgress(
                      total: total,
                      completed: completed,
                      controller: _scrollController,
                      compact: compact,
                    ),
                  ),
                  SizedBox(width: compact ? 10 : 12),
                  _ProgressBadge(
                    completed: completed,
                    total: total,
                    compact: compact,
                  ),
                ],
              ),
              SizedBox(height: compact ? 14 : 16),
              const Divider(height: 1, color: Color(0xFFD9E7F7)),
              SizedBox(height: compact ? 12 : 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _DayCount(
                      completed: completed,
                      total: total,
                      compact: compact,
                    ),
                  ),
                  SizedBox(width: compact ? 8 : 10),
                  Flexible(
                    flex: compact ? 2 : 3,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _ImprovementButton(
                        completed: completed,
                        compact: compact,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TrendIcon extends StatelessWidget {
  final double size;

  const _TrendIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE2EEFF), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB6C9DF).withValues(alpha: .12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        Icons.trending_up_rounded,
        color: const Color(0xFF1279F6),
        size: size * .43,
      ),
    );
  }
}

class _SegmentedProgress extends StatelessWidget {
  final int total;
  final int completed;
  final ScrollController controller;
  final bool compact;

  const _SegmentedProgress({
    required this.total,
    required this.completed,
    required this.controller,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    if (total == 0) {
      return Container(
        height: compact ? 6 : 7,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(99),
          color: const Color(0xFFD8E2EF),
        ),
      );
    }

    return SizedBox(
      height: compact ? 7 : 8,
      child: ListView.separated(
        controller: controller,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: total,
        separatorBuilder: (context, index) => SizedBox(width: compact ? 6 : 8),
        itemBuilder: (context, index) {
          final isCompleted = index < completed;

          return SizedBox(
            width: compact ? 36 : 42,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                gradient: isCompleted
                    ? const LinearGradient(
                        colors: [Color(0xFF0A74FF), Color(0xFF1B8BFF)],
                      )
                    : null,
                color: isCompleted ? null : const Color(0xFFD8E2EF),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProgressBadge extends StatelessWidget {
  final int completed;
  final int total;
  final bool compact;

  const _ProgressBadge({
    required this.completed,
    required this.total,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 42 : 48,
      height: compact ? 42 : 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF8FBFF),
        border: Border.all(color: const Color(0xFF1479FF), width: 1.4),
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '$completed/$total',
          style: _type(
            fontSize: compact ? 13 : 15,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1479FF),
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _DayCount extends StatelessWidget {
  final int completed;
  final int total;
  final bool compact;

  const _DayCount({
    required this.completed,
    required this.total,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.calendar_month_outlined,
          size: compact ? 17 : 19,
          color: const Color(0xFF60708F),
        ),
        SizedBox(width: compact ? 8 : 10),
        Flexible(
          child: Text(
            '$completed of $total days',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _type(
              fontSize: compact ? 12 : 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF7A86A1),
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _ImprovementButton extends StatelessWidget {
  final int completed;
  final bool compact;

  const _ImprovementButton({required this.completed, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  QuestionnaireScreen(initialQuestionIndex: completed),
            ),
          );
        },
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          height: compact ? 34 : 38,
          padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFD8E2EF)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB6C9DF).withValues(alpha: .10),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Complete Questionnaire',
                  maxLines: 1,
                  style: _type(
                    fontSize: compact ? 11.5 : 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1175F4),
                    height: 1,
                  ),
                ),
                SizedBox(width: compact ? 7 : 9),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: const Color(0xFF1175F4),
                  size: compact ? 17 : 19,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

TextStyle _type({
  required double fontSize,
  FontWeight fontWeight = FontWeight.w400,
  required Color color,
  double? height,
}) {
  return GoogleFonts.nunitoSans(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
  );
}
