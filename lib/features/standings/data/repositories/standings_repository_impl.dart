import '../../domain/entities/team_standing.dart';
import '../../domain/repositories/standings_repository.dart';
import '../datasources/standings_remote_data_source.dart';

class StandingsRepositoryImpl implements StandingsRepository {
  StandingsRepositoryImpl(this._remote);
  final StandingsRemoteDataSource _remote;

  @override
  Future<List<TeamStanding>> getStandingsNow() => _remote.fetchNow();
}

