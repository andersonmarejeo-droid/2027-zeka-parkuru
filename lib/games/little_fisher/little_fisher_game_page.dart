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
import 'little_fisher_engine.dart';
import 'little_fisher_scenario.dart';

class LittleFisherGamePage extends StatelessWidget {
  const LittleFisherGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  static const int totalCases = LittleFisherScenario.maximumLevels;
  static const int totalStars = totalCases * 3;

  static final List<ParkurLevelSpec>
  _levels = List<ParkurLevelSpec>.generate(totalCases, (int index) {
    final int level = index + 1;
    final String tr = switch (level) {
      <= 3 => 'Balığın yemini ve yüzdüğü derinliği oku.',
      <= 6 => 'Sürüklenen akıntıya göre makarayı bırak; gerilimi ortada tut.',
      7 || 8 => 'İleri: derin ve yüzey akışları değişirken balığı yor.',
      9 => 'Uzman: 13 balığı dar gerilim bandında tek hata hakkıyla çek.',
      _ => 'Usta finali: 14 türü koparmadan, kaçırmadan tekneye al.',
    };
    final String en = switch (level) {
      <= 3 => 'Read the fish’s bait preference and swimming depth.',
      <= 6 => 'Ease the reel with the moving current and keep tension centred.',
      7 ||
      8 => 'Advanced: tire the fish while deep and surface currents shift.',
      9 => 'Expert: land 13 fish inside a narrow tension band with one miss.',
      _ => 'Master finale: bring 14 species aboard without a break or escape.',
    };
    return ParkurLevelSpec(
      number: level,
      titleTr: 'Akıntı Seferi ${level.toString().padLeft(2, '0')}',
      titleEn: 'Current Expedition ${level.toString().padLeft(2, '0')}',
      subtitleTr: tr,
      subtitleEn: en,
      difficulty: switch (level) {
        <= 3 => 'USTALAŞMA',
        <= 6 => 'DERİNLEŞME',
        7 || 8 => 'İLERİ',
        9 => 'UZMAN',
        _ => 'USTA',
      },
      icon: Icons.phishing_rounded,
    );
  }, growable: false);

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.fun);
    return ParkurLevelHub(
      gameId: 'little_fisher',
      progressPrefix: 'little_fisher',
      titleTr: 'Küçük Balıkçı',
      titleEn: 'Little Fisher',
      taglineTr: 'Yemi seç • Akıntıyı oku • Misina gerilimini koru',
      taglineEn: 'Choose bait • Read the flow • Keep the line safe',
      accent: skin.accent,
      icon: Icons.phishing_rounded,
      levels: _levels,
      dailyCourseMode: dailyCourseMode,
      competitionLevel: competitionLevel,
      competitionLayoutCode: competitionLayoutCode,
      playBuilder:
          (
            BuildContext context,
            ParkurLevelSpec level,
            int previousBestScore,
            int? competitionLayoutCode,
            bool competitionMode,
          ) => LittleFisherPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class LittleFisherPlayPage extends StatefulWidget {
  const LittleFisherPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<LittleFisherPlayPage> createState() => _LittleFisherPlayPageState();
}

class _LittleFisherPlayPageState extends State<LittleFisherPlayPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const Color _ink = Color(0xFF314B50);
  static const Color _accent = Color(0xFF438F91);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.fun,
  );
  late final Ticker _ticker;
  late LittleFisherScenario _scenario;
  late LittleFisherEngine _engine;
  late StudioGameSession _session;
  Duration _lastTick = Duration.zero;
  double _elapsed = 0;
  int _bait = 0;
  int _depth = 1;
  int _score = 0;
  bool _ready = false;
  bool _paused = false;
  bool _finished = false;
  bool _english = false;

  int get _stars {
    if (_engine.misses == 0 && _elapsed <= _scenario.goldTimeSeconds) return 3;
    if (_engine.misses <= 1) return 2;
    return 1;
  }

  String _fishName(int species) => _english
      ? const <String>['Perch', 'Pike', 'Carp', 'Trout'][species]
      : const <String>['Levrek', 'Turna', 'Sazan', 'Alabalık'][species];

  String _baitName(int bait) => _english
      ? const <String>['WORM', 'SPOON', 'FLY'][bait]
      : const <String>['SOLUCAN', 'KAŞIK', 'SİNEK'][bait];

  String _depthName(int depth) => _english
      ? const <String>['SURFACE', 'MID-WATER', 'DEEP'][depth]
      : const <String>['YÜZEY', 'ORTA SU', 'DERİN'][depth];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_tick);
    unawaited(_audioProfile.preload(_audio));
    unawaited(_prepareScenario());
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

  Future<void> _prepareScenario() async {
    LittleFisherScenario scenario = LittleFisherScenario.forLevel(
      widget.level.number,
    );
    try {
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      final String visitKey =
          'little_fisher_level_${widget.level.number}_visits';
      final int visits = await preferences.getInt(visitKey) ?? 0;
      if (visits > 0) {
        final int index =
            await preferences.getInt('little_fisher_practice_index') ?? 0;
        if (index < LittleFisherScenario.maximumPracticeRounds) {
          final int next = index + 1;
          await preferences.setInt('little_fisher_practice_index', next);
          scenario = LittleFisherScenario.forPracticeRound(next);
        }
      }
      await preferences.setInt(visitKey, visits + 1);
    } catch (_) {
      scenario = LittleFisherScenario.forLevel(widget.level.number);
    }
    if (!mounted) return;
    _scenario = scenario;
    _startRound();
    setState(() => _ready = true);
  }

  void _startRound() {
    _ticker.stop();
    _engine = LittleFisherEngine(scenario: _scenario);
    _elapsed = 0;
    _score = 0;
    _bait = 0;
    _depth = 1;
    _paused = false;
    _finished = false;
    _lastTick = Duration.zero;
    _session = StudioGameSession(
      level: widget.level.number,
      seed: _scenario.seed,
    )..start();
    _ticker.start();
  }

  void _setPaused(bool paused) {
    if (!_ready || _finished || _paused == paused) return;
    setState(() => _paused = paused);
    if (paused) {
      _engine.setReeling(false);
      _session.pause();
      _ticker.stop();
    } else {
      _session.resume();
      _lastTick = Duration.zero;
      _ticker.start();
    }
    unawaited(_audio.play(GameSound.uiClick, gain: .24));
  }

  void _chooseBait(int bait) {
    if (_paused || _finished || _engine.isHooked) return;
    setState(() => _bait = bait);
    _audio.hapticSelection();
  }

  void _chooseDepth(int depth) {
    if (_paused || _finished || _engine.isHooked) return;
    setState(() => _depth = depth);
    _audio.hapticSelection();
  }

  void _castOrReel() {
    if (_paused || _finished) return;
    if (!_engine.isHooked) {
      final FishingCastResult result = _engine.cast(bait: _bait, depth: _depth);
      if (result == FishingCastResult.hooked) {
        _audio.hapticLight();
        unawaited(
          _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .28),
        );
      } else if (result == FishingCastResult.wrongBait ||
          result == FishingCastResult.wrongDepth) {
        _session.recordMistake();
        unawaited(
          _audioProfile.play(_audio, GameAudioEvent.rejected, gain: .20),
        );
      }
    } else {
      _engine.setReeling(!_engine.isReeling);
      if (_engine.isReeling) {
        _audio.hapticLight();
        unawaited(
          _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .15),
        );
      }
    }
    setState(() {});
  }

  void _setReeling(bool held) {
    if (!_engine.isHooked || _paused || _finished) return;
    _engine.setReeling(held);
    if (held) _audio.hapticLight();
    setState(() {});
  }

  void _tick(Duration elapsed) {
    if (!_ready || _paused || _finished) return;
    final double raw = (elapsed - _lastTick).inMicroseconds / 1000000;
    _lastTick = elapsed;
    if (raw <= 0) return;
    final double delta = raw.clamp(0, .024).toDouble();
    _elapsed += delta;
    final FishingStepResult result = _engine.step(delta);
    if (result.caught) {
      final int points = 120 + math.max(0, widget.level.number - 3) * 15;
      _score += points;
      _session.recordAccepted(points: points);
      unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .32));
    } else if (result.missed) {
      _session.recordMistake();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .23));
    }
    if (_engine.misses > _scenario.missLimit) {
      unawaited(_finish(completed: false));
    } else if (_engine.isComplete) {
      unawaited(_finish(completed: true));
    }
    if (mounted && !_finished) setState(() {});
  }

  Future<void> _finish({required bool completed}) async {
    if (_finished || !mounted) return;
    _finished = true;
    _ticker.stop();
    if (!completed) {
      final bool retry =
          await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) => AlertDialog(
              title: Text(_english ? 'Line went slack' : 'Misina boşaldı'),
              content: Text(
                _english
                    ? 'Too many casts missed or lines snapped. Read the fish and ease your reel inside the safe band, then try again?'
                    : 'Fazla yem kaçtı ya da misina koptu. Balığın izini okuyup makarayı güvenli aralıkta yöneterek tekrar deneyelim mi?',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(_english ? 'Level map' : 'Bölüm listesi'),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: Text(_english ? 'Retry' : 'Tekrar dene'),
                ),
              ],
            ),
          ) ??
          false;
      if (!mounted) return;
      if (retry) {
        setState(_startRound);
      } else {
        Navigator.of(context)
            .pop(StudioGameResult.failed(score: _score).toParkurResult());
      }
      return;
    }
    _session.complete(
      stars: _stars,
      action: widget.level.number < LittleFisherGamePage.totalCases
          ? StudioResultAction.next
          : StudioResultAction.map,
    );
    unawaited(_audioProfile.play(
      _audio,
      GameAudioEvent.levelComplete,
      levelNumber: widget.level.number,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 170));
    if (!mounted) return;
    final ParkurResultAction? result = await showParkurResultDialog(
      context: context,
      accent: _accent,
      titleTr: 'AKINTI SEFERİ TAMAMLANDI',
      titleEn: 'CURRENT EXPEDITION COMPLETE',
      detailTr:
          '${_engine.catches}/${_scenario.fishCount} balık · ${_engine.misses} yanlış · ${_elapsed.toStringAsFixed(1)} sn.',
      detailEn:
          '${_engine.catches}/${_scenario.fishCount} fish · ${_engine.misses} misses · ${_elapsed.toStringAsFixed(1)} s.',
      stars: _stars,
      score: _score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < LittleFisherGamePage.totalCases,
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
          title: Text(_english ? 'LITTLE FISHER' : 'KÜÇÜK BALIKÇI'),
        ),
        body: const Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    final FishPlan? fish = _engine.currentFish;
    final FishingCurrent current = _scenario.currentAt(_elapsed, _depth);
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: _ink,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _english ? 'LITTLE FISHER' : 'KÜÇÜK BALIKÇI',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('little_fisher_pause'),
            tooltip: _paused
                ? (_english ? 'Resume' : 'Devam et')
                : (_english ? 'Pause' : 'Duraklat'),
            onPressed: () => _setPaused(!_paused),
            icon: Icon(
              _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 5, 12, 6),
              child: Column(
                children: <Widget>[
                  _FishingHud(
                    catches: _engine.catches,
                    total: _scenario.fishCount,
                    misses: _engine.misses,
                    missLimit: _scenario.missLimit,
                    tension: _engine.lineTension,
                    hooked: _engine.isHooked,
                    english: _english,
                  ),
                  const SizedBox(height: 5),
                  _FishBrief(
                    fish: fish,
                    fishName: fish == null ? '' : _fishName(fish.species),
                    baitName: fish == null ? '' : _baitName(fish.preferredBait),
                    depthName: fish == null
                        ? ''
                        : _depthName(fish.preferredDepth),
                    english: _english,
                  ),
                  const SizedBox(height: 5),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints limits) {
                        final double width = math.min(limits.maxWidth, 570);
                        final double height = math.min(
                          limits.maxHeight,
                          width * .83,
                        );
                        return Center(
                          child: SizedBox(
                            key: const ValueKey<String>('little_fisher_scene'),
                            width: width,
                            height: height,
                            child: CustomPaint(
                              painter: _FishingPainter(
                                scenario: _scenario,
                                engine: _engine,
                                elapsed: _elapsed,
                                depth: _depth,
                                current: current,
                                paused: _paused,
                                english: _english,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 5),
                  _ChoiceStrip(
                    label: _english ? 'BAIT' : 'YEM',
                    selected: _bait,
                    values: _english
                        ? const <String>['Worm', 'Spoon', 'Fly']
                        : const <String>['Solucan', 'Kaşık', 'Sinek'],
                    icons: const <IconData>[
                      Icons.grain_rounded,
                      Icons.set_meal_rounded,
                      Icons.bug_report_rounded,
                    ],
                    keyPrefix: 'little_fisher_bait',
                    enabled: !_engine.isHooked && !_paused && !_finished,
                    onSelect: _chooseBait,
                  ),
                  const SizedBox(height: 4),
                  _ChoiceStrip(
                    label: _english ? 'DEPTH' : 'DERİNLİK',
                    selected: _depth,
                    values: _english
                        ? const <String>['Surface', 'Mid', 'Deep']
                        : const <String>['Yüzey', 'Orta', 'Derin'],
                    icons: const <IconData>[
                      Icons.waves_rounded,
                      Icons.water_rounded,
                      Icons.south_rounded,
                    ],
                    keyPrefix: 'little_fisher_depth',
                    enabled: !_engine.isHooked && !_paused && !_finished,
                    onSelect: _chooseDepth,
                  ),
                  const SizedBox(height: 5),
                  GestureDetector(
                    onLongPressStart: _engine.isHooked
                        ? (LongPressStartDetails details) => _setReeling(true)
                        : null,
                    onLongPressEnd: _engine.isHooked
                        ? (LongPressEndDetails details) => _setReeling(false)
                        : null,
                    child: SizedBox(
                      width: double.infinity,
                      height: 51,
                      child: FilledButton.icon(
                        key: const ValueKey<String>('little_fisher_action'),
                        onPressed: !_paused && !_finished ? _castOrReel : null,
                        icon: Icon(
                          !_engine.isHooked
                              ? Icons.sailing_rounded
                              : _engine.isReeling
                              ? Icons.pause_circle_outline_rounded
                              : Icons.replay_rounded,
                          size: 19,
                        ),
                        label: Text(
                          !_engine.isHooked
                              ? (_english ? 'CAST' : 'AT')
                              : (_engine.isReeling
                                    ? (_english ? 'EASE LINE' : 'GERİ BIRAK')
                                    : (_english ? 'REEL' : 'MAKARA')),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: _engine.isHooked && _engine.isReeling
                              ? const Color(0xFFBA7658)
                              : _accent,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFE2D8CF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _engine.isHooked
                        ? (_english
                              ? 'Tap or hold REEL in the middle band; ease off before the line snaps or slackens.'
                              : 'Ortadaki bantta MAKARA’ya dokun/tut; misina kopmadan ya da boşalmadan bırak.')
                        : (_english
                              ? 'Choose the marked bait and fish depth, then cast. The fish card shows its current preference.'
                              : 'İşaretli yemi ve balık derinliğini seçip at. Kart balığın bu seferki tercihini gösterir.'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: StudioVisuals.muted,
                      fontSize: 8.5,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FishingHud extends StatelessWidget {
  const _FishingHud({
    required this.catches,
    required this.total,
    required this.misses,
    required this.missLimit,
    required this.tension,
    required this.hooked,
    required this.english,
  });

  final int catches;
  final int total;
  final int misses;
  final int missLimit;
  final double tension;
  final bool hooked;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey<String>('little_fisher_hud'),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: StudioVisuals.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: StudioVisuals.line),
      boxShadow: StudioVisuals.softShadow,
    ),
    child: Row(
      children: <Widget>[
        Expanded(
          child: _FishingMetric(
            label: english ? 'ON BOARD' : 'TEKNEDE',
            value: '$catches / $total',
            icon: Icons.phishing_rounded,
            color: const Color(0xFF69947E),
          ),
        ),
        Container(width: 1, height: 26, color: StudioVisuals.line),
        Expanded(
          child: _FishingMetric(
            label: english ? 'MISSES' : 'HATA',
            value: '$misses / $missLimit',
            icon: Icons.warning_amber_rounded,
            color: misses == 0
                ? _LittleFisherPlayPageState._accent
                : const Color(0xFFC57561),
          ),
        ),
        Container(width: 1, height: 26, color: StudioVisuals.line),
        Expanded(
          child: _FishingMetric(
            label: english ? 'TENSION' : 'GERİLİM',
            value: hooked ? '${(tension * 100).round()}%' : '—',
            icon: Icons.linear_scale_rounded,
            color: _tensionColor(tension),
          ),
        ),
      ],
    ),
  );

  static Color _tensionColor(double tension) => tension < .24 || tension > .78
      ? const Color(0xFFC57561)
      : const Color(0xFF5C9A81);
}

class _FishingMetric extends StatelessWidget {
  const _FishingMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      Icon(icon, color: color, size: 15),
      const SizedBox(width: 3),
      Flexible(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: StudioVisuals.muted,
                fontSize: 7,
                fontWeight: FontWeight.w900,
                letterSpacing: .2,
              ),
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _LittleFisherPlayPageState._ink,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _FishBrief extends StatelessWidget {
  const _FishBrief({
    required this.fish,
    required this.fishName,
    required this.baitName,
    required this.depthName,
    required this.english,
  });

  final FishPlan? fish;
  final String fishName;
  final String baitName;
  final String depthName;
  final bool english;

  @override
  Widget build(BuildContext context) {
    if (fish == null) {
      return Row(
        children: <Widget>[
          const Icon(
            Icons.done_all_rounded,
            size: 16,
            color: Color(0xFF69947E),
          ),
          const SizedBox(width: 6),
          Text(
            english ? 'The boat is full' : 'Tekne hazır',
            style: const TextStyle(
              color: _LittleFisherPlayPageState._ink,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: StudioVisuals.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: StudioVisuals.line),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            _FishingPainter._fishIcon(fish!.species),
            size: 16,
            color: _FishingPainter._fishColor(fish!.species),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              fishName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _LittleFisherPlayPageState._ink,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.grain_rounded, size: 12, color: const Color(0xFFBA8E5F)),
          const SizedBox(width: 2),
          Text(
            baitName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: StudioVisuals.muted,
              fontSize: 7.3,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.water_rounded, size: 12, color: const Color(0xFF548995)),
          const SizedBox(width: 2),
          Text(
            depthName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: StudioVisuals.muted,
              fontSize: 7.3,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceStrip extends StatelessWidget {
  const _ChoiceStrip({
    required this.label,
    required this.selected,
    required this.values,
    required this.icons,
    required this.keyPrefix,
    required this.enabled,
    required this.onSelect,
  });

  final String label;
  final int selected;
  final List<String> values;
  final List<IconData> icons;
  final String keyPrefix;
  final bool enabled;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      SizedBox(
        width: 55,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: StudioVisuals.muted,
            fontSize: 7.5,
            fontWeight: FontWeight.w900,
            letterSpacing: .35,
          ),
        ),
      ),
      for (int index = 0; index < values.length; index++)
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: index == 0 ? 0 : 4),
            child: Material(
              color: selected == index
                  ? const Color(0xFFE0EFEB)
                  : StudioVisuals.surface,
              borderRadius: BorderRadius.circular(11),
              child: InkWell(
                key: ValueKey<String>('${keyPrefix}_$index'),
                borderRadius: BorderRadius.circular(11),
                onTap: enabled ? () => onSelect(index) : null,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 34),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: selected == index
                          ? const Color(0xFF92BBB0)
                          : StudioVisuals.line,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        icons[index],
                        size: 13,
                        color: selected == index
                            ? _LittleFisherPlayPageState._accent
                            : StudioVisuals.muted,
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          values[index],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected == index
                                ? _LittleFisherPlayPageState._ink
                                : StudioVisuals.muted,
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

class _FishingPainter extends CustomPainter {
  const _FishingPainter({
    required this.scenario,
    required this.engine,
    required this.elapsed,
    required this.depth,
    required this.current,
    required this.paused,
    required this.english,
  });

  final LittleFisherScenario scenario;
  final LittleFisherEngine engine;
  final double elapsed;
  final int depth;
  final FishingCurrent current;
  final bool paused;
  final bool english;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final double w = size.width;
    final double h = size.height;
    final Rect bounds = Offset.zero & size;
    final RRect frame = RRect.fromRectAndRadius(
      bounds.deflate(2),
      const Radius.circular(23),
    );
    canvas.drawShadow(
      Path()..addRRect(frame),
      const Color(0x3332494A),
      8,
      true,
    );
    canvas.drawRRect(
      frame,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFFEFF6EE),
            Color(0xFFCAE0DB),
            Color(0xFF5F9B9D),
            Color(0xFF275C69),
          ],
          stops: <double>[0, .22, .60, 1],
        ).createShader(bounds),
    );
    canvas.drawRRect(
      frame,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = const Color(0xFFD6E7DF),
    );

    final double surfaceY = h * .20;
    final Paint horizon = Paint()
      ..color = const Color(0xFF6F9B8D).withValues(alpha: .20)
      ..strokeWidth = math.max(1, h * .007);
    for (int line = 0; line < 4; line++) {
      final double y = surfaceY + h * (.035 + line * .018);
      final Path wave = Path()..moveTo(w * .04, y);
      for (int step = 0; step <= 20; step++) {
        final double x = w * (.04 + .92 * step / 20);
        final double waveY =
            y + math.sin(step * .9 + elapsed * 1.2 + line) * h * .009;
        wave.lineTo(x, waveY);
      }
      canvas.drawPath(wave, horizon);
    }

    final Paint depthLine = Paint()
      ..color = Colors.white.withValues(alpha: .20)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    for (int band = 1; band <= 2; band++) {
      final double y = h * (.20 + band * .24);
      for (int dash = 0; dash < 8; dash++) {
        final double x = w * (.08 + dash * .12);
        canvas.drawLine(Offset(x, y), Offset(x + w * .055, y), depthLine);
      }
    }

    _drawBoat(canvas, w, h, surfaceY);
    _drawCurrent(canvas, w, h);
    final FishPlan? fish = engine.currentFish;
    final Offset? fishPoint = fish == null ? null : _fishPosition(fish, w, h);
    if (fish != null && fishPoint != null) {
      if (engine.isHooked) {
        final Offset rodTip = Offset(w * .60, surfaceY + h * .09);
        canvas.drawLine(
          rodTip,
          fishPoint,
          Paint()
            ..color = Color.lerp(
              const Color(0xFFE8E1C6),
              const Color(0xFFE4745B),
              (engine.lineTension - .3).clamp(0, 1).toDouble(),
            )!
            ..strokeWidth = 1.35,
        );
        _drawBobber(canvas, Offset(w * .48, surfaceY + h * .20), w, h);
      } else {
        final Offset rodTip = Offset(w * .60, surfaceY + h * .09);
        final Offset bobber = Offset(
          w * .39 + math.sin(elapsed * .9) * w * .018,
          surfaceY + h * (.18 + math.sin(elapsed * 1.4) * .018),
        );
        canvas.drawLine(
          rodTip,
          bobber,
          Paint()
            ..color = const Color(0xFFECE6CF)
            ..strokeWidth = 1.2,
        );
        _drawBobber(canvas, bobber, w, h);
      }
      final double sway = math.sin(elapsed * fish.finSpeed + fish.phase) * .08;
      _drawFish(canvas, fishPoint, math.min(w, h) * .14, fish.species, sway);
      if (engine.isHooked) {
        final Rect staminaTrack = Rect.fromLTWH(
          w * .87,
          h * .29,
          w * .035,
          h * .48,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(staminaTrack, const Radius.circular(8)),
          Paint()..color = const Color(0x447AB0A9),
        );
        final double staminaRatio = (engine.staminaRemaining / fish.stamina)
            .clamp(0, 1)
            .toDouble();
        final Rect staminaFill = Rect.fromLTWH(
          staminaTrack.left,
          staminaTrack.bottom - staminaTrack.height * staminaRatio,
          staminaTrack.width,
          staminaTrack.height * staminaRatio,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(staminaFill, const Radius.circular(8)),
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[Color(0xFFE8BB72), Color(0xFF6EAA92)],
            ).createShader(staminaTrack),
        );
        _drawLabel(
          canvas,
          english ? 'ENERGY' : 'ENERJİ',
          Offset(w * .887, h * .24),
          math.max(6, h * .022),
          Colors.white,
        );
      }
    }

    final Offset gaugeCenter = Offset(w * .91, h * .84);
    final double gaugeHeight = h * .56;
    final Rect gauge = Rect.fromLTWH(
      gaugeCenter.dx - w * .013,
      gaugeCenter.dy - gaugeHeight,
      w * .026,
      gaugeHeight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(gauge, const Radius.circular(7)),
      Paint()..color = const Color(0x5577A6A4),
    );
    final double low = gauge.bottom - gauge.height * .78;
    final double high = gauge.bottom - gauge.height * .30;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(gauge.left - 3, high, gauge.right + 3, low),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0x557EB79D),
    );
    if (engine.isHooked) {
      final double y =
          gauge.bottom -
          gauge.height * engine.lineTension.clamp(0, 1).toDouble();
      final Color tensionColor =
          engine.lineTension < .24 || engine.lineTension > .78
          ? const Color(0xFFDD725F)
          : const Color(0xFFF4D48C);
      canvas.drawCircle(
        Offset(gaugeCenter.dx, y),
        w * .023,
        Paint()..color = tensionColor,
      );
      canvas.drawCircle(
        Offset(gaugeCenter.dx, y),
        w * .012,
        Paint()..color = Colors.white,
      );
      _drawLabel(
        canvas,
        english ? 'SAFE' : 'İYİ',
        Offset(gaugeCenter.dx, (low + high) / 2),
        math.max(6, h * .02),
        Colors.white.withValues(alpha: .86),
      );
    }

    if (paused) {
      canvas.drawRRect(frame, Paint()..color = const Color(0xAA184955));
      _drawLabel(
        canvas,
        english ? 'WATER STILL' : 'SU DURDU',
        Offset(w / 2, h / 2),
        math.max(13, h * .055),
        Colors.white,
      );
    }
  }

  Offset _fishPosition(FishPlan fish, double w, double h) {
    final double centerX = engine.isHooked
        ? .52 +
              engine.fishDistance *
                  .28 *
                  math.sin(elapsed * fish.finSpeed + fish.phase)
        : .52 + .25 * math.sin(elapsed * fish.finSpeed + fish.phase);
    final double centerY =
        .25 +
        fish.preferredDepth * .235 +
        math.sin(elapsed * fish.pullFrequency * .47 + fish.phase) * .018;
    return Offset(centerX * w, centerY * h);
  }

  void _drawBoat(Canvas canvas, double w, double h, double surfaceY) {
    final Rect hull = Rect.fromCenter(
      center: Offset(w * .67, surfaceY + h * .075),
      width: w * .30,
      height: h * .10,
    );
    final Path boat = Path()
      ..moveTo(hull.left, hull.top)
      ..lineTo(hull.right, hull.top)
      ..lineTo(hull.right - w * .045, hull.bottom)
      ..quadraticBezierTo(
        hull.center.dx,
        hull.bottom + h * .025,
        hull.left + w * .045,
        hull.bottom,
      )
      ..close();
    canvas.drawPath(
      boat,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFFC99867), Color(0xFF886144)],
        ).createShader(hull),
    );
    canvas.drawPath(
      boat,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFF73543D),
    );
    for (int plank = 1; plank <= 3; plank++) {
      final double x = hull.left + hull.width * plank / 4;
      canvas.drawLine(
        Offset(x, hull.top + 2),
        Offset(x, hull.bottom - 3),
        Paint()
          ..color = const Color(0x77916B49)
          ..strokeWidth = 1,
      );
    }
    final Offset rodTip = Offset(w * .60, surfaceY + h * .09);
    final Offset rodBase = Offset(w * .72, surfaceY + h * .015);
    canvas.drawLine(
      rodBase,
      rodTip,
      Paint()
        ..color = const Color(0xFF493F36)
        ..strokeWidth = math.max(2, w * .005)
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      rodBase.translate(0, -h * .006),
      rodTip.translate(0, -h * .006),
      Paint()
        ..color = const Color(0xFFD7B178)
        ..strokeWidth = 1.4,
    );
    canvas.drawCircle(
      Offset(w * .64, surfaceY + h * .04),
      w * .016,
      Paint()..color = const Color(0xFFE2AF6D),
    );
  }

  void _drawCurrent(Canvas canvas, double w, double h) {
    final double mag = math.sqrt(current.x * current.x + current.y * current.y);
    if (mag < .001) return;
    final double angle = math.atan2(current.y, current.x);
    final Paint stream = Paint()
      ..color = const Color(0xFFDBF6E8).withValues(alpha: .52)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (int row = 0; row < 4; row++) {
      final double y = h * (.36 + row * .14);
      for (int i = 0; i < 3; i++) {
        final double x =
            w * (.13 + i * .27 + ((elapsed * .08 + row * .17) % .16));
        final Offset start = Offset(x, y);
        final Offset end =
            start +
            Offset(math.cos(angle), math.sin(angle)) * w * (.04 + mag * .5);
        canvas.drawLine(start, end, stream);
        final Offset wing =
            Offset(-math.sin(angle), math.cos(angle)) * w * .009;
        canvas.drawLine(
          end,
          end - Offset(math.cos(angle), math.sin(angle)) * w * .012 + wing,
          stream,
        );
        canvas.drawLine(
          end,
          end - Offset(math.cos(angle), math.sin(angle)) * w * .012 - wing,
          stream,
        );
      }
    }
  }

  void _drawBobber(Canvas canvas, Offset center, double w, double h) {
    final Rect body = Rect.fromCenter(
      center: center,
      width: w * .023,
      height: h * .054,
    );
    canvas.drawOval(
      body,
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[
            Color(0xFFE9F0D9),
            Color(0xFFDB7A5D),
            Color(0xFFB7564C),
          ],
          stops: <double>[0, .42, 1],
        ).createShader(body),
    );
    canvas.drawLine(
      Offset(center.dx, body.top),
      Offset(center.dx, body.bottom),
      Paint()
        ..color = Colors.white.withValues(alpha: .75)
        ..strokeWidth = 1,
    );
  }

  void _drawFish(
    Canvas canvas,
    Offset center,
    double size,
    int species,
    double sway,
  ) {
    final double bodyWidth =
        size *
        switch (species) {
          0 => 1.05,
          1 => 1.32,
          2 => 1.12,
          _ => .93,
        };
    final double bodyHeight =
        size *
        switch (species) {
          0 => .50,
          1 => .43,
          2 => .58,
          _ => .46,
        };
    final Color base = _fishColor(species);
    final Rect body = Rect.fromCenter(
      center: center,
      width: bodyWidth,
      height: bodyHeight,
    );
    final Path silhouette = Path()
      ..moveTo(body.left, center.dy)
      ..quadraticBezierTo(
        body.left + bodyWidth * .34,
        body.top - bodyHeight * .25,
        body.center.dx + bodyWidth * .18,
        center.dy,
      )
      ..quadraticBezierTo(
        body.center.dx,
        body.bottom + bodyHeight * .24,
        body.left,
        center.dy,
      )
      ..close();
    final Offset tailTip = Offset(
      body.left - bodyWidth * (.27 + sway.abs() * .2),
      center.dy,
    );
    final Path tail = Path()
      ..moveTo(body.left + bodyWidth * .02, center.dy)
      ..lineTo(tailTip.dx, tailTip.dy - bodyHeight * .46)
      ..quadraticBezierTo(
        tailTip.dx - bodyWidth * .14,
        center.dy,
        tailTip.dx,
        tailTip.dy + bodyHeight * .46,
      )
      ..close();
    canvas.drawPath(
      tail,
      Paint()..color = Color.lerp(base, const Color(0xFF163F49), .22)!,
    );
    canvas.drawPath(
      silhouette,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color.lerp(base, Colors.white, .42)!,
            base,
            Color.lerp(base, const Color(0xFF123D46), .28)!,
          ],
          stops: const <double>[0, .47, 1],
        ).createShader(body),
    );
    final Paint fin = Paint()
      ..color = Color.lerp(base, Colors.white, .25)!
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, size * .035);
    final Path dorsal = Path()
      ..moveTo(center.dx - bodyWidth * .15, body.top + bodyHeight * .02)
      ..quadraticBezierTo(
        center.dx + bodyWidth * .02,
        body.top - bodyHeight * .5,
        center.dx + bodyWidth * .30,
        body.top + bodyHeight * .05,
      );
    canvas.drawPath(dorsal, fin);
    final Path pectoral = Path()
      ..moveTo(center.dx - bodyWidth * .05, center.dy + bodyHeight * .02)
      ..lineTo(center.dx + bodyWidth * .12, center.dy + bodyHeight * .44)
      ..lineTo(center.dx + bodyWidth * .31, center.dy + bodyHeight * .02);
    canvas.drawPath(pectoral, fin);
    if (species == 1 || species == 2) {
      final Paint stripe = Paint()
        ..color = Colors.white.withValues(alpha: .34)
        ..strokeWidth = math.max(1, size * .025);
      for (int line = 0; line < 4; line++) {
        final double x = body.left + bodyWidth * (.35 + line * .12);
        canvas.drawLine(
          Offset(x, body.top + bodyHeight * .20),
          Offset(x + bodyWidth * .06, body.bottom - bodyHeight * .2),
          stripe,
        );
      }
    }
    canvas.drawCircle(
      Offset(center.dx + bodyWidth * .31, center.dy - bodyHeight * .04),
      size * .036,
      Paint()..color = const Color(0xFFFCF7E8),
    );
    canvas.drawCircle(
      Offset(center.dx + bodyWidth * .32, center.dy - bodyHeight * .04),
      size * .018,
      Paint()..color = const Color(0xFF253A3D),
    );
    final Path gill = Path()
      ..moveTo(center.dx + bodyWidth * .12, center.dy - bodyHeight * .25)
      ..quadraticBezierTo(
        center.dx + bodyWidth * .18,
        center.dy,
        center.dx + bodyWidth * .10,
        center.dy + bodyHeight * .23,
      );
    canvas.drawPath(
      gill,
      Paint()
        ..color = Colors.white.withValues(alpha: .54)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, size * .025),
    );
  }

  static IconData _fishIcon(int species) => switch (species) {
    0 => Icons.set_meal_rounded,
    1 => Icons.phishing_rounded,
    2 => Icons.water_rounded,
    _ => Icons.air_rounded,
  };

  static Color _fishColor(int species) => const <Color>[
    Color(0xFF91C1A2),
    Color(0xFFD0A86F),
    Color(0xFFD6C18A),
    Color(0xFF94BDCB),
  ][species];

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset center,
    double fontSize,
    Color color,
  ) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: .4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _FishingPainter oldDelegate) =>
      oldDelegate.scenario != scenario ||
      oldDelegate.engine != engine ||
      oldDelegate.elapsed != elapsed ||
      oldDelegate.depth != depth ||
      oldDelegate.current != current ||
      oldDelegate.paused != paused ||
      oldDelegate.english != english;
}
