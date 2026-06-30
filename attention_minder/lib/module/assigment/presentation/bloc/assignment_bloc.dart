import 'package:attention_minder/module/assigment/data/model/article_model.dart';
import 'package:attention_minder/module/assigment/data/repository/iassignment_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../data/model/question_model.dart';

part 'assignment_event.dart';

part 'assignment_state.dart';

@injectable
class AssignmentBloc extends Bloc<AssignmentEvent, AssignmentState> {
  final IAssignmentRepository _assignmentRepository;
  BlogResponse? _articleResponse;
  String? _articleError;
  bool _isFetchingArticles = false;
  bool _isFetchingNextArticlePage = false;
  int _articlePage = 1;

  BlogResponse? get articleResponse => _articleResponse;
  String? get articleError => _articleError;
  bool get isFetchingArticles => _isFetchingArticles;
  bool get isFetchingNextArticlePage => _isFetchingNextArticlePage;
  int get articlePage => _articlePage;
  bool get hasMoreArticles {
    final next = _articleResponse?.data?.links?.next?.trim() ?? '';
    return next.isNotEmpty;
  }

  AssignmentBloc(this._assignmentRepository) : super(AssignmentInitial()) {
    on<GetTheQuestion>(_onFetchingQuestions);
    on<QuestionSubmission>(_onSubmitAnswer);
    on<FetchAssessmentResults>(_onFetchAssessmentResults);
    on<GetArticleListEvent>(_onGetArticles);
  }

  void _onFetchingQuestions(
    GetTheQuestion event,
    Emitter<AssignmentState> emit,
  ) async {
    emit(AssignmentLoading());
    try {
      final response = await _assignmentRepository.getUserQuestion();
      final Data userData = Data.fromJson(response['data']);

      emit(FetchQuestionSuccess(userData));
    } catch (e) {
      emit(FetchQuestionFailed(e.toString()));
    }
  }

  void _onSubmitAnswer(
    QuestionSubmission event,
    Emitter<AssignmentState> emit,
  ) async {
    if (event.showLoading) {
      emit(AssignmentLoading());
    }

    try {
      final response = await _assignmentRepository.saveQuestionResponse(
        answers: event.answer,
      );
      emit(
        SaveAnswerSuccess(
          response['message'],
          navigateToResult: event.navigateToResult,
        ),
      );
    } catch (e) {
      emit(SaveAnswerFailed(e.toString()));
    }
  }

  void _onFetchAssessmentResults(
    FetchAssessmentResults event,
    Emitter<AssignmentState> emit,
  ) async {
    emit(AssignmentLoading());

    try {
      final response = await _assignmentRepository.fetchAssessmentResult(
        page: event.page,
      );
      emit(FetchResultsSuccess(response));
    } catch (e) {
      emit(FetchResultsFailed(e.toString()));
    }
  }

  void _onGetArticles(
    GetArticleListEvent event,
    Emitter<AssignmentState> emit,
  ) async {
    if (!event.append && !event.forceRefresh && _articleResponse != null) {
      emit(GetArticlesSuccess(_articleResponse!));
      return;
    }

    if (event.append && !hasMoreArticles) return;
    if (_isFetchingArticles || _isFetchingNextArticlePage) return;

    if (event.append) {
      _isFetchingNextArticlePage = true;
    } else {
      _isFetchingArticles = true;
    }
    _articleError = null;
    emit(GetArticlesLoading(isPagination: event.append));

    try {
      final response = await _assignmentRepository.getArticles(
        page: event.page,
      );
      _articleResponse = event.append && _articleResponse != null
          ? _mergedArticleResponse(_articleResponse!, response)
          : response;
      _articlePage = event.page;
      _articleError = null;
      _isFetchingArticles = false;
      _isFetchingNextArticlePage = false;
      emit(GetArticlesSuccess(_articleResponse!));
    } catch (e) {
      _articleError = e.toString();
      _isFetchingArticles = false;
      _isFetchingNextArticlePage = false;
      emit(GetArticlesFailed(_articleError!));
    }
  }

  BlogResponse _mergedArticleResponse(BlogResponse current, BlogResponse next) {
    final currentResults = current.data?.results ?? const <Blog>[];
    final nextResults = next.data?.results ?? const <Blog>[];
    final existingIds = currentResults.map((article) => article.id).toSet();
    final uniqueNextResults = nextResults
        .where((article) => !existingIds.contains(article.id))
        .toList(growable: false);

    return BlogResponse(
      status: next.status,
      statusCode: next.statusCode,
      message: next.message,
      errors: next.errors,
      data: BlogData(
        links: next.data?.links,
        count: next.data?.count ?? current.data?.count,
        heading: next.data?.heading ?? current.data?.heading,
        results: [...currentResults, ...uniqueNextResults],
      ),
    );
  }
}
