part of 'result_detail_bloc.dart';

abstract class ResultDetailState {}

class ResultDetailInitial extends ResultDetailState {}

class GetResultDetailLoading extends ResultDetailState {}

class GetResultDetailSuccess extends ResultDetailState {
  final WeeklyManagementResponse data;
  GetResultDetailSuccess(this.data);
}

class GetResultDetailFailed extends ResultDetailState {
  final String error;
  GetResultDetailFailed(this.error);
}
