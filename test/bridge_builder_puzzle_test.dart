import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/bridge_builder/bridge_builder_puzzle.dart';
import 'package:zeka_parkuru/games/shared/studio_game_contracts.dart';

void main() {
  test('first 300 bridge cases are distinct connected unique networks', () {
    final Map<String, int> signatures = <String, int>{};
    final List<String> duplicates = <String>[];
    bool foundDoubleRoute = false;
    bool foundCrossingDecision = false;
    for (
      int level = 1;
      level <= GameContentPolicy.minimumUniqueRounds;
      level++
    ) {
      final BridgeBuilderPuzzle puzzle = BridgeBuilderPuzzle.forLevel(level);
      expect(puzzle.islands.length, greaterThanOrEqualTo(7));
      expect(puzzle.links.length, greaterThanOrEqualTo(8));
      expect(puzzle.hasUniqueSolution, isTrue, reason: 'case $level');
      expect(puzzle.isSolved(puzzle.solution), isTrue, reason: 'case $level');
      foundDoubleRoute |= puzzle.solution.contains(2);
      for (int first = 0; first < puzzle.links.length; first++) {
        for (int second = first + 1; second < puzzle.links.length; second++) {
          foundCrossingDecision |= puzzle.crosses(first, second);
        }
      }
      final int? original = signatures[puzzle.boardSignature];
      if (original != null) duplicates.add('$level duplicates $original');
      signatures[puzzle.boardSignature] = level;
    }
    expect(duplicates, isEmpty, reason: duplicates.join(', '));
    expect(signatures, hasLength(GameContentPolicy.minimumUniqueRounds));
    expect(foundDoubleRoute, isTrue);
    expect(foundCrossingDecision, isTrue);
  });

  test('difficulty grows in linked loop count', () {
    expect(BridgeBuilderPuzzle.cyclesForLevel(1), 2);
    expect(BridgeBuilderPuzzle.cyclesForLevel(100), 3);
    expect(BridgeBuilderPuzzle.cyclesForLevel(200), 4);
    expect(BridgeBuilderPuzzle.cyclesForLevel(300), 5);
  });

  test('double bridges, crossings and network connectivity are real rules', () {
    const BridgeBuilderPuzzle doubleRoute = BridgeBuilderPuzzle(
      level: 1,
      islands: <BridgeIsland>[
        BridgeIsland(point: BridgePoint(row: 0, column: 0), target: 2),
        BridgeIsland(point: BridgePoint(row: 0, column: 2), target: 2),
      ],
      links: <BridgeLink>[BridgeLink(first: 0, second: 1)],
      solution: <int>[2],
    );
    expect(doubleRoute.countSolutions(), 1);
    expect(doubleRoute.isSolved(<int>[2]), isTrue);
    expect(doubleRoute.isSolved(<int>[1]), isFalse);

    const BridgeBuilderPuzzle crossingRoutes = BridgeBuilderPuzzle(
      level: 1,
      islands: <BridgeIsland>[
        BridgeIsland(point: BridgePoint(row: 2, column: 0), target: 1),
        BridgeIsland(point: BridgePoint(row: 2, column: 4), target: 1),
        BridgeIsland(point: BridgePoint(row: 0, column: 2), target: 1),
        BridgeIsland(point: BridgePoint(row: 4, column: 2), target: 1),
      ],
      links: <BridgeLink>[
        BridgeLink(first: 0, second: 1),
        BridgeLink(first: 2, second: 3),
      ],
      solution: <int>[1, 1],
    );
    expect(crossingRoutes.hasCrossingBridge(<int>[1, 1]), isTrue);
    expect(crossingRoutes.isSolved(<int>[1, 1]), isFalse);
    expect(crossingRoutes.isNetworkConnected(<int>[1, 1]), isFalse);
  });
}
