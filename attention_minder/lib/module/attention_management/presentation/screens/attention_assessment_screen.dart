import 'package:attention_minder/module/attention_management/data/model/attention_data_model.dart';
import 'package:attention_minder/module/attention_management/presentation/bloc/attention_management_bloc.dart';
import 'package:attention_minder/module/attention_management/presentation/screens/attention_program_overview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AttentionAssessmentScreen extends StatefulWidget {
  const AttentionAssessmentScreen({super.key});

  @override
  State<AttentionAssessmentScreen> createState() =>
      _AttentionAssessmentScreenState();
}

class _AttentionAssessmentScreenState extends State<AttentionAssessmentScreen> {
  int _currentQuestionIndex = 0;
  Map<int, String> _answers = {};
  List<AssessmentQuestion> _questions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    context.read<AttentionManagementBloc>().add(FetchAssessmentQuestionsEvent());
  }

  void _answerQuestion(String answer) {
    setState(() {
      _answers[_questions[_currentQuestionIndex].id] = answer;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _submitAssessment();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  void _submitAssessment() {
    // Format answers for API
    List<Map<String, dynamic>> formattedAnswers = [];
    _answers.forEach((questionId, answer) {
      formattedAnswers.add({
        'question_id': questionId,
        'answer': answer,
      });
    });

    context
        .read<AttentionManagementBloc>()
        .add(SubmitAssessmentEvent(formattedAnswers));

    // Navigate to program overview
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const AttentionProgramOverviewScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocListener<AttentionManagementBloc, AttentionManagementState>(
        listener: (context, state) {
          if (state is AssessmentQuestionsSuccess) {
            setState(() {
              _questions = state.questions;
              _isLoading = false;
            });
          } else if (state is AssessmentQuestionsFailed) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFF7C14A),
                ),
              )
            : _questions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No questions available',
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Go Back'),
                        ),
                      ],
                    ),
                  )
                : SafeArea(
        child: _buildAssessmentContent(screenWidth, screenHeight),
                  ),
      ),
    );
  }

  Widget _buildAssessmentContent(double screenWidth, double screenHeight) {
    final currentQuestion = _questions[_currentQuestionIndex];
    final currentAnswer = _answers[currentQuestion.id];

    return Column(
      children: [
        // Top Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
              Text(
                'Question ${_currentQuestionIndex + 1}/${_questions.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  currentQuestion.category,
                  style: const TextStyle(
                    color: Color(0xFFF7C14A),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Progress Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _questions.length,
              minHeight: 8,
              backgroundColor: Colors.grey.shade800,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFF7C14A),
              ),
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFF7C14A).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    currentQuestion.questionText,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Rating Scale Options
                ..._buildRatingOptions(currentAnswer),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // Bottom Buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (_currentQuestionIndex > 0)
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade800,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _previousQuestion,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_back),
                          SizedBox(width: 8),
                          Text(
                            'Previous',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_currentQuestionIndex > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentAnswer != null
                          ? const Color(0xFF3D7BFF)
                          : Colors.grey.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: currentAnswer != null ? _nextQuestion : null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentQuestionIndex == _questions.length - 1
                              ? 'Finish'
                              : 'Next',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildRatingOptions(String? currentAnswer) {
    return AssessmentQuestion.ratingOptions.map((option) {
      final isSelected = currentAnswer == option;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: () => _answerQuestion(option),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFF7C14A).withOpacity(0.2)
                  : Colors.grey.shade900,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFF7C14A)
                    : Colors.grey.shade700,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFF7C14A)
                          : Colors.grey.shade600,
                      width: 2,
                    ),
                    color:
                        isSelected ? const Color(0xFFF7C14A) : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.black)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 16,
                      color: isSelected ? const Color(0xFFF7C14A) : Colors.white,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}
