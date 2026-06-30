part of 'progress_bloc.dart';

abstract class ProgressState {}

class ProgressInitial extends ProgressState {}

class ProgressLoading extends ProgressState {}

class GetProgressCardSuccess extends ProgressState {
  final AssessmentResultResponse assessmentResult;
  GetProgressCardSuccess(this.assessmentResult);
}

class GetProgressCardFailed extends ProgressState {
  final String message;
  GetProgressCardFailed(this.message);
}
