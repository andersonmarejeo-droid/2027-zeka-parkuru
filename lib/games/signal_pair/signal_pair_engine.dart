import 'signal_pair_scenario.dart';

enum SignalPairPhase {
  navigatorHandoff,
  navigatorBrief,
  operatorHandoff,
  operatorPanel,
  result,
}

enum SignalPairAction { selected, submitted, wrong, incomplete, rejected }

class SignalPairSubmission {
  const SignalPairSubmission({
    required this.action,
    required this.correctPrefix,
    required this.attempts,
  });

  final SignalPairAction action;
  final int correctPrefix;
  final int attempts;

  bool get solved => action == SignalPairAction.submitted;
}

/// Cooperative pass-and-play engine. The route is exposed only on the
/// navigator screen; the operator receives a differently wired control panel.
class SignalPairEngine {
  SignalPairEngine({required this.scenario}) : _route = scenario.targetRoute;

  final SignalPairScenario scenario;
  final List<SignalGlyph> _route;
  final List<int> _input = <int>[];
  SignalPairPhase phase = SignalPairPhase.navigatorHandoff;
  int attempts = 0;
  int mistakes = 0;
  int _bestPrefix = 0;

  List<SignalGlyph> get navigatorRoute =>
      phase == SignalPairPhase.navigatorBrief
      ? List<SignalGlyph>.unmodifiable(_route)
      : const <SignalGlyph>[];
  List<SignalGlyph> get operatorWiring =>
      phase == SignalPairPhase.operatorPanel || phase == SignalPairPhase.result
      ? scenario.panelWiring
      : const <SignalGlyph>[];
  List<int> get enteredButtons => List<int>.unmodifiable(_input);
  int get requiredSignals => scenario.signalCount;
  int get correctPrefix => _bestPrefix;
  bool get isComplete => phase == SignalPairPhase.result;

  bool openNavigatorBrief() {
    if (phase != SignalPairPhase.navigatorHandoff) return false;
    phase = SignalPairPhase.navigatorBrief;
    return true;
  }

  bool hideNavigatorMap() {
    if (phase != SignalPairPhase.navigatorBrief) return false;
    phase = SignalPairPhase.operatorHandoff;
    return true;
  }

  bool openOperatorPanel() {
    if (phase != SignalPairPhase.operatorHandoff) return false;
    phase = SignalPairPhase.operatorPanel;
    return true;
  }

  SignalPairAction selectButton(int button) {
    if (phase != SignalPairPhase.operatorPanel ||
        button < 0 ||
        button >= scenario.panelWiring.length ||
        _input.length >= scenario.signalCount) {
      return SignalPairAction.rejected;
    }
    _input.add(button);
    return SignalPairAction.selected;
  }

  bool undoLastSignal() {
    if (phase != SignalPairPhase.operatorPanel || _input.isEmpty) return false;
    _input.removeLast();
    return true;
  }

  bool resetRoute() {
    if (phase != SignalPairPhase.operatorPanel || _input.isEmpty) return false;
    _input.clear();
    return true;
  }

  SignalPairSubmission submitRoute() {
    if (phase != SignalPairPhase.operatorPanel ||
        _input.length != scenario.signalCount) {
      return SignalPairSubmission(
        action: SignalPairAction.incomplete,
        correctPrefix: _bestPrefix,
        attempts: attempts,
      );
    }
    attempts++;
    int prefix = 0;
    while (prefix < _route.length &&
        scenario.panelWiring[_input[prefix]] == _route[prefix]) {
      prefix++;
    }
    if (prefix == _route.length) {
      phase = SignalPairPhase.result;
      _bestPrefix = prefix;
      return SignalPairSubmission(
        action: SignalPairAction.submitted,
        correctPrefix: prefix,
        attempts: attempts,
      );
    }
    mistakes++;
    _bestPrefix = prefix > _bestPrefix ? prefix : _bestPrefix;
    _input.clear();
    return SignalPairSubmission(
      action: SignalPairAction.wrong,
      correctPrefix: prefix,
      attempts: attempts,
    );
  }
}
