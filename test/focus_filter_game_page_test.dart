import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/focus_filter/focus_filter_game_page.dart';
import 'package:zeka_parkuru/games/focus_filter/focus_filter_scenario.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('320×600 Turkish signal stream flows with one select action', (
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
      titleTr: 'Odak 01',
      titleEn: 'Focus 01',
      subtitleTr: 'Tek görsel özelliğini izle',
      subtitleEn: 'Track one feature',
      difficulty: 'SEÇİCİLİK',
      icon: Icons.filter_center_focus_rounded,
    );
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: FocusFilterPlayPage(level: level, previousBestScore: 0),
      ),
    );
    // The preparation countdown intentionally keeps scheduling one UI update
    // per second, so settle the entry transition without advancing all ten
    // seconds at once.
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('ODAK FİLTRESİ'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final FocusFilterScenario scenario = FocusFilterScenario.forCampaignLevel(
      1,
    );
    final Finder previewCountdown = find.byKey(
      const ValueKey<String>('focus_filter_rule_preview_countdown'),
    );
    expect(find.text('10 sn'), findsOneWidget);
    expect(find.text('KURAL HAZIRLIĞI'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('focus_filter_signal')),
      findsOneWidget,
      reason: 'the signal itself is the answer control after the rule preview',
    );
    await tester.pump(const Duration(seconds: 9));
    expect(find.text('1 sn'), findsOneWidget);
    expect(find.text('KURAL HAZIRLIĞI'), findsOneWidget);
    expect(find.text('1 / ${scenario.stimuli.length}'), findsNothing);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 250));
    expect(previewCountdown, findsNothing);
    expect(find.text('1 / ${scenario.stimuli.length}'), findsOneWidget);

    // The answer action is the signal itself; there is no separate select
    // button in the shape-tap interaction.
    expect(find.byKey(const ValueKey<String>('focus_filter_go')), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('focus_filter_no_go')),
      findsNothing,
    );

    for (final FocusStimulus stimulus in scenario.stimuli) {
      // AnimatedSwitcher can retain the outgoing signal for one frame; the
      // last matching node is the currently visible signal.
      final Finder answer = find
          .byKey(const ValueKey<String>('focus_filter_signal'))
          .last;
      expect(
        tester.getRect(answer).bottom,
        lessThanOrEqualTo(580),
        reason: 'the select control must stay visible without scrolling',
      );
      if (stimulus.isTarget) {
        await tester.tap(answer);
        await tester.pump();
      } else {
        // Non-target signals should advance by themselves without a tap.
        await tester.pump(const Duration(seconds: 2));
      }
      expect(
        tester.takeException(),
        isNull,
        reason: 'signal ${stimulus.index} including completion',
      );
    }
    expect(
      find.byKey(const ValueKey<String>('focus_filter_finish')),
      findsOneWidget,
    );
    expect(find.text('FİLTRE TAMAMLANDI'), findsOneWidget);
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
        home: FocusFilterGamePage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Focus Filter'), findsOneWidget);
    final Finder finale = find.textContaining('Focus 20');
    await tester.scrollUntilVisible(
      finale,
      360,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(finale, findsOneWidget);
    expect(FocusFilterGamePage.totalLevels, 30);
    expect(tester.takeException(), isNull);
  });
}
