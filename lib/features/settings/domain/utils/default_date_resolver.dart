import '../entities/app_settings.dart';

DateTime resolveDefaultDate(DefaultDateOption option, DateTime now) {
  switch (option) {
    case DefaultDateOption.today:
      return now;
    case DefaultDateOption.yesterday:
      return now.subtract(const Duration(days: 1));
    case DefaultDateOption.tomorrow:
      return now.add(const Duration(days: 1));
  }
}
