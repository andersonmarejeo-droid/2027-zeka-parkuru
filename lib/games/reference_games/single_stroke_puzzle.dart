import 'dart:math';
import 'dart:ui';

class StrokePoint {
  const StrokePoint(this.x, this.y);
  final double x;
  final double y;
}

class StrokeEdge {
  const StrokeEdge(this.a, this.b);
  final int a;
  final int b;
  int get low => min(a, b);
  int get high => max(a, b);
  String get key => '$low-$high';
}

/// Authored, validated one-stroke shapes. Every crossing is an explicit node;
/// the campaign never relies on lines visually passing over one another.
class SingleStrokePuzzle {
  const SingleStrokePuzzle({
    required this.points,
    required this.edges,
    required this.start,
    required this.end,
    required this.solution,
    required this.shapeNameTr,
    required this.shapeNameEn,
  });

  final List<StrokePoint> points;
  final List<StrokeEdge> edges;
  final int start;
  final int end;
  final List<int> solution;
  final String shapeNameTr;
  final String shapeNameEn;

  String get signature =>
      '${points.map((StrokePoint p) => '${(p.x * 10000).round()},${(p.y * 10000).round()}').join(';')}#${edges.map((StrokeEdge e) => e.key).toSet().toList()..sort()}';

  static SingleStrokePuzzle generate(int level, int variant) {
    final int safeLevel = level.clamp(1, 300).toInt();
    // The campaign has one authored difficulty stage per visible chapter.
    final int stage = safeLevel.clamp(1, 30).toInt();
    final Random random = Random(
      0x5354524F ^ safeLevel * 7919 ^ variant * 104729,
    );
    final List<StrokePoint> points = <StrokePoint>[];
    final List<StrokeEdge> edges = <StrokeEdge>[];
    late String shapeNameTr;
    late String shapeNameEn;

    if (stage <= 4) {
      final int sides = stage + 2;
      const List<String> namesTr = <String>[
        'Üçgen',
        'Kare',
        'Beşgen',
        'Altıgen',
      ];
      const List<String> namesEn = <String>[
        'Triangle',
        'Square',
        'Pentagon',
        'Hexagon',
      ];
      shapeNameTr = namesTr[stage - 1];
      shapeNameEn = namesEn[stage - 1];
      final double phase = -pi / 2 + (random.nextDouble() - .5) * .12;
      final double radiusX = .31 + random.nextDouble() * .035;
      final double radiusY = .31 + random.nextDouble() * .035;
      for (int index = 0; index < sides; index++) {
        final double angle = phase + 2 * pi * index / sides;
        final double radius = .985 + random.nextDouble() * .03;
        points.add(
          _jitter(
            StrokePoint(
              .5 + cos(angle) * radiusX * radius,
              .5 + sin(angle) * radiusY * radius,
            ),
            random,
            .009,
          ),
        );
        edges.add(StrokeEdge(index, (index + 1) % sides));
      }
    } else if (stage <= 8) {
      _addHouse(points: points, edges: edges);
      shapeNameTr = switch (stage) {
        5 => 'Ev',
        6 => 'Tek çaprazlı ev',
        7 => 'Merkez düğümlü ev',
        _ => 'Taçlı ev ağı',
      };
      shapeNameEn = switch (stage) {
        5 => 'House',
        6 => 'House with one diagonal',
        7 => 'House with a joined crossing',
        _ => 'Crowned house network',
      };

      if (stage == 6) {
        // A single diagonal stays inside the house and has no hidden crossing.
        edges.add(const StrokeEdge(1, 3));
      }
      if (stage >= 7) {
        // The two diagonals meet at a real node. No line crosses invisibly.
        final int center = points.length;
        points.add(const StrokePoint(.5, .66));
        edges.addAll(<StrokeEdge>[
          StrokeEdge(1, center),
          StrokeEdge(center, 3),
          StrokeEdge(2, center),
          StrokeEdge(center, 4),
        ]);
      }
      if (stage == 8) {
        // A broad, separate crown loop adds challenge without threading lines
        // through the house body.
        final int left = points.length;
        points.add(const StrokePoint(.34, .18));
        final int crown = points.length;
        points.add(const StrokePoint(.5, .08));
        final int right = points.length;
        points.add(const StrokePoint(.66, .18));
        edges.addAll(<StrokeEdge>[
          StrokeEdge(0, left),
          StrokeEdge(left, crown),
          StrokeEdge(crown, right),
          StrokeEdge(right, 0),
        ]);
      }
    } else {
      shapeNameTr = switch (stage) {
        <= 11 => 'Açık köprü ağı',
        <= 14 => 'Çift yönlü köprü ağı',
        <= 18 => 'Usta köprü ağı',
        _ => 'Büyük usta ağı',
      };
      shapeNameEn = switch (stage) {
        <= 11 => 'Open bridge network',
        <= 14 => 'Two-way bridge network',
        <= 18 => 'Master bridge network',
        _ => 'Grand master network',
      };

      // One open spine provides the two endpoints. Broad loops attach to it
      // in separate upper/lower lanes; they never overlap or cross each other.
      final double leftAnchorX = stage == 30 ? .235 : .24;
      final double rightAnchorX = 1 - leftAnchorX;
      points.addAll(<StrokePoint>[
        const StrokePoint(.05, .5),
        StrokePoint(leftAnchorX, .5),
        const StrokePoint(.5, .5),
        StrokePoint(rightAnchorX, .5),
        const StrokePoint(.95, .5),
      ]);
      edges.addAll(const <StrokeEdge>[
        StrokeEdge(0, 1),
        StrokeEdge(1, 2),
        StrokeEdge(2, 3),
        StrokeEdge(3, 4),
      ]);

      final int activeLoopCount = stage <= 11
          ? 2
          : stage <= 14
          ? 3
          : 4;
      final int targetLoopEdges = switch (stage) {
        <= 11 => 8 + (stage - 9),
        <= 14 => 12 + (stage - 12),
        <= 18 => 16 + (stage - 15),
        _ => 20,
      };
      final List<int> slots = switch (activeLoopCount) {
        2 => const <int>[0, 3],
        3 => const <int>[0, 1, 3],
        _ => const <int>[0, 1, 2, 3],
      };
      final List<int> cycleSizes = _cycleSizes(
        activeLoopCount: activeLoopCount,
        totalEdges: targetLoopEdges,
        rotation: (stage + variant) % activeLoopCount,
      );
      for (int index = 0; index < slots.length; index++) {
        final int slot = slots[index];
        final bool top = slot < 2;
        final int anchor = slot.isEven ? 1 : 3;
        final double centerX = points[anchor].x;
        // Give every late campaign level its own broad loop silhouette while
        // keeping the upper/lower corridors safely apart. Fine-grained shifts
        // are intentional: they change the outline without squeezing paths.
        final double outerY = stage >= 19
            ? .12 + (stage - 19) * .0025 + slot * .0005
            : .14;
        _addClearLoop(
          points: points,
          edges: edges,
          anchor: anchor,
          centerX: centerX,
          top: top,
          edgeCount: cycleSizes[index],
          outerY: outerY,
          bendOffset: (stage + variant + slot).isEven ? .17 : .15,
        );
      }
    }

    final _EulerRoute route = _findEulerRoute(points.length, edges);
    _validateGeometry(points: points, edges: edges);
    return SingleStrokePuzzle(
      points: List<StrokePoint>.unmodifiable(points),
      edges: List<StrokeEdge>.unmodifiable(edges),
      start: route.start,
      end: route.end,
      solution: List<int>.unmodifiable(route.vertices),
      shapeNameTr: shapeNameTr,
      shapeNameEn: shapeNameEn,
    );
  }

  static StrokePoint _jitter(StrokePoint point, Random random, double amount) =>
      StrokePoint(
        (point.x + (random.nextDouble() - .5) * amount * 2)
            .clamp(.055, .945)
            .toDouble(),
        (point.y + (random.nextDouble() - .5) * amount * 2)
            .clamp(.055, .945)
            .toDouble(),
      );

  static void _addHouse({
    required List<StrokePoint> points,
    required List<StrokeEdge> edges,
  }) {
    points.addAll(const <StrokePoint>[
      StrokePoint(.5, .30), // roof peak
      StrokePoint(.2, .48), // upper left
      StrokePoint(.8, .48), // upper right
      StrokePoint(.8, .84), // lower right
      StrokePoint(.2, .84), // lower left
    ]);
    edges.addAll(const <StrokeEdge>[
      StrokeEdge(0, 1),
      StrokeEdge(0, 2),
      StrokeEdge(1, 2),
      StrokeEdge(2, 3),
      StrokeEdge(3, 4),
      StrokeEdge(4, 1),
    ]);
  }

  static List<int> _cycleSizes({
    required int activeLoopCount,
    required int totalEdges,
    required int rotation,
  }) {
    final List<int> sizes = List<int>.filled(activeLoopCount, 4);
    int extraEdges = totalEdges - activeLoopCount * 4;
    int cursor = 0;
    while (extraEdges > 0) {
      final int index = (cursor + rotation) % activeLoopCount;
      if (sizes[index] < 5) {
        sizes[index]++;
        extraEdges--;
      }
      cursor++;
    }
    return sizes;
  }

  static void _addClearLoop({
    required List<StrokePoint> points,
    required List<StrokeEdge> edges,
    required int anchor,
    required double centerX,
    required bool top,
    required int edgeCount,
    required double outerY,
    required double bendOffset,
  }) {
    double y(double value) => top ? value : 1 - value;
    final List<int> cycle = <int>[anchor];
    final double direction = anchor == 1 ? 1 : -1;

    int add(double x, double yValue) {
      final int index = points.length;
      points.add(StrokePoint(x, y(yValue)));
      return index;
    }

    cycle.add(add(centerX + direction * .17, .32));
    if (edgeCount == 5) {
      cycle.add(add(centerX + direction * bendOffset, outerY));
    }
    cycle.add(add(centerX, .03));
    cycle.add(add(centerX - direction * .12, .19));
    for (int index = 0; index < cycle.length; index++) {
      edges.add(StrokeEdge(cycle[index], cycle[(index + 1) % cycle.length]));
    }
  }

  static void _validateGeometry({
    required List<StrokePoint> points,
    required List<StrokeEdge> edges,
  }) {
    // The board's gesture corridor is about .17 of its width. Keep unrelated
    // nodes/segments at least this far apart so a finger cannot land in two
    // paths at once on a small phone.
    const double minimumPointSpacing = .17;
    const double minimumEdgeLength = .17;
    const double minimumClearance = .17;

    Offset map(StrokePoint point) => Offset(point.x, point.y * 1.12);
    final List<Offset> mapped = points.map(map).toList(growable: false);
    for (int first = 0; first < mapped.length; first++) {
      for (int second = first + 1; second < mapped.length; second++) {
        if ((mapped[first] - mapped[second]).distance < minimumPointSpacing) {
          throw StateError(
            'Single-stroke nodes $first and $second are too close.',
          );
        }
      }
    }

    final Set<String> uniqueEdges = <String>{};
    for (final StrokeEdge edge in edges) {
      if (!uniqueEdges.add(edge.key)) {
        throw StateError('Single-stroke puzzle contains a duplicate edge.');
      }
      if ((mapped[edge.a] - mapped[edge.b]).distance < minimumEdgeLength) {
        throw StateError('Single-stroke edge ${edge.key} is too short.');
      }
    }

    for (int edgeIndex = 0; edgeIndex < edges.length; edgeIndex++) {
      final StrokeEdge first = edges[edgeIndex];
      final Offset a = mapped[first.a];
      final Offset b = mapped[first.b];
      for (int node = 0; node < mapped.length; node++) {
        if (node == first.a || node == first.b) continue;
        if (_pointSegmentDistance(mapped[node], a, b) < minimumClearance) {
          throw StateError(
            'Single-stroke node $node is too close to edge ${first.key}.',
          );
        }
      }
      for (
        int otherIndex = edgeIndex + 1;
        otherIndex < edges.length;
        otherIndex++
      ) {
        final StrokeEdge second = edges[otherIndex];
        final int? sharedNode = first.a == second.a || first.a == second.b
            ? first.a
            : first.b == second.a || first.b == second.b
            ? first.b
            : null;
        if (sharedNode != null) {
          final int firstOther = first.a == sharedNode ? first.b : first.a;
          final int secondOther = second.a == sharedNode ? second.b : second.a;
          final Offset firstVector = mapped[firstOther] - mapped[sharedNode];
          final Offset secondVector = mapped[secondOther] - mapped[sharedNode];
          final double cosine =
              (firstVector.dx * secondVector.dx +
                  firstVector.dy * secondVector.dy) /
              (firstVector.distance * secondVector.distance);
          if (cosine > .9) {
            throw StateError(
              'Single-stroke edges at node $sharedNode overlap or are too close.',
            );
          }
          continue;
        }
        if (_segmentDistance(a, b, mapped[second.a], mapped[second.b]) <
            minimumClearance) {
          throw StateError(
            'Single-stroke edges ${first.key} and ${second.key} cross or overlap.',
          );
        }
      }
    }
  }

  static double _pointSegmentDistance(Offset point, Offset start, Offset end) {
    final Offset segment = end - start;
    final double lengthSquared = segment.distanceSquared;
    if (lengthSquared == 0) return (point - start).distance;
    final double projection =
        (((point - start).dx * segment.dx + (point - start).dy * segment.dy) /
                lengthSquared)
            .clamp(0.0, 1.0)
            .toDouble();
    return (point - (start + segment * projection)).distance;
  }

  static double _segmentDistance(Offset a, Offset b, Offset c, Offset d) {
    if (_segmentsIntersect(a, b, c, d)) return 0;
    return <double>[
      _pointSegmentDistance(a, c, d),
      _pointSegmentDistance(b, c, d),
      _pointSegmentDistance(c, a, b),
      _pointSegmentDistance(d, a, b),
    ].reduce(min);
  }

  static bool _segmentsIntersect(Offset a, Offset b, Offset c, Offset d) {
    const double epsilon = 1e-10;
    double orientation(Offset p, Offset q, Offset r) =>
        (q.dx - p.dx) * (r.dy - p.dy) - (q.dy - p.dy) * (r.dx - p.dx);
    bool onSegment(Offset p, Offset q, Offset r) =>
        q.dx >= min(p.dx, r.dx) - epsilon &&
        q.dx <= max(p.dx, r.dx) + epsilon &&
        q.dy >= min(p.dy, r.dy) - epsilon &&
        q.dy <= max(p.dy, r.dy) + epsilon;

    final double o1 = orientation(a, b, c);
    final double o2 = orientation(a, b, d);
    final double o3 = orientation(c, d, a);
    final double o4 = orientation(c, d, b);
    if (o1 * o2 < -epsilon && o3 * o4 < -epsilon) return true;
    if (o1.abs() <= epsilon && onSegment(a, c, b)) return true;
    if (o2.abs() <= epsilon && onSegment(a, d, b)) return true;
    if (o3.abs() <= epsilon && onSegment(c, a, d)) return true;
    if (o4.abs() <= epsilon && onSegment(c, b, d)) return true;
    return false;
  }

  static _EulerRoute _findEulerRoute(int pointCount, List<StrokeEdge> edges) {
    final List<List<int>> adjacency = List<List<int>>.generate(
      pointCount,
      (_) => <int>[],
    );
    final List<int> degree = List<int>.filled(pointCount, 0);
    for (int index = 0; index < edges.length; index++) {
      final StrokeEdge edge = edges[index];
      adjacency[edge.a].add(index);
      adjacency[edge.b].add(index);
      degree[edge.a]++;
      degree[edge.b]++;
    }
    final List<int> odd = <int>[
      for (int index = 0; index < degree.length; index++)
        if (degree[index].isOdd) index,
    ];
    if (odd.isNotEmpty && odd.length != 2) {
      throw StateError('Single-stroke shape must have zero or two odd nodes.');
    }
    final int start = odd.isEmpty ? 0 : odd.first;
    final int end = odd.isEmpty ? start : odd.last;
    final List<bool> used = List<bool>.filled(edges.length, false);
    final List<int> vertexStack = <int>[start];
    final List<int> route = <int>[];
    while (vertexStack.isNotEmpty) {
      final int current = vertexStack.last;
      final int edgeIndex = adjacency[current].firstWhere(
        (int candidate) => !used[candidate],
        orElse: () => -1,
      );
      if (edgeIndex < 0) {
        route.add(vertexStack.removeLast());
      } else {
        used[edgeIndex] = true;
        final StrokeEdge edge = edges[edgeIndex];
        vertexStack.add(edge.a == current ? edge.b : edge.a);
      }
    }
    final List<int> vertices = route.reversed.toList(growable: false);
    if (vertices.length != edges.length + 1 || vertices.last != end) {
      throw StateError('Generated shape is disconnected or not one-stroke.');
    }
    return _EulerRoute(start: start, end: end, vertices: vertices);
  }
}

class _EulerRoute {
  const _EulerRoute({
    required this.start,
    required this.end,
    required this.vertices,
  });
  final int start;
  final int end;
  final List<int> vertices;
}
