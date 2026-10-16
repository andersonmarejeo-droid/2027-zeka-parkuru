import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/rhythm_drums/rhythm_drums_engine.dart';
import 'package:zeka_parkuru/games/rhythm_drums/rhythm_drums_scenario.dart';

RhythmDrumsScenario _scenario({
  required List<RhythmNote> notes,
  int missLimit = 3,
}) => RhythmDrumsScenario(
  level: 1,
  seed: 7,
  bpm: 120,
  totalBeats: 4,
  notes: notes,
  silentBars: const <int>{},
  missLimit: missLimit,
  perfectWindowFraction: .2,
  goodWindowFraction: .4,
  goldAccuracy: .95,
);

void _advanceTo(RhythmDrumsEngine engine, double target) {
  while (engine.elapsed < target && !engine.failed) {
    engine.step((target - engine.elapsed).clamp(0, .024).toDouble());
  }
}

void main() {
  test('perfect and good windows are distinct and score in the right band', () {
    final RhythmDrumsEngine perfect = RhythmDrumsEngine(
      scenario: _scenario(
        notes: const <RhythmNote>[
          RhythmNote(beat: 1, lane: DrumLane.kick, kind: DrumNoteKind.tap),
        ],
      ),
    );
    _advanceTo(perfect, .5);
    expect(perfect.hitLane(DrumLane.kick).quality, RhythmHitQuality.perfect);
    expect(perfect.score, 100);
    expect(perfect.combo, 1);

    final RhythmDrumsEngine good = RhythmDrumsEngine(
      scenario: _scenario(
        notes: const <RhythmNote>[
          RhythmNote(beat: 1, lane: DrumLane.snare, kind: DrumNoteKind.accent),
        ],
      ),
    );
    _advanceTo(good, .64);
    expect(good.hitLane(DrumLane.snare).quality, RhythmHitQuality.good);
    expect(good.score, 88);
    expect(good.accuracy, 1);
  });

  test('wrong lane and offbeat taps consume the bounded mistake budget', () {
    final RhythmDrumsEngine engine = RhythmDrumsEngine(
      scenario: _scenario(
        notes: const <RhythmNote>[
          RhythmNote(beat: 1, lane: DrumLane.kick, kind: DrumNoteKind.tap),
        ],
        missLimit: 1,
      ),
    );
    _advanceTo(engine, .5);
    expect(engine.hitLane(DrumLane.snare).quality, RhythmHitQuality.wrongLane);
    expect(engine.combo, 0);
    expect(engine.misses, 1);
    expect(engine.failed, isFalse);
    expect(engine.hitLane(DrumLane.kick).quality, RhythmHitQuality.missed);
    expect(engine.offbeats, 2);
    expect(engine.failed, isTrue);
  });

  test('held note scores only after an accurate press and release', () {
    final RhythmDrumsEngine engine = RhythmDrumsEngine(
      scenario: _scenario(
        notes: const <RhythmNote>[
          RhythmNote(
            beat: 1,
            lane: DrumLane.tom,
            kind: DrumNoteKind.hold,
            holdBeats: 1,
          ),
        ],
      ),
    );
    _advanceTo(engine, .5);
    expect(engine.hitLane(DrumLane.tom).quality, RhythmHitQuality.holdStarted);
    expect(engine.holding, isTrue);
    expect(engine.accuracy, 0);
    _advanceTo(engine, 1);
    expect(engine.releaseLane(DrumLane.tom).quality, RhythmHitQuality.perfect);
    expect(engine.holding, isFalse);
    expect(engine.score, 125);
    expect(engine.bestCombo, 1);
  });

  test('unplayed notes expire once and resolve a clean set at the end', () {
    final RhythmDrumsEngine engine = RhythmDrumsEngine(
      scenario: _scenario(
        notes: const <RhythmNote>[
          RhythmNote(beat: 1, lane: DrumLane.hiHat, kind: DrumNoteKind.tap),
        ],
        missLimit: 1,
      ),
    );
    _advanceTo(engine, .72);
    expect(engine.misses, 1);
    expect(engine.states.single, RhythmNoteState.missed);
    _advanceTo(engine, engine.scenario.durationSeconds);
    expect(engine.completed, isTrue);
    expect(engine.failed, isFalse);
  });

  test('a precise player can finish every seeded campaign chart', () {
    for (int level = 1; level <= RhythmDrumsScenario.campaignLevels; level++) {
      final RhythmDrumsScenario scenario = RhythmDrumsScenario.forLevel(level);
      final RhythmDrumsEngine engine = RhythmDrumsEngine(scenario: scenario);
      for (int noteIndex = 0; noteIndex < scenario.notes.length; noteIndex++) {
        final RhythmNote note = scenario.notes[noteIndex];
        _advanceTo(engine, note.beat * scenario.secondsPerBeat);
        expect(
          engine.failed,
          isFalse,
          reason: 'level $level failed before note $noteIndex at ${note.beat}',
        );
        final RhythmInputResult start = engine.hitLane(note.lane);
        if (note.kind == DrumNoteKind.hold) {
          expect(start.quality, RhythmHitQuality.holdStarted);
          _advanceTo(
            engine,
            (note.beat + note.holdBeats) * scenario.secondsPerBeat,
          );
          expect(
            engine.releaseLane(note.lane).quality,
            isNot(RhythmHitQuality.missed),
          );
        } else {
          expect(
            start.quality,
            anyOf(RhythmHitQuality.perfect, RhythmHitQuality.good),
          );
        }
      }
      _advanceTo(engine, scenario.durationSeconds);
      expect(
        engine.completed,
        isTrue,
        reason:
            'level $level did not resolve: elapsed ${engine.elapsed}, duration ${scenario.durationSeconds}, misses ${engine.misses}, failed ${engine.failed}, unresolved ${engine.states.where((RhythmNoteState state) => state != RhythmNoteState.hit && state != RhythmNoteState.missed).length}',
      );
      expect(engine.failed, isFalse, reason: 'level $level failed');
      expect(engine.misses, 0, reason: 'level $level had hidden misses');
      expect(engine.accuracy, 1, reason: 'level $level lost valid hits');
    }
  });

  test('pausing during a sustain releases the pad without a miss', () {
    final RhythmDrumsEngine engine = RhythmDrumsEngine(
      scenario: _scenario(
        notes: const <RhythmNote>[
          RhythmNote(
            beat: 1,
            lane: DrumLane.tom,
            kind: DrumNoteKind.hold,
            holdBeats: 1,
          ),
        ],
      ),
    );
    _advanceTo(engine, .5);
    engine.hitLane(DrumLane.tom);
    engine.interruptHold();
    expect(engine.holding, isFalse);
    expect(engine.misses, 0);
    expect(engine.states.single, RhythmNoteState.pending);
  });
}
