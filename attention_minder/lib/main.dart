import 'package:attention_minder/module/assigment/presentation/bloc/assignment_bloc.dart';
import 'package:attention_minder/module/attention_management/presentation/bloc/attention_management_bloc.dart';
import 'package:attention_minder/module/file_handler/presentation/bloc/file_handler_bloc.dart';
import 'package:attention_minder/module/home/presentation/bloc/progress_bloc.dart';
import 'package:attention_minder/module/splash/presentation/screens/splash_screen.dart';
import 'package:attention_minder/service/treatment_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'Config/Theme/App_color.dart';
import 'Config/widgets/user_profile_avatar_widget.dart';
import 'dependency_injection/injection_container.dart';
import 'module/authentication/presentation/bloc/authentication_bloc.dart';
import 'module/profile/presentation/bloc/profile_bloc.dart';
import 'module/result/presentation/screens/single_result_screen.dart'
    show SingleResultScreen;

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  await getIt.allReady();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthenticationBloc authenticationBloc = getIt<AuthenticationBloc>();
    final ProfileBloc profileBloc = getIt<ProfileBloc>();
    final AssignmentBloc assignmentBloc = getIt<AssignmentBloc>();
    final AttentionManagementBloc attentionManagementBloc =
        getIt<AttentionManagementBloc>();
    final FileHandlerBloc fileHandlerBloc = getIt<FileHandlerBloc>();
    final ProgressBloc progressBloc = getIt<ProgressBloc>();

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (BuildContext context) => authenticationBloc),
        BlocProvider(create: (BuildContext context) => profileBloc),
        BlocProvider(create: (BuildContext context) => assignmentBloc),
        BlocProvider(create: (BuildContext context) => attentionManagementBloc),
        BlocProvider(create: (BuildContext context) => fileHandlerBloc),
        BlocProvider(create: (BuildContext context) => fileHandlerBloc),
        BlocProvider(create: (BuildContext context) => progressBloc),
      ],
      child: MaterialApp(
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
              color: Colors.white.withOpacity(.1),
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
