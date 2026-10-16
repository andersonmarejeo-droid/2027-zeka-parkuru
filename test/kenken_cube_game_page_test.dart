import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/kenken_cube/kenken_cube_game_page.dart';
import 'package:zeka_parkuru/games/kenken_cube/kenken_cube_puzzle.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

void main() {
  setUpAll(installTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('compact phone can solve a standalone KenKen board', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: KenKenCubePlayPage(level: _level(1), previousBestScore: 0),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);

    final KenKenPuzzle puzzle = KenKenPuzzle.forLevel(1);
    for (int index = 0; index < puzzle.cellCount; index++) {
      final Finder cell = find.byKey(ValueKey<String>('kenken_cell_$index'));
      await tester.scrollUntilVisible(
        cell,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(cell);
      final Finder digit = find.byKey(
        ValueKey<String>('kenken_num_${puzzle.solution[index]}'),
      );
      await tester.scrollUntilVisible(
        digit,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(digit);
      await tester.pump();
      expect(tester.takeException(), isNull);
    }

    final Finder check = find.byKey(const ValueKey<String>('kenken_check'));
    await tester.scrollUntilVisible(
      check,
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(check);
    await tester.pumpAndSettle();
    expect(find.text('KENKEN TAMAMLANDI'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('English tablet exposes an independent KenKen parkur', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(800, 1280);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: KenKenCubeGamePage(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('KenKen Cube'), findsOneWidget);
    expect(find.textContaining('KenKen 01'), findsOneWidget);
    expect(KenKenCubeGamePage.totalCases, 30);
    expect(KenKenPuzzle.maximumUniqueCases, 300);
    expect(KenKenCubeGamePage.totalCases, 30);
    expect(tester.takeException(), isNull);
  });
}

ParkurLevelSpec _level(int number) => ParkurLevelSpec(
  number: number,
  titleTr: 'KenKen ${number.toString().padLeft(3, '0')}',
  titleEn: 'KenKen ${number.toString().padLeft(3, '0')}',
  subtitleTr: 'İşlem kafesleri',
  subtitleEn: 'Arithmetic cages',
  difficulty: 'BAŞLANGIÇ',
  icon: Icons.functions_rounded,
);
