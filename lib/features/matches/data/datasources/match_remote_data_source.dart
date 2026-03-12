import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/match_entity.dart';

abstract class MatchRemoteDataSource {
  Future<List<MatchEntity>> fetchUpcoming();
  Future<List<MatchEntity>> fetchLive();
  Future<List<MatchEntity>> fetchFinished();
  Future<List<MatchEntity>> fetchByDate(DateTime date);
}

class MatchRemoteDataSourceStub implements MatchRemoteDataSource {
  @override
  Future<List<MatchEntity>> fetchFinished() async {
    return const [
      MatchEntity(
        id: 'f1',
        homeTeam: 'Rangers',
        awayTeam: 'Bruins',
        status: MatchStatus.finished,
        scoreHome: 3,
        scoreAway: 2,
      ),
    ];
  }

  @override
  Future<List<MatchEntity>> fetchLive() async {
    return const [
      MatchEntity(
        id: 'l1',
        homeTeam: 'Leafs',
        awayTeam: 'Canadiens',
        status: MatchStatus.live,
        scoreHome: 1,
        scoreAway: 1,
      ),
    ];
  }

  @override
  Future<List<MatchEntity>> fetchUpcoming() async {
    return const [
      MatchEntity(
        id: 'u1',
        homeTeam: 'Penguins',
        awayTeam: 'Capitals',
        status: MatchStatus.upcoming,
      ),
    ];
  }

  @override
  Future<List<MatchEntity>> fetchByDate(DateTime date) async {
    final String d = date.toIso8601String().substring(0, 10);
    final uri = Uri.parse('https://api-web.nhle.com/v1/schedule/$d');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Failed to load schedule');
    }
    final map = json.decode(res.body) as Map<String, dynamic>;
    final List<dynamic> days = (map['gameWeek'] as List<dynamic>? ?? <dynamic>[]);
    Map<String, dynamic>? day;
    for (final e in days) {
      if (e is Map<String, dynamic> && e['date'] == d) {
        day = e;
        break;
      }
    }
    final List<dynamic> games = (day?['games'] as List<dynamic>? ?? <dynamic>[]);
    return games.map<MatchEntity>((g) {
      final home = g['homeTeam'] as Map<String, dynamic>;
      final away = g['awayTeam'] as Map<String, dynamic>;
      final state = (g['gameState'] as String?) ?? '';
      final outcome = g['gameOutcome'];
      final pd = g['periodDescriptor'] as Map<String, dynamic>?;
      final int? periodNumber = (pd != null && pd['number'] is int) ? pd['number'] as int : null;
      final String? periodType = pd != null ? pd['periodType'] as String? : null;
      final DateTime? startUtc = g['startTimeUTC'] != null ? DateTime.tryParse(g['startTimeUTC'])?.toLocal() : null;
      MatchStatus status;
      if (state == 'LIVE' || state == 'CRIT') {
        status = MatchStatus.live;
      } else if (outcome != null) {
        status = MatchStatus.finished;
      } else if (startUtc != null && startUtc.isAfter(DateTime.now())) {
        status = MatchStatus.upcoming;
      } else {
        status = MatchStatus.upcoming;
      }
      String readTeam(Map<String, dynamic> t) {
        final place = (t['placeName'] is Map ? t['placeName']['default'] as String? : null) ?? '';
        final common = (t['commonName'] is Map ? t['commonName']['default'] as String? : null) ?? '';
        final abbr = (t['abbrev'] as String?) ?? '';
        final name = ('$place $common').trim();
        return name.isNotEmpty ? name : abbr;
      }
      return MatchEntity(
        id: (g['id'] ?? '').toString(),
        homeTeam: readTeam(home),
        awayTeam: readTeam(away),
        status: status,
        startTime: startUtc,
        scoreHome: home['score'] is int ? home['score'] as int : null,
        scoreAway: away['score'] is int ? away['score'] as int : null,
        homeLogo: home['logo'] as String?,
        awayLogo: away['logo'] as String?,
        periodNumber: periodNumber,
        periodType: periodType,
        homeAbbrev: (home['abbrev'] as String?)?.toUpperCase(),
        awayAbbrev: (away['abbrev'] as String?)?.toUpperCase(),
      );
    }).toList();
  }
}
