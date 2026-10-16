import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/warehouse_master/warehouse_puzzle.dart';

void main() {
  group('Warehouse Master content contract', () {
    test('a generated board has a legal shortest-push certificate', () {
      final WarehousePuzzle puzzle = WarehousePuzzle.forLevel(1);
      expect(puzzle.verifySolution(), isTrue);
      expect(puzzle.optimalPushes, greaterThanOrEqualTo(4));
      expect(
        puzzle.solution.where((WarehouseAction move) => move.isPush),
        hasLength(puzzle.optimalPushes),
      );

      WarehouseState state = puzzle.initialState;
      for (final WarehouseAction action in puzzle.solution) {
        final WarehouseState? next = puzzle.move(state, action.direction);
        expect(next, isNotNull, reason: 'certificate contains an illegal step');
        state = next!;
      }
      expect(puzzle.isSolved(state), isTrue);
      expect(state.pushes, puzzle.optimalPushes);
    });

    test('the 20 campaign boards are deterministic and distinct', () {
      final Set<String> signatures = <String>{};
      for (
        int level = 1;
        level <= WarehousePuzzle.maximumUniqueCases;
        level++
      ) {
        final WarehousePuzzle puzzle = WarehousePuzzle.forLevel(level);
        expect(
          signatures.add(puzzle.boardSignature),
          isTrue,
          reason: 'duplicate board at level $level',
        );
        expect(puzzle.verifySolution(), isTrue, reason: 'level $level');
        expect(
          puzzle.optimalPushes,
          greaterThanOrEqualTo(
            WarehousePuzzle.minimumOptimalPushesForLevel(level),
          ),
          reason: 'level $level fell below its difficulty gate',
        );
        expect(puzzle.initialCrates, hasLength(puzzle.crateCount));
        expect(puzzle.goals, hasLength(puzzle.crateCount));
        expect(puzzle.walls.intersection(puzzle.goals), isEmpty);
        expect(
          puzzle.walls.intersection(puzzle.initialCrates.toSet()),
          isEmpty,
        );
        expect(puzzle.walls, isNot(contains(puzzle.initialPlayer)));
        expect(
          WarehousePuzzle.forLevel(level).boardSignature,
          puzzle.boardSignature,
          reason: 'level $level changed on repeated access',
        );
      }
      expect(signatures, hasLength(WarehousePuzzle.maximumUniqueCases));
      expect(() => WarehousePuzzle.forLevel(21), throwsRangeError);
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('each ten-stage chapter reserves advanced and expert push depth', () {
      for (int level = 1; level <= 10; level++) {
        final WarehousePuzzle puzzle = WarehousePuzzle.forLevel(level);
        expect(puzzle.stageInChapter, level);
        expect(
          puzzle.optimalPushes,
          greaterThanOrEqualTo(
            WarehousePuzzle.minimumOptimalPushesForLevel(level),
          ),
        );
      }
      expect(WarehousePuzzle.forLevel(7).difficultyTier, 'İLERİ');
      expect(WarehousePuzzle.forLevel(8).difficultyTier, 'İLERİ');
      expect(WarehousePuzzle.forLevel(9).difficultyTier, 'UZMAN');
      expect(WarehousePuzzle.forLevel(10).difficultyTier, 'UZMAN');
      expect(
        WarehousePuzzle.minimumOptimalPushesForLevel(10),
        greaterThan(WarehousePuzzle.minimumOptimalPushesForLevel(6)),
      );
    });

    test('blocked steps are rejected without mutating the prior state', () {
      final WarehousePuzzle puzzle = WarehousePuzzle.forLevel(1);
      final WarehouseState before = WarehouseState(
        player: 0,
        crates: puzzle.initialCrates,
      );
      final WarehouseState? result = puzzle.move(before, WarehouseDirection.up);
      expect(result, isNull);
      expect(before.moves, 0);
      expect(before.pushes, 0);
      expect(before.crates, puzzle.initialCrates);
    });
  });
}
