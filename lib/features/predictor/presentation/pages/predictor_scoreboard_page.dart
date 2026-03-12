import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:nhl_app/core/di/di.dart';
import 'package:nhl_app/core/theme/colors.dart';
import 'package:nhl_app/core/widgets/page_header.dart';
import 'package:nhl_app/dev_test_fab.dart';
import 'package:nhl_app/devtools/dev_flags.dart';
import 'package:nhl_app/features/matches/data/datasources/gamecenter_remote_data_source.dart';
import 'package:nhl_app/features/matches/domain/entities/match_entity.dart';
import 'package:nhl_app/features/predictor/data/prediction_storage.dart';
import 'package:nhl_app/features/predictor/domain/entities/prediction_record.dart';
import 'package:nhl_app/features/predictor/domain/utils/prediction_result.dart';

class PredictorScoreboardPage extends StatefulWidget {
  const PredictorScoreboardPage({super.key});

  @override
  State<PredictorScoreboardPage> createState() =>
      _PredictorScoreboardPageState();
}

class _PredictorScoreboardPageState extends State<PredictorScoreboardPage> {
  final _storage = PredictionStorage();
  final _gamecenter = getIt<GamecenterRemoteDataSource>();
  bool _loading = true;
  List<_PredictionView> _history = const [];
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (_loading && silent) return;
    if (!silent) {
      setState(() => _loading = true);
    }
    await _syncPendingPredictions();
    final records = await _storage.load();
    final sorted = [...records]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    setState(() {
      _history = sorted.map(_evaluate).toList();
      if (!silent) {
        _loading = false;
      }
    });
    final hasPending = records.any((r) => r.status != MatchStatus.finished);
    _scheduleAutoRefresh(hasPending);
    final missingResults = sorted
        .where(
          (record) =>
              record.status == MatchStatus.finished &&
              record.actualHomeScore == null &&
              record.actualAwayScore == null,
        )
        .toList();
    if (missingResults.isNotEmpty) {
      unawaited(_hydrateResults(missingResults));
    }
  }

  Future<void> _syncPendingPredictions() async {
    final records = await _storage.load();
    final pending = records.where((r) => r.status != MatchStatus.finished);
    final now = DateTime.now();
    for (final record in pending) {
      final overlay = await _gamecenter.fetchOverlay(record.matchId);
      Map<String, dynamic>? landing;
      final overlayFinal = _overlayIsFinal(overlay);
      if (!overlayFinal) {
        landing = await _gamecenter.fetchLanding(record.matchId);
      }
      final shouldFinish =
          overlayFinal ||
          _landingIsFinal(landing) ||
          _shouldTimeoutFinish(record, now);
      if (!shouldFinish) continue;
      final result = _resultFromOverlay(overlay) ?? _resultFromLanding(landing);
      PredictionResult? outcome;
      if (result != null) {
        outcome = evaluatePrediction(
          record: record,
          homeScore: result.homeScore,
          awayScore: result.awayScore,
          wentToOvertime: result.wentToExtra,
        );
      }
      await _storage.updateMatchStatus(
        record.matchId,
        MatchStatus.finished,
        outcome: outcome,
      );
    }
  }

  bool _shouldTimeoutFinish(PredictionRecord record, DateTime now) {
    final start = record.matchStart;
    if (start != null) {
      final diff = now.difference(start);
      if (!diff.isNegative && diff >= const Duration(hours: 6)) return true;
    } else {
      final diff = now.difference(record.timestamp);
      if (!diff.isNegative && diff >= const Duration(hours: 12)) return true;
    }
    return false;
  }

  bool _overlayIsFinal(
    ({
      String? clock,
      int? periodNumber,
      String? periodType,
      int? home,
      int? away,
    })?
    overlay,
  ) {
    if (overlay == null) return false;
    final clock = overlay.clock?.toLowerCase().trim();
    if (clock != null && clock.contains('final')) return true;
    final type = overlay.periodType?.toUpperCase().trim();
    return type == 'FINAL' || type == 'FINAL_OT' || type == 'FINAL_SO';
  }

  void _scheduleAutoRefresh(bool enable) {
    _autoRefreshTimer?.cancel();
    if (!enable) return;
    _autoRefreshTimer = Timer(
      const Duration(seconds: 10),
      () => _load(silent: true),
    );
  }

  Future<void> _hydrateResults(List<PredictionRecord> records) async {
    var updated = false;
    for (final record in records) {
      final overlay = await _gamecenter.fetchOverlay(record.matchId);
      Map<String, dynamic>? landing;
      final result =
          _resultFromOverlay(overlay) ??
          _resultFromLanding(
            overlay != null
                ? null
                : (landing ??= await _gamecenter.fetchLanding(record.matchId)),
          );
      if (result == null) continue;
      final outcome = evaluatePrediction(
        record: record,
        homeScore: result.homeScore,
        awayScore: result.awayScore,
        wentToOvertime: result.wentToExtra,
      );
      await _storage.updateMatchStatus(
        record.matchId,
        MatchStatus.finished,
        outcome: outcome,
      );
      updated = true;
    }
    if (updated && mounted) {
      await _load(silent: true);
    }
  }

  Future<void> _reset() async {
    await _storage.clear();
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Stats cleared')));
  }

  bool _landingIsFinal(Map<String, dynamic>? landing) {
    if (landing == null) return false;
    final state = (landing['gameState'] as String?)?.toUpperCase().trim();
    if (state != null &&
        (state.contains('FINAL') ||
            state.contains('GAME_END') ||
            state.contains('CONCLUDED'))) {
      return true;
    }
    final stateId = (landing['gameStateId'] as num?)?.toInt();
    if (stateId != null && stateId >= 6) return true;
    final status = landing['status'] as Map<String, dynamic>?;
    final abs = (status?['abstractGameState'] as String?)?.toUpperCase().trim();
    if (abs == 'FINAL') return true;
    final clock = landing['clock'];
    if (clock is Map &&
        (clock['status'] as String?)?.toUpperCase().trim() == 'FINAL') {
      return true;
    }
    return false;
  }

  _GameResult? _resultFromOverlay(
    ({
      String? clock,
      int? periodNumber,
      String? periodType,
      int? home,
      int? away,
    })?
    overlay,
  ) {
    if (overlay == null) return null;
    final home = overlay.home;
    final away = overlay.away;
    if (home == null || away == null) return null;
    return _GameResult(
      homeScore: home,
      awayScore: away,
      periodType: overlay.periodType,
    );
  }

  _GameResult? _resultFromLanding(Map<String, dynamic>? landing) {
    if (landing == null) return null;
    final homeScore = (landing['homeTeam']?['score'] as num?)?.toInt();
    final awayScore = (landing['awayTeam']?['score'] as num?)?.toInt();
    if (homeScore == null || awayScore == null) return null;
    final descriptor = landing['periodDescriptor'] as Map<String, dynamic>?;
    final periodType = descriptor?['periodType'] as String?;
    return _GameResult(
      homeScore: homeScore,
      awayScore: awayScore,
      periodType: periodType,
    );
  }

  _PredictionView _evaluate(PredictionRecord record) {
    final completed = record.status == MatchStatus.finished;
    final points = record.awardedPoints ?? 0;
    final success = record.success ?? false;
    final perfect = record.perfect ?? false;
    return _PredictionView(
      record: record,
      points: points,
      success: success,
      perfect: perfect,
      completed: completed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final completed = _history.where((e) => e.completed).toList();
    final int totalPoints = completed.fold<int>(
      0,
      (sum, item) => sum + item.points,
    );
    final int successCount = completed.where((e) => e.success).length;
    final int perfectScores = completed.where((e) => e.perfect).length;

    final double accuracy = completed.isEmpty
        ? 0.0
        : successCount / completed.length;
    final int longestStreak = _calculateLongestStreak(completed);

    return Stack(
      children: [
        Positioned.fill(
          child: Column(
            children: [
              const PageHeader(
                title: 'Predictor Scoreboard',
                bottomGap: 0,
                actions: [],
                showSettings: true,
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: CustomColors.backgroundColor,
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _history.isEmpty
                      ? const _EmptyScoreboard()
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                            children: [
                              _StatGrid(
                                totalPoints: totalPoints,
                                accuracy: accuracy,
                                longestStreak: longestStreak,
                                perfectScores: perfectScores,
                              ),
                              const SizedBox(height: 16),
                              _ForecastTable(
                                rows: _history.take(5).toList(),
                                onForceComplete: _forceComplete,
                              ),
                              const SizedBox(height: 16),
                              _Milestones(totalPoints: totalPoints),
                              const SizedBox(height: 24),
                              _ResetButton(onTap: _reset),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
        if (enableDevTesterTools)
          Positioned(
            bottom: 24,
            right: 24,
            child: DevTesterFab(onRecordAdded: _load),
          ),
      ],
    );
  }

  Future<void> _forceComplete(String matchId) async {
    await _storage.updateMatchStatus(matchId, MatchStatus.finished);
    if (!mounted) return;
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Prediction marked as finished')),
    );
  }

  int _calculateLongestStreak(List<_PredictionView> items) {
    if (items.isEmpty) return 0;
    final ordered = [...items]
      ..sort((a, b) => a.record.timestamp.compareTo(b.record.timestamp));
    var current = 0;
    var best = 0;
    for (final item in ordered) {
      if (item.success) {
        current += 1;
        best = max(best, current);
      } else {
        current = 0;
      }
    }
    return best;
  }
}

class _PredictionView {
  const _PredictionView({
    required this.record,
    required this.points,
    required this.success,
    required this.perfect,
    required this.completed,
  });

  final PredictionRecord record;
  final int points;
  final bool success;
  final bool perfect;
  final bool completed;
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({
    required this.totalPoints,
    required this.accuracy,
    required this.longestStreak,
    required this.perfectScores,
  });

  final int totalPoints;
  final double accuracy;
  final int longestStreak;
  final int perfectScores;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _StatTile(label: 'Total Points', value: totalPoints.toString()),
      _StatTile(label: 'Accuracy', value: '${(accuracy * 100).round()}%'),
      _StatTile(label: 'Longest Streak', value: longestStreak.toString()),
      _StatTile(label: 'Perfect Scores', value: perfectScores.toString()),
    ];
    return Column(
      children: [
        for (int i = 0; i < tiles.length; i++) ...[
          tiles[i],
          if (i != tiles.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(35, 86, 130, 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              color: Color.fromRGBO(105, 149, 191, 1),
              fontWeight: FontWeight.w500,
              fontSize: 18,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _ForecastTable extends StatelessWidget {
  const _ForecastTable({required this.rows, required this.onForceComplete});

  final List<_PredictionView> rows;
  final ValueChanged<String> onForceComplete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Forecast table',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          _ForecastTableBody(rows: rows, onForceComplete: onForceComplete),
        ],
      ),
    );
  }
}

class _ForecastTableBody extends StatelessWidget {
  const _ForecastTableBody({required this.rows, required this.onForceComplete});

  final List<_PredictionView> rows;
  final ValueChanged<String> onForceComplete;

  static const _line = Color(0xFF598FC3);

  @override
  Widget build(BuildContext context) {
    final columnWidths = <int, TableColumnWidth>{
      0: const FixedColumnWidth(45), // Date
      1: const FlexColumnWidth(2.5), // Match
      2: const FlexColumnWidth(1.5), // Your Pick
      3: const FixedColumnWidth(60), // Points
      4: const FixedColumnWidth(40), // Status
    };

    return Table(
      columnWidths: columnWidths,
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: const TableBorder(
        horizontalInside: BorderSide(color: _line, width: .6),
        verticalInside: BorderSide(color: _line, width: 1),
      ),
      children: [
        TableRow(
          children: const [
            _Cell('Date', head: true),
            _Cell('Match', head: true, align: TextAlign.left, padLeft: 8),
            _Cell('Your Pick', head: true),
            _Cell('Points', head: true),
            _Cell('Status', head: true),
          ],
        ),
        for (final r in rows)
          TableRow(
            children: [
              _Cell(_formatDate(r.record.timestamp)),
              _Cell(_matchupLabel(r.record), align: TextAlign.left, padLeft: 8),
              _Cell(
                r.record.winner[0].toUpperCase() + r.record.winner.substring(1),
              ),
              _Cell(r.completed ? _formatPoints(r.points) : '--'),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: r.completed
                      ? (r.success
                            ? const Icon(
                                Icons.check,
                                color: Colors.lightGreen,
                                size: 18,
                              )
                            : const Icon(
                                Icons.close,
                                color: Colors.redAccent,
                                size: 18,
                              ))
                      : GestureDetector(
                          onTap: () => onForceComplete(r.record.matchId),
                          child: const Icon(
                            Icons.schedule,
                            color: Colors.amberAccent,
                            size: 18,
                          ),
                        ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  static String _formatPoints(int points) =>
      points >= 0 ? '+$points' : '$points';

  static String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$m/$d';
  }

  String _matchupLabel(PredictionRecord record) {
    final home = (record.homeAbbrev ?? _fallbackAbbrev(record.homeTeam))
        .toUpperCase();
    final away = (record.awayAbbrev ?? _fallbackAbbrev(record.awayTeam))
        .toUpperCase();
    return '$home vs $away';
  }

  String _fallbackAbbrev(String name) {
    final cleaned = name.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    if (cleaned.length >= 3) return cleaned.substring(0, 3);
    final buffer = StringBuffer(cleaned);
    while (buffer.length < 3) {
      buffer.write('X');
    }
    return buffer.toString();
  }
}

class _Cell extends StatelessWidget {
  const _Cell(
    this.text, {
    this.head = false,
    this.align = TextAlign.center,
    this.padLeft = 0,
  });

  final String text;
  final bool head;
  final TextAlign align;
  final double padLeft;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(2 + padLeft, 5, 2, 5),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: head ? const Color.fromRGBO(89, 143, 195, 1) : Colors.white,
          fontWeight: head ? FontWeight.w700 : FontWeight.w500,
          fontSize: head ? 12 : 14,
        ),
      ),
    );
  }
}

class _Milestones extends StatelessWidget {
  const _Milestones({required this.totalPoints});

  final int totalPoints;

  @override
  Widget build(BuildContext context) {
    const milestones = [
      _MilestoneData(title: 'Rookie Predictor', targetPoints: 100),
      _MilestoneData(title: 'Sharp Shooter', targetPoints: 300),
      _MilestoneData(title: 'Hockey Oracle', targetPoints: 500),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Milestones',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        for (final milestone in milestones) ...[
          _MilestoneTile(data: milestone, totalPoints: totalPoints),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _MilestoneTile extends StatelessWidget {
  const _MilestoneTile({required this.data, required this.totalPoints});

  final _MilestoneData data;
  final int totalPoints;

  @override
  Widget build(BuildContext context) {
    final double progress = (totalPoints / data.targetPoints).clamp(0.0, 1.0);
    final percent = (progress * 100).round();
    final bool completed = percent == 100;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(35, 86, 130, 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${min(totalPoints, data.targetPoints)} pts / ${data.targetPoints} pts',
                style: TextStyle(
                  color: completed
                      ? const Color.fromRGBO(136, 170, 47, 1)
                      : const Color.fromRGBO(81, 143, 196, 1),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(136, 170, 47, 1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$percent%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MilestoneData {
  const _MilestoneData({required this.title, required this.targetPoints});

  final String title;
  final int targetPoints;
}

class _ResetButton extends StatelessWidget {
  const _ResetButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 70,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color.fromRGBO(136, 170, 47, 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Reset Stats',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _EmptyScoreboard extends StatelessWidget {
  const _EmptyScoreboard();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, color: Colors.white30, size: 64),
          const SizedBox(height: 12),
          const Text(
            'No predicts yet',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _GameResult {
  const _GameResult({
    required this.homeScore,
    required this.awayScore,
    this.periodType,
  });

  final int homeScore;
  final int awayScore;
  final String? periodType;

  bool get wentToExtra {
    final type = periodType?.toUpperCase().trim();
    if (type == null) return false;
    return type.contains('OT') || type.contains('SO');
  }

  int get totalGoals => homeScore + awayScore;
}
