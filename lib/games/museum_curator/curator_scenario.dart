import 'dart:math' as math;

enum MuseumTheme { deepSea, ancient, exploration, naturalWorld, cosmos }

extension MuseumThemeInfo on MuseumTheme {
  String label(bool english) => switch (this) {
    MuseumTheme.deepSea => english ? 'DEEP SEA' : 'DERİN DENİZ',
    MuseumTheme.ancient => english ? 'ANCIENT WORLDS' : 'ESKİ UYGARLIKLAR',
    MuseumTheme.exploration => english ? 'EXPLORATION' : 'KEŞİF',
    MuseumTheme.naturalWorld => english ? 'NATURAL WORLD' : 'DOĞA TARİHİ',
    MuseumTheme.cosmos => english ? 'COSMOS' : 'KOZMOS',
  };
}

class CuratorArtifact {
  const CuratorArtifact({
    required this.id,
    required this.titleTr,
    required this.titleEn,
    required this.themes,
    required this.era,
    required this.fragile,
    required this.appeal,
    required this.cost,
    required this.mark,
  });
  final String id;
  final String titleTr;
  final String titleEn;
  final Set<MuseumTheme> themes;
  final int era;
  final int fragile;
  final int appeal;
  final int cost;
  final String mark;
  String label(bool english) => english ? titleEn : titleTr;

  static const List<CuratorArtifact> values = <CuratorArtifact>[
    CuratorArtifact(
      id: 'conch',
      titleTr: 'Sedefli Denizkabuğu',
      titleEn: 'Pearl Conch',
      themes: <MuseumTheme>{MuseumTheme.deepSea},
      era: 1,
      fragile: 1,
      appeal: 2,
      cost: 8,
      mark: 'C',
    ),
    CuratorArtifact(
      id: 'coral',
      titleTr: 'Mercan Örneği',
      titleEn: 'Coral Specimen',
      themes: <MuseumTheme>{MuseumTheme.deepSea, MuseumTheme.naturalWorld},
      era: 1,
      fragile: 1,
      appeal: 2,
      cost: 11,
      mark: '✦',
    ),
    CuratorArtifact(
      id: 'diver_helmet',
      titleTr: 'Dalgıç Başlığı',
      titleEn: 'Diver Helmet',
      themes: <MuseumTheme>{MuseumTheme.deepSea, MuseumTheme.exploration},
      era: 2,
      fragile: 0,
      appeal: 3,
      cost: 17,
      mark: 'D',
    ),
    CuratorArtifact(
      id: 'bathysphere',
      titleTr: 'Bathy Küresi',
      titleEn: 'Bathysphere',
      themes: <MuseumTheme>{MuseumTheme.deepSea},
      era: 3,
      fragile: 0,
      appeal: 3,
      cost: 22,
      mark: 'B',
    ),
    CuratorArtifact(
      id: 'sonar_chart',
      titleTr: 'Sonar Haritası',
      titleEn: 'Sonar Chart',
      themes: <MuseumTheme>{MuseumTheme.deepSea, MuseumTheme.exploration},
      era: 3,
      fragile: 0,
      appeal: 2,
      cost: 12,
      mark: '≈',
    ),
    CuratorArtifact(
      id: 'ocean_journal',
      titleTr: 'Akıntı Günlüğü',
      titleEn: 'Current Journal',
      themes: <MuseumTheme>{MuseumTheme.deepSea},
      era: 4,
      fragile: 1,
      appeal: 2,
      cost: 10,
      mark: 'J',
    ),
    CuratorArtifact(
      id: 'pressure_gauge',
      titleTr: 'Basınç Saati',
      titleEn: 'Pressure Gauge',
      themes: <MuseumTheme>{MuseumTheme.deepSea},
      era: 4,
      fragile: 0,
      appeal: 2,
      cost: 16,
      mark: 'P',
    ),
    CuratorArtifact(
      id: 'trench_photo',
      titleTr: 'Hendek Fotoğrafı',
      titleEn: 'Trench Photograph',
      themes: <MuseumTheme>{MuseumTheme.deepSea},
      era: 5,
      fragile: 1,
      appeal: 2,
      cost: 14,
      mark: 'F',
    ),
    CuratorArtifact(
      id: 'clay_tablet',
      titleTr: 'Kil Tablet',
      titleEn: 'Clay Tablet',
      themes: <MuseumTheme>{MuseumTheme.ancient},
      era: 1,
      fragile: 1,
      appeal: 2,
      cost: 9,
      mark: '▤',
    ),
    CuratorArtifact(
      id: 'bronze_mask',
      titleTr: 'Bronz Maske',
      titleEn: 'Bronze Mask',
      themes: <MuseumTheme>{MuseumTheme.ancient},
      era: 1,
      fragile: 1,
      appeal: 3,
      cost: 19,
      mark: 'M',
    ),
    CuratorArtifact(
      id: 'ancient_coin',
      titleTr: 'Eski Sikke',
      titleEn: 'Ancient Coin',
      themes: <MuseumTheme>{MuseumTheme.ancient},
      era: 2,
      fragile: 0,
      appeal: 2,
      cost: 8,
      mark: '◎',
    ),
    CuratorArtifact(
      id: 'astrolabe',
      titleTr: 'Usturlap',
      titleEn: 'Astrolabe',
      themes: <MuseumTheme>{
        MuseumTheme.ancient,
        MuseumTheme.exploration,
        MuseumTheme.cosmos,
      },
      era: 2,
      fragile: 0,
      appeal: 3,
      cost: 20,
      mark: '✧',
    ),
    CuratorArtifact(
      id: 'mosaic',
      titleTr: 'Mozaik Parçası',
      titleEn: 'Mosaic Fragment',
      themes: <MuseumTheme>{MuseumTheme.ancient},
      era: 3,
      fragile: 1,
      appeal: 2,
      cost: 13,
      mark: '▦',
    ),
    CuratorArtifact(
      id: 'amphora',
      titleTr: 'Amfora',
      titleEn: 'Amphora',
      themes: <MuseumTheme>{MuseumTheme.ancient},
      era: 3,
      fragile: 1,
      appeal: 2,
      cost: 16,
      mark: 'A',
    ),
    CuratorArtifact(
      id: 'ancient_compass',
      titleTr: 'Bronz Pusula',
      titleEn: 'Bronze Compass',
      themes: <MuseumTheme>{MuseumTheme.ancient},
      era: 4,
      fragile: 0,
      appeal: 2,
      cost: 13,
      mark: 'N',
    ),
    CuratorArtifact(
      id: 'sundial',
      titleTr: 'Güneş Saati',
      titleEn: 'Sundial',
      themes: <MuseumTheme>{MuseumTheme.ancient, MuseumTheme.cosmos},
      era: 5,
      fragile: 0,
      appeal: 2,
      cost: 18,
      mark: '◷',
    ),
    CuratorArtifact(
      id: 'compass',
      titleTr: 'Keşif Pusulası',
      titleEn: 'Field Compass',
      themes: <MuseumTheme>{MuseumTheme.exploration},
      era: 1,
      fragile: 0,
      appeal: 2,
      cost: 10,
      mark: 'N',
    ),
    CuratorArtifact(
      id: 'explorer_map',
      titleTr: 'Kaşif Haritası',
      titleEn: 'Explorer Map',
      themes: <MuseumTheme>{MuseumTheme.exploration},
      era: 2,
      fragile: 1,
      appeal: 2,
      cost: 9,
      mark: '⌖',
    ),
    CuratorArtifact(
      id: 'field_journal',
      titleTr: 'Saha Defteri',
      titleEn: 'Field Journal',
      themes: <MuseumTheme>{MuseumTheme.exploration, MuseumTheme.naturalWorld},
      era: 3,
      fragile: 1,
      appeal: 2,
      cost: 12,
      mark: 'J',
    ),
    CuratorArtifact(
      id: 'ship_bell',
      titleTr: 'Araştırma Gemisi Çanı',
      titleEn: 'Research Ship Bell',
      themes: <MuseumTheme>{MuseumTheme.exploration},
      era: 4,
      fragile: 0,
      appeal: 3,
      cost: 20,
      mark: '◉',
    ),
    CuratorArtifact(
      id: 'old_camera',
      titleTr: 'Cam Plakalı Kamera',
      titleEn: 'Plate Camera',
      themes: <MuseumTheme>{MuseumTheme.exploration},
      era: 4,
      fragile: 1,
      appeal: 3,
      cost: 18,
      mark: '□',
    ),
    CuratorArtifact(
      id: 'polar_chart',
      titleTr: 'Kutup Rotası',
      titleEn: 'Polar Route Chart',
      themes: <MuseumTheme>{MuseumTheme.exploration},
      era: 5,
      fragile: 1,
      appeal: 2,
      cost: 13,
      mark: '⌁',
    ),
    CuratorArtifact(
      id: 'fossil',
      titleTr: 'Ammonit Fosili',
      titleEn: 'Ammonite Fossil',
      themes: <MuseumTheme>{MuseumTheme.naturalWorld},
      era: 1,
      fragile: 0,
      appeal: 3,
      cost: 17,
      mark: '◉',
    ),
    CuratorArtifact(
      id: 'seed_press',
      titleTr: 'Tohum Baskısı',
      titleEn: 'Seed Press',
      themes: <MuseumTheme>{MuseumTheme.naturalWorld},
      era: 2,
      fragile: 1,
      appeal: 2,
      cost: 10,
      mark: '✿',
    ),
    CuratorArtifact(
      id: 'botanical_plate',
      titleTr: 'Bitki Levhası',
      titleEn: 'Botanical Plate',
      themes: <MuseumTheme>{MuseumTheme.naturalWorld},
      era: 2,
      fragile: 1,
      appeal: 2,
      cost: 12,
      mark: '❋',
    ),
    CuratorArtifact(
      id: 'bird_model',
      titleTr: 'Göçmen Kuş Modeli',
      titleEn: 'Migratory Bird Model',
      themes: <MuseumTheme>{MuseumTheme.naturalWorld, MuseumTheme.cosmos},
      era: 3,
      fragile: 0,
      appeal: 3,
      cost: 18,
      mark: '⌁',
    ),
    CuratorArtifact(
      id: 'field_microscope',
      titleTr: 'Saha Mikroskobu',
      titleEn: 'Field Microscope',
      themes: <MuseumTheme>{MuseumTheme.naturalWorld},
      era: 4,
      fragile: 0,
      appeal: 2,
      cost: 21,
      mark: '⊙',
    ),
    CuratorArtifact(
      id: 'fossil_egg',
      titleTr: 'Fosil Yumurta',
      titleEn: 'Fossil Egg',
      themes: <MuseumTheme>{MuseumTheme.naturalWorld},
      era: 4,
      fragile: 1,
      appeal: 3,
      cost: 14,
      mark: '◯',
    ),
    CuratorArtifact(
      id: 'meteorite',
      titleTr: 'Göktaşı Kesiti',
      titleEn: 'Meteorite Slice',
      themes: <MuseumTheme>{MuseumTheme.naturalWorld, MuseumTheme.cosmos},
      era: 5,
      fragile: 0,
      appeal: 3,
      cost: 23,
      mark: '✦',
    ),
    CuratorArtifact(
      id: 'star_chart',
      titleTr: 'Yıldız Atlası',
      titleEn: 'Star Atlas',
      themes: <MuseumTheme>{MuseumTheme.cosmos},
      era: 1,
      fragile: 1,
      appeal: 3,
      cost: 15,
      mark: '✧',
    ),
    CuratorArtifact(
      id: 'moon_sample',
      titleTr: 'Ay Taşı Örneği',
      titleEn: 'Moon Rock Sample',
      themes: <MuseumTheme>{MuseumTheme.cosmos},
      era: 3,
      fragile: 0,
      appeal: 3,
      cost: 21,
      mark: '◐',
    ),
    CuratorArtifact(
      id: 'telescope',
      titleTr: 'Cep Teleskobu',
      titleEn: 'Pocket Telescope',
      themes: <MuseumTheme>{MuseumTheme.cosmos},
      era: 3,
      fragile: 0,
      appeal: 2,
      cost: 19,
      mark: '⌕',
    ),
    CuratorArtifact(
      id: 'prism',
      titleTr: 'Optik Prizma',
      titleEn: 'Optical Prism',
      themes: <MuseumTheme>{MuseumTheme.cosmos},
      era: 4,
      fragile: 1,
      appeal: 3,
      cost: 16,
      mark: '◇',
    ),
    CuratorArtifact(
      id: 'signal_beacon',
      titleTr: 'Sinyal Feneri',
      titleEn: 'Signal Beacon',
      themes: <MuseumTheme>{MuseumTheme.cosmos},
      era: 5,
      fragile: 0,
      appeal: 2,
      cost: 20,
      mark: '⌖',
    ),
    CuratorArtifact(
      id: 'orbit_camera',
      titleTr: 'Yörünge Kamerası',
      titleEn: 'Orbital Camera',
      themes: <MuseumTheme>{MuseumTheme.cosmos},
      era: 5,
      fragile: 1,
      appeal: 3,
      cost: 22,
      mark: '□',
    ),
  ];
}

class CuratorScenario {
  const CuratorScenario({
    required this.level,
    required this.seed,
    required this.theme,
    required this.slotCount,
    required this.fragileLimit,
    required this.visitorTarget,
    required this.budget,
    required this.collection,
  });
  final int level;
  final int seed;
  final MuseumTheme theme;
  final int slotCount;
  final int fragileLimit;
  final int visitorTarget;
  final int budget;
  final List<CuratorArtifact> collection;

  String get signature => '$seed|$layoutSignature';
  String get layoutSignature => <String>[
    theme.name,
    slotCount.toString(),
    fragileLimit.toString(),
    visitorTarget.toString(),
    budget.toString(),
    collection.map((CuratorArtifact a) => a.id).join(','),
  ].join('|');

  static const int campaignLevels = 20;
  static const int practiceExhibitions = 300;

  static CuratorScenario forLevel(int level) {
    final int safe = level.clamp(1, campaignLevels).toInt();
    return _create(
      level: safe,
      seed: 150000 + safe * 887,
      theme: MuseumTheme.values[((safe - 1) ~/ 4) % MuseumTheme.values.length],
      slotCount: 3 + (safe - 1) ~/ 4,
      rng: math.Random(0x1515 + safe * 419),
      difficulty: safe,
    );
  }

  static CuratorScenario forPractice(int index) {
    final int safe = index.clamp(1, practiceExhibitions).toInt();
    final math.Random random = math.Random(0xC0A7 + safe * 7919);
    return _create(
      level: campaignLevels,
      seed: 1500000 + safe * 3571,
      theme: MuseumTheme.values[random.nextInt(MuseumTheme.values.length)],
      slotCount: 3 + random.nextInt(5),
      rng: random,
      difficulty: safe,
    );
  }

  static CuratorScenario _create({
    required int level,
    required int seed,
    required MuseumTheme theme,
    required int slotCount,
    required math.Random rng,
    required int difficulty,
  }) {
    final List<CuratorArtifact> themed =
        CuratorArtifact.values
            .where(
              (CuratorArtifact artifact) => artifact.themes.contains(theme),
            )
            .toList()
          ..sort((CuratorArtifact a, CuratorArtifact b) {
            final int eraOrder = a.era.compareTo(b.era);
            return eraOrder == 0 ? a.id.compareTo(b.id) : eraOrder;
          });
    final List<CuratorArtifact> solution = themed.take(slotCount).toList();
    final int fragileCount = solution.fold<int>(
      0,
      (int sum, CuratorArtifact a) => sum + a.fragile,
    );
    final int appeal = solution.fold<int>(
      0,
      (int sum, CuratorArtifact a) => sum + a.appeal,
    );
    final int cost = solution.fold<int>(
      0,
      (int sum, CuratorArtifact a) => sum + a.cost,
    );
    final List<CuratorArtifact> decoys =
        CuratorArtifact.values
            .where(
              (CuratorArtifact artifact) => !artifact.themes.contains(theme),
            )
            .toList()
          ..shuffle(rng);
    final List<CuratorArtifact> collection = <CuratorArtifact>[
      ...themed,
      ...decoys.take(4 + difficulty % 4),
    ]..sort((CuratorArtifact a, CuratorArtifact b) => a.id.compareTo(b.id));
    return CuratorScenario(
      level: level,
      seed: seed,
      theme: theme,
      slotCount: slotCount,
      fragileLimit: fragileCount + (difficulty < 8 ? 1 : 0),
      visitorTarget: appeal - (difficulty % 3 == 0 ? 1 : 0),
      budget: cost + 10 + rng.nextInt(21),
      collection: List<CuratorArtifact>.unmodifiable(collection),
    );
  }
}
