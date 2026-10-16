import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/loop_master/loop_game_page.dart';
import 'package:zeka_parkuru/games/loop_master/loop_puzzle.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

ParkurLevelSpec _level(int number) => ParkurLevelSpec(
  number: number,
  titleTr: 'Döngü Ustası $number',
  titleEn: 'Loop Master $number',
  subtitleTr: 'Tek kapalı halka',
  subtitleEn: 'One closed loop',
  difficulty: 'USTALAŞMA',
  icon: Icons.loop_rounded,
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

  testWidgets('level hub opens on a compact phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const LoopMasterGamePage(),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(find.text('Döngü Ustası'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'certified loop can be drawn and completes through shared result',
    (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await _mount(
        tester,
        home: LoopMasterPlayPage(level: _level(1), previousBestScore: 0),
        size: const Size(360, 740),
        locale: const Locale('tr'),
      );
      final Finder board = find.byKey(
        const ValueKey<String>('loop_master_board'),
      );
      expect(board, findsOneWidget);
      final LoopPuzzle puzzle = LoopPuzzle.forLevel(1);
      final Offset topLeft = tester.getTopLeft(board);
      final Size boardSize = tester.getSize(board);
      for (final int vertex in <int>[
        ...puzzle.solutionVertices,
        puzzle.solutionVertices.first,
      ]) {
        final LoopPoint point = puzzle.point(vertex);
        await tester.tapAt(
          topLeft +
              Offset(
                boardSize.width * point.column / puzzle.size,
                boardSize.height * point.row / puzzle.size,
              ),
        );
        await tester.pump(const Duration(milliseconds: 40));
      }
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('DÖNGÜ KAPANDI'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('English level hub fits a tablet viewport', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const LoopMasterGamePage(),
      size: const Size(800, 1280),
      locale: const Locale('en'),
    );
    expect(find.text('Loop Master'), findsOneWidget);
    expect(LoopMasterGamePage.totalCases, 30);
    expect(tester.takeException(), isNull);
  });
}
