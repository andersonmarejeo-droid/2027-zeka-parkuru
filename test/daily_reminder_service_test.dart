import 'package:flutter_test/flutter_test.dart';

import 'package:zeka_parkuru/services/daily_reminder_service.dart';

void main() {
  group('Günlük Parkur hatırlatma zamanı', () {
    test('seçilen saat henüz gelmediyse bugün planlanır', () {
      final DateTime next = nextDailyReminderDateTime(
        now: DateTime(2026, 9, 1, 18, 45),
        hour: 19,
        minute: 0,
        completedToday: false,
      );

      expect(next, DateTime(2026, 9, 1, 19));
    });

    test('seçilen saat geçtiyse ertesi güne planlanır', () {
      final DateTime next = nextDailyReminderDateTime(
        now: DateTime(2026, 9, 1, 19, 1),
        hour: 19,
        minute: 0,
        completedToday: false,
      );

      expect(next, DateTime(2026, 9, 2, 19));
    });

    test('parkur tamamlandıysa bugünkü bildirim atlanır', () {
      final DateTime next = nextDailyReminderDateTime(
        now: DateTime(2026, 9, 1, 10),
        hour: 19,
        minute: 0,
        completedToday: true,
      );

      expect(next, DateTime(2026, 9, 2, 19));
    });
  });
}
