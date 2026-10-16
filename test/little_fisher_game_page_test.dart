import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/little_fisher/little_fisher_game_page.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

ParkurLevelSpec _level(int number) => ParkurLevelSpec(
  number: number,
  titleTr: 'Akıntı Seferi $number',
  titleEn: 'Current Expedition $number',
  subtitleTr: 'Misina gerilimini koru',
  subtitleEn: 'Keep the line in its safe band',
  difficulty: number >= 9 ? 'UZMAN' : 'USTALAŞMA',
  icon: Icons.phishing_rounded,
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

  testWidgets('10-level fishing hub fits a compact Turkish phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const LittleFisherGamePage(),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(find.text('Küçük Balıkçı'), findsOneWidget);
    expect(find.text('1. Akıntı Seferi 01'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bait, depth, reel rhythm and pause fit on phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: LittleFisherPlayPage(level: _level(4), previousBestScore: 0),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(
      find.byKey(const ValueKey<String>('little_fisher_scene')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('little_fisher_hud')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('little_fisher_bait_0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('little_fisher_depth_1')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('little_fisher_action')),
    );
    await tester.pump(const Duration(milliseconds: 40));
    expect(find.text('MAKARA'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('little_fisher_action')),
    );
    await tester.pump(const Duration(milliseconds: 80));
    final Finder pause = find.byKey(
      const ValueKey<String>('little_fisher_pause'),
    );
    await tester.tap(pause);
    await tester.pump();
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    await tester.tap(pause);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('English master lake fits an 800-pixel tablet', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: LittleFisherPlayPage(level: _level(10), previousBestScore: 0),
      size: const Size(800, 1280),
      locale: const Locale('en'),
    );
    expect(
      find.byKey(const ValueKey<String>('little_fisher_scene')),
      findsOneWidget,
    );
    expect(find.text('LITTLE FISHER'), findsOneWidget);
    expect(find.text('DEPTH'), findsOneWidget);
    expect(find.text('CAST'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
