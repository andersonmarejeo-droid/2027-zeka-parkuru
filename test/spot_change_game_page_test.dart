import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/games/spot_change/spot_change_game_page.dart';
import 'package:zeka_parkuru/games/spot_change/spot_change_scenario.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('320×600 Turkish scene comparison finds the changed position', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    const ParkurLevelSpec level = ParkurLevelSpec(
      number: 1,
      titleTr: 'Sahne 01',
      titleEn: 'Scene 01',
      subtitleTr: 'Bir konum değişti',
      subtitleEn: 'One position changed',
      difficulty: 'GÖZLEM',
      icon: Icons.compare_rounded,
    );
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: SpotChangePlayPage(level: level, previousBestScore: 0),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('DEĞİŞENİ BUL'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('spot_change_grid')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    final SpotChangeScenario scene = SpotChangeScenario.forCampaignLevel(1);
    for (final int index in scene.changedIndices) {
      final Finder tile = find.byKey(
        ValueKey<String>('spot_change_cell_$index'),
      );
      expect(tester.getRect(tile).bottom, lessThanOrEqualTo(560));
      await tester.tap(tile);
      await tester.pump();
    }
    expect(find.text('SAHNE ÇÖZÜLDÜ'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('spot_change_finish')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('800×1280 English level hub reaches the expert finale', (
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
        home: SpotChangeGamePage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Spot the Change'), findsOneWidget);
    final GridView levelGrid = tester.widget<GridView>(
      find.byType(GridView).first,
    );
    expect(
      (levelGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
          .crossAxisCount,
      1,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey<String>('parkur_level_art_1')))
          .width,
      68,
    );
    final Finder finale = find.textContaining('Scene 20');
    await tester.scrollUntilVisible(
      finale,
      360,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(finale, findsOneWidget);
    expect(SpotChangeGamePage.totalLevels, 30);
    expect(tester.takeException(), isNull);
  });

  testWidgets('320×600 Turkish hub keeps compact level artwork readable', (
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
        home: SpotChangeGamePage(),
      ),
    );
    await tester.pumpAndSettle();

    final GridView levelGrid = tester.widget<GridView>(
      find.byType(GridView).first,
    );
    expect(
      (levelGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
          .crossAxisCount,
      1,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey<String>('parkur_level_art_1')))
          .width,
      60,
    );
    expect(tester.takeException(), isNull);
  });
}
