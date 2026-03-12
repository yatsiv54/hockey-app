class PlayerDetail {
  const PlayerDetail({
    required this.id,
    required this.name,
    required this.number,
    required this.position,
    required this.shoots,
    required this.dob,
    required this.country,
    required this.stats,
  });

  final int id;
  final String name;
  final String number;
  final String position;
  final String shoots;
  final String dob;
  final String country;
  final PlayerSeasonStats stats;
}

class PlayerSeasonStats {
  const PlayerSeasonStats({
    required this.gamesPlayed,
    required this.goals,
    required this.assists,
    required this.points,
    required this.plusMinus,
    required this.pim,
    required this.toiPerGame,
  });

  static const empty = PlayerSeasonStats(
    gamesPlayed: 0,
    goals: 0,
    assists: 0,
    points: 0,
    plusMinus: 0,
    pim: 0,
    toiPerGame: '--:--',
  );

  final int gamesPlayed;
  final int goals;
  final int assists;
  final int points;
  final int plusMinus;
  final int pim;
  final String toiPerGame;
}
