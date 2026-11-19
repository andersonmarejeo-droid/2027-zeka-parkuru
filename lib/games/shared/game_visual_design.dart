import 'package:flutter/material.dart';

import '../../theme/studio_visuals.dart';

enum GameBoardMaterial { paper, wood, felt, ceramic, map, cards, graphite }

/// Authored material choices for every playable game. Colours carry meaning:
/// paper for clues, wood for movable pieces, felt for tabletop strategy.
class GameVisualDesign {
  const GameVisualDesign(this.accent, this.material);

  final Color accent;
  final GameBoardMaterial material;

  static const Map<String, GameVisualDesign> games = {
    'detective_notes': GameVisualDesign(
      Color(0xFF866139),
      GameBoardMaterial.paper,
    ),
    'balance_scale': GameVisualDesign(
      Color(0xFF866139),
      GameBoardMaterial.wood,
    ),
    // Number games deliberately use separate dark, high-contrast accents so
    // neighbouring cards read as distinct instruments in the same category.
    'numbers': GameVisualDesign(Color(0xFF0B6D63), GameBoardMaterial.paper),
    'number_sort': GameVisualDesign(Color(0xFFA05A2C), GameBoardMaterial.wood),
    'target_24': GameVisualDesign(Color(0xFFB13B27), GameBoardMaterial.wood),
    'mini_sudoku': GameVisualDesign(Color(0xFF2457A6), GameBoardMaterial.paper),
    'kenken_cube': GameVisualDesign(Color(0xFF2B7A53), GameBoardMaterial.paper),
    'hidden_masses': GameVisualDesign(
      Color(0xFF1D6271),
      GameBoardMaterial.ceramic,
    ),
    'kakuro': GameVisualDesign(Color(0xFF6B4F9B), GameBoardMaterial.paper),
    'blocks': GameVisualDesign(Color(0xFF3D7183), GameBoardMaterial.ceramic),
    // The previous teal was too light for the catalogue text contrast. Keep
    // the same family while using the darker authored teal used by number
    // games so labels remain readable on compact screens.
    'picture_iq': GameVisualDesign(
      Color(0xFF176D62),
      GameBoardMaterial.paper,
    ),
    'shape_puzzle': GameVisualDesign(Color(0xFF665AA2), GameBoardMaterial.wood),
    'memory': GameVisualDesign(Color(0xFF866139), GameBoardMaterial.ceramic),
    'card_pairs': GameVisualDesign(Color(0xFF866139), GameBoardMaterial.cards),
    'focus_filter': GameVisualDesign(
      Color(0xFFA44F48),
      GameBoardMaterial.ceramic,
    ),
    'rhythm_memory': GameVisualDesign(
      Color(0xFF866139),
      GameBoardMaterial.wood,
    ),
    'attention_tunnel': GameVisualDesign(
      Color(0xFF3D7183),
      GameBoardMaterial.cards,
    ),
    'hanoi': GameVisualDesign(Color(0xFF087FA8), GameBoardMaterial.wood),
    'candy_sort': GameVisualDesign(
      Color(0xFFC46D32),
      GameBoardMaterial.wood,
    ),
    'parking_puzzle': GameVisualDesign(
      Color(0xFFA2643E),
      GameBoardMaterial.graphite,
    ),
    'mini_chess_tactics': GameVisualDesign(
      Color(0xFF866139),
      GameBoardMaterial.wood,
    ),
    'word_hunt': GameVisualDesign(Color(0xFF34715D), GameBoardMaterial.paper),
    'meaning_match': GameVisualDesign(
      Color(0xFF3D7183),
      GameBoardMaterial.paper,
    ),
    'proverb_finish': GameVisualDesign(
      Color(0xFF34715D),
      GameBoardMaterial.paper,
    ),
    'word_wheel': GameVisualDesign(Color(0xFF34715D), GameBoardMaterial.wood),
    'sentence_builder': GameVisualDesign(
      Color(0xFF34715D),
      GameBoardMaterial.paper,
    ),
    'near_meaning': GameVisualDesign(
      Color(0xFF34715D),
      GameBoardMaterial.paper,
    ),
    'letter_maze': GameVisualDesign(
      Color(0xFF34715D),
      GameBoardMaterial.ceramic,
    ),
    'language_detective': GameVisualDesign(
      Color(0xFF866139),
      GameBoardMaterial.paper,
    ),
    'story_order': GameVisualDesign(Color(0xFF3D7183), GameBoardMaterial.cards),
    'reflex': GameVisualDesign(Color(0xFFA44F48), GameBoardMaterial.ceramic),
    'slide_sweets': GameVisualDesign(
      Color(0xFF34715D),
      GameBoardMaterial.graphite,
    ),
    'reversi_arena': GameVisualDesign(
      Color(0xFF267A6C),
      GameBoardMaterial.felt,
    ),
    'picross_master': GameVisualDesign(
      Color(0xFF3D7183),
      GameBoardMaterial.ceramic,
    ),
    'arrow_route': GameVisualDesign(Color(0xFF665AA2), GameBoardMaterial.paper),
    'island_sea': GameVisualDesign(Color(0xFF146C8A), GameBoardMaterial.map),
    'futoshiki': GameVisualDesign(Color(0xFF247568), GameBoardMaterial.paper),
    'skyscrapers': GameVisualDesign(
      Color(0xFF48538C),
      GameBoardMaterial.ceramic,
    ),
    'hitori': GameVisualDesign(Color(0xFF6B3D71), GameBoardMaterial.paper),
    'city_atlas': GameVisualDesign(Color(0xFF247568), GameBoardMaterial.map),
    'world_atlas': GameVisualDesign(Color(0xFF3D7183), GameBoardMaterial.map),
    'katamino_workshop': GameVisualDesign(
      Color(0xFF8E603B),
      GameBoardMaterial.wood,
    ),
    'single_stroke': GameVisualDesign(
      Color(0xFF51419A),
      GameBoardMaterial.paper,
    ),
    'arrow_maze': GameVisualDesign(
      Color(0xFF17647A),
      GameBoardMaterial.map,
    ),
  };

  static GameVisualDesign forGame(String id) =>
      games[id] ??
      const GameVisualDesign(StudioVisuals.tealInk, GameBoardMaterial.paper);

  Color get soft => Color.lerp(Colors.white, accent, .09)!;
  Color get board => switch (material) {
    GameBoardMaterial.wood => const Color(0xFFF1E4D1),
    GameBoardMaterial.felt => const Color(0xFF246B56),
    GameBoardMaterial.graphite => const Color(0xFF334247),
    GameBoardMaterial.map => const Color(0xFFE7EFF0),
    _ => StudioVisuals.paper,
  };
}

/// Route-scoped typography and controls, shared with the launcher. Boards keep
/// their authored geometry; this never scales or rewrites puzzle state.
class StudioGameTheme extends StatelessWidget {
  const StudioGameTheme({super.key, required this.gameId, required this.child});

  final String gameId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData parent = Theme.of(context);
    final GameVisualDesign design = GameVisualDesign.forGame(gameId);
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: design.accent,
      brightness: Brightness.light,
      primary: design.accent,
      onPrimary: Colors.white,
      surface: StudioVisuals.surface,
      onSurface: StudioVisuals.ink,
      onSurfaceVariant: StudioVisuals.muted,
      outline: const Color(0xFF869B92),
      outlineVariant: StudioVisuals.line,
      error: StudioVisuals.dangerInk,
    );
    return Theme(
      data: parent.copyWith(
        brightness: Brightness.light,
        scaffoldBackgroundColor: StudioVisuals.canvas,
        colorScheme: scheme,
        textTheme: parent.textTheme.apply(
          fontFamily: 'Roboto',
          bodyColor: StudioVisuals.ink,
          displayColor: StudioVisuals.ink,
        ),
        iconTheme: const IconThemeData(color: StudioVisuals.ink),
        cardTheme: CardThemeData(
          color: StudioVisuals.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 2,
          shadowColor: design.accent.withValues(alpha: .12),
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: StudioVisuals.cardRadius,
            side: BorderSide(color: StudioVisuals.line.withValues(alpha: .82)),
          ),
        ),
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: design.accent,
          linearTrackColor: StudioVisuals.surfaceSoft,
          circularTrackColor: StudioVisuals.surfaceSoft,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: design.soft,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: StudioVisuals.line.withValues(alpha: .85),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: StudioVisuals.line.withValues(alpha: .85),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: design.accent, width: 1.6),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: StudioVisuals.canvas,
          foregroundColor: StudioVisuals.ink,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'Roboto',
            color: StudioVisuals.ink,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 52),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            textStyle: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: design.accent,
            minimumSize: const Size(48, 48),
            textStyle: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            side: const BorderSide(color: StudioVisuals.line),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: StudioVisuals.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titleTextStyle: const TextStyle(
            fontFamily: 'Roboto',
            color: StudioVisuals.ink,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
          contentTextStyle: const TextStyle(
            fontFamily: 'Roboto',
            color: StudioVisuals.muted,
            fontSize: 16,
            height: 1.45,
          ),
        ),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: child,
      ),
    );
  }
}

/// Keep action labels readable instead of squeezing them on small phones.
class StudioGameActions extends StatelessWidget {
  const StudioGameActions({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, limits) {
      if (limits.maxWidth >= 360 &&
          MediaQuery.textScalerOf(context).scale(1) <= 1.15) {
        return Row(children: children);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final Widget child in children)
            if (child is Expanded)
              child.child
            else if (child is SizedBox)
              const SizedBox(height: 8)
            else
              child,
        ],
      );
    },
  );
}
