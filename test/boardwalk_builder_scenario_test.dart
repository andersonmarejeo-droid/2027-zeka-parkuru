import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/boardwalk_builder/boardwalk_engine.dart';
import 'package:zeka_parkuru/games/boardwalk_builder/boardwalk_scenario.dart';

void main() {
  test('20 authored parks ramp guests, network pieces and storm planning', () {
    final List<BoardwalkScenario> levels = List<BoardwalkScenario>.generate(
      BoardwalkScenario.campaignLevels,
      (int index) => BoardwalkScenario.forLevel(index + 1),
    );
    expect(levels, hasLength(20));
    expect(
      levels.first.requiredBuilds.length,
      lessThan(levels.last.requiredBuilds.length),
    );
    expect(
      levels[8].requiredBuilds.where((BoardwalkBuild item) => item.isRide),
      hasLength(2),
    );
    expect(levels.last.visitorCount, greaterThan(levels.first.visitorCount));
    expect(levels.last.width, 8);
    expect(levels.last.height, 8);
    for (final BoardwalkScenario scenario in levels) {
      final BoardwalkEngine engine = _solve(scenario);
      final BoardwalkEvaluation result = engine.evaluate();
      expect(
        result.canOpen,
        isTrue,
        reason: 'level ${scenario.level}: $result',
      );
      expect(result.requiredPlaced, scenario.requiredBuilds.length);
      expect(result.connectedBuildings, result.buildingCount);
      expect(result.budgetUsed, lessThanOrEqualTo(scenario.budget));
      if (scenario.weather == BoardwalkWeather.shower) {
        expect(result.shelterReady, isTrue);
      }
    }
  });

  test('300 practice park layouts are distinct without relying on seed', () {
    final List<BoardwalkScenario> parks = List<BoardwalkScenario>.generate(
      BoardwalkScenario.practiceParks,
      (int index) => BoardwalkScenario.forPractice(index + 1),
    );
    expect(
      parks.map((BoardwalkScenario park) => park.signature).toSet(),
      hasLength(300),
    );
    expect(
      parks.map((BoardwalkScenario park) => park.layoutSignature).toSet(),
      hasLength(300),
    );
    expect(
      parks.map((BoardwalkScenario park) => park.layoutSignature),
      List<String>.generate(
        300,
        (int index) => BoardwalkScenario.forPractice(index + 1).layoutSignature,
      ),
    );
    for (final BoardwalkScenario scenario in parks) {
      expect(
        _solve(scenario).evaluate().canOpen,
        isTrue,
        reason: 'practice ${scenario.seed}',
      );
    }
  });
}

BoardwalkEngine _solve(BoardwalkScenario scenario) {
  final BoardwalkEngine engine = BoardwalkEngine(scenario: scenario);
  final int center = scenario.width ~/ 2;
  for (int y = scenario.height - 2; y >= 0; y--) {
    final BoardwalkActionResult result = engine.place(
      BoardwalkBuild.path,
      BoardwalkCell(center, y),
    );
    expect(
      result.accepted,
      isTrue,
      reason: 'path $center:$y, level ${scenario.level}',
    );
  }
  for (int index = 0; index < scenario.requiredBuilds.length; index++) {
    final int x = center + (index.isEven ? -1 : 1);
    final int y = index ~/ 2;
    final BoardwalkActionResult result = engine.place(
      scenario.requiredBuilds[index],
      BoardwalkCell(x, y),
    );
    expect(
      result.accepted,
      isTrue,
      reason: 'build $index, level ${scenario.level}',
    );
  }
  return engine;
}
