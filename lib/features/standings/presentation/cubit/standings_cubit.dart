import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nhl_app/core/usecase/usecase.dart';
import '../../domain/entities/team_standing.dart';
import '../../domain/usecases/get_standings_now.dart';
import 'standings_state.dart';

class StandingsCubit extends Cubit<StandingsState> {
  StandingsCubit(this._getNow) : super(const StandingsInitial());

  final GetStandingsNow _getNow;

  Future<void> load() async {
    if (isClosed) return;
    emit(const StandingsLoading());
    try {
      final items = await _getNow(const NoParams());
      if (isClosed) return;
      emit(StandingsLoaded(items));
    } catch (e) {
      if (isClosed) return;
      emit(StandingsError(e.toString()));
    }
  }

  List<TeamStanding> filterLeague(List<TeamStanding> all) {
    final list = List<TeamStanding>.from(all);
    int diffInt(String d) => int.tryParse(d.replaceAll('+', '')) ?? 0;
    list.sort((a, b) {
      var c = b.pts.compareTo(a.pts);
      if (c != 0) return c;
      c = b.row.compareTo(a.row);
      if (c != 0) return c;
      c = diffInt(b.diff).compareTo(diffInt(a.diff));
      if (c != 0) return c;
      return a.gp.compareTo(b.gp);
    });
    return list;
  }

  Map<String, List<TeamStanding>> groupDivision(List<TeamStanding> all) {
    final map = <String, List<TeamStanding>>{};
    for (final t in all) {
      final key = t.division ?? 'Division';
      map.putIfAbsent(key, () => <TeamStanding>[]).add(t);
    }
    for (final e in map.entries) {
      int posNum(String s) => int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 999;
      e.value.sort((a, b) => posNum(a.pos).compareTo(posNum(b.pos)));
    }
    return map;
  }

  Map<String, List<TeamStanding>> groupWildCard(List<TeamStanding> all) {
    final wc = all.where((t) => t.pos.startsWith('WC')).toList();
    final map = <String, List<TeamStanding>>{};
    for (final t in wc) {
      final key = t.conference == 'E' ? 'Eastern' : 'Western';
      map.putIfAbsent(key, () => <TeamStanding>[]).add(t);
    }
    for (final e in map.entries) {
      e.value.sort((a, b) => a.pos.compareTo(b.pos));
    }
    return map;
  }
}
