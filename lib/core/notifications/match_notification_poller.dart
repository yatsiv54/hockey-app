import 'dart:async';

import 'package:nhl_app/core/notifications/notification_service.dart';
import 'package:nhl_app/devtools/dev_flags.dart';
import 'package:nhl_app/features/matches/application/goal_alert_registry.dart';
import 'package:nhl_app/features/matches/data/datasources/gamecenter_remote_data_source.dart';
import 'package:nhl_app/features/matches/domain/entities/match_entity.dart';
import 'package:nhl_app/features/predictor/data/prediction_storage.dart';
import 'package:nhl_app/features/predictor/domain/entities/prediction_record.dart';
import 'package:nhl_app/features/predictor/domain/utils/prediction_result.dart';
import 'package:nhl_app/features/settings/application/app_settings_controller.dart';

class MatchNotificationPoller {
  MatchNotificationPoller(
    this._alerts,
    this._gamecenter,
    this._settings,
    this._notifications,
    this._predictionStorage,
  );

  final GoalAlertRegistry _alerts;
  final GamecenterRemoteDataSource _gamecenter;
  final AppSettingsController _settings;
  final NotificationService _notifications;
  final PredictionStorage _predictionStorage;

  Timer? _timer;
  bool _running = false;
  final Set<String> _finalNotified = <String>{};
  Duration get _interval =>
      enableDevTesterTools ? const Duration(seconds: 5) : const Duration(seconds: 45);

  Future<void> start() async {
    if (_running) return;
    _running = true;
    await _tick();
    _timer = Timer.periodic(_interval, (_) => _tick());
  }

  Future<void> _tick() async {
    await _alerts.ensureLoaded();
    final predictions = await _predictionStorage.load();
    final pendingPredictionIds = predictions
        .where((p) => p.status != MatchStatus.finished)
        .map((p) => p.matchId)
        .toSet();
    final ids = <String>{..._alerts.activeIds, ...pendingPredictionIds};
    if (ids.isEmpty) return;

    for (final id in ids) {
      final overlay = await _gamecenter.fetchOverlay(id);
      if (overlay == null) continue;
      final prediction = _findPrediction(predictions, id);
      final home = overlay.home ?? 0;
      final away = overlay.away ?? 0;
      final clock = overlay.clock;
      final periodType = overlay.periodType;
      final isFinal = _isFinalState(clock, periodType);

      if (isFinal) {
        await _handleFinal(
          matchId: id,
          home: home,
          away: away,
          prediction: prediction,
          periodType: periodType,
        );
      }
    }
  }

  bool _isFinalState(String? clock, String? periodType) {
    final c = clock?.toLowerCase().trim();
    if (c != null && c.contains('final')) return true;
    final p = periodType?.toUpperCase().trim();
    if (p == 'FINAL' || p == 'FINAL_OT' || p == 'FINAL_SO') return true;
    return false;
  }

  Future<void> _handleFinal({
    required String matchId,
    required int home,
    required int away,
    required PredictionRecord? prediction,
    String? periodType,
  }) async {
    if (_finalNotified.contains(matchId)) return;
    _finalNotified.add(matchId);

    if (_alerts.isEnabled(matchId) && _settings.value.finalScoreAlerts) {
      await _notifications.showFinalAlert(
        matchId: matchId,
        title: 'Final score',
        body: '$home : $away',
      );
    }

    if (prediction != null) {
      final outcome = evaluatePrediction(
        record: prediction,
        homeScore: home,
        awayScore: away,
        wentToOvertime: _wentToExtra(periodType),
      );
      await _predictionStorage.updateMatchStatus(
        prediction.matchId,
        MatchStatus.finished,
        outcome: outcome,
      );
      if (_settings.value.predictorNotifications) {
        final result = _winnerKey(home, away);
        final success = prediction.winner == result ||
            (result == 'draw' && prediction.winner == 'draw');
        final title = success ? 'Prediction won' : 'Prediction missed';
        final body =
            success ? 'Score $home:$away' : 'Final score $home:$away';
        await _notifications.showPredictorAlert(title: title, body: body);
      }
    }
  }

  PredictionRecord? _findPrediction(
    List<PredictionRecord> list,
    String matchId,
  ) {
    for (final record in list) {
      if (record.matchId == matchId) return record;
    }
    return null;
  }

  String _winnerKey(int home, int away) {
    if (home > away) return 'home';
    if (away > home) return 'away';
    return 'draw';
  }

  bool _wentToExtra(String? periodType) {
    final p = periodType?.toUpperCase().trim();
    if (p == null) return false;
    return p.contains('OT') || p.contains('SO');
  }

  Future<void> dispose() async {
    _timer?.cancel();
    _running = false;
  }
}
