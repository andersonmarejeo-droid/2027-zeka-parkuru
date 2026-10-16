import 'dart:math' as math;

import '../shared/content_seed.dart';

enum BalanceMaterial { brass, porcelain, slate }

enum BalancePairRule { sameMaterial, mixedMaterial }

enum BalanceClueKind {
  leftLoad,
  brassOnLeft,
  porcelainOnLeft,
  slateOnLeft,
  oddMassOnLeft,
  heavyOnLeft,
  lightOnLeft,
  firstStationsLoad,
  alternatingLeftRemainder,
  heaviestOnLeft,
  lightestOnRight,
}

class BalanceWeight {
  const BalanceWeight({
    required this.id,
    required this.mass,
    required this.material,
  });

  final int id;
  final int mass;
  final BalanceMaterial material;

  String get signature => '$mass:$material';
}

class BalanceStation {
  const BalanceStation({
    required this.index,
    required this.leftMinusRight,
    required this.pairRule,
  });

  final int index;
  final int leftMinusRight;
  final BalancePairRule pairRule;

  String get signature => '$leftMinusRight:$pairRule';

  String text({required bool english}) {
    final String difference = leftMinusRight.abs().toString();
    final String side = leftMinusRight > 0
        ? (english ? 'left' : 'sol')
        : (english ? 'right' : 'sağ');
    final String relation = pairRule == BalancePairRule.sameMaterial
        ? (english ? 'same material' : 'aynı malzeme')
        : (english ? 'different materials' : 'farklı malzemeler');
    return english
        ? '$side pan is heavier by $difference g · $relation'
        : '$side kefe $difference g ağır · $relation';
  }
}

class BalancePlacement {
  const BalancePlacement({required this.leftWeight, required this.rightWeight});

  final int leftWeight;
  final int rightWeight;

  String get signature => '$leftWeight:$rightWeight';
}

class BalanceGlobalClue {
  const BalanceGlobalClue({
    required this.kind,
    required this.value,
    this.threshold = 0,
  });

  final BalanceClueKind kind;
  final int value;
  final int threshold;

  String get signature => '$kind:$value:$threshold';

  bool matches(List<BalanceWeight> weights, List<BalancePlacement> placements) {
    final List<BalanceWeight> left = placements
        .map((BalancePlacement placement) => weights[placement.leftWeight])
        .toList(growable: false);
    final int leftMass = left.fold<int>(
      0,
      (int total, BalanceWeight weight) => total + weight.mass,
    );
    return switch (kind) {
      BalanceClueKind.leftLoad => leftMass == value,
      BalanceClueKind.brassOnLeft =>
        left
                .where(
                  (BalanceWeight weight) =>
                      weight.material == BalanceMaterial.brass,
                )
                .length ==
            value,
      BalanceClueKind.porcelainOnLeft =>
        left
                .where(
                  (BalanceWeight weight) =>
                      weight.material == BalanceMaterial.porcelain,
                )
                .length ==
            value,
      BalanceClueKind.slateOnLeft =>
        left
                .where(
                  (BalanceWeight weight) =>
                      weight.material == BalanceMaterial.slate,
                )
                .length ==
            value,
      BalanceClueKind.oddMassOnLeft =>
        left.where((BalanceWeight weight) => weight.mass.isOdd).length == value,
      BalanceClueKind.heavyOnLeft =>
        left.where((BalanceWeight weight) => weight.mass >= threshold).length ==
            value,
      BalanceClueKind.lightOnLeft =>
        left.where((BalanceWeight weight) => weight.mass <= threshold).length ==
            value,
      BalanceClueKind.firstStationsLoad =>
        placements
                .take(2)
                .fold<int>(
                  0,
                  (int total, BalancePlacement placement) =>
                      total +
                      weights[placement.leftWeight].mass +
                      weights[placement.rightWeight].mass,
                ) ==
            value,
      BalanceClueKind.alternatingLeftRemainder =>
        ((placements.indexed.fold<int>(
                          0,
                          (
                            int total,
                            (int index, BalancePlacement placement) item,
                          ) =>
                              total +
                              (item.$1.isEven
                                  ? weights[item.$2.leftWeight].mass
                                  : -weights[item.$2.leftWeight].mass),
                        ) %
                        5 +
                    5) %
                5) ==
            value,
      BalanceClueKind.heaviestOnLeft =>
        placements.any(
              (BalancePlacement placement) =>
                  placement.leftWeight ==
                  BalanceScalePuzzle._heaviestWeightIndex(weights),
            ) ==
            (value == 1),
      BalanceClueKind.lightestOnRight =>
        placements.any(
              (BalancePlacement placement) =>
                  placement.rightWeight ==
                  BalanceScalePuzzle._lightestWeightIndex(weights),
            ) ==
            (value == 1),
    };
  }

  String text({required bool english}) {
    return switch (kind) {
      BalanceClueKind.leftLoad =>
        english
            ? 'All left pans carry $value g in total.'
            : 'Sol kefelerin toplam yükü $value g olmalı.',
      BalanceClueKind.brassOnLeft =>
        english
            ? '$value brass weight${value == 1 ? '' : 's'} belong on the left.'
            : 'Sol kefelerde tam $value pirinç ağırlık bulunmalı.',
      BalanceClueKind.porcelainOnLeft =>
        english
            ? '$value porcelain weight${value == 1 ? '' : 's'} belong on the left.'
            : 'Sol kefelerde tam $value porselen ağırlık bulunmalı.',
      BalanceClueKind.slateOnLeft =>
        english
            ? '$value slate weight${value == 1 ? '' : 's'} belong on the left.'
            : 'Sol kefelerde tam $value taş ağırlık bulunmalı.',
      BalanceClueKind.oddMassOnLeft =>
        english
            ? '$value left-side weights have an odd mass.'
            : 'Sol kefelerde kütlesi tek sayı olan $value ağırlık bulunmalı.',
      BalanceClueKind.heavyOnLeft =>
        english
            ? '$value weights of at least $threshold g belong on the left.'
            : 'En az $threshold g olan ağırlıklardan $value tanesi solda olmalı.',
      BalanceClueKind.lightOnLeft =>
        english
            ? '$value weights of at most $threshold g belong on the left.'
            : 'En çok $threshold g olan ağırlıklardan $value tanesi solda olmalı.',
      BalanceClueKind.firstStationsLoad =>
        english
            ? 'The first two balances together carry $value g.'
            : 'İlk iki terazideki ağırlıkların toplamı $value g olmalı.',
      BalanceClueKind.alternatingLeftRemainder =>
        english
            ? 'Alternating left-pan loads leave remainder $value when divided by 5.'
            : 'Sıralı sol kefe yüklerinin 5 ile bölümünden kalan $value olmalı.',
      BalanceClueKind.heaviestOnLeft =>
        english
            ? (value == 1
                  ? 'The heaviest weight is on a left pan.'
                  : 'The heaviest weight is not on a left pan.')
            : (value == 1
                  ? 'En ağır ağırlık sol kefelerden birinde olmalı.'
                  : 'En ağır ağırlık sol kefelerden birinde olmamalı.'),
      BalanceClueKind.lightestOnRight =>
        english
            ? (value == 1
                  ? 'The lightest weight is on a right pan.'
                  : 'The lightest weight is not on a right pan.')
            : (value == 1
                  ? 'En hafif ağırlık sağ kefelerden birinde olmalı.'
                  : 'En hafif ağırlık sağ kefelerden birinde olmamalı.'),
    };
  }
}

class BalanceScalePuzzle {
  static const int maximumUniqueCases = 300;
  static const List<String> stationLetters = <String>[
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
  ];
  static final Map<int, BalanceScalePuzzle> _cache =
      <int, BalanceScalePuzzle>{};

  const BalanceScalePuzzle({
    required this.level,
    required this.localStage,
    required this.stations,
    required this.weights,
    required this.extraClues,
    required this.solution,
  });

  final int level;
  final int localStage;
  final List<BalanceStation> stations;
  final List<BalanceWeight> weights;
  final List<BalanceGlobalClue> extraClues;
  final List<BalancePlacement> solution;

  int get stationCount => stations.length;

  String get difficultyTier => switch (localStage) {
    <= 6 => 'MASTERY',
    <= 8 => 'ADVANCED',
    _ => 'EXPERT',
  };

  String get boardSignature =>
      '${weights.map((BalanceWeight weight) => weight.signature).join('|')}#${stations.map((BalanceStation station) => station.signature).join('|')}#${extraClues.map((BalanceGlobalClue clue) => clue.signature).join('|')}';

  static int stageForLevel(int level) => ((level - 1) % 10) + 1;

  static int stationCountForStage(int stage) => switch (stage) {
    <= 3 => 3,
    <= 6 => 4,
    <= 8 => 5,
    9 => 6,
    _ => 7,
  };

  static int supportClueCountForStage(int stage) => switch (stage) {
    1 => 3,
    2 => 2,
    3 => 1,
    4 => 3,
    5 => 2,
    6 => 1,
    7 => 2,
    8 => 1,
    9 => 1,
    _ => 0,
  };

  static BalanceScalePuzzle forLevel(int level) {
    if (level < 1 || level > maximumUniqueCases) {
      throw RangeError.range(level, 1, maximumUniqueCases, 'level');
    }
    return _cache.putIfAbsent(level, () => _generate(level));
  }

  bool get hasUniqueSolution => solve().length == 1;

  bool isSolved(List<BalancePlacement> placements) {
    if (placements.length != stationCount) return false;
    final List<int> used = <int>[
      for (final BalancePlacement placement in placements) placement.leftWeight,
      for (final BalancePlacement placement in placements)
        placement.rightWeight,
    ];
    if (used.length != weights.length ||
        used.toSet().length != weights.length ||
        used.any((int id) => id < 0 || id >= weights.length)) {
      return false;
    }
    for (int index = 0; index < stationCount; index++) {
      if (!_stationMatches(stations[index], placements[index])) return false;
    }
    return extraClues.every(
      (BalanceGlobalClue clue) => clue.matches(weights, placements),
    );
  }

  List<List<BalancePlacement>> solve({int limit = 2}) {
    final List<List<_BalancePair>> candidates =
        List<List<_BalancePair>>.generate(
          stationCount,
          (int stationIndex) => <_BalancePair>[
            for (int left = 0; left < weights.length; left++)
              for (int right = 0; right < weights.length; right++)
                if (left != right &&
                    _stationMatches(
                      stations[stationIndex],
                      BalancePlacement(leftWeight: left, rightWeight: right),
                    ))
                  _BalancePair(left: left, right: right),
          ],
          growable: false,
        );
    if (candidates.any((List<_BalancePair> pairs) => pairs.isEmpty)) {
      return const <List<BalancePlacement>>[];
    }

    final List<List<BalancePlacement>> results = <List<BalancePlacement>>[];
    final List<BalancePlacement?> current = List<BalancePlacement?>.filled(
      stationCount,
      null,
    );
    final int allUsedMask = (1 << weights.length) - 1;
    final int? targetLeftLoad = extraClues
        .where(
          (BalanceGlobalClue clue) => clue.kind == BalanceClueKind.leftLoad,
        )
        .firstOrNull
        ?.value;

    void search(int usedMask, int depth, int currentLeftLoad) {
      if (results.length >= limit) return;
      if (depth == stationCount) {
        if (usedMask != allUsedMask) return;
        final List<BalancePlacement> placements = current
            .cast<BalancePlacement>()
            .toList(growable: false);
        if (extraClues.every(
          (BalanceGlobalClue clue) => clue.matches(weights, placements),
        )) {
          results.add(placements);
        }
        return;
      }

      int nextStation = -1;
      List<_BalancePair>? availableForNext;
      for (int station = 0; station < stationCount; station++) {
        if (current[station] != null) continue;
        final List<_BalancePair> available = candidates[station]
            .where((_BalancePair pair) {
              final int pairMask = (1 << pair.left) | (1 << pair.right);
              return (usedMask & pairMask) == 0;
            })
            .toList(growable: false);
        if (available.isEmpty) return;
        if (availableForNext == null ||
            available.length < availableForNext.length) {
          nextStation = station;
          availableForNext = available;
          if (available.length == 1) break;
        }
      }

      for (final _BalancePair pair in availableForNext!) {
        final int nextLoad = currentLeftLoad + weights[pair.left].mass;
        if (targetLeftLoad != null) {
          final int remainingStations = stationCount - depth - 1;
          final List<int> unusedMasses = <int>[
            for (int id = 0; id < weights.length; id++)
              if (((usedMask | (1 << pair.left) | (1 << pair.right)) &
                      (1 << id)) ==
                  0)
                weights[id].mass,
          ]..sort();
          if (unusedMasses.length < remainingStations * 2) continue;
          final int minimumLeft = unusedMasses
              .take(remainingStations)
              .fold<int>(0, (int sum, int mass) => sum + mass);
          final int maximumLeft = unusedMasses.reversed
              .take(remainingStations)
              .fold<int>(0, (int sum, int mass) => sum + mass);
          if (nextLoad + minimumLeft > targetLeftLoad ||
              nextLoad + maximumLeft < targetLeftLoad) {
            continue;
          }
        }

        current[nextStation] = BalancePlacement(
          leftWeight: pair.left,
          rightWeight: pair.right,
        );
        search(
          usedMask | (1 << pair.left) | (1 << pair.right),
          depth + 1,
          nextLoad,
        );
        current[nextStation] = null;
        if (results.length >= limit) return;
      }
    }

    search(0, 0, 0);
    return results;
  }

  bool _stationMatches(BalanceStation station, BalancePlacement placement) {
    final BalanceWeight left = weights[placement.leftWeight];
    final BalanceWeight right = weights[placement.rightWeight];
    final bool materialMatches = switch (station.pairRule) {
      BalancePairRule.sameMaterial => left.material == right.material,
      BalancePairRule.mixedMaterial => left.material != right.material,
    };
    return left.mass - right.mass == station.leftMinusRight && materialMatches;
  }

  static BalanceScalePuzzle _generate(int level) {
    final int localStage = stageForLevel(level);
    final int stationCount = stationCountForStage(localStage);
    final int weightCount = stationCount * 2;
    final int massLimit = switch (localStage) {
      <= 3 => 24,
      <= 6 => 32,
      <= 8 => 40,
      9 => 48,
      _ => 56,
    };
    final int supportCount = supportClueCountForStage(localStage);

    for (int attempt = 0; attempt < 900; attempt++) {
      final math.Random random = ContentSeed.randomFor(
        gameId: 'balance_scale',
        level: level,
        attempt: attempt,
      );
      final List<int> masses = <int>[];
      while (masses.length < weightCount) {
        final int mass = 1 + random.nextInt(massLimit);
        if (!masses.contains(mass)) masses.add(mass);
      }
      final List<BalanceWeight> weights = List<BalanceWeight>.generate(
        weightCount,
        (int index) => BalanceWeight(
          id: index,
          mass: masses[index],
          material: BalanceMaterial
              .values[random.nextInt(BalanceMaterial.values.length)],
        ),
        growable: false,
      );
      final List<int> ids = List<int>.generate(
        weightCount,
        (int index) => index,
      );
      _shuffle(ids, random);
      final List<BalancePlacement> solution = <BalancePlacement>[
        for (int station = 0; station < stationCount; station++)
          BalancePlacement(
            leftWeight: ids[station * 2],
            rightWeight: ids[station * 2 + 1],
          ),
      ];
      final List<BalanceStation> stations = List<BalanceStation>.generate(
        stationCount,
        (int index) {
          final BalancePlacement pair = solution[index];
          final BalanceWeight left = weights[pair.leftWeight];
          final BalanceWeight right = weights[pair.rightWeight];
          return BalanceStation(
            index: index,
            leftMinusRight: left.mass - right.mass,
            pairRule: left.material == right.material
                ? BalancePairRule.sameMaterial
                : BalancePairRule.mixedMaterial,
          );
        },
        growable: false,
      );
      final List<BalanceGlobalClue> extras = _globalClueCandidates(
        weights,
        solution,
        massLimit,
      );
      _shuffle(extras, random);
      final List<BalanceGlobalClue> selectedExtras = extras
          .take(supportCount)
          .toList(growable: false);
      final BalanceScalePuzzle puzzle = BalanceScalePuzzle(
        level: level,
        localStage: localStage,
        stations: List<BalanceStation>.unmodifiable(stations),
        weights: List<BalanceWeight>.unmodifiable(weights),
        extraClues: List<BalanceGlobalClue>.unmodifiable(selectedExtras),
        solution: List<BalancePlacement>.unmodifiable(solution),
      );
      if (puzzle.isSolved(solution) && puzzle.solve().length == 1) {
        return puzzle;
      }
    }
    throw StateError(
      'Could not generate a unique balance puzzle for level $level.',
    );
  }

  static List<BalanceGlobalClue> _globalClueCandidates(
    List<BalanceWeight> weights,
    List<BalancePlacement> solution,
    int massLimit,
  ) {
    final List<BalanceWeight> left = solution
        .map((BalancePlacement placement) => weights[placement.leftWeight])
        .toList(growable: false);
    final int leftTotal = left.fold<int>(
      0,
      (int total, BalanceWeight weight) => total + weight.mass,
    );
    final int median = (massLimit + 1) ~/ 2;
    final int alternating = solution.indexed.fold<int>(
      0,
      (int total, (int index, BalancePlacement placement) item) =>
          total +
          (item.$1.isEven
              ? weights[item.$2.leftWeight].mass
              : -weights[item.$2.leftWeight].mass),
    );
    final int firstStationsMass = solution
        .take(2)
        .fold<int>(
          0,
          (int total, BalancePlacement placement) =>
              total +
              weights[placement.leftWeight].mass +
              weights[placement.rightWeight].mass,
        );
    return <BalanceGlobalClue>[
      BalanceGlobalClue(kind: BalanceClueKind.leftLoad, value: leftTotal),
      for (final BalanceMaterial material in BalanceMaterial.values)
        BalanceGlobalClue(
          kind: switch (material) {
            BalanceMaterial.brass => BalanceClueKind.brassOnLeft,
            BalanceMaterial.porcelain => BalanceClueKind.porcelainOnLeft,
            BalanceMaterial.slate => BalanceClueKind.slateOnLeft,
          },
          value: left
              .where((BalanceWeight weight) => weight.material == material)
              .length,
        ),
      BalanceGlobalClue(
        kind: BalanceClueKind.oddMassOnLeft,
        value: left.where((BalanceWeight weight) => weight.mass.isOdd).length,
      ),
      BalanceGlobalClue(
        kind: BalanceClueKind.heavyOnLeft,
        value: left
            .where((BalanceWeight weight) => weight.mass >= median)
            .length,
        threshold: median,
      ),
      BalanceGlobalClue(
        kind: BalanceClueKind.lightOnLeft,
        value: left
            .where((BalanceWeight weight) => weight.mass <= median)
            .length,
        threshold: median,
      ),
      BalanceGlobalClue(
        kind: BalanceClueKind.firstStationsLoad,
        value: firstStationsMass,
      ),
      BalanceGlobalClue(
        kind: BalanceClueKind.alternatingLeftRemainder,
        value: ((alternating % 5 + 5) % 5),
      ),
      BalanceGlobalClue(
        kind: BalanceClueKind.heaviestOnLeft,
        value:
            solution.any(
              (BalancePlacement placement) =>
                  placement.leftWeight == _heaviestWeightIndex(weights),
            )
            ? 1
            : 0,
      ),
      BalanceGlobalClue(
        kind: BalanceClueKind.lightestOnRight,
        value:
            solution.any(
              (BalancePlacement placement) =>
                  placement.rightWeight == _lightestWeightIndex(weights),
            )
            ? 1
            : 0,
      ),
    ];
  }

  static int _heaviestWeightIndex(List<BalanceWeight> weights) => weights
      .reduce((BalanceWeight a, BalanceWeight b) => a.mass > b.mass ? a : b)
      .id;

  static int _lightestWeightIndex(List<BalanceWeight> weights) => weights
      .reduce((BalanceWeight a, BalanceWeight b) => a.mass < b.mass ? a : b)
      .id;

  static void _shuffle<T>(List<T> values, math.Random random) {
    for (int index = values.length - 1; index > 0; index--) {
      final int swap = random.nextInt(index + 1);
      final T value = values[index];
      values[index] = values[swap];
      values[swap] = value;
    }
  }
}

class _BalancePair {
  const _BalancePair({required this.left, required this.right});

  final int left;
  final int right;
}
