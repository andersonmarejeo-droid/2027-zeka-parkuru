import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/dual_task/dual_task_game_page.dart';
import 'package:zeka_parkuru/games/dual_task/dual_task_scenario.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets(
    '320×600 Turkish stream scores visual and memory tasks separately',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 600);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const ParkurLevelSpec level = ParkurLevelSpec(
        number: 1,
        titleTr: 'İkili Görev 01',
        titleEn: 'Dual Task 01',
        subtitleTr: 'Şekil + iki sayı',
        subtitleEn: 'Shape + two digits',
        difficulty: 'ÇİFT ODAK',
        icon: Icons.dashboard_customize_rounded,
      );
      final DualTaskScenario scenario = DualTaskScenario.forCampaignLevel(1);

      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('tr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: DualTaskPlayPage(level: level, previousBestScore: 0),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('dual_task_start')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey<String>('dual_task_start')));
      await tester.pump();
      for (final DualTaskTrial trial in scenario.trials) {
        await tester.tap(
          find.byKey(
            ValueKey<String>(
              trial.isTarget ? 'dual_task_match' : 'dual_task_no_match',
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 270));
      }
      expect(
        find.byKey(const ValueKey<String>('dual_task_recall_panel')),
        findsOneWidget,
      );
      for (final int digit in scenario.recallAnswer) {
        await tester.tap(
          find.byKey(ValueKey<String>('dual_task_digit_$digit')),
        );
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.byKey(const ValueKey<String>('dual_task_finish')),
        findsOneWidget,
      );
      expect(find.text('8/8'), findsOneWidget);
      expect(find.text('2/2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('800×1280 English hub exposes the six-digit reverse finale', (
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
        home: DualTaskGamePage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Dual Task'), findsOneWidget);
    final Finder finale = find.textContaining('Dual Task 20');
    await tester.scrollUntilVisible(
      finale,
      360,
      scrollable: find.byType(Scrollable).first,
    );
    expect(finale, findsOneWidget);
    expect(DualTaskGamePage.totalLevels, 20);
    expect(
      DualTaskGamePage.levels.last.subtitleEn,
      contains('six reverse digits'),
    );
    expect(tester.takeException(), isNull);
  });
}
