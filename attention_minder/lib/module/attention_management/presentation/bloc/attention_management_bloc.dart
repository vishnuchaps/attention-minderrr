import 'package:attention_minder/module/attention_management/data/repository/iattention_management_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part 'attention_management_event.dart';
part 'attention_management_state.dart';

@injectable
class AttentionManagementBloc
    extends Bloc<AttentionManagementEvent, AttentionManagementState> {
  final IAttentionManagementRepository _repository;

  AttentionManagementBloc(this._repository)
      : super(AttentionManagementInitial()) {
    on<FetchProgramDataEvent>(_onFetchProgramData);
    on<FetchAssessmentQuestionsEvent>(_onFetchAssessmentQuestions);
    on<SubmitAssessmentEvent>(_onSubmitAssessment);
    on<FetchDailySessionEvent>(_onFetchDailySession);
    on<CompleteSessionEvent>(_onCompleteSession);
    on<SaveGoalsEvent>(_onSaveGoals);
    on<FetchProgressDataEvent>(_onFetchProgressData);
    on<ResetStateEvent>(_onResetState);
  }

  void _onFetchProgramData(
    FetchProgramDataEvent event,
    Emitter<AttentionManagementState> emit,
  ) async {
    emit(AttentionManagementLoading());
    try {
      final response = await _repository.getProgramData();
      emit(ProgramDataSuccess(response));
    } catch (e) {
      emit(ProgramDataFailed(e.toString()));
    }
  }

  void _onFetchAssessmentQuestions(
    FetchAssessmentQuestionsEvent event,
    Emitter<AttentionManagementState> emit,
  ) async {
    emit(AttentionManagementLoading());
    try {
      final response = await _repository.getAssessmentQuestions();
      emit(AssessmentQuestionsSuccess(response));
    } catch (e) {
      emit(AssessmentQuestionsFailed(e.toString()));
    }
  }

  void _onSubmitAssessment(
    SubmitAssessmentEvent event,
    Emitter<AttentionManagementState> emit,
  ) async {
    emit(AttentionManagementLoading());
    try {
      final response = await _repository.submitAssessment(
        answers: event.answers,
      );
      emit(AssessmentSubmitSuccess(
          response['message'] ?? 'Assessment submitted successfully'));
    } catch (e) {
      emit(AssessmentSubmitFailed(e.toString()));
    }
  }

  void _onFetchDailySession(
    FetchDailySessionEvent event,
    Emitter<AttentionManagementState> emit,
  ) async {
    emit(AttentionManagementLoading());
    try {
      final response = await _repository.getDailySession(day: event.day);
      emit(DailySessionSuccess(response));
    } catch (e) {
      emit(DailySessionFailed(e.toString()));
    }
  }

  void _onCompleteSession(
    CompleteSessionEvent event,
    Emitter<AttentionManagementState> emit,
  ) async {
    emit(AttentionManagementLoading());
    try {
      final response = await _repository.completeSession(
        day: event.day,
        sessionData: event.sessionData,
      );
      emit(SessionCompleteSuccess(
          response['message'] ?? 'Session completed successfully'));
    } catch (e) {
      emit(SessionCompleteFailed(e.toString()));
    }
  }

  void _onSaveGoals(
    SaveGoalsEvent event,
    Emitter<AttentionManagementState> emit,
  ) async {
    emit(AttentionManagementLoading());
    try {
      final response = await _repository.saveGoals(goals: event.goals);
      emit(GoalsSaveSuccess(response['message'] ?? 'Goals saved successfully'));
    } catch (e) {
      emit(GoalsSaveFailed(e.toString()));
    }
  }

  void _onFetchProgressData(
    FetchProgressDataEvent event,
    Emitter<AttentionManagementState> emit,
  ) async {
    emit(AttentionManagementLoading());
    try {
      final response = await _repository.getProgressData();
      emit(ProgressDataSuccess(response));
    } catch (e) {
      emit(ProgressDataFailed(e.toString()));
    }
  }

  void _onResetState(
    ResetStateEvent event,
    Emitter<AttentionManagementState> emit,
  ) {
    emit(AttentionManagementInitial());
  }
}
