import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/color_reactor/color_reactor_game_page.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

ParkurLevelSpec _level(int number) => ParkurLevelSpec(
  number: number,
  titleTr: 'Reaktör Dizisi $number',
  titleEn: 'Reactor Sequence $number',
  subtitleTr: 'Darbe yönlendir',
  subtitleEn: 'Route the pulse',
  difficulty: 'USTALAŞMA',
  icon: Icons.bubble_chart_rounded,
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

  testWidgets('10-level reactor hub fits a compact Turkish phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const ColorReactorGamePage(),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(find.text('Renk Reaktörü'), findsOneWidget);
    expect(find.text('1. Reaktör Dizisi 01'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('channel selection and pause work in the compact play scene', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: ColorReactorPlayPage(level: _level(4), previousBestScore: 0),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(find.byKey(const ValueKey<String>('reactor_scene')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('reactor_hud')), findsOneWidget);
    for (int channel = 0; channel < 3; channel++) {
      expect(
        find.byKey(ValueKey<String>('reactor_channel_$channel')),
        findsOneWidget,
      );
    }
    await tester.tap(find.byKey(const ValueKey<String>('reactor_channel_2')));
    await tester.pump();
    final Finder pause = find.byKey(const ValueKey<String>('reactor_pause'));
    await tester.tap(pause);
    await tester.pump();
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    await tester.tap(pause);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('English master sequence paints on a tablet', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: ColorReactorPlayPage(level: _level(10), previousBestScore: 0),
      size: const Size(800, 1280),
      locale: const Locale('en'),
    );
    expect(find.byKey(const ValueKey<String>('reactor_scene')), findsOneWidget);
    expect(find.text('TARGET GATE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
