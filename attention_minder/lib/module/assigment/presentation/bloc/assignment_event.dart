part of 'assignment_bloc.dart';

abstract class AssignmentEvent {}

class GetTheQuestion extends AssignmentEvent {}

class QuestionSubmission extends AssignmentEvent {
  final Map<String, dynamic> answer;
  final bool navigateToResult;
  final bool showLoading;

  QuestionSubmission(
    this.answer, {
    this.navigateToResult = true,
    this.showLoading = true,
  });
}

class FetchAssessmentResults extends AssignmentEvent {
  final int? page;
  FetchAssessmentResults({this.page});
}

class GetArticleListEvent extends AssignmentEvent {
  final bool forceRefresh;
  final int page;
  final bool append;

  GetArticleListEvent({
    this.forceRefresh = false,
    this.page = 1,
    this.append = false,
  });
}
