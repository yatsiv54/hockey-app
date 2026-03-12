import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nhl_app/features/matches/data/datasources/gamecenter_remote_data_source.dart';
import 'package:nhl_app/features/matches/domain/entities/match_entity.dart';

import '../../domain/entities/favorite_game.dart';
import '../../domain/entities/favorite_team.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../../domain/utils/logo_utils.dart';
import '../../../matches/application/goal_alert_registry.dart';
import 'favorites_state.dart';

class FavoritesCubit extends Cubit<FavoritesState> {
  FavoritesCubit(
    this._repository,
    this._gamecenter,
    this._alerts,
  ) : super(const FavoritesState());

  final FavoritesRepository _repository;
  final GamecenterRemoteDataSource _gamecenter;
  final GoalAlertRegistry _alerts;
  bool _loaded = false;
  Timer? _ticker;
  bool _refreshing = false;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    emit(state.copyWith(status: FavoritesStatus.loading));
    try {
      await _alerts.ensureLoaded();
      final teams = await _repository.loadTeams();
      bool changed = false;
      final patchedTeams = teams
          .map((t) {
            if (t.logoUrl == null || t.logoUrl!.isEmpty) {
              changed = true;
              return t.copyWith(logoUrl: logoUrlFromAbbrev(t.abbrev));
            }
            return t;
          })
          .toList();
      if (changed) {
        await _repository.saveTeams(patchedTeams);
      }
      final games = await _repository.loadGames();
      final newState =
        state.copyWith(
          status: FavoritesStatus.ready,
          teams: patchedTeams,
          games: games,
        );
      emit(newState);
      _startOverlayTicker();
    } catch (e) {
      emit(
        state.copyWith(
          status: FavoritesStatus.error,
          message: e.toString(),
        ),
      );
    }
  }

  Future<void> toggleTeam(FavoriteTeam team) async {
    final exists = state.teams.any((t) => t.abbrev == team.abbrev);
    final normalized = team.logoUrl == null || team.logoUrl!.isEmpty
        ? team.copyWith(logoUrl: logoUrlFromAbbrev(team.abbrev))
        : team;
    final updated = exists
        ? state.teams.where((t) => t.abbrev != team.abbrev).toList()
        : [...state.teams, normalized];
    emit(state.copyWith(teams: updated));
    await _repository.saveTeams(updated);
  }

  Future<void> toggleGame(FavoriteGame game) async {
    final exists = state.games.any((g) => g.gameId == game.gameId);
    final updated = exists
        ? state.games.where((g) => g.gameId != game.gameId).toList()
        : [...state.games.where((g) => g.gameId != game.gameId), game];
    emit(state.copyWith(games: updated));
    await _repository.saveGames(updated);
    if (exists) {
      await _alerts.setEnabled(game.gameId, false);
    } else {
      final enable = game.bellGoals || game.bellFinal;
      if (enable) {
        await _alerts.setEnabled(game.gameId, true);
      }
    }
    _startOverlayTicker();
  }

  Future<void> updateGameNotification(
    String gameId, {
    bool? bellGoals,
    bool? bellFinal,
  }) async {
    final updated = state.games.map((g) {
      if (g.gameId != gameId) return g;
      return g.copyWith(
        bellGoals: bellGoals ?? g.bellGoals,
        bellFinal: bellFinal ?? g.bellFinal,
      );
    }).toList();
    emit(state.copyWith(games: updated));
    await _repository.saveGames(updated);
    final game = updated.firstWhere((g) => g.gameId == gameId);
    final shouldEnable = game.bellGoals || game.bellFinal;
    await _alerts.setEnabled(gameId, shouldEnable);
  }

  bool isTeamFavorite(String abbrev) =>
      state.teams.any((element) => element.abbrev == abbrev);

  bool isGameFavorite(String gameId) =>
      state.games.any((element) => element.gameId == gameId);

  Future<void> clearAll() async {
    _ticker?.cancel();
    final ids = state.games.map((g) => g.gameId).toList();
    for (final id in ids) {
      await _alerts.setEnabled(id, false);
    }
    await _repository.saveTeams(const []);
    await _repository.saveGames(const []);
    emit(state.copyWith(teams: const [], games: const []));
  }

  void _startOverlayTicker() {
    _ticker?.cancel();
    if (state.games.isEmpty) return;

    Future<void> refresh() async {
      if (_refreshing) return;
      _refreshing = true;
      bool changed = false;
      final updated = <FavoriteGame>[];
      for (final game in state.games) {
        final overlay = await _gamecenter.fetchOverlay(game.gameId);
        if (overlay == null) {
          updated.add(game);
          continue;
        }
        final status = _statusFromOverlay(overlay, game.status);
        final homeScore = overlay.home ?? game.homeScore;
        final awayScore = overlay.away ?? game.awayScore;
        final next = game.copyWith(
          status: status,
          homeScore: homeScore,
          awayScore: awayScore,
        );
        if (next != game) changed = true;
        updated.add(next);
      }
      if (changed) {
        emit(state.copyWith(games: updated));
        await _repository.saveGames(updated);
      }
      _refreshing = false;
    }

    refresh();
    _ticker = Timer.periodic(const Duration(seconds: 20), (_) => refresh());
  }

  MatchStatus _statusFromOverlay(
    ({String? clock, int? periodNumber, String? periodType, int? home, int? away})
        overlay,
    MatchStatus current,
  ) {
    final clock = overlay.clock?.toLowerCase().trim();
    final periodType = overlay.periodType?.toUpperCase().trim();
    if (clock == 'final' || periodType == 'FINAL') {
      return MatchStatus.finished;
    }
    if (clock != null && clock.isNotEmpty) {
      return MatchStatus.live;
    }
    return current;
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    return super.close();
  }
}
