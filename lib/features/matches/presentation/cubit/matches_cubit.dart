import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nhl_app/core/notifications/notification_service.dart';
import 'package:nhl_app/core/usecase/usecase.dart';
import 'package:nhl_app/features/matches/application/goal_alert_registry.dart';
import 'package:nhl_app/features/predictor/data/prediction_storage.dart';
import 'package:nhl_app/features/predictor/domain/entities/prediction_record.dart';
import 'package:nhl_app/features/predictor/domain/utils/prediction_result.dart';
import 'package:nhl_app/features/settings/application/app_settings_controller.dart';

import '../../data/datasources/gamecenter_remote_data_source.dart';
import '../../domain/entities/match_entity.dart';
import '../../domain/usecases/get_finished_matches.dart';
import '../../domain/usecases/get_live_matches.dart';
import '../../domain/usecases/get_matches_by_date.dart';
import '../../domain/usecases/get_upcoming_matches.dart';
import 'matches_state.dart';

class MatchesCubit extends Cubit<MatchesState> {
  MatchesCubit(
    this._getUpcoming,
    this._getLive,
    this._getFinished,
    this._getByDate,
    this._gamecenter,
    this._alerts,
    this._settings,
    this._notifications,
    this._predictionStorage,
  ) : super(const MatchesInitial()) {
    _alerts.addListener(_onAlertsChanged);
  }

  final GetUpcomingMatches _getUpcoming;
  final GetLiveMatches _getLive;
  final GetFinishedMatches _getFinished;
  final GetMatchesByDate _getByDate;
  final GamecenterRemoteDataSource _gamecenter;
  final GoalAlertRegistry _alerts;
  final AppSettingsController _settings;
  final NotificationService _notifications;
  final PredictionStorage _predictionStorage;

  List<MatchEntity> _lastItems = const [];
  final Set<String> _finalNotified = <String>{};
  final Map<String, MatchEntity> _devMatches = <String, MatchEntity>{};
  Timer? _liveTimer;
  bool _refreshing = false;

  Future<void> loadUpcoming() async {
    await _load(() => _getUpcoming(const NoParams()));
  }

  Future<void> loadLive() async {
    await _load(() => _getLive(const NoParams()));
  }

  Future<void> loadFinished() async {
    await _load(() => _getFinished(const NoParams()));
  }

  Future<void> loadByDate(DateTime date) async {
    await _alerts.ensureLoaded();
    await _load(() => _getByDate(date));
    await _startLiveTicker();
  }

  Future<void> _load(Future<dynamic> Function() loader) async {
    emit(const MatchesLoading());
    try {
      final dynamic raw = await loader();
      if (isClosed) return;
      final List<MatchEntity> data = List<MatchEntity>.from(raw as List);
      if (isClosed) return;
      _lastItems = [
        ..._devMatches.values,
        ...data,
      ];
      await _hydrateInitialSnapshots(_lastItems);
      emit(MatchesLoaded(List.from(_lastItems)));
    } catch (e) {
      if (isClosed) return;
      if (isClosed) return;
      emit(MatchesError(e.toString()));
    }
  }

  Future<void> _startLiveTicker() async {
    _liveTimer?.cancel();
    await _alerts.ensureLoaded();
    if (_lastItems.isEmpty && _alerts.activeIds.isEmpty) return;

    Future<void> refresh() async {
      if (_refreshing) return;
      _refreshing = true;
      if (isClosed) {
        _refreshing = false;
        return;
      }
      await _alerts.ensureLoaded();
      final predictions = await _predictionStorage.load();
      final pendingPredictionIds = predictions
          .where((p) => p.status != MatchStatus.finished)
          .map((p) => p.matchId)
          .toSet();

      final ids = <String>{..._alerts.activeIds, ...pendingPredictionIds};
      ids.addAll(
        _lastItems
            .where((m) => m.status != MatchStatus.finished)
            .map((m) => m.id),
      );
      if (ids.isEmpty) {
        _refreshing = false;
        return;
      }
      bool changed = false;

      for (final id in ids) {
        if (isClosed) {
          _refreshing = false;
          return;
        }
        final overlay = await _gamecenter.fetchOverlay(id);
        if (isClosed) {
          _refreshing = false;
          return;
        }
        if (overlay == null) continue;
        final idx = _lastItems.indexWhere((m) => m.id == id);
        final match = idx == -1 ? null : _lastItems[idx];
        final predictionRecord = _findPrediction(predictions, id);

        final prevHome = match?.scoreHome ?? 0;
        final prevAway = match?.scoreAway ?? 0;
        final nextHome = overlay.home ?? prevHome;
        final nextAway = overlay.away ?? prevAway;
        final nextClock = overlay.clock ?? match?.clock;
        final nextPeriodNumber = overlay.periodNumber ?? match?.periodNumber;
        final nextPeriodType = overlay.periodType ?? match?.periodType;
        final isFinal = _isFinalState(nextClock, nextPeriodType);

        if (match != null) {
          final updated = _applyOverlaySnapshot(match, (
            home: overlay.home,
            away: overlay.away,
            clock: overlay.clock,
            periodNumber: overlay.periodNumber,
            periodType: overlay.periodType,
          ));

          if (nextHome != prevHome ||
              nextAway != prevAway ||
              nextClock != match.clock ||
              nextPeriodNumber != match.periodNumber ||
              nextPeriodType != match.periodType ||
              updated.status != match.status) {
            changed = true;
          }

          _lastItems[idx] = updated;
          if (_devMatches.containsKey(updated.id)) {
            _devMatches[updated.id] = updated;
          }
          await _maybeNotifyGoal(
            updated,
            prevHome,
            prevAway,
            nextHome,
            nextAway,
          );
          if (isFinal) {
            await _maybeNotifyFinal(
              match: updated,
              homeScore: nextHome,
              awayScore: nextAway,
              prediction: predictionRecord,
              wentToOvertime: _wentToExtra(nextPeriodType),
            );
          }
        } else if (isFinal && predictionRecord != null) {
          await _maybeNotifyFinal(
            match: null,
            homeScore: nextHome,
            awayScore: nextAway,
            prediction: predictionRecord,
            wentToOvertime: _wentToExtra(nextPeriodType),
          );
        }
      }

      if (changed) {
        if (isClosed) {
          _refreshing = false;
          return;
        }
        emit(MatchesLoaded(List.from(_lastItems)));
      }
      _refreshing = false;
    }

    await refresh();
    if (isClosed) return;
    _liveTimer = Timer.periodic(const Duration(seconds: 10), (_) => refresh());
  }

  bool _isFinalState(String? clock, String? periodType) {
    final c = clock?.toLowerCase().trim();
    final p = periodType?.toUpperCase().trim();
    return c == 'final' || p == 'FINAL';
  }

  Future<void> _hydrateInitialSnapshots(List<MatchEntity> matches) async {
    final pending =
        matches.where((m) => m.status != MatchStatus.finished).toList();
    if (pending.isEmpty) return;
    await Future.wait(
      pending.map((match) async {
        final overlay = await _gamecenter.fetchOverlay(match.id);
        if (overlay == null) return;
        final idx = matches.indexWhere((m) => m.id == match.id);
        if (idx == -1) return;
        final updated = _applyOverlaySnapshot(
          matches[idx],
          (
            home: overlay.home,
            away: overlay.away,
            clock: overlay.clock,
            periodNumber: overlay.periodNumber,
            periodType: overlay.periodType,
          ),
        );
        if (updated != matches[idx]) {
          matches[idx] = updated;
        }
      }),
    );
  }

  MatchEntity _applyOverlaySnapshot(
    MatchEntity match,
    ({
      String? clock,
      int? periodNumber,
      String? periodType,
      int? home,
      int? away,
    }) overlay,
  ) {
    final nextHome = overlay.home ?? match.scoreHome;
    final nextAway = overlay.away ?? match.scoreAway;
    final nextClock = overlay.clock ?? match.clock;
    final nextPeriodNumber = overlay.periodNumber ?? match.periodNumber;
    final nextPeriodType = overlay.periodType ?? match.periodType;
    final isFinal = _isFinalState(nextClock, nextPeriodType);
    return match.copyWith(
      scoreHome: nextHome,
      scoreAway: nextAway,
      clock: nextClock,
      periodNumber: nextPeriodNumber,
      periodType: nextPeriodType,
      status: isFinal ? MatchStatus.finished : match.status,
    );
  }

  Future<void> _maybeNotifyGoal(
    MatchEntity match,
    int prevHome,
    int prevAway,
    int nextHome,
    int nextAway,
  ) async {
    if (!_settings.value.goalAlerts) return;
    if (!_alerts.isEnabled(match.id)) return;
    final homeDelta = nextHome - prevHome;
    final awayDelta = nextAway - prevAway;
    if (homeDelta <= 0 && awayDelta <= 0) return;
    if (homeDelta > 0) {
      await _notifications.showGoalAlert(
        matchId: match.id,
        title: '${match.homeTeam} scored!',
        body: '${match.homeTeam} $nextHome - ${match.awayTeam} $nextAway',
      );
    }
    if (awayDelta > 0) {
      await _notifications.showGoalAlert(
        matchId: match.id,
        title: '${match.awayTeam} scored!',
        body: '${match.homeTeam} $nextHome - ${match.awayTeam} $nextAway',
      );
    }
  }

  Future<void> _maybeNotifyFinal({
    required MatchEntity? match,
    required int homeScore,
    required int awayScore,
    required PredictionRecord? prediction,
    bool? wentToOvertime,
  }) async {
    final matchId = match?.id ?? prediction?.matchId;
    if (matchId == null) return;
    if (_finalNotified.contains(matchId)) return;
    _finalNotified.add(matchId);

    if (match != null &&
        _settings.value.finalScoreAlerts &&
        _alerts.isEnabled(matchId)) {
      await _notifications.showFinalAlert(
        matchId: matchId,
        title: 'Final: ${match.homeTeam} vs ${match.awayTeam}',
        body: '${match.homeTeam} $homeScore - ${match.awayTeam} $awayScore',
      );
    }

    if (prediction != null) {
      final actualOvertime = wentToOvertime ?? _wentToExtra(match?.periodType);
      final outcome = evaluatePrediction(
        record: prediction,
        homeScore: homeScore,
        awayScore: awayScore,
        wentToOvertime: actualOvertime,
      );
      await _predictionStorage.updateMatchStatus(
        prediction.matchId,
        MatchStatus.finished,
        outcome: outcome,
      );
      if (_settings.value.predictorNotifications) {
        final result = _winnerKey(homeScore, awayScore);
        final success = prediction.winner == result ||
            (result == 'draw' && prediction.winner == 'draw');
        final title = success
            ? 'You nailed ${prediction.homeTeam} vs ${prediction.awayTeam}!'
            : 'Prediction missed for ${prediction.homeTeam} vs ${prediction.awayTeam}';
        final body = success
            ? 'Final score $homeScore-$awayScore.'
            : 'Final score $homeScore-$awayScore. Better luck next time.';
        await _notifications.showPredictorAlert(title: title, body: body);
      }
    }
  }

  String _winnerKey(int home, int away) {
    if (home > away) return 'home';
    if (away > home) return 'away';
    return 'draw';
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

  void _onAlertsChanged() {
    if (_lastItems.isEmpty) return;
    _startLiveTicker();
  }

  bool _wentToExtra(String? periodType) {
    final t = periodType?.toUpperCase().trim();
    if (t == null) return false;
    return t.contains('OT') || t.contains('SO');
  }

  void addDevMatch(MatchEntity match) {
    _devMatches[match.id] = match;
    _lastItems = [match, ..._lastItems];
    emit(MatchesLoaded(List.from(_lastItems)));
    _startLiveTicker();
  }

  @override
  Future<void> close() {
    _liveTimer?.cancel();
    _alerts.removeListener(_onAlertsChanged);
    return super.close();
  }
}
