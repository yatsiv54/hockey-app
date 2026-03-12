import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/player_detail.dart';

abstract class PlayerRemoteDataSource {
  Future<PlayerDetail> fetchDetail(int playerId);
}

class PlayerRemoteDataSourceImpl implements PlayerRemoteDataSource {
  PlayerRemoteDataSourceImpl({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<PlayerDetail> fetchDetail(int playerId) async {
    final uri = Uri.parse('https://api-web.nhle.com/v1/player/$playerId/landing');
    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Failed to load player $playerId');
    }
    final map = json.decode(res.body) as Map<String, dynamic>;
    final first = (map['firstName']?['default'] ?? map['firstName'] ?? '').toString();
    final last = (map['lastName']?['default'] ?? map['lastName'] ?? '').toString();
    final number = (map['sweaterNumber']?.toString() ?? '--').padLeft(2, '0');
    final pos = (map['position'] as String?) ?? '';
    final shoots = (map['shootsCatches'] as String?) ?? '';
    final dob = (map['birthDate'] as String?) ?? '';
    final country = (map['birthCountry'] as String?) ?? '';
    final stats = _parseStats(map);
    return PlayerDetail(
      id: playerId,
      name: '$first $last'.trim(),
      number: '#$number',
      position: pos,
      shoots: shoots,
      dob: dob,
      country: country,
      stats: stats,
    );
  }

  PlayerSeasonStats _parseStats(Map<String, dynamic> map) {
    final sub = map['featuredStats']?['regularSeason']?['subSeason'] as Map<String, dynamic>?;
    final gp = (sub?['gamesPlayed'] as num?)?.toInt();
    if (sub == null || gp == null) {
      return PlayerSeasonStats.empty;
    }
    final goals = (sub['goals'] as num?)?.toInt() ?? 0;
    final assists = (sub['assists'] as num?)?.toInt() ?? 0;
    final points = (sub['points'] as num?)?.toInt() ?? (goals + assists);
    final plusMinus = (sub['plusMinus'] as num?)?.toInt() ?? 0;
    final pim = (sub['pim'] as num?)?.toInt() ?? 0;
    final toi = (map['careerTotals']?['regularSeason']?['avgToi'] as String?) ?? '--:--';
    return PlayerSeasonStats(
      gamesPlayed: gp,
      goals: goals,
      assists: assists,
      points: points,
      plusMinus: plusMinus,
      pim: pim,
      toiPerGame: toi,
    );
  }
}
