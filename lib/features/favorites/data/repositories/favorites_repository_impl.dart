import '../../domain/entities/favorite_game.dart';
import '../../domain/entities/favorite_team.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../datasources/favorites_local_data_source.dart';
import '../models/favorite_game_model.dart';
import '../models/favorite_team_model.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  FavoritesRepositoryImpl(this._local);

  final FavoritesLocalDataSource _local;

  @override
  Future<List<FavoriteTeam>> loadTeams() async {
    final list = await _local.readTeams();
    return list.map(FavoriteTeamModel.fromMap).toList();
  }

  @override
  Future<List<FavoriteGame>> loadGames() async {
    final list = await _local.readGames();
    return list.map(FavoriteGameModel.fromMap).toList();
  }

  @override
  Future<void> saveTeams(List<FavoriteTeam> teams) {
    final data = teams.map((e) => FavoriteTeamModel.fromEntity(e).toMap()).toList();
    return _local.writeTeams(data);
  }

  @override
  Future<void> saveGames(List<FavoriteGame> games) {
    final data = games.map((e) => FavoriteGameModel.fromEntity(e).toMap()).toList();
    return _local.writeGames(data);
  }
}
