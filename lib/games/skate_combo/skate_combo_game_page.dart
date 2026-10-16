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
import 'skate_combo_engine.dart';
import 'skate_combo_scenario.dart';

class SkateComboGamePage extends StatelessWidget {
  const SkateComboGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  static const int totalCases = SkateComboScenario.campaignLevels;
  static const int totalStars = totalCases * 3;

  static final List<ParkurLevelSpec> _levels = List<ParkurLevelSpec>.generate(
    totalCases,
    (int index) {
      final int level = index + 1;
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Parkur ${level.toString().padLeft(2, '0')}',
        titleEn: 'Skate Line ${level.toString().padLeft(2, '0')}',
        subtitleTr: switch (level) {
          <= 3 => 'Rampaya zamanında bas; dönüşü tamamla ve dengeli in.',
          <= 6 => 'İki dönüş yönü ve daha dar iniş penceresini eşleştir.',
          7 || 8 => 'İleri: uzun combo, kısa uçuş ve ardışık rampa.',
          9 => 'Uzman: üç tur dönüş ve hassas gövde dengesi.',
          _ => 'Usta finali: dört tur, kısa uçuş ve tek düşüş hakkı.',
        },
        subtitleEn: switch (level) {
          <= 3 => 'Pump into the ramp, finish the rotation and land balanced.',
          <= 6 =>
            'Match both spin directions through a tighter landing window.',
          7 || 8 => 'Advanced: long combos, short airtime and chained ramps.',
          9 => 'Expert: triple rotations and precise board balance.',
          _ => 'Master finale: four rotations, short airtime and one bail.',
        },
        difficulty: switch (level) {
          <= 3 => 'USTALAŞMA',
          <= 6 => 'DERİNLEŞME',
          7 || 8 => 'İLERİ',
          9 => 'UZMAN',
          _ => 'USTA',
        },
        icon: Icons.skateboarding_rounded,
      );
    },
    growable: false,
  );

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.fun);
    return ParkurLevelHub(
      gameId: 'skate_combo',
      progressPrefix: 'skate_combo',
      titleTr: 'Kaykay Akışı',
      titleEn: 'Skate Flow',
      taglineTr: 'Hızlan • Komboyu çevir • Temiz iniş yap',
      taglineEn: 'Build speed • Spin the combo • Stick the landing',
      accent: skin.accent,
      icon: Icons.skateboarding_rounded,
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
          ) => SkateComboPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class SkateComboPlayPage extends StatefulWidget {
  const SkateComboPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<SkateComboPlayPage> createState() => _SkateComboPlayPageState();
}

class _SkateComboPlayPageState extends State<SkateComboPlayPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const Color _ink = Color(0xFF3D5060);
  static const Color _accent = Color(0xFF4A9994);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.fun,
  );
  late final Ticker _ticker;
  late SkateComboScenario _scenario;
  late SkateComboEngine _engine;
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
        _engine.perfectLandings >= _scenario.jumps.length - 1) {
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
    SkateComboScenario scenario = SkateComboScenario.forLevel(
      widget.level.number,
    );
    try {
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      final String visitKey = 'skate_combo_level_${widget.level.number}_visits';
      final int visits = await preferences.getInt(visitKey) ?? 0;
      if (visits > 0) {
        final int index =
            await preferences.getInt('skate_combo_practice_index') ?? 0;
        if (index < SkateComboScenario.practiceRoutes) {
          final int next = index + 1;
          await preferences.setInt('skate_combo_practice_index', next);
          scenario = SkateComboScenario.forPracticeRoute(next);
        }
      }
      await preferences.setInt(visitKey, visits + 1);
    } catch (_) {
      scenario = SkateComboScenario.forLevel(widget.level.number);
    }
    if (!mounted) return;
    _scenario = scenario;
    _startRun();
    setState(() => _ready = true);
  }

  void _startRun() {
    _ticker.stop();
    _engine = SkateComboEngine(scenario: _scenario);
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
      _session.pause();
      _ticker.stop();
    } else {
      _session.resume();
      _lastTick = Duration.zero;
      _ticker.start();
    }
    unawaited(_audio.play(GameSound.uiClick, gain: .24));
  }

  void _pump() {
    if (!_ready || _paused || _finished) return;
    final SkateInputResult result = _engine.pump();
    switch (result.quality) {
      case SkateActionQuality.perfect:
        _feedback = _english ? 'CLEAN POP' : 'TEMİZ POP';
        _feedbackColor = _accent;
        _session.recordAccepted(points: 35);
        _audio.hapticLight();
        unawaited(
          _audioProfile.play(_audio, GameAudioEvent.accepted, gain: .2),
        );
      case SkateActionQuality.clean:
        _feedback = _english ? 'SPEED UP' : 'HIZ KAZANDIN';
        _feedbackColor = const Color(0xFF638FA3);
        _session.recordAccepted(points: 20);
        unawaited(
          _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .18),
        );
      case SkateActionQuality.early:
        _feedback = _english ? 'TOO EARLY' : 'RAMPA HENÜZ UZAK';
        _feedbackColor = StudioVisuals.muted;
      case SkateActionQuality.late:
        _feedback = _english ? 'POP WINDOW CLOSED' : 'İTİŞ PENCERESİ KAPANDI';
        _feedbackColor = const Color(0xFFD28B55);
      case SkateActionQuality.none ||
          SkateActionQuality.good ||
          SkateActionQuality.bailed:
        break;
    }
    if (mounted && !_finished) setState(() {});
  }

  void _applyTrickGesture(Offset delta, Offset point, Size size) {
    if (!_ready || _paused || _finished || !_engine.airborne) return;
    _engine.addRotation(delta.dx * 5.2);
    _engine.setBalance(
      ((size.height * .5 - point.dy) / (size.height * .42))
          .clamp(-1, 1)
          .toDouble(),
    );
    _feedback = _english
        ? '${_engine.rotation.round()}° · BALANCE ${(100 * _engine.balance).round()}%'
        : '${_engine.rotation.round()}° · DENGE ${(100 * _engine.balance).round()}%';
    _feedbackColor = const Color(0xFFE7BE75);
    if (mounted) setState(() {});
  }

  void _tick(Duration elapsed) {
    if (!_ready || _paused || _finished) return;
    final double raw = (elapsed - _lastTick).inMicroseconds / 1000000;
    _lastTick = elapsed;
    if (raw <= 0) return;
    final SkateStepResult result = _engine.step(raw.clamp(0, .1).toDouble());
    for (int i = 0; i < result.landed; i++) {
      _session.recordAccepted(points: 160);
      unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .2));
      _audio.hapticLight();
      _feedback = _english ? 'STUCK THE LANDING' : 'İNİŞİ KURTARDIN';
      _feedbackColor = _accent;
    }
    for (int i = 0; i < result.bailed; i++) {
      _session.recordMistake();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .2));
      _feedback = _english
          ? 'BAIL · RESET YOUR LINE'
          : 'DÜŞTÜN · YENİDEN TOPARLAN';
      _feedbackColor = const Color(0xFFD16E64);
    }
    if (result.failed) {
      unawaited(_finish(completed: false));
    } else if (result.completed) {
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
              title: Text(_english ? 'Run ended' : 'Koşu sona erdi'),
              content: Text(
                _english
                    ? 'Too many landings missed. Pump before the lip, then match the spin and board level on touchdown.'
                    : 'Düşüş sınırı doldu. Rampadan önce pompalayıp inişte dönüş ve gövde dengesini eşleştir.',
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
        ).pop(StudioGameResult.failed(score: _engine.score).toParkurResult());
      }
      return;
    }

    _session.complete(
      stars: _stars,
      action: widget.level.number < SkateComboGamePage.totalCases
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
      titleTr: 'PARKUR TAMAMLANDI',
      titleEn: 'SKATE LINE COMPLETE',
      detailTr:
          '${_engine.landedCount}/${_scenario.jumps.length} iniş · ${_engine.bestCombo} en uzun combo · hız ${(_engine.speed * 100).round()}%',
      detailEn:
          '${_engine.landedCount}/${_scenario.jumps.length} landings · ${_engine.bestCombo} best combo · speed ${(_engine.speed * 100).round()}%',
      stars: _stars,
      score: _engine.score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < SkateComboGamePage.totalCases,
    );
    if (!mounted) return;
    final StudioResultAction action = switch (result) {
      ParkurResultAction.replay => StudioResultAction.replay,
      ParkurResultAction.next => StudioResultAction.next,
      _ => StudioResultAction.map,
    };
    Navigator.of(context).pop(
      StudioGameResult.completed(
        score: _engine.score,
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
        appBar: AppBar(title: Text(_english ? 'SKATE FLOW' : 'KAYKAY AKIŞI')),
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
          _english ? 'SKATE FLOW' : 'KAYKAY AKIŞI',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('skate_combo_pause'),
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
                  _SkateHud(
                    jump: _engine.jumpIndex.clamp(0, _scenario.jumps.length),
                    total: _scenario.jumps.length,
                    speed: _engine.speed,
                    combo: _engine.combo,
                    misses: _engine.misses,
                    missLimit: _scenario.missLimit,
                  ),
                  const SizedBox(height: 7),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints limits) {
                        final double width = math.min(limits.maxWidth, 640);
                        final double height = math.min(
                          limits.maxHeight,
                          math.max(180, width * .72),
                        );
                        final Size scene = Size(width, height);
                        return Center(
                          child: SizedBox(
                            key: const ValueKey<String>('skate_combo_scene'),
                            width: width,
                            height: height,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanStart: (DragStartDetails details) =>
                                  _applyTrickGesture(
                                    Offset.zero,
                                    details.localPosition,
                                    scene,
                                  ),
                              onPanUpdate: (DragUpdateDetails details) =>
                                  _applyTrickGesture(
                                    details.delta,
                                    details.localPosition,
                                    scene,
                                  ),
                              child: CustomPaint(
                                painter: _SkateScenePainter(
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
                            ? (_english ? 'RUN PAUSED' : 'KOŞU DURAKLATILDI')
                            : _feedback.isNotEmpty
                            ? _feedback
                            : (_engine.airborne
                                  ? (_english
                                        ? 'SWIPE HORIZONTALLY TO SPIN · VERTICALLY TO BALANCE'
                                        : 'DÖNÜŞ İÇİN YATAY · DENGE İÇİN DİKEY SÜRÜKLE')
                                  : (_english
                                        ? 'PUMP in the marked approach window before each ramp'
                                        : 'Her rampadan önce işaretli yaklaşma aralığında POMPALA')),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _feedback.isEmpty || _paused
                              ? StudioVisuals.muted
                              : _feedbackColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  _SkatePumpButton(
                    enabled: !_paused && !_finished,
                    english: _english,
                    speed: _engine.speed,
                    onPressed: _pump,
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

class _SkateHud extends StatelessWidget {
  const _SkateHud({
    required this.jump,
    required this.total,
    required this.speed,
    required this.combo,
    required this.misses,
    required this.missLimit,
  });

  final int jump;
  final int total;
  final double speed;
  final int combo;
  final int misses;
  final int missLimit;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey<String>('skate_combo_hud'),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
    decoration: BoxDecoration(
      color: StudioVisuals.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: StudioVisuals.line),
      boxShadow: StudioVisuals.softShadow,
    ),
    child: Row(
      children: <Widget>[
        _SkateMetric(
          label: 'RAMPA',
          value: '$jump / $total',
          icon: Icons.terrain_rounded,
          color: const Color(0xFF718A99),
        ),
        _divider(),
        _SkateMetric(
          label: 'HIZ',
          value: '${(speed * 100).round()}%',
          icon: Icons.speed_rounded,
          color: const Color(0xFF4A9994),
        ),
        _divider(),
        _SkateMetric(
          label: 'COMBO',
          value: '$combo',
          icon: Icons.bolt_rounded,
          color: const Color(0xFFD49C4A),
        ),
        _divider(),
        _SkateMetric(
          label: 'DÜŞÜŞ',
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

class _SkateMetric extends StatelessWidget {
  const _SkateMetric({
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
                  color: _SkateComboPlayPageState._ink,
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

class _SkatePumpButton extends StatelessWidget {
  const _SkatePumpButton({
    required this.enabled,
    required this.english,
    required this.speed,
    required this.onPressed,
  });
  final bool enabled;
  final bool english;
  final double speed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 66,
    width: double.infinity,
    child: FilledButton(
      key: const ValueKey<String>('skate_combo_pump'),
      onPressed: enabled ? onPressed : null,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF3D666A),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 2,
        shadowColor: const Color(0xFF203546).withValues(alpha: .22),
      ),
      child: Row(
        children: <Widget>[
          const SizedBox(width: 9),
          const Icon(Icons.keyboard_double_arrow_up_rounded, size: 23),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  english ? 'PUMP / POP' : 'POMPALA / SIÇRA',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .4,
                  ),
                ),
                Text(
                  english
                      ? 'Tap in the approach window'
                      : 'Yaklaşma aralığında dokun',
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.white.withValues(alpha: .78),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 72,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  '${(speed * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: speed,
                    minHeight: 4,
                    backgroundColor: Colors.white24,
                    color: const Color(0xFFB1D9C5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    ),
  );
}

class _SkateScenePainter extends CustomPainter {
  const _SkateScenePainter({
    required this.scenario,
    required this.engine,
    required this.paused,
    required this.english,
  });
  final SkateComboScenario scenario;
  final SkateComboEngine engine;
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
            Color(0xFF2D3D49),
            Color(0xFF53616A),
            Color(0xFF33444F),
          ],
        ).createShader(bounds),
    );
    final Paint lights = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-.72, -.8),
        radius: 1,
        colors: <Color>[
          const Color(0xFFD7C49D).withValues(alpha: .18),
          Colors.transparent,
        ],
      ).createShader(bounds);
    canvas.drawRect(bounds, lights);

    final double ground = size.height * .76;
    final Paint concreteLine = Paint()
      ..color = Colors.white.withValues(alpha: .13)
      ..strokeWidth = 1;
    for (int i = 1; i <= 5; i++) {
      final double y = ground + i * size.height * .045;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), concreteLine);
    }
    for (int i = 0; i < 9; i++) {
      final double x = i * size.width / 8;
      canvas.drawLine(
        Offset(x, ground),
        Offset(x - size.width * .08, size.height),
        concreteLine,
      );
    }

    final double pathStart = size.width * .17;
    final double pathEnd = size.width * .94;
    final double scroll = (engine.elapsed * .13) % 1;
    final List<SkateJumpState> states = engine.states;
    for (int i = 0; i < scenario.jumps.length; i++) {
      final SkateJump jump = scenario.jumps[i];
      final double fraction =
          ((jump.takeoffSeconds - engine.elapsed) / 13 + scroll) % 1;
      final double x = pathStart + (pathEnd - pathStart) * fraction;
      if (x < pathStart - 32 || x > size.width + 45) continue;
      _drawRamp(
        canvas,
        Offset(x, ground),
        size,
        jump.feature,
        i + 1,
        states[i],
      );
    }

    final bool airborne = engine.airborne;
    final double boardX = airborne ? size.width * .48 : size.width * .29;
    final double jumpLift = airborne
        ? size.height *
              (.16 +
                  .07 *
                      math.sin(
                        math.pi *
                            (1 -
                                engine.airTimeLeft /
                                    (engine.currentJump?.airtimeSeconds ?? 1)),
                      ))
        : 0;
    final Offset boardCenter = Offset(
      boardX,
      ground - jumpLift - (airborne ? 28 : 0),
    );
    canvas.save();
    canvas.translate(boardCenter.dx, boardCenter.dy);
    canvas.rotate(
      airborne ? engine.rotation * math.pi / 180 : -engine.speed * .035,
    );
    _drawBoard(canvas, size.width * .18);
    _drawSkater(canvas, size.width);
    canvas.restore();

    final double railX = size.width * .70;
    canvas.drawLine(
      Offset(railX, 20),
      Offset(railX, ground - 8),
      Paint()
        ..color = Colors.white.withValues(alpha: .32)
        ..strokeWidth = 1,
    );
    canvas.drawCircle(
      Offset(railX, 23),
      4,
      Paint()..color = const Color(0xFFE3C16F),
    );
    _label(
      canvas,
      airborne
          ? (english ? 'AIR CONTROL' : 'HAVA KONTROLÜ')
          : (english ? 'RAMP LINE' : 'RAMPA HATTI'),
      Offset(14, 14),
      const Color(0xFFE3E8E6),
      9,
      true,
    );
    if (airborne) {
      final double progress =
          1 - engine.airTimeLeft / (engine.currentJump?.airtimeSeconds ?? 1);
      final Rect meter = Rect.fromLTWH(
        14,
        size.height - 20,
        size.width - 28,
        5,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(meter, const Radius.circular(4)),
        Paint()..color = Colors.white.withValues(alpha: .22),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            meter.left,
            meter.top,
            meter.width * progress.clamp(0, 1),
            meter.height,
          ),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xFFE0B96E),
      );
    }
    if (paused) {
      canvas.drawRect(bounds, Paint()..color = const Color(0xBB263743));
      _label(
        canvas,
        'Ⅱ',
        Offset(size.width * .5 - 9, size.height * .48),
        Colors.white,
        34,
        true,
      );
    }
    canvas.restore();
  }

  void _drawRamp(
    Canvas canvas,
    Offset base,
    Size size,
    SkateFeature feature,
    int number,
    SkateJumpState state,
  ) {
    final double w =
        size.width * (feature == SkateFeature.stairGap ? .14 : .105);
    final double h =
        size.height * (feature == SkateFeature.bowlLip ? .20 : .115);
    final Path ramp = Path()
      ..moveTo(base.dx - w * .5, base.dy)
      ..quadraticBezierTo(
        base.dx - w * .05,
        base.dy - h * .2,
        base.dx + w * .5,
        base.dy - h,
      )
      ..lineTo(base.dx + w * .5, base.dy)
      ..close();
    canvas.drawPath(
      ramp.shift(const Offset(0, 4)),
      Paint()..color = const Color(0x55202D35),
    );
    canvas.drawPath(
      ramp,
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[Color(0xFFD0A878), Color(0xFF9C7458)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(base.dx - w * .5, base.dy - h, w, h)),
    );
    canvas.drawPath(
      ramp,
      Paint()
        ..color = const Color(0xFFEDD2A7).withValues(alpha: .6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    final Color stateColor = state == SkateJumpState.landed
        ? const Color(0xFF88C7A9)
        : state == SkateJumpState.bailed
        ? const Color(0xFFD98778)
        : const Color(0xFFE8C27A);
    canvas.drawCircle(
      Offset(base.dx, base.dy - h - 10),
      4,
      Paint()..color = stateColor,
    );
    _label(
      canvas,
      '$number',
      Offset(base.dx - 3, base.dy - h - 25),
      Colors.white.withValues(alpha: .78),
      8,
      true,
    );
  }

  void _drawBoard(Canvas canvas, double width) {
    final Rect deck = Rect.fromCenter(
      center: Offset.zero,
      width: width,
      height: width * .11,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        deck.shift(const Offset(0, 2)),
        Radius.circular(width * .07),
      ),
      Paint()..color = const Color(0x66202A30),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(deck, Radius.circular(width * .07)),
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[
            Color(0xFFDF846D),
            Color(0xFFE5B274),
            Color(0xFF6B8C91),
          ],
        ).createShader(deck),
    );
    canvas.drawLine(
      Offset(-width * .39, 0),
      Offset(width * .39, 0),
      Paint()
        ..color = Colors.white.withValues(alpha: .65)
        ..strokeWidth = 1,
    );
    for (final double x in <double>[-.3, .3]) {
      canvas.drawCircle(
        Offset(x * width, width * .08),
        width * .055,
        Paint()..color = const Color(0xFF303C43),
      );
      canvas.drawCircle(
        Offset(x * width, width * .08),
        width * .022,
        Paint()..color = const Color(0xFFBBC7C7),
      );
    }
  }

  void _drawSkater(Canvas canvas, double width) {
    final double scale = width * .14;
    final Paint suit = Paint()..color = const Color(0xFFE5E9E5);
    final Paint shadow = Paint()..color = const Color(0x55313B42);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, -scale * .08),
        width: scale * .85,
        height: scale * .15,
      ),
      shadow,
    );
    canvas.drawLine(
      Offset(0, -scale * .08),
      Offset(-scale * .1, -scale * .7),
      Paint()
        ..color = const Color(0xFF334B56)
        ..strokeWidth = scale * .12
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(-scale * .12, -scale * .87),
      scale * .16,
      Paint()..color = const Color(0xFFDBA77E),
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(-scale * .12, -scale * .87),
        width: scale * .34,
        height: scale * .28,
      ),
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = const Color(0xFF475A62)
        ..strokeWidth = scale * .08
        ..style = PaintingStyle.stroke,
    );
    canvas.drawLine(
      Offset(-scale * .08, -scale * .48),
      Offset(scale * .26, -scale * .14),
      suit
        ..strokeWidth = scale * .085
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(-scale * .1, -scale * .48),
      Offset(-scale * .42, -scale * .15),
      Paint()
        ..color = const Color(0xFFCBD8D6)
        ..strokeWidth = scale * .08
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(-scale * .1, -scale * .24),
      Offset(-scale * .34, -scale * .01),
      Paint()
        ..color = const Color(0xFFE6B37F)
        ..strokeWidth = scale * .09
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(-scale * .08, -scale * .24),
      Offset(scale * .28, -scale * .02),
      Paint()
        ..color = const Color(0xFF334B56)
        ..strokeWidth = scale * .09
        ..strokeCap = StrokeCap.round,
    );
  }

  void _label(
    Canvas canvas,
    String text,
    Offset offset,
    Color color,
    double size,
    bool bold,
  ) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
          letterSpacing: .35,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_SkateScenePainter oldDelegate) =>
      oldDelegate.engine.elapsed != engine.elapsed ||
      oldDelegate.engine.rotation != engine.rotation ||
      oldDelegate.engine.balance != engine.balance ||
      oldDelegate.paused != paused;
}
