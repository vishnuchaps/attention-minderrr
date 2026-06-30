import 'package:flutter/material.dart';

class TextCardWidget extends StatelessWidget {
  final String text;
  final String subTitle;

  const TextCardWidget({
    super.key,
    required this.text,
    required this.subTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 18,
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: ShapeDecoration(
            color: const Color(0xFFE4ECF5),
            shape: RoundedRectangleBorder(
              side: const BorderSide(width: 1, color: Color(0xFF86C4FF)),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: Text(
            '$text:',
            style: const TextStyle(
              color: Color(0xFF1E1E1E),
              fontSize: 10,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w400,
              height: 1.40,
            ),
          ),
        ),
        const SizedBox(height: 10,),
        Text(
         subTitle,
          style: const TextStyle(
            color: Color(0xFF565656),
            fontSize: 12,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w400,
            height: 1.40,
          ),
        ),
        const SizedBox(height: 10,),


      ],
    );
  }
}
