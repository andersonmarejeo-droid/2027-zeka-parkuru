import 'dart:math';

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

/// A small authored shape whose every segment can be traced in one continuous
/// stroke. The 30-stage campaign advances from simple polygons to a clean
/// house network shown in the reference. Expert rounds keep the main network
/// readable instead of attaching tiny auxiliary triangles or quadrilaterals.
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
    } else {
      shapeNameTr = switch (stage) {
        5 => 'Ev',
        6 => 'Çaprazlı ev',
        7 => 'Çift çaprazlı ev',
        8 => 'Ev ve kesişen çizgiler',
        <= 12 => 'İç kirişli ev',
        <= 16 => 'Çift katlı ev ağı',
        <= 20 => 'Yan kollu ev ağı',
        <= 24 => 'Dış çerçeveli ev ağı',
        _ => 'Usta ağ geçidi',
      };
      shapeNameEn = switch (stage) {
        5 => 'House',
        6 => 'House with a diagonal',
        7 => 'House with crossed diagonals',
        8 => 'House with a crossing',
        <= 12 => 'House with an inner ridge',
        <= 16 => 'Two-tier house network',
        <= 20 => 'House network with side wings',
        <= 24 => 'Framed house network',
        _ => 'Master network gateway',
      };

      // The silhouette is deliberately recognizable: roof, walls, and base.
      points.addAll(<StrokePoint>[
        _jitter(const StrokePoint(.5, .12), random, .014), // roof peak
        _jitter(const StrokePoint(.17, .41), random, .014), // upper left
        _jitter(const StrokePoint(.83, .41), random, .014), // upper right
        _jitter(const StrokePoint(.83, .87), random, .014), // lower right
        _jitter(const StrokePoint(.17, .87), random, .014), // lower left
      ]);
      edges.addAll(const <StrokeEdge>[
        StrokeEdge(0, 1),
        StrokeEdge(0, 2),
        StrokeEdge(1, 2),
        StrokeEdge(2, 3),
        StrokeEdge(3, 4),
        StrokeEdge(4, 1),
      ]);

      if (stage == 6) {
        edges.add(const StrokeEdge(1, 3));
      } else if (stage == 7) {
        edges.addAll(const <StrokeEdge>[StrokeEdge(1, 3), StrokeEdge(2, 4)]);
      } else if (stage >= 8) {
        final int crossing = points.length;
        points.add(_jitter(const StrokePoint(.5, .64), random, .006));
        edges.addAll(<StrokeEdge>[
          StrokeEdge(1, crossing),
          StrokeEdge(crossing, 3),
          StrokeEdge(2, crossing),
          StrokeEdge(crossing, 4),
        ]);

        // Add large routes through the main network in difficulty tiers. Each
        // route is a broad structural loop attached to one existing node. A
        // loop adds two edges to its anchor, so the two open endpoints of the
        // house remain open and the whole graph stays Euler-traceable. These
        // are broad structural corridors, never tiny attached loops.
        if (stage >= 9) {
          _addMainRoute(
            points: points,
            edges: edges,
            anchor: 1,
            bends: const <StrokePoint>[
              StrokePoint(.30, .26),
              StrokePoint(.50, .30),
              StrokePoint(.70, .26),
            ],
            random: random,
          );
        }
        if (stage >= 13) {
          _addMainRoute(
            points: points,
            edges: edges,
            anchor: 2,
            bends: const <StrokePoint>[
              StrokePoint(.30, .68),
              StrokePoint(.50, .86),
              StrokePoint(.70, .68),
            ],
            random: random,
          );
        }
        if (stage >= 17) {
          _addMainRoute(
            points: points,
            edges: edges,
            anchor: 1,
            bends: const <StrokePoint>[
              StrokePoint(.08, .60),
              StrokePoint(.50, .45),
              StrokePoint(.92, .60),
            ],
            random: random,
          );
        }
        if (stage >= 21) {
          _addMainRoute(
            points: points,
            edges: edges,
            anchor: 2,
            bends: const <StrokePoint>[
              StrokePoint(.10, .23),
              StrokePoint(.90, .23),
            ],
            random: random,
          );
        }
        if (stage >= 25) {
          _addMainRoute(
            points: points,
            edges: edges,
            anchor: 1,
            bends: const <StrokePoint>[
              StrokePoint(.32, .50),
              StrokePoint(.68, .50),
            ],
            random: random,
          );
        }
      }
    }

    final _EulerRoute route = _findEulerRoute(points.length, edges);
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

  static void _addMainRoute({
    required List<StrokePoint> points,
    required List<StrokeEdge> edges,
    required int anchor,
    required List<StrokePoint> bends,
    required Random random,
  }) {
    int previous = anchor;
    for (final StrokePoint bend in bends) {
      final int next = points.length;
      points.add(_jitter(bend, random, .004));
      edges.add(StrokeEdge(previous, next));
      previous = next;
    }
    // Close the broad corridor at its anchor. This preserves the two
    // endpoint nodes (the lower corners) for every difficulty tier.
    edges.add(StrokeEdge(previous, anchor));
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
