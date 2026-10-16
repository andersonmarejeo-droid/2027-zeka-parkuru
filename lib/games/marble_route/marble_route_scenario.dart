import 'dart:math' as math;

import '../shared/content_seed.dart';

class MarblePoint {
  const MarblePoint(this.x, this.y);

  final double x;
  final double y;

  String get signature => '${x.toStringAsFixed(3)}:${y.toStringAsFixed(3)}';
}

class MarbleGate {
  const MarbleGate({
    required this.y,
    required this.center,
    required this.width,
    required this.amplitude,
    required this.frequency,
    required this.phase,
  });

  final double y;
  final double center;
  final double width;
  final double amplitude;
  final double frequency;
  final double phase;

  double centerAt(double seconds) =>
      center + amplitude * math.sin(seconds * frequency + phase);

  String get signature =>
      '${y.toStringAsFixed(3)}:${center.toStringAsFixed(3)}:'
      '${width.toStringAsFixed(3)}:${amplitude.toStringAsFixed(3)}:'
      '${frequency.toStringAsFixed(3)}:${phase.toStringAsFixed(3)}';
}

enum MarbleSurfaceKind { felt, rough, ice, current }

class MarbleSurface {
  const MarbleSurface({
    required this.center,
    required this.width,
    required this.height,
    required this.drag,
    required this.kind,
    this.flowX = 0,
    this.flowY = 0,
  });

  final MarblePoint center;
  final double width;
  final double height;
  final double drag;
  final MarbleSurfaceKind kind;
  final double flowX;
  final double flowY;

  bool contains(double x, double y) {
    final double dx = (x - center.x) / (width / 2);
    final double dy = (y - center.y) / (height / 2);
    return dx * dx + dy * dy <= 1;
  }

  String get signature =>
      '${center.signature}:${width.toStringAsFixed(3)}:'
      '${height.toStringAsFixed(3)}:${drag.toStringAsFixed(3)}:$kind:'
      '${flowX.toStringAsFixed(3)}:${flowY.toStringAsFixed(3)}';
}

class MarbleBumper {
  const MarbleBumper({required this.center, required this.radius});

  final MarblePoint center;
  final double radius;

  String get signature => '${center.signature}:${radius.toStringAsFixed(3)}';
}

class MarblePit {
  const MarblePit({required this.center, required this.radius});

  final MarblePoint center;
  final double radius;

  String get signature => '${center.signature}:${radius.toStringAsFixed(3)}';
}

/// Deterministic ten-course campaign and 300 distinct replay configurations.
class MarbleRouteScenario {
  const MarbleRouteScenario._({
    required this.level,
    required this.seed,
    required this.start,
    required this.goal,
    required this.gates,
    required this.surfaces,
    required this.bumpers,
    required this.pits,
    required this.missLimit,
    required this.goldTimeSeconds,
    required this.tiltResponse,
  });

  static const int maximumLevels = 10;
  static const int maximumPracticeRounds = 300;
  static final Map<int, MarbleRouteScenario> _campaign =
      <int, MarbleRouteScenario>{};
  static final Map<int, MarbleRouteScenario> _practice =
      <int, MarbleRouteScenario>{};

  final int level;
  final int seed;
  final MarblePoint start;
  final MarblePoint goal;
  final List<MarbleGate> gates;
  final List<MarbleSurface> surfaces;
  final List<MarbleBumper> bumpers;
  final List<MarblePit> pits;
  final int missLimit;
  final double goldTimeSeconds;
  final double tiltResponse;

  String get signature =>
      '$level|${start.signature}|${goal.signature}|'
      '${gates.map((MarbleGate gate) => gate.signature).join(';')}|'
      '${surfaces.map((MarbleSurface surface) => surface.signature).join(';')}|'
      '${bumpers.map((MarbleBumper bumper) => bumper.signature).join(';')}|'
      '${pits.map((MarblePit pit) => pit.signature).join(';')}|'
      '$missLimit:${goldTimeSeconds.toStringAsFixed(2)}:'
      '${tiltResponse.toStringAsFixed(3)}';

  static void _checkLevel(int level) {
    if (level < 1 || level > maximumLevels) {
      throw RangeError.range(level, 1, maximumLevels, 'level');
    }
  }

  static MarbleRouteScenario forLevel(int level) {
    _checkLevel(level);
    for (int next = 1; next <= level; next++) {
      _campaign.putIfAbsent(next, () => _build(next, replayIndex: 0));
    }
    return _campaign[level]!;
  }

  static MarbleRouteScenario forPracticeRound(int index) {
    if (index < 1 || index > maximumPracticeRounds) {
      throw RangeError.range(index, 1, maximumPracticeRounds, 'index');
    }
    for (int level = 1; level <= maximumLevels; level++) {
      forLevel(level);
    }
    for (int next = _practice.length + 1; next <= index; next++) {
      final int level = ((next - 1) % maximumLevels) + 1;
      _practice[next] = _build(level, replayIndex: next);
    }
    return _practice[index]!;
  }

  static Set<String> get _usedSignatures => <String>{
    ..._campaign.values.map((MarbleRouteScenario course) => course.signature),
    ..._practice.values.map((MarbleRouteScenario course) => course.signature),
  };

  static MarbleRouteScenario _build(int level, {required int replayIndex}) {
    _checkLevel(level);
    final Set<String> used = _usedSignatures;
    for (int attempt = 0; attempt < 240; attempt++) {
      final int seed = ContentSeed.forLevel(
        gameId: 'marble_route:$replayIndex',
        level: level,
        attempt: attempt,
      );
      final math.Random random = math.Random(seed);
      final int gateCount = switch (level) {
        <= 2 => 1,
        <= 5 => 2,
        <= 8 => 3,
        9 => 4,
        _ => 5,
      };
      final double aperture = (.47 - level * .028).clamp(.18, .44).toDouble();
      final List<MarbleGate> gates = List<MarbleGate>.generate(gateCount, (
        int index,
      ) {
        final double y = .78 - (index + 1) * .52 / (gateCount + 1);
        final double amplitude = level <= 2
            ? 0
            : level <= 5
            ? .008 + level * .002
            : .018 + (level - 5) * .009;
        final double center = (.5 + (random.nextDouble() - .5) * .17)
            .clamp(.39, .61)
            .toDouble();
        return MarbleGate(
          y: y,
          center: center,
          width: aperture,
          amplitude: amplitude,
          frequency: .38 + level * .046 + random.nextDouble() * .13,
          phase: random.nextDouble() * math.pi * 2,
        );
      }, growable: false);

      final List<MarbleSurface> surfaces = <MarbleSurface>[];
      final int surfaceCount = level <= 2 ? 0 : (level + 1) ~/ 2;
      for (int index = 0; index < surfaceCount; index++) {
        final MarbleSurfaceKind kind = switch ((index + level) % 3) {
          0 => MarbleSurfaceKind.rough,
          1 => MarbleSurfaceKind.ice,
          _ => MarbleSurfaceKind.current,
        };
        final double y = .25 + random.nextDouble() * .50;
        final double x = .25 + random.nextDouble() * .50;
        surfaces.add(
          MarbleSurface(
            center: MarblePoint(x, y),
            width: .14 + random.nextDouble() * .12,
            height: .07 + random.nextDouble() * .055,
            drag: switch (kind) {
              MarbleSurfaceKind.rough => 2.5 + random.nextDouble() * .6,
              MarbleSurfaceKind.ice => .11 + random.nextDouble() * .12,
              MarbleSurfaceKind.current => .68 + random.nextDouble() * .3,
              MarbleSurfaceKind.felt => .9,
            },
            kind: kind,
            flowX: kind == MarbleSurfaceKind.current
                ? (random.nextDouble() - .5) * .72
                : 0,
            flowY: kind == MarbleSurfaceKind.current
                ? (random.nextDouble() - .5) * .56
                : 0,
          ),
        );
      }

      final List<MarbleBumper> bumpers = <MarbleBumper>[];
      final int bumperCount = math.max(0, level - 3);
      for (int index = 0; index < bumperCount; index++) {
        for (int placement = 0; placement < 80; placement++) {
          final MarblePoint point = MarblePoint(
            .18 + random.nextDouble() * .64,
            .19 + random.nextDouble() * .62,
          );
          final double radius = .022 + random.nextDouble() * .012;
          final bool awayFromAnchors = <MarblePoint>[
            const MarblePoint(.5, .88),
            const MarblePoint(.5, .105),
          ].every((MarblePoint anchor) => _distance(point, anchor) > .12);
          final bool awayFromGates = gates.every((MarbleGate gate) {
            if ((point.y - gate.y).abs() > .065) return true;
            return (point.x - gate.center).abs() >
                gate.width / 2 + radius + .03;
          });
          final bool awayFromBumpers = bumpers.every(
            (MarbleBumper bumper) =>
                _distance(point, bumper.center) > bumper.radius + radius + .06,
          );
          if (awayFromAnchors && awayFromGates && awayFromBumpers) {
            bumpers.add(MarbleBumper(center: point, radius: radius));
            break;
          }
        }
      }

      final List<MarblePit> pits = <MarblePit>[];
      final int pitCount = level < 7
          ? 0
          : level < 10
          ? 1
          : 2;
      for (int index = 0; index < pitCount; index++) {
        final double y = .25 + random.nextDouble() * .5;
        final double side = index.isEven ? .13 : .87;
        pits.add(
          MarblePit(
            center: MarblePoint(side, y),
            radius: .035 + random.nextDouble() * .01,
          ),
        );
      }

      final MarbleRouteScenario candidate = MarbleRouteScenario._(
        level: level,
        seed: seed,
        start: const MarblePoint(.5, .88),
        goal: const MarblePoint(.5, .105),
        gates: List<MarbleGate>.unmodifiable(gates),
        surfaces: List<MarbleSurface>.unmodifiable(surfaces),
        bumpers: List<MarbleBumper>.unmodifiable(bumpers),
        pits: List<MarblePit>.unmodifiable(pits),
        missLimit: level <= 3
            ? 4
            : level <= 6
            ? 3
            : level <= 8
            ? 2
            : 1,
        goldTimeSeconds: math.max(24, 70 - level * 4.2),
        tiltResponse: 1.12 + level * .035,
      );
      if (!used.contains(candidate.signature) && _isFair(candidate)) {
        return candidate;
      }
    }
    throw StateError('Could not generate a unique Mermer Rota course.');
  }

  static double _distance(MarblePoint left, MarblePoint right) {
    final double dx = left.x - right.x;
    final double dy = left.y - right.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  static bool _isFair(MarbleRouteScenario course) =>
      course.gates.isNotEmpty &&
      course.gates.every(
        (MarbleGate gate) =>
            gate.width >= .18 &&
            gate.center - gate.amplitude - gate.width / 2 > .17 &&
            gate.center + gate.amplitude + gate.width / 2 < .83,
      ) &&
      course.surfaces.every(
        (MarbleSurface surface) =>
            surface.center.x - surface.width / 2 > .12 &&
            surface.center.x + surface.width / 2 < .88 &&
            surface.center.y - surface.height / 2 > .12 &&
            surface.center.y + surface.height / 2 < .88,
      );
}
