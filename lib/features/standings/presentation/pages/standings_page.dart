import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nhl_app/core/di/di.dart';
import 'package:nhl_app/core/theme/colors.dart';
import 'package:nhl_app/core/widgets/page_header.dart';
import 'package:nhl_app/features/teams/presentation/pages/team_detail_page.dart';
import '../../domain/entities/team_standing.dart';
import '../cubit/standings_cubit.dart';
import '../cubit/standings_state.dart';

class StandingsPage extends StatefulWidget {
  const StandingsPage({super.key});

  @override
  State<StandingsPage> createState() => _StandingsPageState();
}

class _StandingsPageState extends State<StandingsPage> {
  int tab = 0;

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
                title: 'Standings',
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              spacing: 10,
              children: [
                Expanded(
                  child: _Segment(
                    text: 'Wild Card',
                    active: tab == 0,
                    onTap: () => setState(() => tab = 0),
                  ),
                ),
                Expanded(
                  child: _Segment(
                    text: 'League',
                    active: tab == 1,
                    onTap: () => setState(() => tab = 1),
                  ),
                ),
                Expanded(
                  child: _Segment(
                    text: 'Division',
                    active: tab == 2,
                    onTap: () => setState(() => tab = 2),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: BlocBuilder<StandingsCubit, StandingsState>(
                builder: (context, state) {
                  if (state is StandingsLoading || state is StandingsInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is StandingsError) {
                    return Center(child: Text('Error: ${state.message}'));
                  }
                  final items = (state as StandingsLoaded).items;
                  if (tab == 0) {
                    final groups = context.read<StandingsCubit>().groupWildCard(
                          items,
                        );
                    return _renderGroups(groups);
                  } else if (tab == 1) {
                    final league = context.read<StandingsCubit>().filterLeague(
                          items,
                        );
                    return _renderSingle('League', league);
                  } else {
                    final groups = context.read<StandingsCubit>().groupDivision(
                          items,
                        );
                    return _renderGroups(groups);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _renderGroups(Map<String, List<TeamStanding>> groups) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in groups.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _StandingsBlock(
                title: entry.key,
                rows: entry.value
                    .map(
                      (t) => _TeamRow(
                        pos: t.pos,
                        team: t.team,
                        abbrev: t.abbrev,
                        gp: t.gp,
                        w: t.w,
                        l: t.l,
                        otl: t.otl,
                        pts: t.pts,
                        row: t.row,
                        gf: t.gf,
                        ga: t.ga,
                        diff: t.diff,
                        l10: t.l10,
                        strk: t.strk,
                        division: t.division ?? '',
                        logo: t.logo,
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _renderSingle(String title, List<TeamStanding> list) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 12),
      child: _StandingsBlock(
        title: title,
        rows: list
            .map(
              (t) => _TeamRow(
                pos: t.pos,
                team: t.team,
                abbrev: t.abbrev,
                gp: t.gp,
                w: t.w,
                l: t.l,
                otl: t.otl,
                pts: t.pts,
                row: t.row,
                gf: t.gf,
                ga: t.ga,
                diff: t.diff,
                l10: t.l10,
                strk: t.strk,
                division: t.division ?? '',
                logo: t.logo,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.text,
    required this.active,
    required this.onTap,
  });
  final String text;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? const Color.fromRGBO(36, 110, 171, 1)
              : const Color.fromRGBO(35, 80, 124, 1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: active ? Colors.white : Color.fromRGBO(111, 148, 183, 1),
              fontSize: 20,
              fontWeight: active ? FontWeight.w900 : FontWeight.w300,
            ),
          ),
        ),
      ),
    );
  }
}

class _StandingsBlock extends StatelessWidget {
  const _StandingsBlock({required this.title, required this.rows});
  final String title;
  final List<_TeamRow> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: CustomColors.backgroundColor,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeaderRow(),
                  for (var i = 0; i < rows.length; i++)
                    _DataRow(r: rows[i], isLast: i == rows.length - 1),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cells = [
      _cell('Pos', w: 56, isHeader: true, left: false),
      _cell('Team', w: 200, isHeader: true, align: TextAlign.left),
      _cell('GP', isHeader: true),
      _cell('W', isHeader: true),
      _cell('L', isHeader: true),
      _cell('OTL', isHeader: true),
      _cell('PTS', isHeader: true),
      _cell('ROW', isHeader: true),
      _cell('GF', isHeader: true),
      _cell('GA', isHeader: true),
      _cell('Diff', isHeader: true, w: 64),
      _cell('L10', isHeader: true, w: 64),
      _cell('Strk', isHeader: true, w: 64, right: false),
    ];
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _lineColor, width: 1)),
      ),
      child: Row(children: cells),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({required this.r, this.isLast = false});
  final _TeamRow r;
  final bool isLast;
  @override
  Widget build(BuildContext context) {
    final cells = [
      _cell(r.pos, w: 56, left: false),
      _cell(r.team, w: 200, align: TextAlign.left, bold: true),
      _cell(r.gp.toString()),
      _cell(r.w.toString()),
      _cell(r.l.toString()),
      _cell(r.otl.toString()),
      _cell(r.pts.toString()),
      _cell(r.row.toString()),
      _cell(r.gf.toString()),
      _cell(r.ga.toString()),
      _cell(r.diff, w: 64),
      _cell(r.l10, w: 64),
      _cell(r.strk, w: 64, right: false),
    ];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        context.go(
          '/teams/detail',
          extra: TeamDetailArgs(
            name: r.team,
            division: r.division.isEmpty ? '-' : r.division,
            logoUrl: r.logo,
            abbrev: r.abbrev,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: isLast
                ? BorderSide.none
                : const BorderSide(color: _lineColor, width: 0.7),
          ),
        ),
        child: Row(children: cells),
      ),
    );
  }
}

const _lineColor = Color.fromRGBO(89, 143, 195, 1);

Widget _cell(
  String text, {
  double w = 56,
  bool isHeader = false,
  TextAlign align = TextAlign.center,
  bool bold = false,
  bool left = false,
  bool right = true,
}) {
  final style = TextStyle(
    fontSize: isHeader ? 12.0 : 13.0,
    fontWeight:
        isHeader ? FontWeight.w700 : (bold ? FontWeight.w600 : FontWeight.w400),
  );
  final Alignment containerAlign =
      align == TextAlign.left ? Alignment.centerLeft : Alignment.center;
  return Container(
    alignment: containerAlign,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    width: w,
    decoration: BoxDecoration(
      border: Border(
        left: left
            ? const BorderSide(color: _lineColor, width: 1.5)
            : BorderSide.none,
        right: right
            ? const BorderSide(color: _lineColor, width: 1.5)
            : BorderSide.none,
      ),
    ),
    child: Text(
      text,
      textAlign: align,
      style: style,
      overflow: TextOverflow.ellipsis,
    ),
  );
}

class _TeamRow {
  const _TeamRow({
    required this.pos,
    required this.team,
    required this.abbrev,
    required this.gp,
    required this.w,
    required this.l,
    required this.otl,
    required this.pts,
    required this.row,
    required this.gf,
    required this.ga,
    required this.diff,
    required this.l10,
    required this.strk,
    required this.division,
    required this.logo,
  });

  final String pos;
  final String team;
  final String abbrev;
  final int gp;
  final int w;
  final int l;
  final int otl;
  final int pts;
  final int row;
  final int gf;
  final int ga;
  final String diff;
  final String l10;
  final String strk;
  final String division;
  final String? logo;
}
