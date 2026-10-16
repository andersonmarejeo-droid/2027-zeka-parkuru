import 'dart:math' as math;

import '../shared/content_seed.dart';

typedef MuseumCell = ({int x, int y});

class MuseumGuardSpec {
  const MuseumGuardSpec({
    required this.patrol,
    required this.cadence,
    required this.visionRange,
    required this.startOffset,
  });

  final List<MuseumCell> patrol;
  final int cadence;
  final int visionRange;
  final int startOffset;

  String get signature =>
      '${patrol.map(_cell).join(';')}:$cadence:$visionRange:$startOffset';
  static String _cell(MuseumCell cell) => '${cell.x},${cell.y}';
}

class MuseumLaserSpec {
  const MuseumLaserSpec({
    required this.cell,
    required this.period,
    required this.activeTicks,
    required this.phase,
  });

  final MuseumCell cell;
  final int period;
  final int activeTicks;
  final int phase;

  bool isActiveAt(int turn) => (turn + phase) % period < activeTicks;
  String get signature => '${cell.x},${cell.y}:$period:$activeTicks:$phase';
}

class MuseumScenario {
  const MuseumScenario._({
    required this.level,
    required this.seed,
    required this.walls,
    required this.shadows,
    required this.artifacts,
    required this.guards,
    required this.lasers,
    required this.lureTarget,
  });

  static const int campaignLevels = 20;
  static const int practiceMaps = 300;
  static const int columns = 10;
  static const int rows = 9;
  static const MuseumCell start = (x: 1, y: 7);
  static const MuseumCell exit = (x: 8, y: 7);

  final int level;
  final int seed;
  final List<MuseumCell> walls;
  final List<MuseumCell> shadows;
  final List<MuseumCell> artifacts;
  final List<MuseumGuardSpec> guards;
  final List<MuseumLaserSpec> lasers;
  final MuseumCell lureTarget;

  String get signature => <String>[
    '$level:$seed:${lureTarget.x},${lureTarget.y}',
    'w:${walls.map(_cell).join(';')}',
    's:${shadows.map(_cell).join(';')}',
    'a:${artifacts.map(_cell).join(';')}',
    'g:${guards.map((MuseumGuardSpec guard) => guard.signature).join('|')}',
    'l:${lasers.map((MuseumLaserSpec laser) => laser.signature).join('|')}',
  ].join('::');

  MuseumLaserSpec? laserAt(MuseumCell cell) {
    for (final MuseumLaserSpec laser in lasers) {
      if (laser.cell == cell) return laser;
    }
    return null;
  }

  static MuseumScenario forLevel(int level) {
    if (level < 1 || level > campaignLevels) {
      throw RangeError.range(level, 1, campaignLevels, 'level');
    }
    return _build(
      level,
      ContentSeed.forLevel(gameId: 'museum_after_hours_campaign', level: level),
    );
  }

  static MuseumScenario forPracticeMap(int index) {
    if (index < 1 || index > practiceMaps) {
      throw RangeError.range(index, 1, practiceMaps, 'index');
    }
    return _build(
      1 + ((index - 1) % campaignLevels),
      ContentSeed.forLevel(gameId: 'museum_after_hours_practice', level: index),
    );
  }

  static MuseumScenario _build(int level, int seed) {
    final math.Random random = math.Random(seed);
    final int artifactCount = (1 + level ~/ 7).clamp(1, 3);
    final List<MuseumCell> candidates = <MuseumCell>[
      for (int x = 2; x <= 7; x++) (x: x, y: x.isEven ? 6 : 7),
    ]..shuffle(random);
    final List<MuseumCell> artifacts = candidates
        .take(artifactCount)
        .toList(growable: false);
    final int laserCount = level < 4 ? 0 : 1 + (level - 4) ~/ 6;
    final List<MuseumCell> laserCandidates = <MuseumCell>[
      for (int x = 2; x <= 7; x++)
        if (!artifacts.contains((x: x, y: 7)) &&
            !artifacts.contains((x: x, y: 6)))
          (x: x, y: 7),
    ]..shuffle(random);
    final List<MuseumLaserSpec> lasers = <MuseumLaserSpec>[
      for (int i = 0; i < laserCount; i++)
        MuseumLaserSpec(
          cell: laserCandidates[i],
          period: 4 + (level >= 12 ? i % 2 : 0),
          activeTicks: level >= 17 ? 3 : 2,
          phase: random.nextInt(5),
        ),
    ];
    final Set<MuseumCell> walls = <MuseumCell>{
      for (int x = 1; x <= 8; x++) (x: x, y: 5),
      for (int x = 1; x <= 8; x++) (x: x, y: 1),
    };
    walls.remove((x: 3, y: 5));
    walls.remove((x: 7, y: 5));
    final List<MuseumCell> obstacleCandidates = <MuseumCell>[
      for (int y = 2; y <= 4; y++)
        for (int x = 1; x <= 8; x++)
          if (!artifacts.contains((x: x, y: y)) &&
              !MuseumScenario._basePatrolCells.contains((x: x, y: y)))
            (x: x, y: y),
    ]..shuffle(random);
    walls.addAll(obstacleCandidates.take((level ~/ 2).clamp(0, 9)));
    final List<MuseumCell> safeCells = <MuseumCell>[
      for (int x = 1; x <= 8; x++) (x: x, y: 7),
      ...artifacts,
      (x: 3, y: 6),
      (x: 7, y: 6),
    ];
    final int guardCount = level < 8
        ? 1
        : level < 15
        ? 2
        : 3;
    final List<MuseumGuardSpec> guards = <MuseumGuardSpec>[
      for (int i = 0; i < guardCount; i++)
        MuseumGuardSpec(
          patrol: List<MuseumCell>.unmodifiable(_patrolFor(i)),
          cadence: level >= 16
              ? 1
              : level >= 7
              ? 2
              : 3,
          visionRange: 3 + (level >= 13 ? 1 : 0),
          startOffset: random.nextInt(_patrolFor(i).length),
        ),
    ];
    final List<MuseumCell> lureCandidates = <MuseumCell>[
      for (int x = 2; x <= 7; x++)
        if (!walls.contains((x: x, y: 3))) (x: x, y: 3),
    ];
    return MuseumScenario._(
      level: level,
      seed: seed,
      walls: List<MuseumCell>.unmodifiable(walls),
      shadows: List<MuseumCell>.unmodifiable(safeCells.toSet()),
      artifacts: List<MuseumCell>.unmodifiable(artifacts),
      guards: List<MuseumGuardSpec>.unmodifiable(guards),
      lasers: List<MuseumLaserSpec>.unmodifiable(lasers),
      lureTarget: lureCandidates[random.nextInt(lureCandidates.length)],
    );
  }

  static const Set<MuseumCell> _basePatrolCells = <MuseumCell>{
    (x: 1, y: 2),
    (x: 2, y: 2),
    (x: 3, y: 2),
    (x: 4, y: 2),
    (x: 5, y: 2),
    (x: 6, y: 2),
    (x: 7, y: 2),
    (x: 8, y: 2),
    (x: 1, y: 4),
    (x: 2, y: 4),
    (x: 3, y: 4),
    (x: 4, y: 4),
    (x: 5, y: 4),
    (x: 6, y: 4),
    (x: 7, y: 4),
    (x: 8, y: 4),
    (x: 4, y: 3),
  };

  static List<MuseumCell> _patrolFor(int index) => switch (index % 3) {
    0 => <MuseumCell>[
      for (int x = 1; x <= 8; x++) (x: x, y: 2),
      for (int x = 7; x >= 2; x--) (x: x, y: 2),
    ],
    1 => <MuseumCell>[
      for (int x = 8; x >= 1; x--) (x: x, y: 4),
      for (int x = 2; x <= 7; x++) (x: x, y: 4),
    ],
    _ => <MuseumCell>[
      for (int y = 1; y <= 4; y++) (x: 4, y: y),
      for (int y = 3; y >= 2; y--) (x: 4, y: y),
    ],
  };

  static String _cell(MuseumCell cell) => '${cell.x},${cell.y}';
}
