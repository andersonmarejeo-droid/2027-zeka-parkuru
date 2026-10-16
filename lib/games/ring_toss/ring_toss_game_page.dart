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
import 'ring_toss_engine.dart';
import 'ring_toss_scenario.dart';

class RingTossGamePage extends StatelessWidget {
  const RingTossGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  static const int totalCases = RingTossScenario.maximumLevels;
  static const int totalStars = totalCases * 3;

  static final List<ParkurLevelSpec> _levels = List<ParkurLevelSpec>.generate(
    totalCases,
    (int index) {
      final int level = index + 1;
      final String tr = switch (level) {
        <= 3 => 'Halkayı geriye çek; güç ve fırlatma açısını oku.',
        <= 6 => 'Rüzgârı ve direğin ritmini hesaba kat; dönüşü seç.',
        7 || 8 => 'İleri: hareketli direk, sekme ve yan rüzgârı birleştir.',
        9 => 'Uzman: dar yakalama penceresinde 14 hedefi seri tamamla.',
        _ => 'Usta finali: 15 halkada tek kaçış hakkıyla tam isabet yap.',
      };
      final String en = switch (level) {
        <= 3 => 'Pull the ring back and read the power and launch angle.',
        <= 6 => 'Account for wind and peg rhythm; choose your spin.',
        7 || 8 => 'Advanced: combine a moving peg, bank bounce and crosswind.',
        9 => 'Expert: clear 14 targets through narrow capture windows.',
        _ => 'Master finale: land 15 rings with just one miss allowed.',
      };
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Panayır Parkuru ${level.toString().padLeft(2, '0')}',
        titleEn: 'Fairground Course ${level.toString().padLeft(2, '0')}',
        subtitleTr: tr,
        subtitleEn: en,
        difficulty: switch (level) {
          <= 3 => 'USTALAŞMA',
          <= 6 => 'DERİNLEŞME',
          7 || 8 => 'İLERİ',
          9 => 'UZMAN',
          _ => 'USTA',
        },
        icon: Icons.sports_handball_rounded,
      );
    },
    growable: false,
  );

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.fun);
    return ParkurLevelHub(
      gameId: 'ring_toss',
      progressPrefix: 'ring_toss',
      titleTr: 'Halka At',
      titleEn: 'Ring Toss',
      taglineTr: 'Geriyi çek • Dönüş seç • Hedefi yakala',
      taglineEn: 'Pull back • Set spin • Catch the moving peg',
      accent: skin.accent,
      icon: Icons.sports_handball_rounded,
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
      ) => RingTossPlayPage(level: level, previousBestScore: previousBestScore),
    );
  }
}

class RingTossPlayPage extends StatefulWidget {
  const RingTossPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<RingTossPlayPage> createState() => _RingTossPlayPageState();
}

class _RingTossPlayPageState extends State<RingTossPlayPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const Color _ink = Color(0xFF514238);
  static const Color _accent = Color(0xFFB66C52);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.fun,
  );
  late final Ticker _ticker;
  late RingTossScenario _scenario;
  late RingTossEngine _engine;
  late StudioGameSession _session;
  Duration _lastTick = Duration.zero;
  double _elapsed = 0;
  double _aimX = 0;
  double _aimY = -1;
  double _power = .55;
  int _spin = 0;
  int _score = 0;
  bool _dragging = false;
  bool _ready = false;
  bool _paused = false;
  bool _finished = false;
  bool _english = false;

  int get _stars {
    if (_engine.misses == 0 && _elapsed <= _scenario.goldTimeSeconds) return 3;
    if (_engine.misses <= 1) return 2;
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
    RingTossScenario scenario = RingTossScenario.forLevel(widget.level.number);
    try {
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      final String visitKey = 'ring_toss_level_${widget.level.number}_visits';
      final int visits = await preferences.getInt(visitKey) ?? 0;
      if (visits > 0) {
        final int index =
            await preferences.getInt('ring_toss_practice_index') ?? 0;
        if (index < RingTossScenario.maximumPracticeRounds) {
          final int next = index + 1;
          await preferences.setInt('ring_toss_practice_index', next);
          scenario = RingTossScenario.forPracticeRound(next);
        }
      }
      await preferences.setInt(visitKey, visits + 1);
    } catch (_) {
      scenario = RingTossScenario.forLevel(widget.level.number);
    }
    if (!mounted) return;
    _scenario = scenario;
    _startRound();
    setState(() => _ready = true);
  }

  void _startRound() {
    _ticker.stop();
    _engine = RingTossEngine(scenario: _scenario);
    _elapsed = 0;
    _spin = 0;
    _score = 0;
    _dragging = false;
    _paused = false;
    _finished = false;
    _lastTick = Duration.zero;
    _pointTowardTarget();
    _session = StudioGameSession(
      level: widget.level.number,
      seed: _scenario.seed,
    )..start();
    _ticker.start();
  }

  void _pointTowardTarget() {
    final RingPoint target =
        _engine.currentTargetPosition ?? const RingPoint(.5, .35);
    final double dx = target.x - RingTossEngine.startPoint.x;
    final double dy = target.y - RingTossEngine.startPoint.y;
    final double length = math.max(.001, math.sqrt(dx * dx + dy * dy));
    _aimX = dx / length;
    _aimY = dy / length;
    _power = .54;
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

  void _aimAt(Offset localPosition, Size size) {
    if (!_engine.canThrow || _paused || _finished) return;
    final double px = localPosition.dx / size.width;
    final double py = localPosition.dy / size.height;
    final double dx = RingTossEngine.startPoint.x - px;
    final double dy = RingTossEngine.startPoint.y - py;
    final double length = math.sqrt(dx * dx + dy * dy);
    if (length < .035) return;
    setState(() {
      _aimX = dx / length;
      _aimY = dy / length;
      _power = (length * 2.3).clamp(.18, 1).toDouble();
      _dragging = true;
    });
  }

  void _chooseSpin(int spin) {
    if (!_engine.canThrow || _paused || _finished) return;
    setState(() => _spin = spin);
    _audio.hapticSelection();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .18),
    );
  }

  void _throwRing() {
    if (!_engine.canThrow || _paused || _finished) return;
    if (!_engine.launch(
      directionX: _aimX,
      directionY: _aimY,
      power: _power,
      spin: _spin,
    )) {
      return;
    }
    _dragging = false;
    _audio.hapticLight();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .28),
    );
    setState(() {});
  }

  void _tick(Duration elapsed) {
    if (!_ready || _paused || _finished) return;
    final double raw = (elapsed - _lastTick).inMicroseconds / 1000000;
    _lastTick = elapsed;
    if (raw <= 0) return;
    final double delta = raw.clamp(0, .024).toDouble();
    _elapsed += delta;
    final bool wasReady = _engine.canThrow;
    final RingTossStepResult result = _engine.step(delta);
    if (result.captured) {
      final int chain = _engine.captures;
      final int chainBonus = math.min(120, (chain - 1) * 12).toInt();
      final int points =
          100 + chainBonus - _engine.bumperHits * 2 - _engine.pegBounces * 3;
      _score += math.max(40, points);
      _session.recordAccepted(points: math.max(40, points));
      unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .32));
      if (!_engine.isComplete) _pointTowardTarget();
    } else if (result.missed) {
      _session.recordMistake();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .23));
    } else if (result.pegBounce || result.bumperHit) {
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .12));
    }
    if (!wasReady && _engine.canThrow) _pointTowardTarget();

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
              title: Text(_english ? 'Ring count lost' : 'Atış hakkı doldu'),
              content: Text(
                _english
                    ? 'Too many rings missed the pegs. Read the wind and release window, then try the course again?'
                    : 'Fazla halka direkten kaçtı. Rüzgârı ve bırakma anını yeniden okuyup parkuru tekrar deneyelim mi?',
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
      action: widget.level.number < RingTossGamePage.totalCases
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
      titleTr: 'PANAYIR PARKURU TAMAMLANDI',
      titleEn: 'FAIRGROUND COURSE COMPLETE',
      detailTr:
          '${_engine.captures}/${_scenario.targetCount} isabet · ${_engine.misses} kaçan · ${_elapsed.toStringAsFixed(1)} sn.',
      detailEn:
          '${_engine.captures}/${_scenario.targetCount} catches · ${_engine.misses} missed · ${_elapsed.toStringAsFixed(1)} s.',
      stars: _stars,
      score: _score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < RingTossGamePage.totalCases,
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
        appBar: AppBar(title: Text(_english ? 'RING TOSS' : 'HALKA AT')),
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
          _english ? 'RING TOSS' : 'HALKA AT',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('ring_toss_pause'),
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
                  _RingHud(
                    captures: _engine.captures,
                    total: _scenario.targetCount,
                    misses: _engine.misses,
                    missLimit: _scenario.missLimit,
                    wind: _scenario.windAt(_elapsed),
                    english: _english,
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints limits) {
                        final double width = math.min(limits.maxWidth, 570);
                        final double height = math.min(
                          limits.maxHeight,
                          width * 1.08,
                        );
                        final Size sceneSize = Size(width, height);
                        return Center(
                          child: SizedBox(
                            key: const ValueKey<String>('ring_toss_scene'),
                            width: width,
                            height: height,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapDown: (TapDownDetails details) =>
                                  _aimAt(details.localPosition, sceneSize),
                              onPanStart: (DragStartDetails details) =>
                                  _aimAt(details.localPosition, sceneSize),
                              onPanUpdate: (DragUpdateDetails details) =>
                                  _aimAt(details.localPosition, sceneSize),
                              onPanEnd: (DragEndDetails details) =>
                                  _throwRing(),
                              child: CustomPaint(
                                painter: _RingTossPainter(
                                  scenario: _scenario,
                                  engine: _engine,
                                  elapsed: _elapsed,
                                  aimX: _aimX,
                                  aimY: _aimY,
                                  power: _power,
                                  spin: _spin,
                                  dragging: _dragging,
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
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _SpinSelector(
                          selected: _spin,
                          enabled: _engine.canThrow && !_paused && !_finished,
                          english: _english,
                          onSelect: _chooseSpin,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 102,
                        height: 56,
                        child: FilledButton.icon(
                          key: const ValueKey<String>('ring_toss_throw'),
                          onPressed: _engine.canThrow && !_paused && !_finished
                              ? _throwRing
                              : null,
                          icon: const Icon(
                            Icons.sports_handball_rounded,
                            size: 18,
                          ),
                          label: Text(
                            _english ? 'TOSS' : 'AT',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFFE2D8CF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _english
                        ? 'Drag back from the ring and release, or tap a point then toss. Aim for the moving peg; a soft catch scores.'
                        : 'Halkadan geriye sürükleyip bırak ya da bir nokta seçip AT’a bas. Hareketli direği yumuşak yakala.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: StudioVisuals.muted,
                      fontSize: 9,
                      height: 1.15,
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

class _RingHud extends StatelessWidget {
  const _RingHud({
    required this.captures,
    required this.total,
    required this.misses,
    required this.missLimit,
    required this.wind,
    required this.english,
  });

  final int captures;
  final int total;
  final int misses;
  final int missLimit;
  final RingPoint wind;
  final bool english;

  @override
  Widget build(BuildContext context) {
    final double strength = math.sqrt(wind.x * wind.x + wind.y * wind.y);
    return Container(
      key: const ValueKey<String>('ring_toss_hud'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: StudioVisuals.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: StudioVisuals.line),
        boxShadow: StudioVisuals.softShadow,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _RingMetric(
              label: english ? 'CAUGHT' : 'YAKALANAN',
              value: '$captures / $total',
              icon: Icons.radio_button_checked_rounded,
              color: const Color(0xFF71977C),
            ),
          ),
          Container(width: 1, height: 27, color: StudioVisuals.line),
          Expanded(
            child: _RingMetric(
              label: english ? 'MISSED' : 'KAÇAN',
              value: '$misses / $missLimit',
              icon: Icons.warning_amber_rounded,
              color: misses == 0
                  ? _RingTossPlayPageState._accent
                  : const Color(0xFFC57561),
            ),
          ),
          Container(width: 1, height: 27, color: StudioVisuals.line),
          Expanded(
            child: _RingMetric(
              label: english ? 'CROSSWIND' : 'YAN RÜZGÂR',
              value: strength < .01
                  ? (english ? 'CALM' : 'SAKİN')
                  : '${(strength * 100).round()}%',
              icon: strength < .01
                  ? Icons.air_rounded
                  : wind.x < 0
                  ? Icons.west_rounded
                  : Icons.east_rounded,
              color: const Color(0xFF7793A1),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingMetric extends StatelessWidget {
  const _RingMetric({
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
                color: _RingTossPlayPageState._ink,
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

class _SpinSelector extends StatelessWidget {
  const _SpinSelector({
    required this.selected,
    required this.enabled,
    required this.english,
    required this.onSelect,
  });

  final int selected;
  final bool enabled;
  final bool english;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 56),
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
    decoration: BoxDecoration(
      color: StudioVisuals.surface,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: StudioVisuals.line),
      boxShadow: StudioVisuals.softShadow,
    ),
    child: Row(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            english ? 'SPIN' : 'DÖNÜŞ',
            style: const TextStyle(
              color: StudioVisuals.muted,
              fontSize: 7,
              fontWeight: FontWeight.w900,
              letterSpacing: .35,
            ),
          ),
        ),
        for (final int spin in <int>[-1, 0, 1])
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Material(
                color: selected == spin
                    ? const Color(0xFFF4E7DC)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                child: InkWell(
                  key: ValueKey<String>('ring_toss_spin_$spin'),
                  borderRadius: BorderRadius.circular(9),
                  onTap: enabled ? () => onSelect(spin) : null,
                  child: SizedBox(
                    height: 39,
                    child: Icon(
                      spin < 0
                          ? Icons.turn_left_rounded
                          : spin > 0
                          ? Icons.turn_right_rounded
                          : Icons.arrow_upward_rounded,
                      size: 18,
                      color: selected == spin
                          ? _RingTossPlayPageState._accent
                          : StudioVisuals.muted,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _RingTossPainter extends CustomPainter {
  const _RingTossPainter({
    required this.scenario,
    required this.engine,
    required this.elapsed,
    required this.aimX,
    required this.aimY,
    required this.power,
    required this.spin,
    required this.dragging,
    required this.paused,
    required this.english,
  });

  final RingTossScenario scenario;
  final RingTossEngine engine;
  final double elapsed;
  final double aimX;
  final double aimY;
  final double power;
  final int spin;
  final bool dragging;
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
      const Radius.circular(24),
    );
    canvas.drawShadow(
      Path()..addRRect(frame),
      const Color(0x334C392C),
      9,
      true,
    );
    canvas.drawRRect(
      frame,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFFFFCF5), Color(0xFFF2E6D7)],
        ).createShader(bounds),
    );
    canvas.drawRRect(
      frame,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = const Color(0xFFE3D3C0),
    );

    final double floorY = h * .925;
    final Rect tent = Rect.fromLTWH(w * .045, h * .055, w * .91, h * .77);
    canvas.drawRRect(
      RRect.fromRectAndRadius(tent, const Radius.circular(18)),
      Paint()..color = const Color(0xFFF8F0E5),
    );
    final Paint archPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, w * .006)
      ..color = const Color(0xFFE7D9C6);
    for (int arch = 0; arch < 4; arch++) {
      final double x = w * (.18 + arch * .21);
      canvas.drawLine(Offset(x, h * .08), Offset(x, h * .79), archPaint);
    }
    final Paint floorPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const <Color>[Color(0xFFE5D5C1), Color(0xFFD4BEA4)],
      ).createShader(Rect.fromLTWH(0, floorY, w, h - floorY));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .055, floorY, w * .89, h * .05),
        const Radius.circular(9),
      ),
      floorPaint,
    );
    final Paint floorLine = Paint()
      ..color = Colors.white.withValues(alpha: .65)
      ..strokeWidth = 1.2;
    canvas.drawLine(
      Offset(w * .09, floorY + h * .012),
      Offset(w * .91, floorY + h * .012),
      floorLine,
    );

    // Low-contrast fairground bunting and timber posts give the court a
    // crafted identity without crowding the flight path.
    for (int index = 0; index < 7; index++) {
      final double x = w * (.10 + index * .13);
      final Path pennant = Path()
        ..moveTo(x, h * .10)
        ..lineTo(x + w * .035, h * .10)
        ..lineTo(x + w * .018, h * .17)
        ..close();
      canvas.drawPath(
        pennant,
        Paint()
          ..color = index.isEven
              ? const Color(0xFFDFAF8F).withValues(alpha: .66)
              : const Color(0xFF91A99B).withValues(alpha: .64),
      );
    }

    for (final RingBumper bumper in scenario.bumpers) {
      final Offset center = Offset(bumper.x * w, bumper.y * h);
      final Rect bumperRect = Rect.fromCenter(
        center: center,
        width: bumper.radius * w * 2.4,
        height: bumper.radius * h * 1.5,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(bumperRect, const Radius.circular(8)),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFFE9BD7D), Color(0xFFBD8651)],
          ).createShader(bumperRect),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(bumperRect, const Radius.circular(8)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0xFF9B714C),
      );
      canvas.drawLine(
        Offset(bumperRect.left + 4, bumperRect.center.dy),
        Offset(bumperRect.right - 4, bumperRect.center.dy),
        Paint()
          ..color = Colors.white.withValues(alpha: .62)
          ..strokeWidth = 1.2,
      );
    }

    final RingPoint? target = engine.currentTargetPosition;
    if (target != null && engine.currentTarget != null) {
      _drawPeg(
        canvas,
        Offset(target.x * w, target.y * h),
        engine.currentTarget!.radius * math.min(w, h),
        floorY,
      );
    }

    final RingProjectile? ring = engine.ring;
    if (ring != null && ring.inFlight) {
      _drawRing(
        canvas,
        Offset(ring.x * w, ring.y * h),
        math.min(w, h) * .045,
        ring.spin,
        ring.flightSeconds,
      );
    } else if (ring != null) {
      _drawAim(canvas, w, h);
      _drawRing(
        canvas,
        Offset(
          RingTossEngine.startPoint.x * w,
          RingTossEngine.startPoint.y * h,
        ),
        math.min(w, h) * .045,
        spin.toDouble(),
        elapsed,
      );
    }

    _drawWindRibbon(canvas, w, h);
    if (paused) {
      canvas.drawRRect(frame, Paint()..color = const Color(0xAAFCF8F0));
      _drawLabel(
        canvas,
        english ? 'COURT PAUSED' : 'PARKUR DURAKLATILDI',
        Offset(w / 2, h / 2),
        math.max(13, h * .042),
        const Color(0xFF6C5848),
      );
    }
  }

  void _drawPeg(Canvas canvas, Offset center, double radius, double floorY) {
    final double poleHeight = math.max(radius * 2.4, center.dy * .14);
    final Rect post = Rect.fromLTWH(
      center.dx - radius * .105,
      center.dy - poleHeight * .45,
      radius * .21,
      poleHeight * .76,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(post, Radius.circular(radius * .1)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[
            Color(0xFF9A673E),
            Color(0xFFFFDA98),
            Color(0xFF9A673E),
          ],
        ).createShader(post),
    );
    final Rect hoop = Rect.fromCenter(
      center: center,
      width: radius * 2.1,
      height: radius * .76,
    );
    canvas.drawOval(
      hoop,
      Paint()
        ..color = const Color(0x44B96D52)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * .55,
    );
    canvas.drawOval(
      hoop,
      Paint()
        ..color = const Color(0xFFB6654C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(2.2, radius * .22),
    );
    final Paint glint = Paint()
      ..color = Colors.white.withValues(alpha: .78)
      ..strokeWidth = math.max(1, radius * .075)
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      hoop.deflate(radius * .08),
      math.pi * 1.08,
      math.pi * .46,
      false,
      glint,
    );
    final Rect base = Rect.fromCenter(
      center: Offset(center.dx, floorY - radius * .15),
      width: radius * 2.55,
      height: radius * .42,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(base, Radius.circular(radius * .18)),
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[
            Color(0xFF7C5A42),
            Color(0xFFC09166),
            Color(0xFF765238),
          ],
        ).createShader(base),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(base, Radius.circular(radius * .18)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFF674832),
    );
    _drawLabel(
      canvas,
      '★',
      Offset(center.dx, center.dy - poleHeight * .85),
      math.max(8, radius * .45),
      const Color(0xFFD2A152),
    );
  }

  void _drawRing(
    Canvas canvas,
    Offset center,
    double radius,
    double spin,
    double flightSeconds,
  ) {
    final double flatten = .48 + .08 * math.sin(flightSeconds * 8 + spin);
    final Rect oval = Rect.fromCenter(
      center: center,
      width: radius * 2.25,
      height: radius * 2 * flatten,
    );
    canvas.drawOval(
      oval.shift(Offset(0, radius * .32)),
      Paint()..color = const Color(0x334A392C),
    );
    canvas.drawOval(
      oval,
      Paint()
        ..color = const Color(0x22BD714E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * .72,
    );
    final Paint ringPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color(0xFFFFE0A2),
          Color(0xFFD88D57),
          Color(0xFF8B513C),
        ],
      ).createShader(oval)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * .48
      ..strokeCap = StrokeCap.round;
    canvas.drawOval(oval, ringPaint);
    canvas.drawArc(
      oval.deflate(radius * .1),
      math.pi * 1.05,
      math.pi * .52,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: .82)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, radius * .13)
        ..strokeCap = StrokeCap.round,
    );
    final Offset bead = Offset(
      center.dx + radius * .94 * math.cos(flightSeconds * 5 + spin),
      center.dy + radius * flatten * math.sin(flightSeconds * 5 + spin),
    );
    canvas.drawCircle(
      bead,
      radius * .11,
      Paint()..color = const Color(0xFFFFF4D8),
    );
  }

  void _drawAim(Canvas canvas, double w, double h) {
    if (engine.isComplete) return;
    final double gravity = scenario.gravity;
    final RingPoint wind = scenario.windAt(elapsed);
    final double strength = power * 1.5;
    double x = RingTossEngine.startPoint.x;
    double y = RingTossEngine.startPoint.y;
    double vx = aimX * strength;
    double vy = aimY * strength;
    final Paint pathPaint = Paint()
      ..color = const Color(0xFFAA7453).withValues(alpha: dragging ? .55 : .34)
      ..strokeWidth = 1.35
      ..strokeCap = StrokeCap.round;
    const double step = .095;
    for (int index = 0; index < 26; index++) {
      vx += (wind.x + spin * .018) * step;
      vy += (gravity + wind.y - spin.abs() * .004) * step;
      x += vx * step;
      y += vy * step;
      if (x < .02 || x > .98 || y > .93 || y < .02) break;
      if (index % 2 == 0) {
        final double dotRadius = math.max(1.2, 3.4 - index * .075);
        canvas.drawCircle(
          Offset(x * w, y * h),
          dotRadius,
          pathPaint
            ..color = pathPaint.color.withValues(alpha: .48 - index * .012),
        );
      }
    }
    final Offset start = Offset(
      RingTossEngine.startPoint.x * w,
      RingTossEngine.startPoint.y * h,
    );
    final Offset pull = Offset(
      start.dx - aimX * power * w * .26,
      start.dy - aimY * power * h * .26,
    );
    canvas.drawLine(
      start,
      pull,
      Paint()
        ..color = const Color(0xFFB77B53)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );
    _drawLabel(
      canvas,
      '${(power * 100).round()}%',
      Offset(start.dx + w * .105, start.dy - h * .048),
      math.max(8, h * .025),
      const Color(0xFF86644B),
    );
  }

  void _drawWindRibbon(Canvas canvas, double w, double h) {
    final RingPoint wind = scenario.windAt(elapsed);
    final double length = math.sqrt(wind.x * wind.x + wind.y * wind.y);
    if (length < .001) return;
    final Offset center = Offset(w * .84, h * .16);
    final Offset vector = Offset(wind.x / length, wind.y / length);
    final Offset end =
        center + vector * math.min(w * .06, w * (.025 + length * .75));
    final Paint windPaint = Paint()
      ..color = const Color(0xFF829D9B)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center - vector * w * .035, end, windPaint);
    final double angle = math.atan2(vector.dy, vector.dx);
    final Path arrow = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - math.cos(angle - .55) * w * .018,
        end.dy - math.sin(angle - .55) * w * .018,
      )
      ..lineTo(
        end.dx - math.cos(angle + .55) * w * .018,
        end.dy - math.sin(angle + .55) * w * .018,
      )
      ..close();
    canvas.drawPath(arrow, Paint()..color = const Color(0xFF829D9B));
  }

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
  bool shouldRepaint(covariant _RingTossPainter oldDelegate) =>
      oldDelegate.scenario != scenario ||
      oldDelegate.engine != engine ||
      oldDelegate.elapsed != elapsed ||
      oldDelegate.aimX != aimX ||
      oldDelegate.aimY != aimY ||
      oldDelegate.power != power ||
      oldDelegate.spin != spin ||
      oldDelegate.dragging != dragging ||
      oldDelegate.paused != paused ||
      oldDelegate.english != english;
}
