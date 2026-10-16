import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/features/catalog/domain/studio_game_catalog.dart';
import 'package:zeka_parkuru/games/drift_league/drift_league_game_page.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

ParkurLevelSpec _level(int number) => ParkurLevelSpec(
  number: number,
  titleTr: 'Pist ${number.toString().padLeft(2, '0')}',
  titleEn: 'Circuit ${number.toString().padLeft(2, '0')}',
  subtitleTr: 'Virajı oku ve çizgiyi koru',
  subtitleEn: 'Read the corner and hold your line',
  difficulty: number >= 9 ? 'UZMAN' : 'ISINMA',
  icon: Icons.sports_motorsports_rounded,
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

  test('Drift League is retired from the active catalog', () {
    final game = StudioGameCatalog.byId('drift_league');
    expect(game?.isPlayable, isFalse);
    expect(game?.isRetired, isTrue);
    expect(game?.gameClass, StudioGameClass.fun);
    expect(game?.titleTr, 'Drift Ligi');
  });

  testWidgets('20-level hub fits a compact Turkish phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const DriftLeagueGamePage(),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(find.text('Drift Ligi'), findsOneWidget);
    expect(find.text('1. Pist 01'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('steering, brake, handbrake and pause fit the phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: DriftLeagueRunPage(level: _level(8), previousBestScore: 0),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(
      find.byKey(const ValueKey<String>('drift_league_scene')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('drift_league_hud')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('drift_league_steering')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('drift_league_brake')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('drift_league_handbrake')),
      findsOneWidget,
    );

    final Finder pause = find.byKey(
      const ValueKey<String>('drift_league_pause'),
    );
    await tester.tap(pause);
    await tester.pump();
    expect(find.text('KOŞU DURAKLATILDI'), findsOneWidget);
    await tester.tap(pause);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('English expert circuit fits an 800×1280 tablet', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: DriftLeagueRunPage(level: _level(20), previousBestScore: 0),
      size: const Size(800, 1280),
      locale: const Locale('en'),
    );
    expect(
      find.byKey(const ValueKey<String>('drift_league_scene')),
      findsOneWidget,
    );
    expect(find.text('DRIFT LEAGUE'), findsOneWidget);
    expect(find.text('STEER'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
