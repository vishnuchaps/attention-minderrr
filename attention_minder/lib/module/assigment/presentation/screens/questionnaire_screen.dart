import 'package:attention_minder/module/assigment/data/model/question_model.dart';
import 'package:attention_minder/module/landing/presentation/screens/landing_screen.dart';
import 'package:attention_minder/module/profile/presentation/screens/profile_screen.dart';
import 'package:attention_minder/module/result/presentation/screens/self_assessment_result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../Config/widgets/user_profile_avatar_widget.dart';
import '../bloc/assignment_bloc.dart';

class QuestionnaireScreen extends StatefulWidget {
  final int initialQuestionIndex;

  const QuestionnaireScreen({super.key, this.initialQuestionIndex = 0});

  @override
  _QuestionnaireScreenState createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  int _currentQuestionIndex = 0;
  int _initialQuestionIndex = 0;
  bool _hasAppliedInitialQuestionIndex = false;
  final Map<int, int> _selectedAnswers = {};
  List<Question> _questions = [];
  final List<String> _options = [
    'Not at all',
    'Just a little',
    'Often',
    'Very often',
  ];

  @override
  void initState() {
    super.initState();
    // Fetch questions when the screen loads
    context.read<AssignmentBloc>().add(GetTheQuestion());
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LandingScreen()),
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF020302),
        body: SafeArea(
          child: BlocConsumer<AssignmentBloc, AssignmentState>(
            listener: (context, state) {
              // Handle state changes that need UI feedback
              if (state is FetchQuestionFailed) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message)));
              } else if (state is SaveAnswerSuccess) {
                if (state.navigateToResult && mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(state.message)));
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    // Navigate to the new Self Assessment Result Screen
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const SelfAssessmentResultScreen(),
                      ),
                    );
                  });
                }
              } else if (state is SaveAnswerFailed) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.error)));
              }
            },
            builder: (context, state) {
              // Loading state
              if (state is AssignmentLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF52C95B)),
                );
              }

              if (state is AssignmentInitial && _questions.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF52C95B)),
                );
              }

              // Error state
              if (state is FetchQuestionFailed) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(state.message),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => context.read<AssignmentBloc>().add(
                          GetTheQuestion(),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              // Success state with questions
              if (state is FetchQuestionSuccess) {
                _questions = state.data.questions;
                _applyInitialQuestionIndex();
              }

              if (_questions.isEmpty) {
                return const Center(child: Text("No questions available"));
              }

              final currentQuestion = _questions[_currentQuestionIndex];

              return _buildQuestionnaireContent(_questions, currentQuestion);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionnaireContent(
    List<Question> questions,
    Question currentQuestion,
  ) {
    final bool canGoBack = _currentQuestionIndex > _initialQuestionIndex;
    final bool hasSelectedAnswer = _selectedAnswers.containsKey(
      currentQuestion.id,
    );
    final bool isLastQuestion = _currentQuestionIndex == questions.length - 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 360 ? 16.0 : 20.0;
        final compactHeight = constraints.maxHeight < 720;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                compactHeight ? 10 : 14,
                horizontalPadding,
                12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _topBar(),
                  SizedBox(height: compactHeight ? 16 : 22),
                  _progressHeader(questions),
                  SizedBox(height: compactHeight ? 18 : 24),
                  _assessmentIntro(compactHeight),
                  SizedBox(height: compactHeight ? 18 : 22),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: _questionCard(currentQuestion, compactHeight),
                    ),
                  ),
                  SizedBox(height: compactHeight ? 12 : 16),
                  _navigationBar(
                    canGoBack: canGoBack,
                    hasSelectedAnswer: hasSelectedAnswer,
                    nextText: isLastQuestion ? 'Submit' : 'Next',
                    onBack: canGoBack
                        ? () => setState(() => _currentQuestionIndex--)
                        : null,
                    onNext: hasSelectedAnswer
                        ? () {
                            if (_currentQuestionIndex < questions.length - 1) {
                              _saveSelectedAnswers(navigateToResult: false);
                              setState(() => _currentQuestionIndex++);
                            } else {
                              _saveSelectedAnswers(navigateToResult: true);
                            }
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        _roundIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LandingScreen()),
            );
          },
        ),
        const Spacer(),
        UserProfileAvatar(
          size: 40,
          borderColor: const Color(0xFF121417),
          borderWidth: 2,
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ProfileScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _roundIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFF15171B),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: Colors.white, size: 21),
        ),
      ),
    );
  }

  Widget _progressHeader(List<Question> questions) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: List.generate(questions.length, (index) {
              final bool isComplete =
                  index < _initialQuestionIndex ||
                  _selectedAnswers.containsKey(questions[index].id);

              return Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(
                    right: index == questions.length - 1 ? 0 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: isComplete
                        ? const Color(0xFF48BD53)
                        : const Color(0xFF24272D),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 14),
        Text(
          '${_currentQuestionIndex + 1} of ${questions.length}',
          style: GoogleFonts.poppins(
            color: const Color(0xFF52C95B),
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
      ],
    );
  }

  Widget _assessmentIntro(bool compactHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Self Assessment',
            maxLines: 1,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: compactHeight ? 28 : 32,
              letterSpacing: 0,
              color: Colors.white,
              height: 1.05,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'This short assessment will take approximately\n20-30 minutes.',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w400,
            fontSize: compactHeight ? 14 : 15,
            letterSpacing: 0,
            color: const Color(0xFFA9ABB2),
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _questionCard(Question currentQuestion, bool compactHeight) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        compactHeight ? 16 : 18,
        compactHeight ? 18 : 20,
        compactHeight ? 16 : 18,
        compactHeight ? 16 : 18,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF171A1F), Color(0xFF0D0F13)],
        ),
        border: Border.all(color: const Color(0xFF252A31)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: compactHeight ? 42 : 46,
                height: compactHeight ? 42 : 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF3E9245),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF52C95B).withValues(alpha: 0.22),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.fact_check_rounded,
                  color: Color(0xFF9FE6A5),
                  size: 22,
                ),
              ),
              SizedBox(width: compactHeight ? 14 : 16),
              Expanded(
                child: Text(
                  currentQuestion.questionText,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: compactHeight ? 18 : 20,
                    letterSpacing: 0,
                    color: Colors.white,
                    height: 1.42,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compactHeight ? 18 : 22),
          for (int i = 0; i < _options.length; i++)
            _optionTile(currentQuestion.id, i, compactHeight: compactHeight),
        ],
      ),
    );
  }

  Widget _optionTile(int questionId, int index, {required bool compactHeight}) {
    bool isSelected = _selectedAnswers[questionId] == index;

    return Padding(
      padding: EdgeInsets.only(bottom: index == _options.length - 1 ? 0 : 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _selectedAnswers[questionId] = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            constraints: BoxConstraints(minHeight: compactHeight ? 52 : 58),
            padding: EdgeInsets.symmetric(
              horizontal: compactHeight ? 14 : 16,
              vertical: compactHeight ? 10 : 12,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFF5FFF5)
                  : const Color(0xFF171A1F),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF68D276)
                    : const Color(0xFF282C34),
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF52C95B).withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _options[index],
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: compactHeight ? 15 : 16,
                      letterSpacing: 0,
                      color: isSelected
                          ? const Color(0xFF3D9146)
                          : const Color(0xFFD5D6DA),
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: compactHeight ? 24 : 26,
                  height: compactHeight ? 24 : 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? const Color(0xFF47A64F)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF47A64F)
                          : const Color(0xFF747982),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 18,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navigationBar({
    required bool canGoBack,
    required bool hasSelectedAnswer,
    required String nextText,
    required VoidCallback? onBack,
    required VoidCallback? onNext,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: _navigationButton(
            text: 'Back',
            icon: Icons.arrow_back_rounded,
            isPrimary: false,
            isEnabled: canGoBack,
            onPressed: onBack,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 8,
          child: _navigationButton(
            text: nextText,
            icon: Icons.arrow_forward_rounded,
            isPrimary: true,
            isEnabled: hasSelectedAnswer,
            onPressed: onNext,
          ),
        ),
      ],
    );
  }

  Widget _navigationButton({
    required String text,
    required IconData icon,
    required bool isPrimary,
    required bool isEnabled,
    required VoidCallback? onPressed,
  }) {
    final Color foreground = isPrimary ? Colors.white : const Color(0xFFD9DBE0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isPrimary
                ? (isEnabled
                      ? const Color(0xFF47B94E)
                      : const Color(0xFF244D29))
                : (isEnabled
                      ? const Color(0xFF14171B)
                      : const Color(0xFF101215)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPrimary ? Colors.transparent : const Color(0xFF171B20),
            ),
            boxShadow: isPrimary && isEnabled
                ? [
                    BoxShadow(
                      color: const Color(0xFF47B94E).withValues(alpha: 0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 7),
                    ),
                  ]
                : null,
          ),
          child: Opacity(
            opacity: isEnabled ? 1 : 0.45,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: isPrimary
                  ? [
                      Flexible(
                        child: Text(
                          text,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: foreground,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(icon, color: foreground, size: 24),
                    ]
                  : [
                      Icon(icon, color: foreground, size: 24),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          text,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: foreground,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ],
            ),
          ),
        ),
      ),
    );
  }

  void _applyInitialQuestionIndex() {
    if (_hasAppliedInitialQuestionIndex || _questions.isEmpty) {
      return;
    }

    final maxQuestionIndex = _questions.length - 1;
    final initialQuestionIndex = widget.initialQuestionIndex
        .clamp(0, maxQuestionIndex)
        .toInt();

    _currentQuestionIndex = initialQuestionIndex;
    _initialQuestionIndex = initialQuestionIndex;
    _hasAppliedInitialQuestionIndex = true;
  }

  void _saveSelectedAnswers({required bool navigateToResult}) {
    final assessment = _selectedAnswers.entries.map((entry) {
      return {"question": entry.key, "option": entry.value};
    }).toList();

    context.read<AssignmentBloc>().add(
      QuestionSubmission(
        {"assesment": assessment},
        navigateToResult: navigateToResult,
        showLoading: navigateToResult,
      ),
    );
  }
}
