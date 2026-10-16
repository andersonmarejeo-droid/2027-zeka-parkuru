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
import 'ball_merge_board.dart';
import 'ball_merge_scenario.dart';

class BallMergeGamePage extends StatelessWidget {
  const BallMergeGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  static const int totalCases = BallMergeScenario.maximumLevels;
  static const int totalStars = totalCases * 3;

  static final List<ParkurLevelSpec> _levels =
      List<ParkurLevelSpec>.generate(totalCases, (int index) {
        final int level = index + 1;
        final String tr = switch (level) {
          <= 3 => 'Aynı küreleri buluştur; birleşmeleri zincire dönüştür.',
          <= 6 => 'Sıradaki küreyi ve sekme rotasını birlikte planla.',
          7 || 8 => 'İleri: güçlü alan akışında dar hazneyi kontrollü doldur.',
          9 => 'Uzman: yüksek değerleri koru, birleşme hedefini az hamlede tuttur.',
          _ => 'Usta finali: çapraz akışta 12 füzyonu taşma olmadan kur.',
        };
        final String en = switch (level) {
          <= 3 => 'Bring matching orbs together and turn each fusion into a chain.',
          <= 6 => 'Plan the next orb and its rebound route before every drop.',
          7 || 8 => 'Advanced: control a narrow chamber under stronger flux.',
          9 => 'Expert: protect high-value orbs and reach the merge target efficiently.',
          _ => 'Master finale: create 12 fusions under cross-current without overflow.',
        };
        return ParkurLevelSpec(
          number: level,
          titleTr: 'Füzyon Odası ${level.toString().padLeft(2, '0')}',
          titleEn: 'Fusion Chamber ${level.toString().padLeft(2, '0')}',
          subtitleTr: tr,
          subtitleEn: en,
          difficulty: switch (level) {
            <= 3 => 'USTALAŞMA',
            <= 6 => 'DERİNLEŞME',
            7 || 8 => 'İLERİ',
            9 => 'UZMAN',
            _ => 'USTA',
          },
          icon: Icons.blur_circular_rounded,
        );
      }, growable: false);

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.fun);
    return ParkurLevelHub(
      gameId: 'ball_merge',
      progressPrefix: 'ball_merge',
      titleTr: 'Top Birleştir',
      titleEn: 'Ball Merge',
      taglineTr: 'Rotayı kur • Küreleri birleştir • Hazneyi yönet',
      taglineEn: 'Aim • Fuse matching orbs • Manage the chamber',
      accent: skin.accent,
      icon: Icons.blur_circular_rounded,
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
          ) => BallMergePlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class BallMergePlayPage extends StatefulWidget {
  const BallMergePlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<BallMergePlayPage> createState() => _BallMergePlayPageState();
}

class _MergeBurst {
  _MergeBurst(this.event);

  final BallMergeEvent event;
  double age = 0;
}

class _BallMergePlayPageState extends State<BallMergePlayPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const Color _ink = Color(0xFF253D48);
  static const Color _accent = Color(0xFF318C82);
  static const List<Color> _orbColors = <Color>[
    Color(0xFF7DD9CB),
    Color(0xFFFFA77F),
    Color(0xFFF1CB73),
    Color(0xFF91B7F2),
    Color(0xFFBC9AEF),
    Color(0xFFEA8CB1),
    Color(0xFF7BC4EC),
    Color(0xFFB8D47B),
    Color(0xFFFFC46E),
    Color(0xFFF28A79),
  ];

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.fun,
  );
  final List<_MergeBurst> _bursts = <_MergeBurst>[];
  late final Ticker _ticker;
  late BallMergeScenario _scenario;
  late BallMergeBoard _board;
  late StudioGameSession _session;
  Duration _lastTick = Duration.zero;
  int _queueIndex = 0;
  int _mergeCount = 0;
  int _score = 0;
  int _chain = 0;
  int _bestChain = 0;
  double _aimX = .5;
  double _elapsed = 0;
  double _spawnCooldown = 0;
  double _crowdedTime = 0;
  double _lastMergeAt = -10;
  double _worldHeight = 1.15;
  bool _ready = false;
  bool _paused = false;
  bool _finished = false;
  bool _english = false;

  int? get _nextTier => _queueIndex < _scenario.queue.length
      ? _scenario.queue[_queueIndex]
      : null;

  int get _stars {
    if (_queueIndex <= _scenario.dropLimit - 5 && _bestChain >= 3) return 3;
    if (_queueIndex <= _scenario.dropLimit - 1) return 2;
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
    BallMergeScenario scenario = BallMergeScenario.forLevel(widget.level.number);
    try {
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      final String visitKey = 'ball_merge_level_${widget.level.number}_visits';
      final int visits = await preferences.getInt(visitKey) ?? 0;
      if (visits > 0) {
        final int index = await preferences.getInt('ball_merge_practice_index') ?? 0;
        if (index < BallMergeScenario.maximumPracticeRounds) {
          final int next = index + 1;
          await preferences.setInt('ball_merge_practice_index', next);
          scenario = BallMergeScenario.forPracticeRound(next);
        }
      }
      await preferences.setInt(visitKey, visits + 1);
    } catch (_) {
      scenario = BallMergeScenario.forLevel(widget.level.number);
    }
    if (!mounted) return;
    _scenario = scenario;
    _startRound();
    setState(() => _ready = true);
  }

  void _startRound() {
    _ticker.stop();
    _lastTick = Duration.zero;
    _elapsed = 0;
    _queueIndex = 0;
    _mergeCount = 0;
    _score = 0;
    _chain = 0;
    _bestChain = 0;
    _aimX = .5;
    _spawnCooldown = 0;
    _crowdedTime = 0;
    _lastMergeAt = -10;
    _bursts.clear();
    _board = BallMergeBoard();
    _paused = false;
    _finished = false;
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

  void _aimAt(double x) {
    if (!_ready || _paused || _finished) return;
    setState(() => _aimX = x.clamp(.16, .84).toDouble());
  }

  void _drop() {
    final int? tier = _nextTier;
    if (!_ready || _paused || _finished || tier == null || _spawnCooldown > 0) {
      return;
    }
    final bool added = _board.addOrb(
      tier: tier,
      x: _aimX,
      y: .16 + .028 * math.pow(1.18, tier).toDouble(),
    );
    if (!added) {
      _session.recordMistake();
      _audio.hapticHeavy();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .25));
      return;
    }
    _queueIndex++;
    _spawnCooldown = .34;
    _audio.hapticSelection();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .23));
    setState(() {});
  }

  void _tick(Duration elapsed) {
    if (!_ready || _paused || _finished) return;
    final double raw = (elapsed - _lastTick).inMicroseconds / 1000000;
    _lastTick = elapsed;
    if (raw <= 0) return;
    final double delta = raw.clamp(0, .032).toDouble();
    _elapsed += delta;
    _spawnCooldown = math.max(0, _spawnCooldown - delta);
    final List<BallMergeEvent> merges = _board.step(
      deltaSeconds: delta,
      worldHeight: _worldHeight,
      gravity: _scenario.gravity,
      flux: _scenario.flux,
      elapsedSeconds: _elapsed,
    );
    if (merges.isNotEmpty) {
      _mergeCount += merges.length;
      _chain = _elapsed - _lastMergeAt <= 1.15 ? _chain + merges.length : merges.length;
      _lastMergeAt = _elapsed;
      _bestChain = math.max(_bestChain, _chain);
      for (final BallMergeEvent merge in merges) {
        final int points = 90 + merge.tier * 65 + (_chain > 1 ? _chain * 30 : 0);
        _score += points;
        _session.recordAccepted(points: points);
        _bursts.add(_MergeBurst(merge));
      }
      _audio.hapticLight();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .30));
    }
    for (final _MergeBurst burst in _bursts) {
      burst.age += delta;
    }
    _bursts.removeWhere((_MergeBurst burst) => burst.age >= .62);

    final bool crowded = _board.isCrowded(_worldHeight) && _board.isSettled;
    _crowdedTime = crowded ? _crowdedTime + delta : math.max(0, _crowdedTime - delta * 2);
    if (_mergeCount >= _scenario.mergeGoal) {
      unawaited(_finish(completed: true));
    } else if (_crowdedTime >= 1.0) {
      unawaited(_finish(completed: false));
    } else if (_queueIndex >= _scenario.dropLimit &&
        _spawnCooldown <= 0 &&
        _board.isSettled) {
      unawaited(_finish(completed: _mergeCount >= _scenario.mergeGoal));
    }
    if (mounted && !_finished) setState(() {});
  }

  Future<void> _finish({required bool completed}) async {
    if (_finished || !mounted) return;
    _finished = true;
    _ticker.stop();
    if (!completed) {
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .36));
      final bool retry =
          await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) => AlertDialog(
              title: Text(_english ? 'Chamber overflow' : 'Hazne taştı'),
              content: Text(
                _english
                    ? '$_mergeCount of ${_scenario.mergeGoal} fusions made. Adjust your drop route and try again?'
                    : '${_scenario.mergeGoal} hedefinden $_mergeCount birleşme yaptın. Bırakma rotasını değiştirip yeniden deneyelim mi?',
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
        Navigator.of(context).pop(StudioGameResult.failed(score: _score).toParkurResult());
      }
      return;
    }

    _session.complete(
      stars: _stars,
      action: widget.level.number < BallMergeGamePage.totalCases
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
      titleTr: 'FÜZYON ODASI TAMAMLANDI',
      titleEn: 'FUSION CHAMBER COMPLETE',
      detailTr: '$_mergeCount füzyon · En iyi zincir $_bestChain.',
      detailEn: '$_mergeCount fusions · Best chain $_bestChain.',
      stars: _stars,
      score: _score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < BallMergeGamePage.totalCases,
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
        appBar: AppBar(title: Text(_english ? 'BALL MERGE' : 'TOP BİRLEŞTİR')),
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
          _english ? 'BALL MERGE' : 'TOP BİRLEŞTİR',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('ball_merge_pause'),
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
                  _MergeHud(
                    mergeCount: _mergeCount,
                    mergeGoal: _scenario.mergeGoal,
                    score: _score,
                    remaining: _scenario.dropLimit - _queueIndex,
                    nextTier: _nextTier,
                    english: _english,
                  ),
                  const SizedBox(height: 7),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints limits) {
                        final double width = math.min(limits.maxWidth, 570);
                        final double height = math.min(limits.maxHeight, width * 1.18);
                        _worldHeight = width <= 0 ? 1.15 : height / width;
                        return Center(
                          child: SizedBox(
                            width: width,
                            height: height,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapDown: (TapDownDetails details) => _aimAt(
                                details.localPosition.dx / width,
                              ),
                              onTapUp: (_) => _drop(),
                              onPanUpdate: (DragUpdateDetails details) =>
                                  _aimAt(details.localPosition.dx / width),
                              onPanEnd: (_) => _drop(),
                              child: CustomPaint(
                                key: const ValueKey<String>('ball_merge_scene'),
                                painter: _BallMergePainter(
                                  board: _board,
                                  bursts: List<_MergeBurst>.of(_bursts),
                                  queue: _scenario.queue,
                                  queueIndex: _queueIndex,
                                  aimX: _aimX,
                                  mergeCount: _mergeCount,
                                  mergeGoal: _scenario.mergeGoal,
                                  flux: _scenario.flux,
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
                  _MergeControls(
                    aimX: _aimX,
                    canDrop: !_paused && !_finished && _nextTier != null && _spawnCooldown <= 0,
                    english: _english,
                    onAim: _aimAt,
                    onDrop: _drop,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _english
                        ? 'Tap a lane or drag across the chamber. Fuse equal-value orbs and avoid the brass overfill line.'
                        : 'Haznede dokunup bırak veya sürükleyerek nişan al. Eşit değerleri birleştir; pirinç taşma çizgisinden uzak dur.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: StudioVisuals.muted,
                      fontSize: 9,
                      height: 1.2,
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

class _MergeHud extends StatelessWidget {
  const _MergeHud({
    required this.mergeCount,
    required this.mergeGoal,
    required this.score,
    required this.remaining,
    required this.nextTier,
    required this.english,
  });

  final int mergeCount;
  final int mergeGoal;
  final int score;
  final int remaining;
  final int? nextTier;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey<String>('ball_merge_hud'),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: StudioVisuals.surface,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: StudioVisuals.line),
      boxShadow: StudioVisuals.softShadow,
    ),
    child: Row(
      children: <Widget>[
        Expanded(
          child: _MergeMetric(
            label: english ? 'FUSIONS' : 'FÜZYON',
            value: '$mergeCount / $mergeGoal',
            icon: Icons.blur_circular_rounded,
            color: _BallMergePlayPageState._accent,
          ),
        ),
        Container(width: 1, height: 29, color: StudioVisuals.line),
        Expanded(
          child: _MergeMetric(
            label: english ? 'SCORE' : 'PUAN',
            value: '$score',
            icon: Icons.stars_rounded,
            color: const Color(0xFFD7A44B),
          ),
        ),
        Container(width: 1, height: 29, color: StudioVisuals.line),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                english ? 'NEXT · LEFT' : 'SIRADA · KALAN',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: StudioVisuals.muted,
                  fontSize: 7.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .25,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _MiniOrb(tier: nextTier, size: 21),
                  const SizedBox(width: 4),
                  Text(
                    '$remaining',
                    style: const TextStyle(
                      color: _BallMergePlayPageState._ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MergeMetric extends StatelessWidget {
  const _MergeMetric({
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
      Icon(icon, color: color, size: 16),
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
                fontSize: 7.5,
                fontWeight: FontWeight.w900,
                letterSpacing: .25,
              ),
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _BallMergePlayPageState._ink,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _MiniOrb extends StatelessWidget {
  const _MiniOrb({required this.tier, required this.size});

  final int? tier;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (tier == null) {
      return Icon(Icons.check_circle_outline_rounded, size: size, color: _BallMergePlayPageState._accent);
    }
    final Color color = _BallMergePlayPageState._orbColors[tier! % _BallMergePlayPageState._orbColors.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-.34, -.45),
          radius: 1.1,
          colors: <Color>[Color.lerp(Colors.white, color, .35)!, color, Color.lerp(color, const Color(0xFF223440), .48)!],
          stops: const <double>[0, .55, 1],
        ),
        boxShadow: <BoxShadow>[BoxShadow(color: color.withValues(alpha: .27), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Text(
        '${1 << tier!}',
        maxLines: 1,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * .35,
          fontWeight: FontWeight.w900,
          shadows: const <Shadow>[Shadow(color: Color(0x66304048), blurRadius: 2)],
        ),
      ),
    );
  }
}

class _MergeControls extends StatelessWidget {
  const _MergeControls({
    required this.aimX,
    required this.canDrop,
    required this.english,
    required this.onAim,
    required this.onDrop,
  });

  final double aimX;
  final bool canDrop;
  final bool english;
  final ValueChanged<double> onAim;
  final VoidCallback onDrop;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(11, 4, 6, 4),
    decoration: BoxDecoration(
      color: StudioVisuals.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: StudioVisuals.line),
    ),
    child: Row(
      children: <Widget>[
        Icon(Icons.swap_horiz_rounded, color: _BallMergePlayPageState._accent, size: 20),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 15),
            ),
            child: Slider(
              key: const ValueKey<String>('ball_merge_aim'),
              value: aimX,
              min: .16,
              max: .84,
              activeColor: _BallMergePlayPageState._accent,
              onChanged: onAim,
            ),
          ),
        ),
        const SizedBox(width: 3),
        SizedBox(
          height: 43,
          child: FilledButton.icon(
            key: const ValueKey<String>('ball_merge_drop'),
            onPressed: canDrop ? onDrop : null,
            style: FilledButton.styleFrom(
              backgroundColor: _BallMergePlayPageState._accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.south_rounded, size: 17),
            label: Text(english ? 'DROP' : 'BIRAK', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
          ),
        ),
      ],
    ),
  );
}

class _BallMergePainter extends CustomPainter {
  const _BallMergePainter({
    required this.board,
    required this.bursts,
    required this.queue,
    required this.queueIndex,
    required this.aimX,
    required this.mergeCount,
    required this.mergeGoal,
    required this.flux,
    required this.elapsed,
    required this.paused,
    required this.english,
  });

  final BallMergeBoard board;
  final List<_MergeBurst> bursts;
  final List<int> queue;
  final int queueIndex;
  final double aimX;
  final int mergeCount;
  final int mergeGoal;
  final double flux;
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
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(.045)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF536A72), Color(0xFF263F4A), Color(0xFF172D39)],
        ).createShader(bounds),
    );
    final Rect chamber = Rect.fromLTRB(.073, .07, .927, height - .055);
    canvas.drawRRect(
      RRect.fromRectAndRadius(chamber, const Radius.circular(.044)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF193542), Color(0xFF142A35), Color(0xFF223C46)],
        ).createShader(chamber),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(chamber, const Radius.circular(.044)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .008
        ..color = const Color(0xFFB9D3CF).withValues(alpha: .34),
    );

    final Paint gridPaint = Paint()
      ..color = const Color(0xFFB8D6D1).withValues(alpha: .055)
      ..strokeWidth = .0014;
    for (int row = 0; row < (height * 6).floor(); row++) {
      final double y = .12 + row * .14;
      canvas.drawLine(Offset(.085, y), Offset(.915, y), gridPaint);
    }
    for (int column = 0; column < 7; column++) {
      final double x = .14 + column * .12;
      canvas.drawLine(Offset(x, .09), Offset(x, height - .09), gridPaint);
    }

    // Top aperture and alignment rail.
    final Paint brass = Paint()..color = const Color(0xFFD9B875);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(.42, .035, .58, .094),
        const Radius.circular(.02),
      ),
      brass,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(.438, .047, .562, .087),
        const Radius.circular(.016),
      ),
      Paint()..color = const Color(0xFF25434C),
    );
    final double guideY = .115;
    final Paint guide = Paint()
      ..color = const Color(0xFF92D7C8).withValues(alpha: paused ? .20 : .49)
      ..strokeWidth = .003;
    canvas.drawLine(Offset(aimX, guideY), Offset(aimX, height - .11), guide);
    canvas.drawCircle(Offset(aimX, guideY), .022, Paint()..color = const Color(0xFFB4E8DB));

    // The overfill line is a clear, persistent survival cue.
    final double dangerY = math.min(.27, height * .30);
    final Paint danger = Paint()
      ..color = const Color(0xFFE3B85E).withValues(alpha: .67)
      ..strokeWidth = .003;
    for (double x = .085; x < .915; x += .026) {
      canvas.drawLine(Offset(x, dangerY), Offset(x + .012, dangerY), danger);
    }
    _drawLabel(
      canvas,
      english ? 'OVERFILL' : 'TAŞMA ÇİZGİSİ',
      Offset(.5, dangerY - .018),
      .021,
      const Color(0xFFE7C67E).withValues(alpha: .9),
      FontWeight.w900,
    );

    // A subdued moving current communicates the advanced-level modifier.
    if (flux > .01) {
      final double wave = math.sin(elapsed * (1.5 + flux)) * .016;
      final Path current = Path()
        ..moveTo(.13, .16)
        ..cubicTo(.38, .21 + wave, .62, .10 - wave, .87, .16);
      canvas.drawPath(
        current,
        Paint()
          ..color = const Color(0xFF8BD8CC).withValues(alpha: .28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .003,
      );
      for (int index = 0; index < 3; index++) {
        final double x = .28 + index * .22 + (elapsed * .055) % .16;
        canvas.drawCircle(Offset(x, .16 + wave), .004, Paint()..color = const Color(0xFFAFEEE0).withValues(alpha: .64));
      }
    }

    // The chamber's lower cradle gives the stack a stable visual anchor.
    final double floor = height - .085;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(.078, floor, .922, height - .038),
        const Radius.circular(.028),
      ),
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[Color(0xFF45636A), Color(0xFF243E48)],
        ).createShader(Rect.fromLTRB(.078, floor, .922, height - .038)),
    );
    canvas.drawLine(
      Offset(.105, floor),
      Offset(.895, floor),
      Paint()
        ..color = const Color(0xFFC7DED7).withValues(alpha: .58)
        ..strokeWidth = .004,
    );

    for (final MergeOrb orb in board.orbs) {
      _drawOrb(canvas, Offset(orb.x, orb.y), orb.tier, orb.radius, .0);
    }
    for (final _MergeBurst burst in bursts) {
      final double progress = (burst.age / .62).clamp(0, 1).toDouble();
      final Color color = _BallMergePlayPageState._orbColors[
        burst.event.tier % _BallMergePlayPageState._orbColors.length
      ];
      canvas.drawCircle(
        Offset(burst.event.x, burst.event.y),
        .025 + progress * .075,
        Paint()
          ..color = color.withValues(alpha: (1 - progress) * .55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .006 * (1 - progress * .65),
      );
      for (int spark = 0; spark < 6; spark++) {
        final double angle = math.pi * 2 * spark / 6 + progress * .8;
        final double distance = .018 + progress * .075;
        canvas.drawCircle(
          Offset(
            burst.event.x + math.cos(angle) * distance,
            burst.event.y + math.sin(angle) * distance,
          ),
          .0035 * (1 - progress),
          Paint()..color = color.withValues(alpha: 1 - progress),
        );
      }
    }

    final int? nextTier = queueIndex < queue.length ? queue[queueIndex] : null;
    if (nextTier != null) {
      _drawOrb(canvas, Offset(aimX, .164), nextTier, .028 * math.pow(1.18, nextTier).toDouble(), .58);
    }
    _drawProgressRail(canvas, height);
    if (paused) _drawPause(canvas, height);
    canvas.restore();
  }

  void _drawProgressRail(Canvas canvas, double height) {
    final Rect track = Rect.fromLTRB(.16, height - .028, .84, height - .018);
    canvas.drawRRect(
      RRect.fromRectAndRadius(track, const Radius.circular(.01)),
      Paint()..color = Colors.white.withValues(alpha: .22),
    );
    final double fraction = (mergeCount / mergeGoal).clamp(0, 1).toDouble();
    if (fraction > 0) {
      final Rect fill = Rect.fromLTRB(track.left, track.top, track.left + track.width * fraction, track.bottom);
      canvas.drawRRect(
        RRect.fromRectAndRadius(fill, const Radius.circular(.01)),
        Paint()
          ..shader = const LinearGradient(
            colors: <Color>[Color(0xFF7BE0C8), Color(0xFFF0CF7A)],
          ).createShader(track),
      );
    }
  }

  void _drawOrb(Canvas canvas, Offset center, int tier, double radius, double alpha) {
    final Color base = _BallMergePlayPageState._orbColors[
      tier % _BallMergePlayPageState._orbColors.length
    ];
    canvas.drawCircle(
      Offset(center.dx + radius * .08, center.dy + radius * .22),
      radius * 1.02,
      Paint()..color = const Color(0xFF061B25).withValues(alpha: .43 * (1 - alpha * .45)),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.36, -.46),
          radius: 1.12,
          colors: <Color>[
            Color.lerp(Colors.white, base, .28)!,
            base,
            Color.lerp(base, const Color(0xFF1B3540), .52)!,
          ],
          stops: const <double>[0, .47, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center,
      radius * .94,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.0016, radius * .07)
        ..color = Colors.white.withValues(alpha: .46),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - radius * .21, center.dy - radius * .34),
        width: radius * .52,
        height: radius * .20,
      ),
      Paint()..color = Colors.white.withValues(alpha: .53),
    );
    _drawLabel(
      canvas,
      '${1 << tier}',
      Offset(center.dx, center.dy + radius * .08),
      radius * .77,
      Colors.white,
      FontWeight.w900,
      shadow: true,
    );
    if (tier >= 3) {
      _drawLabel(
        canvas,
        'T${tier + 1}',
        Offset(center.dx, center.dy + radius * .52),
        radius * .27,
        Colors.white.withValues(alpha: .78),
        FontWeight.w800,
      );
    }
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset center,
    double maxWidth,
    Color color,
    FontWeight weight, {
    bool shadow = false,
  }) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: maxWidth * .37,
          fontWeight: weight,
          letterSpacing: -.25,
          shadows: shadow
              ? const <Shadow>[Shadow(color: Color(0x77304048), blurRadius: 3)]
              : null,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, Offset(center.dx - painter.width / 2, center.dy - painter.height / 2));
  }

  void _drawPause(Canvas canvas, double height) {
    final Rect rect = Rect.fromLTWH(.073, .07, .854, height - .125);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(.045)),
      Paint()..color = const Color(0xE9162D38),
    );
    _drawLabel(
      canvas,
      english ? 'PAUSED' : 'DURAKLATILDI',
      Offset(.5, height * .49),
      .58,
      Colors.white,
      FontWeight.w900,
    );
  }

  @override
  bool shouldRepaint(covariant _BallMergePainter oldDelegate) => true;
}
