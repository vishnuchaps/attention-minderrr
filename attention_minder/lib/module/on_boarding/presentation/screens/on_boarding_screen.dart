import 'package:attention_minder/constant/asset_path.dart';
import 'package:attention_minder/module/authentication/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnBoardingScreen extends StatelessWidget {
  const OnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final metrics = _OnBoardingMetrics.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF8E8), Color(0xFFFFFFFF), Color(0xFFEAF6FF)],
            stops: [0, .56, 1],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  metrics.pagePadding,
                  metrics.v(4),
                  metrics.pagePadding,
                  metrics.safeBottom + metrics.v(18),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: metrics.contentWidth,
                          child: _OnBoardingContent(metrics: metrics),
                        ),
                      ),
                    ),
                    SizedBox(height: metrics.v(16)),
                    _GetStartedButton(
                      metrics: metrics,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
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
}

class _OnBoardingMetrics {
  final double width;
  final double height;
  final double scale;
  final double heightScale;
  final double safeBottom;

  const _OnBoardingMetrics({
    required this.width,
    required this.height,
    required this.scale,
    required this.heightScale,
    required this.safeBottom,
  });

  factory _OnBoardingMetrics.of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return _OnBoardingMetrics(
      width: size.width,
      height: size.height,
      scale: (size.width / 430).clamp(.82, 1.0).toDouble(),
      heightScale: (size.height / 844).clamp(.76, 1.0).toDouble(),
      safeBottom: MediaQuery.paddingOf(context).bottom,
    );
  }

  bool get compactHeight => height < 720;
  bool get tinyHeight => height < 640;
  double get pagePadding => s(width < 360 ? 22 : 28);
  double get contentWidth => (width - (pagePadding * 2)).clamp(0, 476);
  double get heroHeight => tinyHeight
      ? v(250)
      : compactHeight
      ? v(285)
      : v(340);
  double get buttonHeight => tinyHeight ? 50 : 56;

  double s(double value) => value * scale;
  double v(double value) => value * heightScale;

  double font(double value) {
    final scaled = value * scale;
    return scaled.clamp(value * .84, value).toDouble();
  }
}

class _OnBoardingHero extends StatelessWidget {
  final _OnBoardingMetrics metrics;

  const _OnBoardingHero({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: metrics.heroHeight,
      child: CustomPaint(
        painter: _HeroDecorPainter(),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: metrics.s(28),
              right: metrics.s(20),
              top: metrics.heroHeight * .2,
              child: Container(
                height: metrics.heroHeight * .62,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .62),
                  borderRadius: BorderRadius.circular(metrics.s(22)),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .68),
                  ),
                ),
              ),
            ),
            Positioned(
              right: -metrics.s(46),
              bottom: metrics.v(20),
              child: Container(
                width: metrics.s(154),
                height: metrics.s(154),
                decoration: BoxDecoration(
                  color: const Color(0xFF93C8FF).withValues(alpha: .38),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: metrics.v(6),
              child: Image.asset(
                onBoardingImage,
                width: metrics.s(metrics.tinyHeight ? 270 : 340),
                height: metrics.heroHeight * .98,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroDecorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final loopPaint = Paint()
      ..color = const Color(0xFFFFB21B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.4
      ..strokeCap = StrokeCap.round;

    final loop = Path()
      ..moveTo(size.width * .64, -size.height * .12)
      ..cubicTo(
        size.width * .55,
        size.height * .23,
        size.width * .18,
        size.height * -.04,
        size.width * .02,
        size.height * .42,
      )
      ..cubicTo(
        -size.width * .1,
        size.height * .78,
        size.width * .32,
        size.height * .68,
        size.width * .42,
        size.height * .92,
      )
      ..cubicTo(
        size.width * .48,
        size.height * 1.08,
        size.width * .22,
        size.height * 1.08,
        size.width * .16,
        size.height * .96,
      );
    canvas.drawPath(loop, loopPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OnBoardingContent extends StatelessWidget {
  final _OnBoardingMetrics metrics;

  const _OnBoardingContent({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OnBoardingHero(metrics: metrics),
        SizedBox(height: metrics.v(metrics.compactHeight ? 8 : 14)),
        RichText(
          text: TextSpan(
            style: GoogleFonts.nunitoSans(
              color: const Color(0xFF101936),
              fontSize: metrics.font(metrics.compactHeight ? 37 : 44),
              fontWeight: FontWeight.w900,
              height: 1.02,
            ),
            children: const [
              TextSpan(text: 'Welcome to\n'),
              TextSpan(
                text: 'Attention Minder',
                style: TextStyle(color: Color(0xFF147DFA)),
              ),
            ],
          ),
        ),
        SizedBox(height: metrics.v(13)),
        Center(child: _HeartDivider(metrics: metrics)),
        SizedBox(height: metrics.v(15)),
        _BodyCopy(
          metrics: metrics,
          text:
              "Attention Minder is your AI-powered guide to better concentration-for kids and adults alike. Whether you're learning or working, our app helps you take control of your focus with a personalized journey.",
        ),
        SizedBox(height: metrics.v(14)),
        _BodyCopy(
          metrics: metrics,
          text:
              "Start with a quick assessment using our smart questionnaire and AI engine. Based on your attention profile, you'll begin a structured concentration management program.",
        ),
        SizedBox(height: metrics.v(metrics.compactHeight ? 20 : 26)),
        _FeatureStrip(metrics: metrics),
      ],
    );
  }
}

class _HeartDivider extends StatelessWidget {
  final _OnBoardingMetrics metrics;

  const _HeartDivider({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: metrics.s(118),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: const Color(0xFFDDE7F3))),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: metrics.s(13)),
            child: Icon(
              Icons.favorite_rounded,
              color: const Color(0xFFF8B51E),
              size: metrics.s(17),
            ),
          ),
          Expanded(child: Container(height: 1, color: const Color(0xFFDDE7F3))),
        ],
      ),
    );
  }
}

class _BodyCopy extends StatelessWidget {
  final _OnBoardingMetrics metrics;
  final String text;

  const _BodyCopy({required this.metrics, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.nunitoSans(
        color: const Color(0xFF566078),
        fontSize: metrics.font(metrics.compactHeight ? 16.1 : 18.4),
        fontWeight: FontWeight.w500,
        height: 1.38,
      ),
    );
  }
}

class _FeatureData {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _FeatureStrip extends StatelessWidget {
  final _OnBoardingMetrics metrics;

  const _FeatureStrip({required this.metrics});

  @override
  Widget build(BuildContext context) {
    const items = [
      _FeatureData(
        icon: Icons.my_location_rounded,
        title: 'Personalized',
        subtitle: 'journey',
      ),
      _FeatureData(
        icon: Icons.psychology_outlined,
        title: 'AI-powered',
        subtitle: 'insights',
      ),
      _FeatureData(
        icon: Icons.bar_chart_rounded,
        title: 'Track & improve',
        subtitle: 'your focus',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        metrics.s(12),
        metrics.v(16),
        metrics.s(12),
        metrics.v(15),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(metrics.s(19)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9DBBDA).withValues(alpha: .12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < items.length; index++) ...[
            Expanded(
              child: _FeatureTile(metrics: metrics, data: items[index]),
            ),
            if (index != items.length - 1) _FeatureDivider(metrics: metrics),
          ],
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final _OnBoardingMetrics metrics;
  final _FeatureData data;

  const _FeatureTile({required this.metrics, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: metrics.s(54),
          height: metrics.s(54),
          decoration: const BoxDecoration(
            color: Color(0xFFEAF5FF),
            shape: BoxShape.circle,
          ),
          child: Icon(
            data.icon,
            color: const Color(0xFF147DFA),
            size: metrics.s(29),
          ),
        ),
        SizedBox(height: metrics.v(12)),
        Text(
          data.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: GoogleFonts.nunitoSans(
            color: const Color(0xFF10162F),
            fontSize: metrics.font(14.6),
            fontWeight: FontWeight.w800,
            height: 1.12,
          ),
        ),
        SizedBox(height: metrics.v(4)),
        Text(
          data.subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: GoogleFonts.nunitoSans(
            color: const Color(0xFF566078),
            fontSize: metrics.font(14.6),
            fontWeight: FontWeight.w500,
            height: 1.12,
          ),
        ),
      ],
    );
  }
}

class _FeatureDivider extends StatelessWidget {
  final _OnBoardingMetrics metrics;

  const _FeatureDivider({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: metrics.v(74),
      margin: EdgeInsets.symmetric(horizontal: metrics.s(8)),
      color: const Color(0xFFDDE7F3),
    );
  }
}

class _GetStartedButton extends StatelessWidget {
  final _OnBoardingMetrics metrics;
  final VoidCallback onTap;

  const _GetStartedButton({required this.metrics, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0F79FF),
      borderRadius: BorderRadius.circular(metrics.s(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(metrics.s(14)),
        onTap: onTap,
        child: SizedBox(
          width: double.infinity,
          height: metrics.buttonHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Get Started',
                style: GoogleFonts.nunitoSans(
                  color: Colors.white,
                  fontSize: metrics.font(20),
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(width: metrics.s(9)),
              Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: metrics.s(22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
