enum DefaultDateOption { today, yesterday, tomorrow }

class AppSettings {
  const AppSettings({
    required this.goalAlerts,
    required this.finalScoreAlerts,
    required this.predictorNotifications,
    required this.defaultDate,
    this.preferredDate,
  });

  factory AppSettings.initial() => const AppSettings(
        goalAlerts: true,
        finalScoreAlerts: false,
        predictorNotifications: true,
        defaultDate: DefaultDateOption.today,
        preferredDate: null,
      );

  final bool goalAlerts;
  final bool finalScoreAlerts;
  final bool predictorNotifications;
  final DefaultDateOption defaultDate;
  final DateTime? preferredDate;

  AppSettings copyWith({
    bool? goalAlerts,
    bool? finalScoreAlerts,
    bool? predictorNotifications,
    DefaultDateOption? defaultDate,
    DateTime? preferredDate,
  }) {
    return AppSettings(
      goalAlerts: goalAlerts ?? this.goalAlerts,
      finalScoreAlerts: finalScoreAlerts ?? this.finalScoreAlerts,
      predictorNotifications:
          predictorNotifications ?? this.predictorNotifications,
      defaultDate: defaultDate ?? this.defaultDate,
      preferredDate: preferredDate ?? this.preferredDate,
    );
  }

  Map<String, dynamic> toMap() => {
        'goalAlerts': goalAlerts,
        'finalScoreAlerts': finalScoreAlerts,
        'predictorNotifications': predictorNotifications,
        'defaultDate': defaultDate.name,
        'preferredDate': preferredDate?.toIso8601String(),
      };

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    final defaultDateName = map['defaultDate'] as String?;
    final defaultDate = DefaultDateOption.values.firstWhere(
      (e) => e.name == defaultDateName,
      orElse: () => DefaultDateOption.today,
    );
    final preferredDateRaw = map['preferredDate'] as String?;
    return AppSettings(
      goalAlerts: map['goalAlerts'] as bool? ?? true,
      finalScoreAlerts: map['finalScoreAlerts'] as bool? ?? false,
      predictorNotifications:
          map['predictorNotifications'] as bool? ?? true,
      defaultDate: defaultDate,
      preferredDate: preferredDateRaw == null
          ? null
          : DateTime.tryParse(preferredDateRaw),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings &&
        other.goalAlerts == goalAlerts &&
        other.finalScoreAlerts == finalScoreAlerts &&
        other.predictorNotifications == predictorNotifications &&
        other.defaultDate == defaultDate &&
        _sameDate(other.preferredDate, preferredDate);
  }

  @override
  int get hashCode =>
      goalAlerts.hashCode ^
      finalScoreAlerts.hashCode ^
      predictorNotifications.hashCode ^
      defaultDate.hashCode ^
      (preferredDate?.millisecondsSinceEpoch ?? 0);

  static bool _sameDate(DateTime? a, DateTime? b) {
    if (a == null || b == null) return a == null && b == null;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
