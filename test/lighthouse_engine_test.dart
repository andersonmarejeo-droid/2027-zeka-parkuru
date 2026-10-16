import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/lighthouse_defense/lighthouse_engine.dart';
import 'package:zeka_parkuru/games/lighthouse_defense/lighthouse_scenario.dart';

void main() {
  test('tower build, target priorities and upgrades respect the economy', () {
    final LighthouseDefenseEngine engine = LighthouseDefenseEngine(
      scenario: LighthouseScenario.forLevel(1),
    );
    expect(engine.startWave(), isFalse);
    expect(engine.buildTower(0, LighthouseTowerType.mortar), isTrue);
    expect(engine.buildTower(0, LighthouseTowerType.ballista), isFalse);
    expect(engine.cycleTargetRule(0), isTrue);
    expect(engine.towers[0]?.targetRule, LighthouseTargetRule.last);
    expect(engine.upgradeTower(0), isTrue);
    expect(engine.towers[0]?.tier, 2);
    expect(engine.startWave(), isTrue);
    expect(engine.buildTower(1, LighthouseTowerType.frost), isFalse);
  });

  test(
    'beacon pulse spends one charge, damages the wave and slows survivors',
    () {
      final LighthouseDefenseEngine engine = LighthouseDefenseEngine(
        scenario: LighthouseScenario.forLevel(1),
      )..buildTower(0, LighthouseTowerType.ballista);
      expect(engine.startWave(), isTrue);
      engine.step(.05);
      expect(engine.enemies, isNotEmpty);
      engine.enemies.first.health = 100;
      final LighthouseStepResult pulse = engine.usePulse();
      expect(pulse.pulseUsed, isTrue);
      expect(engine.pulseCharges, engine.scenario.pulseCharges - 1);
      expect(
        engine.enemies.every(
          (LighthouseEnemyState e) =>
              e.health < e.spec.health || e.slowedFor > 0,
        ),
        isTrue,
      );
    },
  );

  test('two distinct tower roles can hold an opening campaign wave', () {
    final LighthouseDefenseEngine engine =
        LighthouseDefenseEngine(scenario: LighthouseScenario.forLevel(1))
          ..buildTower(0, LighthouseTowerType.ballista)
          ..buildTower(5, LighthouseTowerType.mortar);
    expect(engine.startWave(), isTrue);
    for (int frame = 0; frame < 9000 && engine.waveRunning; frame++) {
      engine.step(1 / 60);
    }
    expect(engine.waveRunning, isFalse);
    expect(engine.failed, isFalse);
    expect(engine.waveIndex, 1);
    expect(engine.totalKills, greaterThan(0));
    expect(engine.lives, greaterThan(0));
  });
}
