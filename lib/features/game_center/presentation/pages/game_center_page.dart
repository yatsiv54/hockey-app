import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:nhl_app/core/di/di.dart';
import 'package:nhl_app/core/router/routes.dart';
import 'package:nhl_app/core/theme/colors.dart';
import 'package:nhl_app/core/widgets/page_header.dart';
import 'package:nhl_app/features/favorites/domain/entities/favorite_game.dart';
import 'package:nhl_app/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:nhl_app/features/matches/domain/entities/match_entity.dart';
import 'package:nhl_app/features/predictor/domain/entities/predictor_match.dart';
import 'package:share_plus/share_plus.dart';

import '../cubit/game_center_cubit.dart';
import '../cubit/game_center_state.dart';

class GameCenterArgs {
  const GameCenterArgs({
    required this.gameId,
    required this.homeTeam,
    required this.awayTeam,
    required this.status,
    this.homeLogo,
    this.awayLogo,
    this.homeScore,
    this.awayScore,
    this.periodText,
    this.clock,
    this.startTime,
  });
  final String gameId;
  final String homeTeam;
  final String awayTeam;
  final MatchStatus status;
  final String? homeLogo;
  final String? awayLogo;
  final int? homeScore;
  final int? awayScore;
  final String? periodText;
  final String? clock;
  final DateTime? startTime;
}

class GameCenterPage extends StatefulWidget {
  const GameCenterPage({super.key, required this.args});
  final GameCenterArgs args;

  @override
  State<GameCenterPage> createState() => _GameCenterPageState();
}

class _GameCenterPageState extends State<GameCenterPage> {
  _StatsTab _statsTab = _StatsTab.game;

  GameCenterArgs get args => widget.args;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocProvider(
          create: (_) => getIt<GameCenterCubit>()..load(args.gameId),
          child: BlocBuilder<GameCenterCubit, GameCenterState>(
            builder: (context, state) {
              if (state is GameCenterLoading || state is GameCenterInitial) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is GameCenterError) {
                return Center(child: Text('Error: ${state.message}'));
              }
              final data = state as GameCenterLoaded;
              final clock = data.clock ?? args.clock ?? _approximateClock();
              final periodText = data.periodText ?? args.periodText;
              final homeScore = data.homeScore ?? args.homeScore;
              final awayScore = data.awayScore ?? args.awayScore;
              final status = _resolveStatus(data);
              return SingleChildScrollView(
                padding: const EdgeInsets.all(0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PageHeader(
                      title: 'Game Center',
                      oneLine: true,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 25,
                        vertical: 12,
                      ),
                      child: Column(
                        children: [
                          _GameHeader(
                            args: args,
                            homeTeam: args.homeTeam,
                            awayTeam: args.awayTeam,
                            homeLogo: args.homeLogo,
                            awayLogo: args.awayLogo,
                            homeScore: homeScore,
                            awayScore: awayScore,
                            clock: clock,
                            periodText: periodText,
                            status: status,
                            startTime: args.startTime,
                          ),
                          const SizedBox(height: 12),
                          _ChanceMeter(
                            homeTeam: args.homeTeam,
                            awayTeam: args.awayTeam,
                            homeShare: data.homeChance,
                          ),
                          const SizedBox(height: 12),
                          _SectionGrid(stats: data.stats),
                          const SizedBox(height: 24),
                          _SegmentSwitcher(
                            active: _statsTab,
                            onChanged: (tab) {
                              if (_statsTab != tab) {
                                setState(() => _statsTab = tab);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    _buildTeamTables(data),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 25,
                        vertical: 12,
                      ),
                      child: Column(
                        children: [
                          _title('Recap'),
                          const SizedBox(height: 8),
                          _RecapTable(table: data.recapTable),
                          const SizedBox(height: 12),
                          _title('Key moments'),
                          const SizedBox(height: 8),
                          _KeyMoments(items: data.keyMoments),
                          const SizedBox(height: 12),
                          _BroadcastsRow(tv: data.tv, radio: data.radio),
                          const SizedBox(height: 24),
                          _PlaysSection(tables: data.playsTables),
                          const SizedBox(height: 12),
                          _ShareButton(
                            enabled: _canShare(data),
                            onShare: () => _shareRecap(data),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _title(String t) => Align(
        alignment: AlignmentGeometry.centerLeft,
        child: Text(
          t,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );

  Widget _buildTeamTables(GameCenterLoaded data) {
    final widgets = <Widget>[];
    void addTable(GameCenterTable table, {required bool lighter}) {
      if (table.rows.isEmpty) return;
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 10));
      widgets.add(
        _MiniTable(
          table: table,
          isLighter: lighter,
          title: '',
        ),
      );
    }

    switch (_statsTab) {
      case _StatsTab.home:
        addTable(data.homeGoalies, lighter: false);
        addTable(data.homeSkaters, lighter: false);
        break;
      case _StatsTab.away:
        addTable(data.awayGoalies, lighter: true);
        addTable(data.awaySkaters, lighter: true);
        break;
      case _StatsTab.game:
        addTable(data.homeGoalies, lighter: false);
        addTable(data.awayGoalies, lighter: true);
        addTable(data.homeSkaters, lighter: false);
        addTable(data.awaySkaters, lighter: true);
        break;
    }

    if (widgets.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(children: widgets),
    );
  }

  MatchStatus _resolveStatus(GameCenterLoaded data) {
    final clock = data.clock ?? args.clock;
    final normalized = clock?.toLowerCase().trim();
    if (normalized != null) {
      if (normalized.contains('final')) return MatchStatus.finished;
      if (normalized.contains('live')) return MatchStatus.live;
    }
    return args.status;
  }

  String _approximateClock() {
    if (args.startTime == null) return '00:00';
    final diff = DateTime.now().difference(args.startTime!);
    if (diff.isNegative) {
      return '00:00';
    }
    final mins = diff.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = (diff.inSeconds.remainder(60)).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  bool _canShare(GameCenterLoaded data) =>
      data.recapTable.rows.isNotEmpty || data.keyMoments.isNotEmpty;

  Future<void> _shareRecap(GameCenterLoaded data) async {
    final text = _buildShareText(data);
    if (text.isEmpty) return;
    await Share.share(text);
  }

  String _buildShareText(GameCenterLoaded data) {
    final buffer = StringBuffer();
    buffer.writeln('Game recap: ${args.homeTeam} vs ${args.awayTeam}');
    if (data.homeScore != null && data.awayScore != null) {
      buffer.writeln(
        'Score: ${args.homeTeam} ${data.homeScore} - ${data.awayScore} ${args.awayTeam}',
      );
    }
    if (data.recapTable.rows.isNotEmpty) {
      buffer.writeln('Periods:');
      for (final row in data.recapTable.rows) {
        if (row.length >= 3) {
          buffer.writeln(' ${row[0]}: ${row[1]} - ${row[2]}');
        }
      }
    }
    if (data.keyMoments.isNotEmpty) {
      buffer.writeln('Key moments:');
      for (final moment in data.keyMoments) {
        buffer.writeln(
          ' ${moment.period} ${moment.time} – ${moment.label} (${moment.team}) ${moment.player}',
        );
      }
    }
    return buffer.toString().trim();
  }
}

class _GameHeader extends StatelessWidget {
  const _GameHeader({
    required this.homeTeam,
    required this.awayTeam,
    this.homeLogo,
    this.awayLogo,
    this.homeScore,
    this.awayScore,
    required this.clock,
    this.periodText,
    required this.status,
    this.startTime,
    required this.args,
  });

  final String homeTeam;
  final String awayTeam;
  final String? homeLogo;
  final String? awayLogo;
  final int? homeScore;
  final int? awayScore;
  final String clock;
  final String? periodText;
  final MatchStatus status;
  final DateTime? startTime;
  final args;

  @override
  Widget build(BuildContext context) {
    final isFavorite = context.select<FavoritesCubit, bool>(
      (cubit) => cubit.isGameFavorite(args.gameId),
    );
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.only(top: 0, left: 0, right: 12, bottom: 12),
      child: Stack(children: [
        Positioned(
          top: 2,
          left: 2,
          child: IconButton(
            icon: Icon(Icons.star_rounded),
            color: isFavorite
                ? const Color.fromRGBO(36, 110, 171, 1)
                : Colors.black38,
            iconSize: 32,
            onPressed: () => context.read<FavoritesCubit>().toggleGame(
                  FavoriteGame(
                    gameId: args.gameId,
                    homeTeam: args.homeTeam,
                    awayTeam: args.awayTeam,
                    homeLogo: args.homeLogo,
                    awayLogo: args.awayLogo,
                    status: status,
                    startTime: args.startTime,
                    homeScore: args.homeScore,
                    awayScore: args.awayScore,
                  ),
                ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _badge(badgeText: 'Home', isHome: true),
                    _statusPill(),
                    _badge(badgeText: 'Away', isHome: false),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Stack(
                alignment: Alignment.topCenter,
                children: [
                  Positioned(
                    top: 0,
                    child: Center(
                      child: _ScoreBlock(
                        homeScore: homeScore,
                        awayScore: awayScore,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _TeamBadgeColumn(
                          badgeText: 'Away',
                          name: awayTeam,
                          logoUrl: awayLogo,
                        ),
                      ),
                      Expanded(
                        child: _TeamBadgeColumn(
                          badgeText: 'Home',
                          name: homeTeam,
                          logoUrl: homeLogo,
                          alignEnd: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 15),
              _FavPredictRow(args: args, status: status),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _statusPill() {
    const color = Color.fromRGBO(36, 110, 171, 1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == MatchStatus.live && periodText != null)
            Text(
              periodText!,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          Text(
            _statusText(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _statusText() {
    switch (status) {
      case MatchStatus.live:
        return clock.isNotEmpty ? clock : 'LIVE';
      case MatchStatus.finished:
        return 'FINAL';
      case MatchStatus.upcoming:
        if (startTime != null) {
          final h = startTime!.hour.toString().padLeft(2, '0');
          final m = startTime!.minute.toString().padLeft(2, '0');
          return '$h:$m';
        }
        return clock;
    }
  }
}

class _TeamBadgeColumn extends StatelessWidget {
  const _TeamBadgeColumn({
    required this.badgeText,
    required this.name,
    this.logoUrl,
    this.alignEnd = false,
  });

  final String badgeText;
  final String name;
  final String? logoUrl;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final alignment =
        alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: alignment,
      children: [
        SizedBox(height: 90, child: _TeamLogo(url: logoUrl)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 19,
              height: 1,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

Widget _badge({required badgeText, required isHome}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    decoration: BoxDecoration(
      color: isHome
          ? Color.fromRGBO(214, 236, 255, 1)
          : Color.fromRGBO(214, 255, 217, 1),
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(8),
        bottomRight: Radius.circular(8),
      ),
    ),
    child: Text(
      badgeText,
      style: TextStyle(
        color: isHome
            ? Color.fromRGBO(36, 110, 171, 1)
            : Color.fromRGBO(136, 170, 47, 1),
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    ),
  );
}

class _ScoreBlock extends StatelessWidget {
  const _ScoreBlock({this.homeScore, this.awayScore});
  final int? homeScore;
  final int? awayScore;

  @override
  Widget build(BuildContext context) {
    final text = (homeScore != null && awayScore != null)
        ? '${awayScore ?? 0}-${homeScore ?? 0}'
        : '-';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          const Text(
            'Score',
            style: TextStyle(
              color: Color(0xFF2D5E95),
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            text,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamLogo extends StatelessWidget {
  const _TeamLogo({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    final placeholder = const DecoratedBox(
      decoration: BoxDecoration(color: Colors.black12, shape: BoxShape.circle),
    );
    final link = url;
    if (link == null || link.isEmpty) return placeholder;
    if (_isSvg(link)) {
      return SvgPicture.network(
        link,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => placeholder,
      );
    }
    return CachedNetworkImage(
      imageUrl: link,
      fit: BoxFit.contain,
      placeholder: (_, __) => placeholder,
      errorWidget: (_, __, ___) => placeholder,
    );
  }

  bool _isSvg(String value) {
    try {
      final uri = Uri.parse(value);
      return uri.path.toLowerCase().endsWith('.svg');
    } catch (_) {
      return value.toLowerCase().contains('.svg');
    }
  }
}

class _FavPredictRow extends StatelessWidget {
  const _FavPredictRow({required this.args, required this.status});

  final GameCenterArgs args;
  final MatchStatus status;

  @override
  Widget build(BuildContext context) {
    final isFavorite = context.select<FavoritesCubit, bool>(
      (cubit) => cubit.isGameFavorite(args.gameId),
    );
    final canPredict = status != MatchStatus.finished;
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            text: isFavorite ? '⭐ Favorited' : '⭐ Favorite',
            color: isFavorite
                ? Colors.redAccent
                : const Color.fromRGBO(36, 110, 171, 1),
            onTap: () => context.read<FavoritesCubit>().toggleGame(
                  FavoriteGame(
                    gameId: args.gameId,
                    homeTeam: args.homeTeam,
                    awayTeam: args.awayTeam,
                    homeLogo: args.homeLogo,
                    awayLogo: args.awayLogo,
                    status: status,
                    startTime: args.startTime,
                    homeScore: args.homeScore,
                    awayScore: args.awayScore,
                  ),
                ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionButton(
            text: '🔮 Predict Game',
            color: const Color.fromRGBO(136, 170, 47, 1),
            enabled: canPredict,
            onTap: canPredict
                ? () => context.go(
                      Routes.predictor,
                      extra: PredictorMatch(
                        id: args.gameId,
                        homeTeam: args.homeTeam,
                        awayTeam: args.awayTeam,
                        status: status,
                        startTime: args.startTime,
                        homeLogo: args.homeLogo,
                        awayLogo: args.awayLogo,
                      ),
                    )
                : null,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.text,
    required this.color,
    this.onTap,
    this.enabled = true,
  });

  final String text;
  final Color color;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }
}

enum _StatsTab { home, game, away }

class _ChanceMeter extends StatelessWidget {
  const _ChanceMeter({
    required this.homeTeam,
    required this.awayTeam,
    required this.homeShare,
  });
  final String homeTeam;
  final String awayTeam;
  final double homeShare;

  @override
  Widget build(BuildContext context) {
    final share = homeShare.clamp(0.05, 0.95);
    final homeFlex = math.max(1, math.min(999, (share * 1000).round()));
    final awayFlex = math.max(1, 1000 - homeFlex);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Row(
            children: [
              Expanded(
                flex: homeFlex,
                child: Container(
                  height: 21,
                  color: const Color.fromRGBO(214, 236, 255, 1),
                ),
              ),
              Expanded(
                flex: awayFlex,
                child: Container(
                  height: 21,
                  color: const Color.fromRGBO(136, 170, 47, 1),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionGrid extends StatelessWidget {
  const _SectionGrid({required this.stats});
  final List<GameCenterStat> stats;
  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return const Text(
        'No team stats available',
        style: TextStyle(color: Colors.white70),
      );
    }
    return Column(
      children: stats
          .map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.label,
                    style: const TextStyle(
                      fontSize: 17,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(child: _statCell(e.homeValue)),
                      const SizedBox(width: 8),
                      Expanded(child: _statCell(e.awayValue)),
                    ],
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _statCell(String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(65, 114, 161, 1),
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      );
}

class _BroadcastsRow extends StatelessWidget {
  const _BroadcastsRow({this.tv = const [], this.radio = const []});
  final List<String> tv;
  final List<String> radio;
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TV:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              _broadcastPill(tv.isNotEmpty ? tv.join(', ') : '—'),
            ],
          ),
        ),
        SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Radio:',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _broadcastPill(radio.isNotEmpty ? radio.join(', ') : '—'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _broadcastPill(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF4F81BD),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.centerLeft,
        child: Text(
          textAlign: TextAlign.center,
          t,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          softWrap: true,
        ),
      );
}

class _PlaysSection extends StatefulWidget {
  const _PlaysSection({required this.tables});
  final Map<String, GameCenterTable> tables;

  @override
  State<_PlaysSection> createState() => _PlaysSectionState();
}

class _PlaysSectionState extends State<_PlaysSection> {
  static const _tabOrder = ['Goals', 'Shots', 'Hits', 'Penalties', 'Faceoff'];
  int _index = 0;
  late List<String> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = _orderedTabs();
  }

  @override
  void didUpdateWidget(covariant _PlaysSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _tabs = _orderedTabs();
    if (_tabs.isEmpty) {
      _index = 0;
    } else {
      _index = _index.clamp(0, _tabs.length - 1);
    }
  }

  List<String> _orderedTabs() => _tabOrder
      .where((tab) => (widget.tables[tab]?.rows.isNotEmpty ?? false))
      .toList();

  @override
  Widget build(BuildContext context) {
    if (_tabs.isEmpty) return const SizedBox.shrink();
    final current = widget.tables[_tabs[_index]]!;
    return Container(
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++) ...[
                  _tab(
                    _tabs[i],
                    active: _index == i,
                    onTap: () => setState(() => _index = i),
                  ),
                  if (i != _tabs.length - 1) const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          _PlaysTable(table: current),
        ],
      ),
    );
  }

  Widget _tab(
    String label, {
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? const Color.fromRGBO(36, 110, 171, 1)
              : const Color.fromRGBO(35, 80, 124, 1),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Color.fromRGBO(111, 148, 183, 1),
            fontWeight: active ? FontWeight.w800 : FontWeight.w500,
            fontSize: 19,
          ),
        ),
      ),
    );
  }
}

class _PlaysTable extends StatelessWidget {
  const _PlaysTable({required this.table});
  final GameCenterTable table;

  static const _line = Color.fromRGBO(89, 143, 195, 1);

  @override
  Widget build(BuildContext context) {
    final hasRows = table.rows.isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: const BoxDecoration(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          child: hasRows
              ? Table(
                  columnWidths: const {
                    0: FlexColumnWidth(0.8),
                    1: FlexColumnWidth(0.8),
                    2: FlexColumnWidth(0.8),
                    3: FlexColumnWidth(1.5),
                    4: FlexColumnWidth(1.5),
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  border: const TableBorder(
                    horizontalInside: BorderSide(color: _line, width: .6),
                    verticalInside: BorderSide(color: _line, width: 1),
                  ),
                  children: [
                    _headerRow(table.headers),
                    for (final r in table.rows) _dataRow(r),
                  ],
                )
              : const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No events',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  TableRow _headerRow(List<String> cols) {
    final items = _normalize(cols, 5);
    return TableRow(
      children: [
        _cell(items[0], align: TextAlign.left, head: true),
        _cell(items[1], align: TextAlign.center, head: true),
        _cell(items[2], align: TextAlign.center, head: true),
        _cell(items[3], align: TextAlign.center, head: true),
        _cell(items[4], align: TextAlign.left, head: true),
      ],
    );
  }

  TableRow _dataRow(List<String> cols) {
    final items = _normalize(cols, 5);
    return TableRow(
      children: [
        _cell(items[0], align: TextAlign.center),
        _cell(items[1], align: TextAlign.center),
        _cell(items[2], align: TextAlign.center),
        _cell(items[3], align: TextAlign.center),
        _cell(items[4], align: TextAlign.center),
      ],
    );
  }

  List<String> _normalize(List<String> src, int len) {
    final out = List<String>.filled(len, '');
    for (var i = 0; i < len && i < src.length; i++) {
      out[i] = src[i];
    }
    return out;
  }

  Widget _cell(String text, {required TextAlign align, bool head = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: align,
        style: TextStyle(
          color: head ? _line : Colors.white,
          fontWeight: head ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    );
  }
}

class _SegmentSwitcher extends StatelessWidget {
  const _SegmentSwitcher({required this.active, required this.onChanged});

  final _StatsTab active;
  final ValueChanged<_StatsTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      children: [
        _seg(
          'Home',
          active: active == _StatsTab.home,
          onTap: () => onChanged(_StatsTab.home),
        ),
        _seg(
          'GAME',
          active: active == _StatsTab.game,
          onTap: () => onChanged(_StatsTab.game),
        ),
        _seg(
          'Away',
          active: active == _StatsTab.away,
          onTap: () => onChanged(_StatsTab.away),
        ),
      ],
    );
  }

  Widget _seg(String t, {required bool active, required VoidCallback onTap}) =>
      Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: active
                  ? const Color.fromRGBO(136, 170, 47, 1)
                  : const Color.fromRGBO(35, 80, 124, 1),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              t,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      );
}

class _MiniTable extends StatelessWidget {
  const _MiniTable({
    required this.table,
    required this.isLighter,
    required this.title,
  });
  final GameCenterTable table;
  final bool isLighter;
  final String title;

  @override
  Widget build(BuildContext context) {
    double _heigh = 0;
    if (table.rows.isEmpty) return const SizedBox.shrink();
    if (title.endsWith('(home)') && title.startsWith('Goalies')) {
      _heigh = 0;
    } else {
      _heigh = 10;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 0),
        ClipRRect(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isLighter
                  ? Color.fromRGBO(39, 86, 132, 1)
                  : Colors.transparent,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: _heigh),
                  Text(
                    table.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  SizedBox(height: 2),
                  _MiniTableBody(headers: table.headers, rows: table.rows),
                  SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniTableBody extends StatelessWidget {
  const _MiniTableBody({required this.headers, required this.rows});
  final List<String> headers;
  final List<List<String>> rows;

  static const _lineColor = Color.fromRGBO(89, 143, 195, 1);

  @override
  Widget build(BuildContext context) {
    final columnWidths = <int, TableColumnWidth>{
      0: const FlexColumnWidth(2),
      1: const FlexColumnWidth(1),
      2: const FlexColumnWidth(1),
      3: const FlexColumnWidth(1),
      4: const FlexColumnWidth(1),
      5: const FlexColumnWidth(1),
      6: const FlexColumnWidth(1),
    };

    return Table(
      columnWidths: columnWidths,
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: TableBorder(
        horizontalInside: BorderSide(color: _lineColor, width: .6),
        verticalInside: BorderSide(color: _lineColor, width: 1),
      ),
      children: [
        TableRow(
          decoration: const BoxDecoration(),
          children: _buildCells(headers, isHead: true),
        ),
        for (final r in rows) TableRow(children: _buildCells(r)),
      ],
    );
  }

  List<Widget> _buildCells(List<String> cols, {bool isHead = false}) {
    final items = cols;
    final textStyle = TextStyle(
      color: isHead ? Color.fromRGBO(89, 143, 195, 1) : Colors.white,
      fontWeight: isHead ? FontWeight.w700 : FontWeight.w400,
    );

    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Text(
          items.isNotEmpty ? items[0] : '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.left,
          style: textStyle,
        ),
      ),
      for (var i = 1; i < items.length; i++)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Text(
            items[i],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: textStyle,
          ),
        ),
    ];
  }
}

class _RecapTable extends StatelessWidget {
  const _RecapTable({required this.table});
  final GameCenterTable table;

  static const _bg = CustomColors.backgroundColor;
  static const _line = Color.fromRGBO(89, 143, 195, 1);

  @override
  Widget build(BuildContext context) {
    if (table.rows.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: _bg),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2), // Period ширший
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: const TableBorder(
              horizontalInside: BorderSide(color: _line, width: .6),
              verticalInside: BorderSide(color: _line, width: 1),
            ),
            children: [
              _row(table.headers, isHead: true),
              for (final r in table.rows) _row(r),
            ],
          ),
        ),
      ),
    );
  }

  TableRow _row(List<String> cols, {bool isHead = false}) {
    final style = TextStyle(
      color: isHead ? _line : Colors.white,
      fontWeight: isHead ? FontWeight.w700 : FontWeight.w400,
    );
    final cells = <Widget>[
      _cell(cols.elementAtOrNull(0) ?? '', align: TextAlign.left, style: style),
      _cell(
        cols.elementAtOrNull(1) ?? '',
        align: TextAlign.center,
        style: style,
      ),
      _cell(
        cols.elementAtOrNull(2) ?? '',
        align: TextAlign.center,
        style: style,
      ),
    ];
    return TableRow(children: cells);
  }

  Widget _cell(
    String text, {
    required TextAlign align,
    required TextStyle style,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: align,
        style: style,
      ),
    );
  }
}

class _KeyMoments extends StatelessWidget {
  const _KeyMoments({required this.items});
  final List<KeyMoment> items;

  static const _line = Color.fromRGBO(89, 143, 195, 1);

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Text(
        'No key moments recorded',
        style: TextStyle(color: Colors.white70),
      );
    }

    // Заголовки як у таблиці
    const headers = ['Event', 'Team', 'Period', 'Time', 'Player'];

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: CustomColors.backgroundColor),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(1), // label ширший
              1: FlexColumnWidth(0.6),
              2: FlexColumnWidth(0.6),
              3: FlexColumnWidth(0.6),
              4: FlexColumnWidth(1), // player ширший
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: const TableBorder(
              horizontalInside: BorderSide(color: _line, width: .6),
              verticalInside: BorderSide(color: _line, width: 1),
            ),
            children: [
              _row(headers, isHead: true),
              for (final e in items)
                _row([e.label, e.team, e.period, e.time, e.player]),
            ],
          ),
        ),
      ),
    );
  }

  TableRow _row(List<String> cols, {bool isHead = false}) {
    final style = TextStyle(
      color: isHead ? _line : Colors.white,
      fontWeight: isHead ? FontWeight.w700 : FontWeight.w400,
    );
    return TableRow(
      children: [
        _cell(
          cols.elementAtOrNull(0) ?? '',
          align: TextAlign.left,
          style: style,
        ),
        _cell(
          cols.elementAtOrNull(1) ?? '',
          align: TextAlign.center,
          style: style,
        ),
        _cell(
          cols.elementAtOrNull(2) ?? '',
          align: TextAlign.center,
          style: style,
        ),
        _cell(
          cols.elementAtOrNull(3) ?? '',
          align: TextAlign.center,
          style: style,
        ),
        _cell(
          cols.elementAtOrNull(4) ?? '',
          align: TextAlign.left,
          style: style,
        ),
      ],
    );
  }

  Widget _cell(
    String text, {
    required TextAlign align,
    required TextStyle style,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: align,
        style: style,
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({required this.enabled, required this.onShare});
  final bool enabled;
  final VoidCallback onShare;
  @override
  Widget build(BuildContext context) {
    final color = enabled
        ? const Color.fromRGBO(136, 170, 47, 1)
        : const Color(0xFF1F3B5C);
    return SizedBox(
      height: 64,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: enabled ? onShare : null,
        child: const Text(
          'Share Game Recap',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
    );
  }
}
