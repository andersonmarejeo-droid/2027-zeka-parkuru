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
import 'rhythm_drums_engine.dart';
import 'rhythm_drums_scenario.dart';

class RhythmDrumsGamePage extends StatelessWidget {
  const RhythmDrumsGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  static const int totalCases = RhythmDrumsScenario.campaignLevels;
  static const int totalStars = totalCases * 3;

  static final List<ParkurLevelSpec>
  _levels = List<ParkurLevelSpec>.generate(totalCases, (int index) {
    final int level = index + 1;
    final String tr = switch (level) {
      <= 3 => 'Dört pedi öğren; vuruş çizgisi hedefe gelince doğru sese bas.',
      <= 6 => 'Aksanları ve kısa ölçü boşluklarını ritmi kaybetmeden izle.',
      7 || 8 => 'İleri: 16’lık senkoplar ve basılı tutulan uzun notalar.',
      9 => 'Uzman: değişen tempo ve art arda sessiz ölçüler.',
      _ => 'Usta finali: 125 BPM, dar zaman penceresi ve iki sessiz ölçü.',
    };
    final String en = switch (level) {
      <= 3 =>
        'Learn four pads; strike the right sound as the beat reaches the rail.',
      <= 6 => 'Read accents and short rests without losing the pulse.',
      7 || 8 => 'Advanced: sixteenth-note syncopation and sustained hits.',
      9 => 'Expert: changing tempo and back-to-back silent bars.',
      _ => 'Master finale: 125 BPM, tight timing and two silent bars.',
    };
    return ParkurLevelSpec(
      number: level,
      titleTr: 'Ritim Etabı ${level.toString().padLeft(2, '0')}',
      titleEn: 'Rhythm Set ${level.toString().padLeft(2, '0')}',
      subtitleTr: tr,
      subtitleEn: en,
      difficulty: switch (level) {
        <= 3 => 'USTALAŞMA',
        <= 6 => 'DERİNLEŞME',
        7 || 8 => 'İLERİ',
        9 => 'UZMAN',
        _ => 'USTA',
      },
      icon: Icons.graphic_eq_rounded,
    );
  }, growable: false);

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.fun);
    return ParkurLevelHub(
      gameId: 'rhythm_drums',
      progressPrefix: 'rhythm_drums',
      titleTr: 'Ritim Atölyesi',
      titleEn: 'Rhythm Workshop',
      taglineTr: 'Ölçüyü duy • Vuruşu yakala • Seriyi koru',
      taglineEn: 'Read the bar • Catch the beat • Keep the combo',
      accent: skin.accent,
      icon: Icons.graphic_eq_rounded,
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
          ) => RhythmDrumsPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class RhythmDrumsPlayPage extends StatefulWidget {
  const RhythmDrumsPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<RhythmDrumsPlayPage> createState() => _RhythmDrumsPlayPageState();
}

class _RhythmDrumsPlayPageState extends State<RhythmDrumsPlayPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const Color _ink = Color(0xFF354B5C);
  static const Color _teal = Color(0xFF438F8D);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.fun,
  );
  final Map<int, DrumLane> _activePointers = <int, DrumLane>{};
  final Set<DrumLane> _pressedLanes = <DrumLane>{};
  late final Ticker _ticker;
  late RhythmDrumsScenario _scenario;
  late RhythmDrumsEngine _engine;
  late StudioGameSession _session;
  Duration _lastTick = Duration.zero;
  bool _ready = false;
  bool _paused = false;
  bool _finished = false;
  bool _english = false;
  String _feedback = '';
  Color _feedbackColor = _teal;

  double get _accuracy => _engine.accuracy;

  int get _stars {
    if (_engine.misses == 0 && _accuracy >= _scenario.goldAccuracy) return 3;
    if (_accuracy >= .68 && _engine.misses <= 1) return 2;
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
    RhythmDrumsScenario scenario = RhythmDrumsScenario.forLevel(
      widget.level.number,
    );
    try {
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      final String visitKey =
          'rhythm_drums_level_${widget.level.number}_visits';
      final int visits = await preferences.getInt(visitKey) ?? 0;
      if (visits > 0) {
        final int index =
            await preferences.getInt('rhythm_drums_practice_index') ?? 0;
        if (index < RhythmDrumsScenario.practicePatterns) {
          final int next = index + 1;
          await preferences.setInt('rhythm_drums_practice_index', next);
          scenario = RhythmDrumsScenario.forPracticePattern(next);
        }
      }
      await preferences.setInt(visitKey, visits + 1);
    } catch (_) {
      scenario = RhythmDrumsScenario.forLevel(widget.level.number);
    }
    if (!mounted) return;
    _scenario = scenario;
    _startRound();
    setState(() => _ready = true);
  }

  void _startRound() {
    _ticker.stop();
    _engine = RhythmDrumsEngine(scenario: _scenario);
    _activePointers.clear();
    _pressedLanes.clear();
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
      _activePointers.clear();
      _pressedLanes.clear();
    });
    if (paused) {
      _engine.interruptHold();
      _session.pause();
      _ticker.stop();
    } else {
      _session.resume();
      _lastTick = Duration.zero;
      _ticker.start();
    }
    unawaited(_audio.play(GameSound.uiClick, gain: .24));
  }

  void _pressLane(int pointer, DrumLane lane) {
    if (!_ready ||
        _paused ||
        _finished ||
        _activePointers.containsKey(pointer)) {
      return;
    }
    _activePointers[pointer] = lane;
    _pressedLanes.add(lane);
    final RhythmInputResult result = _engine.hitLane(lane);
    _handleInput(result);
    if (mounted && !_finished) setState(() {});
  }

  void _releasePointer(int pointer) {
    final DrumLane? lane = _activePointers.remove(pointer);
    if (lane == null) return;
    _pressedLanes.remove(lane);
    if (_ready && !_paused && !_finished) {
      final RhythmInputResult result = _engine.releaseLane(lane);
      _handleInput(result);
    }
    if (mounted && !_finished) setState(() {});
  }

  void _handleInput(RhythmInputResult result) {
    switch (result.quality) {
      case RhythmHitQuality.perfect:
        _feedback = _english ? 'PERFECT' : 'MÜKEMMEL';
        _feedbackColor = const Color(0xFF4A9C8C);
        _session.recordAccepted(points: 100);
        unawaited(
          _audioProfile.play(_audio, GameAudioEvent.accepted, gain: .24),
        );
        _audio.hapticLight();
      case RhythmHitQuality.good:
        _feedback = _english ? 'ON BEAT' : 'TAM ZAMANINDA';
        _feedbackColor = const Color(0xFF5985A4);
        _session.recordAccepted(points: 70);
        unawaited(
          _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .19),
        );
        _audio.hapticSelection();
      case RhythmHitQuality.holdStarted:
        _feedback = _english ? 'HOLD…' : 'BASILI TUT…';
        _feedbackColor = const Color(0xFF657DB0);
        unawaited(
          _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .16),
        );
      case RhythmHitQuality.missed || RhythmHitQuality.wrongLane:
        _feedback = _english ? 'MISS' : 'KAÇTI';
        _feedbackColor = const Color(0xFFD16E64);
        _session.recordMistake();
        unawaited(
          _audioProfile.play(_audio, GameAudioEvent.rejected, gain: .2),
        );
      case RhythmHitQuality.none:
        break;
    }
    if (result.failed) unawaited(_finish(completed: false));
  }

  void _tick(Duration elapsed) {
    if (!_ready || _paused || _finished) return;
    final double raw = (elapsed - _lastTick).inMicroseconds / 1000000;
    _lastTick = elapsed;
    if (raw <= 0) return;
    final RhythmStepResult result = _engine.step(raw.clamp(0, .1).toDouble());
    for (int i = 0; i < result.missed; i++) {
      _session.recordMistake();
    }
    if (result.missed > 0) {
      _feedback = _english ? 'KEEP THE PULSE' : 'ÖLÇÜYÜ KORU';
      _feedbackColor = const Color(0xFFD16E64);
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .14));
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
              title: Text(_english ? 'Set ended' : 'Etap tamamlanamadı'),
              content: Text(
                _english
                    ? 'Too many beats slipped away. Listen for the count-in, then try the pattern again.'
                    : 'Hata sınırı doldu. Ölçüyü sayıp bu deseni yeniden deneyebilirsin.',
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
        Navigator.of(
          context,
        ).pop(StudioGameResult.failed(score: _engine.score).toParkurResult());
      }
      return;
    }

    _session.complete(
      stars: _stars,
      action: widget.level.number < RhythmDrumsGamePage.totalCases
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
      titleTr: 'RİTİM ETABI TAMAMLANDI',
      titleEn: 'RHYTHM SET COMPLETE',
      detailTr:
          '${_engine.perfectHits} mükemmel · ${_engine.bestCombo} en uzun seri · ${(100 * _accuracy).round()}% isabet',
      detailEn:
          '${_engine.perfectHits} perfect · ${_engine.bestCombo} best combo · ${(100 * _accuracy).round()}% accuracy',
      stars: _stars,
      score: _engine.score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < RhythmDrumsGamePage.totalCases,
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
        appBar: AppBar(
          title: Text(_english ? 'RHYTHM WORKSHOP' : 'RİTİM ATÖLYESİ'),
        ),
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
          _english ? 'RHYTHM WORKSHOP' : 'RİTİM ATÖLYESİ',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('rhythm_drums_pause'),
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
                  _RhythmHud(
                    bpm: _scenario.bpm,
                    bar: _engine.currentBar.clamp(1, _scenario.totalBeats ~/ 4),
                    totalBars: _scenario.totalBeats ~/ 4,
                    combo: _engine.combo,
                    misses: _engine.misses,
                    missLimit: _scenario.missLimit,
                    english: _english,
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints limits) {
                        final double width = math.min(limits.maxWidth, 640);
                        final double height = math.min(
                          limits.maxHeight,
                          math.max(176, width * .77),
                        );
                        return Center(
                          child: SizedBox(
                            key: const ValueKey<String>('rhythm_drums_scene'),
                            width: width,
                            height: height,
                            child: CustomPaint(
                              painter: _RhythmScenePainter(
                                scenario: _scenario,
                                engine: _engine,
                                paused: _paused,
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
                            ? (_english ? 'SET PAUSED' : 'ETAP DURAKLATILDI')
                            : _feedback.isNotEmpty
                            ? _feedback
                            : (_english
                                  ? 'Tap on the rail • hold long notes to their tail'
                                  : 'Vuruş çizgideyken bas • uzun notada kuyruğa kadar tut'),
                        key: const ValueKey<String>('rhythm_drums_feedback'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _feedback.isEmpty || _paused
                              ? StudioVisuals.muted
                              : _feedbackColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .25,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  SizedBox(
                    height: 69,
                    child: Row(
                      children: DrumLane.values
                          .map(
                            (DrumLane lane) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                child: _DrumPad(
                                  lane: lane,
                                  english: _english,
                                  pressed: _pressedLanes.contains(lane),
                                  enabled: !_paused && !_finished,
                                  onDown: (int pointer) =>
                                      _pressLane(pointer, lane),
                                  onUp: _releasePointer,
                                ),
                              ),
                            ),
                          )
                          .toList(growable: false),
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

class _RhythmHud extends StatelessWidget {
  const _RhythmHud({
    required this.bpm,
    required this.bar,
    required this.totalBars,
    required this.combo,
    required this.misses,
    required this.missLimit,
    required this.english,
  });

  final int bpm;
  final int bar;
  final int totalBars;
  final int combo;
  final int misses;
  final int missLimit;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey<String>('rhythm_drums_hud'),
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
    decoration: BoxDecoration(
      color: StudioVisuals.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: StudioVisuals.line),
      boxShadow: StudioVisuals.softShadow,
    ),
    child: Row(
      children: <Widget>[
        _RhythmMetric(
          label: english ? 'BPM' : 'TEMPO',
          value: '$bpm',
          icon: Icons.speed_rounded,
          color: const Color(0xFF5985A4),
        ),
        _divider(),
        _RhythmMetric(
          label: english ? 'BAR' : 'ÖLÇÜ',
          value: '$bar / $totalBars',
          icon: Icons.graphic_eq_rounded,
          color: _RhythmScenePainter._colors[1],
        ),
        _divider(),
        _RhythmMetric(
          label: english ? 'COMBO' : 'SERİ',
          value: '$combo',
          icon: Icons.bolt_rounded,
          color: const Color(0xFFD49C4A),
        ),
        _divider(),
        _RhythmMetric(
          label: english ? 'MISSES' : 'HATA',
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

class _RhythmMetric extends StatelessWidget {
  const _RhythmMetric({
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
                  color: _RhythmDrumsPlayPageState._ink,
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

class _DrumPad extends StatelessWidget {
  const _DrumPad({
    required this.lane,
    required this.english,
    required this.pressed,
    required this.enabled,
    required this.onDown,
    required this.onUp,
  });

  final DrumLane lane;
  final bool english;
  final bool pressed;
  final bool enabled;
  final ValueChanged<int> onDown;
  final ValueChanged<int> onUp;

  Color get _color => _RhythmScenePainter._colors[lane.index];

  String get _label => switch (lane) {
    DrumLane.kick => english ? 'KICK' : 'BAS',
    DrumLane.snare => english ? 'SNARE' : 'TRAMPET',
    DrumLane.hiHat => english ? 'HI-HAT' : 'ZİL',
    DrumLane.tom => 'TOM',
  };

  IconData get _icon => switch (lane) {
    DrumLane.kick => Icons.circle_rounded,
    DrumLane.snare => Icons.album_rounded,
    DrumLane.hiHat => Icons.graphic_eq_rounded,
    DrumLane.tom => Icons.radio_button_checked_rounded,
  };

  @override
  Widget build(BuildContext context) => Semantics(
    key: ValueKey<String>('rhythm_drums_pad_${lane.name}'),
    container: true,
    button: true,
    label: _label,
    child: Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: enabled
          ? (PointerDownEvent event) => onDown(event.pointer)
          : null,
      onPointerUp: enabled
          ? (PointerUpEvent event) => onUp(event.pointer)
          : null,
      onPointerCancel: enabled
          ? (PointerCancelEvent event) => onUp(event.pointer)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, pressed ? 2 : 0, 0),
        decoration: BoxDecoration(
          color: pressed ? _color.withValues(alpha: .22) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: pressed ? _color : StudioVisuals.line,
            width: pressed ? 1.7 : 1,
          ),
          boxShadow: pressed
              ? <BoxShadow>[]
              : <BoxShadow>[
                  BoxShadow(
                    color: const Color(0xFF233C4B).withValues(alpha: .09),
                    blurRadius: 9,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: _color.withValues(alpha: .08),
                    blurRadius: 14,
                    spreadRadius: -2,
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(_icon, color: _color, size: 19),
            const SizedBox(height: 4),
            Text(
              _label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFF4B606E),
                fontSize: english ? 8 : 8.5,
                fontWeight: FontWeight.w900,
                letterSpacing: .2,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _RhythmScenePainter extends CustomPainter {
  const _RhythmScenePainter({
    required this.scenario,
    required this.engine,
    required this.paused,
  });

  static const List<Color> _colors = <Color>[
    Color(0xFF62B8AD),
    Color(0xFFE18C78),
    Color(0xFFE4BC69),
    Color(0xFF8297D0),
  ];
  static const List<String> _names = <String>['KICK', 'SNARE', 'HI-HAT', 'TOM'];
  static const double _hitLine = .22;
  static const double _windowSeconds = 2.65;

  final RhythmDrumsScenario scenario;
  final RhythmDrumsEngine engine;
  final bool paused;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    final RRect outer = RRect.fromRectAndRadius(
      bounds,
      const Radius.circular(22),
    );
    canvas.save();
    canvas.clipRRect(outer);
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF142A3A),
            Color(0xFF1C3548),
            Color(0xFF243E50),
          ],
        ).createShader(bounds),
    );

    final Paint sheen = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-.92, -.94),
        radius: 1.25,
        colors: <Color>[
          const Color(0xFF6FA9B2).withValues(alpha: .20),
          Colors.transparent,
        ],
      ).createShader(bounds);
    canvas.drawRect(bounds, sheen);

    final double rowHeight = size.height / 4;
    for (int lane = 0; lane < 4; lane++) {
      final double top = lane * rowHeight;
      final Rect row = Rect.fromLTWH(0, top, size.width, rowHeight);
      canvas.drawRect(
        row,
        Paint()
          ..color = _colors[lane].withValues(alpha: lane.isEven ? .065 : .095),
      );
      if (lane > 0) {
        canvas.drawLine(
          Offset(14, top),
          Offset(size.width - 14, top),
          Paint()
            ..color = Colors.white.withValues(alpha: .095)
            ..strokeWidth = 1,
        );
      }
      _drawLabel(
        canvas,
        _names[lane],
        Offset(13, top + 8),
        color: _colors[lane].withValues(alpha: .78),
        size: 8,
        weight: FontWeight.w900,
        letterSpacing: .6,
      );
    }

    final double beatPosition = engine.beatPosition;
    final int firstBeat = math.max(0, beatPosition.floor() - 1);
    final int lastBeat =
        (beatPosition + _windowSeconds / scenario.secondsPerBeat).ceil();
    for (int beat = firstBeat; beat <= lastBeat; beat++) {
      final double x = _xForTime(beat * scenario.secondsPerBeat, size.width);
      if (x < 1 || x > size.width) continue;
      final bool barStart = beat % 4 == 0;
      canvas.drawLine(
        Offset(x, 24),
        Offset(x, size.height - 8),
        Paint()
          ..color = Colors.white.withValues(alpha: barStart ? .18 : .075)
          ..strokeWidth = barStart ? 1.2 : .7,
      );
      if (barStart) {
        _drawLabel(
          canvas,
          'M${beat ~/ 4 + 1}',
          Offset(x + 4, 7),
          color: Colors.white.withValues(alpha: .54),
          size: 8,
          weight: FontWeight.w800,
          letterSpacing: .3,
        );
      }
    }

    final double railX = size.width * _hitLine;
    final Rect rail = Rect.fromLTWH(railX - 1, 18, 2, size.height - 27);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rail.inflate(5), const Radius.circular(4)),
      Paint()..color = const Color(0xFF8BD5C8).withValues(alpha: .12),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rail, const Radius.circular(3)),
      Paint()..color = const Color(0xFF9FE1D5),
    );
    for (int lane = 0; lane < 4; lane++) {
      final double cy = (lane + .5) * rowHeight;
      canvas.drawCircle(
        Offset(railX, cy),
        5,
        Paint()
          ..color = _colors[lane]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    final List<RhythmNoteState> states = engine.states;
    for (int index = 0; index < scenario.notes.length; index++) {
      final RhythmNote note = scenario.notes[index];
      final RhythmNoteState state = states[index];
      if (state != RhythmNoteState.pending &&
          state != RhythmNoteState.holding) {
        continue;
      }
      final double noteTime = note.beat * scenario.secondsPerBeat;
      final double x = _xForTime(noteTime, size.width);
      final double cy = (note.lane.index + .5) * rowHeight;
      final double radius = note.kind == DrumNoteKind.accent ? 12 : 9.5;
      if (note.kind == DrumNoteKind.hold) {
        final double tail =
            note.holdBeats *
            scenario.secondsPerBeat /
            _windowSeconds *
            (size.width * (1 - _hitLine));
        final Rect hold = Rect.fromLTWH(x - tail, cy - 5, tail + radius, 10);
        canvas.drawRRect(
          RRect.fromRectAndRadius(hold, const Radius.circular(6)),
          Paint()..color = _colors[note.lane.index].withValues(alpha: .55),
        );
      }
      canvas.drawCircle(
        Offset(x, cy + 2),
        radius + 3,
        Paint()..color = _colors[note.lane.index].withValues(alpha: .14),
      );
      canvas.drawCircle(
        Offset(x, cy),
        radius,
        Paint()
          ..shader =
              RadialGradient(
                center: const Alignment(-.35, -.45),
                colors: <Color>[
                  Color.lerp(_colors[note.lane.index], Colors.white, .48)!,
                  _colors[note.lane.index],
                  Color.lerp(
                    _colors[note.lane.index],
                    const Color(0xFF203546),
                    .25,
                  )!,
                ],
              ).createShader(
                Rect.fromCircle(center: Offset(x, cy), radius: radius),
              ),
      );
      canvas.drawCircle(
        Offset(x - radius * .32, cy - radius * .34),
        radius * .2,
        Paint()..color = Colors.white.withValues(alpha: .82),
      );
      if (note.kind == DrumNoteKind.accent) {
        canvas.drawCircle(
          Offset(x, cy),
          radius + 3,
          Paint()
            ..color = Colors.white.withValues(alpha: .76)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
      }
    }

    if (paused) {
      canvas.drawRect(bounds, Paint()..color = const Color(0xCC142A3A));
      _drawLabel(
        canvas,
        'Ⅱ',
        Offset(size.width * .5 - 9, size.height * .5 - 20),
        color: Colors.white,
        size: 32,
        weight: FontWeight.w800,
      );
    }
    canvas.restore();
  }

  double _xForTime(double time, double width) =>
      width * _hitLine +
      (time - engine.elapsed) / _windowSeconds * (width * (1 - _hitLine));

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset position, {
    required Color color,
    required double size,
    required FontWeight weight,
    double letterSpacing = 0,
  }) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
          letterSpacing: letterSpacing,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    painter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(_RhythmScenePainter oldDelegate) =>
      oldDelegate.engine.elapsed != engine.elapsed ||
      oldDelegate.paused != paused ||
      oldDelegate.engine.states != engine.states;
}
