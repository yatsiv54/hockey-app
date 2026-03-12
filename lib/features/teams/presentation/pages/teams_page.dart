import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:nhl_app/core/di/di.dart';
import 'package:nhl_app/core/widgets/page_header.dart';
import 'package:nhl_app/features/standings/presentation/cubit/standings_cubit.dart';
import 'package:nhl_app/features/standings/presentation/cubit/standings_state.dart';
import 'package:nhl_app/features/teams/presentation/pages/team_detail_page.dart';

class TeamsPage extends StatelessWidget {
  const TeamsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<StandingsCubit>()..load(),
      child: Column(
        children: [
          Builder(
            builder: (innerCtx) {
              final cubit = innerCtx.read<StandingsCubit>();
              return PageHeader(
                title: 'Teams',
                actions: [
                  IconButton(
                    tooltip: 'Refresh',
                    icon: Image.asset(
                      'assets/icons/refresh.png',
                      width: 25,
                      height: 25,
                    ),
                    onPressed: () {
                      if (!cubit.isClosed) cubit.load();
                    },
                  ),
                ],
              );
            },
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: BlocBuilder<StandingsCubit, StandingsState>(
                builder: (context, state) {
                  if (state is StandingsLoading || state is StandingsInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is StandingsError) {
                    return Center(child: Text('Error: ${state.message}'));
                  }
                  final items = (state as StandingsLoaded).items;
                  final map = <String, _TeamInfo>{};
                  for (final t in items) {
                    final division = t.division ?? '';
                    final info = map[t.team];
                    if (info == null) {
                      map[t.team] = _TeamInfo(
                        name: t.team,
                        division: division,
                        logoUrl: t.logo,
                        abbrev: t.abbrev,
                      );
                    } else {
                      final updatedDivision =
                          info.division.isEmpty && division.isNotEmpty
                          ? division
                          : info.division;
                      final updatedLogo = info.logoUrl ?? t.logo;
                      map[t.team] = info.copyWith(
                        division: updatedDivision,
                        logoUrl: updatedLogo,
                      );
                    }
                  }
                  final list = map.values.toList()
                    ..sort((a, b) => a.name.compareTo(b.name));
                  return ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final team = list[i];
                      return _TeamTile(
                        team: team,
                        onTap: () {
                          context.go(
                            '/teams/detail',
                            extra: TeamDetailArgs(
                              name: team.name,
                              division: team.division.isEmpty
                                  ? '-'
                                  : team.division,
                              logoUrl: team.logoUrl,
                              abbrev: team.abbrev,
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamInfo {
  const _TeamInfo({
    required this.name,
    required this.division,
    this.logoUrl,
    required this.abbrev,
  });
  final String name;
  final String division;
  final String? logoUrl;
  final String abbrev;

  _TeamInfo copyWith({String? division, String? logoUrl}) => _TeamInfo(
    name: name,
    division: division ?? this.division,
    logoUrl: logoUrl ?? this.logoUrl,
    abbrev: abbrev,
  );
}

class _TeamTile extends StatelessWidget {
  const _TeamTile({required this.team, required this.onTap});
  final _TeamInfo team;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
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
              child: team.logoUrl != null
                  ? SvgPicture.network(
                      team.logoUrl!,
                      fit: BoxFit.contain,
                      placeholderBuilder: (_) =>
                          Container(color: Colors.black12),
                    )
                  : const DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        shape: BoxShape.circle,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
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
                      'Division: ${team.division}',
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
