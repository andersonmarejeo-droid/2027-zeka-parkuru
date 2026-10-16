import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/features/catalog/domain/studio_game_catalog.dart';
import 'package:zeka_parkuru/games/air_hockey_arena/air_hockey_arena_game_page.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

ParkurLevelSpec _level(int number) => ParkurLevelSpec(
  number: number,
  titleTr: 'Arena ${number.toString().padLeft(2, '0')}',
  titleEn: 'Arena ${number.toString().padLeft(2, '0')}',
  subtitleTr: 'Diski oku ve açıyı kapat',
  subtitleEn: 'Read the puck and close the angle',
  difficulty: number >= 9 ? 'UZMAN' : 'ISINMA',
  icon: Icons.sports_hockey_rounded,
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

  test('Air Hockey Arena is retired from the active catalog', () {
    final GameDefinition? game = StudioGameCatalog.byId('air_hockey_arena');
    expect(game?.isPlayable, isFalse);
    expect(game?.isRetired, isTrue);
    expect(game?.gameClass, StudioGameClass.fun);
    expect(game?.titleTr, 'Air Hockey Arena');
  });

  testWidgets('20-arena hub fits a compact Turkish phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const AirHockeyArenaPage(),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(find.text('Air Hockey Arena'), findsOneWidget);
    expect(find.text('1. Arena 01'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('arena court, score, charged smash and pause fit Turkish phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: AirHockeyArenaPlayPage(level: _level(10), previousBestScore: 0),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(
      find.byKey(const ValueKey<String>('air_hockey_arena_scene')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('air_hockey_arena_hud')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('air_hockey_arena_smash')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('air_hockey_arena_pause')),
    );
    await tester.pump();
    expect(find.text('ARENA DURAKLATILDI'), findsOneWidget);
    await tester.tap(find.text('DEVAM ET'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('English expert arena fits an 800×1280 tablet', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: AirHockeyArenaPlayPage(level: _level(20), previousBestScore: 0),
      size: const Size(800, 1280),
      locale: const Locale('en'),
    );
    expect(
      find.byKey(const ValueKey<String>('air_hockey_arena_scene')),
      findsOneWidget,
    );
    expect(find.text('AIR HOCKEY · ARENA'), findsOneWidget);
    expect(find.text('DRAG IN YOUR HALF'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
