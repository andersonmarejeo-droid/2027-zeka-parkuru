import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/festival_producer/festival_engine.dart';
import 'package:zeka_parkuru/games/festival_producer/festival_scenario.dart';

void main() {
  test('20 festival days grow from three to eight bookable sets', () {
    final List<FestivalScenario> days = List<FestivalScenario>.generate(
      FestivalScenario.campaignLevels,
      (int index) => FestivalScenario.forLevel(index + 1),
    );
    expect(days, hasLength(20));
    expect(days.first.showCount, 3);
    expect(days.last.showCount, 8);
    expect(days[6].turnaroundGap, 1);
    for (final FestivalScenario scenario in days) {
      expect(
        scenario.performances.map((FestivalPerformance p) => p.id).toSet(),
        hasLength(scenario.performances.length),
      );
      expect(
        _solve(scenario).evaluate().canPublish,
        isTrue,
        reason: '${scenario.level}: ${scenario.weather}',
      );
    }
  });

  test('300 practice festivals are structurally distinct and solvable', () {
    final List<FestivalScenario> days = List<FestivalScenario>.generate(
      FestivalScenario.practiceFestivals,
      (int index) => FestivalScenario.forPractice(index + 1),
    );
    expect(
      days.map((FestivalScenario day) => day.signature).toSet(),
      hasLength(300),
    );
    expect(
      days.map((FestivalScenario day) => day.layoutSignature).toSet(),
      hasLength(300),
    );
    for (final FestivalScenario scenario in days) {
      expect(
        _solve(scenario).evaluate().canPublish,
        isTrue,
        reason: '${scenario.seed}',
      );
    }
  });
}

FestivalEngine _solve(FestivalScenario scenario) {
  final FestivalEngine engine = FestivalEngine(scenario: scenario);
  for (int index = 0; index < scenario.showCount; index++) {
    final FestivalActionResult result = engine.place(
      performanceIndex: index,
      stage: index.isEven ? 0 : 1,
      block: index,
    );
    expect(result.accepted, isTrue, reason: 'set $index, time window');
  }
  return engine;
}
