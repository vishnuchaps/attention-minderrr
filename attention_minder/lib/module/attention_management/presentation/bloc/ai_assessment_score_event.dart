part of 'ai_assessment_score_bloc.dart';

sealed class AiAssessmentScoreEvent {
  const AiAssessmentScoreEvent();
}

final class SaveAiAssessmentScoreRequested extends AiAssessmentScoreEvent {
  const SaveAiAssessmentScoreRequested(this.request);

  final AiAssessmentScoreRequest request;
}
