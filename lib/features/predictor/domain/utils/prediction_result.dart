import 'package:nhl_app/features/predictor/domain/entities/prediction_record.dart';

class PredictionResult {
  const PredictionResult({
    required this.homeScore,
    required this.awayScore,
    required this.wentToOvertime,
    required this.points,
    required this.success,
    required this.perfect,
  });

  final int homeScore;
  final int awayScore;
  final bool wentToOvertime;
  final int points;
  final bool success;
  final bool perfect;
}

PredictionResult evaluatePrediction({
  required PredictionRecord record,
  required int homeScore,
  required int awayScore,
  required bool wentToOvertime,
}) {
  final winnerHit = record.winner == _winnerKey(homeScore, awayScore);
  final overtimeHit = wentToOvertime && record.overtime;
  final goalsHit = record.totalGoals == homeScore + awayScore;
  final exactHit =
      _matchesExactScore(record.exactScore, homeScore, awayScore);

  final points = (winnerHit ? 5 : 0) +
      (overtimeHit ? 3 : 0) +
      (goalsHit ? 5 : 0) +
      (exactHit ? 10 : 0);
  return PredictionResult(
    homeScore: homeScore,
    awayScore: awayScore,
    wentToOvertime: wentToOvertime,
    points: points,
    success: winnerHit,
    perfect: exactHit,
  );
}

String _winnerKey(int home, int away) {
  if (home > away) return 'home';
  if (away > home) return 'away';
  return 'draw';
}

bool _matchesExactScore(String score, int home, int away) {
  final separator = score.contains(':') ? ':' : '-';
  final parts = score.split(separator);
  if (parts.length != 2) return false;
  final predictedHome = int.tryParse(parts[0].trim());
  final predictedAway = int.tryParse(parts[1].trim());
  if (predictedHome == null || predictedAway == null) return false;
  return predictedHome == home && predictedAway == away;
}
