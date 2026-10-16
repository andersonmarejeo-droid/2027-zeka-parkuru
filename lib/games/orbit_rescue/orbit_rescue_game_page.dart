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
import 'orbit_rescue_engine.dart';
import 'orbit_rescue_scenario.dart';

class OrbitRescueGamePage extends StatelessWidget {
  const OrbitRescueGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  static const int totalCases = OrbitRescueScenario.campaignLevels;
  static const int totalStars = totalCases * 3;

  static final List<ParkurLevelSpec> _levels = List<ParkurLevelSpec>.generate(
    totalCases,
    (int index) {
      final int level = index + 1;
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Kurtarma Yörüngesi ${level.toString().padLeft(2, '0')}',
        titleEn: 'Rescue Orbit ${level.toString().padLeft(2, '0')}',
        subtitleTr: switch (level) {
          <= 3 => 'Kütleçekimini oku; kapsülü ilk halkalara taşı.',
          <= 6 => 'Üç gövdenin çekimini sapan gibi kullan.',
          7 || 8 => 'İleri: dar yörünge penceresi ve sınırlı itki darbeleri.',
          9 => 'Uzman: kalkanı koru, hızı son halkada düşür.',
          _ => 'İki aşamalı usta finali: rotayı çiz, sonra uygula.',
        },
        subtitleEn: switch (level) {
          <= 3 => 'Read gravity and guide the capsule through the first rings.',
          <= 6 => 'Use the pull of three bodies as a slingshot.',
          7 || 8 => 'Advanced: narrow orbit windows and scarce impulse bursts.',
          9 => 'Expert: preserve the shield and brake for the final ring.',
          _ => 'Two-phase master finale: plot the route, then fly it.',
        },
        difficulty: switch (level) {
          <= 3 => 'USTALAŞMA',
          <= 6 => 'DERİNLEŞME',
          7 || 8 => 'İLERİ',
          9 => 'UZMAN',
          _ => 'USTA',
        },
        icon: Icons.public_rounded,
      );
    },
    growable: false,
  );

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.fun);
    return ParkurLevelHub(
      gameId: 'orbit_rescue',
      progressPrefix: 'orbit_rescue',
      titleTr: 'Yörünge Kurtarma',
      titleEn: 'Orbit Rescue',
      taglineTr: 'Kütleçekimini kullan • Rotayı çiz • Kurtar',
      taglineEn: 'Use gravity • Plot a line • Rescue',
      accent: skin.accent,
      icon: Icons.public_rounded,
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
          ) => OrbitRescuePlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class OrbitRescuePlayPage extends StatefulWidget {
  const OrbitRescuePlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<OrbitRescuePlayPage> createState() => _OrbitRescuePlayPageState();
}

class _OrbitRescuePlayPageState extends State<OrbitRescuePlayPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const Color _ink = Color(0xFF33435D);
  static const Color _accent = Color(0xFF62B7BD);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.fun,
  );
  late final Ticker _ticker;
  late OrbitRescueScenario _scenario;
  late OrbitRescueEngine _engine;
  late StudioGameSession _session;
  Duration _lastTick = Duration.zero;
  bool _ready = false;
  bool _planning = false;
  bool _paused = false;
  bool _finished = false;
  bool _english = false;
  String _feedback = '';
  Color _feedbackColor = _accent;

  int get _stars {
    if (_engine.misses == 0 &&
        _engine.accuracy >= .94 &&
        _engine.shield >= 82) {
      return 3;
    }
    if (_engine.accuracy >= .72 && _engine.misses <= 1) return 2;
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
      if (_ready && !_planning && !_paused && !_finished) _setPaused(true);
    } else if (state == AppLifecycleState.resumed && _paused && !_finished) {
      _setPaused(false);
    }
  }

  Future<void> _prepareScenario() async {
    OrbitRescueScenario scenario = OrbitRescueScenario.forLevel(
      widget.level.number,
    );
    try {
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      final String visitKey =
          'orbit_rescue_level_${widget.level.number}_visits';
      final int visits = await preferences.getInt(visitKey) ?? 0;
      if (visits > 0) {
        final int index =
            await preferences.getInt('orbit_rescue_practice_index') ?? 0;
        if (index < OrbitRescueScenario.practiceCourses) {
          final int next = index + 1;
          await preferences.setInt('orbit_rescue_practice_index', next);
          scenario = OrbitRescueScenario.forPracticeCourse(next);
        }
      }
      await preferences.setInt(visitKey, visits + 1);
    } catch (_) {
      scenario = OrbitRescueScenario.forLevel(widget.level.number);
    }
    if (!mounted) return;
    _scenario = scenario;
    _engine = OrbitRescueEngine(scenario: scenario);
    _session = StudioGameSession(
      level: widget.level.number,
      seed: scenario.seed,
    )..start();
    _planning = widget.level.number == 10;
    _ready = true;
    if (!_planning) _ticker.start();
    setState(() {});
  }

  void _launchMission() {
    if (!_ready || !_planning || _finished) return;
    setState(() {
      _planning = false;
      _feedback = _english
          ? 'VECTOR LOCKED · RESCUE IN PROGRESS'
          : 'ROTA KİLİTLENDİ · KURTARMA BAŞLADI';
    });
    _lastTick = Duration.zero;
    _ticker.start();
    unawaited(_audio.play(GameSound.uiClick, gain: .28));
  }

  void _setPaused(bool paused) {
    if (!_ready || _planning || _finished || _paused == paused) return;
    setState(() {
      _paused = paused;
      _engine.setControl(x: 0, y: 0);
    });
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

  void _control(double x, double y) {
    if (!_ready || _planning || _paused || _finished) return;
    _engine.setControl(x: x, y: y);
    setState(() {});
  }

  void _pulse() {
    if (!_ready || _planning || _paused || _finished) return;
    if (_engine.pulse()) {
      unawaited(
        _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .24),
      );
      _audio.hapticLight();
      setState(
        () => _feedback = _english ? 'IMPULSE FIRED' : 'İTKİ DARBESİ VERİLDİ',
      );
    } else {
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .16));
    }
  }

  void _tick(Duration elapsed) {
    if (!_ready || _planning || _paused || _finished) return;
    final double raw = (elapsed - _lastTick).inMicroseconds / 1000000;
    _lastTick = elapsed;
    if (raw <= 0) return;
    final OrbitStepResult result = _engine.step(raw.clamp(0, .04).toDouble());
    for (int i = 0; i < result.cleared; i++) {
      _session.recordAccepted(points: 120);
      _feedback = _english
          ? 'ORBIT WINDOW CLEARED'
          : 'YÖRÜNGE PENCERESİ GEÇİLDİ';
      _feedbackColor = _accent;
      _audio.hapticLight();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .2));
    }
    if (result.missed > 0) {
      for (int i = 0; i < result.missed; i++) {
        _session.recordMistake();
      }
      _feedback = _english
          ? 'WINDOW MISSED · SHIELD DAMAGED'
          : 'HALKA KAÇTI · KALKAN HASARLI';
      _feedbackColor = const Color(0xFFDD8479);
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .2));
    }
    if (result.collision) {
      _feedback = _english
          ? 'GRAVITY WELL CONTACT · CORRECT VECTOR'
          : 'KÜTLEÇEKİMİ TEMASI · VEKTÖRÜ DÜZELT';
      _feedbackColor = const Color(0xFFE3A66F);
    }
    if (result.docked) {
      unawaited(_finish(completed: true));
    } else if (result.failed) {
      unawaited(_finish(completed: false));
    }
    if (mounted && !_finished) setState(() {});
  }

  Future<void> _finish({required bool completed}) async {
    if (_finished || !mounted) return;
    _finished = true;
    _ticker.stop();
    _engine.setControl(x: 0, y: 0);
    if (!completed) {
      final bool retry =
          await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) => AlertDialog(
              title: Text(
                _english ? 'Rescue window lost' : 'Kurtarma penceresi kaçtı',
              ),
              content: Text(
                _english
                    ? 'The capsule crossed a gravity well or rescue ring too fast. Follow the orbit guide and save an impulse for the final brake.'
                    : 'Kapsül bir kütleçekimi kuyusuna ya da kurtarma halkasına hızlı girdi. Yörünge çizgisini izle, son fren için bir darbe sakla.',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(_english ? 'Orbit map' : 'Yörünge haritası'),
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
        setState(() {
          _engine.reset();
          _session = StudioGameSession(
            level: widget.level.number,
            seed: _scenario.seed,
          )..start();
          _planning = widget.level.number == 10;
          _paused = false;
          _finished = false;
        });
        if (!_planning) _ticker.start();
      } else {
        Navigator.of(
          context,
        ).pop(StudioGameResult.failed(score: _session.score).toParkurResult());
      }
      return;
    }
    final int score =
        _session.score +
        _engine.gatesCleared * 105 +
        _engine.bestCombo * 42 +
        _engine.shield.round() +
        _engine.fuel.round();
    _session.complete(
      stars: _stars,
      action: widget.level.number < OrbitRescueGamePage.totalCases
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
      titleTr: 'KURTARMA BAŞARILI',
      titleEn: 'RESCUE COMPLETE',
      detailTr:
          '${_engine.gatesCleared}/${_scenario.gates.length} halka · kalkan %${_engine.shield.round()} · ${_engine.pulsesUsed} itki darbesi',
      detailEn:
          '${_engine.gatesCleared}/${_scenario.gates.length} rings · shield ${_engine.shield.round()}% · ${_engine.pulsesUsed} impulse bursts',
      stars: _stars,
      score: score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < OrbitRescueGamePage.totalCases,
    );
    if (!mounted) return;
    final StudioResultAction action = switch (result) {
      ParkurResultAction.replay => StudioResultAction.replay,
      ParkurResultAction.next => StudioResultAction.next,
      _ => StudioResultAction.map,
    };
    Navigator.of(context).pop(
      StudioGameResult.completed(
        score: score,
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
          title: Text(_english ? 'ORBIT RESCUE' : 'YÖRÜNGE KURTARMA'),
        ),
        body: const Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    final bool active = !_planning && !_paused && !_finished;
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: _ink,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _english ? 'ORBIT RESCUE' : 'YÖRÜNGE KURTARMA',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('orbit_rescue_pause'),
            tooltip: _paused
                ? (_english ? 'Resume' : 'Devam et')
                : (_english ? 'Pause' : 'Duraklat'),
            onPressed: _planning ? null : () => _setPaused(!_paused),
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
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(11, 5, 11, 8),
              child: Column(
                children: <Widget>[
                  _OrbitHud(
                    ring: _engine.gatesCleared,
                    total: _scenario.gates.length,
                    fuel: _engine.fuel / _scenario.fuelCapacity,
                    shield: _engine.shield / _scenario.shieldCapacity,
                    pulses: _scenario.pulseLimit - _engine.pulsesUsed,
                    english: _english,
                  ),
                  const SizedBox(height: 7),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints limits) {
                        final double width = math.min(limits.maxWidth, 680);
                        final double height = math.min(
                          limits.maxHeight,
                          math.max(190, width * .72),
                        );
                        return Center(
                          child: SizedBox(
                            key: const ValueKey<String>('orbit_rescue_scene'),
                            width: width,
                            height: height,
                            child: CustomPaint(
                              painter: _OrbitScenePainter(
                                scenario: _scenario,
                                engine: _engine,
                                planning: _planning,
                                paused: _paused,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    height: 25,
                    child: Center(
                      child: Text(
                        _planning
                            ? (_english
                                  ? 'PLOT THE SLINGSHOT LINE BEFORE IGNITION'
                                  : 'ATEŞLEMEDEN ÖNCE SAPAN ROTASINI PLANLA')
                            : _paused
                            ? (_english
                                  ? 'ORBIT PAUSED'
                                  : 'YÖRÜNGE DURAKLATILDI')
                            : _feedback.isNotEmpty
                            ? _feedback
                            : (_english
                                  ? 'Stay ahead of the moving pull • brake before the rescue ring'
                                  : 'Değişen çekimi öngör • kurtarma halkasından önce frenle'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _feedback.isNotEmpty
                              ? _feedbackColor
                              : StudioVisuals.muted,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (_planning)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        key: const ValueKey<String>('orbit_rescue_launch'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF445C82),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _launchMission,
                        icon: const Icon(Icons.rocket_launch_rounded),
                        label: Text(
                          _english
                              ? 'LOCK PLAN & LAUNCH'
                              : 'ROTAYI KİLİTLE VE FIRLAT',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                  else
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _OrbitControlPad(
                            key: const ValueKey<String>(
                              'orbit_rescue_controls',
                            ),
                            x: _engine.thrustX,
                            y: _engine.thrustY,
                            enabled: active,
                            english: _english,
                            onControl: _control,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _ImpulseButton(
                          key: const ValueKey<String>('orbit_rescue_impulse'),
                          count: _scenario.pulseLimit - _engine.pulsesUsed,
                          enabled: active && _engine.fuel >= 6,
                          english: _english,
                          onPressed: _pulse,
                        ),
                      ],
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

class _OrbitHud extends StatelessWidget {
  const _OrbitHud({
    required this.ring,
    required this.total,
    required this.fuel,
    required this.shield,
    required this.pulses,
    required this.english,
  });

  final int ring;
  final int total;
  final double fuel;
  final double shield;
  final int pulses;
  final bool english;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      _OrbitMetric(
        label: english ? 'RINGS' : 'HALKA',
        value: '$ring / $total',
        icon: Icons.radio_button_checked_rounded,
        color: const Color(0xFF62B7BD),
      ),
      const SizedBox(width: 5),
      _OrbitMetric(
        label: english ? 'FUEL' : 'YAKIT',
        value: '${(fuel * 100).round()}%',
        icon: Icons.bolt_rounded,
        color: const Color(0xFFE4B76D),
        fraction: fuel,
      ),
      const SizedBox(width: 5),
      _OrbitMetric(
        label: english ? 'SHIELD' : 'KALKAN',
        value: '${(shield * 100).round()}%',
        icon: Icons.shield_rounded,
        color: const Color(0xFF8E9ED0),
        fraction: shield,
      ),
      const SizedBox(width: 5),
      _OrbitMetric(
        label: english ? 'PULSES' : 'DARBE',
        value: '$pulses',
        icon: Icons.flash_on_rounded,
        color: const Color(0xFFE4B76D),
      ),
    ],
  );
}

class _OrbitMetric extends StatelessWidget {
  const _OrbitMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.fraction,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final double? fraction;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE7E9EF)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0B2D3A4D),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 11, color: color),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 7.2,
                    fontWeight: FontWeight.w900,
                    color: _OrbitRescuePlayPageState._ink,
                    letterSpacing: .25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: <Widget>[
              Text(
                value,
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              const Spacer(),
              if (fraction != null)
                SizedBox(
                  width: 17,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      value: fraction!.clamp(0, 1),
                      backgroundColor: const Color(0xFFECEEF2),
                      color: color,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _OrbitControlPad extends StatelessWidget {
  const _OrbitControlPad({
    super.key,
    required this.x,
    required this.y,
    required this.enabled,
    required this.english,
    required this.onControl,
  });
  final double x;
  final double y;
  final bool enabled;
  final bool english;
  final void Function(double x, double y) onControl;

  void _update(Offset local, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final Offset delta = local - center;
    final double radius = math.min(size.width, size.height) * .39;
    final Offset normalized = Offset(delta.dx / radius, -delta.dy / radius);
    final double magnitude = normalized.distance;
    final Offset bounded = magnitude > 1 ? normalized / magnitude : normalized;
    onControl(bounded.dx, bounded.dy);
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 86,
    child: LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size size = Size(math.min(200, constraints.maxWidth), 86);
        return Center(
          child: SizedBox.fromSize(
            size: size,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: enabled
                  ? (DragStartDetails details) =>
                        _update(details.localPosition, size)
                  : null,
              onPanUpdate: enabled
                  ? (DragUpdateDetails details) =>
                        _update(details.localPosition, size)
                  : null,
              onPanEnd: enabled ? (_) => onControl(0, 0) : null,
              child: CustomPaint(
                painter: _OrbitPadPainter(x: x, y: y, enabled: enabled),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _OrbitPadPainter extends CustomPainter {
  const _OrbitPadPainter({
    required this.x,
    required this.y,
    required this.enabled,
  });
  final double x;
  final double y;
  final bool enabled;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = math.min(size.width, size.height) * .43;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = enabled ? const Color(0xFFE9EEF4) : const Color(0xFFEFF1F4),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFD5DCE7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawCircle(
      center,
      radius * .58,
      Paint()
        ..color = const Color(0xFFD9E1E9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      Paint()
        ..color = const Color(0x338C9BAF)
        ..strokeWidth = 1,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      Paint()
        ..color = const Color(0x338C9BAF)
        ..strokeWidth = 1,
    );
    final Offset thumb = center + Offset(x, -y) * radius * .58;
    canvas.drawCircle(
      thumb.translate(0, 2),
      radius * .31,
      Paint()..color = const Color(0x192D3A4D),
    );
    canvas.drawCircle(
      thumb,
      radius * .31,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF6FC7CC), Color(0xFF4A929F)],
        ).createShader(Rect.fromCircle(center: thumb, radius: radius * .31)),
    );
    canvas.drawCircle(
      thumb,
      radius * .31,
      Paint()
        ..color = const Color(0xFF397A86)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(_OrbitPadPainter oldDelegate) =>
      x != oldDelegate.x ||
      y != oldDelegate.y ||
      enabled != oldDelegate.enabled;
}

class _ImpulseButton extends StatelessWidget {
  const _ImpulseButton({
    super.key,
    required this.count,
    required this.enabled,
    required this.english,
    required this.onPressed,
  });
  final int count;
  final bool enabled;
  final bool english;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 88,
    height: 80,
    child: FilledButton(
      onPressed: enabled ? onPressed : null,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF4A587A),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFD9DDE6),
        padding: const EdgeInsets.all(7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.flash_on_rounded, size: 22),
          const SizedBox(height: 2),
          Text(
            english ? 'PULSE' : 'DARBE',
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
          ),
          Text(
            '$count',
            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    ),
  );
}

class _OrbitScenePainter extends CustomPainter {
  const _OrbitScenePainter({
    required this.scenario,
    required this.engine,
    required this.planning,
    required this.paused,
  });
  final OrbitRescueScenario scenario;
  final OrbitRescueEngine engine;
  final bool planning;
  final bool paused;

  static const List<Color> _bodyColors = <Color>[
    Color(0xFFCA9672),
    Color(0xFF879BC5),
    Color(0xFF69B7B2),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    final RRect panel = RRect.fromRectAndRadius(
      bounds,
      const Radius.circular(23),
    );
    canvas.drawRRect(
      panel,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF141D35),
            Color(0xFF0D1427),
            Color(0xFF18223C),
          ],
        ).createShader(bounds),
    );
    canvas.save();
    canvas.clipRRect(panel);
    final math.Random starRandom = math.Random(scenario.seed);
    for (int i = 0; i < 52; i++) {
      final Offset star = Offset(
        starRandom.nextDouble() * size.width,
        starRandom.nextDouble() * size.height,
      );
      final double radius = i % 9 == 0 ? 1.35 : .65;
      canvas.drawCircle(
        star,
        radius,
        Paint()..color = Colors.white.withValues(alpha: i % 4 == 0 ? .60 : .25),
      );
    }
    _paintNebula(canvas, size);
    for (int index = 0; index < scenario.bodies.length; index++) {
      _paintOrbit(canvas, size, scenario.bodies[index], index);
    }
    for (int index = 0; index < scenario.gates.length; index++) {
      _paintGate(canvas, size, scenario.gates[index], index);
    }
    _paintTrajectory(canvas, size);
    _paintShip(canvas, size);
    _paintLegend(canvas, size);
    if (planning || paused) {
      final String label = planning ? 'PLAN / 02' : 'PAUSED';
      _drawText(
        canvas,
        label,
        Offset(size.width - 81, 14),
        const Color(0xFFE2C994),
        8,
        FontWeight.w900,
      );
    }
    canvas.restore();
    canvas.drawRRect(
      panel,
      Paint()
        ..color = const Color(0x228494BA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _paintNebula(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(size.width * .48, size.height * .42),
      size.width * .34,
      Paint()
        ..shader =
            RadialGradient(
              colors: <Color>[const Color(0x1B5674B2), const Color(0x005674B2)],
            ).createShader(
              Rect.fromCircle(
                center: Offset(size.width * .48, size.height * .42),
                radius: size.width * .34,
              ),
            ),
    );
    final Paint grid = Paint()
      ..color = const Color(0x0C7E95C3)
      ..strokeWidth = .6;
    for (int i = 1; i < 5; i++) {
      final double x = size.width * i / 5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (int i = 1; i < 4; i++) {
      final double y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
  }

  void _paintOrbit(Canvas canvas, Size size, OrbitBody body, int index) {
    final Offset center = _point(size, body.x, body.y);
    final double scale = math.min(size.width, size.height);
    final double radius = body.radius * scale;
    final Color tint = _bodyColors[body.tintIndex];
    final Rect orbit = Rect.fromCenter(
      center: center,
      width: radius * (5.7 + index * .32),
      height: radius * (3.2 + index * .26),
    );
    canvas.drawOval(
      orbit,
      Paint()
        ..color = tint.withValues(alpha: .24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .75,
    );
    canvas.drawCircle(
      center.translate(0, radius * .13),
      radius * 1.27,
      Paint()
        ..color = const Color(0x44222B42)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(
      center,
      radius * 1.42,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[tint.withValues(alpha: .20), Colors.transparent],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 1.42)),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.35, -.42),
          colors: <Color>[
            Color.lerp(tint, Colors.white, .36)!,
            tint,
            Color.lerp(tint, const Color(0xFF111629), .70)!,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center.translate(-radius * .12, -radius * .16),
      radius * .78,
      Paint()
        ..color = Colors.white.withValues(alpha: .08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    for (int crater = 0; crater < 3; crater++) {
      final Offset spot =
          center +
          Offset(
            (crater - 1) * radius * .31,
            ((crater % 2) == 0 ? .22 : -.3) * radius,
          );
      canvas.drawCircle(
        spot,
        radius * (.08 + crater * .015),
        Paint()..color = Colors.black.withValues(alpha: .12),
      );
    }
    _drawText(
      canvas,
      'GRAVITY ${index + 1}',
      center + Offset(-radius * 1.2, radius * 1.2),
      tint.withValues(alpha: .87),
      6.2,
      FontWeight.w800,
    );
  }

  void _paintGate(Canvas canvas, Size size, OrbitGate gate, int index) {
    final Offset center = _point(size, gate.x, gate.yAt(engine.elapsed));
    final double radius = gate.radius * math.min(size.width, size.height);
    final bool passed = index < engine.nextGate;
    final Color color = gate.docking
        ? const Color(0xFFE7C486)
        : const Color(0xFF72CAD0);
    if (gate.motionAmplitude > 0) {
      final Offset low = _point(size, gate.x, gate.y - gate.motionAmplitude);
      final Offset high = _point(size, gate.x, gate.y + gate.motionAmplitude);
      canvas.drawLine(
        low,
        high,
        Paint()
          ..color = color.withValues(alpha: .23)
          ..strokeWidth = 1,
      );
      canvas.drawCircle(low, 2, Paint()..color = color.withValues(alpha: .36));
      canvas.drawCircle(high, 2, Paint()..color = color.withValues(alpha: .36));
    }
    final Paint ringPaint = Paint()
      ..color = passed
          ? color.withValues(alpha: .32)
          : color.withValues(alpha: .87)
      ..style = PaintingStyle.stroke
      ..strokeWidth = gate.docking ? 3 : 2;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: .08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(center, radius, ringPaint);
    canvas.drawCircle(
      center,
      radius * .72,
      Paint()
        ..color = color.withValues(alpha: .30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .7,
    );
    for (int mark = 0; mark < 4; mark++) {
      final double angle = mark * math.pi / 2;
      final Offset from =
          center + Offset(math.cos(angle), math.sin(angle)) * radius * .88;
      final Offset to =
          center + Offset(math.cos(angle), math.sin(angle)) * radius * 1.12;
      canvas.drawLine(
        from,
        to,
        Paint()
          ..color = color
          ..strokeWidth = 1.3
          ..strokeCap = StrokeCap.round,
      );
    }
    _drawText(
      canvas,
      gate.docking ? 'RESCUE' : 'G${index + 1}',
      center + Offset(-radius * .38, radius + 5),
      color,
      6.5,
      FontWeight.w900,
    );
  }

  void _paintTrajectory(Canvas canvas, Size size) {
    double px = engine.x;
    double py = engine.y;
    double vx = engine.velocityX;
    double vy = engine.velocityY;
    for (int i = 1; i <= 18; i++) {
      const double dt = .14;
      double gx = 0;
      double gy = 0;
      for (final OrbitBody body in scenario.bodies) {
        final double dx = body.x - px;
        final double dy = body.y - py;
        final double inv = 1 / math.pow(dx * dx + dy * dy + .006, 1.5);
        gx += dx * body.gravity * inv;
        gy += dy * body.gravity * inv;
      }
      vx += (gx + engine.thrustX * .255) * dt;
      vy += (gy + engine.thrustY * .255) * dt;
      px += vx * dt;
      py += vy * dt;
      if (px < 0 || px > 1 || py < 0 || py > 1) break;
      final double alpha = .48 * (1 - i / 21);
      canvas.drawCircle(
        _point(size, px, py),
        i % 3 == 0 ? 1.8 : 1.15,
        Paint()..color = const Color(0xFFB5C7E8).withValues(alpha: alpha),
      );
    }
  }

  void _paintShip(Canvas canvas, Size size) {
    final Offset center = _point(size, engine.x, engine.y);
    final double scale = math.min(size.width, size.height) * .025;
    final double angle = math.atan2(engine.velocityY, engine.velocityX);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.drawCircle(
      Offset.zero,
      scale * 1.55,
      Paint()
        ..color = const Color(0x2867D1D1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    final Path wing = Path()
      ..moveTo(scale * 1.8, 0)
      ..lineTo(-scale * .8, -scale * .85)
      ..lineTo(-scale * .44, 0)
      ..lineTo(-scale * .8, scale * .85)
      ..close();
    canvas.drawPath(
      wing.shift(Offset(0, 1.5)),
      Paint()..color = const Color(0x77343D5C),
    );
    canvas.drawPath(
      wing,
      Paint()
        ..shader =
            const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[Color(0xFFF0D49B), Color(0xFF8FAFC1)],
            ).createShader(
              Rect.fromCenter(
                center: Offset.zero,
                width: scale * 3,
                height: scale * 2,
              ),
            ),
    );
    canvas.drawPath(
      wing,
      Paint()
        ..color = const Color(0xFFE9E9D9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawCircle(
      Offset(scale * .38, 0),
      scale * .23,
      Paint()..color = const Color(0xFF72D7D4),
    );
    if (engine.thrustX.abs() + engine.thrustY.abs() > .18) {
      final Path flame = Path()
        ..moveTo(-scale * .8, -scale * .17)
        ..lineTo(-scale * 1.7, 0)
        ..lineTo(-scale * .8, scale * .17)
        ..close();
      canvas.drawPath(
        flame,
        Paint()..color = const Color(0xFFF0B968).withValues(alpha: .85),
      );
    }
    canvas.restore();
  }

  void _paintLegend(Canvas canvas, Size size) {
    final Offset start = _point(size, .075, .5);
    canvas.drawCircle(start, 4, Paint()..color = const Color(0xFFE4B76D));
    _drawText(
      canvas,
      'ORIGIN',
      start + const Offset(7, -3),
      const Color(0xFFC0C8D9),
      6.4,
      FontWeight.w800,
    );
    if (planning) {
      _drawText(
        canvas,
        '01  MAP THE PULL',
        const Offset(14, 15),
        const Color(0xFF89D0D0),
        7.4,
        FontWeight.w900,
      );
    }
  }

  Offset _point(Size size, double x, double y) =>
      Offset(x * size.width, y * size.height);

  void _drawText(
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
          letterSpacing: .35,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    painter.paint(canvas, point);
  }

  @override
  bool shouldRepaint(_OrbitScenePainter oldDelegate) =>
      oldDelegate.engine.x != engine.x ||
      oldDelegate.engine.y != engine.y ||
      oldDelegate.engine.nextGate != engine.nextGate ||
      oldDelegate.engine.fuel != engine.fuel ||
      oldDelegate.engine.pulsesUsed != engine.pulsesUsed ||
      oldDelegate.planning != planning ||
      oldDelegate.paused != paused;
}
