import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/museum_curator/curator_engine.dart';
import 'package:zeka_parkuru/games/museum_curator/curator_scenario.dart';

void main() {
  test('20 exhibition briefs increase collection complexity and solve cleanly', () {
    final List<CuratorScenario> levels = List<CuratorScenario>.generate(
      CuratorScenario.campaignLevels,
      (int index) => CuratorScenario.forLevel(index + 1),
    );
    expect(levels, hasLength(20));
    expect(levels.first.slotCount, 3);
    expect(levels[8].slotCount, 5);
    expect(levels.last.slotCount, 7);
    for (final CuratorScenario scenario in levels) {
      final CuratorEvaluation result = _solve(scenario).evaluate();
      expect(
        result.canOpen,
        isTrue,
        reason:
            '${scenario.level} ${scenario.theme}: ${result.placed}/${result.slots} theme ${result.themeFit} order ${result.chronologyFit} fragile ${result.fragileCount}/${result.fragileLimit} appeal ${result.visitorAppeal}/${result.visitorTarget} budget ${result.budgetUsed}/${result.budget}',
      );
    }
  });

  test('300 practice collection plans differ beyond the random seed', () {
    final List<CuratorScenario> plans = List<CuratorScenario>.generate(
      CuratorScenario.practiceExhibitions,
      (int index) => CuratorScenario.forPractice(index + 1),
    );
    expect(
      plans.map((CuratorScenario plan) => plan.signature).toSet(),
      hasLength(300),
    );
    expect(
      plans.map((CuratorScenario plan) => plan.layoutSignature).toSet(),
      hasLength(300),
    );
    for (final CuratorScenario scenario in plans) {
      final CuratorEvaluation result = _solve(scenario).evaluate();
      expect(
        result.canOpen,
        isTrue,
        reason:
            '${scenario.seed}: ${result.placed}/${result.slots} theme ${result.themeFit} order ${result.chronologyFit} fragile ${result.fragileCount}/${result.fragileLimit} appeal ${result.visitorAppeal}/${result.visitorTarget} budget ${result.budgetUsed}/${result.budget}',
      );
    }
  });
}

CuratorEngine _solve(CuratorScenario scenario) {
  final CuratorEngine engine = CuratorEngine(scenario: scenario);
  final List<CuratorArtifact> solution =
      scenario.collection
          .where(
            (CuratorArtifact artifact) =>
                artifact.themes.contains(scenario.theme),
          )
          .toList()
        ..sort((CuratorArtifact a, CuratorArtifact b) {
          final int eraOrder = a.era.compareTo(b.era);
          return eraOrder == 0 ? a.id.compareTo(b.id) : eraOrder;
        });
  for (int slot = 0; slot < scenario.slotCount; slot++) {
    expect(engine.place(slot, solution[slot]).accepted, isTrue);
  }
  return engine;
}
