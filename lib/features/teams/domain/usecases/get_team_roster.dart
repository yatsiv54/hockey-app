import '../entities/team_player.dart';
import '../repositories/team_repository.dart';

class GetTeamRoster {
  GetTeamRoster(this._repository);
  final TeamRepository _repository;

  Future<List<TeamPlayer>> call(String abbrev) => _repository.getRoster(abbrev);
}
