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
import 'penalty_engine.dart';
import 'penalty_scenario.dart';

class PenaltyMindgamePage extends StatelessWidget {
  const PenaltyMindgamePage({super.key});

  static const int totalCases = PenaltyScenario.campaignLevels;
  static const int totalStars = totalCases * 3;

  static final List<ParkurLevelSpec>
  _levels = List<ParkurLevelSpec>.generate(totalCases, (int index) {
    final int level = index + 1;
    return ParkurLevelSpec(
      number: level,
      titleTr: 'Penaltı ${level.toString().padLeft(2, '0')}',
      titleEn: 'Shootout ${level.toString().padLeft(2, '0')}',
      subtitleTr: switch (level) {
        <= 3 => 'Şut köşesini seç; kalede geliş yönünü takip et.',
        <= 6 => 'Gücü ayarla ve omuz, kalça, basış ipuçlarını çapraz oku.',
        7 || 8 => 'İleri: bir ipucu aldatıcı, diğer ikisi yönü gösterir.',
        9 || 10 => 'Uzman serisi: dar dalış penceresinde iki rolü de oyna.',
        <= 16 => 'Usta serisi: değişen hızda koşuyu ve kaleci eğilimini çöz.',
        _ => 'Final baskısı: beş atış ve ani ölüm kararlarında soğukkanlı kal.',
      },
      subtitleEn: switch (level) {
        <= 3 => 'Choose a shot corner, then track the incoming kick as keeper.',
        <= 6 => 'Set power and cross-check shoulder, hip and plant-foot cues.',
        7 || 8 => 'Advanced: one cue lies; the other two reveal the direction.',
        9 || 10 => 'Expert set: play both roles inside a narrow dive window.',
        <= 16 => 'Master set: read changing run-up pace and goalkeeper bias.',
        _ =>
          'Final pressure: stay composed through five shots and sudden death.',
      },
      difficulty: switch (level) {
        <= 3 => 'ISINMA',
        <= 6 => 'GELİŞİM',
        7 || 8 => 'İLERİ',
        9 || 10 => 'UZMAN',
        <= 16 => 'USTA',
        _ => 'FİNAL',
      },
      icon: Icons.sports_soccer_rounded,
    );
  }, growable: false);

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.fun);
    return ParkurLevelHub(
      gameId: 'penalty_mindgame',
      progressPrefix: 'penalty_mindgame',
      titleTr: 'Penaltı Zihin Oyunu',
      titleEn: 'Penalty Mindgame',
      taglineTr: 'Duruşu oku • Gücü ayarla • Zamanında dal',
      taglineEn: 'Read the stance • Set the power • Dive on time',
      accent: skin.accent,
      icon: Icons.sports_soccer_rounded,
      levels: _levels,
      dailyCourseMode: false,
      playBuilder:
          (
            BuildContext context,
            ParkurLevelSpec level,
            int previousBestScore,
            int? competitionLayoutCode,
            bool competitionMode,
          ) => PenaltyMindgamePlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class PenaltyMindgamePlayPage extends StatefulWidget {
  const PenaltyMindgamePlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<PenaltyMindgamePlayPage> createState() =>
      _PenaltyMindgamePlayPageState();
}

class _PenaltyMindgamePlayPageState extends State<PenaltyMindgamePlayPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const Color _accent = Color(0xFF2C8A72);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.fun,
  );
  late final Ticker _ticker;
  late PenaltyScenario _scenario;
  late PenaltyMindgameEngine _engine;
  late StudioGameSession _session;
  Duration _lastTick = Duration.zero;
  PenaltyLane _shotLane = PenaltyLane.center;
  PenaltyLane _keeperLane = PenaltyLane.center;
  double _power = .72;
  bool _ready = false;
  bool _paused = false;
  bool _finished = false;
  bool _english = false;
  String _feedback = '';

  int get _score =>
      (_engine.playerGoals * 260 +
              _engine.playerSaves * 210 +
              _engine.perfectReads * 85 -
              _engine.playerWideShots * 35)
          .clamp(0, 10000000)
          .toInt();

  int get _stars {
    final int difference =
        _engine.playerGoals + _engine.playerSaves - _engine.opponentGoals;
    if (difference >= 4 && _engine.playerWideShots == 0) return 3;
    if (difference >= 1 || _engine.perfectReads >= 2) return 2;
    return 1;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_tick);
    unawaited(_audioProfile.preload(_audio));
    unawaited(_prepareShootout());
  }

  Future<void> _prepareShootout() async {
    PenaltyScenario scenario = PenaltyScenario.forLevel(widget.level.number);
    try {
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      final String visitKey =
          'penalty_mindgame_level_${widget.level.number}_visits';
      final int visits = await preferences.getInt(visitKey) ?? 0;
      if (visits > 0) {
        final int index =
            await preferences.getInt('penalty_mindgame_practice_index') ?? 0;
        if (index < PenaltyScenario.practiceShootouts) {
          final int next = index + 1;
          await preferences.setInt('penalty_mindgame_practice_index', next);
          scenario = PenaltyScenario.forPracticeShootout(next);
        }
      }
      await preferences.setInt(visitKey, visits + 1);
    } catch (_) {
      // Keep the reproducible campaign set if local progress storage is absent.
    }
    if (!mounted) return;
    _scenario = scenario;
    _resetShootout();
    setState(() => _ready = true);
  }

  void _resetShootout() {
    _ticker.stop();
    _engine = PenaltyMindgameEngine(scenario: _scenario);
    _session = StudioGameSession(
      level: widget.level.number,
      seed: _scenario.seed,
    )..start();
    _shotLane = PenaltyLane.center;
    _keeperLane = PenaltyLane.center;
    _power = .72;
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

  void _tick(Duration elapsed) {
    if (!_ready || _paused || _finished) return;
    final double raw = (elapsed - _lastTick).inMicroseconds / 1000000;
    _lastTick = elapsed;
    if (raw <= 0) return;
    final PenaltyPhase previousPhase = _engine.phase;
    final PenaltyActionResult? event = _engine.step(
      raw.clamp(0, .04).toDouble(),
    );
    if (previousPhase != _engine.phase) {
      _feedback = switch (_engine.phase) {
        PenaltyPhase.opponentRunUp =>
          _english
              ? 'READ THE SHOULDER, HIP AND PLANT FOOT'
              : 'OMUZU, KALÇAYI VE DESTEK AYAĞINI OKU',
        PenaltyPhase.playerShot => '',
        _ => _feedback,
      };
    }
    if (event?.automatic == true) {
      _session.recordMistake();
      _feedback = _english ? 'LATE · GOAL SCORED' : 'GEÇ KALDIN · GOL OLDU';
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .22));
    }
    if (_engine.matchOver) {
      unawaited(_finishShootout(playerWon: _engine.playerWon));
    } else if (mounted && !_finished) {
      setState(() {});
    }
  }

  void _takeShot() {
    if (!_ready ||
        _paused ||
        _finished ||
        _engine.phase != PenaltyPhase.playerShot) {
      return;
    }
    final PenaltyActionResult result = _engine.shoot(
      lane: _shotLane,
      power: _power,
    );
    _session.recordAccepted(
      points: result.outcome == PenaltyOutcome.goal ? 70 : 18,
    );
    _feedback = result.outcome == PenaltyOutcome.goal
        ? (_english ? 'GOAL · CLEAN STRIKE' : 'GOL · TEMİZ VURUŞ')
        : result.outcome == PenaltyOutcome.wide
        ? (_english ? 'WIDE · LOWER THE POWER' : 'DIŞARI · GÜCÜ AZALT')
        : (_english
              ? 'SAVED · CHANGE THE CORNER'
              : 'KURTARDI · DİĞER KÖŞEYİ DENE');
    unawaited(
      _audioProfile.play(
        _audio,
        result.outcome == PenaltyOutcome.goal
            ? GameAudioEvent.accepted
            : GameAudioEvent.primaryAction,
        gain: .25,
      ),
    );
    _audio.hapticLight();
    setState(() {});
  }

  void _dive() {
    if (!_ready || _paused || _finished || !_engine.canDive) return;
    final PenaltyActionResult result = _engine.dive(lane: _keeperLane);
    if (result.outcome == PenaltyOutcome.keeperSave) {
      _session.recordAccepted(points: 85);
      _feedback = _english
          ? 'SAVED · READ THE BODY CUES'
          : 'KURTARDIN · İPUÇLARINI OKUDUN';
      unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .3));
      _audio.hapticMedium();
    } else {
      _session.recordMistake();
      _feedback = _english
          ? 'GOAL · CHECK THE PLANT FOOT'
          : 'GOL · DESTEK AYAĞINA DİKKAT ET';
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .2));
    }
    setState(() {});
  }

  Future<void> _finishShootout({required bool playerWon}) async {
    if (_finished || !mounted) return;
    _finished = true;
    _ticker.stop();
    if (!playerWon) {
      final bool retry =
          await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) => AlertDialog(
              title: Text(_english ? 'Shootout over' : 'Seri tamamlandı'),
              content: Text(
                _english
                    ? 'Use all three body cues and wait for the plant foot before diving. Adjust power to keep your own shots on target.'
                    : 'Üç beden ipucunu birlikte oku; dalış için destek ayağını bekle. Kendi şutlarında gücü ayarlayıp kaleyi bul.',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(_english ? 'Shootout map' : 'Seri haritası'),
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
        setState(_resetShootout);
      } else {
        Navigator.of(context)
            .pop(StudioGameResult.failed(score: _score).toParkurResult());
      }
      return;
    }
    _session.complete(
      stars: _stars,
      action: widget.level.number < PenaltyMindgamePage.totalCases
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
      titleTr: 'PENALTI SERİSİ TAMAMLANDI',
      titleEn: 'SHOOTOUT COMPLETE',
      detailTr:
          '${_engine.playerGoals} gol · ${_engine.playerSaves} kurtarış · ${_engine.perfectReads} temiz okuma',
      detailEn:
          '${_engine.playerGoals} goals · ${_engine.playerSaves} saves · ${_engine.perfectReads} clean reads',
      stars: _stars,
      score: _score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < PenaltyMindgamePage.totalCases,
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
          title: Text(_english ? 'PENALTY MINDGAME' : 'PENALTI ZİHİN OYUNU'),
        ),
        body: const Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    final bool shotPhase = _engine.phase == PenaltyPhase.playerShot;
    final bool keeperPhase = _engine.phase == PenaltyPhase.opponentRunUp;
    final bool controlsEnabled = !_paused && !_finished;
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _english ? 'PENALTY · READ & REACT' : 'PENALTI · OKU VE TEPKİ VER',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
        ),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('penalty_mindgame_pause'),
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
                  _ShootoutScoreCard(
                    player: _engine.playerGoals,
                    opponent: _engine.opponentGoals,
                    round: _engine.currentRound,
                    regulation: _scenario.roundCount,
                    english: _english,
                  ),
                  const SizedBox(height: 7),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints limits) {
                        final double width = math.min(limits.maxWidth, 610);
                        final double height = math.min(
                          limits.maxHeight,
                          width * .70,
                        );
                        return Center(
                          child: SizedBox(
                            key: const ValueKey<String>(
                              'penalty_mindgame_scene',
                            ),
                            width: width,
                            height: height,
                            child: Stack(
                              fit: StackFit.expand,
                              children: <Widget>[
                                CustomPaint(
                                  painter: _PenaltyScenePainter(
                                    engine: _engine,
                                    scenario: _scenario,
                                    shotLane: _shotLane,
                                    keeperLane: _keeperLane,
                                  ),
                                ),
                                if (_paused)
                                  _PenaltyPauseOverlay(
                                    english: _english,
                                    onResume: () => _setPaused(false),
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
                            : keeperPhase
                            ? (_english
                                  ? 'CUE WINDOW · READ BODY LANGUAGE BEFORE THE DIVE'
                                  : 'İPUCU PENCERESİ · DALMADAN BEDEN DİLİNİ OKU')
                            : (_english
                                  ? 'SHOOTER: SET POWER · KEEPER: WAIT FOR THE PLANT FOOT'
                                  : 'ŞUTÖR: GÜCÜ AYARLA · KALECİ: DESTEK AYAĞINI BEKLE'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _feedback.isEmpty
                              ? StudioVisuals.muted
                              : _accent,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  if (shotPhase)
                    _ShotControls(
                      lane: _shotLane,
                      power: _power,
                      enabled: controlsEnabled,
                      english: _english,
                      onLane: (PenaltyLane lane) =>
                          setState(() => _shotLane = lane),
                      onPower: (double value) => setState(() => _power = value),
                      onAction: _takeShot,
                    )
                  else
                    _KeeperControls(
                      lane: _keeperLane,
                      progress: _engine.runUpProgress,
                      enabled: controlsEnabled && keeperPhase,
                      english: _english,
                      onLane: (PenaltyLane lane) =>
                          setState(() => _keeperLane = lane),
                      onAction: _dive,
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

class _ShootoutScoreCard extends StatelessWidget {
  const _ShootoutScoreCard({
    required this.player,
    required this.opponent,
    required this.round,
    required this.regulation,
    required this.english,
  });

  final int player;
  final int opponent;
  final int round;
  final int regulation;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey<String>('penalty_mindgame_hud'),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: StudioVisuals.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: StudioVisuals.line),
      boxShadow: StudioVisuals.softShadow,
    ),
    child: Row(
      children: <Widget>[
        _ShootoutTeam(
          label: english ? 'YOU' : 'SEN',
          score: player,
          color: const Color(0xFF2C8A72),
        ),
        const Spacer(),
        Column(
          children: <Widget>[
            Text(
              english
                  ? 'SHOT $round / $regulation'
                  : 'ATIŞ $round / $regulation',
              style: const TextStyle(
                color: StudioVisuals.muted,
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              english ? 'BOTH ROLES' : 'İKİ ROL',
              style: const TextStyle(
                color: _PenaltySceneInk.color,
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: .5,
              ),
            ),
          ],
        ),
        const Spacer(),
        _ShootoutTeam(
          label: english ? 'RIVAL' : 'RAKİP',
          score: opponent,
          color: const Color(0xFFD5765D),
        ),
      ],
    ),
  );
}

class _ShootoutTeam extends StatelessWidget {
  const _ShootoutTeam({
    required this.label,
    required this.score,
    required this.color,
  });
  final String label;
  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.center,
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

class _ShotControls extends StatelessWidget {
  const _ShotControls({
    required this.lane,
    required this.power,
    required this.enabled,
    required this.english,
    required this.onLane,
    required this.onPower,
    required this.onAction,
  });
  final PenaltyLane lane;
  final double power;
  final bool enabled;
  final bool english;
  final ValueChanged<PenaltyLane> onLane;
  final ValueChanged<double> onPower;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      _LanePicker(
        lane: lane,
        enabled: enabled,
        english: english,
        onLane: onLane,
      ),
      Row(
        children: <Widget>[
          Text(
            english ? 'POWER' : 'GÜÇ',
            style: const TextStyle(
              color: StudioVisuals.muted,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
          Expanded(
            child: Slider(
              key: const ValueKey<String>('penalty_mindgame_power'),
              value: power,
              min: .4,
              max: 1,
              divisions: 12,
              activeColor: const Color(0xFF2C8A72),
              onChanged: enabled ? onPower : null,
            ),
          ),
          Text(
            '${(power * 100).round()}%',
            style: const TextStyle(
              color: _PenaltySceneInk.color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
      SizedBox(
        width: double.infinity,
        height: 45,
        child: FilledButton.icon(
          key: const ValueKey<String>('penalty_mindgame_shoot'),
          onPressed: enabled ? onAction : null,
          icon: const Icon(Icons.sports_soccer_rounded, size: 18),
          label: Text(english ? 'TAKE THE SHOT' : 'ŞUTU ÇEK'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2C8A72),
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: .4,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    ],
  );
}

class _KeeperControls extends StatelessWidget {
  const _KeeperControls({
    required this.lane,
    required this.progress,
    required this.enabled,
    required this.english,
    required this.onLane,
    required this.onAction,
  });
  final PenaltyLane lane;
  final double progress;
  final bool enabled;
  final bool english;
  final ValueChanged<PenaltyLane> onLane;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: LinearProgressIndicator(
          key: const ValueKey<String>('penalty_mindgame_runup'),
          value: progress.clamp(0, 1).toDouble(),
          minHeight: 6,
          backgroundColor: const Color(0xFFE3E9E4),
          valueColor: AlwaysStoppedAnimation<Color>(
            progress > .82 ? const Color(0xFFD5765D) : const Color(0xFF2C8A72),
          ),
        ),
      ),
      const SizedBox(height: 5),
      _LanePicker(
        lane: lane,
        enabled: enabled,
        english: english,
        onLane: onLane,
      ),
      const SizedBox(height: 5),
      SizedBox(
        width: double.infinity,
        height: 45,
        child: FilledButton.icon(
          key: const ValueKey<String>('penalty_mindgame_dive'),
          onPressed: enabled ? onAction : null,
          icon: const Icon(Icons.waves_rounded, size: 18),
          label: Text(english ? 'DIVE NOW' : 'ŞİMDİ DAL'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFD5765D),
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: .4,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    ],
  );
}

class _LanePicker extends StatelessWidget {
  const _LanePicker({
    required this.lane,
    required this.enabled,
    required this.english,
    required this.onLane,
  });
  final PenaltyLane lane;
  final bool enabled;
  final bool english;
  final ValueChanged<PenaltyLane> onLane;

  @override
  Widget build(BuildContext context) {
    final List<(PenaltyLane, String)> lanes = <(PenaltyLane, String)>[
      (PenaltyLane.left, english ? 'LEFT' : 'SOL'),
      (PenaltyLane.center, english ? 'CENTER' : 'ORTA'),
      (PenaltyLane.right, english ? 'RIGHT' : 'SAĞ'),
    ];
    return Row(
      children: <Widget>[
        for (final (PenaltyLane value, String label) in lanes) ...<Widget>[
          Expanded(
            child: SizedBox(
              height: 39,
              child: OutlinedButton(
                key: ValueKey<String>('penalty_mindgame_lane_${value.name}'),
                onPressed: enabled ? () => onLane(value) : null,
                style: OutlinedButton.styleFrom(
                  backgroundColor: lane == value
                      ? const Color(0xFFE7F2EA)
                      : Colors.white,
                  foregroundColor: lane == value
                      ? const Color(0xFF236F5C)
                      : _PenaltySceneInk.color,
                  side: BorderSide(
                    color: lane == value
                        ? const Color(0xFF4A9B7B)
                        : StudioVisuals.line,
                    width: lane == value ? 1.4 : 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .35,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          if (value != PenaltyLane.right) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

abstract final class _PenaltySceneInk {
  static const Color color = Color(0xFF344D4B);
}

class _PenaltyPauseOverlay extends StatelessWidget {
  const _PenaltyPauseOverlay({required this.english, required this.onResume});
  final bool english;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xA51C3034),
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
              color: Color(0xFF2C8A72),
              size: 38,
            ),
            const SizedBox(height: 7),
            Text(
              english ? 'SHOOTOUT PAUSED' : 'PENALTI SERİSİ DURAKLATILDI',
              style: const TextStyle(
                color: _PenaltySceneInk.color,
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

class _PenaltyScenePainter extends CustomPainter {
  const _PenaltyScenePainter({
    required this.engine,
    required this.scenario,
    required this.shotLane,
    required this.keeperLane,
  });
  final PenaltyMindgameEngine engine;
  final PenaltyScenario scenario;
  final PenaltyLane shotLane;
  final PenaltyLane keeperLane;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(24)),
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[Color(0xFFF4F7F3), Color(0xFFE6EEE7)],
        ).createShader(bounds),
    );
    final Rect field = Rect.fromLTWH(
      size.width * .055,
      size.height * .055,
      size.width * .89,
      size.height * .89,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        field.shift(Offset(0, size.height * .012)),
        const Radius.circular(18),
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: .12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(field, const Radius.circular(18)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF5DA17D),
            Color(0xFF438B6B),
            Color(0xFF337957),
          ],
        ).createShader(field),
    );
    final Paint line = Paint()
      ..color = const Color(0xFFE7F1DF).withValues(alpha: .78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final Rect box = Rect.fromLTWH(
      field.left + field.width * .17,
      field.top + field.height * .05,
      field.width * .66,
      field.height * .35,
    );
    canvas.drawRect(box, line);
    canvas.drawRect(
      Rect.fromLTWH(
        field.left + field.width * .31,
        field.top + field.height * .05,
        field.width * .38,
        field.height * .16,
      ),
      line,
    );
    canvas.drawCircle(
      Offset(field.center.dx, field.top + field.height * .41),
      field.width * .09,
      line,
    );
    canvas.drawLine(
      Offset(field.left + field.width * .04, field.top + field.height * .52),
      Offset(field.right - field.width * .04, field.top + field.height * .52),
      Paint()
        ..color = Colors.white.withValues(alpha: .10)
        ..strokeWidth = 1,
    );
    _drawGoal(canvas, field);
    final double goalCenter = field.center.dx;
    final double laneWidth = field.width * .17;
    final double goalY = field.top + field.height * .13;
    final double shooterY = field.top + field.height * .76;
    final double keeperLean = switch (engine.phase) {
      PenaltyPhase.playerShot => _laneOffset(engine.currentKeeperRead) * .09,
      PenaltyPhase.opponentRunUp =>
        _laneOffset(engine.currentCue.majority) * .075,
      _ => 0,
    };
    _drawAthlete(
      canvas,
      Offset(goalCenter + keeperLean * size.width, goalY),
      size.width * .055,
      const Color(0xFFE6B65A),
      keeper: true,
      action: engine.phase == PenaltyPhase.saveFlight
          ? _laneOffset(keeperLane)
          : keeperLean,
    );
    _drawAthlete(
      canvas,
      Offset(goalCenter, shooterY),
      size.width * .061,
      const Color(0xFF324D69),
      keeper: false,
      action: engine.phase == PenaltyPhase.opponentRunUp
          ? _laneOffset(engine.currentCue.hip) * .34
          : _laneOffset(shotLane) * .18,
    );
    final double spotY = field.top + field.height * .64;
    canvas.drawCircle(
      Offset(goalCenter, spotY),
      size.width * .008,
      Paint()..color = const Color(0xFFF0F3D9),
    );
    _drawBall(canvas, size, goalCenter, spotY, laneWidth);
    if (engine.phase == PenaltyPhase.opponentRunUp) {
      _drawCuePips(canvas, size, field);
      final double windowStart = .66 - scenario.diveTimingWindow;
      final double windowEnd = .66 + scenario.diveTimingWindow;
      final double progress = engine.runUpProgress;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            field.left + field.width * .28,
            field.bottom - field.height * .085,
            field.width * .44,
            5,
          ),
          const Radius.circular(3),
        ),
        Paint()..color = Colors.white.withValues(alpha: .35),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            field.left + field.width * (.28 + .44 * windowStart),
            field.bottom - field.height * .085,
            field.width * .44 * (windowEnd - windowStart),
            5,
          ),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFFFFD36B),
      );
      canvas.drawCircle(
        Offset(
          field.left + field.width * (.28 + .44 * progress.clamp(0, 1)),
          field.bottom - field.height * .085 + 2.5,
        ),
        4,
        Paint()..color = const Color(0xFFFFF9E9),
      );
    }
    _drawLabel(
      canvas,
      engine.phase == PenaltyPhase.opponentRunUp
          ? 'READ THE STRIKER'
          : 'CHOOSE YOUR CORNER',
      Offset(field.center.dx, field.bottom - field.height * .025),
      size.width * .022,
      Colors.white.withValues(alpha: .86),
    );
  }

  void _drawGoal(Canvas canvas, Rect field) {
    final Rect goal = Rect.fromLTWH(
      field.left + field.width * .21,
      field.top + field.height * .035,
      field.width * .58,
      field.height * .13,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        goal.shift(Offset(0, 3)),
        const Radius.circular(7),
      ),
      Paint()
        ..color = const Color(0xFF20383B).withValues(alpha: .22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawRect(
      goal,
      Paint()..color = const Color(0xFFE9F3E5).withValues(alpha: .18),
    );
    for (int i = 0; i <= 12; i++) {
      final double x = goal.left + goal.width * i / 12;
      canvas.drawLine(
        Offset(x, goal.top + 2),
        Offset(x, goal.bottom),
        Paint()
          ..color = Colors.white.withValues(alpha: .26)
          ..strokeWidth = .55,
      );
    }
    for (int i = 0; i <= 5; i++) {
      final double y = goal.top + goal.height * i / 5;
      canvas.drawLine(
        Offset(goal.left, y),
        Offset(goal.right, y),
        Paint()
          ..color = Colors.white.withValues(alpha: .23)
          ..strokeWidth = .55,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(goal, const Radius.circular(6)),
      Paint()
        ..color = const Color(0xFFF0F4E6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2,
    );
    final double third = goal.width / 3;
    for (int index = 0; index < 3; index++) {
      final Rect lane = Rect.fromLTWH(
        goal.left + index * third,
        goal.top + 1,
        third,
        goal.height - 2,
      );
      final PenaltyLane direction = PenaltyLane.values[index];
      final bool selected =
          engine.phase == PenaltyPhase.playerShot && direction == shotLane;
      if (selected) {
        canvas.drawRect(
          lane,
          Paint()..color = const Color(0xFFFFF0B6).withValues(alpha: .16),
        );
      }
    }
  }

  void _drawAthlete(
    Canvas canvas,
    Offset center,
    double radius,
    Color kit, {
    required bool keeper,
    required double action,
  }) {
    final double lean = action.clamp(-1, 1).toDouble();
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, radius * 1.75),
        width: radius * 2.1,
        height: radius * .65,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: .19)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.save();
    canvas.translate(center.dx + lean * radius * .55, center.dy);
    canvas.rotate(lean * .27);
    canvas.drawCircle(
      Offset(0, -radius * .92),
      radius * .48,
      Paint()
        ..shader =
            RadialGradient(
              center: const Alignment(-.3, -.5),
              colors: <Color>[const Color(0xFFFFD8B7), const Color(0xFFBF815F)],
            ).createShader(
              Rect.fromCircle(
                center: Offset(0, -radius * .92),
                radius: radius * .48,
              ),
            ),
    );
    final Rect torso = Rect.fromCenter(
      center: Offset(0, 0),
      width: radius * (keeper ? 1.28 : 1.18),
      height: radius * 1.63,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(torso, Radius.circular(radius * .38)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color.lerp(kit, Colors.white, .2)!,
            kit,
            Color.lerp(kit, Colors.black, .16)!,
          ],
        ).createShader(torso),
    );
    final double armSpread = keeper ? .95 : .66;
    final double armY = -.12 * radius;
    final Paint limbs = Paint()
      ..color = const Color(0xFF293D42)
      ..strokeWidth = radius * .23
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(-radius * .35, armY),
      Offset(-radius * armSpread, armY - radius * .28 - lean * radius * .35),
      limbs,
    );
    canvas.drawLine(
      Offset(radius * .35, armY),
      Offset(radius * armSpread, armY - radius * .28 + lean * radius * .35),
      limbs,
    );
    canvas.drawLine(
      Offset(-radius * .24, radius * .65),
      Offset(-radius * .33, radius * 1.35),
      limbs,
    );
    canvas.drawLine(
      Offset(radius * .24, radius * .65),
      Offset(radius * .33, radius * 1.35),
      limbs,
    );
    canvas.restore();
  }

  void _drawCuePips(Canvas canvas, Size size, Rect field) {
    final List<PenaltyLane> cues = <PenaltyLane>[
      engine.currentCue.shoulder,
      engine.currentCue.hip,
      engine.currentCue.plantFoot,
    ];
    final double centerX = field.center.dx;
    final double y = field.top + field.height * .53;
    for (int index = 0; index < cues.length; index++) {
      final Offset position = Offset(
        centerX + (index - 1) * field.width * .16,
        y,
      );
      canvas.drawCircle(
        position,
        size.width * .018,
        Paint()..color = const Color(0xFFF4DA8C).withValues(alpha: .92),
      );
      final double offset = _laneOffset(cues[index]) * size.width * .016;
      canvas.drawLine(
        position - Offset(0, size.width * .012),
        position + Offset(offset, size.width * .012),
        Paint()
          ..color = const Color(0xFF344D4B)
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
    }
    _drawLabel(
      canvas,
      'SHOULDER       HIP       PLANT',
      Offset(centerX, y + size.width * .052),
      size.width * .018,
      Colors.white.withValues(alpha: .86),
    );
  }

  void _drawBall(
    Canvas canvas,
    Size size,
    double centerX,
    double spotY,
    double laneWidth,
  ) {
    final double progress = switch (engine.phase) {
      PenaltyPhase.shotFlight =>
        (engine.phaseSeconds / .48).clamp(0, 1).toDouble(),
      PenaltyPhase.saveFlight =>
        (engine.phaseSeconds / .52).clamp(0, 1).toDouble(),
      _ => 0,
    };
    final PenaltyLane lane = engine.phase == PenaltyPhase.shotFlight
        ? (engine.lastPlayerLane ?? shotLane)
        : engine.phase == PenaltyPhase.saveFlight
        ? (engine.currentKickLane)
        : shotLane;
    final double targetX = centerX + _laneOffset(lane) * laneWidth * .9;
    final Offset start = Offset(centerX, spotY);
    final Offset end = Offset(targetX, size.height * .15);
    final Offset position = Offset.lerp(start, end, progress) ?? start;
    final double arc = math.sin(progress * math.pi) * size.width * .055;
    final Offset ball = position.translate(0, -arc);
    canvas.drawOval(
      Rect.fromCenter(
        center: position.translate(size.width * .018, size.width * .018),
        width: size.width * .04,
        height: size.width * .015,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: .20)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    if (progress > 0) {
      canvas.drawLine(
        start,
        position,
        Paint()
          ..color = Colors.white.withValues(alpha: .18 + progress * .12)
          ..strokeWidth = size.width * .006
          ..strokeCap = StrokeCap.round,
      );
    }
    final double radius = size.width * .018;
    canvas.drawCircle(
      ball,
      radius * 1.12,
      Paint()..color = Colors.white.withValues(alpha: .55),
    );
    canvas.drawCircle(
      ball,
      radius,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.35, -.42),
          colors: <Color>[
            Color(0xFFFFF9EB),
            Color(0xFFEAEDE2),
            Color(0xFFB8C2B8),
          ],
        ).createShader(Rect.fromCircle(center: ball, radius: radius)),
    );
  }

  double _laneOffset(PenaltyLane lane) => switch (lane) {
    PenaltyLane.left => -1,
    PenaltyLane.center => 0,
    PenaltyLane.right => 1,
  };

  void _drawLabel(
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
          letterSpacing: .55,
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
  bool shouldRepaint(covariant _PenaltyScenePainter oldDelegate) => true;
}
