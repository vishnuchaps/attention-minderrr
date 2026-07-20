import 'package:attention_minder/module/result/data/model/result_weeklydetail.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ManagementSessionDetailScreen extends StatelessWidget {
  final ManagementSession session;

  const ManagementSessionDetailScreen({super.key, required this.session});

  static const _background = Color(0xFFF8FBFF);
  static const _ink = Color(0xFF071443);
  static const _muted = Color(0xFF566586);
  static const _blue = Color(0xFF167FF2);
  static const _orange = Color(0xFFF26B12);
  static const _green = Color(0xFF079455);
  static const _purple = Color(0xFF7B4CF0);
  static const _teal = Color(0xFF07969A);
  static const _amber = Color(0xFFB57900);
  static const _red = Color(0xFFD23F3F);
  static const _line = Color(0xFFD9E7F7);

  @override
  Widget build(BuildContext context) {
    final data = _ManagementDetailData.fromSession(session);
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
                      _Header(data: data, compact: compact),
                      SizedBox(height: compact ? 18 : 24),
                      _OverviewCard(data: data, compact: compact),
                      SizedBox(height: compact ? 16 : 20),
                      _MeaningCard(data: data, compact: compact),
                      if (data.primaryMetrics.isNotEmpty) ...[
                        SizedBox(height: compact ? 24 : 30),
                        _SectionTitle(
                          title: data.performanceTitle,
                          compact: compact,
                        ),
                        SizedBox(height: compact ? 12 : 14),
                        _MetricGrid(
                          metrics: data.primaryMetrics,
                          compact: compact,
                        ),
                      ],
                      if (data.insightMetrics.isNotEmpty) ...[
                        SizedBox(height: compact ? 24 : 30),
                        _SectionTitle(
                          title: 'Session Insights',
                          compact: compact,
                        ),
                        SizedBox(height: compact ? 12 : 14),
                        _InsightCard(
                          metrics: data.insightMetrics,
                          compact: compact,
                        ),
                      ],
                      SizedBox(height: compact ? 24 : 30),
                      _GuidanceCard(data: data, compact: compact),
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

class _Header extends StatelessWidget {
  final _ManagementDetailData data;
  final bool compact;

  const _Header({required this.data, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Tooltip(
          message: 'Back',
          child: Material(
            color: Colors.white,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.maybePop(context),
              child: Container(
                width: compact ? 42 : 48,
                height: compact ? 42 : 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ManagementSessionDetailScreen._line,
                  ),
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
                  color: ManagementSessionDetailScreen._ink,
                  size: compact ? 20 : 22,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: compact ? 12 : 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.pageTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _text(
                    fontSize: compact ? 19 : 22,
                    fontWeight: FontWeight.w800,
                    color: ManagementSessionDetailScreen._ink,
                    height: 1.05,
                  ),
                ),
                SizedBox(height: compact ? 8 : 10),
                Row(
                  children: [
                    Icon(
                      data.typeIcon,
                      color: data.typeColor,
                      size: compact ? 18 : 20,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        data.sessionTypeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _text(
                          fontSize: compact ? 13 : 15,
                          fontWeight: FontWeight.w600,
                          color: ManagementSessionDetailScreen._muted,
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

class _OverviewCard extends StatelessWidget {
  final _ManagementDetailData data;
  final bool compact;

  const _OverviewCard({required this.data, required this.compact});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final verticallyStacked = constraints.maxWidth < 330;
        final scorePanel = _ScoreOverviewPanel(data: data, compact: compact);
        final metaPanel = _OverviewMetaPanel(data: data, compact: compact);
        return Container(
          width: double.infinity,
          decoration: _cardDecoration(),
          clipBehavior: Clip.antiAlias,
          child: verticallyStacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    scorePanel,
                    Container(
                      height: 1,
                      color: ManagementSessionDetailScreen._line,
                    ),
                    metaPanel,
                  ],
                )
              : IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 6, child: scorePanel),
                      Container(
                        width: 1,
                        color: ManagementSessionDetailScreen._line,
                      ),
                      Expanded(flex: 5, child: metaPanel),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _ScoreOverviewPanel extends StatelessWidget {
  final _ManagementDetailData data;
  final bool compact;

  const _ScoreOverviewPanel({required this.data, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [data.typeColor.withValues(alpha: .11), Colors.white],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Overall Score',
            style: _text(
              fontSize: compact ? 11 : 13,
              fontWeight: FontWeight.w800,
              color: ManagementSessionDetailScreen._ink,
            ),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: data.scoreText,
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
                      color: ManagementSessionDetailScreen._muted,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 11),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: data.performanceColor.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: data.performanceColor.withValues(alpha: .25),
              ),
            ),
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
        ],
      ),
    );
  }
}

class _OverviewMetaPanel extends StatelessWidget {
  final _ManagementDetailData data;
  final bool compact;

  const _OverviewMetaPanel({required this.data, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(compact ? 16 : 18),
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
            secondary: data.durationText,
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
  final bool compact;

  const _MetaItem({
    required this.icon,
    required this.primary,
    required this.secondary,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: ManagementSessionDetailScreen._blue,
          size: compact ? 17 : 19,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                primary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _text(
                  fontSize: compact ? 10 : 12,
                  fontWeight: FontWeight.w800,
                  color: ManagementSessionDetailScreen._ink,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                secondary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _text(
                  fontSize: compact ? 9 : 11,
                  fontWeight: FontWeight.w600,
                  color: ManagementSessionDetailScreen._muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MeaningCard extends StatelessWidget {
  final _ManagementDetailData data;
  final bool compact;

  const _MeaningCard({required this.data, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 16 : 18),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 40 : 44,
            height: compact ? 40 : 44,
            decoration: BoxDecoration(
              color: data.typeColor.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              data.typeIcon,
              color: data.typeColor,
              size: compact ? 21 : 24,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.contentTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _text(
                    fontSize: compact ? 15 : 17,
                    fontWeight: FontWeight.w800,
                    color: ManagementSessionDetailScreen._ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  data.description,
                  style: _text(
                    fontSize: compact ? 11 : 13,
                    fontWeight: FontWeight.w500,
                    color: ManagementSessionDetailScreen._muted,
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool compact;

  const _SectionTitle({required this.title, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: _text(
        fontSize: compact ? 17 : 20,
        fontWeight: FontWeight.w800,
        color: ManagementSessionDetailScreen._ink,
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  final List<_DetailMetric> metrics;
  final bool compact;

  const _MetricGrid({required this.metrics, required this.compact});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 350 ? 1 : 2;
        final ratio = columns == 1 ? 3.15 : (compact ? 1.48 : 1.58);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: ratio,
          ),
          itemBuilder: (context, index) =>
              _MetricTile(metric: metrics[index], compact: compact),
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  final _DetailMetric metric;
  final bool compact;

  const _MetricTile({required this.metric, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: metric.color.withValues(alpha: .2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9BB4D1).withValues(alpha: .06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: compact ? 36 : 40,
            height: compact ? 36 : 40,
            decoration: BoxDecoration(
              color: metric.color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              metric.icon,
              color: metric.color,
              size: compact ? 18 : 21,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _text(
                    fontSize: compact ? 10 : 11,
                    fontWeight: FontWeight.w700,
                    color: ManagementSessionDetailScreen._muted,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          metric.value,
                          maxLines: 1,
                          style: _text(
                            fontSize: compact ? 15 : 17,
                            fontWeight: FontWeight.w800,
                            color: metric.color,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  metric.supporting,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _text(
                    fontSize: compact ? 9 : 10,
                    fontWeight: FontWeight.w600,
                    color: ManagementSessionDetailScreen._muted,
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

class _InsightCard extends StatelessWidget {
  final List<_DetailMetric> metrics;
  final bool compact;

  const _InsightCard({required this.metrics, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 18,
        vertical: compact ? 6 : 8,
      ),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          for (var index = 0; index < metrics.length; index++) ...[
            Padding(
              padding: EdgeInsets.symmetric(vertical: compact ? 11 : 13),
              child: Row(
                children: [
                  Icon(
                    metrics[index].icon,
                    color: metrics[index].color,
                    size: compact ? 20 : 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          metrics[index].label,
                          style: _text(
                            fontSize: compact ? 11 : 13,
                            fontWeight: FontWeight.w700,
                            color: ManagementSessionDetailScreen._ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          metrics[index].supporting,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _text(
                            fontSize: compact ? 9 : 10,
                            fontWeight: FontWeight.w600,
                            color: ManagementSessionDetailScreen._muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    metrics[index].value,
                    style: _text(
                      fontSize: compact ? 11 : 13,
                      fontWeight: FontWeight.w800,
                      color: metrics[index].color,
                    ),
                  ),
                ],
              ),
            ),
            if (index != metrics.length - 1)
              const Divider(
                height: 1,
                color: ManagementSessionDetailScreen._line,
              ),
          ],
        ],
      ),
    );
  }
}

class _GuidanceCard extends StatelessWidget {
  final _ManagementDetailData data;
  final bool compact;

  const _GuidanceCard({required this.data, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 16 : 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [data.performanceColor.withValues(alpha: .08), Colors.white],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: data.performanceColor.withValues(alpha: .22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            data.score >= 70
                ? Icons.check_circle_outline_rounded
                : Icons.trending_up_rounded,
            color: data.performanceColor,
            size: compact ? 25 : 28,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data.performanceLabel} ${data.activityLabel}',
                  style: _text(
                    fontSize: compact ? 14 : 15,
                    fontWeight: FontWeight.w800,
                    color: data.performanceColor,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  data.guidance,
                  style: _text(
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w500,
                    color: ManagementSessionDetailScreen._muted,
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

class _ManagementDetailData {
  final ManagementSession session;
  final bool isPdf;
  final int score;
  final List<_DetailMetric> primaryMetrics;
  final List<_DetailMetric> insightMetrics;

  const _ManagementDetailData({
    required this.session,
    required this.isPdf,
    required this.score,
    required this.primaryMetrics,
    required this.insightMetrics,
  });

  factory _ManagementDetailData.fromSession(ManagementSession session) {
    final reader = _ResponseReader(session.rawData);
    final isPdf = session.isPdf;
    final primary = <_DetailMetric>[];
    final insights = <_DetailMetric>[];

    void add(
      List<_DetailMetric> target,
      String label,
      List<String> keys,
      IconData icon,
      Color color,
      String Function(num value) formatter,
    ) {
      final value = reader.number(keys);
      if (value == null || value == 0) return;
      target.add(
        _DetailMetric(
          label: label,
          value: formatter(value),
          icon: icon,
          color: _metricColor(label, value, color),
          supporting: _metricSupporting(label, value),
        ),
      );
    }

    if (isPdf) {
      add(
        primary,
        'Attention Engagement',
        const ['attention_engagement_rate'],
        Icons.visibility_outlined,
        ManagementSessionDetailScreen._blue,
        _percent,
      );
      add(
        primary,
        'Concentration Score',
        const ['concentration_score', 'average_concentration_score'],
        Icons.psychology_outlined,
        ManagementSessionDetailScreen._purple,
        (value) => '${_decimal(value)} / 10',
      );
      add(
        primary,
        'Reading Engagement',
        const ['reading_engagement_rate'],
        Icons.menu_book_rounded,
        ManagementSessionDetailScreen._orange,
        _percent,
      );
      add(
        primary,
        'Tracking Quality',
        const ['gaze_quality_avg'],
        Icons.remove_red_eye_outlined,
        ManagementSessionDetailScreen._green,
        _normalizedPercent,
      );

      add(
        insights,
        'Average gaze ratio',
        const ['gaze_ratio_avg'],
        Icons.remove_red_eye_outlined,
        ManagementSessionDetailScreen._purple,
        _decimal,
      );
      add(
        insights,
        'Reading gaze frequency',
        const ['reading_gaze_frequency_avg_hz'],
        Icons.speed_rounded,
        ManagementSessionDetailScreen._teal,
        (value) => '${_decimal(value)} Hz',
      );
      add(
        insights,
        'Distracted frames',
        const ['idle_distracted_frames'],
        Icons.visibility_off_outlined,
        ManagementSessionDetailScreen._orange,
        _integer,
      );
    } else {
      add(
        primary,
        'Attention Engagement',
        const ['attention_engagement_rate'],
        Icons.visibility_outlined,
        ManagementSessionDetailScreen._blue,
        _percent,
      );
      add(
        primary,
        'Concentration Score',
        const ['concentration_score', 'average_concentration_score'],
        Icons.psychology_outlined,
        ManagementSessionDetailScreen._purple,
        (value) => '${_decimal(value)} / 10',
      );
      add(
        primary,
        'Tracking Confidence',
        const ['average_confidence'],
        Icons.verified_outlined,
        ManagementSessionDetailScreen._green,
        _normalizedPercent,
      );
      add(
        insights,
        'Gaze warnings',
        const ['gaze_warning_count'],
        Icons.visibility_off_outlined,
        ManagementSessionDetailScreen._orange,
        _integer,
      );
      add(
        insights,
        'Eyes-closed events',
        const ['eyes_closed_count'],
        Icons.bedtime_outlined,
        ManagementSessionDetailScreen._teal,
        _integer,
      );
    }

    add(
      insights,
      'Inattention duration',
      const ['inattention_duration'],
      Icons.timer_off_outlined,
      ManagementSessionDetailScreen._orange,
      _seconds,
    );
    add(
      insights,
      'Longest inattention',
      const ['maximum_inattention_duration', 'max_inattention_duration'],
      Icons.timelapse_rounded,
      ManagementSessionDetailScreen._orange,
      _seconds,
    );

    return _ManagementDetailData(
      session: session,
      isPdf: isPdf,
      score: session.safeScore.round().clamp(0, 100),
      primaryMetrics: primary,
      insightMetrics: insights,
    );
  }

  String get pageTitle =>
      isPdf ? 'Reading Focus Details' : 'Focus Training Details';
  String get sessionTypeLabel =>
      isPdf ? 'PDF Management Session' : 'Video Management Session';
  String get activityLabel => isPdf ? 'Reading Focus' : 'Focus Training';
  IconData get typeIcon =>
      isPdf ? Icons.description_outlined : Icons.play_circle_outline_rounded;
  Color get typeColor => isPdf
      ? ManagementSessionDetailScreen._orange
      : ManagementSessionDetailScreen._blue;
  String get scoreText => score.toString();

  String get contentTitle {
    final title = session.title?.trim();
    if (title == null || title.isEmpty) return activityLabel;
    return title.replaceFirst(
      RegExp(r'\.(pdf|mp4|mov|m4v)$', caseSensitive: false),
      '',
    );
  }

  String get dateText => _formatDate(session.createdAt?.toLocal());
  String get timeText {
    final label = session.timeLabel?.trim();
    return label == null || label.isEmpty
        ? _formatTime(session.createdAt?.toLocal())
        : label;
  }

  String get durationText {
    final label = session.durationLabel?.trim();
    final hasUsefulLabel =
        label != null &&
        label.isNotEmpty &&
        !(session.safeDurationSeconds > 0 &&
            const {
              '0m',
              '0 min',
              '0 mins',
              '0 minutes',
            }.contains(label.toLowerCase()));
    if (hasUsefulLabel) return label;
    return _seconds(session.safeDurationSeconds);
  }

  String get performanceTitle =>
      isPdf ? 'Reading Performance' : 'Focus Performance';
  String get performanceLabel {
    if (score >= 90) return 'Excellent';
    if (score >= 70) return 'Good';
    if (score >= 50) return 'Fair';
    return 'Needs Improvement';
  }

  Color get performanceColor {
    if (score >= 90) return ManagementSessionDetailScreen._green;
    if (score >= 70) return ManagementSessionDetailScreen._blue;
    if (score >= 50) return const Color(0xFFB57900);
    return const Color(0xFFD23F3F);
  }

  String get description => isPdf
      ? 'This result summarizes attention and reading behavior while you worked through this document.'
      : 'This result summarizes sustained attention and visual engagement while you completed this video.';

  String get guidance {
    if (score >= 90) {
      return isPdf
          ? 'You maintained excellent reading attention. Continue using the same calm pace and environment.'
          : 'You maintained excellent attention through the video. Keep using the same focused viewing routine.';
    }
    if (score >= 70) {
      return isPdf
          ? 'Your reading focus was strong. Short breaks between documents can help maintain this consistency.'
          : 'Your video focus was strong. A distraction-free setup can help you sustain it for longer sessions.';
    }
    if (score >= 50) {
      return isPdf
          ? 'Your reading attention varied. Try shorter reading blocks and pause briefly between sections.'
          : 'Your attention varied during the video. Try shorter training blocks in a quieter environment.';
    }
    return isPdf
        ? 'Start with shorter documents and gradually increase reading time as sustained focus improves.'
        : 'Start with shorter videos and gradually increase session length as sustained attention improves.';
  }
}

class _DetailMetric {
  final String label;
  final String value;
  final String supporting;
  final IconData icon;
  final Color color;

  const _DetailMetric({
    required this.label,
    required this.value,
    required this.supporting,
    required this.icon,
    required this.color,
  });
}

class _ResponseReader {
  final Map<String, dynamic> source;

  const _ResponseReader(this.source);

  num? number(List<String> keys) {
    final value = _value(source, keys);
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '');
  }

  dynamic _value(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      if (map[key] != null) return map[key];
    }
    for (final container in const [
      'metrics',
      'session_summary',
      'summary',
      'data',
    ]) {
      final nested = map[container];
      if (nested is Map) {
        final value = _value(Map<String, dynamic>.from(nested), keys);
        if (value != null) return value;
      }
    }
    return null;
  }
}

Color _metricColor(String label, num value, Color fallback) {
  final normalized = label.toLowerCase();
  double? qualityPercent;
  if (normalized.contains('engagement') ||
      normalized.contains('tracking quality') ||
      normalized.contains('tracking confidence')) {
    qualityPercent = value <= 1 ? value * 100 : value.toDouble();
  } else if (normalized.contains('concentration')) {
    qualityPercent = value <= 10 ? value * 10 : value.toDouble();
  }

  if (qualityPercent != null) {
    if (qualityPercent >= 85) return ManagementSessionDetailScreen._green;
    if (qualityPercent >= 70) return ManagementSessionDetailScreen._blue;
    if (qualityPercent >= 50) return ManagementSessionDetailScreen._amber;
    return ManagementSessionDetailScreen._red;
  }

  if (normalized.contains('warning') ||
      normalized.contains('eyes-closed') ||
      normalized.contains('distracted')) {
    return value >= 5
        ? ManagementSessionDetailScreen._red
        : ManagementSessionDetailScreen._amber;
  }
  if (normalized.contains('inattention')) {
    return value >= 15
        ? ManagementSessionDetailScreen._red
        : ManagementSessionDetailScreen._amber;
  }
  return fallback;
}

String _metricSupporting(String label, num value) {
  final normalized = label.toLowerCase();
  double? qualityPercent;
  if (normalized.contains('engagement') ||
      normalized.contains('tracking quality') ||
      normalized.contains('tracking confidence')) {
    qualityPercent = value <= 1 ? value * 100 : value.toDouble();
  } else if (normalized.contains('concentration')) {
    qualityPercent = value <= 10 ? value * 10 : value.toDouble();
  }

  if (qualityPercent != null) {
    if (qualityPercent >= 85) return 'Excellent';
    if (qualityPercent >= 70) return 'Strong';
    if (qualityPercent >= 50) return 'Developing';
    return 'Needs attention';
  }
  if (normalized.contains('average gaze ratio')) {
    return 'Reading gaze balance';
  }
  if (normalized.contains('gaze frequency')) return 'Reading scan rhythm';
  if (normalized.contains('distracted')) return 'Attention shifts detected';
  if (normalized.contains('warning')) return 'Off-screen attention events';
  if (normalized.contains('eyes-closed')) return 'Eye-closure events';
  if (normalized.contains('longest')) return 'Longest focus interruption';
  if (normalized.contains('inattention')) return 'Total focus interruption';
  return 'Session measurement';
}

String _formatDate(DateTime? date) {
  if (date == null) return 'Date unavailable';
  const months = <String>[
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
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String _formatTime(DateTime? date) {
  if (date == null) return 'Time unavailable';
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${date.hour < 12 ? 'AM' : 'PM'}';
}

String _integer(num value) => value.round().toString();
String _decimal(num value) => value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
String _percent(num value) => '${_decimal(value)}%';
String _normalizedPercent(num value) =>
    _percent(value <= 1 ? value * 100 : value);
String _seconds(num value) {
  final total = value.round().clamp(0, 86400);
  final minutes = total ~/ 60;
  final seconds = total % 60;
  if (minutes == 0) return '$seconds sec';
  if (seconds == 0) return '$minutes min';
  return '$minutes min $seconds sec';
}

BoxDecoration _cardDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(14),
  border: Border.all(color: ManagementSessionDetailScreen._line),
  boxShadow: [
    BoxShadow(
      color: const Color(0xFF9BB4D1).withValues(alpha: .08),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ],
);

TextStyle _text({
  required double fontSize,
  required FontWeight fontWeight,
  required Color color,
  double? height,
}) => GoogleFonts.nunitoSans(
  fontSize: fontSize,
  fontWeight: fontWeight,
  color: color,
  height: height,
);
