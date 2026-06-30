import 'package:attention_minder/Config/Theme/Text_style.dart';
import 'package:attention_minder/Config/widgets/custom_button.dart';
import 'package:attention_minder/constant/asset_path.dart';
import 'package:attention_minder/module/authentication/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';

class OnBoardingScreen extends StatelessWidget {
  const OnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: gradientDecoration,
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: screenHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: screenHeight * 0.02),
                    child: Stack(
                      children: [
                        Image.asset(
                          backgroundVector,
                          width: double.infinity,
                          height: screenHeight * 0.25,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          top: screenHeight * 0.08,
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Image.asset(
                                leftRectangleColor,
                                height: screenHeight * 0.2,
                                fit: BoxFit.contain,
                              ),
                              const Spacer(),
                              Image.asset(
                                onBoardingImage,
                                height: screenHeight * 0.35,
                                fit: BoxFit.contain,
                              ),
                              const Spacer(),
                              Image.asset(
                                rightRectangleColor,
                                height: screenHeight * 0.2,
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.05),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.01,
                    ),
                    child: Text(
                      "Welcome to Attention Minder.\n\n"
                      "Attention Minder is your AI-powered guide to better concentration—for kids and adults alike."
                      "Whether you're learning or working, our app helps you take control of your focus with a personalized journey.\n"
                      "Start with a quick assessment using our smart questionnaire and AI engine. "
                      "Based on your attention profile, you'll begin an AI-powered, structured concentration management program.",
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.normal,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: CustomButton(
                      title: 'Get Started',
                      color: const Color(0xFF0F79FF),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
