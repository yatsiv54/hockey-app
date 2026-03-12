import 'package:equatable/equatable.dart';
import 'package:nhl_app/features/matches/domain/entities/match_entity.dart';

class FavoriteGame extends Equatable {
  const FavoriteGame({
    required this.gameId,
    required this.homeTeam,
    required this.awayTeam,
    this.homeLogo,
    this.awayLogo,
    required this.status,
    this.startTime,
    this.homeScore,
    this.awayScore,
    this.bellGoals = false,
    this.bellFinal = false,
  });

  final String gameId;
  final String homeTeam;
  final String awayTeam;
  final String? homeLogo;
  final String? awayLogo;
  final MatchStatus status;
  final DateTime? startTime;
  final int? homeScore;
  final int? awayScore;
  final bool bellGoals;
  final bool bellFinal;

  FavoriteGame copyWith({
    MatchStatus? status,
    DateTime? startTime,
    int? homeScore,
    int? awayScore,
    bool? bellGoals,
    bool? bellFinal,
  }) {
    return FavoriteGame(
      gameId: gameId,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      homeLogo: homeLogo,
      awayLogo: awayLogo,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      bellGoals: bellGoals ?? this.bellGoals,
      bellFinal: bellFinal ?? this.bellFinal,
    );
  }

  @override
  List<Object?> get props => [
        gameId,
        homeTeam,
        awayTeam,
        homeLogo,
        awayLogo,
        status,
        startTime,
        homeScore,
        awayScore,
        bellGoals,
        bellFinal,
      ];
}
