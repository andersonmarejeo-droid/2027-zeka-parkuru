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
import 'kite_runner_engine.dart';
import 'kite_runner_scenario.dart';

class KiteRunnerGamePage extends StatelessWidget {
  const KiteRunnerGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  static const int totalCases = KiteRunnerScenario.campaignLevels;
  static const int totalStars = totalCases * 3;

  static final List<ParkurLevelSpec> _levels = List<ParkurLevelSpec>.generate(
    totalCases,
    (int index) {
      final int level = index + 1;
      final String tr = switch (level) {
        <= 3 => 'Rüzgârı oku; ipi yumuşak tutup bayrak kapılarından geç.',
        <= 6 => 'Hat gerginliğini dengede tut, elektrik hattını önceden gör.',
        7 || 8 => 'İleri: ters esen rüzgâr ve dar kapı arasında ipi boşalt.',
        9 => 'Uzman: kısa çekiş darbeleriyle yatış ve yükü yönet.',
        _ => 'Usta finali: 12 kapı, güçlü gust ve tek hata hakkı.',
      };
      final String en = switch (level) {
        <= 3 => 'Read the wind, keep the line soft and pass the flag gates.',
        <= 6 => 'Balance line tension and spot power lines early.',
        7 || 8 => 'Advanced: ease the tether between headwind gates.',
        9 => 'Expert: trim bank and load with short, careful pulls.',
        _ => 'Master finale: 12 gates, strong gusts and one miss allowed.',
      };
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Rüzgâr Etabı ${level.toString().padLeft(2, '0')}',
        titleEn: 'Wind Leg ${level.toString().padLeft(2, '0')}',
        subtitleTr: tr,
        subtitleEn: en,
        difficulty: switch (level) {
          <= 3 => 'USTALAŞMA',
          <= 6 => 'DERİNLEŞME',
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
      gameId: 'kite_runner',
      progressPrefix: 'kite_runner',
      titleTr: 'Uçurtma Pilotu',
      titleEn: 'Kite Pilot',
      taglineTr: 'İpi ayarla • Rüzgârı oku • Hattı aş',
      taglineEn: 'Trim the line • Read the wind • Clear the wire',
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
          ) => KiteRunnerPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class KiteRunnerPlayPage extends StatefulWidget {
  const KiteRunnerPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<KiteRunnerPlayPage> createState() => _KiteRunnerPlayPageState();
}

class _KiteRunnerPlayPageState extends State<KiteRunnerPlayPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const Color _ink = Color(0xFF40586C);
  static const Color _teal = Color(0xFF4A9E9B);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.fun,
  );
  late final Ticker _ticker;
  late KiteRunnerScenario _scenario;
  late KiteRunnerEngine _engine;
  late StudioGameSession _session;
  Duration _lastTick = Duration.zero;
  bool _ready = false;
  bool _paused = false;
  bool _finished = false;
  bool _english = false;
  bool _warningPlayed = false;

  int get _stars {
    if (_engine.misses == 0 &&
        _engine.elapsed <= _scenario.goldTimeSeconds &&
        _engine.kite.lineTension < _scenario.snapThreshold * .8) {
      return 3;
    }
    if (_engine.misses <= 1 &&
        _engine.elapsed <= _scenario.goldTimeSeconds * 1.35) {
      return 2;
    }
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
    KiteRunnerScenario scenario = KiteRunnerScenario.forLevel(
      widget.level.number,
    );
    try {
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      final String visitKey = 'kite_runner_level_${widget.level.number}_visits';
      final int visits = await preferences.getInt(visitKey) ?? 0;
      if (visits > 0) {
        final int index =
            await preferences.getInt('kite_runner_practice_index') ?? 0;
        if (index < KiteRunnerScenario.practiceRoutes) {
          final int next = index + 1;
          await preferences.setInt('kite_runner_practice_index', next);
          scenario = KiteRunnerScenario.forPracticeRoute(next);
        }
      }
      await preferences.setInt(visitKey, visits + 1);
    } catch (_) {
      scenario = KiteRunnerScenario.forLevel(widget.level.number);
    }
    if (!mounted) return;
    _scenario = scenario;
    _startFlight();
    setState(() => _ready = true);
  }

  void _startFlight() {
    _ticker.stop();
    _engine = KiteRunnerEngine(scenario: _scenario);
    _paused = false;
    _finished = false;
    _warningPlayed = false;
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
      _engine.setControl(steer: 0, reel: 0);
      _session.pause();
      _ticker.stop();
    } else {
      _session.resume();
      _lastTick = Duration.zero;
      _ticker.start();
    }
    unawaited(_audio.play(GameSound.uiClick, gain: .24));
  }

  void _applyControl(Offset point, Size size) {
    if (!_ready || _paused || _finished) return;
    final double steer = ((point.dx / size.width) * 2 - 1)
        .clamp(-1, 1)
        .toDouble();
    final double reel = ((.5 - point.dy / size.height) * 2)
        .clamp(-1, 1)
        .toDouble();
    _engine.setControl(steer: steer, reel: reel);
    setState(() {});
  }

  void _releaseControl() {
    if (!_ready || _paused || _finished) return;
    _engine.setControl(steer: 0, reel: 0);
    setState(() {});
  }

  void _tick(Duration elapsed) {
    if (!_ready || _paused || _finished) return;
    final double raw = (elapsed - _lastTick).inMicroseconds / 1000000;
    _lastTick = elapsed;
    if (raw <= 0) return;
    final KiteStepResult result = _engine.step(raw.clamp(0, .02).toDouble());
    if (result.gatePassed) {
      _session.recordAccepted(points: 100);
      unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .25));
      _audio.hapticLight();
    }
    if (result.gateMissed || result.wireHit) {
      _session.recordMistake();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .2));
      _warningPlayed = false;
    }
    if (!_warningPlayed &&
        _engine.kite.lineTension > _scenario.snapThreshold * .88) {
      _warningPlayed = true;
      unawaited(
        _audioProfile.play(_audio, GameAudioEvent.timeWarning, gain: .17),
      );
    } else if (_engine.kite.lineTension < _scenario.snapThreshold * .7) {
      _warningPlayed = false;
    }
    if (result.finished) {
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
    if (!completed) {
      final bool retry =
          await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) => AlertDialog(
              title: Text(_english ? 'Kite run ended' : 'Uçurtma etabı bitti'),
              content: Text(
                _english
                    ? 'The line was overloaded, the kite lost lift or too many gates were missed. Ease the tether and retry?'
                    : 'İp fazla gerildi, uçurtma irtifayı kaybetti ya da kapılar kaçtı. İpi yumuşatıp tekrar deneyelim mi?',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(_english ? 'Course map' : 'Bölüm listesi'),
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

    _session.complete(
      stars: _stars,
      action: widget.level.number < KiteRunnerGamePage.totalCases
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
      accent: _teal,
      titleTr: 'RÜZGÂR ROTASI TAMAMLANDI',
      titleEn: 'WIND ROUTE COMPLETE',
      detailTr:
          '${_engine.nextGate}/${_scenario.gates.length} kapı · ${_engine.wiresAvoided} hat aşıldı · ip güvenli.',
      detailEn:
          '${_engine.nextGate}/${_scenario.gates.length} gates · ${_engine.wiresAvoided} wires cleared · line safe.',
      stars: _stars,
      score: _session.score + _engine.wiresAvoided * 45,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < KiteRunnerGamePage.totalCases,
    );
    if (!mounted) return;
    final StudioResultAction action = switch (result) {
      ParkurResultAction.replay => StudioResultAction.replay,
      ParkurResultAction.next => StudioResultAction.next,
      _ => StudioResultAction.map,
    };
    Navigator.of(context).pop(
      StudioGameResult.completed(
        score: _session.score + _engine.wiresAvoided * 45,
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
        appBar: AppBar(title: Text(_english ? 'KITE PILOT' : 'UÇURTMA PİLOTU')),
        body: const Center(child: CircularProgressIndicator(color: _teal)),
      );
    }
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: _ink,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _english ? 'KITE PILOT' : 'UÇURTMA PİLOTU',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('kite_runner_pause'),
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
              padding: const EdgeInsets.fromLTRB(12, 5, 12, 6),
              child: Column(
                children: <Widget>[
                  _KiteHud(
                    gate: _engine.nextGate,
                    total: _scenario.gates.length,
                    tension: _engine.kite.lineTension,
                    threshold: _scenario.snapThreshold,
                    altitude: _engine.kite.altitude,
                    misses: _engine.misses,
                    missLimit: _scenario.missLimit,
                    english: _english,
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints limits) {
                        final double width = math.min(limits.maxWidth, 560);
                        final double height = math.min(
                          limits.maxHeight,
                          width * 1.23,
                        );
                        final Size scene = Size(width, height);
                        return Center(
                          child: SizedBox(
                            key: const ValueKey<String>('kite_runner_scene'),
                            width: width,
                            height: height,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanStart: (DragStartDetails details) =>
                                  _applyControl(details.localPosition, scene),
                              onPanUpdate: (DragUpdateDetails details) =>
                                  _applyControl(details.localPosition, scene),
                              onPanEnd: (DragEndDetails details) =>
                                  _releaseControl(),
                              child: CustomPaint(
                                painter: _KiteRunnerPainter(
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
                  const SizedBox(height: 5),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          _english
                              ? 'Drag left/right to steer; up reels in, down eases the tether. Avoid the live wire.'
                              : 'Sağ-sol uçurtmayı yönlendirir; yukarı ipi sarar, aşağı gevşetir. Elektrik hattına değme.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: StudioVisuals.muted,
                            fontSize: 9,
                            height: 1.16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _KiteStick(
                        key: const ValueKey<String>('kite_runner_controls'),
                        steer: _engine.steer,
                        reel: _engine.reel,
                        enabled: !_paused && !_finished,
                        english: _english,
                        onControl: (double steer, double reel) {
                          _engine.setControl(steer: steer, reel: reel);
                          setState(() {});
                        },
                        onRelease: _releaseControl,
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

class _KiteHud extends StatelessWidget {
  const _KiteHud({
    required this.gate,
    required this.total,
    required this.tension,
    required this.threshold,
    required this.altitude,
    required this.misses,
    required this.missLimit,
    required this.english,
  });

  final int gate;
  final int total;
  final double tension;
  final double threshold;
  final double altitude;
  final int misses;
  final int missLimit;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey<String>('kite_runner_hud'),
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
          child: _KiteMetric(
            label: english ? 'FLAGS' : 'BAYRAKLAR',
            value: '$gate / $total',
            icon: Icons.flag_rounded,
            color: const Color(0xFF5D91A4),
          ),
        ),
        Container(width: 1, height: 28, color: StudioVisuals.line),
        Expanded(
          child: _KiteMetric(
            label: english ? 'LINE LOAD' : 'İP YÜKÜ',
            value: '${(tension * 100).round()}%',
            icon: Icons.linear_scale_rounded,
            color: tension > threshold * .8
                ? const Color(0xFFD46E5D)
                : _KiteRunnerPlayPageState._teal,
          ),
        ),
        Container(width: 1, height: 28, color: StudioVisuals.line),
        Expanded(
          child: _KiteMetric(
            label: misses == 0
                ? (english ? 'HEIGHT' : 'İRTİFA')
                : (english ? 'MISSES' : 'HATA'),
            value: misses == 0
                ? '${(altitude * 100).round()}%'
                : '$misses / $missLimit',
            icon: misses == 0
                ? Icons.height_rounded
                : Icons.warning_amber_rounded,
            color: misses == 0
                ? const Color(0xFF819BA6)
                : const Color(0xFFD46E5D),
          ),
        ),
      ],
    ),
  );
}

class _KiteMetric extends StatelessWidget {
  const _KiteMetric({
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
                color: _KiteRunnerPlayPageState._ink,
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

class _KiteStick extends StatelessWidget {
  const _KiteStick({
    super.key,
    required this.steer,
    required this.reel,
    required this.enabled,
    required this.english,
    required this.onControl,
    required this.onRelease,
  });

  final double steer;
  final double reel;
  final bool enabled;
  final bool english;
  final void Function(double steer, double reel) onControl;
  final VoidCallback onRelease;

  @override
  Widget build(BuildContext context) {
    const Size size = Size(104, 72);
    return Semantics(
      label: english
          ? 'Steering and tether trim control'
          : 'Yön ve ip gerginliği kontrolü',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: enabled
            ? (DragStartDetails details) => _move(details.localPosition)
            : null,
        onPanUpdate: enabled
            ? (DragUpdateDetails details) => _move(details.localPosition)
            : null,
        onPanEnd: enabled ? (_) => onRelease() : null,
        child: CustomPaint(
          key: const ValueKey<String>('kite_runner_control_pad'),
          size: size,
          painter: _KiteStickPainter(steer: steer, reel: reel),
        ),
      ),
    );
  }

  void _move(Offset point) => onControl(
    ((point.dx / 104) * 2 - 1).clamp(-1, 1).toDouble(),
    ((.5 - point.dy / 72) * 2).clamp(-1, 1).toDouble(),
  );
}

class _KiteStickPainter extends CustomPainter {
  const _KiteStickPainter({required this.steer, required this.reel});

  final double steer;
  final double reel;

  @override
  void paint(Canvas canvas, Size size) {
    final RRect plate = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(18),
    );
    canvas.drawRRect(plate, Paint()..color = const Color(0xFFEAF1F2));
    canvas.drawRRect(
      plate,
      Paint()
        ..color = const Color(0xFFD2E1E5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final Paint guide = Paint()
      ..color = const Color(0xFFCAD9DE)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(size.width * .5, 9),
      Offset(size.width * .5, size.height - 9),
      guide,
    );
    canvas.drawLine(
      Offset(10, size.height * .5),
      Offset(size.width - 10, size.height * .5),
      guide,
    );
    final Offset center = Offset(
      size.width * (.5 + steer * .37),
      size.height * (.5 - reel * .34),
    );
    canvas.drawCircle(
      center.translate(0, 2),
      13,
      Paint()..color = const Color(0x33536F7A),
    );
    canvas.drawCircle(
      center,
      13,
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[Color(0xFFA6D5D1), Color(0xFF4A9E9B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromCircle(center: center, radius: 13)),
    );
    canvas.drawCircle(
      center.translate(-3, -4),
      3.2,
      Paint()..color = Colors.white.withValues(alpha: .8),
    );
  }

  @override
  bool shouldRepaint(_KiteStickPainter oldDelegate) =>
      oldDelegate.steer != steer || oldDelegate.reel != reel;
}

class _KiteRunnerPainter extends CustomPainter {
  const _KiteRunnerPainter({
    required this.scenario,
    required this.engine,
    required this.paused,
    required this.english,
  });

  final KiteRunnerScenario scenario;
  final KiteRunnerEngine engine;
  final bool paused;
  final bool english;

  static const Color _teal = Color(0xFF4A9E9B);
  static const Color _coral = Color(0xFFE18A70);

  Offset _point(Size size, double x, double y) =>
      Offset(size.width * x, size.height * y);

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    final RRect frame = RRect.fromRectAndRadius(
      bounds,
      const Radius.circular(24),
    );
    canvas.drawRRect(
      frame,
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[
            Color(0xFFAED0D2),
            Color(0xFFDAE5D9),
            Color(0xFFF3EAD6),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(bounds),
    );
    canvas.save();
    canvas.clipRRect(frame);
    _paintSun(canvas, size);
    _paintClouds(canvas, size);
    _paintWind(canvas, size);
    _paintHills(canvas, size);
    _paintWires(canvas, size);
    _paintGates(canvas, size);
    _paintTether(canvas, size);
    _paintKite(canvas, size);
    _paintReel(canvas, size);
    canvas.restore();
    if (paused) {
      canvas.drawRRect(frame, Paint()..color = const Color(0xAA526F7A));
      _label(
        canvas,
        english ? 'PAUSED' : 'DURAKLATILDI',
        _point(size, .5, .49),
        size.width * .05,
        Colors.white,
      );
    }
  }

  void _paintSun(Canvas canvas, Size size) {
    final Offset center = _point(size, .82, .16);
    final double radius = size.width * .07;
    canvas.drawCircle(
      center,
      radius * 2.5,
      Paint()..color = const Color(0x44FFF0C9),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          colors: <Color>[Color(0xFFFFF8DB), Color(0xFFEBCF99)],
          center: Alignment(-.3, -.4),
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  void _paintClouds(Canvas canvas, Size size) {
    final List<(double, double, double)> clouds = <(double, double, double)>[
      (.19, .21, .15),
      (.62, .29, .19),
      (.34, .41, .12),
    ];
    for (int index = 0; index < clouds.length; index++) {
      final (double, double, double) cloud = clouds[index];
      final double drift =
          math.sin(engine.elapsed * .14 + index * 2) * size.width * .012;
      final Offset center = _point(
        size,
        cloud.$1,
        cloud.$2,
      ).translate(drift, 0);
      final double radius = size.width * cloud.$3 * .22;
      for (int bump = 0; bump < 4; bump++) {
        canvas.drawCircle(
          center.translate(
            (bump - 1.5) * radius * 1.05,
            (bump.isEven ? 0 : -radius * .22),
          ),
          radius * (bump == 1 ? 1.1 : .86),
          Paint()..color = Colors.white.withValues(alpha: .55),
        );
      }
    }
  }

  void _paintWind(Canvas canvas, Size size) {
    final KiteWind wind = scenario.windAt(engine.kite.distance, engine.elapsed);
    final Paint stroke = Paint()
      ..color = const Color(0x5595B9B7)
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    for (int index = 0; index < 7; index++) {
      final double y =
          .19 + index * .066 + math.sin(engine.elapsed * .23 + index) * .008;
      final double x = .10 + (index % 3) * .25 + wind.phase * .013;
      final double direction = wind.cross >= 0 ? 1 : -1;
      canvas.drawLine(
        _point(size, x, y),
        _point(size, x + direction * (.045 + wind.gust.abs() * .04), y),
        stroke,
      );
      canvas.drawLine(
        _point(size, x + direction * (.045 + wind.gust.abs() * .04), y),
        _point(size, x + direction * .035, y - .008),
        stroke,
      );
    }
  }

  void _paintHills(Canvas canvas, Size size) {
    final double horizon = size.height * .72;
    final Path far = Path()..moveTo(0, horizon);
    final List<double> peaks = <double>[
      .02,
      .13,
      .18,
      .30,
      .25,
      .39,
      .44,
      .55,
      .51,
      .67,
      .73,
      .84,
      .80,
      1,
    ];
    for (int index = 0; index < peaks.length; index++) {
      final double y = horizon - size.height * (.035 + (index % 4) * .018);
      far.lineTo(size.width * peaks[index], y);
    }
    far
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(far, Paint()..color = const Color(0xFFB6CBB7));
    final Path near = Path()
      ..moveTo(0, size.height * .79)
      ..quadraticBezierTo(
        size.width * .4,
        size.height * .71,
        size.width,
        size.height * .81,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      near,
      Paint()
        ..shader =
            const LinearGradient(
              colors: <Color>[Color(0xFFD3D5BD), Color(0xFFE7D7B7)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(
              Offset(0, size.height * .72) &
                  Size(size.width, size.height * .28),
            ),
    );
    final Paint sea = Paint()..color = const Color(0x226A9DA6);
    for (int index = 0; index < 5; index++) {
      final double y = size.height * (.84 + index * .025);
      canvas.drawLine(
        _point(size, .08, y),
        _point(size, .92, y),
        sea..strokeWidth = .7 + index * .12,
      );
    }
  }

  void _paintWires(Canvas canvas, Size size) {
    for (int index = 0; index < scenario.wires.length; index++) {
      final KiteWire wire = scenario.wires[index];
      final double ahead = wire.distance - engine.kite.distance;
      if (ahead < -.025 || ahead > .52) continue;
      final double y = .75 - ahead * .60;
      final double center = wire.centerX;
      final Paint cable = Paint()
        ..color = const Color(0xFF53636B)
        ..strokeWidth = size.width * .003
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(_point(size, .03, y), _point(size, .97, y + .016), cable);
      for (int post = 0; post < 4; post++) {
        final double x = .12 + post * .25;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: _point(size, x, y + .004),
              width: size.width * .018,
              height: size.width * .015,
            ),
            const Radius.circular(3),
          ),
          Paint()..color = const Color(0xFF7A8C91),
        );
      }
      canvas.drawCircle(
        _point(size, center, y + .008),
        size.width * wire.width * .43,
        Paint()..color = const Color(0x33D67758),
      );
      _label(
        canvas,
        english ? 'LIVE' : 'HAT',
        _point(size, center, y - .018),
        size.width * .018,
        const Color(0xFFB45D4E),
      );
    }
  }

  void _paintGates(Canvas canvas, Size size) {
    for (int index = engine.nextGate; index < scenario.gates.length; index++) {
      final KiteGate gate = scenario.gates[index];
      final double ahead = gate.distance - engine.kite.distance;
      if (ahead < -.02 || ahead > .48) continue;
      final double perspective = (1 - ahead * .42).clamp(.69, 1).toDouble();
      final double x = gate.centerAt(engine.elapsed);
      final double y = .73 - ahead * .83 - (gate.altitude - .5) * .18;
      final double width = size.width * gate.width * perspective;
      final double height = size.height * gate.height * perspective * .44;
      final Rect opening = Rect.fromCenter(
        center: _point(size, x, y),
        width: width,
        height: height,
      );
      final Color color = index == engine.nextGate ? _coral : _teal;
      final Paint pole = Paint()
        ..color = color
        ..strokeWidth = size.width * .012
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(opening.left, opening.top - height * .35),
        Offset(opening.left, opening.bottom + height * .35),
        pole,
      );
      canvas.drawLine(
        Offset(opening.right, opening.top - height * .35),
        Offset(opening.right, opening.bottom + height * .35),
        pole,
      );
      canvas.drawLine(
        Offset(opening.left, opening.top),
        Offset(opening.right, opening.top),
        pole,
      );
      for (int flag = 0; flag < 5; flag++) {
        final double fx = opening.left + width * (flag + .5) / 5;
        final Path pennant = Path()
          ..moveTo(fx, opening.top + size.width * .004)
          ..lineTo(fx + width * .075, opening.top + size.width * .006)
          ..lineTo(fx + width * .022, opening.top + size.width * .032)
          ..close();
        canvas.drawPath(pennant, Paint()..color = color.withValues(alpha: .8));
      }
      _label(
        canvas,
        '${index + 1}',
        _point(size, x, y),
        size.width * .026 * perspective,
        const Color(0xFF425C68),
      );
    }
  }

  void _paintTether(Canvas canvas, Size size) {
    final Offset kite = _point(
      size,
      engine.kite.x,
      .76 - engine.kite.altitude * .63,
    );
    final Offset spool = _point(size, .5, .91);
    final double stress = (engine.kite.lineTension / scenario.snapThreshold)
        .clamp(0, 1)
        .toDouble();
    final Color color = stress > .78
        ? const Color(0xFFD9755D)
        : const Color(0xFFF6F1DD);
    final Path line = Path()
      ..moveTo(spool.dx, spool.dy)
      ..cubicTo(
        size.width * .42,
        size.height * .79,
        kite.dx + size.width * .06,
        kite.dy + size.height * .11,
        kite.dx,
        kite.dy + size.width * .052,
      );
    canvas.drawPath(
      line,
      Paint()
        ..color = const Color(0x3350616C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * .012,
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * .003,
    );
  }

  void _paintKite(Canvas canvas, Size size) {
    final Offset center = _point(
      size,
      engine.kite.x,
      .76 - engine.kite.altitude * .63,
    );
    final double halfWidth = size.width * .083;
    final double halfHeight = size.height * .10;
    final Offset top = center.translate(0, -halfHeight);
    final Offset right = center.translate(halfWidth, 0);
    final Offset bottom = center.translate(0, halfHeight);
    final Offset left = center.translate(-halfWidth, 0);
    final Path shape = Path()
      ..moveTo(top.dx, top.dy)
      ..quadraticBezierTo(
        center.dx + halfWidth * .08,
        center.dy - halfHeight * .12,
        right.dx,
        right.dy,
      )
      ..quadraticBezierTo(
        center.dx + halfWidth * .15,
        center.dy + halfHeight * .3,
        bottom.dx,
        bottom.dy,
      )
      ..quadraticBezierTo(
        center.dx - halfWidth * .15,
        center.dy + halfHeight * .3,
        left.dx,
        left.dy,
      )
      ..quadraticBezierTo(
        center.dx - halfWidth * .08,
        center.dy - halfHeight * .12,
        top.dx,
        top.dy,
      )
      ..close();
    canvas.drawPath(
      shape.shift(const Offset(0, 3)),
      Paint()..color = const Color(0x4452636B),
    );
    final Path leftPanel = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(center.dx, center.dy)
      ..lineTo(left.dx, left.dy)
      ..close();
    final Path rightPanel = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(right.dx, right.dy)
      ..lineTo(center.dx, center.dy)
      ..close();
    final Path lowerLeft = Path()
      ..moveTo(left.dx, left.dy)
      ..lineTo(center.dx, center.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..close();
    final Path lowerRight = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(right.dx, right.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..close();
    canvas.drawPath(shape, Paint()..color = const Color(0xFFFCFAF0));
    canvas.drawPath(leftPanel, Paint()..color = const Color(0xFF5BAAA3));
    canvas.drawPath(rightPanel, Paint()..color = const Color(0xFFE99978));
    canvas.drawPath(lowerLeft, Paint()..color = const Color(0xFF8EBBC2));
    canvas.drawPath(lowerRight, Paint()..color = const Color(0xFFEBCB8E));
    canvas.drawPath(
      shape,
      Paint()
        ..color = const Color(0xFF66828B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * .004,
    );
    final Paint spar = Paint()
      ..color = const Color(0xFF536F7D)
      ..strokeWidth = size.width * .002;
    canvas.drawLine(top, bottom, spar);
    canvas.drawLine(left, right, spar);
    canvas.drawCircle(
      center,
      size.width * .009,
      Paint()..color = const Color(0xFFFFF8E6),
    );
    _paintTail(canvas, size, bottom);
  }

  void _paintTail(Canvas canvas, Size size, Offset start) {
    final Path tail = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        start.dx + size.width * .04,
        start.dy + size.height * .07,
        start.dx - size.width * .02,
        start.dy + size.height * .11,
        start.dx + size.width * .02,
        start.dy + size.height * .18,
      );
    canvas.drawPath(
      tail,
      Paint()
        ..color = const Color(0xFF8C8371)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * .003,
    );
    for (int index = 1; index <= 3; index++) {
      final double t = index / 4;
      final Offset bow = start.translate(
        size.width * (.018 * math.sin(t * math.pi)),
        size.height * t * .18,
      );
      canvas.drawCircle(
        bow,
        size.width * .014,
        Paint()
          ..color = index.isEven
              ? const Color(0xFFE89A78)
              : const Color(0xFF78B5AC),
      );
    }
  }

  void _paintReel(Canvas canvas, Size size) {
    final Offset center = _point(size, .5, .91);
    final double radius = size.width * .047;
    canvas.drawCircle(
      center.translate(0, radius * .15),
      radius * 1.12,
      Paint()..color = const Color(0x22425056),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          colors: <Color>[
            Color(0xFFF3F0E6),
            Color(0xFFA9A596),
            Color(0xFF596B70),
          ],
          center: Alignment(-.3, -.4),
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center,
      radius * .36,
      Paint()..color = const Color(0xFF607981),
    );
    canvas.drawLine(
      center.translate(-radius * .65, 0),
      center.translate(radius * .65, 0),
      Paint()
        ..color = const Color(0xFF576A70)
        ..strokeWidth = 2,
    );
  }

  void _label(
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
      maxLines: 1,
    )..layout(maxWidth: 160);
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_KiteRunnerPainter oldDelegate) =>
      oldDelegate.engine.elapsed != engine.elapsed ||
      oldDelegate.engine.nextGate != engine.nextGate ||
      oldDelegate.engine.kite.x != engine.kite.x ||
      oldDelegate.engine.kite.altitude != engine.kite.altitude ||
      oldDelegate.engine.kite.lineTension != engine.kite.lineTension ||
      oldDelegate.paused != paused;
}
