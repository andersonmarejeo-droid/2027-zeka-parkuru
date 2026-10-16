import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/deep_current/deep_current_engine.dart';
import 'package:zeka_parkuru/games/deep_current/deep_current_scenario.dart';

void _pilot(DeepCurrentEngine engine, Offset target) {
  for (int step = 0; step < 6000; step++) {
    final Offset delta = target - engine.position;
    if (delta.distance <= .050) return;
    engine.step(.05, delta / delta.distance);
    if (engine.failed) fail('submarine failed en route to $target');
  }
  fail('submarine could not reach $target from ${engine.position}');
}

void main() {
  test(
    'a sonar-guided route can collect all cargo and dock on all 20 dives',
    () {
      for (
        int level = 1;
        level <= DeepCurrentScenario.campaignLevels;
        level++
      ) {
        final DeepCurrentScenario scenario = DeepCurrentScenario.forLevel(
          level,
        );
        final DeepCurrentEngine engine = DeepCurrentEngine(scenario: scenario);
        expect(
          engine.ping().accepted,
          isTrue,
          reason: 'level $level initial sweep',
        );
        for (final DeepCurrentSalvage cargo in scenario.salvage) {
          if (!engine.revealedTargets.any(
            (int index) => scenario.salvage[index] == cargo,
          )) {
            _pilot(engine, cargo.position);
            while (!engine.canPing) {
              engine.step(.10, Offset.zero);
            }
            expect(engine.ping().accepted, isTrue);
          } else {
            _pilot(engine, cargo.position);
          }
          final int cargoIndex = scenario.salvage.indexOf(cargo);
          if (!engine.revealedTargets.contains(cargoIndex)) {
            while (!engine.canPing) {
              engine.step(.10, Offset.zero);
            }
            expect(engine.ping().accepted, isTrue);
          }
          expect(
            engine.collect().collected,
            isTrue,
            reason: 'level $level cargo $cargoIndex',
          );
        }
        _pilot(engine, DeepCurrentScenario.base);
        expect(engine.dock().docked, isTrue, reason: 'level $level return');
      }
    },
  );

  test(
    'sonar, collection range, reef contact and return prerequisites hold',
    () {
      final DeepCurrentScenario scenario = DeepCurrentScenario.forLevel(1);
      final DeepCurrentEngine engine = DeepCurrentEngine(scenario: scenario);
      expect(engine.collect().accepted, isFalse);
      final DeepCurrentActionResult ping = engine.ping();
      expect(ping.accepted, isTrue);
      expect(ping.revealed, greaterThan(0));
      expect(engine.ping().accepted, isFalse);
      expect(engine.dock().accepted, isFalse);

      engine.position = scenario.reefs.first.center;
      final double hullBefore = engine.hull;
      final DeepCurrentStepResult collision = engine.step(.05, Offset.zero);
      expect(collision.collision, isTrue);
      expect(engine.hull, lessThan(hullBefore));
    },
  );

  test('resource depletion fails cleanly and clamps meters to zero', () {
    final DeepCurrentEngine engine = DeepCurrentEngine(
      scenario: DeepCurrentScenario.forLevel(20),
    );
    engine.oxygen = .01;
    final DeepCurrentStepResult result = engine.step(.10, const Offset(1, 0));
    expect(result.failed, isTrue);
    expect(engine.oxygen, 0);
    expect(engine.failed, isTrue);
  });
}
