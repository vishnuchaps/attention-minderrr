import 'package:attention_minder/module/assigment/presentation/widgets/text_card_widget.dart';
import 'package:attention_minder/module/assigment/presentation/widgets/title_subtitle_widget.dart';
import 'package:attention_minder/module/assigment/presentation/widgets/yellow_test_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AssignmentOverlayWidget extends StatelessWidget {
  final String selfAssignmentIcon;
  final String selfAssignmentLeftImage;
  final String selfAssignmentCenterImage;
  final String selfAssignmentRightImage;
  final String arrowIcon;
  final String backIconPath;
  final String assignmentType;
  final YellowTestCardWidget yellowTestCardWidget;
  final List<TitleSubtitleWidget> titleSubtitleWidget;
  final List<TextCardWidget> textCardWidget;
  final VoidCallback ontap;

  const AssignmentOverlayWidget({
    super.key,
    required this.selfAssignmentIcon,
    required this.selfAssignmentLeftImage,
    required this.selfAssignmentCenterImage,
    required this.selfAssignmentRightImage,
    required this.arrowIcon,
    required this.backIconPath,
    required this.assignmentType,
    required this.yellowTestCardWidget,
    required this.titleSubtitleWidget,
    required this.textCardWidget,
    required this.ontap,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: screenHeight * 0.84, // never taller than 82% of screen
            ),
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                color: Colors.white,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
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
                        child: SvgPicture.asset(selfAssignmentIcon),
                      ),
                      const SizedBox(width: 19),
                      Text(
                        assignmentType,
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
                  const SizedBox(height: 8),

                  // Banner image — scales with screen
                  AspectRatio(
                    aspectRatio: 2.5, // wider = shorter height
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFFFB61D),
                            Color(0xFFFBF7EC),
                            Color(0xFFFBFCFD),
                            Color(0xFF0F79FF),
                          ],
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 12,
                            left: 24,
                            child: SvgPicture.asset(
                              selfAssignmentLeftImage,
                              width: 40,
                              height: 40,
                            ),
                          ),
                          Positioned(
                            top: 0,
                            left: 50,
                            right: 50,
                            child: SvgPicture.asset(selfAssignmentCenterImage),
                          ),
                          Positioned(
                            top: 50,
                            right: 43,
                            bottom: 0,
                            child: SvgPicture.asset(
                              selfAssignmentRightImage,
                              width: 40,
                              height: 40,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Flexible(
                    child: Stack(
                      children: [
                        Scrollbar(
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                ListView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: titleSubtitleWidget.length,
                                  itemBuilder: (context, index) =>
                                      TitleSubtitleWidget(
                                        title: titleSubtitleWidget[index].title,
                                        subTitle:
                                            titleSubtitleWidget[index].subTitle,
                                      ),
                                ),
                                ListView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: textCardWidget.length,
                                  itemBuilder: (context, index) =>
                                      TextCardWidget(
                                        text: textCardWidget[index].text,
                                        subTitle:
                                            textCardWidget[index].subTitle,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Yellow card — always visible
                  YellowTestCardWidget(
                    title: yellowTestCardWidget.title,
                    subTitle: yellowTestCardWidget.subTitle,
                  ),
                  const SizedBox(height: 10),

                  // Get started button — always visible
                  InkWell(
                    onTap: ontap,
                    child: Container(
                      height: 43.60,
                      decoration: ShapeDecoration(
                        color: const Color(0xFF0F78FE),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Get started',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: 'Nunito Sans',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(width: 10),
                          SvgPicture.asset(arrowIcon, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Close button — always visible below card
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xfff6f7fa),
              ),
              child: SvgPicture.asset(backIconPath),
            ),
          ),
        ],
      ),
    );
  }
}
