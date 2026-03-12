import 'package:get_it/get_it.dart';

import '../data/datasources/player_remote_data_source.dart';
import '../data/repositories/player_repository_impl.dart';
import '../domain/repositories/player_repository.dart';
import '../domain/usecases/get_player_detail.dart';
import '../presentation/cubit/player_detail_cubit.dart';

void registerPlayerDi(GetIt getIt) {
  if (!getIt.isRegistered<PlayerRemoteDataSource>()) {
    getIt.registerLazySingleton<PlayerRemoteDataSource>(
      () => PlayerRemoteDataSourceImpl(),
    );
  }
  if (!getIt.isRegistered<PlayerRepository>()) {
    getIt.registerLazySingleton<PlayerRepository>(
      () => PlayerRepositoryImpl(getIt()),
    );
  }
  getIt.registerFactory<GetPlayerDetail>(() => GetPlayerDetail(getIt()));
  getIt.registerFactory<PlayerDetailCubit>(() => PlayerDetailCubit(getIt()));
}
