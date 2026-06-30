import 'package:attention_minder/module/on_boarding/presentation/screens/on_boarding_screen.dart';
import 'package:flutter/material.dart';
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen ({super.key});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body: SafeArea(
        child: GestureDetector(
          onTap: (){
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => OnBoardingScreen()),
            );
          },
          child: Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('asset/images/privacy policy.png'), // Path to your image
                fit: BoxFit.fill, // Adjusts how the image fits the container
              ),
            ),
            child: const SizedBox(),),
        ),
      ),
    );
  }
}
