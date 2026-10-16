import 'dart:math' as math;

enum SignalGlyph { sun, wave, leaf, spark }

extension SignalGlyphLabel on SignalGlyph {
  String label(bool english) => switch (this) {
    SignalGlyph.sun => english ? 'SUN' : 'GÜNEŞ',
    SignalGlyph.wave => english ? 'WAVE' : 'DALGA',
    SignalGlyph.leaf => english ? 'LEAF' : 'YAPRAK',
    SignalGlyph.spark => english ? 'SPARK' : 'KIVILCIM',
  };
}

class SignalPairScenario {
  SignalPairScenario._({
    required this.level,
    required this.seed,
    required this.siteId,
    required this.siteTr,
    required this.siteEn,
    required this.signalCount,
    required this.targetRoute,
    required this.panelWiring,
    required this.interference,
  });

  static const int campaignLevels = 20;
  static const int practiceCases = 300;
  static const List<(String, String, String)> _sites =
      <(String, String, String)>[
        ('aurora_station', 'Aurora İstasyonu', 'Aurora Station'),
        ('cobalt_forge', 'Kobalt Dökümhanesi', 'Cobalt Forge'),
        ('quiet_orbit', 'Sessiz Yörünge', 'Quiet Orbit'),
        ('amber_network', 'Kehribar Ağı', 'Amber Network'),
        ('tidal_vault', 'Gelgit Kasası', 'Tidal Vault'),
        ('north_array', 'Kuzey Dizisi', 'North Array'),
        ('glass_relay', 'Cam Röle', 'Glass Relay'),
        ('ember_dome', 'Kor Kubbesi', 'Ember Dome'),
        ('blue_foundry', 'Mavi Atölye', 'Blue Foundry'),
        ('orbit_garden', 'Yörünge Bahçesi', 'Orbit Garden'),
        ('silver_canyon', 'Gümüş Kanyon', 'Silver Canyon'),
        ('neon_port', 'Neon Limanı', 'Neon Port'),
        ('lumen_archive', 'Işık Arşivi', 'Lumen Archive'),
        ('mistral_ridge', 'Mistral Sırtı', 'Mistral Ridge'),
        ('jade_turbine', 'Yeşim Türbini', 'Jade Turbine'),
        ('echo_basin', 'Yankı Havzası', 'Echo Basin'),
        ('solstice_hub', 'Gündönümü Merkezi', 'Solstice Hub'),
        ('coral_silo', 'Mercan Silosu', 'Coral Silo'),
        ('polar_lattice', 'Kutup Örgüsü', 'Polar Lattice'),
        ('last_beacon', 'Son İşaret Feneri', 'Last Beacon'),
      ];

  final int level;
  final int seed;
  final String siteId;
  final String siteTr;
  final String siteEn;
  final int signalCount;
  final List<SignalGlyph> targetRoute;
  final List<SignalGlyph> panelWiring;
  final int interference;

  String signature() => <String>[
    siteId,
    signalCount.toString(),
    targetRoute.map((SignalGlyph signal) => signal.name).join(','),
    panelWiring.map((SignalGlyph signal) => signal.name).join(','),
    interference.toString(),
  ].join('|');

  static SignalPairScenario forLevel(int level) {
    if (level < 1 || level > campaignLevels) {
      throw RangeError.range(level, 1, campaignLevels, 'level');
    }
    final int length = 3 + ((level - 1) * 5 ~/ (campaignLevels - 1));
    return _create(
      level: level,
      siteIndex: level - 1,
      variant: (level - 1) % 15,
      signalCount: length,
      seed: 2801 + level * 331,
    );
  }

  static SignalPairScenario forPractice(int index) {
    if (index < 1 || index > practiceCases) {
      throw RangeError.range(index, 1, practiceCases, 'index');
    }
    final int offset = index - 1;
    return _create(
      level: campaignLevels,
      siteIndex: offset % _sites.length,
      variant: offset ~/ _sites.length,
      signalCount: 4 + (offset % 5),
      seed: 37001 + index * 65537,
    );
  }

  static SignalPairScenario _create({
    required int level,
    required int siteIndex,
    required int variant,
    required int signalCount,
    required int seed,
  }) {
    final math.Random random = math.Random(seed);
    final (String id, String titleTr, String titleEn) = _sites[siteIndex];
    final List<SignalGlyph> route = <SignalGlyph>[];
    for (int step = 0; step < signalCount; step++) {
      final List<SignalGlyph> options = SignalGlyph.values
          .where((SignalGlyph signal) => route.isEmpty || signal != route.last)
          .toList(growable: false);
      route.add(options[random.nextInt(options.length)]);
    }
    final List<SignalGlyph> wiring = SignalGlyph.values.toList()
      ..shuffle(random);
    bool isIdentity = true;
    for (int index = 0; index < wiring.length; index++) {
      if (wiring[index].index != index) {
        isIdentity = false;
        break;
      }
    }
    if (isIdentity) {
      wiring.add(wiring.removeAt(0));
    }
    return SignalPairScenario._(
      level: level,
      seed: seed,
      siteId: id,
      siteTr: titleTr,
      siteEn: titleEn,
      signalCount: signalCount,
      targetRoute: List<SignalGlyph>.unmodifiable(route),
      panelWiring: List<SignalGlyph>.unmodifiable(wiring),
      interference: variant,
    );
  }
}
