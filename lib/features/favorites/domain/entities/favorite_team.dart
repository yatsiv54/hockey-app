import 'package:equatable/equatable.dart';

class FavoriteTeam extends Equatable {
  const FavoriteTeam({
    required this.abbrev,
    required this.name,
    required this.division,
    this.logoUrl,
  });

  final String abbrev;
  final String name;
  final String division;
  final String? logoUrl;

  FavoriteTeam copyWith({
    String? abbrev,
    String? name,
    String? division,
    String? logoUrl,
  }) {
    return FavoriteTeam(
      abbrev: abbrev ?? this.abbrev,
      name: name ?? this.name,
      division: division ?? this.division,
      logoUrl: logoUrl ?? this.logoUrl,
    );
  }

  @override
  List<Object?> get props => [abbrev, name, division, logoUrl];
}
