part of 'ai_assessment_score_bloc.dart';

sealed class AiAssessmentScoreState {
  const AiAssessmentScoreState();
}

final class AiAssessmentScoreInitial extends AiAssessmentScoreState {
  const AiAssessmentScoreInitial();
}

final class AiAssessmentScoreSaving extends AiAssessmentScoreState {
  const AiAssessmentScoreSaving();
}

final class AiAssessmentScoreSaveSuccess extends AiAssessmentScoreState {
  const AiAssessmentScoreSaveSuccess(this.response);

  final Map<String, dynamic> response;
}

final class AiAssessmentScoreSaveFailure extends AiAssessmentScoreState {
  const AiAssessmentScoreSaveFailure(this.message);

  final String message;
}
