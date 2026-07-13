part of 'questionnaire_result_bloc.dart';

sealed class QuestionnaireResultEvent {}

final class GetQuestionnaireResultEvent extends QuestionnaireResultEvent {
  final int? page;

  GetQuestionnaireResultEvent({this.page});
}
