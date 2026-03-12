import 'package:nhl_app/core/usecase/usecase.dart';
import '../entities/match_entity.dart';
import '../repositories/match_repository.dart';

class GetFinishedMatches implements UseCase<List<MatchEntity>, NoParams> {
  GetFinishedMatches(this._repo);
  final MatchRepository _repo;
  @override
  Future<List<MatchEntity>> call(NoParams params) => _repo.getFinished();
}

