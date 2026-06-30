import 'package:flutter/material.dart';

class YellowTestCardWidget extends StatelessWidget {
  final String title;
  final String subTitle;

  const YellowTestCardWidget({
    super.key,
    required this.title,
    required this.subTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 63,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: ShapeDecoration(
        color: const Color(0xFFF1E6D0),
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: Color(0xFFFFCD65)),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title:',
            style: const TextStyle(
              color: Color(0xFF7C580B),
              fontSize: 10,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              height: 1.40,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: Text(
              subTitle,
              style: const TextStyle(
                color: Color(0xFF1E1E1E),
                fontSize: 10,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w400,
                height: 1.40,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
