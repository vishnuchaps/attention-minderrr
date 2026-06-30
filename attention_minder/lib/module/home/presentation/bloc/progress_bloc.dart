import 'package:attention_minder/module/home/data/model/progresscard_model.dart';
import 'package:attention_minder/module/home/data/repository/iprogress_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
// import 'package:meta/meta.dart';

part 'progress_event.dart';
part 'progress_state.dart';

@injectable
class ProgressBloc extends Bloc<ProgressEvent, ProgressState> {
  final IProgressRepository _progressRepository;

  ProgressBloc(this._progressRepository) : super(ProgressInitial()) {
    on<GetProgressCardEvent>(_onGetProgressCard);
  }
  void _onGetProgressCard(
    GetProgressCardEvent event,
    Emitter<ProgressState> emit,
  ) async {
    emit(ProgressLoading());
    try {
      final response = await _progressRepository.getProgressCard();
      emit(GetProgressCardSuccess(response));
    } catch (e) {
      emit(GetProgressCardFailed(e.toString()));
    }
  }
}
