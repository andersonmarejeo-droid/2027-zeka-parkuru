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
import 'bottle_target_scenario.dart';

class BottleTargetGamePage extends StatelessWidget {
  const BottleTargetGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  static const int totalCases = BottleTargetScenario.maximumLevels;
  static const int totalStars = totalCases * 3;

  static final List<ParkurLevelSpec> _levels = List<ParkurLevelSpec>.generate(
    totalCases,
    (int index) {
      final int level = index + 1;
      final String tr = switch (level) {
        <= 3 => 'Açıyı ve gücü ayarla; hedef şişeyi güvenle vur.',
        <= 6 => 'İki hedefi seç; sahne eşyalarını koru.',
        7 || 8 => 'İleri: yansıtıcı yüzeyi kullan ve atışını planla.',
        9 => 'Uzman: dar pencere, üç engel ve dört hedef.',
        _ => 'Usta finali: iki aşamalı rafı sınırlı atışla temizle.',
      };
      final String en = switch (level) {
        <= 3 => 'Set the angle and power; hit the target bottle cleanly.',
        <= 6 => 'Choose two targets and protect the display props.',
        7 || 8 => 'Advanced: plan a bank shot off the reflective surface.',
        9 => 'Expert: a narrow window, three obstacles and four targets.',
        _ => 'Master finale: clear the two-stage rack with limited shots.',
      };
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Atış Poligonu ${level.toString().padLeft(2, '0')}',
        titleEn: 'Range ${level.toString().padLeft(2, '0')}',
        subtitleTr: tr,
        subtitleEn: en,
        difficulty: switch (level) {
          <= 6 => level <= 3 ? 'USTALAŞMA' : 'DERİNLEŞME',
          7 || 8 => 'İLERİ',
          9 => 'UZMAN',
          _ => 'USTA',
        },
        icon: Icons.sports_baseball_rounded,
      );
    },
    growable: false,
  );

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.fun);
    return ParkurLevelHub(
      gameId: 'bottle_target',
      progressPrefix: 'bottle_target',
      titleTr: 'Şişe Kırmaca',
      titleEn: 'Bottle Target',
      taglineTr: 'Açıyı kur • Sekmeyi hesapla • Hedefi vur',
      taglineEn: 'Set the angle • Plan the bounce • Hit the target',
      accent: skin.accent,
      icon: Icons.sports_baseball_rounded,
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
          ) => BottleTargetPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class BottleTargetPlayPage extends StatefulWidget {
  const BottleTargetPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<BottleTargetPlayPage> createState() => _BottleTargetPlayPageState();
}

class _MutableBottle {
  _MutableBottle(this.spec);

  final BottleSpec spec;
  bool standing = true;
}

class _Shot {
  _Shot({required this.x, required this.y, required this.vx, required this.vy});

  double x;
  double y;
  double vx;
  double vy;
  double age = 0;
  int wallBanks = 0;
  final List<Offset> trail = <Offset>[];
}

class _BottleTargetPlayPageState extends State<BottleTargetPlayPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const Color _ink = Color(0xFF24404A);
  static const Color _accent = Color(0xFF318C82);
  static const Color _targetColor = Color(0xFFE27E70);
  static const Color _gold = Color(0xFFE7B85D);
  static const Color _sceneTop = Color(0xFF24464A);
  static const Color _sceneBottom = Color(0xFF152E35);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.fun,
  );
  late final Ticker _ticker;
  late BottleTargetScenario _scenario;
  late StudioGameSession _session;
  Duration _lastTick = Duration.zero;
  List<_MutableBottle> _bottles = <_MutableBottle>[];
  _Shot? _shot;
  double _aimAngle = -math.pi / 2;
  double _power = 1.12;
  double _elapsed = 0;
  int _shotsLeft = 0;
  int _targetsHit = 0;
  int _mistakes = 0;
  int _score = 0;
  bool _ready = false;
  bool _paused = false;
  bool _finished = false;
  bool _english = false;

  int get _targetsRemaining => _bottles
      .where(
        (_MutableBottle bottle) =>
            bottle.standing && bottle.spec.kind == BottleKind.target,
      )
      .length;

  int get _stars {
    if (_mistakes == 0 &&
        _shotsLeft >= _scenario.shots - _scenario.targetCount) {
      return 3;
    }
    if (_mistakes == 0) return 2;
    return 1;
  }

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
      if (!_paused && !_finished && _ready) _setPaused(true);
    } else if (state == AppLifecycleState.resumed && _paused && !_finished) {
      _setPaused(false);
    }
  }

  Future<void> _prepareScenario() async {
    BottleTargetScenario scenario = BottleTargetScenario.forLevel(
      widget.level.number,
    );
    try {
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      final String visitKey =
          'bottle_target_level_${widget.level.number}_visits';
      final int visits = await preferences.getInt(visitKey) ?? 0;
      if (visits > 0) {
        final int index =
            await preferences.getInt('bottle_target_practice_index') ?? 0;
        if (index < BottleTargetScenario.maximumPracticeRounds) {
          final int next = index + 1;
          await preferences.setInt('bottle_target_practice_index', next);
          scenario = BottleTargetScenario.forPracticeRound(next);
        }
      }
      await preferences.setInt(visitKey, visits + 1);
    } catch (_) {
      scenario = BottleTargetScenario.forLevel(widget.level.number);
    }
    if (!mounted) return;
    _scenario = scenario;
    _startRound();
    setState(() => _ready = true);
  }

  void _startRound() {
    _ticker.stop();
    _lastTick = Duration.zero;
    _elapsed = 0;
    _shotsLeft = _scenario.shots;
    _targetsHit = 0;
    _mistakes = 0;
    _score = 0;
    _aimAngle = -math.pi / 2;
    _power = 1.12;
    _shot = null;
    // Scenario objects are immutable; each retry gets fresh standing state.
    _bottles = _scenario.bottles.map(_MutableBottle.new).toList();
    _paused = false;
    _finished = false;
    _session = StudioGameSession(
      level: widget.level.number,
      seed: _scenario.seed,
    )..start();
    _ticker.start();
  }

  void _setPaused(bool paused) {
    if (!_ready || _finished) return;
    setState(() => _paused = paused);
    if (paused) {
      _session.pause();
      _ticker.stop();
      unawaited(_audio.play(GameSound.uiClick, gain: .25));
    } else {
      _session.resume();
      _lastTick = Duration.zero;
      _ticker.start();
      unawaited(_audio.play(GameSound.uiClick, gain: .25));
    }
  }

  void _tick(Duration elapsed) {
    if (!_ready || _paused || _finished) return;
    final double raw = (elapsed - _lastTick).inMicroseconds / 1000000;
    _lastTick = elapsed;
    if (raw <= 0) return;
    final double delta = raw.clamp(0, .04).toDouble();
    _elapsed += delta;
    final _Shot? shot = _shot;
    if (shot != null) _advanceShot(shot, delta);
    if (_targetsRemaining == 0) {
      unawaited(_finish(completed: true));
    } else if (_shotsLeft <= 0 && _shot == null) {
      unawaited(_finish(completed: false));
    }
    if (mounted && !_finished) setState(() {});
  }

  void _advanceShot(_Shot shot, double delta) {
    const int substeps = 2;
    final double step = delta / substeps;
    for (int i = 0; i < substeps && identical(_shot, shot); i++) {
      shot.age += step;
      shot.vy += _scenario.gravity * step;
      shot.x += shot.vx * step;
      shot.y += shot.vy * step;
      shot.trail.add(Offset(shot.x, shot.y));
      if (shot.trail.length > 9) shot.trail.removeAt(0);

      if (shot.x < .075 || shot.x > .925) {
        if (_scenario.wallBanking && shot.wallBanks < 2) {
          shot.x = shot.x.clamp(.075, .925).toDouble();
          shot.vx = -shot.vx * .82;
          shot.wallBanks++;
          unawaited(
            _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .16),
          );
        } else {
          _missShot();
          return;
        }
      }

      for (final RangeObstacleSpec obstacle in _scenario.obstacles) {
        final Rect rect = Rect.fromCenter(
          center: Offset(obstacle.x, obstacle.y),
          width: obstacle.width,
          height: obstacle.height,
        );
        if (rect.inflate(.015).contains(Offset(shot.x, shot.y))) {
          if (obstacle.reflective && shot.wallBanks < 2) {
            shot.vy = -shot.vy.abs() * .72;
            shot.vx = shot.vx * (shot.x < obstacle.x ? -1 : 1);
            shot.wallBanks++;
            shot.y = obstacle.y - obstacle.height / 2 - .02;
          } else {
            _missShot();
            return;
          }
        }
      }

      for (final _MutableBottle bottle in _bottles) {
        if (!bottle.standing) continue;
        final double dx = shot.x - bottle.spec.x;
        final double dy = shot.y - bottle.spec.y;
        final double impactRadius = bottle.spec.radius + .018;
        if (dx * dx + dy * dy <= impactRadius * impactRadius) {
          bottle.standing = false;
          _shot = null;
          if (bottle.spec.kind == BottleKind.target) {
            _targetsHit++;
            final int points = 420 + math.max(0, _shotsLeft) * 90;
            _score += points;
            _session.recordAccepted(points: points);
            _audio.hapticLight();
            unawaited(
              _audioProfile.play(_audio, GameAudioEvent.accepted, gain: .38),
            );
          } else {
            _mistakes++;
            _session.recordMistake();
            unawaited(
              _audioProfile.play(_audio, GameAudioEvent.rejected, gain: .44),
            );
          }
          return;
        }
      }

      if (shot.age > 2.8 || shot.y > .96 || shot.y < .035) {
        _missShot();
        return;
      }
    }
  }

  void _missShot() {
    _shot = null;
    _mistakes++;
    _session.recordMistake();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .34));
  }

  void _updateAim(Offset point, Size size) {
    if (!_ready || _paused || _finished || _shot != null) return;
    final Offset origin = Offset(size.width * .5, size.height * .88);
    final Offset delta = point - origin;
    if (delta.dy >= -size.height * .035) return;
    final double length = delta.distance;
    if (length < size.height * .07) return;
    _aimAngle = math.atan2(delta.dy / size.height, delta.dx / size.width);
    _power = (.7 + length / size.height * 1.75).clamp(.74, 1.42).toDouble();
    setState(() {});
  }

  void _setAngle(double degrees) {
    _aimAngle = degrees * math.pi / 180;
    setState(() {});
  }

  void _setPower(double power) {
    _power = power;
    setState(() {});
  }

  void _fire() {
    if (!_ready || _paused || _finished || _shot != null || _shotsLeft <= 0) {
      return;
    }
    _shotsLeft--;
    _shot = _Shot(
      x: .5,
      y: .88,
      vx: math.cos(_aimAngle) * _power,
      vy: math.sin(_aimAngle) * _power,
    );
    _audio.hapticSelection();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .34),
    );
    setState(() {});
  }

  Future<void> _finish({required bool completed}) async {
    if (_finished || !mounted) return;
    _finished = true;
    _ticker.stop();
    if (!completed) {
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .35));
      final bool retry =
          await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) => AlertDialog(
              title: Text(_english ? 'Range closed' : 'Poligon kapandı'),
              content: Text(
                _english
                    ? '$_targetsHit target bottles, $_mistakes penalties. Try this range again?'
                    : '$_targetsHit hedef şişe, $_mistakes ceza. Bu poligonu yeniden denemek ister misin?',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(_english ? 'Level map' : 'Bölüm listesi'),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  icon: const Icon(Icons.replay_rounded),
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
      action: widget.level.number < BottleTargetGamePage.totalCases
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
      titleTr: 'ATIŞ POLİGONU TAMAMLANDI',
      titleEn: 'RANGE CLEARED',
      detailTr: '$_targetsHit hedef · $_shotsLeft atış kaldı.',
      detailEn: '$_targetsHit targets · $_shotsLeft shots remaining.',
      stars: _stars,
      score: _score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < BottleTargetGamePage.totalCases,
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
          backgroundColor: StudioVisuals.canvas,
          title: Text(_english ? 'BOTTLE TARGET' : 'ŞİŞE KIRMACA'),
        ),
        body: const Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: _ink,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _english ? 'BOTTLE TARGET' : 'ŞİŞE KIRMACA',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('bottle_pause'),
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
            constraints: const BoxConstraints(maxWidth: 700),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              child: Column(
                children: <Widget>[
                  _RangeHud(
                    targetsLeft: _targetsRemaining,
                    shotsLeft: _shotsLeft,
                    score: _score,
                    english: _english,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints limits) {
                        final double height = math.min(
                          limits.maxHeight,
                          limits.maxWidth * 1.23,
                        );
                        final Size boardSize = Size(limits.maxWidth, height);
                        return Center(
                          child: SizedBox(
                            width: boardSize.width,
                            height: boardSize.height,
                            child: GestureDetector(
                              key: const ValueKey<String>('bottle_range_scene'),
                              behavior: HitTestBehavior.opaque,
                              onPanUpdate: (DragUpdateDetails details) =>
                                  _updateAim(details.localPosition, boardSize),
                              onTapDown: (TapDownDetails details) =>
                                  _updateAim(details.localPosition, boardSize),
                              child: CustomPaint(
                                painter: _BottleRangePainter(
                                  bottles: _bottles,
                                  obstacles: _scenario.obstacles,
                                  shot: _shot,
                                  angle: _aimAngle,
                                  power: _power,
                                  gravity: _scenario.gravity,
                                  targetsLeft: _targetsRemaining,
                                  elapsed: _elapsed,
                                  paused: _paused,
                                  english: _english,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 4),
                  _RangeControls(
                    angle: _aimAngle * 180 / math.pi,
                    power: _power,
                    shotsLeft: _shotsLeft,
                    shotInFlight: _shot != null,
                    english: _english,
                    onAngleChanged: _setAngle,
                    onPowerChanged: _setPower,
                    onFire: _fire,
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

class _RangeHud extends StatelessWidget {
  const _RangeHud({
    required this.targetsLeft,
    required this.shotsLeft,
    required this.score,
    required this.english,
  });

  final int targetsLeft;
  final int shotsLeft;
  final int score;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey<String>('bottle_range_hud'),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: StudioVisuals.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: StudioVisuals.line),
      boxShadow: StudioVisuals.softShadow,
    ),
    child: Row(
      children: <Widget>[
        _RangeMetric(
          label: english ? 'TARGETS' : 'HEDEF',
          value: '$targetsLeft',
          icon: Icons.sports_baseball_rounded,
          color: _BottleTargetPlayPageState._targetColor,
        ),
        const _RangeDivider(),
        _RangeMetric(
          label: english ? 'SHOTS' : 'ATIŞ',
          value: '$shotsLeft',
          icon: Icons.bolt_rounded,
          color: _BottleTargetPlayPageState._gold,
        ),
        const _RangeDivider(),
        _RangeMetric(
          label: english ? 'SCORE' : 'PUAN',
          value: '$score',
          icon: Icons.stars_rounded,
          color: _BottleTargetPlayPageState._accent,
        ),
      ],
    ),
  );
}

class _RangeMetric extends StatelessWidget {
  const _RangeMetric({
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
  Widget build(BuildContext context) => Expanded(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              style: const TextStyle(
                color: StudioVisuals.muted,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: .35,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: _BottleTargetPlayPageState._ink,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _RangeDivider extends StatelessWidget {
  const _RangeDivider();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 27,
    margin: const EdgeInsets.symmetric(horizontal: 5),
    color: StudioVisuals.line,
  );
}

class _RangeControls extends StatelessWidget {
  const _RangeControls({
    required this.angle,
    required this.power,
    required this.shotsLeft,
    required this.shotInFlight,
    required this.english,
    required this.onAngleChanged,
    required this.onPowerChanged,
    required this.onFire,
  });

  final double angle;
  final double power;
  final int shotsLeft;
  final bool shotInFlight;
  final bool english;
  final ValueChanged<double> onAngleChanged;
  final ValueChanged<double> onPowerChanged;
  final VoidCallback onFire;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Row(
        children: <Widget>[
          SizedBox(
            width: 68,
            child: Text(
              '${english ? 'ANGLE' : 'AÇI'}  ${angle.round()}°',
              maxLines: 1,
              style: const TextStyle(
                color: StudioVisuals.muted,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                activeTrackColor: _BottleTargetPlayPageState._accent,
                thumbColor: _BottleTargetPlayPageState._accent,
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(
                key: const ValueKey<String>('bottle_angle_slider'),
                value: angle.clamp(-155, -25).toDouble(),
                min: -155,
                max: -25,
                onChanged: shotInFlight ? null : onAngleChanged,
                semanticFormatterCallback: (double value) =>
                    '${english ? 'Aim angle' : 'Nişan açısı'} ${value.round()} degrees',
              ),
            ),
          ),
        ],
      ),
      Row(
        children: <Widget>[
          SizedBox(
            width: 68,
            child: Text(
              '${english ? 'POWER' : 'GÜÇ'}  ${power.toStringAsFixed(1)}',
              maxLines: 1,
              style: const TextStyle(
                color: StudioVisuals.muted,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                activeTrackColor: _BottleTargetPlayPageState._gold,
                thumbColor: _BottleTargetPlayPageState._gold,
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(
                key: const ValueKey<String>('bottle_power_slider'),
                value: power.clamp(.74, 1.42).toDouble(),
                min: .74,
                max: 1.42,
                onChanged: shotInFlight ? null : onPowerChanged,
                semanticFormatterCallback: (double value) =>
                    '${english ? 'Shot power' : 'Atış gücü'} ${value.toStringAsFixed(1)}',
              ),
            ),
          ),
          const SizedBox(width: 6),
          FilledButton.icon(
            key: const ValueKey<String>('bottle_fire'),
            onPressed: shotsLeft > 0 && !shotInFlight ? onFire : null,
            icon: const Icon(Icons.sports_baseball_rounded, size: 16),
            label: Text(english ? 'FIRE' : 'AT'),
            style: FilledButton.styleFrom(
              backgroundColor: _BottleTargetPlayPageState._accent,
              foregroundColor: Colors.white,
              minimumSize: const Size(76, 40),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              textStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
      Text(
        english
            ? 'Drag across the range to set aim, or use the precision controls.'
            : 'Nişanı sahnede sürükle ya da hassas kontrolleri kullan.',
        key: const ValueKey<String>('bottle_hint'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: StudioVisuals.muted,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _BottleRangePainter extends CustomPainter {
  _BottleRangePainter({
    required this.bottles,
    required this.obstacles,
    required this.shot,
    required this.angle,
    required this.power,
    required this.gravity,
    required this.targetsLeft,
    required this.elapsed,
    required this.paused,
    required this.english,
  });

  final List<_MutableBottle> bottles;
  final List<RangeObstacleSpec> obstacles;
  final _Shot? shot;
  final double angle;
  final double power;
  final double gravity;
  final int targetsLeft;
  final double elapsed;
  final bool paused;
  final bool english;

  static const Color _amber = Color(0xFFF0BE64);
  static const Color _mint = Color(0xFF83D0C2);
  static const Color _coral = Color(0xFFFF9C85);
  static const Color _glass = Color(0xFFBCE8E2);

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    final Paint background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          _BottleTargetPlayPageState._sceneTop,
          _BottleTargetPlayPageState._sceneBottom,
        ],
      ).createShader(bounds);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(24)),
      background,
    );
    _drawBackdrop(canvas, size);
    for (final RangeObstacleSpec obstacle in obstacles) {
      _drawObstacle(canvas, size, obstacle);
    }
    for (final _MutableBottle bottle in bottles) {
      if (bottle.standing) _drawBottle(canvas, size, bottle.spec);
    }
    _drawLauncher(canvas, size);
    _drawAimPreview(canvas, size);
    final _Shot? projectile = shot;
    if (projectile != null) _drawProjectile(canvas, size, projectile);
    if (paused) _drawPause(canvas, size);
  }

  void _drawBackdrop(Canvas canvas, Size size) {
    final Paint glow = Paint()
      ..shader =
          RadialGradient(
            colors: <Color>[
              const Color(0xFF5DA69B).withValues(alpha: .18),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * .5, size.height * .48),
              radius: size.width * .8,
            ),
          );
    canvas.drawRect(Offset.zero & size, glow);
    final double floorY = size.height * .79;
    final Paint floor = Paint()
      ..shader =
          const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFF436261), Color(0xFF263E42)],
          ).createShader(
            Rect.fromLTWH(0, floorY, size.width, size.height - floorY),
          );
    canvas.drawRect(
      Rect.fromLTWH(0, floorY, size.width, size.height - floorY),
      floor,
    );
    final Paint baseline = Paint()
      ..color = const Color(0xFFB5D0C8).withValues(alpha: .32)
      ..strokeWidth = 1;
    for (int mark = 1; mark <= 5; mark++) {
      final double x = size.width * mark / 6;
      canvas.drawLine(
        Offset(x, floorY),
        Offset(x, size.height * .825),
        baseline,
      );
    }
    final Paint rail = Paint()
      ..color = const Color(0xFFBDD6CE).withValues(alpha: .28)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(size.width * .07, floorY),
      Offset(size.width * .93, floorY),
      rail,
    );
    for (int i = 0; i < 3; i++) {
      final double x = size.width * (.20 + i * .30);
      final double pulse = .5 + .5 * math.sin(elapsed * .8 + i * 2);
      final Paint marker = Paint()
        ..color = _amber.withValues(alpha: .18 + pulse * .12);
      canvas.drawCircle(Offset(x, size.height * .12), 3 + pulse, marker);
    }
    final Paint vignette = Paint()
      ..shader = const RadialGradient(
        colors: <Color>[Colors.transparent, Color(0x55091318)],
        stops: <double>[.55, 1],
      ).createShader(boundsOf(size));
    canvas.drawRect(Offset.zero & size, vignette);
  }

  Rect boundsOf(Size size) => Offset.zero & size;

  void _drawObstacle(Canvas canvas, Size size, RangeObstacleSpec obstacle) {
    final Rect rect = Rect.fromCenter(
      center: Offset(size.width * obstacle.x, size.height * obstacle.y),
      width: size.width * obstacle.width,
      height: size.height * obstacle.height,
    );
    final RRect rounded = RRect.fromRectAndRadius(
      rect,
      Radius.circular(rect.height * .42),
    );
    final Paint shadow = Paint()
      ..color = Colors.black.withValues(alpha: .28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawRRect(rounded.shift(Offset(0, rect.height * .38)), shadow);
    final Paint body = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: obstacle.reflective
            ? const <Color>[
                Color(0xFFB6D8D4),
                Color(0xFF557B7C),
                Color(0xFF35565B),
              ]
            : const <Color>[
                Color(0xFFD5B477),
                Color(0xFF8F7651),
                Color(0xFF5A5143),
              ],
      ).createShader(rect);
    canvas.drawRRect(rounded, body);
    final Paint edge = Paint()
      ..color = Colors.white.withValues(alpha: .42)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(rounded, edge);
    if (obstacle.reflective) {
      final Paint glint = Paint()
        ..color = Colors.white.withValues(alpha: .72)
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(rect.left + rect.width * .16, rect.top + 2),
        Offset(rect.right - rect.width * .16, rect.top + 2),
        glint,
      );
    }
  }

  void _drawBottle(Canvas canvas, Size size, BottleSpec spec) {
    final Offset center = Offset(size.width * spec.x, size.height * spec.y);
    final double scale = size.width;
    final double width = scale * spec.radius * 1.45;
    final double height = width * (1.35 + (1.3 - spec.weight).clamp(0, .5));
    final Rect body = Rect.fromCenter(
      center: Offset(center.dx, center.dy + height * .12),
      width: width,
      height: height * .73,
    );
    final Rect neck = Rect.fromCenter(
      center: Offset(center.dx, body.top - height * .105),
      width: width * .34,
      height: height * .22,
    );
    final Color base = spec.kind == BottleKind.target
        ? _coral
        : const Color(0xFFE2D8B9);
    final Paint shadow = Paint()
      ..color = Colors.black.withValues(alpha: .38)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, body.bottom + 5),
        width: width * 1.55,
        height: 8,
      ),
      shadow,
    );
    final RRect bodyShape = RRect.fromRectAndRadius(
      body,
      Radius.circular(width * .2),
    );
    final Paint fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: <Color>[
          base.withValues(alpha: .58),
          base,
          base.withValues(alpha: .73),
        ],
      ).createShader(body);
    canvas.drawRRect(bodyShape, fill);
    canvas.drawRRect(
      RRect.fromRectAndRadius(neck, Radius.circular(width * .07)),
      Paint()..color = base,
    );
    final Rect shoulder = Rect.fromCenter(
      center: Offset(center.dx, body.top + height * .055),
      width: width * .68,
      height: height * .24,
    );
    canvas.drawOval(shoulder, Paint()..color = base.withValues(alpha: .92));
    final Paint glassEdge = Paint()
      ..color = _glass.withValues(alpha: .7)
      ..strokeWidth = math.max(1, width * .055)
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(bodyShape, glassEdge);
    final Paint shine = Paint()
      ..color = Colors.white.withValues(alpha: .65)
      ..strokeWidth = math.max(1.2, width * .065)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(body.left + width * .21, body.top + height * .10),
      Offset(body.left + width * .21, body.bottom - height * .12),
      shine,
    );
    final Rect label = Rect.fromCenter(
      center: Offset(center.dx, body.center.dy + height * .03),
      width: width * .64,
      height: height * .21,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(label, Radius.circular(label.height * .22)),
      Paint()
        ..color = spec.kind == BottleKind.target
            ? const Color(0xFFF6E6C6)
            : const Color(0xFFC2D8CB),
    );
    if (spec.kind == BottleKind.target) {
      final Paint targetMark = Paint()
        ..color = _BottleTargetPlayPageState._targetColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.3, width * .06);
      canvas.drawCircle(label.center, label.height * .27, targetMark);
      canvas.drawCircle(
        label.center,
        label.height * .08,
        Paint()..color = _BottleTargetPlayPageState._targetColor,
      );
    } else {
      final Paint leaf = Paint()
        ..color = const Color(0xFF5C9A75)
        ..strokeWidth = math.max(1, width * .055)
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(label.center.dx, label.top + 2),
        Offset(label.center.dx, label.bottom - 2),
        leaf,
      );
      canvas.drawLine(
        Offset(label.center.dx, label.center.dy),
        Offset(
          label.center.dx + label.width * .15,
          label.center.dy - label.height * .17,
        ),
        leaf,
      );
    }
    final Rect cap = Rect.fromCenter(
      center: Offset(neck.center.dx, neck.top + neck.height * .12),
      width: neck.width * 1.28,
      height: math.max(3, height * .045),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(cap, Radius.circular(cap.height * .3)),
      Paint()..color = _amber,
    );
  }

  void _drawLauncher(Canvas canvas, Size size) {
    final Offset origin = Offset(size.width * .5, size.height * .88);
    final double radius = size.width * .072;
    final Paint shadow = Paint()
      ..color = Colors.black.withValues(alpha: .44)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(origin.dx, origin.dy + radius * .7),
        width: radius * 2.8,
        height: radius * .8,
      ),
      shadow,
    );
    final Paint base = Paint()
      ..shader = const LinearGradient(
        colors: <Color>[
          Color(0xFFD2E4D9),
          Color(0xFF75938A),
          Color(0xFF405E5D),
        ],
      ).createShader(Rect.fromCircle(center: origin, radius: radius));
    canvas.drawCircle(origin, radius, base);
    canvas.drawCircle(
      origin,
      radius * .68,
      Paint()
        ..color = const Color(0xFF1E373D)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      origin,
      radius * .68,
      Paint()
        ..color = _glass.withValues(alpha: .78)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    final Paint stand = Paint()
      ..color = const Color(0xFFC8A16B)
      ..strokeWidth = radius * .23
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(origin.dx - radius * .43, origin.dy + radius * .48),
      Offset(origin.dx - radius * .8, origin.dy + radius * 1.25),
      stand,
    );
    canvas.drawLine(
      Offset(origin.dx + radius * .43, origin.dy + radius * .48),
      Offset(origin.dx + radius * .8, origin.dy + radius * 1.25),
      stand,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(origin.dx, origin.dy + radius * 1.25),
          width: radius * 2.2,
          height: radius * .30,
        ),
        Radius.circular(radius * .15),
      ),
      Paint()..color = const Color(0xFF8D7150),
    );
  }

  void _drawAimPreview(Canvas canvas, Size size) {
    if (shot != null || paused) return;
    final Offset origin = Offset(size.width * .5, size.height * .88);
    final double vx = math.cos(angle) * power;
    final double vy = math.sin(angle) * power;
    final Paint pathPaint = Paint()
      ..color = _mint.withValues(alpha: .47)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    double previousX = origin.dx;
    double previousY = origin.dy;
    for (int i = 1; i <= 19; i++) {
      final double t = i * .045;
      final double x = origin.dx + vx * t * size.width;
      final double y =
          origin.dy + (vy * t + .5 * gravity * t * t) * size.height;
      if (y < 0 || x < 0 || x > size.width) break;
      if (i % 2 == 0) {
        canvas.drawLine(Offset(previousX, previousY), Offset(x, y), pathPaint);
      }
      previousX = x;
      previousY = y;
    }
    final Paint arrow = Paint()
      ..color = _amber.withValues(alpha: .85)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final Offset tip = Offset(
      origin.dx + math.cos(angle) * size.width * .13,
      origin.dy + math.sin(angle) * size.height * .13,
    );
    canvas.drawLine(origin, tip, arrow);
  }

  void _drawProjectile(Canvas canvas, Size size, _Shot shot) {
    final Paint trailPaint = Paint()
      ..color = _amber.withValues(alpha: .56)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    for (int i = 1; i < shot.trail.length; i++) {
      final double alpha = i / shot.trail.length;
      trailPaint.color = _amber.withValues(alpha: alpha * .65);
      canvas.drawLine(
        Offset(
          shot.trail[i - 1].dx * size.width,
          shot.trail[i - 1].dy * size.height,
        ),
        Offset(shot.trail[i].dx * size.width, shot.trail[i].dy * size.height),
        trailPaint,
      );
    }
    final Offset center = Offset(shot.x * size.width, shot.y * size.height);
    canvas.drawCircle(
      center,
      size.width * .027,
      Paint()..color = _amber.withValues(alpha: .18),
    );
    canvas.drawCircle(
      center,
      size.width * .013,
      Paint()
        ..shader =
            const RadialGradient(
              colors: <Color>[
                Colors.white,
                Color(0xFFF4D27A),
                Color(0xFFB67B34),
              ],
            ).createShader(
              Rect.fromCircle(center: center, radius: size.width * .014),
            ),
    );
  }

  void _drawPause(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(24),
      ),
      Paint()..color = const Color(0xBB10252B),
    );
    final TextPainter label = TextPainter(
      text: TextSpan(
        text: english ? 'Ⅱ   PAUSED' : 'Ⅱ   DURAKLATILDI',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(
      canvas,
      Offset((size.width - label.width) / 2, size.height * .49),
    );
  }

  @override
  bool shouldRepaint(covariant _BottleRangePainter oldDelegate) =>
      oldDelegate.bottles != bottles ||
      oldDelegate.shot != shot ||
      oldDelegate.angle != angle ||
      oldDelegate.power != power ||
      oldDelegate.gravity != gravity ||
      oldDelegate.targetsLeft != targetsLeft ||
      oldDelegate.elapsed != elapsed ||
      oldDelegate.paused != paused ||
      oldDelegate.english != english;
}
