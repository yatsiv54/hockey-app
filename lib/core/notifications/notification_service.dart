import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const String _androidIcon = '@drawable/notification_icon';

  Future<void> init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings(_androidIcon);
    const initializationSettings = InitializationSettings(android: android);
    await _plugin.initialize(initializationSettings);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _initialized = true;
  }

  Future<void> showGoalAlert({
    required String matchId,
    required String title,
    required String body,
  }) async {
    if (!_initialized) return;
    await _plugin.show(
      _goalNotificationId(matchId),
      title,
      body,
      const NotificationDetails(android: _goalChannel),
    );
  }

  Future<void> showFinalAlert({
    required String matchId,
    required String title,
    required String body,
  }) async {
    if (!_initialized) return;
    await _plugin.show(
      _finalNotificationId(matchId),
      title,
      body,
      const NotificationDetails(android: _finalChannel),
    );
  }

  Future<void> showPredictorAlert({
    required String title,
    required String body,
  }) async {
    if (!_initialized) return;
    await _plugin.show(
      _predictorNotificationId,
      title,
      body,
      const NotificationDetails(android: _predictorChannel),
    );
  }

  Future<void> cancelGameNotifications(String matchId) async {
    if (!_initialized) return;
    await _plugin.cancel(_goalNotificationId(matchId));
    await _plugin.cancel(_finalNotificationId(matchId));
  }

  int _goalNotificationId(String matchId) => matchId.hashCode;
  int _finalNotificationId(String matchId) => matchId.hashCode ^ 0x0f0f0f;
  static const int _predictorNotificationId = 0x7ffff;

  static const AndroidNotificationDetails _goalChannel =
      AndroidNotificationDetails(
    'goal_alerts',
    'Goal Alerts',
    channelDescription: 'Instant alerts when a subscribed match gets a goal.',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    icon: _androidIcon,
  );

  static const AndroidNotificationDetails _finalChannel =
      AndroidNotificationDetails(
    'final_alerts',
    'Final Score Alerts',
    channelDescription: 'Final whistle summaries for your tracked games.',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    icon: _androidIcon,
  );

  static const AndroidNotificationDetails _predictorChannel =
      AndroidNotificationDetails(
    'predictor_alerts',
    'Predictor Alerts',
    channelDescription: 'Reminders and summaries for your predictions.',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    icon: _androidIcon,
  );
}
