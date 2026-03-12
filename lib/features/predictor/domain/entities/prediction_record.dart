import 'package:nhl_app/features/matches/domain/entities/match_entity.dart';

class PredictionRecord {
  const PredictionRecord({
    required this.matchId,
    required this.homeTeam,
    required this.awayTeam,
    required this.winner,
    required this.overtime,
    required this.totalGoals,
    required this.exactScore,
    required this.timestamp,
    required this.status,
    this.matchStart,
    this.actualHomeScore,
    this.actualAwayScore,
    this.actualWentToOvertime,
    this.awardedPoints,
    this.success,
    this.perfect,
    this.homeAbbrev,
    this.awayAbbrev,
  });

  final String matchId;
  final String homeTeam;
  final String awayTeam;
  final String winner; // home/draw/away
  final bool overtime;
  final int totalGoals;
  final String exactScore;
  final DateTime timestamp;
  final MatchStatus status;
  final DateTime? matchStart;
  final int? actualHomeScore;
  final int? actualAwayScore;
  final bool? actualWentToOvertime;
  final int? awardedPoints;
  final bool? success;
  final bool? perfect;
  final String? homeAbbrev;
  final String? awayAbbrev;

  PredictionRecord copyWith({
    String? matchId,
    String? homeTeam,
    String? awayTeam,
    String? winner,
    bool? overtime,
    int? totalGoals,
    String? exactScore,
    DateTime? timestamp,
    MatchStatus? status,
    DateTime? matchStart,
    int? actualHomeScore,
    int? actualAwayScore,
    bool? actualWentToOvertime,
    int? awardedPoints,
    bool? success,
    bool? perfect,
    String? homeAbbrev,
    String? awayAbbrev,
  }) {
    return PredictionRecord(
      matchId: matchId ?? this.matchId,
      homeTeam: homeTeam ?? this.homeTeam,
      awayTeam: awayTeam ?? this.awayTeam,
      winner: winner ?? this.winner,
      overtime: overtime ?? this.overtime,
      totalGoals: totalGoals ?? this.totalGoals,
      exactScore: exactScore ?? this.exactScore,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      matchStart: matchStart ?? this.matchStart,
      actualHomeScore: actualHomeScore ?? this.actualHomeScore,
      actualAwayScore: actualAwayScore ?? this.actualAwayScore,
      actualWentToOvertime:
          actualWentToOvertime ?? this.actualWentToOvertime,
      awardedPoints: awardedPoints ?? this.awardedPoints,
      success: success ?? this.success,
      perfect: perfect ?? this.perfect,
      homeAbbrev: homeAbbrev ?? this.homeAbbrev,
      awayAbbrev: awayAbbrev ?? this.awayAbbrev,
    );
  }

  Map<String, dynamic> toMap() => {
        'matchId': matchId,
        'homeTeam': homeTeam,
        'awayTeam': awayTeam,
        'winner': winner,
        'overtime': overtime,
        'totalGoals': totalGoals,
        'exactScore': exactScore,
        'timestamp': timestamp.toIso8601String(),
        'status': status.name,
        'matchStart': matchStart?.toIso8601String(),
        'actualHomeScore': actualHomeScore,
        'actualAwayScore': actualAwayScore,
        'actualWentToOvertime': actualWentToOvertime,
        'awardedPoints': awardedPoints,
        'success': success,
        'perfect': perfect,
        'homeAbbrev': homeAbbrev,
        'awayAbbrev': awayAbbrev,
      };

  factory PredictionRecord.fromMap(Map<String, dynamic> map) {
    final statusName = map['status'] as String?;
    final status = MatchStatus.values.firstWhere(
      (e) => e.name == statusName,
      orElse: () => MatchStatus.finished,
    );
    return PredictionRecord(
      matchId: map['matchId'] as String? ?? '',
      homeTeam: map['homeTeam'] as String? ?? '',
      awayTeam: map['awayTeam'] as String? ?? '',
      winner: map['winner'] as String? ?? 'draw',
      overtime: (map['overtime'] as bool?) ?? false,
      totalGoals: (map['totalGoals'] as num?)?.toInt() ?? 0,
      exactScore: map['exactScore'] as String? ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ??
          DateTime.now(),
      status: status,
      matchStart: DateTime.tryParse(map['matchStart'] as String? ?? ''),
      actualHomeScore: (map['actualHomeScore'] as num?)?.toInt(),
      actualAwayScore: (map['actualAwayScore'] as num?)?.toInt(),
      actualWentToOvertime: map['actualWentToOvertime'] as bool?,
      awardedPoints: (map['awardedPoints'] as num?)?.toInt(),
      success: map['success'] as bool?,
      perfect: map['perfect'] as bool?,
      homeAbbrev: (map['homeAbbrev'] as String?)?.toUpperCase(),
      awayAbbrev: (map['awayAbbrev'] as String?)?.toUpperCase(),
    );
  }
}
