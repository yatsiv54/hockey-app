import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_player_detail.dart';
import 'player_detail_state.dart';

class PlayerDetailCubit extends Cubit<PlayerDetailState> {
  PlayerDetailCubit(this._getDetail) : super(const PlayerDetailInitial());

  final GetPlayerDetail _getDetail;

  Future<void> load(int playerId) async {
    emit(const PlayerDetailLoading());
    try {
      final detail = await _getDetail(playerId);
      emit(PlayerDetailLoaded(detail));
    } catch (e) {
      emit(PlayerDetailError(e.toString()));
    }
  }
}
