import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/catalog/domain/studio_game_catalog.dart';
import '../../l10n/app_localizations.dart';
import '../../services/game_audio_service.dart';
import '../../theme/studio_visuals.dart';
import '../shared/game_audio_profile.dart';
import '../shared/parkur_game_kit.dart';
import '../shared/studio_game_session.dart';
import '../shared/studio_game_skin.dart';
import 'aquarium_engine.dart';
import 'aquarium_scenario.dart';

class TideglassAquariumGamePage extends StatelessWidget {
  const TideglassAquariumGamePage({super.key});

  static const int totalCases = AquariumScenario.campaignLevels;
  static const int totalStars = totalCases * 3;
  static final List<ParkurLevelSpec> _levels = List<ParkurLevelSpec>.generate(
    totalCases,
    (int index) {
      final int level = index + 1;
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Habitat ${level.toString().padLeft(2, '0')}',
        titleEn: 'Habitat ${level.toString().padLeft(2, '0')}',
        subtitleTr: switch (level) {
          <= 3 => 'Türü, filtreyi ve sıcaklığı dengeli başlat.',
          <= 6 => 'Canlı uyumu, bitki ve uygun tabanı birlikte düşün.',
          7 || 8 => 'İleri: biyolojik yükü filtre ve oksijenle dengele.',
          9 || 10 => 'Uzman: hassas türleri doğru komşularla yerleştir.',
          <= 16 => 'Usta: kalabalık tankta su değerlerini birlikte koru.',
          _ => 'Final: çoklu tür, grup ihtiyacı ve dar filtre payı.',
        },
        subtitleEn: switch (level) {
          <= 3 => 'Start with a balanced species, filter and temperature.',
          <= 6 => 'Balance compatibility, plants and the correct substrate.',
          7 || 8 => 'Advanced: offset bioload with filtration and oxygen.',
          9 || 10 => 'Expert: pair sensitive species with safe tank mates.',
          <= 16 => 'Master: protect water values in a busy habitat.',
          _ => 'Final: mixed species, school sizes and tight filter margins.',
        },
        difficulty: switch (level) {
          <= 3 => 'KURULUM',
          <= 6 => 'HABİTAT',
          7 || 8 => 'İLERİ',
          9 || 10 => 'UZMAN',
          <= 16 => 'USTA',
          _ => 'FİNAL',
        },
        icon: Icons.water_rounded,
      );
    },
    growable: false,
  );

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.fun);
    return ParkurLevelHub(
      gameId: 'tideglass_aquarium',
      progressPrefix: 'tideglass_aquarium',
      titleTr: 'Deniz Camı Akvaryumu',
      titleEn: 'Tideglass Aquarium',
      taglineTr: 'Canlı uyumu • Su değerleri • Huzurlu habitat',
      taglineEn: 'Compatible life • Stable water • Calm habitat',
      accent: skin.accent,
      icon: Icons.water_rounded,
      levels: _levels,
      dailyCourseMode: false,
      playBuilder:
          (
            BuildContext context,
            ParkurLevelSpec level,
            int previousBestScore,
            int? competitionLayoutCode,
            bool competitionMode,
          ) => TideglassAquariumPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class TideglassAquariumPlayPage extends StatefulWidget {
  const TideglassAquariumPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<TideglassAquariumPlayPage> createState() =>
      _TideglassAquariumPlayPageState();
}

class _TideglassAquariumPlayPageState extends State<TideglassAquariumPlayPage> {
  static const Color _accent = Color(0xFF428C98);
  static const Color _ink = Color(0xFF34494C);
  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.fun,
  );
  late AquariumScenario _scenario;
  late AquariumEngine _engine;
  late StudioGameSession _session;
  AquariumSpecies? _extraSpecies;
  bool _ready = false;
  bool _finished = false;
  bool _english = false;
  String _feedback = '';

  @override
  void initState() {
    super.initState();
    unawaited(_audioProfile.preload(_audio));
    unawaited(_prepareTank());
  }

  Future<void> _prepareTank() async {
    AquariumScenario scenario = AquariumScenario.forLevel(widget.level.number);
    try {
      final SharedPreferencesAsync prefs = SharedPreferencesAsync();
      final String key =
          'tideglass_aquarium_level_${widget.level.number}_visits';
      final int visits = await prefs.getInt(key) ?? 0;
      if (visits > 0) {
        final int practice =
            await prefs.getInt('tideglass_aquarium_practice_index') ?? 0;
        if (practice < AquariumScenario.practiceTankChallenges) {
          await prefs.setInt('tideglass_aquarium_practice_index', practice + 1);
          scenario = AquariumScenario.forPractice(practice + 1);
        }
      }
      await prefs.setInt(key, visits + 1);
    } catch (_) {
      // Keep the authored habitat usable when device preferences are unavailable.
    }
    if (!mounted) return;
    _scenario = scenario;
    _engine = AquariumEngine(scenario: scenario);
    _session = StudioGameSession(
      level: widget.level.number,
      seed: scenario.seed,
    )..start();
    setState(() {
      _feedback = _english
          ? 'Match the habitat brief. Fish welfare is explained, never color-only.'
          : 'Habitat brief’ini karşıla. Canlı durumu yalnız renkle anlatılmaz.';
      _ready = true;
    });
  }

  List<AquariumSpecies> get _shownSpecies => <AquariumSpecies>[
    ..._scenario.requiredPopulations.keys,
    if (_extraSpecies != null &&
        !_scenario.requiredPopulations.containsKey(_extraSpecies))
      _extraSpecies!,
  ];

  void _setCount(AquariumSpecies species, int value) {
    if (_finished) return;
    setState(() {
      _engine.setPopulation(species, value);
      _feedback = _english
          ? 'Tank population updated · review the group and filter load.'
          : 'Canlı sayısı güncellendi · grup ve filtre yükünü kontrol et.';
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.menu, gain: .12));
  }

  void _setEquipment(VoidCallback change) {
    if (_finished) return;
    setState(() {
      change();
      _feedback = _english
          ? 'Equipment adjusted · check the visible water readings.'
          : 'Ekipman ayarlandı · görünür su göstergelerini kontrol et.';
    });
  }

  int get _stars {
    final int score = _engine.evaluate().score;
    if (score >= 94) return 3;
    if (score >= 83) return 2;
    return 1;
  }

  Future<void> _reviewHabitat() async {
    if (_finished) return;
    final AquariumEvaluation result = _engine.evaluate();
    if (!result.canSubmit) {
      final List<String> needs = <String>[];
      if (result.speciesCorrect < result.speciesTotal) {
        needs.add(_english ? 'stocking' : 'canlı sayısı');
      }
      if (!result.compatible) {
        needs.add(_english ? 'compatibility' : 'tür uyumu');
      }
      if (!result.temperatureSafe) {
        needs.add(_english ? 'temperature' : 'sıcaklık');
      }
      if (!result.volumeSafe) {
        needs.add(_english ? 'tank volume' : 'tank hacmi');
      }
      if (result.filterCapacity < result.waterLoad) {
        needs.add(_english ? 'filter' : 'filtre');
      }
      if (!result.oxygenSafe) {
        needs.add(_english ? 'oxygen' : 'oksijen');
      }
      if (!result.plantsSafe) {
        needs.add(_english ? 'plants' : 'bitki');
      }
      if (!result.lightingSafe) {
        needs.add(_english ? 'lighting' : 'ışık');
      }
      if (!result.substrateSafe) {
        needs.add(_english ? 'substrate' : 'taban');
      }
      setState(
        () => _feedback = _english
            ? 'Habitat check: ${needs.join(' · ')}'
            : 'Habitat kontrolü: ${needs.join(' · ')}',
      );
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .18));
      return;
    }
    _finished = true;
    final int stars = _stars;
    _session.complete(
      stars: stars,
      action: widget.level.number < TideglassAquariumGamePage.totalCases
          ? StudioResultAction.next
          : StudioResultAction.map,
    );
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.accepted, gain: .38),
    );
    unawaited(_audioProfile.play(
      _audio,
      GameAudioEvent.levelComplete,
      levelNumber: widget.level.number,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 140));
    if (!mounted) return;
    final ParkurResultAction? action = await showParkurResultDialog(
      context: context,
      accent: _accent,
      titleTr: 'HABİTAT DENGELENDİ',
      titleEn: 'HABITAT IN BALANCE',
      detailTr:
          '${_engine.fishCount} canlı · filtre ${result.filterCapacity}/${result.waterLoad} · O₂ ${result.oxygen.toStringAsFixed(1)}',
      detailEn:
          '${_engine.fishCount} animals · filter ${result.filterCapacity}/${result.waterLoad} · O₂ ${result.oxygen.toStringAsFixed(1)}',
      stars: stars,
      score: result.score * 100,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < TideglassAquariumGamePage.totalCases,
    );
    if (!mounted) return;
    final StudioResultAction next = switch (action) {
      ParkurResultAction.replay => StudioResultAction.replay,
      ParkurResultAction.next => StudioResultAction.next,
      _ => StudioResultAction.map,
    };
    Navigator.of(context).pop(
      StudioGameResult.completed(
        score: result.score * 100,
        stars: stars,
        action: next,
      ).toParkurResult(),
    );
  }

  @override
  Widget build(BuildContext context) {
    _english = context.l10n.isEnglish;
    if (!_ready) {
      return Scaffold(
        backgroundColor: StudioVisuals.canvas,
        appBar: AppBar(
          title: Text(_english ? 'TIDEGLASS AQUARIUM' : 'DENİZ CAMI AKVARYUMU'),
        ),
        body: const Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    final AquariumEvaluation evaluation = _engine.evaluate();
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        title: Text(
          _english
              ? 'HABITAT · ${widget.level.number}'
              : 'HABİTAT · ${widget.level.number}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
          child: Column(
            children: <Widget>[
              _buildHud(evaluation),
              const SizedBox(height: 4),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1.92,
                    child: CustomPaint(
                      key: const ValueKey<String>('tideglass_tank_scene'),
                      painter: _AquariumPainter(
                        scenario: _scenario,
                        engine: _engine,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
              _buildSpeciesControls(),
              const SizedBox(height: 3),
              _buildEquipmentControls(),
              const SizedBox(height: 3),
              SizedBox(
                height: 24,
                child: Center(
                  child: Text(
                    _feedback,
                    key: const ValueKey<String>('tideglass_feedback'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 9,
                      color: StudioVisuals.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton.icon(
                  key: const ValueKey<String>('tideglass_review'),
                  onPressed: _finished ? null : _reviewHabitat,
                  style: FilledButton.styleFrom(
                    backgroundColor: evaluation.canSubmit ? _accent : _ink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.spa_rounded),
                  label: Text(
                    _english ? 'REVIEW HABITAT' : 'HABİTATI DEĞERLENDİR',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: .3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHud(AquariumEvaluation evaluation) {
    final bool stable = evaluation.score >= 75;
    return Container(
      height: 35,
      key: const ValueKey<String>('tideglass_hud'),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFE1E9E8)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.air_rounded, size: 17, color: _accent),
          const SizedBox(width: 5),
          Text(
            'O₂ ${evaluation.oxygen.toStringAsFixed(1)}',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
          ),
          const Spacer(),
          Text(
            '${_engine.fishCount}/${_scenario.totalRequiredFish} ${_english ? 'FISH' : 'CANLI'}',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10),
          ),
          const SizedBox(width: 8),
          Icon(
            stable ? Icons.check_circle_rounded : Icons.water_drop_rounded,
            color: stable ? _accent : const Color(0xFFB78352),
            size: 17,
          ),
        ],
      ),
    );
  }

  Widget _buildSpeciesControls() {
    final List<AquariumSpecies> species = _shownSpecies;
    final double width = MediaQuery.sizeOf(context).width - 20;
    final double cardWidth = (width - 6) / 2;
    return SizedBox(
      height: 94,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 4,
        runSpacing: 3,
        children: <Widget>[
          for (final AquariumSpecies animal in species)
            _speciesCard(animal, cardWidth),
          if (_extraSpecies == null)
            SizedBox(
              width: cardWidth,
              height: 44,
              child: PopupMenuButton<AquariumSpecies>(
                key: const ValueKey<String>('tideglass_add_species'),
                tooltip: _english ? 'Add another species' : 'Başka tür ekle',
                onSelected: (AquariumSpecies item) =>
                    setState(() => _extraSpecies = item),
                itemBuilder: (BuildContext context) => AquariumSpecies.values
                    .where(
                      (AquariumSpecies item) =>
                          !_scenario.requiredPopulations.containsKey(item),
                    )
                    .map(
                      (AquariumSpecies item) => PopupMenuItem<AquariumSpecies>(
                        value: item,
                        child: Text(item.label(_english)),
                      ),
                    )
                    .toList(growable: false),
                child: const _SmallControl(
                  icon: Icons.add_rounded,
                  label: 'ADD SPECIES',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _speciesCard(AquariumSpecies species, double width) {
    final int count = _engine.populations[species] ?? 0;
    final int target = _scenario.requiredPopulations[species] ?? 0;
    final bool correct = count == target;
    return Container(
      width: width,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: correct ? const Color(0xFFD8E7DF) : const Color(0xFFE4E0D8),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              species.label(_english),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900),
            ),
          ),
          IconButton(
            key: ValueKey<String>('tideglass_minus_${species.name}'),
            tooltip: _english
                ? 'Remove one ${species.label(true)}'
                : 'Bir ${species.label(false)} azalt',
            visualDensity: VisualDensity.compact,
            onPressed: count > 0 ? () => _setCount(species, count - 1) : null,
            icon: const Icon(Icons.remove_circle_outline_rounded, size: 17),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 31, minHeight: 38),
          ),
          Text(
            '$count/$target',
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
          ),
          IconButton(
            key: ValueKey<String>('tideglass_plus_${species.name}'),
            tooltip: _english
                ? 'Add one ${species.label(true)}'
                : 'Bir ${species.label(false)} ekle',
            visualDensity: VisualDensity.compact,
            onPressed: count < 12 ? () => _setCount(species, count + 1) : null,
            icon: const Icon(Icons.add_circle_outline_rounded, size: 17),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 31, minHeight: 38),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentControls() {
    return SizedBox(
      height: 86,
      child: Column(
        children: <Widget>[
          Expanded(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _equipmentCard(
                    Icons.filter_alt_rounded,
                    _english ? 'FILTER' : 'FİLTRE',
                    '${_engine.filterTier}',
                    onTap: () => _setEquipment(
                      () => _engine.filterTier = _engine.filterTier % 4 + 1,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _equipmentCard(
                    Icons.grass_rounded,
                    _english ? 'PLANTS' : 'BİTKİ',
                    '${_engine.plants}',
                    onTap: () => _setEquipment(
                      () => _engine.plants = _engine.plants >= 5
                          ? 0
                          : _engine.plants + 1,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _equipmentCard(
                    Icons.air_rounded,
                    _english ? 'AERATOR' : 'HAVA',
                    _engine.aerator
                        ? (_english ? 'ON' : 'AÇIK')
                        : (_english ? 'OFF' : 'KAPALI'),
                    onTap: () =>
                        _setEquipment(() => _engine.aerator = !_engine.aerator),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Expanded(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _equipmentCard(
                    Icons.thermostat_rounded,
                    _english ? 'TEMP' : 'ISI',
                    '${_engine.temperature}°',
                    onTap: () => _setEquipment(
                      () => _engine.temperature = _engine.temperature >= 28
                          ? 18
                          : _engine.temperature + 1,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _equipmentCard(
                    Icons.light_mode_rounded,
                    _english ? 'LIGHT' : 'IŞIK',
                    '${_engine.lightTier}',
                    onTap: () => _setEquipment(
                      () => _engine.lightTier = _engine.lightTier >= 3
                          ? 0
                          : _engine.lightTier + 1,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _equipmentCard(
                    Icons.grain_rounded,
                    _english ? 'SUBSTRATE' : 'TABAN',
                    _engine.substrate.label(_english),
                    onTap: () => _setEquipment(
                      () => _engine.substrate =
                          AquariumSubstrate.values[(_engine.substrate.index +
                                  1) %
                              AquariumSubstrate.values.length],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _equipmentCard(
    IconData icon,
    String title,
    String value, {
    required VoidCallback onTap,
  }) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(9),
    child: InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: _finished ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFFE3E9E6)),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 15, color: _accent),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 7,
                      color: StudioVisuals.muted,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9,
                      color: _ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.swap_vert_rounded,
              size: 13,
              color: StudioVisuals.muted,
            ),
          ],
        ),
      ),
    ),
  );
}

class _SmallControl extends StatelessWidget {
  const _SmallControl({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFDCE6E3)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(icon, size: 16, color: const Color(0xFF428C98)),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
}

class _AquariumPainter extends CustomPainter {
  const _AquariumPainter({required this.scenario, required this.engine});
  final AquariumScenario scenario;
  final AquariumEngine engine;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    final RRect frame = RRect.fromRectAndRadius(
      bounds.deflate(3),
      const Radius.circular(14),
    );
    canvas.drawRRect(frame, Paint()..color = const Color(0xFFB8D8D8));
    final Rect water = bounds.deflate(8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(water, const Radius.circular(11)),
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[
            Color(0xFFD5F0EE),
            Color(0xFF86C6C8),
            Color(0xFF76B4B9),
          ],
        ).createShader(water),
    );
    final double floorY = water.bottom - 14;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(water.left, floorY, water.width, 17),
        const Radius.circular(5),
      ),
      Paint()
        ..color = scenario.substrate == AquariumSubstrate.pebble
            ? const Color(0xFFC5B69D)
            : const Color(0xFFD7C8AA),
    );
    for (int i = 0; i < engine.plants; i++) {
      final double x =
          water.left + 15 + (i * 31.0) % math.max(1, water.width - 30);
      final double height = 17 + (i % 3) * 7.0;
      final Paint stem = Paint()
        ..color = const Color(0xFF658E70)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(x, floorY + 2),
        Offset(x - 3, floorY - height),
        stem,
      );
      canvas.drawLine(
        Offset(x, floorY - 3),
        Offset(x + 7, floorY - height * .75),
        stem,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x - 3, floorY - height),
          width: 8,
          height: 4,
        ),
        Paint()..color = const Color(0xFF86AA88),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x + 7, floorY - height * .75),
          width: 8,
          height: 4,
        ),
        Paint()..color = const Color(0xFF94B496),
      );
    }
    int fishNumber = 0;
    for (final MapEntry<AquariumSpecies, int> entry
        in engine.populations.entries) {
      for (int i = 0; i < entry.value; i++) {
        final double x =
            water.left +
            24 +
            ((fishNumber * 37) % math.max(1, water.width - 48));
        final double y =
            water.top +
            22 +
            ((fishNumber * 19) % math.max(1, floorY - water.top - 43));
        _drawFish(canvas, Offset(x, y), entry.key, fishNumber.isOdd);
        fishNumber++;
      }
    }
    for (int i = 0; i < 5; i++) {
      final double x = water.right - 25 - i * 13.0;
      final double y =
          water.top + 13 + (i * 23.0) % math.max(1, water.height - 32);
      canvas.drawCircle(
        Offset(x, y),
        2 + (i % 2),
        Paint()..color = Colors.white.withValues(alpha: .48),
      );
    }
    final TextPainter label = TextPainter(
      text: TextSpan(
        text: '${scenario.liters} L  ·  ${scenario.targetTemperature}°C',
        style: const TextStyle(
          color: Color(0xFF446E72),
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: .4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, Offset(water.left + 7, water.top + 5));
    final Paint glassLine = Paint()
      ..color = Colors.white.withValues(alpha: .35)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(water.left + 6, water.top + 6),
      Offset(water.left + water.width * .36, water.top + 6),
      glassLine,
    );
  }

  void _drawFish(
    Canvas canvas,
    Offset center,
    AquariumSpecies species,
    bool reverse,
  ) {
    final Color body = HSLColor.fromAHSL(
      1,
      species.iconHue.toDouble(),
      .56,
      .54,
    ).toColor();
    canvas.save();
    if (reverse) {
      canvas.translate(center.dx, center.dy);
      canvas.scale(-1, 1);
      canvas.translate(-center.dx, -center.dy);
    }
    final Path tail = Path()
      ..moveTo(center.dx - 7, center.dy)
      ..lineTo(center.dx - 13, center.dy - 5)
      ..lineTo(center.dx - 13, center.dy + 5)
      ..close();
    canvas.drawPath(tail, Paint()..color = body.withValues(alpha: .82));
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 18, height: 10),
      Paint()..color = body,
    );
    canvas.drawCircle(
      Offset(center.dx + 5, center.dy - 1),
      1.1,
      Paint()..color = const Color(0xFF283B3D),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AquariumPainter oldDelegate) =>
      oldDelegate.scenario.signature != scenario.signature ||
      oldDelegate.engine.fishCount != engine.fishCount ||
      oldDelegate.engine.plants != engine.plants ||
      oldDelegate.engine.temperature != engine.temperature ||
      oldDelegate.engine.filterTier != engine.filterTier ||
      oldDelegate.engine.lightTier != engine.lightTier ||
      oldDelegate.engine.aerator != engine.aerator ||
      oldDelegate.engine.substrate != engine.substrate ||
      oldDelegate.engine.populations.toString() !=
          engine.populations.toString();
}
