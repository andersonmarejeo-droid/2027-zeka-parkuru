import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/attention_tunnel/attention_tunnel_game_page.dart';
import 'package:zeka_parkuru/games/attention_tunnel/attention_tunnel_scenario.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('320×600 card shuffle reveals the tracked target', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 600);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const ParkurLevelSpec level = ParkurLevelSpec(
      number: 1,
      titleTr: 'Tünel 01',
      titleEn: 'Tunnel 01',
      subtitleTr: 'Üç hat',
      subtitleEn: 'Three rails',
      difficulty: 'ODAK',
      icon: Icons.blur_on_rounded,
    );
    final AttentionTunnelScenario scenario =
        AttentionTunnelScenario.forCampaignLevel(1);

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: AttentionTunnelPlayPage(level: level, previousBestScore: 0),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('attention_tunnel_start')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('attention_tunnel_target_badge')),
      findsOneWidget,
    );
    for (int slot = 0; slot < 3; slot++) {
      expect(
        find.byKey(ValueKey<String>('attention_tunnel_card_slot_$slot')),
        findsOneWidget,
      );
    }
    final Object? initialLayoutException = tester.takeException();
    expect(initialLayoutException, isNull, reason: '$initialLayoutException');

    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('attention_tunnel_start')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('attention_tunnel_start')),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey<String>('face_down')), findsNWidgets(3));
    for (int frame = 0; frame < 180; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (tester.any(
        find.byKey(const ValueKey<String>('attention_tunnel_hint')),
      )) {
        break;
      }
    }
    final Finder targetSlot = find.byKey(
      ValueKey<String>(
        'attention_tunnel_card_slot_${scenario.finalTargetCardSlot}',
      ),
    );
    expect(targetSlot, findsOneWidget);
    await tester.ensureVisible(targetSlot);
    await tester.tap(targetSlot);
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('attention_tunnel_finish')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('800×1280 English hub reaches the nine-card finale', (
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
        home: AttentionTunnelGamePage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Attention Tunnel'), findsOneWidget);
    final Finder finale = find.textContaining('Tunnel 20');
    await tester.scrollUntilVisible(
      finale,
      360,
      scrollable: find.byType(Scrollable).first,
    );
    expect(finale, findsOneWidget);
    expect(AttentionTunnelGamePage.totalLevels, 30);
    expect(
      AttentionTunnelGamePage.levels.last.subtitleEn,
      contains('Nine cards'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('320×600 finale preview lays out all nine cards', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 600);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const ParkurLevelSpec level = ParkurLevelSpec(
      number: 20,
      titleTr: 'Tünel 20',
      titleEn: 'Tunnel 20',
      subtitleTr: 'Dokuz kart',
      subtitleEn: 'Nine cards',
      difficulty: 'USTA',
      icon: Icons.blur_on_rounded,
    );
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: AttentionTunnelPlayPage(level: level, previousBestScore: 0),
      ),
    );
    await tester.pumpAndSettle();
    for (int slot = 0; slot < 9; slot++) {
      expect(
        find.byKey(ValueKey<String>('attention_tunnel_card_slot_$slot')),
        findsOneWidget,
      );
    }
    expect(
      find.byKey(const ValueKey<String>('attention_tunnel_target_badge')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
