import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/team_player.dart';
import '../../domain/entities/team_schedule_item.dart';

abstract class TeamRemoteDataSource {
  Future<List<TeamPlayer>> fetchRoster(String abbrev);
  Future<List<TeamScheduleItem>> fetchSchedule(String abbrev);
}

class TeamRemoteDataSourceImpl implements TeamRemoteDataSource {
  TeamRemoteDataSourceImpl({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<List<TeamPlayer>> fetchRoster(String abbrev) async {
    final season = _seasonKey();
    final uri = Uri.parse('https://api-web.nhle.com/v1/roster/$abbrev/$season');
    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Failed to load roster for $abbrev');
    }
    final map = json.decode(res.body) as Map<String, dynamic>;
    final players = <TeamPlayer>[];
    for (final group in const ['forwards', 'defensemen', 'goalies']) {
      final list = map[group] as List<dynamic>?;
      if (list == null) continue;
      for (final raw in list.whereType<Map<String, dynamic>>()) {
        final first = (raw['firstName']?['default'] ?? raw['firstName'] ?? '').toString();
        final last = (raw['lastName']?['default'] ?? raw['lastName'] ?? '').toString();
        final name = '$first $last'.trim();
        final number = (raw['sweaterNumber']?.toString() ?? '--').padLeft(2, '0');
        final idValue = raw['playerId'] ?? raw['id'];
        final id = (idValue as num?)?.toInt();
        if (id == null) continue;
        players.add(
          TeamPlayer(
            id: id,
            number: '#$number',
            name: name.isEmpty ? 'Player ${raw['id'] ?? ''}' : name,
            position: (raw['positionCode'] as String?) ?? '',
            shoots: (raw['shootsCatches'] as String?) ?? '',
            dob: (raw['birthDate'] as String?) ?? '',
            country: (raw['birthCountry'] as String?) ?? '',
          ),
        );
      }
    }
    players.sort((a, b) => a.number.compareTo(b.number));
    return players;
  }

  @override
  Future<List<TeamScheduleItem>> fetchSchedule(String abbrev) async {
    final season = _seasonKey();
    final uri = Uri.parse('https://api-web.nhle.com/v1/club-schedule-season/$abbrev/$season');
    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Failed to load schedule for $abbrev');
    }
    final map = json.decode(res.body) as Map<String, dynamic>;
    final games = (map['games'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>();
    final now = DateTime.now().toUtc();
    final upcoming = games
        .where((g) => g['startTimeUTC'] != null)
        .map((game) {
          final startUtc = DateTime.tryParse(game['startTimeUTC'] as String);
          if (startUtc == null) return null;
          final isHome = (game['homeTeam']?['abbrev'] as String?)?.toUpperCase() == abbrev.toUpperCase();
          final opponent = (isHome ? game['awayTeam'] : game['homeTeam']) as Map<String, dynamic>?;
          final name = (opponent?['commonName']?['default'] ?? opponent?['placeName']?['default'] ?? opponent?['abbrev'] ?? '').toString();
          return TeamScheduleItem(
            dateTime: startUtc.toLocal(),
            opponent: name.isEmpty ? 'Opponent' : name,
            isHome: isHome,
          );
        })
        .whereType<TeamScheduleItem>()
        .where((game) => game.dateTime.toUtc().isAfter(now))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return upcoming.take(5).toList();
  }

  String _seasonKey() {
    final now = DateTime.now();
    final startYear = now.month >= 7 ? now.year : now.year - 1;
    final endYear = startYear + 1;
    return '$startYear$endYear';
  }
}
