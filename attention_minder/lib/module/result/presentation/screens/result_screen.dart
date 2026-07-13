import 'package:attention_minder/Config/widgets/user_profile_avatar_widget.dart';
import 'package:attention_minder/dependency_injection/injection_container.dart';
import 'package:attention_minder/module/result/bloc/questionnaire_result_bloc.dart';
import 'package:attention_minder/module/result/bloc/result_bloc.dart';
import 'package:attention_minder/module/result/bloc/result_detail_bloc.dart';
import 'package:attention_minder/module/result/data/model/assessment_history_model.dart';
import 'package:attention_minder/module/result/data/model/dashboard_management.dart';
import 'package:attention_minder/module/result/data/model/questionnaire_result_model.dart';
import 'package:attention_minder/module/result/data/model/result_weeklydetail.dart';
import 'package:attention_minder/module/result/services/result_pdf_exporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  static const _pageBackground = Color(0xFFF8FBFF);
  static const _ink = Color(0xFF06103B);
  static const _muted = Color(0xFF5E6B8D);
  static const _blue = Color(0xFF1288F6);
  static const _purple = Color(0xFF7B61F2);
  static const _line = Color(0xFFD8E7FA);
  static const _green = Color(0xFF159B51);
  static const _orange = Color(0xFFF26B12);

  final ResultBloc _resultBloc = getIt<ResultBloc>();
  final ResultBloc _managementBloc = getIt<ResultBloc>();
  final ResultDetailBloc _resultDetailBloc = getIt<ResultDetailBloc>();
  final QuestionnaireResultBloc _questionnaireResultBloc =
      getIt<QuestionnaireResultBloc>();
  final GlobalKey _reportBoundaryKey = GlobalKey();
  int _selectedTab = 0;
  bool _isExportingManagementPdf = false;

  @override
  void initState() {
    super.initState();
    _resultBloc.add(GetResultEvent());
    _managementBloc.add(GetManagementDashboardEvent());
    _resultDetailBloc.add(GetResultDetailEvent());
    _questionnaireResultBloc.add(GetQuestionnaireResultEvent());
  }

  @override
  void dispose() {
    _resultBloc.close();
    _managementBloc.close();
    _resultDetailBloc.close();
    _questionnaireResultBloc.close();
    super.dispose();
  }

  Future<void> _downloadManagementPdf() async {
    if (_isExportingManagementPdf) return;
    setState(() => _isExportingManagementPdf = true);

    try {
      final fileName = await ResultPdfExporter.exportManagementPage(
        _reportBoundaryKey,
      );
      if (!mounted) return;
      if (fileName == null) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text('$fileName saved successfully.')),
        );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text('Could not download PDF: $error')),
        );
    } finally {
      if (mounted) setState(() => _isExportingManagementPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _resultBloc),
        BlocProvider.value(value: _questionnaireResultBloc),
      ],
      child: Scaffold(
        backgroundColor: _pageBackground,
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<ResultBloc, ResultState>(
            builder: (context, aiState) {
              return BlocBuilder<
                QuestionnaireResultBloc,
                QuestionnaireResultState
              >(
                builder: (context, questionnaireState) {
                  final dashboard = _ResultDashboardData.fromStates(
                    aiState: aiState,
                    questionnaireState: questionnaireState,
                  );

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final compact = width < 370;
                      final horizontalPadding = (width * 0.08)
                          .clamp(18.0, 28.0)
                          .toDouble();
                      final maxContentWidth = width > 560 ? 520.0 : width;

                      return Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: maxContentWidth,
                          ),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              compact ? 18 : 26,
                              horizontalPadding,
                              116 + MediaQuery.paddingOf(context).bottom,
                            ),
                            child: RepaintBoundary(
                              key: _reportBoundaryKey,
                              child: ColoredBox(
                                color: _pageBackground,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _Header(compact: compact),
                                    SizedBox(height: compact ? 18 : 22),
                                    _ResultTabs(
                                      selectedIndex: _selectedTab,
                                      compact: compact,
                                      onChanged: (index) {
                                        setState(() => _selectedTab = index);
                                      },
                                    ),
                                    SizedBox(height: compact ? 20 : 22),
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 220,
                                      ),
                                      switchInCurve: Curves.easeOutCubic,
                                      switchOutCurve: Curves.easeInCubic,
                                      child: _selectedTab == 0
                                          ? _AssessmentTabContent(
                                              key: const ValueKey(
                                                'assessment-tab',
                                              ),
                                              dashboard: dashboard,
                                              compact: compact,
                                            )
                                          : _ManagementTabContent(
                                              key: ValueKey('management-tab'),
                                              bloc: _managementBloc,
                                              resultDetailBloc:
                                                  _resultDetailBloc,
                                              isExporting:
                                                  _isExportingManagementPdf,
                                              onDownload:
                                                  _downloadManagementPdf,
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
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

class _Header extends StatelessWidget {
  final bool compact;

  const _Header({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Results',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _type(
                  fontSize: compact ? 24 : 28,
                  fontWeight: FontWeight.w800,
                  color: _ResultScreenState._ink,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Track your assessments and attention\nmanagement journey.',
                style: _type(
                  fontSize: compact ? 14 : 16,
                  fontWeight: FontWeight.w500,
                  color: _ResultScreenState._muted,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: compact ? 10 : 14),
        Padding(
          padding: EdgeInsets.only(top: compact ? 0 : 2),
          child: UserProfileAvatar(
            size: compact ? 44 : 50,
            borderWidth: 0,
            showAccentRing: false,
          ),
        ),
      ],
    );
  }
}

class _ResultTabs extends StatelessWidget {
  final int selectedIndex;
  final bool compact;
  final ValueChanged<int> onChanged;

  const _ResultTabs({
    required this.selectedIndex,
    required this.compact,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFD7DFEA))),
      ),
      child: Row(
        children: [
          _ResultTabButton(
            label: 'Assessment',
            icon: Icons.assignment_outlined,
            selected: selectedIndex == 0,
            compact: compact,
            onTap: () => onChanged(0),
          ),
          _ResultTabButton(
            label: 'Management',
            icon: Icons.bar_chart_rounded,
            selected: selectedIndex == 1,
            compact: compact,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _ResultTabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _ResultTabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? _ResultScreenState._blue
        : _ResultScreenState._muted;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.only(bottom: compact ? 10 : 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected
                      ? _ResultScreenState._blue
                      : Colors.transparent,
                  width: 2.4,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: compact ? 19 : 22),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _type(
                      fontSize: compact ? 14 : 16,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AssessmentTabContent extends StatefulWidget {
  final _ResultDashboardData dashboard;
  final bool compact;

  const _AssessmentTabContent({
    super.key,
    required this.dashboard,
    required this.compact,
  });

  @override
  State<_AssessmentTabContent> createState() => _AssessmentTabContentState();
}

class _AssessmentTabContentState extends State<_AssessmentTabContent> {
  _AssessmentType _selectedType = _AssessmentType.questionnaire;

  @override
  Widget build(BuildContext context) {
    final filteredItems = widget.dashboard.items
        .where((item) => item.type == _selectedType)
        .toList(growable: false);
    final questionnaireCount = widget.dashboard.questionnaireCount;
    final aiBasedCount = widget.dashboard.aiBasedCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryCard(dashboard: widget.dashboard),
        SizedBox(height: widget.compact ? 20 : 24),
        _HistoryHeader(compact: widget.compact),
        const SizedBox(height: 12),
        Text(
          'Choose assessment type',
          style: _type(
            fontSize: widget.compact ? 11 : 12,
            fontWeight: FontWeight.w800,
            color: _ResultScreenState._muted,
            height: 1,
          ),
        ),
        const SizedBox(height: 8),
        _AssessmentTypeSwitch(
          selectedType: _selectedType,
          compact: widget.compact,
          questionnaireCount: questionnaireCount,
          aiBasedCount: aiBasedCount,
          onChanged: (type) => setState(() => _selectedType = type),
        ),
        SizedBox(height: widget.compact ? 14 : 16),
        _FilteredHistoryPanel(
          type: _selectedType,
          items: filteredItems,
          compact: widget.compact,
          isLoading: _selectedType == _AssessmentType.questionnaire
              ? widget.dashboard.isQuestionnaireLoading
              : widget.dashboard.isAiBasedLoading,
        ),
        const SizedBox(height: 18),
        const _TipCard(),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final _ResultDashboardData dashboard;

  const _SummaryCard({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 350;
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 18,
            vertical: compact ? 14 : 18,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .68),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFCFE2FA), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB6C9DF).withValues(alpha: .11),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  flex: 11,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Total Assessments',
                        style: _type(
                          fontSize: compact ? 13 : 15,
                          fontWeight: FontWeight.w600,
                          color: _ResultScreenState._ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dashboard.totalAssessments.toString(),
                        style: _type(
                          fontSize: compact ? 42 : 52,
                          fontWeight: FontWeight.w700,
                          color: _ResultScreenState._ink,
                          height: .95,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Across all types',
                        style: _type(
                          fontSize: compact ? 12 : 14,
                          fontWeight: FontWeight.w500,
                          color: _ResultScreenState._muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const _VerticalDivider(),
                Expanded(
                  flex: 8,
                  child: _SummaryMetric(
                    icon: Icons.assignment_turned_in_outlined,
                    value: dashboard.questionnaireCount,
                    label: 'Questionnaire',
                    color: _ResultScreenState._blue,
                    background: const Color(0xFFE9F4FF),
                    compact: compact,
                  ),
                ),
                const _VerticalDivider(),
                Expanded(
                  flex: 8,
                  child: _SummaryMetric(
                    icon: Icons.extension_outlined,
                    value: dashboard.aiBasedCount,
                    label: 'AI Based',
                    color: _ResultScreenState._purple,
                    background: const Color(0xFFF2E8FF),
                    compact: compact,
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

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      color: _ResultScreenState._line,
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color color;
  final Color background;
  final bool compact;

  const _SummaryMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.background,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: compact ? 42 : 54,
          height: compact ? 42 : 54,
          decoration: BoxDecoration(color: background, shape: BoxShape.circle),
          child: Icon(icon, color: color, size: compact ? 21 : 27),
        ),
        const SizedBox(height: 10),
        Text(
          value.toString(),
          style: _type(
            fontSize: compact ? 18 : 21,
            fontWeight: FontWeight.w800,
            color: _ResultScreenState._ink,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: _type(
              fontSize: compact ? 11 : 13,
              fontWeight: FontWeight.w500,
              color: _ResultScreenState._muted,
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  final bool compact;

  const _HistoryHeader({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assessment History',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _type(
            fontSize: compact ? 16 : 18,
            fontWeight: FontWeight.w800,
            color: _ResultScreenState._ink,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'View your assessment performance over time.',
          style: _type(
            fontSize: compact ? 11 : 12,
            fontWeight: FontWeight.w600,
            color: _ResultScreenState._muted,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _AssessmentTypeSwitch extends StatelessWidget {
  final _AssessmentType selectedType;
  final bool compact;
  final int questionnaireCount;
  final int aiBasedCount;
  final ValueChanged<_AssessmentType> onChanged;

  const _AssessmentTypeSwitch({
    required this.selectedType,
    required this.compact,
    required this.questionnaireCount,
    required this.aiBasedCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 42 : 46,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD8E7FA)),
      ),
      child: Row(
        children: [
          _AssessmentTypeSegment(
            type: _AssessmentType.questionnaire,
            selected: selectedType == _AssessmentType.questionnaire,
            compact: compact,
            count: questionnaireCount,
            onTap: () => onChanged(_AssessmentType.questionnaire),
          ),
          Container(width: 1, color: const Color(0xFFD8E7FA)),
          _AssessmentTypeSegment(
            type: _AssessmentType.aiBased,
            selected: selectedType == _AssessmentType.aiBased,
            compact: compact,
            count: aiBasedCount,
            onTap: () => onChanged(_AssessmentType.aiBased),
          ),
        ],
      ),
    );
  }
}

class _AssessmentTypeSegment extends StatelessWidget {
  final _AssessmentType type;
  final bool selected;
  final bool compact;
  final int count;
  final VoidCallback onTap;

  const _AssessmentTypeSegment({
    required this.type,
    required this.selected,
    required this.compact,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = type == _AssessmentType.questionnaire
        ? _ResultScreenState._blue
        : _ResultScreenState._purple;
    final activeBackground = type == _AssessmentType.questionnaire
        ? const Color(0xFFEAF4FF)
        : const Color(0xFFF2E7FF);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? activeBackground : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  type.icon,
                  color: selected ? color : _ResultScreenState._muted,
                  size: compact ? 15 : 17,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    type.segmentLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _type(
                      fontSize: compact ? 11 : 13,
                      fontWeight: FontWeight.w800,
                      color: selected ? color : _ResultScreenState._muted,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  constraints: BoxConstraints(minWidth: compact ? 20 : 22),
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 6 : 7,
                    vertical: compact ? 2 : 3,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? color.withValues(alpha: .12)
                        : const Color(0xFFEFF4FA),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? color.withValues(alpha: .26)
                          : const Color(0xFFD9E3EF),
                    ),
                  ),
                  child: Text(
                    count.toString(),
                    textAlign: TextAlign.center,
                    style: _type(
                      fontSize: compact ? 10 : 11,
                      fontWeight: FontWeight.w900,
                      color: selected ? color : _ResultScreenState._muted,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilteredHistoryPanel extends StatelessWidget {
  final _AssessmentType type;
  final List<_AssessmentHistoryItem> items;
  final bool compact;
  final bool isLoading;

  const _FilteredHistoryPanel({
    required this.type,
    required this.items,
    required this.compact,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        compact ? 10 : 12,
        compact ? 10 : 12,
        compact ? 10 : 12,
        compact ? 12 : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4ECF6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB6C9DF).withValues(alpha: .12),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLoading)
            _HistoryLoadingMessage(type: type, compact: compact)
          else if (items.isEmpty)
            _EmptyHistoryMessage(type: type, compact: compact)
          else
            for (var index = 0; index < items.length; index++) ...[
              _HistoryCard(item: items[index], compact: compact),
              if (index != items.length - 1)
                Divider(
                  height: compact ? 18 : 20,
                  thickness: 1,
                  color: const Color(0xFFEAF0F8),
                ),
            ],
          if (!isLoading && items.isNotEmpty) ...[
            SizedBox(height: compact ? 10 : 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Showing all ${type.segmentLabel.toLowerCase()} assessments',
                style: _type(
                  fontSize: compact ? 10 : 11,
                  fontWeight: FontWeight.w600,
                  color: _ResultScreenState._muted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HistoryLoadingMessage extends StatelessWidget {
  final _AssessmentType type;
  final bool compact;

  const _HistoryLoadingMessage({required this.type, required this.compact});

  @override
  Widget build(BuildContext context) {
    final color = type == _AssessmentType.questionnaire
        ? _ResultScreenState._blue
        : _ResultScreenState._purple;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 18 : 22,
      ),
      child: Row(
        children: [
          SizedBox(
            width: compact ? 24 : 28,
            height: compact ? 24 : 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: color,
              backgroundColor: color.withValues(alpha: .12),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Loading ${type.segmentLabel.toLowerCase()} assessments...',
              style: _type(
                fontSize: compact ? 12 : 13,
                fontWeight: FontWeight.w700,
                color: _ResultScreenState._muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistoryMessage extends StatelessWidget {
  final _AssessmentType type;
  final bool compact;

  const _EmptyHistoryMessage({required this.type, required this.compact});

  @override
  Widget build(BuildContext context) {
    final color = type == _AssessmentType.questionnaire
        ? _ResultScreenState._blue
        : _ResultScreenState._purple;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 18 : 22,
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 38 : 42,
            height: compact ? 38 : 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(type.icon, color: color, size: compact ? 19 : 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No ${type.segmentLabel.toLowerCase()} assessments yet.',
              style: _type(
                fontSize: compact ? 12 : 13,
                fontWeight: FontWeight.w700,
                color: _ResultScreenState._muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final _AssessmentHistoryItem item;
  final bool compact;

  const _HistoryCard({required this.item, required this.compact});

  @override
  Widget build(BuildContext context) {
    final scoreColors = _ScoreColors.forScore(item.score);
    final typeColor = item.type == _AssessmentType.questionnaire
        ? _ResultScreenState._blue
        : _ResultScreenState._purple;
    final iconBackground = item.type == _AssessmentType.questionnaire
        ? const Color(0xFFE9F4FF)
        : const Color(0xFFF2E8FF);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: EdgeInsets.fromLTRB(
            compact ? 0 : 2,
            compact ? 3 : 4,
            0,
            compact ? 3 : 4,
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 38 : 42,
                height: compact ? 38 : 42,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item.type.icon,
                  color: typeColor,
                  size: compact ? 19 : 21,
                ),
              ),
              SizedBox(width: compact ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _type(
                        fontSize: compact ? 13 : 14,
                        fontWeight: FontWeight.w800,
                        color: _ResultScreenState._ink,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _DateTimeMeta(
                      date: item.date,
                      time: item.time,
                      compact: compact,
                    ),
                  ],
                ),
              ),
              SizedBox(width: compact ? 7 : 10),
              _ScoreBadge(
                score: item.score,
                label: item.scoreLabel,
                colors: scoreColors,
                compact: compact,
              ),
              SizedBox(width: compact ? 4 : 8),
              Icon(
                Icons.chevron_right_rounded,
                size: compact ? 22 : 24,
                color: _ResultScreenState._muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateTimeMeta extends StatelessWidget {
  final String date;
  final String time;
  final bool compact;

  const _DateTimeMeta({
    required this.date,
    required this.time,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          date,
          style: _type(
            fontSize: compact ? 11 : 13,
            fontWeight: FontWeight.w500,
            color: _ResultScreenState._muted,
            height: 1,
          ),
        ),
        Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            color: _ResultScreenState._muted,
            shape: BoxShape.circle,
          ),
        ),
        Text(
          time,
          style: _type(
            fontSize: compact ? 11 : 13,
            fontWeight: FontWeight.w500,
            color: _ResultScreenState._muted,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final int score;
  final String label;
  final _ScoreColors colors;
  final bool compact;

  const _ScoreBadge({
    required this.score,
    required this.label,
    required this.colors,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 58 : 66,
      height: compact ? 58 : 66,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$score/10',
            style: _type(
              fontSize: compact ? 16 : 20,
              fontWeight: FontWeight.w800,
              color: colors.foreground,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: _type(
                fontSize: compact ? 10 : 12,
                fontWeight: FontWeight.w800,
                color: colors.foreground,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: _ResultScreenState._blue,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Tip: Regular assessments help you understand your\nattention patterns better.',
              style: _type(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _ResultScreenState._muted,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManagementTabContent extends StatelessWidget {
  final ResultBloc bloc;
  final ResultDetailBloc resultDetailBloc;
  final bool isExporting;
  final VoidCallback onDownload;

  const _ManagementTabContent({
    super.key,
    required this.bloc,
    required this.resultDetailBloc,
    required this.isExporting,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ResultBloc, ResultState>(
      bloc: bloc,
      builder: (context, state) {
        if (state is GetManagementDashboardLoading || state is ResultInitial) {
          return const _ManagementStatusCard.loading();
        }
        if (state is GetManagementDashboardFailed) {
          return _ManagementStatusCard.error(
            message: state.error,
            onRetry: () => bloc.add(GetManagementDashboardEvent()),
          );
        }
        if (state is! GetManagementDashboardSuccess) {
          return const SizedBox.shrink();
        }

        final dashboard = state.data;
        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 360;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ManagementSectionHeader(
                  compact: compact,
                  isExporting: isExporting,
                  onDownload: onDownload,
                ),
                SizedBox(height: compact ? 12 : 14),
                _ManagementOverviewCard(data: dashboard),
                SizedBox(height: compact ? 22 : 26),
                Text(
                  'Weekly Progress',
                  style: _type(
                    fontSize: compact ? 16 : 18,
                    fontWeight: FontWeight.w800,
                    color: _ResultScreenState._ink,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: compact ? 12 : 14),
                _WeeklyProgressCard(
                  data: dashboard,
                  resultDetailBloc: resultDetailBloc,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ManagementSectionHeader extends StatelessWidget {
  final bool compact;
  final bool isExporting;
  final VoidCallback onDownload;

  const _ManagementSectionHeader({
    required this.compact,
    required this.isExporting,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Management Overview',
            style: _type(
              fontSize: compact ? 16 : 18,
              fontWeight: FontWeight.w800,
              color: _ResultScreenState._ink,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: isExporting ? null : onDownload,
          style: OutlinedButton.styleFrom(
            foregroundColor: _ResultScreenState._blue,
            side: const BorderSide(color: Color(0xFF77B9F8), width: 1.4),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 14,
              vertical: compact ? 9 : 11,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isExporting)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(Icons.download_rounded, size: 21),
              SizedBox(width: compact ? 6 : 8),
              Text(
                isExporting ? 'Saving...' : 'Download PDF',
                style: _type(
                  fontSize: compact ? 11 : 13,
                  fontWeight: FontWeight.w800,
                  color: isExporting
                      ? _ResultScreenState._muted
                      : _ResultScreenState._blue,
                ),
              ),
              if (!compact && !isExporting) ...[
                const SizedBox(width: 8),
                const Icon(Icons.picture_as_pdf_outlined, size: 22),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ManagementStatusCard extends StatelessWidget {
  final bool isLoading;
  final String? message;
  final VoidCallback? onRetry;

  const _ManagementStatusCard.loading()
    : isLoading = true,
      message = null,
      onRetry = null;

  const _ManagementStatusCard.error({
    required this.message,
    required this.onRetry,
  }) : isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: _softCardDecoration(radius: 14),
      child: Column(
        children: [
          if (isLoading) ...[
            const CircularProgressIndicator(strokeWidth: 2.5),
            const SizedBox(height: 14),
            Text(
              'Loading management progress...',
              style: _type(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _ResultScreenState._muted,
              ),
            ),
          ] else ...[
            const Icon(
              Icons.error_outline_rounded,
              color: _ResultScreenState._orange,
              size: 34,
            ),
            const SizedBox(height: 10),
            Text(
              message ?? 'Unable to load management progress.',
              textAlign: TextAlign.center,
              style: _type(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _ResultScreenState._muted,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ManagementOverviewCard extends StatelessWidget {
  final WeeklyProgressResponse data;

  const _ManagementOverviewCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final dashboard = data.data;
        final metrics = [
          _OverviewMetricData(
            icon: Icons.bar_chart_rounded,
            label: 'Weeks Tracked',
            value: (dashboard?.weeksTracked ?? 0).toString(),
            color: _ResultScreenState._blue,
            background: Color(0xFFDCEEFF),
          ),
          _OverviewMetricData(
            icon: Icons.trending_up_rounded,
            label: 'Avg. Total Score',
            value: '${_formatScore(dashboard?.averageTotalScore ?? 0)}/100',
            color: _ResultScreenState._green,
            background: Color(0xFFE5F4E9),
          ),
          _OverviewMetricData(
            icon: Icons.track_changes_rounded,
            label: 'Best Week',
            value: '${_formatScore(dashboard?.bestWeekScore ?? 0)}/100',
            color: _ResultScreenState._purple,
            background: Color(0xFFF0E4FF),
          ),
          _OverviewMetricData(
            icon: Icons.local_fire_department_outlined,
            label: 'Consistency',
            value: '${_formatScore(dashboard?.consistency ?? 0)}%',
            color: _ResultScreenState._orange,
            background: Color(0xFFFFEBDD),
          ),
        ];

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 12,
            vertical: compact ? 14 : 16,
          ),
          decoration: _softCardDecoration(radius: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (var index = 0; index < metrics.length; index++) ...[
                Expanded(
                  child: _OverviewMetric(
                    data: metrics[index],
                    compact: compact,
                  ),
                ),
                if (index != metrics.length - 1)
                  Container(
                    width: 1,
                    margin: EdgeInsets.symmetric(
                      horizontal: compact ? 5 : 9,
                      vertical: 2,
                    ),
                    color: _ResultScreenState._line,
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  final _OverviewMetricData data;
  final bool compact;

  const _OverviewMetric({required this.data, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: compact ? 40 : 46,
          height: compact ? 40 : 46,
          decoration: BoxDecoration(
            color: data.background,
            shape: BoxShape.circle,
          ),
          child: Icon(data.icon, color: data.color, size: compact ? 20 : 23),
        ),
        SizedBox(height: compact ? 9 : 10),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            data.label,
            maxLines: 1,
            style: _type(
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w700,
              color: _ResultScreenState._muted,
            ),
          ),
        ),
        SizedBox(height: compact ? 6 : 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            data.value,
            maxLines: 1,
            style: _type(
              fontSize: compact ? 16 : 18,
              fontWeight: FontWeight.w800,
              color: data.color,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _OverviewMetricData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color background;

  const _OverviewMetricData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.background,
  });
}

class _WeeklyProgressCard extends StatelessWidget {
  final WeeklyProgressResponse data;
  final ResultDetailBloc resultDetailBloc;

  const _WeeklyProgressCard({
    required this.data,
    required this.resultDetailBloc,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final dashboard = data.data;
        final weeklyProgress =
            dashboard?.weeklyProgress ?? const <WeeklyProgressPoint>[];

        return Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            compact ? 12 : 16,
            compact ? 14 : 16,
            compact ? 12 : 16,
            compact ? 14 : 16,
          ),
          decoration: _softCardDecoration(radius: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ChartHeader(compact: compact),
              SizedBox(height: compact ? 14 : 16),
              SizedBox(
                height: compact ? 170 : 190,
                child: weeklyProgress.isEmpty
                    ? const _EmptyWeeklyProgress()
                    : _WeeklyLineChart(points: weeklyProgress),
              ),
              SizedBox(height: compact ? 14 : 16),
              _ImprovementBanner(
                improvement: dashboard?.improvement ?? 0,
                weeksTracked: dashboard?.weeksTracked ?? 0,
              ),
              SizedBox(height: compact ? 20 : 22),
              BlocBuilder<ResultDetailBloc, ResultDetailState>(
                bloc: resultDetailBloc,
                builder: (context, state) {
                  if (state is GetResultDetailLoading ||
                      state is ResultDetailInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is GetResultDetailFailed) {
                    return _WeekDetailsError(
                      message: state.error,
                      onRetry: () =>
                          resultDetailBloc.add(GetResultDetailEvent()),
                    );
                  }
                  if (state is GetResultDetailSuccess) {
                    return _WeekDetailsList(
                      weeks: state.data.data?.results ?? const <WeeklyResult>[],
                      compact: compact,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChartHeader extends StatelessWidget {
  final bool compact;

  const _ChartHeader({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Total Score',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: _type(
        fontSize: compact ? 16 : 18,
        fontWeight: FontWeight.w800,
        color: _ResultScreenState._ink,
      ),
    );
  }
}

class _WeeklyLineChart extends StatelessWidget {
  final List<WeeklyProgressPoint> points;

  const _WeeklyLineChart({required this.points});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WeeklyLineChartPainter(points),
      child: const SizedBox.expand(),
    );
  }
}

class _EmptyWeeklyProgress extends StatelessWidget {
  const _EmptyWeeklyProgress();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No weekly progress is available yet.',
        textAlign: TextAlign.center,
        style: _type(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: _ResultScreenState._muted,
        ),
      ),
    );
  }
}

class _WeeklyLineChartPainter extends CustomPainter {
  final List<WeeklyProgressPoint> points;

  const _WeeklyLineChartPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final labelStyle = _type(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: _ResultScreenState._muted,
    );
    final axisPaint = Paint()
      ..color = const Color(0xFFD8E1EE)
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..color = _ResultScreenState._blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final dotPaint = Paint()..color = _ResultScreenState._blue;
    final glowPaint = Paint()
      ..color = _ResultScreenState._blue.withValues(alpha: .18)
      ..style = PaintingStyle.fill;

    const left = 32.0;
    const right = 10.0;
    const top = 16.0;
    const bottom = 28.0;
    final chartWidth = size.width - left - right;
    final chartHeight = size.height - top - bottom;
    final origin = Offset(left, top + chartHeight);

    canvas.drawLine(origin, Offset(size.width - right, origin.dy), axisPaint);
    canvas.drawLine(Offset(left, top), origin, axisPaint);

    for (final tick in [0, 25, 50, 75, 100]) {
      final y = top + chartHeight - (tick / 100) * chartHeight;
      _paintText(
        canvas,
        tick.toString(),
        Offset(0, y - 9),
        labelStyle,
        maxWidth: 30,
      );
    }

    final chartPoints = <Offset>[
      for (var index = 0; index < points.length; index++)
        Offset(
          points.length == 1
              ? left + chartWidth / 2
              : left + (chartWidth / (points.length - 1)) * index,
          top +
              chartHeight -
              (points[index].score.clamp(0, 100) / 100) * chartHeight,
        ),
    ];

    final path = Path()..moveTo(chartPoints.first.dx, chartPoints.first.dy);
    for (var index = 1; index < chartPoints.length; index++) {
      path.lineTo(chartPoints[index].dx, chartPoints[index].dy);
    }
    canvas.drawPath(path, linePaint);

    for (var index = 0; index < chartPoints.length; index++) {
      final point = chartPoints[index];
      canvas.drawCircle(point, 6.5, glowPaint);
      canvas.drawCircle(point, 4.2, dotPaint);
      _paintText(
        canvas,
        _formatScore(points[index].score),
        Offset(point.dx - 11, point.dy - 24),
        _type(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: _ResultScreenState._ink,
        ),
        maxWidth: 28,
        align: TextAlign.center,
      );
      _paintText(
        canvas,
        points[index].label.isEmpty ? 'Wk ${index + 1}' : points[index].label,
        Offset(point.dx - 20, origin.dy + 12),
        labelStyle,
        maxWidth: 40,
        align: TextAlign.center,
      );
    }

    final last = chartPoints.last;
    final bubble = RRect.fromRectAndRadius(
      Rect.fromLTWH(last.dx - 19, last.dy - 44, 38, 30),
      const Radius.circular(7),
    );
    canvas.drawRRect(bubble, Paint()..color = _ResultScreenState._blue);
    _paintText(
      canvas,
      _formatScore(points.last.score),
      Offset(last.dx - 12, last.dy - 38),
      _type(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
      maxWidth: 24,
      align: TextAlign.center,
    );
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style, {
    required double maxWidth,
    TextAlign align = TextAlign.left,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _WeeklyLineChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

class _ImprovementBanner extends StatelessWidget {
  final double improvement;
  final int weeksTracked;

  const _ImprovementBanner({
    required this.improvement,
    required this.weeksTracked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE1E7F0)),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          Icon(
            improvement >= 0
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            color: improvement >= 0
                ? _ResultScreenState._green
                : _ResultScreenState._orange,
            size: 20,
          ),
          Text(
            '${improvement >= 0 ? '+' : ''}${_formatScore(improvement)} pts',
            style: _type(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: improvement >= 0
                  ? _ResultScreenState._green
                  : _ResultScreenState._orange,
            ),
          ),
          Text(
            weeksTracked > 1
                ? 'improvement from Week 1 to Week $weeksTracked'
                : 'change from your first tracked week',
            style: _type(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _ResultScreenState._muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekDetailsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _WeekDetailsError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: _type(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _ResultScreenState._muted,
            ),
          ),
          const SizedBox(height: 10),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

class _WeekDetailsList extends StatelessWidget {
  final List<WeeklyResult> weeks;
  final bool compact;

  const _WeekDetailsList({required this.weeks, required this.compact});

  @override
  Widget build(BuildContext context) {
    if (weeks.isEmpty) return const _EmptyWeeklyProgress();

    return Column(
      children: [
        for (var index = 0; index < weeks.length; index++) ...[
          _WeekDetailsSection(week: weeks[index], compact: compact),
          if (index != weeks.length - 1)
            Padding(
              padding: EdgeInsets.symmetric(vertical: compact ? 22 : 26),
              child: const Divider(height: 1, color: Color(0xFFDDE5EF)),
            ),
        ],
      ],
    );
  }
}

const _weekdayLabels = <String>[
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

const _monthLabels = <String>[
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

String _weekTitle(WeeklyResult week) =>
    week.weekNumber == null ? 'Week' : 'Week ${week.weekNumber}';

String _weekDateRange(WeeklyResult week) {
  final start = week.parsedStartDate;
  final end = week.parsedEndDate;
  if (start == null && end == null) return 'Date range unavailable';
  if (start == null) return _shortDate(end!);
  if (end == null) return _shortDate(start);

  if (start.year == end.year && start.month == end.month) {
    return '${start.day} - ${end.day} ${_monthLabels[end.month - 1]} ${end.year}';
  }
  if (start.year == end.year) {
    return '${start.day} ${_monthLabels[start.month - 1]} - '
        '${end.day} ${_monthLabels[end.month - 1]} ${end.year}';
  }
  return '${_shortDate(start)} - ${_shortDate(end)}';
}

String _shortDate(DateTime date) =>
    '${date.day} ${_monthLabels[date.month - 1]} ${date.year}';

String _weekdayLabel(DateTime date) => _weekdayLabels[date.weekday - 1];

String _fullWeekdayLabel(DateTime date) => const <String>[
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
][date.weekday - 1];

class _WeekDetailsSection extends StatefulWidget {
  final WeeklyResult week;
  final bool compact;

  const _WeekDetailsSection({required this.week, required this.compact});

  @override
  State<_WeekDetailsSection> createState() => _WeekDetailsSectionState();
}

class _WeekDetailsSectionState extends State<_WeekDetailsSection> {
  late ManagementDay? _selectedDay = _initialDay(widget.week);

  static ManagementDay? _initialDay(WeeklyResult week) {
    final days = week.days ?? const <ManagementDay>[];
    return days.isEmpty ? null : days.first;
  }

  @override
  void didUpdateWidget(covariant _WeekDetailsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.week != widget.week) {
      _selectedDay = _initialDay(widget.week);
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = widget.week.days ?? const <ManagementDay>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WeekDetailsHeader(week: widget.week, compact: widget.compact),
        SizedBox(height: widget.compact ? 12 : 14),
        if (days.isEmpty)
          const _NoDayData()
        else ...[
          _DaySelector(
            days: days,
            selectedDay: _selectedDay,
            onSelected: (day) => setState(() => _selectedDay = day),
          ),
          SizedBox(height: widget.compact ? 14 : 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _selectedDay == null || !_selectedDay!.containsData
                ? _NoDayData(key: ValueKey(_selectedDay?.date))
                : _DailyScoreCard(
                    key: ValueKey(_selectedDay!.date),
                    day: _selectedDay!,
                  ),
          ),
        ],
      ],
    );
  }
}

class _NoDayData extends StatelessWidget {
  const _NoDayData({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE5EF)),
      ),
      child: Text(
        'No management session was recorded for this day.',
        textAlign: TextAlign.center,
        style: _type(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _ResultScreenState._muted,
        ),
      ),
    );
  }
}

class _WeekDetailsHeader extends StatelessWidget {
  final WeeklyResult week;
  final bool compact;

  const _WeekDetailsHeader({required this.week, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_weekTitle(week)} Details',
                style: _type(
                  fontSize: compact ? 16 : 18,
                  fontWeight: FontWeight.w800,
                  color: _ResultScreenState._ink,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _weekDateRange(week),
                style: _type(
                  fontSize: compact ? 12 : 13,
                  fontWeight: FontWeight.w600,
                  color: _ResultScreenState._muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DaySelector extends StatelessWidget {
  final List<ManagementDay> days;
  final ManagementDay? selectedDay;
  final ValueChanged<ManagementDay> onSelected;

  const _DaySelector({
    required this.days,
    required this.selectedDay,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final visibleCount = days.length.clamp(1, 7);
        final gap = constraints.maxWidth < 360 ? 7.0 : 10.0;
        final itemWidth =
            (constraints.maxWidth - (gap * (visibleCount - 1))) / visibleCount;
        final compact = itemWidth < 44;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (var index = 0; index < days.length; index++) ...[
                SizedBox(
                  width: itemWidth.clamp(38.0, 56.0),
                  child: _DayChip(
                    dayData: days[index],
                    selected:
                        identical(days[index], selectedDay) ||
                        days[index].date == selectedDay?.date,
                    compact: compact,
                    onTap: () => onSelected(days[index]),
                  ),
                ),
                if (index != days.length - 1) SizedBox(width: gap),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DayChip extends StatelessWidget {
  final ManagementDay dayData;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _DayChip({
    required this.dayData,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final date = dayData.parsedDate;
    final weekday = dayData.dayLabel?.trim().isNotEmpty == true
        ? dayData.dayLabel!
        : date == null
        ? 'Day'
        : _weekdayLabel(date);
    // `day_number` can be the ordinal day within the returned week. The chip
    // is a calendar control, so its visible number must come from `date`.
    final dayNumber =
        date?.day.toString() ?? dayData.dayNumber?.toString() ?? '–';
    return Semantics(
      button: true,
      selected: selected,
      label: '$weekday $dayNumber',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: compact ? 44 : 52,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEAF3FF) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? _ResultScreenState._blue
                  : const Color(0xFFDDE5EF),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FittedBox(
                child: Text(
                  weekday,
                  style: _type(
                    fontSize: compact ? 9 : 11,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? _ResultScreenState._blue
                        : _ResultScreenState._muted,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dayNumber,
                style: _type(
                  fontSize: compact ? 13 : 15,
                  fontWeight: FontWeight.w800,
                  color: _ResultScreenState._ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyScoreCard extends StatelessWidget {
  final ManagementDay day;

  const _DailyScoreCard({super.key, required this.day});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;

        final band = _ScoreBand.fromScore(day.safeTotalScore);
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDDE5EF)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 12 : 14,
                  compact ? 14 : 16,
                  compact ? 12 : 14,
                  compact ? 12 : 14,
                ),
                child: constraints.maxWidth < 470
                    ? _CompactDailyScoreContent(day: day, band: band)
                    : _WideDailyScoreContent(day: day, band: band),
              ),
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  compact ? 14 : 16,
                  compact ? 14 : 16,
                  compact ? 14 : 16,
                  compact ? 14 : 16,
                ),
                color: const Color(0xFFF7F9FC),
                child: Row(
                  children: [
                    Icon(band.icon, color: band.color, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Progress Summary',
                            style: _type(
                              fontSize: compact ? 15 : 16,
                              fontWeight: FontWeight.w800,
                              color: _ResultScreenState._ink,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            band.summary,
                            style: _type(
                              fontSize: compact ? 12 : 13,
                              fontWeight: FontWeight.w600,
                              color: _ResultScreenState._muted,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WideDailyScoreContent extends StatelessWidget {
  final ManagementDay day;
  final _ScoreBand band;

  const _WideDailyScoreContent({required this.day, required this.band});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircularScore(score: day.safeTotalScore, color: band.color),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DailyTitleRow(day: day, band: band),
              const SizedBox(height: 16),
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: _DailyMetric(
                        label: 'Concentration',
                        value: _formatScore(day.safeConcentrationScore),
                        suffix: '/100',
                        valueColor: _ResultScreenState._blue,
                      ),
                    ),
                    const _MetricDivider(),
                    Expanded(
                      child: _DailyMetric(
                        label: 'Attention Score',
                        value: _formatScore(day.safeAttentionScore),
                        suffix: '/100',
                        valueColor: _ResultScreenState._green,
                      ),
                    ),
                    const _MetricDivider(),
                    Expanded(
                      child: _DailyMetric(
                        label: 'Total Score',
                        value: _formatScore(day.safeTotalScore),
                        suffix: '/100',
                        valueColor: _ResultScreenState._purple,
                      ),
                    ),
                    const _MetricDivider(),
                    Expanded(
                      child: _DailyMetric(
                        label: 'Duration',
                        value: day.durationLabel ?? '—',
                        suffix: '',
                        valueColor: _ResultScreenState._ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompactDailyScoreContent extends StatelessWidget {
  final ManagementDay day;
  final _ScoreBand band;

  const _CompactDailyScoreContent({required this.day, required this.band});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CircularScore(score: day.safeTotalScore, color: band.color),
            const SizedBox(width: 12),
            Expanded(
              child: _DailyTitleRow(day: day, band: band),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 2.9,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          children: [
            _DailyMetric(
              label: 'Concentration',
              value: _formatScore(day.safeConcentrationScore),
              suffix: '/100',
              valueColor: _ResultScreenState._blue,
            ),
            _DailyMetric(
              label: 'Attention Score',
              value: _formatScore(day.safeAttentionScore),
              suffix: '/100',
              valueColor: _ResultScreenState._green,
            ),
            _DailyMetric(
              label: 'Total Score',
              value: _formatScore(day.safeTotalScore),
              suffix: '/100',
              valueColor: _ResultScreenState._purple,
            ),
            _DailyMetric(
              label: 'Duration',
              value: day.durationLabel ?? '—',
              suffix: '',
              valueColor: _ResultScreenState._ink,
            ),
          ],
        ),
      ],
    );
  }
}

class _DailyTitleRow extends StatelessWidget {
  final ManagementDay day;
  final _ScoreBand band;

  const _DailyTitleRow({required this.day, required this.band});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Text(
          day.parsedDate == null
              ? 'First recorded day'
              : '${_fullWeekdayLabel(day.parsedDate!)}, '
                    '${_shortDate(day.parsedDate!)}',
          style: _type(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: _ResultScreenState._ink,
            height: 1.1,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: band.background,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            band.label,
            style: _type(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: band.color,
            ),
          ),
        ),
      ],
    );
  }
}

class _ScoreBand {
  final String label;
  final String summary;
  final Color color;
  final Color background;
  final IconData icon;

  const _ScoreBand({
    required this.label,
    required this.summary,
    required this.color,
    required this.background,
    required this.icon,
  });

  factory _ScoreBand.fromScore(double score) {
    if (score >= 85) {
      return const _ScoreBand(
        label: 'Excellent Focus',
        summary: 'Excellent focus and attention throughout this day.',
        color: Color(0xFF15803D),
        background: Color(0xFFDCFCE7),
        icon: Icons.trending_up_rounded,
      );
    }
    if (score >= 70) {
      return const _ScoreBand(
        label: 'Strong Focus',
        summary: 'Strong attention with only minor opportunities to improve.',
        color: Color(0xFF1677C8),
        background: Color(0xFFE0F2FE),
        icon: Icons.insights_rounded,
      );
    }
    if (score >= 50) {
      return const _ScoreBand(
        label: 'Building Focus',
        summary: 'Focus is developing; consistent practice will help.',
        color: Color(0xFFB45309),
        background: Color(0xFFFEF3C7),
        icon: Icons.trending_flat_rounded,
      );
    }
    return const _ScoreBand(
      label: 'Focus Needs Support',
      summary: 'This day shows an opportunity to strengthen sustained focus.',
      color: Color(0xFFB42318),
      background: Color(0xFFFEE4E2),
      icon: Icons.trending_down_rounded,
    );
  }
}

class _CircularScore extends StatelessWidget {
  final double score;
  final Color color;

  const _CircularScore({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 76,
            height: 76,
            child: CircularProgressIndicator(
              value: score.clamp(0, 100) / 100,
              strokeWidth: 7,
              strokeCap: StrokeCap.round,
              color: color,
              backgroundColor: const Color(0xFFE8EEF5),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatScore(score),
                style: _type(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: _ResultScreenState._ink,
                  height: 1,
                ),
              ),
              Text(
                '/100',
                style: _type(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _ResultScreenState._muted,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DailyMetric extends StatelessWidget {
  final String label;
  final String value;
  final String suffix;
  final Color valueColor;

  const _DailyMetric({
    required this.label,
    required this.value,
    required this.suffix,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: _type(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _ResultScreenState._muted,
            ),
          ),
        ),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: RichText(
            maxLines: 1,
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: _type(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: valueColor,
                    height: 1,
                  ),
                ),
                TextSpan(
                  text: suffix,
                  style: _type(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _ResultScreenState._muted,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 7),
      color: _ResultScreenState._line,
    );
  }
}

BoxDecoration _softCardDecoration({required double radius}) {
  return BoxDecoration(
    color: Colors.white.withValues(alpha: .82),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: const Color(0xFFDDE5EF)),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFFB6C9DF).withValues(alpha: .13),
        blurRadius: 18,
        offset: const Offset(0, 9),
      ),
    ],
  );
}

String _formatScore(num value) {
  final rounded = value.round();
  return value == rounded ? rounded.toString() : value.toStringAsFixed(1);
}

enum _AssessmentType { questionnaire, aiBased }

extension _AssessmentTypeMeta on _AssessmentType {
  String get segmentLabel =>
      this == _AssessmentType.questionnaire ? 'Questionnaire' : 'AI Based';

  IconData get icon => this == _AssessmentType.questionnaire
      ? Icons.assignment_turned_in_outlined
      : Icons.extension_outlined;
}

class _AssessmentHistoryItem {
  final _AssessmentType type;
  final String title;
  final String date;
  final String time;
  final int score;
  final String scoreLabel;

  const _AssessmentHistoryItem({
    required this.type,
    required this.title,
    required this.date,
    required this.time,
    required this.score,
    required this.scoreLabel,
  });

  String get typeLabel => type.segmentLabel;
}

class _ResultDashboardData {
  final int totalAssessments;
  final int questionnaireCount;
  final int aiBasedCount;
  final List<_AssessmentHistoryItem> items;
  final bool isQuestionnaireLoading;
  final bool isAiBasedLoading;

  const _ResultDashboardData({
    required this.totalAssessments,
    required this.questionnaireCount,
    required this.aiBasedCount,
    required this.items,
    this.isQuestionnaireLoading = false,
    this.isAiBasedLoading = false,
  });

  factory _ResultDashboardData.fromStates({
    required ResultState aiState,
    required QuestionnaireResultState questionnaireState,
  }) {
    final hasQuestionnaireApi =
        questionnaireState is QuestionnaireResultSuccess;
    final hasAiApi = aiState is GetResultSuccess;
    final isQuestionnaireLoading =
        questionnaireState is QuestionnaireResultInitial ||
        questionnaireState is QuestionnaireResultLoading;
    final isAiBasedLoading =
        aiState is ResultInitial || aiState is GetResultLoading;

    final questionnaireItems = hasQuestionnaireApi
        ? _itemsFromQuestionnaireApi(
            questionnaireState.data.data?.results ?? const <ManagementResult>[],
          )
        : const <_AssessmentHistoryItem>[];
    final aiItems = hasAiApi
        ? _itemsFromAiAssessmentApi(aiState.data.results)
        : const <_AssessmentHistoryItem>[];

    final questionnaireCount = hasQuestionnaireApi
        ? questionnaireState.data.data?.count ?? questionnaireItems.length
        : 0;
    final aiBasedCount = hasAiApi ? aiState.data.count : 0;

    return _ResultDashboardData(
      totalAssessments: questionnaireCount + aiBasedCount,
      questionnaireCount: questionnaireCount,
      aiBasedCount: aiBasedCount,
      items: [...questionnaireItems, ...aiItems],
      isQuestionnaireLoading: isQuestionnaireLoading,
      isAiBasedLoading: isAiBasedLoading,
    );
  }

  static List<_AssessmentHistoryItem> _itemsFromQuestionnaireApi(
    List<ManagementResult> items,
  ) {
    return items.map(_itemFromQuestionnaireResult).toList(growable: false);
  }

  static _AssessmentHistoryItem _itemFromQuestionnaireResult(
    ManagementResult item,
  ) {
    final score = _scoreOutOfTen(item.tenScore ?? 0);
    final created = item.createdAt?.toLocal();

    return _AssessmentHistoryItem(
      type: _AssessmentType.questionnaire,
      title: 'Self Assessment',
      date: created == null ? 'Assessment date' : _formatDate(created),
      time: created == null ? '--:--' : _formatTime(created),
      score: score,
      scoreLabel: item.result?.trim().isNotEmpty == true
          ? item.result!.trim()
          : _labelForScore(score),
    );
  }

  static List<_AssessmentHistoryItem> _itemsFromAiAssessmentApi(
    List<AssessmentHistoryItem> items,
  ) {
    return items.map(_itemFromAiAssessmentResult).toList(growable: false);
  }

  static _AssessmentHistoryItem _itemFromAiAssessmentResult(
    AssessmentHistoryItem item,
  ) {
    final score = _scoreOutOfTen(item.score);
    final created = item.createdAt?.toLocal();

    return _AssessmentHistoryItem(
      type: _AssessmentType.aiBased,
      title: item.title ?? 'Attention Assessment',
      date: created == null ? 'Assessment date' : _formatDate(created),
      time: created == null ? '--:--' : _formatTime(created),
      score: score,
      scoreLabel: _labelForScore(score),
    );
  }

  static int _scoreOutOfTen(num rawScore) {
    final normalizedScore = rawScore > 10 ? rawScore / 10 : rawScore;
    return normalizedScore.round().clamp(0, 10);
  }

  static String _formatDate(DateTime date) {
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

  static String _formatTime(DateTime date) {
    final hour = date.hour == 0
        ? 12
        : date.hour > 12
        ? date.hour - 12
        : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final suffix = date.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:$minute $suffix';
  }

  static String _labelForScore(int score) {
    if (score >= 9) return 'Excellent';
    if (score >= 7) return 'Good';
    return 'Average';
  }
}

class _ScoreColors {
  final Color foreground;
  final Color background;

  const _ScoreColors({required this.foreground, required this.background});

  static _ScoreColors forScore(int score) {
    if (score >= 7) {
      return const _ScoreColors(
        foreground: Color(0xFF087A43),
        background: Color(0xFFE8F7EC),
      );
    }

    if (score <= 5) {
      return const _ScoreColors(
        foreground: Color(0xFFD72F2F),
        background: Color(0xFFFFE8E8),
      );
    }

    return const _ScoreColors(
      foreground: Color(0xFF9A6400),
      background: Color(0xFFFFF3D9),
    );
  }
}

TextStyle _type({
  required double fontSize,
  FontWeight fontWeight = FontWeight.w400,
  Color color = _ResultScreenState._ink,
  double? height,
}) {
  return GoogleFonts.nunitoSans(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
  );
}
