import 'package:nhl_app/features/matches/domain/entities/match_entity.dart';

import '../../domain/entities/favorite_game.dart';

class FavoriteGameModel extends FavoriteGame {
  const FavoriteGameModel({
    required super.gameId,
    required super.homeTeam,
    required super.awayTeam,
    super.homeLogo,
    super.awayLogo,
    required super.status,
    super.startTime,
    super.homeScore,
    super.awayScore,
    super.bellGoals,
    super.bellFinal,
  });

  factory FavoriteGameModel.fromMap(Map<String, dynamic> map) {
    return FavoriteGameModel(
      gameId: map['gameId'] as String? ?? '',
      homeTeam: map['homeTeam'] as String? ?? '',
      awayTeam: map['awayTeam'] as String? ?? '',
      homeLogo: map['homeLogo'] as String?,
      awayLogo: map['awayLogo'] as String?,
      status: MatchStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => MatchStatus.upcoming,
      ),
      startTime: map['startTime'] != null ? DateTime.tryParse(map['startTime'] as String) : null,
      homeScore: map['homeScore'] as int?,
      awayScore: map['awayScore'] as int?,
      bellGoals: (map['bellGoals'] as bool?) ?? false,
      bellFinal: (map['bellFinal'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'gameId': gameId,
        'homeTeam': homeTeam,
        'awayTeam': awayTeam,
        'homeLogo': homeLogo,
        'awayLogo': awayLogo,
        'status': status.name,
        'startTime': startTime?.toIso8601String(),
        'homeScore': homeScore,
        'awayScore': awayScore,
        'bellGoals': bellGoals,
        'bellFinal': bellFinal,
      };

  static FavoriteGameModel fromEntity(FavoriteGame game) => FavoriteGameModel(
        gameId: game.gameId,
        homeTeam: game.homeTeam,
        awayTeam: game.awayTeam,
        homeLogo: game.homeLogo,
        awayLogo: game.awayLogo,
        status: game.status,
        startTime: game.startTime,
        homeScore: game.homeScore,
        awayScore: game.awayScore,
        bellGoals: game.bellGoals,
        bellFinal: game.bellFinal,
      );
}
