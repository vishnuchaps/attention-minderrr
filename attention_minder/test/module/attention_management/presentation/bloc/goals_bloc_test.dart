import 'package:attention_minder/module/attention_management/data/model/ai_assessment_score_request.dart';
import 'package:attention_minder/module/attention_management/data/model/goal_submission.dart';
import 'package:attention_minder/module/attention_management/data/model/goals_model.dart';
import 'package:attention_minder/module/attention_management/data/repository/iai_assessment_score_repository.dart';
import 'package:attention_minder/module/attention_management/presentation/bloc/goals_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('LoadGoalsRequested emits the parsed goals response', () async {
    const response = GoalsResponse(isFirst: true, status: true);
    final bloc = GoalsBloc(_GoalsRepository(response: response));

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<GoalsLoading>(),
        isA<GoalsLoadSuccess>().having(
          (state) => state.response.isFirst,
          'isFirst',
          isTrue,
        ),
      ]),
    );
    bloc.add(const LoadGoalsRequested());

    await expectation;
    await bloc.close();
  });

  test('LoadGoalsRequested emits failure when loading throws', () async {
    final bloc = GoalsBloc(_GoalsRepository(error: Exception('offline')));

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([isA<GoalsLoading>(), isA<GoalsLoadFailure>()]),
    );
    bloc.add(const LoadGoalsRequested());

    await expectation;
    await bloc.close();
  });

  test('GoalsSet removes blank goals and emits success', () async {
    final repository = _GoalsRepository(setResult: {'message': 'Goals saved'});
    final bloc = GoalsBloc(repository);

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<GoalsSetInProgress>(),
        isA<GoalsSetSuccess>().having(
          (state) => state.message,
          'message',
          'Goals saved',
        ),
      ]),
    );
    bloc.add(
      const GoalsSet([
        GoalSubmission(goal: ' Improve focus ', rating: 4),
        GoalSubmission(goal: '   ', rating: 2),
      ]),
    );

    await expectation;
    expect(repository.receivedGoals, hasLength(1));
    expect(repository.receivedGoals!.single.goal, 'Improve focus');
    expect(repository.receivedGoals!.single.rating, 4);
    await bloc.close();
  });

  test(
    'GoalsSet rejects an empty submission without calling backend',
    () async {
      final repository = _GoalsRepository();
      final bloc = GoalsBloc(repository);

      final expectation = expectLater(
        bloc.stream,
        emits(isA<GoalsSetFailure>()),
      );
      bloc.add(
        const GoalsSet([
          GoalSubmission(goal: '', rating: 0),
          GoalSubmission(goal: '   ', rating: 0),
        ]),
      );

      await expectation;
      expect(repository.receivedGoals, isNull);
      await bloc.close();
    },
  );

  test(
    'GoalsEvaluationSubmitted preserves ids and individual ratings',
    () async {
      final repository = _GoalsRepository(
        setResult: {'message': 'Evaluation saved'},
      );
      final bloc = GoalsBloc(repository);

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([isA<GoalsSetInProgress>(), isA<GoalsSetSuccess>()]),
      );
      bloc.add(
        const GoalsEvaluationSubmitted([
          GoalSubmission(id: 1, goal: 'Improve daily focus', rating: 4),
          GoalSubmission(id: 2, goal: 'Complete course', rating: 5),
        ]),
      );

      await expectation;
      expect(repository.receivedEvaluation, hasLength(2));
      expect(repository.receivedEvaluation![0].id, 1);
      expect(repository.receivedEvaluation![0].rating, 4);
      expect(repository.receivedEvaluation![1].id, 2);
      expect(repository.receivedEvaluation![1].rating, 5);
      await bloc.close();
    },
  );
}

class _GoalsRepository implements IAiAssessmentScoreRepository {
  _GoalsRepository({this.response, this.error, this.setResult});

  final GoalsResponse? response;
  final Object? error;
  final Map<String, dynamic>? setResult;
  List<GoalSubmission>? receivedGoals;
  List<GoalSubmission>? receivedEvaluation;

  @override
  Future<GoalsResponse> getGoalsResponse() async {
    if (error case final error?) throw error;
    return response!;
  }

  @override
  Future<Map<String, dynamic>> saveScore(AiAssessmentScoreRequest request) =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> setGoals({
    required List<GoalSubmission> goals,
  }) async {
    if (error case final error?) throw error;
    receivedGoals = goals;
    return setResult ?? <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> updateGoalRatings({
    required List<GoalSubmission> goals,
  }) async {
    if (error case final error?) throw error;
    receivedEvaluation = goals;
    return setResult ?? <String, dynamic>{};
  }
}
