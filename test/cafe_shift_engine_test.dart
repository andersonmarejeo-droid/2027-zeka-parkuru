import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/cafe_shift/cafe_shift_engine.dart';
import 'package:zeka_parkuru/games/cafe_shift/cafe_shift_scenario.dart';

void main() {
  test('a parallel-station service plan completes all 20 authored shifts', () {
    for (int level = 1; level <= CafeShiftScenario.campaignLevels; level++) {
      final CafeShiftEngine engine = CafeShiftEngine(
        scenario: CafeShiftScenario.forLevel(level),
      );
      int busiest = 0;
      for (
        int frame = 0;
        frame < 20000 && !engine.completed && !engine.failed;
        frame++
      ) {
        for (final CafeOrderProgress ticket in engine.orders) {
          if (ticket.readyToServe) {
            engine.serve(ticket.spec.id);
          } else if (ticket.assignedStation == null) {
            final CafeStation station = ticket.nextStation!;
            if (!engine.station(station).busy) {
              engine.startStage(ticket.spec.id, station);
            }
          }
        }
        engine.step(.1);
        final int working = engine.stations
            .where((CafeStationState station) => station.busy)
            .length;
        if (working > busiest) busiest = working;
      }
      expect(engine.failed, isFalse, reason: 'level $level');
      expect(
        engine.completed,
        isTrue,
        reason: 'level $level ended at ${engine.elapsed}s',
      );
      expect(
        engine.servedCount,
        greaterThanOrEqualTo(engine.completedOrdersNeeded),
      );
      expect(
        engine.missedCount,
        lessThanOrEqualTo(CafeShiftScenario.forLevel(level).allowedMisses),
      );
      expect(engine.stock, greaterThanOrEqualTo(0));
      if (level >= 12) expect(busiest, greaterThanOrEqualTo(2));
    }
  });

  test(
    'wrong station, busy equipment and unfinished service cannot be bypassed',
    () {
      final CafeShiftEngine engine = CafeShiftEngine(
        scenario: CafeShiftScenario.forLevel(1),
      );
      final CafeOrderProgress first = engine.orders.first;
      final CafeStation needed = first.nextStation!;
      final CafeStation wrong = CafeStation.values.firstWhere(
        (CafeStation station) => station != needed,
      );
      expect(engine.startStage(first.spec.id, wrong).accepted, isFalse);
      expect(engine.serve(first.spec.id).accepted, isFalse);
      expect(engine.startStage(first.spec.id, needed).stageStarted, isTrue);
      expect(engine.station(needed).busy, isTrue);
      expect(
        engine.startStage(engine.orders.last.spec.id, needed).accepted,
        isFalse,
      );
      expect(engine.stock, CafeShiftScenario.forLevel(1).startingStock - 1);
    },
  );

  test(
    'an impatient customer releases the station and miss allowance is enforced',
    () {
      final CafeShiftEngine engine = CafeShiftEngine(
        scenario: CafeShiftScenario.forLevel(20),
      );
      engine.orders.first.patience = .01;
      final CafeShiftStepResult result = engine.step(.1);
      expect(result.missed, 1);
      expect(engine.missedCount, 1);
      expect(engine.failed, isFalse);
      expect(engine.orders.first.patience, greaterThan(0));
    },
  );
}
