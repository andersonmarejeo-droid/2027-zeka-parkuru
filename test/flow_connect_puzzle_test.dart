import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/flow_connect/flow_connect_puzzle.dart';

void main() {
  test(
    'all ten Flow Connect boards have a non-crossing, adjacent solution',
    () {
      for (int level = 1; level <= 10; level++) {
        final FlowPuzzle puzzle = FlowPuzzle.forLevel(level);
        expect(puzzle.hasValidSolution(), isTrue, reason: 'Level $level');
        expect(
          puzzle.isComplete(<int, List<int>>{
            for (final pair in puzzle.pairs) pair.id: pair.solution,
          }),
          isTrue,
        );
      }
    },
  );

  test('adjacency never wraps a row edge into the next row', () {
    final FlowPuzzle puzzle = FlowPuzzle.forLevel(1);
    expect(puzzle.areAdjacent(4, 5), isFalse);
    expect(puzzle.areAdjacent(3, 4), isTrue);
    expect(puzzle.areAdjacent(4, 9), isTrue);
  });
}
