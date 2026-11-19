import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/studio_visuals.dart';

import '../../features/catalog/domain/studio_game_catalog.dart';
import '../../l10n/app_localizations.dart';
import '../../services/game_audio_service.dart';
import '../shared/game_audio_profile.dart';
import '../shared/parkur_game_kit.dart';
import '../shared/studio_game_contracts.dart';
import '../shared/studio_game_session.dart';
import 'mine_detector_puzzle.dart';

/// S03 — a deliberate, logic-first minefield course.
///
/// The puzzle object owns board generation, first-move protection and logic
/// certification. This page only turns that deterministic board into a calm,
/// touch-friendly inspection surface; it never randomises a board or changes
/// a mine after a player has begun to read it.
class MineDetectorGamePage extends StatelessWidget {
  const MineDetectorGamePage({
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
    GameContentPolicy.nativeStages('mine_detective'),
    (int index) {
      final int number = index + 1;
      final int stage = (index % 10) + 1;
      return ParkurLevelSpec(
        number: number,
        titleTr: 'Tarama ${number.toString().padLeft(3, '0')}',
        titleEn: 'Scan ${number.toString().padLeft(3, '0')}',
        subtitleTr: _stageDescription(stage, english: false),
        subtitleEn: _stageDescription(stage, english: true),
        difficulty: _stageTitle(stage, english: false),
        icon: Icons.radar_rounded,
      );
    },
  );

  static String _stageTitle(int stage, {required bool english}) =>
      switch (stage) {
        1 => english ? 'ORIENTATION' : 'KEŞİF',
        2 => english ? 'OPENING CLUES' : 'AÇILIŞ İZLERİ',
        3 => english ? 'EDGE READING' : 'KENAR OKUMA',
        4 => english ? 'CLUE CHAINS' : 'İZ ZİNCİRLERİ',
        5 => english ? 'CROSS-CHECK' : 'ÇAPRAZ KONTROL',
        6 => english ? 'DENSITY' : 'YOĞUNLUK',
        7 => english ? 'ADVANCED' : 'İLERİ',
        8 => english ? 'TACTICAL' : 'TAKTİK',
        9 => english ? 'EXPERT' : 'UZMAN',
        _ => english ? 'MASTER' : 'USTA',
      };

  static String _stageDescription(int stage, {required bool english}) =>
      switch (stage) {
        1 =>
          english
              ? 'Read one protected opening and its first clues.'
              : 'Korunan açılışı ve ilk izleri oku.',
        2 =>
          english
              ? 'Use a clue to clear the edge around it.'
              : 'Bir izin çevresindeki kenarı aç.',
        3 =>
          english
              ? 'Separate safe corridors from marked borders.'
              : 'Güvenli koridoru işaretli sınırdan ayır.',
        4 =>
          english
              ? 'Carry a verified deduction across clue chains.'
              : 'Doğrulanmış çıkarımı iz zincirinde taşı.',
        5 =>
          english
              ? 'Compare two nearby clue groups before opening.'
              : 'Açmadan önce iki yakın iz grubunu karşılaştır.',
        6 =>
          english
              ? 'Maintain flag discipline on a denser field.'
              : 'Yoğun alanda bayrak disiplinini koru.',
        7 =>
          english
              ? 'Resolve compact advanced frontiers without guessing.'
              : 'Sıkı ileri cepheleri tahminsiz çöz.',
        8 =>
          english
              ? 'Protect a narrow route while clues overlap.'
              : 'İzler örtüşürken dar rotayı koru.',
        9 =>
          english
              ? 'Link expert deductions over a broad minefield.'
              : 'Uzman çıkarımları geniş mayın alanında bağla.',
        _ =>
          english
              ? 'Finish a master field using only accountable logic.'
              : 'Usta alanı yalnızca izlenebilir mantıkla bitir.',
      };

  @override
  Widget build(BuildContext context) => ParkurLevelHub(
    gameId: 'mine_detective',
    progressPrefix: 'mine_detective',
    titleTr: 'Mayın Dedektifi',
    titleEn: 'Mine Detector',
    taglineTr: 'İzleri doğrula, güvenli hücreleri aç.',
    taglineEn: 'Verify the clues and clear safe cells.',
    accent: _MinePalette.teal,
    icon: Icons.radar_rounded,
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
        ) => MineDetectorPlayPage(
          level: level,
          previousBestScore: previousBestScore,
        ),
  );
}

class MineDetectorPlayPage extends StatefulWidget {
  const MineDetectorPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<MineDetectorPlayPage> createState() => _MineDetectorPlayPageState();
}

class _MineDetectorPlayPageState extends State<MineDetectorPlayPage> {
  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.logic,
  );
  final List<MineDetectorBoardState> _undo = <MineDetectorBoardState>[];

  late final MineDetectorPuzzle _puzzle;
  late final MineDetectorBoardState _initialState;
  late MineDetectorBoardState _state;
  late final StudioGameSession _session;

  bool _english = false;
  bool _flagMode = false;
  bool _finished = false;
  int _moves = 0;
  int _hints = 0;
  int? _hintedCell;
  String? _notice;
  Timer? _noticeTimer;
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    _puzzle = MineDetectorPuzzle.forLevel(widget.level.contentIndex);
    _initialState = _puzzle.initialState;
    _state = _initialState;
    _session = StudioGameSession(
      level: widget.level.number,
      seed: widget.level.number,
    )..start();
    unawaited(_audioProfile.preload(_audio));
  }

  @override
  void dispose() {
    _noticeTimer?.cancel();
    _hintTimer?.cancel();
    super.dispose();
  }

  int get _flagsPlaced => _state.flagged.length;
  int get _revealedSafe =>
      _puzzle.cellCount - _puzzle.mineCount - _state.remainingSafeCells;
  int get _safeTotal => _puzzle.cellCount - _puzzle.mineCount;

  bool _hasStateChanged(
    MineDetectorBoardState before,
    MineDetectorBoardState after,
  ) =>
      before.revealed.length != after.revealed.length ||
      before.flagged.length != after.flagged.length ||
      before.explodedCell != after.explodedCell;

  void _remember(MineDetectorBoardState state) {
    _undo.add(state);
    if (_undo.length > 100) _undo.removeAt(0);
  }

  void _tapCell(int cell) {
    if (_finished || _state.isLost || _state.isWon || !_session.acceptsInput) {
      return;
    }
    if (_flagMode) {
      _toggleFlag(cell);
      return;
    }
    final MineDetectorBoardState next = _state.revealed.contains(cell)
        ? _puzzle.chord(_state, cell)
        : _puzzle.revealFrom(_state, cell);
    _commit(next, cell: cell, action: _MineAction.reveal);
  }

  void _toggleFlag(int cell) {
    if (_finished || _state.isLost || _state.isWon || !_session.acceptsInput) {
      return;
    }
    final MineDetectorBoardState next = _puzzle.toggleFlag(_state, cell);
    _commit(next, cell: cell, action: _MineAction.flag);
  }

  void _commit(
    MineDetectorBoardState next, {
    required int cell,
    required _MineAction action,
  }) {
    final MineDetectorBoardState before = _state;
    if (!_hasStateChanged(before, next)) {
      if (action == _MineAction.reveal && before.revealed.contains(cell)) {
        _setNotice(
          _english
              ? 'No additional cells are certified by this clue yet.'
              : 'Bu iz henüz yeni bir hücreyi doğrulamıyor.',
        );
      }
      return;
    }
    _remember(before);
    setState(() {
      _state = next;
      _moves++;
      _hintedCell = null;
    });
    _session.recordAccepted();

    if (next.isLost) {
      _session.recordMistake();
      _audio.hapticMedium();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .44));
      _setNotice(
        _english
            ? 'Mine detected. Undo the scan or reset the field.'
            : 'Mayın algılandı. Taramayı geri al veya alanı sıfırla.',
      );
      return;
    }

    _audio.hapticLight();
    unawaited(
      _audioProfile.play(
        _audio,
        action == _MineAction.flag
            ? GameAudioEvent.primaryAction
            : GameAudioEvent.accepted,
        gain: action == _MineAction.flag ? .24 : .34,
      ),
    );
    if (next.isWon) {
      unawaited(_complete());
    }
  }

  void _undoMove() {
    if (_finished || _undo.isEmpty) return;
    final MineDetectorBoardState previous = _undo.removeLast();
    setState(() {
      _state = previous;
      _moves = math.max(0, _moves - 1);
      _hintedCell = null;
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .24));
    _setNotice(_english ? 'Last scan restored.' : 'Son tarama geri alındı.');
  }

  void _restart() {
    if (_finished) return;
    setState(() {
      _state = _initialState;
      _undo.clear();
      _moves = 0;
      _hints = 0;
      _hintedCell = null;
      _flagMode = false;
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .28));
    _setNotice(
      _english
          ? 'The protected opening is ready again.'
          : 'Korunan açılış yeniden hazır.',
    );
  }

  void _showHint() {
    if (_finished || _state.isLost || _state.isWon || !_session.canUseHint) {
      return;
    }
    final _MineHint? hint = _findVerifiedHint();
    if (hint == null) {
      _setNotice(
        _english
            ? 'No unopened deduction remains on this field.'
            : 'Bu alanda açılmamış çıkarım kalmadı.',
      );
      return;
    }
    setState(() {
      _hintedCell = hint.cell;
      _hints++;
      _flagMode = hint.shouldFlag;
    });
    _session.useHint(pointCost: 125);
    _audio.hapticSelection();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .34));
    _setNotice(
      hint.shouldFlag
          ? (_english
                ? 'Verified mark: place a flag on the brass cell.'
                : 'Doğrulanmış işaret: pirinç hücreye bayrak koy.')
          : (_english
                ? 'Verified opening: reveal the teal cell.'
                : 'Doğrulanmış açılış: teal hücreyi aç.'),
    );
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _hintedCell = null);
    });
  }

  /// Requests the model's logic certificate first. The UI intentionally keeps
  /// the final visual choice defensive, so a future report presentation can
  /// evolve without weakening the generated puzzle's guarantee.
  _MineHint? _findVerifiedHint() {
    final MineDetectorLogicReport report = _puzzle.logicSolve(
      fromState: _state,
    );
    final MineDetectorLogicAction? action = report.nextAction;
    if (action == null) return null;
    return _MineHint(cell: action.cell, shouldFlag: action.flagsMine);
  }

  void _setNotice(String value) {
    if (!mounted) return;
    _noticeTimer?.cancel();
    setState(() => _notice = value);
    _noticeTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _notice = null);
    });
  }

  int _stars() {
    if (_hints == 0 && _session.mistakes == 0) return 3;
    if (_hints <= 2 && _session.mistakes <= 1) return 2;
    return 1;
  }

  int _score() => math.max(
    300,
    3200 - _moves * 21 - _hints * 150 - _session.mistakes * 260,
  );

  Future<void> _complete() async {
    if (_finished || !_session.acceptsInput) return;
    _finished = true;
    final int stars = _stars();
    final int score = _score();
    _session.recordAccepted(points: score);
    _session.complete(
      stars: stars,
      action: widget.level.number < MineDetectorGamePage.totalCases
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
    final ParkurResultAction? action = await showParkurResultDialog(
      context: context,
      accent: _MinePalette.teal,
      titleTr: 'MAYIN HARİTASI TEMİZ',
      titleEn: 'MINEFIELD SECURED',
      detailTr:
          '$_revealedSafe güvenli hücre, $_flagsPlaced bayrak ve $_moves tarama tamamlandı.',
      detailEn:
          '$_revealedSafe safe cells, $_flagsPlaced flags and $_moves scans completed.',
      stars: stars,
      score: score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < MineDetectorGamePage.totalCases,
    );
    if (!mounted) return;
    final StudioResultAction resultAction = switch (action) {
      ParkurResultAction.replay => StudioResultAction.replay,
      ParkurResultAction.next => StudioResultAction.next,
      _ => StudioResultAction.map,
    };
    Navigator.of(context).pop(
      StudioGameResult.completed(
        score: score,
        stars: stars,
        action: resultAction,
      ).toParkurResult(),
    );
  }

  @override
  Widget build(BuildContext context) {
    _english = context.l10n.isEnglish;
    final int stage = ((widget.level.number - 1) % 10) + 1;
    return Scaffold(
      backgroundColor: _MinePalette.canvas,
      appBar: AppBar(
        backgroundColor: _MinePalette.canvas,
        foregroundColor: _MinePalette.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 8,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _english ? 'MINE DETECTOR' : 'MAYIN DEDEKTİFİ',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: .7,
              ),
            ),
            Text(
              '${_english ? 'SCAN' : 'TARAMA'} ${widget.level.number.toString().padLeft(3, '0')} · ${MineDetectorGamePage._stageTitle(stage, english: _english)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: _MinePalette.muted,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: .32,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('mine_undo'),
            tooltip: _english ? 'Undo scan' : 'Taramayı geri al',
            onPressed: _undo.isEmpty ? null : _undoMove,
            icon: const Icon(Icons.undo_rounded),
          ),
          IconButton(
            key: const ValueKey<String>('mine_restart'),
            tooltip: _english ? 'Restart field' : 'Alanı sıfırla',
            onPressed: _restart,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveGameFrame(
          maxContentWidth: 760,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints limits) {
              final bool compact =
                  limits.maxWidth < 390 || limits.maxHeight < 660;
              final double boardHeight = compact
                  ? math.max(174, math.min(212, limits.maxHeight - 332))
                  : math.max(280, math.min(470, limits.maxHeight - 272));
              return ListView(
                key: const ValueKey<String>('mine_scroll'),
                padding: EdgeInsets.fromLTRB(12, 4, 12, compact ? 9 : 18),
                children: <Widget>[
                  _MineHeader(
                    stage: stage,
                    english: _english,
                    rows: _puzzle.rows,
                    columns: _puzzle.columns,
                    mines: _puzzle.mineCount,
                    revealedSafe: _revealedSafe,
                    safeTotal: _safeTotal,
                    bestScore: widget.previousBestScore,
                  ),
                  SizedBox(height: compact ? 7 : 11),
                  _SafeOpeningBand(
                    english: _english,
                    row: _puzzle.safeStartCell ~/ _puzzle.columns + 1,
                    column: _puzzle.safeStartCell % _puzzle.columns + 1,
                  ),
                  SizedBox(height: compact ? 7 : 11),
                  SizedBox(
                    height: boardHeight,
                    child: _MineBoard(
                      key: const ValueKey<String>('mine_detector_board'),
                      puzzle: _puzzle,
                      state: _state,
                      hintedCell: _hintedCell,
                      flagMode: _flagMode,
                      english: _english,
                      onTapCell: _tapCell,
                    ),
                  ),
                  SizedBox(height: compact ? 7 : 10),
                  _MineStatusBand(
                    english: _english,
                    flagMode: _flagMode,
                    flagsPlaced: _flagsPlaced,
                    mineCount: _puzzle.mineCount,
                    moves: _moves,
                    lost: _state.isLost,
                    notice: _notice,
                  ),
                  SizedBox(height: compact ? 7 : 10),
                  _MineToolRail(
                    english: _english,
                    flagMode: _flagMode,
                    canUndo: _undo.isNotEmpty,
                    onModeChanged: () {
                      setState(() => _flagMode = !_flagMode);
                      unawaited(
                        _audioProfile.play(
                          _audio,
                          GameAudioEvent.menu,
                          gain: .22,
                        ),
                      );
                    },
                    onHint: _showHint,
                    onUndo: _undoMove,
                    onRestart: _restart,
                  ),
                  SizedBox(height: compact ? 7 : 11),
                  Text(
                    _english
                        ? 'Tap an open clue to chord its neighbours after every required flag is placed. Guessing is never needed.'
                        : 'Gerekli bayrakları koyduktan sonra açık bir ize dokun; komşuları birlikte açılır. Tahmin gerekmez.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: _MinePalette.muted,
                      fontSize: 12,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

enum _MineAction { reveal, flag }

class _MineHint {
  const _MineHint({required this.cell, required this.shouldFlag});

  final int cell;
  final bool shouldFlag;
}

class _MinePalette {
  static const Color canvas = StudioVisuals.canvas;
  static const Color surface = StudioVisuals.surface;
  static const Color ink = StudioVisuals.ink;
  static const Color muted = StudioVisuals.muted;
  static const Color line = StudioVisuals.line;
  static const Color teal = StudioVisuals.tealInk;
  static const Color tealSoft = Color(0xFFE2F0EC);
  static const Color brass = StudioVisuals.amberInk;
  static const Color brassSoft = Color(0xFFF7EEDC);
  static const Color danger = StudioVisuals.dangerInk;
  static const Color graphite = Color(0xFF34454B);
}

class _MineHeader extends StatelessWidget {
  const _MineHeader({
    required this.stage,
    required this.english,
    required this.rows,
    required this.columns,
    required this.mines,
    required this.revealedSafe,
    required this.safeTotal,
    required this.bestScore,
  });

  final int stage;
  final bool english;
  final int rows;
  final int columns;
  final int mines;
  final int revealedSafe;
  final int safeTotal;
  final int bestScore;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: _MinePalette.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _MinePalette.line),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color(0x0D1F3134),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      children: <Widget>[
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0xFFE8F2EF), Color(0xFFD4E8E1)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFCDE1DA)),
          ),
          child: const Icon(
            Icons.radar_rounded,
            color: _MinePalette.teal,
            size: 25,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                english ? 'FIELD ANALYSIS' : 'ALAN ANALİZİ',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: _MinePalette.brass,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.05,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${english ? 'Stage' : 'Aşama'} $stage · $rows×$columns',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: _MinePalette.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '$revealedSafe/$safeTotal ${english ? 'SAFE' : 'GÜVENLİ'} · $mines ${english ? 'MINES' : 'MAYIN'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: _MinePalette.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        if (bestScore > 0)
          Container(
            constraints: const BoxConstraints(minWidth: 42),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
            decoration: BoxDecoration(
              color: _MinePalette.brassSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: <Widget>[
                const Icon(
                  Icons.emoji_events_rounded,
                  color: _MinePalette.brass,
                  size: 15,
                ),
                Text(
                  '$bestScore',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: _MinePalette.ink,
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

class _SafeOpeningBand extends StatelessWidget {
  const _SafeOpeningBand({
    required this.english,
    required this.row,
    required this.column,
  });

  final bool english;
  final int row;
  final int column;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(
      color: _MinePalette.tealSoft,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFCFE4DE)),
    ),
    child: Row(
      children: <Widget>[
        const Icon(Icons.shield_outlined, color: _MinePalette.teal, size: 17),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            english
                ? 'Protected opening: row $row · column $column is already clear.'
                : 'Korunan açılış: $row. satır · $column. sütun zaten açık.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: _MinePalette.ink,
              fontSize: 12,
              height: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

class _MineStatusBand extends StatelessWidget {
  const _MineStatusBand({
    required this.english,
    required this.flagMode,
    required this.flagsPlaced,
    required this.mineCount,
    required this.moves,
    required this.lost,
    required this.notice,
  });

  final bool english;
  final bool flagMode;
  final int flagsPlaced;
  final int mineCount;
  final int moves;
  final bool lost;
  final String? notice;

  @override
  Widget build(BuildContext context) {
    final String copy =
        notice ??
        (lost
            ? (english
                  ? 'Mine found — use Undo to preserve your route.'
                  : 'Mayın bulundu — rotanı korumak için Geri Al kullan.')
            : (flagMode
                  ? (english
                        ? 'Mark mode · touch a hidden cell to place a flag.'
                        : 'İşaret modu · bayrak koymak için kapalı hücreye dokun.')
                  : (english
                        ? 'Reveal mode · touch an open clue again to chord.'
                        : 'Açma modu · komşuları açmak için açık ize yeniden dokun.')));
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      constraints: const BoxConstraints(minHeight: 42),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: lost
            ? const Color(0xFFF9E9E7)
            : flagMode
            ? _MinePalette.brassSoft
            : _MinePalette.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: lost
              ? const Color(0xFFECC3BF)
              : flagMode
              ? const Color(0xFFE8D3AA)
              : _MinePalette.line,
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            lost
                ? Icons.warning_amber_rounded
                : flagMode
                ? Icons.bookmark_rounded
                : Icons.radar_rounded,
            color: lost
                ? _MinePalette.danger
                : flagMode
                ? _MinePalette.brass
                : _MinePalette.teal,
            size: 17,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              copy,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: _MinePalette.ink,
                fontSize: 12,
                height: 1.18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$flagsPlaced/$mineCount\n$moves ${english ? 'MOVES' : 'HAMLE'}',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: _MinePalette.muted,
              fontSize: 10,
              height: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MineToolRail extends StatelessWidget {
  const _MineToolRail({
    required this.english,
    required this.flagMode,
    required this.canUndo,
    required this.onModeChanged,
    required this.onHint,
    required this.onUndo,
    required this.onRestart,
  });

  final bool english;
  final bool flagMode;
  final bool canUndo;
  final VoidCallback onModeChanged;
  final VoidCallback onHint;
  final VoidCallback onUndo;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final List<Widget> buttons = <Widget>[
        _MineToolButton(
          key: const ValueKey<String>('mine_mode'),
          icon: flagMode ? Icons.bookmark_rounded : Icons.radar_rounded,
          label: flagMode
              ? (english ? 'MARK' : 'İŞARET')
              : (english ? 'REVEAL' : 'AÇ'),
          color: flagMode ? _MinePalette.brass : _MinePalette.teal,
          selected: true,
          onPressed: onModeChanged,
        ),
        _MineToolButton(
          key: const ValueKey<String>('mine_hint'),
          icon: Icons.lightbulb_outline_rounded,
          label: english ? 'HINT' : 'İPUCU',
          color: _MinePalette.teal,
          onPressed: onHint,
        ),
        _MineToolButton(
          key: const ValueKey<String>('mine_undo_action'),
          icon: Icons.undo_rounded,
          label: english ? 'UNDO' : 'GERİ AL',
          color: _MinePalette.graphite,
          onPressed: canUndo ? onUndo : null,
        ),
        _MineToolButton(
          key: const ValueKey<String>('mine_restart_action'),
          icon: Icons.restart_alt_rounded,
          label: english ? 'RESET' : 'SIFIRLA',
          color: _MinePalette.muted,
          onPressed: onRestart,
        ),
      ];
      if (constraints.maxWidth >= 510) {
        return Row(
          children: <Widget>[
            for (int index = 0; index < buttons.length; index++) ...<Widget>[
              Expanded(child: buttons[index]),
              if (index != buttons.length - 1) const SizedBox(width: 8),
            ],
          ],
        );
      }
      return Wrap(
        spacing: 8,
        runSpacing: 7,
        alignment: WrapAlignment.center,
        children: buttons
            .map((Widget button) => SizedBox(width: 140, child: button))
            .toList(),
      );
    },
  );
}

class _MineToolButton extends StatelessWidget {
  const _MineToolButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.selected = false,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: 16),
    label: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(label, maxLines: 1),
    ),
    style: OutlinedButton.styleFrom(
      foregroundColor: onPressed == null ? _MinePalette.muted : color,
      backgroundColor: selected
          ? color.withValues(alpha: .09)
          : _MinePalette.surface,
      minimumSize: const Size(48, GameInputPolicy.minimumTargetSize),
      padding: const EdgeInsets.symmetric(horizontal: 7),
      side: BorderSide(
        color: onPressed == null
            ? _MinePalette.line
            : color.withValues(alpha: .30),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      textStyle: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _MineBoard extends StatelessWidget {
  const _MineBoard({
    super.key,
    required this.puzzle,
    required this.state,
    required this.hintedCell,
    required this.flagMode,
    required this.english,
    required this.onTapCell,
  });

  final MineDetectorPuzzle puzzle;
  final MineDetectorBoardState state;
  final int? hintedCell;
  final bool flagMode;
  final bool english;
  final ValueChanged<int> onTapCell;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[Color(0xFFEAF0ED), Color(0xFFDCE7E2)],
      ),
      borderRadius: BorderRadius.circular(25),
      border: Border.all(color: const Color(0xFFC7D5CF)),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color(0x171B3436),
          blurRadius: 23,
          offset: Offset(0, 11),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints limits) {
          final double cell = math.max(
            12,
            math.min(
              (limits.maxWidth - 18) / puzzle.columns,
              (limits.maxHeight - 18) / puzzle.rows,
            ),
          );
          final double gridWidth = cell * puzzle.columns;
          final double gridHeight = cell * puzzle.rows;
          return Semantics(
            label: english
                ? 'Mine detector board. Pinch to inspect dense fields.'
                : 'Mayın dedektifi tahtası. Yoğun alanı incelemek için yakınlaştır.',
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 3.4,
              boundaryMargin: const EdgeInsets.all(72),
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: limits.maxWidth,
                height: limits.maxHeight,
                child: Stack(
                  children: <Widget>[
                    const Positioned.fill(
                      child: CustomPaint(painter: _MineTablePainter()),
                    ),
                    Positioned(
                      left: (limits.maxWidth - gridWidth) / 2,
                      top: (limits.maxHeight - gridHeight) / 2,
                      width: gridWidth,
                      height: gridHeight,
                      child: RepaintBoundary(
                        child: Stack(
                          children: <Widget>[
                            for (
                              int cellIndex = 0;
                              cellIndex < puzzle.cellCount;
                              cellIndex++
                            )
                              _MineCell(
                                key: ValueKey<String>('mine_cell_$cellIndex'),
                                cell: cellIndex,
                                side: cell,
                                row: cellIndex ~/ puzzle.columns,
                                column: cellIndex % puzzle.columns,
                                puzzle: puzzle,
                                state: state,
                                hinted: cellIndex == hintedCell,
                                flagMode: flagMode,
                                english: english,
                                onTap: () => onTapCell(cellIndex),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      bottom: 8,
                      child: IgnorePointer(
                        child: Text(
                          '${puzzle.rows}×${puzzle.columns} · ${puzzle.mineCount} ${english ? 'MINES' : 'MAYIN'}',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            color: Color(0xFF6C857F),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .55,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _MineCell extends StatelessWidget {
  const _MineCell({
    super.key,
    required this.cell,
    required this.side,
    required this.row,
    required this.column,
    required this.puzzle,
    required this.state,
    required this.hinted,
    required this.flagMode,
    required this.english,
    required this.onTap,
  });

  final int cell;
  final double side;
  final int row;
  final int column;
  final MineDetectorPuzzle puzzle;
  final MineDetectorBoardState state;
  final bool hinted;
  final bool flagMode;
  final bool english;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool revealed = state.revealed.contains(cell);
    final bool flagged = state.flagged.contains(cell);
    final bool mine = puzzle.isMine(cell);
    final bool exploded = state.explodedCell == cell;
    final bool showMine = exploded || (state.isLost && mine);
    final int clue = puzzle.adjacentMineCount(cell);
    final String semanticLabel = revealed
        ? (showMine
              ? (english ? 'Mine' : 'Mayın')
              : clue == 0
              ? (english ? 'Clear cell' : 'Boş hücre')
              : (english ? 'Clue $clue' : '$clue izi'))
        : flagged
        ? (english ? 'Flagged cell' : 'Bayraklı hücre')
        : (english ? 'Hidden cell' : 'Kapalı hücre');
    return Positioned(
      left: column * side,
      top: row * side,
      width: side,
      height: side,
      child: Semantics(
        button: true,
        label: semanticLabel,
        hint: flagMode
            ? (english ? 'Toggle flag' : 'Bayrağı değiştir')
            : (english ? 'Reveal or chord' : 'Aç veya birlikte aç'),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.all(math.max(.6, side * .055)),
            decoration: BoxDecoration(
              boxShadow: hinted
                  ? <BoxShadow>[
                      BoxShadow(
                        color: _MinePalette.teal.withValues(alpha: .58),
                        blurRadius: side * .5,
                        spreadRadius: side * .05,
                      ),
                    ]
                  : null,
            ),
            child: CustomPaint(
              painter: _MineCellPainter(
                revealed: revealed,
                flagged: flagged,
                showMine: showMine,
                exploded: exploded,
                hinted: hinted,
              ),
              child: Center(
                child: _MineCellGlyph(
                  side: side,
                  revealed: revealed,
                  flagged: flagged,
                  showMine: showMine,
                  clue: clue,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MineCellGlyph extends StatelessWidget {
  const _MineCellGlyph({
    required this.side,
    required this.revealed,
    required this.flagged,
    required this.showMine,
    required this.clue,
  });

  final double side;
  final bool revealed;
  final bool flagged;
  final bool showMine;
  final int clue;

  @override
  Widget build(BuildContext context) {
    if (flagged && !showMine) {
      return Icon(
        Icons.bookmark_rounded,
        size: math.max(8, side * .56),
        color: _MinePalette.brass,
      );
    }
    if (showMine) {
      return Icon(
        Icons.adjust_rounded,
        size: math.max(8, side * .62),
        color: _MinePalette.danger,
      );
    }
    if (!revealed || clue == 0) return const SizedBox.shrink();
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        '$clue',
        style: TextStyle(
          fontFamily: 'Roboto',
          color: _clueColor(clue),
          fontSize: math.max(8, side * .62),
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  static Color _clueColor(int clue) => switch (clue) {
    1 => const Color(0xFF3C8B80),
    2 => const Color(0xFF4E7895),
    3 => const Color(0xFFB57850),
    4 => const Color(0xFF9A657E),
    _ => _MinePalette.graphite,
  };
}

class _MineTablePainter extends CustomPainter {
  const _MineTablePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint halo = Paint()
      ..color = const Color(0xFF6C9188).withValues(alpha: .07)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
    canvas.drawCircle(
      Offset(size.width * .52, size.height * .45),
      size.width * .36,
      halo,
    );
    final Paint stitch = Paint()
      ..color = const Color(0xFF79978F).withValues(alpha: .22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8, 8, size.width - 16, size.height - 16),
        const Radius.circular(20),
      ),
      stitch,
    );
    for (double x = 18; x < size.width - 18; x += 26) {
      canvas.drawCircle(
        Offset(x, 14),
        1,
        Paint()..color = const Color(0xFF7E9992).withValues(alpha: .25),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MineTablePainter oldDelegate) => false;
}

class _MineCellPainter extends CustomPainter {
  const _MineCellPainter({
    required this.revealed,
    required this.flagged,
    required this.showMine,
    required this.exploded,
    required this.hinted,
  });

  final bool revealed;
  final bool flagged;
  final bool showMine;
  final bool exploded;
  final bool hinted;

  @override
  void paint(Canvas canvas, Size size) {
    final double corner = math.max(1.2, size.shortestSide * .17);
    final RRect face = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(corner),
    );
    final Color edge = exploded
        ? _MinePalette.danger
        : hinted
        ? _MinePalette.teal
        : flagged
        ? _MinePalette.brass
        : revealed
        ? const Color(0xFFCAD5D0)
        : const Color(0xFFB6C8C1);
    if (!revealed) {
      canvas.drawRRect(
        face.shift(Offset(size.width * .055, size.height * .075)),
        Paint()
          ..color = const Color(0xFF28413C).withValues(alpha: .16)
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            math.max(1, size.shortestSide * .06),
          ),
      );
    }
    canvas.drawRRect(
      face,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: revealed
              ? <Color>[const Color(0xFFF7F8F4), const Color(0xFFE8ECE6)]
              : <Color>[const Color(0xFFFFFEFA), const Color(0xFFEBF0EA)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawRRect(
      face,
      Paint()
        ..color = edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = hinted
            ? math.max(1.4, size.shortestSide * .1)
            : math.max(.65, size.shortestSide * .035),
    );
    if (!revealed && !flagged) {
      final Paint glint = Paint()
        ..color = Colors.white.withValues(alpha: .75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.6, size.shortestSide * .025);
      canvas.drawLine(
        Offset(size.width * .2, size.height * .2),
        Offset(size.width * .7, size.height * .2),
        glint,
      );
    }
    if (showMine && exploded) {
      canvas.drawRRect(
        face,
        Paint()..color = _MinePalette.danger.withValues(alpha: .12),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MineCellPainter oldDelegate) =>
      oldDelegate.revealed != revealed ||
      oldDelegate.flagged != flagged ||
      oldDelegate.showMine != showMine ||
      oldDelegate.exploded != exploded ||
      oldDelegate.hinted != hinted;
}
