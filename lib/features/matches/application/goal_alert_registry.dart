import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoalAlertRegistry extends ChangeNotifier {
  GoalAlertRegistry({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;
  bool _loaded = false;
  final Set<String> _matchIds = <String>{};

  static const _storageKey = 'goal_alert_subscriptions';

  bool get isInitialized => _loaded;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final stored = _prefs?.getStringList(_storageKey) ?? const <String>[];
      _matchIds
        ..clear()
        ..addAll(stored);
    } on PlatformException {
      _prefs = null;
    }
    _loaded = true;
  }

  bool isEnabled(String matchId) => _matchIds.contains(matchId);

  Set<String> get activeIds => Set.unmodifiable(_matchIds);

  Future<void> toggle(String matchId) async {
    await ensureLoaded();
    if (_matchIds.contains(matchId)) {
      _matchIds.remove(matchId);
    } else {
      _matchIds.add(matchId);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> setEnabled(String matchId, bool enabled) async {
    await ensureLoaded();
    final changed = enabled ? _matchIds.add(matchId) : _matchIds.remove(matchId);
    if (!changed) return;
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    if (_prefs == null) return;
    await _prefs!.setStringList(_storageKey, _matchIds.toList());
  }

  Future<void> clear() async {
    await ensureLoaded();
    if (_matchIds.isEmpty) return;
    _matchIds.clear();
    await _persist();
    notifyListeners();
  }
}
