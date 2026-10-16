import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/near_meaning/near_meaning_game_page.dart';
import 'package:zeka_parkuru/games/near_meaning/near_meaning_scenario.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('320×600 Turkish context selects and explains the nuance', (
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
      titleTr: 'Nüans 01',
      titleEn: 'Nuance 01',
      subtitleTr: 'Sözcüğü bağlamda çöz',
      subtitleEn: 'Read the word in context',
      difficulty: 'USTALAŞMA',
      icon: Icons.manage_search_rounded,
    );

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: NearMeaningPlayPage(level: firstLevel, previousBestScore: 0),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Yakın Anlam'), findsOneWidget);
    expect(tester.takeException(), isNull);
    final NearMeaningScenario board = NearMeaningScenario.forCampaignLevel(1);
    final NearMeaningBoardCard card = board.cards.first;
    final Finder correctOption = find.byKey(
      ValueKey<String>('near_meaning_option_${card.correctOptionIndex}'),
    );
    await tester.ensureVisible(correctOption);
    await tester.tap(correctOption);
    await tester.pump();

    final Finder submit = find.byKey(
      const ValueKey<String>('near_meaning_submit'),
    );
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('near_meaning_explanation')),
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
        home: NearMeaningGamePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Near Meaning'), findsOneWidget);
    final Finder finalLevel = find.textContaining('Nuance 20');
    await tester.scrollUntilVisible(
      finalLevel,
      360,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(finalLevel, findsOneWidget);
    expect(NearMeaningGamePage.totalCases, 30);
    expect(tester.takeException(), isNull);
  });
}
