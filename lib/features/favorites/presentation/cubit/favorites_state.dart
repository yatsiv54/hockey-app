import 'package:equatable/equatable.dart';

import '../../domain/entities/favorite_game.dart';
import '../../domain/entities/favorite_team.dart';

enum FavoritesStatus { initial, loading, ready, error }

class FavoritesState extends Equatable {
  const FavoritesState({
    this.status = FavoritesStatus.initial,
    this.teams = const [],
    this.games = const [],
    this.message,
  });

  final FavoritesStatus status;
  final List<FavoriteTeam> teams;
  final List<FavoriteGame> games;
  final String? message;

  FavoritesState copyWith({
    FavoritesStatus? status,
    List<FavoriteTeam>? teams,
    List<FavoriteGame>? games,
    String? message,
  }) {
    return FavoritesState(
      status: status ?? this.status,
      teams: teams ?? this.teams,
      games: games ?? this.games,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, teams, games, message];
}
