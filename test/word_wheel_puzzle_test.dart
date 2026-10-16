import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/word_wheel/word_wheel_game_page.dart';
import 'package:zeka_parkuru/games/word_wheel/word_wheel_puzzle.dart';

void main() {
  group('Word Wheel campaign quality', () {
    test('connector follows selection order after wheel rotation', () {
      expect(wordWheelDisplayPath(<int>[2, 0, 1], <int>[1, 2, 0]), <int>[
        2,
        0,
        1,
      ]);
    });

    for (final String locale in <String>['tr', 'en']) {
      test('$locale campaign has 20 stable, distinct, buildable wheels', () {
        final Set<String> signatures = <String>{};
        for (int level = 1; level <= WordWheelPuzzle.maximumLevels; level++) {
          final WordWheelPuzzle puzzle = WordWheelPuzzle.forLevel(
            level,
            languageCode: locale,
          );
          expect(puzzle.level, level);
          expect(puzzle.answers, isNotEmpty);
          expect(puzzle.answers.toSet(), hasLength(puzzle.answers.length));
          expect(
            signatures.add(puzzle.boardSignature),
            isTrue,
            reason: 'level $level',
          );
          for (final String answer in puzzle.answers) {
            expect(puzzle.containsWord(answer), isTrue);
            expect(
              _canBuild(answer, puzzle.wheelLetters),
              isTrue,
              reason: '$locale $level $answer',
            );
          }
          expect(
            WordWheelPuzzle.forLevel(
              level,
              languageCode: locale,
            ).boardSignature,
            puzzle.boardSignature,
          );
          expect(puzzle.difficultyTier, isNotEmpty);
        }
      });
    }

    test('second chapter adds decoy letters and the last stage is expert', () {
      for (final String locale in <String>['tr', 'en']) {
        final WordWheelPuzzle first = WordWheelPuzzle.forLevel(
          1,
          languageCode: locale,
        );
        final WordWheelPuzzle second = WordWheelPuzzle.forLevel(
          11,
          languageCode: locale,
        );
        expect(second.chapter, 2);
        expect(
          second.wheelLetters.length,
          greaterThan(first.wheelLetters.length),
        );
        for (final int level in <int>[7, 8, 9, 10, 17, 18, 19, 20]) {
          expect(
            WordWheelPuzzle.forLevel(
              level,
              languageCode: locale,
            ).difficultyTier,
            'EXPERT',
          );
        }
      }
    });

    test('every wheel answer can be built from its letters exactly once', () {
      final WordWheelPuzzle puzzle = WordWheelPuzzle.forLevel(1);
      for (final String answer in puzzle.answers) {
        expect(_canBuild(answer, puzzle.wheelLetters), isTrue, reason: answer);
      }
      expect(puzzle.validWords, containsAll(puzzle.answers));
      expect(
        puzzle.validWords.any((String word) => !puzzle.answers.contains(word)),
        isTrue,
      );
    });

    test('Turkish dotless ı words are accepted with locale-aware casing', () {
      final WordWheelPuzzle puzzle = WordWheelPuzzle.forLevel(7);

      expect(puzzle.anchor, 'SATIR');
      expect(puzzle.answers, contains('SIRT'));
      expect(puzzle.validWords, contains('SIRT'));
      expect(puzzle.containsWord('sırt'), isTrue);
      expect(puzzle.containsWord('SIRT'), isTrue);
      expect(puzzle.containsWord('sirt'), isFalse);
    });

    test('wider vocabulary accepts buildable bonus words without changing targets', () {
      final WordWheelPuzzle puzzle = WordWheelPuzzle.forLevel(1);

      // KALEM's campaign pack does not list ALEM as a target/bonus entry, but
      // it is a real word and every letter is available on the wheel.
      expect(puzzle.answers, isNot(contains('ALEM')));
      expect(puzzle.validWords, isNot(contains('ALEM')));
      expect(puzzle.isKnownWord('alem'), isTrue);
      expect(puzzle.containsWord('alem'), isTrue);
      expect(puzzle.canBuildWord('alem'), isTrue);
      expect(puzzle.canBuildWord('KAMERA'), isFalse);
      expect(puzzle.isTargetWord('alem'), isFalse);
    });

    test('joker supplies one missing letter to a known bonus word', () {
      final WordWheelPuzzle puzzle = WordWheelPuzzle.forLevel(1);

      expect(puzzle.canBuildWord('KALP', jokerLetter: 'P'), isTrue);
      expect(puzzle.canBuildWord('KALP', jokerLetter: 'Z'), isFalse);
    });

    test('Turkish campaign bonus words are buildable and not duplicated', () {
      for (int level = 1; level <= WordWheelPuzzle.maximumLevels; level++) {
        final WordWheelPuzzle puzzle = WordWheelPuzzle.forLevel(level);
        expect(
          puzzle.validWords.toSet(),
          hasLength(puzzle.validWords.length),
          reason: 'level $level has duplicate bonus words',
        );
        for (final String word in puzzle.validWords) {
          expect(
            _canBuild(word, puzzle.wheelLetters),
            isTrue,
            reason: 'Turkish level $level contains an unbuildable word: $word',
          );
        }
      }
    });

    test('700-round pool is unique and grows harder without cycling', () {
      for (final String locale in <String>['tr', 'en']) {
        final Set<String> signatures = <String>{};
        int previousStage = 0;
        int previousTargets = 0;
        for (int index = 1; index <= WordWheelPuzzle.poolSize; index++) {
          final WordWheelPuzzle puzzle = WordWheelPuzzle.forPool(
            index,
            languageCode: locale,
          );
          expect(
            signatures.add(puzzle.contentSignature),
            isTrue,
            reason: '$locale content $index repeats',
          );
          expect(puzzle.stageInChapter, greaterThanOrEqualTo(previousStage));
          expect(puzzle.targetCount, greaterThanOrEqualTo(previousTargets));
          expect(
            puzzle.answers.every((String word) => word.runes.length >= 2),
            isTrue,
          );
          previousStage = puzzle.stageInChapter;
          previousTargets = puzzle.targetCount;
        }
      }
    });
  });
}

bool _canBuild(String word, List<String> wheel) {
  final Map<String, int> counts = <String, int>{};
  for (final String letter in wheel) {
    counts.update(letter, (int value) => value + 1, ifAbsent: () => 1);
  }
  for (final int rune in word.runes) {
    final String letter = String.fromCharCode(rune);
    final int count = counts[letter] ?? 0;
    if (count == 0) return false;
    counts[letter] = count - 1;
  }
  return true;
}
