import 'package:nhl_app/core/usecase/usecase.dart';
import '../entities/match_entity.dart';
import '../repositories/match_repository.dart';

class GetMatchesByDate implements UseCase<List<MatchEntity>, DateTime> {
  GetMatchesByDate(this._repo);
  final MatchRepository _repo;
  @override
  Future<List<MatchEntity>> call(DateTime params) => _repo.getByDate(params);
}

