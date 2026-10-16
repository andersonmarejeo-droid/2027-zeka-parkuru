import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/interior_studio/interior_engine.dart';
import 'package:zeka_parkuru/games/interior_studio/interior_scenario.dart';

void main() {
  test('placement enforces room bounds, collision and the entry tile', () {
    final InteriorScenario scenario = InteriorScenario.forLevel(1);
    final InteriorEngine engine = InteriorEngine(scenario: scenario);

    expect(
      engine
          .place(
            furniture: InteriorFurniture.sofa,
            x: 1,
            y: 1,
            rotated: false,
            palette: scenario.palette,
          )
          .accepted,
      isTrue,
    );
    expect(
      engine
          .place(
            furniture: InteriorFurniture.bookshelf,
            x: 2,
            y: 1,
            rotated: false,
            palette: scenario.palette,
          )
          .reason,
      'overlap',
    );
    expect(
      engine
          .place(
            furniture: InteriorFurniture.bed,
            x: -1,
            y: 2,
            rotated: false,
            palette: scenario.palette,
          )
          .reason,
      'outside_room',
    );
    expect(
      engine
          .place(
            furniture: InteriorFurniture.plant,
            x: scenario.doorX,
            y: scenario.height - 1,
            rotated: false,
            palette: scenario.palette,
          )
          .reason,
      'door_blocked',
    );
  });

  test('undo and redo restore an exact furniture layout', () {
    final InteriorScenario scenario = InteriorScenario.forLevel(2);
    final InteriorEngine engine = InteriorEngine(scenario: scenario);
    engine.place(
      furniture: InteriorFurniture.sofa,
      x: 0,
      y: 0,
      rotated: false,
      palette: scenario.palette,
    );
    engine.place(
      furniture: InteriorFurniture.plant,
      x: 4,
      y: 0,
      rotated: false,
      palette: scenario.palette,
    );
    final List<String> expected = engine.placements
        .map((InteriorPlacement p) => p.signature)
        .toList();

    expect(engine.undo(), isTrue);
    expect(engine.placements, hasLength(1));
    expect(engine.redo(), isTrue);
    expect(
      engine.placements.map((InteriorPlacement p) => p.signature),
      expected,
    );
  });

  test('every campaign brief has a deterministic valid layout solution', () {
    for (int level = 1; level <= InteriorScenario.campaignLevels; level++) {
      final InteriorScenario scenario = InteriorScenario.forLevel(level);
      final InteriorEngine engine = InteriorEngine(scenario: scenario);
      for (int index = 0; index < scenario.requirements.length; index++) {
        final InteriorFurniture furniture = scenario.requirements[index];
        final List<(int, int, bool)> candidates = <(int, int, bool)>[];
        for (int y = 0; y < scenario.height; y++) {
          for (int x = 0; x < scenario.width; x++) {
            candidates.add((x, y, false));
            candidates.add((x, y, true));
          }
        }
        if (index == 0) {
          candidates.sort((a, b) {
            final int aDistance = (a.$1 - scenario.windowX).abs() + a.$2;
            final int bDistance = (b.$1 - scenario.windowX).abs() + b.$2;
            return aDistance.compareTo(bDistance);
          });
        }
        bool placed = false;
        for (final (int x, int y, bool rotated) in candidates) {
          final InteriorActionResult result = engine.place(
            furniture: furniture,
            x: x,
            y: y,
            rotated: rotated,
            palette: scenario.palette,
          );
          if (!result.accepted) continue;
          final InteriorEvaluation evaluation = engine.evaluate();
          final bool window = evaluation.windowUsed;
          final bool circulation = evaluation.accessibleRatio >= .35;
          if ((index > 0 || window) && circulation) {
            placed = true;
            break;
          }
          engine.undo();
        }
        expect(placed, isTrue, reason: 'level $level, item ${furniture.name}');
      }
      final InteriorEvaluation result = engine.evaluate();
      expect(result.canSubmit, isTrue, reason: 'level $level');
      expect(result.score, inInclusiveRange(0, 100));
    }
  });
}
