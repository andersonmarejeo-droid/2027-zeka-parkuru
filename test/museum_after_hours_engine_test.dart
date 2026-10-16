import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/museum_after_hours/museum_engine.dart';
import 'package:zeka_parkuru/games/museum_after_hours/museum_scenario.dart';

void main() {
  test('every authored shift has a safe shadow route and escape solution', () {
    for (int level = 1; level <= MuseumScenario.campaignLevels; level++) {
      final MuseumScenario scenario = MuseumScenario.forLevel(level);
      final MuseumAfterHoursEngine engine = MuseumAfterHoursEngine(
        scenario: scenario,
      );
      for (int x = 2; x <= MuseumScenario.exit.x; x++) {
        final MuseumCell next = (x: x, y: MuseumScenario.start.y);
        final MuseumLaserSpec? laser = scenario.laserAt(next);
        while (laser != null && laser.isActiveAt(engine.turn + 1)) {
          expect(engine.hide().accepted, isTrue);
        }
        expect(engine.move(1, 0).accepted, isTrue, reason: 'level $level x$x');
        expect(engine.caught, isFalse, reason: 'level $level caught in shadow');
        if (scenario.artifacts.contains(next)) {
          expect(engine.collect().collected, isTrue);
        } else if (scenario.artifacts.contains((x: x, y: 6))) {
          expect(engine.move(0, -1).accepted, isTrue);
          expect(engine.collect().collected, isTrue);
          expect(engine.move(0, 1).accepted, isTrue);
        }
      }
      expect(engine.allArtifactsCollected, isTrue, reason: 'level $level');
      expect(engine.escape().escaped, isTrue, reason: 'level $level');
    }
  });

  test('crossing an active laser catches the player; shadow wait is legal', () {
    final MuseumScenario scenario = MuseumScenario.forLevel(4);
    final MuseumAfterHoursEngine engine = MuseumAfterHoursEngine(
      scenario: scenario,
    );
    final MuseumLaserSpec laser = scenario.lasers.single;
    for (int x = 2; x < laser.cell.x; x++) {
      expect(engine.move(1, 0).accepted, isTrue);
    }
    while (!laser.isActiveAt(engine.turn + 1)) {
      expect(engine.hide().hidden, isTrue);
    }
    final MuseumActionResult hit = engine.move(1, 0);
    expect(hit.laserHit, isTrue);
    expect(engine.caught, isTrue);
  });

  test('walls block movement and objectives cannot be skipped', () {
    final MuseumScenario scenario = MuseumScenario.forLevel(1);
    final MuseumAfterHoursEngine engine = MuseumAfterHoursEngine(
      scenario: scenario,
    );
    expect(engine.move(0, -1).accepted, isTrue);
    expect(engine.move(0, -1).accepted, isFalse);
    expect(engine.escape().escaped, isFalse);
    expect(engine.move(-1, 0).accepted, isFalse);
    expect(engine.useLure().lureUsed, isTrue);
    expect(engine.useLure().accepted, isFalse);
    expect(engine.lureCharges, 0);
  });
}
