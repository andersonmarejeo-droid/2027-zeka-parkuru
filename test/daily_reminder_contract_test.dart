import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _source(String relativePath) {
  return File(relativePath).readAsStringSync();
}

void main() {
  test('Günlük Parkur yerel hatırlatıcısı tek merkezden yönetilir', () {
    final String reminder = _source('lib/services/daily_reminder_service.dart');
    final String main = _source('lib/main.dart');
    final String daily = _source('lib/pages/daily_course_page.dart');
    final String settings = _source('lib/pages/settings_page.dart');
    final String manifest = _source('android/app/src/main/AndroidManifest.xml');

    expect(reminder, contains("notificationPayload = 'open_daily_course'"));
    expect(reminder, contains('AndroidScheduleMode.inexactAllowWhileIdle'));
    expect(
      reminder,
      contains('matchDateTimeComponents: DateTimeComponents.time'),
    );
    expect(reminder, contains('requestNotificationsPermission()'));
    expect(reminder, contains('DailyCourseService.instance.loadToday()'));
    expect(main, contains('onOpenDailyCourse: _openDailyCourse'));
    expect(main, contains("RouteSettings(name: '/daily-course')"));
    expect(daily, contains('markTodayCompleted()'));
    expect(settings, contains('daily_course_reminder_toggle'));
    expect(settings, contains('daily_course_reminder_time_button'));
    expect(
      manifest,
      contains(
        'com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver',
      ),
    );
    expect(manifest, contains('android.permission.RECEIVE_BOOT_COMPLETED'));
  });
}
