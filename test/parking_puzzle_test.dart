import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/parking_puzzle/parking_puzzle.dart';

void main() {
  test('difficulty never resets across the 300-board pool', () {
    int previous = 0;
    for (int level = 1; level <= 300; level++) {
      final minimum = ParkingPuzzle.minimumOptimalMovesForLevel(level);
      expect(minimum, greaterThanOrEqualTo(previous), reason: 'level $level');
      previous = minimum;
    }
    expect(ParkingPuzzle.minimumOptimalMovesForLevel(1), 5);
    expect(ParkingPuzzle.minimumOptimalMovesForLevel(300), 9);
    expect(ParkingPuzzle.forLevel(1).chapter, 1);
    expect(ParkingPuzzle.forLevel(10).stageInChapter, 10);
  });

  test('first 300 parking boards are unique, valid and solver-verified', () {
    final Set<String> signatures = <String>{};
    final Set<int> blockerCounts = <int>{};
    bool foundLongVehicle = false;
    bool foundHorizontalTraffic = false;
    bool foundVerticalTraffic = false;

    for (int level = 1; level <= 300; level++) {
      final ParkingPuzzle puzzle = ParkingPuzzle.forLevel(level);
      expect(puzzle.vehicles.length, greaterThanOrEqualTo(7));
      expect(puzzle.vehicles.length, lessThanOrEqualTo(10));
      expect(puzzle.blockerCount, ParkingPuzzle.blockersForLevel(level));
      expect(
        puzzle.optimalMoves,
        inInclusiveRange(ParkingPuzzle.minimumOptimalMovesForLevel(level), 30),
        reason: 'case $level should be solver-proven and suitably challenging',
      );
      expect(puzzle.isSolved(puzzle.initialOffsets), isFalse);

      final List<int> occupied = List<int>.filled(36, -1);
      for (int index = 0; index < puzzle.vehicles.length; index++) {
        final ParkingVehicle vehicle = puzzle.vehicles[index];
        final int offset = puzzle.initialOffsets[index];
        expect(offset, inInclusiveRange(0, vehicle.maximumOffset(6)));
        foundLongVehicle |= vehicle.length == 3;
        foundHorizontalTraffic |= vehicle.axis == ParkingAxis.horizontal;
        foundVerticalTraffic |= vehicle.axis == ParkingAxis.vertical;
        for (int segment = 0; segment < vehicle.length; segment++) {
          final int row = vehicle.axis == ParkingAxis.horizontal
              ? vehicle.lane
              : offset + segment;
          final int column = vehicle.axis == ParkingAxis.horizontal
              ? offset + segment
              : vehicle.lane;
          final int cell = row * 6 + column;
          expect(occupied[cell], -1, reason: 'overlap at level $level');
          occupied[cell] = index;
        }
      }

      List<int> replay = puzzle.initialOffsets;
      for (final ParkingMove move in puzzle.solution) {
        expect(replay[move.vehicleIndex], move.fromOffset);
        expect(
          puzzle.canMove(replay, move.vehicleIndex, move.toOffset),
          isTrue,
          reason: 'illegal solver step on case $level',
        );
        replay = puzzle.move(replay, move.vehicleIndex, move.toOffset);
      }
      expect(puzzle.isSolved(replay), isTrue, reason: 'case $level');
      signatures.add(puzzle.boardSignature);
      blockerCounts.add(puzzle.blockerCount);
    }

    expect(signatures, hasLength(300));
    expect(blockerCounts, equals(<int>{6, 7, 8, 9}));
    expect(foundLongVehicle, isTrue);
    expect(foundHorizontalTraffic, isTrue);
    expect(foundVerticalTraffic, isTrue);
  });

  test('only lane-aligned, collision-free slides are accepted', () {
    final ParkingPuzzle puzzle = ParkingPuzzle.forLevel(1);
    final List<int> initial = puzzle.initialOffsets;
    final ParkingMove firstSolutionMove = puzzle.solution.first;
    expect(
      puzzle.canMove(
        initial,
        firstSolutionMove.vehicleIndex,
        firstSolutionMove.toOffset,
      ),
      isTrue,
    );
    expect(puzzle.canMove(initial, 0, 5), isFalse);
    expect(puzzle.canMove(initial, 1, 4), isFalse);
    expect(puzzle.hintOffsets(initial), isNot(equals(initial)));
  });
}
