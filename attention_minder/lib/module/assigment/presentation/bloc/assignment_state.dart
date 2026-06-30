part of 'assignment_bloc.dart';

abstract class AssignmentState {}

class AssignmentInitial extends AssignmentState {}

class AssignmentLoading extends AssignmentState {}

class FetchQuestionSuccess extends AssignmentState {
  final Data data;

  FetchQuestionSuccess(this.data);
}

class FetchQuestionFailed extends AssignmentState {
  final String message;

  FetchQuestionFailed(this.message);
}

class SaveAnswerSuccess extends AssignmentState {
  final String message;
  final bool navigateToResult;

  SaveAnswerSuccess(this.message, {this.navigateToResult = true});
}

class SaveAnswerFailed extends AssignmentState {
  final String error;
  SaveAnswerFailed(this.error);
}

class FetchResultsSuccess extends AssignmentState {
  final Map<String, dynamic> resultsData;
  FetchResultsSuccess(this.resultsData);
}

class FetchResultsFailed extends AssignmentState {
  final String error;
  FetchResultsFailed(this.error);
}

class GetArticlesLoading extends AssignmentState {
  final bool isPagination;

  GetArticlesLoading({this.isPagination = false});
}

class GetArticlesSuccess extends AssignmentState {
  final BlogResponse articleResponse;
  GetArticlesSuccess(this.articleResponse);
}

class GetArticlesFailed extends AssignmentState {
  final String error;
  GetArticlesFailed(this.error);
}
