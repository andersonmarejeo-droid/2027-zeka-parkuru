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
import 'paper_flight_engine.dart';
import 'paper_flight_scenario.dart';

class PaperFlightGamePage extends StatelessWidget {
  const PaperFlightGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  static const int totalCases = PaperFlightScenario.maximumLevels;
  static const int totalStars = totalCases * 3;

  static final List<ParkurLevelSpec> _levels = List<ParkurLevelSpec>.generate(
    totalCases,
    (int index) {
      final int level = index + 1;
      final String tr = switch (level) {
        <= 3 => 'Kanat yatışını öğren; geniş halkalardan süzülerek geç.',
        <= 6 => 'Termik sütununu bul, irtifayı koru ve rüzgârı dengele.',
        7 ||
        8 => 'İleri: karşı rüzgârda dar kapı zinciri ve yükseklik bütçesi.',
        9 => 'Uzman: küçük halkalar, kesen rüzgâr ve hassas flare.',
        _ => 'Usta finali: 12 kapı, dar irtifa aralığı ve nokta inişi.',
      };
      final String en = switch (level) {
        <= 3 => 'Learn the bank and glide through wide, forgiving hoops.',
        <= 6 => 'Find thermals, preserve altitude and balance the wind.',
        7 || 8 => 'Advanced: narrow gate chains through a headwind.',
        9 => 'Expert: small hoops, crosswind and a precise landing flare.',
        _ => 'Master finale: 12 hoops, tight altitude and a pinpoint landing.',
      };
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Süzülüş Rotası ${level.toString().padLeft(2, '0')}',
        titleEn: 'Glide Route ${level.toString().padLeft(2, '0')}',
        subtitleTr: tr,
        subtitleEn: en,
        difficulty: switch (level) {
          <= 3 => 'USTALAŞMA',
          <= 6 => 'DERİNLEŞME',
          7 || 8 => 'İLERİ',
          9 => 'UZMAN',
          _ => 'USTA',
        },
        icon: Icons.airplanemode_active_rounded,
      );
    },
    growable: false,
  );

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.fun);
    return ParkurLevelHub(
      gameId: 'paper_flight',
      progressPrefix: 'paper_flight',
      titleTr: 'Kâğıt Uçak Şampiyonası',
      titleEn: 'Paper Flight',
      taglineTr: 'Yatış ver • Termiğe gir • Yumuşak in',
      taglineEn: 'Bank • Catch a thermal • Flare smoothly',
      accent: skin.accent,
      icon: Icons.airplanemode_active_rounded,
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
          ) => PaperFlightPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class PaperFlightPlayPage extends StatefulWidget {
  const PaperFlightPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<PaperFlightPlayPage> createState() => _PaperFlightPlayPageState();
}

class _PaperFlightPlayPageState extends State<PaperFlightPlayPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const Color _ink = Color(0xFF405E70);
  static const Color _accent = Color(0xFF5E91A4);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.fun,
  );
  late final Ticker _ticker;
  late PaperFlightScenario _scenario;
  late PaperFlightEngine _engine;
  late StudioGameSession _session;
  Duration _lastTick = Duration.zero;
  double _elapsed = 0;
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
    PaperFlightScenario scenario = PaperFlightScenario.forLevel(
      widget.level.number,
    );
    try {
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      final String visitKey =
          'paper_flight_level_${widget.level.number}_visits';
      final int visits = await preferences.getInt(visitKey) ?? 0;
      if (visits > 0) {
        final int index =
            await preferences.getInt('paper_flight_practice_index') ?? 0;
        if (index < PaperFlightScenario.maximumPracticeRounds) {
          final int next = index + 1;
          await preferences.setInt('paper_flight_practice_index', next);
          scenario = PaperFlightScenario.forPracticeRound(next);
        }
      }
      await preferences.setInt(visitKey, visits + 1);
    } catch (_) {
      scenario = PaperFlightScenario.forLevel(widget.level.number);
    }
    if (!mounted) return;
    _scenario = scenario;
    _startFlight();
    setState(() => _ready = true);
  }

  void _startFlight() {
    _ticker.stop();
    _engine = PaperFlightEngine(scenario: _scenario);
    _elapsed = 0;
    _score = 0;
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
      _engine.setControl(bank: 0, pitch: 0);
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
    final double bank = ((point.dx / size.width) * 2 - 1)
        .clamp(-1, 1)
        .toDouble();
    final double pitch = ((.5 - point.dy / size.height) * 2)
        .clamp(-1, 1)
        .toDouble();
    _engine.setControl(bank: bank, pitch: pitch);
    setState(() {});
  }

  void _releaseControl() {
    if (!_ready || _paused || _finished) return;
    _engine.setControl(bank: 0, pitch: 0);
    setState(() {});
  }

  void _tick(Duration elapsed) {
    if (!_ready || _paused || _finished) return;
    final double raw = (elapsed - _lastTick).inMicroseconds / 1000000;
    _lastTick = elapsed;
    if (raw <= 0) return;
    final double delta = raw.clamp(0, .024).toDouble();
    _elapsed += delta;
    final FlightStepResult result = _engine.step(delta);
    if (result.gatePassed) {
      _score += 90;
      _session.recordAccepted(points: 90);
      unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .28));
      _audio.hapticLight();
    }
    if (result.gateMissed || result.approachMissed) {
      _session.recordMistake();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .22));
    }
    if (result.enteredThermal) {
      _score += 35;
      _session.recordAccepted(points: 35);
      unawaited(
        _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .17),
      );
    }
    if (result.landed) {
      final int timeBonus = math.max(
        0,
        ((_scenario.goldTimeSeconds - _elapsed) * 4).round(),
      );
      _score += 400 + timeBonus + _engine.thermalsUsed * 35;
      _session.recordAccepted(points: 400 + timeBonus);
      unawaited(_finish(completed: true));
    } else if (result.crashed || _engine.misses > _scenario.missLimit) {
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
              title: Text(_english ? 'Glide interrupted' : 'Süzülüş kesildi'),
              content: Text(
                _english
                    ? 'The plane lost too much altitude or missed too many gates. Regain lift and line up the runway, then retry?'
                    : 'Uçak fazla irtifa kaybetti ya da çok sayıda kapıyı kaçırdı. Termiğe girip pisti hizalayarak tekrar deneyelim mi?',
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
        Navigator.of(context)
            .pop(StudioGameResult.failed(score: _score).toParkurResult());
      }
      return;
    }

    _session.complete(
      stars: _stars,
      action: widget.level.number < PaperFlightGamePage.totalCases
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
      titleTr: 'SÜZÜLÜŞ TAMAMLANDI',
      titleEn: 'GLIDE COMPLETE',
      detailTr:
          '${_engine.nextGate}/${_scenario.gates.length} kapı · ${_engine.thermalsUsed} termik · ${_engine.misses} hata · yumuşak iniş.',
      detailEn:
          '${_engine.nextGate}/${_scenario.gates.length} gates · ${_engine.thermalsUsed} thermals · ${_engine.misses} misses · soft landing.',
      stars: _stars,
      score: _score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < PaperFlightGamePage.totalCases,
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
        appBar: AppBar(title: Text(_english ? 'PAPER FLIGHT' : 'KÂĞIT UÇAK')),
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
          _english ? 'PAPER FLIGHT' : 'KÂĞIT UÇAK',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('paper_flight_pause'),
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
                  _FlightHud(
                    gate: _engine.nextGate,
                    total: _scenario.gates.length,
                    altitude: _engine.plane.altitude,
                    wind: _engine.windStrength,
                    misses: _engine.misses,
                    missLimit: _scenario.missLimit,
                    english: _english,
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints limits) {
                        final double width = math.min(limits.maxWidth, 570);
                        final double height = math.min(
                          limits.maxHeight,
                          width * .96,
                        );
                        final Size sceneSize = Size(width, height);
                        return Center(
                          child: SizedBox(
                            key: const ValueKey<String>('paper_flight_scene'),
                            width: width,
                            height: height,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanStart: (DragStartDetails details) =>
                                  _applyControl(
                                    details.localPosition,
                                    sceneSize,
                                  ),
                              onPanUpdate: (DragUpdateDetails details) =>
                                  _applyControl(
                                    details.localPosition,
                                    sceneSize,
                                  ),
                              onPanEnd: (DragEndDetails details) =>
                                  _releaseControl(),
                              child: CustomPaint(
                                painter: _PaperFlightPainter(
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
                              ? 'Drag the sky or the pad: left/right banks, up/down changes pitch. Ease both controls for the landing flare.'
                              : 'Gökyüzünü ya da kontrol pad’ini sürükle: sağ-sol yatış, yukarı-aşağı burun açısı. İnişte kontrolleri yumuşat.',
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
                      const SizedBox(width: 9),
                      _FlightStick(
                        key: const ValueKey<String>('paper_flight_controls'),
                        bank: _engine.plane.bank,
                        pitch: _engine.plane.pitch,
                        enabled: !_paused && !_finished,
                        english: _english,
                        onControl: (double bank, double pitch) {
                          _engine.setControl(bank: bank, pitch: pitch);
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

class _FlightHud extends StatelessWidget {
  const _FlightHud({
    required this.gate,
    required this.total,
    required this.altitude,
    required this.wind,
    required this.misses,
    required this.missLimit,
    required this.english,
  });

  final int gate;
  final int total;
  final double altitude;
  final double wind;
  final int misses;
  final int missLimit;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey<String>('paper_flight_hud'),
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
          child: _FlightMetric(
            label: english ? 'GATES' : 'KAPILAR',
            value: '$gate / $total',
            icon: Icons.radio_button_checked_rounded,
            color: _PaperFlightPlayPageState._accent,
          ),
        ),
        Container(width: 1, height: 27, color: StudioVisuals.line),
        Expanded(
          child: _FlightMetric(
            label: english ? 'ALTITUDE' : 'İRTİFA',
            value: '${(altitude * 100).round()}%',
            icon: Icons.height_rounded,
            color: const Color(0xFF7699AE),
          ),
        ),
        Container(width: 1, height: 27, color: StudioVisuals.line),
        Expanded(
          child: _FlightMetric(
            label: misses == 0
                ? (english ? 'CROSSWIND' : 'YAN RÜZGÂR')
                : (english ? 'MISSES' : 'HATA'),
            value: misses == 0
                ? '${(wind * 100).round()}%'
                : '$misses / $missLimit',
            icon: misses == 0 ? Icons.air_rounded : Icons.warning_amber_rounded,
            color: misses == 0
                ? const Color(0xFF7793A1)
                : const Color(0xFFC57561),
          ),
        ),
      ],
    ),
  );
}

class _FlightMetric extends StatelessWidget {
  const _FlightMetric({
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
                color: _PaperFlightPlayPageState._ink,
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

class _FlightStick extends StatelessWidget {
  const _FlightStick({
    super.key,
    required this.bank,
    required this.pitch,
    required this.enabled,
    required this.english,
    required this.onControl,
    required this.onRelease,
  });

  final double bank;
  final double pitch;
  final bool enabled;
  final bool english;
  final void Function(double bank, double pitch) onControl;
  final VoidCallback onRelease;

  @override
  Widget build(BuildContext context) {
    const Size size = Size(104, 72);
    return Semantics(
      label: english
          ? 'Bank and pitch control'
          : 'Yatış ve burun açısı kontrolü',
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
          size: size,
          painter: _FlightStickPainter(bank: bank, pitch: pitch),
        ),
      ),
    );
  }

  void _move(Offset point) {
    final double nextBank = ((point.dx / 104) * 2 - 1).clamp(-1, 1).toDouble();
    final double nextPitch = ((.5 - point.dy / 72) * 2).clamp(-1, 1).toDouble();
    onControl(nextBank, nextPitch);
  }
}

class _FlightStickPainter extends CustomPainter {
  const _FlightStickPainter({required this.bank, required this.pitch});

  final double bank;
  final double pitch;

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
      size.width * (.5 + bank * .37),
      size.height * (.5 - pitch * .34),
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
          colors: <Color>[Color(0xFF9AC2D0), Color(0xFF5D91A3)],
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
  bool shouldRepaint(_FlightStickPainter oldDelegate) =>
      oldDelegate.bank != bank || oldDelegate.pitch != pitch;
}

class _PaperFlightPainter extends CustomPainter {
  const _PaperFlightPainter({
    required this.scenario,
    required this.engine,
    required this.paused,
    required this.english,
  });

  final PaperFlightScenario scenario;
  final PaperFlightEngine engine;
  final bool paused;
  final bool english;

  static const Color _skyTop = Color(0xFFB8D9E3);
  static const Color _skyMid = Color(0xFFE9F2EE);
  static const Color _ink = Color(0xFF477287);

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[_skyTop, _skyMid, Color(0xFFFAF5E9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(bounds),
    );
    _paintSun(canvas, size);
    _paintClouds(canvas, size);
    _paintDistantRidges(canvas, size);
    _paintThermals(canvas, size);
    _paintGates(canvas, size);
    _paintLanding(canvas, size);
    _paintWind(canvas, size);
    _paintGlider(canvas, size);
    _paintAltimeter(canvas, size);
    if (paused) {
      canvas.drawRect(bounds, Paint()..color = const Color(0x77617E8A));
      _label(
        canvas,
        'PAUSED',
        Offset(size.width * .5, size.height * .49),
        18,
        Colors.white,
      );
    }
  }

  void _paintSun(Canvas canvas, Size size) {
    final Offset center = Offset(size.width * .82, size.height * .16);
    final double radius = size.width * .09;
    canvas.drawCircle(
      center,
      radius * 2.5,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            const Color(0xFFF4DCA7).withValues(alpha: .36),
            const Color(0xFFF4DCA7).withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 2.5)),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          colors: <Color>[Color(0xFFFFF6D9), Color(0xFFE6C78F)],
          center: Alignment(-.3, -.4),
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  void _paintClouds(Canvas canvas, Size size) {
    final List<(double, double, double, double)> clouds =
        <(double, double, double, double)>[
          (.13, .18, .22, .055),
          (.62, .31, .25, .05),
          (.26, .45, .19, .045),
          (.85, .56, .21, .045),
          (.48, .12, .16, .035),
        ];
    for (int index = 0; index < clouds.length; index++) {
      final (double, double, double, double) cloud = clouds[index];
      final double drift =
          math.sin(engine.elapsedSeconds * (.11 + index * .013) + index) *
          size.width *
          .012;
      final Rect rect = Rect.fromCenter(
        center: Offset(size.width * cloud.$1 + drift, size.height * cloud.$2),
        width: size.width * cloud.$3,
        height: size.height * cloud.$4,
      );
      _cloud(canvas, rect, size.width, const Color(0xCCFFFFFF));
    }
  }

  void _cloud(Canvas canvas, Rect rect, double scale, Color color) {
    final Paint shade = Paint()..color = const Color(0x1A587887);
    final Paint fill = Paint()
      ..shader = LinearGradient(
        colors: <Color>[
          Colors.white.withValues(alpha: .92),
          color.withValues(alpha: .56),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);
    final double r = rect.height * .36;
    for (int i = 0; i < 5; i++) {
      final double x = rect.left + rect.width * (.10 + i * .19);
      final double bump =
          r *
          (i == 2
              ? 1.42
              : i.isOdd
              ? .88
              : 1.1);
      canvas.drawCircle(Offset(x, rect.center.dy + r * .34), bump, shade);
      canvas.drawCircle(Offset(x, rect.center.dy), bump, fill);
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          rect.left + rect.width * .08,
          rect.center.dy,
          rect.width * .84,
          rect.height * .34,
        ),
        Radius.circular(scale * .02),
      ),
      fill,
    );
  }

  void _paintDistantRidges(Canvas canvas, Size size) {
    final double horizon = size.height * .67;
    final Path back = Path()..moveTo(0, horizon);
    final List<double> peaks = <double>[
      .08,
      .26,
      .19,
      .42,
      .31,
      .56,
      .43,
      .72,
      .54,
      .89,
      .68,
      1,
    ];
    for (int i = 0; i < peaks.length; i++) {
      back.lineTo(
        size.width * peaks[i],
        horizon - size.height * (.035 + (i % 3) * .027),
      );
    }
    back
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      back,
      Paint()
        ..shader =
            const LinearGradient(
              colors: <Color>[Color(0xFFC9D5C9), Color(0xFFA6BDB2)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(
              Rect.fromLTWH(
                0,
                horizon - 40,
                size.width,
                size.height - horizon + 40,
              ),
            ),
    );
    final Path front = Path()
      ..moveTo(0, horizon + size.height * .075)
      ..cubicTo(
        size.width * .23,
        horizon,
        size.width * .32,
        horizon + size.height * .11,
        size.width * .54,
        horizon + size.height * .07,
      )
      ..cubicTo(
        size.width * .73,
        horizon + size.height * .025,
        size.width * .82,
        horizon + size.height * .13,
        size.width,
        horizon + size.height * .09,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      front,
      Paint()
        ..shader =
            const LinearGradient(
              colors: <Color>[Color(0xFF9CB7AC), Color(0xFF6F9A94)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(
              Rect.fromLTWH(0, horizon, size.width, size.height - horizon),
            ),
    );
  }

  void _paintThermals(Canvas canvas, Size size) {
    for (final FlightThermal thermal in scenario.thermals) {
      final double ahead = thermal.distance - engine.plane.distance;
      if (ahead < -.06 || ahead > .46) continue;
      final double depth = (1 - ahead / .5).clamp(.1, 1).toDouble();
      final double x = size.width * thermal.centerX;
      final double y = size.height * (.62 - ahead * .7);
      final double radius = size.width * thermal.radius * (.33 + depth * .4);
      final Paint glow = Paint()
        ..color = const Color(0x386BB49E)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 11);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: radius * 1.2,
          height: size.height * .24 * depth,
        ),
        glow,
      );
      for (int ring = 0; ring < 3; ring++) {
        final double rise = math.sin(engine.elapsedSeconds * 2.1 + ring * 2.2);
        final Rect oval = Rect.fromCenter(
          center: Offset(x, y - rise * size.height * .012),
          width: radius * (1.4 - ring * .25),
          height: size.height * (.055 + ring * .018) * depth,
        );
        canvas.drawOval(
          oval,
          Paint()
            ..color = const Color(0x7C85B6A1)
                .withValues(alpha: .28 - ring * .045)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
      }
      if (ahead < .13) {
        _label(
          canvas,
          english ? 'LIFT' : 'TERMİK',
          Offset(x, y - size.height * .06),
          8,
          const Color(0xFF527D6F),
        );
      }
    }
  }

  void _paintGates(Canvas canvas, Size size) {
    final double planeY = _planeY(size);
    for (
      int index = engine.nextGate;
      index < math.min(scenario.gates.length, engine.nextGate + 4);
      index++
    ) {
      final FlightGate gate = scenario.gates[index];
      final double ahead = gate.distance - engine.plane.distance;
      if (ahead < -.035 || ahead > .52) continue;
      final double depth = (1 - ahead / .56).clamp(.12, 1).toDouble();
      final double centerX = gate.centerAt(engine.elapsedSeconds);
      final double x = size.width * centerX;
      final double y =
          planeY -
          ahead * size.height * 1.02 +
          (engine.plane.altitude - gate.altitude) * size.height * .2;
      final double width = size.width * gate.width * (.34 + depth * .72);
      final double height = size.height * gate.height * (.25 + depth * .72);
      final bool active = index == engine.nextGate;
      final Rect outer = Rect.fromCenter(
        center: Offset(x, y),
        width: width,
        height: height,
      );
      final Color ring = active
          ? const Color(0xFFB88E5F)
          : const Color(0xFF8CAEB4);
      canvas.drawOval(
        outer.inflate(size.width * .012),
        Paint()
          ..color = active ? const Color(0x332B6070) : const Color(0x24426973)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * .027 * depth,
      );
      canvas.drawOval(
        outer,
        Paint()
          ..color = ring.withValues(alpha: active ? .9 : .5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * .009 * depth
          ..shader = LinearGradient(
            colors: <Color>[
              Color.lerp(ring, Colors.white, .42)!,
              ring,
              Color.lerp(ring, Colors.black, .14)!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(outer),
      );
      final Paint aperture = Paint()
        ..color = active ? const Color(0x5572B7A9) : const Color(0x22729DA3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3;
      canvas.drawOval(outer.deflate(width * .12), aperture);
      if (active) {
        _label(
          canvas,
          '${index + 1}',
          Offset(x, y - height * .62),
          8 + depth * 3,
          const Color(0xFF4E7480),
        );
      }
    }
  }

  void _paintLanding(Canvas canvas, Size size) {
    final double remaining = 1 - engine.plane.distance;
    if (remaining > .3) return;
    final double depth = (1 - remaining / .34).clamp(.18, 1).toDouble();
    final double x = size.width * scenario.landing.centerX;
    final double y = _planeY(size) - remaining * size.height * .9;
    final double width =
        size.width * scenario.landing.width * (.32 + depth * .8);
    final Rect pad = Rect.fromCenter(
      center: Offset(x, y),
      width: width,
      height: size.height * .065 * (.28 + depth),
    );
    final RRect shape = RRect.fromRectAndRadius(
      pad,
      Radius.circular(pad.height * .3),
    );
    canvas.drawRRect(
      shape.shift(Offset(0, pad.height * .2)),
      Paint()..color = const Color(0x33516C70),
    );
    canvas.drawRRect(
      shape,
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[Color(0xFF6D8F84), Color(0xFF416D68)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(pad),
    );
    for (int stripe = 0; stripe < 5; stripe++) {
      final double stripeX = pad.left + pad.width * (.18 + stripe * .16);
      canvas.drawLine(
        Offset(stripeX, pad.top + pad.height * .17),
        Offset(stripeX, pad.bottom - pad.height * .17),
        Paint()
          ..color = const Color(0x99F5E6C6)
          ..strokeWidth = pad.height * .09,
      );
    }
    _label(
      canvas,
      english ? 'LANDING' : 'PIST',
      Offset(x, y + pad.height * .87),
      8,
      const Color(0xFF466F67),
    );
  }

  void _paintWind(Canvas canvas, Size size) {
    final FlightWind wind = scenario.windAt(
      engine.plane.distance,
      engine.elapsedSeconds,
    );
    final double direction = wind.cross.sign;
    final double strength = wind.cross.abs().clamp(0, .11).toDouble();
    for (int index = 0; index < 5; index++) {
      final double y = size.height * (.24 + index * .095);
      final double x =
          size.width * (.18 + (index % 2) * .62) +
          direction * strength * size.width * 1.8;
      final double len = size.width * (.035 + strength * .22);
      canvas.drawLine(
        Offset(x, y),
        Offset(x + direction * len, y - size.height * .008),
        Paint()
          ..color = const Color(0x5084A9B1)
          ..strokeWidth = 1.15
          ..strokeCap = StrokeCap.round,
      );
      if (index.isEven) {
        _arrow(
          canvas,
          Offset(x + direction * len, y - size.height * .008),
          direction,
          size.width * .009,
          const Color(0x6280A5AE),
        );
      }
    }
  }

  double _planeY(Size size) =>
      size.height * (.71 - (engine.plane.altitude - .55) * .24);

  void _paintGlider(Canvas canvas, Size size) {
    final Offset center = Offset(
      size.width * (.12 + engine.plane.x * .76),
      _planeY(size),
    );
    final double scale = size.width * .095;
    final double tilt =
        engine.plane.bank * .19 + engine.plane.lateralSpeed * .9;
    final double nose = engine.plane.pitch * -.10;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(tilt);
    final Path shadow = Path()
      ..moveTo(-scale * 1.6, scale * .12)
      ..lineTo(scale * .05, -scale * .17)
      ..lineTo(scale * 1.55, scale * .12)
      ..lineTo(scale * .08, scale * .06)
      ..lineTo(-scale * 1.6, scale * .12)
      ..close();
    canvas.drawPath(
      shadow.shift(Offset(1, scale * .29)),
      Paint()..color = const Color(0x3E4D717B),
    );
    final Path wing = Path()
      ..moveTo(-scale * 1.8, scale * .20)
      ..lineTo(scale * .04, -scale * .1 + nose)
      ..lineTo(scale * 1.8, scale * .2)
      ..lineTo(scale * .12, scale * .08)
      ..lineTo(-scale * 1.8, scale * .2)
      ..close();
    canvas.drawPath(
      wing,
      Paint()
        ..shader =
            const LinearGradient(
              colors: <Color>[
                Color(0xFFFFFFFF),
                Color(0xFFE9F1EA),
                Color(0xFFC6DCE0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(
              Rect.fromCenter(
                center: Offset.zero,
                width: scale * 3.8,
                height: scale * .45,
              ),
            ),
    );
    final Path upperFold = Path()
      ..moveTo(-scale * 1.8, scale * .20)
      ..lineTo(scale * .04, -scale * .1 + nose)
      ..lineTo(scale * .12, scale * .08)
      ..close();
    final Path lowerFold = Path()
      ..moveTo(scale * .04, -scale * .1 + nose)
      ..lineTo(scale * 1.8, scale * .2)
      ..lineTo(scale * .12, scale * .08)
      ..close();
    canvas.drawPath(upperFold, Paint()..color = const Color(0xFFF9FBF5));
    canvas.drawPath(lowerFold, Paint()..color = const Color(0xFFD6E6E7));
    final Paint crease = Paint()
      ..color = const Color(0x7A6F929A)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(-scale * 1.25, scale * .16),
      Offset(scale * .06, scale * .045 + nose),
      crease,
    );
    canvas.drawLine(
      Offset(scale * .06, scale * .045 + nose),
      Offset(scale * 1.28, scale * .16),
      crease,
    );
    canvas.drawLine(
      Offset(scale * .04, -scale * .1 + nose),
      Offset(scale * .12, scale * .08),
      crease,
    );
    final Path tip = Path()
      ..moveTo(scale * .04, -scale * .1 + nose)
      ..lineTo(scale * .13, scale * .08)
      ..lineTo(scale * .02, scale * .055)
      ..close();
    canvas.drawPath(tip, Paint()..color = const Color(0xFF8AAEBA));
    canvas.restore();

    final Path trail = Path()
      ..moveTo(center.dx - scale * .12, center.dy + scale * .25)
      ..cubicTo(
        center.dx - scale * .12 - engine.plane.lateralSpeed * size.width * .28,
        center.dy + scale * .58,
        center.dx - scale * .2,
        center.dy + scale * 1.15,
        center.dx - scale * .2,
        center.dy + scale * 1.8,
      );
    canvas.drawPath(
      trail,
      Paint()
        ..color = Colors.white.withValues(alpha: .68)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintAltimeter(Canvas canvas, Size size) {
    final Rect rail = Rect.fromLTWH(
      size.width * .045,
      size.height * .19,
      3,
      size.height * .34,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rail, const Radius.circular(4)),
      Paint()..color = const Color(0x66819DA0),
    );
    for (int tick = 0; tick <= 4; tick++) {
      final double y = rail.top + rail.height * tick / 4;
      canvas.drawLine(
        Offset(rail.left - 3, y),
        Offset(rail.right + 3, y),
        Paint()
          ..color = const Color(0x78819DA0)
          ..strokeWidth = 1,
      );
    }
    final double markerY =
        rail.bottom - rail.height * engine.plane.altitude.clamp(.15, .88) / .88;
    canvas.drawCircle(
      Offset(rail.center.dx, markerY),
      size.width * .015,
      Paint()..color = _ink,
    );
    canvas.drawCircle(
      Offset(rail.center.dx, markerY),
      size.width * .008,
      Paint()..color = Colors.white,
    );
  }

  void _arrow(
    Canvas canvas,
    Offset end,
    double direction,
    double size,
    Color color,
  ) {
    final Path path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(end.dx - direction * size, end.dy - size * .55)
      ..lineTo(end.dx - direction * size, end.dy + size * .55)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _label(
    Canvas canvas,
    String text,
    Offset center,
    double size,
    Color color,
  ) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w900,
          letterSpacing: .8,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_PaperFlightPainter oldDelegate) =>
      oldDelegate.scenario != scenario ||
      oldDelegate.engine != engine ||
      oldDelegate.engine.plane.x != engine.plane.x ||
      oldDelegate.engine.plane.altitude != engine.plane.altitude ||
      oldDelegate.engine.plane.distance != engine.plane.distance ||
      oldDelegate.engine.nextGate != engine.nextGate ||
      oldDelegate.engine.misses != engine.misses ||
      oldDelegate.engine.thermalsUsed != engine.thermalsUsed ||
      oldDelegate.engine.elapsedSeconds != engine.elapsedSeconds ||
      oldDelegate.paused != paused ||
      oldDelegate.english != english;
}
