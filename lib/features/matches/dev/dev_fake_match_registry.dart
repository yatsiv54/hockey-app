import 'dart:math';

import 'package:nhl_app/features/matches/domain/entities/match_entity.dart';

class DevFakeMatchRegistry {
  DevFakeMatchRegistry._();

  static final DevFakeMatchRegistry instance = DevFakeMatchRegistry._();

  final Map<String, _DevFakeMatch> _matches = <String, _DevFakeMatch>{};

  MatchEntity registerMatch({
    required String homeTeam,
    required String awayTeam,
  }) {
    final id = 'dev_fake_${DateTime.now().millisecondsSinceEpoch}';
    final fake = _DevFakeMatch(
      id: id,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
    );
    _matches[id] = fake;
    return fake.toEntity();
  }

  ({String? clock, int? periodNumber, String? periodType, int? home, int? away})?
      overlayFor(String matchId) {
    final match = _matches[matchId];
    if (match == null) return null;
    return match.overlay();
  }
}

class _DevFakeMatch {
  _DevFakeMatch({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
  }) : _startTime = DateTime.now();

  final String id;
  final String homeTeam;
  final String awayTeam;
  final DateTime _startTime;
  bool _finalized = false;
  bool _scored = false;

  MatchEntity toEntity() {
    return MatchEntity(
      id: id,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      status: MatchStatus.live,
      startTime: _startTime,
      scoreHome: 0,
      scoreAway: 0,
      periodNumber: 1,
      periodType: 'REG',
      clock: '20:00',
    );
  }

  ({String? clock, int? periodNumber, String? periodType, int? home, int? away}) overlay() {
    final elapsed = DateTime.now().difference(_startTime).inSeconds;
    if (_finalized) {
      return (
        clock: 'Final',
        periodNumber: 3,
        periodType: 'FINAL',
        home: 1,
        away: 0,
      );
    }
    if (elapsed >= 15) {
      _finalized = true;
      return (
        clock: 'Final',
        periodNumber: 3,
        periodType: 'FINAL',
        home: 1,
        away: 0,
      );
    }
    if (elapsed >= 5) {
      _scored = true;
      final remaining = max(0, 1200 - elapsed);
      return (
        clock: _formatClock(remaining),
        periodNumber: 1,
        periodType: 'REG',
        home: 1,
        away: 0,
      );
    }
    final remaining = max(0, 1200 - elapsed);
    return (
      clock: _formatClock(remaining),
      periodNumber: 1,
      periodType: 'REG',
      home: _scored ? 1 : 0,
      away: 0,
    );
  }

  String _formatClock(int remainingSeconds) {
    final minutes = (remainingSeconds ~/ 60).clamp(0, 20).toString().padLeft(2, '0');
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
