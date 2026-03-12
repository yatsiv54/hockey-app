import 'package:equatable/equatable.dart';
import '../../domain/entities/player_detail.dart';

abstract class PlayerDetailState extends Equatable {
  const PlayerDetailState();
  @override
  List<Object?> get props => [];
}

class PlayerDetailInitial extends PlayerDetailState {
  const PlayerDetailInitial();
}

class PlayerDetailLoading extends PlayerDetailState {
  const PlayerDetailLoading();
}

class PlayerDetailLoaded extends PlayerDetailState {
  const PlayerDetailLoaded(this.detail);
  final PlayerDetail detail;
  @override
  List<Object?> get props => [detail];
}

class PlayerDetailError extends PlayerDetailState {
  const PlayerDetailError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
