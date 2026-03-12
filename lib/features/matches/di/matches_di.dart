import 'package:get_it/get_it.dart';
import 'package:nhl_app/core/notifications/notification_service.dart';
import 'package:nhl_app/features/matches/application/goal_alert_registry.dart';
import 'package:nhl_app/features/predictor/data/prediction_storage.dart';
import 'package:nhl_app/features/settings/application/app_settings_controller.dart';

import '../data/datasources/gamecenter_remote_data_source.dart';
import '../data/datasources/match_remote_data_source.dart';
import '../data/repositories/match_repository_impl.dart';
import '../domain/repositories/match_repository.dart';
import '../domain/usecases/get_finished_matches.dart';
import '../domain/usecases/get_live_matches.dart';
import '../domain/usecases/get_matches_by_date.dart';
import '../domain/usecases/get_upcoming_matches.dart';
import '../presentation/cubit/matches_cubit.dart';

void registerMatchesDi(GetIt getIt) {
  if (!getIt.isRegistered<MatchRemoteDataSource>()) {
    getIt.registerLazySingleton<MatchRemoteDataSource>(() => MatchRemoteDataSourceStub());
  }
  if (!getIt.isRegistered<GamecenterRemoteDataSource>()) {
    getIt.registerLazySingleton<GamecenterRemoteDataSource>(() => GamecenterRemoteDataSource());
  }
  if (!getIt.isRegistered<MatchRepository>()) {
    getIt.registerLazySingleton<MatchRepository>(() => MatchRepositoryImpl(getIt()));
  }
  getIt.registerFactory<GetUpcomingMatches>(() => GetUpcomingMatches(getIt()));
  getIt.registerFactory<GetMatchesByDate>(() => GetMatchesByDate(getIt()));
  getIt.registerFactory<GetLiveMatches>(() => GetLiveMatches(getIt()));
  getIt.registerFactory<GetFinishedMatches>(() => GetFinishedMatches(getIt()));
  getIt.registerFactory<MatchesCubit>(
    () => MatchesCubit(
      getIt(),
      getIt(),
      getIt(),
      getIt(),
      getIt(),
      getIt<GoalAlertRegistry>(),
      getIt<AppSettingsController>(),
      getIt<NotificationService>(),
      getIt<PredictionStorage>(),
    ),
  );
}

