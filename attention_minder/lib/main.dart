import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:attention_minder/module/assigment/presentation/bloc/assignment_bloc.dart';
import 'package:attention_minder/module/attention_management/presentation/bloc/attention_management_bloc.dart';
import 'package:attention_minder/module/attention_management/presentation/bloc/ai_assessment_score_bloc.dart';
import 'package:attention_minder/module/file_handler/presentation/bloc/file_handler_bloc.dart';
import 'package:attention_minder/module/home/presentation/bloc/progress_bloc.dart';
import 'package:attention_minder/module/payments/presentation/screens/payment_result_screen.dart';
import 'package:attention_minder/module/splash/presentation/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'Config/Theme/App_color.dart';
import 'Config/widgets/user_profile_avatar_widget.dart';
import 'dependency_injection/injection_container.dart';
import 'module/authentication/presentation/bloc/authentication_bloc.dart';
import 'module/profile/presentation/bloc/profile_bloc.dart';

import 'firebase_options.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  await getIt.allReady();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  String? _lastHandledLink;

  @override
  void initState() {
    super.initState();
    _initPaymentLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initPaymentLinks() async {
    _linkSubscription = _appLinks.uriLinkStream.listen(_handleIncomingLink);

    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleIncomingLink(initialLink, waitForSplash: true);
      }
    } catch (_) {
      // Deep-link startup should never block the normal app launch.
    }
  }

  void _handleIncomingLink(Uri uri, {bool waitForSplash = false}) {
    final status = _paymentStatusFromUri(uri);
    if (status == null) {
      return;
    }

    final linkKey = uri.toString();
    if (_lastHandledLink == linkKey) {
      return;
    }
    _lastHandledLink = linkKey;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (waitForSplash) {
        await Future<void>.delayed(const Duration(milliseconds: 2300));
      }

      final navigator = appNavigatorKey.currentState;
      if (navigator == null) {
        return;
      }

      navigator.push(
        MaterialPageRoute(builder: (_) => PaymentResultScreen(status: status)),
      );
    });
  }

  PaymentResultStatus? _paymentStatusFromUri(Uri uri) {
    if (_isAppPaymentUri(uri)) {
      return _statusFromPath(uri.path);
    }

    if (_isBackendPaymentUri(uri)) {
      return _statusFromPath(uri.path);
    }

    return null;
  }

  bool _isAppPaymentUri(Uri uri) {
    if (uri.scheme != 'attentionminder') {
      return false;
    }

    return uri.host == 'payment' || uri.host == 'payments';
  }

  bool _isBackendPaymentUri(Uri uri) {
    final isHttp = uri.scheme == 'http' || uri.scheme == 'https';
    if (!isHttp || uri.host != '13.217.234.177') {
      return false;
    }

    return uri.path.startsWith('/payment/success') ||
        uri.path.startsWith('/payment/cancel');
  }

  PaymentResultStatus? _statusFromPath(String path) {
    final normalizedPath = path.toLowerCase();
    if (normalizedPath.contains('success')) {
      return PaymentResultStatus.success;
    }
    if (normalizedPath.contains('cancel') ||
        normalizedPath.contains('failed') ||
        normalizedPath.contains('failure')) {
      return PaymentResultStatus.failed;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final AuthenticationBloc authenticationBloc = getIt<AuthenticationBloc>();
    final ProfileBloc profileBloc = getIt<ProfileBloc>();
    final AssignmentBloc assignmentBloc = getIt<AssignmentBloc>();
    final AttentionManagementBloc attentionManagementBloc =
        getIt<AttentionManagementBloc>();
    final AiAssessmentScoreBloc aiAssessmentScoreBloc =
        getIt<AiAssessmentScoreBloc>();
    final FileHandlerBloc fileHandlerBloc = getIt<FileHandlerBloc>();
    final ProgressBloc progressBloc = getIt<ProgressBloc>();

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (BuildContext context) => authenticationBloc),
        BlocProvider(create: (BuildContext context) => profileBloc),
        BlocProvider(create: (BuildContext context) => assignmentBloc),
        BlocProvider(create: (BuildContext context) => attentionManagementBloc),
        BlocProvider(create: (BuildContext context) => aiAssessmentScoreBloc),
        BlocProvider(create: (BuildContext context) => fileHandlerBloc),
        BlocProvider(create: (BuildContext context) => fileHandlerBloc),
        BlocProvider(create: (BuildContext context) => progressBloc),
      ],
      child: MaterialApp(
        navigatorKey: appNavigatorKey,
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      ),
    );
  }
}

class AttentionProgramScreen extends StatelessWidget {
  const AttentionProgramScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(child: _content()),
            _bottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const UserProfileAvatar(size: 40),
        ],
      ),
    );
  }

  Widget _content() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Text(
            "Attention management using AI",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "This is your personal program based on\nThe assessment you have taken",
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          _daySelector(),
          const SizedBox(height: 24),
          Expanded(child: _taskSection()),
        ],
      ),
    );
  }

  Widget _daySelector() {
    return Row(
      children: [
        _dayCard("Day 1", active: true),
        _dayCard("Day 2"),
        _dayCard("Day 3", locked: true),
        _dayCard("Day 4", locked: true),
      ],
    );
  }

  Widget _dayCard(String text, {bool active = false, bool locked = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: active ? const Color(0xFFF7C14A) : Colors.grey.shade800,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  color: active ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (active)
            const Padding(
              padding: EdgeInsets.all(8),
              child: CircleAvatar(radius: 3, backgroundColor: Colors.black),
            ),
          if (locked)
            const Padding(
              padding: EdgeInsets.all(8),
              child: CircleAvatar(
                radius: 10,
                backgroundColor: Color(0xFFF7C14A),
                child: Icon(Icons.lock, size: 12, color: Colors.black),
              ),
            ),
        ],
      ),
    );
  }

  Widget _taskSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _progressLine(),
        const SizedBox(width: 12),
        Expanded(
          child: ListView(
            children: [
              _taskTile(
                "Understanding attention and reasons for attention loss.",
                completed: true,
              ),
              _taskTile("Attention improvement using AI", play: true),
              _taskTile("Goal setting", locked: true),
              const SizedBox(height: 12),
              const Text(
                "Take a break ☀️",
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              _taskTile("Item one", play: true),
              _taskTile("Item two", play: true),
              _taskTile("Item three", play: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _progressLine() {
    return Column(
      children: [
        Container(width: 4, height: 120, color: Colors.blue),
        const SizedBox(height: 8),
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
        Container(width: 4, height: 200, color: Colors.grey.shade700),
      ],
    );
  }

  Widget _taskTile(
    String title, {
    bool completed = false,
    bool play = false,
    bool locked = false,
  }) {
    IconData icon = Icons.play_arrow;
    Color iconBg = const Color(0xFFF7C14A);

    if (completed) {
      icon = Icons.check;
      iconBg = const Color(0xFFF7C14A);
    } else if (locked) {
      icon = Icons.lock;
      iconBg = Colors.grey.shade700;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(title, style: const TextStyle(color: Colors.white)),
            ),
            CircleAvatar(
              radius: 16,
              backgroundColor: iconBg,
              child: Icon(icon, color: Colors.black, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 56,
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3D7BFF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: () {},
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Next", style: TextStyle(fontSize: 16)),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward),
            ],
          ),
        ),
      ),
    );
  }
}
