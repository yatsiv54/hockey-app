import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:nhl_app/core/di/di.dart';
import 'package:nhl_app/core/widgets/page_header.dart';
import 'package:nhl_app/features/favorites/domain/entities/favorite_game.dart';
import 'package:nhl_app/features/favorites/domain/entities/favorite_team.dart';
import 'package:nhl_app/features/favorites/domain/utils/logo_utils.dart';
import 'package:nhl_app/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:nhl_app/features/favorites/presentation/cubit/favorites_state.dart';
import 'package:nhl_app/features/game_center/presentation/pages/game_center_page.dart';
import 'package:nhl_app/features/matches/application/goal_alert_registry.dart';
import 'package:nhl_app/features/matches/domain/entities/match_entity.dart';
import 'package:nhl_app/features/teams/presentation/pages/team_detail_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

enum _FavoritesTab { teams, games }

class _FavoritesPageState extends State<FavoritesPage> {
  _FavoritesTab _tab = _FavoritesTab.teams;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const PageHeader(title: 'Favorites'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: BlocBuilder<FavoritesCubit, FavoritesState>(
              builder: (context, state) {
                final content = _tab == _FavoritesTab.teams
                    ? _TeamsTab(teams: state.teams)
                    : _GamesTab(games: state.games);
                return Column(
                  children: [
                    _TabSwitcher(
                      active: _tab,
                      onChanged: (tab) => setState(() => _tab = tab),
                    ),
                    SizedBox(height: 8),
                    Flexible(child: content),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _TabSwitcher extends StatelessWidget {
  const _TabSwitcher({required this.active, required this.onChanged});
  final _FavoritesTab active;
  final ValueChanged<_FavoritesTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F4570),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _TabButton(
            text: 'Teams',
            active: active == _FavoritesTab.teams,
            onTap: () => onChanged(_FavoritesTab.teams),
          ),
          SizedBox(width: 6),
          _TabButton(
            text: 'Games',
            active: active == _FavoritesTab.games,
            onTap: () => onChanged(_FavoritesTab.games),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.text,
    required this.active,
    required this.onTap,
  });
  final String text;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: active ? Color.fromRGBO(36, 110, 171, 1) : const Color.fromRGBO(35, 80, 124, 1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? Colors.white : Colors.white54,
              fontWeight: active ? FontWeight.w700 : FontWeight.w300,
              fontSize: 19,
            ),
          ),
        ),
      ),
    );
  }
}

class _TeamsTab extends StatelessWidget {
  const _TeamsTab({required this.teams});
  final List<FavoriteTeam> teams;

  @override
  Widget build(BuildContext context) {
    if (teams.isEmpty) {
      return const _EmptyState(message: 'List is empty');
    }
    final pairs = <List<FavoriteTeam>>[];
    for (var i = 0; i < teams.length; i += 2) {
      pairs.add(teams.sublist(i, i + 2 > teams.length ? teams.length : i + 2));
    }
    return ListView.separated(
      padding: EdgeInsets.only(top: 12),
      itemCount: pairs.length,
      separatorBuilder: (_, __) => const SizedBox.shrink(),
      itemBuilder: (context, index) => _FavoriteTeamsCard(pair: pairs[index]),
    );
  }
}

class _FavoriteTeamsCard extends StatelessWidget {
  const _FavoriteTeamsCard({required this.pair});
  final List<FavoriteTeam> pair;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: pair
          .map(
            (team) => Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 0),
              child: _FavoriteTeamTile(team: team),
            ),
          )
          .toList(),
    );
  }
}

class _FavoriteTeamTile extends StatelessWidget {
  const _FavoriteTeamTile({required this.team});
  final FavoriteTeam team;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        context.go(
          '/teams/detail',
          extra: TeamDetailArgs(
            name: team.name,
            division: team.division,
            logoUrl: team.logoUrl,
            abbrev: team.abbrev,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(0, 12, 25, 12),
        child: Row(
          children: [
            SizedBox(
              height: 56,
              width: 70,
              child: _LogoBox(
                url: team.logoUrl ?? logoUrlFromAbbrev(team.abbrev),
                rounded: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          team.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.star_rounded,
                          color: Colors.redAccent,
                        ),
                        onPressed: () => context.read<FavoritesCubit>().toggleTeam(team),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(79, 160, 241, 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Division: ${team.division.isEmpty ? '-' : team.division}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GamesTab extends StatelessWidget {
  const _GamesTab({required this.games});
  final List<FavoriteGame> games;

  @override
  Widget build(BuildContext context) {
    if (games.isEmpty) {
      return const _EmptyState(message: 'List is empty');
    }
    return ListView.separated(
      padding: EdgeInsets.only(top: 12),
      itemCount: games.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _FavoriteGameCard(game: games[index]),
    );
  }
}

class _FavoriteGameCard extends StatelessWidget {
  const _FavoriteGameCard({required this.game});
  final FavoriteGame game;

  @override
  Widget build(BuildContext context) {
    final isFinished = game.status == MatchStatus.finished;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        context.go(
          '/gamecenter',
          extra: GameCenterArgs(
            gameId: game.gameId,
            homeTeam: game.homeTeam,
            awayTeam: game.awayTeam,
            homeLogo: game.homeLogo,
            awayLogo: game.awayLogo,
            status: game.status,
            startTime: game.startTime,
            homeScore: game.homeScore,
            awayScore: game.awayScore,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFF246EAB),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                    ),
                    child: GestureDetector(
                      onTap: () => context.read<FavoritesCubit>().toggleGame(game),
                      child: const Icon(
                        Icons.star_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Positioned(top: 35, child: _ScoreBlock(game: game)),
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _TeamBlock(
                          name: game.awayTeam,
                          logo: game.awayLogo,
                        ),
                      ),
                      Expanded(
                        child: _TeamBlock(
                          name: game.homeTeam,
                          logo: game.homeLogo,
                          alignEnd: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!isFinished) ...[
              _NotificationToggle(
                label: 'Bell Goals',
                value: game.bellGoals,
                onChanged: (v) {
                  context.read<FavoritesCubit>().updateGameNotification(
                        game.gameId,
                        bellGoals: v,
                      );
                  final shouldEnable = v || game.bellFinal;
                  getIt<GoalAlertRegistry>().setEnabled(
                    game.gameId,
                    shouldEnable,
                  );
                },
              ),
              const SizedBox(height: 8),
              _NotificationToggle(
                label: 'Bell Final',
                value: game.bellFinal,
                onChanged: (v) {
                  context.read<FavoritesCubit>().updateGameNotification(
                        game.gameId,
                        bellFinal: v,
                      );
                  final shouldEnable = v || game.bellGoals;
                  getIt<GoalAlertRegistry>().setEnabled(
                    game.gameId,
                    shouldEnable,
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _centerBadgeText(FavoriteGame g) {
    switch (g.status) {
      case MatchStatus.live:
        return 'Live';
      case MatchStatus.finished:
        return 'Final';
      case MatchStatus.upcoming:
        if (g.startTime != null) {
          final h = g.startTime!.hour.toString().padLeft(2, '0');
          final m = g.startTime!.minute.toString().padLeft(2, '0');
          return '$h:$m';
        }
        return 'Scheduled';
    }
  }
}

class _ScoreBlock extends StatelessWidget {
  const _ScoreBlock({required this.game});
  final FavoriteGame game;

  @override
  Widget build(BuildContext context) {
    final statusText = _statusText(game);
    final scoreText = _scoreText(game);
    return Column(
      children: [
        Text(
          statusText,
          style: const TextStyle(
            color: Color(0xFF2D5E95),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          scoreText,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 28,
          ),
        ),
      ],
    );
  }

  String _scoreText(FavoriteGame g) {
    if (g.homeScore != null && g.awayScore != null) {
      return '${g.awayScore}-${g.homeScore}';
    }
    return g.startTime != null ? _formatTime(g.startTime!) : 'TBD';
  }

  String _statusText(FavoriteGame g) {
    switch (g.status) {
      case MatchStatus.live:
        return 'Live';
      case MatchStatus.finished:
        return 'Final';
      case MatchStatus.upcoming:
        return 'Scheduled';
    }
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _TeamBlock extends StatelessWidget {
  const _TeamBlock({required this.name, this.logo, this.alignEnd = false});
  final String name;
  final String? logo;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _LogoBox(url: logo),
        Text(
          name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ],
    );
  }
}

class _NotificationToggle extends StatelessWidget {
  const _NotificationToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(35, 86, 130, 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Switch(
            value: value,
            onChanged: onChanged,
            trackColor: WidgetStatePropertyAll(const Color(0xFF4CAF50)),
            activeTrackColor: Colors.white,
            inactiveThumbColor: Colors.grey.shade300,
            inactiveTrackColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _LogoBox extends StatelessWidget {
  const _LogoBox({this.url, this.rounded = false});
  final String? url;
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    final placeholder = SizedBox(
      height: 56,
      width: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black12,
          shape: rounded ? BoxShape.rectangle : BoxShape.circle,
          borderRadius: rounded ? BorderRadius.circular(8) : null,
        ),
      ),
    );
    if (url == null || url!.isEmpty) {
      return placeholder;
    }
    final uri = Uri.tryParse(url!);
    final path = uri?.path.toLowerCase() ?? url!.toLowerCase();
    final isSvg = path.endsWith('.svg');
    return SizedBox(
      height: 80,
      width: 100,
      child: ClipRRect(
        borderRadius: rounded ? BorderRadius.circular(12) : BorderRadius.zero,
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Colors.transparent),
          child: isSvg
              ? SvgPicture.network(
                  url!,
                  fit: BoxFit.contain,
                  placeholderBuilder: (_) => placeholder,
                )
              : CachedNetworkImage(
                  imageUrl: url!,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => placeholder,
                  errorWidget: (_, __, ___) => placeholder,
                ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(color: Colors.white70),
        textAlign: TextAlign.center,
      ),
    );
  }
}
