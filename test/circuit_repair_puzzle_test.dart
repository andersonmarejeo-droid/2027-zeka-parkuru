import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/circuit_repair/circuit_repair_puzzle.dart';

void main() {
  test('all Circuit Repair boards can power source to target', () {
    for (int level = 1; level <= 10; level++) {
      final CircuitPuzzle puzzle = CircuitPuzzle.forLevel(level);
      expect(puzzle.hasValidSolution(), isTrue, reason: 'Level $level');
      expect(puzzle.size, lessThanOrEqualTo(5));
    }
  });

  test('wire rotation preserves branch count and direction reciprocity', () {
    final int corner = CircuitDirection.up.bit | CircuitDirection.right.bit;
    expect(
      rotateMaskClockwise(corner),
      CircuitDirection.right.bit | CircuitDirection.down.bit,
    );
    expect(
      rotateMaskClockwise(
        rotateMaskClockwise(rotateMaskClockwise(rotateMaskClockwise(corner))),
      ),
      corner,
    );
  });

  test('an open connection does not jump across a broken reciprocal wire', () {
    final CircuitPuzzle puzzle = CircuitPuzzle.forLevel(1);
    final List<int> broken = List<int>.generate(
      puzzle.cellCount,
      puzzle.solvedMaskAt,
    );
    broken[1] = 0;
    expect(puzzle.isTargetEnergized(broken), isFalse);
  });
}
