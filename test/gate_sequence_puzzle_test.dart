import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/gate_sequence/gate_sequence_puzzle.dart';
import 'package:zeka_parkuru/games/shared/studio_game_contracts.dart';

void main() {
  test('first 300 gate cases are distinct and have one valid solution', () {
    final Set<String> boards = <String>{};
    final Set<String> orders = <String>{};
    final Set<GateClueFamily> families = <GateClueFamily>{};
    for (int level = 1; level <= 300; level++) {
      final GateSequencePuzzle puzzle = GateSequencePuzzle.forLevel(level);
      expect(puzzle.gateCount, inInclusiveRange(5, 8), reason: 'case $level');
      expect(puzzle.clues.length, greaterThanOrEqualTo(5));
      expect(
        puzzle.clues.every((GateClue clue) => clue.matches(puzzle.solution)),
        isTrue,
        reason: 'all clues must accept the intended order on case $level',
      );
      expect(puzzle.hasUniqueSolution, isTrue, reason: 'case $level');
      expect(puzzle.solve(puzzle.clues), hasLength(1), reason: 'case $level');
      expect(puzzle.isSolved(puzzle.solution), isTrue, reason: 'case $level');
      expect(puzzle.isSolved(puzzle.solution.reversed.toList()), isFalse);
      boards.add(puzzle.boardSignature);
      orders.add('${puzzle.gateCount}:${puzzle.solution.join()}');
      families.addAll(puzzle.clues.map((GateClue clue) => clue.family));
    }
    expect(boards, hasLength(300));
    expect(orders, hasLength(300));
    expect(families, containsAll(GateClueFamily.values));
    expect(
      GateSequencePuzzle.maximumUniqueCases,
      greaterThanOrEqualTo(GameContentPolicy.minimumUniqueRounds),
    );
  });

  test('difficulty progresses through five, six, seven and eight gates', () {
    expect(GateSequencePuzzle.gateCountForLevel(1), 5);
    expect(GateSequencePuzzle.gateCountForLevel(100), 6);
    expect(GateSequencePuzzle.gateCountForLevel(200), 7);
    expect(GateSequencePuzzle.gateCountForLevel(300), 8);
  });

  test('clue rules are explicit and localized', () {
    const GateClue placement = GateClue(
      kind: GateClueKind.atPosition,
      first: 0,
      value: 1,
    );
    const GateClue before = GateClue(
      kind: GateClueKind.before,
      first: 0,
      second: 1,
    );
    expect(placement.text(english: true), contains('Amber'));
    expect(placement.text(english: false), contains('Kehribar'));
    expect(before.matches(<int>[0, 1, 2, 3, 4]), isTrue);
    expect(before.matches(<int>[1, 0, 2, 3, 4]), isFalse);
  });
}
