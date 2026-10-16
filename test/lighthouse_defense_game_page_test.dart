import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/features/catalog/domain/studio_game_catalog.dart';
import 'package:zeka_parkuru/games/lighthouse_defense/lighthouse_defense_game_page.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

ParkurLevelSpec _level(int number) => ParkurLevelSpec(
  number: number,
  titleTr: 'Nöbet ${number.toString().padLeft(2, '0')}',
  titleEn: 'Watch ${number.toString().padLeft(2, '0')}',
  subtitleTr: 'Kule kur ve dalgayı karşıla',
  subtitleEn: 'Build towers and hold the wave',
  difficulty: number >= 9 ? 'UZMAN' : 'KEŞİF',
  icon: Icons.light_rounded,
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
  await tester.pump(const Duration(milliseconds: 160));
}

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  test('Lighthouse Defense remains a distinct retired Fun catalog entry', () {
    final GameDefinition? game = StudioGameCatalog.byId('lighthouse_defense');
    expect(game?.isPlayable, isFalse);
    expect(game?.gameClass, StudioGameClass.fun);
    expect(game?.titleTr, 'Fener Savunması');
  });

  testWidgets('20-watch hub fits a compact Turkish phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const LighthouseDefenseGamePage(),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(find.text('Fener Savunması'), findsOneWidget);
    expect(find.text('1. Nöbet 01'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('coastal map, tower placement, upgrade and pause fit phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: LighthouseDefensePlayPage(level: _level(10), previousBestScore: 0),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    final Finder map = find.byKey(
      const ValueKey<String>('lighthouse_defense_map'),
    );
    expect(map, findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('lighthouse_defense_hud')),
      findsOneWidget,
    );
    final Size mapSize = tester.getSize(map);
    final Offset mapOrigin = tester.getTopLeft(map);
    await tester.tapAt(
      mapOrigin + Offset(mapSize.width * .10, mapSize.height * .28),
    );
    await tester.pump();
    expect(find.textContaining('Balista KURULDU'), findsOneWidget);

    await tester.tapAt(
      mapOrigin + Offset(mapSize.width * .10, mapSize.height * .28),
    );
    await tester.pump();
    final Finder upgrade = find.byKey(
      const ValueKey<String>('lighthouse_upgrade'),
    );
    expect(upgrade, findsOneWidget);
    await tester.tap(upgrade);
    await tester.pump();
    expect(find.textContaining('KULE GELİŞTİRİLDİ'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('lighthouse_defense_pause')),
    );
    await tester.pump();
    expect(find.text('KIYI NÖBETİ DURAKLATILDI'), findsOneWidget);
    await tester.tap(find.text('DEVAM ET'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('English final watch fits an 800×1280 tablet', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: LighthouseDefensePlayPage(level: _level(20), previousBestScore: 0),
      size: const Size(800, 1280),
      locale: const Locale('en'),
    );
    expect(
      find.byKey(const ValueKey<String>('lighthouse_defense_map')),
      findsOneWidget,
    );
    expect(find.text('LIGHTHOUSE · WATCH 20'), findsOneWidget);
    expect(
      find.text('TAP A BUILD PAD · TOWERS FIRE AUTOMATICALLY'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
