import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

typedef InternetProbe = Future<bool> Function();

class InternetConnectionGate extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;
  final InternetProbe? probe;

  const InternetConnectionGate({
    super.key,
    required this.child,
    required this.navigatorKey,
    this.probe,
  });

  @override
  State<InternetConnectionGate> createState() => _InternetConnectionGateState();
}

class _InternetConnectionGateState extends State<InternetConnectionGate>
    with WidgetsBindingObserver {
  Timer? _nextCheckTimer;
  bool? _isOnline;
  bool _isChecking = false;

  InternetProbe get _probe => widget.probe ?? _hasInternetAccess;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_checkConnection());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nextCheckTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _nextCheckTimer?.cancel();
      unawaited(_checkConnection());
    }
  }

  Future<void> _checkConnection() async {
    if (_isChecking) return;
    _nextCheckTimer?.cancel();
    if (mounted) setState(() => _isChecking = true);

    final isOnline = await _probe();
    if (!mounted) return;

    setState(() {
      _isOnline = isOnline;
      _isChecking = false;
    });
    _nextCheckTimer = Timer(
      isOnline ? const Duration(seconds: 10) : const Duration(seconds: 3),
      _checkConnection,
    );
  }

  void _handleBack() {
    final navigator = widget.navigatorKey.currentState;
    if (navigator?.canPop() ?? false) {
      navigator!.maybePop();
      return;
    }
    SystemNavigator.pop(animated: true);
  }

  @override
  Widget build(BuildContext context) {
    final offline = _isOnline == false;

    return PopScope(
      canPop: !offline,
      onPopInvokedWithResult: (didPop, result) {
        if (offline && !didPop) _handleBack();
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          if (offline)
            Positioned.fill(
              child: _NoInternetScreen(
                isChecking: _isChecking,
                onRetry: _checkConnection,
                onBack: _handleBack,
              ),
            ),
        ],
      ),
    );
  }
}

Future<bool> _hasInternetAccess() async {
  const probeUris = <String>[
    'https://connectivitycheck.gstatic.com/generate_204',
    'https://www.cloudflare.com/cdn-cgi/trace',
  ];

  try {
    final results = await Future.wait(
      probeUris.map(_probeUri),
    ).timeout(const Duration(seconds: 4), onTimeout: () => [false, false]);
    return results.any((result) => result);
  } catch (_) {
    return false;
  }
}

Future<bool> _probeUri(String value) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
  try {
    final request = await client.getUrl(Uri.parse(value));
    request.followRedirects = false;
    final response = await request.close().timeout(const Duration(seconds: 3));
    await response.drain<void>();
    return response.statusCode >= 200 && response.statusCode < 400;
  } catch (_) {
    return false;
  } finally {
    client.close(force: true);
  }
}

class _NoInternetScreen extends StatelessWidget {
  static const _ink = Color(0xFF061A4D);
  static const _muted = Color(0xFF667394);
  static const _blue = Color(0xFF246BFD);

  final bool isChecking;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  const _NoInternetScreen({
    required this.isChecking,
    required this.onRetry,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compactHeight = constraints.maxHeight < 720;
            final veryCompactHeight = constraints.maxHeight < 620;
            final horizontalPadding = (constraints.maxWidth * .05)
                .clamp(16.0, 24.0)
                .toDouble();

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                compactHeight ? 12 : 18,
                horizontalPadding,
                24 + MediaQuery.paddingOf(context).bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      constraints.maxHeight -
                      (compactHeight ? 36 : 42) -
                      MediaQuery.paddingOf(context).bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _BackButton(onPressed: onBack),
                    ),
                    SizedBox(height: veryCompactHeight ? 12 : 28),
                    _OfflineIllustration(
                      size: veryCompactHeight
                          ? 134
                          : compactHeight
                          ? 166
                          : 200,
                    ),
                    SizedBox(height: compactHeight ? 22 : 32),
                    Text(
                      'No Internet Connection',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: compactHeight ? 24 : 27,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                        height: 1.2,
                        letterSpacing: -.5,
                      ),
                    ),
                    SizedBox(height: compactHeight ? 10 : 14),
                    Text(
                      'You’re offline. Check your internet connection and try '
                      'again.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: compactHeight ? 12.5 : 13.5,
                        fontWeight: FontWeight.w400,
                        color: _muted,
                        height: 1.55,
                      ),
                    ),
                    SizedBox(height: compactHeight ? 22 : 30),
                    SizedBox(
                      height: compactHeight ? 52 : 56,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: isChecking
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF8AADF5),
                                    Color(0xFF8AADF5),
                                  ],
                                )
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFF2C76FF),
                                    Color(0xFF1E5FF0),
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: isChecking
                              ? null
                              : [
                                  BoxShadow(
                                    color: _blue.withValues(alpha: .22),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                        ),
                        child: ElevatedButton(
                          onPressed: isChecking ? null : onRetry,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            disabledBackgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            disabledForegroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: isChecking
                                ? const SizedBox(
                                    key: ValueKey('checking'),
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.3,
                                    ),
                                  )
                                : Row(
                                    key: const ValueKey('retry'),
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.refresh_rounded,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Try Again',
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: compactHeight ? 24 : 38),
                    const _ConnectionTipCard(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ConnectionTipCard extends StatelessWidget {
  const _ConnectionTipCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: _NoInternetScreen._blue,
              size: 22,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tip',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _NoInternetScreen._ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Check Wi‑Fi, mobile data, or airplane mode and try again.',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                    color: _NoInternetScreen._muted,
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

class _BackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _BackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F9FD),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: _NoInternetScreen._ink,
          ),
        ),
      ),
    );
  }
}

class _OfflineIllustration extends StatelessWidget {
  final double size;

  const _OfflineIllustration({required this.size});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size * .9,
              height: size * .72,
              decoration: BoxDecoration(
                color: const Color(0xFFEDF3FF),
                borderRadius: BorderRadius.circular(size * .32),
              ),
            ),
            Icon(
              Icons.wifi_off_rounded,
              color: _NoInternetScreen._blue,
              size: size * .55,
            ),
            Positioned(
              right: size * .08,
              bottom: size * .13,
              child: Container(
                width: size * .27,
                height: size * .27,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6072),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFFE6E9),
                    width: size * .035,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6072).withValues(alpha: .2),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.priority_high_rounded,
                  color: Colors.white,
                  size: size * .16,
                ),
              ),
            ),
            _Sparkle(
              alignment: const Alignment(-.9, -.6),
              color: const Color(0xFF8A63EF),
              size: size * .09,
            ),
            _Sparkle(
              alignment: const Alignment(.9, -.45),
              color: const Color(0xFF4A8AF7),
              size: size * .09,
            ),
          ],
        ),
      ),
    );
  }
}

class _Sparkle extends StatelessWidget {
  final Alignment alignment;
  final Color color;
  final double size;

  const _Sparkle({
    required this.alignment,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Icon(Icons.auto_awesome_rounded, color: color, size: size),
    );
  }
}
