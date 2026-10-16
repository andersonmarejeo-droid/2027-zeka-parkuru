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
import 'block_flow_engine.dart';
import 'block_flow_scenario.dart';

class BlockFlowGamePage extends StatelessWidget {
  const BlockFlowGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  static const int totalCases = BlockFlowScenario.maximumLevels;
  static const int totalStars = totalCases * 3;

  static final List<ParkurLevelSpec> _levels = List<ParkurLevelSpec>.generate(
    totalCases,
    (int index) {
      final int level = index + 1;
      final String tr = switch (level) {
        <= 3 => 'Üç şeridi oku; küpleri topla ve boş koridordan ilerle.',
        <= 6 => 'Faz kapılarını enerjiyle aç; üst ve alt rayı değiştir.',
        7 || 8 => 'İleri: ters akış dalgasını ve iki katmanlı blokları çöz.',
        9 => 'Uzman: yoğun engel sıralarında tek hata hakkını koru.',
        _ => 'Usta finali: çift katman, ters akış ve kaynak bütçesi.',
      };
      final String en = switch (level) {
        <= 3 =>
          'Read all three lanes, collect cubes and follow a clear corridor.',
        <= 6 => 'Spend energy at phase gates to switch between rails.',
        7 || 8 => 'Advanced: solve counterflow waves and stacked blocks.',
        9 => 'Expert: protect your single miss through dense hazard rows.',
        _ => 'Master finale: two decks, counterflow and a tight energy budget.',
      };
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Akış Koridoru ${level.toString().padLeft(2, '0')}',
        titleEn: 'Flow Corridor ${level.toString().padLeft(2, '0')}',
        subtitleTr: tr,
        subtitleEn: en,
        difficulty: switch (level) {
          <= 3 => 'USTALAŞMA',
          <= 6 => 'DERİNLEŞME',
          7 || 8 => 'İLERİ',
          9 => 'UZMAN',
          _ => 'USTA',
        },
        icon: Icons.view_in_ar_rounded,
      );
    },
    growable: false,
  );

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.fun);
    return ParkurLevelHub(
      gameId: 'block_flow',
      progressPrefix: 'block_flow',
      titleTr: 'Blok Akışı',
      titleEn: 'Block Flow',
      taglineTr: 'Şerit değiştir • Enerjiyi koru • Akıştan çık',
      taglineEn: 'Shift lanes • Protect energy • Break the flow',
      accent: skin.accent,
      icon: Icons.view_in_ar_rounded,
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
          ) => BlockFlowPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class BlockFlowPlayPage extends StatefulWidget {
  const BlockFlowPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<BlockFlowPlayPage> createState() => _BlockFlowPlayPageState();
}

class _BlockFlowPlayPageState extends State<BlockFlowPlayPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const Color _ink = Color(0xFF3A4D5C);
  static const Color _accent = Color(0xFF5A9E92);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.fun,
  );
  late final Ticker _ticker;
  late BlockFlowScenario _scenario;
  late BlockFlowEngine _engine;
  late StudioGameSession _session;
  Duration _lastTick = Duration.zero;
  double _visualLane = 1;
  double _visualDeck = 0;
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
    BlockFlowScenario scenario = BlockFlowScenario.forLevel(
      widget.level.number,
    );
    try {
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      final String visitKey = 'block_flow_level_${widget.level.number}_visits';
      final int visits = await preferences.getInt(visitKey) ?? 0;
      if (visits > 0) {
        final int index =
            await preferences.getInt('block_flow_practice_index') ?? 0;
        if (index < BlockFlowScenario.maximumPracticeRounds) {
          final int next = index + 1;
          await preferences.setInt('block_flow_practice_index', next);
          scenario = BlockFlowScenario.forPracticeRound(next);
        }
      }
      await preferences.setInt(visitKey, visits + 1);
    } catch (_) {
      scenario = BlockFlowScenario.forLevel(widget.level.number);
    }
    if (!mounted) return;
    _scenario = scenario;
    _startRun();
    setState(() => _ready = true);
  }

  void _startRun() {
    _ticker.stop();
    _engine = BlockFlowEngine(scenario: _scenario);
    _elapsed = 0;
    _score = 0;
    _visualLane = 1;
    _visualDeck = 0;
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

  void _changeLane(int direction) {
    if (!_ready || _paused || _finished) return;
    if (!_engine.shiftLane(direction)) return;
    _audio.hapticSelection();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .17),
    );
    setState(() {});
  }

  void _switchDeck() {
    if (!_ready || _paused || _finished || !_engine.switchDeck()) return;
    _audio.hapticLight();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .24),
    );
    setState(() {});
  }

  void _tick(Duration elapsed) {
    if (!_ready || _paused || _finished) return;
    final double raw = (elapsed - _lastTick).inMicroseconds / 1000000;
    _lastTick = elapsed;
    if (raw <= 0) return;
    final double delta = raw.clamp(0, .024).toDouble();
    _elapsed += delta;
    final BlockFlowStepResult result = _engine.step(delta);
    _visualLane += (_engine.lane - _visualLane) * (delta * 11).clamp(0, 1);
    _visualDeck += (_engine.deck - _visualDeck) * (delta * 8).clamp(0, 1);
    if (result.collectedShard) {
      _score += 60;
      _session.recordAccepted(points: 60);
      unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .27));
      _audio.hapticLight();
    }
    if (result.hitObstacle) {
      _session.recordMistake();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .28));
      _audio.hapticMedium();
    }
    if (result.passedRow && !result.hitObstacle) {
      _score += 12;
      _session.recordAccepted(points: 12);
    }
    if (result.finished) {
      final int timeBonus = math.max(
        0,
        ((_scenario.goldTimeSeconds - _elapsed) * 5).round(),
      );
      final int shardBonus = _engine.shards >= _scenario.targetShards ? 250 : 0;
      _score += 300 + timeBonus + shardBonus;
      _session.recordAccepted(points: 300 + timeBonus + shardBonus);
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
              title: Text(_english ? 'Route interrupted' : 'Akış kesildi'),
              content: Text(
                _english
                    ? 'Too many blocks were hit. Read the upcoming lanes and save energy for a rift, then retry?'
                    : 'Çok fazla bloğa çarptın. Yaklaşan şeritleri okuyup enerji küplerini biriktirerek tekrar deneyelim mi?',
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
        setState(_startRun);
      } else {
        Navigator.of(context)
            .pop(StudioGameResult.failed(score: _score).toParkurResult());
      }
      return;
    }

    _session.complete(
      stars: _stars,
      action: widget.level.number < BlockFlowGamePage.totalCases
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
      titleTr: 'BLOK AKIŞI TAMAMLANDI',
      titleEn: 'BLOCK FLOW COMPLETE',
      detailTr:
          '${_engine.nextRow}/${_scenario.rowCount} sıra · ${_engine.shards}/${_scenario.targetShards} enerji küpü · ${_engine.misses} çarpışma.',
      detailEn:
          '${_engine.nextRow}/${_scenario.rowCount} rows · ${_engine.shards}/${_scenario.targetShards} energy cubes · ${_engine.misses} collisions.',
      stars: _stars,
      score: _score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < BlockFlowGamePage.totalCases,
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
        appBar: AppBar(title: Text(_english ? 'BLOCK FLOW' : 'BLOK AKIŞI')),
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
          _english ? 'BLOCK FLOW' : 'BLOK AKIŞI',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('block_flow_pause'),
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
                  _FlowHud(
                    row: _engine.nextRow,
                    total: _scenario.rowCount,
                    shards: _engine.shards,
                    target: _scenario.targetShards,
                    energy: _engine.energy,
                    maximumEnergy: _scenario.maximumEnergy,
                    misses: _engine.misses,
                    missLimit: _scenario.missLimit,
                    dualDeck: _scenario.dualDeck,
                    english: _english,
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints limits) {
                        final double width = math.min(limits.maxWidth, 570);
                        final double height = math.min(
                          limits.maxHeight,
                          width * 1.12,
                        );
                        final Size sceneSize = Size(width, height);
                        return Center(
                          child: SizedBox(
                            key: const ValueKey<String>('block_flow_scene'),
                            width: width,
                            height: height,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onHorizontalDragEnd: (DragEndDetails details) {
                                final double velocity =
                                    details.primaryVelocity ?? 0;
                                if (velocity.abs() < 120) return;
                                _changeLane(velocity < 0 ? -1 : 1);
                              },
                              onTapUp: (TapUpDetails details) {
                                final double relativeX =
                                    details.localPosition.dx / sceneSize.width;
                                if (relativeX < .36) {
                                  _changeLane(-1);
                                } else if (relativeX > .64) {
                                  _changeLane(1);
                                }
                              },
                              child: CustomPaint(
                                painter: _BlockFlowPainter(
                                  scenario: _scenario,
                                  engine: _engine,
                                  visualLane: _visualLane,
                                  visualDeck: _visualDeck,
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
                  Row(
                    children: <Widget>[
                      _LaneButton(
                        key: const ValueKey<String>('block_flow_left'),
                        icon: Icons.chevron_left_rounded,
                        label: _english ? 'LEFT' : 'SOL',
                        enabled: _engine.lane > 0 && !_paused && !_finished,
                        onPressed: () => _changeLane(-1),
                      ),
                      const SizedBox(width: 6),
                      _LaneButton(
                        key: const ValueKey<String>('block_flow_right'),
                        icon: Icons.chevron_right_rounded,
                        label: _english ? 'RIGHT' : 'SAĞ',
                        enabled: _engine.lane < 2 && !_paused && !_finished,
                        onPressed: () => _changeLane(1),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _DeckSwitchButton(
                          key: const ValueKey<String>('block_flow_rift'),
                          enabled:
                              _engine.canSwitchDeck && !_paused && !_finished,
                          deck: _engine.deck,
                          energy: _engine.energy,
                          english: _english,
                          onPressed: _switchDeck,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _english
                        ? 'Read the next two block rows. Swipe to change one lane; spend an energy cube at a rift to shift decks.'
                        : 'Öndeki iki blok sırasını oku. Kaydırıp bir şerit değiştir; katman kapısında enerji küpü harca.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: StudioVisuals.muted,
                      fontSize: 9,
                      height: 1.15,
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

class _FlowHud extends StatelessWidget {
  const _FlowHud({
    required this.row,
    required this.total,
    required this.shards,
    required this.target,
    required this.energy,
    required this.maximumEnergy,
    required this.misses,
    required this.missLimit,
    required this.dualDeck,
    required this.english,
  });

  final int row;
  final int total;
  final int shards;
  final int target;
  final int energy;
  final int maximumEnergy;
  final int misses;
  final int missLimit;
  final bool dualDeck;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey<String>('block_flow_hud'),
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
          child: _FlowMetric(
            label: english ? 'ROUTE' : 'ROTA',
            value: '$row / $total',
            icon: Icons.route_rounded,
            color: const Color(0xFF5A9E92),
          ),
        ),
        Container(width: 1, height: 27, color: StudioVisuals.line),
        Expanded(
          child: _FlowMetric(
            label: english ? 'CUBES' : 'KÜP',
            value: '$shards / $target',
            icon: Icons.diamond_rounded,
            color: const Color(0xFFBC9A5D),
          ),
        ),
        Container(width: 1, height: 27, color: StudioVisuals.line),
        Expanded(
          child: _FlowMetric(
            label: dualDeck
                ? (english ? 'ENERGY' : 'ENERJİ')
                : (english ? 'MISSES' : 'HATA'),
            value: dualDeck
                ? '$energy / $maximumEnergy'
                : '$misses / $missLimit',
            icon: dualDeck ? Icons.bolt_rounded : Icons.warning_amber_rounded,
            color: dualDeck ? const Color(0xFF8399C0) : const Color(0xFFC57561),
          ),
        ),
      ],
    ),
  );
}

class _FlowMetric extends StatelessWidget {
  const _FlowMetric({
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
                color: _BlockFlowPlayPageState._ink,
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

class _LaneButton extends StatelessWidget {
  const _LaneButton({
    super.key,
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 72,
    height: 54,
    child: FilledButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF526F73),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFE1E7E3),
        disabledForegroundColor: const Color(0xFF8A9691),
        padding: const EdgeInsets.symmetric(horizontal: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    ),
  );
}

class _DeckSwitchButton extends StatelessWidget {
  const _DeckSwitchButton({
    super.key,
    required this.enabled,
    required this.deck,
    required this.energy,
    required this.english,
    required this.onPressed,
  });

  final bool enabled;
  final int deck;
  final int energy;
  final bool english;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 54,
    child: FilledButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: const Icon(Icons.swap_vert_rounded, size: 20),
      label: Text(
        enabled
            ? (english ? 'SHIFT DECK · $energy' : 'KATMAN DEĞİŞTİR · $energy')
            : (english ? 'RIFT AHEAD' : 'KAPIYI BEKLE'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: deck == 0
            ? const Color(0xFF738BC0)
            : const Color(0xFFBA7964),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFE1E7E3),
        disabledForegroundColor: const Color(0xFF8A9691),
        padding: const EdgeInsets.symmetric(horizontal: 7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    ),
  );
}

class _BlockFlowPainter extends CustomPainter {
  const _BlockFlowPainter({
    required this.scenario,
    required this.engine,
    required this.visualLane,
    required this.visualDeck,
    required this.paused,
    required this.english,
  });

  final BlockFlowScenario scenario;
  final BlockFlowEngine engine;
  final double visualLane;
  final double visualDeck;
  final bool paused;
  final bool english;

  static const Color _night = Color(0xFF233746);
  static const Color _teal = Color(0xFF69C7B3);
  static const Color _coral = Color(0xFFE49276);

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    final RRect frame = RRect.fromRectAndRadius(
      bounds.deflate(size.width * .025),
      Radius.circular(size.width * .07),
    );
    canvas.drawRRect(
      frame.shift(Offset(0, size.height * .012)),
      Paint()
        ..color = const Color(0x22354A55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawRRect(
      frame,
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[Color(0xFF304B5A), _night, Color(0xFF182B37)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
    );
    final Rect corridor = bounds.deflate(size.width * .075);
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(corridor, Radius.circular(size.width * .045)),
    );
    _paintBackdrop(canvas, corridor);
    _paintLanes(canvas, corridor);
    _paintRows(canvas, corridor);
    _paintRunner(canvas, corridor);
    _paintProgress(canvas, corridor);
    canvas.restore();
    if (paused) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(corridor, Radius.circular(size.width * .045)),
        Paint()..color = const Color(0xAA13242E),
      );
      _label(
        canvas,
        'PAUSED',
        Offset(size.width * .5, size.height * .48),
        18,
        Colors.white,
      );
    }
  }

  void _paintBackdrop(Canvas canvas, Rect rect) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[
            Color(0xFF415C67),
            Color(0xFF203541),
            Color(0xFF142732),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rect),
    );
    final Paint skyline = Paint()..color = const Color(0x1738D1B8);
    for (int index = 0; index < 6; index++) {
      final double x = rect.left + rect.width * (index + .5) / 6;
      final double width = rect.width * .07;
      final double height = rect.height * (.08 + (index % 3) * .025);
      final Rect tower = Rect.fromLTWH(
        x - width / 2,
        rect.top + rect.height * .09,
        width,
        height,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(tower, const Radius.circular(5)),
        skyline,
      );
    }
    final Paint vignette = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -.2),
        radius: 1,
        colors: <Color>[Colors.transparent, _night.withValues(alpha: .72)],
        stops: const <double>[.45, 1],
      ).createShader(rect);
    canvas.drawRect(rect, vignette);
  }

  Offset _lanePoint(Rect rect, int lane, double depth, int deck) {
    final double perspective = (.42 + depth * .58).clamp(.38, 1).toDouble();
    final double separation = rect.width * .22 * perspective;
    final double x = rect.center.dx + (lane - 1) * separation;
    final double deckOffset = deck == 1 ? -rect.height * .018 * perspective : 0;
    return Offset(x, rect.top + depth * rect.height + deckOffset);
  }

  void _paintLanes(Canvas canvas, Rect rect) {
    final double horizon = rect.top + rect.height * .12;
    final double runnerY = rect.top + rect.height * .78;
    for (int deck = 0; deck < (scenario.dualDeck ? 2 : 1); deck++) {
      final double offset = deck == 1 ? -rect.width * .055 : 0;
      for (int lane = 0; lane < 3; lane++) {
        final double laneOffset = (lane - 1) * rect.width * .27;
        final Path path = Path()
          ..moveTo(rect.center.dx + laneOffset * .45 + offset, horizon)
          ..lineTo(rect.center.dx + laneOffset + offset, runnerY);
        canvas.drawPath(
          path,
          Paint()
            ..color = deck == 1
                ? const Color(0x36598DD0)
                : const Color(0x386BD6C2)
            ..style = PaintingStyle.stroke
            ..strokeWidth = rect.width * .13
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawPath(
          path,
          Paint()
            ..color = deck == 1
                ? const Color(0x775B82B5)
                : const Color(0x7771BBAA)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.25
            ..strokeCap = StrokeCap.round,
        );
      }
    }
    for (int tick = 0; tick < 8; tick++) {
      final double y = rect.top + rect.height * (.20 + tick * .085);
      final double perspective = .42 + ((runnerY - y) / rect.height) * .58;
      final double width = rect.width * .50 * perspective;
      final bool counter = engine.upcomingRow?.counterflow ?? false;
      final Path marker = Path()
        ..moveTo(rect.center.dx - width / 2, y)
        ..lineTo(rect.center.dx + width / 2, y);
      canvas.drawPath(
        marker,
        Paint()
          ..color = counter ? const Color(0x2DE89E84) : const Color(0x1FFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      if (tick.isEven) {
        final double direction = counter ? -1 : 1;
        _arrow(
          canvas,
          Offset(rect.right - rect.width * .13, y),
          direction,
          rect.width * .014,
          counter
              ? _coral.withValues(alpha: .56)
              : _teal.withValues(alpha: .42),
        );
      }
    }
  }

  void _paintRows(Canvas canvas, Rect rect) {
    final double avatarY = rect.top + rect.height * .78;
    final double spacing = rect.height * .105;
    final double fraction = engine.progress - engine.nextRow;
    final int visibleEnd = math.min(scenario.rows.length, engine.nextRow + 9);
    for (int index = engine.nextRow; index < visibleEnd; index++) {
      final BlockFlowRow row = scenario.rows[index];
      final double ahead = (index + 1 - engine.progress).clamp(0, 8).toDouble();
      final double y = avatarY - ahead * spacing;
      if (y < rect.top - spacing || y > avatarY + spacing) continue;
      final double depth = ((y - rect.top) / rect.height)
          .clamp(.04, .96)
          .toDouble();
      final double scale = .40 + depth * .60;
      for (final FlowHazard hazard in row.hazards) {
        final Offset center = _lanePoint(rect, hazard.lane, depth, hazard.deck);
        final double w = rect.width * .15 * scale;
        final double h = rect.height * .052 * scale;
        _paintBlock(
          canvas,
          Rect.fromCenter(center: center, width: w, height: h),
          hazard.shape,
          hazard.deck,
        );
      }
      for (final FlowShard shard in row.shards) {
        final Offset center = _lanePoint(rect, shard.lane, depth, shard.deck);
        _paintShard(canvas, center, rect.width * .024 * scale, row.index);
      }
      if (row.riftLaneMask != 0) {
        for (int lane = 0; lane < 3; lane++) {
          if (!row.hasRiftAt(lane)) continue;
          final Offset center = _lanePoint(rect, lane, depth, 0);
          canvas.drawOval(
            Rect.fromCenter(
              center: center.translate(0, rect.height * .008 * scale),
              width: rect.width * .18 * scale,
              height: rect.height * .035 * scale,
            ),
            Paint()
              ..color = const Color(0x776F8CDC)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.3 * scale,
          );
        }
      }
      if (row.counterflow) {
        final Offset arrowCenter = Offset(rect.left + rect.width * .075, y);
        _arrow(canvas, arrowCenter, -1, rect.width * .028 * scale, _coral);
      }
      final TextPainter rowIndex = TextPainter(
        text: TextSpan(
          text: '${row.index + 1}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: .23 + .35 * depth),
            fontSize: 7 * scale,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      rowIndex.paint(
        canvas,
        Offset(rect.right - rect.width * .075, y - rowIndex.height / 2),
      );
    }
    final double beatY = avatarY - spacing * (1 - fraction);
    if (beatY >= rect.top && beatY <= avatarY + 8) {
      canvas.drawLine(
        Offset(rect.left + 6, beatY),
        Offset(rect.right - 6, beatY),
        Paint()
          ..color = const Color(0x4478D9C1)
          ..strokeWidth = 1.2,
      );
    }
  }

  void _paintBlock(Canvas canvas, Rect face, int shape, int deck) {
    final double side = face.height * .48;
    final Color base = deck == 1
        ? const Color(0xFF7F99CF)
        : <Color>[
            const Color(0xFFE48D74),
            const Color(0xFFC77A65),
            const Color(0xFFBD9870),
            const Color(0xFF8FA99D),
          ][shape % 4];
    final Path top = Path()
      ..moveTo(face.left, face.top)
      ..lineTo(face.left + side, face.top - side * .62)
      ..lineTo(face.right + side, face.top - side * .62)
      ..lineTo(face.right, face.top)
      ..close();
    final Path sideFace = Path()
      ..moveTo(face.right, face.top)
      ..lineTo(face.right + side, face.top - side * .62)
      ..lineTo(face.right + side, face.bottom - side * .32)
      ..lineTo(face.right, face.bottom)
      ..close();
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        face.shift(Offset(0, side * .25)),
        Radius.circular(face.height * .18),
      ),
      Paint()..color = const Color(0x4C0B1820),
    );
    canvas.drawPath(top, Paint()..color = Color.lerp(base, Colors.white, .34)!);
    canvas.drawPath(
      sideFace,
      Paint()..color = Color.lerp(base, Colors.black, .24)!,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(face, Radius.circular(face.height * .18)),
      Paint()
        ..shader = LinearGradient(
          colors: <Color>[
            Color.lerp(base, Colors.white, .13)!,
            base,
            Color.lerp(base, Colors.black, .12)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(face),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(face, Radius.circular(face.height * .18)),
      Paint()
        ..color = Colors.white.withValues(alpha: .38)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    if (shape == 2) {
      final Paint band = Paint()
        ..color = const Color(0xB5423F51)
        ..strokeWidth = face.height * .14
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(face.left + side * .2, face.center.dy),
        Offset(face.right - side * .2, face.center.dy),
        band,
      );
    } else if (shape == 3) {
      final Paint slit = Paint()
        ..color = const Color(0xBFF0D6A0)
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(face.center.dx, face.top + face.height * .18),
        Offset(face.center.dx, face.bottom - face.height * .18),
        slit,
      );
    }
  }

  void _paintShard(Canvas canvas, Offset center, double radius, int row) {
    final double pulse = .92 + .08 * math.sin(engine.elapsedSeconds * 5 + row);
    final double r = radius * pulse;
    final Path diamond = Path()
      ..moveTo(center.dx, center.dy - r * 1.35)
      ..lineTo(center.dx + r, center.dy)
      ..lineTo(center.dx, center.dy + r * 1.35)
      ..lineTo(center.dx - r, center.dy)
      ..close();
    canvas.drawCircle(
      center.translate(0, r * .6),
      r * 1.34,
      Paint()..color = const Color(0x447DE5D3),
    );
    canvas.drawPath(
      diamond,
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[
            Color(0xFFFFEAB2),
            Color(0xFF5FDECB),
            Color(0xFF4589B7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromCircle(center: center, radius: r * 1.5)),
    );
    canvas.drawPath(
      diamond,
      Paint()
        ..color = const Color(0xC8FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _paintRunner(Canvas canvas, Rect rect) {
    final double y = rect.top + rect.height * .78;
    final int baseDeck = visualDeck.round();
    final double deckBlend = (visualDeck - baseDeck).abs();
    final double x =
        rect.center.dx +
        (visualLane - 1) * rect.width * .22 -
        (visualDeck * rect.width * .055);
    final Offset center = Offset(x, y - rect.height * .035 * deckBlend);
    final double size = rect.width * .095;
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, size * .56),
        width: size * 1.5,
        height: size * .49,
      ),
      Paint()..color = const Color(0x665CE2C4),
    );
    final Rect face = Rect.fromCenter(
      center: center,
      width: size,
      height: size * .94,
    );
    final Path top = Path()
      ..moveTo(face.left, face.top + size * .14)
      ..lineTo(face.center.dx, face.top - size * .2)
      ..lineTo(face.right, face.top + size * .14)
      ..lineTo(face.center.dx, face.top + size * .45)
      ..close();
    canvas.drawPath(top, Paint()..color = const Color(0xFFBAF4E6));
    canvas.drawRRect(
      RRect.fromRectAndRadius(face, Radius.circular(size * .22)),
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[
            Color(0xFF73D6C0),
            Color(0xFF338A83),
            Color(0xFF225C68),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(face),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(face, Radius.circular(size * .22)),
      Paint()
        ..color = const Color(0xFFB9F6E5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    final Paint eye = Paint()..color = const Color(0xFF183943);
    canvas.drawCircle(
      Offset(face.left + size * .32, face.top + size * .42),
      size * .055,
      eye,
    );
    canvas.drawCircle(
      Offset(face.right - size * .32, face.top + size * .42),
      size * .055,
      eye,
    );
    canvas.drawLine(
      Offset(face.left + size * .28, face.bottom + size * .12),
      Offset(face.right - size * .28, face.bottom + size * .12),
      Paint()
        ..color = const Color(0xFFB6D7CF)
        ..strokeWidth = size * .075
        ..strokeCap = StrokeCap.round,
    );
    if (scenario.dualDeck) {
      _label(
        canvas,
        visualDeck < .5 ? 'A' : 'B',
        Offset(rect.right - rect.width * .09, rect.bottom - rect.height * .07),
        10,
        Colors.white.withValues(alpha: .7),
      );
    }
  }

  void _paintProgress(Canvas canvas, Rect rect) {
    final Rect track = Rect.fromLTWH(
      rect.left + 10,
      rect.top + 10,
      rect.width - 20,
      3,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(track, const Radius.circular(5)),
      Paint()..color = const Color(0x55FFFFFF),
    );
    final Rect fill = Rect.fromLTWH(
      track.left,
      track.top,
      track.width * engine.progressFraction,
      track.height,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(fill, const Radius.circular(5)),
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[_teal, Color(0xFFFFD28E)],
        ).createShader(track),
    );
  }

  void _arrow(
    Canvas canvas,
    Offset center,
    double direction,
    double size,
    Color color,
  ) {
    final Path path = Path()
      ..moveTo(center.dx, center.dy - direction * size)
      ..lineTo(center.dx - size * .55, center.dy + direction * size * .24)
      ..lineTo(center.dx - size * .17, center.dy + direction * size * .24)
      ..lineTo(center.dx - size * .17, center.dy + direction * size)
      ..lineTo(center.dx + size * .17, center.dy + direction * size)
      ..lineTo(center.dx + size * .17, center.dy + direction * size * .24)
      ..lineTo(center.dx + size * .55, center.dy + direction * size * .24)
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
          letterSpacing: 1,
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
  bool shouldRepaint(_BlockFlowPainter oldDelegate) =>
      oldDelegate.scenario != scenario ||
      oldDelegate.engine != engine ||
      oldDelegate.engine.nextRow != engine.nextRow ||
      oldDelegate.engine.progress != engine.progress ||
      oldDelegate.engine.lane != engine.lane ||
      oldDelegate.engine.deck != engine.deck ||
      oldDelegate.engine.shards != engine.shards ||
      oldDelegate.engine.energy != engine.energy ||
      oldDelegate.english != english ||
      oldDelegate.paused != paused ||
      oldDelegate.visualLane != visualLane ||
      oldDelegate.visualDeck != visualDeck;
}
