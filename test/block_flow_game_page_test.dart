import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/block_flow/block_flow_game_page.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

ParkurLevelSpec _level(int number) => ParkurLevelSpec(
  number: number,
  titleTr: 'Akış Koridoru ${number.toString().padLeft(2, '0')}',
  titleEn: 'Flow Corridor ${number.toString().padLeft(2, '0')}',
  subtitleTr: 'Şeritleri ve enerjiyi yönet',
  subtitleEn: 'Manage lanes and energy',
  difficulty: number >= 9 ? 'UZMAN' : 'USTALAŞMA',
  icon: Icons.view_in_ar_rounded,
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

  testWidgets('ten-level hub fits a compact Turkish phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const BlockFlowGamePage(),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(find.text('Blok Akışı'), findsOneWidget);
    expect(find.text('1. Akış Koridoru 01'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lane, energy, rift and pause controls fit a Turkish phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: BlockFlowPlayPage(level: _level(6), previousBestScore: 0),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(
      find.byKey(const ValueKey<String>('block_flow_scene')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('block_flow_hud')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('block_flow_left')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('block_flow_right')),
      findsOneWidget,
    );
    final Finder pause = find.byKey(const ValueKey<String>('block_flow_pause'));
    await tester.tap(find.byKey(const ValueKey<String>('block_flow_right')));
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tap(pause);
    await tester.pump();
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    await tester.tap(pause);
    await tester.pump();
    await tester.drag(
      find.byKey(const ValueKey<String>('block_flow_scene')),
      const Offset(-95, 0),
    );
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.takeException(), isNull);
  });

  testWidgets('English master corridor fits an 800-pixel tablet', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: BlockFlowPlayPage(level: _level(10), previousBestScore: 0),
      size: const Size(800, 1280),
      locale: const Locale('en'),
    );
    expect(
      find.byKey(const ValueKey<String>('block_flow_scene')),
      findsOneWidget,
    );
    expect(find.text('BLOCK FLOW'), findsOneWidget);
    expect(find.text('ROUTE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
