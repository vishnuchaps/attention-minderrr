import 'package:attention_minder/module/result/data/model/assessment_history_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AiAssessmentResultDetailScreen extends StatelessWidget {
  final AssessmentHistoryItem result;

  const AiAssessmentResultDetailScreen({super.key, required this.result});

  static const _background = Color(0xFFF8FBFF);
  static const _ink = Color(0xFF071443);
  static const _muted = Color(0xFF566586);
  static const _blue = Color(0xFF167FF2);
  static const _green = Color(0xFF079455);
  static const _purple = Color(0xFF7B4CF0);
  static const _orange = Color(0xFFF26B12);
  static const _teal = Color(0xFF07969A);
  static const _line = Color(0xFFD9E7F7);

  @override
  Widget build(BuildContext context) {
    final data = _AiDetailData.fromResult(result);

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
                      _AiHeader(compact: compact),
                      SizedBox(height: compact ? 18 : 24),
                      _AiOverviewCard(data: data, compact: compact),
                      SizedBox(height: compact ? 16 : 20),
                      _MeaningCard(data: data, compact: compact),
                      SizedBox(height: compact ? 24 : 30),
                      _SectionTitle(
                        title: 'Performance Summary',
                        compact: compact,
                      ),
                      SizedBox(height: compact ? 12 : 14),
                      _AiPerformanceCard(data: data, compact: compact),
                      SizedBox(height: compact ? 24 : 30),
                      _SectionTitle(
                        title: 'Session Insights',
                        compact: compact,
                      ),
                      SizedBox(height: compact ? 12 : 14),
                      _SessionInsightCard(data: data, compact: compact),
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

class _AiHeader extends StatelessWidget {
  final bool compact;

  const _AiHeader({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BackButton(compact: compact),
        SizedBox(width: compact ? 12 : 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Assessment Details',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _text(
                    fontSize: compact ? 19 : 22,
                    fontWeight: FontWeight.w800,
                    color: AiAssessmentResultDetailScreen._ink,
                    height: 1.05,
                  ),
                ),
                SizedBox(height: compact ? 8 : 10),
                Row(
                  children: [
                    Icon(
                      Icons.smart_toy_outlined,
                      color: AiAssessmentResultDetailScreen._purple,
                      size: compact ? 18 : 20,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'AI Based Assessment',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _text(
                          fontSize: compact ? 13 : 15,
                          fontWeight: FontWeight.w600,
                          color: AiAssessmentResultDetailScreen._muted,
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

class _BackButton extends StatelessWidget {
  final bool compact;

  const _BackButton({required this.compact});

  @override
  Widget build(BuildContext context) {
    final size = compact ? 42.0 : 48.0;
    return Tooltip(
      message: 'Back',
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => Navigator.maybePop(context),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AiAssessmentResultDetailScreen._line),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9BB4D1).withValues(alpha: .1),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AiAssessmentResultDetailScreen._ink,
              size: compact ? 20 : 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _AiOverviewCard extends StatelessWidget {
  final _AiDetailData data;
  final bool compact;

  const _AiOverviewCard({required this.data, required this.compact});

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
              flex: 6,
              child: _OverallScore(data: data, compact: compact),
            ),
            Container(width: 1, color: AiAssessmentResultDetailScreen._line),
            Expanded(
              flex: 5,
              child: _SessionMeta(data: data, compact: compact),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverallScore extends StatelessWidget {
  final _AiDetailData data;
  final bool compact;

  const _OverallScore({required this.data, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 14 : 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFECFAF4), Color(0xFFFFFFFF)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              if (!compact) ...[
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD9F8E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: AiAssessmentResultDetailScreen._green,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  'Overall Score',
                  maxLines: 1,
                  style: _text(
                    fontSize: compact ? 11 : 13,
                    fontWeight: FontWeight.w800,
                    color: AiAssessmentResultDetailScreen._ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: data.overallScoreText,
                    style: _text(
                      fontSize: compact ? 42 : 50,
                      fontWeight: FontWeight.w800,
                      color: data.performanceColor,
                      height: 1,
                    ),
                  ),
                  TextSpan(
                    text: ' / 100',
                    style: _text(
                      fontSize: compact ? 13 : 16,
                      fontWeight: FontWeight.w700,
                      color: AiAssessmentResultDetailScreen._muted,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: data.performanceColor.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: data.performanceColor.withValues(alpha: .28),
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                data.performanceLabel,
                maxLines: 1,
                style: _text(
                  fontSize: compact ? 11 : 13,
                  fontWeight: FontWeight.w800,
                  color: data.performanceColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionMeta extends StatelessWidget {
  final _AiDetailData data;
  final bool compact;

  const _SessionMeta({required this.data, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(compact ? 13 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _MetaItem(
            icon: Icons.calendar_today_outlined,
            primary: data.dateText,
            secondary: data.timeText,
            compact: compact,
          ),
          SizedBox(height: compact ? 14 : 18),
          _MetaItem(
            icon: Icons.schedule_rounded,
            primary: 'Duration',
            secondary: data.durationClock,
            tertiary: data.durationSecondsText,
            compact: compact,
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String primary;
  final String secondary;
  final String? tertiary;
  final bool compact;

  const _MetaItem({
    required this.icon,
    required this.primary,
    required this.secondary,
    this.tertiary,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: compact ? 18 : 21,
          color: AiAssessmentResultDetailScreen._muted,
        ),
        SizedBox(width: compact ? 8 : 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                primary,
                style: _text(
                  fontSize: compact ? 11 : 13,
                  fontWeight: FontWeight.w700,
                  color: AiAssessmentResultDetailScreen._ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                secondary,
                style: _text(
                  fontSize: compact ? 11 : 13,
                  fontWeight: FontWeight.w800,
                  color: AiAssessmentResultDetailScreen._ink,
                ),
              ),
              if (tertiary != null) ...[
                const SizedBox(height: 2),
                Text(
                  tertiary!,
                  style: _text(
                    fontSize: compact ? 9 : 11,
                    fontWeight: FontWeight.w600,
                    color: AiAssessmentResultDetailScreen._muted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MeaningCard extends StatelessWidget {
  final _AiDetailData data;
  final bool compact;

  const _MeaningCard({required this.data, required this.compact});

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
              color: AiAssessmentResultDetailScreen._blue,
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
                  'What does this mean?',
                  style: _text(
                    fontSize: compact ? 15 : 16,
                    fontWeight: FontWeight.w800,
                    color: AiAssessmentResultDetailScreen._ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  data.meaning,
                  style: _text(
                    fontSize: compact ? 12 : 13,
                    fontWeight: FontWeight.w500,
                    color: AiAssessmentResultDetailScreen._muted,
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
        color: AiAssessmentResultDetailScreen._ink,
      ),
    );
  }
}

class _AiPerformanceCard extends StatelessWidget {
  final _AiDetailData data;
  final bool compact;

  const _AiPerformanceCard({required this.data, required this.compact});

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _AiMetric(
        label: 'Concentration Score',
        value: data.concentrationScoreText,
        supporting: data.concentrationLabel,
        progress: data.concentrationProgress,
        icon: Icons.track_changes_rounded,
        color: AiAssessmentResultDetailScreen._green,
        background: const Color(0xFFE7F8F0),
      ),
      _AiMetric(
        label: 'Average Concentration Score',
        value: data.averageConcentrationText,
        supporting: data.averageConcentrationLabel,
        progress: data.averageConcentrationProgress,
        icon: Icons.trending_up_rounded,
        color: AiAssessmentResultDetailScreen._blue,
        background: const Color(0xFFE9F2FF),
      ),
      _AiMetric(
        label: 'Attention Engagement Rate',
        value: data.engagementText,
        supporting: data.engagementLabel,
        progress: data.engagementProgress,
        icon: Icons.group_outlined,
        color: AiAssessmentResultDetailScreen._purple,
        background: const Color(0xFFF2ECFF),
      ),
      _AiMetric(
        label: 'Average Confidence',
        value: data.confidenceText,
        supporting: data.confidenceLabel,
        progress: data.confidenceProgress,
        icon: Icons.verified_user_outlined,
        color: AiAssessmentResultDetailScreen._orange,
        background: const Color(0xFFFFF2E6),
      ),
      _AiMetric(
        label: 'Total Processed Frames',
        value: data.framesText,
        supporting: data.framesSupporting,
        progress: data.framesProgress,
        icon: Icons.center_focus_strong_rounded,
        color: AiAssessmentResultDetailScreen._teal,
        background: const Color(0xFFE7F7F8),
      ),
      _AiMetric(
        label: 'Session Duration',
        value: data.durationMetricText,
        supporting: data.durationClock,
        progress: data.durationProgress,
        icon: Icons.hourglass_bottom_rounded,
        color: AiAssessmentResultDetailScreen._blue,
        background: const Color(0xFFEAF1FF),
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
            _AiMetricRow(metric: metrics[index], compact: compact),
            if (index != metrics.length - 1)
              const Divider(
                height: 1,
                color: AiAssessmentResultDetailScreen._line,
              ),
          ],
        ],
      ),
    );
  }
}

class _AiMetric {
  final String label;
  final String value;
  final String supporting;
  final double? progress;
  final IconData icon;
  final Color color;
  final Color background;

  const _AiMetric({
    required this.label,
    required this.value,
    required this.supporting,
    required this.progress,
    required this.icon,
    required this.color,
    required this.background,
  });
}

class _AiMetricRow extends StatelessWidget {
  final _AiMetric metric;
  final bool compact;

  const _AiMetricRow({required this.metric, required this.compact});

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
              color: metric.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              metric.icon,
              color: metric.color,
              size: compact ? 19 : 21,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        metric.label,
                        style: _text(
                          fontSize: compact ? 11 : 13,
                          fontWeight: FontWeight.w700,
                          color: AiAssessmentResultDetailScreen._ink,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          metric.value,
                          style: _text(
                            fontSize: compact ? 11 : 13,
                            fontWeight: FontWeight.w800,
                            color: metric.color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          metric.supporting,
                          style: _text(
                            fontSize: compact ? 9 : 11,
                            fontWeight: FontWeight.w700,
                            color: AiAssessmentResultDetailScreen._muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: metric.progress,
                    minHeight: compact ? 6 : 7,
                    backgroundColor: const Color(0xFFE5E9EF),
                    valueColor: AlwaysStoppedAnimation<Color>(metric.color),
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

class _SessionInsightCard extends StatelessWidget {
  final _AiDetailData data;
  final bool compact;

  const _SessionInsightCard({required this.data, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 16 : 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFF0FBF6), Color(0xFFF8FFFC)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC9ECDD)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 42 : 46,
            height: compact ? 42 : 46,
            decoration: BoxDecoration(
              color: data.performanceColor.withValues(alpha: .1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              data.insightIcon,
              color: data.performanceColor,
              size: compact ? 22 : 25,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.insightTitle,
                  style: _text(
                    fontSize: compact ? 14 : 15,
                    fontWeight: FontWeight.w800,
                    color: data.performanceColor,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  data.insightBody,
                  style: _text(
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w500,
                    color: AiAssessmentResultDetailScreen._muted,
                    height: 1.4,
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

class _AiDetailData {
  final int overallScore;
  final double? concentrationScore;
  final double? averageConcentrationScore;
  final double? engagementRate;
  final double? averageConfidence;
  final int? totalProcessedFrames;
  final int? sampledFrames;
  final int? durationSeconds;
  final DateTime? createdAt;

  const _AiDetailData({
    required this.overallScore,
    required this.concentrationScore,
    required this.averageConcentrationScore,
    required this.engagementRate,
    required this.averageConfidence,
    required this.totalProcessedFrames,
    required this.sampledFrames,
    required this.durationSeconds,
    required this.createdAt,
  });

  factory _AiDetailData.fromResult(AssessmentHistoryItem result) {
    return _AiDetailData(
      overallScore: result.score.clamp(0, 100),
      concentrationScore: _scoreOutOfTen(result.concentrationScore),
      averageConcentrationScore: _scoreOutOfTen(
        result.averageConcentrationScore,
      ),
      engagementRate: _percentage(result.attentionEngagementRate),
      averageConfidence: _percentage(result.averageConfidence),
      totalProcessedFrames: result.totalProcessedFrames,
      sampledFrames: result.sampledFrames,
      durationSeconds: result.sessionDurationSeconds,
      createdAt: result.createdAt?.toLocal(),
    );
  }

  String get overallScoreText => overallScore.toString();
  String get dateText => _formatDate(createdAt);
  String get timeText => _formatTime(createdAt);

  String get performanceLabel {
    if (overallScore >= 90) return 'Excellent';
    if (overallScore >= 70) return 'Good';
    if (overallScore >= 50) return 'Fair';
    return 'Needs Improvement';
  }

  Color get performanceColor {
    if (overallScore >= 90) return AiAssessmentResultDetailScreen._green;
    if (overallScore >= 70) return AiAssessmentResultDetailScreen._blue;
    if (overallScore >= 50) return const Color(0xFFB57900);
    return const Color(0xFFD23F3F);
  }

  String get meaning {
    if (overallScore >= 90) {
      return 'You maintained excellent attention throughout the session. Keep up the great work!';
    }
    if (overallScore >= 70) {
      return 'You maintained good attention through most of the session. Consistent practice can make it even stronger.';
    }
    if (overallScore >= 50) {
      return 'Your attention was variable during this session. Short, regular focus practice can help improve consistency.';
    }
    return 'The session detected frequent attention difficulty. Start with shorter activities and gradually build sustained focus.';
  }

  String get insightTitle => '$performanceLabel Performance';
  String get insightBody => meaning;
  IconData get insightIcon =>
      overallScore >= 70 ? Icons.check_rounded : Icons.trending_up_rounded;

  String get concentrationScoreText => concentrationScore == null
      ? 'Not available'
      : '${_number(concentrationScore!)} / 10';
  String get averageConcentrationText => averageConcentrationScore == null
      ? 'Not available'
      : '${_number(averageConcentrationScore!)} / 10';
  String get engagementText =>
      engagementRate == null ? 'Not available' : '${_number(engagementRate!)}%';
  String get confidenceText => averageConfidence == null
      ? 'Not available'
      : '${_number(averageConfidence!)}%';
  String get framesText => totalProcessedFrames?.toString() ?? 'Not available';
  String get framesSupporting => totalProcessedFrames == null
      ? ''
      : sampledFrames == null
      ? 'frames'
      : '$sampledFrames sampled';
  String get durationMetricText =>
      durationSeconds == null ? 'Not available' : '$durationSeconds sec';
  String get durationClock => durationSeconds == null
      ? 'Not available'
      : _durationClock(durationSeconds!);
  String get durationSecondsText =>
      durationSeconds == null ? '' : '$durationSeconds seconds';

  String get concentrationLabel => _scoreLabel(concentrationScore);
  String get averageConcentrationLabel =>
      _scoreLabel(averageConcentrationScore);
  String get engagementLabel => _percentLabel(engagementRate);
  String get confidenceLabel => _percentLabel(averageConfidence);

  double? get concentrationProgress =>
      concentrationScore == null ? null : concentrationScore! / 10;
  double? get averageConcentrationProgress => averageConcentrationScore == null
      ? null
      : averageConcentrationScore! / 10;
  double? get engagementProgress =>
      engagementRate == null ? null : engagementRate! / 100;
  double? get confidenceProgress =>
      averageConfidence == null ? null : averageConfidence! / 100;
  double? get framesProgress {
    if (totalProcessedFrames == null || totalProcessedFrames == 0) return null;
    if (sampledFrames == null) return 1;
    return (sampledFrames! / totalProcessedFrames!).clamp(0, 1);
  }

  double? get durationProgress => durationSeconds == null ? null : 1;

  static double? _scoreOutOfTen(double? value) {
    if (value == null) return null;
    return (value > 10 ? value / 10 : value).clamp(0, 10);
  }

  static double? _percentage(double? value) {
    if (value == null) return null;
    return (value <= 1 ? value * 100 : value).clamp(0, 100);
  }

  static String _scoreLabel(double? value) {
    if (value == null) return '';
    if (value >= 9) return 'Excellent';
    if (value >= 7) return 'Good';
    if (value >= 5) return 'Fair';
    return 'Needs improvement';
  }

  static String _percentLabel(double? value) {
    if (value == null) return '';
    if (value >= 90) return 'Excellent';
    if (value >= 70) return 'Good';
    if (value >= 50) return 'Fair';
    return 'Needs improvement';
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: AiAssessmentResultDetailScreen._line),
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

String _number(num value) => value.toStringAsFixed(1);

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

String _durationClock(int totalSeconds) {
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}
