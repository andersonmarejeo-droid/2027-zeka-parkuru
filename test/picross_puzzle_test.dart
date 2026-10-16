import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/picross_master/picross_puzzle.dart';

void main() {
  group('Picross Ustası kampanyası', () {
    test('20 seviye sabit, artan boyutlu ve benzersiz tahtalar üretir', () {
      final List<PicrossPuzzle> boards = <PicrossPuzzle>[
        for (int level = 1; level <= PicrossPuzzle.maximumLevels; level++)
          PicrossPuzzle.forLevel(level),
      ];

      expect(boards, hasLength(20));
      expect(
        boards.map((PicrossPuzzle board) => board.boardSignature).toSet(),
        hasLength(20),
      );
      expect(
        boards.map((PicrossPuzzle board) => board.size).toList(),
        orderedEquals(<int>[
          5,
          5,
          6,
          6,
          7,
          7,
          8,
          8,
          9,
          9,
          10,
          10,
          11,
          11,
          12,
          12,
          13,
          13,
          14,
          15,
        ]),
      );
      expect(
        boards.every((PicrossPuzzle board) => board.solutionCount() == 1),
        isTrue,
      );
    });

    test('300 ardışık pratik tahtasının her biri farklı ve tek çözümlüdür', () {
      final Set<String> signatures = <String>{};
      for (
        int index = 1;
        index <= PicrossPuzzle.maximumVerifiedBoards;
        index++
      ) {
        final PicrossPuzzle board = PicrossPuzzle.forPracticeBoard(index);
        signatures.add(board.boardSignature);
      }
      expect(signatures, hasLength(PicrossPuzzle.maximumVerifiedBoards));
      expect(() => PicrossPuzzle.forPracticeBoard(301), throwsRangeError);
    });

    test('ileri ve usta kapıları 7–10 ile 17–20 arasında korunur', () {
      expect(PicrossPuzzle.forLevel(7).difficultyTier, 'ADVANCED');
      expect(PicrossPuzzle.forLevel(8).difficultyTier, 'ADVANCED');
      expect(PicrossPuzzle.forLevel(9).difficultyTier, 'EXPERT');
      expect(PicrossPuzzle.forLevel(10).difficultyTier, 'EXPERT');
      expect(PicrossPuzzle.forLevel(17).difficultyTier, 'MASTER');
      expect(PicrossPuzzle.forLevel(20).difficultyTier, 'MASTER');
      expect(() => PicrossPuzzle.forLevel(0), throwsRangeError);
      expect(() => PicrossPuzzle.forLevel(21), throwsRangeError);
    });
  });
}
