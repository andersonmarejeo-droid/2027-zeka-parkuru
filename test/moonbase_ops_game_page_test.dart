import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/moonbase_ops/moonbase_ops_game_page.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

const ParkurLevelSpec _level = ParkurLevelSpec(
  number: 10,
  titleTr: 'Üs 10',
  titleEn: 'Outpost 10',
  subtitleTr: 'Kaynak ağı kur.',
  subtitleEn: 'Build the life support network.',
  difficulty: 'UZMAN',
  icon: Icons.rocket_launch_rounded,
);

Future<void> _mount(
  WidgetTester tester, {
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
      home: MoonbaseOpsPlayPage(level: _level, previousBestScore: 0),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('resource HUD, modular grid and edit controls fit small phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(
      find.byKey(const ValueKey<String>('moonbase_ops_hud')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('moonbase_ops_brief')),
      findsOneWidget,
    );
    final Finder grid = find.byKey(const ValueKey<String>('moonbase_ops_grid'));
    expect(grid, findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('moonbase_module_solarArray')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('moonbase_ops_launch')),
      findsOneWidget,
    );
    expect(tester.getSize(grid).width, greaterThan(220));

    final Offset topLeft = tester.getTopLeft(grid);
    final Size gridSize = tester.getSize(grid);
    await tester.tapAt(
      topLeft + Offset(gridSize.width * .63, gridSize.height * .5),
    );
    await tester.pump();
    expect(find.textContaining('kuruldu'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('moonbase_ops_undo')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('moonbase_ops_redo')));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('English tablet displays readable mission and module palette', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      size: const Size(800, 1280),
      locale: const Locale('en'),
    );
    expect(find.text('OUTPOST · 10'), findsOneWidget);
    expect(find.textContaining('SOLAR ECLIPSE'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('moonbase_module_greenhouse')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
