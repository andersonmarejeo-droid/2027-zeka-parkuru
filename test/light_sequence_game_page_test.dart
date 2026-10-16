import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/games/light_sequence/light_sequence_game_page.dart';
import 'package:zeka_parkuru/games/light_sequence/light_sequence_scenario.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('320×600 Turkish spatial pattern can be replayed and solved', (
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
      titleTr: 'Sinyal 01',
      titleEn: 'Signal 01',
      subtitleTr: 'Konum sırası',
      subtitleEn: 'Position order',
      difficulty: 'ISINMA',
      icon: Icons.light_mode_rounded,
    );
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: LightSequencePlayPage(level: level, previousBestScore: 0),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Işık Dizisi'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('light_sequence_grid')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(
      find.byKey(const ValueKey<String>('light_sequence_start')),
    );
    await tester.pump();
    for (int pulse = 0; pulse < 10; pulse++) {
      await tester.pump(const Duration(milliseconds: 700));
    }
    await tester.pumpAndSettle();

    final LightSequenceScenario board = LightSequenceScenario.forCampaignLevel(
      1,
    );
    for (final int cell in board.answer) {
      final Finder tile = find.byKey(
        ValueKey<String>('light_sequence_cell_$cell'),
      );
      await tester.ensureVisible(tile);
      await tester.tap(tile);
      await tester.pump();
    }
    expect(
      find.byKey(const ValueKey<String>('light_sequence_finish')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('800×1280 English hub exposes all 20 campaign levels', (
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
        home: LightSequenceGamePage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Light Sequence'), findsOneWidget);
    final Finder finale = find.textContaining('Signal 20');
    await tester.scrollUntilVisible(
      finale,
      360,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(finale, findsOneWidget);
    expect(LightSequenceGamePage.totalLevels, 20);
    expect(tester.takeException(), isNull);
  });
}
