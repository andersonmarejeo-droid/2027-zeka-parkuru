import 'dart:math' as math;

enum MoonModule {
  solarArray,
  habitat,
  greenhouse,
  laboratory,
  battery,
  radiator,
  shield,
  commRelay,
}

enum MoonHazard { calm, coldFront, meteorShower, solarEclipse }

extension MoonModuleInfo on MoonModule {
  String label(bool english) => switch (this) {
    MoonModule.solarArray => english ? 'SOLAR' : 'GÜNEŞ',
    MoonModule.habitat => english ? 'HABITAT' : 'YAŞAM',
    MoonModule.greenhouse => english ? 'OXYGEN' : 'OKSİJEN',
    MoonModule.laboratory => english ? 'LAB' : 'LABORATUVAR',
    MoonModule.battery => english ? 'BATTERY' : 'BATARYA',
    MoonModule.radiator => english ? 'RADIATOR' : 'RADYATÖR',
    MoonModule.shield => english ? 'SHIELD' : 'KALKAN',
    MoonModule.commRelay => english ? 'RELAY' : 'RÖLE',
  };

  int get cost => switch (this) {
    MoonModule.solarArray => 32,
    MoonModule.habitat => 40,
    MoonModule.greenhouse => 34,
    MoonModule.laboratory => 42,
    MoonModule.battery => 25,
    MoonModule.radiator => 28,
    MoonModule.shield => 38,
    MoonModule.commRelay => 30,
  };

  int get power => switch (this) {
    MoonModule.solarArray => 10,
    MoonModule.battery => 6,
    _ => 0,
  };

  int get oxygen => this == MoonModule.greenhouse ? 5 : 0;

  int get cooling => this == MoonModule.radiator ? 6 : 0;

  int get heat => switch (this) {
    MoonModule.habitat => 1,
    MoonModule.greenhouse || MoonModule.commRelay => 1,
    MoonModule.laboratory => 3,
    MoonModule.solarArray => 1,
    _ => 0,
  };
}

class MoonCell {
  const MoonCell(this.x, this.y);
  final int x;
  final int y;
  String get signature => '$x:$y';
  @override
  bool operator ==(Object other) =>
      other is MoonCell && other.x == x && other.y == y;
  @override
  int get hashCode => Object.hash(x, y);
}

class MoonbaseScenario {
  const MoonbaseScenario({
    required this.level,
    required this.seed,
    required this.size,
    required this.crew,
    required this.powerDemand,
    required this.oxygenDemand,
    required this.heatLimit,
    required this.hazard,
    required this.requiredModules,
    required this.rocks,
    required this.budget,
  });

  final int level;
  final int seed;
  final int size;
  final int crew;
  final int powerDemand;
  final int oxygenDemand;
  final int heatLimit;
  final MoonHazard hazard;
  final List<MoonModule> requiredModules;
  final List<MoonCell> rocks;
  final int budget;

  MoonCell get core => MoonCell(size ~/ 2, size ~/ 2);
  int get powerPenalty => hazard == MoonHazard.solarEclipse ? 4 : 0;
  int get batteryBonus => hazard == MoonHazard.solarEclipse ? 6 : 0;
  bool get shieldRequired => hazard == MoonHazard.meteorShower;

  String get signature => '$seed|$layoutSignature';
  String get layoutSignature => <String>[
    size.toString(),
    crew.toString(),
    powerDemand.toString(),
    oxygenDemand.toString(),
    heatLimit.toString(),
    hazard.name,
    budget.toString(),
    requiredModules.map((MoonModule module) => module.name).join(','),
    rocks.map((MoonCell cell) => cell.signature).join(','),
  ].join('|');

  static const int campaignLevels = 20;
  static const int practiceMissions = 300;

  static MoonbaseScenario forLevel(int level) {
    final int safe = level.clamp(1, campaignLevels).toInt();
    final int crew = 2 + safe ~/ 2;
    final bool lab = safe >= 4;
    final bool relay = safe >= 7;
    final MoonHazard hazard = safe < 9
        ? MoonHazard.values[(safe - 1) % 2]
        : switch ((safe - 9) % 3) {
            0 => MoonHazard.meteorShower,
            1 => MoonHazard.solarEclipse,
            _ => MoonHazard.coldFront,
          };
    final int powerDemand = crew * 2 + (lab ? 4 : 0) + (relay ? 2 : 0);
    final int oxygenDemand = crew * 2;
    final int heatLimit = safe < 9 ? 7 + safe ~/ 3 : 9 + safe ~/ 6;
    return _create(
      level: safe,
      seed: 140000 + safe * 719,
      size: safe >= 13 ? 8 : 7,
      crew: crew,
      powerDemand: powerDemand,
      oxygenDemand: oxygenDemand,
      heatLimit: heatLimit,
      hazard: hazard,
      extra: safe >= 17 ? 1 : 0,
    );
  }

  static MoonbaseScenario forPractice(int index) {
    final int safe = index.clamp(1, practiceMissions).toInt();
    final math.Random random = math.Random(0xA17B + safe * 7013);
    final int crew = 2 + safe % 11;
    final bool lab = safe % 4 != 0;
    final bool relay = safe % 3 == 0;
    final MoonHazard hazard =
        MoonHazard.values[random.nextInt(MoonHazard.values.length)];
    return _create(
      level: campaignLevels,
      seed: 1400000 + safe * 3301,
      size: 7 + (safe % 4 == 0 ? 1 : 0),
      crew: crew,
      powerDemand: crew * 2 + (lab ? 4 : 0) + (relay ? 2 : 0),
      oxygenDemand: crew * 2,
      heatLimit: 8 + random.nextInt(8),
      hazard: hazard,
      extra: safe % 5 == 0 ? 1 : 0,
      random: random,
      lab: lab,
      relay: relay,
    );
  }

  static MoonbaseScenario _create({
    required int level,
    required int seed,
    required int size,
    required int crew,
    required int powerDemand,
    required int oxygenDemand,
    required int heatLimit,
    required MoonHazard hazard,
    required int extra,
    math.Random? random,
    bool? lab,
    bool? relay,
  }) {
    final bool needsLab = lab ?? level >= 4;
    final bool needsRelay = relay ?? level >= 7;
    final int batteryBonus = hazard == MoonHazard.solarEclipse ? 6 : 0;
    final int panels =
        ((powerDemand +
                    (hazard == MoonHazard.solarEclipse ? 4 : 0) -
                    batteryBonus) /
                10)
            .ceil()
            .clamp(1, 6);
    final int greenhouses = (oxygenDemand / 5).ceil();
    final int habitats = (crew / 4).ceil();
    final List<MoonModule> modules = <MoonModule>[
      ...List<MoonModule>.filled(panels, MoonModule.solarArray),
      ...List<MoonModule>.filled(habitats, MoonModule.habitat),
      ...List<MoonModule>.filled(greenhouses, MoonModule.greenhouse),
      if (needsLab) MoonModule.laboratory,
      if (needsRelay) MoonModule.commRelay,
      if (hazard == MoonHazard.solarEclipse) MoonModule.battery,
      if (hazard == MoonHazard.meteorShower) MoonModule.shield,
      ...List<MoonModule>.filled(
        (((crew +
                        (needsLab ? 3 : 0) +
                        greenhouses +
                        panels +
                        (hazard == MoonHazard.coldFront ? 3 : 0) +
                        (needsRelay ? 1 : 0) +
                        extra -
                        heatLimit) /
                    6)
                .ceil())
            .clamp(0, 5),
        MoonModule.radiator,
      ),
      ...List<MoonModule>.filled(extra, MoonModule.commRelay),
    ];
    final int subtotal = modules.fold<int>(
      0,
      (int sum, MoonModule module) => sum + module.cost,
    );
    final List<MoonCell> rocks = _rocks(
      random ?? math.Random(seed * 3571),
      size,
      seed,
    );
    return MoonbaseScenario(
      level: level,
      seed: seed,
      size: size,
      crew: crew,
      powerDemand: powerDemand,
      oxygenDemand: oxygenDemand,
      heatLimit: heatLimit,
      hazard: hazard,
      requiredModules: List<MoonModule>.unmodifiable(modules),
      rocks: List<MoonCell>.unmodifiable(rocks),
      budget: subtotal + 44 + (random?.nextInt(52) ?? level * 2),
    );
  }

  static List<MoonCell> _rocks(math.Random random, int size, int seed) {
    final Set<MoonCell> result = <MoonCell>{};
    final int count = 3 + seed.abs() % 5;
    while (result.length < count) {
      final bool edge = random.nextBool();
      final MoonCell cell = edge
          ? MoonCell(random.nextBool() ? 0 : size - 1, random.nextInt(size))
          : MoonCell(random.nextInt(size), random.nextBool() ? 0 : size - 1);
      if (cell != MoonCell(size ~/ 2, size ~/ 2)) result.add(cell);
    }
    return result.toList(growable: false);
  }
}
