class TeamScheduleItem {
  const TeamScheduleItem({
    required this.dateTime,
    required this.opponent,
    required this.isHome,
  });

  final DateTime dateTime;
  final String opponent;
  final bool isHome;
}
