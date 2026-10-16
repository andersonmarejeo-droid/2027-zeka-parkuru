import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/hex_connection/hex_connection_game_page.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

ParkurLevelSpec _level(int number) => ParkurLevelSpec(
  number: number,
  titleTr: 'Hex $number',
  titleEn: 'Hex $number',
  subtitleTr: 'Köprü kur',
  subtitleEn: 'Build a bridge',
  difficulty: 'USTALAŞMA',
  icon: Icons.hexagon_outlined,
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

  testWidgets('20-level hub fits compact Turkish phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const HexConnectionGamePage(),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(find.text('Hex Bağlantısı'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'phone match accepts a move, gets a reply and undoes a full turn',
    (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await _mount(
        tester,
        home: HexConnectionPlayPage(level: _level(1), previousBestScore: 0),
        size: const Size(360, 800),
        locale: const Locale('tr'),
      );
      expect(find.text('5×5 · Koral 0 · Lacivert 0'), findsOneWidget);

      final Finder canvas = find.byKey(
        const ValueKey<String>('hex_board_canvas'),
      );
      final Size canvasSize = tester.getSize(canvas);
      final double radius = canvasSize.width / 8;
      final double halfHeight = math.sqrt(3) * radius / 2;
      final Offset firstHex =
          tester.getTopLeft(canvas) + Offset(radius, halfHeight);
      await tester.tapAt(firstHex);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 240));
      expect(find.text('5×5 · Koral 1 · Lacivert 1'), findsOneWidget);

      final Finder undo = find.byKey(const ValueKey<String>('hex_undo'));
      await tester.ensureVisible(undo);
      await tester.tap(undo);
      await tester.pump();
      expect(find.text('5×5 · Koral 0 · Lacivert 0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('English hub fits a tablet viewport', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const HexConnectionGamePage(),
      size: const Size(800, 1280),
      locale: const Locale('en'),
    );
    expect(find.text('Hex Connection'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
