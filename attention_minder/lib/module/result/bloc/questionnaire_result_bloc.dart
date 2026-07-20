import 'package:attention_minder/module/result/data/model/questionnaire_result_model.dart';
import 'package:attention_minder/module/result/data/repository/iresult_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
part 'questionnaire_result_event.dart';
part 'questionnaire_result_state.dart';

@injectable
class QuestionnaireResultBloc
    extends Bloc<QuestionnaireResultEvent, QuestionnaireResultState> {
  final IResultRepository _resultRepository;

  QuestionnaireResultBloc(this._resultRepository)
    : super(QuestionnaireResultInitial()) {
    on<GetQuestionnaireResultEvent>(_onGetQuestionnaireResults);
  }

  void _onGetQuestionnaireResults(
    GetQuestionnaireResultEvent event,
    Emitter<QuestionnaireResultState> emit,
  ) async {
    emit(QuestionnaireResultLoading());
    try {
      final response = await _resultRepository.fetchQuestionnaireResult(
        page: event.page,
      );
      emit(QuestionnaireResultSuccess(response));
    } catch (e) {
      emit(QuestionnaireResultFailed(e.toString()));
    }
  }
}
