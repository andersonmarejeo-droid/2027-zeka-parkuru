import 'package:flutter/material.dart';

import '../../features/catalog/domain/studio_game_catalog.dart';
import '../../theme/studio_visuals.dart';
import 'game_visual_design.dart';

/// Visual material assigned to a catalog class.
///
/// Quiet, natural materials with dark accents that also read on white cards.
class StudioGameSkin {
  const StudioGameSkin({
    required this.gameClass,
    required this.accent,
    required this.accentSoft,
    required this.boardBackground,
    required this.boardSurface,
  });

  final StudioGameClass gameClass;
  final Color accent;
  final Color accentSoft;
  final Color boardBackground;
  final Color boardSurface;

  static StudioGameSkin forClass(StudioGameClass gameClass) {
    return switch (gameClass) {
      StudioGameClass.logic => const StudioGameSkin(
        gameClass: StudioGameClass.logic,
        accent: Color(0xFF665AA2),
        accentSoft: Color(0xFFEDEBFA),
        boardBackground: Color(0xFF303D3B),
        boardSurface: Color(0xFF43514E),
      ),
      StudioGameClass.numbers => const StudioGameSkin(
        gameClass: StudioGameClass.numbers,
        accent: StudioVisuals.tealInk,
        accentSoft: StudioVisuals.tealSoft,
        boardBackground: Color(0xFF0D2529),
        boardSurface: Color(0xFF17363A),
      ),
      StudioGameClass.visual => const StudioGameSkin(
        gameClass: StudioGameClass.visual,
        accent: Color(0xFF9C5471),
        accentSoft: Color(0xFFF8E9EF),
        boardBackground: Color(0xFF343D3B),
        boardSurface: Color(0xFF48554E),
      ),
      StudioGameClass.memory => const StudioGameSkin(
        gameClass: StudioGameClass.memory,
        accent: StudioVisuals.amberInk,
        accentSoft: StudioVisuals.amberSoft,
        boardBackground: Color(0xFF3D3930),
        boardSurface: Color(0xFF575044),
      ),
      StudioGameClass.strategy => const StudioGameSkin(
        gameClass: StudioGameClass.strategy,
        accent: Color(0xFFA2643E),
        accentSoft: Color(0xFFFAECE5),
        boardBackground: Color(0xFF2B1D19),
        boardSurface: Color(0xFF412B24),
      ),
      StudioGameClass.language => const StudioGameSkin(
        gameClass: StudioGameClass.language,
        accent: Color(0xFF3D7183),
        accentSoft: Color(0xFFE9F0FA),
        boardBackground: Color(0xFF172333),
        boardSurface: Color(0xFF26374D),
      ),
      StudioGameClass.speed => const StudioGameSkin(
        gameClass: StudioGameClass.speed,
        accent: StudioVisuals.dangerInk,
        accentSoft: Color(0xFFFBEAEA),
        boardBackground: Color(0xFF303D3B),
        boardSurface: Color(0xFF43514E),
      ),
      StudioGameClass.fun => const StudioGameSkin(
        gameClass: StudioGameClass.fun,
        accent: StudioVisuals.teal,
        accentSoft: StudioVisuals.amberSoft,
        boardBackground: Color(0xFF14282A),
        boardSurface: Color(0xFF203D40),
      ),
    };
  }

  static StudioGameSkin forGame(GameDefinition game) => forId(game.id);

  static StudioGameSkin forId(String gameId) {
    final GameVisualDesign design = GameVisualDesign.forGame(gameId);
    return StudioGameSkin(
      gameClass:
          StudioGameCatalog.byId(gameId)?.gameClass ?? StudioGameClass.logic,
      accent: design.accent,
      accentSoft: design.soft,
      boardBackground: design.board,
      boardSurface: StudioVisuals.surface,
    );
  }
}
