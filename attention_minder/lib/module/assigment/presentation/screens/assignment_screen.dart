import 'dart:ui';

import 'package:attention_minder/constant/asset_path.dart';
import 'package:attention_minder/module/assigment/presentation/screens/ai_assessment_list_screen.dart';
import 'package:attention_minder/module/assigment/presentation/screens/questionnaire_screen.dart';
import 'package:attention_minder/module/home/presentation/widgets/featured_articles_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AssignmentScreen extends StatelessWidget {
  final bool showBackButton;

  const AssignmentScreen({super.key, this.showBackButton = true});

  static const _navy = Color(0xFF071443);
  static const _body = Color(0xFF48577C);
  static const _blue = Color(0xFF157CF3);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 430).clamp(.82, 1.0).toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFFFBFCFF),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
            bottom: 96 * scale + MediaQuery.paddingOf(context).bottom,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 22 * scale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 34 * scale),
                    _PageHeader(scale: scale, showBackButton: showBackButton),
                    SizedBox(height: 24 * scale),
                    _CuratorCard(scale: scale),
                    SizedBox(height: 24 * scale),
                    _SectionTitle(scale: scale),
                    SizedBox(height: 14 * scale),
                    _AssessmentCard(
                      scale: scale,
                      accent: const Color(0xFF6DA1FF),
                      iconColors: const [Color(0xFF76ABFF), Color(0xFF668BEF)],
                      icon: const Icon(
                        Icons.format_list_bulleted_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                      title: 'Self assessment',
                      description:
                          'This science-backed self-report questionnaire helps you evaluate your symptoms, understand patterns, and gain insights into your attention and behavioral traits.',
                      duration: '15–20 min',
                      onTap: () => _showSelfAssessment(context),
                    ),
                    SizedBox(height: 12 * scale),
                    _AssessmentCard(
                      scale: scale,
                      accent: const Color(0xFFA97CFF),
                      iconColors: const [Color(0xFFB993FF), Color(0xFF9067ED)],
                      icon: const Icon(
                        Icons.psychology_outlined,
                        color: Colors.white,
                        size: 35,
                      ),
                      title: 'Assessment using AI',
                      description:
                          'Our AI-powered assessment analyzes your responses to provide deeper insights and personalized recommendations.',
                      duration: '20–25 min',
                      onTap: () => _showAiAssessment(context),
                    ),
                    SizedBox(height: 22 * scale),
                    const FeaturedArticlesSection(
                      style: FeaturedArticlesStyle.assessment,
                      itemSpacing: 9,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSelfAssessment(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: const Color(0xB80A1424),
      builder: (dialogContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
          child: _AssessmentProgramDialog(
            assignmentType: 'Self assignment',
            preparation:
                'Choose a quiet, comfortable location free from distractions. ',
            sections: const [
              _DialogSection(
                title: 'Overview',
                description:
                    'This assessment aims to gather information about your behaviors, feelings, and experiences to help identify symptoms of ADHD.',
                icon: Icons.visibility_outlined,
              ),
              _DialogSection(
                title: 'Purpose',
                description:
                    'The purpose of this questionnaire is to evaluate various aspects of attention, impulsivity, and hyperactivity in your daily life.',
                icon: Icons.track_changes_rounded,
              ),
            ],
            details: const [
              _DialogDetail(
                label: 'Questions',
                description:
                    'You will be asked to complete a series of questions related to your behaviors, thoughts, and feelings. ',
                icon: Icons.help_outline_rounded,
              ),
              _DialogDetail(
                label: 'Duration',
                description:
                    'Completing the questionnaire will take approximately 20-30 minutes.',
                icon: Icons.schedule_rounded,
              ),
              _DialogDetail(
                label: 'Confidentiality',
                description:
                    'Your responses will be kept confidential and all data will be anonymized to protect your privacy.',
                icon: Icons.privacy_tip_outlined,
              ),
            ],
            onClose: () => Navigator.of(dialogContext).pop(),
            onGetStarted: () {
              Navigator.push(
                dialogContext,
                MaterialPageRoute(builder: (_) => QuestionnaireScreen()),
              );
            },
          ),
        );
      },
    );
  }

  void _showAiAssessment(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: const Color(0xB80A1424),
      builder: (dialogContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
          child: _AssessmentProgramDialog(
            assignmentType: 'Assessment using AI ',
            preparation:
                'Choose a quiet, comfortable location free from distractions. Ensure you have a reliable smartphone with internet access.',
            sections: const [
              _DialogSection(
                title: 'Overview',
                description:
                    'This assessment is designed to observe and evaluate your behaviors in various settings to identify potential ADHD symptoms.',
                icon: Icons.visibility_outlined,
              ),
              _DialogSection(
                title: 'Purpose',
                description:
                    'You may be asked to perform certain tasks or activities designed to highlight behaviors related to ADHD. These tasks might include puzzles, games, videos, or structured activities that require focus and attention.',
                icon: Icons.track_changes_rounded,
              ),
            ],
            details: const [
              _DialogDetail(
                label: 'Interactive Tasks',
                description:
                    'You will engage in various tasks designed to assess different aspects of attention and behavior.',
                icon: Icons.assignment_outlined,
              ),
              _DialogDetail(
                label: 'Duration',
                description:
                    'The entire assessment will take approximately 10-30 minutes.',
                icon: Icons.schedule_rounded,
              ),
              _DialogDetail(
                label: 'Confidentiality',
                description: 'Data will be anonymized to protect your privacy.',
                icon: Icons.privacy_tip_outlined,
              ),
            ],
            onClose: () => Navigator.of(dialogContext).pop(),
            onGetStarted: () {
              Navigator.pop(dialogContext);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AiAssessmentListScreen(),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _DialogSection {
  final String title;
  final String description;
  final IconData icon;

  const _DialogSection({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class _DialogDetail {
  final String label;
  final String description;
  final IconData icon;

  const _DialogDetail({
    required this.label,
    required this.description,
    required this.icon,
  });
}

class _AssessmentProgramDialog extends StatefulWidget {
  final String assignmentType;
  final String preparation;
  final List<_DialogSection> sections;
  final List<_DialogDetail> details;
  final VoidCallback onClose;
  final VoidCallback onGetStarted;

  const _AssessmentProgramDialog({
    required this.assignmentType,
    required this.preparation,
    required this.sections,
    required this.details,
    required this.onClose,
    required this.onGetStarted,
  });

  static const _navy = Color(0xFF101D36);
  static const _copy = Color(0xFF48546A);
  static const _blue = Color(0xFF0F7FFF);
  static const _iconBg = Color(0xFFEAF5FF);

  @override
  State<_AssessmentProgramDialog> createState() =>
      _AssessmentProgramDialogState();
}

class _AssessmentProgramDialogState extends State<_AssessmentProgramDialog> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final shortestSide = media.shortestSide;
    final scale = (shortestSide / 430).clamp(.78, .94).toDouble();
    final horizontalInset = (shortestSide * .065).clamp(18.0, 30.0);
    final verticalInset = (media.height * .06).clamp(22.0, 50.0);

    return Dialog(
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: horizontalInset,
        vertical: verticalInset,
      ),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 440,
          maxHeight: media.height - (verticalInset * 2),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24 * scale),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .22),
                blurRadius: 32,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              17 * scale,
              18 * scale,
              17 * scale,
              18 * scale,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AssessmentDialogHeader(
                  scale: scale,
                  title: widget.assignmentType,
                  onClose: widget.onClose,
                ),
                SizedBox(height: 14 * scale),
                Flexible(
                  child: ScrollbarTheme(
                    data: ScrollbarThemeData(
                      thumbColor: WidgetStateProperty.all(
                        const Color(0xFF8DBEFF),
                      ),
                      trackColor: WidgetStateProperty.all(
                        const Color(0xFFEAF2FC),
                      ),
                      trackBorderColor: WidgetStateProperty.all(
                        Colors.transparent,
                      ),
                    ),
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      trackVisibility: true,
                      radius: const Radius.circular(20),
                      thickness: (3.5 * scale).clamp(3, 4),
                      interactive: true,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.only(right: 10 * scale),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _AssessmentHeroImage(scale: scale),
                            SizedBox(height: 16 * scale),
                            for (
                              var index = 0;
                              index < widget.sections.length;
                              index++
                            ) ...[
                              _AssessmentInfoRow(
                                icon: widget.sections[index].icon,
                                title: widget.sections[index].title,
                                description: widget.sections[index].description,
                                scale: scale,
                              ),
                              if (index != widget.sections.length - 1)
                                _AssessmentDivider(scale: scale),
                            ],
                            SizedBox(height: 8 * scale),
                            for (final detail in widget.details)
                              _AssessmentCompactInfoRow(
                                icon: detail.icon,
                                label: detail.label,
                                description: detail.description,
                                scale: scale,
                              ),
                            SizedBox(height: 6 * scale),
                            _AssessmentPreparationCard(
                              preparation: widget.preparation,
                              scale: scale,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 15 * scale),
                _AssessmentGetStartedButton(
                  scale: scale,
                  onTap: widget.onGetStarted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AssessmentDialogHeader extends StatelessWidget {
  final double scale;
  final String title;
  final VoidCallback onClose;

  const _AssessmentDialogHeader({
    required this.scale,
    required this.title,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38 * scale,
          height: 38 * scale,
          padding: EdgeInsets.all(6 * scale),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11 * scale),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF158CFF), Color(0xFF0977F3)],
            ),
          ),
          child: SvgPicture.asset(selfAssignmentIcon),
        ),
        SizedBox(width: 13 * scale),
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _AssessmentProgramDialog._navy,
              fontSize: (18 * scale).clamp(14.5, 18),
              fontFamily: 'Nunito Sans',
              fontWeight: FontWeight.w700,
              height: 1.14,
            ),
          ),
        ),
        SizedBox(width: 10 * scale),
        Material(
          color: const Color(0xFFF0F4F9),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onClose,
            child: SizedBox.square(
              dimension: 38 * scale,
              child: Icon(
                Icons.close_rounded,
                color: _AssessmentProgramDialog._navy,
                size: 25 * scale,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AssessmentHeroImage extends StatelessWidget {
  final double scale;

  const _AssessmentHeroImage({required this.scale});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2.38,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18 * scale),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, .4, .61, 1],
              colors: [
                Color(0xFFFFBD24),
                Color(0xFFFFFBF0),
                Color(0xFFFFFFFF),
                Color(0xFF147FFF),
              ],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: height * .15,
                    left: width * .07,
                    child: SvgPicture.asset(
                      selfAssignmentLeftImage,
                      width: width * .115,
                    ),
                  ),
                  Positioned(
                    top: -height * .12,
                    left: width * .19,
                    right: width * .19,
                    bottom: -height * .09,
                    child: SvgPicture.asset(
                      selfAssignmentCenterImage,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned(
                    top: height * .36,
                    right: width * .09,
                    child: SvgPicture.asset(
                      selfAssignmentRightImage,
                      width: width * .115,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AssessmentInfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final double scale;

  const _AssessmentInfoRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2 * scale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AssessmentCircleIcon(icon: icon, scale: scale),
          SizedBox(width: 14 * scale),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 1 * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: _AssessmentProgramDialog._navy,
                      fontSize: (16.2 * scale).clamp(13.5, 16.2),
                      fontFamily: 'Nunito Sans',
                      fontWeight: FontWeight.w700,
                      height: 1.18,
                    ),
                  ),
                  SizedBox(height: 6 * scale),
                  Text(
                    description,
                    style: TextStyle(
                      color: _AssessmentProgramDialog._copy,
                      fontSize: (13.4 * scale).clamp(11.8, 13.4),
                      fontFamily: 'Nunito Sans',
                      fontWeight: FontWeight.w500,
                      height: 1.48,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssessmentCompactInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final double scale;

  const _AssessmentCompactInfoRow({
    required this.icon,
    required this.label,
    required this.description,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10 * scale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AssessmentCircleIcon(icon: icon, scale: scale),
          SizedBox(width: 14 * scale),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 3 * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F1FF),
                      borderRadius: BorderRadius.circular(6 * scale),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 7 * scale,
                        vertical: 2.5 * scale,
                      ),
                      child: Text(
                        '$label:',
                        style: TextStyle(
                          color: _AssessmentProgramDialog._blue,
                          fontSize: (11.8 * scale).clamp(10.4, 11.8),
                          fontFamily: 'Nunito Sans',
                          fontWeight: FontWeight.w700,
                          height: 1.05,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 7 * scale),
                  Text(
                    description,
                    style: TextStyle(
                      color: _AssessmentProgramDialog._copy,
                      fontSize: (13.1 * scale).clamp(11.7, 13.1),
                      fontFamily: 'Nunito Sans',
                      fontWeight: FontWeight.w500,
                      height: 1.42,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssessmentCircleIcon extends StatelessWidget {
  final IconData icon;
  final double scale;

  const _AssessmentCircleIcon({required this.icon, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44 * scale,
      height: 44 * scale,
      decoration: const BoxDecoration(
        color: _AssessmentProgramDialog._iconBg,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: _AssessmentProgramDialog._blue,
        size: 25 * scale,
      ),
    );
  }
}

class _AssessmentDivider extends StatelessWidget {
  final double scale;

  const _AssessmentDivider({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 11 * scale, 0, 12 * scale),
      child: const Divider(height: 1, thickness: 1, color: Color(0xFFE8EEF6)),
    );
  }
}

class _AssessmentPreparationCard extends StatelessWidget {
  final String preparation;
  final double scale;

  const _AssessmentPreparationCard({
    required this.preparation,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        10 * scale,
        12 * scale,
        12 * scale,
        12 * scale,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF3),
        borderRadius: BorderRadius.circular(10 * scale),
        border: Border.all(color: const Color(0xFFFFD685)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44 * scale,
            height: 44 * scale,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF0CC),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.verified_user_outlined,
              color: const Color(0xFFD99A00),
              size: 25 * scale,
            ),
          ),
          SizedBox(width: 12 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preparation:',
                  style: TextStyle(
                    color: const Color(0xFFB47A00),
                    fontSize: (13.1 * scale).clamp(11.7, 13.1),
                    fontFamily: 'Nunito Sans',
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: 5 * scale),
                Text(
                  preparation,
                  style: TextStyle(
                    color: _AssessmentProgramDialog._copy,
                    fontSize: (12.8 * scale).clamp(11.4, 12.8),
                    fontFamily: 'Nunito Sans',
                    fontWeight: FontWeight.w500,
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

class _AssessmentGetStartedButton extends StatelessWidget {
  final double scale;
  final VoidCallback onTap;

  const _AssessmentGetStartedButton({required this.scale, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _AssessmentProgramDialog._blue,
      borderRadius: BorderRadius.circular(11 * scale),
      child: InkWell(
        borderRadius: BorderRadius.circular(11 * scale),
        onTap: onTap,
        child: SizedBox(
          width: double.infinity,
          height: (52 * scale).clamp(43, 50),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Get started',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: (17.2 * scale).clamp(14.8, 17.2),
                  fontFamily: 'Nunito Sans',
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              SizedBox(width: 9 * scale),
              Icon(
                Icons.north_east_rounded,
                color: Colors.white,
                size: 23 * scale,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  final double scale;
  final bool showBackButton;

  const _PageHeader({required this.scale, required this.showBackButton});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showBackButton) ...[
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 7,
            shadowColor: const Color(0xFF243557).withValues(alpha: .18),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.maybePop(context),
              child: SizedBox(
                width: 42 * scale,
                height: 42 * scale,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AssignmentScreen._navy,
                  size: 20 * scale,
                ),
              ),
            ),
          ),
          SizedBox(width: 14 * scale),
        ],
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 5 * scale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ADHD Assessment',
                  style: TextStyle(
                    color: AssignmentScreen._navy,
                    fontSize: (24 * scale).clamp(21, 24),
                    fontFamily: 'Nunito Sans',
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                ),
                SizedBox(height: 15 * scale),
                Text(
                  'Understand your attention better.\nTake the first step toward clarity.',
                  style: TextStyle(
                    color: AssignmentScreen._body,
                    fontSize: (13.5 * scale).clamp(12, 13.5),
                    fontFamily: 'Nunito Sans',
                    fontWeight: FontWeight.w500,
                    height: 1.55,
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

class _CuratorCard extends StatelessWidget {
  final double scale;

  const _CuratorCard({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        15 * scale,
        13 * scale,
        14 * scale,
        15 * scale,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14 * scale),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF03102E), Color(0xFF0C2D68)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0E3473).withValues(alpha: .16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ASSESSMENT STANDARD',
            style: TextStyle(
              color: const Color(0xFF67A7FF),
              fontSize: 10.5 * scale,
              fontFamily: 'Nunito Sans',
              fontWeight: FontWeight.w600,
              letterSpacing: .35,
            ),
          ),
          SizedBox(height: 9 * scale),
          Row(
            children: [
              _TrustPill(
                scale: scale,
                icon: Icons.verified_user_outlined,
                title: 'Evidence-based',
                subtitle: 'Structured screening',
              ),
              SizedBox(width: 8 * scale),
              _TrustPill(
                scale: scale,
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy-first',
                subtitle: 'Data protected',
              ),
              SizedBox(width: 8 * scale),
              _TrustPill(
                scale: scale,
                icon: Icons.route_outlined,
                title: 'Guided flow',
                subtitle: 'Clear next steps',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrustPill extends StatelessWidget {
  final double scale;
  final IconData icon;
  final String title;
  final String subtitle;

  const _TrustPill({
    required this.scale,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        constraints: BoxConstraints(minHeight: 58 * scale),
        padding: EdgeInsets.symmetric(
          horizontal: 7 * scale,
          vertical: 8 * scale,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(12 * scale),
          border: Border.all(color: Colors.white.withValues(alpha: .12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF87B9FF), size: 18 * scale),
            SizedBox(height: 5 * scale),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: (10.7 * scale).clamp(9.5, 10.7),
                fontFamily: 'Nunito Sans',
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            SizedBox(height: 3 * scale),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFFD2D9EA),
                fontSize: (9.2 * scale).clamp(8.3, 9.2),
                fontFamily: 'Nunito Sans',
                fontWeight: FontWeight.w500,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final double scale;

  const _SectionTitle({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.auto_awesome_rounded,
          color: const Color(0xFF75A7FF),
          size: 23 * scale,
        ),
        SizedBox(width: 10 * scale),
        Expanded(
          child: Text(
            'Choose your preferred method',
            style: TextStyle(
              color: AssignmentScreen._navy,
              fontSize: (17 * scale).clamp(15, 17),
              fontFamily: 'Nunito Sans',
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _AssessmentCard extends StatelessWidget {
  final double scale;
  final Color accent;
  final List<Color> iconColors;
  final Widget icon;
  final String title;
  final String description;
  final String duration;
  final VoidCallback onTap;

  const _AssessmentCard({
    required this.scale,
    required this.accent,
    required this.iconColors,
    required this.icon,
    required this.title,
    required this.description,
    required this.duration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(13 * scale),
      child: InkWell(
        borderRadius: BorderRadius.circular(13 * scale),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13 * scale),
            border: Border.all(color: const Color(0xFFE5EAF2)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF20345D).withValues(alpha: .075),
                blurRadius: 18 * scale,
                offset: Offset(0, 7 * scale),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 3 * scale,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(13 * scale),
                      bottomLeft: Radius.circular(13 * scale),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      17 * scale,
                      14 * scale,
                      14 * scale,
                      12 * scale,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 47 * scale,
                          height: 47 * scale,
                          alignment: Alignment.center,
                          padding: EdgeInsets.all(7 * scale),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: iconColors,
                            ),
                            borderRadius: BorderRadius.circular(11 * scale),
                          ),
                          child: icon,
                        ),
                        SizedBox(width: 18 * scale),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  color: AssignmentScreen._navy,
                                  fontSize: (15.5 * scale).clamp(14, 15.5),
                                  fontFamily: 'Nunito Sans',
                                  fontWeight: FontWeight.w800,
                                  height: 1.15,
                                ),
                              ),
                              SizedBox(height: 8 * scale),
                              Text(
                                description,
                                style: TextStyle(
                                  color: AssignmentScreen._body,
                                  fontSize: (11.7 * scale).clamp(10.7, 11.7),
                                  fontFamily: 'Nunito Sans',
                                  fontWeight: FontWeight.w600,
                                  height: 1.46,
                                ),
                              ),
                              SizedBox(height: 11 * scale),
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 9 * scale,
                                      vertical: 6 * scale,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5FD),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.schedule_rounded,
                                          size: 14 * scale,
                                          color: const Color(0xFF50658E),
                                        ),
                                        SizedBox(width: 5 * scale),
                                        Text(
                                          duration,
                                          style: TextStyle(
                                            color: const Color(0xFF50658E),
                                            fontSize: 10.5 * scale,
                                            fontFamily: 'Nunito Sans',
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Learn more',
                                    style: TextStyle(
                                      color: AssignmentScreen._blue,
                                      fontSize: 10.5 * scale,
                                      fontFamily: 'Nunito Sans',
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(width: 11 * scale),
                                  Container(
                                    width: 42 * scale,
                                    height: 42 * scale,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF1D2C4A,
                                          ).withValues(alpha: .12),
                                          blurRadius: 16,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.arrow_forward_rounded,
                                      color: AssignmentScreen._navy,
                                      size: 23 * scale,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
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
