import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/games/skyscrapers/skyscrapers_game_page.dart';
import 'package:zeka_parkuru/games/skyscrapers/skyscrapers_puzzle.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

ParkurLevelSpec _level(int number) => ParkurLevelSpec(
  number: number,
  titleTr: 'Gökdelen $number',
  titleEn: 'Skyline $number',
  subtitleTr: 'Görüş çizgilerini çöz',
  subtitleEn: 'Solve each sightline',
  difficulty: 'USTALAŞMA',
  icon: Icons.location_city_outlined,
);

Future<void> _mount(
  WidgetTester tester, {
  required Widget home,
  required Size size,
  required Locale locale,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData.light(useMaterial3: true),
      home: home,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 180));
}

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('20-level hub fits a compact Turkish phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const SkyscrapersGamePage(),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(find.text('Gökdelenler'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('certified skyline accepts heights and completes the campaign', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final SkyscrapersPuzzle puzzle = SkyscrapersPuzzle.forLevel(1);
    await _mount(
      tester,
      home: SkyscrapersPlayPage(level: _level(1), previousBestScore: 0),
      size: const Size(320, 700),
      locale: const Locale('tr'),
    );

    for (int cell = 0; cell < puzzle.solution.length; cell++) {
      final Finder target = find.byKey(
        ValueKey<String>('skyscrapers_cell_$cell'),
      );
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pump();
      final Finder height = find.byKey(
        ValueKey<String>('skyscrapers_height_${puzzle.solution[cell]}'),
      );
      await tester.ensureVisible(height);
      await tester.tap(height);
      await tester.pump();
    }

    final Finder check = find.byKey(
      const ValueKey<String>('skyscrapers_check'),
    );
    await tester.ensureVisible(check);
    await tester.tap(check);
    await tester.pump(const Duration(milliseconds: 260));
    await tester.pumpAndSettle();
    expect(find.text('SİLÜET TAMAMLANDI'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('duplicate heights highlight and undo cleanly on a small phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final SkyscrapersPuzzle puzzle = SkyscrapersPuzzle.forLevel(1);
    await _mount(
      tester,
      home: SkyscrapersPlayPage(level: _level(1), previousBestScore: 0),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );

    Future<void> place(int cell, int height) async {
      final Finder target = find.byKey(
        ValueKey<String>('skyscrapers_cell_$cell'),
      );
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pump();
      final Finder button = find.byKey(
        ValueKey<String>('skyscrapers_height_$height'),
      );
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
    }

    await place(0, puzzle.solution[0]);
    await place(1, puzzle.solution[0]);
    expect(
      find.text('Bu yükseklik aynı satır veya sütunda zaten var.'),
      findsOneWidget,
    );
    final Finder undo = find.byKey(const ValueKey<String>('skyscrapers_undo'));
    await tester.ensureVisible(undo);
    await tester.tap(undo);
    await tester.pump();
    expect(find.text('Son işlem geri alındı.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('English level hub fits a tablet viewport', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const SkyscrapersGamePage(),
      size: const Size(800, 1280),
      locale: const Locale('en'),
    );
    expect(find.text('Skyscrapers'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
