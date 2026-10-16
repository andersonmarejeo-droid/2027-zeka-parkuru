import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/sentence_builder/sentence_builder_game_page.dart';
import 'package:zeka_parkuru/games/sentence_builder/sentence_builder_scenario.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('320×600 Turkish board builds and checks clause order', (
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
      titleTr: 'Cümle Atölyesi 01',
      titleEn: 'Sentence Studio 01',
      subtitleTr: 'Anlamlı cümle bloklarını sırala',
      subtitleEn: 'Order meaningful sentence blocks',
      difficulty: 'USTALAŞMA',
      icon: Icons.format_align_left_rounded,
    );

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: SentenceBuilderPlayPage(level: firstLevel, previousBestScore: 0),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cümle Kur'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final SentenceBoardCard card = SentenceBuilderScenario.forCampaignLevel(1)
        .cards
        .first;
    for (final String part in card.sentence.partsTr) {
      final int index = card.scrambledTr.indexOf(part);
      final Finder block = find.byKey(
        ValueKey<String>('sentence_builder_part_$index'),
      );
      await tester.ensureVisible(block);
      await tester.tap(block);
      await tester.pump();
      expect(tester.takeException(), isNull);
    }

    final Finder submit = find.byKey(
      const ValueKey<String>('sentence_builder_submit'),
    );
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('sentence_builder_note')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('800×1280 English hub exposes all twenty stages', (
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
        home: SentenceBuilderGamePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sentence Builder'), findsOneWidget);
    final Finder finalLevel = find.textContaining('Sentence Studio 20');
    await tester.scrollUntilVisible(
      finalLevel,
      360,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(finalLevel, findsOneWidget);
    expect(SentenceBuilderGamePage.totalCases, 30);
    expect(tester.takeException(), isNull);
  });
}
