import 'dart:async';

import 'package:attention_minder/Config/widgets/custom_bottom_navigation.dart';
import 'package:attention_minder/module/assigment/presentation/screens/assignment_screen.dart';
import 'package:attention_minder/module/home/presentation/screens/home_screen.dart';
import 'package:attention_minder/module/management/presentation/screens/management_screen.dart';
import 'package:attention_minder/module/profile/presentation/bloc/profile_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../result/presentation/screens/result_screen.dart';
import 'package:attention_minder/module/legal/presentation/screens/privacy_policy_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  static const String _walkthroughPreferenceKey = 'showHomeWalkthrough';

  int _currentIndex = 0;
  int _walkthroughStep = 0;
  bool _showWalkthrough = false;
  bool _exitArmed = false;
  Timer? _exitResetTimer;

  final _startAssessmentKey = GlobalKey();
  final _continueManagementKey = GlobalKey();
  final _attentionAssessmentKey = GlobalKey();
  final _attentionManagementKey = GlobalKey();
  final _navItemKeys = List<GlobalKey>.generate(5, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(GetTheProfileEvent());
    _loadWalkthroughPreference();
  }

  @override
  void dispose() {
    _exitResetTimer?.cancel();
    super.dispose();
  }

  void _handleDashboardBack() {
    if (_exitArmed) {
      _exitResetTimer?.cancel();
      SystemNavigator.pop(animated: true);
      return;
    }

    _exitArmed = true;
    _exitResetTimer?.cancel();
    _exitResetTimer = Timer(const Duration(seconds: 2), () {
      _exitArmed = false;
    });

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            88 + MediaQuery.paddingOf(context).bottom,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.white, size: 19),
              SizedBox(width: 10),
              Expanded(child: Text('Press back again to exit')),
            ],
          ),
        ),
      );
  }

  void _onItemTapped(int index) {
    if (_showWalkthrough) return;
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _loadWalkthroughPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final shouldShow = prefs.getBool(_walkthroughPreferenceKey) ?? false;
    if (!mounted || !shouldShow) return;

    setState(() {
      _currentIndex = 0;
      _showWalkthrough = true;
    });
  }

  Future<void> _completeWalkthrough() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_walkthroughPreferenceKey, false);
    if (!mounted) return;

    setState(() {
      _showWalkthrough = false;
      _walkthroughStep = 0;
    });
  }

  void _nextWalkthroughStep() {
    if (_walkthroughStep == _walkthroughSteps.length - 1) {
      _completeWalkthrough();
      return;
    }

    setState(() {
      _walkthroughStep += 1;
    });
  }

  List<Widget> get _pages => [
    HomeScreen(
      startAssessmentKey: _startAssessmentKey,
      continueManagementKey: _continueManagementKey,
      attentionAssessmentKey: _attentionAssessmentKey,
      attentionManagementKey: _attentionManagementKey,
    ),
    AssignmentScreen(showBackButton: false),
    ManagementScreen(showBackButton: false),
    ResultScreen(),
    PrivacyPolicyScreen(),
  ];

  List<_WalkthroughStep> get _walkthroughSteps => [
    _WalkthroughStep(
      key: _startAssessmentKey,
      number: 1,
      title: 'Start New Assessment',
      description:
          'Begin a new assessment to evaluate your attention and get personalized insights.',
      placement: _CalloutPlacement.below,
    ),
    _WalkthroughStep(
      key: _continueManagementKey,
      number: 2,
      title: 'Continue Attention Management',
      description:
          'Pick up where you left off and continue your attention training session.',
      placement: _CalloutPlacement.below,
    ),
    _WalkthroughStep(
      key: _attentionAssessmentKey,
      number: 3,
      title: 'Attention Assessment',
      description:
          'Measure your attention levels and track progress over time.',
      placement: _CalloutPlacement.below,
    ),
    _WalkthroughStep(
      key: _attentionManagementKey,
      number: 4,
      title: 'Attention Management',
      description:
          'Use activities and guided exercises to improve focus and concentration.',
      placement: _CalloutPlacement.below,
    ),
    _WalkthroughStep(
      key: _navItemKeys[3],
      number: 5,
      title: 'Results',
      description:
          'View your performance history and detailed results whenever you need them.',
      placement: _CalloutPlacement.above,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleDashboardBack();
      },
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(child: _pages[_currentIndex]),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CustomBottomNavigationBar(
                selectedIndex: _currentIndex,
                onItemTapped: _onItemTapped,
                itemKeys: _navItemKeys,
              ),
            ),
            if (_showWalkthrough)
              Positioned.fill(
                child: _HomeWalkthroughOverlay(
                  steps: _walkthroughSteps,
                  currentIndex: _walkthroughStep,
                  onNext: _nextWalkthroughStep,
                  onSkip: _completeWalkthrough,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum _CalloutPlacement { above, below }

class _WalkthroughStep {
  final GlobalKey key;
  final int number;
  final String title;
  final String description;
  final _CalloutPlacement placement;

  const _WalkthroughStep({
    required this.key,
    required this.number,
    required this.title,
    required this.description,
    required this.placement,
  });
}

class _HomeWalkthroughOverlay extends StatelessWidget {
  final List<_WalkthroughStep> steps;
  final int currentIndex;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _HomeWalkthroughOverlay({
    required this.steps,
    required this.currentIndex,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final currentRect = _targetRectFor(steps[currentIndex].key);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _WalkthroughScrimPainter(
                targetRect: currentRect,
                radius: 22,
              ),
            ),
          ),
          for (var index = 0; index < steps.length; index++)
            if (_targetRectFor(steps[index].key) != null)
              _TargetMarker(
                step: steps[index],
                rect: _targetRectFor(steps[index].key)!,
                isActive: index == currentIndex,
              ),
          if (currentRect != null)
            _WalkthroughCallout(
              step: steps[currentIndex],
              targetRect: currentRect,
              screenSize: size,
            ),
          _WalkthroughFooter(
            currentIndex: currentIndex,
            totalSteps: steps.length,
            onNext: onNext,
            onSkip: onSkip,
          ),
        ],
      ),
    );
  }

  Rect? _targetRectFor(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return null;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    final offset = renderObject.localToGlobal(Offset.zero);
    return offset & renderObject.size;
  }
}

class _WalkthroughScrimPainter extends CustomPainter {
  final Rect? targetRect;
  final double radius;

  const _WalkthroughScrimPainter({
    required this.targetRect,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: .58);
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size);

    if (targetRect != null) {
      path.addRRect(
        RRect.fromRectAndRadius(
          targetRect!.inflate(7),
          Radius.circular(radius),
        ),
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WalkthroughScrimPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect || oldDelegate.radius != radius;
  }
}

class _TargetMarker extends StatelessWidget {
  final _WalkthroughStep step;
  final Rect rect;
  final bool isActive;

  const _TargetMarker({
    required this.step,
    required this.rect,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final markerSize = isActive ? 30.0 : 26.0;
    final top = rect.top - markerSize * .5;
    final left = step.number == 5
        ? rect.left - markerSize * .5
        : rect.right - markerSize * .72;

    return Stack(
      children: [
        if (isActive)
          Positioned.fromRect(
            rect: rect.inflate(7),
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: .35),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        Positioned(
          left: left,
          top: top,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: markerSize,
            height: markerSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF0A84FF)
                  : const Color(0xFF758195),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .20),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              '${step.number}',
              style: TextStyle(
                color: Colors.white,
                fontSize: isActive ? 15 : 13,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WalkthroughCallout extends StatelessWidget {
  final _WalkthroughStep step;
  final Rect targetRect;
  final Size screenSize;

  const _WalkthroughCallout({
    required this.step,
    required this.targetRect,
    required this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = 24.0;
    final width = (targetRect.width + 42).clamp(260.0, screenSize.width - 48);
    final left = (targetRect.center.dx - width / 2).clamp(
      horizontalPadding,
      screenSize.width - width - horizontalPadding,
    );
    final top = step.placement == _CalloutPlacement.below
        ? targetRect.bottom + 18
        : targetRect.top - 122;
    final clampedTop = top.clamp(88.0, screenSize.height - 198);

    return Positioned(
      left: left,
      top: clampedTop,
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (step.placement == _CalloutPlacement.below)
            _CalloutArrow(
              up: true,
              width: width,
              targetCenterX: targetRect.center.dx - left,
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FBFF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E7F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .16),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    step.title,
                    style: const TextStyle(
                      color: Color(0xFF07123A),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    step.description,
                    style: const TextStyle(
                      color: Color(0xFF1D2A57),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.22,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (step.placement == _CalloutPlacement.above)
            _CalloutArrow(
              up: false,
              width: width,
              targetCenterX: targetRect.center.dx - left,
            ),
        ],
      ),
    );
  }
}

class _CalloutArrow extends StatelessWidget {
  final bool up;
  final double width;
  final double targetCenterX;

  const _CalloutArrow({
    required this.up,
    required this.width,
    required this.targetCenterX,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 14,
      child: Align(
        alignment: Alignment(
          ((targetCenterX / width) * 2 - 1).clamp(-.82, .82),
          0,
        ),
        child: CustomPaint(
          size: const Size(24, 14),
          painter: _CalloutArrowPainter(up: up),
        ),
      ),
    );
  }
}

class _CalloutArrowPainter extends CustomPainter {
  final bool up;

  const _CalloutArrowPainter({required this.up});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (up) {
      path
        ..moveTo(size.width / 2, 0)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
    } else {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close();
    }
    canvas.drawPath(path, Paint()..color = const Color(0xFFF8FBFF));
  }

  @override
  bool shouldRepaint(covariant _CalloutArrowPainter oldDelegate) {
    return oldDelegate.up != up;
  }
}

class _WalkthroughFooter extends StatelessWidget {
  final int currentIndex;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _WalkthroughFooter({
    required this.currentIndex,
    required this.totalSteps,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(28, 14, 28, 14 + bottomPadding),
        color: Colors.black.withValues(alpha: .18),
        child: Row(
          children: [
            TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2F9BFF),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: const Text('Skip'),
            ),
            const Spacer(),
            Row(
              children: [
                for (var index = 0; index < totalSteps; index++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: index == currentIndex ? 12 : 8,
                    height: index == currentIndex ? 12 : 8,
                    margin: const EdgeInsets.symmetric(horizontal: 7),
                    decoration: BoxDecoration(
                      color: index == currentIndex
                          ? const Color(0xFF0A84FF)
                          : Colors.white.withValues(alpha: .28),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: 96,
              height: 52,
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFF0A84FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                child: Text(currentIndex == totalSteps - 1 ? 'Done' : 'Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
