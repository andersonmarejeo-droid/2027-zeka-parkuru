import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/bubble_shooter/bubble_shooter_puzzle.dart';

void main() {
  test('bubble boards grow steadily and fill the available row range', () {
    final List<int> rows = <int>[
      for (int level = 1; level <= 10; level++)
        BubbleShooterPuzzle.rowsForLevel(level),
    ];

    expect(rows, orderedEquals(<int>[7, 7, 8, 8, 9, 9, 10, 10, 11, 12]));
    expect(rows.last, BubbleShooterPuzzle.maxRows);
    expect(rows, orderedEquals(rows.toList()..sort()));
  });

  test('each bubble-shooter level has 300 distinct legal fields', () {
    for (int level = 1; level <= 10; level++) {
      final Set<String> signatures = <String>{
        for (int variant = 0; variant < 300; variant++)
          BubbleShooterPuzzle.generate(level, variant).signature,
      };
      expect(signatures, hasLength(300), reason: 'level $level');

      final BubbleShooterPuzzle puzzle = BubbleShooterPuzzle.generate(
        level,
        41,
      );
      expect(puzzle.rows, BubbleShooterPuzzle.rowsForLevel(level));
      expect(puzzle.colorCount, BubbleShooterPuzzle.colorCountForLevel(level));
      for (int row = 0; row < BubbleShooterPuzzle.maxRows; row++) {
        for (int column = 0; column < BubbleShooterPuzzle.columns; column++) {
          if (!BubbleShooterPuzzle.isValidCell(row, column)) {
            expect(
              puzzle.cells[row * BubbleShooterPuzzle.columns + column],
              isNull,
            );
          }
        }
      }
    }
  });

  test(
    'matching a group pops it and drops bubbles detached from the ceiling',
    () {
      final List<int?> cells = List<int?>.filled(
        BubbleShooterPuzzle.maxRows * BubbleShooterPuzzle.columns,
        null,
      );
      cells[0] = 0;
      cells[1] = 0;
      cells[BubbleShooterPuzzle.columns + 2] = 2;
      cells[2 * BubbleShooterPuzzle.columns + 2] = 2;
      final BubbleShooterEngine engine = BubbleShooterEngine(
        BubbleShooterPuzzle(
          level: 1,
          variant: 0,
          rows: 3,
          colorCount: 3,
          shotLimit: 20,
          cells: cells,
        ),
      );

      final BubbleShotResult result = engine.fire(row: 1, column: 0, color: 0);

      expect(result.placed, isTrue);
      expect(result.matched, 3);
      expect(result.fallen, 2);
      expect(result.removedBubbles, hasLength(5));
      expect(engine.isCleared, isTrue);
    },
  );

  test('occupied or stagger-invalid cells reject a shot without mutation', () {
    final BubbleShooterPuzzle puzzle = BubbleShooterPuzzle.generate(2, 9);
    final BubbleShooterEngine engine = BubbleShooterEngine(puzzle);
    final String before = engine.cells.map((int? value) => value ?? '.').join();

    expect(engine.fire(row: 0, column: 0, color: 1).placed, isFalse);
    expect(engine.fire(row: 1, column: 7, color: 1).placed, isFalse);
    expect(engine.cells.map((int? value) => value ?? '.').join(), before);
  });
}
