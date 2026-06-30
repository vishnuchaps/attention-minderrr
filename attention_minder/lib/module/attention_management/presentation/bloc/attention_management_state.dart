part of 'attention_management_bloc.dart';

abstract class AttentionManagementState {}

class AttentionManagementInitial extends AttentionManagementState {}

class AttentionManagementLoading extends AttentionManagementState {}

// Program Data States
class ProgramDataSuccess extends AttentionManagementState {
  final dynamic data;

  ProgramDataSuccess(this.data);
}

class ProgramDataFailed extends AttentionManagementState {
  final String message;

  ProgramDataFailed(this.message);
}

// Assessment States
class AssessmentQuestionsSuccess extends AttentionManagementState {
  final dynamic questions;

  AssessmentQuestionsSuccess(this.questions);
}

class AssessmentQuestionsFailed extends AttentionManagementState {
  final String message;

  AssessmentQuestionsFailed(this.message);
}

class AssessmentSubmitSuccess extends AttentionManagementState {
  final String message;

  AssessmentSubmitSuccess(this.message);
}

class AssessmentSubmitFailed extends AttentionManagementState {
  final String error;

  AssessmentSubmitFailed(this.error);
}

// Daily Session States
class DailySessionSuccess extends AttentionManagementState {
  final dynamic sessionData;

  DailySessionSuccess(this.sessionData);
}

class DailySessionFailed extends AttentionManagementState {
  final String message;

  DailySessionFailed(this.message);
}

class SessionCompleteSuccess extends AttentionManagementState {
  final String message;

  SessionCompleteSuccess(this.message);
}

class SessionCompleteFailed extends AttentionManagementState {
  final String error;

  SessionCompleteFailed(this.error);
}

// Goals States
class GoalsSaveSuccess extends AttentionManagementState {
  final String message;

  GoalsSaveSuccess(this.message);
}

class GoalsSaveFailed extends AttentionManagementState {
  final String error;

  GoalsSaveFailed(this.error);
}

// Progress States
class ProgressDataSuccess extends AttentionManagementState {
  final dynamic progressData;

  ProgressDataSuccess(this.progressData);
}

class ProgressDataFailed extends AttentionManagementState {
  final String message;

  ProgressDataFailed(this.message);
}
