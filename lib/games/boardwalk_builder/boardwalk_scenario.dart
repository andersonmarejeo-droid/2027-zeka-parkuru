import 'dart:math' as math;

enum BoardwalkWeather { clear, breezy, shower }

enum BoardwalkBuild {
  path,
  carousel,
  pierWheel,
  snackBar,
  bench,
  litterBin,
  shadeCanopy,
  lamp,
}

extension BoardwalkBuildInfo on BoardwalkBuild {
  String label(bool english) => switch (this) {
    BoardwalkBuild.path => english ? 'BOARDWALK' : 'YOL',
    BoardwalkBuild.carousel => english ? 'CAROUSEL' : 'ATLI KARINCA',
    BoardwalkBuild.pierWheel => english ? 'PIER WHEEL' : 'DÖNME DOLAP',
    BoardwalkBuild.snackBar => english ? 'SNACK BAR' : 'KUMSAL KAFE',
    BoardwalkBuild.bench => english ? 'BENCH' : 'BANK',
    BoardwalkBuild.litterBin => english ? 'BIN' : 'GERİ DÖNÜŞÜM',
    BoardwalkBuild.shadeCanopy => english ? 'SHADE' : 'GÖLGELİK',
    BoardwalkBuild.lamp => english ? 'LAMP' : 'AYDINLATMA',
  };

  int get cost => switch (this) {
    BoardwalkBuild.path => 4,
    BoardwalkBuild.carousel => 44,
    BoardwalkBuild.pierWheel => 58,
    BoardwalkBuild.snackBar => 36,
    BoardwalkBuild.bench => 13,
    BoardwalkBuild.litterBin => 8,
    BoardwalkBuild.shadeCanopy => 18,
    BoardwalkBuild.lamp => 12,
  };

  int get rideCapacity => switch (this) {
    BoardwalkBuild.carousel => 6,
    BoardwalkBuild.pierWheel => 7,
    _ => 0,
  };

  int get foodCapacity => this == BoardwalkBuild.snackBar ? 7 : 0;

  bool get isRide => rideCapacity > 0;
}

class BoardwalkCell {
  const BoardwalkCell(this.x, this.y);
  final int x;
  final int y;
  String get signature => '$x:$y';
  @override
  bool operator ==(Object other) =>
      other is BoardwalkCell && other.x == x && other.y == y;
  @override
  int get hashCode => Object.hash(x, y);
}

class BoardwalkScenario {
  const BoardwalkScenario({
    required this.level,
    required this.seed,
    required this.width,
    required this.height,
    required this.budget,
    required this.visitorCount,
    required this.requiredBuilds,
    required this.minimumBins,
    required this.minimumBenches,
    required this.weather,
    required this.blockedCells,
  });

  final int level;
  final int seed;
  final int width;
  final int height;
  final int budget;
  final int visitorCount;
  final List<BoardwalkBuild> requiredBuilds;
  final int minimumBins;
  final int minimumBenches;
  final BoardwalkWeather weather;
  final List<BoardwalkCell> blockedCells;

  BoardwalkCell get entry => BoardwalkCell(width ~/ 2, height - 1);
  String get layoutSignature => <String>[
    width.toString(),
    height.toString(),
    budget.toString(),
    visitorCount.toString(),
    requiredBuilds.map((BoardwalkBuild b) => b.name).join(','),
    minimumBins.toString(),
    minimumBenches.toString(),
    weather.name,
    blockedCells.map((BoardwalkCell c) => c.signature).join(','),
  ].join('|');
  String get signature => '$seed|$layoutSignature';

  static const int campaignLevels = 20;
  static const int practiceParks = 300;

  static BoardwalkScenario forLevel(int level) {
    final int safe = level.clamp(1, campaignLevels).toInt();
    final int phase = (safe - 1) ~/ 4;
    final BoardwalkBuild primaryRide = safe.isEven
        ? BoardwalkBuild.pierWheel
        : BoardwalkBuild.carousel;
    final List<BoardwalkBuild> builds = <BoardwalkBuild>[
      primaryRide,
      if (safe >= 9)
        primaryRide == BoardwalkBuild.pierWheel
            ? BoardwalkBuild.carousel
            : BoardwalkBuild.pierWheel,
      BoardwalkBuild.snackBar,
      if (safe >= 15) BoardwalkBuild.snackBar,
      ...List<BoardwalkBuild>.filled(1 + phase, BoardwalkBuild.bench),
      ...List<BoardwalkBuild>.filled(1 + phase ~/ 2, BoardwalkBuild.litterBin),
      if (safe >= 9) BoardwalkBuild.shadeCanopy,
      if (safe >= 13) BoardwalkBuild.lamp,
    ];
    final int subtotal = builds.fold<int>(
      0,
      (int sum, BoardwalkBuild b) => sum + b.cost,
    );
    final int visitors = 3 + safe ~/ 2;
    return BoardwalkScenario(
      level: safe,
      seed: 93000 + safe * 541,
      width: safe >= 12 ? 8 : 7,
      height: safe >= 17 ? 8 : 7,
      budget: subtotal + visitors * 16 + 55,
      visitorCount: visitors,
      requiredBuilds: List<BoardwalkBuild>.unmodifiable(builds),
      minimumBins: 1 + phase ~/ 2,
      minimumBenches: 1 + phase,
      weather: safe < 9
          ? BoardwalkWeather.values[(safe - 1) % 2]
          : BoardwalkWeather.values[(safe - 9) %
                BoardwalkWeather.values.length],
      blockedCells: _blocked(
        safe,
        7 + (safe >= 12 ? 1 : 0),
        7 + (safe >= 17 ? 1 : 0),
      ),
    );
  }

  static BoardwalkScenario forPractice(int index) {
    final int safe = index.clamp(1, practiceParks).toInt();
    final math.Random random = math.Random(0xB04D + safe * 2399);
    final int width = 7 + (safe % 3 == 0 ? 1 : 0);
    final int height = 7 + (safe % 5 == 0 ? 1 : 0);
    final int visitorCount = 4 + safe % 13;
    final BoardwalkWeather weather =
        BoardwalkWeather.values[random.nextInt(BoardwalkWeather.values.length)];
    final List<BoardwalkBuild> builds = <BoardwalkBuild>[
      for (int i = 0; i < (visitorCount / 6).ceil(); i++)
        (safe + i).isEven ? BoardwalkBuild.pierWheel : BoardwalkBuild.carousel,
      ...List<BoardwalkBuild>.filled(
        (visitorCount / 14).ceil(),
        BoardwalkBuild.snackBar,
      ),
      ...List<BoardwalkBuild>.filled(1 + safe % 3, BoardwalkBuild.bench),
      ...List<BoardwalkBuild>.filled(1 + safe % 3, BoardwalkBuild.litterBin),
      if (safe % 4 == 0 || weather == BoardwalkWeather.shower)
        BoardwalkBuild.shadeCanopy,
    ];
    final int base = builds.fold<int>(
      0,
      (int sum, BoardwalkBuild b) => sum + b.cost,
    );
    return BoardwalkScenario(
      level: campaignLevels,
      seed: 800000 + safe * 4459,
      width: width,
      height: height,
      budget: base + visitorCount * 18 + random.nextInt(80),
      visitorCount: visitorCount,
      requiredBuilds: List<BoardwalkBuild>.unmodifiable(builds),
      minimumBins: 1 + safe % 3,
      minimumBenches: 1 + safe % 3,
      weather: weather,
      blockedCells: _blocked(safe, width, height),
    );
  }

  static List<BoardwalkCell> _blocked(int seed, int width, int height) {
    final math.Random random = math.Random(seed * 3571);
    final BoardwalkCell entry = BoardwalkCell(width ~/ 2, height - 1);
    final Set<BoardwalkCell> cells = <BoardwalkCell>{};
    final int count = 3 + seed % 6;
    while (cells.length < count) {
      final int edgeX = random.nextBool() ? 0 : width - 1;
      final BoardwalkCell cell = BoardwalkCell(
        edgeX,
        random.nextInt(height - 2),
      );
      if (cell != entry && cell.y != height - 2) cells.add(cell);
    }
    return List<BoardwalkCell>.unmodifiable(cells);
  }
}
