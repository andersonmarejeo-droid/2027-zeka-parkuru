import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/beam_director/beam_director_puzzle.dart';

void main() {
  test('all Beam Director boards have a bounded valid beam route', () {
    for (int level = 1; level <= 10; level++) {
      final BeamDirectorPuzzle puzzle = BeamDirectorPuzzle.forLevel(level);
      final BeamTrace trace = puzzle.trace(puzzle.solvedStates);

      expect(puzzle.width, lessThanOrEqualTo(5));
      expect(puzzle.height, lessThanOrEqualTo(5));
      expect(puzzle.hasValidSolution, isTrue);
      expect(trace.reachesTarget, isTrue);
      expect(trace.cells.length, lessThanOrEqualTo(puzzle.cellCount * 2));
    }
  });

  test(
    'a slash and backslash mirror reflect a beam in opposite directions',
    () {
      final BeamDirectorPuzzle first = BeamDirectorPuzzle.forLevel(1);
      final List<bool> wrongState = List<bool>.from(first.solvedStates);
      wrongState[0] = !wrongState[0];

      expect(first.trace(first.solvedStates).reachesTarget, isTrue);
      expect(first.trace(wrongState).reachesTarget, isFalse);
    },
  );
}
