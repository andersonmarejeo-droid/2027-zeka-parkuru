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
import 'mini_golf_engine.dart';
import 'mini_golf_scenario.dart';

class MiniGolfGamePage extends StatelessWidget {
  const MiniGolfGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  static const int totalCases = MiniGolfScenario.maximumLevels;
  static const int totalStars = totalCases * 3;

  static final List<ParkurLevelSpec>
  _levels = List<ParkurLevelSpec>.generate(totalCases, (int index) {
    final int level = index + 1;
    final String tr = switch (level) {
      <= 3 => 'Geri çek, açıyı ayarla ve ilk yeşil hattı oku.',
      <= 6 => 'Çim-kum farkını kullan, kapının ritminde güç seç.',
      7 || 8 => 'İleri: spin, rüzgâr ve taş sekmesini birleştir.',
      9 => 'Uzman: beş vuruşta hareketli kapı ve dar finişi çöz.',
      _ => 'Usta finali: rüzgârda üç-par parkurunu hassas bırakışlarla bitir.',
    };
    final String en = switch (level) {
      <= 3 => 'Pull back, set your angle and read the first green line.',
      <= 6 => 'Use grass/sand friction and time power to the moving gate.',
      7 || 8 => 'Advanced: combine spin, wind and stone-bank rebounds.',
      9 => 'Expert: solve the moving gate and narrow finish in five strokes.',
      _ =>
        'Master finale: finish a windy par-three course with precision putts.',
    };
    return ParkurLevelSpec(
      number: level,
      titleTr: 'Yeşil Parkur ${level.toString().padLeft(2, '0')}',
      titleEn: 'Green Course ${level.toString().padLeft(2, '0')}',
      subtitleTr: tr,
      subtitleEn: en,
      difficulty: switch (level) {
        <= 3 => 'USTALAŞMA',
        <= 6 => 'DERİNLEŞME',
        7 || 8 => 'İLERİ',
        9 => 'UZMAN',
        _ => 'USTA',
      },
      icon: Icons.sports_golf_rounded,
    );
  }, growable: false);

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.fun);
    return ParkurLevelHub(
      gameId: 'mini_golf_route',
      progressPrefix: 'mini_golf_route',
      titleTr: 'Mini Golf Rota',
      titleEn: 'Mini Golf Route',
      taglineTr: 'Açı seç • Zemini oku • Parı yakala',
      taglineEn: 'Pick a line • Read the surface • Beat par',
      accent: skin.accent,
      icon: Icons.sports_golf_rounded,
      levels: _levels,
      dailyCourseMode: dailyCourseMode,
      competitionLevel: competitionLevel,
      competitionLayoutCode: competitionLayoutCode,
      playBuilder: (
        BuildContext context,
        ParkurLevelSpec level,
        int previousBestScore,
        int? competitionLayoutCode,
        bool competitionMode,
      ) => MiniGolfPlayPage(level: level, previousBestScore: previousBestScore),
    );
  }
}

class MiniGolfPlayPage extends StatefulWidget {
  const MiniGolfPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<MiniGolfPlayPage> createState() => _MiniGolfPlayPageState();
}

class _MiniGolfPlayPageState extends State<MiniGolfPlayPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const Color _ink = Color(0xFF33453F);
  static const Color _accent = Color(0xFF318C82);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.fun,
  );
  late final Ticker _ticker;
  late MiniGolfScenario _scenario;
  late MiniGolfEngine _engine;
  late StudioGameSession _session;
  Duration _lastTick = Duration.zero;
  double _elapsed = 0;
  double _worldHeight = 1.1;
  double _aimX = 0;
  double _aimY = -1;
  double _power = .43;
  int _spin = 0;
  int _strokes = 0;
  int _contacts = 0;
  int _score = 0;
  bool _inMotion = false;
  bool _inSand = false;
  bool _ready = false;
  bool _paused = false;
  bool _finished = false;
  bool _english = false;

  int get _stars {
    if (_strokes <= _scenario.par && _contacts == 0) return 3;
    if (_strokes <= _scenario.par + 1) return 2;
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
      if (_ready && !_paused && !_finished) _setPaused(true);
    } else if (state == AppLifecycleState.resumed && _paused && !_finished) {
      _setPaused(false);
    }
  }

  Future<void> _prepareScenario() async {
    MiniGolfScenario scenario = MiniGolfScenario.forLevel(widget.level.number);
    try {
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      final String visitKey =
          'mini_golf_route_level_${widget.level.number}_visits';
      final int visits = await preferences.getInt(visitKey) ?? 0;
      if (visits > 0) {
        final int index =
            await preferences.getInt('mini_golf_route_practice_index') ?? 0;
        if (index < MiniGolfScenario.maximumPracticeRounds) {
          final int next = index + 1;
          await preferences.setInt('mini_golf_route_practice_index', next);
          scenario = MiniGolfScenario.forPracticeRound(next);
        }
      }
      await preferences.setInt(visitKey, visits + 1);
    } catch (_) {
      scenario = MiniGolfScenario.forLevel(widget.level.number);
    }
    if (!mounted) return;
    _scenario = scenario;
    _startRound();
    setState(() => _ready = true);
  }

  void _startRound() {
    _ticker.stop();
    _engine = MiniGolfEngine(scenario: _scenario);
    _elapsed = 0;
    _strokes = 0;
    _contacts = 0;
    _score = 0;
    _spin = 0;
    _inMotion = false;
    _inSand = false;
    _paused = false;
    _finished = false;
    _lastTick = Duration.zero;
    _setAimTowardCup();
    _session = StudioGameSession(
      level: widget.level.number,
      seed: _scenario.seed,
    )..start();
    _ticker.start();
  }

  void _setAimTowardCup() {
    final double dx = _scenario.hole.x - _engine.ball.x;
    final double dy = (_scenario.hole.y - _engine.ball.y) * _worldHeight;
    final double length = math.max(.001, math.sqrt(dx * dx + dy * dy));
    _aimX = dx / length;
    _aimY = dy / length;
    _power = (.43 - widget.level.number * .008).clamp(.28, .42).toDouble();
  }

  void _setPaused(bool paused) {
    if (!_ready || _finished || _paused == paused) return;
    setState(() => _paused = paused);
    if (paused) {
      _session.pause();
      _ticker.stop();
    } else {
      _session.resume();
      _lastTick = Duration.zero;
      _ticker.start();
    }
    unawaited(_audio.play(GameSound.uiClick, gain: .24));
  }

  void _aimAt(Offset localPosition, double width) {
    if (_inMotion || _paused || _finished) return;
    final double px = localPosition.dx / width;
    final double py = localPosition.dy / width;
    final double dx = _engine.ball.x - px;
    final double dy = _engine.ball.y - py;
    final double distance = math.sqrt(dx * dx + dy * dy);
    if (distance < .025) return;
    setState(() {
      _aimX = dx / distance;
      _aimY = dy / distance;
      _power = (distance * 2.45).clamp(.16, .98).toDouble();
    });
  }

  void _chooseSpin(int spin) {
    if (_inMotion || _paused || _finished) return;
    setState(() => _spin = spin);
    _audio.hapticSelection();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .20),
    );
  }

  void _strike() {
    if (_inMotion ||
        _paused ||
        _finished ||
        _strokes >= _scenario.strokeLimit) {
      return;
    }
    if (!_engine.strike(
      directionX: _aimX,
      directionY: _aimY,
      power: _power,
      spin: _spin,
    )) {
      return;
    }
    _strokes++;
    _inMotion = true;
    _inSand = false;
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .28),
    );
    _audio.hapticLight();
    setState(() {});
  }

  void _tick(Duration elapsed) {
    if (!_ready || _paused || _finished) return;
    final double raw = (elapsed - _lastTick).inMicroseconds / 1000000;
    _lastTick = elapsed;
    if (raw <= 0) return;
    final double delta = raw.clamp(0, .032).toDouble();
    _elapsed += delta;
    if (_inMotion) {
      final GolfStepResult result = _engine.step(
        deltaSeconds: delta,
        worldHeight: _worldHeight,
        elapsedSeconds: _elapsed,
      );
      _inSand = result.inSand;
      if (result.gateBounce || result.bumperHit) {
        _contacts++;
        _session.recordMistake();
        unawaited(
          _audioProfile.play(_audio, GameAudioEvent.rejected, gain: .20),
        );
      }
      if (result.enteredHole) {
        _inMotion = false;
        _score = math.max(100, 1000 - _strokes * 95 - _contacts * 25);
        _session.recordAccepted(points: _score);
        unawaited(
          _audioProfile.play(_audio, GameAudioEvent.accepted, gain: .30),
        );
        unawaited(_finish(completed: true));
      } else if (_engine.isSettled) {
        _inMotion = false;
        if (_strokes >= _scenario.strokeLimit) {
          unawaited(_finish(completed: false));
        } else {
          _setAimTowardCup();
          if (mounted) setState(() {});
        }
      }
    }
    if (mounted && !_finished && (!_inMotion || raw > 0)) setState(() {});
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
              title: Text(_english ? 'Out of strokes' : 'Vuruş hakkı doldu'),
              content: Text(
                _english
                    ? 'The cup is still open. Re-read the surface and try the hole again?'
                    : 'Delik henüz bitmedi. Zemini yeniden okuyup parkuru tekrar deneyelim mi?',
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
            .pop(StudioGameResult.failed(score: 0).toParkurResult());
      }
      return;
    }

    _session.complete(
      stars: _stars,
      action: widget.level.number < MiniGolfGamePage.totalCases
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
      titleTr: 'YEŞİL PARKUR TAMAMLANDI',
      titleEn: 'GREEN COURSE COMPLETE',
      detailTr: '$_strokes vuruş · Par ${_scenario.par} · $_contacts temas.',
      detailEn:
          '$_strokes strokes · Par ${_scenario.par} · $_contacts contacts.',
      stars: _stars,
      score: _score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < MiniGolfGamePage.totalCases,
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
          title: Text(_english ? 'MINI GOLF ROUTE' : 'MİNİ GOLF ROTA'),
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
          _english ? 'MINI GOLF ROUTE' : 'MİNİ GOLF ROTA',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('mini_golf_pause'),
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
              padding: const EdgeInsets.fromLTRB(13, 6, 13, 7),
              child: Column(
                children: <Widget>[
                  _GolfHud(
                    strokes: _strokes,
                    par: _scenario.par,
                    strokeLimit: _scenario.strokeLimit,
                    inSand: _inSand,
                    english: _english,
                  ),
                  const SizedBox(height: 7),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints limits) {
                        final double width = math.min(limits.maxWidth, 570);
                        final double height = math.min(
                          limits.maxHeight,
                          width * 1.18,
                        );
                        _worldHeight = width <= 0 ? 1.1 : height / width;
                        return Center(
                          child: SizedBox(
                            width: width,
                            height: height,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapDown: (TapDownDetails details) =>
                                  _aimAt(details.localPosition, width),
                              onPanUpdate: (DragUpdateDetails details) =>
                                  _aimAt(details.localPosition, width),
                              child: CustomPaint(
                                key: const ValueKey<String>('mini_golf_scene'),
                                painter: _MiniGolfPainter(
                                  scenario: _scenario,
                                  engine: _engine,
                                  worldHeight: _worldHeight,
                                  elapsed: _elapsed,
                                  aimX: _aimX,
                                  aimY: _aimY,
                                  power: _power,
                                  spin: _spin,
                                  inMotion: _inMotion,
                                  inSand: _inSand,
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
                  const SizedBox(height: 6),
                  _GolfControls(
                    spin: _spin,
                    power: _power,
                    canStrike:
                        !_inMotion &&
                        !_paused &&
                        !_finished &&
                        _strokes < _scenario.strokeLimit,
                    english: _english,
                    onSpin: _chooseSpin,
                    onStrike: _strike,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _english
                        ? 'Drag backward from the ball to set line and power, choose spin, then putt through the moving gate.'
                        : 'Açı ve gücü ayarlamak için bilyeden geriye sürükle; spin seçip hareketli kapıdan vuruş yap.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: StudioVisuals.muted,
                      fontSize: 9,
                      height: 1.2,
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

class _GolfHud extends StatelessWidget {
  const _GolfHud({
    required this.strokes,
    required this.par,
    required this.strokeLimit,
    required this.inSand,
    required this.english,
  });

  final int strokes;
  final int par;
  final int strokeLimit;
  final bool inSand;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey<String>('mini_golf_hud'),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: StudioVisuals.surface,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: StudioVisuals.line),
      boxShadow: StudioVisuals.softShadow,
    ),
    child: Row(
      children: <Widget>[
        Expanded(
          child: _GolfMetric(
            label: english ? 'STROKES' : 'VURUŞ',
            value: '$strokes / $strokeLimit',
            icon: Icons.sports_golf_rounded,
            color: _MiniGolfPlayPageState._accent,
          ),
        ),
        Container(width: 1, height: 28, color: StudioVisuals.line),
        Expanded(
          child: _GolfMetric(
            label: english ? 'COURSE PAR' : 'PARKUR PARI',
            value: 'PAR $par',
            icon: Icons.flag_rounded,
            color: const Color(0xFFD3A55F),
          ),
        ),
        Container(width: 1, height: 28, color: StudioVisuals.line),
        Expanded(
          child: _GolfMetric(
            label: english ? 'SURFACE' : 'ZEMİN',
            value: inSand
                ? (english ? 'SAND' : 'KUM')
                : (english ? 'GREEN' : 'ÇİM'),
            icon: inSand ? Icons.grain_rounded : Icons.grass_rounded,
            color: inSand ? const Color(0xFFC69A5A) : const Color(0xFF5F9E77),
          ),
        ),
      ],
    ),
  );
}

class _GolfMetric extends StatelessWidget {
  const _GolfMetric({
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
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 4),
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
                fontSize: 7.2,
                fontWeight: FontWeight.w900,
                letterSpacing: .2,
              ),
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _MiniGolfPlayPageState._ink,
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

class _GolfControls extends StatelessWidget {
  const _GolfControls({
    required this.spin,
    required this.power,
    required this.canStrike,
    required this.english,
    required this.onSpin,
    required this.onStrike,
  });

  final int spin;
  final double power;
  final bool canStrike;
  final bool english;
  final ValueChanged<int> onSpin;
  final VoidCallback onStrike;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(6, 5, 6, 5),
    decoration: BoxDecoration(
      color: StudioVisuals.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: StudioVisuals.line),
    ),
    child: Row(
      children: <Widget>[
        for (final (int value, IconData icon) option in const <(int, IconData)>[
          (-1, Icons.rotate_left_rounded),
          (0, Icons.circle_outlined),
          (1, Icons.rotate_right_rounded),
        ])
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: IconButton.filledTonal(
              key: ValueKey<String>('mini_golf_spin_${option.$1}'),
              onPressed: canStrike ? () => onSpin(option.$1) : null,
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(
                backgroundColor: spin == option.$1
                    ? const Color(0xFFDDEDE4)
                    : const Color(0xFFF4F1EB),
                foregroundColor: spin == option.$1
                    ? _MiniGolfPlayPageState._accent
                    : StudioVisuals.muted,
              ),
              icon: Icon(option.$2, size: 18),
              tooltip: option.$1 < 0
                  ? (english ? 'Left spin' : 'Sol spin')
                  : option.$1 > 0
                  ? (english ? 'Right spin' : 'Sağ spin')
                  : (english ? 'No spin' : 'Spin yok'),
            ),
          ),
        const SizedBox(width: 5),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${english ? 'POWER' : 'GÜÇ'} ${(power * 100).round()}%',
                maxLines: 1,
                style: const TextStyle(
                  color: StudioVisuals.muted,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  minHeight: 5,
                  value: power,
                  backgroundColor: const Color(0xFFE6E4DC),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    _MiniGolfPlayPageState._accent,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 43,
          child: FilledButton.icon(
            key: const ValueKey<String>('mini_golf_strike'),
            onPressed: canStrike ? onStrike : null,
            style: FilledButton.styleFrom(
              backgroundColor: _MiniGolfPlayPageState._accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.sports_golf_rounded, size: 17),
            label: Text(
              english ? 'PUTT' : 'VUR',
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    ),
  );
}

class _MiniGolfPainter extends CustomPainter {
  const _MiniGolfPainter({
    required this.scenario,
    required this.engine,
    required this.worldHeight,
    required this.elapsed,
    required this.aimX,
    required this.aimY,
    required this.power,
    required this.spin,
    required this.inMotion,
    required this.inSand,
    required this.paused,
    required this.english,
  });

  final MiniGolfScenario scenario;
  final MiniGolfEngine engine;
  final double worldHeight;
  final double elapsed;
  final double aimX;
  final double aimY;
  final double power;
  final int spin;
  final bool inMotion;
  final bool inSand;
  final bool paused;
  final bool english;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final double height = size.height / size.width;
    canvas.save();
    canvas.scale(size.width, size.width);
    final Rect bounds = Rect.fromLTWH(0, 0, 1, height);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(.045)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFF8F2E5),
            Color(0xFFEAE4D3),
            Color(0xFFD8D6C4),
          ],
        ).createShader(bounds),
    );
    final Rect green = Rect.fromLTRB(.075, .06, .925, height - .06);
    canvas.drawRRect(
      RRect.fromRectAndRadius(green, const Radius.circular(.045)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF7DB88B),
            Color(0xFF57936E),
            Color(0xFF3F785F),
          ],
        ).createShader(green),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(green, const Radius.circular(.045)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .006
        ..color = const Color(0xFFE3E3CA).withValues(alpha: .83),
    );

    for (int stripe = 0; stripe < 9; stripe++) {
      final double x = .12 + stripe * .095;
      canvas.drawLine(
        Offset(x, .085),
        Offset(x, height - .085),
        Paint()
          ..color =
              (stripe.isEven
                      ? const Color(0xFFDAF0C8)
                      : const Color(0xFF1F614C))
                  .withValues(alpha: .045)
          ..strokeWidth = .032,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(.10, .09, .90, height - .09),
        const Radius.circular(.035),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .002
        ..color = Colors.white.withValues(alpha: .28),
    );

    // Shallow, warm sand traps with layered cut contours.
    for (final GolfPatch patch in scenario.sand) {
      final Rect sandBounds = Rect.fromCenter(
        center: Offset(patch.x, patch.y * height),
        width: patch.width,
        height: patch.height * height,
      );
      canvas.drawOval(
        sandBounds.shift(const Offset(.009, .012)),
        Paint()..color = const Color(0xFF243C31).withValues(alpha: .18),
      );
      canvas.drawOval(
        sandBounds,
        Paint()
          ..shader = const RadialGradient(
            colors: <Color>[
              Color(0xFFF3DDAE),
              Color(0xFFD9BD88),
              Color(0xFFB89460),
            ],
            stops: <double>[0, .68, 1],
          ).createShader(sandBounds),
      );
      canvas.drawOval(
        sandBounds.deflate(.009),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .002
          ..color = const Color(0xFFFFF0C8).withValues(alpha: .63),
      );
      for (int mark = 0; mark < 4; mark++) {
        final double px =
            sandBounds.left + sandBounds.width * (.2 + mark * .19);
        final double py =
            sandBounds.top +
            sandBounds.height * (.40 + (mark.isEven ? .16 : -.12));
        canvas.drawCircle(
          Offset(px, py),
          .0026,
          Paint()..color = const Color(0xFF987B54).withValues(alpha: .36),
        );
      }
    }

    for (final GolfBumper bumper in scenario.bumpers) {
      final Offset center = Offset(bumper.x, bumper.y * height);
      canvas.drawCircle(
        center.translate(.007, .010),
        bumper.radius * 1.07,
        Paint()..color = const Color(0xFF23362E).withValues(alpha: .20),
      );
      canvas.drawCircle(
        center,
        bumper.radius,
        Paint()
          ..shader =
              RadialGradient(
                center: const Alignment(-.3, -.4),
                colors: const <Color>[
                  Color(0xFFDED9C6),
                  Color(0xFF8C9685),
                  Color(0xFF566655),
                ],
              ).createShader(
                Rect.fromCircle(center: center, radius: bumper.radius),
              ),
      );
      canvas.drawCircle(
        center,
        bumper.radius * .78,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .002
          ..color = Colors.white.withValues(alpha: .42),
      );
      canvas.drawCircle(
        center,
        bumper.radius * .18,
        Paint()..color = const Color(0xFF5D725F),
      );
    }

    // Moving gate rails leave a shifting, visibly open route.
    final double gateY = scenario.gateY * height;
    final double gapCenter = scenario.gateCenterAt(elapsed);
    final double gapLeft = gapCenter - scenario.gateWidth / 2;
    final double gapRight = gapCenter + scenario.gateWidth / 2;
    final Paint rail = Paint()
      ..color = const Color(0xFFD2B56F)
      ..strokeWidth = .012
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(.095, gateY), Offset(gapLeft, gateY), rail);
    canvas.drawLine(Offset(gapRight, gateY), Offset(.905, gateY), rail);
    final Paint gateInlay = Paint()
      ..color = const Color(0xFFFFE8AB)
      ..strokeWidth = .003;
    canvas.drawLine(
      Offset(.095, gateY - .009),
      Offset(gapLeft, gateY - .009),
      gateInlay,
    );
    canvas.drawLine(
      Offset(gapRight, gateY - .009),
      Offset(.905, gateY - .009),
      gateInlay,
    );
    for (final double x in <double>[.105, gapLeft, gapRight, .895]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, gateY), width: .026, height: .055),
          const Radius.circular(.008),
        ),
        Paint()
          ..shader =
              const LinearGradient(
                colors: <Color>[Color(0xFFE5D4A0), Color(0xFF967844)],
              ).createShader(
                Rect.fromCenter(
                  center: Offset(x, gateY),
                  width: .026,
                  height: .055,
                ),
              ),
      );
    }
    _drawText(
      canvas,
      english ? 'MOVING GATE' : 'HAREKETLİ KAPI',
      Offset(.5, gateY - .033),
      .27,
      .025,
      const Color(0xFFFFE8AB),
      FontWeight.w900,
    );

    // A small wind vane shows direction and strength without obscuring play.
    if (scenario.windX.abs() + scenario.windY.abs() > .001) {
      final Offset vane = Offset(.84, .14);
      final double windAngle = math.atan2(scenario.windY, scenario.windX);
      canvas.drawCircle(
        vane,
        .028,
        Paint()..color = const Color(0xFFEAF1D8).withValues(alpha: .20),
      );
      canvas.drawLine(
        vane,
        vane.translate(math.cos(windAngle) * .045, math.sin(windAngle) * .045),
        Paint()
          ..color = const Color(0xFFE7F1D7)
          ..strokeWidth = .005
          ..strokeCap = StrokeCap.round,
      );
      _drawText(
        canvas,
        'W',
        Offset(vane.dx, vane.dy - .038),
        .05,
        .022,
        const Color(0xFFF0F0D8),
        FontWeight.w900,
      );
    }

    // Cup, flag and cut turf lip.
    final Offset hole = Offset(scenario.hole.x, scenario.hole.y * height);
    canvas.drawOval(
      Rect.fromCenter(
        center: hole.translate(.005, .012),
        width: .085,
        height: .049,
      ),
      Paint()..color = const Color(0xFF183C30).withValues(alpha: .35),
    );
    canvas.drawCircle(
      hole,
      MiniGolfEngine.cupRadius,
      Paint()
        ..shader =
            const RadialGradient(
              colors: <Color>[
                Color(0xFF10241D),
                Color(0xFF07130F),
                Color(0xFF71916A),
              ],
              stops: <double>[0, .69, 1],
            ).createShader(
              Rect.fromCircle(center: hole, radius: MiniGolfEngine.cupRadius),
            ),
    );
    canvas.drawCircle(
      hole,
      MiniGolfEngine.cupRadius * .93,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .003
        ..color = const Color(0xFFDCE8C6).withValues(alpha: .75),
    );
    canvas.drawLine(
      hole.translate(.015, -.007),
      hole.translate(.015, -.15),
      Paint()
        ..color = const Color(0xFFF3EAD3)
        ..strokeWidth = .003,
    );
    final Path flag = Path()
      ..moveTo(hole.dx + .016, hole.dy - .148)
      ..lineTo(hole.dx + .102, hole.dy - .126)
      ..lineTo(hole.dx + .016, hole.dy - .103)
      ..close();
    canvas.drawPath(
      flag,
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[Color(0xFFE98978), Color(0xFFB84E48)],
        ).createShader(flag.getBounds()),
    );

    // Shot guide is an approximate, labeled impulse ray (not a solved path).
    final Offset ball = Offset(engine.ball.x, engine.ball.y);
    if (!inMotion && !paused) {
      final double rayLength = .17 + power * .20;
      final Offset end = Offset(
        ball.dx + aimX * rayLength,
        ball.dy + aimY * rayLength,
      );
      canvas.drawLine(
        ball,
        end,
        Paint()
          ..color = const Color(0xFFFFF2CB).withValues(alpha: .78)
          ..strokeWidth = .0035
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        end,
        .008 + power * .004,
        Paint()..color = const Color(0xFFF7E7B2).withValues(alpha: .8),
      );
      final double perpendicularX = -aimY * spin * .021;
      final double perpendicularY = aimX * spin * .021;
      if (spin != 0) {
        canvas.drawArc(
          Rect.fromCircle(center: ball, radius: .05),
          spin < 0 ? .7 : 2.9,
          spin * .8,
          false,
          Paint()
            ..color = const Color(0xFFDDF1D2)
            ..style = PaintingStyle.stroke
            ..strokeWidth = .003,
        );
        canvas.drawCircle(
          end.translate(perpendicularX, perpendicularY),
          .004,
          Paint()..color = const Color(0xFFDDF1D2),
        );
      }
    }
    if (_isInBunker()) {
      canvas.drawCircle(
        ball,
        .047,
        Paint()..color = const Color(0xFFE7D09E).withValues(alpha: .24),
      );
    }
    canvas.drawCircle(
      ball.translate(.006, .010),
      MiniGolfEngine.ballRadius * 1.07,
      Paint()..color = const Color(0xFF173A2F).withValues(alpha: .30),
    );
    canvas.drawCircle(
      ball,
      MiniGolfEngine.ballRadius,
      Paint()
        ..shader =
            const RadialGradient(
              center: Alignment(-.35, -.46),
              colors: <Color>[
                Colors.white,
                Color(0xFFE9E8D9),
                Color(0xFFBBC6AE),
                Color(0xFF687F6B),
              ],
              stops: <double>[0, .34, .72, 1],
            ).createShader(
              Rect.fromCircle(center: ball, radius: MiniGolfEngine.ballRadius),
            ),
    );
    canvas.drawCircle(
      ball.translate(-.005, -.006),
      .0035,
      Paint()..color = Colors.white.withValues(alpha: .88),
    );
    if (paused) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(.075, .06, .85, height - .12),
          const Radius.circular(.045),
        ),
        Paint()..color = const Color(0xD9EAE6D8),
      );
      _drawText(
        canvas,
        english ? 'COURSE PAUSED' : 'PARKUR DURAKLATILDI',
        Offset(.5, height * .49),
        .63,
        .045,
        _MiniGolfPlayPageState._ink,
        FontWeight.w900,
      );
    }
    canvas.restore();
  }

  bool _isInBunker() => scenario.sand.any((GolfPatch patch) {
    final double dx = (engine.ball.x - patch.x) / (patch.width / 2);
    final double dy =
        (engine.ball.y / worldHeight - patch.y) / (patch.height / 2);
    return dx * dx + dy * dy <= 1;
  });

  void _drawText(
    Canvas canvas,
    String text,
    Offset center,
    double maxWidth,
    double fontSize,
    Color color,
    FontWeight weight,
  ) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: weight,
          letterSpacing: .3,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _MiniGolfPainter oldDelegate) => true;
}
