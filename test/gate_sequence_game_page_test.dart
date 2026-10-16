import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/gate_sequence/gate_sequence_game_page.dart';
import 'package:zeka_parkuru/games/gate_sequence/gate_sequence_puzzle.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

void main() {
  setUpAll(installTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('vault sequence is playable and completes on a compact phone', (
    WidgetTester tester,
  ) async {
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
        home: GateSequencePlayPage(
          level: const ParkurLevelSpec(
            number: 1,
            titleTr: 'Dizi 1',
            titleEn: 'Sequence 1',
            subtitleTr: 'Sırala',
            subtitleEn: 'Order',
            difficulty: 'ÇIRAK',
            icon: Icons.door_front_door_outlined,
          ),
          previousBestScore: 0,
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);

    final GateSequencePuzzle puzzle = GateSequencePuzzle.forLevel(1);
    final List<int> intentionallyWrong = <int>[
      puzzle.solution[1],
      puzzle.solution[0],
      ...puzzle.solution.skip(2),
    ];
    for (final int gate in intentionallyWrong) {
      final Finder tile = find.byKey(
        ValueKey<String>('gate_sequence_gate_$gate'),
      );
      await tester.scrollUntilVisible(
        tile,
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      await tester.tap(tile);
      await tester.pump();
      expect(tester.takeException(), isNull);
    }

    final Finder check = find.byKey(
      const ValueKey<String>('gate_sequence_check'),
    );
    await tester.scrollUntilVisible(
      check,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(check);
    await tester.pumpAndSettle();
    await tester.tap(check);
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.textContaining('ipucu ile çelişiyor'), findsOneWidget);

    final Finder firstSlot = find.byKey(
      const ValueKey<String>('gate_sequence_slot_0'),
    );
    await tester.scrollUntilVisible(
      firstSlot,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(firstSlot);
    await tester.pumpAndSettle();
    await tester.tap(firstSlot);

    final Finder movedGate = find.byKey(
      ValueKey<String>('gate_sequence_gate_${puzzle.solution.first}'),
    );
    await tester.scrollUntilVisible(
      movedGate,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(movedGate);
    await tester.pumpAndSettle();
    await tester.tap(movedGate);
    await tester.pump();

    final Finder verifyAgain = find.byKey(
      const ValueKey<String>('gate_sequence_check'),
    );
    await tester.scrollUntilVisible(
      verifyAgain,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(verifyAgain);
    await tester.pumpAndSettle();
    await tester.tap(verifyAgain);
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('KASA AÇILDI'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sequence board fits a wide English tablet without overflow', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(800, 1280);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const GateSequenceGamePage(),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Gate Sequence'), findsOneWidget);
  });
}
