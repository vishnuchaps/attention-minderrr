part of 'goals_bloc.dart';

sealed class GoalsState {
  const GoalsState();
}

final class GoalsInitial extends GoalsState {}

final class GoalsLoading extends GoalsState {}

final class GoalsLoadSuccess extends GoalsState {
  final GoalsResponse response;

  const GoalsLoadSuccess(this.response);
}

final class GoalsLoadFailure extends GoalsState {
  final String message;

  const GoalsLoadFailure(this.message);
}

final class GoalsSetInProgress extends GoalsState {}

final class GoalsSetSuccess extends GoalsState {
  final String message;

  const GoalsSetSuccess(this.message);
}

final class GoalsSetFailure extends GoalsState {
  final String message;

  const GoalsSetFailure(this.message);
}