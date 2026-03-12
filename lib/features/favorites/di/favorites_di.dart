import 'package:get_it/get_it.dart';

import '../data/datasources/favorites_local_data_source.dart';
import '../data/repositories/favorites_repository_impl.dart';
import '../domain/repositories/favorites_repository.dart';

void registerFavoritesDi(GetIt getIt) {
  if (!getIt.isRegistered<FavoritesLocalDataSource>()) {
    getIt.registerLazySingleton<FavoritesLocalDataSource>(
      () => FavoritesLocalDataSourceImpl(),
    );
  }
  if (!getIt.isRegistered<FavoritesRepository>()) {
    getIt.registerLazySingleton<FavoritesRepository>(
      () => FavoritesRepositoryImpl(getIt()),
    );
  }
}
