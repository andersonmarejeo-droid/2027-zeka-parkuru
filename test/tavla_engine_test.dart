import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/tavla_master/tavla_engine.dart';
import 'package:zeka_parkuru/games/tavla_master/tavla_scenario.dart';

void main() {
  group('Tavla kuralları', () {
    test('standart açılışta iki tarafın 15 pulu ve 167 pipi vardır', () {
      final TavlaPosition position = TavlaPosition.standard();
      expect(position.checkersOnBoard(TavlaSide.white), 15);
      expect(position.checkersOnBoard(TavlaSide.black), 15);
      expect(position.pipCount(TavlaSide.white), 167);
      expect(position.pipCount(TavlaSide.black), 167);
    });

    test('bar üzerindeki pul önce oyuna girmek zorundadır', () {
      final List<int> points = List<int>.filled(24, 0);
      points[0] = -2;
      points[11] = -5;
      points[16] = -3;
      points[18] = -5;
      final TavlaPosition position = TavlaPosition(
        points: points,
        whiteBar: 1,
        blackBar: 0,
        whiteOff: 14,
        blackOff: 0,
      );

      final List<TavlaMove> moves = position.legalMovesForDie(
        TavlaSide.white,
        1,
      );
      expect(moves, hasLength(1));
      expect(moves.single.from, TavlaPoint.bar);
      expect(moves.single.to, 23);
      final TavlaPosition entered = position.play(
        moves.single,
        TavlaSide.white,
      );
      expect(entered.whiteBar, 0);
      expect(entered.points[23], 1);
    });

    test('a blot is hit to the bar; a made point blocks the landing', () {
      final List<int> points = List<int>.filled(24, 0);
      points[8] = 1;
      points[6] = -1;
      final TavlaPosition blot = TavlaPosition(
        points: points,
        whiteBar: 0,
        blackBar: 0,
        whiteOff: 14,
        blackOff: 14,
      );
      final TavlaMove hit = blot.legalMovesForDie(TavlaSide.white, 2).single;
      final TavlaPosition afterHit = blot.play(hit, TavlaSide.white);
      expect(hit.hit, isTrue);
      expect(afterHit.points[6], 1);
      expect(afterHit.blackBar, 1);

      final List<int> blockedPoints = List<int>.of(points)..[6] = -2;
      final TavlaPosition blocked = TavlaPosition(
        points: blockedPoints,
        whiteBar: 0,
        blackBar: 0,
        whiteOff: 14,
        blackOff: 13,
      );
      expect(
        blocked
            .legalMovesForDie(TavlaSide.white, 2)
            .any((TavlaMove move) => move.to == 6),
        isFalse,
      );
    });

    test('bearing off requires a home board and honors overshoot rules', () {
      final List<int> home = List<int>.filled(24, 0);
      home[0] = 1;
      home[5] = 1;
      home[18] = -1;
      final TavlaPosition exact = TavlaPosition(
        points: home,
        whiteBar: 0,
        blackBar: 0,
        whiteOff: 13,
        blackOff: 14,
      );
      expect(
        exact
            .legalMovesForDie(TavlaSide.white, 6)
            .any((TavlaMove move) => move.from == 5 && move.bearOff),
        isTrue,
      );

      final List<int> fartherChecker = List<int>.filled(24, 0)
        ..[0] = 1
        ..[4] = 1
        ..[18] = -1;
      final TavlaPosition overshoot = TavlaPosition(
        points: fartherChecker,
        whiteBar: 0,
        blackBar: 0,
        whiteOff: 13,
        blackOff: 14,
      );
      expect(
        overshoot
            .legalMovesForDie(TavlaSide.white, 6)
            .any((TavlaMove move) => move.from == 0 && move.bearOff),
        isFalse,
      );
      expect(() => exact.legalMovesForDie(TavlaSide.white, 0), returnsNormally);
    });

    test('when only one die can be played, the higher die is compulsory', () {
      final List<int> points = List<int>.filled(24, 0)
        ..[10] = 1
        ..[3] = -2;
      final TavlaPosition position = TavlaPosition(
        points: points,
        whiteBar: 0,
        blackBar: 0,
        whiteOff: 14,
        blackOff: 13,
      );

      final List<List<TavlaMove>> turns = position.legalTurnSequences(
        TavlaSide.white,
        2,
        5,
      );
      expect(turns, hasLength(1));
      expect(turns.single, hasLength(1));
      expect(turns.single.single.die, 5);
      expect(turns.single.single.to, 5);
    });

    test('a completed match cannot accept moves from the losing side', () {
      final List<int> points = List<int>.filled(24, 0)..[10] = -1;
      final TavlaPosition finished = TavlaPosition(
        points: points,
        whiteBar: 0,
        blackBar: 0,
        whiteOff: 15,
        blackOff: 14,
      );
      expect(finished.legalMovesForDie(TavlaSide.black, 1), isEmpty);
      expect(
        finished.legalTurnSequences(TavlaSide.black, 1, 2),
        <List<TavlaMove>>[<TavlaMove>[]],
      );
    });
  });

  group('Tavla 20 seviye ve tekrar oynanış', () {
    test('20 erişilebilir ve benzersiz başlangıç konumu üretilir', () {
      final List<TavlaScenario> scenarios = <TavlaScenario>[
        for (int level = 1; level <= TavlaScenario.maximumLevels; level++)
          TavlaScenario.forLevel(level),
      ];
      expect(
        scenarios.map((TavlaScenario scenario) => scenario.signature).toSet(),
        hasLength(20),
      );
      for (final TavlaScenario scenario in scenarios) {
        expect(scenario.sideToMove, TavlaSide.white);
        expect(
          scenario.position.checkersOnBoard(TavlaSide.white) +
              scenario.position.whiteBar +
              scenario.position.whiteOff,
          15,
        );
        expect(
          scenario.position.checkersOnBoard(TavlaSide.black) +
              scenario.position.blackBar +
              scenario.position.blackOff,
          15,
        );
        expect(
          scenario.position
              .legalTurnSequences(
                scenario.sideToMove,
                scenario.dieA,
                scenario.dieB,
              )
              .any((List<TavlaMove> sequence) => sequence.isNotEmpty),
          isTrue,
        );
      }
    });

    test('ilk 300 pratik konumu benzersiz ve yasal zar sırasına sahiptir', () {
      final Set<String> signatures = <String>{};
      for (
        int index = 1;
        index <= TavlaScenario.maximumVerifiedBoards;
        index++
      ) {
        final TavlaScenario scenario = TavlaScenario.forPracticeBoard(index);
        signatures.add(scenario.signature);
        expect(scenario.sideToMove, TavlaSide.white);
        expect(
          scenario.position
              .legalTurnSequences(
                scenario.sideToMove,
                scenario.dieA,
                scenario.dieB,
              )
              .any((List<TavlaMove> sequence) => sequence.isNotEmpty),
          isTrue,
        );
      }
      expect(signatures, hasLength(TavlaScenario.maximumVerifiedBoards));
      expect(() => TavlaScenario.forPracticeBoard(301), throwsRangeError);
    });

    test('ileri ve usta zorluk kapıları sabittir', () {
      expect(TavlaScenario.forLevel(7).difficultyTier, 'ADVANCED');
      expect(TavlaScenario.forLevel(8).difficultyTier, 'ADVANCED');
      expect(TavlaScenario.forLevel(9).difficultyTier, 'EXPERT');
      expect(TavlaScenario.forLevel(10).difficultyTier, 'EXPERT');
      expect(TavlaScenario.forLevel(17).difficultyTier, 'MASTER');
      expect(TavlaScenario.forLevel(20).difficultyTier, 'MASTER');
    });

    test('uzman ve usta rakipleri yasal, ileri bakışlı hamle seçer', () {
      final TavlaScenario scenario = TavlaScenario.forLevel(17);
      final List<List<TavlaMove>> legalTurns = scenario.position
          .legalTurnSequences(
            scenario.sideToMove,
            scenario.dieA,
            scenario.dieB,
          );
      final List<TavlaMove> expert = TavlaEngine.chooseTurn(
        scenario.position,
        scenario.sideToMove,
        legalTurns,
        strategyLevel: 9,
      );
      final List<TavlaMove> master = TavlaEngine.chooseTurn(
        scenario.position,
        scenario.sideToMove,
        legalTurns,
        strategyLevel: 17,
      );

      expect(legalTurns, contains(expert));
      expect(legalTurns, contains(master));
      expect(expert, isNotEmpty);
      expect(master, isNotEmpty);
    });
  });
}
