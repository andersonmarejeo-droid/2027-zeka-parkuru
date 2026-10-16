import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/features/catalog/domain/studio_game_catalog.dart';
import 'package:zeka_parkuru/games/relic_run/relic_run_game_page.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

ParkurLevelSpec _level(int number) => ParkurLevelSpec(
  number: number,
  titleTr: 'Sefer ${number.toString().padLeft(2, '0')}',
  titleEn: 'Expedition ${number.toString().padLeft(2, '0')}',
  subtitleTr: 'İşareti oku, konum al, karşılık ver',
  subtitleEn: 'Read the tell, reposition and counter',
  difficulty: number >= 9 ? 'UZMAN' : 'KEŞİF',
  icon: Icons.explore_rounded,
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
  await tester.pump(const Duration(milliseconds: 150));
}

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  test('Relic Run remains a distinct retired Fun catalog entry', () {
    final GameDefinition? game = StudioGameCatalog.byId('relic_run');
    expect(game?.isPlayable, isFalse);
    expect(game?.gameClass, StudioGameClass.fun);
    expect(game?.titleTr, 'Kalıntı Seferi');
  });

  testWidgets('20-expedition hub fits a compact Turkish phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const RelicRunGamePage(),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(find.text('Kalıntı Seferi'), findsOneWidget);
    expect(find.text('1. Sefer 01'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('room board, telegraph HUD and controls pause cleanly', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: RelicRunPlayPage(level: _level(10), previousBestScore: 0),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(
      find.byKey(const ValueKey<String>('relic_run_board')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('relic_run_hud')), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('relic_run_attack')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('relic_run_dodge')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('relic_run_skill')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey<String>('relic_run_pause')));
    await tester.pump();
    expect(find.text('SEFER DURAKLATILDI'), findsOneWidget);
    await tester.tap(find.text('DEVAM ET'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('English final expedition fits an 800×1280 tablet', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: RelicRunPlayPage(level: _level(20), previousBestScore: 0),
      size: const Size(800, 1280),
      locale: const Locale('en'),
    );
    expect(
      find.byKey(const ValueKey<String>('relic_run_board')),
      findsOneWidget,
    );
    expect(find.text('RELIC RUN · EXPEDITION 20'), findsOneWidget);
    expect(
      find.text('MARKED CELLS ARE NEXT · TAP A TARGET TO AIM'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
