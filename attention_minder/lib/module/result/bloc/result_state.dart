part of 'result_bloc.dart';

abstract class ResultState {}

class ResultInitial extends ResultState {}

class GetResultLoading extends ResultState {}

class GetResultSuccess extends ResultState {
  final AssessmentHistoryResponse data;
  GetResultSuccess(this.data);
}

class GetResultFailed extends ResultState {
  final String error;
  GetResultFailed(this.error);
}

class GetManagementDashboardLoading extends ResultState {}

class GetManagementDashboardSuccess extends ResultState {
  final WeeklyProgressResponse data;

  GetManagementDashboardSuccess(this.data);
}

class GetManagementDashboardFailed extends ResultState {
  final String error;

  GetManagementDashboardFailed(this.error);
}
