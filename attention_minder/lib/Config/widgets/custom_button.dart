import 'package:attention_minder/Config/Theme/App_color.dart';
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String title; // Button title
  final Color color; // Background color
  final VoidCallback onTap; // Tap callback

  const CustomButton({
    Key? key,
    required this.title,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8), // Rounded corners
        ),
        child: Center(
          child: Text(
            title,
            style: AppTextStyles.nunitoCenter.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
