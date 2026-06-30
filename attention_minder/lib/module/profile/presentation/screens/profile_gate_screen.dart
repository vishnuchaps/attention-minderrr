import 'package:attention_minder/module/landing/presentation/screens/landing_screen.dart';
import 'package:attention_minder/module/profile/presentation/bloc/profile_bloc.dart';
import 'package:attention_minder/module/profile/presentation/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileGateScreen extends StatefulWidget {
  const ProfileGateScreen({super.key});

  @override
  State<ProfileGateScreen> createState() => _ProfileGateScreenState();
}

class _ProfileGateScreenState extends State<ProfileGateScreen> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(GetTheProfileEvent());
  }

  void _openNextScreen(Widget screen) {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => screen));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      body: SafeArea(
        child: BlocConsumer<ProfileBloc, ProfileState>(
          listenWhen: (previous, current) {
            return !_hasNavigated &&
                (current is FetchProfileSuccess ||
                    current is FetchProfileFailed);
          },
          listener: (context, state) {
            if (state is FetchProfileSuccess) {
              _openNextScreen(
                state.data.isCompleted
                    ? const LandingScreen()
                    : ProfileScreen(),
              );
            }
          },
          builder: (context, state) {
            if (state is FetchProfileFailed) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFDC2626),
                      size: 40,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Unable to load your profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF07123A),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF59627D),
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 22),
                    ElevatedButton(
                      onPressed: () {
                        _hasNavigated = false;
                        context.read<ProfileBloc>().add(GetTheProfileEvent());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A84FF),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Retry',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              );
            }

            return const SizedBox.expand();
          },
        ),
      ),
    );
  }
}
