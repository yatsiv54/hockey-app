import 'package:get_it/get_it.dart';
import 'package:nhl_app/core/network/network_info.dart';
import 'package:nhl_app/core/notifications/match_notification_poller.dart';
import 'package:nhl_app/core/notifications/notification_service.dart';
import 'package:nhl_app/core/router/router.dart';
import 'package:nhl_app/features/favorites/di/favorites_di.dart';
import 'package:nhl_app/features/game_center/di/game_center_di.dart';
import 'package:nhl_app/features/matches/application/goal_alert_registry.dart';
import 'package:nhl_app/features/matches/data/datasources/gamecenter_remote_data_source.dart';
import 'package:nhl_app/features/matches/di/matches_di.dart';
import 'package:nhl_app/features/player/di/player_di.dart';
import 'package:nhl_app/features/predictor/data/prediction_storage.dart';
import 'package:nhl_app/features/settings/application/app_settings_controller.dart';
import 'package:nhl_app/features/settings/di/settings_di.dart';
import 'package:nhl_app/features/standings/di/standings_di.dart';
import 'package:nhl_app/features/teams/di/teams_di.dart';
import 'package:nhl_app/features/welcome/data/welcome_storage.dart';


final getIt = GetIt.instance;

void configureDi() {
  if (!getIt.isRegistered<AppRouter>()) {
    getIt.registerLazySingleton<AppRouter>(() => AppRouter());
  }
  if (!getIt.isRegistered<NetworkInfo>()) {
    getIt.registerLazySingleton<NetworkInfo>(() => DummyNetworkInfo());
  }
  if (!getIt.isRegistered<NotificationService>()) {
    getIt.registerLazySingleton<NotificationService>(() => NotificationService());
  }
  if (!getIt.isRegistered<GoalAlertRegistry>()) {
    getIt.registerLazySingleton<GoalAlertRegistry>(() => GoalAlertRegistry());
  }
  if (!getIt.isRegistered<PredictionStorage>()) {
    getIt.registerLazySingleton<PredictionStorage>(() => PredictionStorage());
  }
  if (!getIt.isRegistered<WelcomeStorage>()) {
    getIt.registerLazySingleton<WelcomeStorage>(() => WelcomeStorage());
  }
  if (!getIt.isRegistered<MatchNotificationPoller>()) {
    getIt.registerLazySingleton<MatchNotificationPoller>(
      () => MatchNotificationPoller(
        getIt<GoalAlertRegistry>(),
        getIt<GamecenterRemoteDataSource>(),
        getIt<AppSettingsController>(),
        getIt<NotificationService>(),
        getIt<PredictionStorage>(),
      ),
    );
  }

  registerMatchesDi(getIt);
  registerStandingsDi(getIt);
  registerGameCenterDi(getIt);
  registerTeamsDi(getIt);
  registerPlayerDi(getIt);
  registerFavoritesDi(getIt);
  registerSettingsDi(getIt);
}
