class MatchEntity {
  const MatchEntity({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.status,
    this.startTime,
    this.scoreHome,
    this.scoreAway,
    this.homeLogo,
    this.awayLogo,
    this.periodNumber,
    this.periodType,
    this.clock,
    this.homeAbbrev,
    this.awayAbbrev,
  });

  final String id;
  final String homeTeam;
  final String awayTeam;
  final MatchStatus status;
  final DateTime? startTime;
  final int? scoreHome;
  final int? scoreAway;
  final String? homeLogo;
  final String? awayLogo;
  final int? periodNumber; // 1,2,3,4
  final String? periodType; // REG/OT/SO
  final String? clock; // e.g. 05:13 for LIVE
  final String? homeAbbrev;
  final String? awayAbbrev;

  MatchEntity copyWith({
    String? id,
    String? homeTeam,
    String? awayTeam,
    MatchStatus? status,
    DateTime? startTime,
    int? scoreHome,
    int? scoreAway,
    String? homeLogo,
    String? awayLogo,
    int? periodNumber,
    String? periodType,
    String? clock,
    String? homeAbbrev,
    String? awayAbbrev,
  }) {
    return MatchEntity(
      id: id ?? this.id,
      homeTeam: homeTeam ?? this.homeTeam,
      awayTeam: awayTeam ?? this.awayTeam,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      scoreHome: scoreHome ?? this.scoreHome,
      scoreAway: scoreAway ?? this.scoreAway,
      homeLogo: homeLogo ?? this.homeLogo,
      awayLogo: awayLogo ?? this.awayLogo,
      periodNumber: periodNumber ?? this.periodNumber,
      periodType: periodType ?? this.periodType,
      clock: clock ?? this.clock,
      homeAbbrev: homeAbbrev ?? this.homeAbbrev,
      awayAbbrev: awayAbbrev ?? this.awayAbbrev,
    );
  }
}

enum MatchStatus { upcoming, live, finished }
