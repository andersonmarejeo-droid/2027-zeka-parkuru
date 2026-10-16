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
import 'magnet_path_engine.dart';
import 'magnet_path_scenario.dart';

class MagnetPathGamePage extends StatelessWidget {
  const MagnetPathGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  static const int totalCases = MagnetPathScenario.maximumLevels;
  static const int totalStars = totalCases * 3;

  static final List<ParkurLevelSpec> _levels =
      List<ParkurLevelSpec>.generate(totalCases, (int index) {
        final int level = index + 1;
        final String tr = switch (level) {
          <= 3 => 'Mıknatısı bilyeden uzağa taşı; akış ve ataleti izle.',
          <= 6 => 'Kutup yönünü değiştirip kapıları doğru sırayla topla.',
          7 || 8 => 'İleri: metal engellerin çevresinde momentum kır.',
          9 => 'Uzman: dar halkaları çapraz alanda ve sınırlı çarpışmayla geç.',
          _ => 'Usta finali: iki kalkan arasındaki altı kapıyı hedefe bağla.',
        };
        final String en = switch (level) {
          <= 3 => 'Move the magnet beyond the puck and read inertia as it follows.',
          <= 6 => 'Reverse polarity and collect each gate in the correct order.',
          7 || 8 => 'Advanced: bleed momentum around the metal baffles.',
          9 => 'Expert: cross a field of narrow gates with limited collisions.',
          _ => 'Master finale: guide the puck through six gates and dock at the target between shields.',
        };
        return ParkurLevelSpec(
          number: level,
          titleTr: 'Kutup Parkuru ${level.toString().padLeft(2, '0')}',
          titleEn: 'Magnetic Course ${level.toString().padLeft(2, '0')}',
          subtitleTr: tr,
          subtitleEn: en,
          difficulty: switch (level) {
            <= 3 => 'USTALAŞMA',
            <= 6 => 'DERİNLEŞME',
            7 || 8 => 'İLERİ',
            9 => 'UZMAN',
            _ => 'USTA',
          },
          icon: Icons.flare_rounded,
        );
      }, growable: false);

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.fun);
    return ParkurLevelHub(
      gameId: 'magnet_path',
      progressPrefix: 'magnet_path',
      titleTr: 'Mıknatıs Rotası',
      titleEn: 'Magnet Path',
      taglineTr: 'Alanı konumlandır • Kutbu değiştir • Bilyeyi kurtar',
      taglineEn: 'Place the field • Reverse the poles • Guide the puck',
      accent: skin.accent,
      icon: Icons.flare_rounded,
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
          ) => MagnetPathPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class MagnetPathPlayPage extends StatefulWidget {
  const MagnetPathPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<MagnetPathPlayPage> createState() => _MagnetPathPlayPageState();
}

class _MagnetPathPlayPageState extends State<MagnetPathPlayPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const Color _ink = Color(0xFF25404A);
  static const Color _accent = Color(0xFF318C82);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.fun,
  );
  late final Ticker _ticker;
  late MagnetPathScenario _scenario;
  late MagnetPathEngine _engine;
  late StudioGameSession _session;
  Duration _lastTick = Duration.zero;
  double _elapsed = 0;
  double _magnetX = .53;
  double _magnetY = .48;
  double _worldHeight = 1.1;
  int _collisions = 0;
  int _score = 0;
  bool _attract = true;
  bool _ready = false;
  bool _paused = false;
  bool _finished = false;
  bool _english = false;

  int get _gatesPassed => _engine.nextGate;

  int get _stars {
    if (_collisions == 0 && _elapsed < 45 - widget.level.number * 1.5) return 3;
    if (_collisions <= 1) return 2;
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
    MagnetPathScenario scenario = MagnetPathScenario.forLevel(widget.level.number);
    try {
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      final String visitKey = 'magnet_path_level_${widget.level.number}_visits';
      final int visits = await preferences.getInt(visitKey) ?? 0;
      if (visits > 0) {
        final int index = await preferences.getInt('magnet_path_practice_index') ?? 0;
        if (index < MagnetPathScenario.maximumPracticeRounds) {
          final int next = index + 1;
          await preferences.setInt('magnet_path_practice_index', next);
          scenario = MagnetPathScenario.forPracticeRound(next);
        }
      }
      await preferences.setInt(visitKey, visits + 1);
    } catch (_) {
      scenario = MagnetPathScenario.forLevel(widget.level.number);
    }
    if (!mounted) return;
    _scenario = scenario;
    _startRun();
    setState(() => _ready = true);
  }

  void _startRun() {
    _ticker.stop();
    _engine = MagnetPathEngine(scenario: _scenario);
    _elapsed = 0;
    _magnetX = .52;
    _magnetY = _worldHeight * .48;
    _collisions = 0;
    _score = 0;
    _attract = true;
    _paused = false;
    _finished = false;
    _lastTick = Duration.zero;
    _session = StudioGameSession(level: widget.level.number, seed: _scenario.seed)
      ..start();
    _ticker.start();
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

  void _moveMagnet(Offset localPosition, double width) {
    if (!_ready || _paused || _finished) return;
    setState(() {
      _magnetX = (localPosition.dx / width).clamp(.12, .88).toDouble();
      _magnetY = (localPosition.dy / width)
          .clamp(.12, _worldHeight - .12)
          .toDouble();
    });
  }

  void _togglePolarity() {
    if (!_ready || _paused || _finished) return;
    setState(() => _attract = !_attract);
    _audio.hapticSelection();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .24));
  }

  void _resetPuck() {
    if (!_ready || _paused || _finished) return;
    setState(() {
      _engine.reset();
      _magnetX = .52;
      _magnetY = _worldHeight * .48;
    });
    _audio.hapticLight();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .22),
    );
  }

  void _tick(Duration elapsed) {
    if (!_ready || _paused || _finished) return;
    final double raw = (elapsed - _lastTick).inMicroseconds / 1000000;
    _lastTick = elapsed;
    if (raw <= 0) return;
    final double delta = raw.clamp(0, .032).toDouble();
    _elapsed += delta;
    final MagnetStepResult result = _engine.step(
      deltaSeconds: delta,
      worldHeight: _worldHeight,
      magnetX: _magnetX,
      magnetY: _magnetY,
      attract: _attract,
    );
    if (result.collided) {
      _collisions++;
      _session.recordMistake();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .22));
    }
    if (result.gatesReached.isNotEmpty) {
      _score += 120 + math.max(0, 45 - _collisions * 12);
      _session.recordAccepted(points: 120);
      _audio.hapticLight();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .28));
    }
    if (_engine.nextGate >= _scenario.gates.length) {
      unawaited(_finish(completed: true));
    } else if (_collisions >= _scenario.collisionLimit) {
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
              title: Text(_english ? 'Puck jammed' : 'Bilye parkurda sıkıştı'),
              content: Text(
                _english
                    ? 'The collision limit was reached. Reposition the field and retry the course?'
                    : 'Çarpışma sınırına ulaşıldı. Alanı yeniden konumlandırıp parkuru tekrar deneyelim mi?',
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
        Navigator.of(context).pop(StudioGameResult.failed(score: _score).toParkurResult());
      }
      return;
    }

    _session.complete(
      stars: _stars,
      action: widget.level.number < MagnetPathGamePage.totalCases
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
      titleTr: 'KUTUP PARKURU TAMAMLANDI',
      titleEn: 'MAGNETIC COURSE COMPLETE',
      detailTr: '$_gatesPassed kapı · $_collisions çarpışma.',
      detailEn: '$_gatesPassed gates · $_collisions collisions.',
      stars: _stars,
      score: _score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < MagnetPathGamePage.totalCases,
    );
    if (!mounted) return;
    final StudioResultAction action = switch (result) {
      ParkurResultAction.replay => StudioResultAction.replay,
      ParkurResultAction.next => StudioResultAction.next,
      _ => StudioResultAction.map,
    };
    Navigator.of(context).pop(
      StudioGameResult.completed(score: _score, stars: _stars, action: action)
          .toParkurResult(),
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
        appBar: AppBar(title: Text(_english ? 'MAGNET PATH' : 'MIKNATIS ROTASI')),
        body: const Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: _ink,
        surfaceTintColor: Colors.transparent,
        title: Text(_english ? 'MAGNET PATH' : 'MIKNATIS ROTASI', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('magnet_path_pause'),
            tooltip: _paused ? (_english ? 'Resume' : 'Devam et') : (_english ? 'Pause' : 'Duraklat'),
            onPressed: () => _setPaused(!_paused),
            icon: Icon(_paused ? Icons.play_arrow_rounded : Icons.pause_rounded),
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
                  _MagnetHud(
                    passed: _gatesPassed,
                    total: _scenario.gates.length,
                    collisions: _collisions,
                    collisionLimit: _scenario.collisionLimit,
                    english: _english,
                  ),
                  const SizedBox(height: 7),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints limits) {
                        final double width = math.min(limits.maxWidth, 570);
                        final double height = math.min(limits.maxHeight, width * 1.17);
                        _worldHeight = width <= 0 ? 1.1 : height / width;
                        return Center(
                          child: SizedBox(
                            width: width,
                            height: height,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapDown: (TapDownDetails details) => _moveMagnet(details.localPosition, width),
                              onPanStart: (DragStartDetails details) => _moveMagnet(details.localPosition, width),
                              onPanUpdate: (DragUpdateDetails details) => _moveMagnet(details.localPosition, width),
                              child: CustomPaint(
                                key: const ValueKey<String>('magnet_path_scene'),
                                painter: _MagnetPathPainter(
                                  scenario: _scenario,
                                  engine: _engine,
                                  magnetX: _magnetX,
                                  magnetY: _magnetY,
                                  worldHeight: _worldHeight,
                                  attract: _attract,
                                  collisions: _collisions,
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
                  const SizedBox(height: 6),
                  _MagnetControls(
                    attract: _attract,
                    english: _english,
                    onPolarity: _togglePolarity,
                    onReset: _resetPuck,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _english
                        ? 'Drag the horseshoe magnet through the arena; switch N/S to pull or push. The puck keeps its momentum.'
                        : 'At nalı mıknatısı sahnede sürükle; çekmek/itmek için K/G kutbunu değiştir. Bilye ivmesini korur.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: StudioVisuals.muted, fontSize: 9, height: 1.2, fontWeight: FontWeight.w700),
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

class _MagnetHud extends StatelessWidget {
  const _MagnetHud({required this.passed, required this.total, required this.collisions, required this.collisionLimit, required this.english});

  final int passed;
  final int total;
  final int collisions;
  final int collisionLimit;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey<String>('magnet_path_hud'),
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(color: StudioVisuals.surface, borderRadius: BorderRadius.circular(17), border: Border.all(color: StudioVisuals.line), boxShadow: StudioVisuals.softShadow),
    child: Row(children: <Widget>[
      Expanded(child: _MagnetMetric(label: english ? 'GATES' : 'KAPILAR', value: '$passed / $total', icon: Icons.radio_button_checked_rounded, color: const Color(0xFFD6AF69))),
      Container(width: 1, height: 28, color: StudioVisuals.line),
      Expanded(child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        Text(english ? 'IMPACTS' : 'ÇARPIŞMA', style: const TextStyle(color: StudioVisuals.muted, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: .3)),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List<Widget>.generate(collisionLimit, (int index) => Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: Icon(Icons.circle_rounded, size: 10, color: index < collisionLimit - collisions ? const Color(0xFFE4927B) : const Color(0xFFE8E3DC))))),
      ])),
      Container(width: 1, height: 28, color: StudioVisuals.line),
      Expanded(child: _MagnetMetric(label: english ? 'FIELD' : 'ALAN', value: english ? 'LIVE' : 'AKTİF', icon: Icons.flare_rounded, color: _MagnetPathPlayPageState._accent)),
    ]),
  );
}

class _MagnetMetric extends StatelessWidget {
  const _MagnetMetric({required this.label, required this.value, required this.icon, required this.color});

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
    Icon(icon, color: color, size: 17),
    const SizedBox(width: 4),
    Flexible(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: StudioVisuals.muted, fontSize: 7.5, fontWeight: FontWeight.w900, letterSpacing: .3)),
      Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _MagnetPathPlayPageState._ink, fontSize: 12, fontWeight: FontWeight.w900)),
    ])),
  ]);
}

class _MagnetControls extends StatelessWidget {
  const _MagnetControls({required this.attract, required this.english, required this.onPolarity, required this.onReset});

  final bool attract;
  final bool english;
  final VoidCallback onPolarity;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => Row(children: <Widget>[
    Expanded(
      child: SizedBox(
        height: 47,
        child: FilledButton.icon(
          key: const ValueKey<String>('magnet_path_polarity'),
          onPressed: onPolarity,
          style: FilledButton.styleFrom(backgroundColor: attract ? const Color(0xFF478D89) : const Color(0xFFD0786B), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
          icon: Icon(attract ? Icons.south_east_rounded : Icons.north_west_rounded, size: 18),
          label: Text(english ? (attract ? 'ATTRACT · N' : 'REPEL · S') : (attract ? 'ÇEK · KUTUP K' : 'İT · KUTUP G'), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900)),
        ),
      ),
    ),
    const SizedBox(width: 8),
    SizedBox(
      height: 47,
      child: OutlinedButton.icon(
        key: const ValueKey<String>('magnet_path_reset'),
        onPressed: onReset,
        style: OutlinedButton.styleFrom(foregroundColor: _MagnetPathPlayPageState._ink, side: const BorderSide(color: StudioVisuals.line), backgroundColor: StudioVisuals.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), padding: const EdgeInsets.symmetric(horizontal: 12)),
        icon: const Icon(Icons.replay_rounded, size: 17),
        label: Text(english ? 'RE-CENTER' : 'YENİDEN', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900)),
      ),
    ),
  ]);
}

class _MagnetPathPainter extends CustomPainter {
  const _MagnetPathPainter({required this.scenario, required this.engine, required this.magnetX, required this.magnetY, required this.worldHeight, required this.attract, required this.collisions, required this.elapsed, required this.paused, required this.english});

  final MagnetPathScenario scenario;
  final MagnetPathEngine engine;
  final double magnetX;
  final double magnetY;
  final double worldHeight;
  final bool attract;
  final int collisions;
  final double elapsed;
  final bool paused;
  final bool english;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final double height = size.height / size.width;
    canvas.save();
    canvas.scale(size.width, size.width);
    final Rect bounds = Rect.fromLTWH(0, 0, 1, height);
    canvas.drawRRect(RRect.fromRectAndRadius(bounds, const Radius.circular(.045)), Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: <Color>[Color(0xFF354E58), Color(0xFF1D3642), Color(0xFF142C38)]).createShader(bounds));
    final Rect arena = Rect.fromLTRB(.07, .055, .93, height - .055);
    canvas.drawRRect(RRect.fromRectAndRadius(arena, const Radius.circular(.045)), Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: <Color>[Color(0xFF213E49), Color(0xFF18313D)]).createShader(arena));
    canvas.drawRRect(RRect.fromRectAndRadius(arena, const Radius.circular(.045)), Paint()..style = PaintingStyle.stroke..strokeWidth = .006..color = const Color(0xFFA9C7C0).withValues(alpha: .4));

    final Paint grid = Paint()..color = const Color(0xFFB6D0C7).withValues(alpha: .045)..strokeWidth = .0015;
    for (int column = 0; column < 9; column++) {
      final double x = .11 + column * .098;
      canvas.drawLine(Offset(x, .08), Offset(x, height - .08), grid);
    }
    for (int row = 0; row < 12; row++) {
      final double y = .09 + row * .10;
      if (y < height - .08) canvas.drawLine(Offset(.08, y), Offset(.92, y), grid);
    }

    // Sequential gate route is a guide, not a direct-draw solution path.
    final List<MagnetPoint> route = <MagnetPoint>[scenario.start, ...scenario.gates];
    for (int index = engine.nextGate; index < route.length - 1; index++) {
      final MagnetPoint first = route[index];
      final MagnetPoint second = route[index + 1];
      final double y1 = first.y * height;
      final double y2 = second.y * height;
      final Paint pathPaint = Paint()..color = Colors.white.withValues(alpha: .14)..strokeWidth = .003..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(first.x, y1), Offset(second.x, y2), pathPaint);
    }

    for (int index = 0; index < scenario.gates.length; index++) {
      final MagnetPoint gate = scenario.gates[index];
      final Offset center = Offset(gate.x, gate.y * height);
      final bool passed = index < engine.nextGate;
      final bool current = index == engine.nextGate;
      final Color color = passed ? const Color(0xFF71CDB4) : current ? const Color(0xFFF1C777) : const Color(0xFF8CA6A5);
      canvas.drawCircle(center, scenario.gateRadius * 1.22, Paint()..color = color.withValues(alpha: current ? .11 + math.sin(elapsed * 3).abs() * .12 : .06));
      canvas.drawCircle(center, scenario.gateRadius, Paint()..style = PaintingStyle.stroke..strokeWidth = current ? .009 : .005..color = color.withValues(alpha: passed ? .48 : .92));
      canvas.drawCircle(center, scenario.gateRadius * .68, Paint()..style = PaintingStyle.stroke..strokeWidth = .0025..color = color.withValues(alpha: .43));
      _drawText(canvas, (index + 1).toString().padLeft(2, '0'), Offset(center.dx, center.dy), .11, .034, color, FontWeight.w900);
      if (current) {
        canvas.drawCircle(center, .008, Paint()..color = color);
      }
    }

    for (final MagnetBaffle baffle in scenario.baffles) {
      final Offset center = Offset(baffle.x, baffle.y * height);
      canvas.drawCircle(center.translate(.007, .012), baffle.radius * 1.13, Paint()..color = Colors.black.withValues(alpha: .28));
      canvas.drawCircle(center, baffle.radius, Paint()..shader = RadialGradient(center: const Alignment(-.3, -.4), colors: <Color>[const Color(0xFF9CAEB0), const Color(0xFF526B74), const Color(0xFF283F49)]).createShader(Rect.fromCircle(center: center, radius: baffle.radius)));
      canvas.drawCircle(center, baffle.radius * .83, Paint()..style = PaintingStyle.stroke..strokeWidth = .0025..color = const Color(0xFFD4E1D9).withValues(alpha: .42));
      canvas.drawCircle(center, baffle.radius * .33, Paint()..color = const Color(0xFF273B43));
      canvas.drawCircle(center, baffle.radius * .09, Paint()..color = const Color(0xFFE1BE74));
    }

    final Offset puck = Offset(engine.puck.x, engine.puck.y);
    final Offset magnet = Offset(magnetX, magnetY);
    final Color poleColor = attract ? const Color(0xFF83D9C5) : const Color(0xFFFF957F);
    for (int line = 0; line < 7; line++) {
      final double offset = (line - 3) * .022;
      final Path field = Path()
        ..moveTo(magnet.dx - .065, magnet.dy + offset)
        ..cubicTo(magnet.dx - .13, magnet.dy - .13 + offset, puck.dx + .12, puck.dy - .16 + offset, puck.dx, puck.dy);
      canvas.drawPath(field, Paint()..color = poleColor.withValues(alpha: .11 + line % 2 * .035)..style = PaintingStyle.stroke..strokeWidth = .0022);
    }

    // Puck halo and polished ceramic body.
    canvas.drawCircle(puck.translate(.006, .012), .038, Paint()..color = Colors.black.withValues(alpha: .32));
    canvas.drawCircle(puck, .035, Paint()..color = const Color(0xFF58C6B5).withValues(alpha: .18));
    canvas.drawCircle(puck, .026, Paint()..shader = const RadialGradient(center: Alignment(-.34, -.42), colors: <Color>[Color(0xFFFFFFFF), Color(0xFF9DE5D2), Color(0xFF43AFA5), Color(0xFF225F67)], stops: <double>[0, .24, .64, 1]).createShader(Rect.fromCircle(center: puck, radius: .026)));
    canvas.drawCircle(puck, .026, Paint()..style = PaintingStyle.stroke..strokeWidth = .0025..color = Colors.white.withValues(alpha: .72));
    canvas.drawCircle(puck.translate(-.008, -.01), .005, Paint()..color = Colors.white.withValues(alpha: .8));

    // Horseshoe magnet: twin pole shoes, nickel spine and visible N/S legends.
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: magnet.translate(.006, .012), width: .15, height: .135), const Radius.circular(.025)), Paint()..color = Colors.black.withValues(alpha: .27));
    final Rect magnetBody = Rect.fromCenter(center: magnet, width: .15, height: .135);
    canvas.drawRRect(RRect.fromRectAndRadius(magnetBody, const Radius.circular(.025)), Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: <Color>[Color(0xFFECF0E5), Color(0xFF99A9A7), Color(0xFF586F75)]).createShader(magnetBody));
    final RRect inner = RRect.fromRectAndRadius(Rect.fromCenter(center: magnet.translate(0, .004), width: .073, height: .079), const Radius.circular(.018));
    canvas.drawRRect(inner, Paint()..color = const Color(0xFF1C3641));
    final Rect northPole = Rect.fromLTRB(magnet.dx - .075, magnet.dy - .067, magnet.dx - .025, magnet.dy - .023);
    final Rect southPole = Rect.fromLTRB(magnet.dx + .025, magnet.dy - .067, magnet.dx + .075, magnet.dy - .023);
    canvas.drawRRect(RRect.fromRectAndRadius(northPole, const Radius.circular(.012)), Paint()..color = attract ? poleColor : const Color(0xFF6E8793));
    canvas.drawRRect(RRect.fromRectAndRadius(southPole, const Radius.circular(.012)), Paint()..color = attract ? const Color(0xFF708A97) : poleColor);
    _drawText(canvas, 'N', Offset(northPole.center.dx, northPole.center.dy), .035, .026, Colors.white, FontWeight.w900);
    _drawText(canvas, 'S', Offset(southPole.center.dx, southPole.center.dy), .035, .026, Colors.white, FontWeight.w900);
    canvas.drawRRect(RRect.fromRectAndRadius(magnetBody, const Radius.circular(.025)), Paint()..style = PaintingStyle.stroke..strokeWidth = .003..color = const Color(0xFFE0E8DB).withValues(alpha: .66));

    final String polarity = attract ? (english ? 'PULL FIELD' : 'ÇEKİM ALANI') : (english ? 'PUSH FIELD' : 'İTİM ALANI');
    _drawText(canvas, polarity, Offset(magnet.dx, magnet.dy + .092), .23, .027, poleColor, FontWeight.w900);
    if (collisions > 0) {
      _drawText(canvas, english ? 'WATCH THE BAFFLES' : 'KALKANLARI İZLE', Offset(.5, .105), .43, .029, const Color(0xFFE7C47E), FontWeight.w900);
    }
    if (paused) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(.07, .055, .86, height - .11), const Radius.circular(.045)), Paint()..color = const Color(0xD91A303C));
      _drawText(canvas, english ? 'FIELD PAUSED' : 'ALAN DURAKLATILDI', Offset(.5, height * .5), .62, .047, Colors.white, FontWeight.w900);
    }
    canvas.restore();
  }

  void _drawText(Canvas canvas, String text, Offset center, double maxWidth, double fontSize, Color color, FontWeight weight) {
    final TextPainter painter = TextPainter(text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: weight, letterSpacing: .3)), textDirection: TextDirection.ltr, maxLines: 1, ellipsis: '…')..layout(maxWidth: maxWidth);
    painter.paint(canvas, Offset(center.dx - painter.width / 2, center.dy - painter.height / 2));
  }

  @override
  bool shouldRepaint(covariant _MagnetPathPainter oldDelegate) => true;
}
