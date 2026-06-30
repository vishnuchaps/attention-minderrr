import 'package:attention_minder/Config/widgets/user_profile_header_widget.dart'
    show UserProfileHeader;
import 'package:attention_minder/constant/spaces.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SingleResultScreen extends StatelessWidget {
  const SingleResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const UserProfileHeader(
              username: "ADHD Assessment Results",
              style: TextStyle(
                color: Color(0xFF2F2F2F),
                fontSize: 17,
                fontFamily: 'Nunito Sans',
                fontWeight: FontWeight.w500,
                height: 1.40,
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(15.0),
              child: Text(
                "Here’s a summary of your assessment",
                style: TextStyle(
                  fontFamily: 'Nunito Sans',
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                  height: 20 / 13, // line-height divided by font-size
                  letterSpacing: 0,
                  color: Colors
                      .black, // Since background is black, text should be white
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 15.0, right: 15),
              child: Container(
                width: double.infinity,
                height: 99,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBEBEB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Add your child widgets here
                        Text(
                          "Dane,",
                          style: TextStyle(
                            fontFamily: 'Nunito Sans',
                            fontWeight: FontWeight.w400,
                            fontSize: 13,
                            height: 20 / 13,
                            letterSpacing: 0,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          "30-12-2024",
                          style: TextStyle(
                            fontFamily: 'Nunito Sans',
                            fontWeight: FontWeight.w400,
                            fontSize: 13,
                            height: 20 / 13,
                            letterSpacing: 0,
                            color: Colors.black,
                          ),
                        ),
                        // You can add another widget to the right if needed
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Container(
                height: 391,
                width: 370,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E2C29),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Overall Score",
                      style: TextStyle(
                        fontFamily: 'Nunito Sans',
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: 152,
                      height: 152,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: '8',
                              style: TextStyle(
                                fontFamily: 'Nunito Sans',
                                fontWeight: FontWeight.w800,
                                fontSize: 64,
                                color: Color(0xFF0F79FF),
                              ),
                            ),
                            TextSpan(
                              text: '/10',
                              style: TextStyle(
                                fontFamily: 'Nunito Sans',
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                                color: Color(0xFF0F79FF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _iconWithGraph('Inattention', Icons.access_time, 0.6),
                        _iconWithGraph('Hyperactivity', Icons.access_time, 0.8),
                        _iconWithGraph('Impulsivity', Icons.access_time, 0.4),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconWithGraph(String label, IconData icon, double graphValue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Nunito Sans',
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Color(0xFF8B8B8B),
              ),
            ),
            const SizedBox(width: 5),
            Icon(icon, color: Color.fromRGBO(255, 182, 29, 0.52), size: 20),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: 60, // give room for left + right dots + center bar
          height: 60,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Bar column in the center (only 12px wide)
              Positioned(
                left: (60 - 12) / 2,
                child: Container(
                  width: 12,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: FractionallySizedBox(
                    heightFactor: graphValue,
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Color(0xFFC19334), // bottom color
                            Color(0xFFFFD700), // top color (bright gold)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ),

              // Dotted line + yellow rectangle
              Positioned(
                bottom: 60 * graphValue - 5.22,
                left: 0,
                right: 0,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // 👈 prevents overflow
                    children: [
                      // Left dots
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(4, (_) => _buildDot()),
                      ),
                      const SizedBox(width: 4),

                      // Center yellow rectangle
                      Container(
                        width: 19.88,
                        height: 5.22,
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(255, 255, 255, 0.27),
                          border: Border.all(color: Colors.white, width: 0.4),
                          borderRadius: BorderRadius.circular(1.53),
                        ),
                      ),

                      const SizedBox(width: 4),

                      // Right dots
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(4, (_) => _buildDot()),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDot() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      width: 4,
      height: 2,
      decoration: const BoxDecoration(
        color: Color(0xFFFFB61D),
        shape: BoxShape.circle,
      ),
    );
  }
}
