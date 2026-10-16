import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/museum_after_hours/museum_after_hours_game_page.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

ParkurLevelSpec _level() => const ParkurLevelSpec(
  number: 10,
  titleTr: 'Vardiya 10',
  titleEn: 'Shift 10',
  subtitleTr: 'Üç eseri al, sessiz çık.',
  subtitleEn: 'Recover three works and leave unseen.',
  difficulty: 'UZMAN',
  icon: Icons.museum_rounded,
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
      home: MuseumAfterHoursPlayPage(level: _level(), previousBestScore: 0),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 180));
}

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('fixed museum board and action controls fit a compact phone', (
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
      find.byKey(const ValueKey<String>('museum_after_hours_map')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('museum_after_hours_hud')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('museum_move_right')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('museum_collect')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey<String>('museum_move_right')));
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('museum_after_hours_pause')),
    );
    await tester.pump();
    expect(find.textContaining('DURAKLATILDI'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('museum_after_hours_pause')),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('English gallery HUD and controls fit a tablet', (
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
    expect(find.text('MUSEUM · SHIFT 10'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('museum_after_hours_map')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
