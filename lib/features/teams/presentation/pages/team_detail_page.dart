import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nhl_app/core/theme/colors.dart';
import 'package:nhl_app/core/di/di.dart';
import 'package:nhl_app/core/widgets/page_header.dart';
import 'package:nhl_app/features/player/presentation/pages/player_detail_page.dart';
import 'package:nhl_app/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:nhl_app/features/favorites/presentation/cubit/favorites_state.dart';
import 'package:nhl_app/features/favorites/domain/entities/favorite_team.dart';
import 'package:nhl_app/features/favorites/domain/utils/logo_utils.dart';
import '../../domain/entities/team_player.dart';
import '../../domain/entities/team_schedule_item.dart';
import '../cubit/team_detail_cubit.dart';
import '../cubit/team_detail_state.dart';

class TeamDetailArgs {
  const TeamDetailArgs({
    required this.name,
    required this.division,
    required this.abbrev,
    this.logoUrl,
  });
  final String name;
  final String division;
  final String abbrev;
  final String? logoUrl;
}

class TeamDetailPage extends StatelessWidget {
  const TeamDetailPage({super.key, required this.args});
  final TeamDetailArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TeamDetailCubit>()..load(args.abbrev),
      child: Column(
        children: [
          BlocBuilder<FavoritesCubit, FavoritesState>(
            builder: (context, favState) {
              final isFavorite = favState.teams.any(
                (t) => t.abbrev == args.abbrev,
              );
              return PageHeader(
                title: args.name,
                actions: [
                  IconButton(
                    tooltip: isFavorite
                        ? 'Remove from favorites'
                        : 'Add to favorites',
                    icon: Icon(
                      size: 33,
                      isFavorite
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: isFavorite ? Colors.redAccent : Colors.white,
                    ),
                    onPressed: () {
                      context.read<FavoritesCubit>().toggleTeam(
                            FavoriteTeam(
                              abbrev: args.abbrev,
                              name: args.name,
                              division: args.division,
                              logoUrl: args.logoUrl ??
                                  logoUrlFromAbbrev(args.abbrev),
                            ),
                          );
                    },
                  ),
                ],
              );
            },
          ),
          Expanded(
            child: BlocBuilder<TeamDetailCubit, TeamDetailState>(
              builder: (context, state) {
                if (state is TeamDetailLoading || state is TeamDetailInitial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is TeamDetailError) {
                  return Center(child: Text('Error: ${state.message}'));
                }
                final data = state as TeamDetailLoaded;
                return ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 12,
                  ),
                  children: [
                    _TeamHeaderCard(
                      name: args.name,
                      division: args.division,
                      logoUrl: args.logoUrl,
                    ),
                    const SizedBox(height: 16),
                    const _SectionTitle('Roster'),
                    const SizedBox(height: 0),
                    if (data.roster.isEmpty)
                      const Text(
                        'Roster unavailable',
                        style: TextStyle(color: Colors.white70),
                      )
                    else
                      _RosterTable(
                        players: data.roster,
                        onPlayerTap: (player) {
                          context.go(
                            '/teams/player',
                            extra: PlayerDetailArgs(
                              playerId: player.id,
                              fallbackName: player.name,
                              fallbackNumber: player.number,
                              fallbackPosition: player.position,
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 16),
                    const _SectionTitle('Schedule'),
                    const SizedBox(height: 8),
                    if (data.schedule.isEmpty)
                      const Text(
                        'No upcoming games',
                        style: TextStyle(color: Colors.white70),
                      )
                    else
                      ...data.schedule.map((e) => _SchedulePill(item: e)),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamHeaderCard extends StatelessWidget {
  const _TeamHeaderCard({
    required this.name,
    required this.division,
    this.logoUrl,
  });
  final String name;
  final String division;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(0),
      child: Row(
        children: [
          SizedBox(
            height: 90,
            width: 80,
            child: logoUrl != null
                ? SvgPicture.network(
                    logoUrl!,
                    fit: BoxFit.contain,
                    placeholderBuilder: (_) => Container(color: Colors.black12),
                  )
                : const DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      shape: BoxShape.circle,
                    ),
                  ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.only(right: 25),
                  child: Container(
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
                      'Division: $division',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
    );
  }
}

const _lineColor = Color.fromRGBO(89, 143, 195, 1);

const double _wNum = 45;
const double _wPos = 35;
const double _wShoots = 60;
const double _wDob = 90;

class _RosterTable extends StatelessWidget {
  const _RosterTable({required this.players, required this.onPlayerTap});
  final List<TeamPlayer> players;
  final ValueChanged<TeamPlayer> onPlayerTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: CustomColors.backgroundColor),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _RosterHeaderRow(),
            for (var i = 0; i < players.length; i++)
              _RosterDataRow(
                player: players[i],
                isLast: i == players.length - 1,
                onTap: () => onPlayerTap(players[i]),
              ),
          ],
        ),
      ),
    );
  }
}

class _RosterHeaderRow extends StatelessWidget {
  const _RosterHeaderRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _lineColor, width: 1)),
      ),
      child: Row(
        children: [
          const _Cell(
            '#',
            w: _wNum,
            isHeader: true,
            left: false,
            align: TextAlign.left,
          ),
          Expanded(child: _Cell('Name', isHeader: true)),
          const _Cell('Pos', w: _wPos, isHeader: true),
          const _Cell('Shoots', w: _wShoots, isHeader: true),
          const _Cell('DOB', w: _wDob, isHeader: true, right: false),
        ],
      ),
    );
  }
}

class _RosterDataRow extends StatelessWidget {
  const _RosterDataRow({required this.player, this.isLast = false, this.onTap});
  final TeamPlayer player;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: isLast
                  ? BorderSide.none
                  : const BorderSide(color: _lineColor, width: .7),
            ),
          ),
          child: Row(
            children: [
              _Cell(player.number, w: _wNum, left: false),
              Expanded(
                child: _Cell(player.name, align: TextAlign.center, bold: true),
              ),
              _Cell(player.position, w: _wPos),
              _Cell(player.shoots, w: _wShoots),
              _Cell(player.dob, w: _wDob, right: false),
            ],
          ),
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(
    this.text, {
    this.w = 56,
    this.isHeader = false,
    this.align = TextAlign.center,
    this.bold = false,
    this.left = true,
    this.right = true,
  });

  final String text;
  final double? w;
  final bool isHeader;
  final TextAlign align;
  final bool bold;
  final bool left;
  final bool right;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: isHeader ? Color.fromRGBO(89, 143, 195, 1) : Colors.white,
      fontSize: 15,
      fontWeight: isHeader
          ? FontWeight.w700
          : (bold ? FontWeight.w600 : FontWeight.w400),
    );
    final Alignment containerAlign =
        align == TextAlign.left ? Alignment.centerLeft : Alignment.center;
    return Container(
      alignment: containerAlign,
      width: w,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          left: left
              ? const BorderSide(color: _lineColor, width: 0.7)
              : BorderSide.none,
          right: right
              ? const BorderSide(color: _lineColor, width: 0.7)
              : BorderSide.none,
        ),
      ),
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

class _SchedulePill extends StatelessWidget {
  const _SchedulePill({required this.item});
  final TeamScheduleItem item;

  @override
  Widget build(BuildContext context) {
    final date = _formatDate(item.dateTime);
    final time = _formatTime(item.dateTime);
    final place = item.isHome ? 'Home' : 'Away';
    final text = '$date - ${item.opponent} - $time - $place';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(65, 114, 161, 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        textAlign: TextAlign.center,
        text,
        style: const TextStyle(
          fontSize: 17,
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[dt.month - 1];
    final day = dt.day.toString().padLeft(2, '0');
    return '$month $day';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
