import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/proverb_finish/proverb_finish_game_page.dart';
import 'package:zeka_parkuru/games/proverb_finish/proverb_finish_scenario.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('320×600 Turkish round submits an answer and reveals usage', (
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
      titleTr: 'Söz Ustası 01',
      titleEn: 'Proverb Craft 01',
      subtitleTr: 'En bilinen sözleri tamamla',
      subtitleEn: 'Complete familiar sayings',
      difficulty: 'USTALAŞMA',
      icon: Icons.menu_book_rounded,
    );

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: ProverbFinishPlayPage(level: firstLevel, previousBestScore: 0),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Atasözü Tamamla'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final ProverbFinishScenario scenario =
        ProverbFinishScenario.forCampaignLevel(1);
    final int correctIndex = scenario.answerOrder.indexOf(
      scenario.cards.first.ending,
    );
    final Finder answer = find.byKey(
      ValueKey<String>('proverb_finish_answer_$correctIndex'),
    );
    await tester.ensureVisible(answer);
    await tester.tap(answer);
    await tester.pump();

    final Finder submit = find.byKey(
      const ValueKey<String>('proverb_finish_submit'),
    );
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('proverb_finish_usage_note')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('800×1280 English hub exposes its full 20-stage campaign', (
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
        home: ProverbFinishGamePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Finish the Proverb'), findsOneWidget);
    final Finder finalLevel = find.textContaining('Proverb Craft 20');
    await tester.scrollUntilVisible(
      finalLevel,
      360,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(finalLevel, findsOneWidget);
    expect(ProverbFinishGamePage.totalCases, 30);
    expect(tester.takeException(), isNull);
  });
}
