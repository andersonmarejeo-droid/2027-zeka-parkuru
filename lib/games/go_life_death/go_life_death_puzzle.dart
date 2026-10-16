import 'dart:math' as math;

import '../shared/content_seed.dart';
import 'go_position.dart';

enum GoPuzzleGoal { capture, save }

class GoLifeDeathPuzzle {
  const GoLifeDeathPuzzle._({
    required this.level,
    required this.seed,
    required this.position,
    required this.goal,
    required this.targetStones,
    required this.solutionPoint,
    required this.proofLegalMoves,
    required this.decoyStones,
  });

  static const int maximumLevels = 20;
  static const int maximumVerifiedBoards = 300;
  static final Map<int, GoLifeDeathPuzzle> _campaign =
      <int, GoLifeDeathPuzzle>{};
  static final Map<int, GoLifeDeathPuzzle> _practice =
      <int, GoLifeDeathPuzzle>{};

  final int level;
  final int seed;
  final GoPosition position;
  final GoPuzzleGoal goal;
  final Set<int> targetStones;
  final int solutionPoint;
  final int proofLegalMoves;
  final int decoyStones;

  String get signature =>
      '${position.signature}:${goal.name}:${targetStones.toList()..sort()}';

  GoStone get targetColor =>
      goal == GoPuzzleGoal.capture ? GoStone.white : GoStone.black;

  int get targetLiberties =>
      position.groupAt(targetStones.first)?.liberties.length ?? 0;

  String get difficultyTier => switch (level) {
    <= 6 => 'FOUNDATION',
    7 || 8 => 'ADVANCED',
    9 || 10 => 'EXPERT',
    <= 16 => 'DEEP READING',
    _ => 'MASTER TSUMEGO',
  };

  static GoLifeDeathPuzzle forLevel(int level) {
    if (level < 1 || level > maximumLevels) {
      throw RangeError.range(level, 1, maximumLevels, 'level');
    }
    return _campaign.putIfAbsent(level, () => _generate(level));
  }

  static GoLifeDeathPuzzle forPracticeBoard(int index) {
    if (index < 1 || index > maximumVerifiedBoards) {
      throw RangeError.range(index, 1, maximumVerifiedBoards, 'index');
    }
    for (int level = 1; level <= maximumLevels; level++) {
      _campaign.putIfAbsent(level, () => _generate(level));
    }
    for (int next = _practice.length + 1; next <= index; next++) {
      final int level = ((next - 1) % maximumLevels) + 1;
      GoLifeDeathPuzzle? accepted;
      for (int cycle = next; accepted == null; cycle++) {
        final GoLifeDeathPuzzle candidate = _generate(
          level,
          contentCycle: 1000 + cycle,
        );
        if (<GoLifeDeathPuzzle>[..._campaign.values, ..._practice.values].every(
          (GoLifeDeathPuzzle previous) =>
              previous.signature != candidate.signature,
        )) {
          accepted = candidate;
        }
      }
      _practice[next] = accepted;
    }
    return _practice[index]!;
  }

  bool isSolution(int point) {
    final GoPlayResult? move = position.play(point);
    if (move == null) return false;
    if (goal == GoPuzzleGoal.capture) {
      return targetStones.every(
        (int target) => move.position.at(target) != targetColor,
      );
    }
    final GoGroup? surviving = move.position.groupAt(targetStones.first);
    return surviving != null &&
        surviving.stones.containsAll(targetStones) &&
        surviving.liberties.length >= 2;
  }

  List<int> get certifiedWinningMoves => <int>[
    for (int point = 0; point < position.stones.length; point++)
      if (position.at(point) == GoStone.empty && isSolution(point)) point,
  ];

  static GoLifeDeathPuzzle _generate(int level, {int contentCycle = 0}) {
    final int size = _boardSize(level);
    final int targetCount = _targetCount(level);
    final int decoyTarget = _decoyCount(level);
    String lastRejection = 'no attempt';
    for (int attempt = 0; attempt < 12000; attempt++) {
      final int seed = ContentSeed.forLevel(
        gameId: 'go_life_death:$contentCycle',
        level: level,
        attempt: attempt,
      );
      final math.Random random = math.Random(seed);
      final Set<int>? target = _growTarget(
        size: size,
        count: targetCount,
        random: random,
      );
      if (target == null) {
        lastRejection = 'target geometry';
        continue;
      }
      final Set<int> perimeter = <int>{
        for (final int stone in target)
          ..._neighbors(
            size,
            stone,
          ).where((int point) => !target.contains(point)),
      };
      if (perimeter.length < 3) {
        lastRejection = 'short perimeter';
        continue;
      }
      final int solution = perimeter.elementAt(
        random.nextInt(perimeter.length),
      );
      final GoPuzzleGoal goal = (level + contentCycle + attempt).isEven
          ? GoPuzzleGoal.capture
          : GoPuzzleGoal.save;
      final GoStone targetColor = goal == GoPuzzleGoal.capture
          ? GoStone.white
          : GoStone.black;
      final GoStone enemyColor = targetColor.opposite;
      final List<GoStone> stones = List<GoStone>.filled(
        size * size,
        GoStone.empty,
      );
      for (final int point in target) {
        stones[point] = targetColor;
      }
      for (final int point in perimeter) {
        if (point != solution) stones[point] = enemyColor;
      }
      GoPosition position = GoPosition(
        size: size,
        stones: stones,
        toMove: goal == GoPuzzleGoal.capture ? enemyColor : targetColor,
      );
      final GoGroup? targetGroup = position.groupAt(target.first);
      if (targetGroup == null ||
          !targetGroup.stones.containsAll(target) ||
          targetGroup.stones.length != target.length ||
          targetGroup.liberties.length != 1 ||
          !targetGroup.liberties.contains(solution)) {
        lastRejection = 'initial target liberty';
        continue;
      }

      final List<int> noiseCandidates = <int>[
        for (int point = 0; point < size * size; point++)
          if (stones[point] == GoStone.empty &&
              _minimumDistance(size, point, target) >= 3)
            point,
      ]..shuffle(random);
      int placedDecoys = 0;
      for (final int point in noiseCandidates) {
        if (placedDecoys >= decoyTarget) break;
        stones[point] = random.nextBool() ? targetColor : enemyColor;
        final GoPosition candidate = GoPosition(
          size: size,
          stones: stones,
          toMove: position.toMove,
        );
        if (candidate.hasOnlyGroupsWithLiberties()) {
          position = candidate;
          placedDecoys++;
        } else {
          stones[point] = GoStone.empty;
        }
      }
      if (placedDecoys < math.min(decoyTarget, 2) ||
          !position.hasOnlyGroupsWithLiberties()) {
        lastRejection = 'decoy validity';
        continue;
      }
      final GoGroup? verifiedTarget = position.groupAt(target.first);
      if (verifiedTarget == null ||
          !verifiedTarget.stones.containsAll(target) ||
          verifiedTarget.stones.length != target.length ||
          verifiedTarget.liberties.length != 1 ||
          !verifiedTarget.liberties.contains(solution)) {
        lastRejection = 'target changed after decoys';
        continue;
      }
      final GoLifeDeathPuzzle draft = GoLifeDeathPuzzle._(
        level: level,
        seed: seed,
        position: position,
        goal: goal,
        targetStones: Set<int>.unmodifiable(target),
        solutionPoint: solution,
        proofLegalMoves: 0,
        decoyStones: placedDecoys,
      );
      if (!draft.isSolution(solution)) {
        lastRejection = 'marked solution is not a ${goal.name}';
        continue;
      }
      final List<int> wins = draft.certifiedWinningMoves;
      if (wins.length != 1 || wins.single != solution) {
        lastRejection = 'winning moves ${wins.length}, goal ${goal.name}';
        continue;
      }
      return GoLifeDeathPuzzle._(
        level: level,
        seed: seed,
        position: position,
        goal: goal,
        targetStones: Set<int>.unmodifiable(target),
        solutionPoint: solution,
        proofLegalMoves: position.stones
            .asMap()
            .entries
            .where(
              (MapEntry<int, GoStone> entry) =>
                  entry.value == GoStone.empty &&
                  position.play(entry.key) != null,
            )
            .length,
        decoyStones: placedDecoys,
      );
    }
    throw StateError(
      'Unable to certify Go puzzle at level $level: $lastRejection.',
    );
  }

  static int _boardSize(int level) => switch (level) {
    <= 6 => 5,
    <= 13 => 7,
    _ => 9,
  };

  static int _targetCount(int level) => switch (level) {
    <= 3 => 1,
    <= 6 => 2,
    7 || 8 => 3,
    <= 10 => 4,
    <= 13 => 5,
    <= 16 => 6,
    <= 18 => 7,
    _ => 8,
  };

  static int _decoyCount(int level) => switch (level) {
    <= 3 => 0,
    <= 6 => 2,
    7 || 8 => 4,
    <= 10 => 6,
    <= 13 => 8,
    <= 16 => 12,
    <= 18 => 16,
    _ => 20,
  };

  static Set<int>? _growTarget({
    required int size,
    required int count,
    required math.Random random,
  }) {
    for (int attempt = 0; attempt < 30; attempt++) {
      final int row = 1 + random.nextInt(size - 2);
      final int column = 1 + random.nextInt(size - 2);
      final Set<int> target = <int>{row * size + column};
      while (target.length < count) {
        final Set<int> frontier = <int>{
          for (final int stone in target)
            ..._neighbors(
              size,
              stone,
            ).where((int next) => !target.contains(next)),
        };
        if (frontier.isEmpty) break;
        final int next = frontier.elementAt(random.nextInt(frontier.length));
        final GoPoint point = GoPoint(next ~/ size, next % size);
        if (point.row <= 0 ||
            point.row >= size - 1 ||
            point.column <= 0 ||
            point.column >= size - 1) {
          continue;
        }
        target.add(next);
      }
      if (target.length == count) return target;
    }
    return null;
  }

  static List<int> _neighbors(int size, int point) {
    final int row = point ~/ size;
    final int column = point % size;
    return <int>[
      if (row > 0) point - size,
      if (row + 1 < size) point + size,
      if (column > 0) point - 1,
      if (column + 1 < size) point + 1,
    ];
  }

  static int _minimumDistance(int size, int point, Set<int> targets) {
    final int row = point ~/ size;
    final int column = point % size;
    return targets
        .map((int target) {
          return (row - target ~/ size).abs() + (column - target % size).abs();
        })
        .reduce(math.min);
  }
}
