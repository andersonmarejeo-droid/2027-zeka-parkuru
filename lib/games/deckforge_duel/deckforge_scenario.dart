import 'dart:math' as math;

enum DeckforgeArchetype { vanguard, sentinel, trickster }

extension DeckforgeArchetypeLabel on DeckforgeArchetype {
  String label(bool english) => switch (this) {
    DeckforgeArchetype.vanguard => english ? 'VANGUARD' : 'ÖNCÜ',
    DeckforgeArchetype.sentinel => english ? 'SENTINEL' : 'MUHAFIZ',
    DeckforgeArchetype.trickster => english ? 'TRICKSTER' : 'DÜZENBAZ',
  };
}

enum DeckforgeIntent { assault, guard, focus }

extension DeckforgeIntentLabel on DeckforgeIntent {
  String label(bool english) => switch (this) {
    DeckforgeIntent.assault => english ? 'HEAVY ASSAULT' : 'AĞIR SALDIRI',
    DeckforgeIntent.guard => english ? 'FORTIFY' : 'SAVUNMA',
    DeckforgeIntent.focus => english ? 'CHARGE / DISRUPT' : 'ODAK / BOZMA',
  };
}

enum DeckforgeCard {
  quickCut,
  brace,
  focus,
  breaker,
  feint,
  mend,
  riposte,
  siphon,
  overdrive,
  disrupt,
}

class DeckforgeCardRule {
  const DeckforgeCardRule({
    required this.titleTr,
    required this.titleEn,
    required this.cost,
    this.damage = 0,
    this.piercing = 0,
    this.shield = 0,
    this.heal = 0,
    this.focus = 0,
    this.counter = 0,
    this.jam = 0,
    this.energyTax = 0,
  });

  final String titleTr;
  final String titleEn;
  final int cost;
  final int damage;
  final int piercing;
  final int shield;
  final int heal;
  final int focus;
  final int counter;
  final int jam;
  final int energyTax;
}

extension DeckforgeCardRuleData on DeckforgeCard {
  DeckforgeCardRule get rule => switch (this) {
    DeckforgeCard.quickCut => const DeckforgeCardRule(
      titleTr: 'Hızlı Kesik',
      titleEn: 'Quick Cut',
      cost: 1,
      damage: 4,
    ),
    DeckforgeCard.brace => const DeckforgeCardRule(
      titleTr: 'Siper',
      titleEn: 'Brace',
      cost: 1,
      shield: 5,
    ),
    DeckforgeCard.focus => const DeckforgeCardRule(
      titleTr: 'Odak',
      titleEn: 'Focus',
      cost: 1,
      focus: 3,
    ),
    DeckforgeCard.breaker => const DeckforgeCardRule(
      titleTr: 'Kırıcı',
      titleEn: 'Breaker',
      cost: 2,
      damage: 8,
    ),
    DeckforgeCard.feint => const DeckforgeCardRule(
      titleTr: 'Yanıltma',
      titleEn: 'Feint',
      cost: 1,
      damage: 3,
      piercing: 2,
    ),
    DeckforgeCard.mend => const DeckforgeCardRule(
      titleTr: 'Onarım',
      titleEn: 'Mend',
      cost: 2,
      heal: 5,
    ),
    DeckforgeCard.riposte => const DeckforgeCardRule(
      titleTr: 'Karşı Duruş',
      titleEn: 'Riposte',
      cost: 2,
      shield: 2,
      counter: 4,
    ),
    DeckforgeCard.siphon => const DeckforgeCardRule(
      titleTr: 'Can Çek',
      titleEn: 'Siphon',
      cost: 2,
      damage: 4,
      heal: 2,
    ),
    DeckforgeCard.overdrive => const DeckforgeCardRule(
      titleTr: 'Tam Güç',
      titleEn: 'Overdrive',
      cost: 3,
      damage: 12,
      energyTax: 1,
    ),
    DeckforgeCard.disrupt => const DeckforgeCardRule(
      titleTr: 'Kesinti',
      titleEn: 'Disrupt',
      cost: 2,
      damage: 2,
      jam: 1,
    ),
  };

  String label(bool english) => english ? rule.titleEn : rule.titleTr;
}

class DeckforgeScenario {
  DeckforgeScenario._({
    required this.level,
    required this.seed,
    required this.arenaId,
    required this.arenaTr,
    required this.arenaEn,
    required this.opponentArchetype,
    required this.opponentEnergyCap,
    required this.playerHealth,
    required this.opponentHealth,
    required this.playerDeck,
    required this.opponentDeck,
    required this.intentPattern,
    required this.practiceVariant,
  });

  static const int campaignLevels = 20;
  static const int practiceBattles = 300;
  static const List<(String, String, String)> _arenas =
      <(String, String, String)>[
        ('onyx_ring', 'Oniks Arenası', 'Onyx Arena'),
        ('sunken_foundry', 'Batık Dökümhane', 'Sunken Foundry'),
        ('paper_citadel', 'Kâğıt Kale', 'Paper Citadel'),
        ('jade_observatory', 'Yeşim Gözlemevi', 'Jade Observatory'),
        ('lumen_bastion', 'Lumen Tabyası', 'Lumen Bastion'),
        ('storm_gallery', 'Fırtına Galerisi', 'Storm Gallery'),
        ('copper_stage', 'Bakır Sahne', 'Copper Stage'),
        ('frost_vault', 'Kırağı Kasası', 'Frost Vault'),
        ('ember_court', 'Kor Avlusu', 'Ember Court'),
        ('north_dais', 'Kuzey Kürsüsü', 'North Dais'),
        ('velvet_grid', 'Kadife Izgara', 'Velvet Grid'),
        ('silver_pit', 'Gümüş Çukur', 'Silver Pit'),
        ('coral_hall', 'Mercan Salonu', 'Coral Hall'),
        ('glass_lab', 'Cam Laboratuvar', 'Glass Lab'),
        ('quiet_foundry', 'Sessiz Dökümhane', 'Quiet Foundry'),
        ('moon_arcade', 'Ay Pasajı', 'Moon Arcade'),
        ('brass_terrace', 'Pirinç Teras', 'Brass Terrace'),
        ('violet_dock', 'Menekşe Rıhtımı', 'Violet Dock'),
        ('last_gallery', 'Son Galeri', 'Last Gallery'),
        ('crown_room', 'Taç Odası', 'Crown Room'),
      ];

  final int level;
  final int seed;
  final String arenaId;
  final String arenaTr;
  final String arenaEn;
  final DeckforgeArchetype opponentArchetype;
  final int opponentEnergyCap;
  final int playerHealth;
  final int opponentHealth;
  final List<DeckforgeCard> playerDeck;
  final List<DeckforgeCard> opponentDeck;
  final List<DeckforgeIntent> intentPattern;
  final int practiceVariant;

  String signature() => <String>[
    arenaId,
    opponentArchetype.name,
    opponentEnergyCap.toString(),
    playerHealth.toString(),
    opponentHealth.toString(),
    practiceVariant.toString(),
    playerDeck.map((DeckforgeCard card) => card.name).join(','),
    opponentDeck.map((DeckforgeCard card) => card.name).join(','),
    intentPattern.map((DeckforgeIntent intent) => intent.name).join(','),
  ].join('|');

  static DeckforgeScenario forLevel(int level) {
    if (level < 1 || level > campaignLevels) {
      throw RangeError.range(level, 1, campaignLevels, 'level');
    }
    return _create(
      level: level,
      arenaIndex: level - 1,
      variant: (level - 1) % 15,
      opponentArchetype: DeckforgeArchetype.values[(level - 1) % 3],
      opponentEnergyCap: level <= 2 ? 1 : (level <= 6 ? 2 : 3),
      opponentHealth: 34 + level,
      seed: 5401 + level * 977,
    );
  }

  static DeckforgeScenario forPractice(int index) {
    if (index < 1 || index > practiceBattles) {
      throw RangeError.range(index, 1, practiceBattles, 'index');
    }
    final int offset = index - 1;
    return _create(
      level: campaignLevels,
      arenaIndex: offset % _arenas.length,
      variant: offset ~/ _arenas.length,
      opponentArchetype: DeckforgeArchetype.values[offset % 3],
      opponentEnergyCap: 3,
      opponentHealth: 40 + (offset % 5) * 2,
      seed: 71001 + index * 104729,
    );
  }

  static DeckforgeScenario _create({
    required int level,
    required int arenaIndex,
    required int variant,
    required DeckforgeArchetype opponentArchetype,
    required int opponentEnergyCap,
    required int opponentHealth,
    required int seed,
  }) {
    final math.Random random = math.Random(seed);
    final (String id, String titleTr, String titleEn) = _arenas[arenaIndex];
    final List<DeckforgeCard> balanced = <DeckforgeCard>[
      DeckforgeCard.quickCut,
      DeckforgeCard.quickCut,
      DeckforgeCard.quickCut,
      DeckforgeCard.brace,
      DeckforgeCard.brace,
      DeckforgeCard.brace,
      DeckforgeCard.focus,
      DeckforgeCard.focus,
      DeckforgeCard.breaker,
      DeckforgeCard.breaker,
      DeckforgeCard.feint,
      DeckforgeCard.feint,
      DeckforgeCard.mend,
      DeckforgeCard.mend,
      DeckforgeCard.riposte,
      DeckforgeCard.siphon,
      DeckforgeCard.overdrive,
      DeckforgeCard.disrupt,
    ];
    final List<DeckforgeCard> opponent = List<DeckforgeCard>.from(balanced);
    switch (opponentArchetype) {
      case DeckforgeArchetype.vanguard:
        opponent[3] = DeckforgeCard.breaker;
        opponent[4] = DeckforgeCard.overdrive;
        opponent[12] = DeckforgeCard.quickCut;
        break;
      case DeckforgeArchetype.sentinel:
        opponent[0] = DeckforgeCard.brace;
        opponent[10] = DeckforgeCard.mend;
        opponent[16] = DeckforgeCard.riposte;
        break;
      case DeckforgeArchetype.trickster:
        opponent[3] = DeckforgeCard.feint;
        opponent[4] = DeckforgeCard.disrupt;
        opponent[15] = DeckforgeCard.siphon;
        break;
    }
    balanced.shuffle(random);
    opponent.shuffle(random);
    final List<DeckforgeIntent> intents = <DeckforgeIntent>[];
    final List<DeckforgeIntent> cycle = switch (opponentArchetype) {
      DeckforgeArchetype.vanguard => <DeckforgeIntent>[
        DeckforgeIntent.assault,
        DeckforgeIntent.assault,
        DeckforgeIntent.focus,
        DeckforgeIntent.assault,
        DeckforgeIntent.guard,
      ],
      DeckforgeArchetype.sentinel => <DeckforgeIntent>[
        DeckforgeIntent.guard,
        DeckforgeIntent.assault,
        DeckforgeIntent.guard,
        DeckforgeIntent.focus,
      ],
      DeckforgeArchetype.trickster => <DeckforgeIntent>[
        DeckforgeIntent.focus,
        DeckforgeIntent.assault,
        DeckforgeIntent.guard,
        DeckforgeIntent.focus,
      ],
    };
    for (int i = 0; i < 10; i++) {
      final DeckforgeIntent intent = cycle[(i + variant) % cycle.length];
      intents.add(
        random.nextInt(5) == 0
            ? DeckforgeIntent.values[random.nextInt(3)]
            : intent,
      );
    }
    return DeckforgeScenario._(
      level: level,
      seed: seed,
      arenaId: id,
      arenaTr: titleTr,
      arenaEn: titleEn,
      opponentArchetype: opponentArchetype,
      opponentEnergyCap: opponentEnergyCap,
      playerHealth: 38,
      opponentHealth: opponentHealth,
      playerDeck: List<DeckforgeCard>.unmodifiable(balanced),
      opponentDeck: List<DeckforgeCard>.unmodifiable(opponent),
      intentPattern: List<DeckforgeIntent>.unmodifiable(intents),
      practiceVariant: variant,
    );
  }
}
