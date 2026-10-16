import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/games/story_order/story_order_game_page.dart';
import 'package:zeka_parkuru/games/story_order/story_order_scenario.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('320×600 Turkish story file can be solved without overflow', (
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
      titleTr: 'Dosya 01',
      titleEn: 'Story 01',
      subtitleTr: 'Olay sırası',
      subtitleEn: 'Story order',
      difficulty: 'USTALAŞMA',
      icon: Icons.timeline_rounded,
    );
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: StoryOrderPlayPage(level: level, previousBestScore: 0),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hikâye Sırası'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('story_order_scroll')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    final StoryOrderScenario board = StoryOrderScenario.forCampaignLevel(1);
    for (final String id in board.expectedIds) {
      final Finder card = find.byKey(ValueKey<String>('story_order_card_$id'));
      await tester.ensureVisible(card);
      await tester.tap(card);
      await tester.pump();
    }
    final Finder submit = find.byKey(
      const ValueKey<String>('story_order_submit'),
    );
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('story_order_explanation')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('story_order_continue')),
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
        home: StoryOrderGamePage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Story Order'), findsOneWidget);
    final Finder finale = find.textContaining('Story 20');
    await tester.scrollUntilVisible(
      finale,
      360,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(finale, findsOneWidget);
    expect(StoryOrderGamePage.totalCases, 30);
    expect(tester.takeException(), isNull);
  });
}
