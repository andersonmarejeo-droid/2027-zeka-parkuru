import 'dart:collection';
import 'dart:math' as math;

import '../shared/content_seed.dart';
import '../shared/studio_game_contracts.dart';

/// The kinds of deterministic deductions used by the no-guess certificate.
enum MineDetectorInferenceKind {
  directSafe,
  directMine,
  subsetSafe,
  subsetMine,
}

/// A single action in the proof that a board can be completed without guessing.
class MineDetectorLogicAction {
  const MineDetectorLogicAction({
    required this.cell,
    required this.kind,
    required this.constraintSize,
  });

  final int cell;
  final MineDetectorInferenceKind kind;
  final int constraintSize;

  bool get revealsSafeCell =>
      kind == MineDetectorInferenceKind.directSafe ||
      kind == MineDetectorInferenceKind.subsetSafe;

  bool get flagsMine => !revealsSafeCell;

  bool get usesSubset =>
      kind == MineDetectorInferenceKind.subsetSafe ||
      kind == MineDetectorInferenceKind.subsetMine;
}

/// Immutable visible board state.  The puzzle owns clue and mine information;
/// this type deliberately carries only what the player has uncovered.
class MineDetectorBoardState {
  const MineDetectorBoardState._({
    required this.revealed,
    required this.flagged,
    required this.totalSafeCells,
    required this.explodedCell,
  });

  final Set<int> revealed;
  final Set<int> flagged;
  final int totalSafeCells;
  final int? explodedCell;

  bool get isLost => explodedCell != null;
  bool get isWon => !isLost && revealed.length == totalSafeCells;
  int get remainingSafeCells => totalSafeCells - revealed.length;
}

/// Diagnostic and hint material from the deterministic Minesweeper solver.
class MineDetectorLogicReport {
  const MineDetectorLogicReport({
    required this.initialState,
    required this.finalState,
    required this.actions,
    required this.constraintPeak,
    required this.inferenceRounds,
    required this.subsetInferenceCount,
    required this.hadContradiction,
  });

  final MineDetectorBoardState initialState;
  final MineDetectorBoardState finalState;
  final List<MineDetectorLogicAction> actions;
  final int constraintPeak;
  final int inferenceRounds;
  final int subsetInferenceCount;
  final bool hadContradiction;

  bool get isSolved => finalState.isWon && !hadContradiction;
  int get revealActionCount => actions
      .where((MineDetectorLogicAction action) => action.revealsSafeCell)
      .length;
  int get flagActionCount => actions
      .where((MineDetectorLogicAction action) => action.flagsMine)
      .length;
  MineDetectorLogicAction? get nextAction =>
      actions.isEmpty ? null : actions.first;
}

/// A deterministic, no-guess Minesweeper board.
///
/// Every catalogued board starts with a pre-opened zero-area (`safeStartCell`),
/// and is accepted only after [logicSolve] clears every safe cell using classic
/// point rules plus subset-difference inference.  The solver never examines
/// an unrevealed cell's actual mine status to choose an action.
class MineDetectorPuzzle {
  static const int maximumUniqueCases = GameContentPolicy.minimumUniqueRounds;
  static final Map<int, MineDetectorPuzzle> _cache =
      <int, MineDetectorPuzzle>{};
  static final Set<String> _materializedSignatures = <String>{};

  MineDetectorPuzzle._({
    required this.level,
    required this.localStage,
    required this.rows,
    required this.columns,
    required Set<int> mines,
    required this.safeStartCell,
  }) : mines = Set<int>.unmodifiable(mines),
       clues = List<int>.unmodifiable(
         _createClues(rows: rows, columns: columns, mines: mines),
       );

  /// Useful for focused gameplay tests and future authored challenge boards.
  factory MineDetectorPuzzle.fromMines({
    required int rows,
    required int columns,
    required Set<int> mines,
    required int safeStartCell,
    int level = 1,
    int localStage = 1,
  }) {
    final int cellCount = rows * columns;
    if (rows < 2 ||
        columns < 2 ||
        safeStartCell < 0 ||
        safeStartCell >= cellCount ||
        mines.any((int cell) => cell < 0 || cell >= cellCount) ||
        mines.contains(safeStartCell)) {
      throw ArgumentError('Mine layout or safe opening is invalid.');
    }
    return MineDetectorPuzzle._(
      level: level,
      localStage: localStage,
      rows: rows,
      columns: columns,
      mines: mines,
      safeStartCell: safeStartCell,
    );
  }

  final int level;
  final int localStage;
  final int rows;
  final int columns;
  final Set<int> mines;
  final int safeStartCell;

  /// `-1` marks a mine; every other entry is the classic adjacent mine count.
  final List<int> clues;

  int get cellCount => rows * columns;
  int get mineCount => mines.length;
  int get safeCellCount => cellCount - mineCount;
  double get mineDensity => mineCount / cellCount;

  /// Alias retained for generic board tooling that calls the opening index a
  /// `startIndex`. The cell is already opened in [initialState].
  int get startIndex => safeStartCell;

  String get difficultyTier => switch (localStage) {
    <= 2 => 'BAŞLANGIÇ',
    <= 6 => 'USTALAŞMA',
    <= 8 => 'İLERİ',
    _ => 'UZMAN',
  };

  /// Includes the opening cell because changing it materially changes play.
  String get boardSignature {
    final List<int> sortedMines = mines.toList()..sort();
    return '$rows×$columns@$safeStartCell:${sortedMines.join(',')}';
  }

  late final MineDetectorBoardState initialState = _revealSafeArea(
    const MineDetectorBoardState._(
      revealed: <int>{},
      flagged: <int>{},
      totalSafeCells: 0,
      explodedCell: null,
    ),
    safeStartCell,
  );

  late final MineDetectorLogicReport logicCertificate = logicSolve();

  int get openingRevealCount => initialState.revealed.length;
  int get hiddenAfterOpening => cellCount - openingRevealCount;
  int get certifiedLogicSteps => logicCertificate.actions.length;
  int get certifiedSubsetSteps => logicCertificate.subsetInferenceCount;
  int get certifiedInferenceRounds => logicCertificate.inferenceRounds;
  int get certifiedConstraintPeak => logicCertificate.constraintPeak;
  int get complexityScore =>
      certifiedLogicSteps +
      certifiedInferenceRounds * 2 +
      certifiedSubsetSteps * 4 +
      certifiedConstraintPeak ~/ 3;

  static int stageForLevel(int level) => ((level - 1) % 10) + 1;

  Map<String, Object?> toCampaignMap() => {
    'level': level,
    'localStage': localStage,
    'rows': rows,
    'columns': columns,
    'safeStartCell': safeStartCell,
    'mines': mines.toList(),
  };

  static void installCampaignBank(List<dynamic> boards) {
    if (boards.length != 300) {
      throw FormatException('Invalid mine_detective bank');
    }
    for (int i = 0; i < boards.length; i++) {
      final m = Map<String, dynamic>.from(boards[i] as Map);
      _cache[i + 1] = MineDetectorPuzzle._(
        level: m['level'] as int,
        localStage: m['localStage'] as int,
        rows: m['rows'] as int,
        columns: m['columns'] as int,
        safeStartCell: m['safeStartCell'] as int,
        mines: Set<int>.from(m['mines'] as List),
      );
    }
  }

  static MineDetectorPuzzle forLevel(int level) {
    if (level < 1 || level > maximumUniqueCases) {
      throw RangeError.range(level, 1, maximumUniqueCases, 'level');
    }
    return _cache.putIfAbsent(level, () => _generate(level));
  }

  bool isValidCell(int cell) => cell >= 0 && cell < cellCount;
  int indexAt(int row, int column) {
    if (row < 0 || row >= rows || column < 0 || column >= columns) {
      throw RangeError('($row, $column) is outside the board.');
    }
    return row * columns + column;
  }

  int rowOf(int cell) {
    _checkCell(cell);
    return cell ~/ columns;
  }

  int columnOf(int cell) {
    _checkCell(cell);
    return cell % columns;
  }

  bool isMine(int cell) {
    _checkCell(cell);
    return mines.contains(cell);
  }

  int adjacentMineCount(int cell) {
    _checkCell(cell);
    return clues[cell];
  }

  Set<int> neighborsOf(int cell) {
    _checkCell(cell);
    final int row = rowOf(cell);
    final int column = columnOf(cell);
    return Set<int>.unmodifiable(<int>{
      for (int dy = -1; dy <= 1; dy++)
        for (int dx = -1; dx <= 1; dx++)
          if ((dx != 0 || dy != 0) &&
              row + dy >= 0 &&
              row + dy < rows &&
              column + dx >= 0 &&
              column + dx < columns)
            indexAt(row + dy, column + dx),
    });
  }

  bool isRevealed(MineDetectorBoardState state, int cell) =>
      state.revealed.contains(cell);
  bool isFlagged(MineDetectorBoardState state, int cell) =>
      state.flagged.contains(cell);

  /// Opens a cell; zeroes flood-fill through adjacent safe cells.
  MineDetectorBoardState revealFrom(MineDetectorBoardState state, int cell) {
    _validateState(state);
    _checkCell(cell);
    if (state.isLost ||
        state.isWon ||
        state.revealed.contains(cell) ||
        state.flagged.contains(cell)) {
      return state;
    }
    if (mines.contains(cell)) {
      return MineDetectorBoardState._(
        revealed: state.revealed,
        flagged: state.flagged,
        totalSafeCells: safeCellCount,
        explodedCell: cell,
      );
    }
    return _revealSafeArea(state, cell);
  }

  /// Flags or unflags a hidden cell.  Flags are intentionally not treated as
  /// truth by gameplay; a wrong flag can still be exposed by a chord.
  MineDetectorBoardState toggleFlag(MineDetectorBoardState state, int cell) {
    _validateState(state);
    _checkCell(cell);
    if (state.isLost || state.isWon || state.revealed.contains(cell)) {
      return state;
    }
    final Set<int> flagged = Set<int>.from(state.flagged);
    if (!flagged.add(cell)) flagged.remove(cell);
    return MineDetectorBoardState._(
      revealed: state.revealed,
      flagged: Set<int>.unmodifiable(flagged),
      totalSafeCells: safeCellCount,
      explodedCell: null,
    );
  }

  /// Standard Minesweeper chord: opening a revealed clue opens its unflagged
  /// neighbours when the displayed flag count matches that clue.
  MineDetectorBoardState chord(MineDetectorBoardState state, int cell) {
    _validateState(state);
    _checkCell(cell);
    if (state.isLost || state.isWon || !state.revealed.contains(cell)) {
      return state;
    }
    final int clue = adjacentMineCount(cell);
    if (clue <= 0) return state;
    final Set<int> neighbours = neighborsOf(cell);
    final int flagCount = neighbours.where(state.flagged.contains).length;
    if (flagCount != clue) return state;
    MineDetectorBoardState next = state;
    for (final int neighbour in neighbours) {
      if (next.flagged.contains(neighbour)) continue;
      next = revealFrom(next, neighbour);
      if (next.isLost) return next;
    }
    return next;
  }

  /// Runs the exact same rule engine used for content certification.
  ///
  /// No random branch or mine lookup is used to select an action: each action
  /// follows from a visible clue constraint or the board-wide remaining-mine
  /// counter.  The mine layout is only used by [revealFrom] after a cell has
  /// already been proven safe.
  MineDetectorLogicReport logicSolve({MineDetectorBoardState? fromState}) {
    final MineDetectorBoardState initial = fromState ?? initialState;
    _validateState(initial);
    // A user can deliberately place a speculative flag. It must never turn a
    // hint into an unsafe recommendation, so an externally supplied state
    // with a false flag is reported as uncertified rather than solved under a
    // hidden assumption. Generated certificate states only contain proven
    // flags and therefore never take this path.
    if (initial.flagged.any((int cell) => !mines.contains(cell))) {
      return MineDetectorLogicReport(
        initialState: initial,
        finalState: initial,
        actions: const <MineDetectorLogicAction>[],
        constraintPeak: 0,
        inferenceRounds: 0,
        subsetInferenceCount: 0,
        hadContradiction: true,
      );
    }
    MineDetectorBoardState state = initial;
    final List<MineDetectorLogicAction> actions = <MineDetectorLogicAction>[];
    int constraintPeak = 0;
    int rounds = 0;
    int subsetActions = 0;
    bool contradiction = false;

    while (!state.isLost && !state.isWon) {
      rounds++;
      final _ConstraintBuild build = _buildConstraints(state);
      constraintPeak = math.max(constraintPeak, build.constraints.length);
      if (build.contradiction) {
        contradiction = true;
        break;
      }
      // Use ordinary point rules first. Aside from being easier to explain in
      // a hint, this avoids materialising subset differences until they are
      // genuinely needed on an advanced frontier.
      _Deduction? deduction = _findDeduction(build.constraints);
      if (deduction == null) {
        final List<_Constraint> closure = _constraintClosure(build.constraints);
        if (closure.isEmpty) break;
        constraintPeak = math.max(constraintPeak, closure.length);
        deduction = _findDeduction(closure);
      }
      if (deduction == null) break;

      final MineDetectorLogicAction action = MineDetectorLogicAction(
        cell: deduction.cell,
        kind: deduction.kind,
        constraintSize: deduction.constraintSize,
      );
      actions.add(action);
      if (action.usesSubset) subsetActions++;
      state = action.revealsSafeCell
          ? revealFrom(state, action.cell)
          : _flagKnownMine(state, action.cell);
    }

    return MineDetectorLogicReport(
      initialState: initial,
      finalState: state,
      actions: List<MineDetectorLogicAction>.unmodifiable(actions),
      constraintPeak: constraintPeak,
      inferenceRounds: rounds,
      subsetInferenceCount: subsetActions,
      hadContradiction: contradiction,
    );
  }

  bool verifyLogicSolvable() => logicCertificate.isSolved;

  MineDetectorBoardState _flagKnownMine(
    MineDetectorBoardState state,
    int cell,
  ) {
    if (state.flagged.contains(cell)) return state;
    final Set<int> flagged = Set<int>.from(state.flagged)..add(cell);
    return MineDetectorBoardState._(
      revealed: state.revealed,
      flagged: Set<int>.unmodifiable(flagged),
      totalSafeCells: safeCellCount,
      explodedCell: null,
    );
  }

  MineDetectorBoardState _revealSafeArea(
    MineDetectorBoardState source,
    int firstCell,
  ) {
    final Set<int> revealed = Set<int>.from(source.revealed);
    final Queue<int> queue = Queue<int>()..add(firstCell);
    while (queue.isNotEmpty) {
      final int cell = queue.removeFirst();
      if (revealed.contains(cell) || source.flagged.contains(cell)) continue;
      if (mines.contains(cell)) continue;
      revealed.add(cell);
      if (clues[cell] != 0) continue;
      for (final int neighbour in neighborsOf(cell)) {
        if (!revealed.contains(neighbour) &&
            !source.flagged.contains(neighbour) &&
            !mines.contains(neighbour)) {
          queue.add(neighbour);
        }
      }
    }
    return MineDetectorBoardState._(
      revealed: Set<int>.unmodifiable(revealed),
      flagged: source.flagged,
      totalSafeCells: safeCellCount,
      explodedCell: source.explodedCell,
    );
  }

  _ConstraintBuild _buildConstraints(MineDetectorBoardState state) {
    final List<_Constraint> constraints = <_Constraint>[];
    bool contradiction = false;
    for (final int revealedCell in state.revealed) {
      final int clue = clues[revealedCell];
      if (clue <= 0) continue;
      final Set<int> neighbours = neighborsOf(revealedCell);
      final int flagged = neighbours.where(state.flagged.contains).length;
      final Set<int> hidden = neighbours
          .where(
            (int cell) =>
                !state.revealed.contains(cell) && !state.flagged.contains(cell),
          )
          .toSet();
      final int remaining = clue - flagged;
      if (remaining < 0 || remaining > hidden.length) {
        contradiction = true;
        continue;
      }
      if (hidden.isNotEmpty) {
        constraints.add(
          _Constraint(cells: hidden, mines: remaining, isSubsetDerived: false),
        );
      } else if (remaining != 0) {
        contradiction = true;
      }
    }

    final Set<int> hiddenCells = <int>{
      for (int cell = 0; cell < cellCount; cell++)
        if (!state.revealed.contains(cell) && !state.flagged.contains(cell))
          cell,
    };
    // The player and the certificate know how many flags have been placed,
    // not whether those flags happen to be right.  Counting every flag here
    // keeps the solver a true visible-information rule engine.
    final int remainingMines = mineCount - state.flagged.length;
    if (remainingMines < 0 || remainingMines > hiddenCells.length) {
      contradiction = true;
    } else if (hiddenCells.isNotEmpty) {
      constraints.add(
        _Constraint(
          cells: hiddenCells,
          mines: remainingMines,
          isSubsetDerived: false,
        ),
      );
    }
    return _ConstraintBuild(constraints, contradiction);
  }

  static List<_Constraint> _constraintClosure(List<_Constraint> source) {
    final List<_Constraint> constraints = <_Constraint>[];
    final Set<String> known = <String>{};

    void add(_Constraint constraint) {
      if (constraint.cells.isEmpty ||
          constraint.mines < 0 ||
          constraint.mines > constraint.cells.length) {
        return;
      }
      final String key = constraint.key;
      if (known.add(key)) constraints.add(constraint);
    }

    for (final _Constraint constraint in source) {
      add(constraint);
    }

    // Difference constraints are a standard named-subset Minesweeper rule.
    // One visible-frontier difference is deliberately enough here; each new
    // reveal rebuilds the frontier on the next round. Keeping derivation to
    // base constraints makes content generation fast and predictable.
    final List<_Constraint> base = List<_Constraint>.from(constraints);
    for (int cursor = 0; cursor < base.length; cursor++) {
      final _Constraint left = base[cursor];
      for (int index = 0; index < base.length; index++) {
        if (index == cursor) continue;
        final _Constraint right = base[index];
        if (left.cells.length >= right.cells.length ||
            !right.cells.containsAll(left.cells)) {
          continue;
        }
        final Set<int> difference = Set<int>.from(right.cells)
          ..removeAll(left.cells);
        final int mines = right.mines - left.mines;
        if (mines < 0 || mines > difference.length) continue;
        add(
          _Constraint(cells: difference, mines: mines, isSubsetDerived: true),
        );
      }
    }
    return constraints;
  }

  static _Deduction? _findDeduction(List<_Constraint> constraints) {
    final List<_Constraint> ordered = List<_Constraint>.from(constraints)
      ..sort((_Constraint a, _Constraint b) {
        final int origin = a.isSubsetDerived == b.isSubsetDerived
            ? 0
            : a.isSubsetDerived
            ? 1
            : -1;
        if (origin != 0) return origin;
        final int length = a.cells.length.compareTo(b.cells.length);
        if (length != 0) return length;
        return a.key.compareTo(b.key);
      });
    for (final _Constraint constraint in ordered) {
      if (constraint.mines != 0 &&
          constraint.mines != constraint.cells.length) {
        continue;
      }
      final int cell = constraint.cells.reduce(math.min);
      final bool safe = constraint.mines == 0;
      return _Deduction(
        cell: cell,
        kind: safe
            ? (constraint.isSubsetDerived
                  ? MineDetectorInferenceKind.subsetSafe
                  : MineDetectorInferenceKind.directSafe)
            : (constraint.isSubsetDerived
                  ? MineDetectorInferenceKind.subsetMine
                  : MineDetectorInferenceKind.directMine),
        constraintSize: constraint.cells.length,
      );
    }
    return null;
  }

  static MineDetectorPuzzle _generate(int level) {
    final int stage = stageForLevel(level);
    final _MineStageSpec spec = _MineStageSpec.forStage(stage);
    for (int attempt = 0; attempt < 200; attempt++) {
      final math.Random random = ContentSeed.randomFor(
        gameId: 'mine_detector',
        level: level,
        attempt: attempt,
      );
      // The opening lives one row in from the edge, leaving a genuine 3×3
      // mine-free launch area even on the narrowest 6-column board.
      final int safeColumn = 1 + random.nextInt(spec.columns - 2);
      final bool flipVertically = random.nextBool();
      final bool mirrorHorizontally = random.nextBool();
      final Set<int> mines = _randomMinesInFrontier(spec, random);
      final Set<int> transformed = _transformMines(
        mines,
        rows: spec.rows,
        columns: spec.columns,
        flipVertically: flipVertically,
        mirrorHorizontally: mirrorHorizontally,
      );
      final int startRow = flipVertically ? 1 : spec.rows - 2;
      final int startColumn = mirrorHorizontally
          ? spec.columns - 1 - safeColumn
          : safeColumn;
      final int safeStart = startRow * spec.columns + startColumn;
      final MineDetectorPuzzle puzzle = MineDetectorPuzzle._(
        level: level,
        localStage: stage,
        rows: spec.rows,
        columns: spec.columns,
        mines: transformed,
        safeStartCell: safeStart,
      );
      final MineDetectorLogicReport certificate = puzzle.logicCertificate;
      if (!_meetsStageDifficulty(puzzle, certificate, spec)) continue;
      if (!_materializedSignatures.add(puzzle.boardSignature)) continue;
      return puzzle;
    }
    throw StateError(
      'Could not create a no-guess Mine Detector board for level $level.',
    );
  }

  static Set<int> _randomMinesInFrontier(
    _MineStageSpec spec,
    math.Random random,
  ) {
    final List<int> candidates = <int>[
      for (int row = 0; row < spec.rows - spec.clearRows; row++)
        for (int column = 0; column < spec.columns; column++)
          row * spec.columns + column,
    ]..shuffle(random);
    return candidates.take(spec.mineCount).toSet();
  }

  static Set<int> _transformMines(
    Set<int> source, {
    required int rows,
    required int columns,
    required bool flipVertically,
    required bool mirrorHorizontally,
  }) => Set<int>.unmodifiable(<int>{
    for (final int cell in source)
      ((flipVertically ? rows - 1 - cell ~/ columns : cell ~/ columns) *
              columns) +
          (mirrorHorizontally ? columns - 1 - cell % columns : cell % columns),
  });

  static bool _meetsStageDifficulty(
    MineDetectorPuzzle puzzle,
    MineDetectorLogicReport certificate,
    _MineStageSpec spec,
  ) {
    if (!certificate.isSolved || certificate.hadContradiction) return false;
    if (puzzle.openingRevealCount < spec.minimumOpeningCells ||
        puzzle.hiddenAfterOpening < spec.minimumHiddenCells ||
        certificate.actions.length < spec.minimumLogicActions ||
        certificate.inferenceRounds < spec.minimumInferenceRounds ||
        certificate.constraintPeak < spec.minimumConstraintPeak ||
        certificate.subsetInferenceCount < spec.minimumSubsetActions) {
      return false;
    }
    return true;
  }

  static List<int> _createClues({
    required int rows,
    required int columns,
    required Set<int> mines,
  }) {
    final int cellCount = rows * columns;
    return List<int>.generate(cellCount, (int cell) {
      if (mines.contains(cell)) return -1;
      final int row = cell ~/ columns;
      final int column = cell % columns;
      int count = 0;
      for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
          if (dx == 0 && dy == 0) continue;
          final int nextRow = row + dy;
          final int nextColumn = column + dx;
          if (nextRow >= 0 &&
              nextRow < rows &&
              nextColumn >= 0 &&
              nextColumn < columns &&
              mines.contains(nextRow * columns + nextColumn)) {
            count++;
          }
        }
      }
      return count;
    });
  }

  void _checkCell(int cell) {
    if (!isValidCell(cell)) {
      throw RangeError.range(cell, 0, cellCount - 1, 'cell');
    }
  }

  void _validateState(MineDetectorBoardState state) {
    if (state.totalSafeCells != safeCellCount ||
        state.revealed.any((int cell) => !isValidCell(cell) || isMine(cell)) ||
        state.flagged.any((int cell) => !isValidCell(cell)) ||
        state.revealed.any(state.flagged.contains)) {
      throw ArgumentError('Board state does not belong to this puzzle.');
    }
  }
}

class _Constraint {
  _Constraint({
    required Set<int> cells,
    required this.mines,
    required this.isSubsetDerived,
  }) : cells = Set<int>.unmodifiable(cells);

  final Set<int> cells;
  final int mines;
  final bool isSubsetDerived;

  String get key {
    final List<int> sorted = cells.toList()..sort();
    return '${sorted.join('.')}:$mines';
  }
}

class _ConstraintBuild {
  const _ConstraintBuild(this.constraints, this.contradiction);

  final List<_Constraint> constraints;
  final bool contradiction;
}

class _Deduction {
  const _Deduction({
    required this.cell,
    required this.kind,
    required this.constraintSize,
  });

  final int cell;
  final MineDetectorInferenceKind kind;
  final int constraintSize;
}

class _MineStageSpec {
  const _MineStageSpec({
    required this.rows,
    required this.columns,
    required this.mineCount,
    required this.clearRows,
    required this.minimumOpeningCells,
    required this.minimumHiddenCells,
    required this.minimumLogicActions,
    required this.minimumInferenceRounds,
    required this.minimumConstraintPeak,
    required this.minimumSubsetActions,
  });

  final int rows;
  final int columns;
  final int mineCount;
  final int clearRows;
  final int minimumOpeningCells;
  final int minimumHiddenCells;
  final int minimumLogicActions;
  final int minimumInferenceRounds;
  final int minimumConstraintPeak;
  final int minimumSubsetActions;

  static _MineStageSpec forStage(int stage) => _specs[stage - 1];

  static const List<_MineStageSpec> _specs = <_MineStageSpec>[
    _MineStageSpec(
      rows: 6,
      columns: 6,
      mineCount: 4,
      clearRows: 3,
      minimumOpeningCells: 12,
      minimumHiddenCells: 12,
      minimumLogicActions: 4,
      minimumInferenceRounds: 4,
      minimumConstraintPeak: 4,
      minimumSubsetActions: 0,
    ),
    _MineStageSpec(
      rows: 6,
      columns: 7,
      mineCount: 6,
      clearRows: 3,
      minimumOpeningCells: 14,
      minimumHiddenCells: 15,
      minimumLogicActions: 6,
      minimumInferenceRounds: 5,
      minimumConstraintPeak: 5,
      minimumSubsetActions: 0,
    ),
    _MineStageSpec(
      rows: 7,
      columns: 7,
      mineCount: 8,
      clearRows: 3,
      minimumOpeningCells: 15,
      minimumHiddenCells: 18,
      minimumLogicActions: 8,
      minimumInferenceRounds: 6,
      minimumConstraintPeak: 6,
      minimumSubsetActions: 0,
    ),
    _MineStageSpec(
      rows: 7,
      columns: 8,
      mineCount: 10,
      clearRows: 3,
      minimumOpeningCells: 16,
      minimumHiddenCells: 20,
      minimumLogicActions: 10,
      minimumInferenceRounds: 7,
      minimumConstraintPeak: 7,
      minimumSubsetActions: 0,
    ),
    _MineStageSpec(
      rows: 8,
      columns: 8,
      mineCount: 12,
      clearRows: 3,
      minimumOpeningCells: 18,
      minimumHiddenCells: 24,
      minimumLogicActions: 12,
      minimumInferenceRounds: 8,
      minimumConstraintPeak: 8,
      minimumSubsetActions: 0,
    ),
    _MineStageSpec(
      rows: 8,
      columns: 9,
      mineCount: 14,
      clearRows: 3,
      minimumOpeningCells: 20,
      minimumHiddenCells: 28,
      minimumLogicActions: 14,
      minimumInferenceRounds: 9,
      minimumConstraintPeak: 9,
      minimumSubsetActions: 0,
    ),
    _MineStageSpec(
      rows: 9,
      columns: 9,
      mineCount: 16,
      clearRows: 3,
      minimumOpeningCells: 22,
      minimumHiddenCells: 32,
      minimumLogicActions: 16,
      minimumInferenceRounds: 10,
      minimumConstraintPeak: 10,
      minimumSubsetActions: 1,
    ),
    _MineStageSpec(
      rows: 9,
      columns: 10,
      mineCount: 18,
      clearRows: 3,
      minimumOpeningCells: 24,
      minimumHiddenCells: 36,
      minimumLogicActions: 18,
      minimumInferenceRounds: 11,
      minimumConstraintPeak: 11,
      minimumSubsetActions: 1,
    ),
    _MineStageSpec(
      rows: 10,
      columns: 10,
      mineCount: 20,
      clearRows: 3,
      minimumOpeningCells: 26,
      minimumHiddenCells: 40,
      minimumLogicActions: 20,
      minimumInferenceRounds: 12,
      minimumConstraintPeak: 12,
      minimumSubsetActions: 2,
    ),
    _MineStageSpec(
      rows: 10,
      columns: 11,
      mineCount: 22,
      clearRows: 3,
      minimumOpeningCells: 28,
      minimumHiddenCells: 44,
      minimumLogicActions: 22,
      minimumInferenceRounds: 13,
      minimumConstraintPeak: 13,
      minimumSubsetActions: 2,
    ),
  ];
}
