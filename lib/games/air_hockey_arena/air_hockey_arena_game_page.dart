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
import 'air_hockey_engine.dart';
import 'air_hockey_scenario.dart';

class AirHockeyArenaPage extends StatelessWidget {
  const AirHockeyArenaPage({super.key});

  static const int totalCases = AirHockeyScenario.campaignLevels;
  static const int totalStars = totalCases * 3;

  static final List<ParkurLevelSpec>
  _levels = List<ParkurLevelSpec>.generate(totalCases, (int index) {
    final int level = index + 1;
    return ParkurLevelSpec(
      number: level,
      titleTr: 'Arena ${level.toString().padLeft(2, '0')}',
      titleEn: 'Arena ${level.toString().padLeft(2, '0')}',
      subtitleTr: switch (level) {
        <= 3 => 'Diskin çizgisini oku; raketi savunma alanında sürükle.',
        <= 6 => 'Açıyı kenardan çıkar; tek güçlü smaç hakkını zamanla.',
        7 || 8 => 'İleri: daha dar kale ve ilk sekme tamponları.',
        9 || 10 => 'Uzman: üç çarpışmayı ve rakip dönüşünü önceden oku.',
        <= 16 => 'Usta masa: hızlı disk, kaygan zemin ve çift tampon.',
        _ => 'Final arena: dar hedef, üç tampon ve hızlı kontra rallisi.',
      },
      subtitleEn: switch (level) {
        <= 3 =>
          'Read the puck path and drag your mallet inside the defensive half.',
        <= 6 => 'Bank off the rail and time your single charged smash.',
        7 || 8 => 'Advanced: narrower goals and the first rebound bumpers.',
        9 || 10 => 'Expert: read three collisions and the rival counter early.',
        <= 16 => 'Master table: faster puck, slick surface and paired bumpers.',
        _ => 'Final arena: narrow target, three bumpers and rapid counter rallies.',
      },
      difficulty: switch (level) {
        <= 3 => 'ISINMA',
        <= 6 => 'GELİŞİM',
        7 || 8 => 'İLERİ',
        9 || 10 => 'UZMAN',
        <= 16 => 'USTA',
        _ => 'FİNAL',
      },
      icon: Icons.sports_hockey_rounded,
    );
  }, growable: false);

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.fun);
    return ParkurLevelHub(
      gameId: 'air_hockey_arena',
      progressPrefix: 'air_hockey_arena',
      titleTr: 'Air Hockey Arena',
      titleEn: 'Air Hockey Arena',
      taglineTr: 'Sürükle • Açıyı kur • Smaçla',
      taglineEn: 'Drag • Bank the angle • Smash',
      accent: skin.accent,
      icon: Icons.sports_hockey_rounded,
      levels: _levels,
      dailyCourseMode: false,
      playBuilder:
          (
            BuildContext context,
            ParkurLevelSpec level,
            int previousBestScore,
            int? competitionLayoutCode,
            bool competitionMode,
          ) => AirHockeyArenaPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class AirHockeyArenaPlayPage extends StatefulWidget {
  const AirHockeyArenaPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<AirHockeyArenaPlayPage> createState() => _AirHockeyArenaPlayPageState();
}

class _AirHockeyArenaPlayPageState extends State<AirHockeyArenaPlayPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const Color _accent = Color(0xFF3196A0);
  static const Color _coral = Color(0xFFD87962);
  static const Color _ink = Color(0xFF354B57);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.fun,
  );
  late final Ticker _ticker;
  late AirHockeyScenario _scenario;
  late AirHockeyEngine _engine;
  late StudioGameSession _session;
  Duration _lastTick = Duration.zero;
  Offset _target = const Offset(.5, .79);
  bool _ready = false;
  bool _paused = false;
  bool _finished = false;
  bool _english = false;
  String _feedback = '';

  int get _score =>
      (_engine.playerGoals * 250 +
              _engine.playerHits * 12 +
              _engine.longestRally * 24 +
              _engine.smashesUsed * 48)
          .clamp(0, 10000000)
          .toInt();

  int get _stars {
    final int margin = _engine.playerGoals - _engine.opponentGoals;
    if (margin >= 3 && _engine.smashesUsed > 0) return 3;
    if (margin >= 1 || _engine.longestRally >= 5) return 2;
    return 1;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_tick);
    unawaited(_audioProfile.preload(_audio));
    unawaited(_prepareArena());
  }

  Future<void> _prepareArena() async {
    AirHockeyScenario scenario = AirHockeyScenario.forLevel(
      widget.level.number,
    );
    try {
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      final String visitKey =
          'air_hockey_arena_level_${widget.level.number}_visits';
      final int visits = await preferences.getInt(visitKey) ?? 0;
      if (visits > 0) {
        final int index =
            await preferences.getInt('air_hockey_arena_practice_index') ?? 0;
        if (index < AirHockeyScenario.practiceArenas) {
          final int next = index + 1;
          await preferences.setInt('air_hockey_arena_practice_index', next);
          scenario = AirHockeyScenario.forPracticeArena(next);
        }
      }
      await preferences.setInt(visitKey, visits + 1);
    } catch (_) {
      // Keep the deterministic campaign table if local storage is unavailable.
    }
    if (!mounted) return;
    _scenario = scenario;
    _resetMatch();
    setState(() => _ready = true);
  }

  void _resetMatch() {
    _ticker.stop();
    _engine = AirHockeyEngine(scenario: _scenario);
    _session = StudioGameSession(
      level: widget.level.number,
      seed: _scenario.seed,
    )..start();
    _target = const Offset(.5, .79);
    _paused = false;
    _finished = false;
    _lastTick = Duration.zero;
    _feedback = '';
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
    setState(() => _paused = value);
    if (value) {
      _session.pause();
      _ticker.stop();
    } else {
      _session.resume();
      _lastTick = Duration.zero;
      _ticker.start();
    }
    unawaited(_audio.play(GameSound.uiClick, gain: .24));
  }

  void _dragMallet(Offset local, Size size) {
    if (!_ready ||
        _paused ||
        _finished ||
        size.width <= 0 ||
        size.height <= 0) {
      return;
    }
    setState(() {
      _target = Offset(
        (local.dx / size.width).clamp(.09, .91).toDouble(),
        (local.dy / size.height).clamp(.55, .91).toDouble(),
      );
    });
  }

  void _smash() {
    if (!_ready || _paused || _finished || !_engine.smashAvailable) return;
    _engine.queueSmash();
    _feedback = _english
        ? 'SMASH ARMED · WAIT FOR CONTACT'
        : 'SMAÇ HAZIR · TEMASI BEKLE';
    _audio.hapticLight();
    setState(() {});
  }

  void _tick(Duration elapsed) {
    if (!_ready || _paused || _finished) return;
    final double raw = (elapsed - _lastTick).inMicroseconds / 1000000;
    _lastTick = elapsed;
    if (raw <= 0) return;
    final AirHockeyStepResult result = _engine.step(
      deltaSeconds: raw.clamp(0, .04).toDouble(),
      playerTarget: _target,
    );
    if (result.playerHit) {
      _session.recordAccepted(points: 16);
      _feedback = result.smashUsed
          ? (_english
                ? 'CHARGED SMASH · FOLLOW THROUGH'
                : 'GÜÇLÜ SMAÇ · TAKİP ET')
          : (_english
                ? 'CLEAN RETURN · FIND THE OPEN RAIL'
                : 'TEMİZ DÖNÜŞ · AÇIK KENARI BUL');
      unawaited(
        _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .23),
      );
      _audio.hapticLight();
    }
    if (result.opponentHit) {
      _feedback = _english
          ? 'COUNTER · DEFEND THE REBOUND'
          : 'KONTRA · SEKİŞİ SAVUN';
      unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .15));
    }
    if (result.pointWinner != null) {
      if (result.pointWinner == AirHockeySide.player) {
        _session.recordAccepted(points: 100);
        _feedback = _english
            ? 'GOAL · RESET YOUR MALLET'
            : 'GOL · RAKETİ YENİDEN KONUMLA';
        unawaited(
          _audioProfile.play(_audio, GameAudioEvent.accepted, gain: .27),
        );
      } else {
        _session.recordMistake();
        _feedback = _english
            ? 'GOAL CONCEDED · CLOSE THE LANE'
            : 'GOL YEDİN · AÇIYI KAPAT';
        unawaited(
          _audioProfile.play(_audio, GameAudioEvent.rejected, gain: .2),
        );
      }
    }
    if (result.matchOver) {
      unawaited(_finishMatch(playerWon: result.playerWon));
    } else if (mounted && !_finished) {
      setState(() {});
    }
  }

  Future<void> _finishMatch({required bool playerWon}) async {
    if (_finished || !mounted) return;
    _finished = true;
    _ticker.stop();
    if (!playerWon) {
      final bool retry =
          await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) => AlertDialog(
              title: Text(_english ? 'Arena point' : 'Arena tamamlandı'),
              content: Text(
                _english
                    ? 'Keep your mallet behind the centre line, lead the puck instead of chasing it, and save the smash for contact.'
                    : 'Raketi orta çizginin arkasında tut; diski kovalamak yerine gelişini kes ve smaçı temasa sakla.',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(_english ? 'Arena map' : 'Arena haritası'),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: Text(_english ? 'Rematch' : 'Rövanş'),
                ),
              ],
            ),
          ) ??
          false;
      if (!mounted) return;
      if (retry) {
        setState(_resetMatch);
      } else {
        Navigator.of(context)
            .pop(StudioGameResult.failed(score: _score).toParkurResult());
      }
      return;
    }

    _session.complete(
      stars: _stars,
      action: widget.level.number < AirHockeyArenaPage.totalCases
          ? StudioResultAction.next
          : StudioResultAction.map,
    );
    unawaited(_audioProfile.play(
      _audio,
      GameAudioEvent.levelComplete,
      levelNumber: widget.level.number,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 140));
    if (!mounted) return;
    final ParkurResultAction? result = await showParkurResultDialog(
      context: context,
      accent: _accent,
      titleTr: 'ARENA KAZANILDI',
      titleEn: 'ARENA WON',
      detailTr:
          '${_engine.playerGoals} gol · ${_engine.longestRally} temaslık uzun ralli · ${_engine.smashesUsed} smaç',
      detailEn:
          '${_engine.playerGoals} goals · ${_engine.longestRally}-touch rally · ${_engine.smashesUsed} smashes',
      stars: _stars,
      score: _score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < AirHockeyArenaPage.totalCases,
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
        appBar: AppBar(
          title: Text(_english ? 'AIR HOCKEY ARENA' : 'AIR HOCKEY ARENA'),
        ),
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
          _english ? 'AIR HOCKEY · ARENA' : 'AIR HOCKEY · ARENA',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
        ),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('air_hockey_arena_pause'),
            tooltip: _paused
                ? (_english ? 'Resume' : 'Devam et')
                : (_english ? 'Pause' : 'Duraklat'),
            onPressed: () => _setPaused(!_paused),
            icon: Icon(
              _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
              child: Column(
                children: <Widget>[
                  _ArenaScoreHud(
                    player: _engine.playerGoals,
                    opponent: _engine.opponentGoals,
                    target: _scenario.goalsToWin,
                    rally: _engine.currentRallyHits,
                    english: _english,
                  ),
                  const SizedBox(height: 7),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints limits) {
                        final double width = math.min(limits.maxWidth, 540);
                        final double height = math.min(
                          limits.maxHeight,
                          width * .98,
                        );
                        final Size sceneSize = Size(width, height);
                        return Center(
                          child: SizedBox(
                            key: const ValueKey<String>(
                              'air_hockey_arena_scene',
                            ),
                            width: width,
                            height: height,
                            child: Stack(
                              fit: StackFit.expand,
                              children: <Widget>[
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onPanStart: (DragStartDetails details) =>
                                      _dragMallet(
                                        details.localPosition,
                                        sceneSize,
                                      ),
                                  onPanUpdate: (DragUpdateDetails details) =>
                                      _dragMallet(
                                        details.localPosition,
                                        sceneSize,
                                      ),
                                  onTapDown: (TapDownDetails details) =>
                                      _dragMallet(
                                        details.localPosition,
                                        sceneSize,
                                      ),
                                  child: CustomPaint(
                                    painter: _AirHockeyTablePainter(
                                      engine: _engine,
                                      scenario: _scenario,
                                    ),
                                  ),
                                ),
                                if (_paused)
                                  _ArenaPauseOverlay(
                                    english: _english,
                                    onResume: () => _setPaused(false),
                                  ),
                                Positioned(
                                  bottom: 6,
                                  left: 0,
                                  right: 0,
                                  child: IgnorePointer(
                                    child: Center(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: .82,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 9,
                                            vertical: 4,
                                          ),
                                          child: Text(
                                            _english
                                                ? 'DRAG IN YOUR HALF'
                                                : 'KENDİ YARINDA SÜRÜKLE',
                                            style: const TextStyle(
                                              color: _ink,
                                              fontSize: 7.5,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: .45,
                                            ),
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
                    height: 20,
                    child: Center(
                      child: Text(
                        _feedback.isNotEmpty
                            ? _feedback
                            : (_english
                                  ? 'LEAD THE PUCK · CLOSE THE ANGLE · SMASH ONLY AT CONTACT'
                                  : 'DİSKİN ÖNÜNE GEÇ · AÇIYI KAPAT · SMAÇI TEMASA SAKLA'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _feedback.isEmpty
                              ? StudioVisuals.muted
                              : _accent,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .08,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      key: const ValueKey<String>('air_hockey_arena_smash'),
                      onPressed:
                          !_paused && !_finished && _engine.smashAvailable
                          ? _smash
                          : null,
                      icon: Icon(
                        _engine.smashAvailable
                            ? Icons.bolt_rounded
                            : Icons.hourglass_empty_rounded,
                        size: 18,
                      ),
                      label: Text(
                        _engine.smashAvailable
                            ? (_english ? 'CHARGED SMASH' : 'GÜÇLÜ SMAÇ')
                            : (_english
                                  ? 'RECHARGES NEXT POINT'
                                  : 'SONRAKİ SAYIDA YENİLENİR'),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: _engine.smashAvailable
                            ? _coral
                            : const Color(0xFF9EACAF),
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .25,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
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

class _ArenaScoreHud extends StatelessWidget {
  const _ArenaScoreHud({
    required this.player,
    required this.opponent,
    required this.target,
    required this.rally,
    required this.english,
  });
  final int player;
  final int opponent;
  final int target;
  final int rally;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey<String>('air_hockey_arena_hud'),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: StudioVisuals.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: StudioVisuals.line),
      boxShadow: StudioVisuals.softShadow,
    ),
    child: Row(
      children: <Widget>[
        _ArenaScoreSide(
          label: english ? 'YOU' : 'SEN',
          score: player,
          color: const Color(0xFF3196A0),
        ),
        const Spacer(),
        Column(
          children: <Widget>[
            Text(
              english ? 'FIRST TO $target' : '$target SAYIDA KAZANIR',
              style: const TextStyle(
                color: StudioVisuals.muted,
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              english ? 'RALLY $rally' : 'RALLİ $rally',
              style: const TextStyle(
                color: _AirHockeyInk.color,
                fontSize: 8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const Spacer(),
        _ArenaScoreSide(
          label: english ? 'RIVAL' : 'RAKİP',
          score: opponent,
          color: const Color(0xFFD87962),
        ),
      ],
    ),
  );
}

class _ArenaScoreSide extends StatelessWidget {
  const _ArenaScoreSide({
    required this.label,
    required this.score,
    required this.color,
  });
  final String label;
  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: .5,
        ),
      ),
      Text(
        '$score',
        style: TextStyle(
          color: color,
          fontSize: 22,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

abstract final class _AirHockeyInk {
  static const Color color = Color(0xFF354B57);
}

class _ArenaPauseOverlay extends StatelessWidget {
  const _ArenaPauseOverlay({required this.english, required this.onResume});
  final bool english;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xA51A2F37),
    child: Center(
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.pause_circle_filled_rounded,
              color: Color(0xFF3196A0),
              size: 38,
            ),
            const SizedBox(height: 7),
            Text(
              english ? 'ARENA PAUSED' : 'ARENA DURAKLATILDI',
              style: const TextStyle(
                color: _AirHockeyInk.color,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 9),
            FilledButton(
              onPressed: onResume,
              child: Text(english ? 'RESUME' : 'DEVAM ET'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AirHockeyTablePainter extends CustomPainter {
  const _AirHockeyTablePainter({required this.engine, required this.scenario});
  final AirHockeyEngine engine;
  final AirHockeyScenario scenario;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(25)),
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[Color(0xFFF2F6F5), Color(0xFFE1EAE9)],
        ).createShader(bounds),
    );
    for (int i = 0; i < 7; i++) {
      final double x = size.width * (.08 + i * .14);
      canvas.drawLine(
        Offset(x, size.height * .04),
        Offset(x + size.width * .025, size.height * .96),
        Paint()
          ..color = const Color(0xFFC4D1D0).withValues(alpha: .15)
          ..strokeWidth = 1,
      );
    }
    final Rect table = Rect.fromLTWH(
      size.width * .075,
      size.height * .035,
      size.width * .85,
      size.height * .93,
    );
    final Rect rail = table.inflate(size.width * .026);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rail.shift(Offset(0, size.height * .017)),
        const Radius.circular(21),
      ),
      Paint()
        ..color = const Color(0xFF1D3540).withValues(alpha: .18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rail, const Radius.circular(21)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF344C59),
            Color(0xFF203944),
            Color(0xFF172F3A),
          ],
        ).createShader(rail),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(table, const Radius.circular(17)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFD4E9E8),
            Color(0xFFB7D9DA),
            Color(0xFF9AC5CC),
          ],
        ).createShader(table),
    );
    final Paint tableLine = Paint()
      ..color = const Color(0xFFF4FFFF).withValues(alpha: .76)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        table.deflate(table.width * .055),
        const Radius.circular(10),
      ),
      tableLine,
    );
    canvas.drawLine(
      Offset(table.left, table.center.dy),
      Offset(table.right, table.center.dy),
      Paint()
        ..color = const Color(0xFF648C95).withValues(alpha: .45)
        ..strokeWidth = 1.1,
    );
    canvas.drawCircle(
      table.center,
      table.width * .14,
      Paint()
        ..color = Colors.white.withValues(alpha: .32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    canvas.drawCircle(
      table.center,
      table.width * .025,
      Paint()..color = Colors.white.withValues(alpha: .7),
    );
    _drawGoal(canvas, table, top: true);
    _drawGoal(canvas, table, top: false);
    _drawHalfCircle(canvas, table, top: true);
    _drawHalfCircle(canvas, table, top: false);
    for (final Offset bumper in scenario.bumpers) {
      _drawBumper(
        canvas,
        _map(bumper, table),
        size.width * AirHockeyEngine.bumperRadius,
      );
    }
    _drawMallet(
      canvas,
      _map(engine.opponentMallet, table),
      size.width * AirHockeyEngine.paddleRadius,
      const Color(0xFF2D8393),
    );
    _drawMallet(
      canvas,
      _map(engine.playerMallet, table),
      size.width * AirHockeyEngine.paddleRadius,
      const Color(0xFFD87962),
    );
    _drawPuck(canvas, size, table);
    _drawLabel(
      canvas,
      'RIVAL',
      Offset(table.center.dx, table.top + table.height * .045),
      size.width * .026,
      const Color(0xFF3B646D).withValues(alpha: .82),
    );
    _drawLabel(
      canvas,
      'YOU',
      Offset(table.center.dx, table.bottom - table.height * .038),
      size.width * .026,
      const Color(0xFF8C5147).withValues(alpha: .85),
    );
  }

  void _drawGoal(Canvas canvas, Rect table, {required bool top}) {
    final double width = table.width * scenario.goalWidth;
    final double y = top ? table.top - 1 : table.bottom - table.height * .018;
    final Rect slot = Rect.fromCenter(
      center: Offset(table.center.dx, y),
      width: width,
      height: table.height * .042,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(slot, const Radius.circular(8)),
      Paint()..color = const Color(0xFF102B36),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(slot.deflate(2), const Radius.circular(6)),
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[Color(0xFF385B67), Color(0xFF152F3B)],
        ).createShader(slot),
    );
    for (int i = 1; i < 9; i++) {
      final double x = slot.left + slot.width * i / 9;
      canvas.drawLine(
        Offset(x, slot.top + 3),
        Offset(x, slot.bottom - 3),
        Paint()
          ..color = const Color(0xFFA6D6D9).withValues(alpha: .38)
          ..strokeWidth = .55,
      );
    }
  }

  void _drawHalfCircle(Canvas canvas, Rect table, {required bool top}) {
    final double y = top ? table.top : table.bottom;
    final Rect arc = Rect.fromCenter(
      center: Offset(table.center.dx, y),
      width: table.width * .42,
      height: table.height * .20,
    );
    canvas.drawArc(
      arc,
      top ? 0 : math.pi,
      math.pi,
      false,
      Paint()
        ..color = const Color(0xFFF3FFFF).withValues(alpha: .55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  void _drawBumper(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center + Offset(0, radius * .30),
      radius * 1.2,
      Paint()
        ..color = const Color(0xFF35535D).withValues(alpha: .22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(
      center,
      radius * 1.12,
      Paint()
        ..shader = const RadialGradient(
          colors: <Color>[
            Color(0xFFF7FFFF),
            Color(0xFF83AFB4),
            Color(0xFF456E77),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 1.12)),
    );
    canvas.drawCircle(
      center,
      radius * .38,
      Paint()..color = const Color(0xFFE6F7F4),
    );
    canvas.drawCircle(
      center,
      radius * 1.12,
      Paint()
        ..color = Colors.white.withValues(alpha: .62)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  void _drawMallet(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, radius * .48),
        width: radius * 2.2,
        height: radius * .75,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: .2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(
      center,
      radius * 1.13,
      Paint()
        ..color = Color.lerp(color, Colors.white, .42)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * .17,
    );
    canvas.drawCircle(
      center,
      radius * .98,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.36, -.46),
          colors: <Color>[
            Color.lerp(color, Colors.white, .38)!,
            color,
            Color.lerp(color, Colors.black, .24)!,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center,
      radius * .31,
      Paint()..color = Colors.white.withValues(alpha: .55),
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * .71),
      math.pi * 1.05,
      math.pi * .76,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: .35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.25,
    );
  }

  void _drawPuck(Canvas canvas, Size size, Rect table) {
    for (int i = engine.trail.length - 1; i >= 0; i--) {
      final double alpha = (1 - i / engine.trail.length) * .19;
      canvas.drawCircle(
        _map(engine.trail[i], table),
        size.width * (.018 - i * .001),
        Paint()..color = const Color(0xFFF6FFFF).withValues(alpha: alpha),
      );
    }
    final Offset center = _map(engine.puck, table);
    final double radius = size.width * AirHockeyEngine.puckRadius;
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(radius * .35, radius * .8),
        width: radius * 2.4,
        height: radius * .8,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: .24)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawCircle(
      center,
      radius * 1.2,
      Paint()..color = Colors.white.withValues(alpha: .54),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.34, -.44),
          colors: <Color>[
            Color(0xFFFFFFFF),
            Color(0xFFE4ECEA),
            Color(0xFF899DA1),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center + Offset(-radius * .28, -radius * .34),
      radius * .2,
      Paint()..color = Colors.white,
    );
  }

  Offset _map(Offset point, Rect table) => Offset(
    table.left + point.dx * table.width,
    table.top + point.dy * table.height,
  );

  void _drawLabel(
    Canvas canvas,
    String value,
    Offset center,
    double fontSize,
    Color color,
  ) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: .7,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _AirHockeyTablePainter oldDelegate) => true;
}
