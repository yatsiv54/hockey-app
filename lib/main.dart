import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nhl_app/core/notifications/match_notification_poller.dart';
import 'package:nhl_app/core/notifications/notification_service.dart';
import 'package:nhl_app/core/router/router.dart';
import 'package:nhl_app/core/theme/colors.dart';
import 'package:nhl_app/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:nhl_app/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:nhl_app/features/matches/application/goal_alert_registry.dart';
import 'package:nhl_app/features/matches/data/datasources/gamecenter_remote_data_source.dart';
import 'package:nhl_app/features/settings/application/app_settings_controller.dart';

import 'core/di/di.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureDi();
  await Future.wait([
    getIt<NotificationService>().init(),
    getIt<GoalAlertRegistry>().ensureLoaded(),
    getIt<AppSettingsController>().ensureLoaded(),
  ]);
  getIt<MatchNotificationPoller>().start();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final router = getIt<AppRouter>().router;
    return BlocProvider(
      create: (_) => FavoritesCubit(
        getIt<FavoritesRepository>(),
        getIt<GamecenterRemoteDataSource>(),
        getIt<GoalAlertRegistry>(),
      )..load(),
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Live NHL',
        theme: ThemeData(
          fontFamily: 'Arial',
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2E6AA0),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: CustomColors.backgroundColor,
        ),
        routerConfig: router,
      ),
    );
  }
}
