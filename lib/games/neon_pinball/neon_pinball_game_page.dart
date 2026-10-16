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
import 'neon_pinball_engine.dart';
import 'neon_pinball_scenario.dart';

class NeonPinballGamePage extends StatelessWidget {
  const NeonPinballGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  static const int totalCases = NeonPinballScenario.campaignLevels;
  static const int totalStars = totalCases * 3;

  static final List<ParkurLevelSpec> _levels = List<ParkurLevelSpec>.generate(
    totalCases,
    (int index) {
      final int level = index + 1;
      final String tr = switch (level) {
        <= 3 => 'Kanat zamanlamasını öğren; ışıklı hedef sırasını izle.',
        <= 6 => 'Bumper sekmelerini kullan, kombo penceresini kaçırma.',
        7 || 8 => 'İleri: hızlı kayan hedefler ve daralan kurtarma açısı.',
        9 => 'Uzman: kilidi açıp iki topu aynı anda yönet.',
        _ => 'Usta finali: 12 hedef, kısa kombo ve çift top masası.',
      };
      final String en = switch (level) {
        <= 3 => 'Learn flipper timing and follow the lit target sequence.',
        <= 6 => 'Use bumper rebounds and protect your combo window.',
        7 || 8 => 'Advanced: fast moving targets and a narrow save angle.',
        9 => 'Expert: release the lock and control two balls at once.',
        _ => 'Master finale: 12 targets, short combos and multiball.',
      };
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Neon Masa ${level.toString().padLeft(2, '0')}',
        titleEn: 'Neon Table ${level.toString().padLeft(2, '0')}',
        subtitleTr: tr,
        subtitleEn: en,
        difficulty: switch (level) {
          <= 3 => 'USTALAŞMA',
          <= 6 => 'DERİNLEŞME',
          7 || 8 => 'İLERİ',
          9 => 'UZMAN',
          _ => 'USTA',
        },
        icon: Icons.sports_esports_rounded,
      );
    },
    growable: false,
  );

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.fun);
    return ParkurLevelHub(
      gameId: 'neon_pinball',
      progressPrefix: 'neon_pinball',
      titleTr: 'Neon Pinball',
      titleEn: 'Neon Pinball',
      taglineTr: 'Kanatları zamanla • Hedef sırasını bozma',
      taglineEn: 'Time the flippers • Keep the target chain',
      accent: skin.accent,
      icon: Icons.sports_esports_rounded,
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
          ) => NeonPinballPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class NeonPinballPlayPage extends StatefulWidget {
  const NeonPinballPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<NeonPinballPlayPage> createState() => _NeonPinballPlayPageState();
}

class _NeonPinballPlayPageState extends State<NeonPinballPlayPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const Color _ink = Color(0xFF32485E);
  static const Color _teal = Color(0xFF33D4C2);
  static const Color _amber = Color(0xFFFFC66D);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.fun,
  );
  late final Ticker _ticker;
  late NeonPinballScenario _scenario;
  late NeonPinballEngine _engine;
  late StudioGameSession _session;
  Duration _lastTick = Duration.zero;
  bool _ready = false;
  bool _paused = false;
  bool _finished = false;
  bool _english = false;

  int get _stars {
    if (_engine.drains == 0 &&
        _engine.wrongTargets <= 1 &&
        _engine.elapsed <= _scenario.goldTimeSeconds) {
      return 3;
    }
    if (_engine.drains <= 1 &&
        _engine.wrongTargets <= 4 &&
        _engine.elapsed <= _scenario.goldTimeSeconds * 1.3) {
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
    NeonPinballScenario scenario = NeonPinballScenario.forLevel(
      widget.level.number,
    );
    try {
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      final String visitKey =
          'neon_pinball_level_${widget.level.number}_visits';
      final int visits = await preferences.getInt(visitKey) ?? 0;
      if (visits > 0) {
        final int index =
            await preferences.getInt('neon_pinball_practice_index') ?? 0;
        if (index < NeonPinballScenario.practiceLayouts) {
          final int next = index + 1;
          await preferences.setInt('neon_pinball_practice_index', next);
          scenario = NeonPinballScenario.forPracticeLayout(next);
        }
      }
      await preferences.setInt(visitKey, visits + 1);
    } catch (_) {
      scenario = NeonPinballScenario.forLevel(widget.level.number);
    }
    if (!mounted) return;
    _scenario = scenario;
    _startGame();
    setState(() => _ready = true);
  }

  void _startGame() {
    _ticker.stop();
    _engine = NeonPinballEngine(scenario: _scenario);
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
      _engine.setFlippers(left: false, right: false);
      _session.pause();
      _ticker.stop();
    } else {
      _session.resume();
      _lastTick = Duration.zero;
      _ticker.start();
    }
    unawaited(_audio.play(GameSound.uiClick, gain: .24));
  }

  void _tick(Duration elapsed) {
    if (!_ready || _paused || _finished) return;
    final double raw = (elapsed - _lastTick).inMicroseconds / 1000000;
    _lastTick = elapsed;
    if (raw <= 0) return;
    final PinballStepResult result = _engine.step(
      raw.clamp(0, .018).toDouble(),
    );
    if (result.targetHit != null) {
      _session.recordAccepted(points: 100 * _engine.currentMultiplier);
      unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .26));
      _audio.hapticLight();
    }
    if (result.wrongTargetHit) {
      _session.recordMistake();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .15));
    }
    if (result.bumperHit || result.flipperHit) {
      unawaited(
        _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .13),
      );
    }
    if (result.drained) {
      _session.recordMistake();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .2));
    }
    if (result.completed) {
      unawaited(_finish(completed: true));
    } else if (result.failed) {
      unawaited(_finish(completed: false));
    }
    if (mounted && !_finished) setState(() {});
  }

  void _launch() {
    if (!_ready || _paused || _finished) return;
    final PinballTarget target = _scenario.targets[_engine.nextTarget];
    final double aim = (target.at(_engine.elapsed).x - .5) * 2.0;
    if (_engine.launch(aim: aim)) {
      setState(() {});
      unawaited(
        _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .18),
      );
      _audio.hapticLight();
    }
  }

  void _setFlipper({required bool left, required bool pressed}) {
    if (!_ready || _paused || _finished) return;
    _engine.setFlippers(
      left: left ? pressed : _engine.leftFlipper,
      right: left ? _engine.rightFlipper : pressed,
    );
    setState(() {});
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
              title: Text(_english ? 'Table drained' : 'Masa boşaldı'),
              content: Text(
                _english
                    ? 'The target chain is incomplete. Relaunch the ball and work the two flippers together?'
                    : 'Hedef zinciri tamamlanmadı. Topu yeniden başlatıp iki kanadı birlikte yönetelim mi?',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(_english ? 'Table map' : 'Bölüm listesi'),
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
        setState(_startGame);
      } else {
        Navigator.of(
          context,
        ).pop(StudioGameResult.failed(score: _engine.score).toParkurResult());
      }
      return;
    }

    _session.complete(
      stars: _stars,
      action: widget.level.number < NeonPinballGamePage.totalCases
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
      titleTr: 'MASA TAMAMLANDI',
      titleEn: 'TABLE COMPLETE',
      detailTr:
          '${_engine.nextTarget}/${_scenario.targets.length} hedef · ${_engine.bestCombo} en iyi kombo · ${_engine.drains} drain.',
      detailEn:
          '${_engine.nextTarget}/${_scenario.targets.length} targets · ${_engine.bestCombo} best combo · ${_engine.drains} drains.',
      stars: _stars,
      score: _engine.score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < NeonPinballGamePage.totalCases,
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
        appBar: AppBar(title: Text(_english ? 'NEON PINBALL' : 'NEON PINBALL')),
        body: const Center(child: CircularProgressIndicator(color: _teal)),
      );
    }
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: _ink,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'NEON PINBALL',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('neon_pinball_pause'),
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
            constraints: const BoxConstraints(maxWidth: 620),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 5, 12, 7),
              child: Column(
                children: <Widget>[
                  _PinballHud(
                    target: _engine.nextTarget,
                    total: _scenario.targets.length,
                    score: _engine.score,
                    balls: _engine.ballsRemaining,
                    combo: _engine.combo,
                    multiplier: _engine.currentMultiplier,
                    multiball: _engine.multiballActive,
                    english: _english,
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints limits) {
                        final double width = math.min(limits.maxWidth, 460);
                        final double height = math.min(
                          limits.maxHeight,
                          width * 1.32,
                        );
                        return Center(
                          child: SizedBox(
                            key: const ValueKey<String>('neon_pinball_scene'),
                            width: width,
                            height: height,
                            child: CustomPaint(
                              painter: _NeonPinballPainter(
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
                  const SizedBox(height: 5),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _FlipperButton(
                          key: const ValueKey<String>('neon_pinball_left'),
                          label: _english ? 'LEFT' : 'SOL',
                          icon: Icons.keyboard_arrow_up_rounded,
                          active: _engine.leftFlipper,
                          enabled:
                              !_paused && !_finished && _engine.orbs.isNotEmpty,
                          onChanged: (bool pressed) =>
                              _setFlipper(left: true, pressed: pressed),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _LaunchButton(
                        key: const ValueKey<String>('neon_pinball_launch'),
                        enabled:
                            !_paused && !_finished && _engine.waitingToLaunch,
                        label: _english ? 'LAUNCH' : 'BAŞLAT',
                        onPressed: _launch,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _FlipperButton(
                          key: const ValueKey<String>('neon_pinball_right'),
                          label: _english ? 'RIGHT' : 'SAĞ',
                          icon: Icons.keyboard_arrow_up_rounded,
                          active: _engine.rightFlipper,
                          enabled:
                              !_paused && !_finished && _engine.orbs.isNotEmpty,
                          onChanged: (bool pressed) =>
                              _setFlipper(left: false, pressed: pressed),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _english
                        ? 'Hold a flipper as the ball arrives; tap LAUNCH between balls.'
                        : 'Top yaklaşırken kanadı basılı tut; toplar arasında BAŞLAT’a dokun.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: StudioVisuals.muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
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

class _PinballHud extends StatelessWidget {
  const _PinballHud({
    required this.target,
    required this.total,
    required this.score,
    required this.balls,
    required this.combo,
    required this.multiplier,
    required this.multiball,
    required this.english,
  });

  final int target;
  final int total;
  final int score;
  final int balls;
  final int combo;
  final int multiplier;
  final bool multiball;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey<String>('neon_pinball_hud'),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: StudioVisuals.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: StudioVisuals.line),
      boxShadow: StudioVisuals.softShadow,
    ),
    child: Row(
      children: <Widget>[
        _HudMetric(
          icon: Icons.radio_button_checked_rounded,
          label: english ? 'NEXT' : 'SIRA',
          value: '${target + 1} / $total',
          color: _NeonPinballPlayPageState._teal,
        ),
        _hudDivider(),
        _HudMetric(
          icon: Icons.stars_rounded,
          label: english ? 'SCORE' : 'PUAN',
          value: score.toString().padLeft(5, '0'),
          color: _NeonPinballPlayPageState._amber,
        ),
        _hudDivider(),
        _HudMetric(
          icon: multiball
              ? Icons.blur_circular_rounded
              : Icons.sports_esports_rounded,
          label: multiball
              ? (english ? 'MULTI' : 'ÇİFT TOP')
              : (combo > 1 ? '×$multiplier' : (english ? 'BALLS' : 'TOP')),
          value: multiball ? '×$multiplier' : '$balls',
          color: multiball ? const Color(0xFFB896FF) : const Color(0xFF7290A2),
        ),
      ],
    ),
  );

  Widget _hudDivider() => Container(
    width: 1,
    height: 27,
    margin: const EdgeInsets.symmetric(horizontal: 3),
    color: StudioVisuals.line,
  );
}

class _HudMetric extends StatelessWidget {
  const _HudMetric({
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
        Icon(icon, size: 15, color: color),
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
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .2,
                  color: StudioVisuals.muted,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: _NeonPinballPlayPageState._ink,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _FlipperButton extends StatelessWidget {
  const _FlipperButton({
    super.key,
    required this.label,
    required this.icon,
    required this.active,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final bool active;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => onChanged(true) : null,
      onTapUp: enabled ? (_) => onChanged(false) : null,
      onTapCancel: enabled ? () => onChanged(false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        height: 47,
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE0F7F3) : StudioVisuals.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: active
                ? _NeonPinballPlayPageState._teal
                : StudioVisuals.line,
            width: active ? 1.6 : 1,
          ),
          boxShadow: active
              ? <BoxShadow>[
                  BoxShadow(
                    color: _NeonPinballPlayPageState._teal.withValues(
                      alpha: .2,
                    ),
                    blurRadius: 9,
                    spreadRadius: 1,
                  ),
                ]
              : StudioVisuals.softShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              size: 20,
              color: enabled ? const Color(0xFF387F81) : StudioVisuals.muted,
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    ),
  );
}

class _LaunchButton extends StatelessWidget {
  const _LaunchButton({
    super.key,
    required this.enabled,
    required this.label,
    required this.onPressed,
  });

  final bool enabled;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 47,
    child: FilledButton(
      onPressed: enabled ? onPressed : null,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF334D61),
        disabledBackgroundColor: const Color(0xFFE7ECEF),
        padding: const EdgeInsets.symmetric(horizontal: 9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.rocket_launch_rounded, size: 17),
          Text(
            label,
            style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    ),
  );
}

class _NeonPinballPainter extends CustomPainter {
  const _NeonPinballPainter({
    required this.scenario,
    required this.engine,
    required this.paused,
    required this.english,
  });

  final NeonPinballScenario scenario;
  final NeonPinballEngine engine;
  final bool paused;
  final bool english;

  static const Color _deep = Color(0xFF142438);
  static const Color _board = Color(0xFF20344A);
  static const Color _teal = Color(0xFF55E5D2);
  static const Color _amber = Color(0xFFFFC66D);
  static const Color _violet = Color(0xFFB795FF);

  Offset _point(Size size, double x, double y) =>
      Offset(size.width * x, size.height * y);

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    final RRect shell = RRect.fromRectAndRadius(
      bounds,
      const Radius.circular(25),
    );
    canvas.drawRRect(
      shell,
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[
            Color(0xFF34495D),
            Color(0xFF1D2D41),
            Color(0xFF101C2B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
    );
    canvas.drawRRect(
      shell,
      Paint()
        ..color = const Color(0xFF6E8296)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    final Rect playfield = Rect.fromLTRB(
      size.width * .075,
      size.height * .045,
      size.width * .925,
      size.height * .955,
    );
    final RRect well = RRect.fromRectAndRadius(
      playfield,
      const Radius.circular(19),
    );
    canvas.drawRRect(
      well,
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[_board, Color(0xFF18293C), _deep],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(playfield),
    );
    canvas.save();
    canvas.clipRRect(well);
    _paintEtchedLanes(canvas, size);
    _paintScoreGlass(canvas, size);
    _paintBumpers(canvas, size);
    _paintTargetSequence(canvas, size);
    _paintLock(canvas, size);
    _paintFlippers(canvas, size);
    _paintDrainAndShooter(canvas, size);
    _paintBalls(canvas, size);
    canvas.restore();
    _paintCabinetBolts(canvas, size);
    if (paused) {
      canvas.drawRRect(well, Paint()..color = const Color(0xB9111B2A));
      _label(
        canvas,
        english ? 'PAUSED' : 'DURAKLATILDI',
        _point(size, .5, .49),
        size.width * .052,
        Colors.white,
      );
    } else if (engine.waitingToLaunch) {
      _label(
        canvas,
        english ? 'READY' : 'HAZIR',
        _point(size, .5, .73),
        size.width * .032,
        const Color(0xCCFFFFFF),
      );
    }
  }

  void _paintEtchedLanes(Canvas canvas, Size size) {
    final Paint lane = Paint()
      ..color = const Color(0x3156D8CC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .004;
    final Path left = Path()
      ..moveTo(size.width * .16, size.height * .10)
      ..cubicTo(
        size.width * .13,
        size.height * .30,
        size.width * .17,
        size.height * .50,
        size.width * .22,
        size.height * .81,
      )
      ..quadraticBezierTo(
        size.width * .26,
        size.height * .90,
        size.width * .39,
        size.height * .86,
      );
    final Path right = Path()
      ..moveTo(size.width * .84, size.height * .10)
      ..cubicTo(
        size.width * .87,
        size.height * .30,
        size.width * .83,
        size.height * .50,
        size.width * .78,
        size.height * .81,
      )
      ..quadraticBezierTo(
        size.width * .74,
        size.height * .90,
        size.width * .61,
        size.height * .86,
      );
    canvas.drawPath(left, lane);
    canvas.drawPath(right, lane);
    final Paint grid = Paint()
      ..color = const Color(0x167EA2B5)
      ..strokeWidth = 1;
    for (int index = 0; index < 7; index++) {
      final double y = size.height * (.12 + index * .09);
      canvas.drawLine(
        Offset(size.width * .2, y),
        Offset(size.width * .8, y),
        grid,
      );
    }
  }

  void _paintScoreGlass(Canvas canvas, Size size) {
    final Rect panel = Rect.fromLTWH(
      size.width * .25,
      size.height * .075,
      size.width * .5,
      size.height * .07,
    );
    final RRect glass = RRect.fromRectAndRadius(
      panel,
      const Radius.circular(12),
    );
    canvas.drawRRect(glass, Paint()..color = const Color(0xFF0E1A29));
    canvas.drawRRect(
      glass,
      Paint()
        ..color = const Color(0xFF526C80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final String mode = engine.multiballActive
        ? 'MULTIBALL'
        : 'STAGE ${scenario.level.toString().padLeft(2, '0')}';
    _label(canvas, mode, _point(size, .5, .105), size.width * .027, _teal);
    _label(
      canvas,
      engine.score.toString().padLeft(6, '0'),
      _point(size, .5, .135),
      size.width * .032,
      const Color(0xFFF1F7F4),
    );
  }

  void _paintBumpers(Canvas canvas, Size size) {
    for (int index = 0; index < scenario.bumpers.length; index++) {
      final PinballBumper bumper = scenario.bumpers[index];
      final Offset center = _point(size, bumper.x, bumper.y);
      final double radius = size.width * bumper.radius;
      final Color color = index.isEven ? _teal : _amber;
      canvas.drawCircle(
        center,
        radius * 1.55,
        Paint()..color = color.withValues(alpha: .09),
      );
      canvas.drawCircle(
        center,
        radius * 1.22,
        Paint()
          ..color = color.withValues(alpha: .22)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );
      canvas.drawCircle(
        center.translate(0, radius * .12),
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[
              color.withValues(alpha: .95),
              const Color(0xFF25384B),
              _deep,
            ],
            stops: const <double>[0, .45, 1],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      canvas.drawCircle(
        center.translate(-radius * .26, -radius * .31),
        radius * .16,
        Paint()..color = Colors.white.withValues(alpha: .75),
      );
    }
  }

  void _paintTargetSequence(Canvas canvas, Size size) {
    for (int index = 0; index < scenario.targets.length; index++) {
      final PinballTarget target = scenario.targets[index];
      final ({double x, double y}) centerAt = target.at(engine.elapsed);
      final Offset center = _point(size, centerAt.x, centerAt.y);
      final double radius = size.width * target.radius;
      final bool lit = engine.litTargets.contains(index);
      final bool current = index == engine.nextTarget;
      final Color color = lit
          ? _teal
          : current
          ? _amber
          : _violet;
      if (current) {
        canvas.drawCircle(
          center,
          radius * 2.0,
          Paint()..color = color.withValues(alpha: .12),
        );
      }
      final Rect targetRect = Rect.fromCenter(
        center: center,
        width: radius * 2,
        height: radius * 2,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(targetRect, Radius.circular(radius * .48)),
        Paint()
          ..shader = LinearGradient(
            colors: lit
                ? <Color>[const Color(0xFFC6FFF2), _teal]
                : current
                ? <Color>[const Color(0xFFFFE7B4), _amber]
                : <Color>[const Color(0xFF735D9E), _violet],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(targetRect),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(targetRect, Radius.circular(radius * .48)),
        Paint()
          ..color = color.withValues(alpha: .9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      _label(
        canvas,
        '${index + 1}',
        center,
        radius * .70,
        lit ? const Color(0xFF163248) : const Color(0xFF18283A),
      );
    }
  }

  void _paintLock(Canvas canvas, Size size) {
    if (!scenario.hasLock) return;
    final Offset center = _point(size, .5, .63);
    final Color color = engine.lockOpened ? _teal : _amber;
    canvas.drawCircle(
      center,
      size.width * .048,
      Paint()..color = color.withValues(alpha: .1),
    );
    canvas.drawCircle(
      center,
      size.width * .034,
      Paint()
        ..color = color.withValues(alpha: .14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    _label(
      canvas,
      engine.lockOpened ? '2×' : 'LOCK',
      center,
      size.width * .019,
      color,
    );
  }

  void _paintFlippers(Canvas canvas, Size size) {
    _flipper(canvas, size, left: true, active: engine.leftFlipper);
    _flipper(canvas, size, left: false, active: engine.rightFlipper);
  }

  void _flipper(
    Canvas canvas,
    Size size, {
    required bool left,
    required bool active,
  }) {
    final Offset pivot = _point(size, left ? .29 : .71, .865);
    final Offset tip = _point(
      size,
      left ? (active ? .48 : .49) : (active ? .52 : .51),
      active ? .785 : .845,
    );
    final Color color = active ? _amber : _teal;
    canvas.drawLine(
      pivot.translate(0, size.width * .009),
      tip.translate(0, size.width * .009),
      Paint()
        ..color = const Color(0x7706111D)
        ..strokeWidth = size.width * .055
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      pivot,
      tip,
      Paint()
        ..color = color.withValues(alpha: active ? .24 : .11)
        ..strokeWidth = size.width * .10
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      pivot,
      tip,
      Paint()
        ..color = color
        ..strokeWidth = size.width * .034
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      pivot,
      size.width * .025,
      Paint()..color = const Color(0xFFCBD8DE),
    );
    canvas.drawCircle(
      pivot,
      size.width * .014,
      Paint()..color = active ? _amber : const Color(0xFF496278),
    );
  }

  void _paintDrainAndShooter(Canvas canvas, Size size) {
    final Paint drain = Paint()
      ..color = const Color(0xFF091522)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .012;
    canvas.drawLine(_point(size, .42, .925), _point(size, .58, .925), drain);
    final Rect rail = Rect.fromLTRB(
      size.width * .835,
      size.height * .17,
      size.width * .90,
      size.height * .94,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rail, const Radius.circular(12)),
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[Color(0xFF273B50), Color(0xFF101C2B)],
        ).createShader(rail),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rail, const Radius.circular(12)),
      Paint()
        ..color = const Color(0xFF52677A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawLine(
      _point(size, .867, .22),
      _point(size, .867, .85),
      Paint()
        ..color = _amber.withValues(alpha: .42)
        ..strokeWidth = 2,
    );
    _label(
      canvas,
      'SHOOTER',
      _point(size, .868, .895),
      size.width * .012,
      const Color(0xFFAEBBC4),
    );
    if (engine.waitingToLaunch) {
      final Offset ball = _point(size, .868, .79);
      canvas.drawCircle(
        ball,
        size.width * .021,
        Paint()..color = const Color(0xFF4A5F74),
      );
      canvas.drawCircle(
        ball.translate(-size.width * .006, -size.width * .007),
        size.width * .009,
        Paint()..color = Colors.white.withValues(alpha: .75),
      );
    }
  }

  void _paintBalls(Canvas canvas, Size size) {
    for (final PinballOrb orb in engine.orbs) {
      final Offset center = _point(size, orb.x, orb.y);
      final double radius = size.width * orb.radius;
      canvas.drawCircle(
        center,
        radius * 2.1,
        Paint()..color = const Color(0x6655E5D2),
      );
      canvas.drawCircle(
        center.translate(0, radius * .10),
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: const <Color>[
              Colors.white,
              Color(0xFFD5E1E8),
              Color(0xFF748A9B),
            ],
            center: const Alignment(-.35, -.4),
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
      canvas.drawCircle(
        center.translate(-radius * .28, -radius * .34),
        radius * .22,
        Paint()..color = Colors.white,
      );
    }
  }

  void _paintCabinetBolts(Canvas canvas, Size size) {
    final Paint bolt = Paint()..color = const Color(0xFFA7B6C3);
    for (final Offset point in <Offset>[
      Offset(size.width * .047, size.height * .03),
      Offset(size.width * .953, size.height * .03),
      Offset(size.width * .047, size.height * .97),
      Offset(size.width * .953, size.height * .97),
    ]) {
      canvas.drawCircle(point, size.width * .009, bolt);
      canvas.drawLine(
        point.translate(-2, 0),
        point.translate(2, 0),
        Paint()
          ..color = const Color(0xFF33475A)
          ..strokeWidth = 1,
      );
    }
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
          letterSpacing: .6,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: 220);
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_NeonPinballPainter oldDelegate) =>
      oldDelegate.engine.elapsed != engine.elapsed ||
      oldDelegate.engine.score != engine.score ||
      oldDelegate.engine.nextTarget != engine.nextTarget ||
      oldDelegate.engine.leftFlipper != engine.leftFlipper ||
      oldDelegate.engine.rightFlipper != engine.rightFlipper ||
      oldDelegate.engine.orbs.length != engine.orbs.length ||
      oldDelegate.paused != paused;
}
