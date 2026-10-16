import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/mine_detector/mine_detector_puzzle.dart';

void main() {
  group('Mine Detector no-guess content contract', () {
    test('a first board has a no-guess certificate', () {
      final MineDetectorPuzzle puzzle = MineDetectorPuzzle.forLevel(1);
      expect(puzzle.verifyLogicSolvable(), isTrue);
    });

    test('the 20 campaign boards are unique, safely opened and certified', () {
      final Set<String> signatures = <String>{};
      for (
        int level = 1;
        level <= MineDetectorPuzzle.maximumUniqueCases;
        level++
      ) {
        final MineDetectorPuzzle puzzle = MineDetectorPuzzle.forLevel(level);
        final MineDetectorLogicReport certificate = puzzle.logicCertificate;
        expect(
          signatures.add(puzzle.boardSignature),
          isTrue,
          reason: 'repeated mine layout at level $level',
        );
        expect(puzzle.mines, hasLength(puzzle.mineCount));
        expect(puzzle.clues, hasLength(puzzle.cellCount));
        expect(puzzle.isMine(puzzle.safeStartCell), isFalse);
        expect(puzzle.adjacentMineCount(puzzle.safeStartCell), 0);
        expect(
          puzzle.neighborsOf(puzzle.safeStartCell).any(puzzle.isMine),
          isFalse,
          reason: 'the designated 3×3 launch zone must be mine-free',
        );
        expect(puzzle.initialState.revealed, contains(puzzle.safeStartCell));
        expect(
          puzzle.initialState.revealed.any(puzzle.isMine),
          isFalse,
          reason: 'opening exposed a mine at level $level',
        );
        expect(
          puzzle.verifyLogicSolvable(),
          isTrue,
          reason: 'level $level required a guess',
        );
        expect(certificate.isSolved, isTrue);
        expect(certificate.hadContradiction, isFalse);
        expect(certificate.finalState.isWon, isTrue);
        expect(
          certificate.actions
              .where((MineDetectorLogicAction action) => action.flagsMine)
              .every(
                (MineDetectorLogicAction action) => puzzle.isMine(action.cell),
              ),
          isTrue,
          reason: 'certificate flagged a non-mine at level $level',
        );
        expect(
          certificate.actions
              .where((MineDetectorLogicAction action) => action.revealsSafeCell)
              .every(
                (MineDetectorLogicAction action) => !puzzle.isMine(action.cell),
              ),
          isTrue,
          reason: 'certificate revealed a mine at level $level',
        );
        expect(
          MineDetectorPuzzle.forLevel(level).boardSignature,
          puzzle.boardSignature,
        );
      }
      expect(signatures, hasLength(MineDetectorPuzzle.maximumUniqueCases));
      expect(() => MineDetectorPuzzle.forLevel(301), throwsRangeError);
    });

    test('the ten-stage curve raises inference load, not only board size', () {
      final List<MineDetectorPuzzle> stages = <MineDetectorPuzzle>[
        for (int stage = 1; stage <= 10; stage++)
          MineDetectorPuzzle.forLevel(stage),
      ];
      expect(stages.map((MineDetectorPuzzle puzzle) => puzzle.rows), <int>[
        6,
        6,
        7,
        7,
        8,
        8,
        9,
        9,
        10,
        10,
      ]);
      expect(stages.map((MineDetectorPuzzle puzzle) => puzzle.columns), <int>[
        6,
        7,
        7,
        8,
        8,
        9,
        9,
        10,
        10,
        11,
      ]);
      expect(stages.map((MineDetectorPuzzle puzzle) => puzzle.mineCount), <int>[
        4,
        6,
        8,
        10,
        12,
        14,
        16,
        18,
        20,
        22,
      ]);
      for (int stage = 1; stage <= 10; stage++) {
        final MineDetectorPuzzle puzzle = stages[stage - 1];
        expect(puzzle.localStage, stage);
        expect(puzzle.certifiedLogicSteps, greaterThanOrEqualTo(stage * 2 + 2));
        expect(
          puzzle.certifiedInferenceRounds,
          greaterThanOrEqualTo(stage + 3),
        );
      }
      expect(stages[6].difficultyTier, 'İLERİ');
      expect(stages[7].difficultyTier, 'İLERİ');
      expect(stages[8].difficultyTier, 'UZMAN');
      expect(stages[9].difficultyTier, 'UZMAN');
      expect(stages[6].certifiedSubsetSteps, greaterThanOrEqualTo(1));
      expect(stages[7].certifiedSubsetSteps, greaterThanOrEqualTo(1));
      expect(stages[8].certifiedSubsetSteps, greaterThanOrEqualTo(2));
      expect(stages[9].certifiedSubsetSteps, greaterThanOrEqualTo(2));
      expect(
        stages.last.complexityScore,
        greaterThan(stages.first.complexityScore),
      );
    });

    test(
      'classic clues, flood fill, flags and chord preserve immutable state',
      () {
        final MineDetectorPuzzle puzzle = MineDetectorPuzzle.fromMines(
          rows: 5,
          columns: 5,
          mines: <int>{0, 2, 6, 8, 10, 12},
          safeStartCell: 24,
        );
        final MineDetectorBoardState opening = puzzle.initialState;
        expect(opening.isLost, isFalse);
        expect(opening.revealed, contains(24));
        expect(opening.revealed.any(puzzle.isMine), isFalse);
        for (final int cell in opening.revealed) {
          if (puzzle.adjacentMineCount(cell) != 0) continue;
          for (final int next in puzzle.neighborsOf(cell)) {
            if (puzzle.isMine(next)) continue;
            expect(
              opening.revealed.contains(next),
              isTrue,
              reason: 'zero at $cell did not flood safe neighbour $next',
            );
          }
        }

        final int clueCell = opening.revealed.firstWhere((int cell) {
          final int clue = puzzle.adjacentMineCount(cell);
          return clue > 0 &&
              puzzle
                  .neighborsOf(cell)
                  .where(puzzle.isMine)
                  .every((int mine) => !opening.revealed.contains(mine));
        });
        final Set<int> nearbyMines = puzzle
            .neighborsOf(clueCell)
            .where(puzzle.isMine)
            .toSet();
        MineDetectorBoardState flagged = opening;
        for (final int mine in nearbyMines) {
          flagged = puzzle.toggleFlag(flagged, mine);
        }
        expect(flagged.flagged, containsAll(nearbyMines));
        expect(opening.flagged, isEmpty, reason: 'states must be immutable');
        final MineDetectorBoardState chorded = puzzle.chord(flagged, clueCell);
        expect(chorded.isLost, isFalse);
        expect(
          chorded.revealed.length,
          greaterThanOrEqualTo(opening.revealed.length),
        );

        final int hiddenSafe = Iterable<int>.generate(puzzle.cellCount)
            .firstWhere(
              (int cell) =>
                  !puzzle.isMine(cell) && !opening.revealed.contains(cell),
            );
        final MineDetectorBoardState speculative = puzzle.toggleFlag(
          opening,
          hiddenSafe,
        );
        final MineDetectorLogicReport unsafeHintGuard = puzzle.logicSolve(
          fromState: speculative,
        );
        expect(unsafeHintGuard.hadContradiction, isTrue);
        expect(unsafeHintGuard.nextAction, isNull);
        expect(puzzle.rowOf(24), 4);
        expect(puzzle.columnOf(24), 4);
        expect(puzzle.indexAt(4, 4), 24);
        expect(() => puzzle.indexAt(5, 0), throwsRangeError);
      },
    );
  });
}
