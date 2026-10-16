import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/rhythm_memory/rhythm_memory_game_page.dart';
import 'package:zeka_parkuru/games/rhythm_memory/rhythm_memory_scenario.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets(
    '320×600 rhythm controls play back and accept a recalled phrase',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 600);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const ParkurLevelSpec level = ParkurLevelSpec(
        number: 1,
        titleTr: 'Ritim 01',
        titleEn: 'Rhythm 01',
        subtitleTr: 'Kısa ritim',
        subtitleEn: 'Short rhythm',
        difficulty: 'TEMPO',
        icon: Icons.graphic_eq_rounded,
      );
      final RhythmMemoryScenario scenario =
          RhythmMemoryScenario.forCampaignLevel(1);

      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('tr'),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RhythmMemoryPlayPage(level: level, previousBestScore: 0),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('rhythm_memory_start')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('rhythm_memory_pad_grid')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('rhythm_memory_start')),
      );
      await tester.pump(const Duration(milliseconds: 260));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('rhythm_memory_start')),
        findsOneWidget,
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('rhythm_memory_start')),
      );
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.textContaining('Sıra sende'), findsOneWidget);

      for (final RhythmBeat beat in scenario.beats) {
        await tester.tap(
          find.byKey(ValueKey<String>('rhythm_memory_pad_${beat.note}')),
        );
        await tester.pump(const Duration(milliseconds: 1));
      }
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('rhythm_memory_finish')),
        findsOneWidget,
      );
    },
  );

  testWidgets('800×1280 English hub presents the master level', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1280);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: RhythmMemoryGamePage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(RhythmMemoryGamePage.totalLevels, 30);
    expect(find.text('Rhythm Memory'), findsOneWidget);
    expect(RhythmMemoryGamePage.levels.last.titleEn, 'Rhythm 20');
    expect(RhythmMemoryGamePage.levels.last.subtitleEn, contains('11 notes'));
  });
}
