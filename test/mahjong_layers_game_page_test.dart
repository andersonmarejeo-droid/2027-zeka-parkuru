import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/mahjong_layers/mahjong_layers_game_page.dart';
import 'package:zeka_parkuru/games/mahjong_layers/mahjong_layers_puzzle.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

void main() {
  setUpAll(installTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets(
    'compact phone clears a layered Mahjong route and keeps tools safe',
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
          home: MahjongLayersPlayPage(level: _level(1), previousBestScore: 0),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey<String>('mahjong_hint')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey<String>('mahjong_shuffle')));
      await tester.pump(const Duration(milliseconds: 280));
      await tester.tap(find.byKey(const ValueKey<String>('mahjong_shuffle')));
      await tester.pump(const Duration(milliseconds: 280));
      expect(tester.takeException(), isNull);

      final MahjongLayersPuzzle puzzle = MahjongLayersPuzzle.forLevel(1);
      final MahjongMove firstMove = puzzle.solution.first;
      await tester.tap(
        find.byKey(ValueKey<String>('mahjong_tile_${firstMove.firstTileId}')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(ValueKey<String>('mahjong_tile_${firstMove.secondTileId}')),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.byKey(ValueKey<String>('mahjong_tile_${firstMove.firstTileId}')),
        findsNothing,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('mahjong_undo_action')),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.byKey(ValueKey<String>('mahjong_tile_${firstMove.firstTileId}')),
        findsOneWidget,
      );

      for (int moveIndex = 0; moveIndex < puzzle.solution.length; moveIndex++) {
        final MahjongMove move = puzzle.solution[moveIndex];
        await tester.tap(
          find.byKey(ValueKey<String>('mahjong_tile_${move.firstTileId}')),
        );
        await tester.pump();
        await tester.tap(
          find.byKey(ValueKey<String>('mahjong_tile_${move.secondTileId}')),
        );
        await tester.pump(const Duration(milliseconds: 280));
        expect(
          find.byKey(ValueKey<String>('mahjong_tile_${move.firstTileId}')),
          findsNothing,
          reason: 'solution move $moveIndex should remove its first tile',
        );
      }
      await tester.pumpAndSettle();
      expect(find.text('KATMANLAR AÇILDI'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('English tablet exposes the 20-level Mahjong parkur', (
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
        home: MahjongLayersGamePage(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));
    expect(find.text('Mahjong Layers'), findsOneWidget);
    expect(find.textContaining('Layer 001'), findsOneWidget);
    expect(MahjongLayersGamePage.totalCases, 20);
    expect(
      MahjongLayersGamePage.totalCases,
      MahjongLayersPuzzle.maximumUniqueCases,
    );
    expect(tester.takeException(), isNull);
  });
}

ParkurLevelSpec _level(int number) => ParkurLevelSpec(
  number: number,
  titleTr: 'Katman ${number.toString().padLeft(3, '0')}',
  titleEn: 'Layer ${number.toString().padLeft(3, '0')}',
  subtitleTr: 'Açık taş çiftleri',
  subtitleEn: 'Free tile pairs',
  difficulty: 'KEŞİF',
  icon: Icons.layers_rounded,
);
