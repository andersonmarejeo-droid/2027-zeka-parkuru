import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/games/silent_count/silent_count_game_page.dart';
import 'package:zeka_parkuru/games/silent_count/silent_count_scenario.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('320×600 Turkish event stream audits the generated inventory', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 600);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const ParkurLevelSpec level = ParkurLevelSpec(
      number: 1,
      titleTr: 'Sayım 01',
      titleEn: 'Count 01',
      subtitleTr: 'İki bölme',
      subtitleEn: 'Two bays',
      difficulty: 'İZLE',
      icon: Icons.inventory_2_rounded,
    );
    final SilentCountScenario scenario = SilentCountScenario.forCampaignLevel(
      1,
    );

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: SilentCountPlayPage(level: level, previousBestScore: 0),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('silent_count_start')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey<String>('silent_count_start')));
    await tester.pump();
    for (int event = 0; event < scenario.eventCount; event++) {
      expect(
        find.byKey(const ValueKey<String>('silent_count_event_card')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey<String>('silent_count_next')));
      await tester.pump();
    }

    expect(
      find.byKey(const ValueKey<String>('silent_count_audit_card')),
      findsOneWidget,
    );
    for (int category in scenario.queryOrder) {
      await tester.tap(
        find.byKey(
          ValueKey<String>(
            'silent_count_answer_${scenario.finalCounts[category]}',
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(
      find.byKey(const ValueKey<String>('silent_count_finish')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('800×1280 English level hub exposes the 20-event finale', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1280);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: SilentCountGamePage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Silent Count'), findsOneWidget);
    final Finder finale = find.textContaining('Count 20');
    await tester.scrollUntilVisible(
      finale,
      360,
      scrollable: find.byType(Scrollable).first,
    );
    expect(finale, findsOneWidget);
    expect(SilentCountGamePage.totalLevels, 20);
    expect(SilentCountGamePage.levels.last.subtitleEn, contains('20 events'));
    expect(tester.takeException(), isNull);
  });
}
