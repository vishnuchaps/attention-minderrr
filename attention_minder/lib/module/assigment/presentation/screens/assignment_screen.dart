import 'package:attention_minder/constant/asset_path.dart';
import 'package:attention_minder/module/assigment/presentation/screens/ai_assessment_list_screen.dart';
import 'package:attention_minder/module/assigment/presentation/screens/questionnaire_screen.dart';
import 'package:attention_minder/module/assigment/presentation/widgets/assignment_overlay_widget.dart';
import 'package:attention_minder/module/assigment/presentation/widgets/text_card_widget.dart';
import 'package:attention_minder/module/assigment/presentation/widgets/title_subtitle_widget.dart';
import 'package:attention_minder/module/assigment/presentation/widgets/yellow_test_card_widget.dart';
import 'package:attention_minder/module/home/presentation/widgets/featured_articles_section.dart';
import 'package:flutter/material.dart';

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
      builder: (dialogContext) => AssignmentOverlayWidget(
        selfAssignmentIcon: selfAssignmentIcon,
        selfAssignmentLeftImage: selfAssignmentLeftImage,
        selfAssignmentCenterImage: selfAssignmentCenterImage,
        selfAssignmentRightImage: selfAssignmentRightImage,
        arrowIcon: arrowIcon,
        backIconPath: backIconPath,
        assignmentType: 'Self assignment',
        yellowTestCardWidget: const YellowTestCardWidget(
          title: 'Preparation',
          subTitle:
              'Choose a quiet, comfortable location free from distractions. ',
        ),
        titleSubtitleWidget: const [
          TitleSubtitleWidget(
            title: 'Overview',
            subTitle:
                'This assessment aims to gather information about your behaviors, feelings, and experiences to help identify symptoms of ADHD.',
          ),
          TitleSubtitleWidget(
            title: 'Purpose',
            subTitle:
                'The purpose of this questionnaire is to evaluate various aspects of attention, impulsivity, and hyperactivity in your daily life.',
          ),
        ],
        textCardWidget: const [
          TextCardWidget(
            text: 'Questions',
            subTitle:
                'You will be asked to complete a series of questions related to your behaviors, thoughts, and feelings. ',
          ),
          TextCardWidget(
            text: 'Duration',
            subTitle:
                'Completing the questionnaire will take approximately 20-30 minutes.',
          ),
          TextCardWidget(
            text: 'Confidentiality',
            subTitle:
                'Your responses will be kept confidential and all data will be anonymized to protect your privacy.',
          ),
        ],
        ontap: () {
          Navigator.push(
            dialogContext,
            MaterialPageRoute(builder: (_) => QuestionnaireScreen()),
          );
        },
      ),
    );
  }

  void _showAiAssessment(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AssignmentOverlayWidget(
        selfAssignmentIcon: selfAssignmentIcon,
        selfAssignmentLeftImage: selfAssignmentLeftImage,
        selfAssignmentCenterImage: selfAssignmentCenterImage,
        selfAssignmentRightImage: selfAssignmentRightImage,
        arrowIcon: arrowIcon,
        backIconPath: backIconPath,
        assignmentType: 'Assessment using AI ',
        yellowTestCardWidget: const YellowTestCardWidget(
          title: 'Preparation',
          subTitle:
              'Choose a quiet, comfortable location free from distractions. Ensure you have a reliable smartphone with internet access.',
        ),
        titleSubtitleWidget: const [
          TitleSubtitleWidget(
            title: 'Overview',
            subTitle:
                'This assessment is designed to observe and evaluate your behaviors in various settings to identify potential ADHD symptoms.',
          ),
          TitleSubtitleWidget(
            title: 'Purpose',
            subTitle:
                'You may be asked to perform certain tasks or activities designed to highlight behaviors related to ADHD. These tasks might include puzzles, games, videos, or structured activities that require focus and attention.',
          ),
        ],
        textCardWidget: const [
          TextCardWidget(
            text: 'Interactive Tasks',
            subTitle:
                'You will engage in various tasks designed to assess different aspects of attention and behavior.',
          ),
          TextCardWidget(
            text: 'Duration',
            subTitle:
                'The entire assessment will take approximately 10-30 minutes.',
          ),
          TextCardWidget(
            text: 'Confidentiality',
            subTitle: 'Data will be anonymized to protect your privacy.',
          ),
        ],
        ontap: () {
          Navigator.pop(dialogContext);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AiAssessmentListScreen()),
          );
        },
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
            'CURATED BY',
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
              Container(
                width: 42 * scale,
                height: 42 * scale,
                padding: EdgeInsets.all(1.5 * scale),
                decoration: const BoxDecoration(
                  color: Color(0xFFB8D6FF),
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'asset/images/demo_doctor_image.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(width: 9 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Dr. Harry Simon',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13 * scale,
                              fontFamily: 'Nunito Sans',
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        SizedBox(width: 6 * scale),
                        Icon(
                          Icons.verified_rounded,
                          color: const Color(0xFF2D91F7),
                          size: 17 * scale,
                        ),
                      ],
                    ),
                    SizedBox(height: 4 * scale),
                    Text(
                      'Clinical Psychologist',
                      style: TextStyle(
                        color: const Color(0xFFD2D9EA),
                        fontSize: 11.5 * scale,
                        fontFamily: 'Nunito Sans',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 47 * scale,
                color: const Color(0xFF6B86B5).withValues(alpha: .45),
              ),
              SizedBox(width: 14 * scale),
              Icon(
                Icons.shield_outlined,
                color: Colors.white,
                size: 29 * scale,
              ),
              SizedBox(width: 8 * scale),
              SizedBox(
                width: 105 * scale,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Evidence-based\n',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const TextSpan(text: 'Trusted by\nprofessionals'),
                    ],
                  ),
                  style: TextStyle(
                    color: const Color(0xFFD2D9EA),
                    fontSize: 10.5 * scale,
                    fontFamily: 'Nunito Sans',
                    fontWeight: FontWeight.w500,
                    height: 1.42,
                  ),
                ),
              ),
            ],
          ),
        ],
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
