import 'aquarium_scenario.dart';

class AquariumEvaluation {
  const AquariumEvaluation({
    required this.score,
    required this.speciesCorrect,
    required this.speciesTotal,
    required this.waterLoad,
    required this.filterCapacity,
    required this.temperatureSafe,
    required this.compatible,
    required this.schoolingSafe,
    required this.volumeSafe,
    required this.plantsSafe,
    required this.lightingSafe,
    required this.substrateSafe,
    required this.oxygen,
    required this.oxygenSafe,
    required this.canSubmit,
  });

  final int score;
  final int speciesCorrect;
  final int speciesTotal;
  final int waterLoad;
  final int filterCapacity;
  final bool temperatureSafe;
  final bool compatible;
  final bool schoolingSafe;
  final bool volumeSafe;
  final bool plantsSafe;
  final bool lightingSafe;
  final bool substrateSafe;
  final double oxygen;
  final bool oxygenSafe;
  final bool canSubmit;
}

class AquariumEngine {
  AquariumEngine({required this.scenario})
    : populations = <AquariumSpecies, int>{
        for (final AquariumSpecies species in AquariumSpecies.values)
          species: 0,
      },
      plants = scenario.minimumPlants,
      filterTier = scenario.minimumFilterTier,
      temperature = scenario.targetTemperature,
      substrate = scenario.substrate,
      lightTier = scenario.minimumLight,
      aerator = scenario.aeratorRequired;

  final AquariumScenario scenario;
  final Map<AquariumSpecies, int> populations;
  int plants;
  int filterTier;
  int temperature;
  AquariumSubstrate substrate;
  int lightTier;
  bool aerator;

  int get fishCount => populations.values.fold<int>(0, (int a, int b) => a + b);
  int get waterLoad => populations.entries.fold<int>(
    0,
    (int total, MapEntry<AquariumSpecies, int> entry) =>
        total + entry.key.bioload * entry.value,
  );
  int get filterCapacity => switch (filterTier) {
    <= 0 => 0,
    1 => 8,
    2 => 15,
    3 => 24,
    _ => 36,
  };

  void setPopulation(AquariumSpecies species, int count) {
    populations[species] = count.clamp(0, 12).toInt();
  }

  AquariumEvaluation evaluate() {
    final List<AquariumSpecies> present = populations.entries
        .where((MapEntry<AquariumSpecies, int> e) => e.value > 0)
        .map((MapEntry<AquariumSpecies, int> e) => e.key)
        .toList(growable: false);
    final int correct = scenario.requiredPopulations.entries
        .where(
          (MapEntry<AquariumSpecies, int> e) => populations[e.key] == e.value,
        )
        .length;
    final bool noUnexpected = present.every(
      scenario.requiredPopulations.containsKey,
    );
    final bool compatible = _compatible(present);
    final bool schoolingSafe = present.every((AquariumSpecies species) {
      final int count = populations[species] ?? 0;
      return count == 0 || count >= species.minimumGroup;
    });
    final bool temperatureSafe = present.every((AquariumSpecies species) {
      final (int min, int max) = _temperatureRange(species);
      return temperature >= min && temperature <= max;
    });
    final int waterDemand = present.fold<int>(0, (
      int total,
      AquariumSpecies species,
    ) {
      final int count = populations[species] ?? 0;
      return total +
          (species == AquariumSpecies.goldfish ? count * 12 : count * 4);
    });
    final bool volumeSafe = waterDemand <= scenario.liters;
    final bool plantsSafe = plants >= scenario.minimumPlants;
    final bool lightingSafe =
        lightTier >= scenario.minimumLight && lightTier <= 3;
    final bool substrateSafe = substrate == scenario.substrate;
    final double oxygen =
        5.6 + plants * .38 + (aerator ? 1.15 : 0) - waterLoad * .055;
    final bool oxygenSafe = oxygen >= 5.5 && oxygen <= 9.2;
    final bool filtrationSafe =
        filterTier >= scenario.minimumFilterTier && filterCapacity >= waterLoad;
    final int score =
        ((correct / scenario.requiredPopulations.length * 32) +
                (compatible ? 12 : 0) +
                (schoolingSafe ? 8 : 0) +
                (volumeSafe ? 10 : 0) +
                (filtrationSafe ? 10 : 0) +
                (temperatureSafe ? 8 : 0) +
                (plantsSafe ? 6 : 0) +
                (lightingSafe ? 4 : 0) +
                (substrateSafe ? 4 : 0) +
                (oxygenSafe ? 6 : 0))
            .round()
            .clamp(0, 100)
            .toInt();
    return AquariumEvaluation(
      score: score,
      speciesCorrect: correct,
      speciesTotal: scenario.requiredPopulations.length,
      waterLoad: waterLoad,
      filterCapacity: filterCapacity,
      temperatureSafe: temperatureSafe,
      compatible: compatible && noUnexpected,
      schoolingSafe: schoolingSafe,
      volumeSafe: volumeSafe,
      plantsSafe: plantsSafe,
      lightingSafe: lightingSafe,
      substrateSafe: substrateSafe,
      oxygen: oxygen,
      oxygenSafe: oxygenSafe,
      canSubmit:
          correct == scenario.requiredPopulations.length &&
          noUnexpected &&
          compatible &&
          schoolingSafe &&
          volumeSafe &&
          filtrationSafe &&
          temperatureSafe &&
          plantsSafe &&
          lightingSafe &&
          substrateSafe &&
          oxygenSafe &&
          (!scenario.aeratorRequired || aerator),
    );
  }

  static (int, int) _temperatureRange(AquariumSpecies species) =>
      switch (species) {
        AquariumSpecies.goldfish => (18, 24),
        AquariumSpecies.betta => (24, 28),
        AquariumSpecies.snail => (18, 28),
        AquariumSpecies.shrimp => (21, 27),
        _ => (21, 27),
      };

  static bool _compatible(List<AquariumSpecies> species) {
    if (species.contains(AquariumSpecies.goldfish) &&
        species.any(
          (AquariumSpecies item) =>
              item != AquariumSpecies.goldfish && item != AquariumSpecies.snail,
        )) {
      return false;
    }
    if (species.contains(AquariumSpecies.betta) &&
        species.any(
          (AquariumSpecies item) =>
              item == AquariumSpecies.guppy ||
              item == AquariumSpecies.tetra ||
              item == AquariumSpecies.corydoras ||
              item == AquariumSpecies.shrimp,
        )) {
      return false;
    }
    if (species.contains(AquariumSpecies.shrimp) &&
        species.contains(AquariumSpecies.goldfish)) {
      return false;
    }
    return true;
  }
}
