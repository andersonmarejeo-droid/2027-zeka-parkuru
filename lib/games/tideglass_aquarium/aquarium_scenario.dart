enum AquariumSpecies { guppy, tetra, corydoras, shrimp, betta, goldfish, snail }

enum AquariumSubstrate { sand, pebble, fineGravel }

extension AquariumSpeciesInfo on AquariumSpecies {
  String label(bool english) => switch (this) {
    AquariumSpecies.guppy => english ? 'GUPPY' : 'LEBİSTES',
    AquariumSpecies.tetra => english ? 'TETRA' : 'TETRA',
    AquariumSpecies.corydoras => english ? 'CORY' : 'ÇÖPÇÜ',
    AquariumSpecies.shrimp => english ? 'SHRIMP' : 'KARİDES',
    AquariumSpecies.betta => english ? 'BETTA' : 'BETTA',
    AquariumSpecies.goldfish => english ? 'GOLDFISH' : 'JAPON',
    AquariumSpecies.snail => english ? 'SNAIL' : 'SALYANGOZ',
  };

  int get bioload => switch (this) {
    AquariumSpecies.guppy => 1,
    AquariumSpecies.tetra => 1,
    AquariumSpecies.corydoras => 2,
    AquariumSpecies.shrimp => 1,
    AquariumSpecies.betta => 2,
    AquariumSpecies.goldfish => 4,
    AquariumSpecies.snail => 1,
  };

  int get minimumGroup => switch (this) {
    AquariumSpecies.betta ||
    AquariumSpecies.goldfish ||
    AquariumSpecies.snail => 1,
    _ => 3,
  };

  int get iconHue => switch (this) {
    AquariumSpecies.guppy => 18,
    AquariumSpecies.tetra => 202,
    AquariumSpecies.corydoras => 36,
    AquariumSpecies.shrimp => 345,
    AquariumSpecies.betta => 274,
    AquariumSpecies.goldfish => 27,
    AquariumSpecies.snail => 84,
  };
}

extension AquariumSubstrateInfo on AquariumSubstrate {
  String label(bool english) => switch (this) {
    AquariumSubstrate.sand => english ? 'SAND' : 'KUM',
    AquariumSubstrate.pebble => english ? 'PEBBLE' : 'ÇAKIL',
    AquariumSubstrate.fineGravel => english ? 'FINE GRAVEL' : 'İNCE GRAVEL',
  };
}

class AquariumScenario {
  const AquariumScenario({
    required this.level,
    required this.seed,
    required this.liters,
    required this.targetTemperature,
    required this.requiredPopulations,
    required this.minimumPlants,
    required this.minimumFilterTier,
    required this.substrate,
    required this.minimumLight,
    required this.aeratorRequired,
    required this.difficulty,
  });

  final int level;
  final int seed;
  final int liters;
  final int targetTemperature;
  final Map<AquariumSpecies, int> requiredPopulations;
  final int minimumPlants;
  final int minimumFilterTier;
  final AquariumSubstrate substrate;
  final int minimumLight;
  final bool aeratorRequired;
  final int difficulty;

  int get totalRequiredFish =>
      requiredPopulations.values.fold<int>(0, (a, b) => a + b);
  String get signature => <String>[
    seed.toString(),
    liters.toString(),
    targetTemperature.toString(),
    requiredPopulations.entries
        .map((e) => '${e.key.name}:${e.value}')
        .join(','),
    minimumPlants.toString(),
    minimumFilterTier.toString(),
    substrate.name,
    minimumLight.toString(),
    aeratorRequired.toString(),
  ].join('|');

  String get layoutSignature => <String>[
    liters.toString(),
    targetTemperature.toString(),
    requiredPopulations.entries
        .map((e) => '${e.key.name}:${e.value}')
        .join(','),
    minimumPlants.toString(),
    minimumFilterTier.toString(),
    substrate.name,
    minimumLight.toString(),
    aeratorRequired.toString(),
  ].join('|');

  static const int campaignLevels = 20;
  static const int practiceTankChallenges = 300;

  static const List<Map<AquariumSpecies, int>>
  _communities = <Map<AquariumSpecies, int>>[
    <AquariumSpecies, int>{AquariumSpecies.guppy: 3, AquariumSpecies.tetra: 4},
    <AquariumSpecies, int>{
      AquariumSpecies.goldfish: 2,
      AquariumSpecies.snail: 1,
    },
    <AquariumSpecies, int>{AquariumSpecies.betta: 1, AquariumSpecies.snail: 1},
    <AquariumSpecies, int>{AquariumSpecies.shrimp: 5, AquariumSpecies.snail: 2},
    <AquariumSpecies, int>{
      AquariumSpecies.tetra: 5,
      AquariumSpecies.corydoras: 3,
    },
    <AquariumSpecies, int>{
      AquariumSpecies.guppy: 3,
      AquariumSpecies.shrimp: 3,
      AquariumSpecies.snail: 1,
    },
  ];

  static AquariumScenario forLevel(int level) {
    final int safeLevel = level.clamp(1, campaignLevels).toInt();
    final int groupIndex = (safeLevel - 1) % _communities.length;
    final int tier = switch (safeLevel) {
      <= 3 => 1,
      <= 6 => 2,
      <= 10 => 3,
      <= 15 => 4,
      _ => 5,
    };
    final Map<AquariumSpecies, int> population = Map<AquariumSpecies, int>.of(
      _communities[groupIndex],
    );
    if (tier >= 4 &&
        safeLevel >= 13 &&
        population[AquariumSpecies.tetra] != null) {
      population[AquariumSpecies.tetra] =
          population[AquariumSpecies.tetra]! + 2;
    }
    return AquariumScenario(
      level: safeLevel,
      seed: 81000 + safeLevel * 113,
      liters: 45 + tier * 20,
      targetTemperature: groupIndex == 1 ? 21 : (groupIndex == 2 ? 26 : 24),
      requiredPopulations: Map<AquariumSpecies, int>.unmodifiable(population),
      minimumPlants: (tier / 2).ceil(),
      minimumFilterTier: tier <= 2 ? 1 : (tier <= 4 ? 2 : 3),
      substrate: groupIndex == 1
          ? AquariumSubstrate.pebble
          : AquariumSubstrate.sand,
      minimumLight: tier <= 2 ? 1 : 2,
      aeratorRequired: tier >= 4,
      difficulty: safeLevel,
    );
  }

  static AquariumScenario forPractice(int index) {
    final int safeIndex = index.clamp(1, practiceTankChallenges).toInt();
    final int family = safeIndex % _communities.length;
    final int variation = safeIndex ~/ _communities.length;
    final Map<AquariumSpecies, int> population = Map<AquariumSpecies, int>.of(
      _communities[family],
    );
    if (variation % 3 == 1 && population[AquariumSpecies.guppy] != null) {
      population[AquariumSpecies.guppy] =
          population[AquariumSpecies.guppy]! + 1;
    } else if (variation % 3 == 2 &&
        population[AquariumSpecies.tetra] != null) {
      population[AquariumSpecies.tetra] =
          population[AquariumSpecies.tetra]! + 1;
    }
    final AquariumSubstrate substrate = AquariumSubstrate
        .values[(family + variation) % AquariumSubstrate.values.length];
    return AquariumScenario(
      level: campaignLevels,
      seed: 700000 + safeIndex * 4201,
      liters: 55 + variation * 2,
      targetTemperature: family == 1 ? 19 + variation % 5 : 22 + variation % 7,
      requiredPopulations: Map<AquariumSpecies, int>.unmodifiable(population),
      minimumPlants: 1 + variation % 5,
      minimumFilterTier: 1 + variation % 3,
      substrate: substrate,
      minimumLight: 1 + variation % 3,
      aeratorRequired: variation.isOdd,
      difficulty: safeIndex,
    );
  }
}
