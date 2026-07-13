part of 'questionnaire_result_bloc.dart';

sealed class QuestionnaireResultState {}

final class QuestionnaireResultInitial extends QuestionnaireResultState {}

final class QuestionnaireResultLoading extends QuestionnaireResultState {}

final class QuestionnaireResultSuccess extends QuestionnaireResultState {
  final ManagementHistoryResponse data;

  QuestionnaireResultSuccess(this.data);
}

final class QuestionnaireResultFailed extends QuestionnaireResultState {
  final String error;

  QuestionnaireResultFailed(this.error);
}
