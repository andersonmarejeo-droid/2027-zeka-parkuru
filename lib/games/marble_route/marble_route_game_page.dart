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
import 'marble_route_engine.dart';
import 'marble_route_scenario.dart';

class MarbleRouteGamePage extends StatelessWidget {
  const MarbleRouteGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  static const int totalCases = MarbleRouteScenario.maximumLevels;
  static const int totalStars = totalCases * 3;

  static final List<ParkurLevelSpec> _levels = List<ParkurLevelSpec>.generate(
    totalCases,
    (int index) {
      final int level = index + 1;
      final String tr = switch (level) {
        <= 3 => 'Tahtayı küçük hareketlerle eğ; bilyeyi ilk geçitten geçir.',
        <= 6 => 'Buz, keçe ve tamponların hızını ayrı ayrı oku.',
        7 ||
        8 => 'İleri: hareketli köprü, buz ve yan çukurları birlikte yönet.',
        9 => 'Uzman rotası: dört kayan kapı, az hata hakkı ve dar çizgi.',
        _ => 'Usta finali: beş zamanlı geçit ve iki düşüş cebi.',
      };
      final String en = switch (level) {
        <= 3 => 'Tilt the board gently and guide the marble through each gate.',
        <= 6 => 'Read the speed of ice, felt and bumper surfaces separately.',
        7 || 8 => 'Advanced: combine a moving bridge, ice and side pits.',
        9 => 'Expert route: four moving gates and only one fall allowed.',
        _ => 'Master finale: five timed gates and two fall pockets.',
      };
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Mermer Parkur ${level.toString().padLeft(2, '0')}',
        titleEn: 'Marble Course ${level.toString().padLeft(2, '0')}',
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
      gameId: 'marble_route',
      progressPrefix: 'marble_route',
      titleTr: 'Mermer Rota',
      titleEn: 'Marble Route',
      taglineTr: 'Tahtayı eğ • Ataleti oku • Çukura ulaş',
      taglineEn: 'Tilt the board • Manage momentum • Reach the cup',
      accent: skin.accent,
      icon: Icons.sports_handball_rounded,
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
          ) => MarbleRoutePlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class MarbleRoutePlayPage extends StatefulWidget {
  const MarbleRoutePlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<MarbleRoutePlayPage> createState() => _MarbleRoutePlayPageState();
}

class _MarbleRoutePlayPageState extends State<MarbleRoutePlayPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const Color _ink = Color(0xFF3E514B);
  static const Color _accent = Color(0xFF528878);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.fun,
  );
  late final Ticker _ticker;
  late MarbleRouteScenario _scenario;
  late MarbleRouteEngine _engine;
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
    MarbleRouteScenario scenario = MarbleRouteScenario.forLevel(
      widget.level.number,
    );
    try {
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      final String visitKey =
          'marble_route_level_${widget.level.number}_visits';
      final int visits = await preferences.getInt(visitKey) ?? 0;
      if (visits > 0) {
        final int index =
            await preferences.getInt('marble_route_practice_index') ?? 0;
        if (index < MarbleRouteScenario.maximumPracticeRounds) {
          final int next = index + 1;
          await preferences.setInt('marble_route_practice_index', next);
          scenario = MarbleRouteScenario.forPracticeRound(next);
        }
      }
      await preferences.setInt(visitKey, visits + 1);
    } catch (_) {
      scenario = MarbleRouteScenario.forLevel(widget.level.number);
    }
    if (!mounted) return;
    _scenario = scenario;
    _startRound();
    setState(() => _ready = true);
  }

  void _startRound() {
    _ticker.stop();
    _engine = MarbleRouteEngine(scenario: _scenario);
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
      _engine.setTilt(0, 0);
      _session.pause();
      _ticker.stop();
    } else {
      _session.resume();
      _lastTick = Duration.zero;
      _ticker.start();
    }
    unawaited(_audio.play(GameSound.uiClick, gain: .24));
  }

  void _applyBoardTilt(Offset localPosition, Size size) {
    if (!_ready || _paused || _finished) return;
    final double x = ((localPosition.dx / size.width) * 2 - 1)
        .clamp(-1, 1)
        .toDouble();
    final double y = ((localPosition.dy / size.height) * 2 - 1)
        .clamp(-1, 1)
        .toDouble();
    _engine.setTilt(x, y);
    setState(() {});
  }

  void _releaseBoardTilt() {
    if (!_ready || _paused || _finished) return;
    _engine.setTilt(0, 0);
    setState(() {});
  }

  void _tick(Duration elapsed) {
    if (!_ready || _paused || _finished) return;
    final double raw = (elapsed - _lastTick).inMicroseconds / 1000000;
    _lastTick = elapsed;
    if (raw <= 0) return;
    final double delta = raw.clamp(0, .024).toDouble();
    _elapsed += delta;
    final MarbleStepResult result = _engine.step(delta);
    if (result.gatePassed) {
      _score += 80;
      _session.recordAccepted(points: 80);
      unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .30));
      _audio.hapticLight();
    } else if (result.fell) {
      _session.recordMistake();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .28));
    } else if (result.gateBounced || result.bumperHit) {
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .12));
    }
    if (result.reachedGoal) {
      final int timeBonus = math.max(
        0,
        ((_scenario.goldTimeSeconds - _elapsed) * 4).round(),
      );
      _score += 400 + timeBonus;
      _session.recordAccepted(points: 400 + timeBonus);
      unawaited(_finish(completed: true));
    } else if (_engine.misses > _scenario.missLimit) {
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
              title: Text(_english ? 'Route run out' : 'Düşüş hakkı doldu'),
              content: Text(
                _english
                    ? 'The marble fell too many times. Use short board tilts, then try the course again?'
                    : 'Bilye fazla kez kenar cebine düştü. Tahtayı kısa eğimlerle yönetip yeniden deneyelim mi?',
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
        setState(_startRound);
      } else {
        Navigator.of(context)
            .pop(StudioGameResult.failed(score: _score).toParkurResult());
      }
      return;
    }

    _session.complete(
      stars: _stars,
      action: widget.level.number < MarbleRouteGamePage.totalCases
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
      titleTr: 'MERMER PARKURU TAMAMLANDI',
      titleEn: 'MARBLE COURSE COMPLETE',
      detailTr:
          '${_engine.nextGate}/${_scenario.gates.length} geçit · ${_engine.misses} düşüş · ${_elapsed.toStringAsFixed(1)} sn.',
      detailEn:
          '${_engine.nextGate}/${_scenario.gates.length} gates · ${_engine.misses} falls · ${_elapsed.toStringAsFixed(1)} s.',
      stars: _stars,
      score: _score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < MarbleRouteGamePage.totalCases,
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
        appBar: AppBar(title: Text(_english ? 'MARBLE ROUTE' : 'MERMER ROTA')),
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
          _english ? 'MARBLE ROUTE' : 'MERMER ROTA',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('marble_route_pause'),
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
                  _RouteHud(
                    gate: _engine.nextGate,
                    total: _scenario.gates.length,
                    misses: _engine.misses,
                    missLimit: _scenario.missLimit,
                    speed: _engine.speed,
                    surface: _engine.currentSurface,
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
                        final Size boardSize = Size(width, height);
                        return Center(
                          child: SizedBox(
                            key: const ValueKey<String>('marble_route_board'),
                            width: width,
                            height: height,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanStart: (DragStartDetails details) =>
                                  _applyBoardTilt(
                                    details.localPosition,
                                    boardSize,
                                  ),
                              onPanUpdate: (DragUpdateDetails details) =>
                                  _applyBoardTilt(
                                    details.localPosition,
                                    boardSize,
                                  ),
                              onPanEnd: (DragEndDetails details) =>
                                  _releaseBoardTilt(),
                              child: CustomPaint(
                                painter: _MarbleRoutePainter(
                                  scenario: _scenario,
                                  engine: _engine,
                                  paused: _paused,
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
                              ? 'Touch and tilt the plate. Short movements preserve control; let go to coast.'
                              : 'Plakaya dokunup eğ. Kısa hareketler kontrolü korur; bırakınca bilye süzülür.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: StudioVisuals.muted,
                            fontSize: 9,
                            height: 1.18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      _TiltPad(
                        key: const ValueKey<String>('marble_route_tilt'),
                        x: _engine.tiltX,
                        y: _engine.tiltY,
                        enabled: !_paused && !_finished,
                        english: _english,
                        onTilt: _engine.setTilt,
                        onRelease: _releaseBoardTilt,
                        onRefresh: () => setState(() {}),
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

class _RouteHud extends StatelessWidget {
  const _RouteHud({
    required this.gate,
    required this.total,
    required this.misses,
    required this.missLimit,
    required this.speed,
    required this.surface,
    required this.english,
  });

  final int gate;
  final int total;
  final int misses;
  final int missLimit;
  final double speed;
  final MarbleSurfaceKind surface;
  final bool english;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('marble_route_hud'),
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
            child: _RouteMetric(
              label: english ? 'GATES' : 'GEÇİT',
              value: '$gate / $total',
              icon: Icons.route_rounded,
              color: _MarbleRoutePlayPageState._accent,
            ),
          ),
          Container(width: 1, height: 27, color: StudioVisuals.line),
          Expanded(
            child: _RouteMetric(
              label: english ? 'FALLS' : 'DÜŞÜŞ',
              value: '$misses / $missLimit',
              icon: Icons.warning_amber_rounded,
              color: misses == 0
                  ? _MarbleRoutePlayPageState._accent
                  : const Color(0xFFC57561),
            ),
          ),
          Container(width: 1, height: 27, color: StudioVisuals.line),
          Expanded(
            child: _RouteMetric(
              label: _surfaceLabel(surface, english),
              value: '${(speed * 100).round()}%',
              icon: surface == MarbleSurfaceKind.ice
                  ? Icons.ac_unit_rounded
                  : surface == MarbleSurfaceKind.rough
                  ? Icons.grain_rounded
                  : surface == MarbleSurfaceKind.current
                  ? Icons.waves_rounded
                  : Icons.slow_motion_video_rounded,
              color: const Color(0xFF7793A1),
            ),
          ),
        ],
      ),
    );
  }

  String _surfaceLabel(MarbleSurfaceKind kind, bool english) => switch (kind) {
    MarbleSurfaceKind.felt => english ? 'FELT' : 'KEÇE',
    MarbleSurfaceKind.rough => english ? 'ROUGH' : 'PÜRÜZ',
    MarbleSurfaceKind.ice => english ? 'ICE' : 'BUZ',
    MarbleSurfaceKind.current => english ? 'FLOW' : 'AKINTI',
  };
}

class _RouteMetric extends StatelessWidget {
  const _RouteMetric({
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
                color: _MarbleRoutePlayPageState._ink,
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

class _TiltPad extends StatelessWidget {
  const _TiltPad({
    super.key,
    required this.x,
    required this.y,
    required this.enabled,
    required this.english,
    required this.onTilt,
    required this.onRelease,
    required this.onRefresh,
  });

  final double x;
  final double y;
  final bool enabled;
  final bool english;
  final void Function(double x, double y) onTilt;
  final VoidCallback onRelease;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    const Size size = Size(104, 72);
    return Semantics(
      label: english ? 'Board tilt control' : 'Tahta eğim kontrolü',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: enabled
            ? (DragStartDetails details) => _update(details.localPosition)
            : null,
        onPanUpdate: enabled
            ? (DragUpdateDetails details) => _update(details.localPosition)
            : null,
        onPanEnd: enabled ? (_) => onRelease() : null,
        child: Container(
          width: size.width,
          height: size.height,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF0EC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFD5E0DA)),
          ),
          child: CustomPaint(
            painter: _TiltPadPainter(x: x, y: y),
          ),
        ),
      ),
    );
  }

  void _update(Offset point) {
    final double nextX = ((point.dx / 104) * 2 - 1).clamp(-1, 1).toDouble();
    final double nextY = ((point.dy / 72) * 2 - 1).clamp(-1, 1).toDouble();
    onTilt(nextX, nextY);
    onRefresh();
  }
}

class _TiltPadPainter extends CustomPainter {
  const _TiltPadPainter({required this.x, required this.y});

  final double x;
  final double y;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint guide = Paint()
      ..color = const Color(0xFFC7D3CC)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(size.width * .5, 9),
      Offset(size.width * .5, size.height - 9),
      guide,
    );
    canvas.drawLine(
      Offset(11, size.height * .5),
      Offset(size.width - 11, size.height * .5),
      guide,
    );
    final Offset center = Offset(
      size.width * (.5 + x * .37),
      size.height * (.5 + y * .34),
    );
    canvas.drawCircle(
      center.translate(0, 2),
      13,
      Paint()..color = const Color(0x2252675E),
    );
    canvas.drawCircle(
      center,
      13,
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[Color(0xFF74A28F), Color(0xFF3E7966)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromCircle(center: center, radius: 13)),
    );
    canvas.drawCircle(
      center.translate(-3, -4),
      3.2,
      Paint()..color = Colors.white.withValues(alpha: .76),
    );
  }

  @override
  bool shouldRepaint(_TiltPadPainter oldDelegate) =>
      oldDelegate.x != x || oldDelegate.y != y;
}

class _MarbleRoutePainter extends CustomPainter {
  const _MarbleRoutePainter({
    required this.scenario,
    required this.engine,
    required this.paused,
  });

  final MarbleRouteScenario scenario;
  final MarbleRouteEngine engine;
  final bool paused;

  static const Color _felt = Color(0xFF668B7C);
  static const Color _feltDark = Color(0xFF385D53);
  static const Color _brass = Color(0xFFCDAA68);

  @override
  void paint(Canvas canvas, Size size) {
    final Rect outer = Offset.zero & size;
    final Rect board = outer.deflate(size.width * .035);
    final RRect boardShape = RRect.fromRectAndRadius(
      board,
      Radius.circular(size.width * .075),
    );
    canvas.drawRRect(
      boardShape.shift(Offset(0, size.height * .011)),
      Paint()
        ..color = const Color(0x243A5149)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawRRect(
      boardShape,
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[
            Color(0xFFE6DCCB),
            Color(0xFFB8A68C),
            Color(0xFFE9DFC9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(board),
    );
    final Rect surface = board.deflate(size.width * .046);
    final RRect playfield = RRect.fromRectAndRadius(
      surface,
      Radius.circular(size.width * .045),
    );
    canvas.save();
    canvas.clipRRect(playfield);
    canvas.drawRRect(
      playfield,
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[Color(0xFF73988A), _felt, _feltDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(surface),
    );
    _paintFeltGrain(canvas, surface, size.width);
    _paintRouteRails(canvas, surface);
    _paintSurfaces(canvas, surface);
    _paintPits(canvas, surface);
    _paintGates(canvas, surface);
    _paintBumpers(canvas, surface);
    _paintGoal(canvas, surface);
    _paintMarble(canvas, surface);
    canvas.restore();
    _paintEdgePins(canvas, board);
    if (paused) {
      canvas.drawRRect(playfield, Paint()..color = const Color(0x991D302A));
      _drawLabel(
        canvas,
        'PAUSED',
        Offset(size.width * .5, size.height * .49),
        math.max(16, size.width * .047),
        Colors.white,
      );
    }
  }

  Offset _point(MarblePoint point, Rect field) => Offset(
    field.left + point.x * field.width,
    field.top + point.y * field.height,
  );

  void _paintFeltGrain(Canvas canvas, Rect field, double width) {
    final Paint grain = Paint()
      ..color = const Color(0x16FFFFFF)
      ..strokeWidth = .7;
    for (int row = 0; row < 32; row++) {
      final double y = field.top + field.height * (row + .5) / 32;
      canvas.drawLine(
        Offset(field.left + 12, y),
        Offset(field.right - 12, y + math.sin(row * .7) * width * .003),
        grain,
      );
    }
  }

  void _paintRouteRails(Canvas canvas, Rect field) {
    final Paint rail = Paint()
      ..color = const Color(0x62523F31)
      ..style = PaintingStyle.stroke
      ..strokeWidth = field.width * .014;
    final Paint inner = Paint()
      ..color = const Color(0x3BE0D1B7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final RRect inset = RRect.fromRectAndRadius(
      field.deflate(field.width * .035),
      Radius.circular(field.width * .05),
    );
    canvas.drawRRect(inset, rail);
    canvas.drawRRect(inset.deflate(field.width * .012), inner);
    final Path center = Path()
      ..moveTo(field.left + field.width * .5, field.bottom - field.height * .1)
      ..lineTo(field.left + field.width * .5, field.top + field.height * .1);
    canvas.drawPath(
      center,
      Paint()
        ..color = const Color(0x2454E4B2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = field.width * .006
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintSurfaces(Canvas canvas, Rect field) {
    for (final MarbleSurface patch in scenario.surfaces) {
      final Offset center = _point(patch.center, field);
      final Rect rect = Rect.fromCenter(
        center: center,
        width: patch.width * field.width,
        height: patch.height * field.height,
      );
      final Color top = switch (patch.kind) {
        MarbleSurfaceKind.felt => const Color(0xFF89AD9D),
        MarbleSurfaceKind.rough => const Color(0xFFC6AE82),
        MarbleSurfaceKind.ice => const Color(0xFFBCE0E6),
        MarbleSurfaceKind.current => const Color(0xFF80B5B1),
      };
      final Color bottom = switch (patch.kind) {
        MarbleSurfaceKind.felt => const Color(0xFF517667),
        MarbleSurfaceKind.rough => const Color(0xFF8C7451),
        MarbleSurfaceKind.ice => const Color(0xFF6CABB9),
        MarbleSurfaceKind.current => const Color(0xFF4E8587),
      };
      canvas.drawOval(
        rect,
        Paint()
          ..shader = LinearGradient(
            colors: <Color>[top, bottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(rect),
      );
      final Paint detail = Paint()
        ..color = Colors.white.withValues(alpha: .24)
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round;
      if (patch.kind == MarbleSurfaceKind.ice) {
        canvas.drawLine(
          Offset(rect.left + rect.width * .2, rect.top + rect.height * .32),
          Offset(
            rect.right - rect.width * .18,
            rect.bottom - rect.height * .25,
          ),
          detail,
        );
        canvas.drawLine(
          Offset(rect.left + rect.width * .48, rect.top + rect.height * .14),
          Offset(
            rect.right - rect.width * .34,
            rect.bottom - rect.height * .12,
          ),
          detail,
        );
      } else if (patch.kind == MarbleSurfaceKind.rough) {
        for (int i = 0; i < 5; i++) {
          final double x = rect.left + rect.width * (.15 + i * .16);
          canvas.drawCircle(Offset(x, center.dy), 1.1, detail);
        }
      } else if (patch.kind == MarbleSurfaceKind.current) {
        for (int i = 0; i < 3; i++) {
          final double y = rect.top + rect.height * (.32 + i * .19);
          final double shift = patch.flowX.sign * rect.width * .11;
          canvas.drawLine(
            Offset(rect.left + rect.width * .23 + shift, y),
            Offset(rect.right - rect.width * .22 + shift, y),
            detail,
          );
        }
      }
    }
  }

  void _paintPits(Canvas canvas, Rect field) {
    for (final MarblePit pit in scenario.pits) {
      final Offset center = _point(pit.center, field);
      final double radius = pit.radius * field.width;
      canvas.drawCircle(
        center.translate(0, radius * .12),
        radius * 1.24,
        Paint()..color = const Color(0x33503D30),
      );
      canvas.drawCircle(
        center,
        radius * 1.17,
        Paint()
          ..shader = const RadialGradient(
            colors: <Color>[Color(0xFFBBA77F), Color(0xFF675747)],
          ).createShader(Rect.fromCircle(center: center, radius: radius * 1.2)),
      );
      canvas.drawCircle(
        center,
        radius * .78,
        Paint()
          ..shader = const RadialGradient(
            colors: <Color>[Color(0xFF344840), Color(0xFF172B27)],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: center.translate(-radius * .18, -radius * .28),
          width: radius * .62,
          height: radius * .21,
        ),
        Paint()..color = const Color(0x33FFFFFF),
      );
    }
  }

  void _paintGates(Canvas canvas, Rect field) {
    for (int index = 0; index < scenario.gates.length; index++) {
      final MarbleGate gate = scenario.gates[index];
      final double centerX = gate.centerAt(engine.elapsedSeconds);
      final double y = field.top + gate.y * field.height;
      final double left = field.left + .075 * field.width;
      final double right = field.right - .075 * field.width;
      final double gapLeft =
          field.left + (centerX - gate.width / 2) * field.width;
      final double gapRight =
          field.left + (centerX + gate.width / 2) * field.width;
      final bool active = index == engine.nextGate;
      final Color metal = active
          ? const Color(0xFFD9C08C)
          : const Color(0xFF8D9B92);
      final Paint shadow = Paint()
        ..color = const Color(0x55502E27)
        ..strokeWidth = field.width * .033
        ..strokeCap = StrokeCap.round;
      final Paint bar = Paint()
        ..color = metal
        ..strokeWidth = field.width * .022
        ..strokeCap = StrokeCap.round;
      for (final (double, double) segment in <(double, double)>[
        (left, gapLeft),
        (gapRight, right),
      ]) {
        canvas.drawLine(
          Offset(segment.$1, y + 2),
          Offset(segment.$2, y + 2),
          shadow,
        );
        canvas.drawLine(Offset(segment.$1, y), Offset(segment.$2, y), bar);
      }
      final Paint opening = Paint()
        ..color = active ? const Color(0x9EEBCB79) : const Color(0x517AC4A5)
        ..strokeWidth = field.width * .006
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(gapLeft, y), Offset(gapRight, y), opening);
      for (final double x in <double>[left, right]) {
        canvas.drawCircle(
          Offset(x, y),
          field.width * .018,
          Paint()..color = _brass,
        );
      }
    }
  }

  void _paintBumpers(Canvas canvas, Rect field) {
    for (final MarbleBumper bumper in scenario.bumpers) {
      final Offset center = _point(bumper.center, field);
      final double radius = bumper.radius * field.width;
      canvas.drawCircle(
        center.translate(0, radius * .18),
        radius * 1.18,
        Paint()..color = const Color(0x3540362A),
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = const RadialGradient(
            colors: <Color>[
              Color(0xFFFFE9B8),
              Color(0xFFB98B4E),
              Color(0xFF69533D),
            ],
            stops: <double>[0, .66, 1],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
      canvas.drawCircle(
        center,
        radius * .51,
        Paint()..color = const Color(0xFF53695D),
      );
      canvas.drawCircle(
        center.translate(-radius * .27, -radius * .31),
        radius * .17,
        Paint()..color = const Color(0xBFFFFFFF),
      );
    }
  }

  void _paintGoal(Canvas canvas, Rect field) {
    final Offset center = _point(scenario.goal, field);
    final double radius = MarbleRouteEngine.goalRadius * field.width;
    canvas.drawCircle(
      center.translate(0, radius * .2),
      radius * 1.34,
      Paint()..color = const Color(0x3940332D),
    );
    canvas.drawCircle(center, radius * 1.32, Paint()..color = _brass);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          colors: <Color>[Color(0xFF253A33), Color(0xFF13251F)],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 1.12),
      math.pi * 1.12,
      math.pi * .76,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: .55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _paintMarble(Canvas canvas, Rect field) {
    final Offset center = _point(
      MarblePoint(engine.marble.x, engine.marble.y),
      field,
    );
    final double radius = MarbleRouteEngine.marbleRadius * field.width;
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(radius * .17, radius * .5),
        width: radius * 2.2,
        height: radius * 1.03,
      ),
      Paint()..color = const Color(0x4C17211D),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.38, -.5),
          radius: .9,
          colors: <Color>[
            Color(0xFFFFFFFF),
            Color(0xFFEAF3F0),
            Color(0xFF8DAAA1),
            Color(0xFF486B61),
          ],
          stops: <double>[0, .24, .72, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center.translate(-radius * .34, -radius * .36),
      radius * .18,
      Paint()..color = Colors.white.withValues(alpha: .86),
    );
    if (engine.speed > .12) {
      final double length = (engine.speed * field.width * .22)
          .clamp(2, 16)
          .toDouble();
      final double speed = math.max(.001, engine.speed);
      final Offset tail = Offset(
        center.dx - engine.marble.vx / speed * length,
        center.dy - engine.marble.vy / speed * length,
      );
      canvas.drawLine(
        center,
        tail,
        Paint()
          ..color = const Color(0x9FFFFFFF)
          ..strokeWidth = radius * .15
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _paintEdgePins(Canvas canvas, Rect board) {
    final Paint pin = Paint()
      ..shader =
          const RadialGradient(
            colors: <Color>[Color(0xFFFFE6B4), Color(0xFF8D734F)],
          ).createShader(
            Rect.fromCircle(center: Offset.zero, radius: board.width * .009),
          );
    final double inset = board.width * .04;
    for (final Offset point in <Offset>[
      Offset(board.left + inset, board.top + inset),
      Offset(board.right - inset, board.top + inset),
      Offset(board.left + inset, board.bottom - inset),
      Offset(board.right - inset, board.bottom - inset),
    ]) {
      canvas.drawCircle(point, board.width * .009, pin);
    }
  }

  void _drawLabel(
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
          letterSpacing: 1.1,
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
  bool shouldRepaint(_MarbleRoutePainter oldDelegate) =>
      oldDelegate.scenario != scenario ||
      oldDelegate.engine != engine ||
      oldDelegate.engine.marble.x != engine.marble.x ||
      oldDelegate.engine.marble.y != engine.marble.y ||
      oldDelegate.engine.nextGate != engine.nextGate ||
      oldDelegate.engine.misses != engine.misses ||
      oldDelegate.engine.elapsedSeconds != engine.elapsedSeconds ||
      oldDelegate.paused != paused;
}
