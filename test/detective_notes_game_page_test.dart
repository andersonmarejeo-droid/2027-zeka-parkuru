import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/detective_notes/detective_notes_game_page.dart';
import 'package:zeka_parkuru/games/detective_notes/detective_notes_puzzle.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

void main() {
  setUpAll(installTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets(
    'detective board solves from its deduction matrix on a compact phone',
    (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('tr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: DetectiveNotesPlayPage(
            level: const ParkurLevelSpec(
              number: 1,
              titleTr: 'Dosya 1',
              titleEn: 'Case 1',
              subtitleTr: 'Çöz',
              subtitleEn: 'Solve',
              difficulty: 'GÖZLEMCİ',
              icon: Icons.manage_search_rounded,
            ),
            previousBestScore: 0,
          ),
        ),
      );
      await tester.pump();
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -1000));
      await tester.pumpAndSettle();
      final Object? initialLayoutIssue = tester.takeException();
      expect(
        initialLayoutIssue,
        isNull,
        reason: initialLayoutIssue is FlutterError
            ? initialLayoutIssue.toStringDeep()
            : '$initialLayoutIssue',
      );

      final DetectiveNotesPuzzle puzzle = DetectiveNotesPuzzle.forLevel(1);
      for (int person = 0; person < 4; person++) {
        final int relic = puzzle.solution.relicByPerson[person];
        final Finder cell = find.byKey(
          ValueKey<String>('detective_cell_relic_${person}_$relic'),
        );
        await tester.ensureVisible(cell);
        await tester.tap(cell);
        await tester.pump();
      }
      final Finder roomsTab = find.byKey(
        const ValueKey<String>('detective_rooms_tab'),
      );
      await tester.ensureVisible(roomsTab);
      await tester.tap(roomsTab);
      await tester.pump();
      for (int person = 0; person < 4; person++) {
        final int room = puzzle.solution.roomByPerson[person];
        final Finder cell = find.byKey(
          ValueKey<String>('detective_cell_room_${person}_$room'),
        );
        await tester.ensureVisible(cell);
        await tester.tap(cell);
        await tester.pump();
      }
      final Finder seatsTab = find.byKey(
        const ValueKey<String>('detective_seats_tab'),
      );
      await tester.ensureVisible(seatsTab);
      await tester.tap(seatsTab);
      await tester.pump();
      for (int person = 0; person < 4; person++) {
        final int seat = puzzle.solution.seatOfPerson(person);
        final Finder cell = find.byKey(
          ValueKey<String>('detective_cell_seat_${person}_$seat'),
        );
        await tester.ensureVisible(cell);
        await tester.tap(cell);
        await tester.pump();
      }
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -520));
      await tester.pumpAndSettle();
      final Finder solveButton = find.text('VAKAYI ÇÖZ');
      await tester.ensureVisible(solveButton);
      await tester.tap(solveButton);
      await tester.pump(const Duration(milliseconds: 220));

      expect(find.text('VAKA ÇÖZÜLDÜ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
