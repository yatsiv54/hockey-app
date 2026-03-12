import '../entities/team_standing.dart';

abstract class StandingsRepository {
  Future<List<TeamStanding>> getStandingsNow();
}

