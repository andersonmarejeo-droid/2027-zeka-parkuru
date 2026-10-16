import 'dart:math' as math;

import '../shared/content_seed.dart';

class RhythmBeat {
  const RhythmBeat({required this.note, required this.accent});

  final int note;
  final bool accent;

  String get signature => '$note:${accent ? 1 : 0}';
}

/// A beat pattern with pitch, accent and deliberate silence intervals.
class RhythmMemoryScenario {
  const RhythmMemoryScenario({
    required this.stage,
    required this.beats,
    required this.gaps,
    required this.reverseRecall,
    required this.baseBeatMs,
    required this.isPractice,
    required this.round,
    required this.variant,
  });

  static const int campaignLevels = 20;
  static const int uniquePracticeRounds = 300;
  static final List<RhythmMemoryScenario> _practiceDeck = _buildPracticeDeck();

  final int stage;
  final List<RhythmBeat> beats;

  /// Inter-onset intervals: 1=short, 2=long, 3=rest.
  final List<int> gaps;
  final bool reverseRecall;
  final int baseBeatMs;
  final bool isPractice;
  final int round;
  final int variant;

  int get length => beats.length;
  int get mistakeLimit => stage <= 3
      ? 5
      : stage <= 6
      ? 4
      : stage <= 10
      ? 3
      : stage <= 16
      ? 2
      : 1;
  List<RhythmBeat> get answer =>
      List<RhythmBeat>.unmodifiable(reverseRecall ? beats.reversed : beats);
  List<int> get answerGaps =>
      List<int>.unmodifiable(reverseRecall ? gaps.reversed : gaps);
  int get accentCount => beats.where((RhythmBeat beat) => beat.accent).length;
  String get difficultyBand => stage <= 3
      ? 'TEMPO'
      : stage <= 6
      ? 'VURUŞ'
      : stage <= 10
      ? 'ARA'
      : stage <= 16
      ? 'TERS'
      : 'USTA';

  String get instruction => reverseRecall
      ? 'Ritmi tersten çal • uzun arayı ve vurguyu koru'
      : 'Notaları, kısa/uzun araları ve vurguyu taklit et';

  String get signature => <String>[
    '$stage:$reverseRecall:$baseBeatMs',
    for (int index = 0; index < beats.length; index++)
      '${beats[index].signature}${index < gaps.length ? '/${gaps[index]}' : ''}',
  ].join('|');

  /// Accepts a small expressive tempo range while still distinguishing short,
  /// long and held silences. Tempo is normalized per attempt, not per device.
  bool accepts({
    required List<int> notes,
    required List<bool> accents,
    required List<int> intervalsMs,
  }) {
    final List<RhythmBeat> expected = answer;
    if (notes.length != expected.length || accents.length != expected.length) {
      return false;
    }
    for (int index = 0; index < expected.length; index++) {
      if (notes[index] != expected[index].note ||
          accents[index] != expected[index].accent) {
        return false;
      }
    }
    if (intervalsMs.length != answerGaps.length ||
        intervalsMs.any((int interval) => interval <= 0)) {
      return false;
    }
    if (intervalsMs.isEmpty) return true;

    final List<double> unitEstimates = <double>[
      for (int index = 0; index < intervalsMs.length; index++)
        intervalsMs[index] / answerGaps[index],
    ]..sort();
    final double tempoUnit = unitEstimates[unitEstimates.length ~/ 2];
    for (int index = 0; index < intervalsMs.length; index++) {
      final double expectedMs = tempoUnit * answerGaps[index];
      if ((intervalsMs[index] - expectedMs).abs() >
          math.max(180, expectedMs * .38)) {
        return false;
      }
    }
    return true;
  }

  static RhythmMemoryScenario forCampaignLevel(int level) {
    if (level < 1 || level > campaignLevels) {
      throw RangeError.range(level, 1, campaignLevels);
    }
    return _build(
      stage: level,
      isPractice: false,
      round: level,
      seed: ContentSeed.forLevel(
        gameId: 'rhythm_memory:campaign',
        level: level,
      ),
      variant: 0,
    );
  }

  static RhythmMemoryScenario forPracticeRound(int round) {
    if (round < 1 || round > uniquePracticeRounds) {
      throw RangeError.range(round, 1, uniquePracticeRounds);
    }
    return _practiceDeck[round - 1];
  }

  static List<RhythmMemoryScenario> _buildPracticeDeck() {
    final Set<String> occupied = <String>{
      for (int level = 1; level <= campaignLevels; level++)
        forCampaignLevel(level).signature,
    };
    final List<RhythmMemoryScenario> deck = <RhythmMemoryScenario>[];
    for (int round = 1; round <= uniquePracticeRounds; round++) {
      final int stage = ((round - 1) % campaignLevels) + 1;
      RhythmMemoryScenario? chosen;
      for (int attempt = 0; attempt < 10000; attempt++) {
        final RhythmMemoryScenario candidate = _build(
          stage: stage,
          isPractice: true,
          round: round,
          seed: ContentSeed.forLevel(
            gameId: 'rhythm_memory:practice:$attempt',
            level: round,
          ),
          variant: attempt,
        );
        if (occupied.add(candidate.signature)) {
          chosen = candidate;
          break;
        }
      }
      if (chosen == null) {
        throw StateError('Could not generate unique rhythm round $round.');
      }
      deck.add(chosen);
    }
    return List<RhythmMemoryScenario>.unmodifiable(deck);
  }

  static RhythmMemoryScenario _build({
    required int stage,
    required bool isPractice,
    required int round,
    required int seed,
    required int variant,
  }) {
    final math.Random random = math.Random(seed);
    final int length = switch (stage) {
      <= 2 => 3,
      <= 4 => 4,
      <= 6 => 5,
      <= 9 => 6,
      10 => 7,
      <= 13 => 7,
      <= 16 => 8,
      <= 18 => 9,
      19 => 10,
      _ => 11,
    };
    final int noteRange = stage <= 3
        ? 3
        : stage <= 6
        ? 4
        : stage <= 10
        ? 5
        : stage <= 16
        ? 6
        : 8;
    final int maxGap = stage <= 3
        ? 1
        : stage <= 6
        ? 2
        : stage <= 10
        ? 3
        : stage <= 16
        ? 3
        : 4;
    final List<RhythmBeat> beats = <RhythmBeat>[];
    for (int index = 0; index < length; index++) {
      final int note = random.nextInt(noteRange);
      final bool accent =
          stage >= 7 &&
          ((index + random.nextInt(3) + variant) % (stage >= 17 ? 2 : 3) == 0);
      beats.add(RhythmBeat(note: note, accent: accent));
    }
    if (stage >= 7 && beats.every((RhythmBeat beat) => !beat.accent)) {
      final int accentIndex = length ~/ 2;
      beats[accentIndex] = RhythmBeat(
        note: beats[accentIndex].note,
        accent: true,
      );
    }
    final List<int> gaps = List<int>.generate(length - 1, (int index) {
      if (maxGap == 1) return 1;
      int gap = random.nextInt(maxGap) + 1;
      if (stage >= 17 && (index + variant) % 4 == 3) gap = 4;
      return gap;
    }, growable: false);
    return RhythmMemoryScenario(
      stage: stage,
      beats: List<RhythmBeat>.unmodifiable(beats),
      gaps: List<int>.unmodifiable(gaps),
      reverseRecall: stage >= 11,
      baseBeatMs: stage <= 6
          ? 500
          : stage <= 10
          ? 400
          : stage <= 16
          ? 330
          : 280,
      isPractice: isPractice,
      round: round,
      variant: variant,
    );
  }
}
