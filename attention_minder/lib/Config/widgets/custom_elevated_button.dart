import 'package:attention_minder/constant/colors.dart';
import 'package:attention_minder/constant/text_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomElevatedbutton extends StatelessWidget {
  const CustomElevatedbutton({
    super.key,
    required this.width,
    required this.label,
    this.callBack,
    this.child, // Add this optional child property
  });

  final double width;
  final String label;
  final void Function()? callBack;
  final Widget? child; // The widget to display inside the button

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 49,
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          radius: 4,
          colors: [
            Color(0xFF4883F7),
            Color(0xFF4883F7),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ElevatedButton(
        style: ButtonStyle(
          shadowColor: WidgetStatePropertyAll(AppColor.transparentColor),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10))),
          overlayColor: WidgetStatePropertyAll(AppColor.transparentColor),
          surfaceTintColor: WidgetStatePropertyAll(AppColor.transparentColor),
          backgroundColor: WidgetStatePropertyAll(AppColor.transparentColor),
        ),
        onPressed: callBack,
        child: child ?? // Display the child if provided, otherwise the label
            Text(
              label,
              style: TextStyles.poppinsM14Black.copyWith(
                color: const Color(0xFFF6F7FA),
              ),
            ),
      ),
    );
  }
}