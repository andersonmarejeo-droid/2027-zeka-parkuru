import 'dart:math' as math;

enum FestivalWeather { clear, drizzle, wind }

enum FestivalGenre {
  indie,
  electronic,
  folk,
  percussion,
  dance,
  comedy,
  choir,
  strings,
  jazz,
  circus,
  spokenWord,
  ambient,
  maker,
  world,
}

extension FestivalGenreLabel on FestivalGenre {
  String label(bool english) => switch (this) {
    FestivalGenre.indie => english ? 'INDIE' : 'BAĞIMSIZ',
    FestivalGenre.electronic => english ? 'ELECTRO' : 'ELEKTRONİK',
    FestivalGenre.folk => english ? 'FOLK' : 'HALK',
    FestivalGenre.percussion => english ? 'DRUMS' : 'VURMALI',
    FestivalGenre.dance => english ? 'DANCE' : 'DANS',
    FestivalGenre.comedy => english ? 'COMEDY' : 'KOMEDİ',
    FestivalGenre.choir => english ? 'CHOIR' : 'KORO',
    FestivalGenre.strings => english ? 'STRINGS' : 'YAYLI',
    FestivalGenre.jazz => english ? 'JAZZ' : 'CAZ',
    FestivalGenre.circus => english ? 'CIRCUS' : 'SİRK',
    FestivalGenre.spokenWord => english ? 'POETRY' : 'ŞİİR',
    FestivalGenre.ambient => english ? 'AMBIENT' : 'AMBIYANS',
    FestivalGenre.maker => english ? 'MAKER' : 'ATÖLYE',
    FestivalGenre.world => english ? 'WORLD' : 'DÜNYA',
  };
}

class FestivalPerformance {
  const FestivalPerformance({
    required this.id,
    required this.titleTr,
    required this.titleEn,
    required this.genre,
    required this.audience,
    required this.power,
    required this.crew,
    required this.cost,
    required this.rainReady,
    required this.earliestBlock,
    required this.latestBlock,
  });
  final String id;
  final String titleTr;
  final String titleEn;
  final FestivalGenre genre;
  final int audience;
  final int power;
  final int crew;
  final int cost;
  final bool rainReady;
  final int earliestBlock;
  final int latestBlock;
  String label(bool english) => english ? titleEn : titleTr;

  static const List<FestivalPerformance> templates = <FestivalPerformance>[
    FestivalPerformance(
      id: 'paper_sky',
      titleTr: 'Kâğıt Gökyüzü',
      titleEn: 'Paper Sky',
      genre: FestivalGenre.indie,
      audience: 4,
      power: 3,
      crew: 2,
      cost: 24,
      rainReady: true,
      earliestBlock: 0,
      latestBlock: 7,
    ),
    FestivalPerformance(
      id: 'pulse_lab',
      titleTr: 'Nabız Laboratuvarı',
      titleEn: 'Pulse Lab',
      genre: FestivalGenre.electronic,
      audience: 4,
      power: 4,
      crew: 2,
      cost: 28,
      rainReady: true,
      earliestBlock: 0,
      latestBlock: 7,
    ),
    FestivalPerformance(
      id: 'cedar_roots',
      titleTr: 'Sedir Kökleri',
      titleEn: 'Cedar Roots',
      genre: FestivalGenre.folk,
      audience: 3,
      power: 2,
      crew: 2,
      cost: 18,
      rainReady: true,
      earliestBlock: 0,
      latestBlock: 7,
    ),
    FestivalPerformance(
      id: 'copper_drums',
      titleTr: 'Bakır Davullar',
      titleEn: 'Copper Drums',
      genre: FestivalGenre.percussion,
      audience: 4,
      power: 3,
      crew: 3,
      cost: 21,
      rainReady: false,
      earliestBlock: 0,
      latestBlock: 7,
    ),
    FestivalPerformance(
      id: 'orbit_dancers',
      titleTr: 'Yörünge Dansçıları',
      titleEn: 'Orbit Dancers',
      genre: FestivalGenre.dance,
      audience: 3,
      power: 2,
      crew: 2,
      cost: 19,
      rainReady: false,
      earliestBlock: 0,
      latestBlock: 7,
    ),
    FestivalPerformance(
      id: 'tiny_theatre',
      titleTr: 'Minik Tiyatro',
      titleEn: 'Tiny Theatre',
      genre: FestivalGenre.comedy,
      audience: 3,
      power: 1,
      crew: 2,
      cost: 16,
      rainReady: true,
      earliestBlock: 0,
      latestBlock: 7,
    ),
    FestivalPerformance(
      id: 'north_chorus',
      titleTr: 'Kuzey Korosu',
      titleEn: 'Northern Chorus',
      genre: FestivalGenre.choir,
      audience: 4,
      power: 2,
      crew: 3,
      cost: 22,
      rainReady: true,
      earliestBlock: 0,
      latestBlock: 7,
    ),
    FestivalPerformance(
      id: 'glass_strings',
      titleTr: 'Cam Yaylılar',
      titleEn: 'Glass Strings',
      genre: FestivalGenre.strings,
      audience: 3,
      power: 2,
      crew: 2,
      cost: 20,
      rainReady: false,
      earliestBlock: 0,
      latestBlock: 7,
    ),
    FestivalPerformance(
      id: 'blue_hour',
      titleTr: 'Mavi Saat Cazı',
      titleEn: 'Blue Hour Jazz',
      genre: FestivalGenre.jazz,
      audience: 4,
      power: 3,
      crew: 2,
      cost: 25,
      rainReady: true,
      earliestBlock: 0,
      latestBlock: 7,
    ),
    FestivalPerformance(
      id: 'cloud_circus',
      titleTr: 'Bulut Sirki',
      titleEn: 'Cloud Circus',
      genre: FestivalGenre.circus,
      audience: 3,
      power: 2,
      crew: 3,
      cost: 20,
      rainReady: false,
      earliestBlock: 0,
      latestBlock: 7,
    ),
    FestivalPerformance(
      id: 'open_notebook',
      titleTr: 'Açık Defter Şiirleri',
      titleEn: 'Open Notebook',
      genre: FestivalGenre.spokenWord,
      audience: 2,
      power: 1,
      crew: 1,
      cost: 12,
      rainReady: true,
      earliestBlock: 0,
      latestBlock: 7,
    ),
    FestivalPerformance(
      id: 'soft_signal',
      titleTr: 'Yumuşak Sinyal',
      titleEn: 'Soft Signal',
      genre: FestivalGenre.ambient,
      audience: 2,
      power: 2,
      crew: 1,
      cost: 14,
      rainReady: true,
      earliestBlock: 0,
      latestBlock: 7,
    ),
    FestivalPerformance(
      id: 'light_makers',
      titleTr: 'Işık Üretenler',
      titleEn: 'Light Makers',
      genre: FestivalGenre.maker,
      audience: 3,
      power: 2,
      crew: 2,
      cost: 17,
      rainReady: false,
      earliestBlock: 0,
      latestBlock: 7,
    ),
    FestivalPerformance(
      id: 'world_table',
      titleTr: 'Dünya Sofrası Ritimleri',
      titleEn: 'World Table Rhythms',
      genre: FestivalGenre.world,
      audience: 4,
      power: 3,
      crew: 3,
      cost: 23,
      rainReady: true,
      earliestBlock: 0,
      latestBlock: 7,
    ),
  ];
}

class FestivalScenario {
  const FestivalScenario({
    required this.level,
    required this.seed,
    required this.timeSlots,
    required this.showCount,
    required this.performances,
    required this.weather,
    required this.rainSlot,
    required this.turnaroundGap,
    required this.audienceCapacity,
    required this.powerCapacity,
    required this.crewCapacity,
    required this.minimumGenres,
    required this.audienceTarget,
    required this.budget,
  });
  final int level;
  final int seed;
  final int timeSlots;
  final int showCount;
  final List<FestivalPerformance> performances;
  final FestivalWeather weather;
  final int rainSlot;
  final int turnaroundGap;
  final int audienceCapacity;
  final int powerCapacity;
  final int crewCapacity;
  final int minimumGenres;
  final int audienceTarget;
  final int budget;
  static const int campaignLevels = 20;
  static const int practiceFestivals = 300;

  String get signature => '$seed|$layoutSignature';
  String get layoutSignature => <String>[
    timeSlots.toString(),
    showCount.toString(),
    weather.name,
    rainSlot.toString(),
    turnaroundGap.toString(),
    audienceCapacity.toString(),
    powerCapacity.toString(),
    crewCapacity.toString(),
    minimumGenres.toString(),
    audienceTarget.toString(),
    budget.toString(),
    performances
        .map(
          (FestivalPerformance item) =>
              '${item.id}:${item.earliestBlock}-${item.latestBlock}',
        )
        .join(','),
  ].join('|');

  static FestivalScenario forLevel(int level) {
    final int safe = level.clamp(1, campaignLevels).toInt();
    return _create(
      level: safe,
      seed: 160000 + safe * 977,
      showCount: 3 + ((safe - 1) * 5 ~/ 19),
      random: math.Random(0xF357 + safe * 991),
      difficulty: safe,
    );
  }

  static FestivalScenario forPractice(int index) {
    final int safe = index.clamp(1, practiceFestivals).toInt();
    final math.Random random = math.Random(0xFE57 + safe * 7919);
    return _create(
      level: campaignLevels,
      seed: 1600000 + safe * 3323,
      showCount: 3 + random.nextInt(6),
      random: random,
      difficulty: safe,
    );
  }

  static FestivalScenario _create({
    required int level,
    required int seed,
    required int showCount,
    required math.Random random,
    required int difficulty,
  }) {
    final List<FestivalPerformance> ordered =
        FestivalPerformance.templates.toList()..shuffle(random);
    final List<FestivalPerformance> lineup = ordered.take(showCount).toList();
    if (!lineup.any((FestivalPerformance item) => item.rainReady)) {
      lineup[lineup.length - 1] = FestivalPerformance.templates.firstWhere(
        (FestivalPerformance p) => p.rainReady,
      );
    }
    final Set<String> lineupIds = lineup
        .map((FestivalPerformance p) => p.id)
        .toSet();
    final List<FestivalPerformance> extras = ordered
        .where((FestivalPerformance p) => !lineupIds.contains(p.id))
        .toList();
    final List<FestivalPerformance> pool =
        <FestivalPerformance>[...lineup, ...extras]
            .asMap()
            .entries
            .map((MapEntry<int, FestivalPerformance> entry) {
              final int i = entry.key;
              final FestivalPerformance item = entry.value;
              final int earliest = i < showCount
                  ? (i - 1).clamp(0, 7)
                  : random.nextInt(5);
              final int latest = i < showCount
                  ? (i + 2).clamp(0, 7)
                  : (earliest + 1 + random.nextInt(8 - earliest)).clamp(
                      earliest,
                      7,
                    );
              return FestivalPerformance(
                id: item.id,
                titleTr: item.titleTr,
                titleEn: item.titleEn,
                genre: item.genre,
                audience: item.audience,
                power: item.power,
                crew: item.crew,
                cost: item.cost,
                rainReady: item.rainReady,
                earliestBlock: earliest,
                latestBlock: latest,
              );
            })
            .toList(growable: false);
    final FestivalWeather weather = difficulty % 3 == 0
        ? FestivalWeather.drizzle
        : FestivalWeather.values[random.nextInt(FestivalWeather.values.length)];
    final int rainSlot = lineup.indexWhere(
      (FestivalPerformance item) => item.rainReady,
    );
    final int audience = lineup.fold<int>(
      0,
      (int sum, FestivalPerformance item) => sum + item.audience,
    );
    final int budget = lineup.fold<int>(
      0,
      (int sum, FestivalPerformance item) => sum + item.cost,
    );
    return FestivalScenario(
      level: level,
      seed: seed,
      timeSlots: 8,
      showCount: showCount,
      performances: List<FestivalPerformance>.unmodifiable(pool),
      weather: weather,
      rainSlot: rainSlot,
      turnaroundGap: difficulty >= 7 ? 1 : 0,
      audienceCapacity: 4 + difficulty % 3,
      powerCapacity: 4 + difficulty % 2,
      crewCapacity: 3 + difficulty % 2,
      minimumGenres: math.min(3, showCount),
      audienceTarget: audience - (difficulty % 4 == 0 ? 1 : 0),
      budget: budget + 18 + random.nextInt(22),
    );
  }
}
