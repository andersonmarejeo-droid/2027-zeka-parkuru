import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/boardwalk_builder/boardwalk_engine.dart';
import 'package:zeka_parkuru/games/boardwalk_builder/boardwalk_scenario.dart';

void main() {
  test(
    'entrance, rock, occupied tile and budget constraints are protected',
    () {
      final BoardwalkScenario scenario = BoardwalkScenario.forLevel(1);
      final BoardwalkEngine engine = BoardwalkEngine(scenario: scenario);
      expect(
        engine.place(BoardwalkBuild.path, scenario.entry).reason,
        'entry_reserved',
      );
      final BoardwalkCell rock = scenario.blockedCells.first;
      expect(engine.place(BoardwalkBuild.path, rock).reason, 'blocked');
      final BoardwalkCell free = BoardwalkCell(1, 1);
      expect(engine.place(BoardwalkBuild.path, free).accepted, isTrue);
      expect(engine.place(BoardwalkBuild.bench, free).reason, 'occupied');

      final BoardwalkScenario tiny = BoardwalkScenario(
        level: 1,
        seed: 1,
        width: 7,
        height: 7,
        budget: 3,
        visitorCount: 1,
        requiredBuilds: const <BoardwalkBuild>[],
        minimumBins: 0,
        minimumBenches: 0,
        weather: BoardwalkWeather.clear,
        blockedCells: const <BoardwalkCell>[],
      );
      expect(
        BoardwalkEngine(scenario: tiny)
            .place(BoardwalkBuild.path, const BoardwalkCell(2, 2))
            .reason,
        'over_budget',
      );
    },
  );

  test('undo and redo restore the park layout and access evaluation', () {
    final BoardwalkScenario scenario = BoardwalkScenario.forLevel(1);
    final BoardwalkEngine engine = BoardwalkEngine(scenario: scenario);
    final BoardwalkCell cell = BoardwalkCell(
      scenario.width ~/ 2,
      scenario.height - 2,
    );
    expect(engine.place(BoardwalkBuild.path, cell).accepted, isTrue);
    expect(engine.placements, hasLength(1));
    expect(engine.undo(), isTrue);
    expect(engine.placements, isEmpty);
    expect(engine.redo(), isTrue);
    expect(engine.placements.single.cell, cell);
  });
}
