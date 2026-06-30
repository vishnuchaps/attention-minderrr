import 'package:attention_minder/module/others/presentation/screens/privacy_policy_screen.dart';
import 'package:flutter/material.dart';
class TermsAndConditionScreen extends StatelessWidget {
  const TermsAndConditionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body: SafeArea(
        child: GestureDetector(
          onTap: (){
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PrivacyPolicyScreen()),
            );
          },
          child: Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('asset/images/terms.png'), // Path to your image
                fit: BoxFit.fill, // Adjusts how the image fits the container
              ),
            ),
            child: const SizedBox(),),
        ),
      ),
    );
  }
}
