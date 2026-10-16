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
import 'drift_league_engine.dart';
import 'drift_league_scenario.dart';

class DriftLeagueGamePage extends StatelessWidget {
  const DriftLeagueGamePage({super.key});

  static const int totalCases = DriftLeagueScenario.campaignLevels;
  static const int totalStars = totalCases * 3;

  static final List<ParkurLevelSpec> _levels = List<ParkurLevelSpec>.generate(
    totalCases,
    (int index) {
      final int level = index + 1;
      final String number = level.toString().padLeft(2, '0');
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Pist $number',
        titleEn: 'Circuit $number',
        subtitleTr: switch (level) {
          <= 3 => 'Virajı oku; çizgide kal ve kontrollü kaymayı dene.',
          <= 6 => 'Yüzey tutuşu değişirken fren ve el frenini ayır.',
          7 || 8 => 'İleri: daha dar kapılar ve uzun drift zinciri.',
          9 || 10 => 'Uzman: dar çizgi, az toparlanma ve keskin viraj.',
          <= 16 => 'Usta çizgisi: farklı zeminleri ve kapı sırasını birleştir.',
          _ => 'Final etabı: uzun çizgi, hassas kapılar, yüksek drift hedefi.',
        },
        subtitleEn: switch (level) {
          <= 3 => 'Read the turn, stay on line and learn a controlled slide.',
          <= 6 => 'Separate braking from handbrake as grip changes.',
          7 || 8 => 'Advanced: tighter gates and a longer drift chain.',
          9 || 10 => 'Expert: narrow line, fewer recoveries and sharper turns.',
          <= 16 => 'Master the line by combining surfaces and gate order.',
          _ => 'Final stage: precise gates, sustained drift and clean control.',
        },
        difficulty: switch (level) {
          <= 3 => 'ISINMA',
          <= 6 => 'GELİŞİM',
          7 || 8 => 'İLERİ',
          9 || 10 => 'UZMAN',
          <= 16 => 'USTA',
          _ => 'FİNAL',
        },
        icon: Icons.sports_motorsports_rounded,
      );
    },
    growable: false,
  );

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.fun);
    return ParkurLevelHub(
      gameId: 'drift_league',
      progressPrefix: 'drift_league',
      titleTr: 'Drift Ligi',
      titleEn: 'Drift League',
      taglineTr: 'Virajı oku • Freni ayarla • Çizgiyi koru',
      taglineEn: 'Read the corner • Brake with intent • Hold your line',
      accent: skin.accent,
      icon: Icons.sports_motorsports_rounded,
      levels: _levels,
      dailyCourseMode: false,
      playBuilder:
          (
            BuildContext context,
            ParkurLevelSpec level,
            int previousBestScore,
            int? competitionLayoutCode,
            bool competitionMode,
          ) => DriftLeagueRunPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class DriftLeagueRunPage extends StatefulWidget {
  const DriftLeagueRunPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<DriftLeagueRunPage> createState() => _DriftLeagueRunPageState();
}

class _DriftLeagueRunPageState extends State<DriftLeagueRunPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const Color _accent = Color(0xFF278E82);
  static const Color _amber = Color(0xFFD7A04D);
  static const Color _ink = Color(0xFF40535D);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.fun,
  );
  late final Ticker _ticker;
  late DriftLeagueScenario _scenario;
  late DriftLeagueEngine _engine;
  late StudioGameSession _session;
  Duration _lastTick = Duration.zero;
  bool _ready = false;
  bool _paused = false;
  bool _finished = false;
  bool _english = false;
  bool _handbrake = false;
  bool _braking = false;
  double _steering = 0;
  String _feedback = '';
  bool _previouslyDrifting = false;

  int get _stars {
    if (_engine.recoveries == 0 &&
        _engine.driftScore >= _scenario.targetDriftScore &&
        _engine.elapsedSeconds <= _scenario.goldTimeSeconds) {
      return 3;
    }
    if (_engine.recoveries <= 1) return 2;
    return 1;
  }

  int get _score =>
      (_engine.driftScore * 10 +
              _engine.checkpointsPassed * 100 +
              math.max(
                0,
                (_scenario.goldTimeSeconds - _engine.elapsedSeconds) * 20,
              ))
          .round()
          .clamp(0, 10000000)
          .toInt();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_tick);
    unawaited(_audioProfile.preload(_audio));
    unawaited(_prepareScenario());
  }

  Future<void> _prepareScenario() async {
    DriftLeagueScenario scenario = DriftLeagueScenario.forLevel(
      widget.level.number,
    );
    try {
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      final String visitKey =
          'drift_league_level_${widget.level.number}_visits';
      final int visits = await preferences.getInt(visitKey) ?? 0;
      if (visits > 0) {
        final int practiceIndex =
            await preferences.getInt('drift_league_practice_index') ?? 0;
        if (practiceIndex < DriftLeagueScenario.practiceRoutes) {
          final int next = practiceIndex + 1;
          await preferences.setInt('drift_league_practice_index', next);
          scenario = DriftLeagueScenario.forPracticeRoute(next);
        }
      }
      await preferences.setInt(visitKey, visits + 1);
    } catch (_) {
      // Test host or restricted storage falls back to the deterministic course.
    }
    if (!mounted) return;
    _scenario = scenario;
    _startRun();
    setState(() => _ready = true);
  }

  void _startRun() {
    _ticker.stop();
    _engine = DriftLeagueEngine(scenario: _scenario);
    _session = StudioGameSession(
      level: widget.level.number,
      seed: _scenario.seed,
    )..start();
    _lastTick = Duration.zero;
    _paused = false;
    _finished = false;
    _steering = 0;
    _handbrake = false;
    _braking = false;
    _feedback = '';
    _previouslyDrifting = false;
    _ticker.start();
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

  void _setPaused(bool value) {
    if (!_ready || _finished || _paused == value) return;
    setState(() {
      _paused = value;
      _steering = 0;
      _handbrake = false;
      _braking = false;
    });
    if (value) {
      _session.pause();
    } else {
      _session.resume();
      _lastTick = Duration.zero;
    }
    unawaited(_audio.play(GameSound.uiClick, gain: .24));
  }

  void _tick(Duration elapsed) {
    if (!_ready || _paused || _finished) return;
    final double raw = (elapsed - _lastTick).inMicroseconds / 1000000;
    _lastTick = elapsed;
    if (raw <= 0) return;
    final DriftStepResult result = _engine.step(
      deltaSeconds: raw.clamp(0, .05).toDouble(),
      steering: _steering,
      handbrake: _handbrake,
      braking: _braking,
    );
    if (result.passedCheckpoint) {
      _session.recordAccepted(points: 70);
      _feedback = _english
          ? 'GATE ${_engine.checkpointsPassed} CLEARED'
          : 'KAPI ${_engine.checkpointsPassed} GEÇİLDİ';
      unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .18));
      _audio.hapticLight();
    }
    if (_engine.isDrifting && !_previouslyDrifting) {
      unawaited(
        _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .12),
      );
    }
    _previouslyDrifting = _engine.isDrifting;
    if (result.recovered) {
      _session.recordMistake();
      _feedback = _english ? 'BACK ON THE LINE' : 'ÇİZGİYE GERİ DÖNDÜN';
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .16));
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
    _steering = 0;
    _handbrake = false;
    _braking = false;
    if (!completed) {
      final bool retry =
          await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) => AlertDialog(
              title: Text(_english ? 'Run ended' : 'Koşu sona erdi'),
              content: Text(
                _english
                    ? 'Too many off-track recoveries. Brake before the corner and use the handbrake only to hold a controlled slide.'
                    : 'Toparlanma sınırı doldu. Virajdan önce fren yap; el frenini kontrollü kayışta kullan.',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(_english ? 'Circuit map' : 'Pist haritası'),
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
        Navigator.of(context)
            .pop(StudioGameResult.failed(score: _score).toParkurResult());
      }
      return;
    }

    _session.complete(
      stars: _stars,
      action: widget.level.number < DriftLeagueGamePage.totalCases
          ? StudioResultAction.next
          : StudioResultAction.map,
    );
    unawaited(_audioProfile.play(
      _audio,
      GameAudioEvent.levelComplete,
      levelNumber: widget.level.number,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    final ParkurResultAction? result = await showParkurResultDialog(
      context: context,
      accent: _accent,
      titleTr: 'PİST TAMAMLANDI',
      titleEn: 'CIRCUIT COMPLETE',
      detailTr:
          '${_engine.checkpointsPassed}/${_scenario.checkpointCount} kapı · ${_engine.driftScore.round()} drift puanı · ${_engine.recoveries} toparlanma',
      detailEn:
          '${_engine.checkpointsPassed}/${_scenario.checkpointCount} gates · ${_engine.driftScore.round()} drift points · ${_engine.recoveries} recoveries',
      stars: _stars,
      score: _score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < DriftLeagueGamePage.totalCases,
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

  void _steerFrom(Offset localPosition, Size size) {
    if (!_ready || _paused || _finished) return;
    final double normalized = (localPosition.dx / size.width - .5) * 2;
    setState(() => _steering = normalized.clamp(-1, 1).toDouble());
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
        appBar: AppBar(title: Text(_english ? 'DRIFT LEAGUE' : 'DRIFT LİGİ')),
        body: const Center(child: CircularProgressIndicator(color: _accent)),
      );
    }

    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _english ? 'DRIFT LEAGUE' : 'DRIFT LİGİ',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('drift_league_pause'),
            tooltip: _paused
                ? (_english ? 'Resume' : 'Devam et')
                : (_english ? 'Pause' : 'Duraklat'),
            onPressed: () => _setPaused(!_paused),
            icon: Icon(
              _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            ),
          ),
          const SizedBox(width: 7),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 5, 10, 8),
              child: Column(
                children: <Widget>[
                  _DriftHud(
                    gates: _engine.checkpointsPassed,
                    totalGates: _scenario.checkpointCount,
                    speed: _engine.speed,
                    driftScore: _engine.driftScore.round(),
                    target: _scenario.targetDriftScore,
                    english: _english,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints limits) {
                        final double width = math.min(limits.maxWidth, 690);
                        final double height = math.min(limits.maxHeight, width);
                        final Size sceneSize = Size(width, height);
                        return Center(
                          child: SizedBox(
                            key: const ValueKey<String>('drift_league_scene'),
                            width: width,
                            height: height,
                            child: Stack(
                              fit: StackFit.expand,
                              children: <Widget>[
                                CustomPaint(
                                  painter: _DriftScenePainter(
                                    scenario: _scenario,
                                    engine: _engine,
                                    frame: _engine.elapsedSeconds,
                                  ),
                                ),
                                if (_paused)
                                  _DriftPauseOverlay(
                                    english: _english,
                                    onResume: () => _setPaused(false),
                                  ),
                                if (!_paused &&
                                    _engine.projection.distance >
                                        _scenario.trackWidth * .57)
                                  Positioned.fill(
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: SizedBox(
                                        width: sceneSize.width * .38,
                                        height: 45,
                                        child: TextButton.icon(
                                          key: const ValueKey<String>(
                                            'drift_league_recenter',
                                          ),
                                          onPressed: _recenterCar,
                                          icon: const Icon(
                                            Icons.center_focus_strong_rounded,
                                            size: 16,
                                          ),
                                          label: Text(
                                            _english
                                                ? 'REJOIN LINE'
                                                : 'ÇİZGİYE DÖN',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          style: TextButton.styleFrom(
                                            foregroundColor: const Color(
                                              0xFF536873,
                                            ),
                                            backgroundColor: Colors.white
                                                .withValues(alpha: .88),
                                            textStyle: const TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
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
                        _feedback.isNotEmpty
                            ? _feedback
                            : (_english
                                  ? 'AUTO-THROTTLE · STEER ON THE PAD · HOLD DRIFT THROUGH A TURN'
                                  : 'OTOMATİK GAZ · PEDDE YÖN VER · VİRAJDA DRİFTİ BASILI TUT'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _feedback.isEmpty
                              ? StudioVisuals.muted
                              : _accent,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  _DriftControls(
                    english: _english,
                    steering: _steering,
                    handbrake: _handbrake,
                    braking: _braking,
                    enabled: !_paused && !_finished,
                    onSteerStart: _steerFrom,
                    onSteerUpdate: _steerFrom,
                    onSteerEnd: () => setState(() => _steering = 0),
                    onDriftChanged: (bool value) =>
                        setState(() => _handbrake = value),
                    onBrakeChanged: (bool value) =>
                        setState(() => _braking = value),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _recenterCar() {
    if (_paused || _finished) return;
    final Offset tangent = _scenario.tangentAt(_engine.projection.progress);
    _engine
      ..position = _scenario.pointAt(_engine.projection.progress)
      ..heading = math.atan2(tangent.dy, tangent.dx)
      ..velocity = tangent * math.max(.1, _engine.speed * .62)
      ..offTrackSeconds = 0;
    setState(() {
      _feedback = _english ? 'CLEAN LINE, KEEP GOING' : 'ÇİZGİ TEMİZ, DEVAM ET';
      _steering = 0;
      _handbrake = false;
      _braking = false;
    });
    _audio.hapticLight();
  }
}

class _DriftHud extends StatelessWidget {
  const _DriftHud({
    required this.gates,
    required this.totalGates,
    required this.speed,
    required this.driftScore,
    required this.target,
    required this.english,
  });

  final int gates;
  final int totalGates;
  final double speed;
  final int driftScore;
  final int target;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey<String>('drift_league_hud'),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: StudioVisuals.surface,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: StudioVisuals.line),
      boxShadow: StudioVisuals.softShadow,
    ),
    child: Row(
      children: <Widget>[
        _DriftMetric(
          icon: Icons.flag_outlined,
          label: english ? 'GATES' : 'KAPILAR',
          value: '$gates / $totalGates',
          color: const Color(0xFF70899A),
        ),
        _divider(),
        _DriftMetric(
          icon: Icons.speed_rounded,
          label: english ? 'SPEED' : 'HIZ',
          value: '${(speed * 260).round()} km/h',
          color: _DriftLeagueRunPageState._accent,
        ),
        _divider(),
        _DriftMetric(
          icon: Icons.stacked_line_chart_rounded,
          label: english ? 'DRIFT' : 'DRİFT',
          value: '$driftScore / $target',
          color: const Color(0xFFD19A43),
        ),
      ],
    ),
  );

  Widget _divider() => Container(
    width: 1,
    height: 30,
    margin: const EdgeInsets.symmetric(horizontal: 5),
    color: StudioVisuals.line,
  );
}

class _DriftMetric extends StatelessWidget {
  const _DriftMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Row(
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
                  fontSize: 7.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: StudioVisuals.ink,
                  fontSize: 10.5,
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

class _DriftControls extends StatelessWidget {
  const _DriftControls({
    required this.english,
    required this.steering,
    required this.handbrake,
    required this.braking,
    required this.enabled,
    required this.onSteerStart,
    required this.onSteerUpdate,
    required this.onSteerEnd,
    required this.onDriftChanged,
    required this.onBrakeChanged,
  });

  final bool english;
  final double steering;
  final bool handbrake;
  final bool braking;
  final bool enabled;
  final void Function(Offset localPosition, Size size) onSteerStart;
  final void Function(Offset localPosition, Size size) onSteerUpdate;
  final VoidCallback onSteerEnd;
  final ValueChanged<bool> onDriftChanged;
  final ValueChanged<bool> onBrakeChanged;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: !enabled,
    child: SizedBox(
      height: 72,
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return GestureDetector(
                  key: const ValueKey<String>('drift_league_steering'),
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (DragStartDetails details) =>
                      onSteerStart(details.localPosition, constraints.biggest),
                  onPanUpdate: (DragUpdateDetails details) =>
                      onSteerUpdate(details.localPosition, constraints.biggest),
                  onPanEnd: (_) => onSteerEnd(),
                  onPanCancel: onSteerEnd,
                  child: Container(
                    decoration: BoxDecoration(
                      color: StudioVisuals.surface,
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(color: StudioVisuals.line),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Icon(Icons.chevron_left_rounded, size: 19),
                            Transform.rotate(
                              angle: steering * .43,
                              child: const Icon(
                                Icons.radio_button_unchecked_rounded,
                                size: 23,
                                color: _DriftLeagueRunPageState._accent,
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, size: 19),
                          ],
                        ),
                        Text(
                          english ? 'STEER' : 'DİREKSİYON',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: StudioVisuals.ink,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 3,
            child: _HoldControl(
              key: const ValueKey<String>('drift_league_brake'),
              icon: Icons.south_rounded,
              label: english ? 'BRAKE' : 'FREN',
              active: braking,
              activeColor: const Color(0xFFEAF0F3),
              onChanged: onBrakeChanged,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 3,
            child: _HoldControl(
              key: const ValueKey<String>('drift_league_handbrake'),
              icon: Icons.rotate_right_rounded,
              label: english ? 'DRIFT' : 'EL FRENİ',
              active: handbrake,
              activeColor: const Color(0xFFFFF1D9),
              foreground: const Color(0xFF93671E),
              onChanged: onDriftChanged,
            ),
          ),
        ],
      ),
    ),
  );
}

class _HoldControl extends StatelessWidget {
  const _HoldControl({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onChanged,
    this.foreground = StudioVisuals.ink,
  });

  final IconData icon;
  final String label;
  final bool active;
  final Color activeColor;
  final Color foreground;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTapDown: (_) => onChanged(true),
    onTapUp: (_) => onChanged(false),
    onTapCancel: () => onChanged(false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 95),
      decoration: BoxDecoration(
        color: active ? activeColor : StudioVisuals.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: active
              ? foreground.withValues(alpha: .35)
              : StudioVisuals.line,
        ),
        boxShadow: active ? const <BoxShadow>[] : StudioVisuals.softShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, color: foreground, size: 21),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foreground,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    ),
  );
}

class _DriftPauseOverlay extends StatelessWidget {
  const _DriftPauseOverlay({required this.english, required this.onResume});

  final bool english;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xBFEAF0EF),
    alignment: Alignment.center,
    child: Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: StudioVisuals.line),
        boxShadow: StudioVisuals.softShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.pause_circle_filled_rounded,
            color: _DriftLeagueRunPageState._accent,
            size: 42,
          ),
          const SizedBox(height: 8),
          Text(
            english ? 'RUN PAUSED' : 'KOŞU DURAKLATILDI',
            style: const TextStyle(
              color: StudioVisuals.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 13),
          FilledButton.icon(
            onPressed: onResume,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(english ? 'Resume' : 'Devam et'),
            style: FilledButton.styleFrom(
              backgroundColor: _DriftLeagueRunPageState._accent,
            ),
          ),
        ],
      ),
    ),
  );
}

class _DriftScenePainter extends CustomPainter {
  const _DriftScenePainter({
    required this.scenario,
    required this.engine,
    required this.frame,
  });

  final DriftLeagueScenario scenario;
  final DriftLeagueEngine engine;
  final double frame;

  Offset _screen(Offset point, Size size, double unit) => Offset(
    size.width / 2 + (point.dx - .5) * unit,
    size.height / 2 + (point.dy - .5) * unit,
  );

  Path _trackPath(Size size, double unit) {
    final List<Offset> points = scenario.centerline
        .map((Offset point) => _screen(point, size, unit))
        .toList(growable: false);
    final Path path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int index = 0; index < points.length; index++) {
      final Offset current = points[index];
      final Offset next = points[(index + 1) % points.length];
      final Offset middle = Offset.lerp(current, next, .5)!;
      path.quadraticBezierTo(current.dx, current.dy, middle.dx, middle.dy);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double unit = math.min(size.width, size.height);
    final Rect bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFF4F6F1), Color(0xFFE5EBE5)],
        ).createShader(bounds),
    );
    _drawTrack(canvas, size, unit);
    _drawSurfaceWindows(canvas, size, unit);
    _drawLaneMarks(canvas, size, unit);
    _drawCheckpoints(canvas, size, unit);
    _drawCar(canvas, size, unit);
    _drawCornerCompass(canvas, size);
  }

  void _drawTrack(Canvas canvas, Size size, double unit) {
    final Path path = _trackPath(size, unit);
    final double roadWidth = unit * scenario.trackWidth;
    canvas.save();
    canvas.translate(0, 3.5);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = roadWidth + 11
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0x332D3D46),
    );
    canvas.restore();
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = roadWidth + 9
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFFFDFEFC),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = roadWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF556770),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = roadWidth * .76
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF62747C),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x66334149),
    );
  }

  void _drawSurfaceWindows(Canvas canvas, Size size, double unit) {
    for (final DriftSurfaceWindow surface in scenario.surfaces) {
      final Path patch = Path();
      final int steps = math.max(
        2,
        ((surface.end - surface.start) * 56).round(),
      );
      for (int index = 0; index <= steps; index++) {
        final double progress =
            surface.start + (surface.end - surface.start) * index / steps;
        final Offset point = _screen(scenario.pointAt(progress), size, unit);
        if (index == 0) {
          patch.moveTo(point.dx, point.dy);
        } else {
          patch.lineTo(point.dx, point.dy);
        }
      }
      final Color color = switch (surface.kind) {
        1 => const Color(0xFFBBAE91),
        2 => const Color(0xFF668C90),
        _ => const Color(0xFF9AA7A5),
      };
      canvas.drawPath(
        patch,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = unit * scenario.trackWidth * .62
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: .62),
      );
      canvas.drawPath(
        patch,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = unit * scenario.trackWidth * .16
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: .17),
      );
    }
  }

  void _drawLaneMarks(Canvas canvas, Size size, double unit) {
    final Paint paint = Paint()
      ..color = const Color(0x77EAF0EC)
      ..strokeWidth = math.max(1.1, unit * .004)
      ..strokeCap = StrokeCap.round;
    for (int index = 0; index < 24; index++) {
      final double progress = index / 24;
      final Offset center = _screen(scenario.pointAt(progress), size, unit);
      final Offset tangent = scenario.tangentAt(progress);
      final Offset normal = Offset(-tangent.dy, tangent.dx);
      final Offset mark = normal * (unit * scenario.trackWidth * .12);
      canvas.drawLine(center - mark, center + mark, paint);
    }
  }

  void _drawCheckpoints(Canvas canvas, Size size, double unit) {
    for (int index = 0; index < scenario.checkpointCount; index++) {
      final double progress = (index + 1) / scenario.checkpointCount;
      final Offset center = _screen(scenario.pointAt(progress), size, unit);
      final Offset tangent = scenario.tangentAt(progress);
      final Offset normal = Offset(-tangent.dy, tangent.dx);
      final double half = unit * scenario.trackWidth * .42;
      final bool passed = index < engine.checkpointsPassed;
      final bool upcoming = index == engine.checkpointsPassed;
      final Color color = passed
          ? const Color(0xFFB7DED5)
          : upcoming
          ? _DriftLeagueRunPageState._amber
          : const Color(0xFFDCE4E3);
      final Paint gatePaint = Paint()
        ..color = color
        ..strokeWidth = upcoming ? 3.2 : 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        center - normal * half,
        center + normal * half,
        gatePaint,
      );
      if (upcoming) {
        final Paint ring = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = color.withValues(alpha: .58);
        canvas.drawCircle(center, unit * scenario.checkpointRadius * .78, ring);
      }
    }

    final Offset start = _screen(scenario.pointAt(0), size, unit);
    final Offset tangent = scenario.tangentAt(0);
    final Offset normal = Offset(-tangent.dy, tangent.dx);
    final double half = unit * scenario.trackWidth * .48;
    final Paint startPaint = Paint()
      ..color = const Color(0xFFF9FBF8)
      ..strokeWidth = math.max(3, unit * .012)
      ..strokeCap = StrokeCap.butt;
    canvas.drawLine(start - normal * half, start + normal * half, startPaint);
    for (int index = -2; index < 2; index++) {
      final Offset markCenter = start + normal * (index * unit * .022);
      canvas.drawCircle(
        markCenter,
        unit * .006,
        Paint()
          ..color = index.isEven ? _DriftLeagueRunPageState._ink : Colors.white,
      );
    }
  }

  void _drawCar(Canvas canvas, Size size, double unit) {
    final Offset center = _screen(engine.position, size, unit);
    final double length = unit * .091;
    final double width = unit * .048;
    if (engine.isDrifting) {
      final Offset rear =
          center -
          Offset(math.cos(engine.heading), math.sin(engine.heading)) *
              length *
              .53;
      for (int index = 0; index < 3; index++) {
        final double radius = unit * (.018 + index * .008);
        canvas.drawCircle(
          rear + Offset(-index * unit * .008, index * unit * .012),
          radius,
          Paint()
            ..color = const Color(0x1EFAFEFA)
                .withValues(alpha: .42 - index * .1),
        );
      }
    }

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(engine.heading + math.pi / 2);
    final RRect body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: width, height: length),
      Radius.circular(width * .38),
    );
    canvas.drawRRect(
      body.shift(Offset(0, unit * .008)),
      Paint()..color = const Color(0x3A14252C),
    );
    for (final double side in <double>[-1, 1]) {
      for (final double axle in <double>[-.30, .30]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(side * width * .48, axle * length),
              width: width * .20,
              height: length * .22,
            ),
            Radius.circular(width * .08),
          ),
          Paint()..color = const Color(0xFF24333A),
        );
      }
    }
    canvas.drawRRect(body, Paint()..color = const Color(0xFF258E83));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, length * .07),
          width: width * .67,
          height: length * .34,
        ),
        Radius.circular(width * .24),
      ),
      Paint()..color = const Color(0xFFBBD6D4),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, -length * .32),
          width: width * .48,
          height: length * .13,
        ),
        Radius.circular(width * .08),
      ),
      Paint()..color = const Color(0xFFFFF4D9),
    );
    for (final double side in <double>[-1, 1]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(side * width * .30, length * .45),
            width: width * .16,
            height: length * .06,
          ),
          Radius.circular(width * .04),
        ),
        Paint()..color = const Color(0xFFD96767),
      );
    }
    canvas.restore();
  }

  void _drawCornerCompass(Canvas canvas, Size size) {
    final Offset center = Offset(size.width - 23, 23);
    canvas.drawCircle(
      center,
      13,
      Paint()..color = Colors.white.withValues(alpha: .85),
    );
    canvas.drawCircle(
      center,
      13,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFFD8E1DF),
    );
    final double angle = engine.heading;
    final Path pointer = Path()
      ..moveTo(center.dx + math.cos(angle) * 8, center.dy + math.sin(angle) * 8)
      ..lineTo(
        center.dx + math.cos(angle + 2.4) * 4,
        center.dy + math.sin(angle + 2.4) * 4,
      )
      ..lineTo(
        center.dx + math.cos(angle - 2.4) * 4,
        center.dy + math.sin(angle - 2.4) * 4,
      )
      ..close();
    canvas.drawPath(pointer, Paint()..color = _DriftLeagueRunPageState._accent);
  }

  @override
  bool shouldRepaint(covariant _DriftScenePainter oldDelegate) =>
      oldDelegate.frame != frame ||
      oldDelegate.engine.checkpointsPassed != engine.checkpointsPassed ||
      oldDelegate.engine.position != engine.position ||
      oldDelegate.engine.isDrifting != engine.isDrifting ||
      oldDelegate.engine.heading != engine.heading;
}
