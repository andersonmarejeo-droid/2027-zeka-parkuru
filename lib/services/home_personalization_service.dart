import '../games/shared/studio_game_contracts.dart';
import '../features/catalog/domain/studio_game_catalog.dart';
import 'onboarding_preference_service.dart';

class HomeGameRecommendation {
  const HomeGameRecommendation({
    required this.gameId,
    required this.reasonTr,
    required this.reasonEn,
  });

  final String gameId;
  final String reasonTr;
  final String reasonEn;

  String reason({required bool isEnglish}) => isEnglish ? reasonEn : reasonTr;
}

/// Produces a device-only recommendation without changing progression or score.
class HomePersonalizationService {
  const HomePersonalizationService();

  static const Map<String, int> _campaignLevelCounts = <String, int>{
    'kakuro': 20,
    'reversi_arena': 20,
    'picross_master': 20,
    'tavla_master': 20,
    'arrow_route': 20,
    'mini_chess_tactics': 20,
    'loop_master': 20,
    'go_life_death': 20,
    'code_breaker': 20,
    'shogi_mate': 20,
    'island_sea': 20,
    'peg_solitaire': 20,
    'futoshiki': 20,
    'hex_connection': 20,
    'skyscrapers': 20,
    'hitori': 20,
    // Retained as a legacy progress scale; retired games are not recommended.
    'ball_merge': 10,
    'mini_golf_route': 10,
    'slide_sweets': 10,
    'neon_pinball': 10,
    'drift_league': 10,
    'air_hockey_arena': 10,
    'lighthouse_defense': 10,
    'boardwalk_builder': 10,
    'secret_room_party': 10,
    'deckforge_duel': 10,
    'meaning_match': 20,
    'proverb_finish': 20,
    'sentence_builder': 20,
    'near_meaning': 20,
    'letter_maze': 20,
    'language_detective': 20,
    'story_order': 20,
    'card_pairs': 20,
    'focus_filter': 20,
    'rhythm_memory': 20,
    'attention_tunnel': 20,
    'city_atlas': 10,
    'world_atlas': 10,
    'katamino_workshop': 10,
    'single_stroke': 10,
    'arrow_maze': 10,
    'bubble_shooter': 10,
  };

  static const List<String> allGameIds = <String>[
    'numbers',
    'blocks',
    'memory',
    'card_pairs',
    'focus_filter',
    'rhythm_memory',
    'attention_tunnel',
    'hanoi',
    'word_hunt',
    'meaning_match',
    'proverb_finish',
    'sentence_builder',
    'near_meaning',
    'letter_maze',
    'language_detective',
    'story_order',
    'picture_iq',
    'number_sort',
    'shape_puzzle',
    'reflex',
    'hidden_masses',
    'kakuro',
    'reversi_arena',
    'picross_master',
    'arrow_route',
    'mini_chess_tactics',
    'island_sea',
    'futoshiki',
    'skyscrapers',
    'hitori',
    'slide_sweets',
    'city_atlas',
    'world_atlas',
    'katamino_workshop',
    'single_stroke',
    'arrow_maze',
  ];

  HomeGameRecommendation recommend({
    required OnboardingPreferences? preferences,
    required Map<String, int> unlockedLevels,
    required Map<String, int> earnedStars,
  }) {
    final PlayerGameGoal? goal = preferences?.gameGoal;
    final PlayerAgeGroup? age = preferences?.ageGroup;
    final List<String> primaryCandidates = _goalCandidates(goal);
    final List<String> secondaryCandidates = _ageCandidates(age);

    final List<String> candidates = _recommendationPool(
      primaryCandidates: primaryCandidates,
      secondaryCandidates: secondaryCandidates,
      unlockedLevels: unlockedLevels,
      earnedStars: earnedStars,
    );
    final Map<String, int> preferenceOrder = <String, int>{
      for (int index = 0; index < candidates.length; index++)
        candidates[index]: index,
    };

    candidates.sort((String left, String right) {
      final int leftScore = _progressScore(
        left,
        unlockedLevels: unlockedLevels,
        earnedStars: earnedStars,
      );
      final int rightScore = _progressScore(
        right,
        unlockedLevels: unlockedLevels,
        earnedStars: earnedStars,
      );
      final int comparison = leftScore.compareTo(rightScore);
      if (comparison != 0) return comparison;
      return (preferenceOrder[left] ?? 99).compareTo(
        preferenceOrder[right] ?? 99,
      );
    });

    return HomeGameRecommendation(
      gameId: candidates.first,
      reasonTr: _reasonTr(goal, age),
      reasonEn: _reasonEn(goal, age),
    );
  }

  List<String> _recommendationPool({
    required List<String> primaryCandidates,
    required List<String> secondaryCandidates,
    required Map<String, int> unlockedLevels,
    required Map<String, int> earnedStars,
  }) {
    bool isAvailable(String gameId) =>
        StudioGameCatalog.byId(gameId)?.isPlayable ?? true;

    bool isIncomplete(String gameId) {
      final int levelCount = GameContentPolicy.standardGames.contains(gameId)
          ? GameContentPolicy.campaignLevels
          : (_campaignLevelCounts[gameId] ?? 10);
      return (unlockedLevels[gameId] ?? 1) < levelCount ||
          (earnedStars[gameId] ?? 0) < levelCount * 3;
    }

    final List<String> primary = primaryCandidates
        .where((String gameId) => isAvailable(gameId) && isIncomplete(gameId))
        .toList(growable: false);
    if (primary.isNotEmpty) return primary;

    final List<String> secondary = secondaryCandidates
        .where((String gameId) => isAvailable(gameId) && isIncomplete(gameId))
        .toList(growable: false);
    if (secondary.isNotEmpty) return secondary;

    final List<String> remaining = allGameIds
        .where((String gameId) => isAvailable(gameId) && isIncomplete(gameId))
        .toList(growable: false);
    return remaining.isEmpty
        ? allGameIds.where(isAvailable).toList(growable: false)
        : remaining;
  }

  int _progressScore(
    String gameId, {
    required Map<String, int> unlockedLevels,
    required Map<String, int> earnedStars,
  }) {
    final int levelCount = GameContentPolicy.standardGames.contains(gameId)
        ? GameContentPolicy.campaignLevels
        : (_campaignLevelCounts[gameId] ?? 10);
    final int stars = (earnedStars[gameId] ?? 0)
        .clamp(0, levelCount * 3)
        .toInt();
    final int level = (unlockedLevels[gameId] ?? 1)
        .clamp(1, levelCount)
        .toInt();
    final int levelScore = levelCount == 1
        ? 100
        : 10 + (level - 1) * 90 ~/ (levelCount - 1);
    return stars * 3000 ~/ (levelCount * 3) + levelScore;
  }

  List<String> _goalCandidates(PlayerGameGoal? goal) => switch (goal) {
    PlayerGameGoal.haveFun => const <String>[
      'word_hunt',
      'reflex',
      'slide_sweets',
    ],
    PlayerGameGoal.improveMind => const <String>[
      'hidden_masses',
      'kakuro',
      'reversi_arena',
      'picross_master',
      'arrow_route',
      'mini_chess_tactics',
      'island_sea',
      'futoshiki',
      'skyscrapers',
      'hitori',
      'numbers',
      'hanoi',
      'meaning_match',
      'proverb_finish',
      'sentence_builder',
      'near_meaning',
      'letter_maze',
      'language_detective',
      'story_order',
      'card_pairs',
      'focus_filter',
      'rhythm_memory',
      'attention_tunnel',
      'city_atlas',
      'world_atlas',
      'katamino_workshop',
      'single_stroke',
      'arrow_maze',
    ],
    PlayerGameGoal.dailyExercise => const <String>[
      'memory',
      'card_pairs',
      'focus_filter',
      'rhythm_memory',
      'attention_tunnel',
      'shape_puzzle',
      'number_sort',
    ],
    PlayerGameGoal.competeWithFriends => const <String>[
      'reflex',
      'blocks',
      'reversi_arena',
      'picross_master',
      'arrow_route',
      'mini_chess_tactics',
      'island_sea',
      'futoshiki',
      'skyscrapers',
      'hitori',
    ],
    null => const <String>['memory', 'numbers'],
  };

  List<String> _ageCandidates(PlayerAgeGroup? age) => switch (age) {
    PlayerAgeGroup.age6To8 => const <String>['memory', 'shape_puzzle'],
    PlayerAgeGroup.age9To12 => const <String>[
      'blocks',
      'word_hunt',
      'picture_iq',
    ],
    PlayerAgeGroup.age13To17 => const <String>[
      'hidden_masses',
      'kakuro',
      'reversi_arena',
      'picross_master',
      'arrow_route',
      'mini_chess_tactics',
      'island_sea',
      'futoshiki',
      'skyscrapers',
      'hitori',
      'numbers',
      'reflex',
      'city_atlas',
      'world_atlas',
      'katamino_workshop',
      'single_stroke',
      'arrow_maze',
    ],
    PlayerAgeGroup.age18To40 || PlayerAgeGroup.age40Plus => const <String>[
      'hidden_masses',
      'kakuro',
      'reversi_arena',
      'hanoi',
      'number_sort',
      'city_atlas',
      'world_atlas',
      'katamino_workshop',
      'single_stroke',
      'arrow_maze',
    ],
    PlayerAgeGroup.preferNotToSay || null => const <String>[],
  };

  String _reasonTr(PlayerGameGoal? goal, PlayerAgeGroup? age) {
    final String base = switch (goal) {
      PlayerGameGoal.haveFun => 'Eğlence hedefin için seçildi',
      PlayerGameGoal.improveMind => 'Zihin gelişimi hedefin için seçildi',
      PlayerGameGoal.dailyExercise => 'Günlük egzersiz hedefin için seçildi',
      PlayerGameGoal.competeWithFriends => 'Rekabet hedefin için seçildi',
      null => 'İlerlemeni dengelemek için seçildi',
    };
    return age == null || age == PlayerAgeGroup.preferNotToSay
        ? base
        : '$base • yaş grubuna uygun';
  }

  String _reasonEn(PlayerGameGoal? goal, PlayerAgeGroup? age) {
    final String base = switch (goal) {
      PlayerGameGoal.haveFun => 'Selected for your fun goal',
      PlayerGameGoal.improveMind => 'Selected for your mind-training goal',
      PlayerGameGoal.dailyExercise => 'Selected for your daily exercise goal',
      PlayerGameGoal.competeWithFriends => 'Selected for your competition goal',
      null => 'Selected to balance your progress',
    };
    return age == null || age == PlayerAgeGroup.preferNotToSay
        ? base
        : '$base • matched to your age group';
  }
}
