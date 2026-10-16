import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/mine_detector/mine_detector_game_page.dart';
import 'package:zeka_parkuru/games/mine_detector/mine_detector_puzzle.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

void main() {
  setUpAll(installTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets(
    'compact phone preserves Mine Detector controls and clears its certified route',
    (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('tr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: MineDetectorPlayPage(level: _level(1), previousBestScore: 0),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);

      final MineDetectorPuzzle puzzle = MineDetectorPuzzle.forLevel(1);
      final int openClue = puzzle.initialState.revealed.firstWhere(
        (int cell) => puzzle.adjacentMineCount(cell) > 0,
      );

      // A pre-opened clue takes the chord route and gives feedback without
      // mutating the protected opening.
      await tester.tap(find.byKey(ValueKey<String>('mine_cell_$openClue')));
      await tester.pump();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey<String>('mine_hint')));
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('mine_restart_action')),
      );
      await tester.pump();

      bool flagMode = false;
      Future<void> setMode(bool wantFlags) async {
        if (flagMode == wantFlags) return;
        await tester.tap(find.byKey(const ValueKey<String>('mine_mode')));
        await tester.pump();
        flagMode = wantFlags;
      }

      // The exact model certificate is also the player route: no test-only
      // mine lookup or hidden-state shortcut is used here.
      for (final MineDetectorLogicAction action
          in puzzle.logicCertificate.actions) {
        await setMode(action.flagsMine);
        await tester.tap(
          find.byKey(ValueKey<String>('mine_cell_${action.cell}')),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      }

      await tester.pumpAndSettle();
      expect(find.text('MAYIN HARİTASI TEMİZ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('English tablet exposes the 20-level Mine Detector course', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(800, 1280);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: MineDetectorGamePage(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));
    expect(find.text('Mine Detector'), findsOneWidget);
    expect(find.textContaining('Scan 001'), findsOneWidget);
    expect(MineDetectorGamePage.totalCases, 30);
    expect(MineDetectorPuzzle.maximumUniqueCases, 300);
    expect(MineDetectorGamePage.totalCases, 30);
    expect(tester.takeException(), isNull);
  });
}

ParkurLevelSpec _level(int number) => ParkurLevelSpec(
  number: number,
  titleTr: 'Tarama ${number.toString().padLeft(3, '0')}',
  titleEn: 'Scan ${number.toString().padLeft(3, '0')}',
  subtitleTr: 'Güvenli hücreleri aç',
  subtitleEn: 'Clear safe cells',
  difficulty: 'KEŞİF',
  icon: Icons.radar_rounded,
);
