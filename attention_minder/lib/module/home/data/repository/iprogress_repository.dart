import 'package:attention_minder/module/home/data/model/progresscard_model.dart';

abstract class IProgressRepository {
  Future<AssessmentResultResponse> getProgressCard();
}
