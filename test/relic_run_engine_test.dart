import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/relic_run/relic_run_engine.dart';
import 'package:zeka_parkuru/games/relic_run/relic_run_scenario.dart';

void main() {
  test('a marked lane can be broken by a normal move or a two-cell evade', () {
    final RelicRunEngine moved = RelicRunEngine(
      scenario: RelicRunScenario.forLevel(1),
    );
    expect(moved.telegraphedCells, contains(moved.player));
    final RelicRunActionResult move = moved.move(1, 0);
    expect(move.accepted, isTrue);
    expect(move.damageReceived, 0);

    final RelicRunEngine evaded = RelicRunEngine(
      scenario: RelicRunScenario.forLevel(1),
    );
    final RelicRunActionResult dodge = evaded.dodge();
    expect(dodge.dodged, isTrue);
    expect(dodge.damageReceived, 0);
    expect(evaded.dodgeReady, isFalse);
  });

  test('directional strike, relic pulse and reward choice change the run', () {
    final RelicRunEngine engine = RelicRunEngine(
      scenario: RelicRunScenario.forLevel(4),
    );
    final RelicRunFoeState target = engine.livingFoes.first;
    target.cell = (x: 3, y: 4);
    target.health = 3;
    for (final RelicRunFoeState foe in engine.livingFoes.skip(1)) {
      foe.health = 0;
    }
    expect(engine.aimAt(target.cell), isTrue);
    final RelicRunActionResult strike = engine.attack();
    expect(strike.hit, isTrue);
    expect(target.health, 2);

    final RelicRunActionResult pulse = engine.activateRelic();
    expect(pulse.relicActivated, isTrue);
    expect(pulse.hit, isTrue);
    expect(engine.kills, 1);
    expect(engine.relicCharge, greaterThanOrEqualTo(0));
  });

  test(
    'the exit gates three distinct rooms and two between-room relic picks',
    () {
      final RelicRunEngine engine = RelicRunEngine(
        scenario: RelicRunScenario.forLevel(12),
      );
      for (int room = 0; room < RelicRunScenario.roomCount; room++) {
        for (final RelicRunFoeState foe in engine.livingFoes) {
          foe.health = 0;
        }
        expect(engine.exitOpen, isTrue);
        RelicRunActionResult result = const RelicRunActionResult();
        while (engine.player.x < RelicRunEngine.exitCell.x) {
          result = engine.move(1, 0);
        }
        expect(result.roomCleared, isTrue);
        if (room < RelicRunScenario.roomCount - 1) {
          expect(engine.awaitingRelicChoice, isTrue);
          final RelicRunRelic choice = engine.currentRelicOffer.first;
          expect(engine.chooseRelic(choice).accepted, isTrue);
          expect(engine.roomIndex, room + 1);
        } else {
          expect(result.completed, isTrue);
          expect(engine.completed, isTrue);
        }
      }
      expect(engine.relicsCollected, 2);
    },
  );
}
