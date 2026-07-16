import 'package:attention_minder/dependency_injection/injection_container.dart';
import 'package:attention_minder/module/assigment/presentation/bloc/assignment_bloc.dart';
import 'package:attention_minder/module/assigment/presentation/screens/questionnaire_screen.dart';
import 'package:attention_minder/module/landing/presentation/screens/landing_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SelfAssessmentResultScreen extends StatefulWidget {
  const SelfAssessmentResultScreen({super.key});

  @override
  State<SelfAssessmentResultScreen> createState() =>
      _SelfAssessmentResultScreenState();
}

class _SelfAssessmentResultScreenState
    extends State<SelfAssessmentResultScreen> {
  static const _pageBackground = Color(0xFFFBFCFF);
  static const _ink = Color(0xFF071345);
  static const _muted = Color(0xFF586585);
  static const _blue = Color(0xFF1479FF);
  static const _green = Color(0xFF31C96B);
  static const _orange = Color(0xFFFF8A00);
  static const _line = Color(0xFFE1E8F2);

  final AssignmentBloc _assignmentBloc = getIt<AssignmentBloc>();
  String _username = 'User';

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _assignmentBloc.add(FetchAssessmentResults());
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _username = prefs.getString('username') ?? 'User';
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _assignmentBloc,
      child: Scaffold(
        backgroundColor: _pageBackground,
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<AssignmentBloc, AssignmentState>(
            builder: (context, state) {
              if (state is AssignmentInitial || state is AssignmentLoading) {
                return const _ResultLoadingView();
              }
              if (state is FetchResultsFailed) {
                return _ResultErrorView(
                  message: state.error,
                  onRetry: () => _assignmentBloc.add(FetchAssessmentResults()),
                );
              }
              if (state is! FetchResultsSuccess) {
                return const _ResultLoadingView();
              }

              final result = _ResultViewData.fromMap(state.resultsData);
              if (result == null) {
                return _ResultErrorView(
                  message: 'The assessment result could not be read.',
                  onRetry: () => _assignmentBloc.add(FetchAssessmentResults()),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final compact = width < 370;
                  final horizontalPadding = (width * .075)
                      .clamp(18.0, 30.0)
                      .toDouble();
                  final maxWidth = width > 560 ? 520.0 : width;

                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          compact ? 18 : 24,
                          horizontalPadding,
                          28 + MediaQuery.paddingOf(context).bottom,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TopBar(compact: compact),
                            SizedBox(height: compact ? 26 : 32),
                            _SummaryCard(
                              username: result.username ?? _username,
                              compact: compact,
                            ),
                            SizedBox(height: compact ? 20 : 24),
                            _OverallScoreCard(result: result, compact: compact),
                            SizedBox(height: compact ? 20 : 24),
                            _AttentionOverviewCard(
                              result: result,
                              compact: compact,
                            ),
                            SizedBox(height: compact ? 20 : 24),
                            _ScoreExplanationCard(
                              result: result,
                              compact: compact,
                            ),
                            SizedBox(height: compact ? 18 : 22),
                            _ActionButtons(compact: compact),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ResultLoadingView extends StatelessWidget {
  const _ResultLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: _SelfAssessmentResultScreenState._blue,
      ),
    );
  }
}

class _ResultErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ResultErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 42,
              color: _SelfAssessmentResultScreenState._orange,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: _type(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _SelfAssessmentResultScreenState._muted,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final bool compact;

  const _TopBar({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.maybePop(context),
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.arrow_back_rounded,
                color: _SelfAssessmentResultScreenState._ink,
                size: compact ? 25 : 28,
              ),
            ),
          ),
        ),
        SizedBox(width: compact ? 14 : 18),
        Expanded(
          child: Text(
            'Assessment Result',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _type(
              fontSize: compact ? 20 : 23,
              fontWeight: FontWeight.w900,
              color: _SelfAssessmentResultScreenState._ink,
              height: 1.05,
            ),
          ),
        ),
        Container(
          width: compact ? 34 : 38,
          height: compact ? 34 : 38,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFDDE9FA)),
          ),
          child: Icon(
            Icons.shield_outlined,
            color: _SelfAssessmentResultScreenState._blue,
            size: compact ? 20 : 22,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String username;
  final bool compact;

  const _SummaryCard({required this.username, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        compact ? 18 : 22,
        compact ? 18 : 22,
        compact ? 14 : 18,
        compact ? 18 : 22,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCFE5FF)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF6FF), Color(0xFFDCEFFF)],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Great effort, $username!',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _type(
                    fontSize: compact ? 19 : 22,
                    fontWeight: FontWeight.w900,
                    color: _SelfAssessmentResultScreenState._ink,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Here's a summary of your\nattention assessment.",
                  style: _type(
                    fontSize: compact ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: _SelfAssessmentResultScreenState._ink,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: compact ? 8 : 12),
          _ClipboardIllustration(compact: compact),
        ],
      ),
    );
  }
}

class _ClipboardIllustration extends StatelessWidget {
  final bool compact;

  const _ClipboardIllustration({required this.compact});

  @override
  Widget build(BuildContext context) {
    final width = compact ? 88.0 : 104.0;

    return SizedBox(
      width: width,
      height: compact ? 92 : 106,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: width * .92,
              height: width * .72,
              decoration: BoxDecoration(
                color: const Color(0xFFCFEAFF).withValues(alpha: .62),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 9,
            left: width * .18,
            child: Container(
              width: width * .56,
              height: width * .76,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBFD4EA), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9CB2C9).withValues(alpha: .32),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  width * .09,
                  width * .16,
                  width * .09,
                  width * .09,
                ),
                child: Column(
                  children: [
                    _MiniLine(
                      width: width * .24,
                      color: const Color(0xFF1479FF),
                    ),
                    SizedBox(height: width * .06),
                    _MiniLine(
                      width: width * .34,
                      color: const Color(0xFFC8D7EA),
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _MiniBar(height: width * .18),
                        SizedBox(width: width * .05),
                        _MiniBar(height: width * .28),
                        SizedBox(width: width * .05),
                        _MiniBar(height: width * .43),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: Container(
              width: width * .26,
              height: width * .11,
              decoration: BoxDecoration(
                color: const Color(0xFF3B6CB8),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Positioned(
            right: 4,
            bottom: 12,
            child: Container(
              width: compact ? 28 : 34,
              height: compact ? 28 : 34,
              decoration: const BoxDecoration(
                color: Color(0xFF1479FF),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: compact ? 18 : 21,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniLine extends StatelessWidget {
  final double width;
  final Color color;

  const _MiniLine({required this.width, required this.color});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: width,
        height: 4,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  final double height;

  const _MiniBar({required this.height});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF7FB9FF),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

class _OverallScoreCard extends StatelessWidget {
  final _ResultViewData result;
  final bool compact;

  const _OverallScoreCard({required this.result, required this.compact});

  @override
  Widget build(BuildContext context) {
    final score = result.score;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 18 : 22,
        vertical: compact ? 24 : 28,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF05245A), Color(0xFF001B46)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0C2F70).withValues(alpha: .25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Overall Score',
            style: _type(
              fontSize: compact ? 15 : 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: compact ? 22 : 26),
          SizedBox(
            width: compact ? 162 : 178,
            height: compact ? 162 : 178,
            child: _ScoreRing(score: score),
          ),
          SizedBox(height: compact ? 22 : 26),
          Text(
            result.focusLabel,
            style: _type(
              fontSize: compact ? 20 : 22,
              fontWeight: FontWeight.w900,
              color: _SelfAssessmentResultScreenState._blue,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            result.scoreMessage,
            style: _type(
              fontSize: compact ? 13 : 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  final double score;

  const _ScoreRing({required this.score});

  @override
  Widget build(BuildContext context) {
    final value = (score / 10).clamp(0.0, 1.0);

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox.expand(
          child: CircularProgressIndicator(
            value: value,
            strokeWidth: 15,
            strokeCap: StrokeCap.round,
            color: _SelfAssessmentResultScreenState._blue,
            backgroundColor: Colors.white.withValues(alpha: .18),
          ),
        ),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: _formatScore(score),
                style: _type(
                  fontSize: 58,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              TextSpan(
                text: '/10',
                style: _type(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: .86),
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AttentionOverviewCard extends StatelessWidget {
  final _ResultViewData result;
  final bool compact;

  const _AttentionOverviewCard({required this.result, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        compact ? 18 : 22,
        compact ? 20 : 24,
        compact ? 18 : 22,
        compact ? 18 : 22,
      ),
      decoration: _softCardDecoration(radius: 17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attention Overview',
            style: _type(
              fontSize: compact ? 15 : 16,
              fontWeight: FontWeight.w900,
              color: _SelfAssessmentResultScreenState._ink,
            ),
          ),
          SizedBox(height: compact ? 22 : 26),
          _OverviewRow(
            icon: Icons.fact_check_outlined,
            title: 'Total Answer Score',
            subtitle: 'Combined score from all answers',
            value: result.rawTotalText,
            color: _SelfAssessmentResultScreenState._orange,
            background: const Color(0xFFEAF4FF),
            compact: compact,
          ),
          const _OverviewDivider(),
          _OverviewRow(
            icon: Icons.menu_book_outlined,
            title: 'Reading & Focus Score',
            subtitle: 'Reading and focus category total',
            value: result.readFocusTotalText,
            color: _SelfAssessmentResultScreenState._green,
            background: const Color(0xFFEAF9EF),
            compact: compact,
          ),
        ],
      ),
    );
  }
}

class _OverviewRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final Color color;
  final Color background;
  final bool compact;

  const _OverviewRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.color,
    required this.background,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: compact ? 52 : 58,
          height: compact ? 52 : 58,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: color, size: compact ? 26 : 29),
        ),
        SizedBox(width: compact ? 14 : 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _type(
                  fontSize: compact ? 14 : 16,
                  fontWeight: FontWeight.w900,
                  color: _SelfAssessmentResultScreenState._ink,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _type(
                  fontSize: compact ? 12 : 14,
                  fontWeight: FontWeight.w600,
                  color: _SelfAssessmentResultScreenState._muted,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: compact ? 10 : 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: _type(
                fontSize: compact ? 20 : 23,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OverviewDivider extends StatelessWidget {
  const _OverviewDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 34,
      thickness: 1,
      color: _SelfAssessmentResultScreenState._line,
    );
  }
}

class _ScoreExplanationCard extends StatelessWidget {
  final _ResultViewData result;
  final bool compact;

  const _ScoreExplanationCard({required this.result, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        compact ? 18 : 22,
        compact ? 18 : 22,
        compact ? 16 : 18,
        compact ? 18 : 22,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E7),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFFFDCA3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: _SelfAssessmentResultScreenState._orange,
                size: 23,
              ),
              const SizedBox(width: 10),
              Text(
                'Understanding Your Score',
                style: _type(
                  fontSize: compact ? 16 : 18,
                  fontWeight: FontWeight.w900,
                  color: _SelfAssessmentResultScreenState._orange,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 18 : 22),
          Text(
            'Each answer contributes 0 to 4 points. Your total is normalized '
            'to a score out of 10, with reverse scoring applied to applicable '
            'questions.',
            style: _type(
              fontSize: compact ? 13 : 15,
              fontWeight: FontWeight.w600,
              color: _SelfAssessmentResultScreenState._ink,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Your result: ${result.resultLabel}',
            style: _type(
              fontSize: compact ? 14 : 16,
              fontWeight: FontWeight.w900,
              color: _SelfAssessmentResultScreenState._orange,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final bool compact;

  const _ActionButtons({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: compact ? 50 : 54,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const QuestionnaireScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _SelfAssessmentResultScreenState._blue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Retake assessment',
              style: _type(
                fontSize: compact ? 14 : 15,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: compact ? 48 : 52,
          child: OutlinedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LandingScreen()),
                (route) => false,
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: _SelfAssessmentResultScreenState._ink,
              side: const BorderSide(color: Color(0xFFDDE5EF)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Back to home',
              style: _type(
                fontSize: compact ? 14 : 15,
                fontWeight: FontWeight.w900,
                color: _SelfAssessmentResultScreenState._ink,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultViewData {
  final double score;
  final int rawTotal;
  final double readFocusTotal;
  final String resultLabel;
  final String? username;

  const _ResultViewData({
    required this.score,
    required this.rawTotal,
    required this.readFocusTotal,
    required this.resultLabel,
    required this.username,
  });

  static _ResultViewData? fromMap(Map<String, dynamic> data) {
    final payload = data['data'] is Map ? data['data'] as Map : data;
    final score = _numberFromPayload(payload, 'tenscore');
    final rawTotal = _numberFromPayload(payload, 'raw_total');
    final readFocusTotal = _numberFromPayload(payload, 'read_focus_total');
    final resultLabel = payload['result']?.toString().trim() ?? '';

    if (score == null ||
        rawTotal == null ||
        readFocusTotal == null ||
        resultLabel.isEmpty) {
      return null;
    }

    return _ResultViewData(
      score: score.clamp(0, 10).toDouble(),
      rawTotal: rawTotal.round(),
      readFocusTotal: readFocusTotal,
      resultLabel: resultLabel,
      username: _nonEmptyString(payload['user']),
    );
  }

  String get focusLabel => resultLabel;

  String get scoreMessage {
    if (score >= 9) return 'Satisfactory to strong attention skills';
    if (score >= 7) return 'Mild attention difficulty';
    if (score >= 5) return 'Moderate attention difficulty';
    return 'Severe attention difficulty';
  }

  String get rawTotalText => rawTotal.toString();

  String get readFocusTotalText => _formatScore(readFocusTotal);

  static double? _numberFromPayload(Map<dynamic, dynamic> payload, String key) {
    final value = payload[key];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static String? _nonEmptyString(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}

String _formatScore(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);

BoxDecoration _softCardDecoration({required double radius}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: const Color(0xFFE1E8F2)),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFFB6C9DF).withValues(alpha: .12),
        blurRadius: 22,
        offset: const Offset(0, 10),
      ),
    ],
  );
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
