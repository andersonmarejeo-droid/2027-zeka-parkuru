import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/detective_notes/detective_notes_puzzle.dart';
import 'package:zeka_parkuru/games/shared/studio_game_contracts.dart';

void main() {
  test('30-chapter detective guidance gradually gives way to deduction', () {
    int previousBudget = 8;
    final signatures = <String>{};
    for (int chapter = 1; chapter <= 30; chapter++) {
      final budget = DetectiveNotesPuzzle.guidedFactBudgetForChapter(chapter);
      expect(budget, lessThanOrEqualTo(previousBudget));
      previousBudget = budget;
      for (int variant = 0; variant < 10; variant++) {
        final puzzle = DetectiveNotesPuzzle.forLevel(
          (chapter - 1) * 10 + variant + 1,
          progressive: true,
        );
        expect(
          puzzle.hasUniqueSolution,
          isTrue,
          reason: 'chapter $chapter variant $variant',
        );
        expect(
          puzzle.clues.every((clue) => clue.matches(puzzle.solution)),
          isTrue,
        );
        expect(
          signatures.add(
            '${puzzle.solution.personAtSeat}|${puzzle.solution.relicByPerson}|${puzzle.solution.roomByPerson}',
          ),
          isTrue,
        );
      }
    }
    expect(previousBudget, 0);
    expect(signatures, hasLength(300));
  });

  test('300 detective cases have distinct boards and unique solutions', () {
    final Set<String> boardSignatures = <String>{};
    for (int level = 1; level <= 300; level++) {
      final DetectiveNotesPuzzle puzzle = DetectiveNotesPuzzle.forLevel(level);

      expect(puzzle.clues.length, greaterThanOrEqualTo(5));
      expect(puzzle.clues.length, lessThanOrEqualTo(30));
      expect(
        puzzle.clues.every(
          (DetectiveClue clue) => clue.matches(puzzle.solution),
        ),
        isTrue,
      );
      expect(puzzle.hasUniqueSolution, isTrue, reason: 'case $level');
      expect(puzzle.solution.relicByPerson.toSet(), equals(<int>{0, 1, 2, 3}));
      expect(puzzle.solution.roomByPerson.toSet(), equals(<int>{0, 1, 2, 3}));
      boardSignatures.add(
        '${puzzle.solution.personAtSeat}|'
        '${puzzle.solution.relicByPerson}|'
        '${puzzle.solution.roomByPerson}',
      );
    }
    expect(boardSignatures, hasLength(300));
    expect(
      DetectiveNotesPuzzle.maximumUniqueCases,
      greaterThanOrEqualTo(GameContentPolicy.minimumUniqueRounds),
    );
  });

  test('campaign cases vary each deduction axis and label pack', () {
    final Set<String> seatPatterns = <String>{};
    final Set<String> relicPatterns = <String>{};
    final Set<String> roomPatterns = <String>{};
    final Set<String> peopleSets = <String>{};

    for (int level = 1; level <= 300; level++) {
      final DetectiveNotesPuzzle puzzle = DetectiveNotesPuzzle.forLevel(level);
      seatPatterns.add(puzzle.solution.personAtSeat.toString());
      relicPatterns.add(puzzle.solution.relicByPerson.toString());
      roomPatterns.add(puzzle.solution.roomByPerson.toString());
      peopleSets.add(puzzle.labels.people.join('|'));
    }

    expect(seatPatterns, hasLength(24));
    expect(relicPatterns, hasLength(24));
    expect(roomPatterns, hasLength(24));
    expect(peopleSets.length, greaterThan(1));
  });

  test('clue copy is localized with the matching evidence names', () {
    const DetectiveClue clue = DetectiveClue(
      kind: DetectiveClueKind.personRelic,
      first: 0,
      second: 0,
    );
    expect(clue.text(english: true), contains('Amber Compass'));
    expect(clue.text(english: false), contains('Kehribar Pusula'));

    final DetectiveNotesLabels labels =
        DetectiveNotesPuzzle.forLevel(2).labels;
    const DetectiveClue roomClue = DetectiveClue(
      kind: DetectiveClueKind.personRoom,
      first: 0,
      second: 2,
    );
    expect(
      roomClue.text(english: false, labels: labels),
      contains(labels.roomsTr[2]),
    );
  });

  test(
    'the case stays open until every person has one correct relic and room',
    () {
      final DetectiveNotesPuzzle puzzle = DetectiveNotesPuzzle.forLevel(3);
      final List<List<DetectiveMark>> relics =
          List<List<DetectiveMark>>.generate(
            4,
            (_) => List<DetectiveMark>.filled(4, DetectiveMark.unknown),
          );
      final List<List<DetectiveMark>> rooms =
          List<List<DetectiveMark>>.generate(
            4,
            (_) => List<DetectiveMark>.filled(4, DetectiveMark.unknown),
          );
      final List<List<DetectiveMark>> seats =
          List<List<DetectiveMark>>.generate(
            4,
            (_) => List<DetectiveMark>.filled(4, DetectiveMark.unknown),
          );

      expect(puzzle.isSolved(relics, rooms, seats), isFalse);
      for (int person = 0; person < 4; person++) {
        relics[person][puzzle.solution.relicByPerson[person]] =
            DetectiveMark.confirmed;
        rooms[person][puzzle.solution.roomByPerson[person]] =
            DetectiveMark.confirmed;
        seats[person][puzzle.solution.seatOfPerson(person)] =
            DetectiveMark.confirmed;
      }
      expect(puzzle.isSolved(relics, rooms, seats), isTrue);

      relics[0][puzzle.solution.relicByPerson[0]] = DetectiveMark.crossed;
      expect(puzzle.isSolved(relics, rooms, seats), isFalse);
    },
  );
}
