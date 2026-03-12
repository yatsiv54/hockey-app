import 'package:nhl_app/core/usecase/usecase.dart';
import '../entities/match_entity.dart';
import '../repositories/match_repository.dart';

class GetUpcomingMatches implements UseCase<List<MatchEntity>, NoParams> {
  GetUpcomingMatches(this._repo);
  final MatchRepository _repo;
  @override
  Future<List<MatchEntity>> call(NoParams params) => _repo.getUpcoming();
}

