import '../entities/player_detail.dart';
import '../repositories/player_repository.dart';

class GetPlayerDetail {
  GetPlayerDetail(this._repository);
  final PlayerRepository _repository;

  Future<PlayerDetail> call(int playerId) => _repository.getPlayerDetail(playerId);
}
