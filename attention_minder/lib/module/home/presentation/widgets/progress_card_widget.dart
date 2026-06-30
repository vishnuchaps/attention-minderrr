import 'package:attention_minder/constant/asset_path.dart';
import 'package:attention_minder/module/assigment/presentation/screens/questionnaire_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

class ProgressCardWidget extends StatefulWidget {
  final int totalQuestions;
  final int answeredQuestions;

  const ProgressCardWidget({
    super.key,
    required this.totalQuestions,
    required this.answeredQuestions,
  });

  @override
  State<ProgressCardWidget> createState() => _ProgressCardWidgetState();
}

class _ProgressCardWidgetState extends State<ProgressCardWidget> {
  static const double _itemWidth = 45;
  static const double _separatorWidth = 10;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToProgressEdge(),
    );
  }

  @override
  void didUpdateWidget(covariant ProgressCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.answeredQuestions != widget.answeredQuestions ||
        oldWidget.totalQuestions != widget.totalQuestions) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollToProgressEdge(),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToProgressEdge() {
    if (!_scrollController.hasClients) {
      return;
    }

    final questionCount = widget.totalQuestions < 0 ? 0 : widget.totalQuestions;
    final completedCount = widget.answeredQuestions
        .clamp(0, questionCount)
        .toInt();

    if (completedCount <= 1) {
      _scrollController.jumpTo(_scrollController.position.minScrollExtent);
      return;
    }

    final targetOffset = ((completedCount - 1) * (_itemWidth + _separatorWidth))
        .clamp(
          _scrollController.position.minScrollExtent,
          _scrollController.position.maxScrollExtent,
        )
        .toDouble();

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final questionCount = widget.totalQuestions < 0 ? 0 : widget.totalQuestions;
    final completedCount = widget.answeredQuestions
        .clamp(0, questionCount)
        .toInt();

    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 18, 10, 5),
        margin: const EdgeInsets.fromLTRB(10, 10, 10, 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: const Color(0xFFD8D8DF),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "You are progressing",
              style: GoogleFonts.nunitoSans(
                fontSize: 24,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 15,
                    child: ListView.separated(
                      controller: _scrollController,
                      shrinkWrap: true,
                      // physics: const NeverScrollableScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (BuildContext build, int index) {
                        return Container(
                          width: 45,
                          height: 11,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(35),
                            color: index < completedCount
                                ? const Color(0xffffb61d)
                                : Colors.white,
                          ),
                        );
                      },
                      separatorBuilder: (BuildContext build, int index) {
                        return const SizedBox(width: 10);
                      },
                      itemCount: questionCount,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 27,
                  height: 27,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(35),
                    color: const Color(0xff3fad67),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: SvgPicture.asset(
                        finishIcon, // Path to your SVG file
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Text(
                  "$completedCount Out of $questionCount",
                  style: GoogleFonts.nunitoSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuestionnaireScreen(
                          initialQuestionIndex: completedCount,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(57),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 4),
                        const Text(
                          "Complete Questionnaire",
                          style: TextStyle(
                            fontFamily: "Nunito Sans",
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xff373737),
                            height: 16 / 12,
                          ),
                          textAlign: TextAlign.left,
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 27,
                          height: 27,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(35),
                            color: const Color(0xffDEDEDE),
                          ),
                          child: Center(
                            child: SizedBox(
                              width: 8,
                              height: 8,
                              child: SvgPicture.asset(playIcon),
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
