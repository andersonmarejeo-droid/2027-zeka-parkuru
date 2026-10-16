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
import 'snowboard_slalom_engine.dart';
import 'snowboard_slalom_scenario.dart';

class SnowboardSlalomGamePage extends StatelessWidget {
  const SnowboardSlalomGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  static const int totalCases = SnowboardSlalomScenario.campaignLevels;
  static const int totalStars = totalCases * 3;

  static final List<ParkurLevelSpec> _levels = List<ParkurLevelSpec>.generate(
    totalCases,
    (int index) {
      final int level = index + 1;
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Kar Parkuru ${level.toString().padLeft(2, '0')}',
        titleEn: 'Snow Run ${level.toString().padLeft(2, '0')}',
        subtitleTr: switch (level) {
          <= 3 => 'Kapı merkezine kavis çiz; yumuşak kar çizgisini izle.',
          <= 6 => 'Buzda kenarı erken bırak; tümsek öncesi hızı kes.',
          7 || 8 => 'İleri: ters rüzgâr, buz şeridi ve dar kapı kombosu.',
          9 => 'Uzman: sis perdesi altında ardışık tümsek kapıları.',
          _ => 'Usta finali: dar kapılar, buz ve tek düşüş hakkı.',
        },
        subtitleEn: switch (level) {
          <= 3 => 'Carve toward each gate and read the soft-snow line.',
          <= 6 => 'Release the edge on ice; scrub speed before moguls.',
          7 || 8 => 'Advanced: crosswind, ice bands and narrow gate chains.',
          9 => 'Expert: chained mogul gates behind a snow curtain.',
          _ => 'Master finale: narrow gates, ice and one fall allowed.',
        },
        difficulty: switch (level) {
          <= 3 => 'USTALAŞMA',
          <= 6 => 'DERİNLEŞME',
          7 || 8 => 'İLERİ',
          9 => 'UZMAN',
          _ => 'USTA',
        },
        icon: Icons.downhill_skiing_rounded,
      );
    },
    growable: false,
  );

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.fun);
    return ParkurLevelHub(
      gameId: 'snowboard_slalom',
      progressPrefix: 'snowboard_slalom',
      titleTr: 'Kar Sörfü Slalomu',
      titleEn: 'Snowboard Slalom',
      taglineTr: 'Kavis çiz • Kenarı yönet • Kapı serisini geç',
      taglineEn: 'Carve the line • Manage edge • Clear the gates',
      accent: skin.accent,
      icon: Icons.downhill_skiing_rounded,
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
          ) => SnowboardSlalomPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class SnowboardSlalomPlayPage extends StatefulWidget {
  const SnowboardSlalomPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<SnowboardSlalomPlayPage> createState() =>
      _SnowboardSlalomPlayPageState();
}

class _SnowboardSlalomPlayPageState extends State<SnowboardSlalomPlayPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const Color _ink = Color(0xFF415768);
  static const Color _accent = Color(0xFF559B9C);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.fun,
  );
  late final Ticker _ticker;
  late SnowboardSlalomScenario _scenario;
  late SnowboardSlalomEngine _engine;
  late StudioGameSession _session;
  Duration _lastTick = Duration.zero;
  bool _ready = false;
  bool _paused = false;
  bool _finished = false;
  bool _english = false;
  String _feedback = '';
  Color _feedbackColor = _accent;

  int get _stars {
    if (_engine.misses == 0 &&
        _engine.bestCombo >= _scenario.gates.length - 1) {
      return 3;
    }
    if (_engine.accuracy >= .76 && _engine.misses <= 1) return 2;
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
    SnowboardSlalomScenario scenario = SnowboardSlalomScenario.forLevel(
      widget.level.number,
    );
    try {
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      final String visitKey =
          'snowboard_slalom_level_${widget.level.number}_visits';
      final int visits = await preferences.getInt(visitKey) ?? 0;
      if (visits > 0) {
        final int index =
            await preferences.getInt('snowboard_slalom_practice_index') ?? 0;
        if (index < SnowboardSlalomScenario.practiceCourses) {
          final int next = index + 1;
          await preferences.setInt('snowboard_slalom_practice_index', next);
          scenario = SnowboardSlalomScenario.forPracticeCourse(next);
        }
      }
      await preferences.setInt(visitKey, visits + 1);
    } catch (_) {
      scenario = SnowboardSlalomScenario.forLevel(widget.level.number);
    }
    if (!mounted) return;
    _scenario = scenario;
    _startRun();
    setState(() => _ready = true);
  }

  void _startRun() {
    _ticker.stop();
    _engine = SnowboardSlalomEngine(scenario: _scenario);
    _feedback = '';
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
      _engine.setCarve(0);
      _engine.setBrake(false);
      _session.pause();
      _ticker.stop();
    } else {
      _session.resume();
      _lastTick = Duration.zero;
      _ticker.start();
    }
    unawaited(_audio.play(GameSound.uiClick, gain: .24));
  }

  void _carve(Offset point, Size size) {
    if (!_ready || _paused || _finished) return;
    final double steering = ((point.dx / size.width) * 2 - 1)
        .clamp(-1, 1)
        .toDouble();
    _engine.setCarve(steering);
    if (mounted) setState(() {});
  }

  void _tick(Duration elapsed) {
    if (!_ready || _paused || _finished) return;
    final double raw = (elapsed - _lastTick).inMicroseconds / 1000000;
    _lastTick = elapsed;
    if (raw <= 0) return;
    final SnowStepResult result = _engine.step(raw.clamp(0, .04).toDouble());
    for (int i = 0; i < result.cleared; i++) {
      _session.recordAccepted(points: 90);
      _feedback = _english ? 'GATE CLEAN' : 'KAPI TEMİZ';
      _feedbackColor = _accent;
      _audio.hapticLight();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .2));
    }
    for (int i = 0; i < result.missed; i++) {
      _session.recordMistake();
      _feedback = _english
          ? 'GATE MISSED · RESET YOUR EDGE'
          : 'KAPI KAÇTI · KENARI YUMUŞAT';
      _feedbackColor = const Color(0xFFD07869);
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .18));
    }
    if (result.completed) {
      unawaited(_finish(completed: true));
    } else if (result.failed) {
      unawaited(_finish(completed: false));
    }
    if (mounted && !_finished) setState(() {});
  }

  void _setBrake(bool pressed) {
    if (!_ready || _paused || _finished) return;
    _engine.setBrake(pressed);
    if (pressed) {
      unawaited(
        _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .12),
      );
      _audio.hapticSelection();
    }
    if (mounted) setState(() {});
  }

  Future<void> _finish({required bool completed}) async {
    if (_finished || !mounted) return;
    _finished = true;
    _ticker.stop();
    _engine.setBrake(false);
    if (!completed) {
      final bool retry =
          await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) => AlertDialog(
              title: Text(_english ? 'Run ended' : 'Koşu sona erdi'),
              content: Text(
                _english
                    ? 'Too many gates or falls. Follow the flag center, soften your edge on ice and brake before moguls.'
                    : 'Kapı ve düşüş sınırı doldu. Bayrak merkezini izle, buzda kenarı bırak ve tümsekten önce frenle.',
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
        setState(_startRun);
      } else {
        Navigator.of(
          context,
        ).pop(StudioGameResult.failed(score: _session.score).toParkurResult());
      }
      return;
    }

    _session.complete(
      stars: _stars,
      action: widget.level.number < SnowboardSlalomGamePage.totalCases
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
      titleTr: 'KAR PARKURU TAMAMLANDI',
      titleEn: 'SNOW RUN COMPLETE',
      detailTr:
          '${_engine.gatesCleared}/${_scenario.gates.length} kapı · ${_engine.bestCombo} kesintisiz seri · kenar yükü ${(_engine.edgeLoad * 100).round()}%',
      detailEn:
          '${_engine.gatesCleared}/${_scenario.gates.length} gates · ${_engine.bestCombo} clean chain · edge load ${(_engine.edgeLoad * 100).round()}%',
      stars: _stars,
      score:
          _session.score + _engine.gatesCleared * 90 + _engine.bestCombo * 35,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < SnowboardSlalomGamePage.totalCases,
    );
    if (!mounted) return;
    final StudioResultAction action = switch (result) {
      ParkurResultAction.replay => StudioResultAction.replay,
      ParkurResultAction.next => StudioResultAction.next,
      _ => StudioResultAction.map,
    };
    Navigator.of(context).pop(
      StudioGameResult.completed(
        score:
            _session.score + _engine.gatesCleared * 90 + _engine.bestCombo * 35,
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
          title: Text(_english ? 'SNOWBOARD SLALOM' : 'KAR SÖRFÜ SLALOMU'),
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
          _english ? 'SNOWBOARD SLALOM' : 'KAR SÖRFÜ SLALOMU',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
        ),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('snowboard_slalom_pause'),
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
              padding: const EdgeInsets.fromLTRB(12, 5, 12, 7),
              child: Column(
                children: <Widget>[
                  _SnowHud(
                    gate: _engine.gatesCleared,
                    total: _scenario.gates.length,
                    speed: _engine.speed,
                    edgeLoad: _engine.edgeLoad,
                    misses: _engine.misses,
                    missLimit: _scenario.missLimit,
                    english: _english,
                  ),
                  const SizedBox(height: 7),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints limits) {
                        final double width = math.min(limits.maxWidth, 640);
                        final double height = math.min(
                          limits.maxHeight,
                          math.max(180, width * .77),
                        );
                        final Size scene = Size(width, height);
                        return Center(
                          child: SizedBox(
                            key: const ValueKey<String>(
                              'snowboard_slalom_scene',
                            ),
                            width: width,
                            height: height,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanStart: (DragStartDetails details) =>
                                  _carve(details.localPosition, scene),
                              onPanUpdate: (DragUpdateDetails details) =>
                                  _carve(details.localPosition, scene),
                              onPanEnd: (DragEndDetails details) {
                                _engine.setCarve(0);
                                if (mounted) setState(() {});
                              },
                              child: CustomPaint(
                                painter: _SnowScenePainter(
                                  scenario: _scenario,
                                  engine: _engine,
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
                  SizedBox(
                    height: 23,
                    child: Center(
                      child: Text(
                        _paused
                            ? (_english ? 'RUN PAUSED' : 'PARKUR DURAKLATILDI')
                            : _feedback.isNotEmpty
                            ? _feedback
                            : (_english
                                  ? 'Drag left/right to carve • hold BRAKE to scrub speed'
                                  : 'Kavis için sağa-sola sürükle • hızı kesmek için FREN’e basılı tut'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _feedback.isEmpty || _paused
                              ? StudioVisuals.muted
                              : _feedbackColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  _SnowBrakeButton(
                    english: _english,
                    pressed: _engine.braking,
                    enabled: !_paused && !_finished,
                    onChange: _setBrake,
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

class _SnowHud extends StatelessWidget {
  const _SnowHud({
    required this.gate,
    required this.total,
    required this.speed,
    required this.edgeLoad,
    required this.misses,
    required this.missLimit,
    required this.english,
  });
  final int gate;
  final int total;
  final double speed;
  final double edgeLoad;
  final int misses;
  final int missLimit;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey<String>('snowboard_slalom_hud'),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
    decoration: BoxDecoration(
      color: StudioVisuals.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: StudioVisuals.line),
      boxShadow: StudioVisuals.softShadow,
    ),
    child: Row(
      children: <Widget>[
        _SnowMetric(
          label: english ? 'GATES' : 'KAPILAR',
          value: '$gate / $total',
          icon: Icons.flag_rounded,
          color: const Color(0xFF5989A0),
        ),
        _divider(),
        _SnowMetric(
          label: english ? 'SPEED' : 'HIZ',
          value: '${(speed * 100).round()}%',
          icon: Icons.speed_rounded,
          color: const Color(0xFF4E9DA0),
        ),
        _divider(),
        _SnowMetric(
          label: english ? 'EDGE' : 'KENAR',
          value: '${(edgeLoad * 100).round()}%',
          icon: Icons.waves_rounded,
          color: edgeLoad > .72
              ? const Color(0xFFD28B55)
              : const Color(0xFF849DAA),
        ),
        _divider(),
        _SnowMetric(
          label: english ? 'FALLS' : 'DÜŞÜŞ',
          value: '$misses / $missLimit',
          icon: Icons.favorite_rounded,
          color: misses >= missLimit - 1
              ? const Color(0xFFD16E64)
              : const Color(0xFF819BA6),
        ),
      ],
    ),
  );

  Widget _divider() => Container(
    width: 1,
    height: 28,
    margin: const EdgeInsets.symmetric(horizontal: 2),
    color: StudioVisuals.line,
  );
}

class _SnowMetric extends StatelessWidget {
  const _SnowMetric({
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
        Icon(icon, color: color, size: 14),
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
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _SnowboardSlalomPlayPageState._ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SnowBrakeButton extends StatelessWidget {
  const _SnowBrakeButton({
    required this.english,
    required this.pressed,
    required this.enabled,
    required this.onChange,
  });
  final bool english;
  final bool pressed;
  final bool enabled;
  final ValueChanged<bool> onChange;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: english
        ? 'Brake, hold to reduce speed'
        : 'Fren, hızı azaltmak için basılı tut',
    child: Listener(
      key: const ValueKey<String>('snowboard_slalom_brake'),
      behavior: HitTestBehavior.opaque,
      onPointerDown: enabled ? (_) => onChange(true) : null,
      onPointerUp: enabled ? (_) => onChange(false) : null,
      onPointerCancel: enabled ? (_) => onChange(false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: 62,
        width: double.infinity,
        decoration: BoxDecoration(
          color: pressed ? const Color(0xFFE5A477) : const Color(0xFF526C79),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: .62),
            width: 1.2,
          ),
          boxShadow: pressed
              ? const <BoxShadow>[]
              : const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x22263C4D),
                    blurRadius: 9,
                    offset: Offset(0, 4),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: <Widget>[
              const Icon(Icons.south_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  english
                      ? 'BRAKE · HOLD TO SCRUB SPEED'
                      : 'FREN · HIZI KESMEK İÇİN BASILI TUT',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .28,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SnowScenePainter extends CustomPainter {
  const _SnowScenePainter({
    required this.scenario,
    required this.engine,
    required this.paused,
    required this.english,
  });
  final SnowboardSlalomScenario scenario;
  final SnowboardSlalomEngine engine;
  final bool paused;
  final bool english;

  static const Color _coral = Color(0xFFE68F78);
  static const Color _blue = Color(0xFF6E91AF);

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    final RRect frame = RRect.fromRectAndRadius(
      bounds,
      const Radius.circular(22),
    );
    canvas.save();
    canvas.clipRRect(frame);
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFFC8E0E8),
            Color(0xFFE8F0EF),
            Color(0xFFF9FAF8),
          ],
        ).createShader(bounds),
    );
    final Paint sun = Paint()
      ..shader = RadialGradient(
        center: const Alignment(.72, -.83),
        radius: .62,
        colors: <Color>[
          const Color(0xFFF5E9D2).withValues(alpha: .78),
          Colors.transparent,
        ],
      ).createShader(bounds);
    canvas.drawRect(bounds, sun);
    _mountains(canvas, size);

    final double horizon = size.height * .45;
    final Path trail = Path()
      ..moveTo(size.width * .5, horizon)
      ..cubicTo(
        size.width * .08,
        size.height * .56,
        size.width * .94,
        size.height * .69,
        size.width * .5,
        size.height * 1.12,
      );
    canvas.drawPath(
      trail,
      Paint()
        ..color = const Color(0xFFD9E4E2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * .64
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      trail,
      Paint()
        ..color = Colors.white.withValues(alpha: .44)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * .54
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      trail,
      Paint()
        ..color = const Color(0xFFB5D0D6).withValues(alpha: .52)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );

    final SnowGate? next = engine.currentGate;
    for (
      int index = engine.nextGate;
      index < math.min(scenario.gates.length, engine.nextGate + 5);
      index++
    ) {
      final SnowGate gate = scenario.gates[index];
      final double ahead = (gate.distance - engine.routeDistance)
          .clamp(0, 9)
          .toDouble();
      final double depth = 1 - ahead / 9;
      final double y = horizon + depth * depth * size.height * .43;
      final double spread = size.width * (.16 + depth * .32);
      final double cx = size.width * .5 + (gate.centerX - .5) * spread * 2;
      final double h = size.height * (.025 + depth * .095);
      final double pole = size.width * (.003 + depth * .005);
      final Color flag = index.isEven ? _coral : _blue;
      _flag(
        canvas,
        Offset(cx - size.width * (.105 - depth * .028), y),
        h,
        pole,
        flag,
        true,
      );
      _flag(
        canvas,
        Offset(cx + size.width * (.105 - depth * .028), y),
        h,
        pole,
        flag,
        false,
      );
      final SnowGateState state = engine.states[index];
      if (state == SnowGateState.upcoming && index == engine.nextGate) {
        canvas.drawLine(
          Offset(cx - size.width * .06, y + h),
          Offset(cx + size.width * .06, y + h),
          Paint()
            ..color = const Color(0xFF7297A3).withValues(alpha: .55)
            ..strokeWidth = 1.2,
        );
      }
    }

    final double px = size.width * (.5 + (engine.x - .5) * .36);
    final double py = size.height * .78;
    canvas.save();
    canvas.translate(px, py);
    canvas.rotate(engine.lateralVelocity * .38);
    _drawRider(canvas, size);
    canvas.restore();

    final SnowSurface currentSurface = next?.surface ?? SnowSurface.packed;
    final String surfaceName = switch (currentSurface) {
      SnowSurface.packed => english ? 'PACKED' : 'EZİLMİŞ KAR',
      SnowSurface.powder => english ? 'POWDER' : 'TOZ KAR',
      SnowSurface.ice => english ? 'ICE · RELEASE EDGE' : 'BUZ · KENARI BIRAK',
      SnowSurface.moguls => english ? 'MOGULS · BRAKE' : 'TÜMSEK · FRENLE',
    };
    _text(
      canvas,
      surfaceName,
      const Offset(13, 14),
      const Color(0xFF496675),
      9,
      FontWeight.w900,
    );
    if (paused) {
      canvas.drawRect(bounds, Paint()..color = const Color(0xBFE8F0EF));
      _text(
        canvas,
        'Ⅱ',
        Offset(size.width * .5 - 10, size.height * .48),
        const Color(0xFF415768),
        34,
        FontWeight.w900,
      );
    }
    canvas.restore();
  }

  void _mountains(Canvas canvas, Size size) {
    final Paint far = Paint()
      ..color = const Color(0xFFA6C1CD).withValues(alpha: .72);
    final Paint near = Paint()
      ..color = const Color(0xFF91AEBB).withValues(alpha: .65);
    final Path farPath = Path()
      ..moveTo(0, size.height * .53)
      ..lineTo(size.width * .14, size.height * .23)
      ..lineTo(size.width * .25, size.height * .41)
      ..lineTo(size.width * .43, size.height * .16)
      ..lineTo(size.width * .59, size.height * .46)
      ..lineTo(size.width * .77, size.height * .22)
      ..lineTo(size.width, size.height * .5)
      ..lineTo(size.width, size.height * .62)
      ..lineTo(0, size.height * .62)
      ..close();
    canvas.drawPath(farPath, far);
    final Path nearPath = Path()
      ..moveTo(0, size.height * .55)
      ..lineTo(size.width * .20, size.height * .38)
      ..lineTo(size.width * .32, size.height * .51)
      ..lineTo(size.width * .52, size.height * .32)
      ..lineTo(size.width * .68, size.height * .53)
      ..lineTo(size.width * .86, size.height * .36)
      ..lineTo(size.width, size.height * .51)
      ..lineTo(size.width, size.height * .68)
      ..lineTo(0, size.height * .68)
      ..close();
    canvas.drawPath(nearPath, near);
    final Paint ridge = Paint()
      ..color = const Color(0xFFF7FAF8).withValues(alpha: .92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * .14, size.height * .23),
      Offset(size.width * .185, size.height * .34),
      ridge,
    );
    canvas.drawLine(
      Offset(size.width * .43, size.height * .16),
      Offset(size.width * .49, size.height * .29),
      ridge,
    );
    canvas.drawLine(
      Offset(size.width * .77, size.height * .22),
      Offset(size.width * .82, size.height * .31),
      ridge,
    );
  }

  void _flag(
    Canvas canvas,
    Offset base,
    double h,
    double pole,
    Color color,
    bool left,
  ) {
    canvas.drawLine(
      base,
      base.translate(0, -h),
      Paint()
        ..color = const Color(0xFF647D87)
        ..strokeWidth = pole,
    );
    final Path flag = Path()
      ..moveTo(base.dx, base.dy - h)
      ..lineTo(base.dx + (left ? 1 : -1) * h * .58, base.dy - h * .86)
      ..lineTo(base.dx, base.dy - h * .62)
      ..close();
    canvas.drawPath(flag, Paint()..color = color);
    canvas.drawCircle(
      base.translate(0, -h),
      pole * 1.5,
      Paint()..color = Colors.white,
    );
  }

  void _drawRider(Canvas canvas, Size size) {
    final double s = size.width * .15;
    final Rect board = Rect.fromCenter(
      center: Offset.zero,
      width: s,
      height: s * .11,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, s * .12),
        width: s * .94,
        height: s * .22,
      ),
      Paint()..color = const Color(0x553F5B69),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(board, Radius.circular(s * .06)),
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[
            Color(0xFFE09277),
            Color(0xFFF2C78B),
            Color(0xFF799CA9),
          ],
        ).createShader(board),
    );
    for (final double wheelX in <double>[-.31, .31]) {
      canvas.drawCircle(
        Offset(wheelX * s, s * .07),
        s * .045,
        Paint()..color = const Color(0xFF344C59),
      );
    }
    final Paint coat = Paint()
      ..color = const Color(0xFF426879)
      ..strokeWidth = s * .1
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, -s * .08), Offset(-s * .02, -s * .59), coat);
    canvas.drawCircle(
      Offset(-s * .03, -s * .72),
      s * .12,
      Paint()..color = const Color(0xFFE6B589),
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(-s * .03, -s * .72),
        width: s * .26,
        height: s * .2,
      ),
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = const Color(0xFF536D78)
        ..strokeWidth = s * .07
        ..style = PaintingStyle.stroke,
    );
    canvas.drawLine(
      Offset(-s * .02, -s * .48),
      Offset(-s * .33, -s * .22),
      coat..strokeWidth = s * .075,
    );
    canvas.drawLine(
      Offset(-s * .02, -s * .48),
      Offset(s * .26, -s * .18),
      Paint()
        ..color = const Color(0xFF426879)
        ..strokeWidth = s * .075
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(-s * .02, -s * .17),
      Offset(-s * .3, -s * .02),
      Paint()
        ..color = const Color(0xFF385B6B)
        ..strokeWidth = s * .08
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(-s * .02, -s * .17),
      Offset(s * .28, -s * .01),
      Paint()
        ..color = const Color(0xFF385B6B)
        ..strokeWidth = s * .08
        ..strokeCap = StrokeCap.round,
    );
  }

  void _text(
    Canvas canvas,
    String text,
    Offset point,
    Color color,
    double size,
    FontWeight weight,
  ) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
          letterSpacing: .3,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    painter.paint(canvas, point);
  }

  @override
  bool shouldRepaint(_SnowScenePainter oldDelegate) =>
      oldDelegate.engine.elapsed != engine.elapsed ||
      oldDelegate.engine.x != engine.x ||
      oldDelegate.engine.nextGate != engine.nextGate ||
      oldDelegate.paused != paused;
}
