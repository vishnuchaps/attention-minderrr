import 'package:attention_minder/constant/asset_path.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class AssignmentStartCardWidget extends StatefulWidget {
  final String icon;
  final String title;
  final String subTitle;
  final VoidCallback onTap;

  const AssignmentStartCardWidget({
    super.key,
    required this.icon,
    required this.subTitle,
    required this.title,
    required this.onTap,
  });

  @override
  State<AssignmentStartCardWidget> createState() =>
      _AssignmentStartCardWidgetState();
}

class _AssignmentStartCardWidgetState extends State<AssignmentStartCardWidget> {
  final GlobalKey _gestureKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 152,
      padding: const EdgeInsets.only(top: 5, left: 5, right: 5, bottom: 12),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                clipBehavior: Clip.antiAlias,
                decoration: ShapeDecoration(
                  color: const Color(0xFF0084FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                child: SvgPicture.asset(widget.icon),
              ),
              const SizedBox(width: 19),
              Text(
                widget.title,
                style: const TextStyle(
                  color: Color(0xFF292929),
                  fontSize: 16,
                  fontFamily: 'Nunito Sans',
                  fontWeight: FontWeight.w400,
                  height: 0.88,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Text(
              widget.subTitle,
              style: const TextStyle(
                color: Color(0xFF565656),
                fontSize: 11,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 2,
              left: 14,
              right: 2,
              bottom: 2,
            ),
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(57),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Learn more',
                  style: TextStyle(
                    color: Color(0xFF0F78FE),
                    fontSize: 12,
                    fontFamily: 'Nunito Sans',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  key: _gestureKey,
                  onTap: widget.onTap,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(120),
                        side: const BorderSide(color: Colors.grey, width: 1),
                      ),
                    ),
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: SvgPicture.asset(
                        arrowIcon,
                        color: const Color(0xFF0F78FE),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
