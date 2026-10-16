import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/features/catalog/domain/studio_game_catalog.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/games/table_tennis_rally/table_tennis_rally_game_page.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

ParkurLevelSpec _level(int number) => ParkurLevelSpec(
  number: number,
  titleTr: 'Ralli ${number.toString().padLeft(2, '0')}',
  titleEn: 'Rally ${number.toString().padLeft(2, '0')}',
  subtitleTr: 'Konumlan ve zamanında vur',
  subtitleEn: 'Get in position and time the hit',
  difficulty: number >= 9 ? 'UZMAN' : 'ISINMA',
  icon: Icons.sports_tennis_rounded,
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

  test('Table Tennis Rally remains a distinct retired Fun catalog entry', () {
    final GameDefinition? game = StudioGameCatalog.byId('table_tennis_rally');
    expect(game?.isPlayable, isFalse);
    expect(game?.gameClass, StudioGameClass.fun);
    expect(game?.titleTr, 'Masa Tenisi Rallisi');
  });

  testWidgets('20-match hub fits a compact Turkish phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const TableTennisRallyGamePage(),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(find.text('Masa Tenisi Rallisi'), findsOneWidget);
    expect(find.text('1. Ralli 01'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('paddle, shot choices and pause fit a Turkish phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: TableTennisRallyPlayPage(level: _level(10), previousBestScore: 0),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(
      find.byKey(const ValueKey<String>('table_tennis_rally_scene')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('table_tennis_rally_hud')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('table_tennis_shot_topspin')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('table_tennis_shot_slice')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('table_tennis_shot_block')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('table_tennis_rally_hit')),
      findsOneWidget,
    );

    final Finder pause = find.byKey(
      const ValueKey<String>('table_tennis_rally_pause'),
    );
    await tester.tap(pause);
    await tester.pump();
    expect(find.text('RALLİ DURAKLATILDI'), findsOneWidget);
    await tester.tap(find.text('DEVAM ET'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('English expert match fits an 800×1280 tablet', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: TableTennisRallyPlayPage(level: _level(20), previousBestScore: 0),
      size: const Size(800, 1280),
      locale: const Locale('en'),
    );
    expect(
      find.byKey(const ValueKey<String>('table_tennis_rally_scene')),
      findsOneWidget,
    );
    expect(find.text('TABLE TENNIS · RALLY'), findsOneWidget);
    expect(find.text('HIT · TIME YOUR RETURN'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
