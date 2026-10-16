import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/language_detective/language_detective_game_page.dart';
import 'package:zeka_parkuru/games/language_detective/language_detective_scenario.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('320×600 Turkish evidence file can be solved', (
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
      titleTr: 'Dosya 01',
      titleEn: 'Case 01',
      subtitleTr: 'Açık kanıtı ayıkla',
      subtitleEn: 'Read the evidence',
      difficulty: 'USTALAŞMA',
      icon: Icons.manage_search_rounded,
    );
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: LanguageDetectivePlayPage(
          level: firstLevel,
          previousBestScore: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dil Dedektifi'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('language_detective_evidence')),
      findsOneWidget,
    );
    final Finder hintButton = find.byKey(
      const ValueKey<String>('language_detective_hint'),
    );
    await tester.ensureVisible(hintButton);
    final Text hintLabel = tester.widget<Text>(
      find.descendant(of: hintButton, matching: find.byType(Text)),
    );
    expect(hintLabel.data, 'DELİL İPUCU');
    expect(hintLabel.maxLines, 1);
    expect(hintLabel.softWrap, isFalse);
    expect(hintLabel.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);

    final DetectiveBoardCase firstCase =
        LanguageDetectiveScenario.forCampaignLevel(1).cases.first;
    final Finder correctOption = find.byKey(
      ValueKey<String>(
        'language_detective_option_${firstCase.correctOptionIndex}',
      ),
    );
    await tester.ensureVisible(correctOption);
    await tester.tap(correctOption);
    await tester.pump();

    final Finder submit = find.byKey(
      const ValueKey<String>('language_detective_submit'),
    );
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('language_detective_explanation')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('800×1280 English hub reaches the expert finale', (
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
        home: LanguageDetectiveGamePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Language Detective'), findsOneWidget);
    final Finder finalLevel = find.textContaining('Case 20');
    await tester.scrollUntilVisible(
      finalLevel,
      360,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(finalLevel, findsOneWidget);
    expect(LanguageDetectiveGamePage.totalCases, 30);
    expect(tester.takeException(), isNull);
  });
}
