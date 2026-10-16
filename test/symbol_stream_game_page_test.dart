import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/games/symbol_stream/symbol_stream_game_page.dart';
import 'package:zeka_parkuru/games/symbol_stream/symbol_stream_scenario.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

Future<void> _waitForDecision(WidgetTester tester) async {
  final Finder match = find.byKey(
    const ValueKey<String>('symbol_stream_match'),
  );
  final Finder noMatch = find.byKey(
    const ValueKey<String>('symbol_stream_no_match'),
  );
  for (int attempt = 0; attempt < 40; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (tester.any(match) && tester.any(noMatch)) return;
  }
  fail('The next N-back response window did not appear.');
}

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets(
    '320×600 Turkish N-back stream accepts its generated answer key',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 600);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const ParkurLevelSpec level = ParkurLevelSpec(
        number: 1,
        titleTr: 'Akış 01',
        titleEn: 'Stream 01',
        subtitleTr: 'Bir geri',
        subtitleEn: '1-back',
        difficulty: 'AKIŞ',
        icon: Icons.view_stream_rounded,
      );
      final SymbolStreamScenario scenario =
          SymbolStreamScenario.forCampaignLevel(1);
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('tr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: SymbolStreamPlayPage(level: level, previousBestScore: 0),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('symbol_stream_start')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('symbol_stream_start')),
      );
      for (final SymbolStreamItem item in scenario.items.where(
        (SymbolStreamItem item) => item.hasDecision,
      )) {
        await _waitForDecision(tester);
        await tester.tap(
          find.byKey(
            ValueKey<String>(
              item.matches! ? 'symbol_stream_match' : 'symbol_stream_no_match',
            ),
          ),
        );
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        find.byKey(const ValueKey<String>('symbol_stream_finish')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('800×1280 English hub reaches the rule-shift finale', (
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
        home: SymbolStreamGamePage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Symbol Stream'), findsOneWidget);
    final Finder finale = find.textContaining('Stream 20');
    await tester.scrollUntilVisible(
      finale,
      360,
      scrollable: find.byType(Scrollable).first,
    );
    expect(finale, findsOneWidget);
    expect(SymbolStreamGamePage.totalLevels, 20);
    expect(
      SymbolStreamGamePage.levels.last.subtitleEn,
      contains('two rule shifts'),
    );
    expect(tester.takeException(), isNull);
  });
}
