import 'dart:collection';

enum GoStone { empty, black, white }

extension GoStoneRules on GoStone {
  GoStone get opposite => switch (this) {
    GoStone.black => GoStone.white,
    GoStone.white => GoStone.black,
    GoStone.empty => GoStone.empty,
  };
}

class GoGroup {
  GoGroup({required Set<int> stones, required Set<int> liberties})
    : stones = UnmodifiableSetView<int>(stones),
      liberties = UnmodifiableSetView<int>(liberties);

  final Set<int> stones;
  final Set<int> liberties;
}

class GoPlayResult {
  GoPlayResult({
    required this.position,
    required Set<int> captured,
    required this.koPoint,
    required this.playedPoint,
  }) : captured = UnmodifiableSetView<int>(captured);

  final GoPosition position;
  final Set<int> captured;
  final int? koPoint;
  final int playedPoint;
}

/// Small-board Go rules: captures, suicide prevention, pass and simple ko.
/// The same rule model powers the tactical exercise and its content proof.
class GoPosition {
  GoPosition({
    required this.size,
    required List<GoStone> stones,
    required this.toMove,
    this.koPoint,
    this.consecutivePasses = 0,
  }) : stones = List<GoStone>.unmodifiable(stones) {
    if (size < 2 || stones.length != size * size || toMove == GoStone.empty) {
      throw ArgumentError('Invalid Go position.');
    }
  }

  final int size;
  final List<GoStone> stones;
  final GoStone toMove;
  final int? koPoint;
  final int consecutivePasses;

  String get signature =>
      '$size:${stones.map((GoStone stone) => stone.index).join()}:$koPoint:$toMove';

  bool get isGameOver => consecutivePasses >= 2;

  GoStone at(int point) => stones[point];

  int point(int row, int column) => row * size + column;

  GoPoint coordinates(int point) => GoPoint(point ~/ size, point % size);

  List<int> neighbors(int point) {
    final GoPoint p = coordinates(point);
    return <int>[
      if (p.row > 0) point - size,
      if (p.row + 1 < size) point + size,
      if (p.column > 0) point - 1,
      if (p.column + 1 < size) point + 1,
    ];
  }

  GoGroup? groupAt(int point) {
    if (point < 0 || point >= stones.length || stones[point] == GoStone.empty) {
      return null;
    }
    final GoStone color = stones[point];
    final Set<int> group = <int>{};
    final Set<int> liberties = <int>{};
    final List<int> pending = <int>[point];
    while (pending.isNotEmpty) {
      final int current = pending.removeLast();
      if (!group.add(current)) continue;
      for (final int adjacent in neighbors(current)) {
        if (stones[adjacent] == GoStone.empty) {
          liberties.add(adjacent);
        } else if (stones[adjacent] == color && !group.contains(adjacent)) {
          pending.add(adjacent);
        }
      }
    }
    return GoGroup(stones: group, liberties: liberties);
  }

  List<GoGroup> groups({GoStone? color}) {
    final Set<int> visited = <int>{};
    final List<GoGroup> result = <GoGroup>[];
    for (int current = 0; current < stones.length; current++) {
      if (stones[current] == GoStone.empty ||
          (color != null && stones[current] != color) ||
          visited.contains(current)) {
        continue;
      }
      final GoGroup group = groupAt(current)!;
      visited.addAll(group.stones);
      result.add(group);
    }
    return result;
  }

  GoPlayResult? play(int point) {
    if (isGameOver ||
        point < 0 ||
        point >= stones.length ||
        stones[point] != GoStone.empty ||
        point == koPoint) {
      return null;
    }
    final List<GoStone> next = List<GoStone>.of(stones);
    next[point] = toMove;
    final Set<int> captured = <int>{};
    final Set<int> inspected = <int>{};
    for (final int adjacent in neighbors(point)) {
      if (next[adjacent] != toMove.opposite || inspected.contains(adjacent)) {
        continue;
      }
      final GoPosition draft = GoPosition(
        size: size,
        stones: next,
        toMove: toMove.opposite,
      );
      final GoGroup enemy = draft.groupAt(adjacent)!;
      inspected.addAll(enemy.stones);
      if (enemy.liberties.isEmpty) {
        for (final int capturedPoint in enemy.stones) {
          next[capturedPoint] = GoStone.empty;
          captured.add(capturedPoint);
        }
      }
    }
    final GoPosition afterPlacement = GoPosition(
      size: size,
      stones: next,
      toMove: toMove.opposite,
    );
    final GoGroup ownGroup = afterPlacement.groupAt(point)!;
    if (ownGroup.liberties.isEmpty) return null;
    final int? nextKo =
        captured.length == 1 &&
            ownGroup.stones.length == 1 &&
            ownGroup.liberties.length == 1
        ? captured.single
        : null;
    final GoPosition nextPosition = GoPosition(
      size: size,
      stones: next,
      toMove: toMove.opposite,
      koPoint: nextKo,
    );
    return GoPlayResult(
      position: nextPosition,
      captured: captured,
      koPoint: nextKo,
      playedPoint: point,
    );
  }

  GoPosition pass() => GoPosition(
    size: size,
    stones: stones,
    toMove: toMove.opposite,
    consecutivePasses: consecutivePasses + 1,
  );

  bool hasOnlyGroupsWithLiberties() =>
      groups().every((GoGroup group) => group.liberties.isNotEmpty);
}

class GoPoint {
  const GoPoint(this.row, this.column);

  final int row;
  final int column;
}
