part of 'attention_management_bloc.dart';

abstract class AttentionManagementEvent {}

class FetchProgramDataEvent extends AttentionManagementEvent {}

class FetchAssessmentQuestionsEvent extends AttentionManagementEvent {}

class SubmitAssessmentEvent extends AttentionManagementEvent {
  final List<Map<String, dynamic>> answers;

  SubmitAssessmentEvent(this.answers);
}

class FetchDailySessionEvent extends AttentionManagementEvent {
  final int day;

  FetchDailySessionEvent(this.day);
}

class CompleteSessionEvent extends AttentionManagementEvent {
  final int day;
  final Map<String, dynamic> sessionData;

  CompleteSessionEvent(this.day, this.sessionData);
}

class SaveGoalsEvent extends AttentionManagementEvent {
  final List<String> goals;

  SaveGoalsEvent(this.goals);
}

class FetchProgressDataEvent extends AttentionManagementEvent {}

class ResetStateEvent extends AttentionManagementEvent {}
