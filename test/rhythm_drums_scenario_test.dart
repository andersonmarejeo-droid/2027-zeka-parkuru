import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/rhythm_drums/rhythm_drums_scenario.dart';

void main() {
  test('ten sets grow from a count-in to expert syncopation and holds', () {
    final List<RhythmDrumsScenario> levels = List<RhythmDrumsScenario>.generate(
      RhythmDrumsScenario.campaignLevels,
      (int index) => RhythmDrumsScenario.forLevel(index + 1),
    );

    expect(
      levels.map((RhythmDrumsScenario set) => set.level),
      orderedEquals(List<int>.generate(10, (int index) => index + 1)),
    );
    expect(
      levels.map((RhythmDrumsScenario set) => set.bpm),
      orderedEquals(<int>[76, 81, 86, 91, 96, 101, 106, 111, 120, 125]),
    );
    expect(levels.first.notes.length, greaterThanOrEqualTo(8));
    expect(levels[5].silentBars, hasLength(1));
    expect(levels[8].silentBars, hasLength(2));
    expect(
      levels[6].notes.any((RhythmNote note) => note.beat != note.beat.round()),
      isTrue,
      reason: 'advanced charts should use sixteenth-note syncopation',
    );
    expect(
      levels[7].notes.any((RhythmNote note) => note.kind == DrumNoteKind.hold),
      isTrue,
    );
    expect(
      levels[9].perfectWindowSeconds,
      lessThan(levels.first.perfectWindowSeconds),
    );
    expect(levels[9].missLimit, 2);
    for (final RhythmDrumsScenario set in levels) {
      expect(set.notes, isNotEmpty, reason: 'level ${set.level}');
      expect(
        set.notes.every(
          (RhythmNote note) => !set.silentBars.contains(note.beat ~/ 4),
        ),
        isTrue,
        reason: 'level ${set.level} placed a note in a silent bar',
      );
    }
  });

  test(
    'the first 300 practice patterns differ from campaign and each other',
    () {
      final Set<String> signatures = <String>{
        for (
          int level = 1;
          level <= RhythmDrumsScenario.campaignLevels;
          level++
        )
          RhythmDrumsScenario.forLevel(level).signature,
      };
      for (
        int index = 1;
        index <= RhythmDrumsScenario.practicePatterns;
        index++
      ) {
        final RhythmDrumsScenario pattern =
            RhythmDrumsScenario.forPracticePattern(index);
        expect(
          signatures.add(pattern.signature),
          isTrue,
          reason: 'practice pattern $index repeats',
        );
        expect(pattern.notes, isNotEmpty);
      }
      expect(signatures, hasLength(310));
    },
  );

  test('campaign and practice indexes reject values outside their limits', () {
    expect(() => RhythmDrumsScenario.forLevel(0), throwsRangeError);
    expect(() => RhythmDrumsScenario.forLevel(11), throwsRangeError);
    expect(() => RhythmDrumsScenario.forPracticePattern(0), throwsRangeError);
    expect(() => RhythmDrumsScenario.forPracticePattern(301), throwsRangeError);
  });
}
