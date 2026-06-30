import 'package:attention_minder/constant/asset_path.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class HomeCardWidget extends StatelessWidget {
  final Color color;
  final String text;
  final String icon;

  const HomeCardWidget({
    super.key,
    required this.color,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      height: 96,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: ShapeDecoration(
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          SizedBox(
            width: 21,
            height: 21,
            child: SvgPicture.asset(
              icon, // Path to your SVG file
            ),
          ),
          const Spacer(),
          Row(
            children: [
               Text(
                text,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontFamily: 'Nunito Sans',
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(120),
                  ),
                ),
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: SvgPicture.asset(
                    arrowIcon, // Path to your SVG file
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
