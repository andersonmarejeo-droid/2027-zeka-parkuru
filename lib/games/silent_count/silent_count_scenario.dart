import 'dart:math' as math;

import '../shared/content_seed.dart';

class SilentCountEvent {
  const SilentCountEvent({
    required this.category,
    required this.enters,
    required this.reversed,
  });

  final int category;

  /// The arrow shown on the event card. When the gate is reversed its effect
  /// is the opposite, so the player must retain both the event and rule state.
  final bool enters;
  final bool reversed;

  bool get adds => enters != reversed;

  String get signature => '$category:${enters ? 1 : 0}:${reversed ? 1 : 0}';
}

/// A visual inventory-tracking challenge with a changing entry/exit gate.
/// The event history disappears as the player advances; only the initial
/// inventory remains, so the final audit depends on maintaining hidden counts.
class SilentCountScenario {
  const SilentCountScenario({
    required this.stage,
    required this.initialCounts,
    required this.events,
    required this.ruleChangeBeforeEvent,
    required this.queryOrder,
    required this.finalCounts,
    required this.isPractice,
    required this.round,
    required this.variant,
  });

  static const int campaignLevels = 20;
  static const int uniquePracticeRounds = 300;
  static const int maxCount = 9;
  static final List<SilentCountScenario> _practiceDeck = _buildPracticeDeck();

  final int stage;
  final List<int> initialCounts;
  final List<SilentCountEvent> events;
  final List<int> ruleChangeBeforeEvent;
  final List<int> queryOrder;
  final List<int> finalCounts;
  final bool isPractice;
  final int round;
  final int variant;

  int get categoryCount => initialCounts.length;
  int get eventCount => events.length;
  int get ruleChangeCount => ruleChangeBeforeEvent.length;
  int get mistakeLimit => stage <= 3
      ? 4
      : stage <= 6
      ? 3
      : stage <= 10
      ? 2
      : 1;

  String get signature => <String>[
    '$stage:$categoryCount:$eventCount:${ruleChangeBeforeEvent.join(',')}',
    'I:${initialCounts.join(',')}',
    'E:${events.map((SilentCountEvent event) => event.signature).join(',')}',
    'Q:${queryOrder.join(',')}',
  ].join('|');

  int get netChangeTotal => List<int>.generate(categoryCount, (int index) {
    return finalCounts[index] - initialCounts[index];
  }).fold<int>(0, (int total, int value) => total + value);

  int netChangeFor(int category) =>
      finalCounts[category] - initialCounts[category];

  static SilentCountScenario forCampaignLevel(int level) {
    if (level < 1 || level > campaignLevels) {
      throw RangeError.range(level, 1, campaignLevels);
    }
    return _build(
      stage: level,
      isPractice: false,
      round: level,
      variant: 0,
      seed: ContentSeed.forLevel(gameId: 'silent_count:campaign', level: level),
    );
  }

  static SilentCountScenario forPracticeRound(int round) {
    if (round < 1 || round > uniquePracticeRounds) {
      throw RangeError.range(round, 1, uniquePracticeRounds);
    }
    return _practiceDeck[round - 1];
  }

  static List<SilentCountScenario> _buildPracticeDeck() {
    final Set<String> occupied = <String>{
      for (int level = 1; level <= campaignLevels; level++)
        forCampaignLevel(level).signature,
    };
    final List<SilentCountScenario> deck = <SilentCountScenario>[];
    for (int round = 1; round <= uniquePracticeRounds; round++) {
      final int stage = ((round - 1) % campaignLevels) + 1;
      SilentCountScenario? chosen;
      for (int attempt = 0; attempt < 20000; attempt++) {
        final SilentCountScenario candidate = _build(
          stage: stage,
          isPractice: true,
          round: round,
          variant: attempt,
          seed: ContentSeed.forLevel(
            gameId: 'silent_count:practice:$attempt',
            level: round,
          ),
        );
        if (occupied.add(candidate.signature)) {
          chosen = candidate;
          break;
        }
      }
      if (chosen == null) {
        throw StateError(
          'Could not generate unique silent count round $round.',
        );
      }
      deck.add(chosen);
    }
    return List<SilentCountScenario>.unmodifiable(deck);
  }

  static SilentCountScenario _build({
    required int stage,
    required bool isPractice,
    required int round,
    required int variant,
    required int seed,
  }) {
    final math.Random random = math.Random(seed);
    final int categories = switch (stage) {
      <= 2 => 2,
      <= 6 => 3,
      <= 10 => 4,
      <= 16 => 4,
      _ => 5,
    };
    final int eventCount = switch (stage) {
      <= 2 => 7,
      <= 4 => 8,
      <= 6 => 9,
      7 => 11,
      8 => 12,
      9 => 13,
      10 => 14,
      <= 13 => 15,
      <= 16 => 17,
      17 => 17,
      18 => 18,
      19 => 19,
      _ => 20,
    };
    final List<int> ruleChanges = _ruleChangesFor(stage, eventCount);
    final List<int> initial = List<int>.generate(
      categories,
      (int _) => 1 + random.nextInt(3),
      growable: false,
    );
    final List<int> counts = List<int>.of(initial);
    final List<SilentCountEvent> events = <SilentCountEvent>[];
    bool reversed = false;

    for (int index = 0; index < eventCount; index++) {
      if (ruleChanges.contains(index)) reversed = !reversed;
      final List<(int, bool)> validMoves = <(int, bool)>[
        for (
          int category = 0;
          category < categories;
          category++
        ) ...<(int, bool)>[
          if (counts[category] < maxCount)
            (category, !reversed), // Entry arrow applies +1 under this gate.
          if (counts[category] > 0)
            (category, reversed), // Exit arrow applies -1 under this gate.
        ],
      ];
      final (int category, bool enters) =
          validMoves[random.nextInt(validMoves.length)];
      final SilentCountEvent event = SilentCountEvent(
        category: category,
        enters: enters,
        reversed: reversed,
      );
      counts[category] += event.adds ? 1 : -1;
      events.add(event);
    }

    final List<int> queryOrder = List<int>.generate(
      categories,
      (int index) => index,
    )..shuffle(random);

    return SilentCountScenario(
      stage: stage,
      initialCounts: List<int>.unmodifiable(initial),
      events: List<SilentCountEvent>.unmodifiable(events),
      ruleChangeBeforeEvent: List<int>.unmodifiable(ruleChanges),
      queryOrder: List<int>.unmodifiable(queryOrder),
      finalCounts: List<int>.unmodifiable(counts),
      isPractice: isPractice,
      round: round,
      variant: variant,
    );
  }

  static List<int> _ruleChangesFor(int stage, int eventCount) {
    if (stage <= 6) return const <int>[];
    if (stage <= 12) return <int>[eventCount ~/ 2];
    if (stage <= 19) {
      return <int>[eventCount ~/ 3, (eventCount * 2) ~/ 3];
    }
    return <int>[eventCount ~/ 4, eventCount ~/ 2, (eventCount * 3) ~/ 4];
  }
}
