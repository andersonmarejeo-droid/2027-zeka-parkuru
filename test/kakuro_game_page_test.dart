import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/kakuro/kakuro_game_page.dart';
import 'package:zeka_parkuru/games/kakuro/kakuro_puzzle.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

void main() {
  setUpAll(installTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('320×600 Kakuro board accepts a keypad entry without overflow', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: KakuroPlayPage(
          level: ParkurLevelSpec(
            number: 1,
            titleTr: 'Kakuro 01',
            titleEn: 'Kakuro 01',
            subtitleTr: 'Kesişen toplamları çöz',
            subtitleEn: 'Solve crossing sums',
            difficulty: 'USTALAŞMA',
            icon: Icons.grid_on_rounded,
          ),
          previousBestScore: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('KAKURO IZGARASI'), findsOneWidget);

    final KakuroPuzzle puzzle = KakuroPuzzle.forLevel(1);
    final int cellIndex = puzzle.cells.indexWhere(
      (KakuroCell cell) => cell.isPlayable,
    );
    final int digit = puzzle.solution[cellIndex];
    await tester.tap(find.byKey(ValueKey<String>('kakuro_cell_$cellIndex')));
    final Finder digitKey = find.byKey(ValueKey<String>('kakuro_digit_$digit'));
    await tester.scrollUntilVisible(
      digitKey,
      140,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(digitKey);
    await tester.pumpAndSettle();
    expect(find.text('$digit'), findsWidgets);
    expect(tester.takeException(), isNull);

    final Finder check = find.byKey(const ValueKey<String>('kakuro_check'));
    await tester.scrollUntilVisible(
      check,
      140,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(check);
    await tester.pumpAndSettle();
    expect(find.textContaining('tüm beyaz hücreleri doldur'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('English hub presents its 20-stage campaign on tablet', (
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
        home: KakuroGamePage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Kakuro Grid'), findsOneWidget);
    expect(find.textContaining('Kakuro 01'), findsOneWidget);
    expect(KakuroGamePage.totalCases, 30);
    expect(tester.takeException(), isNull);
  });
}
