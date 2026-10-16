import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/bottle_target/bottle_target_game_page.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

ParkurLevelSpec _level(int number) => ParkurLevelSpec(
  number: number,
  titleTr: 'Atış Poligonu $number',
  titleEn: 'Range $number',
  subtitleTr: 'Şişeleri hedefle',
  subtitleEn: 'Aim at the bottles',
  difficulty: 'USTALAŞMA',
  icon: Icons.sports_baseball_rounded,
);

Future<void> _mount(
  WidgetTester tester, {
  required Widget home,
  required Size size,
  required Locale locale,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData.light(useMaterial3: true),
      home: home,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 180));
}

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('10-level range hub fits a compact Turkish phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const BottleTargetGamePage(),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(find.text('Şişe Kırmaca'), findsOneWidget);
    expect(find.text('1. Atış Poligonu 01'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('aim controls, pause and target-hit flow are playable', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: BottleTargetPlayPage(level: _level(1), previousBestScore: 0),
      size: const Size(360, 720),
      locale: const Locale('tr'),
    );

    expect(
      find.byKey(const ValueKey<String>('bottle_range_scene')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('bottle_angle_slider')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('bottle_power_slider')),
      findsOneWidget,
    );
    final Finder pause = find.byKey(const ValueKey<String>('bottle_pause'));
    await tester.tap(pause);
    await tester.pump();
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    await tester.tap(pause);
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey<String>('bottle_fire')));
    for (int frame = 0; frame < 45; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.text('ATIŞ POLİGONU TAMAMLANDI'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('English range controls fit a tablet', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: BottleTargetPlayPage(level: _level(10), previousBestScore: 0),
      size: const Size(800, 1280),
      locale: const Locale('en'),
    );
    expect(
      find.byKey(const ValueKey<String>('bottle_range_hud')),
      findsOneWidget,
    );
    expect(find.text('0'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
