import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/games/tideglass_aquarium/tideglass_aquarium_game_page.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

const ParkurLevelSpec _level = ParkurLevelSpec(
  number: 1,
  titleTr: 'Habitat 1',
  titleEn: 'Habitat 1',
  subtitleTr: 'Su değerlerini dengele.',
  subtitleEn: 'Balance water values.',
  difficulty: 'UZMAN',
  icon: Icons.water_rounded,
);

Future<void> _mount(
  WidgetTester tester, {
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
      home: TideglassAquariumPlayPage(level: _level, previousBestScore: 0),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);
  testWidgets('aquarium controls fit 320 by 600', (WidgetTester tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(
      find.byKey(const ValueKey<String>('tideglass_tank_scene')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('tideglass_hud')), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('tideglass_review')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('tideglass_plus_guppy')),
    );
    await tester.pump();
    expect(find.text('1/3'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('tideglass_add_species')),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('English aquarium fits tablet', (WidgetTester tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      size: const Size(800, 1280),
      locale: const Locale('en'),
    );
    expect(find.text('HABITAT · 1'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('tideglass_plus_tetra')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
