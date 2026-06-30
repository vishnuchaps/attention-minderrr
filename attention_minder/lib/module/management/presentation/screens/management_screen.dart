import 'package:attention_minder/constant/asset_path.dart';
import 'package:attention_minder/module/assigment/presentation/widgets/assignment_overlay_widget.dart';
import 'package:attention_minder/module/assigment/presentation/widgets/text_card_widget.dart';
import 'package:attention_minder/module/assigment/presentation/widgets/title_subtitle_widget.dart';
import 'package:attention_minder/module/assigment/presentation/widgets/yellow_test_card_widget.dart';
import 'package:attention_minder/module/attention_management/presentation/screens/attention_program_overview_screen.dart';
import 'package:attention_minder/module/home/presentation/widgets/featured_articles_section.dart';
import 'package:flutter/material.dart';

class ManagementScreen extends StatelessWidget {
  final bool showBackButton;

  const ManagementScreen({super.key, this.showBackButton = true});

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
                    _ProgramHero(scale: scale),
                    SizedBox(height: 24 * scale),
                    _SectionTitle(scale: scale),
                    SizedBox(height: 14 * scale),
                    _ManagementCard(
                      scale: scale,
                      onTap: () => _showManagementProgram(context),
                    ),
                    SizedBox(height: 23 * scale),
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

  void _showManagementProgram(BuildContext context) {
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
        assignmentType: 'Attention Management using AI ',
        yellowTestCardWidget: const YellowTestCardWidget(
          title: 'Preparation',
          subTitle:
              'Choose a quiet, comfortable location free from distractions. Ensure you have a reliable smartphone with internet access.',
        ),
        titleSubtitleWidget: const [
          TitleSubtitleWidget(
            title: 'Overview',
            subTitle:
                'This program is designed to help you manage attention through AI-driven exercises.',
          ),
          TitleSubtitleWidget(
            title: 'Purpose',
            subTitle:
                'You will engage in personalized tasks that adapt to your focus levels.',
          ),
        ],
        textCardWidget: const [
          TextCardWidget(
            text: 'Interactive Tasks',
            subTitle: 'Engage in various tasks designed to improve attention.',
          ),
          TextCardWidget(
            text: 'Duration',
            subTitle: 'The session will take approximately 10-20 minutes.',
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
            MaterialPageRoute(
              builder: (_) => const AttentionProgramOverviewScreen(),
            ),
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
                  color: ManagementScreen._navy,
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
                  'Attention Management',
                  style: TextStyle(
                    color: ManagementScreen._navy,
                    fontSize: (24 * scale).clamp(20, 24),
                    fontFamily: 'Nunito Sans',
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                ),
                SizedBox(height: 15 * scale),
                Text(
                  'Train your focus with a personalized plan.\nBuild better attention, one day at a time.',
                  style: TextStyle(
                    color: ManagementScreen._body,
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

class _ProgramHero extends StatelessWidget {
  final double scale;

  const _ProgramHero({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(17 * scale),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14 * scale),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF03102E), Color(0xFF0C3473)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0E3473).withValues(alpha: .17),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 55 * scale,
            height: 55 * scale,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15 * scale),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF347FE8), Color(0xFF24458F)],
              ),
            ),
            child: Icon(
              Icons.track_changes_rounded,
              color: Colors.white,
              size: 31 * scale,
            ),
          ),
          SizedBox(width: 14 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your personalized focus plan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: (14.5 * scale).clamp(13, 14.5),
                    fontFamily: 'Nunito Sans',
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 7 * scale),
                Text(
                  'Adaptive exercises designed around your attention needs.',
                  style: TextStyle(
                    color: const Color(0xFFD2D9EA),
                    fontSize: (11.3 * scale).clamp(10.4, 11.3),
                    fontFamily: 'Nunito Sans',
                    fontWeight: FontWeight.w500,
                    height: 1.42,
                  ),
                ),
                SizedBox(height: 10 * scale),
                Wrap(
                  spacing: 7 * scale,
                  runSpacing: 6 * scale,
                  children: [
                    _HeroBadge(
                      scale: scale,
                      icon: Icons.auto_awesome_rounded,
                      label: 'AI-powered',
                    ),
                    _HeroBadge(
                      scale: scale,
                      icon: Icons.shield_outlined,
                      label: 'Evidence-based',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final double scale;
  final IconData icon;
  final String label;

  const _HeroBadge({
    required this.scale,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 5 * scale),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: .12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.5 * scale, color: const Color(0xFF84B5FF)),
          SizedBox(width: 5 * scale),
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFFE6EDFA),
              fontSize: 9.5 * scale,
              fontFamily: 'Nunito Sans',
              fontWeight: FontWeight.w700,
            ),
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
            'Start your attention program',
            style: TextStyle(
              color: ManagementScreen._navy,
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

class _ManagementCard extends StatelessWidget {
  final double scale;
  final VoidCallback onTap;

  const _ManagementCard({required this.scale, required this.onTap});

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
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF5A9CFF), Color(0xFF6E74F5)],
                    ),
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
                      15 * scale,
                      14 * scale,
                      13 * scale,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 49 * scale,
                          height: 49 * scale,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF75AAFF), Color(0xFF6678EF)],
                            ),
                            borderRadius: BorderRadius.circular(12 * scale),
                          ),
                          child: Icon(
                            Icons.psychology_outlined,
                            color: Colors.white,
                            size: 34 * scale,
                          ),
                        ),
                        SizedBox(width: 17 * scale),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Attention Management using AI',
                                style: TextStyle(
                                  color: ManagementScreen._navy,
                                  fontSize: (15.5 * scale).clamp(14, 15.5),
                                  fontFamily: 'Nunito Sans',
                                  fontWeight: FontWeight.w800,
                                  height: 1.18,
                                ),
                              ),
                              SizedBox(height: 8 * scale),
                              Text(
                                'Follow adaptive, AI-guided exercises that help strengthen focus, reduce distractions, and build lasting attention habits.',
                                style: TextStyle(
                                  color: ManagementScreen._body,
                                  fontSize: (11.7 * scale).clamp(10.7, 11.7),
                                  fontFamily: 'Nunito Sans',
                                  fontWeight: FontWeight.w600,
                                  height: 1.46,
                                ),
                              ),
                              SizedBox(height: 12 * scale),
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
                                          '10–20 min',
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
                                      color: ManagementScreen._blue,
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
                                      color: ManagementScreen._navy,
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
