// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:attention_minder/dependency_injection/preference_module.dart'
    as _i675;
import 'package:attention_minder/module/assigment/data/repository/assignment_repository.dart'
    as _i213;
import 'package:attention_minder/module/assigment/data/repository/iassignment_repository.dart'
    as _i979;
import 'package:attention_minder/module/assigment/presentation/bloc/assignment_bloc.dart'
    as _i310;
import 'package:attention_minder/module/attention_management/data/repository/ai_assessment_score_repository.dart'
    as _i1016;
import 'package:attention_minder/module/attention_management/data/repository/attention_management_repository.dart'
    as _i71;
import 'package:attention_minder/module/attention_management/data/repository/iai_assessment_score_repository.dart'
    as _i361;
import 'package:attention_minder/module/attention_management/data/repository/iattention_management_repository.dart'
    as _i546;
import 'package:attention_minder/module/attention_management/presentation/bloc/ai_assessment_score_bloc.dart'
    as _i90;
import 'package:attention_minder/module/attention_management/presentation/bloc/attention_management_bloc.dart'
    as _i730;
import 'package:attention_minder/module/authentication/data/repository/authentication_repository.dart'
    as _i972;
import 'package:attention_minder/module/authentication/data/repository/iauthentication_repository.dart'
    as _i707;
import 'package:attention_minder/module/authentication/data/service/social_auth_service.dart'
    as _i228;
import 'package:attention_minder/module/authentication/presentation/bloc/authentication_bloc.dart'
    as _i275;
import 'package:attention_minder/module/file_handler/data/repository/file_handler_repository.dart'
    as _i1069;
import 'package:attention_minder/module/file_handler/data/repository/ifile_handler_repository.dart'
    as _i115;
import 'package:attention_minder/module/file_handler/presentation/bloc/file_handler_bloc.dart'
    as _i220;
import 'package:attention_minder/module/home/data/repository/iprogress_repository.dart'
    as _i829;
import 'package:attention_minder/module/home/data/repository/progress_repository.dart'
    as _i991;
import 'package:attention_minder/module/home/presentation/bloc/progress_bloc.dart'
    as _i867;
import 'package:attention_minder/module/profile/data/repository/iprofile_repository.dart'
    as _i557;
import 'package:attention_minder/module/profile/data/repository/profile_repository.dart'
    as _i386;
import 'package:attention_minder/module/profile/presentation/bloc/profile_bloc.dart'
    as _i113;
import 'package:attention_minder/module/result/bloc/questionnaire_result_bloc.dart'
    as _i707;
import 'package:attention_minder/module/result/bloc/result_bloc.dart' as _i423;
import 'package:attention_minder/module/result/bloc/result_detail_bloc.dart'
    as _i829;
import 'package:attention_minder/module/result/data/repository/iresult_repository.dart'
    as _i789;
import 'package:attention_minder/module/result/data/repository/result_repository.dart'
    as _i761;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final preferenceModule = _$PreferenceModule();
    gh.factory<_i228.SocialAuthService>(() => _i228.SocialAuthService());
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => preferenceModule.prefs,
      preResolve: true,
    );
    gh.factory<_i557.IProfileRepository>(() => _i386.ProfileRepository());
    gh.factory<_i979.IAssignmentRepository>(() => _i213.AssignmentRepository());
    gh.factory<_i829.IProgressRepository>(() => _i991.ProgressRepository());
    gh.factory<_i113.ProfileBloc>(
        () => _i113.ProfileBloc(gh<_i557.IProfileRepository>()));
    gh.factory<_i546.IAttentionManagementRepository>(
        () => _i71.AttentionManagementRepository());
    gh.factory<_i730.AttentionManagementBloc>(() =>
        _i730.AttentionManagementBloc(
            gh<_i546.IAttentionManagementRepository>()));
    gh.factory<_i707.IAuthenticationRepository>(
        () => _i972.AuthenticationRepository());
    gh.factory<_i789.IResultRepository>(() => _i761.ResultRepository());
    gh.factory<_i867.ProgressBloc>(
        () => _i867.ProgressBloc(gh<_i829.IProgressRepository>()));
    gh.factory<_i115.IFileHandlerRepository>(
        () => _i1069.FileHandlerRepository());
    gh.factory<_i310.AssignmentBloc>(
        () => _i310.AssignmentBloc(gh<_i979.IAssignmentRepository>()));
    gh.factory<_i361.IAiAssessmentScoreRepository>(() =>
        _i1016.AiAssessmentScoreRepository(gh<_i460.SharedPreferences>()));
    gh.factory<_i275.AuthenticationBloc>(() => _i275.AuthenticationBloc(
          gh<_i707.IAuthenticationRepository>(),
          gh<_i228.SocialAuthService>(),
        ));
    gh.factory<_i423.ResultBloc>(
        () => _i423.ResultBloc(gh<_i789.IResultRepository>()));
    gh.factory<_i829.ResultDetailBloc>(
        () => _i829.ResultDetailBloc(gh<_i789.IResultRepository>()));
    gh.factory<_i707.QuestionnaireResultBloc>(
        () => _i707.QuestionnaireResultBloc(gh<_i789.IResultRepository>()));
    gh.factory<_i220.FileHandlerBloc>(
        () => _i220.FileHandlerBloc(gh<_i115.IFileHandlerRepository>()));
    gh.factory<_i90.AiAssessmentScoreBloc>(() =>
        _i90.AiAssessmentScoreBloc(gh<_i361.IAiAssessmentScoreRepository>()));
    return this;
  }
}

class _$PreferenceModule extends _i675.PreferenceModule {}
