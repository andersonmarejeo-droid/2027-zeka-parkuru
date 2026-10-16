import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/deep_current/deep_current_scenario.dart';

void main() {
  test('20 dives increase cargo, current pressure and resource commitment', () {
    final List<DeepCurrentScenario> dives = List<DeepCurrentScenario>.generate(
      DeepCurrentScenario.campaignLevels,
      (int index) => DeepCurrentScenario.forLevel(index + 1),
    );
    expect(dives.first.salvage, hasLength(1));
    expect(dives[5].salvage, hasLength(1));
    expect(dives[6].salvage, hasLength(2));
    expect(dives.last.salvage, hasLength(4));
    expect(
      dives.last.currents.length,
      greaterThan(dives.first.currents.length),
    );
    expect(dives.last.subSpeed, lessThan(dives.first.subSpeed));
    expect(dives.last.oxygenCapacity, lessThan(dives.first.oxygenCapacity));
    expect(dives.last.safeDepth, lessThan(dives.first.safeDepth));
    for (final DeepCurrentScenario dive in dives) {
      for (final DeepCurrentSalvage cargo in dive.salvage) {
        expect(cargo.position.dx, greaterThan(DeepCurrentScenario.base.dx));
        expect(cargo.position.dx, lessThan(.9));
        expect(cargo.position.dy, inInclusiveRange(.39, .61));
      }
    }
  });

  test('300 practice dives are deterministic and signature-unique', () {
    final Set<String> signatures = <String>{};
    for (
      int index = 1;
      index <= DeepCurrentScenario.practiceMissions;
      index++
    ) {
      final DeepCurrentScenario dive = DeepCurrentScenario.forPracticeMission(
        index,
      );
      expect(
        dive.signature,
        DeepCurrentScenario.forPracticeMission(index).signature,
      );
      expect(
        signatures.add(dive.signature),
        isTrue,
        reason: 'mission $index repeated',
      );
      expect(
        dive.signature,
        isNot(DeepCurrentScenario.forLevel(dive.level).signature),
      );
    }
    expect(signatures, hasLength(DeepCurrentScenario.practiceMissions));
  });

  test('scenario factories enforce the published limits', () {
    expect(() => DeepCurrentScenario.forLevel(0), throwsRangeError);
    expect(() => DeepCurrentScenario.forLevel(21), throwsRangeError);
    expect(() => DeepCurrentScenario.forPracticeMission(0), throwsRangeError);
    expect(() => DeepCurrentScenario.forPracticeMission(301), throwsRangeError);
  });
}
