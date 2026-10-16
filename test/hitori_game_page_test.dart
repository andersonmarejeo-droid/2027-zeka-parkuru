import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/hitori/hitori_game_page.dart';
import 'package:zeka_parkuru/games/hitori/hitori_puzzle.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

ParkurLevelSpec _level(int number) => ParkurLevelSpec(
  number: number,
  titleTr: 'Sayı Eleme $number',
  titleEn: 'Number Shade $number',
  subtitleTr: 'Tekrarları ele',
  subtitleEn: 'Shade duplicates',
  difficulty: 'USTALAŞMA',
  icon: Icons.grid_view_rounded,
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
      home: const HitoriGamePage(),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(find.text('Hitori'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shading is reversible and a verified solution completes', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final HitoriPuzzle puzzle = HitoriPuzzle.forLevel(1);
    await _mount(
      tester,
      home: HitoriPlayPage(level: _level(1), previousBestScore: 0),
      size: const Size(320, 760),
      locale: const Locale('tr'),
    );

    final Finder firstCell = find.byKey(
      const ValueKey<String>('hitori_cell_0'),
    );
    await tester.ensureVisible(firstCell);
    await tester.tap(firstCell);
    await tester.pump();
    expect(find.text('Hücre gölgelendi.'), findsOneWidget);

    final Finder undo = find.byKey(const ValueKey<String>('hitori_undo'));
    await tester.ensureVisible(undo);
    await tester.tap(undo);
    await tester.pump();
    expect(find.text('Son gölgeleme geri alındı.'), findsOneWidget);

    for (int cell = 0; cell < puzzle.solution.length; cell++) {
      if (!puzzle.solution[cell]) continue;
      final Finder target = find.byKey(ValueKey<String>('hitori_cell_$cell'));
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pump();
    }
    final Finder check = find.byKey(const ValueKey<String>('hitori_check'));
    await tester.ensureVisible(check);
    await tester.tap(check);
    await tester.pump(const Duration(milliseconds: 260));
    await tester.pumpAndSettle();
    expect(find.text('HITORI TAMAMLANDI'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('adjacent shades are flagged and can be undone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: HitoriPlayPage(level: _level(1), previousBestScore: 0),
      size: const Size(320, 700),
      locale: const Locale('tr'),
    );
    for (final int cell in <int>[0, 1]) {
      final Finder target = find.byKey(ValueKey<String>('hitori_cell_$cell'));
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pump();
    }
    final Finder check = find.byKey(const ValueKey<String>('hitori_check'));
    await tester.ensureVisible(check);
    await tester.tap(check);
    await tester.pump();
    expect(
      find.text('Vurgulanan hücreler Hitori kurallarından birini bozuyor.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('English hub fits a tablet viewport', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const HitoriGamePage(),
      size: const Size(800, 1280),
      locale: const Locale('en'),
    );
    expect(find.text('Hitori'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('8x8 expert board scrolls on a compact phone without overflow', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: HitoriPlayPage(level: _level(20), previousBestScore: 0),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );

    final Finder board = find.byKey(
      const ValueKey<String>('hitori_board_horizontal_scroll'),
    );
    expect(
      find.byKey(const ValueKey<String>('hitori_board_frame')),
      findsOneWidget,
    );
    expect(board, findsOneWidget);
    await tester.drag(board, const Offset(-110, 0));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('hitori_cell_63')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
