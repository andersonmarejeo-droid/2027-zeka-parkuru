import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/catalog/domain/studio_game_catalog.dart';
import '../../l10n/app_localizations.dart';
import '../../services/game_audio_service.dart';
import '../../theme/studio_visuals.dart';
import '../shared/game_audio_profile.dart';
import '../shared/parkur_game_kit.dart';
import '../shared/studio_game_session.dart';
import '../shared/studio_game_skin.dart';
import 'relic_run_engine.dart';
import 'relic_run_scenario.dart';

class RelicRunGamePage extends StatelessWidget {
  const RelicRunGamePage({super.key});

  static const int totalCases = RelicRunScenario.campaignLevels;
  static const int totalStars = totalCases * 3;

  static final List<ParkurLevelSpec> _levels = List<ParkurLevelSpec>.generate(
    totalCases,
    (int index) {
      final int level = index + 1;
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Sefer ${level.toString().padLeft(2, '0')}',
        titleEn: 'Expedition ${level.toString().padLeft(2, '0')}',
        subtitleTr: switch (level) {
          <= 3 => 'Düşman işaretini oku; bir hamle önden karar ver.',
          <= 6 => 'Nöbetçi, takipçi ve menzilli tehdidi ayırt et.',
          7 || 8 => 'İleri: üç oda, daha sıkı tuzak ağı ve koruyucu.',
          9 || 10 => 'Uzman: yan yana tehditlerde kaçınma yönünü seç.',
          <= 16 => 'Usta: zırhı, menzili ve kalıntı gücünü birlikte yönet.',
          _ => 'Final seferi: koruyucuyu oku, iki kalıntıyı doğru seç.',
        },
        subtitleEn: switch (level) {
          <= 3 => 'Read the enemy tell and decide one move ahead.',
          <= 6 => 'Separate the sentinel, stalker and ranged threat.',
          7 || 8 => 'Advanced: three rooms, denser traps and a guardian.',
          9 || 10 => 'Expert: choose a dodge lane through overlapping threats.',
          <= 16 => 'Master: manage armour, range and relic power together.',
          _ =>
            'Final expedition: read the guardian and choose two relics well.',
        },
        difficulty: switch (level) {
          <= 3 => 'KEŞİF',
          <= 6 => 'DERİNLEŞME',
          7 || 8 => 'İLERİ',
          9 || 10 => 'UZMAN',
          <= 16 => 'USTA',
          _ => 'FİNAL',
        },
        icon: Icons.explore_rounded,
      );
    },
    growable: false,
  );

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.fun);
    return ParkurLevelHub(
      gameId: 'relic_run',
      progressPrefix: 'relic_run',
      titleTr: 'Kalıntı Seferi',
      titleEn: 'Relic Run',
      taglineTr: 'Oku • Konumlan • Karşılık ver',
      taglineEn: 'Read • Reposition • Counter',
      accent: skin.accent,
      icon: Icons.explore_rounded,
      levels: _levels,
      dailyCourseMode: false,
      playBuilder: (
        BuildContext context,
        ParkurLevelSpec level,
        int previousBestScore,
        int? competitionLayoutCode,
        bool competitionMode,
      ) => RelicRunPlayPage(level: level, previousBestScore: previousBestScore),
    );
  }
}

class RelicRunPlayPage extends StatefulWidget {
  const RelicRunPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<RelicRunPlayPage> createState() => _RelicRunPlayPageState();
}

class _RelicRunPlayPageState extends State<RelicRunPlayPage>
    with WidgetsBindingObserver {
  static const Color _accent = Color(0xFF438F94);
  static const Color _amber = Color(0xFFD09B56);
  static const Color _ink = Color(0xFF35464F);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.fun,
  );
  late RelicRunScenario _scenario;
  late RelicRunEngine _engine;
  late StudioGameSession _session;
  bool _ready = false;
  bool _paused = false;
  bool _finished = false;
  bool _english = false;
  bool _choiceDialogOpen = false;
  String _feedback = '';

  int get _score =>
      (_engine.kills * 120 +
              _engine.health * 3 +
              _engine.relicsCollected * 80 +
              math.max(0, 100 - _engine.actions))
          .clamp(0, 10000000)
          .toInt();

  int get _stars {
    if (_engine.damageTaken <= 18 && _engine.relicsCollected == 2) return 3;
    if (_engine.health >= 36 && _engine.relicsCollected >= 1) return 2;
    return 1;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_audioProfile.preload(_audio));
    unawaited(_prepareRun());
  }

  Future<void> _prepareRun() async {
    RelicRunScenario scenario = RelicRunScenario.forLevel(widget.level.number);
    try {
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      final String visitKey = 'relic_run_level_${widget.level.number}_visits';
      final int visits = await preferences.getInt(visitKey) ?? 0;
      if (visits > 0) {
        final int index =
            await preferences.getInt('relic_run_practice_index') ?? 0;
        if (index < RelicRunScenario.practiceRuns) {
          final int next = index + 1;
          await preferences.setInt('relic_run_practice_index', next);
          scenario = RelicRunScenario.forPracticeRun(next);
        }
      }
      await preferences.setInt(visitKey, visits + 1);
    } catch (_) {
      // The authored campaign remains playable when local persistence is absent.
    }
    if (!mounted) return;
    _scenario = scenario;
    _engine = RelicRunEngine(scenario: scenario);
    _session = StudioGameSession(
      level: widget.level.number,
      seed: scenario.seed,
    )..start();
    setState(() => _ready = true);
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
    if (!_ready ||
        _finished ||
        _engine.awaitingRelicChoice ||
        _paused == value) {
      return;
    }
    setState(() => _paused = value);
    if (value) {
      _session.pause();
    } else {
      _session.resume();
    }
    unawaited(_audio.play(GameSound.uiClick, gain: .22));
  }

  void _move(int dx, int dy) => _apply(_engine.move(dx, dy));
  void _attack() => _apply(_engine.attack());
  void _dodge() => _apply(_engine.dodge());
  void _relic() => _apply(_engine.activateRelic());

  void _apply(RelicRunActionResult result) {
    if (!_ready || _paused || _finished) return;
    if (!result.accepted) {
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .16));
      return;
    }
    if (result.hit) {
      _session.recordAccepted(points: result.kill ? 80 : 28);
      unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .24));
      _audio.hapticLight();
      _feedback = result.kill
          ? (_english
                ? 'THREAT CLEARED · RELIC CHARGED'
                : 'TEHDİT TEMİZLENDİ · KALINTI DOLDU')
          : (_english
                ? 'CLEAN STRIKE · READ THE NEXT TELL'
                : 'TEMİZ VURUŞ · SIRADAKİ İŞARETİ OKU');
    } else if (result.dodged) {
      _session.recordAccepted(points: 14);
      unawaited(
        _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .21),
      );
      _audio.hapticLight();
      _feedback = _english
          ? 'EVADE · LANE BROKEN'
          : 'KAÇINMA · SALDIRI HATTI BOZULDU';
    } else {
      _session.recordAccepted(points: 4);
      unawaited(
        _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .16),
      );
      _feedback = result.trapTriggered
          ? (_english
                ? 'TRAP SPRUNG · WATCH YOUR FOOTING'
                : 'TUZAK TETİKLENDİ · ADIMINI KOLLA')
          : (result.relicActivated
                ? (_english
                      ? 'RELIC PULSE · ROOM CONTROLLED'
                      : 'KALINTI DARBESİ · ODA KONTROLDE')
                : (_english
                      ? 'POSITION HELD · WATCH THE MARKED TILES'
                      : 'KONUM ALINDI · İŞARETLİ HÜCRELERİ İZLE'));
    }
    if (result.damageReceived > 0) {
      _session.recordMistake();
      _feedback = _english
          ? 'HIT TAKEN · ${result.damageReceived} · REPOSITION BEFORE THE NEXT WIND-UP'
          : 'DARBE ALDIN · ${result.damageReceived} · YENİ İŞARETTE YER DEĞİŞTİR';
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .23));
    }
    if (_engine.livingFoes.isEmpty && !result.roomCleared) {
      _feedback = _english
          ? 'EXIT OPEN · REACH THE GLOWING ARCH'
          : 'ÇIKIŞ AÇIK · IŞIKLI KAPIYA ULAŞ';
    }
    setState(() {});
    if (result.roomCleared && !result.completed) _promptRelicChoice();
    if (result.completed) unawaited(_finishRun());
    if (result.failed) unawaited(_offerRetry());
  }

  void _promptRelicChoice() {
    if (_choiceDialogOpen || !mounted) return;
    _choiceDialogOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_showRelicChoice());
    });
  }

  Future<void> _showRelicChoice() async {
    final RelicRunRelic? relic = await showDialog<RelicRunRelic>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(_english ? 'CHOOSE A RELIC' : 'BİR KALINTI SEÇ'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                _english
                    ? 'Room ${_engine.roomIndex + 1} is clear. Shape the next room to your style.'
                    : '${_engine.roomIndex + 1}. oda temiz. Sonraki odayı oyun tarzına göre güçlendir.',
                style: const TextStyle(
                  color: StudioVisuals.muted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              for (final RelicRunRelic option in _engine.currentRelicOffer)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _RelicChoiceCard(
                    relic: option,
                    english: _english,
                    onTap: () => Navigator.pop(dialogContext, option),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    _choiceDialogOpen = false;
    if (!mounted || relic == null) return;
    final RelicRunActionResult result = _engine.chooseRelic(relic);
    if (result.accepted) {
      _feedback = _english
          ? '${_relicName(relic, true).toUpperCase()} RELIC · ROOM ${_engine.roomIndex + 1}'
          : '${context.l10n.uppercaseLabel(_relicName(relic, false))} KALINTISI · ${_engine.roomIndex + 1}. ODA';
      unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .2));
    }
    setState(() {});
  }

  Future<void> _offerRetry() async {
    if (_finished || !mounted) return;
    _finished = true;
    _session.fail();
    final bool retry =
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: Text(_english ? 'EXPEDITION LOST' : 'SEFER SONLANDI'),
            content: Text(
              _english
                  ? 'Enemy marks show their next strike. Dodge out of the lane, then punish one exposed foe at a time.'
                  : 'Düşman işaretleri sıradaki saldırıyı gösterir. Hattan kaçın, sonra açıkta kalan tek tehdide karşılık ver.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(_english ? 'MAP' : 'HARİTA'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(dialogContext, true),
                icon: const Icon(Icons.restart_alt_rounded),
                label: Text(_english ? 'RETRY' : 'YENİDEN DENE'),
              ),
            ],
          ),
        ) ??
        false;
    if (!mounted) return;
    if (retry) {
      _engine = RelicRunEngine(scenario: _scenario);
      _session = StudioGameSession(
        level: widget.level.number,
        seed: _scenario.seed,
      )..start();
      _finished = false;
      _feedback = '';
      setState(() {});
    } else {
      Navigator.of(context)
          .pop(StudioGameResult.failed(score: _score).toParkurResult());
    }
  }

  Future<void> _finishRun() async {
    if (_finished || !mounted) return;
    _finished = true;
    _session.complete(
      stars: _stars,
      action: widget.level.number < RelicRunGamePage.totalCases
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
      titleTr: 'SEFER TAMAMLANDI',
      titleEn: 'EXPEDITION COMPLETE',
      detailTr:
          '${_engine.kills} tehdit · ${_engine.relicsCollected} kalıntı · ${_engine.health} sağlık kaldı',
      detailEn:
          '${_engine.kills} threats · ${_engine.relicsCollected} relics · ${_engine.health} health left',
      stars: _stars,
      score: _score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < RelicRunGamePage.totalCases,
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

  void _aimAt(Offset local, Size size) {
    if (!_ready || _paused || _finished || size.isEmpty) return;
    final RelicCell cell = (
      x: (local.dx / size.width * RelicRunScenario.columns)
          .floor()
          .clamp(0, RelicRunScenario.columns - 1)
          .toInt(),
      y: (local.dy / size.height * RelicRunScenario.rows)
          .floor()
          .clamp(0, RelicRunScenario.rows - 1)
          .toInt(),
    );
    if (_engine.aimAt(cell)) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _english = context.l10n.isEnglish;
    if (!_ready) {
      return Scaffold(
        backgroundColor: StudioVisuals.canvas,
        appBar: AppBar(title: Text(_english ? 'RELIC RUN' : 'KALINTI SEFERİ')),
        body: const Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    final bool active = !_paused && !_engine.awaitingRelicChoice && !_finished;
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _english
              ? 'RELIC RUN · EXPEDITION ${widget.level.number}'
              : 'KALINTI SEFERİ · ${widget.level.number}. SEFER',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: .25,
          ),
        ),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('relic_run_pause'),
            tooltip: _paused
                ? (_english ? 'Resume' : 'Devam et')
                : (_english ? 'Pause' : 'Duraklat'),
            onPressed: _engine.awaitingRelicChoice
                ? null
                : () => _setPaused(!_paused),
            icon: Icon(
              _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Stack(
        children: <Widget>[
          SafeArea(
            top: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 5, 10, 9),
                  child: Column(
                    children: <Widget>[
                      _RelicRunHud(
                        health: _engine.health,
                        maxHealth: _engine.maxHealth,
                        room: _engine.roomIndex + 1,
                        charge: _engine.relicCharge,
                        foes: _engine.livingFoes.length,
                        guardian: _engine.roomHasGuardian,
                        english: _english,
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: LayoutBuilder(
                          builder:
                              (BuildContext context, BoxConstraints limits) {
                                final double side = math.min(
                                  limits.maxWidth,
                                  limits.maxHeight,
                                );
                                final Size boardSize = Size(side, side);
                                return Center(
                                  child: SizedBox(
                                    key: const ValueKey<String>(
                                      'relic_run_board',
                                    ),
                                    width: side,
                                    height: side,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTapDown: (TapDownDetails details) =>
                                          _aimAt(
                                            details.localPosition,
                                            boardSize,
                                          ),
                                      child: CustomPaint(
                                        painter: _RelicRunBoardPainter(
                                          engine: _engine,
                                        ),
                                      ),
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
                                      ? 'MARKED CELLS ARE NEXT · TAP A TARGET TO AIM'
                                      : 'İŞARETLİ HÜCRELER SIRADAKİ SALDIRI · HEDEFE DOKUN VE NİŞAN AL'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 7.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .08,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_engine.awaitingRelicChoice)
                        _RelicRewardStrip(
                          offers: _engine.currentRelicOffer,
                          english: _english,
                          onChoose: (RelicRunRelic relic) {
                            final RelicRunActionResult result = _engine
                                .chooseRelic(relic);
                            if (result.accepted) {
                              _feedback = _english
                                  ? 'RELIC BONDED · ROOM ${_engine.roomIndex + 1}'
                                  : 'KALINTI BAĞLANDI · ${_engine.roomIndex + 1}. ODA';
                              setState(() {});
                            }
                          },
                        )
                      else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            _RelicDirectionPad(
                              enabled: active,
                              onDirection: _move,
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Column(
                                children: <Widget>[
                                  SizedBox(
                                    height: 43,
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      key: const ValueKey<String>(
                                        'relic_run_attack',
                                      ),
                                      onPressed: active ? _attack : null,
                                      icon: const Icon(
                                        Icons.bolt_rounded,
                                        size: 15,
                                      ),
                                      label: Text(
                                        _english ? 'STRIKE' : 'VUR',
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: _accent,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    height: 43,
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      key: const ValueKey<String>(
                                        'relic_run_dodge',
                                      ),
                                      onPressed: active && _engine.dodgeReady
                                          ? _dodge
                                          : null,
                                      icon: const Icon(
                                        Icons.north_east_rounded,
                                        size: 14,
                                      ),
                                      label: Text(
                                        _english ? 'EVADE' : 'KAÇIN',
                                        style: const TextStyle(
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: _ink,
                                        padding: EdgeInsets.zero,
                                        side: const BorderSide(
                                          color: Color(0xFFD6DFDC),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    height: 43,
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      key: const ValueKey<String>(
                                        'relic_run_skill',
                                      ),
                                      onPressed:
                                          active && _engine.relicCharge >= 2
                                          ? _relic
                                          : null,
                                      icon: const Icon(
                                        Icons.auto_awesome_rounded,
                                        size: 14,
                                      ),
                                      label: Text(
                                        _english
                                            ? 'RELIC ${_engine.relicCharge}/2'
                                            : 'KALINTI ${_engine.relicCharge}/2',
                                        style: const TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: _amber,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_paused)
            _RelicPauseOverlay(
              english: _english,
              onResume: () => _setPaused(false),
            ),
        ],
      ),
    );
  }
}

class _RelicRunHud extends StatelessWidget {
  const _RelicRunHud({
    required this.health,
    required this.maxHealth,
    required this.room,
    required this.charge,
    required this.foes,
    required this.guardian,
    required this.english,
  });

  final int health;
  final int maxHealth;
  final int room;
  final int charge;
  final int foes;
  final bool guardian;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey<String>('relic_run_hud'),
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(
      color: StudioVisuals.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: StudioVisuals.line),
      boxShadow: StudioVisuals.softShadow,
    ),
    child: Row(
      children: <Widget>[
        Icon(
          Icons.favorite_rounded,
          color: health <= 32
              ? const Color(0xFFCF755F)
              : _RelicRunPalette.accent,
          size: 17,
        ),
        const SizedBox(width: 5),
        SizedBox(
          width: 68,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '$health / $maxHealth',
                style: const TextStyle(
                  color: _RelicRunPalette.ink,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: health / maxHealth,
                  minHeight: 4,
                  color: health <= 32
                      ? const Color(0xFFCF755F)
                      : _RelicRunPalette.accent,
                  backgroundColor: const Color(0xFFE8EEEA),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Column(
          children: <Widget>[
            Text(
              english ? 'ROOM $room / 3' : 'ODA $room / 3',
              style: const TextStyle(
                color: _RelicRunPalette.ink,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: .25,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              guardian
                  ? (english ? 'GUARDIAN' : 'KORUYUCU')
                  : (english ? '$foes THREATS' : '$foes TEHDİT'),
              style: TextStyle(
                color: guardian ? _RelicRunPalette.amber : StudioVisuals.muted,
                fontSize: 7.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F5F0),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.auto_awesome_rounded,
                size: 13,
                color: _RelicRunPalette.amber,
              ),
              const SizedBox(width: 4),
              Text(
                '$charge / 2',
                style: const TextStyle(
                  color: _RelicRunPalette.ink,
                  fontSize: 9,
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

class _RelicDirectionPad extends StatelessWidget {
  const _RelicDirectionPad({required this.enabled, required this.onDirection});
  final bool enabled;
  final void Function(int dx, int dy) onDirection;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 136,
    height: 136,
    child: Column(
      children: <Widget>[
        _dpadRow(null, (0, -1), null),
        _dpadRow((-1, 0), null, (1, 0)),
        _dpadRow(null, (0, 1), null),
      ],
    ),
  );

  Widget _dpadRow((int, int)? left, (int, int)? middle, (int, int)? right) =>
      Expanded(
        child: Row(
          children: <Widget>[
            _dpadButton(left),
            _dpadButton(middle),
            _dpadButton(right),
          ],
        ),
      );

  Widget _dpadButton((int, int)? direction) => Expanded(
    child: Padding(
      padding: const EdgeInsets.all(2),
      child: direction == null
          ? const SizedBox.expand()
          : Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              child: InkWell(
                onTap: enabled
                    ? () => onDirection(direction.$1, direction.$2)
                    : null,
                borderRadius: BorderRadius.circular(13),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: const Color(0xFFD9E2DE)),
                  ),
                  child: Icon(
                    switch (direction) {
                      (-1, 0) => Icons.west_rounded,
                      (1, 0) => Icons.east_rounded,
                      (0, -1) => Icons.north_rounded,
                      _ => Icons.south_rounded,
                    },
                    color: _RelicRunPalette.ink,
                    size: 18,
                  ),
                ),
              ),
            ),
    ),
  );
}

class _RelicRewardStrip extends StatelessWidget {
  const _RelicRewardStrip({
    required this.offers,
    required this.english,
    required this.onChoose,
  });
  final List<RelicRunRelic> offers;
  final bool english;
  final ValueChanged<RelicRunRelic> onChoose;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 136,
    child: Row(
      children: <Widget>[
        for (final RelicRunRelic relic in offers)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _RelicChoiceCard(
                relic: relic,
                english: english,
                onTap: () => onChoose(relic),
              ),
            ),
          ),
      ],
    ),
  );
}

class _RelicChoiceCard extends StatelessWidget {
  const _RelicChoiceCard({
    required this.relic,
    required this.english,
    required this.onTap,
  });
  final RelicRunRelic relic;
  final bool english;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (
      IconData icon,
      Color color,
      String tr,
      String en,
      String detailTr,
      String detailEn,
    ) = switch (relic) {
      RelicRunRelic.ember => (
        Icons.local_fire_department_rounded,
        const Color(0xFFC97F59),
        'Kor Ateşi',
        'Cinderheart',
        'Yönlü saldırı +1 hasar',
        '+1 damage on strikes',
      ),
      RelicRunRelic.aegis => (
        Icons.shield_moon_rounded,
        const Color(0xFF598DA2),
        'Ay Kalkanı',
        'Moon Aegis',
        'Sağlık +12, anında +24',
        '+12 max health, restore 24',
      ),
      RelicRunRelic.echo => (
        Icons.waves_rounded,
        const Color(0xFF7D83B2),
        'Yankı Camı',
        'Echo Glass',
        'Kaçınma yenilenir, +1 enerji',
        'Reset evade, +1 charge',
      ),
      RelicRunRelic.prism => (
        Icons.change_history_rounded,
        const Color(0xFF9B7EAC),
        'Prizma Kıvılcımı',
        'Prism Spark',
        'Kalıntı darbesi +2 hasar',
        '+2 relic pulse damage',
      ),
    };
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFDCE5E1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon, color: color, size: 18),
              const Spacer(),
              Text(
                english ? en : tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _RelicRunPalette.ink,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                english ? detailEn : detailTr,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: StudioVisuals.muted,
                  fontSize: 8,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _relicName(RelicRunRelic relic, bool english) => switch (relic) {
  RelicRunRelic.ember => english ? 'Cinderheart' : 'Kor Ateşi',
  RelicRunRelic.aegis => english ? 'Moon Aegis' : 'Ay Kalkanı',
  RelicRunRelic.echo => english ? 'Echo Glass' : 'Yankı Camı',
  RelicRunRelic.prism => english ? 'Prism Spark' : 'Prizma Kıvılcımı',
};

class _RelicPauseOverlay extends StatelessWidget {
  const _RelicPauseOverlay({required this.english, required this.onResume});
  final bool english;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: ColoredBox(
      color: const Color(0xA52B3639),
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
                color: _RelicRunPalette.accent,
                size: 38,
              ),
              const SizedBox(height: 7),
              Text(
                english ? 'EXPEDITION PAUSED' : 'SEFER DURAKLATILDI',
                style: const TextStyle(
                  color: _RelicRunPalette.ink,
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
    ),
  );
}

abstract final class _RelicRunPalette {
  static const Color ink = Color(0xFF35464F);
  static const Color accent = Color(0xFF438F94);
  static const Color amber = Color(0xFFD09B56);
}

class _RelicRunBoardPainter extends CustomPainter {
  const _RelicRunBoardPainter({required this.engine});
  final RelicRunEngine engine;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect board = Offset.zero & size;
    final RRect frame = RRect.fromRectAndRadius(
      board,
      const Radius.circular(23),
    );
    canvas.drawRRect(
      frame,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF45545A),
            Color(0xFF25383F),
            Color(0xFF1E3035),
          ],
        ).createShader(board),
    );
    final double cellW = size.width / RelicRunScenario.columns;
    final double cellH = size.height / RelicRunScenario.rows;
    final Set<RelicCell> walls = engine.walls.toSet();
    final Set<RelicCell> traps = engine.traps.toSet();
    final Set<RelicCell> warnings = engine.telegraphedCells.toSet();
    for (int y = 0; y < RelicRunScenario.rows; y++) {
      for (int x = 0; x < RelicRunScenario.columns; x++) {
        final RelicCell cell = (x: x, y: y);
        final Rect rect = Rect.fromLTWH(
          x * cellW,
          y * cellH,
          cellW,
          cellH,
        ).deflate(1.3);
        final bool corridor = x == 4 || y == 4;
        final Color base = (x + y).isEven
            ? const Color(0xFFE6E2D7)
            : const Color(0xFFDDDCCF);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(5)),
          Paint()
            ..color = corridor
                ? Color.lerp(base, const Color(0xFFF1EDE2), .48)!
                : base,
        );
        canvas.drawLine(
          rect.topLeft + Offset(3, 1),
          rect.topRight - Offset(3, 0),
          Paint()
            ..color = Colors.white.withValues(alpha: .34)
            ..strokeWidth = 1,
        );
        if (warnings.contains(cell)) {
          _drawWarning(canvas, rect);
        }
        if (traps.contains(cell)) {
          _drawTrap(canvas, rect);
        }
        if (cell == RelicRunEngine.exitCell) {
          _drawExit(canvas, rect, engine.exitOpen);
        }
        if (walls.contains(cell)) {
          _drawWall(canvas, rect);
        }
      }
    }
    for (final RelicRunFoeState foe in engine.livingFoes) {
      _drawFoe(
        canvas,
        _center(foe.cell, cellW, cellH),
        math.min(cellW, cellH) * .36,
        foe,
      );
    }
    _drawHero(
      canvas,
      _center(engine.player, cellW, cellH),
      math.min(cellW, cellH) * .37,
      engine.facing,
    );
    final TextPainter exitLabel = TextPainter(
      text: TextSpan(
        text: engine.exitOpen ? 'EXIT' : 'SEALED',
        style: TextStyle(
          color: engine.exitOpen ? Colors.white : const Color(0xFF936E44),
          fontSize: math.max(5, cellW * .12),
          fontWeight: FontWeight.w900,
          letterSpacing: .6,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    exitLabel.paint(
      canvas,
      _center(RelicRunEngine.exitCell, cellW, cellH) -
          Offset(exitLabel.width / 2, exitLabel.height / 2),
    );
  }

  void _drawWall(Canvas canvas, Rect rect) {
    final Rect shadow = rect.shift(const Offset(0, 2));
    canvas.drawRRect(
      RRect.fromRectAndRadius(shadow, const Radius.circular(6)),
      Paint()..color = const Color(0xFF26363A).withValues(alpha: .22),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(6)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFA8AAA0),
            Color(0xFF727E7C),
            Color(0xFF56696A),
          ],
        ).createShader(rect),
    );
    canvas.drawLine(
      rect.topLeft + const Offset(5, 4),
      rect.topRight - const Offset(5, 4),
      Paint()
        ..color = Colors.white.withValues(alpha: .36)
        ..strokeWidth = 1.2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(6)),
      Paint()
        ..color = const Color(0xFF475B5E).withValues(alpha: .52)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _drawWarning(Canvas canvas, Rect rect) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(7)),
      Paint()..color = const Color(0xFFE4876B).withValues(alpha: .35),
    );
    final Path path = Path()
      ..moveTo(rect.center.dx, rect.top + rect.height * .22)
      ..lineTo(rect.right - rect.width * .2, rect.center.dy)
      ..lineTo(rect.center.dx, rect.bottom - rect.height * .2)
      ..lineTo(rect.left + rect.width * .2, rect.center.dy)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFC76E5A).withValues(alpha: .75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );
  }

  void _drawTrap(Canvas canvas, Rect rect) {
    final Offset center = rect.center;
    final double radius = math.min(rect.width, rect.height) * .22;
    canvas.drawCircle(
      center,
      radius * 1.28,
      Paint()..color = const Color(0xFFD19751).withValues(alpha: .28),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          colors: <Color>[
            Color(0xFFF1D59A),
            Color(0xFFBB8150),
            Color(0xFF755849),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center,
      radius * .35,
      Paint()..color = const Color(0xFF594C45),
    );
    for (int i = 0; i < 4; i++) {
      final double angle = i * math.pi / 2;
      canvas.drawLine(
        center +
            Offset(
              math.cos(angle) * radius * .54,
              math.sin(angle) * radius * .54,
            ),
        center +
            Offset(
              math.cos(angle) * radius * .92,
              math.sin(angle) * radius * .92,
            ),
        Paint()
          ..color = const Color(0xFFFFEBC1)
          ..strokeWidth = 1.3,
      );
    }
  }

  void _drawExit(Canvas canvas, Rect rect, bool open) {
    final Rect portal = rect.deflate(rect.width * .19);
    canvas.drawRRect(
      RRect.fromRectAndRadius(portal, Radius.circular(rect.width * .17)),
      Paint()
        ..shader = RadialGradient(
          colors: open
              ? const <Color>[
                  Color(0xFFB6E3D6),
                  Color(0xFF558E8C),
                  Color(0xFF356469),
                ]
              : const <Color>[
                  Color(0xFFE2D5B9),
                  Color(0xFFB29061),
                  Color(0xFF66574C),
                ],
        ).createShader(portal),
    );
    canvas.drawArc(
      portal.deflate(2),
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = const Color(0xFFF1DDAE).withValues(alpha: .88)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );
    canvas.drawCircle(
      portal.center,
      portal.width * .13,
      Paint()..color = Colors.white.withValues(alpha: open ? .82 : .4),
    );
  }

  void _drawFoe(
    Canvas canvas,
    Offset center,
    double radius,
    RelicRunFoeState foe,
  ) {
    final Color color = switch (foe.spec.kind) {
      RelicRunFoeKind.stalker => const Color(0xFFC47C68),
      RelicRunFoeKind.sentinel => const Color(0xFF798B83),
      RelicRunFoeKind.ranger => const Color(0xFF738DA4),
      RelicRunFoeKind.guardian => const Color(0xFF8E6F93),
    };
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, radius * .72),
        width: radius * 2.1,
        height: radius * .68,
      ),
      Paint()
        ..color = const Color(0xFF34434A).withValues(alpha: .25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawCircle(
      center,
      radius * 1.14,
      Paint()..color = color.withValues(alpha: .2),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.35, -.46),
          colors: <Color>[
            Color.lerp(color, Colors.white, .54)!,
            color,
            Color.lerp(color, const Color(0xFF25363D), .33)!,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    if (foe.spec.kind == RelicRunFoeKind.guardian) {
      final Path crest = Path()
        ..moveTo(center.dx - radius * .67, center.dy - radius * .48)
        ..lineTo(center.dx - radius * .55, center.dy - radius * 1.18)
        ..lineTo(center.dx, center.dy - radius * .76)
        ..lineTo(center.dx + radius * .55, center.dy - radius * 1.18)
        ..lineTo(center.dx + radius * .67, center.dy - radius * .48)
        ..close();
      canvas.drawPath(crest, Paint()..color = const Color(0xFFE0BC86));
    }
    canvas.drawCircle(
      center + Offset(-radius * .26, -radius * .1),
      radius * .08,
      Paint()..color = const Color(0xFFFFF8E8),
    );
    canvas.drawCircle(
      center + Offset(radius * .26, -radius * .1),
      radius * .08,
      Paint()..color = const Color(0xFFFFF8E8),
    );
    canvas.drawLine(
      center + Offset(-radius * .34, radius * .28),
      center + Offset(radius * .34, radius * .28),
      Paint()
        ..color = const Color(0xFF29383E).withValues(alpha: .7)
        ..strokeWidth = math.max(1, radius * .09)
        ..strokeCap = StrokeCap.round,
    );
    for (int index = 0; index < foe.health; index++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            center.dx - radius * .55 + index * radius * .35,
            center.dy + radius * 1.12,
            radius * .24,
            math.max(1.3, radius * .12),
          ),
          const Radius.circular(2),
        ),
        Paint()..color = Colors.white.withValues(alpha: .85),
      );
    }
  }

  void _drawHero(
    Canvas canvas,
    Offset center,
    double radius,
    (int dx, int dy) facing,
  ) {
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, radius * .7),
        width: radius * 2.15,
        height: radius * .68,
      ),
      Paint()
        ..color = const Color(0xFF263C41).withValues(alpha: .23)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawCircle(
      center,
      radius * 1.2,
      Paint()..color = const Color(0xFF6AB6AF).withValues(alpha: .28),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.4, -.47),
          colors: <Color>[
            Color(0xFFE3F4E6),
            Color(0xFF68B2A8),
            Color(0xFF347B7D),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * .78),
      math.pi * .12,
      math.pi * .76,
      false,
      Paint()
        ..color = const Color(0xFFF5E4C2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * .2,
    );
    final Offset gaze =
        Offset(facing.$1.toDouble(), facing.$2.toDouble()) * radius * .25;
    canvas.drawCircle(
      center + gaze + Offset(-radius * .18, -radius * .05),
      radius * .075,
      Paint()..color = const Color(0xFF294149),
    );
    canvas.drawCircle(
      center + gaze + Offset(radius * .18, -radius * .05),
      radius * .075,
      Paint()..color = const Color(0xFF294149),
    );
    canvas.drawCircle(
      center,
      radius * 1.13,
      Paint()
        ..color = const Color(0xFFB3DFD3).withValues(alpha: .55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );
  }

  static Offset _center(RelicCell cell, double cellW, double cellH) =>
      Offset((cell.x + .5) * cellW, (cell.y + .5) * cellH);

  @override
  bool shouldRepaint(covariant _RelicRunBoardPainter oldDelegate) => true;
}
