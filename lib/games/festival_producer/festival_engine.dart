import 'festival_scenario.dart';

class FestivalAssignment {
  const FestivalAssignment({
    required this.performanceIndex,
    required this.stage,
    required this.block,
  });
  final int performanceIndex;
  final int stage;
  final int block;
  String get signature => '$performanceIndex:$stage:$block';
}

class FestivalEvaluation {
  const FestivalEvaluation({
    required this.score,
    required this.scheduled,
    required this.requiredShows,
    required this.stageZeroShows,
    required this.stageOneShows,
    required this.genreCount,
    required this.minimumGenres,
    required this.audience,
    required this.audienceTarget,
    required this.budgetUsed,
    required this.budget,
    required this.resourceReady,
    required this.turnaroundReady,
    required this.weatherReady,
    required this.canPublish,
  });
  final int score;
  final int scheduled;
  final int requiredShows;
  final int stageZeroShows;
  final int stageOneShows;
  final int genreCount;
  final int minimumGenres;
  final int audience;
  final int audienceTarget;
  final int budgetUsed;
  final int budget;
  final bool resourceReady;
  final bool turnaroundReady;
  final bool weatherReady;
  final bool canPublish;
}

class FestivalActionResult {
  const FestivalActionResult(this.accepted, this.reason);
  final bool accepted;
  final String reason;
}

class FestivalEngine {
  FestivalEngine({required this.scenario});
  final FestivalScenario scenario;
  final List<FestivalAssignment> _assignments = <FestivalAssignment>[];
  final List<List<FestivalAssignment>> _undo = <List<FestivalAssignment>>[];
  final List<List<FestivalAssignment>> _redo = <List<FestivalAssignment>>[];

  List<FestivalAssignment> get assignments =>
      List<FestivalAssignment>.unmodifiable(_assignments);
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  int get budgetUsed => _assignments.fold<int>(
    0,
    (int sum, FestivalAssignment item) =>
        sum + scenario.performances[item.performanceIndex].cost,
  );

  FestivalActionResult place({
    required int performanceIndex,
    required int stage,
    required int block,
  }) {
    if (performanceIndex < 0 ||
        performanceIndex >= scenario.performances.length) {
      return const FestivalActionResult(false, 'unknown_performance');
    }
    if (stage < 0 || stage > 1 || block < 0 || block >= scenario.timeSlots) {
      return const FestivalActionResult(false, 'outside_schedule');
    }
    final FestivalPerformance performance =
        scenario.performances[performanceIndex];
    if (_assignments.any(
      (FestivalAssignment a) => a.performanceIndex == performanceIndex,
    )) {
      return const FestivalActionResult(false, 'already_booked');
    }
    if (_assignments.any(
      (FestivalAssignment a) => a.stage == stage && a.block == block,
    )) {
      return const FestivalActionResult(false, 'stage_occupied');
    }
    if (block < performance.earliestBlock || block > performance.latestBlock) {
      return const FestivalActionResult(false, 'outside_time_window');
    }
    if (budgetUsed + performance.cost > scenario.budget) {
      return const FestivalActionResult(false, 'over_budget');
    }
    _commit(
      () => _assignments.add(
        FestivalAssignment(
          performanceIndex: performanceIndex,
          stage: stage,
          block: block,
        ),
      ),
    );
    return const FestivalActionResult(true, 'booked');
  }

  FestivalActionResult removeAt({required int stage, required int block}) {
    final int index = _assignments.indexWhere(
      (FestivalAssignment item) => item.stage == stage && item.block == block,
    );
    if (index < 0) return const FestivalActionResult(false, 'empty');
    _commit(() => _assignments.removeAt(index));
    return const FestivalActionResult(true, 'removed');
  }

  bool undo() {
    if (_undo.isEmpty) return false;
    _redo.add(List<FestivalAssignment>.of(_assignments));
    _assignments
      ..clear()
      ..addAll(_undo.removeLast());
    return true;
  }

  bool redo() {
    if (_redo.isEmpty) return false;
    _undo.add(List<FestivalAssignment>.of(_assignments));
    _assignments
      ..clear()
      ..addAll(_redo.removeLast());
    return true;
  }

  FestivalEvaluation evaluate() {
    final Map<int, List<FestivalAssignment>> byTime =
        <int, List<FestivalAssignment>>{};
    final List<int> stageCount = <int>[0, 0];
    final Set<FestivalGenre> allGenres = <FestivalGenre>{};
    int audience = 0;
    bool weatherReady = true;
    for (final FestivalAssignment assignment in _assignments) {
      final FestivalPerformance performance =
          scenario.performances[assignment.performanceIndex];
      audience += performance.audience;
      allGenres.add(performance.genre);
      stageCount[assignment.stage]++;
      byTime
          .putIfAbsent(assignment.block, () => <FestivalAssignment>[])
          .add(assignment);
      if (scenario.weather == FestivalWeather.drizzle &&
          assignment.block == scenario.rainSlot &&
          assignment.stage == 1 &&
          !performance.rainReady) {
        weatherReady = false;
      }
    }

    bool resourceReady = true;
    for (final List<FestivalAssignment> atTime in byTime.values) {
      final int crowd = atTime.fold<int>(
        0,
        (int sum, FestivalAssignment a) =>
            sum + scenario.performances[a.performanceIndex].audience,
      );
      final int power = atTime.fold<int>(
        0,
        (int sum, FestivalAssignment a) =>
            sum + scenario.performances[a.performanceIndex].power,
      );
      final int crew = atTime.fold<int>(
        0,
        (int sum, FestivalAssignment a) =>
            sum + scenario.performances[a.performanceIndex].crew,
      );
      if (crowd > scenario.audienceCapacity ||
          power > scenario.powerCapacity ||
          crew > scenario.crewCapacity) {
        resourceReady = false;
      }
    }

    bool turnaroundReady = true;
    for (int stage = 0; stage < 2; stage++) {
      final List<int> blocks =
          _assignments
              .where((FestivalAssignment a) => a.stage == stage)
              .map((FestivalAssignment a) => a.block)
              .toList()
            ..sort();
      for (int i = 1; i < blocks.length; i++) {
        if (blocks[i] - blocks[i - 1] <= scenario.turnaroundGap) {
          turnaroundReady = false;
        }
      }
    }

    final int lineupAppeal = _assignments.fold<int>(
      0,
      (int sum, FestivalAssignment a) =>
          sum + scenario.performances[a.performanceIndex].audience,
    );
    final int score =
        ((mathMin(_assignments.length / scenario.showCount, 1) * 25) +
                (stageCount.every((int count) => count > 0) ? 10 : 0) +
                (allGenres.length / FestivalGenre.values.length * 10) +
                (mathMin(lineupAppeal / scenario.audienceTarget, 1) * 20) +
                (resourceReady ? 15 : 0) +
                (turnaroundReady ? 10 : 0) +
                (weatherReady ? 5 : 0) +
                (budgetUsed <= scenario.budget ? 5 : 0))
            .round()
            .clamp(0, 100)
            .toInt();
    final bool full = _assignments.length == scenario.showCount;
    return FestivalEvaluation(
      score: score,
      scheduled: _assignments.length,
      requiredShows: scenario.showCount,
      stageZeroShows: stageCount[0],
      stageOneShows: stageCount[1],
      genreCount: allGenres.length,
      minimumGenres: scenario.minimumGenres,
      audience: audience,
      audienceTarget: scenario.audienceTarget,
      budgetUsed: budgetUsed,
      budget: scenario.budget,
      resourceReady: resourceReady,
      turnaroundReady: turnaroundReady,
      weatherReady: weatherReady,
      canPublish:
          full &&
          stageCount.every((int count) => count > 0) &&
          allGenres.length >= scenario.minimumGenres &&
          audience >= scenario.audienceTarget &&
          resourceReady &&
          turnaroundReady &&
          weatherReady &&
          budgetUsed <= scenario.budget,
    );
  }

  void _commit(void Function() mutation) {
    _undo.add(List<FestivalAssignment>.of(_assignments));
    if (_undo.length > 80) _undo.removeAt(0);
    _redo.clear();
    mutation();
  }
}

double mathMin(double a, double b) => a < b ? a : b;
