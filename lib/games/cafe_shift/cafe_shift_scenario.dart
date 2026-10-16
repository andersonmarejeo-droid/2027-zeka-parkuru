import 'dart:math' as math;

import '../shared/content_seed.dart';

enum CafeProduct { espresso, latte, tea, toastie, cocoa }

enum CafeStation { grinder, espresso, kettle, grill, milk, finishing }

enum CafeModifier { none, oatMilk, doubleShot, extraToast, sugarFree }

class CafeOrderSpec {
  const CafeOrderSpec({
    required this.id,
    required this.product,
    required this.modifier,
    required this.route,
    required this.stageSeconds,
    required this.patienceSeconds,
    required this.tip,
  });

  final int id;
  final CafeProduct product;
  final CafeModifier modifier;
  final List<CafeStation> route;
  final List<double> stageSeconds;
  final double patienceSeconds;
  final int tip;

  String get signature =>
      '$id:${product.name}:${modifier.name}:${route.map((CafeStation station) => station.name).join(',')}:${stageSeconds.map((double seconds) => seconds.toStringAsFixed(3)).join(',')}:${patienceSeconds.toStringAsFixed(2)}:$tip';
}

class CafeShiftScenario {
  const CafeShiftScenario._({
    required this.level,
    required this.seed,
    required this.orders,
    required this.activeLimit,
    required this.arrivalInterval,
    required this.allowedMisses,
    required this.startingStock,
  });

  static const int campaignLevels = 20;
  static const int practiceShifts = 300;

  final int level;
  final int seed;
  final List<CafeOrderSpec> orders;
  final int activeLimit;
  final double arrivalInterval;
  final int allowedMisses;
  final int startingStock;

  String get signature => <String>[
    '$level:$seed:$activeLimit:${arrivalInterval.toStringAsFixed(3)}:$allowedMisses:$startingStock',
    orders.map((CafeOrderSpec order) => order.signature).join('|'),
  ].join('::');

  static CafeShiftScenario forLevel(int level) {
    if (level < 1 || level > campaignLevels) {
      throw RangeError.range(level, 1, campaignLevels, 'level');
    }
    return _build(
      level,
      ContentSeed.forLevel(gameId: 'cafe_shift_campaign', level: level),
    );
  }

  static CafeShiftScenario forPracticeShift(int index) {
    if (index < 1 || index > practiceShifts) {
      throw RangeError.range(index, 1, practiceShifts, 'index');
    }
    return _build(
      1 + ((index - 1) % campaignLevels),
      ContentSeed.forLevel(gameId: 'cafe_shift_practice', level: index),
    );
  }

  static CafeShiftScenario _build(int level, int seed) {
    final math.Random random = math.Random(seed);
    final int orderCount = 4 + (level - 1) ~/ 3;
    final List<CafeProduct> products = <CafeProduct>[
      CafeProduct.espresso,
      CafeProduct.latte,
      CafeProduct.tea,
      if (level >= 3) CafeProduct.toastie,
      if (level >= 6) CafeProduct.cocoa,
    ];
    final List<CafeOrderSpec> orders = <CafeOrderSpec>[
      for (int index = 0; index < orderCount; index++)
        _order(index, level, products[random.nextInt(products.length)], random),
    ];
    return CafeShiftScenario._(
      level: level,
      seed: seed,
      orders: List<CafeOrderSpec>.unmodifiable(orders),
      activeLimit: level >= 12 ? 3 : 2,
      arrivalInterval: (6.8 - level * .13).clamp(3.8, 6.7).toDouble(),
      allowedMisses: level >= 17 ? 1 : 2,
      startingStock: orderCount + 1,
    );
  }

  static CafeOrderSpec _order(
    int id,
    int level,
    CafeProduct product,
    math.Random random,
  ) {
    final CafeModifier candidateModifier = level < 4
        ? CafeModifier.none
        : switch (random.nextInt(level >= 11 ? 5 : 4)) {
            0 => CafeModifier.oatMilk,
            1 when level >= 8 => CafeModifier.doubleShot,
            2 when level >= 8 => CafeModifier.extraToast,
            3 when level >= 12 => CafeModifier.sugarFree,
            _ => CafeModifier.none,
          };
    final CafeModifier modifier = switch (candidateModifier) {
      CafeModifier.oatMilk
          when product == CafeProduct.latte || product == CafeProduct.cocoa =>
        candidateModifier,
      CafeModifier.doubleShot
          when product == CafeProduct.espresso ||
              product == CafeProduct.latte =>
        candidateModifier,
      CafeModifier.extraToast when product == CafeProduct.toastie =>
        candidateModifier,
      CafeModifier.sugarFree
          when product == CafeProduct.tea || product == CafeProduct.cocoa =>
        candidateModifier,
      _ => CafeModifier.none,
    };
    final List<CafeStation> route = switch (product) {
      CafeProduct.espresso => <CafeStation>[
        CafeStation.grinder,
        CafeStation.espresso,
        CafeStation.finishing,
      ],
      CafeProduct.latte => <CafeStation>[
        CafeStation.grinder,
        CafeStation.espresso,
        CafeStation.milk,
      ],
      CafeProduct.tea => <CafeStation>[
        CafeStation.kettle,
        CafeStation.finishing,
      ],
      CafeProduct.toastie => <CafeStation>[
        CafeStation.grill,
        CafeStation.finishing,
      ],
      CafeProduct.cocoa => <CafeStation>[
        CafeStation.kettle,
        CafeStation.milk,
        CafeStation.finishing,
      ],
    };
    if (modifier == CafeModifier.doubleShot) {
      route.insert(
        route.indexOf(CafeStation.espresso) + 1,
        CafeStation.espresso,
      );
    }
    if (modifier == CafeModifier.extraToast && product == CafeProduct.toastie) {
      route.insert(route.length - 1, CafeStation.grill);
    }
    final double pressure = 1 + level * .015;
    final List<double> durations = <double>[
      for (final CafeStation station in route)
        (_baseDuration(station) * pressure * (.88 + random.nextDouble() * .24))
            .clamp(.55, 3.4)
            .toDouble(),
    ];
    return CafeOrderSpec(
      id: id,
      product: product,
      modifier: modifier,
      route: List<CafeStation>.unmodifiable(route),
      stageSeconds: List<double>.unmodifiable(durations),
      patienceSeconds: (47 - level * .43 + random.nextDouble() * 4)
          .clamp(35, 51)
          .toDouble(),
      tip: 8 + level + random.nextInt(9),
    );
  }

  static double _baseDuration(CafeStation station) => switch (station) {
    CafeStation.grinder => 1.05,
    CafeStation.espresso => 1.65,
    CafeStation.kettle => 1.45,
    CafeStation.grill => 2.0,
    CafeStation.milk => .88,
    CafeStation.finishing => .72,
  };
}
