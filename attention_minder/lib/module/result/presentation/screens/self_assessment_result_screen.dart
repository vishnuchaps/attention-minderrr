import 'package:attention_minder/Config/widgets/custom_bottom_navigation.dart';
import 'package:attention_minder/dependency_injection/injection_container.dart';
import 'package:attention_minder/module/assigment/presentation/bloc/assignment_bloc.dart';
import 'package:attention_minder/module/assigment/presentation/screens/questionnaire_screen.dart';
import 'package:attention_minder/module/landing/presentation/screens/landing_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SelfAssessmentResultScreen extends StatefulWidget {
  const SelfAssessmentResultScreen({super.key});

  @override
  State<SelfAssessmentResultScreen> createState() =>
      _SelfAssessmentResultScreenState();
}

class _SelfAssessmentResultScreenState
    extends State<SelfAssessmentResultScreen> {
  final AssignmentBloc _assignmentBloc = getIt<AssignmentBloc>();
  String _username = "User";

  @override
  void initState() {
    super.initState();
    _loadUsername();
    // Fetch result to show in this screen
    _assignmentBloc.add(FetchAssessmentResults());
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? "User";
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _assignmentBloc,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(),
                  const SizedBox(height: 30),
                  _buildSummaryHeader(),
                  const SizedBox(height: 10),
                  _buildResultsData(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Attention Self Assessment Results",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E1E1E),
          ),
        ),
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF0F78FE),
            shape: BoxShape.circle,
          ),
        )
      ],
    );
  }

  Widget _buildSummaryHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Here's a summary of your assessment",
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF1E1E1E),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEEEEEE),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "$_username,",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E1E1E),
                        ),
                      ),
                      // Date hardcoded or dynamic? Using mock for now per design
                      const Text(
                        "30-12-2024",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "Your scores are visualized below",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                ],
              )
              // Add cloud visual here if assets available
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultsData() {
    return BlocBuilder<AssignmentBloc, AssignmentState>(
      builder: (context, state) {
        // Mock data logic for visualization, mirroring functionality
        final score = "8";
        final inattention = "06";

        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF333333),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text(
                    "Overall score",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: score,
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F78FE),
                              ),
                            ),
                            const TextSpan(
                              text: "/10",
                              style: TextStyle(
                                fontSize: 18,
                                color: Color(0xFF0F78FE),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Inattention",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(width: 5),
                      Icon(Icons.info_outline,
                          color: Colors.amber[700], size: 16),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    inattention,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Bar indicator
                  Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(
                        width: 20,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        width: 20,
                        height: 40, // proportional height
                        decoration: BoxDecoration(
                          color: Colors.amber[700],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      // Dotted line mockup
                      Container(
                        height: 1,
                        width: 100,
                        color: Colors.amber[700]!.withOpacity(0.5),
                      )
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFCE3AD).withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFCE3AD)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "What best for you",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                          fontSize: 14, color: Colors.black, height: 1.5),
                      children: [
                        TextSpan(text: "You will feel better with "),
                        TextSpan(
                          text: "attention management using AI ",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline),
                        ),
                        TextSpan(text: "module within the app"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const QuestionnaireScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F78FE),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Retake assessment",
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  // Navigate to Landing Screen (Home/Dashboard)
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LandingScreen()),
                      (route) => false);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Back to home",
                    style: TextStyle(color: Color(0xFF0F78FE), fontSize: 16)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        );
      },
    );
  }
}
