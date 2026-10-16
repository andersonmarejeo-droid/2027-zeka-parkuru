import '../shared/studio_game_contracts.dart';

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../features/catalog/domain/studio_game_catalog.dart';
import '../../l10n/app_localizations.dart';
import '../../services/game_audio_service.dart';
import '../../theme/studio_visuals.dart';
import '../shared/game_audio_profile.dart';
import '../shared/parkur_game_kit.dart';
import '../shared/studio_game_session.dart';
import '../shared/studio_game_skin.dart';
import 'reversi_engine.dart';
import 'reversi_scenario.dart';

class ReversiGamePage extends StatelessWidget {
  const ReversiGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  static const int totalCases = GameContentPolicy.campaignLevels;
  static const int totalStars = totalCases * 3;

  static final List<ParkurLevelSpec> _levels = List<ParkurLevelSpec>.generate(
    GameContentPolicy.nativeStages('reversi_arena'),
    (int index) {
      final int number = index + 1;
      final int stage = index % 10 + 1;
      final int chapter = index ~/ 10 + 1;
      final String difficulty = switch (stage) {
        <= 6 => chapter == 1 ? 'USTALAŞMA' : 'İLERİ',
        <= 8 => 'İLERİ',
        _ => 'UZMAN',
      };
      return ParkurLevelSpec(
        number: number,
        titleTr: 'Reversi ${number.toString().padLeft(2, '0')}',
        titleEn: 'Reversi ${number.toString().padLeft(2, '0')}',
        subtitleTr: _subtitle(stage, chapter, english: false),
        subtitleEn: _subtitle(stage, chapter, english: true),
        difficulty: difficulty,
        icon: Icons.change_circle_outlined,
      );
    },
    growable: false,
  );

  static String _subtitle(int stage, int chapter, {required bool english}) {
    if (chapter == 2 && stage <= 6) {
      return english
          ? 'Denser starts and a sharper opponent demand flexible plans.'
          : 'Daha yoğun başlangıçlar ve güçlü rakip esnek plan ister.';
    }
    return switch (stage) {
      <= 3 =>
        english
            ? 'Learn to bracket stones and control the open lanes.'
            : 'Taşları yakalamayı ve açık hatları yönetmeyi öğren.',
      <= 6 =>
        english
            ? 'Trade early discs for mobility and stronger squares.'
            : 'Erken taşları hareket alanı ve güçlü kareler için takas et.',
      7 || 8 =>
        english
            ? 'Advanced play: protect corners and limit replies.'
            : 'İleri oyun: köşeleri koru, rakibin yanıtlarını sınırla.',
      9 => english ? 'Expert match: one careless edge can decide the board.' : 'Uzman karşılaşma: dikkatsiz bir kenar tüm tahtayı değiştirebilir.',
      _ =>
        english
            ? 'Expert finish: calculate a longer sequence before committing.'
            : 'Uzman finali: hamleden önce daha uzun bir diziyi hesapla.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forId('reversi_arena');
    return ParkurLevelHub(
      gameId: 'reversi_arena',
      progressPrefix: 'reversi_arena',
      titleTr: 'Reversi Arenası',
      titleEn: 'Reversi Arena',
      taglineTr: 'Taşları çevir • Köşeleri ele geçir • Rakibini sıkıştır',
      taglineEn: 'Flip the board • Claim corners • Limit your opponent',
      accent: skin.accent,
      icon: Icons.change_circle_outlined,
      levels: _levels,
      dailyCourseMode: dailyCourseMode,
      competitionLevel: competitionLevel,
      competitionLayoutCode: competitionLayoutCode,
      playBuilder: (
        BuildContext context,
        ParkurLevelSpec level,
        int previousBestScore,
        int? competitionLayoutCode,
        bool competitionMode,
      ) => ReversiPlayPage(level: level, previousBestScore: previousBestScore),
    );
  }
}

class ReversiPlayPage extends StatefulWidget {
  const ReversiPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<ReversiPlayPage> createState() => _ReversiPlayPageState();
}

class _ReversiPlayPageState extends State<ReversiPlayPage> {
  static const Color _accent = Color(0xFF267A6C);
  static const Color _feltDeep = Color(0xFF155848);
  static const Color _feltLight = Color(0xFF257966);
  static const Color _chalk = Color(0xFFE8F2D5);
  static const Color _ink = StudioVisuals.ink;

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.strategy,
  );
  final List<ReversiPosition> _undoStack = <ReversiPosition>[];

  late final ReversiScenario _scenario;
  late ReversiPosition _position;
  late StudioGameSession _session;
  Set<int> _legalMoves = <int>{};
  int? _lastMove;
  int? _hintMove;
  int _hints = 0;
  int _humanMoves = 0;
  int _moveSequence = 0;
  bool _english = false;
  bool _finished = false;
  bool _aiThinking = false;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _scenario = (widget.level.poolIndex != null
        ? ReversiScenario.forPool(widget.level.contentIndex)
        : ReversiScenario.forLevel(widget.level.contentLevel));
    _position = _scenario.position;
    _session = StudioGameSession(
      level: widget.level.number,
      seed: _scenario.seed,
    )..start();
    _refreshLegalMoves();
    unawaited(_audioProfile.preload(_audio));
  }

  void _refreshLegalMoves() {
    _legalMoves = _position.legalMoves().toSet();
  }

  void _playCell(int cell) {
    if (_finished ||
        _aiThinking ||
        !_session.acceptsInput ||
        _position.toMove != ReversiStone.dark) {
      return;
    }
    if (!_legalMoves.contains(cell)) {
      setState(() {
        _notice = _english
            ? 'That square does not capture an opposing line.'
            : 'Bu kare rakip taşını yakalamıyor; işaretli noktaları dene.';
        _hintMove = null;
      });
      _audio.hapticLight();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .24));
      return;
    }

    _undoStack.add(_position);
    final ReversiTurnResolution resolution = resolveReversiTurn(
      _position.play(cell),
    );
    setState(() {
      _position = resolution.position;
      _lastMove = cell;
      _hintMove = null;
      _humanMoves++;
      _moveSequence++;
      _notice = resolution.ended
          ? null
          : resolution.passed
          ? (_position.toMove == ReversiStone.dark
                ? (_english
                      ? 'Your opponent has no legal move. Play again.'
                      : 'Rakibin yasal hamlesi yok; bir kez daha oynuyorsun.')
                : (_english
                      ? 'You have no legal move. Your opponent plays again.'
                      : 'Yasal hamlen kalmadı; rakip bir kez daha oynayacak.'))
          : null;
      _refreshLegalMoves();
    });
    _audio.hapticMedium();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .3));
    if (resolution.ended) {
      unawaited(_finishMatch());
    } else if (_position.toMove == ReversiStone.light) {
      unawaited(_runOpponent());
    }
  }

  Future<void> _runOpponent() async {
    if (_finished || !mounted) return;
    setState(() => _aiThinking = true);
    await Future<void>.delayed(const Duration(milliseconds: 240));
    if (!mounted || _finished) return;

    bool ended = false;
    int? lastOpponentMove;
    int automaticPasses = 0;
    while (mounted && !_finished && _position.toMove == ReversiStone.light) {
      final int move = ReversiEngine.chooseMove(
        _position,
        player: ReversiStone.light,
        difficulty: _scenario.difficulty,
        seed: _scenario.seed ^ (_moveSequence * 0x45D9F3B),
      );
      final ReversiTurnResolution resolution = resolveReversiTurn(
        _position.play(move),
      );
      _position = resolution.position;
      _lastMove = move;
      lastOpponentMove = move;
      _moveSequence++;
      if (resolution.passed && _position.toMove == ReversiStone.light) {
        automaticPasses++;
      }
      ended = resolution.ended;
      if (ended || _position.toMove == ReversiStone.dark) break;
      // This is the mandatory pass case: the engine keeps its turn.
      if (automaticPasses > 1) break;
    }
    if (!mounted) return;
    setState(() {
      _aiThinking = false;
      _notice = automaticPasses > 0
          ? (_english
                ? 'You have no legal move. Your opponent plays again.'
                : 'Yasal hamlen kalmadı; rakip bir kez daha oynayacak.')
          : null;
      _refreshLegalMoves();
    });
    if (ended || _position.isTerminal) {
      unawaited(_finishMatch());
    } else if (lastOpponentMove != null) {
      _audio.hapticLight();
      unawaited(
        _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .2),
      );
    }
  }

  void _undo() {
    if (_finished || _aiThinking || _undoStack.isEmpty) return;
    setState(() {
      _position = _undoStack.removeLast();
      _lastMove = null;
      _hintMove = null;
      _notice = null;
      _refreshLegalMoves();
    });
    _audio.hapticSelection();
    unawaited(_audio.play(GameSound.uiBack, gain: .2));
  }

  void _hint() {
    if (_finished ||
        _aiThinking ||
        !_session.canUseHint ||
        _position.toMove != ReversiStone.dark) {
      return;
    }
    final int suggestion = ReversiEngine.chooseMove(
      _position,
      player: ReversiStone.dark,
      difficulty: _scenario.difficulty,
      seed: _scenario.seed ^ (_moveSequence * 0x27D4EB2D) ^ 0x51A7,
    );
    setState(() {
      _hintMove = suggestion;
      _hints++;
      _notice = _english
          ? 'Suggestion: look for the square with the gold ring.'
          : 'Öneri: altın çerçeveli kareyi ve açtığı hattı incele.';
    });
    _session.useHint(pointCost: 160);
    _audio.hapticSelection();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .3));
  }

  void _restart() {
    if (_aiThinking || _finished) return;
    setState(() {
      _position = _scenario.position;
      _undoStack.clear();
      _lastMove = null;
      _hintMove = null;
      _hints = 0;
      _humanMoves = 0;
      _moveSequence = 0;
      _notice = _english
          ? 'The same verified start is ready.'
          : 'Aynı doğrulanmış başlangıç yeniden hazır.';
      _refreshLegalMoves();
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .2));
  }

  int get _score {
    final int margin = _position.darkCount - _position.lightCount;
    return math.max(
      250,
      1050 +
          margin * 36 +
          widget.level.number * 24 +
          _humanMoves * 5 -
          _hints * 160,
    );
  }

  int get _stars {
    final int margin = _position.darkCount - _position.lightCount;
    if (margin > 0 && _hints == 0) return 3;
    if (margin >= -8) return 2;
    return 1;
  }

  Future<void> _finishMatch() async {
    if (_finished || !mounted) return;
    _finished = true;
    final int score = _score;
    final int stars = _stars;
    final int margin = _position.darkCount - _position.lightCount;
    _session.recordAccepted(points: score);
    _session.complete(
      stars: stars,
      action: widget.level.number < ReversiGamePage.totalCases
          ? StudioResultAction.next
          : StudioResultAction.map,
    );
    _audio.hapticMedium();
    unawaited(_audioProfile.play(
      _audio,
      GameAudioEvent.levelComplete,
      levelNumber: widget.level.number,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;

    final String titleTr = margin > 0
        ? 'TAHTA SENİN'
        : margin == 0
        ? 'BERABERE'
        : 'KARŞILAŞMA TAMAMLANDI';
    final String titleEn = margin > 0
        ? 'BOARD WON'
        : margin == 0
        ? 'DRAW'
        : 'MATCH COMPLETE';
    final String detailTr =
        'Sen ${_position.darkCount} · Rakip ${_position.lightCount} taş • $_hints öneri kullanıldı.';
    final String detailEn =
        'You ${_position.darkCount} · Opponent ${_position.lightCount} discs • $_hints hints used.';
    final ParkurResultAction? result = await showParkurResultDialog(
      context: context,
      accent: _accent,
      titleTr: titleTr,
      titleEn: titleEn,
      detailTr: detailTr,
      detailEn: detailEn,
      stars: stars,
      score: score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < ReversiGamePage.totalCases,
    );
    if (!mounted) return;
    final StudioResultAction action = switch (result) {
      ParkurResultAction.replay => StudioResultAction.replay,
      ParkurResultAction.next => StudioResultAction.next,
      _ => StudioResultAction.map,
    };
    Navigator.of(context).pop(
      StudioGameResult.completed(
        score: score,
        stars: stars,
        action: action,
      ).toParkurResult(),
    );
  }

  @override
  Widget build(BuildContext context) {
    _english = context.l10n.isEnglish;
    final double width = MediaQuery.sizeOf(context).width;
    final double boardSize = math.min(width - (width < 360 ? 24 : 36), 520);
    final bool playerTurn =
        !_aiThinking && !_finished && _position.toMove == ReversiStone.dark;
    final String turnLabel = _finished
        ? (_english ? 'MATCH COMPLETE' : 'KARŞILAŞMA TAMAMLANDI')
        : _aiThinking || _position.toMove == ReversiStone.light
        ? (_english ? 'OPPONENT THINKING' : 'RAKİP DÜŞÜNÜYOR')
        : (_english ? 'YOUR TURN' : 'SIRA SENDE');

    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 12,
        title: Text(
          _english ? 'REVERSI ARENA' : 'REVERSI ARENASI',
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${widget.level.number.toString().padLeft(2, '0')} / ${GameContentPolicy.campaignLevels}',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: StudioVisuals.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .6,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            width < 360 ? 12 : 18,
            6,
            width < 360 ? 12 : 18,
            22,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 590),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _RoundHeading(
                    chapter: _scenario.chapter,
                    stage: _scenario.stageInChapter,
                    occupied: _position.occupiedCount,
                    text: _english
                        ? 'Place on a legal empty square to trap opponent discs in a straight line between your discs; trapped discs flip to your color. Finish with more discs than your opponent.'
                        : 'Boş kareye taş koy. Rakibin taşlarını aynı çizgide kendi taşlarının arasında bırakırsan hepsi senin rengine döner. Oyun sonunda rakibinden fazla taşa sahip ol.',
                    english: _english,
                  ),
                  const SizedBox(height: 13),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _ScorePanel(
                          label: _english ? 'YOU · DARK' : 'SEN · KOYU',
                          count: _position.darkCount,
                          dark: true,
                          active: playerTurn,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ScorePanel(
                          label: _english ? 'OPPONENT · LIGHT' : 'RAKİP · AÇIK',
                          count: _position.lightCount,
                          dark: false,
                          active:
                              _aiThinking ||
                              _position.toMove == ReversiStone.light,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _TurnBanner(
                    label: turnLabel,
                    playerTurn: playerTurn,
                    thinking: _aiThinking,
                    legalCount: _legalMoves.length,
                    english: _english,
                  ),
                  if (_notice != null) ...<Widget>[
                    const SizedBox(height: 8),
                    _NoticeBanner(text: _notice!),
                  ],
                  const SizedBox(height: 13),
                  SizedBox(
                    width: boardSize,
                    child: _ReversiBoard(
                      position: _position,
                      legalMoves: _legalMoves,
                      lastMove: _lastMove,
                      hintMove: _hintMove,
                      enabled: playerTurn,
                      onTap: _playCell,
                      english: _english,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _BoardLegend(english: _english),
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.auto_awesome_rounded,
                          label: _english ? 'HINT' : 'ÖNERİ',
                          onPressed: playerTurn ? _hint : null,
                          emphasis: true,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.undo_rounded,
                          label: _english ? 'UNDO' : 'GERİ AL',
                          onPressed: !_aiThinking && _undoStack.isNotEmpty
                              ? _undo
                              : null,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.refresh_rounded,
                          label: _english ? 'RESTART' : 'YENİDEN',
                          onPressed: !_aiThinking ? _restart : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _english
                        ? 'Only the marked empty squares are legal. You may capture stones horizontally, vertically, or diagonally.'
                        : 'Yalnızca işaretli boş karelere oynayabilirsin. Rakip taşlarını yatay, dikey veya çapraz yönde çevirebilirsin.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: StudioVisuals.muted,
                      fontSize: 11,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
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

class _RoundHeading extends StatelessWidget {
  const _RoundHeading({
    required this.chapter,
    required this.stage,
    required this.occupied,
    required this.text,
    required this.english,
  });

  final int chapter;
  final int stage;
  final int occupied;
  final String text;
  final bool english;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 12, 15, 13),
      decoration: BoxDecoration(
        color: StudioVisuals.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: StudioVisuals.line),
        boxShadow: StudioVisuals.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F2ED),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.change_circle_outlined,
                  color: _ReversiPlayPageState._accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  english
                      ? 'CHAPTER $chapter · MATCH ${stage.toString().padLeft(2, '0')}'
                      : 'BÖLÜM $chapter · KARŞILAŞMA ${stage.toString().padLeft(2, '0')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: _ReversiPlayPageState._ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .55,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _TinyPill(
                label: '$occupied / 64',
                color: const Color(0xFFEDF2EE),
                ink: const Color(0xFF586A63),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            text,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: StudioVisuals.muted,
              fontSize: 11,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScorePanel extends StatelessWidget {
  const _ScorePanel({
    required this.label,
    required this.count,
    required this.dark,
    required this.active,
  });

  final String label;
  final int count;
  final bool dark;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final Color disc = dark ? const Color(0xFF24333B) : const Color(0xFFFFFEF5);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE9F3ED) : StudioVisuals.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? _ReversiPlayPageState._accent : StudioVisuals.line,
          width: active ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: disc,
              border: Border.all(
                color: dark ? const Color(0xFF566871) : const Color(0xFFD2DCD4),
                width: 1,
              ),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x180C2520),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: StudioVisuals.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .35,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '$count',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: _ReversiPlayPageState._ink,
                    fontSize: 20,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TurnBanner extends StatelessWidget {
  const _TurnBanner({
    required this.label,
    required this.playerTurn,
    required this.thinking,
    required this.legalCount,
    required this.english,
  });

  final String label;
  final bool playerTurn;
  final bool thinking;
  final int legalCount;
  final bool english;

  @override
  Widget build(BuildContext context) {
    final Color accent = playerTurn
        ? _ReversiPlayPageState._accent
        : const Color(0xFF74818A);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F1),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: <Widget>[
          if (thinking)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: accent),
            )
          else
            Icon(
              playerTurn ? Icons.touch_app_rounded : Icons.psychology_rounded,
              size: 16,
              color: accent,
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Roboto',
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: .55,
              ),
            ),
          ),
          Text(
            playerTurn
                ? (english ? '$legalCount moves' : '$legalCount yasal hamle')
                : (english ? '8 × 8 BOARD' : '8 × 8 TAHTA'),
            maxLines: 1,
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: StudioVisuals.muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF5DE),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFECD9A8)),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontFamily: 'Roboto',
        color: Color(0xFF775B24),
        fontSize: 12,
        height: 1.35,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _ReversiBoard extends StatelessWidget {
  const _ReversiBoard({
    required this.position,
    required this.legalMoves,
    required this.lastMove,
    required this.hintMove,
    required this.enabled,
    required this.onTap,
    required this.english,
  });

  final ReversiPosition position;
  final Set<int> legalMoves;
  final int? lastMove;
  final int? hintMove;
  final bool enabled;
  final ValueChanged<int> onTap;
  final bool english;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFDFE9E3),
            Color(0xFFAFC7BA),
            Color(0xFFDCE7E0),
          ],
        ),
        border: Border.all(color: const Color(0xFFC3D1C8)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x150E3329),
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              _ReversiPlayPageState._feltLight,
              _ReversiPlayPageState._feltDeep,
            ],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reversiBoardSize,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: reversiBoardSide,
            ),
            itemBuilder: (BuildContext context, int cell) {
              final int stone = position.board[cell];
              final bool legal = legalMoves.contains(cell);
              final bool highlighted = cell == hintMove;
              final bool last = cell == lastMove;
              final String semanticLabel = _cellLabel(
                cell,
                stone,
                legal,
                highlighted,
                english,
              );
              return Semantics(
                button: legal,
                label: semanticLabel,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: ValueKey<String>('reversi_cell_$cell'),
                    onTap: enabled ? () => onTap(cell) : null,
                    splashColor: _ReversiPlayPageState._chalk.withValues(
                      alpha: .2,
                    ),
                    highlightColor: Colors.transparent,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0x3068A18A),
                          width: .55,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          if (highlighted)
                            Container(
                              width: 25,
                              height: 25,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFFFD47B),
                                  width: 2.5,
                                ),
                                boxShadow: const <BoxShadow>[
                                  BoxShadow(
                                    color: Color(0x80FFD47B),
                                    blurRadius: 9,
                                  ),
                                ],
                              ),
                            )
                          else if (legal && enabled)
                            Container(
                              width: 11,
                              height: 11,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _ReversiPlayPageState._chalk.withValues(
                                  alpha: .84,
                                ),
                                boxShadow: const <BoxShadow>[
                                  BoxShadow(
                                    color: Color(0x4864D4AE),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          if (stone != ReversiStone.empty)
                            _Disc(
                              dark: stone == ReversiStone.dark,
                              diameter: 28,
                              lastMove: last,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _cellLabel(int cell, int stone, bool legal, bool hint, bool english) {
    final int row = cell ~/ 8 + 1;
    final String column = String.fromCharCode(65 + cell % 8);
    final String occupant = stone == ReversiStone.dark
        ? (english ? 'dark disc' : 'koyu taş')
        : stone == ReversiStone.light
        ? (english ? 'light disc' : 'açık taş')
        : (english ? 'empty' : 'boş');
    final String move = legal
        ? (english ? ', legal move' : ', yasal hamle')
        : '';
    final String suggestion = hint
        ? (english ? ', suggested move' : ', önerilen hamle')
        : '';
    return '$column$row · $occupant$move$suggestion';
  }
}

class _Disc extends StatelessWidget {
  const _Disc({
    required this.dark,
    required this.diameter,
    this.lastMove = false,
  });

  final bool dark;
  final double diameter;
  final bool lastMove;

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = dark
        ? const <Color>[Color(0xFF50606A), Color(0xFF263640), Color(0xFF111C23)]
        : const <Color>[
            Color(0xFFFFFFFF),
            Color(0xFFF0F2E8),
            Color(0xFFD8E1D9),
          ];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-.33, -.42),
          radius: .96,
          colors: colors,
          stops: const <double>[0, .6, 1],
        ),
        border: Border.all(
          color: dark ? const Color(0xFF71818A) : const Color(0xFFBCCBC0),
          width: 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: dark ? const Color(0x770B211B) : const Color(0x52546E60),
            blurRadius: lastMove ? 7 : 4,
            offset: const Offset(0, 2),
          ),
          if (lastMove)
            const BoxShadow(color: Color(0x40FFD47B), blurRadius: 9),
        ],
      ),
      child: Align(
        alignment: const Alignment(-.32, -.4),
        child: Container(
          width: diameter * .24,
          height: diameter * .11,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            color: (dark ? Colors.white : const Color(0xFF80968A)).withValues(
              alpha: dark ? .25 : .2,
            ),
          ),
        ),
      ),
    );
  }
}

class _BoardLegend extends StatelessWidget {
  const _BoardLegend({required this.english});

  final bool english;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _ReversiPlayPageState._chalk,
            border: Border.all(color: const Color(0xFF8EB59F)),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          english ? 'LEGAL SQUARES' : 'YASAL HAMLE NOKTALARI',
          style: const TextStyle(
            fontFamily: 'Roboto',
            color: StudioVisuals.muted,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: .6,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.emphasis = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final Color background = emphasis
        ? const Color(0xFFE5F0E9)
        : StudioVisuals.surface;
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: emphasis
              ? const Color(0xFF286F5D)
              : const Color(0xFF55656D),
          backgroundColor: background,
          disabledForegroundColor: const Color(0xFFA8B2AD),
          side: BorderSide(
            color: emphasis ? const Color(0xFFB8D3C3) : StudioVisuals.line,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _TinyPill extends StatelessWidget {
  const _TinyPill({
    required this.label,
    required this.color,
    required this.ink,
  });

  final String label;
  final Color color;
  final Color ink;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontFamily: 'Roboto',
        color: ink,
        fontSize: 11,
        fontWeight: FontWeight.w900,
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      ),
    ),
  );
}
