import 'package:get_it/get_it.dart';

import '../data/datasources/team_remote_data_source.dart';
import '../data/repositories/team_repository_impl.dart';
import '../domain/repositories/team_repository.dart';
import '../domain/usecases/get_team_roster.dart';
import '../domain/usecases/get_team_schedule.dart';
import '../presentation/cubit/team_detail_cubit.dart';

void registerTeamsDi(GetIt getIt) {
  if (!getIt.isRegistered<TeamRemoteDataSource>()) {
    getIt.registerLazySingleton<TeamRemoteDataSource>(() => TeamRemoteDataSourceImpl());
  }
  if (!getIt.isRegistered<TeamRepository>()) {
    getIt.registerLazySingleton<TeamRepository>(() => TeamRepositoryImpl(getIt()));
  }
  getIt.registerFactory<GetTeamRoster>(() => GetTeamRoster(getIt()));
  getIt.registerFactory<GetTeamSchedule>(() => GetTeamSchedule(getIt()));
  getIt.registerFactory<TeamDetailCubit>(() => TeamDetailCubit(getIt(), getIt()));
}
