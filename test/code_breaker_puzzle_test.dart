import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/code_breaker/code_breaker_puzzle.dart';

void main() {
  group('Kod Kırıcı geri bildirim motoru', () {
    test('yerindeki ve yeri yanlış sembolleri tekrarları saymadan eşler', () {
      final CodeBreakerPuzzle puzzle = CodeBreakerPuzzle.forLevel(1);
      final List<int> secret = <int>[0, 0, 1, 2];
      expect(
        CodeBreakerPuzzle.scoreGuess(
          secret: secret,
          guess: <int>[0, 1, 0, 0],
          paletteSize: 6,
        ),
        const CodeFeedback(exact: 1, misplaced: 2),
      );
      expect(puzzle.isSolved(puzzle.secret), isTrue);
      expect(puzzle.isValidGuess(<int>[0, 1, 2, 3]), isTrue);
      final CodeBreakerPuzzle distinct = CodeBreakerPuzzle.forLevel(4);
      expect(distinct.isValidGuess(<int>[0, 0, 2, 3]), isFalse);
    });

    test(
      'tekrarsız kuralı ve olasılık uzayı matematiksel olarak tutarlıdır',
      () {
        final CodeBreakerPuzzle puzzle = CodeBreakerPuzzle.forLevel(4);
        expect(puzzle.repeatsAllowed, isFalse);
        expect(puzzle.searchSpace, 7 * 6 * 5 * 4);
        expect(puzzle.isValidGuess(puzzle.secret), isTrue);
        expect(puzzle.secret.toSet(), hasLength(puzzle.slots));
      },
    );
  });

  group('Kod Kırıcı içerik sertifikası', () {
    test('20 kampanya kodu kademeli yuva, palet ve kural taşır', () {
      final List<CodeBreakerPuzzle> puzzles = <CodeBreakerPuzzle>[
        for (int level = 1; level <= CodeBreakerPuzzle.maximumLevels; level++)
          CodeBreakerPuzzle.forLevel(level),
      ];
      expect(
        puzzles.map((CodeBreakerPuzzle puzzle) => puzzle.signature).toSet(),
        hasLength(20),
      );
      for (final CodeBreakerPuzzle puzzle in puzzles) {
        expect(puzzle.isValidGuess(puzzle.secret), isTrue);
        expect(puzzle.isSolved(puzzle.secret), isTrue);
        expect(puzzle.searchSpace, greaterThan(100));
      }
      expect(CodeBreakerPuzzle.forLevel(7).slots, 5);
      expect(CodeBreakerPuzzle.forLevel(9).difficultyTier, 'EXPERT');
      expect(
        CodeBreakerPuzzle.forLevel(10).searchSpace,
        greaterThan(CodeBreakerPuzzle.forLevel(8).searchSpace),
      );
      expect(
        CodeBreakerPuzzle.forLevel(17).searchSpace,
        greaterThan(CodeBreakerPuzzle.forLevel(10).searchSpace),
      );
      expect(CodeBreakerPuzzle.forLevel(19).paletteSize, 10);
    });

    test('ilk 300 tekrar kodu kampanya ve kendi arasında tekrarsızdır', () {
      final Set<String> signatures = <String>{
        for (int level = 1; level <= CodeBreakerPuzzle.maximumLevels; level++)
          CodeBreakerPuzzle.forLevel(level).signature,
      };
      for (
        int index = 1;
        index <= CodeBreakerPuzzle.maximumVerifiedBoards;
        index++
      ) {
        final CodeBreakerPuzzle puzzle = CodeBreakerPuzzle.forPracticeBoard(
          index,
        );
        expect(signatures.add(puzzle.signature), isTrue, reason: 'Code $index');
        expect(puzzle.isSolved(puzzle.secret), isTrue);
      }
      expect(signatures, hasLength(320));
      expect(() => CodeBreakerPuzzle.forPracticeBoard(301), throwsRangeError);
    });
  });
}
