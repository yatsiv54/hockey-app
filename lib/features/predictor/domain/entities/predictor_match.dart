import 'package:nhl_app/features/matches/domain/entities/match_entity.dart';

class PredictorMatch {
  const PredictorMatch({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.status,
    this.startTime,
    this.homeLogo,
    this.awayLogo,
    this.venue,
    this.homeAbbrev,
    this.awayAbbrev,
  });

  final String id;
  final String homeTeam;
  final String awayTeam;
  final MatchStatus status;
  final DateTime? startTime;
  final String? homeLogo;
  final String? awayLogo;
  final String? venue;
  final String? homeAbbrev;
  final String? awayAbbrev;

  factory PredictorMatch.fromMatch(MatchEntity match, {String? venue}) {
    return PredictorMatch(
      id: match.id,
      homeTeam: match.homeTeam,
      awayTeam: match.awayTeam,
      status: match.status,
      startTime: match.startTime,
      homeLogo: match.homeLogo,
      awayLogo: match.awayLogo,
      venue: venue,
      homeAbbrev: match.homeAbbrev,
      awayAbbrev: match.awayAbbrev,
    );
  }
}
