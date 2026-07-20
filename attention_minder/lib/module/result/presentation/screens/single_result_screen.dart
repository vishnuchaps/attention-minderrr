import 'package:attention_minder/module/result/data/model/questionnaire_result_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SingleResultScreen extends StatelessWidget {
  final ManagementResult result;

  const SingleResultScreen({super.key, required this.result});

  static const _background = Color(0xFFF8FBFF);
  static const _ink = Color(0xFF071443);
  static const _muted = Color(0xFF566586);
  static const _blue = Color(0xFF1288F6);
  static const _orange = Color(0xFFF26B12);
  static const _line = Color(0xFFD9E7F7);

  @override
  Widget build(BuildContext context) {
    final data = _AssessmentDetailData.fromResult(result);

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 370;
            final horizontalPadding = (constraints.maxWidth * .055)
                .clamp(16.0, 24.0)
                .toDouble();

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    compact ? 14 : 20,
                    horizontalPadding,
                    28 + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailHeader(compact: compact, data: data),
                      SizedBox(height: compact ? 18 : 24),
                      _OverviewCard(data: data, compact: compact),
                      SizedBox(height: compact ? 16 : 20),
                      _AboutResultCard(data: data, compact: compact),
                      SizedBox(height: compact ? 24 : 30),
                      _SectionTitle(
                        title: 'Performance Summary',
                        compact: compact,
                      ),
                      SizedBox(height: compact ? 12 : 14),
                      _PerformanceCard(data: data, compact: compact),
                      SizedBox(height: compact ? 24 : 30),
                      _SectionTitle(
                        title: 'Assessment Insights',
                        compact: compact,
                      ),
                      SizedBox(height: compact ? 12 : 14),
                      _Insights(data: data, compact: compact),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  final bool compact;
  final _AssessmentDetailData data;

  const _DetailHeader({required this.compact, required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CircleAction(
          tooltip: 'Back',
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.maybePop(context),
          compact: compact,
        ),
        SizedBox(width: compact ? 12 : 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assessment Details',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _text(
                    fontSize: compact ? 19 : 22,
                    fontWeight: FontWeight.w800,
                    color: SingleResultScreen._ink,
                    height: 1.05,
                  ),
                ),
                SizedBox(height: compact ? 8 : 10),
                Row(
                  children: [
                    Icon(
                      Icons.assignment_turned_in_outlined,
                      color: SingleResultScreen._blue,
                      size: compact ? 18 : 20,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Questionnaire Assessment',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _text(
                          fontSize: compact ? 13 : 15,
                          fontWeight: FontWeight.w600,
                          color: SingleResultScreen._muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleAction extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final bool compact;

  const _CircleAction({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: _CircleActionVisual(icon: icon, compact: compact),
        ),
      ),
    );
  }
}

class _CircleActionVisual extends StatelessWidget {
  final IconData icon;
  final bool compact;

  const _CircleActionVisual({required this.icon, required this.compact});

  @override
  Widget build(BuildContext context) {
    final size = compact ? 42.0 : 48.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: SingleResultScreen._line),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9BB4D1).withValues(alpha: .11),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: SingleResultScreen._ink,
        size: compact ? 20 : 22,
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final _AssessmentDetailData data;
  final bool compact;

  const _OverviewCard({required this.data, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: _cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: _ResultSummary(data: data, compact: compact),
            ),
            Container(width: 1, color: SingleResultScreen._line),
            Expanded(
              flex: 6,
              child: _AssessmentMeta(data: data, compact: compact),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultSummary extends StatelessWidget {
  final _AssessmentDetailData data;
  final bool compact;

  const _ResultSummary({required this.data, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 18 : 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFFFF3E5), Color(0xFFFFFFFF)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Result',
            style: _text(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: SingleResultScreen._muted,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            data.resultLabel,
            style: _text(
              fontSize: compact ? 24 : 27,
              fontWeight: FontWeight.w800,
              color: data.accentColor,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: data.accentColor.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: data.accentColor.withValues(alpha: .2)),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'T-Score: ${data.scoreText} / 10',
                maxLines: 1,
                softWrap: false,
                style: _text(
                  fontSize: compact ? 12 : 13,
                  fontWeight: FontWeight.w700,
                  color: data.accentColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssessmentMeta extends StatelessWidget {
  final _AssessmentDetailData data;
  final bool compact;

  const _AssessmentMeta({required this.data, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(compact ? 18 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Assessment ID',
            style: _text(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: SingleResultScreen._muted,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            data.assessmentId,
            style: _text(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: SingleResultScreen._ink,
            ),
          ),
          const SizedBox(height: 16),
          _DateRow(
            label: 'Started',
            date: data.startedDate,
            time: data.startedTime,
          ),
          const SizedBox(height: 13),
          _DateRow(
            label: 'Completed',
            date: data.completedDate,
            time: data.completedTime,
          ),
        ],
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  final String label;
  final String date;
  final String time;

  const _DateRow({required this.label, required this.date, required this.time});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.calendar_today_outlined,
          size: 18,
          color: SingleResultScreen._muted,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 2,
                children: [
                  Text(
                    date,
                    style: _text(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: SingleResultScreen._ink,
                    ),
                  ),
                  if (time.isNotEmpty)
                    Text(
                      '•  $time',
                      style: _text(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: SingleResultScreen._ink,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: _text(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: SingleResultScreen._muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AboutResultCard extends StatelessWidget {
  final _AssessmentDetailData data;
  final bool compact;

  const _AboutResultCard({required this.data, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 16 : 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCDE3FA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 40 : 44,
            height: compact ? 40 : 44,
            decoration: const BoxDecoration(
              color: SingleResultScreen._blue,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.info_outline_rounded,
              color: Colors.white,
              size: compact ? 22 : 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About your result',
                  style: _text(
                    fontSize: compact ? 15 : 16,
                    fontWeight: FontWeight.w800,
                    color: SingleResultScreen._ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  data.aboutResult,
                  style: _text(
                    fontSize: compact ? 12 : 13,
                    fontWeight: FontWeight.w500,
                    color: SingleResultScreen._muted,
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool compact;

  const _SectionTitle({required this.title, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: _text(
        fontSize: compact ? 18 : 20,
        fontWeight: FontWeight.w800,
        color: SingleResultScreen._ink,
      ),
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  final _AssessmentDetailData data;
  final bool compact;

  const _PerformanceCard({required this.data, required this.compact});

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _MetricData(
        label: 'Overall Score (T-Score)',
        value: '${data.scoreText} / 10',
        progress: data.score / 10,
        icon: Icons.track_changes_rounded,
        color: SingleResultScreen._orange,
        background: const Color(0xFFFFF0E3),
      ),
      _MetricData(
        label: 'Raw Total Score',
        value: data.rawTotal == null ? 'Not available' : '${data.rawTotal}',
        progress: data.score / 10,
        icon: Icons.description_outlined,
        color: const Color(0xFFF39A19),
        background: const Color(0xFFFFF4E5),
      ),
      _MetricData.category(
        label: 'Read Focus',
        value: data.readFocus,
        icon: Icons.visibility_outlined,
        color: const Color(0xFF168CF4),
        background: const Color(0xFFE9F4FF),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 18,
        vertical: compact ? 8 : 10,
      ),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          for (var index = 0; index < metrics.length; index++) ...[
            _MetricRow(data: metrics[index], compact: compact),
            if (index != metrics.length - 1)
              const Divider(height: 1, color: SingleResultScreen._line),
          ],
        ],
      ),
    );
  }
}

class _MetricData {
  final String label;
  final String value;
  final double progress;
  final IconData icon;
  final Color color;
  final Color background;

  const _MetricData({
    required this.label,
    required this.value,
    required this.progress,
    required this.icon,
    required this.color,
    required this.background,
  });

  factory _MetricData.category({
    required String label,
    required double? value,
    required IconData icon,
    required Color color,
    required Color background,
  }) {
    return _MetricData(
      label: label,
      value: value == null ? 'Not available' : '${_formatNumber(value)} / 10',
      progress: ((value ?? 0) / 10).clamp(0, 1),
      icon: icon,
      color: color,
      background: background,
    );
  }
}

class _MetricRow extends StatelessWidget {
  final _MetricData data;
  final bool compact;

  const _MetricRow({required this.data, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 13 : 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: compact ? 38 : 42,
            height: compact ? 38 : 42,
            decoration: BoxDecoration(
              color: data.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: data.color, size: compact ? 19 : 21),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        data.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _text(
                          fontSize: compact ? 12 : 13,
                          fontWeight: FontWeight.w700,
                          color: SingleResultScreen._ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      data.value,
                      style: _text(
                        fontSize: compact ? 12 : 13,
                        fontWeight: FontWeight.w800,
                        color: data.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: data.progress.clamp(0, 1),
                    minHeight: compact ? 6 : 7,
                    backgroundColor: const Color(0xFFE5E9EF),
                    valueColor: AlwaysStoppedAnimation<Color>(data.color),
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

class _Insights extends StatelessWidget {
  final _AssessmentDetailData data;
  final bool compact;

  const _Insights({required this.data, required this.compact});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 360;
        final cards = [
          _InsightCard(
            title: 'Focus Area',
            description: data.focusInsight,
            icon: Icons.track_changes_rounded,
            color: SingleResultScreen._blue,
            background: const Color(0xFFF0F8FF),
            compact: compact,
          ),
          _InsightCard(
            title: 'Keep Going',
            description: data.encouragement,
            icon: Icons.trending_up_rounded,
            color: const Color(0xFF815BEF),
            background: const Color(0xFFF7F1FF),
            compact: compact,
          ),
        ];

        if (stacked) {
          return Column(
            children: [cards.first, const SizedBox(height: 12), cards.last],
          );
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: cards.first),
              const SizedBox(width: 12),
              Expanded(child: cards.last),
            ],
          ),
        );
      },
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Color background;
  final bool compact;

  const _InsightCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.background,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 16 : 18),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: .18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: .17)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: _text(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: SingleResultScreen._ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: _text(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: SingleResultScreen._muted,
              height: 1.42,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssessmentDetailData {
  final int? id;
  final String resultLabel;
  final double score;
  final int? rawTotal;
  final double? readFocus;
  final DateTime? startedAt;
  final DateTime? completedAt;

  const _AssessmentDetailData({
    required this.id,
    required this.resultLabel,
    required this.score,
    required this.rawTotal,
    required this.readFocus,
    required this.startedAt,
    required this.completedAt,
  });

  factory _AssessmentDetailData.fromResult(ManagementResult result) {
    final score = (result.tenScore ?? 0).clamp(0, 10).toDouble();
    final backendLabel = result.result?.trim();
    return _AssessmentDetailData(
      id: result.id,
      resultLabel: backendLabel == null || backendLabel.isEmpty
          ? _labelForScore(score)
          : backendLabel,
      score: score,
      rawTotal: result.rawTotal,
      readFocus: result.readFocusTotal,
      startedAt: result.createdAt?.toLocal(),
      completedAt: result.completedAt?.toLocal(),
    );
  }

  String get assessmentId => id == null ? 'Not available' : '#$id';
  String get scoreText => _formatNumber(score);
  String get startedDate => _formatDate(startedAt);
  String get startedTime => _formatTime(startedAt);
  String get completedDate => _formatDate(completedAt);
  String get completedTime => _formatTime(completedAt);

  Color get accentColor {
    if (score <= 4) return const Color(0xFFD74242);
    if (score <= 6) return SingleResultScreen._orange;
    if (score <= 8) return const Color(0xFFB27B00);
    return const Color(0xFF168A50);
  }

  String get aboutResult {
    if (score <= 4) {
      return 'Your result indicates a severe level of difficulty. Consider using the recommended support activities consistently and discussing persistent concerns with a qualified professional.';
    }
    if (score <= 6) {
      return 'Your result indicates a moderate level of difficulty. Keep practicing focused activities and track your progress over time.';
    }
    if (score <= 8) {
      return 'Your result indicates a mild level of difficulty. Regular practice can help strengthen attention and reading consistency.';
    }
    return 'Your result indicates satisfactory to strong attention skills. Continue your current habits and review progress periodically.';
  }

  String get focusInsight {
    if (readFocus == null) {
      return 'Continue building steady focus and engagement during reading.';
    }
    return 'Your reading focus score is ${_formatNumber(readFocus!)}. Build it through short, consistent reading practice.';
  }

  String get encouragement {
    if (score >= 9) {
      return 'Maintain your strong routine and check your progress periodically.';
    }
    if (score >= 7) {
      return 'Small, regular improvements can move your attention skills forward.';
    }
    return 'Consistency is the key to stronger attention and cognitive performance.';
  }

  static String _labelForScore(double score) {
    if (score <= 4) return 'Severe difficulty';
    if (score <= 6) return 'Moderate difficulty';
    if (score <= 8) return 'Mild difficulty';
    return 'Satisfactory to strong';
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: SingleResultScreen._line),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF9BB4D1).withValues(alpha: .09),
        blurRadius: 20,
        offset: const Offset(0, 9),
      ),
    ],
  );
}

TextStyle _text({
  required double fontSize,
  required FontWeight fontWeight,
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

String _formatNumber(num value) => value.toStringAsFixed(1);

String _formatDate(DateTime? date) {
  if (date == null) return 'Not available';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
}

String _formatTime(DateTime? date) {
  if (date == null) return '';
  final hour = date.hour == 0
      ? 12
      : date.hour > 12
      ? date.hour - 12
      : date.hour;
  final minute = date.minute.toString().padLeft(2, '0');
  final suffix = date.hour >= 12 ? 'PM' : 'AM';
  return '${hour.toString().padLeft(2, '0')}:$minute $suffix';
}
