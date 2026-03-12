import '../../domain/entities/match_entity.dart';

sealed class MatchesState {
  const MatchesState();
}

class MatchesInitial extends MatchesState {
  const MatchesInitial();
}

class MatchesLoading extends MatchesState {
  const MatchesLoading();
}

class MatchesLoaded extends MatchesState {
  const MatchesLoaded(this.items);
  final List<MatchEntity> items;
}

class MatchesError extends MatchesState {
  const MatchesError(this.message);
  final String message;
}

