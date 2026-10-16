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
import 'table_tennis_engine.dart';
import 'table_tennis_scenario.dart';

class TableTennisRallyGamePage extends StatelessWidget {
  const TableTennisRallyGamePage({super.key});

  static const int totalCases = TableTennisScenario.campaignLevels;
  static const int totalStars = totalCases * 3;

  static final List<ParkurLevelSpec>
  _levels = List<ParkurLevelSpec>.generate(totalCases, (int index) {
    final int level = index + 1;
    return ParkurLevelSpec(
      number: level,
      titleTr: 'Ralli ${level.toString().padLeft(2, '0')}',
      titleEn: 'Rally ${level.toString().padLeft(2, '0')}',
      subtitleTr: switch (level) {
        <= 3 => 'Topun gelişini oku; raketi doğru yere taşı ve zamanla.',
        <= 6 => 'Üst spin, kesme ve blok vuruşlarını doğru durumda seç.',
        7 || 8 => 'İleri: rakip hazırlığını izle ve açık köşeye oyna.',
        9 || 10 => 'Uzman maçı: hızlı servisler ve dar zamanlama penceresi.',
        <= 16 => 'Usta masası: spin dizisini ve rakip yerleşimini çöz.',
        _ => 'Final: uzun rallide açıyı, zamanı ve spin cevabını birleştir.',
      },
      subtitleEn: switch (level) {
        <= 3 => 'Read the incoming ball, move into position and time the hit.',
        <= 6 => 'Choose topspin, slice or block for the situation.',
        7 || 8 => 'Advanced: read the setup and attack the open corner.',
        9 || 10 => 'Expert match: faster serves and tighter timing windows.',
        <= 16 => 'Master table: read spin patterns and opponent positioning.',
        _ => 'Final: combine angle, timing and spin under long-rally pressure.',
      },
      difficulty: switch (level) {
        <= 3 => 'ISINMA',
        <= 6 => 'GELİŞİM',
        7 || 8 => 'İLERİ',
        9 || 10 => 'UZMAN',
        <= 16 => 'USTA',
        _ => 'FİNAL',
      },
      icon: Icons.sports_tennis_rounded,
    );
  }, growable: false);

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.fun);
    return ParkurLevelHub(
      gameId: 'table_tennis_rally',
      progressPrefix: 'table_tennis_rally',
      titleTr: 'Masa Tenisi Rallisi',
      titleEn: 'Table Tennis Rally',
      taglineTr: 'Konumlan • Spin seç • Ralliyi bitir',
      taglineEn: 'Get in position • Choose spin • Finish the rally',
      accent: skin.accent,
      icon: Icons.sports_tennis_rounded,
      levels: _levels,
      dailyCourseMode: false,
      playBuilder:
          (
            BuildContext context,
            ParkurLevelSpec level,
            int previousBestScore,
            int? competitionLayoutCode,
            bool competitionMode,
          ) => TableTennisRallyPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class TableTennisRallyPlayPage extends StatefulWidget {
  const TableTennisRallyPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<TableTennisRallyPlayPage> createState() =>
      _TableTennisRallyPlayPageState();
}

class _TableTennisRallyPlayPageState extends State<TableTennisRallyPlayPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const Color _accent = Color(0xFF267C79);
  static const Color _ink = Color(0xFF334B54);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.fun,
  );
  late final Ticker _ticker;
  late TableTennisScenario _scenario;
  late TableTennisEngine _engine;
  late StudioGameSession _session;
  Duration _lastTick = Duration.zero;
  double _playerX = .5;
  double _queuedSeconds = 0;
  TableTennisShot? _queuedShot;
  TableTennisShot _selectedShot = TableTennisShot.topspin;
  bool _ready = false;
  bool _paused = false;
  bool _finished = false;
  bool _english = false;
  String _feedback = '';

  int get _score =>
      (_engine.playerPoints * 180 +
              _engine.playerHits * 16 +
              _engine.longestRally * 22 -
              _engine.unforcedErrors * 9)
          .clamp(0, 10000000)
          .toInt();

  int get _stars {
    final int margin = _engine.playerPoints - _engine.opponentPoints;
    if (margin >= 3 && _engine.unforcedErrors == 0) return 3;
    if (margin >= 1 || _engine.longestRally >= 5) return 2;
    return 1;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_tick);
    unawaited(_audioProfile.preload(_audio));
    unawaited(_prepareMatch());
  }

  Future<void> _prepareMatch() async {
    TableTennisScenario scenario = TableTennisScenario.forLevel(
      widget.level.number,
    );
    try {
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      final String visitKey =
          'table_tennis_rally_level_${widget.level.number}_visits';
      final int visits = await preferences.getInt(visitKey) ?? 0;
      if (visits > 0) {
        final int practiceIndex =
            await preferences.getInt('table_tennis_rally_practice_index') ?? 0;
        if (practiceIndex < TableTennisScenario.practiceRallies) {
          final int next = practiceIndex + 1;
          await preferences.setInt('table_tennis_rally_practice_index', next);
          scenario = TableTennisScenario.forPracticeRally(next);
        }
      }
      await preferences.setInt(visitKey, visits + 1);
    } catch (_) {
      // Keep the stable campaign match if preferences are unavailable.
    }
    if (!mounted) return;
    _scenario = scenario;
    _resetMatch();
    setState(() => _ready = true);
  }

  void _resetMatch() {
    _ticker.stop();
    _engine = TableTennisEngine(scenario: _scenario);
    _session = StudioGameSession(
      level: widget.level.number,
      seed: _scenario.seed,
    )..start();
    _playerX = .5;
    _queuedSeconds = 0;
    _queuedShot = null;
    _paused = false;
    _finished = false;
    _feedback = '';
    _lastTick = Duration.zero;
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

  void _movePaddle(double localX, double width) {
    if (!_ready || _paused || _finished || width <= 0) return;
    setState(() => _playerX = (localX / width).clamp(.075, .925).toDouble());
  }

  void _chooseShot(TableTennisShot shot) {
    if (!_ready || _paused || _finished) return;
    setState(() => _selectedShot = shot);
  }

  void _hit() {
    if (!_ready || _paused || _finished) return;
    _queuedShot = _selectedShot;
    _queuedSeconds = .23;
    _audio.hapticLight();
  }

  void _tick(Duration elapsed) {
    if (!_ready || _paused || _finished) return;
    final double raw = (elapsed - _lastTick).inMicroseconds / 1000000;
    _lastTick = elapsed;
    if (raw <= 0) return;
    final double delta = raw.clamp(0, .04).toDouble();
    if (_queuedSeconds > 0) {
      _queuedSeconds = math.max(0, _queuedSeconds - delta);
      if (_queuedSeconds == 0) _queuedShot = null;
    }
    final RallyStepResult result = _engine.step(
      deltaSeconds: delta,
      playerPaddleX: _playerX,
      shot: _queuedSeconds > 0 ? _queuedShot : null,
    );
    if (result.playerHit) {
      _queuedShot = null;
      _queuedSeconds = 0;
      _session.recordAccepted(points: 18);
      _feedback = _shotFeedback(_selectedShot);
      unawaited(
        _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .24),
      );
    }
    if (result.opponentHit) {
      unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .16));
      _feedback = _english
          ? 'RALLY · READ THE NEXT ANGLE'
          : 'RALLİ · SONRAKİ AÇIYI OKU';
    }
    if (result.pointWinner != null) {
      if (result.pointWinner == RallyPointWinner.player) {
        _session.recordAccepted(points: 90);
        _feedback = _english
            ? 'POINT · KEEP THE PRESSURE'
            : 'SAYI · BASKIYI SÜRDÜR';
        unawaited(
          _audioProfile.play(_audio, GameAudioEvent.accepted, gain: .26),
        );
      } else {
        _session.recordMistake();
        _feedback = result.playerMiss
            ? (_english
                  ? 'LATE · RESET YOUR POSITION'
                  : 'GEÇ KALDIN · POZİSYON AL')
            : (_english ? 'OPPONENT POINT' : 'RAKİP SAYI ALDI');
        unawaited(
          _audioProfile.play(_audio, GameAudioEvent.rejected, gain: .19),
        );
      }
    }
    if (result.matchOver) {
      unawaited(_finishMatch(playerWon: result.playerWon));
    } else if (mounted && !_finished) {
      setState(() {});
    }
  }

  String _shotFeedback(TableTennisShot shot) => switch (shot) {
    TableTennisShot.topspin =>
      _english ? 'TOPSPIN · FAST ATTACK' : 'ÜST SPİN · HIZLI ATAK',
    TableTennisShot.slice =>
      _english ? 'SLICE · LATE MOVEMENT' : 'KESME · GEÇ AÇILAN AÇI',
    TableTennisShot.block =>
      _english ? 'BLOCK · CONTROLLED RETURN' : 'BLOK · KONTROLLÜ DÖNÜŞ',
  };

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
              title: Text(_english ? 'Match point' : 'Maç tamamlandı'),
              content: Text(
                _english
                    ? 'The opponent won this set. Move early, then time the contact instead of swinging at every ball.'
                    : 'Bu seti rakip aldı. Topa erken konumlan; her gelişte değil, temas penceresinde vur.',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(_english ? 'Match map' : 'Maç haritası'),
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
      action: widget.level.number < TableTennisRallyGamePage.totalCases
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
      titleTr: 'SET TAMAMLANDI',
      titleEn: 'SET COMPLETE',
      detailTr:
          '${_engine.playerPoints}–${_engine.opponentPoints} sayı · ${_engine.longestRally} vuruşluk en uzun ralli',
      detailEn:
          '${_engine.playerPoints}–${_engine.opponentPoints} points · ${_engine.longestRally}-hit best rally',
      stars: _stars,
      score: _score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < TableTennisRallyGamePage.totalCases,
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
        appBar: AppBar(title: Text(_english ? 'TABLE TENNIS' : 'MASA TENİSİ')),
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
          _english ? 'TABLE TENNIS · RALLY' : 'MASA TENİSİ · RALLİ',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
        ),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('table_tennis_rally_pause'),
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
                  _RallyScoreCard(
                    player: _engine.playerPoints,
                    opponent: _engine.opponentPoints,
                    target: _scenario.pointsToWin,
                    hits: _engine.currentRallyHits,
                    english: _english,
                  ),
                  const SizedBox(height: 7),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints limits) {
                        final double width = math.min(limits.maxWidth, 510);
                        final double height = math.min(
                          limits.maxHeight,
                          width * .98,
                        );
                        final Size sceneSize = Size(width, height);
                        return Center(
                          child: SizedBox(
                            key: const ValueKey<String>(
                              'table_tennis_rally_scene',
                            ),
                            width: width,
                            height: height,
                            child: Stack(
                              fit: StackFit.expand,
                              children: <Widget>[
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTapDown: (TapDownDetails details) =>
                                      _movePaddle(
                                        details.localPosition.dx,
                                        sceneSize.width,
                                      ),
                                  onHorizontalDragUpdate:
                                      (DragUpdateDetails details) =>
                                          _movePaddle(
                                            details.localPosition.dx,
                                            sceneSize.width,
                                          ),
                                  child: CustomPaint(
                                    painter: _RallyTablePainter(
                                      engine: _engine,
                                      scenario: _scenario,
                                      accent: _accent,
                                    ),
                                  ),
                                ),
                                if (_paused)
                                  _RallyPauseOverlay(
                                    english: _english,
                                    onResume: () => _setPaused(false),
                                  ),
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 5,
                                  child: IgnorePointer(
                                    child: Center(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: .82,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          child: Text(
                                            _english
                                                ? 'DRAG TO POSITION'
                                                : 'SÜRÜKLEYEREK KONUMLAN',
                                            style: const TextStyle(
                                              color: _ink,
                                              fontSize: 8,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: .5,
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
                                  ? 'READ THE BOUNCE · MOVE FIRST · HIT IN THE CONTACT WINDOW'
                                  : 'SEKİŞİ OKU · ÖNCE YERLEŞ · TEMAS PENCERESİNDE VUR'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _feedback.isEmpty
                              ? StudioVisuals.muted
                              : _accent,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  _ShotControls(
                    selected: _selectedShot,
                    enabled: !_paused && !_finished,
                    english: _english,
                    onSelect: _chooseShot,
                    onHit: _hit,
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

class _RallyScoreCard extends StatelessWidget {
  const _RallyScoreCard({
    required this.player,
    required this.opponent,
    required this.target,
    required this.hits,
    required this.english,
  });

  final int player;
  final int opponent;
  final int target;
  final int hits;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey<String>('table_tennis_rally_hud'),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: StudioVisuals.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: StudioVisuals.line),
      boxShadow: StudioVisuals.softShadow,
    ),
    child: Row(
      children: <Widget>[
        Expanded(
          child: _ScoreSide(
            label: english ? 'YOU' : 'SEN',
            value: player,
            color: const Color(0xFF267C79),
            align: CrossAxisAlignment.start,
          ),
        ),
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
              english ? 'RALLY  $hits' : 'RALLİ  $hits',
              style: const TextStyle(
                color: _RallyScoreCardInk.value,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        Expanded(
          child: _ScoreSide(
            label: english ? 'RIVAL' : 'RAKİP',
            value: opponent,
            color: _RallyScoreCardInk.coral,
            align: CrossAxisAlignment.end,
          ),
        ),
      ],
    ),
  );
}

abstract final class _RallyScoreCardInk {
  static const Color value = Color(0xFF334B54);
  static const Color coral = Color(0xFFD46F58);
}

class _ScoreSide extends StatelessWidget {
  const _ScoreSide({
    required this.label,
    required this.value,
    required this.color,
    required this.align,
  });

  final String label;
  final int value;
  final Color color;
  final CrossAxisAlignment align;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: align,
    children: <Widget>[
      Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: .6,
        ),
      ),
      Text(
        '$value',
        style: TextStyle(
          color: color,
          fontSize: 24,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

class _ShotControls extends StatelessWidget {
  const _ShotControls({
    required this.selected,
    required this.enabled,
    required this.english,
    required this.onSelect,
    required this.onHit,
  });

  final TableTennisShot selected;
  final bool enabled;
  final bool english;
  final ValueChanged<TableTennisShot> onSelect;
  final VoidCallback onHit;

  @override
  Widget build(BuildContext context) {
    final List<(TableTennisShot, String, IconData)> shots =
        <(TableTennisShot, String, IconData)>[
          (
            TableTennisShot.topspin,
            english ? 'TOPSPIN' : 'ÜST SPİN',
            Icons.trending_up_rounded,
          ),
          (
            TableTennisShot.slice,
            english ? 'SLICE' : 'KESME',
            Icons.south_east_rounded,
          ),
          (
            TableTennisShot.block,
            english ? 'BLOCK' : 'BLOK',
            Icons.shield_outlined,
          ),
        ];
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            for (final (TableTennisShot shot, String label, IconData icon)
                in shots) ...<Widget>[
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    key: ValueKey<String>('table_tennis_shot_${shot.name}'),
                    onPressed: enabled ? () => onSelect(shot) : null,
                    icon: Icon(icon, size: 15),
                    label: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: selected == shot
                          ? Colors.white
                          : _RallyScoreCardInk.value,
                      backgroundColor: selected == shot
                          ? const Color(0xFF267C79)
                          : Colors.white,
                      side: BorderSide(
                        color: selected == shot
                            ? const Color(0xFF267C79)
                            : StudioVisuals.line,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      textStyle: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                  ),
                ),
              ),
              if (shot != TableTennisShot.block) const SizedBox(width: 6),
            ],
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            key: const ValueKey<String>('table_tennis_rally_hit'),
            onPressed: enabled ? onHit : null,
            icon: const Icon(Icons.sports_tennis_rounded, size: 19),
            label: Text(
              english ? 'HIT · TIME YOUR RETURN' : 'VUR · ZAMANLAMAYI YAKALA',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD46F58),
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: .45,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RallyPauseOverlay extends StatelessWidget {
  const _RallyPauseOverlay({required this.english, required this.onResume});
  final bool english;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xA51C3034),
    child: Center(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.pause_circle_filled_rounded,
              color: Color(0xFF267C79),
              size: 38,
            ),
            const SizedBox(height: 8),
            Text(
              english ? 'RALLY PAUSED' : 'RALLİ DURAKLATILDI',
              style: const TextStyle(
                color: _RallyScoreCardInk.value,
                fontWeight: FontWeight.w900,
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

class _RallyTablePainter extends CustomPainter {
  const _RallyTablePainter({
    required this.engine,
    required this.scenario,
    required this.accent,
  });

  final TableTennisEngine engine;
  final TableTennisScenario scenario;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(26)),
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[Color(0xFFF5F7F5), Color(0xFFE7EEEA)],
        ).createShader(bounds),
    );
    for (int i = 0; i < 6; i++) {
      final double y = size.height * (.09 + i * .16);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + size.width * .07),
        Paint()
          ..color = const Color(0xFFCAD8D1).withValues(alpha: .15)
          ..strokeWidth = 1,
      );
    }

    final Rect table = Rect.fromCenter(
      center: Offset(size.width * .5, size.height * .485),
      width: size.width * .72,
      height: size.height * .84,
    );
    final Rect frame = table.inflate(size.width * .028);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        frame.shift(Offset(0, size.height * .025)),
        const Radius.circular(20),
      ),
      Paint()
        ..color = const Color(0xFF172C30).withValues(alpha: .18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(frame, const Radius.circular(18)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFC89564),
            Color(0xFF8F5C3D),
            Color(0xFF704630),
          ],
        ).createShader(frame),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(table, const Radius.circular(12)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF3B9690),
            Color(0xFF287D79),
            Color(0xFF1D6869),
          ],
        ).createShader(table),
    );

    final Rect upperHalf = Rect.fromLTWH(
      table.left + 2,
      table.top + 2,
      table.width - 4,
      table.height * .49,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        upperHalf,
        topLeft: const Radius.circular(10),
        topRight: const Radius.circular(10),
      ),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF469C94), Color(0xFF348982)],
        ).createShader(upperHalf),
    );
    final Rect lowerHalf = Rect.fromLTWH(
      table.left + 2,
      table.center.dy,
      table.width - 4,
      table.bottom - table.center.dy - 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        lowerHalf,
        bottomLeft: const Radius.circular(10),
        bottomRight: const Radius.circular(10),
      ),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF32867F), Color(0xFF246E70)],
        ).createShader(lowerHalf),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(table, const Radius.circular(12)),
      Paint()
        ..color = const Color(0xFFEAF5E8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
    final double inset = table.width * .062;
    final Rect play = table.deflate(inset);
    canvas.drawRRect(
      RRect.fromRectAndRadius(play, const Radius.circular(5)),
      Paint()
        ..color = Colors.white.withValues(alpha: .82)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.25,
    );

    final double midY = table.center.dy;
    canvas.drawLine(
      Offset(table.left + 3, midY + 2),
      Offset(table.right - 3, midY + 2),
      Paint()
        ..color = const Color(0xFF153E40).withValues(alpha: .45)
        ..strokeWidth = size.width * .025
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(table.left + 3, midY),
      Offset(table.right - 3, midY),
      Paint()
        ..color = const Color(0xFFE9F0E7)
        ..strokeWidth = size.width * .014
        ..strokeCap = StrokeCap.round,
    );
    for (int i = 0; i <= 23; i++) {
      final double x = table.left + table.width * i / 23;
      canvas.drawLine(
        Offset(x, midY - size.width * .018),
        Offset(x, midY + size.width * .018),
        Paint()
          ..color = const Color(0xFFD8E7DD).withValues(alpha: .8)
          ..strokeWidth = .65,
      );
    }

    _drawPaddle(
      canvas,
      size,
      Offset(
        table.left + table.width * engine.opponentX,
        table.top + table.height * .145,
      ),
      size.width * .068,
      const Color(0xFF344A5B),
      upper: true,
      angle: -engine.velocity.dx * .18,
    );
    _drawPaddle(
      canvas,
      size,
      Offset(
        table.left + table.width * engine.playerX,
        table.top + table.height * .855,
      ),
      size.width * .074,
      const Color(0xFFD46F58),
      upper: false,
      angle: engine.velocity.dx * .16,
    );
    _drawBall(canvas, size, table);
    _drawLabel(
      canvas,
      'RIVAL',
      Offset(table.center.dx, table.top + table.height * .07),
      size.width * .032,
      Colors.white.withValues(alpha: .78),
    );
    _drawLabel(
      canvas,
      'YOU',
      Offset(table.center.dx, table.bottom - table.height * .055),
      size.width * .032,
      Colors.white.withValues(alpha: .82),
    );
    if (scenario.surface == TableSurface.sideWind) {
      _drawLabel(
        canvas,
        'SIDE SPIN',
        Offset(table.center.dx, table.center.dy - size.width * .045),
        size.width * .025,
        const Color(0xFFE6CE92),
      );
    }
  }

  void _drawPaddle(
    Canvas canvas,
    Size size,
    Offset center,
    double radius,
    Color color, {
    required bool upper,
    required double angle,
  }) {
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, radius * .42),
        width: radius * 2.2,
        height: radius * .68,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: .19)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle.clamp(-.28, .28));
    final double handleTop = upper ? -radius * 1.15 : radius * .24;
    final Rect handle = Rect.fromCenter(
      center: Offset(0, handleTop + radius * .45),
      width: radius * .35,
      height: radius * .95,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(handle, Radius.circular(radius * .16)),
      Paint()
        ..shader = LinearGradient(
          colors: <Color>[const Color(0xFFE4B985), const Color(0xFFAA704C)],
        ).createShader(handle),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, upper ? radius * .04 : -radius * .04),
        width: radius * 2.0,
        height: radius * 1.52,
      ),
      Paint()
        ..color = const Color(0xFF152A2E).withValues(alpha: .28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * .25,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, upper ? 0 : 0),
        width: radius * 1.9,
        height: radius * 1.43,
      ),
      Paint()
        ..shader =
            RadialGradient(
              center: const Alignment(-.35, -.48),
              colors: <Color>[
                Color.lerp(color, Colors.white, .35)!,
                color,
                Color.lerp(color, Colors.black, .20)!,
              ],
            ).createShader(
              Rect.fromCenter(
                center: Offset.zero,
                width: radius * 1.9,
                height: radius * 1.43,
              ),
            ),
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset.zero,
        width: radius * 1.34,
        height: radius * .86,
      ),
      math.pi * 1.12,
      math.pi * .78,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: .16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.restore();
  }

  void _drawBall(Canvas canvas, Size size, Rect table) {
    for (int i = engine.trail.length - 1; i >= 0; i--) {
      final Offset point = engine.trail[i];
      final double alpha = (1 - i / engine.trail.length) * .22;
      canvas.drawCircle(
        _map(point, table),
        size.width * (.012 - i * .00035),
        Paint()..color = const Color(0xFFFFE5A2).withValues(alpha: alpha),
      );
    }
    final Offset center = _map(engine.ball, table);
    final double radius = size.width * .022;
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(radius * .42, radius * .76),
        width: radius * 2.4,
        height: radius * .75,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: .22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawCircle(
      center,
      radius * 1.14,
      Paint()..color = Colors.white.withValues(alpha: .68),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.38, -.42),
          colors: <Color>[
            Color(0xFFFFF9D9),
            Color(0xFFFFD773),
            Color(0xFFF0A941),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center + Offset(-radius * .27, -radius * .30),
      radius * .22,
      Paint()..color = Colors.white.withValues(alpha: .85),
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
          letterSpacing: .8,
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
  bool shouldRepaint(covariant _RallyTablePainter oldDelegate) => true;
}
