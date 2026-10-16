import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/signal_pair/signal_pair_scenario.dart';

void main() {
  test('20 missions grow from three to eight communicated signals', () {
    final List<SignalPairScenario> campaign = <SignalPairScenario>[
      for (int level = 1; level <= 20; level++)
        SignalPairScenario.forLevel(level),
    ];
    expect(campaign.first.signalCount, 3);
    expect(campaign.last.signalCount, 8);
    expect(campaign.map((scenario) => scenario.siteId).toSet(), hasLength(20));
    for (final SignalPairScenario scenario in campaign) {
      expect(scenario.targetRoute, hasLength(scenario.signalCount));
      expect(scenario.panelWiring.toSet(), hasLength(4));
      expect(
        scenario.targetRoute.any(
          (signal) => signal == scenario.panelWiring.first,
        ),
        isTrue,
      );
      expect(scenario.targetRoute, isNotEmpty);
    }
  });

  test('300 practice routes and wiring layouts are structurally unique', () {
    final List<SignalPairScenario> cases = <SignalPairScenario>[
      for (int index = 1; index <= 300; index++)
        SignalPairScenario.forPractice(index),
    ];
    expect(
      cases.map((scenario) => scenario.signature()).toSet(),
      hasLength(300),
    );
    for (int index = 1; index <= 300; index++) {
      expect(
        SignalPairScenario.forPractice(index).signature(),
        cases[index - 1].signature(),
      );
    }
  });

  test('practice bounds are enforced', () {
    expect(() => SignalPairScenario.forLevel(21), throwsRangeError);
    expect(() => SignalPairScenario.forPractice(301), throwsRangeError);
  });
}
