import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/cafe_shift/cafe_shift_game_page.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

const ParkurLevelSpec _level = ParkurLevelSpec(
  number: 10,
  titleTr: 'Vardiya 10',
  titleEn: 'Shift 10',
  subtitleTr: 'Siparişleri sırala.',
  subtitleEn: 'Route the orders.',
  difficulty: 'UZMAN',
  icon: Icons.local_cafe_rounded,
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
      home: CafeShiftPlayPage(level: _level, previousBestScore: 0),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 180));
}

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('fixed cafe tickets, counter art and station buttons fit phone', (
    WidgetTester tester,
  ) async {
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
      find.byKey(const ValueKey<String>('cafe_shift_scene')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('cafe_shift_hud')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('cafe_station_grinder')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('cafe_station_finishing')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('cafe_shift_serve')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey<String>('cafe_shift_pause')));
    await tester.pump();
    expect(find.textContaining('DURAKLATILDI'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('cafe_shift_pause')));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('English shift board and guest tickets fit tablet', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      size: const Size(800, 1280),
      locale: const Locale('en'),
    );
    expect(find.text('CAFE · SHIFT 10'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('cafe_shift_serve')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
