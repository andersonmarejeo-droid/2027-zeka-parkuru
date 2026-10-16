import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/deep_current/deep_current_game_page.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

const ParkurLevelSpec _level = ParkurLevelSpec(
  number: 10,
  titleTr: 'Dalış 10',
  titleEn: 'Dive 10',
  subtitleTr: 'Kurtar ve dön.',
  subtitleEn: 'Recover and return.',
  difficulty: 'UZMAN',
  icon: Icons.sailing_rounded,
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
      home: DeepCurrentPlayPage(level: _level, previousBestScore: 0),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('fixed dive scene and thumb controls fit a compact phone', (
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
      find.byKey(const ValueKey<String>('deep_current_ocean')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('deep_current_hud')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('deep_current_right')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('deep_current_ping')),
      findsOneWidget,
    );
    await tester.press(
      find.byKey(const ValueKey<String>('deep_current_right')),
    );
    await tester.pump(const Duration(milliseconds: 320));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(const ValueKey<String>('deep_current_pause')));
    await tester.pump();
    expect(find.textContaining('GÖREV DURAKLATILDI'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('deep_current_pause')));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('English mission HUD fits tablet and opens sonar controls', (
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
    expect(find.text('DEEP CURRENT · DIVE 10'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('deep_current_collect')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
