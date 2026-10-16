import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/cafe_shift/cafe_shift_scenario.dart';

void main() {
  test('20 shifts grow the menu, ticket load and recipe complexity', () {
    final List<CafeShiftScenario> shifts = List<CafeShiftScenario>.generate(
      CafeShiftScenario.campaignLevels,
      (int index) => CafeShiftScenario.forLevel(index + 1),
    );
    expect(shifts.first.orders, hasLength(4));
    expect(shifts.last.orders, hasLength(10));
    expect(shifts.first.activeLimit, 2);
    expect(shifts.last.activeLimit, 3);
    expect(
      shifts.first.orders.every(
        (CafeOrderSpec order) => order.modifier == CafeModifier.none,
      ),
      isTrue,
    );
    expect(
      shifts.last.orders.any((CafeOrderSpec order) => order.route.length >= 4),
      isTrue,
    );
    expect(shifts.last.allowedMisses, 1);
    for (final CafeShiftScenario shift in shifts) {
      expect(shift.startingStock, greaterThanOrEqualTo(shift.orders.length));
      for (final CafeOrderSpec order in shift.orders) {
        expect(order.route, isNotEmpty);
        expect(order.route.length, order.stageSeconds.length);
        if (order.modifier == CafeModifier.doubleShot) {
          expect(
            order.route.where(
              (CafeStation station) => station == CafeStation.espresso,
            ),
            hasLength(2),
          );
        }
        if (order.modifier == CafeModifier.extraToast) {
          expect(
            order.route.where(
              (CafeStation station) => station == CafeStation.grill,
            ),
            hasLength(2),
          );
        }
      }
    }
  });

  test('300 practice shifts are reproducible and signature-unique', () {
    final Set<String> signatures = <String>{};
    for (int index = 1; index <= CafeShiftScenario.practiceShifts; index++) {
      final CafeShiftScenario shift = CafeShiftScenario.forPracticeShift(index);
      expect(
        shift.signature,
        CafeShiftScenario.forPracticeShift(index).signature,
      );
      expect(
        signatures.add(shift.signature),
        isTrue,
        reason: 'shift $index repeated',
      );
      expect(
        shift.signature,
        isNot(CafeShiftScenario.forLevel(shift.level).signature),
      );
    }
    expect(signatures, hasLength(CafeShiftScenario.practiceShifts));
  });

  test('shift factories enforce campaign and practice limits', () {
    expect(() => CafeShiftScenario.forLevel(0), throwsRangeError);
    expect(() => CafeShiftScenario.forLevel(21), throwsRangeError);
    expect(() => CafeShiftScenario.forPracticeShift(0), throwsRangeError);
    expect(() => CafeShiftScenario.forPracticeShift(301), throwsRangeError);
  });
}
