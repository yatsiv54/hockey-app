import '../../domain/entities/team_player.dart';
import '../../domain/entities/team_schedule_item.dart';
import '../../domain/repositories/team_repository.dart';
import '../datasources/team_remote_data_source.dart';

class TeamRepositoryImpl implements TeamRepository {
  TeamRepositoryImpl(this._remote);

  final TeamRemoteDataSource _remote;

  @override
  Future<List<TeamPlayer>> getRoster(String abbrev) => _remote.fetchRoster(abbrev);

  @override
  Future<List<TeamScheduleItem>> getSchedule(String abbrev) => _remote.fetchSchedule(abbrev);
}
