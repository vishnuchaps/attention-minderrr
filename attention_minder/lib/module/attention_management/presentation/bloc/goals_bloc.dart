import 'package:attention_minder/module/attention_management/data/model/goals_model.dart';
import 'package:attention_minder/module/attention_management/data/model/goal_submission.dart';
import 'package:attention_minder/module/attention_management/data/repository/iai_assessment_score_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part 'goals_event.dart';
part 'goals_state.dart';

@injectable
class GoalsBloc extends Bloc<GoalsEvent, GoalsState> {
  GoalsBloc(this._repository) : super(GoalsInitial()) {
    on<LoadGoalsRequested>(_onLoadGoals);
    on<GoalsSet>(_onSetGoals);
    on<GoalsEvaluationSubmitted>(_onSubmitEvaluation);
  }

  final IAiAssessmentScoreRepository _repository;

  Future<void> _onLoadGoals(
    LoadGoalsRequested event,
    Emitter<GoalsState> emit,
  ) async {
    emit(GoalsLoading());

    try {
      final response = await _repository.getGoalsResponse();
      emit(GoalsLoadSuccess(response));
    } catch (error) {
      emit(GoalsLoadFailure(error.toString()));
    }
  }

  Future<void> _onSetGoals(GoalsSet event, Emitter<GoalsState> emit) async {
    final goals = event.goals
        .map((goal) => goal.normalized())
        .where((goal) => goal.goal.isNotEmpty)
        .toList(growable: false);

    if (goals.isEmpty) {
      emit(const GoalsSetFailure('Enter at least one goal to continue.'));
      return;
    }

    emit(GoalsSetInProgress());

    try {
      final response = await _repository.setGoals(goals: goals);
      final message = response['message']?.toString().trim() ?? '';

      emit(
        GoalsSetSuccess(
          message.isEmpty ? 'Goals saved successfully.' : message,
        ),
      );
    } catch (error) {
      emit(GoalsSetFailure(error.toString()));
    }
  }

  Future<void> _onSubmitEvaluation(
    GoalsEvaluationSubmitted event,
    Emitter<GoalsState> emit,
  ) async {
    final goals = event.goals
        .map((goal) => goal.normalized())
        .where((goal) => goal.goal.isNotEmpty)
        .toList(growable: false);

    if (goals.isEmpty || goals.any((goal) => goal.id == null)) {
      emit(
        const GoalsSetFailure(
          'We could not identify every saved goal. Please refresh and try again.',
        ),
      );
      return;
    }

    emit(GoalsSetInProgress());
    try {
      final response = await _repository.updateGoalRatings(goals: goals);
      final message = response['message']?.toString().trim() ?? '';
      emit(
        GoalsSetSuccess(
          message.isEmpty
              ? 'Your evaluation was submitted successfully.'
              : message,
        ),
      );
    } catch (error) {
      emit(GoalsSetFailure(error.toString()));
    }
  }
}
