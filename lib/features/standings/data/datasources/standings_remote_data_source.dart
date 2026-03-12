import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/team_standing.dart';

abstract class StandingsRemoteDataSource {
  Future<List<TeamStanding>> fetchNow();
}

class StandingsRemoteDataSourceImpl implements StandingsRemoteDataSource {
  @override
  Future<List<TeamStanding>> fetchNow() async {
    final uri = Uri.parse('https://api-web.nhle.com/v1/standings/now');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Failed to load standings');
    }
    final map = json.decode(res.body) as Map<String, dynamic>;
    final List<dynamic> arr = map['standings'] as List<dynamic>;
    return arr.map<TeamStanding>((e) {
      final m = e as Map<String, dynamic>;
      String read(Map? obj, String key) => (obj?[key] as String?) ?? '';
      final team = read(m['teamName'] as Map?, 'default');
      final abbrev = _readString(m['teamAbbrev'] ?? m['teamTriCode']);
      final conf = _readString(m['conferenceAbbrev'] ?? m['conferenceName']);
      final div = _readString(m['divisionName']);
      final gp = (m['gamesPlayed'] as num?)?.toInt() ?? 0;
      final w = (m['wins'] as num?)?.toInt() ?? 0;
      final l = (m['losses'] as num?)?.toInt() ?? 0;
      final otl = (m['otLosses'] as num?)?.toInt() ?? 0;
      final pts = (m['points'] as num?)?.toInt() ?? 0;
      final row = (m['regulationPlusOtWins'] as num?)?.toInt() ?? 0;
      final gf = (m['goalFor'] as num? ?? m['goalsFor'] as num? ?? 0).toInt();
      final ga = (m['goalAgainst'] as num?)?.toInt() ?? 0;
      final diffNum = (m['goalDifferential'] as num?)?.toInt() ?? 0;
      final diff = (diffNum >= 0 ? '+' : '') + diffNum.toString();
      final l10 = '${(m['l10Wins'] as num?)?.toInt() ?? 0}-${(m['l10Losses'] as num?)?.toInt() ?? 0}-${(m['l10OtLosses'] as num?)?.toInt() ?? 0}';
      final strkCode = _readString(m['streakCode']);
      final strkCount = (m['streakCount'] as num?)?.toInt() ?? 0;
      final strk = strkCode + strkCount.toString();

      // Positions depend on view; store league/division/wildcard markers into pos
      String pos;
      final wc = (m['wildcardSequence'] as num?)?.toInt() ?? 0;
      if (wc > 0) {
        pos = 'WC' + wc.toString();
      } else {
        final leagueSeq = (m['leagueSequence'] as num?)?.toInt();
        final divSeq = (m['divisionSequence'] as num?)?.toInt();
        pos = (leagueSeq ?? divSeq ?? 0).toString();
      }

      return TeamStanding(
        team: team,
        abbrev: abbrev,
        pos: pos,
        gp: gp,
        w: w,
        l: l,
        otl: otl,
        pts: pts,
        row: row,
        gf: gf,
        ga: ga,
        diff: diff,
        l10: l10,
        strk: strk,
        conference: conf,
        division: div,
        logo: m['teamLogo'] as String?,
      );
    }).toList();
  }

  String _readString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      if (map['default'] is String) return map['default'] as String;
      for (final entry in map.values) {
        if (entry is String) return entry;
      }
      return '';
    }
    return value.toString();
  }
}
