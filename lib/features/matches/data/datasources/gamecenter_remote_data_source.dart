import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nhl_app/features/matches/dev/dev_fake_match_registry.dart';

class GamecenterRemoteDataSource {
  GamecenterRemoteDataSource({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>?> fetchLanding(String gameId) async {
    return _getJson('https://api-web.nhle.com/v1/gamecenter/$gameId/landing');
  }

  Future<Map<String, dynamic>?> fetchBoxscore(String gameId) async {
    return _getJson('https://api-web.nhle.com/v1/gamecenter/$gameId/boxscore');
  }

  Future<Map<String, dynamic>?> fetchPlayByPlay(String gameId) async {
    return _getJson('https://api-web.nhle.com/v1/gamecenter/$gameId/play-by-play');
  }

  Future<Map<String, dynamic>?> _getJson(String url) async {
    final res = await _client.get(Uri.parse(url));
    if (res.statusCode != 200) return null;
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<({String? clock, int? periodNumber, String? periodType, int? home, int? away})?> fetchOverlay(String gameId) async {
    final devOverlay = DevFakeMatchRegistry.instance.overlayFor(gameId);
    if (devOverlay != null) return devOverlay;
    final map = await fetchLanding(gameId);
    if (map == null) return null;
    try {
      final linescore = map['linescore'] as Map<String, dynamic>?;
      final home = (linescore?['home']?['score'] as num?)?.toInt() ?? (map['homeTeam']?['score'] as num?)?.toInt() ?? 0;
      final away = (linescore?['away']?['score'] as num?)?.toInt() ?? (map['awayTeam']?['score'] as num?)?.toInt() ?? 0;
      final pd = map['periodDescriptor'] as Map<String, dynamic>?;
      final periodNumber = (pd?['number'] as num?)?.toInt();
      final periodType = pd?['periodType'] as String?;
      final clock = (map['clock'] is Map) ? (map['clock']['timeRemaining'] as String?) : map['clock'] as String?;
      return (clock: clock, periodNumber: periodNumber, periodType: periodType, home: home, away: away);
    } catch (_) {
      return null;
    }
  }

  Future<GameCenterDetailsDto> fetchGameCenterData(String gameId) async {
    final landing = await fetchLanding(gameId) ?? <String, dynamic>{};
    final boxscore = await fetchBoxscore(gameId) ?? <String, dynamic>{};
    final playByPlay = await fetchPlayByPlay(gameId) ?? <String, dynamic>{};
    return _buildDetails(landing, boxscore, playByPlay);
  }

  Future<GameCenterDetailsDto> _buildDetails(
    Map<String, dynamic> landing,
    Map<String, dynamic> boxscore,
    Map<String, dynamic> playByPlay,
  ) async {
    final home = (landing['homeTeam'] as Map<String, dynamic>?) ?? (boxscore['homeTeam'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final away = (landing['awayTeam'] as Map<String, dynamic>?) ?? (boxscore['awayTeam'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final homeId = (home['id'] as num?)?.toInt();
    final awayId = (away['id'] as num?)?.toInt();
    final homeAbbr = (home['abbrev'] as String?) ?? 'HOME';
    final awayAbbr = (away['abbrev'] as String?) ?? 'AWAY';

    final tv = _readBroadcasts(landing['tvBroadcasts']);
    final radio = _readBroadcasts(landing['radioBroadcasts']);

    final summary = landing['summary'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final scoring = (summary['scoring'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();

    final plays = (playByPlay['plays'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
    plays.sort((a, b) => ((a['sortOrder'] as num?) ?? 0).compareTo((b['sortOrder'] as num?) ?? 0));

    final playerStats = (boxscore['playerByGameStats'] as Map<String, dynamic>? ?? <String, dynamic>{});
    final playerMap = _buildPlayerMap(playByPlay['rosterSpots'] as List<dynamic>? ?? const []);

    final statComparisons = _buildStats(landing, playerStats, plays, scoring, homeAbbr, awayAbbr, homeId, awayId);
    final playsTables = _buildPlayTables(scoring, plays, playerMap, homeAbbr, awayAbbr, homeId, awayId);
    final goalieTables = _buildGoalieTables(playerStats, homeAbbr, awayAbbr);
    final skaterTables = _buildSkaterTables(playerStats, homeAbbr, awayAbbr);
    final recap = _buildRecapTable(scoring, homeAbbr, awayAbbr, home['score'], away['score']);
    final keyMoments = _buildKeyMoments(scoring, plays, playerMap, homeAbbr, awayAbbr, homeId, awayId);

    final clock = _readClock(landing['clock']);
    final pd = landing['periodDescriptor'] as Map<String, dynamic>?;
    final periodText = pd != null ? _formatPeriod((pd['number'] as num?)?.toInt() ?? 1, pd['periodType'] as String?) : null;

    final homeChance = await _calculateHomeChance(homeAbbr, awayAbbr);

    return GameCenterDetailsDto(
      clock: clock,
      periodText: periodText,
      homeScore: (home['score'] as num?)?.toInt(),
      awayScore: (away['score'] as num?)?.toInt(),
      tv: tv,
      radio: radio,
      stats: statComparisons,
      playsTables: playsTables,
      homeGoalies: goalieTables.$1,
      awayGoalies: goalieTables.$2,
      homeSkaters: skaterTables.$1,
      awaySkaters: skaterTables.$2,
      recapTable: recap,
      keyMoments: keyMoments,
      homeAbbr: homeAbbr,
      awayAbbr: awayAbbr,
      homeChance: homeChance,
    );
  }

  List<String> _readBroadcasts(dynamic source) {
    if (source is! List) return const [];
    return source
        .whereType<Map<String, dynamic>>()
        .map((e) => (e['callLetters'] as String?) ?? (e['network'] as String?) ?? (e['name'] as String?) ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Map<int, Map<String, dynamic>> _buildPlayerMap(List<dynamic> roster) {
    final map = <int, Map<String, dynamic>>{};
    for (final spot in roster.whereType<Map<String, dynamic>>()) {
      final id = (spot['playerId'] as num?)?.toInt();
      if (id != null) {
        map[id] = spot;
      }
    }
    return map;
  }

  List<StatComparisonDto> _buildStats(
    Map<String, dynamic> landing,
    Map<String, dynamic> playerStats,
    List<Map<String, dynamic>> plays,
    List<Map<String, dynamic>> scoring,
    String homeAbbr,
    String awayAbbr,
    int? homeId,
    int? awayId,
  ) {
    final homeSog = (landing['homeTeam']?['sog'] as num?)?.toInt() ?? 0;
    final awaySog = (landing['awayTeam']?['sog'] as num?)?.toInt() ?? 0;

    final hits = _sumPlayerStat(playerStats, 'hits');
    final blocks = _sumPlayerStat(playerStats, 'blockedShots');
    final pim = _sumPlayerStat(playerStats, 'pim');
    final faceoff = _computeFaceoffPct(plays, homeId, awayId);
    final zoneTime = _computeZoneTime(plays, homeId, awayId);
    final powerPlay = _computePowerPlay(scoring, plays, homeAbbr, awayAbbr, homeId, awayId);

    return [
      StatComparisonDto(label: 'Shots on Goal', homeValue: '$homeSog', awayValue: '$awaySog'),
      StatComparisonDto(label: 'PowerPlay %', homeValue: powerPlay.$1, awayValue: powerPlay.$2),
      StatComparisonDto(label: 'Time in Offensive Zone', homeValue: zoneTime.$1, awayValue: zoneTime.$2),
      StatComparisonDto(label: 'Hits', homeValue: '${hits.$1}', awayValue: '${hits.$2}'),
      StatComparisonDto(label: 'Blocks', homeValue: '${blocks.$1}', awayValue: '${blocks.$2}'),
      StatComparisonDto(label: 'Faceoff %', homeValue: faceoff.$1, awayValue: faceoff.$2),
      StatComparisonDto(label: 'PIM', homeValue: '${pim.$1}', awayValue: '${pim.$2}'),
    ];
  }

  (int, int) _sumPlayerStat(Map<String, dynamic> stats, String key) {
    int sumForTeam(String teamKey) {
      final team = stats[teamKey] as Map<String, dynamic>?;
      if (team == null) return 0;
      int total = 0;
      for (final group in const ['forwards', 'defense']) {
        final list = team[group] as List<dynamic>?;
        if (list == null) continue;
        for (final player in list.whereType<Map<String, dynamic>>()) {
          total += (player[key] as num?)?.toInt() ?? 0;
        }
      }
      return total;
    }

    return (sumForTeam('homeTeam'), sumForTeam('awayTeam'));
  }

  (String, String) _computeFaceoffPct(List<Map<String, dynamic>> plays, int? homeId, int? awayId) {
    final faceoffs = plays.where((p) => p['typeDescKey'] == 'faceoff').toList();
    if (faceoffs.isEmpty) return ('0%', '0%');
    final total = faceoffs.length;
    final homeWins = faceoffs.where((p) => (p['details']?['eventOwnerTeamId'] as num?)?.toInt() == homeId).length;
    final awayWins = total - homeWins;
    final homePct = (homeWins / total * 100).toStringAsFixed(0) + '%';
    final awayPct = (awayWins / total * 100).toStringAsFixed(0) + '%';
    return (homePct, awayPct);
  }

  (String, String) _computeZoneTime(List<Map<String, dynamic>> plays, int? homeId, int? awayId) {
    final relevant = plays
        .where((p) => p['details'] is Map<String, dynamic>)
        .map((p) {
          final details = p['details'] as Map<String, dynamic>;
          final teamId = (details['eventOwnerTeamId'] as num?)?.toInt();
          final zone = details['zoneCode'] as String?;
          if (teamId == null || zone == null) return null;
          final pd = p['periodDescriptor'] as Map<String, dynamic>?;
          final periodNumber = (pd?['number'] as num?)?.toInt() ?? 1;
          final periodType = pd?['periodType'] as String?;
          final time = p['timeInPeriod'] as String? ?? '00:00';
          final absolute = _absoluteSeconds(periodNumber, periodType, time);
          return _TimedEvent(teamId: teamId, zone: zone, seconds: absolute);
        })
        .whereType<_TimedEvent>()
        .toList();

    if (relevant.length < 2) return ('00:00', '00:00');
    relevant.sort((a, b) => a.seconds.compareTo(b.seconds));
    final totals = <int, int>{};
    for (var i = 0; i < relevant.length - 1; i++) {
      final current = relevant[i];
      final next = relevant[i + 1];
      if (current.zone == 'O' && (current.teamId == homeId || current.teamId == awayId)) {
        final delta = next.seconds - current.seconds;
        if (delta > 0) {
          totals.update(current.teamId, (value) => value + delta, ifAbsent: () => delta);
        }
      }
    }
    final home = _formatDuration(totals[homeId] ?? 0);
    final away = _formatDuration(totals[awayId] ?? 0);
    return (home, away);
  }

  (String, String) _computePowerPlay(
    List<Map<String, dynamic>> scoring,
    List<Map<String, dynamic>> plays,
    String homeAbbr,
    String awayAbbr,
    int? homeId,
    int? awayId,
  ) {
    int goalsFor(String abbr) {
      int total = 0;
      for (final period in scoring) {
        final goals = (period['goals'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
        total += goals.where((g) => g['strength'] == 'pp' && (g['teamAbbrev']?['default'] ?? g['teamAbbrev']) == abbr).length;
      }
      return total;
    }

    int opportunitiesFor(int? opponentId) {
      if (opponentId == null) return 0;
      final penalties = plays.where((p) => p['typeDescKey'] == 'penalty');
      return penalties.where((p) => (p['details']?['eventOwnerTeamId'] as num?)?.toInt() == opponentId && (p['details']?['duration'] as num?) != null).length;
    }

    final homeGoals = goalsFor(homeAbbr);
    final awayGoals = goalsFor(awayAbbr);
    final homeOpp = opportunitiesFor(awayId);
    final awayOpp = opportunitiesFor(homeId);

    String format(int goals, int opp) {
      if (opp == 0) return '0/0 (0%)';
      final pct = goals / opp * 100;
      return '$goals/$opp (${pct.toStringAsFixed(0)}%)';
    }

    return (format(homeGoals, homeOpp), format(awayGoals, awayOpp));
  }

  Map<String, GameCenterTableDto> _buildPlayTables(
    List<Map<String, dynamic>> scoring,
    List<Map<String, dynamic>> plays,
    Map<int, Map<String, dynamic>> playerMap,
    String homeAbbr,
    String awayAbbr,
    int? homeId,
    int? awayId,
  ) {
    final goalsTable = _buildGoalsTable(scoring);
    final shotsTable = _buildShotsTable(plays, playerMap, homeAbbr, awayAbbr, homeId, awayId);
    final hitsTable = _buildHitsTable(plays, playerMap, homeAbbr, awayAbbr, homeId, awayId);
    final penaltiesTable = _buildPenaltiesTable(plays, playerMap, homeAbbr, awayAbbr, homeId, awayId);
    final faceoffTable = _buildFaceoffTable(plays, playerMap, homeAbbr, awayAbbr, homeId, awayId);

    return {
      'Goals': goalsTable,
      'Shots': shotsTable,
      'Hits': hitsTable,
      'Penalties': penaltiesTable,
      'Faceoff': faceoffTable,
    };
  }

  GameCenterTableDto _buildGoalsTable(List<Map<String, dynamic>> scoring) {
    final rows = <List<String>>[];
    for (final period in scoring) {
      final label = _formatPeriod((period['periodDescriptor']?['number'] as num?)?.toInt() ?? 1, period['periodDescriptor']?['periodType'] as String?);
      final goals = (period['goals'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
      for (final goal in goals) {
        final assists = (goal['assists'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map((a) => (a['name']?['default'] ?? a['name'])?.toString() ?? '')
            .where((a) => a.isNotEmpty)
            .join(', ');
        rows.add([
          label,
          goal['timeInPeriod'] as String? ?? '--:--',
          (goal['teamAbbrev']?['default'] ?? goal['teamAbbrev'] ?? '').toString(),
          (goal['name']?['default'] ?? goal['name'] ?? '').toString(),
          assists.isEmpty ? 'Unassisted' : assists,
        ]);
      }
    }
    return GameCenterTableDto(
      title: 'Goals',
      headers: const ['Period', 'Time', 'Team', 'Scorer', 'Assists'],
      rows: rows,
    );
  }

  GameCenterTableDto _buildShotsTable(
    List<Map<String, dynamic>> plays,
    Map<int, Map<String, dynamic>> playerMap,
    String homeAbbr,
    String awayAbbr,
    int? homeId,
    int? awayId,
  ) {
    final list = plays
        .where((p) => const {'shot-on-goal', 'missed-shot', 'blocked-shot'}.contains(p['typeDescKey']))
        .take(12)
        .toList();
    final rows = list.map((play) {
      final details = play['details'] as Map<String, dynamic>? ?? const {};
      final teamId = (details['eventOwnerTeamId'] as num?)?.toInt();
      final team = teamId == null
          ? '-'
          : teamId == homeId
              ? homeAbbr
              : teamId == awayId
                  ? awayAbbr
                  : teamId.toString();
      final shooter = _playerName(playerMap, details['shootingPlayerId']);
      final result = _shotResult(play, playerMap);
      return [
        _formatPeriod((play['periodDescriptor']?['number'] as num?)?.toInt() ?? 1, play['periodDescriptor']?['periodType'] as String?),
        play['timeInPeriod'] as String? ?? '--:--',
        team.isEmpty ? (teamId == null ? '-' : teamId.toString()) : team,
        shooter,
        result,
      ];
    }).toList();
    return GameCenterTableDto(
      title: 'Shots',
      headers: const ['Period', 'Time', 'Team', 'Shooter', 'Result'],
      rows: rows,
    );
  }

  GameCenterTableDto _buildHitsTable(
    List<Map<String, dynamic>> plays,
    Map<int, Map<String, dynamic>> playerMap,
    String homeAbbr,
    String awayAbbr,
    int? homeId,
    int? awayId,
  ) {
    final rows = plays
        .where((p) => p['typeDescKey'] == 'hit')
        .take(12)
        .map((play) {
          final details = play['details'] as Map<String, dynamic>? ?? const {};
          final teamId = (details['eventOwnerTeamId'] as num?)?.toInt();
          final team = teamId == null
              ? '-'
              : teamId == homeId
                  ? homeAbbr
                  : teamId == awayId
                      ? awayAbbr
                      : teamId.toString();
          return [
            _formatPeriod((play['periodDescriptor']?['number'] as num?)?.toInt() ?? 1, play['periodDescriptor']?['periodType'] as String?),
            play['timeInPeriod'] as String? ?? '--:--',
            team,
            _playerName(playerMap, details['hittingPlayerId']),
            _playerName(playerMap, details['hitteePlayerId']),
          ];
        })
        .toList();
    return GameCenterTableDto(
      title: 'Hits',
      headers: const ['Period', 'Time', 'Team', 'Hitter', 'Hittee'],
      rows: rows,
    );
  }

  GameCenterTableDto _buildPenaltiesTable(
    List<Map<String, dynamic>> plays,
    Map<int, Map<String, dynamic>> playerMap,
    String homeAbbr,
    String awayAbbr,
    int? homeId,
    int? awayId,
  ) {
    final rows = plays
        .where((p) => p['typeDescKey'] == 'penalty')
        .take(12)
        .map((play) {
          final details = play['details'] as Map<String, dynamic>? ?? const {};
          final teamId = (details['eventOwnerTeamId'] as num?)?.toInt();
          final team = teamId == null
              ? '-'
              : teamId == homeId
                  ? homeAbbr
                  : teamId == awayId
                      ? awayAbbr
                      : teamId.toString();
          final penalty = (details['descKey'] as String? ?? '').replaceAll('-', ' ');
          final mins = (details['duration'] as num?)?.toInt() ?? 0;
          return [
            _formatPeriod((play['periodDescriptor']?['number'] as num?)?.toInt() ?? 1, play['periodDescriptor']?['periodType'] as String?),
            play['timeInPeriod'] as String? ?? '--:--',
            team,
            penalty.isEmpty ? 'Penalty' : penalty,
            mins == 0 ? '-' : '${mins} min',
          ];
        })
        .toList();
    return GameCenterTableDto(
      title: 'Penalties',
      headers: const ['Period', 'Time', 'Team', 'Penalty', 'Minutes'],
      rows: rows,
    );
  }

  GameCenterTableDto _buildFaceoffTable(
    List<Map<String, dynamic>> plays,
    Map<int, Map<String, dynamic>> playerMap,
    String homeAbbr,
    String awayAbbr,
    int? homeId,
    int? awayId,
  ) {
    final rows = plays
        .where((p) => p['typeDescKey'] == 'faceoff')
        .take(12)
        .map((play) {
          final details = play['details'] as Map<String, dynamic>? ?? const {};
          final winnerTeamId = (details['eventOwnerTeamId'] as num?)?.toInt();
          final team = winnerTeamId == null
              ? '-'
              : winnerTeamId == homeId
                  ? homeAbbr
                  : awayAbbr;
          return [
            _formatPeriod((play['periodDescriptor']?['number'] as num?)?.toInt() ?? 1, play['periodDescriptor']?['periodType'] as String?),
            play['timeInPeriod'] as String? ?? '--:--',
            team,
            _playerName(playerMap, details['winningPlayerId']),
            _playerName(playerMap, details['losingPlayerId']),
          ];
        })
        .toList();
    return GameCenterTableDto(
      title: 'Faceoff',
      headers: const ['Period', 'Time', 'Team', 'Winner', 'Loser'],
      rows: rows,
    );
  }

  (GameCenterTableDto, GameCenterTableDto) _buildGoalieTables(Map<String, dynamic> playerStats, String homeAbbr, String awayAbbr) {
    GameCenterTableDto build(String teamKey, String label) {
      final team = playerStats[teamKey] as Map<String, dynamic>?;
      final goalies = (team?['goalies'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>();
      final rows = goalies
          .map((g) => [
                (g['name']?['default'] ?? g['name'] ?? '').toString(),
                (g['saves'] ?? '-').toString(),
                (g['shotsAgainst'] ?? '-').toString(),
                g['savePctg'] == null ? '-' : (double.tryParse(g['savePctg'].toString()) ?? 0).toStringAsFixed(3),
                (g['toi'] ?? '--:--').toString(),
              ])
          .toList();
      return GameCenterTableDto(
        title: 'Goalies $label',
        headers: const ['Player', 'SV', 'SOG', 'SV%', 'TOI'],
        rows: rows,
      );
    }

    return (
      build('homeTeam', '$homeAbbr (home)'),
      build('awayTeam', '$awayAbbr (away)'),
    );
  }

  (GameCenterTableDto, GameCenterTableDto) _buildSkaterTables(Map<String, dynamic> playerStats, String homeAbbr, String awayAbbr) {
    GameCenterTableDto build(String teamKey, String label) {
      final team = playerStats[teamKey] as Map<String, dynamic>?;
      final players = <Map<String, dynamic>>[];
      for (final group in const ['forwards', 'defense']) {
        players.addAll(((team?[group] as List<dynamic>?) ?? const []).whereType<Map<String, dynamic>>());
      }
      players.sort((a, b) => _toiSeconds(b['toi']) - _toiSeconds(a['toi']));
      final rows = players.take(10).map((p) {
        return [
          (p['name']?['default'] ?? p['name'] ?? '').toString(),
          (p['goals'] ?? 0).toString(),
          (p['assists'] ?? 0).toString(),
          (p['hits'] ?? 0).toString(),
          (p['sog'] ?? 0).toString(),
          (p['blockedShots'] ?? 0).toString(),
        ];
      }).toList();
      return GameCenterTableDto(
        title: 'Skaters $label',
        headers: const ['Player', 'G', 'A', 'HIT', 'SOG', 'BLK'],
        rows: rows,
      );
    }

    return (
      build('homeTeam', '$homeAbbr (home)'),
      build('awayTeam', '$awayAbbr (away)'),
    );
  }

  GameCenterTableDto _buildRecapTable(List<Map<String, dynamic>> scoring, String homeAbbr, String awayAbbr, Object? homeScore, Object? awayScore) {
    final rows = <List<String>>[];
    for (final period in scoring) {
      final label = _formatPeriod((period['periodDescriptor']?['number'] as num?)?.toInt() ?? 1, period['periodDescriptor']?['periodType'] as String?);
      final goals = (period['goals'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
      final home = goals.where((g) => (g['teamAbbrev']?['default'] ?? g['teamAbbrev']) == homeAbbr).length;
      final away = goals.where((g) => (g['teamAbbrev']?['default'] ?? g['teamAbbrev']) == awayAbbr).length;
      rows.add([label, '$home', '$away']);
    }
    rows.add(['Final', '${homeScore ?? 0}', '${awayScore ?? 0}']);
    return GameCenterTableDto(
      title: 'Recap',
      headers: ['Period', homeAbbr, awayAbbr],
      rows: rows,
    );
  }

  List<KeyMomentDto> _buildKeyMoments(
    List<Map<String, dynamic>> scoring,
    List<Map<String, dynamic>> plays,
    Map<int, Map<String, dynamic>> playerMap,
    String homeAbbr,
    String awayAbbr,
    int? homeId,
    int? awayId,
  ) {
    final goals = <Map<String, dynamic>>[];
    for (final period in scoring) {
      goals.addAll((period['goals'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>());
    }
    goals.sort((a, b) {
      final pa = (a['periodDescriptor']?['number'] as num?)?.toInt() ?? 0;
      final pb = (b['periodDescriptor']?['number'] as num?)?.toInt() ?? 0;
      if (pa != pb) return pa.compareTo(pb);
      final ta = a['timeInPeriod'] as String? ?? '00:00';
      final tb = b['timeInPeriod'] as String? ?? '00:00';
      return ta.compareTo(tb);
    });

    final keyMoments = <KeyMomentDto>[];
    if (goals.isNotEmpty) {
      keyMoments.add(_goalMoment('First goal', goals.first));
      keyMoments.add(_goalMoment('Final goal', goals.last));
      final goAhead = _findGoAheadGoal(goals);
      if (goAhead != null) {
        keyMoments.add(_goalMoment('Go-ahead', goAhead));
      }
    }

    final penalties = plays.where((p) => p['typeDescKey'] == 'penalty').toList();
    if (penalties.isNotEmpty) {
      keyMoments.add(_penaltyMoment(penalties.first, playerMap, homeAbbr, awayAbbr, homeId, awayId));
    }

    return keyMoments;
  }

  KeyMomentDto _goalMoment(String label, Map<String, dynamic> goal) {
    final period = _formatPeriod((goal['periodDescriptor']?['number'] as num?)?.toInt() ?? 1, goal['periodDescriptor']?['periodType'] as String?);
    final time = goal['timeInPeriod'] as String? ?? '--:--';
    final team = (goal['teamAbbrev']?['default'] ?? goal['teamAbbrev'] ?? '').toString();
    final scorer = (goal['name']?['default'] ?? goal['name'] ?? '').toString();
    return KeyMomentDto(label: label, team: team, period: period, time: time, player: scorer);
  }

  Map<String, dynamic>? _findGoAheadGoal(List<Map<String, dynamic>> goals) {
    int home = 0;
    int away = 0;
    for (final goal in goals) {
      final team = (goal['teamAbbrev']?['default'] ?? goal['teamAbbrev'] ?? '').toString();
      if (team.isEmpty) continue;
      if (goal['isHome'] == true) {
        home++;
      } else {
        away++;
      }
      if ((home - away).abs() == 1 && (home - away) != 0 && (home + away) > 1) {
        return goal;
      }
    }
    return null;
  }

  KeyMomentDto _penaltyMoment(
    Map<String, dynamic> play,
    Map<int, Map<String, dynamic>> playerMap,
    String homeAbbr,
    String awayAbbr,
    int? homeId,
    int? awayId,
  ) {
    final details = play['details'] as Map<String, dynamic>? ?? const {};
    final period = _formatPeriod((play['periodDescriptor']?['number'] as num?)?.toInt() ?? 1, play['periodDescriptor']?['periodType'] as String?);
    final time = play['timeInPeriod'] as String? ?? '--:--';
    final teamId = (details['eventOwnerTeamId'] as num?)?.toInt();
    final team = teamId == null
        ? '-'
        : teamId == homeId
            ? homeAbbr
            : teamId == awayId
                ? awayAbbr
                : teamId.toString();
    final player = _playerName(playerMap, details['committedByPlayerId']);
    return KeyMomentDto(label: 'Notable penalty', team: team, period: period, time: time, player: player);
  }

  String _shotResult(Map<String, dynamic> play, Map<int, Map<String, dynamic>> playerMap) {
    final type = play['typeDescKey'] as String? ?? '';
    final details = play['details'] as Map<String, dynamic>? ?? const {};
    switch (type) {
      case 'shot-on-goal':
        final shotType = (details['shotType'] as String? ?? '').toUpperCase();
        return shotType.isEmpty ? 'On goal' : '$shotType on goal';
      case 'missed-shot':
        final reason = (details['reason'] as String? ?? 'Missed');
        return 'Missed ($reason)';
      case 'blocked-shot':
        return 'Blocked by ' + _playerName(playerMap, details['blockingPlayerId']);
      default:
        return type;
    }
  }

  String _playerName(Map<int, Map<String, dynamic>> map, Object? idObj) {
    final id = (idObj as num?)?.toInt();
    if (id == null) return '-';
    final entry = map[id];
    if (entry == null) return '#$id';
    final first = (entry['firstName']?['default'] ?? entry['firstName'] ?? '').toString();
    final last = (entry['lastName']?['default'] ?? entry['lastName'] ?? '').toString();
    final combined = '$first $last'.trim();
    return combined.isEmpty ? '#$id' : combined;
  }

  String? _readClock(dynamic clock) {
    if (clock is String) return clock;
    if (clock is Map && clock['timeRemaining'] is String) return clock['timeRemaining'] as String;
    return null;
  }

  int _toiSeconds(Object? toi) {
    if (toi is String && toi.contains(':')) {
      final parts = toi.split(':');
      final minutes = int.tryParse(parts[0]) ?? 0;
      final seconds = int.tryParse(parts[1]) ?? 0;
      return minutes * 60 + seconds;
    }
    return 0;
  }

  int _absoluteSeconds(int periodNumber, String? periodType, String timeInPeriod) {
    final base = () {
      if (periodNumber <= 3) return (periodNumber - 1) * 20 * 60;
      if (periodType == 'OT') {
        return 3 * 20 * 60 + (periodNumber - 4) * 5 * 60;
      }
      return 3 * 20 * 60 + 5 * 60;
    }();
    final parts = timeInPeriod.split(':');
    final minutes = int.tryParse(parts.first) ?? 0;
    final seconds = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    return base + minutes * 60 + seconds;
  }

  String _formatDuration(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  String _formatPeriod(int number, String? type) {
    final t = (type ?? 'REG').toUpperCase();
    if (t == 'OT') return 'OT';
    if (t == 'SO') return 'SO';
    switch (number) {
      case 1:
        return '1st';
      case 2:
        return '2nd';
      case 3:
        return '3rd';
      default:
        return '${number}th';
    }
  }

  Future<double> _calculateHomeChance(String homeAbbr, String awayAbbr) async {
    try {
      final homeGames = await _fetchSeasonGames(homeAbbr);
      final awayGames = await _fetchSeasonGames(awayAbbr);
      final homeForm = _recentWinRate(homeGames, 5) ?? 0.5;
      final awayForm = _recentWinRate(awayGames, 5) ?? 0.5;
      final formScore = _normalizeForm(homeForm, awayForm);
      final headToHead = _headToHeadRate(homeGames, awayAbbr, 4) ?? 0.5;
      return (formScore * 0.6) + (headToHead * 0.4);
    } catch (_) {
      return 0.5;
    }
  }

  Future<List<_ScheduleGame>> _fetchSeasonGames(String abbr) async {
    final season = _seasonKey();
    final uri = Uri.parse('https://api-web.nhle.com/v1/club-schedule-season/$abbr/$season');
    final res = await _client.get(uri);
    if (res.statusCode != 200) return const [];
    final map = json.decode(res.body) as Map<String, dynamic>;
    final games = (map['games'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>();
    final list = <_ScheduleGame>[];
    for (final game in games) {
      final id = (game['id'] as num?)?.toInt();
      if (id == null) continue;
      final home = game['homeTeam'] as Map<String, dynamic>?;
      final away = game['awayTeam'] as Map<String, dynamic>?;
      if (home == null || away == null) continue;
      final homeAbbr = (home['abbrev'] as String?) ?? '';
      final awayAbbr = (away['abbrev'] as String?) ?? '';
      final homeScore = (home['score'] as num?)?.toInt();
      final awayScore = (away['score'] as num?)?.toInt();
      if (homeScore == null || awayScore == null) continue;
      final isHomeTeam = homeAbbr.toUpperCase() == abbr.toUpperCase();
      final teamScore = isHomeTeam ? homeScore : awayScore;
      final oppScore = isHomeTeam ? awayScore : homeScore;
      final opponent = isHomeTeam ? awayAbbr : homeAbbr;
      final start = DateTime.tryParse(game['startTimeUTC'] as String? ?? '');
      if (start == null) continue;
      list.add(
        _ScheduleGame(
          id: id,
          date: start.toLocal(),
          opponent: opponent,
          win: teamScore > oppScore,
        ),
      );
    }
    return list;
  }

  double? _recentWinRate(List<_ScheduleGame> games, int take) {
    if (games.isEmpty) return null;
    final sorted = [...games]..sort((a, b) => b.date.compareTo(a.date));
    final recent = sorted.take(take).toList();
    if (recent.isEmpty) return null;
    final wins = recent.where((g) => g.win).length;
    return wins / recent.length;
  }

  double? _headToHeadRate(List<_ScheduleGame> games, String opponent, int take) {
    final filtered = games.where((g) => g.opponent.toUpperCase() == opponent.toUpperCase()).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    if (filtered.isEmpty) return null;
    final recent = filtered.take(take).toList();
    final wins = recent.where((g) => g.win).length;
    return wins / recent.length;
  }

  double _normalizeForm(double home, double away) {
    final total = home + away;
    if (total <= 0) return 0.5;
    return home / total;
  }

  String _seasonKey() {
    final now = DateTime.now();
    final startYear = now.month >= 7 ? now.year : now.year - 1;
    final endYear = startYear + 1;
    return '$startYear$endYear';
  }
}

class _TimedEvent {
  const _TimedEvent({required this.teamId, required this.zone, required this.seconds});
  final int teamId;
  final String zone;
  final int seconds;
}

class GameCenterDetailsDto {
  const GameCenterDetailsDto({
    this.clock,
    this.periodText,
    this.homeScore,
    this.awayScore,
    required this.tv,
    required this.radio,
    required this.stats,
    required this.playsTables,
    required this.homeGoalies,
    required this.awayGoalies,
    required this.homeSkaters,
    required this.awaySkaters,
    required this.recapTable,
    required this.keyMoments,
    required this.homeAbbr,
    required this.awayAbbr,
    required this.homeChance,
  });

  final String? clock;
  final String? periodText;
  final int? homeScore;
  final int? awayScore;
  final List<String> tv;
  final List<String> radio;
  final List<StatComparisonDto> stats;
  final Map<String, GameCenterTableDto> playsTables;
  final GameCenterTableDto homeGoalies;
  final GameCenterTableDto awayGoalies;
  final GameCenterTableDto homeSkaters;
  final GameCenterTableDto awaySkaters;
  final GameCenterTableDto recapTable;
  final List<KeyMomentDto> keyMoments;
  final String homeAbbr;
  final String awayAbbr;
  final double homeChance;
}

class StatComparisonDto {
  const StatComparisonDto({required this.label, required this.homeValue, required this.awayValue});
  final String label;
  final String homeValue;
  final String awayValue;
}

class GameCenterTableDto {
  const GameCenterTableDto({required this.title, required this.headers, required this.rows});
  final String title;
  final List<String> headers;
  final List<List<String>> rows;
}

class KeyMomentDto {
  const KeyMomentDto({required this.label, required this.team, required this.period, required this.time, required this.player});
  final String label;
  final String team;
  final String period;
  final String time;
  final String player;
}

class _ScheduleGame {
  const _ScheduleGame({required this.id, required this.date, required this.opponent, required this.win});
  final int id;
  final DateTime date;
  final String opponent;
  final bool win;
}
