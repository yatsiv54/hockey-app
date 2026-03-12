import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class FavoritesLocalDataSource {
  Future<List<Map<String, dynamic>>> readTeams();
  Future<void> writeTeams(List<Map<String, dynamic>> data);
  Future<List<Map<String, dynamic>>> readGames();
  Future<void> writeGames(List<Map<String, dynamic>> data);
}

class FavoritesLocalDataSourceImpl implements FavoritesLocalDataSource {
  FavoritesLocalDataSourceImpl({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;
  final Map<String, List<Map<String, dynamic>>> _fallbackStore = {
    _teamsKey: <Map<String, dynamic>>[],
    _gamesKey: <Map<String, dynamic>>[],
  };

  Future<SharedPreferences?> get _prefsInstance async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
    } on PlatformException {
      _prefs = null;
    }
    return _prefs;
  }

  static const _teamsKey = 'favorite_teams';
  static const _gamesKey = 'favorite_games';

  @override
  Future<List<Map<String, dynamic>>> readTeams() async {
    final prefs = await _prefsInstance;
    if (prefs == null) {
      return List<Map<String, dynamic>>.from(_fallbackStore[_teamsKey]!);
    }
    final raw = prefs.getString(_teamsKey);
    if (raw == null || raw.isEmpty) return const [];
    final list = json.decode(raw) as List<dynamic>;
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  @override
  Future<void> writeTeams(List<Map<String, dynamic>> data) async {
    final prefs = await _prefsInstance;
    if (prefs == null) {
      _fallbackStore[_teamsKey] = data;
      return;
    }
    await prefs.setString(_teamsKey, json.encode(data));
  }

  @override
  Future<List<Map<String, dynamic>>> readGames() async {
    final prefs = await _prefsInstance;
    if (prefs == null) {
      return List<Map<String, dynamic>>.from(_fallbackStore[_gamesKey]!);
    }
    final raw = prefs.getString(_gamesKey);
    if (raw == null || raw.isEmpty) return const [];
    final list = json.decode(raw) as List<dynamic>;
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  @override
  Future<void> writeGames(List<Map<String, dynamic>> data) async {
    final prefs = await _prefsInstance;
    if (prefs == null) {
      _fallbackStore[_gamesKey] = data;
      return;
    }
    await prefs.setString(_gamesKey, json.encode(data));
}
}
