import 'dart:convert';

import 'package:nhl_app/features/matches/domain/entities/match_entity.dart';
import 'package:nhl_app/features/predictor/domain/utils/prediction_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/prediction_record.dart';

class PredictionStorage {
  PredictionStorage({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;
  static const _key = 'predictions_history';

  Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<List<PredictionRecord>> load() async {
    final prefs = await _instance;
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    final list = (jsonDecode(raw) as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(PredictionRecord.fromMap)
        .toList();
    return list;
  }

  Future<void> append(PredictionRecord record) async {
    final prefs = await _instance;
    final existing = await load();
    final updated = [...existing, record];
    final payload = jsonEncode(updated.map((e) => e.toMap()).toList());
    await prefs.setString(_key, payload);
  }

  Future<void> clear() async {
    final prefs = await _instance;
    await prefs.remove(_key);
  }

  Future<void> updateMatchStatus(
    String matchId,
    MatchStatus status, {
    PredictionResult? outcome,
  }) async {
    final prefs = await _instance;
    final existing = await load();
    final updated = existing
        .map(
          (record) => record.matchId == matchId
              ? record.copyWith(
                  status: status,
                  actualHomeScore: outcome?.homeScore ?? record.actualHomeScore,
                  actualAwayScore: outcome?.awayScore ?? record.actualAwayScore,
                  actualWentToOvertime:
                      outcome?.wentToOvertime ?? record.actualWentToOvertime,
                  awardedPoints: outcome?.points ?? record.awardedPoints,
                  success: outcome?.success ?? record.success,
                  perfect: outcome?.perfect ?? record.perfect,
                )
              : record,
        )
        .toList();
    final payload = jsonEncode(updated.map((e) => e.toMap()).toList());
    await prefs.setString(_key, payload);
  }
}
