import '../entities/team_player.dart';
import '../entities/team_schedule_item.dart';

abstract class TeamRepository {
  Future<List<TeamPlayer>> getRoster(String abbrev);
  Future<List<TeamScheduleItem>> getSchedule(String abbrev);
}
