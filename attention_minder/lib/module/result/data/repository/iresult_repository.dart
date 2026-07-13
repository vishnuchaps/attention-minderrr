import 'package:attention_minder/module/result/data/model/assessment_history_model.dart';
import 'package:attention_minder/module/result/data/model/dashboard_management.dart';
import 'package:attention_minder/module/result/data/model/questionnaire_result_model.dart';
import 'package:attention_minder/module/result/data/model/result_weeklydetail.dart';

abstract class IResultRepository {
  Future<AssessmentHistoryResponse> fetchResult({int? page});

  Future<ManagementHistoryResponse> fetchQuestionnaireResult({int? page});

  Future<WeeklyProgressResponse> fetchManagementDashboard();
  Future<WeeklyManagementResponse> fetchResultWeeklyDetail();

}
