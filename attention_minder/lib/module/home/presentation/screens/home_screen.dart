import 'package:attention_minder/Config/widgets/user_profile_avatar_widget.dart';
import 'package:attention_minder/constant/asset_path.dart';
import 'package:attention_minder/module/assigment/presentation/screens/assignment_screen.dart';
import 'package:attention_minder/module/attention_management/presentation/screens/attention_program_overview_screen.dart';
import 'package:attention_minder/module/home/presentation/bloc/progress_bloc.dart';
import 'package:attention_minder/module/home/presentation/widgets/featured_articles_section.dart';
import 'package:attention_minder/module/home/presentation/widgets/progress_card_widget.dart';
import 'package:attention_minder/module/management/presentation/screens/management_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  final GlobalKey? startAssessmentKey;
  final GlobalKey? continueManagementKey;
  final GlobalKey? attentionAssessmentKey;
  final GlobalKey? attentionManagementKey;

  const HomeScreen({
    super.key,
    this.startAssessmentKey,
    this.continueManagementKey,
    this.attentionAssessmentKey,
    this.attentionManagementKey,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<String?> _usernameFuture;

  @override
  void initState() {
    super.initState();
    _usernameFuture = _getUsername();
    context.read<ProgressBloc>().add(GetProgressCardEvent());
  }

  Future<String?> _getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  String _toDisplayName(String? username) {
    final trimmedUsername = username?.trim();
    if (trimmedUsername == null || trimmedUsername.isEmpty) {
      return 'Guest';
    }
    return trimmedUsername
        .split(RegExp(r'[\s_]+'))
        .where((part) => part.isNotEmpty)
        .map((part) {
          final lowerCasePart = part.toLowerCase();
          return lowerCasePart[0].toUpperCase() + lowerCasePart.substring(1);
        })
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _HomeMetrics.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      body: SafeArea(
        child: FutureBuilder<String?>(
          future: _usernameFuture,
          builder: (context, snapshot) {
            final username = _toDisplayName(snapshot.data);

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    metrics.pagePadding,
                    metrics.v(34),
                    metrics.pagePadding,
                    metrics.v(10),
                  ),
                  sliver: SliverAppBar(
                    pinned: true,
                    automaticallyImplyLeading: false,
                    expandedHeight: 90,
                    toolbarHeight: 95,

                    backgroundColor: Colors.white,
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.pin,
                      background: _HomeHeader(
                        username: username,
                        metrics: metrics,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: metrics.pagePadding,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: BlocBuilder<ProgressBloc, ProgressState>(
                      builder: (context, state) {
                        // if (state is ProgressLoading) {
                        //   return ProgressCardWidget(
                        //     answeredQuestions: 0,
                        //     totalQuestions: 0,
                        //   );
                        // }
                        if (state is GetProgressCardSuccess) {
                          final progressData = state.assessmentResult.data;
                          final answeredQuestions =
                              progressData?.answeredQuestions ?? 0;
                          final totalQuestions =
                              progressData?.totalQuestions ?? 0;

                          if (answeredQuestions > 0 &&
                              answeredQuestions < totalQuestions) {
                            return ProgressCardWidget(
                              answeredQuestions: answeredQuestions,
                              totalQuestions: totalQuestions,
                            );
                          }
                        } else if (state is GetProgressCardFailed) {
                          return Center(
                            child: Text(
                              'Error: ${state.message}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          );
                        }
                        return SizedBox.shrink();
                      },
                    ),
                  ),
                ),

                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: metrics.pagePadding,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _QuickActions(
                      metrics: metrics,
                      startAssessmentKey: widget.startAssessmentKey,
                      continueManagementKey: widget.continueManagementKey,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    metrics.pagePadding,
                    metrics.v(22),
                    metrics.pagePadding,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _ProgramCards(
                      metrics: metrics,
                      attentionAssessmentKey: widget.attentionAssessmentKey,
                      attentionManagementKey: widget.attentionManagementKey,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    metrics.pagePadding,
                    metrics.v(30),
                    metrics.pagePadding,
                    metrics.v(118),
                  ),
                  sliver: SliverToBoxAdapter(
                    child: const FeaturedArticlesSection(
                      style: FeaturedArticlesStyle.home,
                      itemSpacing: 14,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HomeMetrics {
  final double width;
  final double height;
  final double scale;
  final double heightScale;

  const _HomeMetrics({
    required this.width,
    required this.height,
    required this.scale,
    required this.heightScale,
  });

  factory _HomeMetrics.of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return _HomeMetrics(
      width: size.width,
      height: size.height,
      scale: (size.width / 430).clamp(.82, 1.0).toDouble(),
      heightScale: (size.width / 430).clamp(.82, 1.0).toDouble(),
    );
  }

  double get pagePadding => s(width < 360 ? 22 : 25);
  double get cardGap => s(12);
  bool get compact => width < 365;

  double s(double value) => value * scale;
  double v(double value) => value * heightScale;

  double font(double value) {
    final scaled = value * scale;
    return scaled.clamp(value * .82, value).toDouble();
  }
}

class _HomeHeader extends StatelessWidget {
  final String username;
  final _HomeMetrics metrics;

  const _HomeHeader({required this.username, required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FBFF),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, $username',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF07123A),
                    fontSize: metrics.font(34),
                    height: 1.12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: metrics.v(12)),
                Text(
                  "Let's continue your journey to better focus and mental well-being.",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF59627D),
                    fontSize: metrics.font(16),
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: metrics.s(16)),
          UserProfileAvatar(size: metrics.s(62), borderWidth: 3),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final _HomeMetrics metrics;
  final GlobalKey? startAssessmentKey;
  final GlobalKey? continueManagementKey;

  const _QuickActions({
    required this.metrics,
    this.startAssessmentKey,
    this.continueManagementKey,
  });

  @override
  Widget build(BuildContext context) {
    final gap = metrics.cardGap;
    final height = metrics
        .s(metrics.compact ? 184 : 190)
        .clamp(168.0, 190.0)
        .toDouble();

    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            key: startAssessmentKey,
            metrics: metrics,
            height: height,
            title: 'Start New\nAssessment',
            subtitle: 'Begin a new attention\nassessment',
            icon: homeCardIcon1,
            iconColor: const Color(0xFF815800),
            useButterflyIcon: true,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF0CC), Color(0xFFFFE5A9)],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AssignmentScreen()),
              );
            },
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: _QuickActionCard(
            key: continueManagementKey,
            metrics: metrics,
            height: height,
            title: 'Continue\nAttention\nManagement',
            subtitle: 'Resume your attention\nmanagement plan',
            icon: homeCardIcon2,
            iconColor: const Color(0xFFA7AAB0),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF3F3F4), Color(0xFFE7E7E9)],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AttentionProgramOverviewScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final _HomeMetrics metrics;
  final double height;
  final String title;
  final String subtitle;
  final String icon;
  final Color iconColor;
  final Gradient gradient;
  final VoidCallback onTap;
  final bool useButterflyIcon;

  const _QuickActionCard({
    super.key,
    required this.metrics,
    required this.height,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.gradient,
    required this.onTap,
    this.useButterflyIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(metrics.s(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(metrics.s(20)),
        onTap: onTap,
        child: Ink(
          height: height,
          padding: EdgeInsets.all(metrics.s(18)),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(metrics.s(20)),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                child: _SoftIconBubble(
                  metrics: metrics,
                  icon: icon,
                  color: iconColor,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF111827),
                        fontSize: metrics.font(17),
                        height: 1.14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: metrics.v(10)),
                    Padding(
                      padding: EdgeInsets.only(right: metrics.s(34)),
                      child: Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF59627D),
                          fontSize: metrics.font(13),
                          height: 1.30,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 4,
                bottom: 0,
                child: _ArrowButton(metrics: metrics, size: metrics.s(46)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgramCards extends StatelessWidget {
  final _HomeMetrics metrics;
  final GlobalKey? attentionAssessmentKey;
  final GlobalKey? attentionManagementKey;

  const _ProgramCards({
    required this.metrics,
    this.attentionAssessmentKey,
    this.attentionManagementKey,
  });

  @override
  Widget build(BuildContext context) {
    final gap = metrics.cardGap;
    final height = metrics
        .s(metrics.compact ? 188 : 196)
        .clamp(172.0, 196.0)
        .toDouble();

    return Row(
      children: [
        Expanded(
          child: _ProgramCard(
            key: attentionAssessmentKey,
            metrics: metrics,
            height: height,
            title: 'Attention\nAssessment',
            svg: vectorsvg,
            backgroundColor: const Color(0xFFDDF2FF),
            accentColor: const Color(0xFF90CEF5),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AssignmentScreen()),
              );
            },
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: _ProgramCard(
            key: attentionManagementKey,
            metrics: metrics,
            height: height,
            svg: vector1svg,
            title: 'Attention\nManagement',
            backgroundColor: const Color(0xFFF4E5FF),
            accentColor: const Color(0xFFD8A8F6),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManagementScreen()),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProgramTrustBadge extends StatelessWidget {
  final _HomeMetrics metrics;

  const _ProgramTrustBadge({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: metrics.s(9),
        vertical: metrics.v(6),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .62),
        borderRadius: BorderRadius.circular(metrics.s(18)),
        border: Border.all(color: const Color(0xFFD9E7FA)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: const Color(0xFF0A84FF),
            size: metrics.s(15),
          ),
          SizedBox(width: metrics.s(5)),
          Text(
            'Evidence-based',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFF07123A),
              fontSize: metrics.font(11.2),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  final _HomeMetrics metrics;
  final double height;
  final String title;
  final Color backgroundColor;
  final Color accentColor;
  final VoidCallback onTap;
  final String svg;
  const _ProgramCard({
    super.key,
    required this.metrics,
    required this.height,
    required this.title,
    required this.backgroundColor,
    required this.accentColor,
    required this.onTap,
    required this.svg,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(metrics.s(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(metrics.s(20)),
        onTap: onTap,
        child: Ink(
          height: height,
          padding: EdgeInsets.all(metrics.s(16)),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(metrics.s(20)),
            border: Border.all(color: accentColor.withValues(alpha: .32)),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -metrics.s(16),
                bottom: -metrics.s(18),
                child: _DecorativePuzzle(
                  size: metrics.s(118),
                  svg: svg,
                  color: accentColor.withValues(alpha: .28),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProgramTrustBadge(metrics: metrics),
                  SizedBox(height: metrics.v(metrics.compact ? 18 : 22)),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF111827),
                      fontSize: metrics.font(20),
                      height: 1.12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        color: const Color(0xFF59627D),
                        size: metrics.s(19),
                      ),
                      SizedBox(width: metrics.s(6)),
                      Expanded(
                        child: Text(
                          '1 hour 20 min',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFF59627D),
                            fontSize: metrics.font(14),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      _ArrowButton(metrics: metrics, size: metrics.s(46)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoftIconBubble extends StatelessWidget {
  final _HomeMetrics metrics;
  final String icon;
  final Color color;
  final double iconSize;

  const _SoftIconBubble({
    required this.metrics,
    required this.icon,
    required this.color,
  }) : iconSize = 25;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: metrics.s(44),
      height: metrics.s(44),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: SvgPicture.asset(
          icon,
          width: metrics.s(iconSize),
          height: metrics.s(iconSize),
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final _HomeMetrics metrics;
  final double size;

  const _ArrowButton({required this.metrics, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Icon(
        Icons.arrow_forward_rounded,
        color: Colors.black,
        size: metrics.s(24),
      ),
    );
  }
}

class _DecorativePuzzle extends StatelessWidget {
  final double size;
  final Color color;
  final String svg;
  const _DecorativePuzzle({
    required this.size,
    required this.color,
    required this.svg,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0,
      child: SvgPicture.asset(
        svg,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
    );
  }
}
