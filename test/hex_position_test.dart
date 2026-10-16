import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/hex_connection/hex_position.dart';

void main() {
  group('Hex connection rules', () {
    test('red connects north to south through six-neighbor stones', () {
      final List<int> cells = List<int>.filled(25, 0);
      for (int row = 0; row < 4; row++) {
        cells[row * 5 + 2] = HexSide.red.value;
      }
      final HexPosition broken = HexPosition(
        size: 5,
        cells: cells,
        nextSide: HexSide.red,
      );
      expect(broken.hasConnection(HexSide.red), isFalse);
      expect(broken.shortestConnectionCost(HexSide.red), 1);
      final HexPosition connected = broken.play(22)!;
      expect(connected.winner, HexSide.red);
      expect(connected.play(0), isNull);
    });

    test('blue connects west to east and both players cannot win together', () {
      final List<int> cells = List<int>.filled(25, 0);
      for (int column = 0; column < 4; column++) {
        cells[2 * 5 + column] = HexSide.blue.value;
      }
      final HexPosition broken = HexPosition(
        size: 5,
        cells: cells,
        nextSide: HexSide.blue,
      );
      final HexPosition connected = broken.play(14)!;
      expect(connected.hasConnection(HexSide.blue), isTrue);
      expect(connected.winner, HexSide.blue);
      expect(connected.hasConnection(HexSide.red), isFalse);
    });

    test('only open cells are legal and generated openings never repeat', () {
      final HexPosition start = HexScenarioBank.forLevel(1).start;
      expect(start.legalMoves, hasLength(25));
      expect(start.play(0)?.nextSide, HexSide.blue);
      expect(start.play(-1), isNull);
      expect(start.play(25), isNull);
      expect(start.play(0)?.play(0), isNull);
    });
  });

  group('Hex scenario certification', () {
    test('20 campaign starts are unique, unfinished and human-ready', () {
      final Set<String> signatures = <String>{};
      for (int level = 1; level <= HexScenarioBank.maximumLevels; level++) {
        final HexScenario scenario = HexScenarioBank.forLevel(level);
        expect(
          signatures.add(scenario.signature),
          isTrue,
          reason: 'level $level',
        );
        expect(scenario.isValidStart, isTrue, reason: 'level $level');
        expect(scenario.size, HexScenarioBank.sizeForLevel(level));
        expect(
          scenario.openingMoves,
          HexScenarioBank.openingMovesForLevel(level),
        );
      }
      expect(signatures, hasLength(20));
    });

    test(
      'first 300 practice layouts never repeat a campaign or each other',
      () {
        final Set<String> signatures = <String>{
          for (int level = 1; level <= HexScenarioBank.maximumLevels; level++)
            HexScenarioBank.forLevel(level).signature,
        };
        for (
          int index = 1;
          index <= HexScenarioBank.maximumVerifiedBoards;
          index++
        ) {
          final HexScenario scenario = HexScenarioBank.forPracticeBoard(index);
          expect(
            signatures.add(scenario.signature),
            isTrue,
            reason: 'practice $index',
          );
          expect(scenario.isValidStart, isTrue, reason: 'practice $index');
        }
        expect(signatures, hasLength(320));
        expect(() => HexScenarioBank.forPracticeBoard(301), throwsRangeError);
      },
    );

    test(
      'the computer always makes a legal move and deepens by level band',
      () {
        final HexScenario scenario = HexScenarioBank.forLevel(10);
        final int? response = HexComputerPlayer.chooseMove(
          scenario.start,
          side: HexSide.red,
          level: 10,
          seed: scenario.seed,
        );
        expect(response, isNotNull);
        expect(scenario.start.legalMoves, contains(response));
        expect(
          HexScenarioBank.searchDepthForLevel(8),
          lessThan(HexScenarioBank.searchDepthForLevel(9)),
        );
        expect(
          HexScenarioBank.searchDepthForLevel(16),
          lessThan(HexScenarioBank.searchDepthForLevel(17)),
        );
      },
    );
  });
}
