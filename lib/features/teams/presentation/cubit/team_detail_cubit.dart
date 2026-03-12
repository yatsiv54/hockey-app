import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_team_roster.dart';
import '../../domain/usecases/get_team_schedule.dart';
import 'team_detail_state.dart';

class TeamDetailCubit extends Cubit<TeamDetailState> {
  TeamDetailCubit(this._getRoster, this._getSchedule)
      : super(const TeamDetailInitial());

  final GetTeamRoster _getRoster;
  final GetTeamSchedule _getSchedule;

  Future<void> load(String abbrev) async {
    emit(const TeamDetailLoading());
    try {
      final roster = await _getRoster(abbrev);
      final schedule = await _getSchedule(abbrev);
      emit(TeamDetailLoaded(roster: roster, schedule: schedule));
    } catch (e) {
      emit(TeamDetailError(e.toString()));
    }
  }
}
