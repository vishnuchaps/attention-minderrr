import 'package:attention_minder/module/attention_management/data/repository/iai_assessment_score_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../data/model/ai_assessment_score_request.dart';

part 'ai_assessment_score_event.dart';
part 'ai_assessment_score_state.dart';

@injectable
class AiAssessmentScoreBloc
    extends Bloc<AiAssessmentScoreEvent, AiAssessmentScoreState> {
  AiAssessmentScoreBloc(this._repository)
    : super(const AiAssessmentScoreInitial()) {
    on<SaveAiAssessmentScoreRequested>(_onSaveRequested);
  }

  final IAiAssessmentScoreRepository _repository;

  Future<void> _onSaveRequested(
    SaveAiAssessmentScoreRequested event,
    Emitter<AiAssessmentScoreState> emit,
  ) async {
    if (state is AiAssessmentScoreSaving) return;

    emit(const AiAssessmentScoreSaving());
    try {
      final response = await _repository.saveScore(event.request);
      emit(AiAssessmentScoreSaveSuccess(response));
    } catch (error) {
      emit(AiAssessmentScoreSaveFailure(error.toString()));
    }
  }
}
