import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/museum_curator/curator_engine.dart';
import 'package:zeka_parkuru/games/museum_curator/curator_scenario.dart';

void main() {
  test('a collection object cannot occupy two pedestals', () {
    final CuratorScenario scenario = CuratorScenario.forLevel(1);
    final CuratorEngine engine = CuratorEngine(scenario: scenario);
    final CuratorArtifact artifact = scenario.collection.firstWhere(
      (CuratorArtifact item) => item.themes.contains(scenario.theme),
    );
    expect(engine.place(0, artifact).accepted, isTrue);
    expect(engine.place(1, artifact).reason, 'already_displayed');
  });

  test('undo and redo restore ordered exhibit assignments', () {
    final CuratorScenario scenario = CuratorScenario.forLevel(5);
    final CuratorEngine engine = CuratorEngine(scenario: scenario);
    final List<CuratorArtifact> items =
        scenario.collection
            .where(
              (CuratorArtifact item) => item.themes.contains(scenario.theme),
            )
            .toList()
          ..sort(
            (CuratorArtifact a, CuratorArtifact b) => a.era.compareTo(b.era),
          );
    expect(engine.place(0, items[0]).accepted, isTrue);
    expect(engine.place(1, items[1]).accepted, isTrue);
    expect(engine.undo(), isTrue);
    expect(engine.slots[1], isNull);
    expect(engine.redo(), isTrue);
    expect(engine.slots[1], items[1]);
  });

  test(
    'chronology and fragile object limits are visible review conditions',
    () {
      final CuratorScenario scenario = CuratorScenario.forLevel(8);
      final CuratorEngine engine = CuratorEngine(scenario: scenario);
      final List<CuratorArtifact> items =
          scenario.collection
              .where(
                (CuratorArtifact item) => item.themes.contains(scenario.theme),
              )
              .toList()
            ..sort(
              (CuratorArtifact a, CuratorArtifact b) => a.era.compareTo(b.era),
            );
      expect(engine.place(0, items.last).accepted, isTrue);
      expect(engine.place(1, items.first).accepted, isTrue);
      expect(engine.evaluate().chronologyFit, isFalse);
    },
  );
}
