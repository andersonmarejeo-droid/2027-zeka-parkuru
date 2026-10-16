import 'dart:math' as math;

enum DiceOpponentStyle { measured, reader, daring }

extension DiceOpponentStyleLabel on DiceOpponentStyle {
  String label(bool english) => switch (this) {
    DiceOpponentStyle.measured => english ? 'MEASURED' : 'TEMKİNLİ',
    DiceOpponentStyle.reader => english ? 'TABLE READER' : 'MASA OKURU',
    DiceOpponentStyle.daring => english ? 'DARING' : 'CESUR',
  };
}

class DiceBluffScenario {
  DiceBluffScenario._({
    required this.level,
    required this.seed,
    required this.arenaId,
    required this.arenaTr,
    required this.arenaEn,
    required this.diceCount,
    required this.faceCount,
    required this.wildFace,
    required this.opponentStyle,
    required this.humanDice,
    required this.opponentDice,
  });

  static const int campaignLevels = 20;
  static const int practiceHands = 300;
  static const List<(String, String, String)> _arenas =
      <(String, String, String)>[
        ('copper_wharf', 'Bakır Rıhtım', 'Copper Wharf'),
        ('lantern_den', 'Fener Hanı', 'Lantern Den'),
        ('saffron_table', 'Safran Masası', 'Saffron Table'),
        ('moon_quay', 'Ay İskelesi', 'Moon Quay'),
        ('velvet_cabin', 'Kadife Kamara', 'Velvet Cabin'),
        ('salt_court', 'Tuz Avlusu', 'Salt Court'),
        ('blue_cavern', 'Mavi Mağara', 'Blue Cavern'),
        ('ivory_deck', 'Fildişi Güverte', 'Ivory Deck'),
        ('storm_cellar', 'Fırtına Mahzeni', 'Storm Cellar'),
        ('brass_garden', 'Pirinç Bahçe', 'Brass Garden'),
        ('amber_dock', 'Kehribar Rıhtım', 'Amber Dock'),
        ('night_market', 'Gece Pazarı', 'Night Market'),
        ('jade_boathouse', 'Yeşim Kayıkhane', 'Jade Boathouse'),
        ('rose_foundry', 'Gül Dökümhanesi', 'Rose Foundry'),
        ('north_lookout', 'Kuzey Gözetleme', 'North Lookout'),
        ('black_sail', 'Kara Yelken', 'Black Sail'),
        ('glass_bastion', 'Cam Burç', 'Glass Bastion'),
        ('quiet_tavern', 'Sessiz Meyhane', 'Quiet Tavern'),
        ('golden_lock', 'Altın Kilit', 'Golden Lock'),
        ('last_harbor', 'Son Liman', 'Last Harbor'),
      ];

  final int level;
  final int seed;
  final String arenaId;
  final String arenaTr;
  final String arenaEn;
  final int diceCount;
  final int faceCount;
  final int? wildFace;
  final DiceOpponentStyle opponentStyle;
  final List<int> humanDice;
  final List<int> opponentDice;

  int get totalDice => diceCount * 2;

  String signature() => <String>[
    arenaId,
    diceCount.toString(),
    faceCount.toString(),
    wildFace?.toString() ?? 'none',
    opponentStyle.name,
    humanDice.join(','),
    opponentDice.join(','),
  ].join('|');

  /// Builds a deterministic hand variant while keeping the same arena rules.
  /// Useful for authored puzzles, replays and verifying that AI decisions only
  /// use the opponent's public bids plus its own private dice.
  DiceBluffScenario withDiceHands({
    required List<int> humanDice,
    required List<int> opponentDice,
  }) {
    if (humanDice.length != diceCount || opponentDice.length != diceCount) {
      throw ArgumentError('Each hand must contain exactly $diceCount dice.');
    }
    if (<int>[
      ...humanDice,
      ...opponentDice,
    ].any((int face) => face < 1 || face > faceCount)) {
      throw RangeError('Dice faces must stay between 1 and $faceCount.');
    }
    return DiceBluffScenario._(
      level: level,
      seed: seed,
      arenaId: arenaId,
      arenaTr: arenaTr,
      arenaEn: arenaEn,
      diceCount: diceCount,
      faceCount: faceCount,
      wildFace: wildFace,
      opponentStyle: opponentStyle,
      humanDice: List<int>.unmodifiable(humanDice),
      opponentDice: List<int>.unmodifiable(opponentDice),
    );
  }

  static DiceBluffScenario forLevel(int level) {
    if (level < 1 || level > campaignLevels) {
      throw RangeError.range(level, 1, campaignLevels, 'level');
    }
    final int dice = 3 + ((level - 1) * 4 ~/ (campaignLevels - 1));
    final int faces = level <= 5 ? 4 : (level <= 10 ? 5 : 6);
    return _create(
      level: level,
      arenaIndex: level - 1,
      diceCount: dice,
      faceCount: faces,
      wildFace: level >= 9 ? faces : null,
      opponentStyle: DiceOpponentStyle.values[(level - 1) % 3],
      seed: 8101 + level * 197,
    );
  }

  static DiceBluffScenario forPractice(int index) {
    if (index < 1 || index > practiceHands) {
      throw RangeError.range(index, 1, practiceHands, 'index');
    }
    final int variant = index - 1;
    final int dice = 3 + (variant % 5);
    final int faces = 4 + (variant % 3);
    return _create(
      level: campaignLevels,
      arenaIndex: variant % _arenas.length,
      diceCount: dice,
      faceCount: faces,
      wildFace: variant % 3 == 2 ? faces : null,
      opponentStyle: DiceOpponentStyle.values[variant % 3],
      seed: 19001 + index * 7919,
    );
  }

  static DiceBluffScenario _create({
    required int level,
    required int arenaIndex,
    required int diceCount,
    required int faceCount,
    required int? wildFace,
    required DiceOpponentStyle opponentStyle,
    required int seed,
  }) {
    final math.Random random = math.Random(seed);
    final (String id, String titleTr, String titleEn) = _arenas[arenaIndex];
    return DiceBluffScenario._(
      level: level,
      seed: seed,
      arenaId: id,
      arenaTr: titleTr,
      arenaEn: titleEn,
      diceCount: diceCount,
      faceCount: faceCount,
      wildFace: wildFace,
      opponentStyle: opponentStyle,
      humanDice: List<int>.generate(
        diceCount,
        (_) => random.nextInt(faceCount) + 1,
        growable: false,
      ),
      opponentDice: List<int>.generate(
        diceCount,
        (_) => random.nextInt(faceCount) + 1,
        growable: false,
      ),
    );
  }
}
