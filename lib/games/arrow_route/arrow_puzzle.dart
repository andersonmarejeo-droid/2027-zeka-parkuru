import 'dart:math' as math;

import '../shared/content_seed.dart';

enum ArrowHeading { north, east, south, west }

class RouteArrow {
  const RouteArrow({
    required this.id,
    required this.row,
    required this.column,
    required this.heading,
  });

  final int id;
  final int row;
  final int column;
  final ArrowHeading heading;
}

/// An arrow-removal board with a generated, uniquely forced legal exit order.
/// Later arrows are placed outside every earlier exit ray while their own ray
/// is blocked by the immediately preceding arrow. This certifies solvability.
class ArrowPuzzle {
  const ArrowPuzzle._({
    required this.level,
    required this.size,
    required this.seed,
    required this.arrows,
    required this.solutionIds,
  });

  static const int maximumLevels = 20;
  static const int maximumVerifiedBoards = 300;
  static const int _generationAttempts = 260;
  static final Map<int, ArrowPuzzle> _campaign = <int, ArrowPuzzle>{};
  static final Map<int, ArrowPuzzle> _practice = <int, ArrowPuzzle>{};

  final int level;
  final int size;
  final int seed;
  final List<RouteArrow> arrows;
  final List<int> solutionIds;

  String get signature {
    final List<String> visibleArrows =
        arrows
            .map(
              (RouteArrow arrow) =>
                  '${arrow.row}:${arrow.column}:${arrow.heading.index}:${colorIndexFor(arrow)}',
            )
            .toList(growable: false)
          ..sort();
    return '$size:${visibleArrows.join('|')}';
  }

  int colorIndexFor(RouteArrow arrow) =>
      ((seed & 0x7fffffff) + arrow.row * 17 + arrow.column * 31) % 4;

  String get difficultyTier => switch (level) {
    <= 6 => 'MASTERY',
    7 || 8 => 'ADVANCED',
    <= 16 => 'EXPERT',
    _ => 'MASTER',
  };

  Map<String, Object?> toCampaignMap() => {
    'level': level,
    'size': size,
    'seed': seed,
    'solutionIds': solutionIds,
    'arrows': arrows
        .map((a) => [a.id, a.row, a.column, a.heading.index])
        .toList(),
  };

  static void installCampaignBank(List<dynamic> boards) {
    if (boards.length != 300) throw FormatException('Invalid arrow_route bank');
    for (int i = 0; i < boards.length; i++) {
      final m = Map<String, dynamic>.from(boards[i] as Map);
      _practice[i + 1] = ArrowPuzzle._(
        level: m['level'] as int,
        size: m['size'] as int,
        seed: m['seed'] as int,
        solutionIds: List<int>.from(m['solutionIds'] as List),
        arrows: (m['arrows'] as List)
            .map(
              (e) => RouteArrow(
                id: e[0] as int,
                row: e[1] as int,
                column: e[2] as int,
                heading: ArrowHeading.values[e[3] as int],
              ),
            )
            .toList(),
      );
    }
  }

  static ArrowPuzzle forLevel(int level) {
    if (level < 1 || level > maximumLevels) {
      throw RangeError.range(level, 1, maximumLevels, 'level');
    }
    return _campaign.putIfAbsent(level, () => _generate(level));
  }

  /// Returns the first 300 deterministic, campaign-distinct replay boards.
  static ArrowPuzzle forPracticeBoard(int index) {
    final cached = _practice[index];
    if (cached != null) return cached;
    if (index < 1 || index > maximumVerifiedBoards) {
      throw RangeError.range(index, 1, maximumVerifiedBoards, 'index');
    }
    for (int level = 1; level <= maximumLevels; level++) {
      _campaign.putIfAbsent(level, () => _generate(level));
    }
    for (int next = _practice.length + 1; next <= index; next++) {
      final int level = ((next - 1) % maximumLevels) + 1;
      ArrowPuzzle? accepted;
      for (int cycle = next; accepted == null; cycle++) {
        final ArrowPuzzle candidate = _generate(
          level,
          contentCycle: 1000 + cycle,
        );
        final bool repeated =
            <ArrowPuzzle>[..._campaign.values, ..._practice.values].any(
              (ArrowPuzzle previous) =>
                  previous.signature == candidate.signature,
            );
        if (!repeated) accepted = candidate;
      }
      _practice[next] = accepted;
    }
    return _practice[index]!;
  }

  RouteArrow arrowById(int id) =>
      arrows.firstWhere((RouteArrow arrow) => arrow.id == id);

  List<RouteArrow> clearable(Set<int> remainingIds) => arrows
      .where(
        (RouteArrow arrow) =>
            remainingIds.contains(arrow.id) &&
            blockerFor(arrow, remainingIds) == null,
      )
      .toList(growable: false);

  RouteArrow? blockerFor(RouteArrow arrow, Set<int> remainingIds) {
    for (final (int row, int column) in _ray(
      row: arrow.row,
      column: arrow.column,
      heading: arrow.heading,
      size: size,
    )) {
      for (final RouteArrow other in arrows) {
        if (remainingIds.contains(other.id) &&
            other.row == row &&
            other.column == column) {
          return other;
        }
      }
    }
    return null;
  }

  List<(int, int)> exitRay(RouteArrow arrow) => _ray(
    row: arrow.row,
    column: arrow.column,
    heading: arrow.heading,
    size: size,
  );

  bool hasCertifiedUniqueOrder() {
    final Set<int> remaining = arrows
        .map((RouteArrow arrow) => arrow.id)
        .toSet();
    for (final int expected in solutionIds) {
      final List<RouteArrow> choices = clearable(remaining);
      if (choices.length != 1 || choices.single.id != expected) return false;
      remaining.remove(expected);
    }
    return remaining.isEmpty && clearable(remaining).isEmpty;
  }

  static ArrowPuzzle _generate(int level, {int contentCycle = 0}) {
    final int size = _sizeForLevel(level);
    final int arrowCount = _arrowCountForLevel(level);
    for (int attempt = 0; attempt < _generationAttempts; attempt++) {
      final int seed = ContentSeed.forLevel(
        gameId: 'arrow_route:$contentCycle',
        level: level,
        attempt: attempt,
      );
      final math.Random random = math.Random(seed);
      final List<RouteArrow> arrows = <RouteArrow>[
        RouteArrow(
          id: 0,
          row: random.nextInt(size),
          column: random.nextInt(size),
          heading: ArrowHeading.values[random.nextInt(4)],
        ),
      ];

      while (arrows.length < arrowCount) {
        final RouteArrow previous = arrows.last;
        final Set<(int, int)> occupiedRays = <(int, int)>{
          for (final RouteArrow arrow in arrows)
            ..._ray(
              row: arrow.row,
              column: arrow.column,
              heading: arrow.heading,
              size: size,
            ),
        };
        final List<RouteArrow> candidates = <RouteArrow>[];
        for (int row = 0; row < size; row++) {
          for (int column = 0; column < size; column++) {
            if (arrows.any(
              (RouteArrow arrow) => arrow.row == row && arrow.column == column,
            )) {
              continue;
            }
            if (occupiedRays.contains((row, column))) continue;
            for (final ArrowHeading heading in ArrowHeading.values) {
              final List<(int, int)> ray = _ray(
                row: row,
                column: column,
                heading: heading,
                size: size,
              );
              if (ray.contains((previous.row, previous.column))) {
                candidates.add(
                  RouteArrow(
                    id: arrows.length,
                    row: row,
                    column: column,
                    heading: heading,
                  ),
                );
              }
            }
          }
        }
        if (candidates.isEmpty) break;

        // Prefer occasional right-angle turns so the certified dependency
        // chain reads as a layered spatial problem, not a single straight row.
        final List<RouteArrow> turns = candidates
            .where(
              (RouteArrow candidate) =>
                  candidate.heading.index.isOdd != previous.heading.index.isOdd,
            )
            .toList(growable: false);
        final List<RouteArrow> pool = turns.isNotEmpty && random.nextBool()
            ? turns
            : candidates;
        arrows.add(pool[random.nextInt(pool.length)]);
      }

      if (arrows.length != arrowCount) continue;
      final ArrowPuzzle puzzle = ArrowPuzzle._(
        level: level,
        size: size,
        seed: seed,
        arrows: List<RouteArrow>.unmodifiable(arrows),
        solutionIds: List<int>.unmodifiable(
          List<int>.generate(arrows.length, (int index) => index),
        ),
      );
      if (puzzle.hasCertifiedUniqueOrder()) return puzzle;
    }
    throw StateError(
      'Could not create a uniquely solvable Arrow Route board for level $level.',
    );
  }

  static int _sizeForLevel(int level) => switch (level) {
    <= 2 => 5,
    <= 6 => 6,
    <= 10 => 7,
    _ => 8,
  };

  static int _arrowCountForLevel(int level) => switch (level) {
    <= 10 => 6 + level,
    _ => 5 + level,
  };

  static List<(int, int)> _ray({
    required int row,
    required int column,
    required ArrowHeading heading,
    required int size,
  }) {
    final (int rowDelta, int columnDelta) = switch (heading) {
      ArrowHeading.north => (-1, 0),
      ArrowHeading.east => (0, 1),
      ArrowHeading.south => (1, 0),
      ArrowHeading.west => (0, -1),
    };
    final List<(int, int)> cells = <(int, int)>[];
    int nextRow = row + rowDelta;
    int nextColumn = column + columnDelta;
    while (nextRow >= 0 &&
        nextRow < size &&
        nextColumn >= 0 &&
        nextColumn < size) {
      cells.add((nextRow, nextColumn));
      nextRow += rowDelta;
      nextColumn += columnDelta;
    }
    return cells;
  }
}
