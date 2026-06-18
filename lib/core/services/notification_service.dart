import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/home/home_providers.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    
    tz.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification click -> Navigate logic can be injected here
      },
    );
    
    _initialized = true;
  }

  Future<bool> requestNotificationPermission() async {
    final bool? result = await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
        
    if (result != null) return result;

    final androidResult = await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
        
    return androidResult ?? false;
  }

  Future<void> scheduleResetReminder(int resetHour) async {
    await _flutterLocalNotificationsPlugin.cancel(100); // 100 is ID for reset reminder
    
    var now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, resetHour);
    scheduledDate = scheduledDate.subtract(const Duration(minutes: 30));
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_reset_channel', 'Daily Reset Reminder',
      channelDescription: 'Reminds you before your daily limit resets',
      importance: Importance.high,
      priority: Priority.high,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        100,
        'Günlük Sıfırlama Yaklaşıyor ⏳',
        '30 dakika içinde hesaplamalarınız sıfırlanacak!',
        scheduledDate,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      // If exact alarm permission is missing, fallback to inexact
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        100,
        'Günlük Sıfırlama Yaklaşıyor ⏳',
        '30 dakika içinde hesaplamalarınız sıfırlanacak!',
        scheduledDate,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> showLimitReachedNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'limit_alert_channel', 'Limit Alerts',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher'
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());

    await _flutterLocalNotificationsPlugin.show(
      200,
      'Sosyal Medya Limitin Doldu! 🔒',
      'Jeton kazan ve devam et.',
      platformDetails,
    );
  }

  Future<void> showJetonEarnedNotification(int amount, String app, int minutes) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'rewards_channel', 'Rewards',
      importance: Importance.high,
      priority: Priority.high,
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());

    await _flutterLocalNotificationsPlugin.show(
      300,
      '🪙 +$amount Jeton kazandın!',
      '$app için ekstra $minutes dk süre tanımlandı.',
      platformDetails,
    );
  }

  Future<void> scheduleInactiveReminder(int resetHour) async {
    await _flutterLocalNotificationsPlugin.cancel(400); // 400 is ID for inactive reminder
    
    // Schedule inactive reminder at 15 hours after resetHour (e.g. 4 AM -> 7 PM)
    final reminderHour = (resetHour + 15) % 24;
    
    var now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, reminderHour);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'inactive_reminder_channel', 'App Inactivity Reminder',
      channelDescription: 'Reminds you to earn jetons when you haven\'t opened the app',
      importance: Importance.high,
      priority: Priority.high,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        400,
        'Haydi! Jeton Kazan 🪙',
        'Ekran süresi satın almak için jetonlarını biriktirmeyi unutma!',
        scheduledDate,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      // If exact alarm permission is missing, fallback to inexact
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        400,
        'Haydi! Jeton Kazan 🪙',
        'Ekran süresi satın almak için jetonlarını biriktirmeyi unutma!',
        scheduledDate,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}

final notificationServiceProvider = Provider((ref) => NotificationService());

/// This provider observes the resetHour of the user and automatically reschedules the notification
final notificationSyncProvider = Provider((ref) {
  final service = ref.watch(notificationServiceProvider);
  final user = ref.watch(userProvider).value;
  
  if (user != null) {
    service.scheduleResetReminder(user.resetHour);
    service.scheduleInactiveReminder(user.resetHour);
  }
});
