import '../../domain/entities/team_standing.dart';

sealed class StandingsState {
  const StandingsState();
}

class StandingsInitial extends StandingsState {
  const StandingsInitial();
}

class StandingsLoading extends StandingsState {
  const StandingsLoading();
}

class StandingsLoaded extends StandingsState {
  const StandingsLoaded(this.items);
  final List<TeamStanding> items;
}

class StandingsError extends StandingsState {
  const StandingsError(this.message);
  final String message;
}

