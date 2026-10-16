import 'pet_case_scenario.dart';

class PetCareStepResult {
  const PetCareStepResult({required this.accepted, required this.completed});
  final bool accepted;
  final bool completed;
}

class PetCareEngine {
  PetCareEngine({required this.scenario});

  final PetCaseScenario scenario;
  int nextStep = 0;
  int mistakes = 0;
  final List<CareStep> completedSteps = <CareStep>[];

  CareStep? get currentStep =>
      nextStep < scenario.steps.length ? scenario.steps[nextStep] : null;
  bool get completed => nextStep >= scenario.steps.length;
  int get score =>
      (scenario.steps.length * 100 - mistakes * 18).clamp(0, 1000000).toInt();
  int get stars => mistakes == 0 ? 3 : (mistakes <= 2 ? 2 : 1);

  PetCareStepResult choose(CareStep action) {
    if (completed) {
      return const PetCareStepResult(accepted: false, completed: true);
    }
    if (action != currentStep) {
      mistakes++;
      return const PetCareStepResult(accepted: false, completed: false);
    }
    completedSteps.add(action);
    nextStep++;
    return PetCareStepResult(accepted: true, completed: completed);
  }

  void restart() {
    nextStep = 0;
    mistakes = 0;
    completedSteps.clear();
  }
}
