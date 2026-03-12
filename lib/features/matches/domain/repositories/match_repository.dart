import '../entities/match_entity.dart';

abstract class MatchRepository {
  Future<List<MatchEntity>> getUpcoming();
  Future<List<MatchEntity>> getLive();
  Future<List<MatchEntity>> getFinished();
  Future<List<MatchEntity>> getByDate(DateTime date);
}
