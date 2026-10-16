import 'dart:math' as math;

import '../shared/content_seed.dart';

typedef RelicCell = ({int x, int y});

enum RelicRunFoeKind { stalker, sentinel, ranger, guardian }

enum RelicRunRelic { ember, aegis, echo, prism }

class RelicRunFoeSpec {
  const RelicRunFoeSpec({
    required this.kind,
    required this.cell,
    required this.health,
    required this.damage,
  });

  final RelicRunFoeKind kind;
  final RelicCell cell;
  final int health;
  final int damage;

  String get signature => '${kind.name}:${cell.x},${cell.y}:$health:$damage';
}

class RelicRunRoom {
  const RelicRunRoom({
    required this.seed,
    required this.index,
    required this.walls,
    required this.traps,
    required this.foes,
    required this.isGuardianRoom,
  });

  final int seed;
  final int index;
  final List<RelicCell> walls;
  final List<RelicCell> traps;
  final List<RelicRunFoeSpec> foes;
  final bool isGuardianRoom;

  String get signature => <String>[
    '$seed:$index:${isGuardianRoom ? 1 : 0}',
    'w:${walls.map(_cell).join(';')}',
    't:${traps.map(_cell).join(';')}',
    'f:${foes.map((RelicRunFoeSpec foe) => foe.signature).join(';')}',
  ].join('|');

  static String _cell(RelicCell cell) => '${cell.x},${cell.y}';
}

/// Three-room tactical runs with readable enemy intent and deterministic loot.
class RelicRunScenario {
  const RelicRunScenario._({
    required this.level,
    required this.seed,
    required this.rooms,
    required this.relicOffers,
  });

  static const int campaignLevels = 20;
  static const int practiceRuns = 300;
  static const int roomCount = 3;
  static const int columns = 9;
  static const int rows = 9;

  final int level;
  final int seed;
  final List<RelicRunRoom> rooms;
  final List<List<RelicRunRelic>> relicOffers;

  String get signature => <String>[
    '$level:$seed',
    rooms.map((RelicRunRoom room) => room.signature).join('||'),
    relicOffers
        .map(
          (List<RelicRunRelic> offer) =>
              offer.map((RelicRunRelic r) => r.name).join(','),
        )
        .join(';'),
  ].join('|');

  static RelicRunScenario forLevel(int level) {
    if (level < 1 || level > campaignLevels) {
      throw RangeError.range(level, 1, campaignLevels, 'level');
    }
    return _build(
      level,
      ContentSeed.forLevel(gameId: 'relic_run_campaign', level: level),
    );
  }

  static RelicRunScenario forPracticeRun(int index) {
    if (index < 1 || index > practiceRuns) {
      throw RangeError.range(index, 1, practiceRuns, 'index');
    }
    return _build(
      1 + ((index - 1) % campaignLevels),
      ContentSeed.forLevel(gameId: 'relic_run_practice', level: index),
    );
  }

  static RelicRunScenario _build(int level, int seed) {
    final math.Random random = math.Random(seed);
    final List<RelicRunRoom> rooms = <RelicRunRoom>[
      for (int room = 0; room < roomCount; room++)
        _buildRoom(
          level: level,
          roomIndex: room,
          seed: seed ^ (0x51A7 + room * 0x9E37),
          random: math.Random(seed ^ (0x51A7 + room * 0x9E37)),
        ),
    ];
    final List<RelicRunRelic> relics = RelicRunRelic.values.toList()
      ..shuffle(random);
    final List<List<RelicRunRelic>> offers = <List<RelicRunRelic>>[
      for (int room = 0; room < roomCount - 1; room++)
        List<RelicRunRelic>.unmodifiable(<RelicRunRelic>[
          relics[(room * 2) % relics.length],
          relics[(room * 2 + 1) % relics.length],
        ]),
    ];
    return RelicRunScenario._(
      level: level,
      seed: seed,
      rooms: List<RelicRunRoom>.unmodifiable(rooms),
      relicOffers: List<List<RelicRunRelic>>.unmodifiable(offers),
    );
  }

  static RelicRunRoom _buildRoom({
    required int level,
    required int roomIndex,
    required int seed,
    required math.Random random,
  }) {
    final int wallCount = (2 + level ~/ 3 + roomIndex).clamp(2, 10);
    final List<RelicCell> wallCandidates = <RelicCell>[
      for (int y = 1; y < rows - 1; y++)
        for (int x = 2; x < columns - 1; x++)
          if (y != 4 && !(x <= 3 && y == 3)) (x: x, y: y),
    ]..shuffle(random);
    final Set<RelicCell> walls = wallCandidates.take(wallCount).toSet();

    final List<RelicCell> foeCandidates = <RelicCell>[
      for (int y = 1; y < rows - 1; y++)
        for (int x = 3; x < columns - 1; x++)
          if (y != 4 && !walls.contains((x: x, y: y))) (x: x, y: y),
    ]..shuffle(random);
    final RelicCell openingThreat = (x: 3, y: 3);
    foeCandidates.remove(openingThreat);
    foeCandidates.insert(0, openingThreat);
    final int ordinaryCount = (2 + level ~/ 5 + roomIndex).clamp(2, 5);
    final bool guardianRoom = level >= 7 && roomIndex == roomCount - 1;
    final int count = ordinaryCount + (guardianRoom ? 1 : 0);
    final List<RelicRunFoeSpec> foes = <RelicRunFoeSpec>[
      for (int i = 0; i < count; i++)
        RelicRunFoeSpec(
          kind: guardianRoom && i == count - 1
              ? RelicRunFoeKind.guardian
              : _kindFor(level, roomIndex, i),
          cell: foeCandidates[i],
          health: guardianRoom && i == count - 1
              ? 4 + level ~/ 8
              : 1 + (level >= 8 ? 1 : 0) + (level >= 16 ? 1 : 0),
          damage: 5 + level ~/ 4 + (guardianRoom && i == count - 1 ? 4 : 0),
        ),
    ];
    final List<RelicCell> trapCandidates = <RelicCell>[
      for (int y = 1; y < rows - 1; y++)
        for (int x = 2; x < columns - 1; x++)
          if (y != 4 &&
              !walls.contains((x: x, y: y)) &&
              !foes.any((RelicRunFoeSpec foe) => foe.cell == (x: x, y: y)))
            (x: x, y: y),
    ]..shuffle(random);
    final int trapCount = level < 4 ? 1 : 1 + level ~/ 7 + roomIndex ~/ 2;
    return RelicRunRoom(
      seed: seed,
      index: roomIndex,
      walls: List<RelicCell>.unmodifiable(walls),
      traps: List<RelicCell>.unmodifiable(trapCandidates.take(trapCount)),
      foes: List<RelicRunFoeSpec>.unmodifiable(foes),
      isGuardianRoom: guardianRoom,
    );
  }

  static RelicRunFoeKind _kindFor(int level, int roomIndex, int index) {
    if (level < 3) {
      return index.isEven ? RelicRunFoeKind.stalker : RelicRunFoeKind.sentinel;
    }
    return switch ((index + roomIndex + level) % 3) {
      0 => RelicRunFoeKind.stalker,
      1 => RelicRunFoeKind.ranger,
      _ => RelicRunFoeKind.sentinel,
    };
  }
}
