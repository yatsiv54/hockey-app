import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nhl_app/features/matches/data/datasources/gamecenter_remote_data_source.dart';
import 'game_center_state.dart';

class GameCenterCubit extends Cubit<GameCenterState> {
  GameCenterCubit(this._remote) : super(const GameCenterInitial());

  final GamecenterRemoteDataSource _remote;
  Timer? _timer;

  Future<void> load(String gameId) async {
    emit(const GameCenterLoading());
    try {
      final detail = await _remote.fetchGameCenterData(gameId);
      emit(
        GameCenterLoaded(
          clock: detail.clock,
          periodText: detail.periodText,
          homeScore: detail.homeScore,
          awayScore: detail.awayScore,
          tv: detail.tv,
          radio: detail.radio,
          stats: detail.stats
              .map((s) => GameCenterStat(
                    label: s.label,
                    homeValue: s.homeValue,
                    awayValue: s.awayValue,
                  ))
              .toList(),
          playsTables: detail.playsTables.map(
            (key, value) => MapEntry(key, _toTable(value)),
          ),
          homeGoalies: _toTable(detail.homeGoalies),
          awayGoalies: _toTable(detail.awayGoalies),
          homeSkaters: _toTable(detail.homeSkaters),
          awaySkaters: _toTable(detail.awaySkaters),
          recapTable: _toTable(detail.recapTable),
          keyMoments: detail.keyMoments
              .map((km) => KeyMoment(
                    label: km.label,
                    team: km.team,
                    period: km.period,
                    time: km.time,
                    player: km.player,
                  ))
              .toList(),
          homeAbbr: detail.homeAbbr,
          awayAbbr: detail.awayAbbr,
          homeChance: detail.homeChance,
        ),
      );
      _startTicker(gameId);
    } catch (e) {
      emit(GameCenterError(e.toString()));
    }
  }

  void _startTicker(String gameId) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) async {
      try {
        final overlay = await _remote.fetchOverlay(gameId);
        if (overlay == null) return;
        final prev = state;
        if (prev is GameCenterLoaded) {
          emit(
            prev.copyWith(
              clock: overlay.clock ?? prev.clock,
              periodText: overlay.periodNumber != null
                  ? _formatPeriod(overlay.periodNumber!, overlay.periodType)
                  : prev.periodText,
              homeScore: overlay.home ?? prev.homeScore,
              awayScore: overlay.away ?? prev.awayScore,
            ),
          );
        }
      } catch (_) {}
    });
  }

  GameCenterTable _toTable(GameCenterTableDto dto) =>
      GameCenterTable(title: dto.title, headers: List<String>.from(dto.headers), rows: dto.rows.map((e) => List<String>.from(e)).toList());

  String _formatPeriod(int number, String? type) {
    final t = (type ?? 'REG').toUpperCase();
    if (t == 'OT') return 'OT';
    if (t == 'SO') return 'SO';
    switch (number) {
      case 1:
        return '1st';
      case 2:
        return '2nd';
      case 3:
        return '3rd';
      default:
        return '${number}th';
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
