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

  static const List<String> allGameIds = <String>[
    'logic',
    'numbers',
    'blocks',
    'memory',
    'hanoi',
    'word_hunt',
    'picture_iq',
    'candy_sort',
    'number_sort',
    'shape_puzzle',
    'reflex',
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
    bool isIncomplete(String gameId) {
      return (unlockedLevels[gameId] ?? 1) < 10 ||
          (earnedStars[gameId] ?? 0) < 30;
    }

    final List<String> primary = primaryCandidates
        .where(isIncomplete)
        .toList(growable: false);
    if (primary.isNotEmpty) return primary;

    final List<String> secondary = secondaryCandidates
        .where(isIncomplete)
        .toList(growable: false);
    if (secondary.isNotEmpty) return secondary;

    final List<String> remaining = allGameIds
        .where(isIncomplete)
        .toList(growable: false);
    return remaining.isEmpty ? allGameIds.toList() : remaining;
  }

  int _progressScore(
    String gameId, {
    required Map<String, int> unlockedLevels,
    required Map<String, int> earnedStars,
  }) {
    final int stars = (earnedStars[gameId] ?? 0).clamp(0, 30).toInt();
    final int level = (unlockedLevels[gameId] ?? 1).clamp(1, 10).toInt();
    return stars * 100 + level * 10;
  }

  List<String> _goalCandidates(PlayerGameGoal? goal) => switch (goal) {
    PlayerGameGoal.haveFun => const <String>[
      'candy_sort',
      'word_hunt',
      'reflex',
    ],
    PlayerGameGoal.improveMind => const <String>['logic', 'numbers', 'hanoi'],
    PlayerGameGoal.dailyExercise => const <String>[
      'memory',
      'shape_puzzle',
      'number_sort',
    ],
    PlayerGameGoal.competeWithFriends => const <String>[
      'reflex',
      'blocks',
      'logic',
    ],
    null => const <String>['logic', 'memory', 'numbers'],
  };

  List<String> _ageCandidates(PlayerAgeGroup? age) => switch (age) {
    PlayerAgeGroup.age6To8 => const <String>[
      'memory',
      'candy_sort',
      'shape_puzzle',
    ],
    PlayerAgeGroup.age9To12 => const <String>[
      'blocks',
      'word_hunt',
      'picture_iq',
    ],
    PlayerAgeGroup.age13To17 => const <String>['logic', 'numbers', 'reflex'],
    PlayerAgeGroup.age18To40 ||
    PlayerAgeGroup.age40Plus => const <String>['logic', 'hanoi', 'number_sort'],
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
