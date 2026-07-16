part of 'goals_bloc.dart';

class GoalsEvent {
  const GoalsEvent();
}

final class LoadGoalsRequested extends GoalsEvent {
  const LoadGoalsRequested();
}

final class GoalsSet extends GoalsEvent {
  final List<GoalSubmission> goals;

  const GoalsSet(this.goals);
}

final class GoalsEvaluationSubmitted extends GoalsEvent {
  final List<GoalSubmission> goals;

  const GoalsEvaluationSubmitted(this.goals);
}
