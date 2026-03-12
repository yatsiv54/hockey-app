import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:nhl_app/core/di/di.dart';
import 'package:nhl_app/core/notifications/notification_service.dart';
import 'package:nhl_app/core/widgets/page_header.dart';
import 'package:nhl_app/devtools/dev_flags.dart';
import 'package:nhl_app/features/favorites/domain/entities/favorite_game.dart';
import 'package:nhl_app/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:nhl_app/features/game_center/presentation/pages/game_center_page.dart';
import 'package:nhl_app/features/matches/application/goal_alert_registry.dart';
import 'package:nhl_app/features/matches/dev/dev_fake_match_registry.dart';
import 'package:nhl_app/features/predictor/domain/entities/predictor_match.dart';
import 'package:nhl_app/features/settings/application/app_settings_controller.dart';
import 'package:nhl_app/features/settings/domain/entities/app_settings.dart';

import '../../domain/entities/match_entity.dart';
import '../cubit/matches_cubit.dart';
import '../cubit/matches_state.dart';

class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key});

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  late final MatchesCubit _cubit;
  late final GoalAlertRegistry _alerts;
  late final AppSettingsController _settings;
  late final NotificationService _notificationService;
  DateTime _selectedDate = DateTime.now();
  MatchStatus? _filter = MatchStatus.live;
  DefaultDateOption? _lastDefaultOption;
  DateTime _baseDate = DateTime.now();
  DateTime? _lastBaseDate;
  int _devMatchCounter = 1;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<MatchesCubit>();
    _alerts = getIt<GoalAlertRegistry>()..addListener(_onAlertsChanged);
    _settings = getIt<AppSettingsController>()..addListener(_onSettingsChanged);
    _notificationService = getIt<NotificationService>();
    _initAsync();
  }

  String get _headerTitle {
    switch (_filter) {
      case MatchStatus.live:
        return 'Live NHL Games';
      case MatchStatus.upcoming:
        return 'Upcoming NHL Games';
      case MatchStatus.finished:
        return 'Final NHL Games';
      default:
        return 'Matches';
    }
  }

  Future<void> _initAsync() async {
    await Future.wait([_alerts.ensureLoaded(), _settings.ensureLoaded()]);
    _baseDate = _settings.baseDate;
    _lastBaseDate = _baseDate;
    _lastDefaultOption = _settings.value.defaultDate;
    final initialDate = _settings.resolveDateFor(_settings.value.defaultDate);
    if (!mounted) return;
    setState(() => _selectedDate = initialDate);
    _loadMatches(initialDate);
  }

  void _onSettingsChanged() {
    final option = _settings.value.defaultDate;
    final base = _settings.baseDate;
    final defaultChanged = option != _lastDefaultOption;
    final baseChanged =
        _lastBaseDate == null || !_isSameDate(base, _lastBaseDate!);
    if (!defaultChanged && !baseChanged) return;
    _lastDefaultOption = option;
    _lastBaseDate = base;
    _baseDate = base;
    final resolved = _settings.resolveDateFor(option);
    if (_isSameDate(resolved, _selectedDate)) return;
    setState(() => _selectedDate = resolved);
    _loadMatches(resolved);
  }

  void _onAlertsChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _spawnDevMatch() {
    final match = DevFakeMatchRegistry.instance.registerMatch(
      homeTeam: 'Dev Home $_devMatchCounter',
      awayTeam: 'Dev Away $_devMatchCounter',
    );
    _devMatchCounter++;
    if (!_cubit.isClosed) {
      _cubit.addDevMatch(match);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Dev match ${match.homeTeam} vs ${match.awayTeam} додано',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _alerts.removeListener(_onAlertsChanged);
    _settings.removeListener(_onSettingsChanged);
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
                PageHeader(
                  title: _headerTitle,
                  oneLine: true,
                ),
                Builder(
                  builder: (innerCtx) {
                    final referenceToday = _baseDate;
                    return _Filters(
                      initialDate: _selectedDate,
                      referenceToday: referenceToday,
                      onChanged: (date, status) {
                        final dateChanged = !_isSameDate(date, _selectedDate);
                        setState(() {
                          _selectedDate = date;
                          _filter = status;
                        });
                        if (dateChanged) {
                          _loadMatches(date);
                        }
                      },
                    );
                  },
                ),
                Expanded(
                  child: BlocBuilder<MatchesCubit, MatchesState>(
                    builder: (context, state) {
                      if (state is MatchesLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state is MatchesLoaded) {
                        final items = _applyFilter(state.items, _filter);
                        return ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: items.length,
                          itemBuilder: (c, i) {
                            final match = items[i];
                            final bellEnabled = _alerts.isEnabled(match.id);
                            return _GameCard(
                              match: match,
                              bellEnabled: bellEnabled,
                              onBellToggle: () => _toggleBell(match),
                            );
                          },
                        );
                      }
                      if (state is MatchesError) {
                        return Center(child: Text('Error: ${state.message}'));
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          ),
          if (enableDevTesterTools)
            Positioned(
              right: 20,
              bottom: 110,
              child: FloatingActionButton.extended(
                heroTag: 'dev_fake_match_fab',
                onPressed: _spawnDevMatch,
                icon: const Icon(Icons.flash_on),
                label: const Text('Dev match'),
                backgroundColor: Colors.deepOrangeAccent,
              ),
            ),
        ],
      ),
    );
  }

  void _loadMatches(DateTime date) {
    if (_cubit.isClosed) return;
    _cubit.loadByDate(date);
  }

  List<MatchEntity> _applyFilter(List<MatchEntity> all, MatchStatus? f) {
    if (f == null) return all;
    return all.where((e) => e.status == f).toList();
  }

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _toggleBell(MatchEntity match) async {
    await _alerts.toggle(match.id);
    if (!mounted) return;
    final enabled = _alerts.isEnabled(match.id);
    if (!enabled) {
      await _notificationService.cancelGameNotifications(match.id);
      if (!mounted) return;
    }
    final text = enabled
        ? 'Goal alerts enabled for ${match.awayTeam} vs ${match.homeTeam}'
        : 'Goal alerts disabled for ${match.awayTeam} vs ${match.homeTeam}';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _Filters extends StatefulWidget {
  const _Filters({
    required this.onChanged,
    required this.initialDate,
    required this.referenceToday,
  });
  final DateTime initialDate;
  final void Function(DateTime date, MatchStatus? status) onChanged;
  final DateTime referenceToday;

  @override
  State<_Filters> createState() => _FiltersState();
}

class _FiltersState extends State<_Filters> {
  late DateTime selected;
  int tabIndex = 0; // 0 live,1 upcoming,2 final
  late DateTime referenceToday;

  @override
  void initState() {
    super.initState();
    selected = widget.initialDate;
    referenceToday = widget.referenceToday;
  }

  @override
  void didUpdateWidget(covariant _Filters oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSameDate(oldWidget.initialDate, widget.initialDate)) {
      selected = widget.initialDate;
    }
    if (!_isSameDate(oldWidget.referenceToday, widget.referenceToday)) {
      referenceToday = widget.referenceToday;
    }
  }

  void _shift(int days) {
    setState(() {
      selected = selected.add(Duration(days: days));
    });
    widget.onChanged(selected, _statusFromTab());
  }

  @override
  Widget build(BuildContext context) {
    final dates = List<DateTime>.generate(
      5,
      (i) => selected.add(Duration(days: i - 2)),
    );
    return Container(
      color: Colors.transparent,
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _Chip(
                  text: 'Live Now',
                  active: tabIndex == 0,
                  onTap: () {
                    setState(() => tabIndex = 0);
                    widget.onChanged(selected, _statusFromTab());
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Chip(
                  text: 'Upcoming',
                  active: tabIndex == 1,
                  onTap: () {
                    setState(() => tabIndex = 1);
                    widget.onChanged(selected, _statusFromTab());
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Chip(
                  text: 'Final',
                  active: tabIndex == 2,
                  onTap: () {
                    setState(() => tabIndex = 2);
                    widget.onChanged(selected, _statusFromTab());
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Color.fromRGBO(36, 110, 171, 1),
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _shift(-1),
                  child: const Icon(
                    Icons.arrow_left,
                    color: Color.fromRGBO(136, 170, 47, 1),
                    size: 40,
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: dates.map((d) {
                      final labelTop =
                          _sameDate(d, referenceToday) ? 'Today' : _wday(d);
                      final labelBottom = _dm(d);
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => selected = d);
                            widget.onChanged(selected, _statusFromTab());
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  labelTop,
                                  style: TextStyle(
                                    color: _sameDate(d, selected)
                                        ? Color.fromRGBO(136, 170, 47, 1)
                                        : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                    height: 1.0,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  labelBottom,
                                  style: TextStyle(
                                    color: _sameDate(d, selected)
                                        ? Color.fromRGBO(136, 170, 47, 1)
                                        : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 2),
                GestureDetector(
                  onTap: () => _shift(1),
                  child: const Icon(
                    Icons.arrow_right,
                    color: Color.fromRGBO(136, 170, 47, 1),
                    size: 40,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _wday(DateTime d) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[d.weekday - 1];
  }

  String _dm(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd.$mm';
  }

  bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  MatchStatus _statusFromTab() {
    switch (tabIndex) {
      case 0:
        return MatchStatus.live;
      case 1:
        return MatchStatus.upcoming;
      case 2:
      default:
        return MatchStatus.finished;
    }
  }

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.match,
    required this.bellEnabled,
    required this.onBellToggle,
  });

  final MatchEntity match;
  final bool bellEnabled;
  final VoidCallback onBellToggle;

  void _toggleFavorite(BuildContext context) {
    final favorite = FavoriteGame(
      gameId: match.id,
      homeTeam: match.homeTeam,
      awayTeam: match.awayTeam,
      homeLogo: match.homeLogo,
      awayLogo: match.awayLogo,
      status: match.status,
      startTime: match.startTime,
      homeScore: match.scoreHome,
      awayScore: match.scoreAway,
    );
    context.read<FavoritesCubit>().toggleGame(favorite);
  }

  void _openGameCenter(BuildContext context) {
    context.go(
      '/gamecenter',
      extra: GameCenterArgs(
        gameId: match.id,
        status: match.status,
        homeTeam: match.homeTeam,
        awayTeam: match.awayTeam,
        homeLogo: match.homeLogo,
        awayLogo: match.awayLogo,
        homeScore: match.scoreHome,
        awayScore: match.scoreAway,
        periodText: _periodText(match),
        clock:
            match.status == MatchStatus.live ? (match.clock ?? '00:00') : null,
        startTime: match.startTime,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFinished = match.status == MatchStatus.finished;
    final favoritesState = context.watch<FavoritesCubit>().state;
    final isFavorite = favoritesState.games.any((g) => g.gameId == match.id);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openGameCenter(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.only(right: 12, left: 12, bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 15, left: 5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _TeamCol(
                          name: match.awayTeam,
                          logoUrl: match.awayLogo,
                        ),
                      ),
                      Text(
                        _scoreText(match),
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: _TeamCol(
                          name: match.homeTeam,
                          logoUrl: match.homeLogo,
                          alignEnd: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _PillButton(
                          text: bellEnabled ? 'Unbell' : 'Bell',
                          color: bellEnabled
                              ? Colors.redAccent
                              : const Color.fromRGBO(36, 110, 171, 1),
                          enabled: !isFinished,
                          onTap: isFinished ? null : onBellToggle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PillButton(
                          text: isFavorite ? 'Favorited' : 'Star',
                          color: isFavorite
                              ? Colors.redAccent
                              : const Color.fromRGBO(136, 170, 47, 1),
                          onTap: () => _toggleFavorite(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PillButton(
                          text: 'Predictor',
                          color: const Color.fromRGBO(36, 110, 171, 1),
                          enabled: !isFinished,
                          onTap: isFinished
                              ? null
                              : () {
                                  context.go(
                                    '/predictor',
                                    extra: PredictorMatch.fromMatch(match),
                                  );
                                },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              left: -10,
              child: IconButton(
                icon: const Icon(Icons.star_rounded),
                color: isFavorite
                    ? const Color.fromRGBO(36, 110, 171, 1)
                    : Colors.black38,
                iconSize: 32,
                onPressed: () => _toggleFavorite(context),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(36, 110, 171, 1),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (match.status == MatchStatus.live &&
                          match.periodNumber != null)
                        Text(
                          _periodText(match),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      Text(
                        _centerBadgeText(match),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _scoreText(MatchEntity m) {
    if (m.scoreHome != null && m.scoreAway != null) {
      return '${m.scoreAway ?? 0} - ${m.scoreHome ?? 0}';
    }
    return '-';
  }

  String _centerBadgeText(MatchEntity m) {
    switch (m.status) {
      case MatchStatus.live:
        if (m.clock != null && m.clock!.isNotEmpty) return m.clock!;
        if (m.startTime != null) {
          return _elapsedSince(m.startTime!);
        }
        return 'LIVE';
      case MatchStatus.finished:
        return 'FINAL';
      case MatchStatus.upcoming:
        if (m.startTime != null) {
          final h = m.startTime!.hour.toString().padLeft(2, '0');
          final min = m.startTime!.minute.toString().padLeft(2, '0');
          return '$h:$min';
        }
        return 'SOON';
    }
  }

  static String _periodText(MatchEntity m) {
    final n = m.periodNumber ?? 1;
    final t = (m.periodType ?? 'REG').toUpperCase();
    if (t == 'OT') return 'OT';
    if (t == 'SO') return 'SO';
    switch (n) {
      case 1:
        return '1st';
      case 2:
        return '2nd';
      case 3:
        return '3rd';
      default:
        return '${n}th';
    }
  }

  String _elapsedSince(DateTime start) {
    final diff = DateTime.now().difference(start);
    if (diff.isNegative) return '00:00';
    final mins = diff.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = diff.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }
}

class _TeamCol extends StatelessWidget {
  const _TeamCol({required this.name, this.logoUrl, this.alignEnd = false});

  final String name;
  final String? logoUrl;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 100,
          child: logoUrl != null && logoUrl!.isNotEmpty
              ? SvgPicture.network(
                  logoUrl!,
                  fit: BoxFit.fill,
                  placeholderBuilder: (_) => Container(color: Colors.black12),
                )
              : const DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    shape: BoxShape.circle,
                  ),
                ),
        ),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 120),
          child: Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              height: 1,
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.text,
    required this.color,
    this.enabled = true,
    this.onTap,
  });

  final String text;
  final Color color;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = enabled ? color : Colors.grey.shade600;
    return GestureDetector(
      onTap: enabled && onTap != null ? onTap : null,
      child: Container(
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.active, required this.onTap});
  final String text;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? Color.fromRGBO(36, 110, 171, 1)
              : Color.fromRGBO(35, 80, 124, 1),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : Color.fromRGBO(111, 148, 183, 1),
            ),
          ),
        ),
      ),
    );
  }
}
