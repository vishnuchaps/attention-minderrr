import 'dart:ui';

import 'package:attention_minder/constant/asset_path.dart';
import 'package:attention_minder/module/attention_management/presentation/screens/attention_program_overview_screen.dart';
import 'package:attention_minder/module/home/presentation/widgets/featured_articles_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
      barrierColor: const Color(0xB80A1424),
      builder: (dialogContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
          child: _ManagementProgramDialog(
            onClose: () => Navigator.of(dialogContext).pop(),
            onGetStarted: () {
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
      },
    );
  }
}

class _ManagementProgramDialog extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onGetStarted;

  const _ManagementProgramDialog({
    required this.onClose,
    required this.onGetStarted,
  });

  static const _navy = Color(0xFF101D36);
  static const _copy = Color(0xFF48546A);
  static const _blue = Color(0xFF0F7FFF);
  static const _iconBg = Color(0xFFEAF5FF);

  @override
  State<_ManagementProgramDialog> createState() =>
      _ManagementProgramDialogState();
}

class _ManagementProgramDialogState extends State<_ManagementProgramDialog> {
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
                _ManagementDialogHeader(scale: scale, onClose: widget.onClose),
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
                            _ManagementHeroImage(scale: scale),
                            SizedBox(height: 16 * scale),
                            _InfoRow(
                              icon: Icons.visibility_outlined,
                              title: 'Overview',
                              description:
                                  'This program is designed to help you manage attention through AI-driven exercises.',
                              scale: scale,
                            ),
                            _Divider(scale: scale),
                            _InfoRow(
                              icon: Icons.track_changes_rounded,
                              title: 'Purpose',
                              description:
                                  'You will engage in personalized tasks that adapt to your focus levels.',
                              scale: scale,
                            ),
                            SizedBox(height: 8 * scale),
                            _CompactInfoRow(
                              icon: Icons.assignment_outlined,
                              label: 'Interactive Tasks',
                              description:
                                  'Engage in various tasks designed to improve attention.',
                              scale: scale,
                            ),
                            _CompactInfoRow(
                              icon: Icons.schedule_rounded,
                              label: 'Duration',
                              description:
                                  'The session will take approximately 10-20 minutes.',
                              scale: scale,
                            ),
                            _CompactInfoRow(
                              icon: Icons.privacy_tip_outlined,
                              label: 'Confidentiality',
                              description:
                                  'Data will be anonymized to protect your privacy.',
                              scale: scale,
                            ),
                            SizedBox(height: 6 * scale),
                            _PreparationCard(scale: scale),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 15 * scale),
                _GetStartedButton(scale: scale, onTap: widget.onGetStarted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ManagementDialogHeader extends StatelessWidget {
  final double scale;
  final VoidCallback onClose;

  const _ManagementDialogHeader({required this.scale, required this.onClose});

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
            'Attention Management using AI',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _ManagementProgramDialog._navy,
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
                color: _ManagementProgramDialog._navy,
                size: 25 * scale,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ManagementHeroImage extends StatelessWidget {
  final double scale;

  const _ManagementHeroImage({required this.scale});

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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final double scale;

  const _InfoRow({
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
          _CircleIcon(icon: icon, scale: scale),
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
                      color: _ManagementProgramDialog._navy,
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
                      color: _ManagementProgramDialog._copy,
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

class _CompactInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final double scale;

  const _CompactInfoRow({
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
          _CircleIcon(icon: icon, scale: scale),
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
                          color: _ManagementProgramDialog._blue,
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
                      color: _ManagementProgramDialog._copy,
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

class _CircleIcon extends StatelessWidget {
  final IconData icon;
  final double scale;

  const _CircleIcon({required this.icon, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44 * scale,
      height: 44 * scale,
      decoration: const BoxDecoration(
        color: _ManagementProgramDialog._iconBg,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: _ManagementProgramDialog._blue,
        size: 25 * scale,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final double scale;

  const _Divider({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 11 * scale, 0, 12 * scale),
      child: const Divider(height: 1, thickness: 1, color: Color(0xFFE8EEF6)),
    );
  }
}

class _PreparationCard extends StatelessWidget {
  final double scale;

  const _PreparationCard({required this.scale});

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
                  'Choose a quiet, comfortable location free from distractions. Ensure you have a reliable smartphone with internet access.',
                  style: TextStyle(
                    color: _ManagementProgramDialog._copy,
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

class _GetStartedButton extends StatelessWidget {
  final double scale;
  final VoidCallback onTap;

  const _GetStartedButton({required this.scale, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _ManagementProgramDialog._blue,
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
