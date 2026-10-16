import 'dart:collection';

enum BeamDirection {
  up(0, -1),
  right(1, 0),
  down(0, 1),
  left(-1, 0);

  const BeamDirection(this.dx, this.dy);

  final int dx;
  final int dy;
}

class BeamMirror {
  const BeamMirror({
    required this.cell,
    required this.solvedSlash,
    required this.initialSlash,
  });

  final int cell;
  final bool solvedSlash;
  final bool initialSlash;
}

class BeamTrace {
  const BeamTrace({
    required this.cells,
    required this.reachesTarget,
    required this.exitsBoard,
  });

  final List<int> cells;
  final bool reachesTarget;
  final bool exitsBoard;
}

/// A deterministic mirror puzzle. Mirrors use two states: slash (`/`) and
/// backslash (`\\`). Every level has a hand-authored, traceable answer.
class BeamDirectorPuzzle {
  const BeamDirectorPuzzle({
    required this.level,
    required this.width,
    required this.height,
    required this.sourceCell,
    required this.targetCell,
    required this.sourceDirection,
    required this.mirrors,
  });

  final int level;
  final int width;
  final int height;
  final int sourceCell;
  final int targetCell;
  final BeamDirection sourceDirection;
  final List<BeamMirror> mirrors;

  int get cellCount => width * height;

  bool isMirrorAt(int cell) =>
      mirrors.any((BeamMirror mirror) => mirror.cell == cell);

  bool solvedAt(int cell) => mirrors
      .firstWhere((BeamMirror mirror) => mirror.cell == cell)
      .solvedSlash;

  bool initialAt(int cell) => mirrors
      .firstWhere((BeamMirror mirror) => mirror.cell == cell)
      .initialSlash;

  List<bool> get solvedStates => mirrors
      .map((BeamMirror mirror) => mirror.solvedSlash)
      .toList(growable: false);

  List<bool> get initialStates => mirrors
      .map((BeamMirror mirror) => mirror.initialSlash)
      .toList(growable: false);

  BeamTrace trace(List<bool> mirrorStates) {
    if (mirrorStates.length != mirrors.length) {
      throw ArgumentError.value(
        mirrorStates.length,
        'mirrorStates.length',
        'Must match the number of mirrors.',
      );
    }

    final Map<int, bool> stateByCell = <int, bool>{
      for (int index = 0; index < mirrors.length; index++)
        mirrors[index].cell: mirrorStates[index],
    };
    final List<int> cells = <int>[sourceCell];
    final Set<String> seenStates = HashSet<String>();
    int current = sourceCell;
    BeamDirection direction = sourceDirection;

    for (int step = 0; step < cellCount * 8; step++) {
      final int x = current % width;
      final int y = current ~/ width;
      final int nextX = x + direction.dx;
      final int nextY = y + direction.dy;
      if (nextX < 0 || nextX >= width || nextY < 0 || nextY >= height) {
        return BeamTrace(
          cells: List<int>.unmodifiable(cells),
          reachesTarget: false,
          exitsBoard: true,
        );
      }

      current = nextY * width + nextX;
      cells.add(current);
      if (current == targetCell) {
        return BeamTrace(
          cells: List<int>.unmodifiable(cells),
          reachesTarget: true,
          exitsBoard: false,
        );
      }

      final bool? slash = stateByCell[current];
      if (slash != null) {
        direction = _reflect(direction, slash: slash);
      }
      final String loopKey = '$current:${direction.index}';
      if (!seenStates.add(loopKey)) {
        return BeamTrace(
          cells: List<int>.unmodifiable(cells),
          reachesTarget: false,
          exitsBoard: false,
        );
      }
    }

    return BeamTrace(
      cells: List<int>.unmodifiable(cells),
      reachesTarget: false,
      exitsBoard: false,
    );
  }

  bool get hasValidSolution => trace(solvedStates).reachesTarget;

  static BeamDirectorPuzzle forLevel(int level) {
    final int normalized = ((level - 1) % 10) + 1;
    return switch (normalized) {
      1 => _fromLegs(
        level: normalized,
        width: 4,
        height: 4,
        startX: 0,
        startY: 0,
        legs: const <_BeamLeg>[
          _BeamLeg(BeamDirection.right, 2),
          _BeamLeg(BeamDirection.down, 2),
        ],
      ),
      2 => _fromLegs(
        level: normalized,
        width: 4,
        height: 4,
        startX: 0,
        startY: 3,
        legs: const <_BeamLeg>[
          _BeamLeg(BeamDirection.up, 2),
          _BeamLeg(BeamDirection.right, 2),
        ],
      ),
      3 => _fromLegs(
        level: normalized,
        width: 5,
        height: 5,
        startX: 0,
        startY: 0,
        legs: const <_BeamLeg>[
          _BeamLeg(BeamDirection.right, 3),
          _BeamLeg(BeamDirection.down, 2),
          _BeamLeg(BeamDirection.left, 2),
        ],
      ),
      4 => _fromLegs(
        level: normalized,
        width: 5,
        height: 5,
        startX: 0,
        startY: 4,
        legs: const <_BeamLeg>[
          _BeamLeg(BeamDirection.up, 3),
          _BeamLeg(BeamDirection.right, 3),
          _BeamLeg(BeamDirection.down, 1),
        ],
      ),
      5 => _fromLegs(
        level: normalized,
        width: 5,
        height: 5,
        startX: 4,
        startY: 0,
        legs: const <_BeamLeg>[
          _BeamLeg(BeamDirection.down, 3),
          _BeamLeg(BeamDirection.left, 3),
          _BeamLeg(BeamDirection.up, 1),
        ],
      ),
      6 => _fromLegs(
        level: normalized,
        width: 5,
        height: 5,
        startX: 0,
        startY: 0,
        legs: const <_BeamLeg>[
          _BeamLeg(BeamDirection.right, 4),
          _BeamLeg(BeamDirection.down, 3),
          _BeamLeg(BeamDirection.left, 3),
          _BeamLeg(BeamDirection.up, 2),
        ],
      ),
      7 => _fromLegs(
        level: normalized,
        width: 5,
        height: 5,
        startX: 4,
        startY: 4,
        legs: const <_BeamLeg>[
          _BeamLeg(BeamDirection.left, 3),
          _BeamLeg(BeamDirection.up, 3),
          _BeamLeg(BeamDirection.right, 2),
          _BeamLeg(BeamDirection.down, 1),
        ],
      ),
      8 => _fromLegs(
        level: normalized,
        width: 5,
        height: 5,
        startX: 0,
        startY: 2,
        legs: const <_BeamLeg>[
          _BeamLeg(BeamDirection.right, 3),
          _BeamLeg(BeamDirection.up, 2),
          _BeamLeg(BeamDirection.left, 2),
          _BeamLeg(BeamDirection.down, 1),
          _BeamLeg(BeamDirection.right, 1),
        ],
      ),
      9 => _fromLegs(
        level: normalized,
        width: 5,
        height: 5,
        startX: 2,
        startY: 0,
        legs: const <_BeamLeg>[
          _BeamLeg(BeamDirection.down, 3),
          _BeamLeg(BeamDirection.right, 2),
          _BeamLeg(BeamDirection.up, 2),
          _BeamLeg(BeamDirection.left, 1),
        ],
      ),
      _ => _fromLegs(
        level: normalized,
        width: 5,
        height: 5,
        startX: 0,
        startY: 4,
        legs: const <_BeamLeg>[
          _BeamLeg(BeamDirection.right, 4),
          _BeamLeg(BeamDirection.up, 4),
          _BeamLeg(BeamDirection.left, 3),
          _BeamLeg(BeamDirection.down, 2),
          _BeamLeg(BeamDirection.right, 1),
        ],
      ),
    };
  }

  static BeamDirectorPuzzle _fromLegs({
    required int level,
    required int width,
    required int height,
    required int startX,
    required int startY,
    required List<_BeamLeg> legs,
  }) {
    assert(legs.length >= 2);
    int x = startX;
    int y = startY;
    final List<BeamMirror> mirrors = <BeamMirror>[];
    for (int index = 0; index < legs.length; index++) {
      final _BeamLeg leg = legs[index];
      x += leg.direction.dx * leg.steps;
      y += leg.direction.dy * leg.steps;
      if (x < 0 || x >= width || y < 0 || y >= height) {
        throw ArgumentError('Beam leg is outside the board.');
      }
      if (index == legs.length - 1) continue;
      final bool solvedSlash = _mirrorFor(
        incoming: leg.direction,
        outgoing: legs[index + 1].direction,
      );
      mirrors.add(
        BeamMirror(
          cell: y * width + x,
          solvedSlash: solvedSlash,
          initialSlash: (index + level).isEven ? solvedSlash : !solvedSlash,
        ),
      );
    }

    return BeamDirectorPuzzle(
      level: level,
      width: width,
      height: height,
      sourceCell: startY * width + startX,
      targetCell: y * width + x,
      sourceDirection: legs.first.direction,
      mirrors: List<BeamMirror>.unmodifiable(mirrors),
    );
  }

  static BeamDirection _reflect(
    BeamDirection direction, {
    required bool slash,
  }) {
    if (slash) {
      return switch (direction) {
        BeamDirection.up => BeamDirection.right,
        BeamDirection.right => BeamDirection.up,
        BeamDirection.down => BeamDirection.left,
        BeamDirection.left => BeamDirection.down,
      };
    }
    return switch (direction) {
      BeamDirection.up => BeamDirection.left,
      BeamDirection.left => BeamDirection.up,
      BeamDirection.down => BeamDirection.right,
      BeamDirection.right => BeamDirection.down,
    };
  }

  static bool _mirrorFor({
    required BeamDirection incoming,
    required BeamDirection outgoing,
  }) {
    const Set<String> slashTurns = <String>{
      'up:right',
      'right:up',
      'down:left',
      'left:down',
    };
    final String key = '${incoming.name}:${outgoing.name}';
    if (slashTurns.contains(key)) return true;
    const Set<String> backslashTurns = <String>{
      'up:left',
      'left:up',
      'down:right',
      'right:down',
    };
    if (backslashTurns.contains(key)) return false;
    throw ArgumentError('A beam path must turn 90 degrees at a mirror.');
  }
}

class _BeamLeg {
  const _BeamLeg(this.direction, this.steps) : assert(steps > 0);

  final BeamDirection direction;
  final int steps;
}
