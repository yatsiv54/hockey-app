import 'package:flutter/foundation.dart';

import '../data/app_settings_storage.dart';
import '../domain/entities/app_settings.dart';

class AppSettingsController extends ChangeNotifier {
  AppSettingsController(this._storage);

  final AppSettingsStorage _storage;
  AppSettings _settings = AppSettings.initial();
  bool _initialized = false;

  AppSettings get value => _settings;
  bool get isInitialized => _initialized;

  Future<void> ensureLoaded() async {
    if (_initialized) return;
    _settings = await _storage.load();
    _initialized = true;
    notifyListeners();
  }

  Future<void> updateGoalAlerts(bool enabled) =>
      _update(_settings.copyWith(goalAlerts: enabled));

  Future<void> updateFinalScoreAlerts(bool enabled) =>
      _update(_settings.copyWith(finalScoreAlerts: enabled));

  Future<void> updatePredictorNotifications(bool enabled) =>
      _update(_settings.copyWith(predictorNotifications: enabled));

  Future<void> updateDefaultDate(DefaultDateOption option) =>
      _update(_settings.copyWith(defaultDate: option));

  Future<void> updatePreferredDate(DateTime? date) {
    final normalized =
        date == null ? null : DateTime(date.year, date.month, date.day);
    return _update(_settings.copyWith(preferredDate: normalized));
  }

  Future<void> resetToDefaults() => _update(AppSettings.initial());

  DateTime get baseDate =>
      _normalizeDate(_settings.preferredDate ?? DateTime.now());

  DateTime resolveDateFor(DefaultDateOption option) {
    final base = baseDate;
    switch (option) {
      case DefaultDateOption.today:
        return base;
      case DefaultDateOption.yesterday:
        return base.subtract(const Duration(days: 1));
      case DefaultDateOption.tomorrow:
        return base.add(const Duration(days: 1));
    }
  }

  Future<void> _update(AppSettings settings) async {
    _settings = settings;
    await _storage.save(settings);
    notifyListeners();
  }

  DateTime _normalizeDate(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
