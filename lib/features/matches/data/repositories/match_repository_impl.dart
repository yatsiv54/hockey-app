import '../../domain/entities/match_entity.dart';
import '../../domain/repositories/match_repository.dart';
import '../datasources/match_remote_data_source.dart';

class MatchRepositoryImpl implements MatchRepository {
  MatchRepositoryImpl(this._remote);
  final MatchRemoteDataSource _remote;

  @override
  Future<List<MatchEntity>> getFinished() => _remote.fetchFinished();

  @override
  Future<List<MatchEntity>> getLive() => _remote.fetchLive();

  @override
  Future<List<MatchEntity>> getUpcoming() => _remote.fetchUpcoming();

  @override
  Future<List<MatchEntity>> getByDate(DateTime date) => _remote.fetchByDate(date);
}
