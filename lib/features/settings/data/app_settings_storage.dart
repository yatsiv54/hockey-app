import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/app_settings.dart';

class AppSettingsStorage {
  AppSettingsStorage({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;
  static const _key = 'app_settings';

  Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<AppSettings> load() async {
    final prefs = await _instance;
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return AppSettings.initial();
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return AppSettings.fromMap(map);
    } catch (_) {
      return AppSettings.initial();
    }
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await _instance;
    await prefs.setString(_key, jsonEncode(settings.toMap()));
  }
}
