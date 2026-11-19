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
import 'balloon_scenario.dart';

class BalloonCatcherGamePage extends StatelessWidget {
  const BalloonCatcherGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  static const int totalCases = BalloonScenario.maximumLevels;
  static const int totalStars = totalCases * 3;

  static final List<ParkurLevelSpec> _levels = List<ParkurLevelSpec>.generate(
    totalCases,
    (int index) {
      final int level = index + 1;
      final int band = (level - 1) % 10 + 1;
      final String tr = switch (band) {
        <= 3 => 'Sepeti sürükle; hedef balonları yakalamayı öğren.',
        <= 6 => 'Renk sırasını izle; sis bulutlarına dikkat et.',
        7 || 8 => 'İleri: çapraz rüzgârda iki uçuş bandını birlikte oku.',
        9 => 'Uzman: renk değişimini ve dar yakalama aralığını yönet.',
        10 => 'Bölüm finali: art arda gelen hedef dalgasında üç hakkını koru.',
        _ => 'Usta rotası: rüzgâr, renk sırası ve yanıltıcı dalgayı birleştir.',
      };
      final String en = switch (band) {
        <= 3 => 'Drag the basket and learn to catch the target balloons.',
        <= 6 => 'Follow the color order and watch the storm clouds.',
        7 || 8 => 'Advanced: read two flight bands through crosswinds.',
        9 => 'Expert: manage color shifts and a narrow catch window.',
        10 => 'Section finale: keep all three lives through a target wave.',
        _ => 'Master the wind, color sequence and decoy wave together.',
      };
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Gökyüzü Rotası ${level.toString().padLeft(2, '0')}',
        titleEn: 'Sky Route ${level.toString().padLeft(2, '0')}',
        subtitleTr: tr,
        subtitleEn: en,
        difficulty: switch (band) {
          <= 6 => level <= 10 ? 'USTALAŞMA' : 'DERİNLEŞME',
          7 || 8 => 'İLERİ',
          9 => 'UZMAN',
          _ => 'USTA',
        },
        icon: Icons.air_rounded,
      );
    },
    growable: false,
  );

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.fun);
    return ParkurLevelHub(
      gameId: 'balloon_pop',
      progressPrefix: 'balloon_pop',
      titleTr: 'Balon Avcısı',
      titleEn: 'Balloon Catcher',
      taglineTr: 'Rüzgârı oku • Doğru balonları yakala',
      taglineEn: 'Read the wind • Catch the right balloons',
      accent: skin.accent,
      icon: Icons.air_rounded,
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
          ) => BalloonCatcherPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class BalloonCatcherPlayPage extends StatefulWidget {
  const BalloonCatcherPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<BalloonCatcherPlayPage> createState() => _BalloonCatcherPlayPageState();
}

class _BalloonFlight {
  _BalloonFlight({
    required this.id,
    required this.kind,
    required this.colorIndex,
    required this.baseX,
    required this.speed,
    required this.sway,
    required this.phase,
    required this.seed,
  });

  final int id;
  final BalloonObjectKind kind;
  final int colorIndex;
  final double baseX;
  final double speed;
  final double sway;
  final double phase;
  final int seed;
  double age = 0;
  double x = 0;
  double y = -.12;
  bool resolved = false;
}

class _CatchParticle {
  _CatchParticle(this.x, this.y, this.color, this.phase);

  final double x;
  final double y;
  final Color color;
  final double phase;
  double age = 0;
}

class _BalloonCatcherPlayPageState extends State<BalloonCatcherPlayPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const List<Color> _colors = <Color>[
    Color(0xFFE77E73),
    Color(0xFF4F9D9A),
    Color(0xFFE3AC54),
    Color(0xFF7187C5),
  ];
  static const Color _accent = Color(0xFF318C82);
  static const Color _ink = Color(0xFF25404A);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.fun,
  );
  final List<_BalloonFlight> _flights = <_BalloonFlight>[];
  final List<_CatchParticle> _particles = <_CatchParticle>[];

  late final Ticker _ticker;
  late BalloonScenario _scenario;
  late StudioGameSession _session;
  Duration _lastTick = Duration.zero;
  double _elapsed = 0;
  double _basketX = .5;
  int _spawnCursor = 0;
  int _catches = 0;
  int _lives = 3;
  int _score = 0;
  int _combo = 0;
  int _bestCombo = 0;
  int _errors = 0;
  bool _ready = false;
  bool _paused = false;
  bool _finished = false;
  bool _english = false;
  String? _hint;

  double get _timeLeft => math.max(0, _scenario.seconds - _elapsed);
  int get _activeColor =>
      _scenario.targetColors[(_catches ~/ _scenario.switchEvery) %
          _scenario.targetColors.length];
  int get _stars {
    if (_errors == 0 && _lives == _scenario.lives) return 3;
    if (_lives >= 2) return 2;
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
      if (!_paused && !_finished) {
        setState(() => _paused = true);
        _ticker.stop();
      }
    } else if (state == AppLifecycleState.resumed && _paused && !_finished) {
      setState(() => _paused = false);
      _lastTick = Duration.zero;
      _ticker.start();
    }
  }

  Future<void> _prepareScenario() async {
    BalloonScenario scenario = BalloonScenario.forLevel(widget.level.number);
    try {
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      final String visitKey = 'balloon_pop_level_${widget.level.number}_visits';
      final int visits = await preferences.getInt(visitKey) ?? 0;
      if (visits > 0) {
        final int index =
            await preferences.getInt('balloon_pop_practice_index') ?? 0;
        if (index < BalloonScenario.maximumPracticeRounds) {
          final int next = index + 1;
          await preferences.setInt('balloon_pop_practice_index', next);
          scenario = BalloonScenario.forPracticeRound(next);
        }
      }
      await preferences.setInt(visitKey, visits + 1);
    } catch (_) {
      scenario = BalloonScenario.forLevel(widget.level.number);
    }
    if (!mounted) return;
    _scenario = scenario;
    setState(() => _ready = true);
    _startRound();
  }

  void _startRound() {
    _ticker.stop();
    _elapsed = 0;
    _lastTick = Duration.zero;
    _basketX = .5;
    _spawnCursor = 0;
    _catches = 0;
    _lives = _scenario.lives;
    _score = 0;
    _combo = 0;
    _bestCombo = 0;
    _errors = 0;
    _flights.clear();
    _particles.clear();
    _paused = false;
    _finished = false;
    _hint = _english
        ? 'Drag the basket. Catch the outlined color; let storm clouds pass.'
        : 'Sepeti sürükle. Çerçeveli rengi yakala; sis bulutlarını bırak geçsin.';
    _session = StudioGameSession(
      level: widget.level.number,
      seed: _scenario.seed,
    )..start();
    if (mounted) setState(() {});
    _ticker.start();
  }

  void _tick(Duration elapsed) {
    if (!_ready || _paused || _finished) return;
    final double rawDelta = (elapsed - _lastTick).inMicroseconds / 1000000;
    _lastTick = elapsed;
    if (rawDelta <= 0) return;
    final double delta = rawDelta.clamp(0, .12).toDouble();
    _advance(delta);
    if (_catches >= _scenario.requiredCatches) {
      unawaited(_finish(completed: true));
    } else if (_lives <= 0 || _timeLeft <= 0) {
      unawaited(_finish(completed: false));
    }
    if (mounted && !_finished) setState(() {});
  }

  void _advance(double delta) {
    _elapsed += delta;
    while (_spawnCursor < _scenario.spawns.length &&
        _elapsed >= .18 + _spawnCursor * _scenario.spawnInterval) {
      final BalloonSpawnSpec spec = _scenario.spawns[_spawnCursor];
      final int color = switch (spec.kind) {
        BalloonObjectKind.target => _activeColor,
        BalloonObjectKind.decoy =>
          (_activeColor + spec.colorOffset) % _colors.length,
        BalloonObjectKind.storm => -1,
        BalloonObjectKind.star => -2,
      };
      final double x = .08 + spec.lane * .14;
      _flights.add(
        _BalloonFlight(
          id: _spawnCursor,
          kind: spec.kind,
          colorIndex: color,
          baseX: x,
          speed: spec.speed,
          sway: spec.sway,
          phase: spec.phase,
          seed: _scenario.seed ^ _spawnCursor,
        ),
      );
      _spawnCursor++;
    }

    for (final _BalloonFlight flight in _flights) {
      if (flight.resolved) continue;
      flight.age += delta;
      flight.y = -.10 + flight.age * flight.speed;
      flight.x =
          (flight.baseX +
                  math.sin(flight.age * 2.25 + flight.phase) * flight.sway +
                  math.sin(_elapsed * .42 + flight.phase * .27) *
                      _scenario.windStrength)
              .clamp(.035, .965)
              .toDouble();
      if (flight.y >= .82) {
        final double catchRange = _scenario.basketWidth / 2 + .037;
        if ((flight.x - _basketX).abs() <= catchRange) {
          _resolveCatch(flight);
        } else if (flight.y >= 1.04) {
          if (flight.kind == BalloonObjectKind.target) {
            _loseLife(flight.x, .93, _colors[flight.colorIndex]);
          }
          flight.resolved = true;
        }
      }
    }
    _flights.removeWhere((_BalloonFlight flight) => flight.resolved);
    for (final _CatchParticle particle in _particles) {
      particle.age += delta;
    }
    _particles.removeWhere((_CatchParticle particle) => particle.age > .65);
  }

  void _resolveCatch(_BalloonFlight flight) {
    flight.resolved = true;
    switch (flight.kind) {
      case BalloonObjectKind.target:
        if (flight.colorIndex == _activeColor) {
          _catches++;
          _combo++;
          _bestCombo = math.max(_bestCombo, _combo);
          final int points = 220 + math.min(_combo, 12) * 24;
          _score += points;
          _session.recordAccepted(points: points);
          _hint = _english
              ? 'Clean catch! Keep the chain alive.'
              : 'Temiz yakalama! Seriyi sürdür.';
          _emitCatch(flight.x, flight.y, _colors[flight.colorIndex]);
          _audio.hapticLight();
          unawaited(
            _audioProfile.play(_audio, GameAudioEvent.accepted, gain: .32),
          );
        } else {
          _loseLife(flight.x, flight.y, _colors[flight.colorIndex]);
        }
      case BalloonObjectKind.decoy:
        _loseLife(flight.x, flight.y, _colors[flight.colorIndex]);
      case BalloonObjectKind.storm:
        _loseLife(flight.x, flight.y, const Color(0xFF71818A));
      case BalloonObjectKind.star:
        _score += 420;
        _session.recordAccepted(points: 420);
        _hint = _english
            ? 'Bonus star secured. Your color target stays the same.'
            : 'Bonus yıldız alındı. Hedef rengin değişmedi.';
        _emitCatch(flight.x, flight.y, const Color(0xFFF0BF5A));
        _audio.hapticSelection();
        unawaited(
          _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .35),
        );
    }
  }

  void _loseLife(double x, double y, Color color) {
    _lives--;
    _errors++;
    _combo = 0;
    _session.recordMistake();
    _hint = _english
        ? 'Careful—wrong catch or missed target. The basket is still yours.'
        : 'Dikkat—yanlış yakalama ya da kaçan hedef. Sepet hâlâ sende.';
    _emitCatch(x, y, color);
    _audio.hapticHeavy();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .48));
  }

  void _emitCatch(double x, double y, Color color) {
    for (int i = 0; i < 7; i++) {
      _particles.add(
        _CatchParticle(
          x,
          y,
          color,
          (math.pi * 2 * i / 7) + ((_scenario.seed + i) % 17) * .11,
        ),
      );
    }
  }

  void _moveBasket(double dx, double width) {
    if (!_ready || _finished || _paused || width <= 0) return;
    setState(() {
      _basketX = (dx / width).clamp(.11, .89).toDouble();
    });
  }

  void _togglePause() {
    if (!_ready || _finished) return;
    setState(() => _paused = !_paused);
    if (_paused) {
      _ticker.stop();
      unawaited(_audio.play(GameSound.uiClick, gain: .25));
    } else {
      _lastTick = Duration.zero;
      _ticker.start();
      unawaited(_audio.play(GameSound.uiClick, gain: .25));
    }
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
              backgroundColor: StudioVisuals.surface,
              icon: const Icon(Icons.air_rounded, color: _accent, size: 34),
              title: Text(_english ? 'Flight ended' : 'Uçuş tamamlandı'),
              content: Text(
                _english
                    ? 'You caught $_catches / ${_scenario.requiredCatches} target balloons. Try the same route once more?'
                    : '$_catches / ${_scenario.requiredCatches} hedef balon yakaladın. Aynı rotayı yeniden denemek ister misin?',
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
        _startRound();
      } else {
        Navigator.of(context)
            .pop(StudioGameResult.failed(score: _score).toParkurResult());
      }
      return;
    }

    final int stars = _stars;
    _session.complete(
      stars: stars,
      action: widget.level.number < BalloonCatcherGamePage.totalCases
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
      titleTr: 'BALON ROTASI TAMAMLANDI',
      titleEn: 'BALLOON ROUTE COMPLETE',
      detailTr:
          '$_catches balon · En iyi seri $_bestCombo · $_lives hak kaldı.',
      detailEn:
          '$_catches balloons · Best chain $_bestCombo · $_lives lives left.',
      stars: stars,
      score: _score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < BalloonCatcherGamePage.totalCases,
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
        stars: stars,
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
          foregroundColor: StudioVisuals.ink,
          title: Text(_english ? 'BALLOON CATCHER' : 'BALON AVCISI'),
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
        titleSpacing: 14,
        title: Text(
          _english ? 'BALLOON CATCHER' : 'BALON AVCISI',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('balloon_pause'),
            tooltip: _paused
                ? (_english ? 'Resume' : 'Devam et')
                : (_english ? 'Pause' : 'Duraklat'),
            onPressed: _togglePause,
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
                  _BalloonHud(
                    caught: _catches,
                    goal: _scenario.requiredCatches,
                    lives: _lives,
                    timeLeft: _timeLeft.ceil(),
                    combo: _combo,
                    color: _colors[_activeColor],
                    colorIndex: _activeColor,
                    english: _english,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints limits) {
                        final double sceneHeight = math.min(
                          limits.maxHeight,
                          limits.maxWidth * 1.28,
                        );
                        return Center(
                          child: SizedBox(
                            width: limits.maxWidth,
                            height: sceneHeight,
                            child: GestureDetector(
                              key: const ValueKey<String>('balloon_scene'),
                              behavior: HitTestBehavior.opaque,
                              onPanStart: (DragStartDetails details) =>
                                  _moveBasket(
                                    details.localPosition.dx,
                                    limits.maxWidth,
                                  ),
                              onPanUpdate: (DragUpdateDetails details) =>
                                  _moveBasket(
                                    details.localPosition.dx,
                                    limits.maxWidth,
                                  ),
                              onTapDown: (TapDownDetails details) =>
                                  _moveBasket(
                                    details.localPosition.dx,
                                    limits.maxWidth,
                                  ),
                              child: RepaintBoundary(
                                child: CustomPaint(
                                  key: const ValueKey<String>(
                                    'balloon_scene_painter',
                                  ),
                                  painter: _BalloonScenePainter(
                                    flights: List<_BalloonFlight>.unmodifiable(
                                      _flights,
                                    ),
                                    particles: List<_CatchParticle>.unmodifiable(
                                      _particles,
                                    ),
                                    basketX: _basketX,
                                    elapsed: _elapsed,
                                    wind: _scenario.windStrength,
                                    level: widget.level.number,
                                    score: _score,
                                    targetColor: _colors[_activeColor],
                                    paused: _paused,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 5),
                  _BalloonControls(
                    value: _basketX,
                    hint: _hint ?? '',
                    english: _english,
                    onChanged: (double value) =>
                        setState(() => _basketX = value),
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

class _BalloonHud extends StatelessWidget {
  const _BalloonHud({
    required this.caught,
    required this.goal,
    required this.lives,
    required this.timeLeft,
    required this.combo,
    required this.color,
    required this.colorIndex,
    required this.english,
  });

  final int caught;
  final int goal;
  final int lives;
  final int timeLeft;
  final int combo;
  final Color color;
  final int colorIndex;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey<String>('balloon_hud'),
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
    decoration: BoxDecoration(
      color: StudioVisuals.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: StudioVisuals.line),
      boxShadow: StudioVisuals.softShadow,
    ),
    child: Row(
      children: <Widget>[
        Expanded(
          child: _HudMetric(
            label: english ? 'CATCH' : 'YAKALA',
            value: '$caught / $goal',
            icon: Icons.air_rounded,
            color: _BalloonCatcherPlayPageState._accent,
          ),
        ),
        const _HudDivider(),
        Expanded(
          child: Semantics(
            label: english
                ? 'Current target color ${colorIndex + 1}'
                : 'Sıradaki hedef renk ${colorIndex + 1}',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 31,
                  height: 31,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: .18),
                    border: Border.all(color: color, width: 2.5),
                  ),
                  child: Icon(Icons.air_rounded, color: color, size: 17),
                ),
                const SizedBox(width: 5),
                Text(
                  '${colorIndex + 1}',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
        const _HudDivider(),
        Expanded(
          child: _HudMetric(
            label: english ? 'TIME' : 'SÜRE',
            value: '${timeLeft}s',
            icon: Icons.timelapse_rounded,
            color: timeLeft <= 8
                ? StudioVisuals.danger
                : const Color(0xFFD39337),
          ),
        ),
        const _HudDivider(),
        Expanded(
          child: Semantics(
            label: english ? '$lives lives remaining' : '$lives hak kaldı',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Icon(
                  Icons.favorite_rounded,
                  color: lives < 2
                      ? StudioVisuals.danger
                      : const Color(0xFFD97872),
                  size: 17,
                ),
                const SizedBox(width: 3),
                Text(
                  '$lives',
                  style: const TextStyle(
                    color: _BalloonCatcherPlayPageState._ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _HudDivider extends StatelessWidget {
  const _HudDivider();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 25,
    color: StudioVisuals.line,
    margin: const EdgeInsets.symmetric(horizontal: 5),
  );
}

class _HudMetric extends StatelessWidget {
  const _HudMetric({
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
      Icon(icon, color: color, size: 17),
      const SizedBox(width: 3),
      Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: 1,
                style: const TextStyle(
                  color: StudioVisuals.muted,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .35,
                ),
              ),
            ),
            Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                color: _BalloonCatcherPlayPageState._ink,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _BalloonControls extends StatelessWidget {
  const _BalloonControls({
    required this.value,
    required this.hint,
    required this.english,
    required this.onChanged,
  });

  final double value;
  final String hint;
  final bool english;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Semantics(
        label: english ? 'Move catching basket' : 'Yakalama sepetini taşı',
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 5,
            activeTrackColor: _BalloonCatcherPlayPageState._accent,
            inactiveTrackColor: StudioVisuals.line,
            thumbColor: _BalloonCatcherPlayPageState._accent,
            overlayColor: _BalloonCatcherPlayPageState._accent.withValues(
              alpha: .12,
            ),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 21),
          ),
          child: Slider(
            key: const ValueKey<String>('balloon_basket_slider'),
            value: value.clamp(.11, .89).toDouble(),
            min: .11,
            max: .89,
            onChanged: onChanged,
          ),
        ),
      ),
      Text(
        hint,
        key: const ValueKey<String>('balloon_hint'),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: StudioVisuals.muted,
          fontSize: 10,
          height: 1.25,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _BalloonScenePainter extends CustomPainter {
  _BalloonScenePainter({
    required this.flights,
    required this.particles,
    required this.basketX,
    required this.elapsed,
    required this.wind,
    required this.level,
    required this.score,
    required this.targetColor,
    required this.paused,
  });

  final List<_BalloonFlight> flights;
  final List<_CatchParticle> particles;
  final double basketX;
  final double elapsed;
  final double wind;
  final int level;
  final int score;
  final Color targetColor;
  final bool paused;

  static const Color _skyTop = Color(0xFFD9F0EF);
  static const Color _skyBottom = Color(0xFFFFE8D7);
  static const List<Color> _colors = <Color>[
    Color(0xFFE77E73),
    Color(0xFF4F9D9A),
    Color(0xFFE3AC54),
    Color(0xFF7187C5),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(25)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[_skyTop, Color(0xFFEAF4E8), _skyBottom],
          stops: <double>[0, .64, 1],
        ).createShader(bounds),
    );
    _paintSun(canvas, size);
    _paintClouds(canvas, size);
    _paintHills(canvas, size);
    _paintWind(canvas, size);
    _paintFlights(canvas, size);
    _paintParticles(canvas, size);
    _paintGround(canvas, size);
    _paintBasket(canvas, size);
    _paintFrame(canvas, size);
    if (paused) _paintPauseVeil(canvas, size);
  }

  void _paintSun(Canvas canvas, Size size) {
    final Offset center = Offset(size.width * .80, size.height * .18);
    canvas.drawCircle(
      center,
      size.width * .14,
      Paint()
        ..shader =
            RadialGradient(
              colors: <Color>[
                const Color(0xFFFFF4CF).withValues(alpha: .48),
                const Color(0xFFFFF4CF).withValues(alpha: 0),
              ],
            ).createShader(
              Rect.fromCircle(center: center, radius: size.width * .14),
            ),
    );
    canvas.drawCircle(
      center,
      size.width * .058,
      Paint()..color = const Color(0xFFFFE6A9).withValues(alpha: .9),
    );
  }

  void _paintClouds(Canvas canvas, Size size) {
    final Paint cloud = Paint()..color = Colors.white.withValues(alpha: .62);
    final List<(double, double, double)> clouds = <(double, double, double)>[
      (.16, .18, .06),
      (.55, .32, .045),
      (.85, .43, .055),
    ];
    for (int i = 0; i < clouds.length; i++) {
      final (double x, double y, double radius) = clouds[i];
      final double drift =
          math.sin(elapsed * .11 + i * 2.1) * size.width * .012;
      final Offset center = Offset(x * size.width + drift, y * size.height);
      final double r = size.width * radius;
      canvas.drawOval(
        Rect.fromCenter(
          center: center.translate(0, r * .28),
          width: r * 3.2,
          height: r * 1.0,
        ),
        cloud,
      );
      canvas.drawCircle(center.translate(-r * .65, 0), r * .64, cloud);
      canvas.drawCircle(center, r * .88, cloud);
      canvas.drawCircle(center.translate(r * .7, r * .12), r * .56, cloud);
    }
  }

  void _paintHills(Canvas canvas, Size size) {
    final Path far = Path()
      ..moveTo(0, size.height * .70)
      ..cubicTo(
        size.width * .19,
        size.height * .59,
        size.width * .26,
        size.height * .73,
        size.width * .45,
        size.height * .67,
      )
      ..cubicTo(
        size.width * .61,
        size.height * .60,
        size.width * .81,
        size.height * .72,
        size.width,
        size.height * .62,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(far, Paint()..color = const Color(0xFFAFCFC5));
    final Path near = Path()
      ..moveTo(0, size.height * .80)
      ..cubicTo(
        size.width * .18,
        size.height * .70,
        size.width * .37,
        size.height * .82,
        size.width * .58,
        size.height * .76,
      )
      ..cubicTo(
        size.width * .76,
        size.height * .70,
        size.width * .89,
        size.height * .79,
        size.width,
        size.height * .73,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(near, Paint()..color = const Color(0xFF8FB9A7));
  }

  void _paintWind(Canvas canvas, Size size) {
    final Paint line = Paint()
      ..color = const Color(0xFF579A9A).withValues(alpha: .28)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 3; i++) {
      final double y = size.height * (.38 + i * .075);
      final double start = size.width * (.08 + i * .14);
      final double length = size.width * (.12 + wind * 1.5);
      final Path path = Path()
        ..moveTo(start + math.sin(elapsed * .48 + i) * 5, y)
        ..cubicTo(
          start + length * .38,
          y - 5,
          start + length * .72,
          y + 5,
          start + length,
          y,
        );
      canvas.drawPath(path, line);
    }
  }

  void _paintFlights(Canvas canvas, Size size) {
    for (final _BalloonFlight flight in flights) {
      final Offset center = Offset(
        flight.x * size.width,
        flight.y * size.height,
      );
      switch (flight.kind) {
        case BalloonObjectKind.target:
        case BalloonObjectKind.decoy:
          _paintBalloon(canvas, center, size.width, flight.colorIndex);
        case BalloonObjectKind.storm:
          _paintStorm(canvas, center, size.width, flight.seed);
        case BalloonObjectKind.star:
          _paintStar(canvas, center, size.width);
      }
    }
  }

  void _paintBalloon(Canvas canvas, Offset center, double width, int index) {
    final double rx = width * .054;
    final double ry = rx * 1.17;
    final Color color = _palette(index);
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, ry * .26),
        width: rx * 1.9,
        height: ry * .55,
      ),
      Paint()..color = const Color(0xFF42575B).withValues(alpha: .14),
    );
    final Path body = Path()
      ..moveTo(center.dx, center.dy - ry)
      ..cubicTo(
        center.dx + rx * 1.07,
        center.dy - ry * .94,
        center.dx + rx * 1.22,
        center.dy + ry * .04,
        center.dx + rx * .56,
        center.dy + ry * .65,
      )
      ..quadraticBezierTo(
        center.dx + rx * .3,
        center.dy + ry * .91,
        center.dx,
        center.dy + ry * .91,
      )
      ..quadraticBezierTo(
        center.dx - rx * .3,
        center.dy + ry * .91,
        center.dx - rx * .56,
        center.dy + ry * .65,
      )
      ..cubicTo(
        center.dx - rx * 1.22,
        center.dy + ry * .04,
        center.dx - rx * 1.07,
        center.dy - ry * .94,
        center.dx,
        center.dy - ry,
      )
      ..close();
    canvas.drawShadow(body, const Color(0x44384B52), 3, true);
    canvas.drawPath(
      body,
      Paint()
        ..shader =
            RadialGradient(
              center: const Alignment(-.38, -.42),
              radius: 1.15,
              colors: <Color>[
                color.withValues(alpha: .72),
                color,
                _shade(color),
              ],
              stops: const <double>[0, .58, 1],
            ).createShader(
              Rect.fromCenter(
                center: center,
                width: rx * 2.5,
                height: ry * 2.2,
              ),
            ),
    );
    final Path rib = Path()
      ..moveTo(center.dx - rx * .1, center.dy - ry * .72)
      ..quadraticBezierTo(
        center.dx + rx * .13,
        center.dy,
        center.dx,
        center.dy + ry * .72,
      );
    canvas.drawPath(
      rib,
      Paint()
        ..color = Colors.white.withValues(alpha: .20)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(-rx * .43, -ry * .38),
        width: rx * .26,
        height: ry * .52,
      ),
      Paint()..color = Colors.white.withValues(alpha: .74),
    );
    final Path knot = Path()
      ..moveTo(center.dx - rx * .14, center.dy + ry * .77)
      ..lineTo(center.dx + rx * .14, center.dy + ry * .77)
      ..lineTo(center.dx, center.dy + ry * 1.04)
      ..close();
    canvas.drawPath(knot, Paint()..color = _shade(color));
    final Path string = Path()
      ..moveTo(center.dx, center.dy + ry * 1.02)
      ..cubicTo(
        center.dx + rx * .2,
        center.dy + ry * 1.45,
        center.dx - rx * .17,
        center.dy + ry * 1.63,
        center.dx + rx * .05,
        center.dy + ry * 2.03,
      );
    canvas.drawPath(
      string,
      Paint()
        ..color = const Color(0xFF697E7A).withValues(alpha: .75)
        ..strokeWidth = 1.1
        ..style = PaintingStyle.stroke,
    );
    if (index == colorIndexForTarget) {
      canvas.drawCircle(
        center,
        rx * 1.4,
        Paint()
          ..color = targetColor.withValues(alpha: .72)
          ..strokeWidth = 1.7
          ..style = PaintingStyle.stroke,
      );
    }
  }

  int get colorIndexForTarget {
    for (int index = 0; index < _colors.length; index++) {
      if (_colors[index] == targetColor) return index;
    }
    return -99;
  }

  void _paintStorm(Canvas canvas, Offset center, double width, int seed) {
    final double radius = width * .047;
    final Path cloud = Path()
      ..moveTo(center.dx - radius * 1.25, center.dy + radius * .26)
      ..cubicTo(
        center.dx - radius * 1.45,
        center.dy - radius * .23,
        center.dx - radius * 1.08,
        center.dy - radius * .72,
        center.dx - radius * .56,
        center.dy - radius * .58,
      )
      ..cubicTo(
        center.dx - radius * .38,
        center.dy - radius * 1.32,
        center.dx + radius * .58,
        center.dy - radius * 1.26,
        center.dx + radius * .67,
        center.dy - radius * .51,
      )
      ..cubicTo(
        center.dx + radius * 1.43,
        center.dy - radius * .51,
        center.dx + radius * 1.51,
        center.dy + radius * .42,
        center.dx + radius * .89,
        center.dy + radius * .55,
      )
      ..lineTo(center.dx - radius * .78, center.dy + radius * .55)
      ..close();
    canvas.drawShadow(cloud, const Color(0x3343535E), 2, true);
    canvas.drawPath(
      cloud,
      Paint()
        ..shader =
            const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[Color(0xFFA4B4B9), Color(0xFF788E96)],
            ).createShader(
              Rect.fromCenter(
                center: center,
                width: radius * 3,
                height: radius * 2,
              ),
            ),
    );
    final Paint bolt = Paint()
      ..color = seed.isEven ? const Color(0xFFFFD58B) : Colors.white
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final Path lightning = Path()
      ..moveTo(center.dx + radius * .18, center.dy + radius * .45)
      ..lineTo(center.dx - radius * .08, center.dy + radius * .87)
      ..lineTo(center.dx + radius * .17, center.dy + radius * .84)
      ..lineTo(center.dx - radius * .10, center.dy + radius * 1.22);
    canvas.drawPath(lightning, bolt);
  }

  void _paintStar(Canvas canvas, Offset center, double width) {
    final double radius = width * .044;
    final Path star = Path();
    for (int point = 0; point < 10; point++) {
      final double angle = -math.pi / 2 + point * math.pi / 5;
      final double r = point.isEven ? radius : radius * .46;
      final Offset position =
          center + Offset(math.cos(angle) * r, math.sin(angle) * r);
      if (point == 0) {
        star.moveTo(position.dx, position.dy);
      } else {
        star.lineTo(position.dx, position.dy);
      }
    }
    star.close();
    canvas.drawShadow(star, const Color(0x887D5D23), 5, true);
    canvas.drawPath(
      star,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFFFE7A0), Color(0xFFE5A943)],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center.translate(-radius * .24, -radius * .25),
      radius * .14,
      Paint()..color = Colors.white.withValues(alpha: .9),
    );
  }

  void _paintParticles(Canvas canvas, Size size) {
    for (final _CatchParticle particle in particles) {
      final double progress = (particle.age / .65).clamp(0, 1).toDouble();
      final double radius = size.width * .008 * (1 - progress);
      final double distance = size.width * (.035 + progress * .11);
      final Offset center = Offset(
        particle.x * size.width + math.cos(particle.phase) * distance,
        particle.y * size.height + math.sin(particle.phase) * distance,
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = particle.color.withValues(alpha: 1 - progress),
      );
    }
  }

  void _paintGround(Canvas canvas, Size size) {
    final Rect ground = Rect.fromLTWH(
      0,
      size.height * .895,
      size.width,
      size.height * .105,
    );
    canvas.drawRect(
      ground,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFFC5DCC8), Color(0xFFB8D1C0)],
        ).createShader(ground),
    );
    final Paint grass = Paint()
      ..color = const Color(0xFF789F86).withValues(alpha: .7)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 13; i++) {
      final double x = size.width * (i / 13);
      final double y = size.height * .91 + (i.isEven ? 4 : 0);
      canvas.drawLine(Offset(x, y), Offset(x + 3, y - 6), grass);
    }
  }

  void _paintBasket(Canvas canvas, Size size) {
    final Offset center = Offset(basketX * size.width, size.height * .89);
    final double width = size.width * .28;
    final double height = size.height * .07;
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, height * .94),
        width: width * .87,
        height: height * .2,
      ),
      Paint()..color = const Color(0xFF375A55).withValues(alpha: .2),
    );
    final Rect bodyRect = Rect.fromCenter(
      center: center.translate(0, height * .47),
      width: width,
      height: height,
    );
    final Path basket = Path()
      ..moveTo(bodyRect.left, bodyRect.top)
      ..lineTo(bodyRect.right, bodyRect.top)
      ..lineTo(bodyRect.right - width * .14, bodyRect.bottom)
      ..quadraticBezierTo(
        center.dx,
        bodyRect.bottom + height * .10,
        bodyRect.left + width * .14,
        bodyRect.bottom,
      )
      ..close();
    canvas.drawShadow(basket, const Color(0x55334C43), 4, true);
    canvas.drawPath(
      basket,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFDDA96B), Color(0xFFB97843)],
        ).createShader(bodyRect),
    );
    final Paint weave = Paint()
      ..color = const Color(0xFF805737).withValues(alpha: .57)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (int i = 1; i <= 3; i++) {
      final double y = bodyRect.top + bodyRect.height * i / 4;
      final double inset = width * .14 * i / 4;
      canvas.drawLine(
        Offset(bodyRect.left + inset, y),
        Offset(bodyRect.right - inset, y),
        weave,
      );
    }
    for (int i = -2; i <= 2; i++) {
      final double x = center.dx + i * width * .115;
      canvas.drawLine(
        Offset(x, bodyRect.top + 1),
        Offset(center.dx + i * width * .084, bodyRect.bottom),
        weave,
      );
    }
    final Rect rim = Rect.fromCenter(
      center: center.translate(0, height * .08),
      width: width * 1.08,
      height: height * .25,
    );
    canvas.drawOval(rim, Paint()..color = const Color(0xFFECC98B));
    canvas.drawOval(
      rim,
      Paint()
        ..color = const Color(0xFF92613E)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  void _paintFrame(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(25)),
      Paint()
        ..color = Colors.white.withValues(alpha: .48)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke,
    );
  }

  void _paintPauseVeil(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(25)),
      Paint()..color = const Color(0xBFFFFFFF),
    );
    final TextPainter painter = TextPainter(
      text: const TextSpan(
        text: 'Ⅱ',
        style: TextStyle(
          color: _BalloonCatcherPlayPageState._ink,
          fontSize: 58,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(
        (size.width - painter.width) / 2,
        (size.height - painter.height) / 2,
      ),
    );
  }

  Color _palette(int index) =>
      _colors[index.clamp(0, _colors.length - 1).toInt()];

  Color _shade(Color color) => Color.lerp(color, const Color(0xFF263F4A), .24)!;

  @override
  bool shouldRepaint(covariant _BalloonScenePainter oldDelegate) => true;
}
