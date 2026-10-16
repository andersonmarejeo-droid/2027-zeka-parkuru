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
import 'tavla_engine.dart';
import 'tavla_scenario.dart';

class TavlaGamePage extends StatelessWidget {
  const TavlaGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  static const int totalCases = TavlaScenario.maximumLevels;
  static const int totalStars = totalCases * 3;

  static final List<ParkurLevelSpec> _levels = List<ParkurLevelSpec>.generate(
    totalCases,
    (int index) {
      final int number = index + 1;
      final String difficulty = switch (number) {
        <= 6 => 'USTALAŞMA',
        7 || 8 => 'İLERİ',
        <= 16 => 'UZMAN',
        _ => 'USTA',
      };
      return ParkurLevelSpec(
        number: number,
        titleTr: 'Tavla ${number.toString().padLeft(2, '0')}',
        titleEn: 'Backgammon ${number.toString().padLeft(2, '0')}',
        subtitleTr: _subtitle(number, english: false),
        subtitleEn: _subtitle(number, english: true),
        difficulty: difficulty,
        icon: Icons.casino_outlined,
      );
    },
    growable: false,
  );

  static String _subtitle(int level, {required bool english}) {
    if (level >= 17) {
      return english
          ? 'Master match: plan bar entries, prime breaks and exact bear-offs.'
          : 'Usta karşılaşması: bar girişini, kapı kırmayı ve pul toplamayı planla.';
    }
    if (level >= 11) {
      return english
          ? 'Read denser positions and protect blots while racing home.'
          : 'Yoğun konumları oku; eve yarışırken açık pullarını koru.';
    }
    if (level >= 7) {
      return english
          ? 'Advanced play combines hitting, anchors and flexible dice use.'
          : 'İleri aşama kırma, güvenli kapı ve esnek zar kullanımını birleştirir.';
    }
    return english
        ? 'Enter from the bar, make points and move every checker home.'
        : 'Bar’dan gir, kapı kur ve pullarını güvenle evine taşı.';
  }

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(
      StudioGameClass.strategy,
    );
    return ParkurLevelHub(
      gameId: 'tavla_master',
      progressPrefix: 'tavla_master',
      titleTr: 'Tavla Ustası',
      titleEn: 'Backgammon Master',
      taglineTr: 'Zarı oku • Kapı kur • Pullarını topla',
      taglineEn: 'Read the dice • Make points • Bear off to win',
      accent: skin.accent,
      icon: Icons.casino_outlined,
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
      ) => TavlaPlayPage(level: level, previousBestScore: previousBestScore),
    );
  }
}

class TavlaPlayPage extends StatefulWidget {
  const TavlaPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<TavlaPlayPage> createState() => _TavlaPlayPageState();
}

class _TavlaPlayPageState extends State<TavlaPlayPage> {
  static const Color _accent = Color(0xFF9B6B50);
  static const Color _felt = Color(0xFF617C78);
  static const Color _board = Color(0xFFEAE2D7);
  static const Color _darkStone = Color(0xFF263849);
  static const Color _lightStone = Color(0xFFF9F7F1);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.strategy,
  );
  final List<({TavlaPosition position, List<List<TavlaMove>> turns})>
  _undoStack = <({TavlaPosition position, List<List<TavlaMove>> turns})>[];
  math.Random _diceRandom = math.Random(0x7A71A);

  late TavlaScenario _scenario;
  late TavlaPosition _position;
  late StudioGameSession _session;
  List<List<TavlaMove>> _remainingTurns = <List<TavlaMove>>[];
  int _side = TavlaSide.white;
  int _dieA = 1;
  int _dieB = 2;
  int? _selectedFrom;
  TavlaMove? _hintMove;
  String? _notice;
  int _hints = 0;
  int _turnsPlayed = 0;
  int _humanMoves = 0;
  bool _ready = false;
  bool _aiThinking = false;
  bool _finished = false;
  bool _english = false;

  @override
  void initState() {
    super.initState();
    unawaited(_audioProfile.preload(_audio));
    unawaited(_prepareScenario());
  }

  Future<void> _prepareScenario() async {
    TavlaScenario scenario = TavlaScenario.forLevel(widget.level.number);
    try {
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      final String visitKey =
          'tavla_master_level_${widget.level.number}_visits';
      final int visits = await preferences.getInt(visitKey) ?? 0;
      if (visits > 0) {
        final int played =
            await preferences.getInt('tavla_master_practice_index') ?? 0;
        if (played < TavlaScenario.maximumVerifiedBoards) {
          final int next = played + 1;
          await preferences.setInt('tavla_master_practice_index', next);
          scenario = TavlaScenario.forPracticeBoard(next);
        }
      }
      await preferences.setInt(visitKey, visits + 1);
    } catch (_) {
      scenario = TavlaScenario.forLevel(widget.level.number);
    }
    if (!mounted) return;
    setState(() {
      _scenario = scenario;
      _position = scenario.position;
      _side = scenario.sideToMove;
      _dieA = scenario.dieA;
      _dieB = scenario.dieB;
      _remainingTurns = _position.legalTurnSequences(_side, _dieA, _dieB);
      _session = StudioGameSession(
        level: widget.level.number,
        seed: scenario.seed,
      )..start();
      _ready = true;
    });
    if (_remainingTurns.every((List<TavlaMove> turn) => turn.isEmpty)) {
      unawaited(_passBlockedTurn());
    }
  }

  Iterable<TavlaMove> get _availableMoves => _remainingTurns
      .where((List<TavlaMove> turn) => turn.isNotEmpty)
      .map((List<TavlaMove> turn) => turn.first);

  Set<int> get _legalSources =>
      _availableMoves.map((TavlaMove move) => move.from).toSet();

  Set<int> get _legalTargets => _selectedFrom == null
      ? <int>{}
      : _availableMoves
            .where((TavlaMove move) => move.from == _selectedFrom)
            .map((TavlaMove move) => move.to)
            .toSet();

  List<int> get _remainingDice {
    for (final List<TavlaMove> turn in _remainingTurns) {
      if (turn.isNotEmpty) {
        return turn.map((TavlaMove move) => move.die).toList(growable: false);
      }
    }
    return const <int>[];
  }

  int get _score => math.max(
    0,
    5200 +
        (_position.whiteOff - _position.blackOff) * 95 -
        _hints * 260 -
        _session.mistakes * 180 -
        math.max(0, _turnsPlayed - 18) * 12,
  );

  int get _stars {
    if (_hints == 0 && _session.mistakes == 0) return 3;
    if (_hints <= 2 && _session.mistakes <= 2) return 2;
    return 1;
  }

  void _selectSource(int from) {
    if (_finished || _aiThinking || _side != TavlaSide.white) return;
    if (!_legalSources.contains(from)) {
      setState(() {
        _selectedFrom = null;
        _notice = _english
            ? 'Only a checker that can use one of the remaining dice may move.'
            : 'Yalnızca kalan zarlardan biriyle ilerleyebilen pul seçilebilir.';
      });
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .2));
      return;
    }
    setState(() {
      _selectedFrom = _selectedFrom == from ? null : from;
      _notice = null;
    });
    _audio.hapticSelection();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .18),
    );
  }

  void _tapPoint(int point) {
    if (_finished || _aiThinking || _side != TavlaSide.white) return;
    final int? selected = _selectedFrom;
    if (selected == null) {
      if (_position.points[point] > 0) _selectSource(point);
      return;
    }
    if (point == selected) {
      setState(() => _selectedFrom = null);
      return;
    }
    final TavlaMove? move = _availableMoves
        .where((TavlaMove move) => move.from == selected && move.to == point)
        .firstOrNull;
    if (move == null) {
      if (_position.points[point] > 0) {
        _selectSource(point);
      } else {
        setState(() {
          _notice = _english
              ? 'That point is blocked or unreachable with the remaining dice.'
              : 'Bu nokta kapalı ya da kalan zarlarla ulaşılamıyor.';
        });
        unawaited(
          _audioProfile.play(_audio, GameAudioEvent.rejected, gain: .2),
        );
      }
      return;
    }
    _playMove(move);
  }

  void _tapBar() {
    if (_position.whiteBar == 0) return;
    _selectSource(TavlaPoint.bar);
  }

  void _tapOffTray() {
    final int? selected = _selectedFrom;
    if (selected == null) return;
    final TavlaMove? move = _availableMoves
        .where(
          (TavlaMove candidate) =>
              candidate.from == selected && candidate.bearOff,
        )
        .firstOrNull;
    if (move != null) _playMove(move);
  }

  void _playMove(TavlaMove move) {
    if (!_session.acceptsInput || _finished) return;
    _undoStack.add((
      position: _position,
      turns: List<List<TavlaMove>>.unmodifiable(
        _remainingTurns.map(List<TavlaMove>.unmodifiable),
      ),
    ));
    final List<List<TavlaMove>> continuations = _remainingTurns
        .where(
          (List<TavlaMove> turn) =>
              turn.isNotEmpty &&
              turn.first.from == move.from &&
              turn.first.to == move.to &&
              turn.first.die == move.die,
        )
        .map(
          (List<TavlaMove> turn) => List<TavlaMove>.unmodifiable(turn.skip(1)),
        )
        .toList(growable: false);
    setState(() {
      _position = _position.play(move, TavlaSide.white);
      _remainingTurns = continuations;
      _selectedFrom = null;
      _hintMove = null;
      _notice = move.hit
          ? (_english
                ? 'Blot hit — the opposing checker enters the bar.'
                : 'Pul kırıldı — rakip pul bara girdi.')
          : move.bearOff
          ? (_english ? 'Checker borne off.' : 'Pul toplandı.')
          : null;
      _humanMoves++;
    });
    _audio.hapticLight();
    unawaited(
      _audioProfile.play(
        _audio,
        move.hit ? GameAudioEvent.accepted : GameAudioEvent.primaryAction,
        gain: .2,
      ),
    );
    if (_position.whiteWon) {
      unawaited(_finish(won: true));
    } else if (_remainingTurns.every((List<TavlaMove> turn) => turn.isEmpty)) {
      _undoStack.clear();
      _turnsPlayed++;
      unawaited(_advanceTurn());
    }
  }

  void _undo() {
    if (_finished || _aiThinking || _undoStack.isEmpty) return;
    final ({TavlaPosition position, List<List<TavlaMove>> turns}) snapshot =
        _undoStack.removeLast();
    setState(() {
      _position = snapshot.position;
      _remainingTurns = snapshot.turns;
      _selectedFrom = null;
      _hintMove = null;
      _notice = _english
          ? 'Last checker move restored.'
          : 'Son pul hamlesi geri alındı.';
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .2));
  }

  void _showHint() {
    if (_finished || _aiThinking || _side != TavlaSide.white ||
        !_session.canUseHint) {
      return;
    }
    final List<TavlaMove> move = TavlaEngine.chooseTurn(
      _position,
      TavlaSide.white,
      _remainingTurns,
      strategyLevel: widget.level.number,
    );
    if (move.isEmpty) return;
    _session.useHint(pointCost: 260);
    setState(() {
      _hints++;
      _hintMove = move.first;
      _selectedFrom = move.first.from;
      _notice = _english
          ? 'Recommended: use the highlighted source and destination.'
          : 'Öneri: vurgulanan pul ve hedef noktayla hamle yap.';
    });
    _audio.hapticSelection();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .3));
  }

  Future<void> _confirmReset() async {
    if (!_ready || _finished) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(
          _english ? 'Restart this match?' : 'Maç yeniden başlasın mı?',
        ),
        content: Text(
          _english
              ? 'The same verified position and dice will be restored.'
              : 'Aynı doğrulanmış konum ve zarlar yeniden yüklenir.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(_english ? 'Keep playing' : 'Devam et'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(_english ? 'Restart' : 'Yeniden başlat'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _diceRandom = math.Random(_scenario.seed ^ 0x7A71A);
    setState(() {
      _position = _scenario.position;
      _side = _scenario.sideToMove;
      _dieA = _scenario.dieA;
      _dieB = _scenario.dieB;
      _remainingTurns = _position.legalTurnSequences(_side, _dieA, _dieB);
      _undoStack.clear();
      _selectedFrom = null;
      _hintMove = null;
      _notice = null;
      _hints = 0;
      _turnsPlayed = 0;
      _humanMoves = 0;
      _finished = false;
      _aiThinking = false;
      _session = StudioGameSession(
        level: widget.level.number,
        seed: _scenario.seed,
      )..start();
    });
  }

  void _rollDice() {
    _dieA = _diceRandom.nextInt(6) + 1;
    _dieB = _diceRandom.nextInt(6) + 1;
    _remainingTurns = _position.legalTurnSequences(_side, _dieA, _dieB);
  }

  Future<void> _advanceTurn() async {
    if (_finished || !mounted) return;
    setState(() {
      _side = -_side;
      _selectedFrom = null;
      _hintMove = null;
      _notice = null;
      _rollDice();
    });
    if (_remainingTurns.every((List<TavlaMove> turn) => turn.isEmpty)) {
      await _passBlockedTurn();
    } else if (_side == TavlaSide.black) {
      await _runComputerTurn();
    }
  }

  Future<void> _passBlockedTurn() async {
    if (!mounted || _finished) return;
    setState(() {
      _notice = _english
          ? 'No legal move — the turn passes.'
          : 'Yasal hamle yok — sıra rakibe geçiyor.';
    });
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (mounted && !_finished) {
      _turnsPlayed++;
      await _advanceTurn();
    }
  }

  Future<void> _runComputerTurn() async {
    if (_finished || !mounted) return;
    setState(() {
      _aiThinking = true;
      _notice = _english
          ? 'Opponent is calculating…'
          : 'Rakip hamlesini hesaplıyor…';
    });
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted || _finished) return;
    final List<TavlaMove> sequence = TavlaEngine.chooseTurn(
      _position,
      TavlaSide.black,
      _remainingTurns,
      strategyLevel: widget.level.number,
    );
    for (final TavlaMove move in sequence) {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      if (!mounted || _finished) return;
      setState(() => _position = _position.play(move, TavlaSide.black));
      _audio.hapticLight();
      unawaited(
        _audioProfile.play(
          _audio,
          move.hit ? GameAudioEvent.accepted : GameAudioEvent.primaryAction,
          gain: .17,
        ),
      );
      if (_position.blackWon) {
        await _finish(won: false);
        return;
      }
    }
    _turnsPlayed++;
    if (!mounted || _finished) return;
    setState(() => _aiThinking = false);
    await _advanceTurn();
  }

  Future<void> _finish({required bool won}) async {
    if (_finished || !mounted) return;
    _finished = true;
    final int score = won ? _score : 0;
    final int stars = won ? _stars : 0;
    if (won) {
      _session.recordAccepted(points: score);
      _session.complete(
        stars: stars,
        action: widget.level.number < TavlaGamePage.totalCases
            ? StudioResultAction.next
            : StudioResultAction.map,
      );
    } else {
      _session.fail();
    }
    _audio.hapticMedium();
    unawaited(_audioProfile.play(
      _audio,
      GameAudioEvent.levelComplete,
      levelNumber: widget.level.number,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    final ParkurResultAction? result = await showParkurResultDialog(
      context: context,
      accent: _accent,
      titleTr: won ? 'MAÇI KAZANDIN' : 'RAKİP PULLARINI TOPLADI',
      titleEn: won ? 'MATCH WON' : 'OPPONENT WON THE RACE',
      detailTr: won
          ? '$_turnsPlayed tur · $_humanMoves hamle · $_hints ipucu.'
          : '$_turnsPlayed tur sürdü. Yeni bir zar düzeniyle yeniden dene.',
      detailEn: won
          ? '$_turnsPlayed turns · $_humanMoves moves · $_hints hints.'
          : 'The match lasted $_turnsPlayed turns. Try again with a new plan.',
      stars: stars,
      score: score,
      previousBestScore: widget.previousBestScore,
      canGoNext: won && widget.level.number < TavlaGamePage.totalCases,
    );
    if (!mounted) return;
    final StudioResultAction action = switch (result) {
      ParkurResultAction.replay => StudioResultAction.replay,
      ParkurResultAction.next => StudioResultAction.next,
      _ => StudioResultAction.map,
    };
    Navigator.of(context).pop(
      (won
              ? StudioGameResult.completed(
                  score: score,
                  stars: stars,
                  action: action,
                )
              : StudioGameResult.failed(score: score))
          .toParkurResult(),
    );
  }

  @override
  Widget build(BuildContext context) {
    _english = context.l10n.isEnglish;
    if (!_ready) {
      return Scaffold(
        backgroundColor: StudioVisuals.canvas,
        appBar: AppBar(
          backgroundColor: StudioVisuals.canvas,
          foregroundColor: StudioVisuals.ink,
          surfaceTintColor: Colors.transparent,
          title: Text(_english ? 'BACKGAMMON MASTER' : 'TAVLA USTASI'),
        ),
        body: const Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    final Set<int> legalTargets = _legalTargets;
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 12,
        title: Text(
          _english ? 'BACKGAMMON MASTER' : 'TAVLA USTASI',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: _TavlaLevelPill(level: widget.level.number)),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _MatchStatus(
                position: _position,
                side: _side,
                dieA: _dieA,
                dieB: _dieB,
                aiThinking: _aiThinking,
                english: _english,
                turns: _turnsPlayed,
              ),
              const SizedBox(height: 12),
              _BackgammonBoard(
                position: _position,
                selectedFrom: _selectedFrom,
                legalSources: _legalSources,
                legalTargets: legalTargets,
                hintMove: _hintMove,
                onTapPoint: _tapPoint,
                onTapBar: _tapBar,
                onTapOff: _tapOffTray,
                canBearOff: legalTargets.contains(TavlaPoint.off),
                english: _english,
              ),
              const SizedBox(height: 10),
              _DicePanel(
                dieA: _dieA,
                dieB: _dieB,
                side: _side,
                remainingDice: _remainingDice,
                whiteOff: _position.whiteOff,
                blackOff: _position.blackOff,
                english: _english,
              ),
              const SizedBox(height: 9),
              _TavlaActions(
                canUndo: _undoStack.isNotEmpty,
                busy: _aiThinking || _finished,
                english: _english,
                onUndo: _undo,
                onHint: _showHint,
                onReset: _confirmReset,
              ),
              if (_notice != null) ...<Widget>[
                const SizedBox(height: 9),
                _TavlaNotice(text: _notice!),
              ],
              const SizedBox(height: 8),
              Text(
                _english
                    ? 'Tap a checker, then a highlighted point. A checker on the bar must enter before any other move.'
                    : 'Puluna, ardından vurgulanan noktaya dokun. Bar’daki pul, diğer hamlelerden önce oyuna girmelidir.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: StudioVisuals.muted,
                  fontSize: 10,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TavlaLevelPill extends StatelessWidget {
  const _TavlaLevelPill({required this.level});
  final int level;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: StudioVisuals.surface,
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: StudioVisuals.line),
    ),
    child: Text(
      context.l10n.levelOutOf(level, TavlaGamePage.totalCases),
      style: const TextStyle(
        color: StudioVisuals.ink,
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _MatchStatus extends StatelessWidget {
  const _MatchStatus({
    required this.position,
    required this.side,
    required this.dieA,
    required this.dieB,
    required this.aiThinking,
    required this.english,
    required this.turns,
  });

  final TavlaPosition position;
  final int side;
  final int dieA;
  final int dieB;
  final bool aiThinking;
  final bool english;
  final int turns;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
    decoration: BoxDecoration(
      color: StudioVisuals.surface,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: StudioVisuals.line),
      boxShadow: StudioVisuals.softShadow,
    ),
    child: Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: side == TavlaSide.white
                    ? _TavlaPlayPageState._accent
                    : _TavlaPlayPageState._felt,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                aiThinking
                    ? (english ? 'OPPONENT THINKING' : 'RAKİP DÜŞÜNÜYOR')
                    : side == TavlaSide.white
                    ? (english ? 'YOUR TURN · WHITE' : 'SIRA SENDE · AÇIK PUL')
                    : (english ? 'DARK CHECKERS' : 'KOYU PULLAR'),
                style: const TextStyle(
                  color: StudioVisuals.ink,
                  fontSize: 10,
                  letterSpacing: .55,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '${english ? 'TURN' : 'TUR'} ${turns + 1}',
              style: const TextStyle(
                color: StudioVisuals.muted,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        Row(
          children: <Widget>[
            _StoneCounter(
              light: true,
              count: position.whiteOff,
              label: english ? 'HOME' : 'TOPLANDI',
            ),
            const SizedBox(width: 6),
            _StoneCounter(
              light: false,
              count: position.whiteBar,
              label: english ? 'BAR' : 'BAR',
            ),
            const Spacer(),
            _DieFace(value: dieA),
            const SizedBox(width: 5),
            _DieFace(value: dieB),
            const Spacer(),
            _StoneCounter(
              light: false,
              count: position.blackBar,
              label: english ? 'BAR' : 'BAR',
            ),
            const SizedBox(width: 6),
            _StoneCounter(
              light: false,
              count: position.blackOff,
              label: english ? 'RIVAL' : 'RAKİP',
            ),
          ],
        ),
      ],
    ),
  );
}

class _StoneCounter extends StatelessWidget {
  const _StoneCounter({
    required this.light,
    required this.count,
    required this.label,
  });
  final bool light;
  final int count;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      _CheckerStone(light: light, size: 19),
      const SizedBox(height: 2),
      Text(
        '$count',
        style: const TextStyle(
          color: StudioVisuals.ink,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
      Text(
        label,
        maxLines: 1,
        style: const TextStyle(
          color: StudioVisuals.muted,
          fontSize: 7,
          letterSpacing: .25,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

class _BackgammonBoard extends StatelessWidget {
  const _BackgammonBoard({
    required this.position,
    required this.selectedFrom,
    required this.legalSources,
    required this.legalTargets,
    required this.hintMove,
    required this.onTapPoint,
    required this.onTapBar,
    required this.onTapOff,
    required this.canBearOff,
    required this.english,
  });

  final TavlaPosition position;
  final int? selectedFrom;
  final Set<int> legalSources;
  final Set<int> legalTargets;
  final TavlaMove? hintMove;
  final ValueChanged<int> onTapPoint;
  final VoidCallback onTapBar;
  final VoidCallback onTapOff;
  final bool canBearOff;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: const Color(0xFFD9CEC0),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFC6B7A5)),
      boxShadow: StudioVisuals.softShadow,
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Container(
        color: _TavlaPlayPageState._board,
        child: Column(
          children: <Widget>[
            _PointRow(
              points: List<int>.generate(12, (int index) => index + 12),
              position: position,
              top: true,
              selectedFrom: selectedFrom,
              legalSources: legalSources,
              legalTargets: legalTargets,
              hintMove: hintMove,
              onTapPoint: onTapPoint,
              english: english,
            ),
            Container(
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFB9A48D),
                border: Border.symmetric(
                  horizontal: BorderSide(color: Color(0xFFA58D73)),
                ),
              ),
              child: Row(
                children: <Widget>[
                  const SizedBox(width: 9),
                  _RailStone(count: position.blackBar, light: false),
                  const Spacer(),
                  Text(
                    english ? 'BOARD' : 'TAHTA',
                    style: const TextStyle(
                      color: Color(0xFF5E5448),
                      fontSize: 7,
                      letterSpacing: .8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Material(
                    color: canBearOff
                        ? const Color(0xFFEAF3EA)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    child: InkWell(
                      onTap: canBearOff ? onTapOff : null,
                      borderRadius: BorderRadius.circular(9),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 5,
                        ),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              Icons.south_rounded,
                              size: 13,
                              color: canBearOff
                                  ? const Color(0xFF426B58)
                                  : const Color(0xFF807567),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              english ? 'OFF' : 'TOPLA',
                              style: const TextStyle(
                                color: StudioVisuals.ink,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Material(
                    color: position.whiteBar > 0
                        ? const Color(0xFFFFF5E5)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    child: InkWell(
                      onTap: position.whiteBar > 0 ? onTapBar : null,
                      borderRadius: BorderRadius.circular(9),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        child: Row(
                          children: <Widget>[
                            _CheckerStone(light: true, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              '${english ? 'BAR' : 'BAR'} ${position.whiteBar}',
                              style: const TextStyle(
                                color: StudioVisuals.ink,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            _PointRow(
              points: List<int>.generate(12, (int index) => 11 - index),
              position: position,
              top: false,
              selectedFrom: selectedFrom,
              legalSources: legalSources,
              legalTargets: legalTargets,
              hintMove: hintMove,
              onTapPoint: onTapPoint,
              english: english,
            ),
          ],
        ),
      ),
    ),
  );
}

class _PointRow extends StatelessWidget {
  const _PointRow({
    required this.points,
    required this.position,
    required this.top,
    required this.selectedFrom,
    required this.legalSources,
    required this.legalTargets,
    required this.hintMove,
    required this.onTapPoint,
    required this.english,
  });

  final List<int> points;
  final TavlaPosition position;
  final bool top;
  final int? selectedFrom;
  final Set<int> legalSources;
  final Set<int> legalTargets;
  final TavlaMove? hintMove;
  final ValueChanged<int> onTapPoint;
  final bool english;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 147,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int index = 0; index < points.length; index++)
          Expanded(
            child: _BoardPoint(
              point: points[index],
              count: position.points[points[index]],
              top: top,
              alternate: index.isOdd,
              selected: selectedFrom == points[index],
              legalSource: legalSources.contains(points[index]),
              legalTarget: legalTargets.contains(points[index]),
              hinted:
                  hintMove?.to == points[index] ||
                  hintMove?.from == points[index],
              onTap: () => onTapPoint(points[index]),
              english: english,
            ),
          ),
      ],
    ),
  );
}

class _BoardPoint extends StatelessWidget {
  const _BoardPoint({
    required this.point,
    required this.count,
    required this.top,
    required this.alternate,
    required this.selected,
    required this.legalSource,
    required this.legalTarget,
    required this.hinted,
    required this.onTap,
    required this.english,
  });

  final int point;
  final int count;
  final bool top;
  final bool alternate;
  final bool selected;
  final bool legalSource;
  final bool legalTarget;
  final bool hinted;
  final VoidCallback onTap;
  final bool english;

  @override
  Widget build(BuildContext context) {
    final bool light = count >= 0;
    final int stones = count.abs();
    final Color triangle = alternate
        ? const Color(0xFFB8785D)
        : const Color(0xFF58716F);
    return Semantics(
      button: true,
      label: english
          ? 'Point ${point + 1}, $stones ${light ? 'light' : 'dark'} checkers'
          : '${point + 1}. nokta, $stones ${light ? 'açık' : 'koyu'} pul',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFFFE8B5)
                : legalTarget
                ? const Color(0xFFE0EEE5)
                : Colors.transparent,
            border: Border.all(
              color: hinted
                  ? const Color(0xFFE3AA53)
                  : legalSource
                  ? const Color(0xFF6F9E8C)
                  : Colors.transparent,
              width: hinted || legalSource ? 1.4 : .2,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              CustomPaint(
                painter: _PointTrianglePainter(color: triangle, top: top),
              ),
              Align(
                alignment: top ? Alignment.topCenter : Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (stones > 5)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 3,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: light
                                ? _TavlaPlayPageState._darkStone
                                : _TavlaPlayPageState._lightStone,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '×$stones',
                            style: TextStyle(
                              color: light
                                  ? Colors.white
                                  : _TavlaPlayPageState._darkStone,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        )
                      else
                        for (int index = 0; index < stones; index++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 1),
                            child: _CheckerStone(light: light, size: 19),
                          ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 2,
                left: 0,
                right: 0,
                child: Text(
                  '${point + 1}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: (stones > 0 && light == top)
                        ? Colors.white.withValues(alpha: .86)
                        : const Color(0xFF675F55),
                    fontSize: 7,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (legalTarget)
                Align(
                  alignment: top ? Alignment.bottomCenter : Alignment.topCenter,
                  child: Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: _TavlaPlayPageState._accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PointTrianglePainter extends CustomPainter {
  const _PointTrianglePainter({required this.color, required this.top});

  final Color color;
  final bool top;

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path();
    if (top) {
      path
        ..moveTo(size.width * .08, 0)
        ..lineTo(size.width * .92, 0)
        ..lineTo(size.width * .5, size.height * .74)
        ..close();
    } else {
      path
        ..moveTo(size.width * .08, size.height)
        ..lineTo(size.width * .92, size.height)
        ..lineTo(size.width * .5, size.height * .26)
        ..close();
    }
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: .92));
  }

  @override
  bool shouldRepaint(_PointTrianglePainter oldDelegate) =>
      color != oldDelegate.color || top != oldDelegate.top;
}

class _CheckerStone extends StatelessWidget {
  const _CheckerStone({required this.light, required this.size});

  final bool light;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        center: const Alignment(-.28, -.35),
        radius: 1.1,
        colors: light
            ? const <Color>[Color(0xFFFFFFFF), Color(0xFFE4DED3)]
            : const <Color>[Color(0xFF536676), Color(0xFF253748)],
      ),
      border: Border.all(
        color: light ? const Color(0xFFC9C1B5) : const Color(0xFF172A38),
        width: 1,
      ),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
      ],
    ),
  );
}

class _RailStone extends StatelessWidget {
  const _RailStone({required this.count, required this.light});
  final int count;
  final bool light;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      if (count > 0) _CheckerStone(light: light, size: 21),
      if (count > 1)
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            '$count',
            style: const TextStyle(
              color: _TavlaPlayPageState._darkStone,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
    ],
  );
}

class _DicePanel extends StatelessWidget {
  const _DicePanel({
    required this.dieA,
    required this.dieB,
    required this.side,
    required this.remainingDice,
    required this.whiteOff,
    required this.blackOff,
    required this.english,
  });

  final int dieA;
  final int dieB;
  final int side;
  final List<int> remainingDice;
  final int whiteOff;
  final int blackOff;
  final bool english;

  @override
  Widget build(BuildContext context) {
    final List<int> shownDice = dieA == dieB
        ? List<int>.filled(4, dieA)
        : <int>[dieA, dieB];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: StudioVisuals.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: StudioVisuals.line),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              side == TavlaSide.white
                  ? (english ? 'YOU · WHITE' : 'SEN · AÇIK')
                  : (english ? 'RIVAL · DARK' : 'RAKİP · KOYU'),
              style: const TextStyle(
                color: StudioVisuals.muted,
                fontSize: 9,
                letterSpacing: .5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          for (int index = 0; index < shownDice.length; index++) ...<Widget>[
            if (index > 0) const SizedBox(width: 4),
            _DieFace(
              value: shownDice[index],
              enabled:
                  remainingDice
                      .where((int remaining) => remaining == shownDice[index])
                      .length >
                  shownDice
                      .take(index)
                      .where((int previous) => previous == shownDice[index])
                      .length,
            ),
          ],
          const SizedBox(width: 9),
          Text(
            english ? 'OFF $whiteOff : $blackOff' : 'TOP $whiteOff : $blackOff',
            style: const TextStyle(
              color: StudioVisuals.muted,
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DieFace extends StatelessWidget {
  const _DieFace({required this.value, this.enabled = true});
  final int value;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Container(
    width: 26,
    height: 26,
    decoration: BoxDecoration(
      color: enabled ? const Color(0xFFFCFBF8) : const Color(0xFFE6E2DC),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: enabled ? const Color(0xFFD7DDE1) : const Color(0xFFC6C0B7),
      ),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color(0x100B1A2B),
          blurRadius: 3,
          offset: Offset(0, 1),
        ),
      ],
    ),
    child: Opacity(
      opacity: enabled ? 1 : .36,
      child: CustomPaint(painter: _DiePipPainter(value)),
    ),
  );
}

class _DiePipPainter extends CustomPainter {
  const _DiePipPainter(this.value);
  final int value;

  @override
  void paint(Canvas canvas, Size size) {
    final double unit = size.width / 4;
    final List<Offset> positions = <Offset>[
      const Offset(1, 1),
      const Offset(3, 3),
      const Offset(1, 3),
      const Offset(3, 1),
      const Offset(2, 2),
      const Offset(1, 2),
      const Offset(3, 2),
    ];
    final List<Offset> selected = switch (value) {
      1 => <Offset>[positions[4]],
      2 => <Offset>[positions[0], positions[1]],
      3 => <Offset>[positions[0], positions[4], positions[1]],
      4 => <Offset>[positions[0], positions[2], positions[3], positions[1]],
      5 => <Offset>[
        positions[0],
        positions[2],
        positions[4],
        positions[3],
        positions[1],
      ],
      _ => positions,
    };
    final Paint paint = Paint()..color = _TavlaPlayPageState._darkStone;
    for (final Offset position in selected) {
      canvas.drawCircle(
        Offset(position.dx * unit, position.dy * unit),
        size.width * .07,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DiePipPainter oldDelegate) => value != oldDelegate.value;
}

class _TavlaActions extends StatelessWidget {
  const _TavlaActions({
    required this.canUndo,
    required this.busy,
    required this.english,
    required this.onUndo,
    required this.onHint,
    required this.onReset,
  });

  final bool canUndo;
  final bool busy;
  final bool english;
  final VoidCallback onUndo;
  final VoidCallback onHint;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: _ActionButton(
          icon: Icons.undo_rounded,
          label: english ? 'UNDO' : 'GERİ AL',
          onTap: !busy && canUndo ? onUndo : null,
        ),
      ),
      const SizedBox(width: 7),
      Expanded(
        child: _ActionButton(
          icon: Icons.lightbulb_outline_rounded,
          label: english ? 'HINT' : 'İPUCU',
          onTap: busy ? null : onHint,
        ),
      ),
      const SizedBox(width: 7),
      Expanded(
        child: _ActionButton(
          icon: Icons.restart_alt_rounded,
          label: english ? 'RESTART' : 'BAŞTAN',
          onTap: busy ? null : onReset,
        ),
      ),
    ],
  );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      foregroundColor: StudioVisuals.ink,
      backgroundColor: StudioVisuals.surface,
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      side: const BorderSide(color: StudioVisuals.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
    ),
    icon: Icon(icon, size: 15),
    label: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        label,
        maxLines: 1,
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
      ),
    ),
  );
}

class _TavlaNotice extends StatelessWidget {
  const _TavlaNotice({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: StudioVisuals.amberSoft,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: StudioVisuals.amber.withValues(alpha: .25)),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: StudioVisuals.ink,
        fontSize: 10,
        height: 1.35,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
