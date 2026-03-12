import 'package:equatable/equatable.dart';

import '../../domain/entities/team_player.dart';
import '../../domain/entities/team_schedule_item.dart';

abstract class TeamDetailState extends Equatable {
  const TeamDetailState();

  @override
  List<Object?> get props => [];
}

class TeamDetailInitial extends TeamDetailState {
  const TeamDetailInitial();
}

class TeamDetailLoading extends TeamDetailState {
  const TeamDetailLoading();
}

class TeamDetailLoaded extends TeamDetailState {
  const TeamDetailLoaded({required this.roster, required this.schedule});
  final List<TeamPlayer> roster;
  final List<TeamScheduleItem> schedule;

  @override
  List<Object?> get props => [roster, schedule];
}

class TeamDetailError extends TeamDetailState {
  const TeamDetailError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
