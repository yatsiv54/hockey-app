import '../entities/player_detail.dart';

abstract class PlayerRepository {
  Future<PlayerDetail> getPlayerDetail(int playerId);
}
