import 'dart:math' as math;

import 'rhythm_drums_scenario.dart';

enum RhythmNoteState { pending, holding, hit, missed }

enum RhythmHitQuality { none, perfect, good, holdStarted, missed, wrongLane }

class RhythmInputResult {
  const RhythmInputResult({
    this.quality = RhythmHitQuality.none,
    this.noteIndex,
    this.completed = false,
    this.failed = false,
  });

  final RhythmHitQuality quality;
  final int? noteIndex;
  final bool completed;
  final bool failed;
}

class RhythmStepResult {
  const RhythmStepResult({
    this.missed = 0,
    this.completed = false,
    this.failed = false,
  });

  final int missed;
  final bool completed;
  final bool failed;
}

/// Deterministic lane/timing/hold judgement, independent of audio latency.
class RhythmDrumsEngine {
  RhythmDrumsEngine({required this.scenario})
    : _states = List<RhythmNoteState>.filled(
        scenario.notes.length,
        RhythmNoteState.pending,
        growable: false,
      );

  final RhythmDrumsScenario scenario;
  final List<RhythmNoteState> _states;
  double elapsed = 0;
  int score = 0;
  int misses = 0;
  int perfectHits = 0;
  int goodHits = 0;
  int offbeats = 0;
  int combo = 0;
  int bestCombo = 0;
  int _activeHold = -1;
  double _holdStartTiming = 0;
  bool completed = false;
  bool failed = false;

  List<RhythmNoteState> get states =>
      List<RhythmNoteState>.unmodifiable(_states);
  double get accuracy =>
      (perfectHits + goodHits) / math.max(1, scenario.notes.length);
  double get beatPosition => elapsed / scenario.secondsPerBeat;
  int get currentBar => (beatPosition ~/ 4) + 1;
  bool get holding => _activeHold >= 0;

  RhythmInputResult hitLane(DrumLane lane) {
    if (completed || failed) return const RhythmInputResult();
    final List<int> candidates = <int>[];
    for (int index = 0; index < scenario.notes.length; index++) {
      if (_states[index] != RhythmNoteState.pending) continue;
      final RhythmNote note = scenario.notes[index];
      if (note.kind == DrumNoteKind.hold && _activeHold >= 0) continue;
      final double delta = elapsed - _timeFor(note);
      if (delta.abs() <= scenario.goodWindowSeconds) candidates.add(index);
    }
    if (candidates.isEmpty) {
      offbeats++;
      _recordMiss();
      return RhythmInputResult(
        quality: RhythmHitQuality.missed,
        failed: failed,
      );
    }
    candidates.sort(
      (int a, int b) => (_timeFor(scenario.notes[a]) - elapsed).abs().compareTo(
        (_timeFor(scenario.notes[b]) - elapsed).abs(),
      ),
    );
    final int index = candidates.first;
    final RhythmNote note = scenario.notes[index];
    if (note.lane != lane) {
      offbeats++;
      _states[index] = RhythmNoteState.missed;
      _recordMiss();
      return RhythmInputResult(
        quality: RhythmHitQuality.wrongLane,
        noteIndex: index,
        failed: failed,
      );
    }
    final double error = elapsed - _timeFor(note);
    if (note.kind == DrumNoteKind.hold) {
      _states[index] = RhythmNoteState.holding;
      _activeHold = index;
      _holdStartTiming = error.abs();
      return RhythmInputResult(
        quality: RhythmHitQuality.holdStarted,
        noteIndex: index,
      );
    }
    _states[index] = RhythmNoteState.hit;
    final RhythmHitQuality quality = _qualityFor(error.abs());
    _recordHit(note, quality);
    return RhythmInputResult(quality: quality, noteIndex: index);
  }

  RhythmInputResult releaseLane(DrumLane lane) {
    if (_activeHold < 0 || completed || failed) {
      return const RhythmInputResult();
    }
    final int index = _activeHold;
    final RhythmNote note = scenario.notes[index];
    if (note.lane != lane) return const RhythmInputResult();
    final double targetRelease =
        _timeFor(note) + note.holdBeats * scenario.secondsPerBeat;
    final double error = (elapsed - targetRelease).abs();
    _activeHold = -1;
    if (_holdStartTiming > scenario.goodWindowSeconds ||
        error > scenario.goodWindowSeconds) {
      _states[index] = RhythmNoteState.missed;
      _recordMiss();
      return RhythmInputResult(
        quality: RhythmHitQuality.missed,
        noteIndex: index,
        failed: failed,
      );
    }
    _states[index] = RhythmNoteState.hit;
    final RhythmHitQuality quality = _qualityFor(
      math.max(_holdStartTiming, error),
    );
    _recordHit(note, quality, hold: true);
    return RhythmInputResult(quality: quality, noteIndex: index);
  }

  RhythmStepResult step(double deltaSeconds) {
    final double delta = deltaSeconds.clamp(0, .1).toDouble();
    if (delta <= 0 || completed || failed) return const RhythmStepResult();
    elapsed += delta;
    int missedThisFrame = 0;
    for (int index = 0; index < scenario.notes.length; index++) {
      if (_states[index] != RhythmNoteState.pending) continue;
      if (elapsed - _timeFor(scenario.notes[index]) >
          scenario.goodWindowSeconds) {
        _states[index] = RhythmNoteState.missed;
        _recordMiss();
        missedThisFrame++;
      }
    }
    if (_activeHold >= 0) {
      final RhythmNote note = scenario.notes[_activeHold];
      final double endTime =
          _timeFor(note) + note.holdBeats * scenario.secondsPerBeat;
      if (elapsed - endTime > scenario.goodWindowSeconds) {
        _states[_activeHold] = RhythmNoteState.missed;
        _activeHold = -1;
        _recordMiss();
        missedThisFrame++;
      }
    }
    if (!failed && elapsed >= scenario.durationSeconds) {
      completed = _states.every(
        (RhythmNoteState state) =>
            state == RhythmNoteState.hit || state == RhythmNoteState.missed,
      );
      if (!completed) {
        failed = true;
      }
    }
    return RhythmStepResult(
      missed: missedThisFrame,
      completed: completed,
      failed: failed,
    );
  }

  void _recordHit(
    RhythmNote note,
    RhythmHitQuality quality, {
    bool hold = false,
  }) {
    if (quality == RhythmHitQuality.perfect) {
      perfectHits++;
    } else {
      goodHits++;
    }
    combo++;
    bestCombo = math.max(bestCombo, combo);
    final int base = quality == RhythmHitQuality.perfect ? 100 : 70;
    final double accent = note.kind == DrumNoteKind.accent ? 1.25 : 1;
    final double holdBonus = hold ? 1.25 : 1;
    score += (base * (1 + (combo ~/ 8)) * accent * holdBonus).round();
  }

  RhythmHitQuality _qualityFor(double error) =>
      error <= scenario.perfectWindowSeconds
      ? RhythmHitQuality.perfect
      : RhythmHitQuality.good;

  void _recordMiss() {
    misses++;
    combo = 0;
    if (misses > scenario.missLimit) failed = true;
  }

  double _timeFor(RhythmNote note) => note.beat * scenario.secondsPerBeat;

  void reset() {
    for (int index = 0; index < _states.length; index++) {
      _states[index] = RhythmNoteState.pending;
    }
    elapsed = 0;
    score = 0;
    misses = 0;
    perfectHits = 0;
    goodHits = 0;
    offbeats = 0;
    combo = 0;
    bestCombo = 0;
    _activeHold = -1;
    _holdStartTiming = 0;
    completed = false;
    failed = false;
  }

  /// A lifecycle pause cancels a touch without scoring a miss; the frozen
  /// measure resumes and the player can re-enter the sustained note.
  void interruptHold() {
    if (_activeHold < 0) return;
    _states[_activeHold] = RhythmNoteState.pending;
    _activeHold = -1;
    _holdStartTiming = 0;
  }
}
