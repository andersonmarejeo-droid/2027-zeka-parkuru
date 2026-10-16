import 'curator_scenario.dart';

class CuratorEvaluation {
  const CuratorEvaluation({
    required this.score,
    required this.placed,
    required this.slots,
    required this.themeFit,
    required this.chronologyFit,
    required this.fragileCount,
    required this.fragileLimit,
    required this.visitorAppeal,
    required this.visitorTarget,
    required this.budgetUsed,
    required this.budget,
    required this.canOpen,
  });
  final int score;
  final int placed;
  final int slots;
  final int themeFit;
  final bool chronologyFit;
  final int fragileCount;
  final int fragileLimit;
  final int visitorAppeal;
  final int visitorTarget;
  final int budgetUsed;
  final int budget;
  final bool canOpen;
}

class CuratorActionResult {
  const CuratorActionResult(this.accepted, this.reason);
  final bool accepted;
  final String reason;
}

class CuratorEngine {
  CuratorEngine({required this.scenario})
    : _slots = List<CuratorArtifact?>.filled(scenario.slotCount, null);
  final CuratorScenario scenario;
  final List<CuratorArtifact?> _slots;
  final List<List<CuratorArtifact?>> _undo = <List<CuratorArtifact?>>[];
  final List<List<CuratorArtifact?>> _redo = <List<CuratorArtifact?>>[];

  List<CuratorArtifact?> get slots =>
      List<CuratorArtifact?>.unmodifiable(_slots);
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  CuratorActionResult place(int slot, CuratorArtifact artifact) {
    if (slot < 0 || slot >= _slots.length) {
      return const CuratorActionResult(false, 'slot_outside');
    }
    if (!scenario.collection.contains(artifact)) {
      return const CuratorActionResult(false, 'not_in_collection');
    }
    if (_slots.asMap().entries.any(
      (MapEntry<int, CuratorArtifact?> item) =>
          item.key != slot && item.value == artifact,
    )) {
      return const CuratorActionResult(false, 'already_displayed');
    }
    _commit(() => _slots[slot] = artifact);
    return const CuratorActionResult(true, 'displayed');
  }

  CuratorActionResult remove(int slot) {
    if (slot < 0 || slot >= _slots.length || _slots[slot] == null) {
      return const CuratorActionResult(false, 'empty');
    }
    _commit(() => _slots[slot] = null);
    return const CuratorActionResult(true, 'removed');
  }

  bool undo() {
    if (_undo.isEmpty) return false;
    _redo.add(List<CuratorArtifact?>.of(_slots));
    _slots.setAll(0, _undo.removeLast());
    return true;
  }

  bool redo() {
    if (_redo.isEmpty) return false;
    _undo.add(List<CuratorArtifact?>.of(_slots));
    _slots.setAll(0, _redo.removeLast());
    return true;
  }

  CuratorEvaluation evaluate() {
    final List<CuratorArtifact> placed = _slots
        .whereType<CuratorArtifact>()
        .toList();
    final int themeFit = placed
        .where(
          (CuratorArtifact artifact) =>
              artifact.themes.contains(scenario.theme),
        )
        .length;
    final bool chronologyFit = List<bool>.generate(
      placed.length < 2 ? 0 : placed.length - 1,
      (int index) => placed[index].era <= placed[index + 1].era,
    ).every((bool value) => value);
    final int fragileCount = placed.fold<int>(
      0,
      (int sum, CuratorArtifact a) => sum + a.fragile,
    );
    final int visitorAppeal = placed.fold<int>(
      0,
      (int sum, CuratorArtifact a) => sum + a.appeal,
    );
    final int budgetUsed = placed.fold<int>(
      0,
      (int sum, CuratorArtifact a) => sum + a.cost,
    );
    final bool themeReady = themeFit == scenario.slotCount;
    final bool preservationReady = fragileCount <= scenario.fragileLimit;
    final bool visitorsReady = visitorAppeal >= scenario.visitorTarget;
    final bool budgetReady = budgetUsed <= scenario.budget;
    final bool full = placed.length == scenario.slotCount;
    final int score =
        ((placed.length / scenario.slotCount * 25) +
                (themeFit / scenario.slotCount * 20) +
                (chronologyFit ? 15 : 0) +
                (preservationReady ? 15 : 0) +
                ((visitorAppeal / scenario.visitorTarget).clamp(0.0, 1.0) *
                    15) +
                (budgetReady ? 10 : 0))
            .round()
            .clamp(0, 100)
            .toInt();
    return CuratorEvaluation(
      score: score,
      placed: placed.length,
      slots: scenario.slotCount,
      themeFit: themeFit,
      chronologyFit: chronologyFit,
      fragileCount: fragileCount,
      fragileLimit: scenario.fragileLimit,
      visitorAppeal: visitorAppeal,
      visitorTarget: scenario.visitorTarget,
      budgetUsed: budgetUsed,
      budget: scenario.budget,
      canOpen:
          full &&
          themeReady &&
          chronologyFit &&
          preservationReady &&
          visitorsReady &&
          budgetReady,
    );
  }

  void _commit(void Function() mutation) {
    _undo.add(List<CuratorArtifact?>.of(_slots));
    if (_undo.length > 80) _undo.removeAt(0);
    _redo.clear();
    mutation();
  }
}
