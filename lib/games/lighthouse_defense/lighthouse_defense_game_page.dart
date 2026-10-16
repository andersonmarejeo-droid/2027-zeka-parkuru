import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/catalog/domain/studio_game_catalog.dart';
import '../../l10n/app_localizations.dart';
import '../../services/game_audio_service.dart';
import '../../theme/studio_visuals.dart';
import '../shared/game_audio_profile.dart';
import '../shared/parkur_game_kit.dart';
import '../shared/studio_game_session.dart';
import '../shared/studio_game_skin.dart';
import 'lighthouse_engine.dart';
import 'lighthouse_scenario.dart';

class LighthouseDefenseGamePage extends StatelessWidget {
  const LighthouseDefenseGamePage({super.key});

  static const int totalCases = LighthouseScenario.campaignLevels;
  static const int totalStars = totalCases * 3;

  static final List<ParkurLevelSpec> _levels = List<ParkurLevelSpec>.generate(
    totalCases,
    (int index) {
      final int level = index + 1;
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Nöbet ${level.toString().padLeft(2, '0')}',
        titleEn: 'Watch ${level.toString().padLeft(2, '0')}',
        subtitleTr: switch (level) {
          <= 3 => 'Patika menzilini kapat; ilk dalgayı az kuleyle durdur.',
          <= 6 => 'Yavaşlatmayı zırh delen taretle eşleştir.',
          7 || 8 => 'İleri: hava birimi ve uzun kıvrımlı rota geliyor.',
          9 || 10 => 'Uzman: ağır hedefte kule önceliğini değiştir.',
          <= 16 => 'Usta: sıçrama hasarı ve sınırlı kıyı enerjisini planla.',
          _ => 'Final: zırhlı koruyucuyu dalga ekonomisiyle karşıla.',
        },
        subtitleEn: switch (level) {
          <= 3 => 'Cover the path and stop the first wave with a lean defense.',
          <= 6 => 'Pair slow effects with armour-piercing towers.',
          7 || 8 => 'Advanced: air units and long switchbacks arrive.',
          9 || 10 => 'Expert: change target priority against heavy enemies.',
          <= 16 => 'Master: plan splash damage and scarce coastal energy.',
          _ => 'Final: answer the armoured guardian with wave economy.',
        },
        difficulty: switch (level) {
          <= 3 => 'KEŞİF',
          <= 6 => 'DALGA',
          7 || 8 => 'İLERİ',
          9 || 10 => 'UZMAN',
          <= 16 => 'USTA',
          _ => 'FİNAL',
        },
        icon: Icons.light_rounded,
      );
    },
    growable: false,
  );

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.fun);
    return ParkurLevelHub(
      gameId: 'lighthouse_defense',
      progressPrefix: 'lighthouse_defense',
      titleTr: 'Fener Savunması',
      titleEn: 'Lighthouse Defense',
      taglineTr: 'Kur • Öncelik ver • Dalgayı karşıla',
      taglineEn: 'Build • Prioritise • Hold the wave',
      accent: skin.accent,
      icon: Icons.light_rounded,
      levels: _levels,
      dailyCourseMode: false,
      playBuilder:
          (
            BuildContext context,
            ParkurLevelSpec level,
            int previousBestScore,
            int? competitionLayoutCode,
            bool competitionMode,
          ) => LighthouseDefensePlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class LighthouseDefensePlayPage extends StatefulWidget {
  const LighthouseDefensePlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<LighthouseDefensePlayPage> createState() =>
      _LighthouseDefensePlayPageState();
}

class _LighthouseDefensePlayPageState extends State<LighthouseDefensePlayPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const Color _accent = Color(0xFF388E83);
  static const Color _amber = Color(0xFFD19B57);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.fun,
  );
  late final Ticker _ticker;
  late LighthouseScenario _scenario;
  late LighthouseDefenseEngine _engine;
  late StudioGameSession _session;
  Duration _lastTick = Duration.zero;
  LighthouseTowerType _selectedType = LighthouseTowerType.ballista;
  int? _selectedPad;
  bool _ready = false;
  bool _paused = false;
  bool _finished = false;
  bool _english = false;
  String _feedback = '';

  int get _score =>
      (_engine.totalKills * 145 +
              _engine.lives * 60 +
              _engine.coins +
              _engine.totalShots)
          .clamp(0, 10000000)
          .toInt();

  int get _stars {
    if (_engine.lives >= 11 && _engine.totalEscapes == 0) return 3;
    if (_engine.lives >= 4) return 2;
    return 1;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_tick);
    unawaited(_audioProfile.preload(_audio));
    unawaited(_prepareMap());
  }

  Future<void> _prepareMap() async {
    LighthouseScenario scenario = LighthouseScenario.forLevel(
      widget.level.number,
    );
    try {
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      final String visitKey =
          'lighthouse_defense_level_${widget.level.number}_visits';
      final int visits = await preferences.getInt(visitKey) ?? 0;
      if (visits > 0) {
        final int index =
            await preferences.getInt('lighthouse_defense_practice_index') ?? 0;
        if (index < LighthouseScenario.practiceMaps) {
          final int next = index + 1;
          await preferences.setInt('lighthouse_defense_practice_index', next);
          scenario = LighthouseScenario.forPracticeMap(next);
        }
      }
      await preferences.setInt(visitKey, visits + 1);
    } catch (_) {
      // Keep the authored map playable if local storage is unavailable.
    }
    if (!mounted) return;
    _scenario = scenario;
    _engine = LighthouseDefenseEngine(scenario: scenario);
    _session = StudioGameSession(
      level: widget.level.number,
      seed: scenario.seed,
    )..start();
    setState(() => _ready = true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (_ready && !_paused && !_finished) _setPaused(true);
    } else if (state == AppLifecycleState.resumed && _paused && !_finished) {
      _setPaused(false);
    }
  }

  void _setPaused(bool value) {
    if (!_ready || _finished || _paused == value) return;
    setState(() => _paused = value);
    if (value) {
      _session.pause();
      _ticker.stop();
    } else {
      _session.resume();
      _lastTick = Duration.zero;
      if (_engine.waveRunning) _ticker.start();
    }
    unawaited(_audio.play(GameSound.uiClick, gain: .22));
  }

  void _tick(Duration elapsed) {
    if (!_ready || _paused || _finished || !_engine.waveRunning) return;
    final double raw = (elapsed - _lastTick).inMicroseconds / 1000000;
    _lastTick = elapsed;
    if (raw <= 0) return;
    final LighthouseStepResult result = _engine.step(
      raw.clamp(0, .05).toDouble(),
    );
    if (result.shots > 0) {
      _session.recordAccepted(points: result.shots);
    }
    if (result.kills > 0) {
      _session.recordAccepted(points: result.kills * 80);
      unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .12));
    }
    if (result.escapes > 0) {
      _session.recordMistake();
      _feedback = _english
          ? 'A SHIP REACHED THE LIGHTHOUSE · REPLAN THE NEXT WAVE'
          : 'BİR DÜŞMAN FENERİ GEÇTİ · SONRAKİ DALGAYI YENİDEN KUR';
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .18));
    }
    if (result.waveCleared) {
      _ticker.stop();
      _feedback = _english
          ? 'WAVE HELD · SPEND THE REWARD BEFORE THE NEXT SIGNAL'
          : 'DALGA DURDURULDU · SONRAKİ SİNYALDEN ÖNCE ÖDÜLÜ KULLAN';
      unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .2));
    }
    setState(() {});
    if (result.victory) unawaited(_finishMap());
    if (result.failed) unawaited(_offerRetry());
  }

  void _selectType(LighthouseTowerType type) {
    if (_engine.waveRunning || _paused) return;
    setState(() {
      _selectedType = type;
      _selectedPad = null;
      _feedback = _english
          ? '${_typeName(type, true)} SELECTED · TAP AN EMPTY BUILD PAD'
          : '${_typeName(type, false)} SEÇİLDİ · BOŞ YAPI NOKTASINA DOKUN';
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.menu, gain: .18));
  }

  void _tapMap(Offset local, Size size) {
    if (!_ready ||
        _paused ||
        _finished ||
        _engine.waveRunning ||
        size.isEmpty) {
      return;
    }
    int nearest = -1;
    double distance = double.infinity;
    for (int index = 0; index < _scenario.pads.length; index++) {
      final Offset center = Offset(
        _scenario.pads[index].dx * size.width,
        _scenario.pads[index].dy * size.height,
      );
      final double current = (center - local).distance;
      if (current < distance) {
        nearest = index;
        distance = current;
      }
    }
    if (nearest < 0 || distance > math.min(size.width, size.height) * .075) {
      return;
    }
    if (_engine.towers[nearest] == null) {
      final bool built = _engine.buildTower(nearest, _selectedType);
      setState(() {
        _selectedPad = built ? nearest : null;
        _feedback = built
            ? (_english
                  ? '${_typeName(_selectedType, true)} BUILT · SET ITS TARGET PRIORITY'
                  : '${_typeName(_selectedType, false)} KURULDU · HEDEF ÖNCELİĞİNİ AYARLA')
            : (_english
                  ? 'NOT ENOUGH COINS FOR THAT BUILD'
                  : 'BU KULE İÇİN YETERLİ ALTIN YOK');
      });
      unawaited(
        _audioProfile.play(
          _audio,
          built ? GameAudioEvent.accepted : GameAudioEvent.rejected,
          gain: .2,
        ),
      );
    } else {
      setState(() => _selectedPad = nearest);
      unawaited(_audioProfile.play(_audio, GameAudioEvent.menu, gain: .15));
    }
  }

  void _upgradeSelected() {
    final int? pad = _selectedPad;
    if (pad == null) return;
    final bool upgraded = _engine.upgradeTower(pad);
    setState(() {
      _feedback = upgraded
          ? (_english
                ? 'TOWER UPGRADED · DAMAGE AND RANGE INCREASED'
                : 'KULE GELİŞTİRİLDİ · HASAR VE MENZİL ARTTI')
          : (_english
                ? 'UPGRADE NEEDS MORE COINS OR IS ALREADY AT TIER III'
                : 'YÜKSELTME İÇİN ALTIN YETMİYOR YA DA KULE III. KADEMEDE');
    });
    unawaited(
      _audioProfile.play(
        _audio,
        upgraded ? GameAudioEvent.accepted : GameAudioEvent.rejected,
        gain: .2,
      ),
    );
  }

  void _cyclePriority() {
    final int? pad = _selectedPad;
    if (pad == null) return;
    final bool changed = _engine.cycleTargetRule(pad);
    if (!changed) return;
    final LighthouseTargetRule rule = _engine.towers[pad]!.targetRule;
    setState(
      () => _feedback = _english
          ? 'TARGET PRIORITY · ${_priorityName(rule, true)}'
          : 'HEDEF ÖNCELİĞİ · ${_priorityName(rule, false)}',
    );
  }

  void _startWave() {
    if (!_engine.startWave()) {
      setState(
        () => _feedback = _english
            ? 'BUILD AT LEAST ONE TOWER BEFORE THE WAVE'
            : 'DALGADAN ÖNCE EN AZ BİR KULE KUR',
      );
      return;
    }
    _lastTick = Duration.zero;
    setState(
      () => _feedback = _english
          ? 'WAVE ${_engine.waveIndex + 1} INBOUND'
          : '${_engine.waveIndex + 1}. DALGA GELİYOR',
    );
    _ticker.start();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .2),
    );
  }

  void _pulse() {
    final LighthouseStepResult result = _engine.usePulse();
    if (!result.pulseUsed) return;
    setState(
      () => _feedback = _english
          ? 'BEACON PULSE · ENEMIES SLOWED'
          : 'FENER DARBESİ · DÜŞMANLAR YAVAŞLATILDI',
    );
    _session.recordAccepted(points: result.kills * 100);
    unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .24));
    _audio.hapticLight();
  }

  Future<void> _offerRetry() async {
    if (_finished || !mounted) return;
    _finished = true;
    _ticker.stop();
    _session.fail();
    final bool retry =
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: Text(_english ? 'THE LIGHT WENT DARK' : 'FENER SÖNDÜ'),
            content: Text(
              _english
                  ? 'Rebuild around the long bends, tune a tower toward the toughest ship, then signal the next wave.'
                  : 'Uzun kıvrımları kapsayacak biçimde kuleleri yeniden kur; ağır hedefe öncelik verip sonraki dalgayı başlat.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(_english ? 'MAP' : 'HARİTA'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(dialogContext, true),
                icon: const Icon(Icons.restart_alt_rounded),
                label: Text(_english ? 'RETRY' : 'YENİDEN DENE'),
              ),
            ],
          ),
        ) ??
        false;
    if (!mounted) return;
    if (retry) {
      _engine = LighthouseDefenseEngine(scenario: _scenario);
      _session = StudioGameSession(
        level: widget.level.number,
        seed: _scenario.seed,
      )..start();
      _selectedPad = null;
      _finished = false;
      _feedback = '';
      setState(() {});
    } else {
      Navigator.of(context)
          .pop(StudioGameResult.failed(score: _score).toParkurResult());
    }
  }

  Future<void> _finishMap() async {
    if (_finished || !mounted) return;
    _finished = true;
    _ticker.stop();
    _session.complete(
      stars: _stars,
      action: widget.level.number < LighthouseDefenseGamePage.totalCases
          ? StudioResultAction.next
          : StudioResultAction.map,
    );
    unawaited(_audioProfile.play(
      _audio,
      GameAudioEvent.levelComplete,
      levelNumber: widget.level.number,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 140));
    if (!mounted) return;
    final ParkurResultAction? result = await showParkurResultDialog(
      context: context,
      accent: _accent,
      titleTr: 'KIYI KORUNDU',
      titleEn: 'COAST HELD',
      detailTr:
          '${_engine.totalKills} düşman durduruldu · ${_engine.lives} fener dayanımı kaldı',
      detailEn:
          '${_engine.totalKills} ships stopped · ${_engine.lives} lighthouse integrity left',
      stars: _stars,
      score: _score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < LighthouseDefenseGamePage.totalCases,
    );
    if (!mounted) return;
    final StudioResultAction action = switch (result) {
      ParkurResultAction.replay => StudioResultAction.replay,
      ParkurResultAction.next => StudioResultAction.next,
      _ => StudioResultAction.map,
    };
    Navigator.of(context).pop(
      StudioGameResult.completed(
        score: _score,
        stars: _stars,
        action: action,
      ).toParkurResult(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _english = context.l10n.isEnglish;
    if (!_ready) {
      return Scaffold(
        backgroundColor: StudioVisuals.canvas,
        appBar: AppBar(
          title: Text(_english ? 'LIGHTHOUSE DEFENSE' : 'FENER SAVUNMASI'),
        ),
        body: const Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    final bool building =
        !_engine.waveRunning && !_engine.victory && !_engine.failed;
    final LighthouseTower? selected = _selectedPad == null
        ? null
        : _engine.towers[_selectedPad!];
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _english
              ? 'LIGHTHOUSE · WATCH ${widget.level.number}'
              : 'FENER SAVUNMASI · ${widget.level.number}. NÖBET',
          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900),
        ),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('lighthouse_defense_pause'),
            tooltip: _paused
                ? (_english ? 'Resume' : 'Devam et')
                : (_english ? 'Pause' : 'Duraklat'),
            onPressed: () => _setPaused(!_paused),
            icon: Icon(
              _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            ),
          ),
          const SizedBox(width: 5),
        ],
      ),
      body: Stack(
        children: <Widget>[
          SafeArea(
            top: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 780),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(9, 5, 9, 8),
                  child: Column(
                    children: <Widget>[
                      _LighthouseHud(engine: _engine, english: _english),
                      const SizedBox(height: 5),
                      Expanded(
                        child: LayoutBuilder(
                          builder:
                              (BuildContext context, BoxConstraints limits) {
                                final double width = math.min(
                                  limits.maxWidth,
                                  720,
                                );
                                final double height = math.min(
                                  limits.maxHeight,
                                  width * .68,
                                );
                                final Size mapSize = Size(width, height);
                                return Center(
                                  child: SizedBox(
                                    key: const ValueKey<String>(
                                      'lighthouse_defense_map',
                                    ),
                                    width: width,
                                    height: height,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTapDown: (TapDownDetails details) =>
                                          _tapMap(
                                            details.localPosition,
                                            mapSize,
                                          ),
                                      child: CustomPaint(
                                        painter: _LighthouseMapPainter(
                                          engine: _engine,
                                          selectedPad: _selectedPad,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                        ),
                      ),
                      SizedBox(
                        height: 19,
                        child: Center(
                          child: Text(
                            _feedback.isNotEmpty
                                ? _feedback
                                : (_english
                                      ? 'TAP A BUILD PAD · TOWERS FIRE AUTOMATICALLY'
                                      : 'YAPI NOKTASINA DOKUN · KULELER OTOMATİK ATEŞ EDER'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF51656A),
                              fontSize: 7.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .08,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (building && selected != null)
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _TowerMiniAction(
                                key: const ValueKey<String>(
                                  'lighthouse_upgrade',
                                ),
                                icon: Icons.upgrade_rounded,
                                label: _english
                                    ? 'UPGRADE · ${_engine.upgradePrice(selected)}'
                                    : 'YÜKSELT · ${_engine.upgradePrice(selected)}',
                                onTap: _upgradeSelected,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: _TowerMiniAction(
                                key: const ValueKey<String>(
                                  'lighthouse_priority',
                                ),
                                icon: Icons.filter_alt_rounded,
                                label: _priorityName(
                                  selected.targetRule,
                                  _english,
                                ).toUpperCase(),
                                onTap: _cyclePriority,
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: <Widget>[
                            for (final LighthouseTowerType type
                                in LighthouseTowerType.values)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  child: _TowerTypeCard(
                                    type: type,
                                    selected: _selectedType == type,
                                    price: LighthouseDefenseEngine
                                        .buildPrices[type]!,
                                    english: _english,
                                    enabled: building,
                                    onTap: () => _selectType(type),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      const SizedBox(height: 5),
                      SizedBox(
                        height: 44,
                        width: double.infinity,
                        child: FilledButton.icon(
                          key: const ValueKey<String>(
                            'lighthouse_defense_wave',
                          ),
                          onPressed: building
                              ? _startWave
                              : (_engine.waveRunning && _engine.pulseCharges > 0
                                    ? _pulse
                                    : null),
                          icon: Icon(
                            building
                                ? Icons.sailing_rounded
                                : Icons.flash_on_rounded,
                            size: 17,
                          ),
                          label: Text(
                            building
                                ? (_engine.waveIndex == 0
                                      ? (_english
                                            ? 'SIGNAL WAVE 1'
                                            : 'DALGAYI BAŞLAT')
                                      : (_english
                                            ? 'SIGNAL WAVE ${_engine.waveIndex + 1}'
                                            : '${_engine.waveIndex + 1}. DALGAYI BAŞLAT'))
                                : (_english
                                      ? 'BEACON PULSE · ${_engine.pulseCharges} LEFT'
                                      : 'FENER DARBESİ · ${_engine.pulseCharges} HAK'),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .25,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: building ? _accent : _amber,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_paused)
            _LighthousePauseOverlay(
              english: _english,
              onResume: () => _setPaused(false),
            ),
        ],
      ),
    );
  }
}

class _LighthouseHud extends StatelessWidget {
  const _LighthouseHud({required this.engine, required this.english});
  final LighthouseDefenseEngine engine;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey<String>('lighthouse_defense_hud'),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: StudioVisuals.surface,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: StudioVisuals.line),
      boxShadow: StudioVisuals.softShadow,
    ),
    child: Row(
      children: <Widget>[
        _HudMetric(
          icon: Icons.favorite_rounded,
          value: '${engine.lives}',
          label: english ? 'INTEGRITY' : 'DAYANIM',
          color: const Color(0xFF528F82),
        ),
        const Spacer(),
        _HudMetric(
          icon: Icons.monetization_on_rounded,
          value: '${engine.coins}',
          label: english ? 'COINS' : 'ALTIN',
          color: const Color(0xFFD09B57),
        ),
        const Spacer(),
        Column(
          children: <Widget>[
            Text(
              english
                  ? 'WAVE ${engine.waveIndex + (engine.waveRunning ? 1 : 0)} / ${engine.scenario.waves.length}'
                  : 'DALGA ${engine.waveIndex + (engine.waveRunning ? 1 : 0)} / ${engine.scenario.waves.length}',
              style: const TextStyle(
                color: Color(0xFF3B5057),
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              english
                  ? '${engine.towerCount} TOWERS · ${engine.enemies.length} ON PATH'
                  : '${engine.towerCount} KULE · ${engine.enemies.length} YOLDA',
              style: const TextStyle(
                color: StudioVisuals.muted,
                fontSize: 7.2,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _HudMetric extends StatelessWidget {
  const _HudMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Icon(icon, size: 15, color: color),
      const SizedBox(width: 4),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: StudioVisuals.muted,
              fontSize: 6.4,
              fontWeight: FontWeight.w900,
              letterSpacing: .35,
            ),
          ),
        ],
      ),
    ],
  );
}

class _TowerTypeCard extends StatelessWidget {
  const _TowerTypeCard({
    required this.type,
    required this.selected,
    required this.price,
    required this.english,
    required this.enabled,
    required this.onTap,
  });
  final LighthouseTowerType type;
  final bool selected;
  final int price;
  final bool english;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? const Color(0xFFE4F1EC) : Colors.white,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 55,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF66A89B) : const Color(0xFFDCE5E0),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(_towerIcon(type), size: 15, color: _towerColor(type)),
            const SizedBox(height: 2),
            Text(
              _typeName(type, english),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF35464F),
                fontSize: 7.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              '$price',
              style: const TextStyle(
                color: Color(0xFFBA8751),
                fontSize: 7,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _TowerMiniAction extends StatelessWidget {
  const _TowerMiniAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 38,
    child: OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 7.5, fontWeight: FontWeight.w900),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        foregroundColor: const Color(0xFF41585E),
        side: const BorderSide(color: Color(0xFFD6E0DA)),
      ),
    ),
  );
}

class _LighthousePauseOverlay extends StatelessWidget {
  const _LighthousePauseOverlay({
    required this.english,
    required this.onResume,
  });
  final bool english;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: ColoredBox(
      color: const Color(0xA5273939),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.pause_circle_filled_rounded,
                color: Color(0xFF388E83),
                size: 38,
              ),
              const SizedBox(height: 7),
              Text(
                english ? 'COASTAL WATCH PAUSED' : 'KIYI NÖBETİ DURAKLATILDI',
                style: const TextStyle(
                  color: Color(0xFF35464F),
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 9),
              FilledButton(
                onPressed: onResume,
                child: Text(english ? 'RESUME' : 'DEVAM ET'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

String _typeName(LighthouseTowerType type, bool english) =>
    switch ((type, english)) {
      (LighthouseTowerType.ballista, true) => 'Ballista',
      (LighthouseTowerType.ballista, false) => 'Balista',
      (LighthouseTowerType.frost, true) => 'Frost',
      (LighthouseTowerType.frost, false) => 'Ayaz',
      (LighthouseTowerType.mortar, true) => 'Mortar',
      (LighthouseTowerType.mortar, false) => 'Havan',
    };

IconData _towerIcon(LighthouseTowerType type) => switch (type) {
  LighthouseTowerType.ballista => Icons.gps_fixed_rounded,
  LighthouseTowerType.frost => Icons.ac_unit_rounded,
  LighthouseTowerType.mortar => Icons.radio_button_checked_rounded,
};

Color _towerColor(LighthouseTowerType type) => switch (type) {
  LighthouseTowerType.ballista => const Color(0xFF4D8791),
  LighthouseTowerType.frost => const Color(0xFF789DB1),
  LighthouseTowerType.mortar => const Color(0xFFBC8259),
};

String _priorityName(LighthouseTargetRule rule, bool english) =>
    switch ((rule, english)) {
      (LighthouseTargetRule.first, true) => 'First',
      (LighthouseTargetRule.first, false) => 'Öndeki',
      (LighthouseTargetRule.last, true) => 'Last',
      (LighthouseTargetRule.last, false) => 'Sondaki',
      (LighthouseTargetRule.strongest, true) => 'Strongest',
      (LighthouseTargetRule.strongest, false) => 'En Güçlü',
    };

class _LighthouseMapPainter extends CustomPainter {
  const _LighthouseMapPainter({
    required this.engine,
    required this.selectedPad,
  });
  final LighthouseDefenseEngine engine;
  final int? selectedPad;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(23)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFDFECE7),
            Color(0xFFBFD9D2),
            Color(0xFF9FC4C2),
          ],
        ).createShader(bounds),
    );
    final math.Random texture = math.Random(engine.scenario.seed);
    for (int i = 0; i < 20; i++) {
      final Offset dot = Offset(
        texture.nextDouble() * size.width,
        texture.nextDouble() * size.height,
      );
      canvas.drawCircle(
        dot,
        1 + texture.nextDouble() * 2,
        Paint()..color = Colors.white.withValues(alpha: .12),
      );
    }
    final List<List<Offset>> routes = <List<Offset>>[
      engine.scenario.path,
      engine.scenario.alternatePath,
    ];
    for (final List<Offset> points in routes) {
      final Path route = Path();
      for (int index = 0; index < points.length; index++) {
        final Offset point = _map(points[index], size);
        if (index == 0) {
          route.moveTo(point.dx, point.dy);
        } else {
          route.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(
        route,
        Paint()
          ..color = const Color(0xFF35575C).withValues(alpha: .25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.height * .19
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.drawPath(
        route,
        Paint()
          ..color = const Color(0xFFDBD5C1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.height * .16
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.drawPath(
        route,
        Paint()
          ..color = const Color(0xFFEAE2CB)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.height * .125
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    for (int index = 0; index < engine.scenario.pads.length; index++) {
      final Offset center = _map(engine.scenario.pads[index], size);
      final double radius = math.min(size.width, size.height) * .055;
      canvas.drawCircle(
        center + Offset(0, radius * .34),
        radius * 1.16,
        Paint()
          ..color = const Color(0xFF34494B).withValues(alpha: .17)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = const RadialGradient(
            colors: <Color>[
              Color(0xFFFFFDF3),
              Color(0xFFD8BD8C),
              Color(0xFF99836A),
            ],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
      canvas.drawCircle(
        center,
        radius * .72,
        Paint()
          ..color = Colors.white.withValues(alpha: .58)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      if (selectedPad == index && engine.towers[index] != null) {
        canvas.drawCircle(
          center,
          radius * 1.42,
          Paint()
            ..color = const Color(0xFF318D7F).withValues(alpha: .58)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2,
        );
        final LighthouseTower tower = engine.towers[index]!;
        final double range = switch (tower.type) {
          LighthouseTowerType.ballista => .34 + tower.tier * .018,
          LighthouseTowerType.frost => .29 + tower.tier * .015,
          LighthouseTowerType.mortar => .40 + tower.tier * .018,
        };
        canvas.drawOval(
          Rect.fromCenter(
            center: center,
            width: range * size.width * 2,
            height: range * size.height * 2,
          ),
          Paint()
            ..color = const Color(0xFF40988C).withValues(alpha: .08)
            ..style = PaintingStyle.fill,
        );
      }
    }
    _drawLighthouse(
      canvas,
      _map(const Offset(.91, .51), size),
      size.height * .105,
    );
    for (int index = 0; index < engine.towers.length; index++) {
      final LighthouseTower? tower = engine.towers[index];
      if (tower != null) {
        _drawTower(
          canvas,
          _map(engine.scenario.pads[index], size),
          math.min(size.width, size.height) * .054,
          tower,
        );
      }
    }
    for (final LighthouseEnemyState enemy in engine.enemies) {
      _drawEnemy(
        canvas,
        _map(_positionAt(enemy.progress, enemy.spec.routeBranch), size),
        math.min(size.width, size.height) *
            (enemy.spec.kind == LighthouseEnemyKind.boss ? .045 : .027),
        enemy,
      );
    }
    _drawBeaconSweep(
      canvas,
      _map(const Offset(.91, .51), size),
      size.height * .105,
    );
  }

  void _drawLighthouse(Canvas canvas, Offset center, double radius) {
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, radius * 1.25),
        width: radius * 2.5,
        height: radius * .6,
      ),
      Paint()
        ..color = const Color(0xFF425B58).withValues(alpha: .2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    final Path base = Path()
      ..moveTo(center.dx - radius * .78, center.dy + radius)
      ..lineTo(center.dx - radius * .56, center.dy - radius * .68)
      ..lineTo(center.dx + radius * .56, center.dy - radius * .68)
      ..lineTo(center.dx + radius * .78, center.dy + radius)
      ..close();
    canvas.drawPath(
      base,
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[
            Color(0xFFF4F0E4),
            Color(0xFFB7C8BD),
            Color(0xFF839E96),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 1.5)),
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: center - Offset(0, radius * .72),
        width: radius * 1.5,
        height: radius * .28,
      ),
      Paint()..color = const Color(0xFFD28162),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center - Offset(0, radius * 1.05),
          width: radius * 1.32,
          height: radius * .42,
        ),
        Radius.circular(radius * .1),
      ),
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[Color(0xFFEAD8A7), Color(0xFFAA8659)],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center - Offset(0, radius * 1.05),
      radius * .18,
      Paint()..color = const Color(0xFFFFF1C5),
    );
    canvas.drawLine(
      center - Offset(radius * 1.05, radius * 1.15),
      center + Offset(radius * 1.8, radius * .18),
      Paint()
        ..color = const Color(0xFFFFF1C5).withValues(alpha: .13)
        ..strokeWidth = radius * 1.15,
    );
  }

  void _drawBeaconSweep(Canvas canvas, Offset center, double radius) {
    final Rect beam = Rect.fromCircle(center: center, radius: radius * 2.2);
    canvas.drawArc(
      beam,
      math.pi * 1.10,
      math.pi * .32,
      true,
      Paint()
        ..shader = const SweepGradient(
          colors: <Color>[
            Color(0x00FFF0C7),
            Color(0x66FFF0C7),
            Color(0x00FFF0C7),
          ],
          startAngle: 0,
          endAngle: math.pi * 2,
        ).createShader(beam),
    );
  }

  void _drawTower(
    Canvas canvas,
    Offset center,
    double radius,
    LighthouseTower tower,
  ) {
    final Color color = _towerColor(tower.type);
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, radius * .7),
        width: radius * 2.4,
        height: radius * .75,
      ),
      Paint()
        ..color = const Color(0xFF314548).withValues(alpha: .25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(
      center,
      radius * 1.12,
      Paint()..color = const Color(0xFFD7CAB0),
    );
    canvas.drawCircle(
      center,
      radius * .92,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.35, -.48),
          colors: <Color>[
            Color.lerp(color, Colors.white, .55)!,
            color,
            Color.lerp(color, const Color(0xFF233C42), .35)!,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center,
      radius * .45,
      Paint()..color = const Color(0xFFF3EBD9),
    );
    switch (tower.type) {
      case LighthouseTowerType.ballista:
        canvas.drawLine(
          center - Offset(0, radius * .68),
          center + Offset(0, radius * .7),
          Paint()
            ..color = const Color(0xFFF5F0E0)
            ..strokeWidth = radius * .15
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawLine(
          center - Offset(radius * .62, 0),
          center + Offset(radius * .62, 0),
          Paint()
            ..color = const Color(0xFFF5F0E0)
            ..strokeWidth = radius * .12,
        );
      case LighthouseTowerType.frost:
        for (int i = 0; i < 6; i++) {
          final double angle = i * math.pi / 3;
          canvas.drawLine(
            center,
            center + Offset(math.cos(angle), math.sin(angle)) * radius * .65,
            Paint()
              ..color = const Color(0xFFFAFFFF)
              ..strokeWidth = radius * .1,
          );
        }
      case LighthouseTowerType.mortar:
        canvas.drawCircle(
          center,
          radius * .56,
          Paint()..color = const Color(0xFFDEBA8C),
        );
        canvas.drawCircle(
          center,
          radius * .22,
          Paint()..color = const Color(0xFF5B5250),
        );
    }
    final TextPainter tier = TextPainter(
      text: TextSpan(
        text: '${tower.tier}',
        style: const TextStyle(
          color: Color(0xFF34454A),
          fontSize: 7,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tier.paint(canvas, center + Offset(radius * .63, radius * .48));
  }

  void _drawEnemy(
    Canvas canvas,
    Offset center,
    double radius,
    LighthouseEnemyState enemy,
  ) {
    final Color color = switch (enemy.spec.kind) {
      LighthouseEnemyKind.runner => const Color(0xFFC77D63),
      LighthouseEnemyKind.armored => const Color(0xFF78888A),
      LighthouseEnemyKind.glider => const Color(0xFF8296B3),
      LighthouseEnemyKind.brute => const Color(0xFF9B6E69),
      LighthouseEnemyKind.boss => const Color(0xFF875D75),
    };
    canvas.drawCircle(
      center + Offset(0, radius * .35),
      radius * 1.12,
      Paint()
        ..color = const Color(0xFF3B5151).withValues(alpha: .2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.4, -.45),
          colors: <Color>[
            Color.lerp(color, Colors.white, .5)!,
            color,
            Color.lerp(color, const Color(0xFF273B3E), .35)!,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center + Offset(-radius * .28, -radius * .08),
      radius * .09,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      center + Offset(radius * .28, -radius * .08),
      radius * .09,
      Paint()..color = Colors.white,
    );
    final double barWidth = radius * 2.2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center - Offset(0, radius * 1.4),
          width: barWidth,
          height: math.max(2, radius * .22),
        ),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF34494B).withValues(alpha: .5),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          center.dx - barWidth / 2,
          center.dy - radius * 1.51,
          barWidth * (enemy.health / enemy.spec.health).clamp(0, 1),
          math.max(2, radius * .18),
        ),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFFF2D79F),
    );
  }

  Offset _positionAt(double progress, int branch) {
    final List<Offset> path = branch == 0
        ? engine.scenario.path
        : engine.scenario.alternatePath;
    double routeLength = 0;
    for (int i = 1; i < path.length; i++) {
      routeLength += (path[i] - path[i - 1]).distance;
    }
    double remaining = routeLength * progress.clamp(0, 1).toDouble();
    for (int i = 1; i < path.length; i++) {
      final double segment = (path[i] - path[i - 1]).distance;
      if (remaining <= segment || i == path.length - 1) {
        return Offset.lerp(
          path[i - 1],
          path[i],
          (remaining / segment).clamp(0, 1).toDouble(),
        )!;
      }
      remaining -= segment;
    }
    return path.last;
  }

  Offset _map(Offset point, Size size) =>
      Offset(point.dx * size.width, point.dy * size.height);

  @override
  bool shouldRepaint(covariant _LighthouseMapPainter oldDelegate) => true;
}
