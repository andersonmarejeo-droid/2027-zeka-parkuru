import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/features/catalog/domain/studio_game_catalog.dart';
import 'package:zeka_parkuru/games/penalty_mindgame/penalty_mindgame_game_page.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

ParkurLevelSpec _level(int number) => ParkurLevelSpec(
  number: number,
  titleTr: 'Penaltı ${number.toString().padLeft(2, '0')}',
  titleEn: 'Shootout ${number.toString().padLeft(2, '0')}',
  subtitleTr: 'Duruşu oku ve zamanında dal',
  subtitleEn: 'Read the stance and dive on time',
  difficulty: number >= 9 ? 'UZMAN' : 'ISINMA',
  icon: Icons.sports_soccer_rounded,
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

  test('Penalty Mindgame remains a distinct retired Fun catalog entry', () {
    final GameDefinition? game = StudioGameCatalog.byId('penalty_mindgame');
    expect(game?.isPlayable, isFalse);
    expect(game?.gameClass, StudioGameClass.fun);
    expect(game?.titleTr, 'Penaltı Zihin Oyunu');
  });

  testWidgets('20-round hub fits a compact Turkish phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const PenaltyMindgamePage(),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(find.text('Penaltı Zihin Oyunu'), findsOneWidget);
    expect(find.text('1. Penaltı 01'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('kicking, power, keeper lanes and pause fit a Turkish phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: PenaltyMindgamePlayPage(level: _level(10), previousBestScore: 0),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(
      find.byKey(const ValueKey<String>('penalty_mindgame_scene')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('penalty_mindgame_hud')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('penalty_mindgame_power')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('penalty_mindgame_shoot')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('penalty_mindgame_lane_left')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('penalty_mindgame_lane_center')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('penalty_mindgame_lane_right')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('penalty_mindgame_pause')),
    );
    await tester.pump();
    expect(find.text('PENALTI SERİSİ DURAKLATILDI'), findsOneWidget);
    await tester.tap(find.text('DEVAM ET'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('English expert shootout fits an 800×1280 tablet', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: PenaltyMindgamePlayPage(level: _level(20), previousBestScore: 0),
      size: const Size(800, 1280),
      locale: const Locale('en'),
    );
    expect(
      find.byKey(const ValueKey<String>('penalty_mindgame_scene')),
      findsOneWidget,
    );
    expect(find.text('PENALTY · READ & REACT'), findsOneWidget);
    expect(find.text('TAKE THE SHOT'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
