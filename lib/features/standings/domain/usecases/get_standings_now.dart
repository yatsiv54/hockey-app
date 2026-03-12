import 'package:nhl_app/core/usecase/usecase.dart';
import '../entities/team_standing.dart';
import '../repositories/standings_repository.dart';

class GetStandingsNow implements UseCase<List<TeamStanding>, NoParams> {
  GetStandingsNow(this._repo);
  final StandingsRepository _repo;
  @override
  Future<List<TeamStanding>> call(NoParams params) => _repo.getStandingsNow();
}

