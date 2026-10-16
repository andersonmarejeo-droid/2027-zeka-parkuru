import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Layout rules shared by new games and level hubs.
///
/// The frame deliberately limits only the menu/content column. Game boards may
/// still use their full available area inside [child] when that improves play.
class ResponsiveGameFrame extends StatelessWidget {
  const ResponsiveGameFrame({
    super.key,
    required this.child,
    this.maxContentWidth = 760,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double maxContentWidth;
  final EdgeInsetsGeometry padding;

  /// Narrow phones need room for a visible back action and a 48 dp target.
  static EdgeInsets pagePaddingFor(double width) {
    if (width < 360) return const EdgeInsets.symmetric(horizontal: 12);
    if (width < 600) return const EdgeInsets.symmetric(horizontal: 16);
    return const EdgeInsets.symmetric(horizontal: 24);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double contentWidth = math.min(
          constraints.maxWidth,
          maxContentWidth,
        );
        return Center(
          child: SizedBox(
            width: contentWidth,
            height: constraints.maxHeight,
            child: Padding(padding: padding, child: child),
          ),
        );
      },
    );
  }
}

/// Shared touch thresholds. Individual games keep their own move rules but
/// use these values so touch targets do not regress as the catalog expands.
abstract final class GameInputPolicy {
  static const double minimumTargetSize = 48;
  static const double dragActivationDistance = 8;

  static bool shouldStartDrag(Offset start, Offset current) {
    return (current - start).distance >= dragActivationDistance;
  }

  static Size minimumInteractiveSize(Size visualSize) {
    return Size(
      math.max(visualSize.width, minimumTargetSize),
      math.max(visualSize.height, minimumTargetSize),
    );
  }
}

/// Minimum content depth required before a new game is shipped.
abstract final class GameContentPolicy {
  static const int campaignLevels = 30;
  static const int variantsPerChapter = 10;
  /// Kelime Çarkı uses 700 deterministic rounds while showing 30 chapters.
  static const int wordWheelPoolSize = 700;
  static const Set<String> standardGames = {
    'detective_notes',
    'balance_scale',
    'numbers',
    'number_sort',
    'target_24',
    'mini_sudoku',
    'kenken_cube',
    'hidden_masses',
    'kakuro',
    'blocks',
    'picture_iq',
    'shape_puzzle',
    'memory',
    'card_pairs',
    'focus_filter',
    'rhythm_memory',
    'attention_tunnel',
    'hanoi',
    'candy_sort',
    'parking_puzzle',
    'mini_chess_tactics',
    'word_hunt',
    'meaning_match',
    'proverb_finish',
    'word_wheel',
    'sentence_builder',
    'near_meaning',
    'letter_maze',
    'language_detective',
    'story_order',
    'reflex',
    'slide_sweets',
    'reversi_arena',
    'picross_master',
    'arrow_route',
    'island_sea',
    'futoshiki',
    'skyscrapers',
    'hitori',
    'city_atlas',
    'world_atlas',
    'katamino_workshop',
    'single_stroke',
    'arrow_maze',
  };

  /// Native difficulty templates are deliberately separate from visible
  /// chapters; pool generators map their rounds monotonically to these stages.
  static int nativeStages(String gameId) {
    if (gameId == 'single_stroke') return campaignLevels;
    if (gameId == 'parking_puzzle' ||
        gameId == 'detective_notes' ||
        gameId == 'hanoi') {
      return 300;
    }
    if (const {
      'mini_chess_tactics',
      'picross_master',
      'arrow_route',
      'loop_master',
      'island_sea',
      'futoshiki',
      'skyscrapers',
      'hitori',
      'card_pairs',
      'focus_filter',
      'spot_change',
      'rhythm_memory',
      'attention_tunnel',
      'meaning_match',
      'proverb_finish',
      'sentence_builder',
      'near_meaning',
      'letter_maze',
      'language_detective',
      'story_order',
      'reversi_arena',
      'word_wheel',
      'hidden_masses',
      'kakuro',
    }.contains(gameId)) {
      return 20;
    }
    return 10;
  }

  static int nativeLevel(int chapter, {int stages = 10}) =>
      1 +
      (chapter.clamp(1, campaignLevels) - 1) *
          variantsPerChapter ~/
          (minimumUniqueRounds ~/ stages);

  static int variantsForChapter(String gameId, int chapter) {
    if (gameId != 'word_wheel') return variantsPerChapter;
    RangeError.checkValueInInterval(chapter, 1, campaignLevels, 'chapter');
    final int base = wordWheelPoolSize ~/ campaignLevels;
    final int remainder = wordWheelPoolSize % campaignLevels;
    return base + (chapter <= remainder ? 1 : 0);
  }

  static int poolIndexForGame(
    String gameId,
    int chapter,
    int variant, {
    int stages = 10,
  }) {
    if (gameId != 'word_wheel') {
      return poolIndex(chapter, variant, stages: stages);
    }
    RangeError.checkValueInInterval(chapter, 1, campaignLevels, 'chapter');
    RangeError.checkValueInInterval(
      variant,
      0,
      variantsForChapter(gameId, chapter) - 1,
      'variant',
    );
    final int base = wordWheelPoolSize ~/ campaignLevels;
    final int remainder = wordWheelPoolSize % campaignLevels;
    final int preceding = (chapter - 1) * base +
        (chapter - 1 < remainder ? chapter - 1 : remainder);
    return preceding + variant + 1;
  }

  /// A bijection: 30 chapters × 10 variants address all 300 native entries
  /// exactly once. Adjacent chapters never regress to an earlier template.
  static int poolIndex(int chapter, int variant, {int stages = 10}) {
    RangeError.checkValueInInterval(chapter, 1, campaignLevels, 'chapter');
    RangeError.checkValueInInterval(
      variant,
      0,
      variantsPerChapter - 1,
      'variant',
    );
    if (minimumUniqueRounds % stages != 0) throw ArgumentError.value(stages);
    final int slot = (chapter - 1) * variantsPerChapter + variant;
    final int copies = minimumUniqueRounds ~/ stages;
    return (slot % copies) * stages + slot ~/ copies + 1;
  }

  static int safeUnlocked(int stored, List<int> stars) {
    if (stored <= campaignLevels) return stored.clamp(1, campaignLevels);
    int unlocked = 1;
    while (unlocked < campaignLevels &&
        unlocked <= stars.length &&
        stars[unlocked - 1] > 0) {
      unlocked++;
    }
    return unlocked;
  }

  static String difficulty(int chapter, {bool english = false}) {
    final int band = ((chapter - 1) ~/ 6).clamp(0, 4);
    return (english
        ? const ['FOUNDATION', 'DEVELOPING', 'ADVANCED', 'EXPERT', 'MASTER']
        : const ['BAŞLANGIÇ', 'GELİŞİM', 'İLERİ', 'UZMAN', 'USTA'])[band];
  }

  /// Best 20 campaign length per game. Each level is a distinct authored-seed
  /// board; the catalog's 20 games are a separate count from these levels.
  static const int bestSeriesCampaignLevels = 20;

  /// Legacy depth threshold retained for the wider studio-game catalog.
  static const int minimumUniqueRounds = 300;
}
