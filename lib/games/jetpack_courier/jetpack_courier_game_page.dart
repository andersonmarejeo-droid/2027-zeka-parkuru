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
import 'jetpack_courier_engine.dart';
import 'jetpack_courier_scenario.dart';

class JetpackCourierGamePage extends StatelessWidget {
  const JetpackCourierGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  static const int totalCases = JetpackCourierScenario.campaignLevels;
  static const int totalStars = totalCases * 3;

  static final List<ParkurLevelSpec> _levels = List<ParkurLevelSpec>.generate(
    totalCases,
    (int index) {
      final int level = index + 1;
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Kurye Rotası ${level.toString().padLeft(2, '0')}',
        titleEn: 'Delivery Route ${level.toString().padLeft(2, '0')}',
        subtitleTr: switch (level) {
          <= 3 => 'Yumuşak gazla irtifayı koru; her halkada paketi sabitle.',
          <= 6 => 'Yatay rüzgârı oku; yakıt ve ısıyı soğutma bacasında yönet.',
          7 || 8 => 'İleri: dar kapılar, dalgalı hava ve kırılgan kargo.',
          9 => 'Uzman: kısa itki, yüksek ısı ve hassas teslimat çizgisi.',
          _ => 'Usta finali: düşük yakıt, dar halka ve nokta inişi.',
        },
        subtitleEn: switch (level) {
          <= 3 => 'Modulate thrust to hold altitude and steady the parcel at each ring.',
          <= 6 => 'Read crosswind; manage fuel and heat at coolant vents.',
          7 || 8 => 'Advanced: tight rings, gusts and fragile cargo.',
          9 => 'Expert: short bursts, high heat and a precise delivery line.',
          _ => 'Master finale: low fuel, narrow rings and a soft landing.',
        },
        difficulty: switch (level) {
          <= 3 => 'USTALAŞMA',
          <= 6 => 'DERİNLEŞME',
          7 || 8 => 'İLERİ',
          9 => 'UZMAN',
          _ => 'USTA',
        },
        icon: Icons.rocket_launch_rounded,
      );
    },
    growable: false,
  );

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.fun);
    return ParkurLevelHub(
      gameId: 'jetpack_courier',
      progressPrefix: 'jetpack_courier',
      titleTr: 'Jetpack Kurye',
      titleEn: 'Jetpack Courier',
      taglineTr: 'Gazı ayarla • Paketi koru • Yumuşak in',
      taglineEn: 'Modulate thrust • Protect the parcel • Land soft',
      accent: skin.accent,
      icon: Icons.rocket_launch_rounded,
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
          ) => JetpackCourierPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class JetpackCourierPlayPage extends StatefulWidget {
  const JetpackCourierPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<JetpackCourierPlayPage> createState() => _JetpackCourierPlayPageState();
}

class _JetpackCourierPlayPageState extends State<JetpackCourierPlayPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const Color _ink = Color(0xFF405869);
  static const Color _accent = Color(0xFF4E9995);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.fun,
  );
  late final Ticker _ticker;
  late JetpackCourierScenario _scenario;
  late JetpackCourierEngine _engine;
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
        _engine.accuracy >= .94 &&
        _engine.packageIntegrity >= 86) {
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
      if (_ready && !_paused && !_finished) _setPaused(true);
    } else if (state == AppLifecycleState.resumed && _paused && !_finished) {
      _setPaused(false);
    }
  }

  Future<void> _prepareScenario() async {
    JetpackCourierScenario scenario = JetpackCourierScenario.forLevel(
      widget.level.number,
    );
    try {
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      final String visitKey =
          'jetpack_courier_level_${widget.level.number}_visits';
      final int visits = await preferences.getInt(visitKey) ?? 0;
      if (visits > 0) {
        final int index =
            await preferences.getInt('jetpack_courier_practice_index') ?? 0;
        if (index < JetpackCourierScenario.practiceFlights) {
          final int next = index + 1;
          await preferences.setInt('jetpack_courier_practice_index', next);
          scenario = JetpackCourierScenario.forPracticeFlight(next);
        }
      }
      await preferences.setInt(visitKey, visits + 1);
    } catch (_) {
      scenario = JetpackCourierScenario.forLevel(widget.level.number);
    }
    if (!mounted) return;
    _scenario = scenario;
    _startFlight();
    setState(() => _ready = true);
  }

  void _startFlight() {
    _ticker.stop();
    _engine = JetpackCourierEngine(scenario: _scenario);
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
    setState(() {
      _paused = paused;
      _engine.setControl(steer: 0, throttle: 0);
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

  void _control(double steer, double throttle) {
    if (!_ready || _paused || _finished) return;
    _engine.setControl(steer: steer, throttle: throttle);
    if (mounted) setState(() {});
  }

  void _tick(Duration elapsed) {
    if (!_ready || _paused || _finished) return;
    final double raw = (elapsed - _lastTick).inMicroseconds / 1000000;
    _lastTick = elapsed;
    if (raw <= 0) return;
    final CourierStepResult result = _engine.step(raw.clamp(0, .04).toDouble());
    for (int i = 0; i < result.cleared; i++) {
      _session.recordAccepted(points: 100);
      _feedback = _english ? 'PARCEL SECURE' : 'PAKET SABİT';
      _feedbackColor = _accent;
      _audio.hapticLight();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .2));
    }
    for (int i = 0; i < result.missed; i++) {
      _session.recordMistake();
      _feedback = _english
          ? 'CARGO SHOCK · STEADY THE JET'
          : 'KARGO SARSILDI · JETİ DENGELE';
      _feedbackColor = const Color(0xFFD17768);
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .18));
    }
    if (result.overheated) {
      _feedback = _english
          ? 'THERMAL LOCK · RELEASE TO COOL'
          : 'ISI KİLİDİ · SOĞUMASI İÇİN GAZI BIRAK';
      _feedbackColor = const Color(0xFFD48C55);
      unawaited(
        _audioProfile.play(_audio, GameAudioEvent.timeWarning, gain: .18),
      );
    }
    if (result.impact) {
      _feedback = _english
          ? 'HARD CONTACT · PARCEL DAMAGED'
          : 'SERT TEMAS · PAKET HASAR GÖRDÜ';
      _feedbackColor = const Color(0xFFD17768);
    }
    if (result.completed) {
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
    _engine.setControl(steer: 0, throttle: 0);
    if (!completed) {
      final bool retry =
          await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) => AlertDialog(
              title: Text(
                _english ? 'Delivery run ended' : 'Teslimat rotası bitti',
              ),
              content: Text(
                _english
                    ? 'The parcel took too much shock or too many rings were missed. Reduce throttle near the dock and cool the pack between bursts.'
                    : 'Paket çok sarsıldı ya da halka sınırı aşıldı. İniş cebinde gazı azalt, itişler arasında paketi soğut.',
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
        setState(_startFlight);
      } else {
        Navigator.of(
          context,
        ).pop(StudioGameResult.failed(score: _session.score).toParkurResult());
      }
      return;
    }

    final int score =
        _session.score +
        _engine.checkpointsCleared * 85 +
        _engine.bestCombo * 35 +
        _engine.packageIntegrity.round();
    _session.complete(
      stars: _stars,
      action: widget.level.number < JetpackCourierGamePage.totalCases
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
      titleTr: 'TESLİMAT TAMAMLANDI',
      titleEn: 'DELIVERY COMPLETE',
      detailTr:
          '${_engine.checkpointsCleared}/${_scenario.checkpoints.length} halka · paket %${_engine.packageIntegrity.round()} · yakıt %${_engine.fuel.round()}',
      detailEn:
          '${_engine.checkpointsCleared}/${_scenario.checkpoints.length} rings · cargo ${_engine.packageIntegrity.round()}% · fuel ${_engine.fuel.round()}%',
      stars: _stars,
      score: score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < JetpackCourierGamePage.totalCases,
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
          title: Text(_english ? 'JETPACK COURIER' : 'JETPACK KURYE'),
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
          _english ? 'JETPACK COURIER' : 'JETPACK KURYE',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('jetpack_courier_pause'),
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
                  _CourierHud(
                    ring: _engine.checkpointsCleared,
                    total: _scenario.checkpoints.length,
                    fuel: _engine.fuel / _scenario.fuelCapacity,
                    heat: _engine.heat / 100,
                    cargo: _engine.packageIntegrity,
                    english: _english,
                  ),
                  const SizedBox(height: 7),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints limits) {
                        final double width = math.min(limits.maxWidth, 640);
                        final double height = math.min(
                          limits.maxHeight,
                          math.max(180, width * .76),
                        );
                        return Center(
                          child: SizedBox(
                            key: const ValueKey<String>(
                              'jetpack_courier_scene',
                            ),
                            width: width,
                            height: height,
                            child: CustomPaint(
                              painter: _CourierScenePainter(
                                scenario: _scenario,
                                engine: _engine,
                                paused: _paused,
                                english: _english,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    height: 24,
                    child: Center(
                      child: Text(
                        _paused
                            ? (_english ? 'FLIGHT PAUSED' : 'UÇUŞ DURAKLATILDI')
                            : _feedback.isNotEmpty
                            ? _feedback
                            : (_english
                                  ? 'Steer left/right • set thrust softly • release to cool'
                                  : 'Sağa-sola yönlen • gazı yumuşat • soğutmak için bırak'),
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
                  const SizedBox(height: 4),
                  _CourierStick(
                    key: const ValueKey<String>('jetpack_courier_controls'),
                    steer: _engine.steer,
                    throttle: _engine.throttle,
                    enabled: !_paused && !_finished,
                    english: _english,
                    onControl: _control,
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

class _CourierHud extends StatelessWidget {
  const _CourierHud({
    required this.ring,
    required this.total,
    required this.fuel,
    required this.heat,
    required this.cargo,
    required this.english,
  });
  final int ring;
  final int total;
  final double fuel;
  final double heat;
  final double cargo;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey<String>('jetpack_courier_hud'),
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
    decoration: BoxDecoration(
      color: StudioVisuals.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: StudioVisuals.line),
      boxShadow: StudioVisuals.softShadow,
    ),
    child: Row(
      children: <Widget>[
        _CourierMetric(
          label: english ? 'RINGS' : 'HALKA',
          value: '$ring / $total',
          icon: Icons.circle_outlined,
          color: const Color(0xFF5B98A2),
        ),
        _divider(),
        _CourierMetric(
          label: english ? 'FUEL' : 'YAKIT',
          value: '${(fuel * 100).round()}%',
          icon: Icons.local_gas_station_rounded,
          color: fuel < .25 ? const Color(0xFFD16E64) : const Color(0xFF668FA0),
        ),
        _divider(),
        _CourierMetric(
          label: english ? 'HEAT' : 'ISI',
          value: '${(heat * 100).round()}%',
          icon: Icons.thermostat_rounded,
          color: heat > .7 ? const Color(0xFFD28B55) : const Color(0xFF849DAA),
        ),
        _divider(),
        _CourierMetric(
          label: english ? 'CARGO' : 'PAKET',
          value: '${cargo.round()}%',
          icon: Icons.inventory_2_outlined,
          color: cargo < 55 ? const Color(0xFFD16E64) : const Color(0xFF4E9995),
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

class _CourierMetric extends StatelessWidget {
  const _CourierMetric({
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
                  color: _JetpackCourierPlayPageState._ink,
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

class _CourierStick extends StatelessWidget {
  const _CourierStick({
    super.key,
    required this.steer,
    required this.throttle,
    required this.enabled,
    required this.english,
    required this.onControl,
  });
  final double steer;
  final double throttle;
  final bool enabled;
  final bool english;
  final void Function(double steer, double throttle) onControl;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: Text(
          english ? 'STEER' : 'YÖN',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: StudioVisuals.muted,
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: .5,
          ),
        ),
      ),
      Semantics(
        label: english
            ? 'Directional and jet thrust control'
            : 'Yön ve jet itki kontrolü',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: enabled
              ? (DragStartDetails d) => _move(d.localPosition)
              : null,
          onPanUpdate: enabled
              ? (DragUpdateDetails d) => _move(d.localPosition)
              : null,
          onPanEnd: enabled ? (_) => onControl(0, 0) : null,
          child: CustomPaint(
            key: const ValueKey<String>('jetpack_courier_stick'),
            size: const Size(126, 76),
            painter: _CourierStickPainter(steer: steer, throttle: throttle),
          ),
        ),
      ),
      Expanded(
        child: Text(
          english ? 'THRUST' : 'İTKİ',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: StudioVisuals.muted,
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: .5,
          ),
        ),
      ),
    ],
  );

  void _move(Offset point) => onControl(
    ((point.dx / 126) * 2 - 1).clamp(-1, 1).toDouble(),
    ((.7 - point.dy / 76) * 1.45).clamp(0, 1).toDouble(),
  );
}

class _CourierStickPainter extends CustomPainter {
  const _CourierStickPainter({required this.steer, required this.throttle});
  final double steer;
  final double throttle;
  @override
  void paint(Canvas canvas, Size size) {
    final RRect plate = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(18),
    );
    canvas.drawRRect(plate, Paint()..color = const Color(0xFFEAF1F1));
    canvas.drawRRect(
      plate,
      Paint()
        ..color = const Color(0xFFD2E0E2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final Paint guide = Paint()
      ..color = const Color(0xFFC7D8DB)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(size.width * .5, 8),
      Offset(size.width * .5, size.height - 8),
      guide,
    );
    canvas.drawLine(
      Offset(10, size.height * .5),
      Offset(size.width - 10, size.height * .5),
      guide,
    );
    canvas.drawCircle(
      Offset(size.width * .5, size.height * .5),
      22,
      Paint()..color = const Color(0xFFDAE7E7),
    );
    final Offset knob = Offset(
      size.width * (.5 + steer * .35),
      size.height * (.7 - throttle * .48),
    );
    canvas.drawCircle(
      knob.translate(0, 2),
      12,
      Paint()..color = const Color(0x33405D68),
    );
    canvas.drawCircle(
      knob,
      12,
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[Color(0xFFA8D5D0), Color(0xFF4E9995)],
        ).createShader(Rect.fromCircle(center: knob, radius: 12)),
    );
    canvas.drawCircle(
      knob.translate(-3, -4),
      3,
      Paint()..color = Colors.white.withValues(alpha: .82),
    );
    final Rect meter = Rect.fromLTWH(size.width - 8, 10, 3, size.height - 20);
    canvas.drawRRect(
      RRect.fromRectAndRadius(meter, const Radius.circular(3)),
      Paint()..color = const Color(0xFFD5E1E2),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          meter.left,
          meter.bottom - meter.height * throttle,
          meter.width,
          meter.height * throttle,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFE4AC69),
    );
  }

  @override
  bool shouldRepaint(_CourierStickPainter oldDelegate) =>
      oldDelegate.steer != steer || oldDelegate.throttle != throttle;
}

class _CourierScenePainter extends CustomPainter {
  const _CourierScenePainter({
    required this.scenario,
    required this.engine,
    required this.paused,
    required this.english,
  });
  final JetpackCourierScenario scenario;
  final JetpackCourierEngine engine;
  final bool paused;
  final bool english;

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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFB6D9E0),
            Color(0xFFE2EDE8),
            Color(0xFFF7E9D8),
          ],
        ).createShader(bounds),
    );
    final Paint sun = Paint()
      ..shader = RadialGradient(
        center: const Alignment(.72, -.72),
        radius: .68,
        colors: <Color>[
          const Color(0xFFFFF1D4).withValues(alpha: .82),
          Colors.transparent,
        ],
      ).createShader(bounds);
    canvas.drawRect(bounds, sun);
    _city(canvas, size);

    final double horizon = size.height * .18;
    final double lookAhead = 7.0;
    for (
      int index = engine.nextCheckpoint;
      index < math.min(scenario.checkpoints.length, engine.nextCheckpoint + 5);
      index++
    ) {
      final CourierCheckpoint point = scenario.checkpoints[index];
      final double depth =
          (point.progress - engine.progress).clamp(0, lookAhead) / lookAhead;
      final double scale = .20 + (1 - depth) * .82;
      final double cx = size.width * (.5 + (point.centerX - .5) * scale);
      final double cy =
          horizon +
          (1 - point.centerAltitude) * size.height * (.48 + (1 - depth) * .18);
      final double radius = size.width * (.035 + (1 - depth) * .045);
      final Color ringColor = point.deliveryDock
          ? const Color(0xFFE0A66D)
          : point.coolantVent
          ? const Color(0xFF68A8A5)
          : const Color(0xFF6E9EAA);
      canvas.drawCircle(
        Offset(cx, cy),
        radius + 5,
        Paint()
          ..color = ringColor.withValues(alpha: .12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      canvas.drawCircle(
        Offset(cx, cy),
        radius,
        Paint()
          ..color = ringColor.withValues(alpha: .82)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(2, radius * .15),
      );
      canvas.drawCircle(
        Offset(cx, cy),
        radius * .72,
        Paint()
          ..color = Colors.white.withValues(alpha: .14)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      final CourierCheckpointState state = engine.states[index];
      if (state == CourierCheckpointState.cleared) {
        canvas.drawCircle(
          Offset(cx, cy),
          radius * .55,
          Paint()..color = const Color(0xFF78BCA7).withValues(alpha: .32),
        );
      }
    }

    final Offset courier = Offset(
      size.width * (.5 + (engine.x - .5) * .68),
      size.height * (.82 - (engine.altitude - .12) * .70),
    );
    _courier(
      canvas,
      courier,
      size,
      engine.thrustActive,
      engine.lateralVelocity,
      engine.verticalVelocity,
    );

    _text(
      canvas,
      english
          ? 'ROUTE ${engine.nextCheckpoint + 1} / ${scenario.checkpoints.length}'
          : 'ROTA ${engine.nextCheckpoint + 1} / ${scenario.checkpoints.length}',
      const Offset(13, 13),
      const Color(0xFF496775),
      9,
      FontWeight.w900,
    );
    if (paused) {
      canvas.drawRect(bounds, Paint()..color = const Color(0xBFEAF0ED));
      _text(
        canvas,
        'Ⅱ',
        Offset(size.width * .5 - 9, size.height * .48),
        const Color(0xFF405869),
        34,
        FontWeight.w900,
      );
    }
    canvas.restore();
  }

  void _city(Canvas canvas, Size size) {
    final Paint distant = Paint()
      ..color = const Color(0xFF91B4BF).withValues(alpha: .44);
    final Paint near = Paint()
      ..color = const Color(0xFF789CA8).withValues(alpha: .36);
    for (int index = 0; index < 10; index++) {
      final double w = size.width * (.035 + (index % 3) * .012);
      final double h = size.height * (.11 + ((index * 7) % 5) * .023);
      final double x = index * size.width / 9 - w * .3;
      final Rect building = Rect.fromLTWH(x, size.height * .42 - h, w, h);
      canvas.drawRRect(
        RRect.fromRectAndRadius(building, const Radius.circular(2)),
        index.isEven ? distant : near,
      );
      final Paint window = Paint()
        ..color = const Color(0xFFF4E4C6).withValues(alpha: .65);
      for (int row = 0; row < 3; row++) {
        canvas.drawRect(
          Rect.fromLTWH(x + w * .25, size.height * .42 - h + row * 7 + 4, 2, 3),
          window,
        );
      }
    }
    final Rect ground = Rect.fromLTWH(
      0,
      size.height * .44,
      size.width,
      size.height * .56,
    );
    canvas.drawRect(
      ground,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFFDAE8E5), Color(0xFFCADBD7)],
        ).createShader(ground),
    );
    final Rect pad = Rect.fromLTWH(
      size.width * .68,
      size.height * .45,
      size.width * .25,
      size.height * .035,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(pad, const Radius.circular(5)),
      Paint()..color = const Color(0xFF688A91),
    );
    canvas.drawLine(
      Offset(pad.left + 8, pad.center.dy),
      Offset(pad.right - 8, pad.center.dy),
      Paint()
        ..color = const Color(0xFFECC27F)
        ..strokeWidth = 2,
    );
  }

  void _courier(
    Canvas canvas,
    Offset center,
    Size size,
    bool thrust,
    double vx,
    double vy,
  ) {
    final double scale = size.width * .115;
    final Paint shadow = Paint()..color = const Color(0x332F4D58);
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, scale * .42),
        width: scale * .65,
        height: scale * .16,
      ),
      shadow,
    );
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(vx * .26 - vy * .10);
    if (thrust) {
      final Path flame = Path()
        ..moveTo(-scale * .18, scale * .15)
        ..quadraticBezierTo(
          -scale * .28,
          scale * (.34 + .06 * math.sin(engine.elapsed * 22)),
          -scale * .10,
          scale * .49,
        )
        ..quadraticBezierTo(scale * .02, scale * .34, -scale * .02, scale * .14)
        ..close();
      canvas.drawPath(
        flame,
        Paint()
          ..shader =
              const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0xFFE8AD6E),
                  Color(0xFFF3D39D),
                  Colors.transparent,
                ],
              ).createShader(
                Rect.fromCenter(
                  center: Offset(-scale * .1, scale * .33),
                  width: scale * .35,
                  height: scale * .38,
                ),
              ),
      );
    }
    final RRect pack = RRect.fromRectAndRadius(
      Rect.fromLTWH(-scale * .39, -scale * .30, scale * .28, scale * .46),
      Radius.circular(scale * .08),
    );
    canvas.drawRRect(
      pack.shift(Offset(0, 2)),
      Paint()..color = const Color(0x33334852),
    );
    canvas.drawRRect(
      pack,
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[Color(0xFF657F88), Color(0xFF3F5B65)],
        ).createShader(pack.outerRect),
    );
    canvas.drawLine(
      Offset(-scale * .22, -scale * .27),
      Offset(-scale * .22, scale * .06),
      Paint()
        ..color = const Color(0xFFE1B77B)
        ..strokeWidth = 1.2,
    );
    final RRect parcel = RRect.fromRectAndRadius(
      Rect.fromLTWH(scale * .19, -scale * .15, scale * .28, scale * .27),
      Radius.circular(scale * .035),
    );
    canvas.drawRRect(
      parcel.shift(Offset(0, 2)),
      Paint()..color = const Color(0x33545A56),
    );
    canvas.drawRRect(
      parcel,
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[Color(0xFFE7BD83), Color(0xFFC38B5C)],
        ).createShader(parcel.outerRect),
    );
    canvas.drawLine(
      Offset(scale * .32, -scale * .15),
      Offset(scale * .32, scale * .12),
      Paint()
        ..color = const Color(0xFF8B634A)
        ..strokeWidth = 1,
    );
    final Paint suit = Paint()
      ..color = const Color(0xFFE7ECE7)
      ..strokeWidth = scale * .11
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(0, -scale * .16),
      Offset(scale * .04, scale * .22),
      suit,
    );
    canvas.drawCircle(
      Offset(scale * .04, -scale * .32),
      scale * .115,
      Paint()..color = const Color(0xFFDCA77B),
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(scale * .04, -scale * .34),
        width: scale * .24,
        height: scale * .2,
      ),
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = const Color(0xFF526A73)
        ..strokeWidth = scale * .065
        ..style = PaintingStyle.stroke,
    );
    canvas.drawLine(
      Offset(scale * .02, -scale * .08),
      Offset(-scale * .20, scale * .07),
      suit..strokeWidth = scale * .07,
    );
    canvas.drawLine(
      Offset(scale * .03, -scale * .08),
      Offset(scale * .23, scale * .02),
      Paint()
        ..color = const Color(0xFFE7ECE7)
        ..strokeWidth = scale * .07
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(scale * .02, scale * .19),
      Offset(-scale * .13, scale * .34),
      Paint()
        ..color = const Color(0xFF3D5861)
        ..strokeWidth = scale * .08
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(scale * .03, scale * .19),
      Offset(scale * .18, scale * .32),
      Paint()
        ..color = const Color(0xFF3D5861)
        ..strokeWidth = scale * .08
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
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
  bool shouldRepaint(_CourierScenePainter oldDelegate) =>
      oldDelegate.engine.elapsed != engine.elapsed ||
      oldDelegate.engine.x != engine.x ||
      oldDelegate.engine.altitude != engine.altitude ||
      oldDelegate.engine.nextCheckpoint != engine.nextCheckpoint ||
      oldDelegate.engine.thrustActive != engine.thrustActive ||
      oldDelegate.paused != paused;
}
