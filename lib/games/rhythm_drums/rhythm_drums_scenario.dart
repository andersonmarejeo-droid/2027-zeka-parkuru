import 'dart:math' as math;

import '../shared/content_seed.dart';

enum DrumLane { kick, snare, hiHat, tom }

enum DrumNoteKind { tap, accent, hold }

class RhythmNote {
  const RhythmNote({
    required this.beat,
    required this.lane,
    required this.kind,
    this.holdBeats = 0,
  });

  final double beat;
  final DrumLane lane;
  final DrumNoteKind kind;
  final double holdBeats;

  String get signature =>
      '${beat.toStringAsFixed(2)}:${lane.index}:${kind.index}:'
      '${holdBeats.toStringAsFixed(2)}';
}

class RhythmDrumsScenario {
  const RhythmDrumsScenario({
    required this.level,
    required this.seed,
    required this.bpm,
    required this.totalBeats,
    required this.notes,
    required this.silentBars,
    required this.missLimit,
    required this.perfectWindowFraction,
    required this.goodWindowFraction,
    required this.goldAccuracy,
  });

  static const int campaignLevels = 10;
  static const int practicePatterns = 300;

  final int level;
  final int seed;
  final int bpm;
  final int totalBeats;
  final List<RhythmNote> notes;
  final Set<int> silentBars;
  final int missLimit;
  final double perfectWindowFraction;
  final double goodWindowFraction;
  final double goldAccuracy;

  double get secondsPerBeat => 60 / bpm;
  double get perfectWindowSeconds => secondsPerBeat * perfectWindowFraction;
  double get goodWindowSeconds => secondsPerBeat * goodWindowFraction;
  double get durationSeconds =>
      notes.fold<double>(
        (totalBeats + 1).toDouble(),
        (double latestEnd, RhythmNote note) =>
            math.max(latestEnd, note.beat + note.holdBeats + 1),
      ) *
      secondsPerBeat;

  String get signature =>
      '$level|$bpm|$totalBeats|${notes.map((RhythmNote note) => note.signature).join(';')}|'
      '${_sortedSilentBars.join(',')}|$missLimit';

  List<int> get _sortedSilentBars => silentBars.toList()..sort();

  static RhythmDrumsScenario forLevel(int level) {
    final int normalized = RangeError.checkValueInInterval(
      level,
      1,
      campaignLevels,
      'level',
    );
    return _create(
      normalized,
      ContentSeed.forLevel(gameId: 'rhythm_drums', level: normalized),
    );
  }

  static RhythmDrumsScenario forPracticePattern(int index) {
    final int normalized = RangeError.checkValueInInterval(
      index,
      1,
      practicePatterns,
      'index',
    );
    return _create(
      1 + ((normalized - 1) % campaignLevels),
      ContentSeed.forLevel(gameId: 'rhythm_drums_practice', level: normalized),
    );
  }

  static RhythmDrumsScenario _create(int level, int seed) {
    final math.Random random = math.Random(seed);
    final int bars = 3 + (level - 1) ~/ 2;
    final int totalBeats = bars * 4;
    final int bpm = 76 + (level - 1) * 5 + (level >= 9 ? 4 : 0);
    final int desiredNotes = 12 + level * 2;
    final Set<int> silentBars = <int>{};
    if (level >= 6) {
      silentBars.add(1 + random.nextInt(bars - 1));
      if (level >= 9 && bars >= 5) {
        int next;
        do {
          next = 1 + random.nextInt(bars - 1);
        } while (silentBars.contains(next));
        silentBars.add(next);
      }
    }

    final List<double> candidates = <double>[];
    final int ticksPerBeat = level >= 7
        ? 4
        : level >= 4
        ? 2
        : 1;
    // Leave one beat for the count-in. Starting from tick 8 accidentally
    // removed the opening half of every short campaign chart.
    for (int tick = ticksPerBeat; tick < totalBeats * ticksPerBeat; tick++) {
      final double beat = tick / ticksPerBeat;
      if (silentBars.contains((beat ~/ 4))) continue;
      if (level >= 7 && random.nextDouble() < .22) continue;
      candidates.add(beat);
    }
    candidates.shuffle(random);
    candidates.sort();
    final List<RhythmNote> notes = <RhythmNote>[];
    for (final double beat in candidates) {
      if (notes.length >= desiredNotes) break;
      if (notes.any(
        (RhythmNote note) =>
            beat - note.beat < math.max(.42, note.holdBeats + .2),
      )) {
        continue;
      }
      final DrumLane lane =
          DrumLane.values[random.nextInt(DrumLane.values.length)];
      final DrumNoteKind kind = level >= 4 && random.nextDouble() < .22
          ? (level >= 8 && random.nextDouble() < .58
                ? DrumNoteKind.hold
                : DrumNoteKind.accent)
          : DrumNoteKind.tap;
      final double hold = kind == DrumNoteKind.hold
          ? (level >= 9 ? 1.5 : 1.0)
          : 0;
      notes.add(
        RhythmNote(beat: beat, lane: lane, kind: kind, holdBeats: hold),
      );
    }
    notes.sort((RhythmNote a, RhythmNote b) => a.beat.compareTo(b.beat));

    return RhythmDrumsScenario(
      level: level,
      seed: seed,
      bpm: bpm,
      totalBeats: totalBeats,
      notes: List<RhythmNote>.unmodifiable(notes),
      silentBars: Set<int>.unmodifiable(silentBars),
      missLimit: level >= 10
          ? 2
          : level >= 8
          ? 3
          : level >= 5
          ? 4
          : 6,
      perfectWindowFraction: .22 - level * .012,
      goodWindowFraction: .40 - level * .018,
      goldAccuracy: .97 - (level - 1) * .004,
    );
  }
}
