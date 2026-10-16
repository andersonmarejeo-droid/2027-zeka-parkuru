import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/skate_combo/skate_combo_engine.dart';
import 'package:zeka_parkuru/games/skate_combo/skate_combo_scenario.dart';

void _advanceTo(SkateComboEngine engine, double target) {
  while (engine.elapsed < target && !engine.failed) {
    engine.step((target - engine.elapsed).clamp(0, .024).toDouble());
  }
}

void main() {
  test(
    'paced pumps, measured rotations and balance clear all ten campaigns',
    () {
      for (int level = 1; level <= SkateComboScenario.campaignLevels; level++) {
        final SkateComboScenario scenario = SkateComboScenario.forLevel(level);
        final SkateComboEngine engine = SkateComboEngine(scenario: scenario);
        for (int index = 0; index < scenario.jumps.length; index++) {
          final SkateJump jump = scenario.jumps[index];
          for (final double before in <double>[1.3, 1, .72]) {
            _advanceTo(engine, jump.takeoffSeconds - before);
            expect(
              engine.pump().quality,
              anyOf(SkateActionQuality.perfect, SkateActionQuality.clean),
            );
          }
          _advanceTo(engine, jump.takeoffSeconds);
          expect(engine.airborne, isTrue, reason: 'level $level jump $index');
          engine.addRotation(jump.targetRotation);
          engine.setBalance(jump.targetBalance);
          _advanceTo(engine, jump.landingSeconds);
          expect(
            engine.states[index],
            SkateJumpState.landed,
            reason: 'level $level jump $index did not stick',
          );
          expect(engine.failed, isFalse, reason: 'level $level failed');
        }
        _advanceTo(engine, scenario.finishSeconds);
        expect(engine.completed, isTrue, reason: 'level $level did not finish');
        expect(engine.misses, 0, reason: 'level $level had hidden bails');
        expect(engine.bestCombo, scenario.jumps.length);
      }
    },
  );

  test('spin direction and landing balance are judged separately', () {
    final SkateComboScenario scenario = SkateComboScenario.forLevel(1);
    final SkateComboEngine engine = SkateComboEngine(scenario: scenario);
    final SkateJump first = scenario.jumps.first;
    _advanceTo(engine, first.takeoffSeconds - .72);
    engine.pump();
    _advanceTo(engine, first.takeoffSeconds);
    engine.addRotation(-first.targetRotation);
    engine.setBalance(first.targetBalance);
    _advanceTo(engine, first.landingSeconds);
    expect(engine.states.first, SkateJumpState.bailed);
    expect(engine.misses, 1);
    expect(engine.combo, 0);
  });

  test('under-speed launch bails even when the landing gesture is precise', () {
    final SkateComboScenario scenario = SkateComboScenario.forLevel(1);
    final SkateComboEngine engine = SkateComboEngine(scenario: scenario);
    final SkateJump first = scenario.jumps.first;
    _advanceTo(engine, first.takeoffSeconds);
    engine.addRotation(first.targetRotation);
    engine.setBalance(first.targetBalance);
    _advanceTo(engine, first.landingSeconds);
    expect(engine.states.first, SkateJumpState.bailed);
  });
}
