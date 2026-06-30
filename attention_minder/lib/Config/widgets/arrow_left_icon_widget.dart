import 'package:attention_minder/constant/asset_path.dart';
import 'package:flutter/material.dart';
class ArrowLeftIconWidget extends StatelessWidget {
  final VoidCallback callback;
  const ArrowLeftIconWidget({super.key,required this.callback,});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FA), // Background color
        borderRadius: BorderRadius.circular(10), // Circular button
      ),
      child: IconButton(
        icon: Image.asset(
          arrowLeftIcon, // Path to the back arrow PNG icon
          width: 24, // Size of the icon
          height: 24,
        ),
        onPressed: callback,
        padding: EdgeInsets.zero, // Remove default padding
      ),
    );
  }
}
