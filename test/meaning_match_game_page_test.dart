import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/meaning_match/meaning_match_game_page.dart';
import 'package:zeka_parkuru/games/meaning_match/meaning_match_scenario.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('320×600 Turkish board selects and locks a valid group', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;

    const ParkurLevelSpec firstLevel = ParkurLevelSpec(
      number: 1,
      titleTr: 'Anlam Kümesi 01',
      titleEn: 'Meaning Set 01',
      subtitleTr: 'Açık kavram gruplarını bul',
      subtitleEn: 'Find the clear concept groups',
      difficulty: 'USTALAŞMA',
      icon: Icons.hub_rounded,
    );

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: MeaningMatchPlayPage(level: firstLevel, previousBestScore: 0),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Anlam Eşleştir'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final MeaningMatchScenario scenario = MeaningMatchScenario.forCampaignLevel(
      1,
    );
    final MeaningCategory category = scenario.categories.first;
    final List<MeaningTile> group = scenario.tiles
        .where((MeaningTile tile) => tile.categoryId == category.id)
        .toList(growable: false);
    expect(group, hasLength(scenario.wordsPerCategory));

    for (final MeaningTile tile in group) {
      await tester.tap(find.text(tile.word));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }

    await tester.tap(find.text('KÜMEYİ KİLİTLE'));
    await tester.pumpAndSettle();

    expect(
      find.text('${category.title(false)} · ${category.clue(false)}'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('800×1280 English hub exposes the 20-stage campaign', (
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
        home: MeaningMatchGamePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Meaning Match'), findsOneWidget);
    final Finder finalLevel = find.textContaining('Meaning Set 20');
    await tester.scrollUntilVisible(
      finalLevel,
      360,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(finalLevel, findsOneWidget);
    expect(MeaningMatchGamePage.totalCases, 30);
    expect(tester.takeException(), isNull);
  });
}
