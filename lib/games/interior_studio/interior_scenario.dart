import 'dart:math' as math;

enum InteriorStyle { modern, natural, cozy }

enum InteriorPalette { linen, sage, terracotta }

enum InteriorFurniture { sofa, bed, desk, plant, lamp, bookshelf, diningTable }

extension InteriorStyleLabel on InteriorStyle {
  String label(bool english) => switch (this) {
    InteriorStyle.modern => english ? 'MODERN' : 'MODERN',
    InteriorStyle.natural => english ? 'NATURAL' : 'DOĞAL',
    InteriorStyle.cozy => english ? 'COZY' : 'SICAK',
  };
}

extension InteriorPaletteLabel on InteriorPalette {
  String label(bool english) => switch (this) {
    InteriorPalette.linen => english ? 'LINEN' : 'KETEN',
    InteriorPalette.sage => english ? 'SAGE' : 'ADAÇAYI',
    InteriorPalette.terracotta => english ? 'CLAY' : 'KİREMİT',
  };
}

extension InteriorFurnitureInfo on InteriorFurniture {
  String label(bool english) => switch (this) {
    InteriorFurniture.sofa => english ? 'SOFA' : 'KANEPE',
    InteriorFurniture.bed => english ? 'BED' : 'YATAK',
    InteriorFurniture.desk => english ? 'DESK' : 'ÇALIŞMA',
    InteriorFurniture.plant => english ? 'PLANT' : 'BİTKİ',
    InteriorFurniture.lamp => english ? 'LAMP' : 'LAMBA',
    InteriorFurniture.bookshelf => english ? 'BOOKS' : 'KİTAPLIK',
    InteriorFurniture.diningTable => english ? 'TABLE' : 'MASA',
  };

  int get cost => switch (this) {
    InteriorFurniture.sofa => 42,
    InteriorFurniture.bed => 44,
    InteriorFurniture.desk => 31,
    InteriorFurniture.plant => 12,
    InteriorFurniture.lamp => 15,
    InteriorFurniture.bookshelf => 26,
    InteriorFurniture.diningTable => 34,
  };

  (int, int) get footprint => switch (this) {
    InteriorFurniture.sofa ||
    InteriorFurniture.bed ||
    InteriorFurniture.bookshelf => (2, 1),
    InteriorFurniture.diningTable => (2, 2),
    _ => (1, 1),
  };

  Set<InteriorStyle> get styles => switch (this) {
    InteriorFurniture.sofa => <InteriorStyle>{
      InteriorStyle.modern,
      InteriorStyle.cozy,
    },
    InteriorFurniture.bed => <InteriorStyle>{
      InteriorStyle.natural,
      InteriorStyle.cozy,
    },
    InteriorFurniture.desk => <InteriorStyle>{
      InteriorStyle.modern,
      InteriorStyle.natural,
    },
    InteriorFurniture.diningTable => <InteriorStyle>{
      InteriorStyle.modern,
      InteriorStyle.natural,
      InteriorStyle.cozy,
    },
    InteriorFurniture.plant => <InteriorStyle>{
      InteriorStyle.natural,
      InteriorStyle.cozy,
    },
    InteriorFurniture.bookshelf => <InteriorStyle>{
      InteriorStyle.modern,
      InteriorStyle.natural,
    },
    InteriorFurniture.lamp => <InteriorStyle>{
      InteriorStyle.modern,
      InteriorStyle.cozy,
    },
  };
}

class InteriorScenario {
  const InteriorScenario({
    required this.level,
    required this.seed,
    required this.width,
    required this.height,
    required this.style,
    required this.palette,
    required this.budget,
    required this.requirements,
    required this.windowX,
    required this.difficulty,
  });

  final int level;
  final int seed;
  final int width;
  final int height;
  final InteriorStyle style;
  final InteriorPalette palette;
  final int budget;
  final List<InteriorFurniture> requirements;
  final int windowX;
  final int difficulty;

  int get doorX => width ~/ 2;

  String get signature => <String>[
    seed.toString(),
    width.toString(),
    height.toString(),
    style.name,
    palette.name,
    budget.toString(),
    windowX.toString(),
    requirements.map((InteriorFurniture item) => item.name).join(','),
  ].join('|');

  String get layoutSignature => <String>[
    width.toString(),
    height.toString(),
    style.name,
    palette.name,
    budget.toString(),
    windowX.toString(),
    requirements.map((InteriorFurniture item) => item.name).join(','),
  ].join('|');

  static const int campaignLevels = 20;
  static const int practiceScenarios = 300;

  static InteriorScenario forLevel(int level) {
    final int safeLevel = level.clamp(1, campaignLevels).toInt();
    final int requirementCount = switch (safeLevel) {
      <= 3 => 3,
      <= 6 => 4,
      <= 10 => 5,
      <= 15 => 6,
      _ => 7,
    };
    final InteriorStyle style =
        InteriorStyle.values[(safeLevel - 1) % InteriorStyle.values.length];
    return InteriorScenario(
      level: safeLevel,
      seed: 42000 + safeLevel * 97,
      width: safeLevel >= 12 ? 8 : 7,
      height: safeLevel >= 17 ? 8 : 7,
      style: style,
      palette: InteriorPalette
          .values[(safeLevel ~/ 3) % InteriorPalette.values.length],
      budget: 124 + safeLevel * 20,
      requirements: List<InteriorFurniture>.unmodifiable(
        _requirements(style, requirementCount, safeLevel * 2),
      ),
      windowX: safeLevel.isEven ? 1 : (safeLevel >= 12 ? 6 : 5),
      difficulty: safeLevel,
    );
  }

  static InteriorScenario forPractice(int index) {
    final int safeIndex = index.clamp(1, practiceScenarios).toInt();
    final math.Random random = math.Random(0x51A7 + safeIndex * 7919);
    final int count = 3 + (safeIndex % 5);
    final InteriorStyle style =
        InteriorStyle.values[random.nextInt(InteriorStyle.values.length)];
    final List<InteriorFurniture> requirements = _requirements(
      style,
      count,
      random.nextInt(InteriorFurniture.values.length),
    );
    return InteriorScenario(
      level: campaignLevels,
      seed: 900000 + safeIndex * 3571,
      width: 7 + (safeIndex % 4 == 0 ? 1 : 0),
      height: 7 + (safeIndex % 7 == 0 ? 1 : 0),
      style: style,
      palette:
          InteriorPalette.values[random.nextInt(InteriorPalette.values.length)],
      budget:
          requirements.fold<int>(
            20,
            (int sum, InteriorFurniture item) => sum + item.cost,
          ) +
          random.nextInt(35),
      requirements: List<InteriorFurniture>.unmodifiable(requirements),
      windowX: 1 + random.nextInt(5),
      difficulty: safeIndex,
    );
  }

  static List<InteriorFurniture> _requirements(
    InteriorStyle style,
    int count,
    int start,
  ) {
    final List<InteriorFurniture> furniture = InteriorFurniture.values;
    final int needed = (count * .6).ceil();
    for (int offset = 0; offset < furniture.length; offset++) {
      final List<InteriorFurniture> candidate =
          List<InteriorFurniture>.generate(
            count,
            (int index) =>
                furniture[(start + offset + index) % furniture.length],
          );
      if (candidate
              .where((InteriorFurniture item) => item.styles.contains(style))
              .length >=
          needed) {
        return candidate;
      }
    }
    return furniture.take(count).toList(growable: false);
  }
}
