import 'package:get_it/get_it.dart';
import 'package:nhl_app/features/matches/data/datasources/gamecenter_remote_data_source.dart';
import '../presentation/cubit/game_center_cubit.dart';

void registerGameCenterDi(GetIt getIt) {
  // GamecenterRemoteDataSource is registered in matches_di, but ensure it's there.
  if (!getIt.isRegistered<GamecenterRemoteDataSource>()) {
    getIt.registerLazySingleton<GamecenterRemoteDataSource>(() => GamecenterRemoteDataSource());
  }
  getIt.registerFactory<GameCenterCubit>(() => GameCenterCubit(getIt()));
}

