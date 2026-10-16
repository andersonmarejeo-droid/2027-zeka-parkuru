import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/reversi_arena/reversi_engine.dart';
import 'package:zeka_parkuru/games/reversi_arena/reversi_scenario.dart';

void main() {
  group('Reversi kuralları', () {
    test(
      'standart başlangıçta dört yasal hamle ve doğru taş çevirme vardır',
      () {
        final ReversiPosition opening = ReversiPosition.standard();
        expect(opening.darkCount, 2);
        expect(opening.lightCount, 2);
        expect(opening.legalMoves(), hasLength(4));

        final ReversiPosition next = opening.play(opening.legalMoves().first);
        expect(next.toMove, ReversiStone.light);
        expect(next.darkCount, 4);
        expect(next.lightCount, 1);
        expect(() => opening.play(0), throwsArgumentError);
      },
    );

    test('zorunlu pas rakip hamlesiyle devam eder, çift pas oyunu bitirir', () {
      final List<int> board = List<int>.filled(64, ReversiStone.dark);
      board[1] = ReversiStone.light;
      board[3] = ReversiStone.empty;
      final ReversiPosition noDarkMove = ReversiPosition(
        board: board,
        toMove: ReversiStone.dark,
      );

      expect(noDarkMove.legalMoves(), isEmpty);
      final ReversiTurnResolution pass = resolveReversiTurn(noDarkMove);
      expect(pass.passed, isTrue);
      expect(pass.ended, isFalse);
      expect(pass.position.toMove, ReversiStone.light);
      expect(pass.position.legalMoves(), <int>[3]);

      final ReversiTurnResolution end = resolveReversiTurn(
        pass.position.play(3),
      );
      expect(end.ended, isTrue);
      expect(end.position.occupiedCount, 64);
    });

    test('tam oyun rastgele yasal hamlelerle sınırlı sayıda biter', () {
      ReversiPosition position = ReversiPosition.standard();
      final math.Random random = math.Random(81723);
      int turns = 0;
      while (!position.isTerminal && turns < 120) {
        final List<int> moves = position.legalMoves();
        if (moves.isEmpty) {
          position = resolveReversiTurn(position).position;
          continue;
        }
        position = resolveReversiTurn(
          position.play(moves[random.nextInt(moves.length)]),
        ).position;
        turns++;
      }
      expect(position.isTerminal, isTrue);
      expect(position.occupiedCount, 64);
      expect(turns, lessThanOrEqualTo(60));
    });

    test('arama motoru yasal hamle döndürür ve seed ile tekrarlanır', () {
      final ReversiPosition position = ReversiPosition.standard();
      final int first = ReversiEngine.chooseMove(
        position,
        player: ReversiStone.dark,
        difficulty: 9,
        seed: 129,
      );
      final int repeated = ReversiEngine.chooseMove(
        position,
        player: ReversiStone.dark,
        difficulty: 9,
        seed: 129,
      );
      expect(position.legalMoves(), contains(first));
      expect(repeated, first);
    });
  });

  group('Reversi 20 maçlık kampanya', () {
    test('20 başlangıç yasal, tekrarsız ve aynı seed ile kararlıdır', () {
      final Set<String> signatures = <String>{};
      for (int level = 1; level <= ReversiScenario.maximumLevels; level++) {
        final ReversiScenario scenario = ReversiScenario.forLevel(level);
        expect(scenario.position.toMove, ReversiStone.dark);
        expect(scenario.position.legalMoves(), isNotEmpty);
        expect(scenario.position.isTerminal, isFalse);
        expect(scenario.position.occupiedCount, 4 + scenario.openingMoves);
        expect(
          signatures.add(scenario.boardSignature),
          isTrue,
          reason: 'tekrarlanan tahta: seviye $level',
        );
        expect(
          ReversiScenario.forLevel(level).boardSignature,
          scenario.boardSignature,
        );
      }
      expect(signatures, hasLength(20));
    });

    test('ilk ve ikinci bölümün ileri/uzman eşiği korunur', () {
      expect(ReversiScenario.forLevel(7).difficultyTier, 'İLERİ');
      expect(ReversiScenario.forLevel(8).difficultyTier, 'İLERİ');
      expect(ReversiScenario.forLevel(9).difficultyTier, 'UZMAN');
      expect(ReversiScenario.forLevel(10).difficultyTier, 'UZMAN');
      expect(ReversiScenario.forLevel(19).difficultyTier, 'UZMAN');
      expect(ReversiScenario.forLevel(20).difficultyTier, 'UZMAN');
      expect(() => ReversiScenario.forLevel(0), throwsRangeError);
      expect(() => ReversiScenario.forLevel(21), throwsRangeError);
    });
  });
}
