import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import 'daily_course_service.dart';

typedef DailyCourseOpenHandler = void Function();

/// Returns the next wall-clock reminder time.
///
/// A completed course never schedules another reminder for the same day. An
/// incomplete course is reminded later today only when the selected time has
/// not passed yet.
DateTime nextDailyReminderDateTime({
  required DateTime now,
  required int hour,
  required int minute,
  required bool completedToday,
}) {
  final DateTime today = DateTime(now.year, now.month, now.day, hour, minute);
  if (completedToday || !today.isAfter(now)) {
    return DateTime(now.year, now.month, now.day + 1, hour, minute);
  }
  return today;
}

class DailyReminderService {
  DailyReminderService._();

  static final DailyReminderService instance = DailyReminderService._();

  static const int notificationId = 41001;
  static const String notificationPayload = 'open_daily_course';
  static const String channelId = 'daily_course_reminder_v1';
  static const String channelName = 'Günlük Parkur Hatırlatıcıları';

  static const int defaultHour = 19;
  static const int defaultMinute = 0;

  static const String _enabledKey = 'daily_course_reminder_enabled_v1';
  static const String _hourKey = 'daily_course_reminder_hour_v1';
  static const String _minuteKey = 'daily_course_reminder_minute_v1';
  static const String _permissionAskedKey =
      'daily_course_reminder_permission_asked_v1';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  DailyCourseOpenHandler? _onOpenDailyCourse;
  Future<void>? _initialization;
  bool _nativeReady = false;
  bool _pendingOpen = false;
  bool _enabled = true;
  int _hour = defaultHour;
  int _minute = defaultMinute;
  DateTime? _lastOpenAt;

  bool get enabled => _enabled;
  int get hour => _hour;
  int get minute => _minute;

  bool get _supportsNativeNotifications =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> start({
    required DailyCourseOpenHandler onOpenDailyCourse,
  }) async {
    _onOpenDailyCourse = onOpenDailyCourse;

    try {
      await initialize(requestPermissionOnFirstUse: true);
      _deliverPendingOpen();
      await refreshSchedule();
    } catch (error, stackTrace) {
      debugPrint('Daily reminder initialization skipped: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> initialize({bool requestPermissionOnFirstUse = false}) {
    final Future<void>? current = _initialization;
    if (current != null) return current;

    final Future<void> created = _initialize(
      requestPermissionOnFirstUse: requestPermissionOnFirstUse,
    );
    _initialization = created;
    return created;
  }

  Future<void> _initialize({required bool requestPermissionOnFirstUse}) async {
    _enabled = await _preferences.getBool(_enabledKey) ?? true;
    _hour = (await _preferences.getInt(_hourKey) ?? defaultHour)
        .clamp(0, 23)
        .toInt();
    _minute = (await _preferences.getInt(_minuteKey) ?? defaultMinute)
        .clamp(0, 59)
        .toInt();

    if (!_supportsNativeNotifications) return;

    try {
      timezone_data.initializeTimeZones();
      final TimezoneInfo deviceTimeZone =
          await FlutterTimezone.getLocalTimezone();
      timezone.setLocalLocation(
        timezone.getLocation(deviceTimeZone.identifier),
      );

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      await _notifications.initialize(
        settings: const InitializationSettings(android: androidSettings),
        onDidReceiveNotificationResponse: _handleNotificationResponse,
      );

      _nativeReady = true;
    } catch (error, stackTrace) {
      debugPrint('Daily reminder native setup failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      _nativeReady = false;
      return;
    }

    final NotificationAppLaunchDetails? launchDetails = await _notifications
        .getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final NotificationResponse? response =
          launchDetails?.notificationResponse;
      if (response?.payload == notificationPayload) {
        _pendingOpen = true;
      }
    }

    if (_enabled && requestPermissionOnFirstUse) {
      await _requestFirstPermissionIfNeeded();
    }
  }

  Future<void> _requestFirstPermissionIfNeeded() async {
    final AndroidFlutterLocalNotificationsPlugin? android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;

    final bool alreadyEnabled = await android.areNotificationsEnabled() ?? true;
    if (alreadyEnabled) return;

    final bool askedBefore =
        await _preferences.getBool(_permissionAskedKey) ?? false;
    if (askedBefore) {
      await _storeEnabled(false);
      return;
    }

    await _preferences.setBool(_permissionAskedKey, true);
    final bool granted =
        await android.requestNotificationsPermission() ?? false;
    if (!granted) {
      await _storeEnabled(false);
    }
  }

  Future<bool> setEnabled(bool value) async {
    await initialize();

    if (!value) {
      await _storeEnabled(false);
      await _cancelNotification();
      return true;
    }

    if (_supportsNativeNotifications && !_nativeReady) {
      await _storeEnabled(false);
      return false;
    }

    if (_supportsNativeNotifications && _nativeReady) {
      final AndroidFlutterLocalNotificationsPlugin? android = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final bool granted =
          await android?.requestNotificationsPermission() ?? true;
      if (!granted) {
        await _storeEnabled(false);
        await _cancelNotification();
        return false;
      }
    }

    await _storeEnabled(true);
    await refreshSchedule();
    return true;
  }

  Future<void> setTime({required int hour, required int minute}) async {
    await initialize();

    _hour = hour.clamp(0, 23).toInt();
    _minute = minute.clamp(0, 59).toInt();
    await Future.wait<void>(<Future<void>>[
      _preferences.setInt(_hourKey, _hour),
      _preferences.setInt(_minuteKey, _minute),
    ]);
    await refreshSchedule();
  }

  Future<void> resetDefaults() async {
    await initialize();
    await setTime(hour: defaultHour, minute: defaultMinute);
    await setEnabled(true);
  }

  Future<void> markTodayCompleted() async {
    await initialize();
    if (!_enabled) return;
    await refreshSchedule(completedToday: true);
  }

  Future<void> refreshSchedule({bool? completedToday}) async {
    await initialize();
    if (!_nativeReady) return;

    await _cancelNotification();
    if (!_enabled) return;

    final bool completed =
        completedToday ??
        (await DailyCourseService.instance.loadToday()).allCompleted;
    final DateTime next = nextDailyReminderDateTime(
      now: DateTime.now(),
      hour: _hour,
      minute: _minute,
      completedToday: completed,
    );
    final timezone.TZDateTime scheduledDate = timezone.TZDateTime(
      timezone.local,
      next.year,
      next.month,
      next.day,
      next.hour,
      next.minute,
    );

    final bool turkish =
        PlatformDispatcher.instance.locale.languageCode == 'tr';
    final String title = turkish
        ? 'Bugünün Zekâ Parkuru hazır! 🧠'
        : "Today's Brain Course is ready! 🧠";
    final String body = turkish
        ? 'Serini koru, kısa parkurunu tamamla ve yıldızlarını topla.'
        : 'Keep your streak, finish the daily course and collect your stars.';

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription:
              'Tamamlanmamış Günlük Parkur için cihaz içi hatırlatmalar.',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
          visibility: NotificationVisibility.public,
          autoCancel: true,
        );

    await _notifications.zonedSchedule(
      id: notificationId,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: notificationPayload,
    );
  }

  Future<void> _storeEnabled(bool value) async {
    _enabled = value;
    await _preferences.setBool(_enabledKey, value);
  }

  Future<void> _cancelNotification() async {
    if (!_nativeReady) return;
    await _notifications.cancel(id: notificationId);
  }

  void _handleNotificationResponse(NotificationResponse response) {
    if (response.payload != notificationPayload) return;
    _pendingOpen = true;
    _deliverPendingOpen();
  }

  void _deliverPendingOpen() {
    final DailyCourseOpenHandler? handler = _onOpenDailyCourse;
    if (!_pendingOpen || handler == null) return;

    final DateTime now = DateTime.now();
    final DateTime? previous = _lastOpenAt;
    if (previous != null &&
        now.difference(previous) < const Duration(seconds: 2)) {
      _pendingOpen = false;
      return;
    }

    _pendingOpen = false;
    _lastOpenAt = now;
    scheduleMicrotask(handler);
  }
}
