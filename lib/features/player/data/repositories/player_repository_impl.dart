import '../../domain/entities/player_detail.dart';
import '../../domain/repositories/player_repository.dart';
import '../datasources/player_remote_data_source.dart';

class PlayerRepositoryImpl implements PlayerRepository {
  PlayerRepositoryImpl(this._remote);

  final PlayerRemoteDataSource _remote;

  @override
  Future<PlayerDetail> getPlayerDetail(int playerId) => _remote.fetchDetail(playerId);
}
