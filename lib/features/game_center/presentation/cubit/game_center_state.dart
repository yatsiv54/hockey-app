import 'package:equatable/equatable.dart';

class GameCenterState extends Equatable {
  const GameCenterState();
  @override
  List<Object?> get props => [];
}

class GameCenterInitial extends GameCenterState {
  const GameCenterInitial();
}

class GameCenterLoading extends GameCenterState {
  const GameCenterLoading();
}

class GameCenterError extends GameCenterState {
  const GameCenterError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class GameCenterLoaded extends GameCenterState {
  const GameCenterLoaded({
    required this.clock,
    required this.periodText,
    required this.homeScore,
    required this.awayScore,
    required this.tv,
    required this.radio,
    required this.stats,
    required this.playsTables,
    required this.homeGoalies,
    required this.awayGoalies,
    required this.homeSkaters,
    required this.awaySkaters,
    required this.recapTable,
    required this.keyMoments,
    required this.homeAbbr,
    required this.awayAbbr,
    required this.homeChance,
  });

  final String? clock;
  final String? periodText;
  final int? homeScore;
  final int? awayScore;
  final List<String> tv;
  final List<String> radio;
  final List<GameCenterStat> stats;
  final Map<String, GameCenterTable> playsTables;
  final GameCenterTable homeGoalies;
  final GameCenterTable awayGoalies;
  final GameCenterTable homeSkaters;
  final GameCenterTable awaySkaters;
  final GameCenterTable recapTable;
  final List<KeyMoment> keyMoments;
  final String homeAbbr;
  final String awayAbbr;
  final double homeChance;

  GameCenterLoaded copyWith({
    String? clock,
    String? periodText,
    int? homeScore,
    int? awayScore,
    double? homeChance,
  }) {
    return GameCenterLoaded(
      clock: clock ?? this.clock,
      periodText: periodText ?? this.periodText,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      tv: tv,
      radio: radio,
      stats: stats,
      playsTables: playsTables,
      homeGoalies: homeGoalies,
      awayGoalies: awayGoalies,
      homeSkaters: homeSkaters,
      awaySkaters: awaySkaters,
      recapTable: recapTable,
      keyMoments: keyMoments,
      homeAbbr: homeAbbr,
      awayAbbr: awayAbbr,
      homeChance: homeChance ?? this.homeChance,
    );
  }

  @override
  List<Object?> get props => [
        clock,
        periodText,
        homeScore,
        awayScore,
        tv,
        radio,
        stats,
        playsTables,
        homeGoalies,
        awayGoalies,
        homeSkaters,
        awaySkaters,
        recapTable,
        keyMoments,
        homeAbbr,
        awayAbbr,
        homeChance,
      ];
}

class GameCenterStat extends Equatable {
  const GameCenterStat({required this.label, required this.homeValue, required this.awayValue});
  final String label;
  final String homeValue;
  final String awayValue;
  @override
  List<Object?> get props => [label, homeValue, awayValue];
}

class GameCenterTable extends Equatable {
  const GameCenterTable({required this.title, required this.headers, required this.rows});
  final String title;
  final List<String> headers;
  final List<List<String>> rows;
  @override
  List<Object?> get props => [title, headers, rows];
}

class KeyMoment extends Equatable {
  const KeyMoment({required this.label, required this.team, required this.period, required this.time, required this.player});
  final String label;
  final String team;
  final String period;
  final String time;
  final String player;
  @override
  List<Object?> get props => [label, team, period, time, player];
}
