import 'package:shared_preferences/shared_preferences.dart';

class WelcomeStorage {
  WelcomeStorage({SharedPreferences? prefs}) : _prefs = prefs;

  static const _key = 'welcome_completed';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<bool> isCompleted() async {
    final prefs = await _instance;
    return prefs.getBool(_key) ?? false;
  }

  Future<void> markCompleted() async {
    final prefs = await _instance;
    await prefs.setBool(_key, true);
  }

  Future<void> reset() async {
    final prefs = await _instance;
    await prefs.remove(_key);
  }
}
