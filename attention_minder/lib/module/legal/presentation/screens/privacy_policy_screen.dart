import 'package:attention_minder/module/legal/presentation/screens/contact_support_screen.dart';
import 'package:attention_minder/module/legal/presentation/screens/terms_of_service_screen.dart';
import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _introText =
      'Welcome to ADHD Mentor! Your privacy is important to us. This Privacy Policy explains how we collect, use, and protect your personal information when you use our app. We are committed to safeguarding your privacy while providing a seamless experience to help you manage ADHD through our Cognitive Behavioral Therapy (CBT) tools.';

  static const _sections = [
    _PolicySection(
      title: 'Data Collection',
      content:
          'Personal Information: Your name, email address, and phone number when you create an account.',
      icon: Icons.fact_check_outlined,
      initiallyExpanded: true,
    ),
    _PolicySection(
      title: 'Data Usage',
      content:
          'We use your data to provide and improve our services, including personalizing your experience and communicating with you.',
      icon: Icons.insights_outlined,
    ),
    _PolicySection(
      title: 'User Rights',
      content:
          'You have the right to access, correct, or delete your personal information at any time.',
      icon: Icons.manage_accounts_outlined,
    ),
    _PolicySection(
      title: 'Security Practices',
      content:
          'We implement industry-standard security measures to protect your data from unauthorized access.',
      icon: Icons.lock_outline_rounded,
    ),
    _PolicySection(
      title: 'Legal Terms (in case of Terms and Conditions)',
      content:
          'Please refer to our Terms of Service for full legal details regarding the use of our application.',
      icon: Icons.gavel_outlined,
    ),
    _PolicySection(
      title: 'Data Usage',
      content: 'Additional details about data usage...',
      icon: Icons.data_usage_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final metrics = _PrivacyMetrics.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    metrics.pagePadding,
                    metrics.v(20),
                    metrics.pagePadding,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _PrivacyHeader(metrics: metrics),
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
                    child: _PrivacyHero(metrics: metrics),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    metrics.pagePadding,
                    metrics.v(18),
                    metrics.pagePadding,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _PolicyHighlights(metrics: metrics),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    metrics.pagePadding,
                    metrics.v(18),
                    metrics.pagePadding,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _PolicyIntro(metrics: metrics),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    metrics.pagePadding,
                    metrics.v(18),
                    metrics.pagePadding,
                    0,
                  ),
                  sliver: SliverList.separated(
                    itemBuilder: (context, index) {
                      final section = _sections[index];
                      return _PolicyAccordion(
                        section: section,
                        metrics: metrics,
                      );
                    },
                    separatorBuilder: (_, _) => SizedBox(height: metrics.v(10)),
                    itemCount: _sections.length,
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    metrics.pagePadding,
                    metrics.v(20),
                    metrics.pagePadding,
                    metrics.bottomPadding,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _PrivacyActions(metrics: metrics),
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

class _PrivacyMetrics {
  final double width;
  final double height;
  final double scale;
  final double heightScale;
  final double safeBottom;

  const _PrivacyMetrics({
    required this.width,
    required this.height,
    required this.scale,
    required this.heightScale,
    required this.safeBottom,
  });

  factory _PrivacyMetrics.of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return _PrivacyMetrics(
      width: size.width,
      height: size.height,
      scale: (size.width / 430).clamp(.82, 1.0).toDouble(),
      heightScale: (size.height / 844).clamp(.82, 1.0).toDouble(),
      safeBottom: MediaQuery.paddingOf(context).bottom,
    );
  }

  double get pagePadding => s(width < 360 ? 20 : 24);
  double get bottomPadding => safeBottom + v(118);

  double s(double value) => value * scale;
  double v(double value) => value * heightScale;

  double font(double value) {
    final scaled = value * scale;
    return scaled.clamp(value * .84, value).toDouble();
  }
}

class _PolicySection {
  final String title;
  final String content;
  final IconData icon;
  final bool initiallyExpanded;

  const _PolicySection({
    required this.title,
    required this.content,
    required this.icon,
    this.initiallyExpanded = false,
  });
}

class _PrivacyHeader extends StatelessWidget {
  final _PrivacyMetrics metrics;

  const _PrivacyHeader({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Privacy policy',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: const Color(0xFF071443),
        fontSize: metrics.font(20),
        fontFamily: 'Nunito Sans',
        fontWeight: FontWeight.w800,
        height: 1.1,
      ),
    );
  }
}

class _PrivacyHero extends StatelessWidget {
  final _PrivacyMetrics metrics;

  const _PrivacyHero({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        metrics.s(17),
        metrics.v(17),
        metrics.s(17),
        metrics.v(18),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(metrics.s(16)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF03102E), Color(0xFF0C3473)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0E3473).withValues(alpha: .16),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: metrics.s(52),
            height: metrics.s(52),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(metrics.s(14)),
              border: Border.all(color: Colors.white.withValues(alpha: .14)),
            ),
            child: Icon(
              Icons.privacy_tip_outlined,
              color: const Color(0xFF93C2FF),
              size: metrics.s(31),
            ),
          ),
          SizedBox(width: metrics.s(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your data stays protected',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: metrics.font(17),
                    fontFamily: 'Nunito Sans',
                    fontWeight: FontWeight.w800,
                    height: 1.18,
                  ),
                ),
                SizedBox(height: metrics.v(8)),
                Text(
                  'Review how ADHD Mentor collects, uses, and safeguards information while you use the app.',
                  style: TextStyle(
                    color: const Color(0xFFD2D9EA),
                    fontSize: metrics.font(12.3),
                    fontFamily: 'Nunito Sans',
                    fontWeight: FontWeight.w500,
                    height: 1.42,
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

class _PolicyHighlights extends StatelessWidget {
  final _PrivacyMetrics metrics;

  const _PolicyHighlights({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final highlights = [
      _HighlightData(
        icon: Icons.lock_outline_rounded,
        title: 'Secure',
        subtitle: 'Protected access',
      ),
      _HighlightData(
        icon: Icons.person_outline_rounded,
        title: 'Control',
        subtitle: 'Access your data',
      ),
      _HighlightData(
        icon: Icons.shield_outlined,
        title: 'Private',
        subtitle: 'Anonymized data',
      ),
    ];

    return Row(
      children: [
        for (var index = 0; index < highlights.length; index++) ...[
          Expanded(
            child: _HighlightCard(data: highlights[index], metrics: metrics),
          ),
          if (index != highlights.length - 1) SizedBox(width: metrics.s(9)),
        ],
      ],
    );
  }
}

class _HighlightData {
  final IconData icon;
  final String title;
  final String subtitle;

  const _HighlightData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _HighlightCard extends StatelessWidget {
  final _HighlightData data;
  final _PrivacyMetrics metrics;

  const _HighlightCard({required this.data, required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: metrics.v(91)),
      padding: EdgeInsets.symmetric(
        horizontal: metrics.s(9),
        vertical: metrics.v(11),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(metrics.s(13)),
        border: Border.all(color: const Color(0xFFE5EAF2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF20345D).withValues(alpha: .06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: metrics.s(34),
            height: metrics.s(34),
            decoration: const BoxDecoration(
              color: Color(0xFFEAF5FF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              data.icon,
              color: const Color(0xFF0F7FFF),
              size: metrics.s(19),
            ),
          ),
          SizedBox(height: metrics.v(9)),
          Text(
            data.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF071443),
              fontSize: metrics.font(12.5),
              fontFamily: 'Nunito Sans',
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          SizedBox(height: metrics.v(4)),
          Text(
            data.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF55627A),
              fontSize: metrics.font(10.5),
              fontFamily: 'Nunito Sans',
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyIntro extends StatelessWidget {
  final _PrivacyMetrics metrics;

  const _PolicyIntro({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(metrics.s(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(metrics.s(14)),
        border: Border.all(color: const Color(0xFFE5EAF2)),
      ),
      child: Text(
        PrivacyPolicyScreen._introText,
        style: TextStyle(
          color: const Color(0xFF48577C),
          fontSize: metrics.font(13.2),
          fontFamily: 'Nunito Sans',
          fontWeight: FontWeight.w500,
          height: 1.55,
        ),
      ),
    );
  }
}

class _PolicyAccordion extends StatelessWidget {
  final _PolicySection section;
  final _PrivacyMetrics metrics;

  const _PolicyAccordion({required this.section, required this.metrics});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(metrics.s(14)),
        border: Border.all(color: const Color(0xFFE5EAF2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF20345D).withValues(alpha: .055),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: const Color(0xFF0F7FFF).withValues(alpha: .06),
          highlightColor: const Color(0xFF0F7FFF).withValues(alpha: .04),
        ),
        child: ExpansionTile(
          initiallyExpanded: section.initiallyExpanded,
          maintainState: true,
          tilePadding: EdgeInsets.fromLTRB(
            metrics.s(14),
            metrics.v(2),
            metrics.s(12),
            metrics.v(2),
          ),
          childrenPadding: EdgeInsets.fromLTRB(
            metrics.s(68),
            0,
            metrics.s(15),
            metrics.v(15),
          ),
          iconColor: const Color(0xFF0F7FFF),
          collapsedIconColor: const Color(0xFF8A97AD),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(metrics.s(14)),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(metrics.s(14)),
          ),
          leading: Container(
            width: metrics.s(40),
            height: metrics.s(40),
            decoration: const BoxDecoration(
              color: Color(0xFFEAF5FF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              section.icon,
              color: const Color(0xFF0F7FFF),
              size: metrics.s(22),
            ),
          ),
          title: Text(
            section.title,
            style: TextStyle(
              color: const Color(0xFF071443),
              fontSize: metrics.font(14.2),
              fontFamily: 'Nunito Sans',
              fontWeight: FontWeight.w800,
              height: 1.22,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                section.content,
                style: TextStyle(
                  color: const Color(0xFF48577C),
                  fontSize: metrics.font(12.7),
                  fontFamily: 'Nunito Sans',
                  fontWeight: FontWeight.w500,
                  height: 1.48,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyActions extends StatelessWidget {
  final _PrivacyMetrics metrics;

  const _PrivacyActions({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final compact = metrics.width < 370;

    if (compact) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: _TermsButton(metrics: metrics),
          ),
          SizedBox(height: metrics.v(10)),
          SizedBox(
            width: double.infinity,
            child: _SupportButton(metrics: metrics),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _TermsButton(metrics: metrics)),
        SizedBox(width: metrics.s(10)),
        Expanded(child: _SupportButton(metrics: metrics)),
      ],
    );
  }
}

class _TermsButton extends StatelessWidget {
  final _PrivacyMetrics metrics;

  const _TermsButton({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const TermsOfServiceScreen()),
        );
      },
      style: OutlinedButton.styleFrom(
        minimumSize: Size(0, metrics.v(48)),
        side: const BorderSide(color: Color(0xFFD4E5FB)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(metrics.s(13)),
        ),
        foregroundColor: const Color(0xFF071443),
      ),
      child: Text(
        'Terms of Service',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: metrics.font(12.2),
          fontFamily: 'Nunito Sans',
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SupportButton extends StatelessWidget {
  final _PrivacyMetrics metrics;

  const _SupportButton({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const ContactSupportScreen()),
        );
      },
      style: ElevatedButton.styleFrom(
        minimumSize: Size(0, metrics.v(48)),
        backgroundColor: const Color(0xFF0F7FFF),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(metrics.s(13)),
        ),
      ),
      child: Text(
        'Contact Support',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: metrics.font(12.2),
          fontFamily: 'Nunito Sans',
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
