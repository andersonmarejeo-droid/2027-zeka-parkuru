import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/little_fisher/little_fisher_engine.dart';
import 'package:zeka_parkuru/games/little_fisher/little_fisher_scenario.dart';

void main() {
  test('matching bait/depth and pulsed reeling lands a real fish', () {
    final LittleFisherEngine engine = LittleFisherEngine(
      scenario: LittleFisherScenario.forLevel(1),
    );
    final FishPlan fish = engine.currentFish!;
    expect(
      engine.cast(bait: fish.preferredBait, depth: fish.preferredDepth),
      FishingCastResult.hooked,
    );
    FishingStepResult result = const FishingStepResult();
    for (
      int frame = 0;
      frame < 1400 && !result.caught && !result.missed;
      frame++
    ) {
      engine.setReeling(engine.lineTension < .56);
      result = engine.step(.02);
    }
    expect(result.caught, isTrue);
    expect(engine.catches, 1);
    expect(engine.fishIndex, 1);
    expect(engine.misses, 0);
    expect(engine.isHooked, isFalse);
  });

  test('wrong bait or depth is signalled without consuming the fish', () {
    final LittleFisherEngine engine = LittleFisherEngine(
      scenario: LittleFisherScenario.forLevel(2),
    );
    expect(engine.cast(bait: 1, depth: 1), FishingCastResult.wrongBait);
    expect(engine.fishIndex, 0);
    expect(engine.misses, 1);
    for (int frame = 0; frame < 30; frame++) {
      engine.step(.024);
    }
    expect(engine.cast(bait: 0, depth: 0), FishingCastResult.wrongDepth);
    expect(engine.fishIndex, 0);
    expect(engine.misses, 2);
  });

  test('reeling through the snap zone breaks line and records a miss', () {
    final LittleFisherEngine engine = LittleFisherEngine(
      scenario: LittleFisherScenario.forLevel(1),
    );
    final FishPlan fish = engine.currentFish!;
    engine.cast(bait: fish.preferredBait, depth: fish.preferredDepth);
    engine.setReeling(true);
    FishingStepResult result = const FishingStepResult();
    for (
      int frame = 0;
      frame < 400 && !result.missed && !result.caught;
      frame++
    ) {
      result = engine.step(.024);
    }
    expect(result.lineSnapped, isTrue);
    expect(engine.misses, 1);
    expect(engine.isHooked, isFalse);
    expect(engine.fishIndex, 0);
  });
}
