import 'package:attention_minder/module/result/data/model/result_weeklydetail.dart';
import 'package:attention_minder/module/result/data/repository/iresult_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part 'result_detail_event.dart';
part 'result_detail_state.dart';

@injectable
class ResultDetailBloc extends Bloc<ResultDetailEvent, ResultDetailState> {
  final IResultRepository _resultRepository;

  ResultDetailBloc(this._resultRepository) : super(ResultDetailInitial()) {
    on<GetResultDetailEvent>(_onGetWeeklyDetailResult);
  }
  Future<void> _onGetWeeklyDetailResult(
    GetResultDetailEvent event,
    Emitter<ResultDetailState> emit,
  ) async {
    emit(GetResultDetailLoading());
    try {
      final response = await _resultRepository.fetchResultWeeklyDetail();
      emit(GetResultDetailSuccess(response));
    } catch (error) {
      emit(GetResultDetailFailed(error.toString()));
    }
  }
}
