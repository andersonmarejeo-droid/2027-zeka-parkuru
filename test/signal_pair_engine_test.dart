import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/signal_pair/signal_pair_engine.dart';
import 'package:zeka_parkuru/games/signal_pair/signal_pair_scenario.dart';

void main() {
  test('navigator route is cleared before operator wiring is exposed', () {
    final SignalPairScenario scenario = SignalPairScenario.forLevel(12);
    final SignalPairEngine engine = SignalPairEngine(scenario: scenario);
    expect(engine.navigatorRoute, isEmpty);
    expect(engine.operatorWiring, isEmpty);
    expect(engine.openNavigatorBrief(), isTrue);
    expect(engine.navigatorRoute, scenario.targetRoute);
    expect(engine.hideNavigatorMap(), isTrue);
    expect(engine.navigatorRoute, isEmpty);
    expect(engine.operatorWiring, isEmpty);
    expect(engine.openOperatorPanel(), isTrue);
    expect(engine.navigatorRoute, isEmpty);
    expect(engine.operatorWiring, scenario.panelWiring);
  });

  test('wrong prefix is measured; partners can correct and restore relay', () {
    final SignalPairScenario scenario = SignalPairScenario.forLevel(8);
    final SignalPairEngine engine = SignalPairEngine(scenario: scenario);
    engine.openNavigatorBrief();
    engine.hideNavigatorMap();
    engine.openOperatorPanel();
    final List<SignalGlyph> wiring = engine.operatorWiring;
    final SignalGlyph wrongSignal = scenario.targetRoute.first == wiring.first
        ? wiring[1]
        : wiring.first;
    final int wrongButton = wiring.indexOf(wrongSignal);
    expect(engine.selectButton(wrongButton), SignalPairAction.selected);
    for (final SignalGlyph signal in scenario.targetRoute.skip(1)) {
      expect(
        engine.selectButton(wiring.indexOf(signal)),
        SignalPairAction.selected,
      );
    }
    final SignalPairSubmission wrong = engine.submitRoute();
    expect(wrong.action, SignalPairAction.wrong);
    expect(wrong.correctPrefix, 0);
    expect(engine.enteredButtons, isEmpty);
    expect(engine.mistakes, 1);
    for (final SignalGlyph signal in scenario.targetRoute) {
      expect(
        engine.selectButton(wiring.indexOf(signal)),
        SignalPairAction.selected,
      );
    }
    final SignalPairSubmission solved = engine.submitRoute();
    expect(solved.action, SignalPairAction.submitted);
    expect(solved.correctPrefix, scenario.signalCount);
    expect(engine.phase, SignalPairPhase.result);
    expect(engine.selectButton(0), SignalPairAction.rejected);
  });

  test('incomplete route, undo and reset are guarded', () {
    final SignalPairEngine engine = SignalPairEngine(
      scenario: SignalPairScenario.forLevel(2),
    );
    engine.openNavigatorBrief();
    engine.hideNavigatorMap();
    engine.openOperatorPanel();
    expect(engine.submitRoute().action, SignalPairAction.incomplete);
    expect(engine.undoLastSignal(), isFalse);
    expect(engine.selectButton(0), SignalPairAction.selected);
    expect(engine.undoLastSignal(), isTrue);
    expect(engine.resetRoute(), isFalse);
  });
}
