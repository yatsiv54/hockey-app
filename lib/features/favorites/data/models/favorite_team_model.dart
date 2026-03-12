import '../../domain/entities/favorite_team.dart';

class FavoriteTeamModel extends FavoriteTeam {
  const FavoriteTeamModel({
    required super.abbrev,
    required super.name,
    required super.division,
    super.logoUrl,
  });

  factory FavoriteTeamModel.fromMap(Map<String, dynamic> map) {
    return FavoriteTeamModel(
      abbrev: map['abbrev'] as String? ?? '',
      name: map['name'] as String? ?? '',
      division: map['division'] as String? ?? '-',
      logoUrl: map['logoUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'abbrev': abbrev,
        'name': name,
        'division': division,
        'logoUrl': logoUrl,
      };

  static FavoriteTeamModel fromEntity(FavoriteTeam team) => FavoriteTeamModel(
        abbrev: team.abbrev,
        name: team.name,
        division: team.division,
        logoUrl: team.logoUrl,
      );
}
