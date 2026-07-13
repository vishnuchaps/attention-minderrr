part of 'result_bloc.dart';

abstract class ResultEvent {}

class GetResultEvent extends ResultEvent {
  final int? page;
  GetResultEvent({this.page});
}

class GetManagementDashboardEvent extends ResultEvent {}
