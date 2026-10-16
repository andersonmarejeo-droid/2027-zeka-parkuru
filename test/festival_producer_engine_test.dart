import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/festival_producer/festival_engine.dart';
import 'package:zeka_parkuru/games/festival_producer/festival_scenario.dart';

void main() {
  test('a stage cannot host two sets at once and show cannot repeat', () {
    final FestivalScenario scenario = FestivalScenario.forLevel(8);
    final FestivalEngine engine = FestivalEngine(scenario: scenario);
    expect(
      engine.place(performanceIndex: 0, stage: 0, block: 0).accepted,
      isTrue,
    );
    expect(
      engine.place(performanceIndex: 1, stage: 0, block: 0).reason,
      'stage_occupied',
    );
    expect(
      engine.place(performanceIndex: 0, stage: 1, block: 1).reason,
      'already_booked',
    );
  });

  test(
    'drizzle, per-time capacities and stage changeover are review constraints',
    () {
      final FestivalScenario rain = FestivalScenario(
        level: 9,
        seed: 9,
        timeSlots: 8,
        showCount: 3,
        performances: <FestivalPerformance>[
          FestivalPerformance.templates.firstWhere(
            (FestivalPerformance p) => !p.rainReady,
          ),
          ...FestivalPerformance.templates
              .where((FestivalPerformance p) => p.rainReady)
              .take(2),
        ],
        weather: FestivalWeather.drizzle,
        rainSlot: 1,
        turnaroundGap: 1,
        audienceCapacity: 8,
        powerCapacity: 8,
        crewCapacity: 8,
        minimumGenres: 2,
        audienceTarget: 1,
        budget: 100,
      );
      final FestivalEngine unsafe = FestivalEngine(scenario: rain);
      final int openAir = rain.performances.indexWhere(
        (FestivalPerformance p) => !p.rainReady,
      );
      expect(
        unsafe
            .place(performanceIndex: openAir, stage: 1, block: rain.rainSlot)
            .accepted,
        isTrue,
      );
      expect(unsafe.evaluate().weatherReady, isFalse);

      final FestivalScenario scenario = FestivalScenario.forLevel(9);
      final FestivalEngine full = FestivalEngine(scenario: scenario);
      expect(
        full.place(performanceIndex: 0, stage: 0, block: 0).accepted,
        isTrue,
      );
      expect(
        full.place(performanceIndex: 1, stage: 0, block: 1).accepted,
        isTrue,
      );
      expect(full.evaluate().turnaroundReady, isFalse);
      final FestivalEngine crowded = FestivalEngine(scenario: scenario);
      final List<int> highDraw = <int>[
        for (int i = 0; i < scenario.performances.length; i++)
          if (scenario.performances[i].audience == 4) i,
      ].take(2).toList();
      expect(highDraw, hasLength(2));
      expect(
        crowded
            .place(performanceIndex: highDraw[0], stage: 0, block: 0)
            .accepted,
        isTrue,
      );
      expect(
        crowded
            .place(performanceIndex: highDraw[1], stage: 1, block: 0)
            .accepted,
        isTrue,
      );
      expect(crowded.evaluate().resourceReady, isFalse);
    },
  );

  test('undo and redo restore a stage booking', () {
    final FestivalScenario scenario = FestivalScenario.forLevel(1);
    final FestivalEngine engine = FestivalEngine(scenario: scenario);
    expect(
      engine.place(performanceIndex: 0, stage: 0, block: 0).accepted,
      isTrue,
    );
    expect(engine.undo(), isTrue);
    expect(engine.assignments, isEmpty);
    expect(engine.redo(), isTrue);
    expect(engine.assignments.single.block, 0);
  });
}
