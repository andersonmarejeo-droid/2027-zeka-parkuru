import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/features/catalog/domain/studio_game_catalog.dart';
import 'package:zeka_parkuru/games/hanoi/hanoi_game_page.dart';
import 'package:zeka_parkuru/games/shared/studio_game_skin.dart';
import 'package:zeka_parkuru/games/shared/game_visual_design.dart';
import 'package:zeka_parkuru/theme/studio_visuals.dart';

void main() {
  test('legacy class fallback keeps a calm opaque material', () {
    for (final StudioGameClass gameClass in StudioGameClass.values) {
      final StudioGameSkin skin = StudioGameSkin.forClass(gameClass);

      expect(skin.gameClass, gameClass);
      expect((skin.accentSoft.a * 255).round(), 255);
      expect(skin.boardBackground.computeLuminance(), lessThan(0.1));
      expect(
        skin.boardSurface.computeLuminance(),
        greaterThan(skin.boardBackground.computeLuminance()),
      );
    }
  });

  test('numbers class uses the shared studio teal material', () {
    expect(
      StudioGameSkin.forClass(StudioGameClass.numbers).accent,
      StudioVisuals.tealInk,
    );
  });

  test('Hanoi uses a vivid distinct color for every ring', () {
    expect(HanoiVisuals.rings.length, greaterThanOrEqualTo(6));
    expect(HanoiVisuals.rings.toSet().length, HanoiVisuals.rings.length);
    expect(HanoiVisuals.boardTop.computeLuminance(), lessThan(.1));
    expect(
      GameVisualDesign.forGame('hanoi').accent,
      const Color(0xFF087FA8),
    );
  });

  test(
    'all active games use their authored material, not the legacy dark skin',
    () {
      for (final game in StudioGameCatalog.games.where(
        (game) => game.isPlayable,
      )) {
        final skin = StudioGameSkin.forGame(game);
        final design = GameVisualDesign.forGame(game.id);
        expect(skin.gameClass, game.gameClass);
        expect(skin.accent, design.accent);
        expect(skin.boardBackground, design.board);
        expect(skin.boardSurface, StudioVisuals.surface);
      }
      expect(
        StudioGameSkin.forId('hanoi').boardBackground.computeLuminance(),
        greaterThan(.7),
      );
      expect(
        StudioGameSkin.forId('reversi_arena').boardBackground,
        const Color(0xFF246B56),
      );
    },
  );
}
