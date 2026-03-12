import 'package:get_it/get_it.dart';
import '../data/datasources/standings_remote_data_source.dart';
import '../data/repositories/standings_repository_impl.dart';
import '../domain/repositories/standings_repository.dart';
import '../domain/usecases/get_standings_now.dart';
import '../presentation/cubit/standings_cubit.dart';

void registerStandingsDi(GetIt getIt) {
  if (!getIt.isRegistered<StandingsRemoteDataSource>()) {
    getIt.registerLazySingleton<StandingsRemoteDataSource>(() => StandingsRemoteDataSourceImpl());
  }
  if (!getIt.isRegistered<StandingsRepository>()) {
    getIt.registerLazySingleton<StandingsRepository>(() => StandingsRepositoryImpl(getIt()));
  }
  getIt.registerFactory<GetStandingsNow>(() => GetStandingsNow(getIt()));
  getIt.registerFactory<StandingsCubit>(() => StandingsCubit(getIt()));
}

