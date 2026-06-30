import 'package:attention_minder/module/attention_management/presentation/screens/attention_program_overview_screen.dart';
import 'package:flutter/material.dart';

class AttentionWelcomeScreen extends StatelessWidget {
  const AttentionWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.06,
              vertical: screenHeight * 0.02,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: screenHeight * 0.08),

                // AI Brain Icon
                Container(
                  width: screenWidth * 0.3,
                  height: screenWidth * 0.3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF7C14A), Color(0xFFFFD54F)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF7C14A).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.psychology_outlined,
                    size: screenWidth * 0.15,
                    color: Colors.black,
                  ),
                ),

                SizedBox(height: screenHeight * 0.05),

                // Title
                Text(
                  'Attention Management\nUsing AI',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: screenWidth * 0.08,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                    color: Colors.white,
                  ),
                ),

                SizedBox(height: screenHeight * 0.03),

                // Subtitle
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFF7C14A).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    'AI-Powered Attention Improvement\nfor Kids and Adults',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                      color: Colors.white70,
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.04),

                // Description
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.05),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildFeatureItem(
                        screenWidth,
                        Icons.psychology,
                        'Smart AI Analysis',
                        'Personalized assessment using advanced AI technology',
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      _buildFeatureItem(
                        screenWidth,
                        Icons.timeline,
                        'Customized Program',
                        'Tailored 30-day attention improvement journey',
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      _buildFeatureItem(
                        screenWidth,
                        Icons.trending_up,
                        'Track Progress',
                        'Monitor your improvement with real-time insights',
                      ),
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.05),

                // Get Started Button
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AttentionProgramOverviewScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: screenHeight * 0.022),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3D7BFF),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3D7BFF).withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: screenWidth * 0.05,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: screenWidth * 0.06,
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),

                // Skip Text
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Not now',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      color: Colors.grey.shade500,
                      decoration: TextDecoration.underline,
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

  Widget _buildFeatureItem(
    double screenWidth,
    IconData icon,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF7C14A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.black,
            size: screenWidth * 0.06,
          ),
        ),
        SizedBox(width: screenWidth * 0.04),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFF7C14A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  color: Colors.white60,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
