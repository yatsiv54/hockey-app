import '../entities/team_schedule_item.dart';
import '../repositories/team_repository.dart';

class GetTeamSchedule {
  GetTeamSchedule(this._repository);
  final TeamRepository _repository;

  Future<List<TeamScheduleItem>> call(String abbrev) => _repository.getSchedule(abbrev);
}
