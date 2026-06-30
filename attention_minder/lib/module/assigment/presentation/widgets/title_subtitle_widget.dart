import 'package:flutter/material.dart';

class TitleSubtitleWidget extends StatelessWidget {
  final String title;
  final String subTitle;

  const TitleSubtitleWidget({
    super.key,
    required this.subTitle,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            )),
        const SizedBox(
          height: 10,
        ),
        Text(
          subTitle,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
            )),
        const SizedBox(
          height: 14,
        ),
      ],
    );
  }
}
