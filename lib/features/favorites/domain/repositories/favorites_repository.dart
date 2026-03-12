import '../entities/favorite_game.dart';
import '../entities/favorite_team.dart';

abstract class FavoritesRepository {
  Future<List<FavoriteTeam>> loadTeams();
  Future<List<FavoriteGame>> loadGames();
  Future<void> saveTeams(List<FavoriteTeam> teams);
  Future<void> saveGames(List<FavoriteGame> games);
}
