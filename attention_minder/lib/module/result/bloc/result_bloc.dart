import 'package:attention_minder/module/result/data/model/assessment_history_model.dart';
import 'package:attention_minder/module/result/data/model/dashboard_management.dart';
import 'package:attention_minder/module/result/data/repository/iresult_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part 'result_event.dart';
part 'result_state.dart';

@injectable
class ResultBloc extends Bloc<ResultEvent, ResultState> {
  final IResultRepository _resultRepository;
  ResultBloc(this._resultRepository) : super(ResultInitial()) {
    on<GetResultEvent>(_onGetResults);
    on<GetManagementDashboardEvent>(_onGetManagementDashboard);
  }
  void _onGetResults(GetResultEvent event, Emitter<ResultState> emit) async {
    emit(GetResultLoading());
    try {
      final response = await _resultRepository.fetchResult(page: event.page);
      emit(GetResultSuccess(response));
    } catch (e) {
      emit(GetResultFailed(e.toString()));
    }
  }

  Future<void> _onGetManagementDashboard(
    GetManagementDashboardEvent event,
    Emitter<ResultState> emit,
  ) async {
    emit(GetManagementDashboardLoading());
    try {
      final response = await _resultRepository.fetchManagementDashboard();
      emit(GetManagementDashboardSuccess(response));
    } catch (error) {
      emit(GetManagementDashboardFailed(error.toString()));
    }
  }
  
}
