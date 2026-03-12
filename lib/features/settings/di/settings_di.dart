import 'package:get_it/get_it.dart';

import '../application/app_settings_controller.dart';
import '../data/app_settings_storage.dart';

void registerSettingsDi(GetIt getIt) {
  if (!getIt.isRegistered<AppSettingsStorage>()) {
    getIt.registerLazySingleton<AppSettingsStorage>(
      () => AppSettingsStorage(),
    );
  }
  if (!getIt.isRegistered<AppSettingsController>()) {
    getIt.registerLazySingleton<AppSettingsController>(
      () => AppSettingsController(getIt<AppSettingsStorage>()),
    );
  }
}
