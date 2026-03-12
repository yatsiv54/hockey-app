class TeamStanding {
  const TeamStanding({
    required this.team,
    required this.abbrev,
    required this.pos,
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
    this.conference,
    this.division,
    this.logo,
  });

  final String team;
  final String abbrev;
  final String pos;
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
  final String? conference;
  final String? division;
  final String? logo;
}
