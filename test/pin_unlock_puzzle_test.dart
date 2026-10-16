import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/pin_unlock/pin_unlock_puzzle.dart';
import 'package:zeka_parkuru/games/shared/studio_game_contracts.dart';

void main() {
  test('300 locks are distinct, deterministic and solver-verified', () {
    final Set<String> boards = <String>{};
    final Set<String> solutions = <String>{};
    final Set<PinClueFamily> families = <PinClueFamily>{};

    for (int level = 1; level <= 300; level++) {
      final PinUnlockPuzzle puzzle = PinUnlockPuzzle.forLevel(level);
      final int stage = PinUnlockPuzzle.stageForLevel(level);
      expect(puzzle.pinCount, inInclusiveRange(5, 8), reason: 'level $level');
      expect(puzzle.localStage, stage);
      expect(
        puzzle.solution.every((int height) => height >= 1 && height <= 4),
        isTrue,
        reason: 'pin heights are calibrated on level $level',
      );
      expect(
        puzzle.clues.length,
        puzzle.pinCount + PinUnlockPuzzle.extraCluesForStage(stage),
        reason: 'clue budget follows the 10-stage curve on level $level',
      );
      expect(
        puzzle.clues.every((PinClue clue) => clue.matches(puzzle.solution)),
        isTrue,
        reason: 'every signal accepts the intended alignment on level $level',
      );
      expect(puzzle.solve(puzzle.clues), hasLength(1), reason: 'level $level');
      expect(puzzle.isSolved(puzzle.solution), isTrue, reason: 'level $level');
      expect(
        puzzle.isSolved(List<int>.filled(puzzle.pinCount, 5)),
        isFalse,
        reason: 'out-of-calibration pin setting on level $level',
      );
      expect(
        PinUnlockPuzzle.forLevel(level).boardSignature,
        puzzle.boardSignature,
        reason: 'level generation must be stable',
      );
      boards.add(puzzle.boardSignature);
      solutions.add('${puzzle.pinCount}:${puzzle.solution.join()}');
      families.addAll(puzzle.clues.map((PinClue clue) => clue.family));
    }

    expect(boards, hasLength(300));
    expect(solutions, hasLength(300));
    expect(families, containsAll(PinClueFamily.values));
    expect(
      PinUnlockPuzzle.maximumUniqueCases,
      greaterThanOrEqualTo(GameContentPolicy.minimumUniqueRounds),
    );
  });

  test('every ten-level package ramps into advanced and expert stages', () {
    for (int start = 1; start <= 291; start += 10) {
      final List<PinUnlockPuzzle> package = List<PinUnlockPuzzle>.generate(
        10,
        (int offset) => PinUnlockPuzzle.forLevel(start + offset),
      );
      expect(
        package.map((PinUnlockPuzzle puzzle) => puzzle.localStage),
        orderedEquals(<int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]),
      );
      expect(package[5].difficultyTier, 'MASTERY');
      expect(package[6].difficultyTier, 'ADVANCED');
      expect(package[7].difficultyTier, 'ADVANCED');
      expect(package[8].difficultyTier, 'EXPERT');
      expect(package[9].difficultyTier, 'EXPERT');
      for (int stage = 1; stage < 10; stage++) {
        expect(
          package[stage].clues.length,
          lessThan(package[stage - 1].clues.length),
          reason: 'each stage adds challenge within package $start',
        );
      }
      expect(
        package[8].clues.any(
          (PinClue clue) => clue.family == PinClueFamily.sequence,
        ),
        isTrue,
      );
    }
  });

  test('mechanical signals are clear and localized', () {
    const PinClue pair = PinClue(
      kind: PinClueKind.pairSum,
      first: 0,
      second: 1,
      value: 5,
    );
    const PinClue rising = PinClue(kind: PinClueKind.risingSteps, value: 2);
    expect(pair.text(english: true), contains('A and B'));
    expect(pair.text(english: false), contains('A ve B'));
    expect(pair.matches(<int>[2, 3, 1, 4, 2]), isTrue);
    expect(pair.matches(<int>[1, 1, 1, 1, 1]), isFalse);
    expect(rising.matches(<int>[1, 3, 2, 4, 4]), isTrue);
    expect(rising.family, PinClueFamily.sequence);
  });
}
