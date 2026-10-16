import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/games/warehouse_master/warehouse_master_game_page.dart';
import 'package:zeka_parkuru/games/warehouse_master/warehouse_puzzle.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

ParkurLevelSpec _level(int number) {
  final int stage = ((number - 1) % 10) + 1;
  return ParkurLevelSpec(
    number: number,
    titleTr: 'Depo $number',
    titleEn: 'Warehouse $number',
    subtitleTr: 'Paket 1 · Aşama $stage / 10',
    subtitleEn: 'Chapter 1 · Stage $stage / 10',
    difficulty: stage >= 9 ? 'UZMAN' : 'PLANLAYICI',
    icon: Icons.inventory_2_outlined,
  );
}

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
  await tester.pump(const Duration(milliseconds: 120));
}

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('warehouse level hub opens on a compact phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const WarehouseMasterGamePage(),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(find.byType(Scaffold), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone controls can clear the verified shortest push route', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: WarehouseMasterPlayPage(level: _level(1), previousBestScore: 0),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(
      find.byKey(const ValueKey<String>('warehouse_board')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    final WarehousePuzzle puzzle = WarehousePuzzle.forLevel(1);
    for (final WarehouseAction action in puzzle.solution) {
      final String key = switch (action.direction) {
        WarehouseDirection.up => 'warehouse_up',
        WarehouseDirection.right => 'warehouse_right',
        WarehouseDirection.down => 'warehouse_down',
        WarehouseDirection.left => 'warehouse_left',
      };
      final Finder control = find.byKey(ValueKey<String>(key));
      await tester.ensureVisible(control);
      await tester.tap(control);
      await tester.pump(const Duration(milliseconds: 25));
    }
    await tester.pump(const Duration(milliseconds: 220));
    expect(find.text('DEPO PLANI TAMAMLANDI'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('English tablet warehouse hub keeps its layout stable', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const WarehouseMasterGamePage(),
      size: const Size(800, 1280),
      locale: const Locale('en'),
    );
    expect(find.text('Warehouse Master'), findsOneWidget);
    expect(WarehouseMasterGamePage.totalCases, 20);
    expect(
      WarehouseMasterGamePage.totalCases,
      WarehousePuzzle.maximumUniqueCases,
    );
    expect(tester.takeException(), isNull);
  });
}
