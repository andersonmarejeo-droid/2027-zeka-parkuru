import '../shared/studio_game_contracts.dart';

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
import 'chess_mate_puzzle.dart';
import 'chess_piece_painter.dart';

class ChessMateGamePage extends StatelessWidget {
  const ChessMateGamePage({
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
    GameContentPolicy.nativeStages('mini_chess_tactics'),
    (int index) {
      final int level = index + 1;
      final int stage = index % 10 + 1;
      final int chapter = index ~/ 10 + 1;
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Satranç Matı ${level.toString().padLeft(2, '0')}',
        titleEn: 'Chess Mate ${level.toString().padLeft(2, '0')}',
        subtitleTr: _subtitle(stage, chapter, english: false),
        subtitleEn: _subtitle(stage, chapter, english: true),
        difficulty: switch (stage) {
          <= 6 => chapter == 1 ? 'USTALAŞMA' : 'DERİNLEŞME',
          7 || 8 => 'İLERİ',
          9 => 'UZMAN',
          _ => 'USTA',
        },
        icon: Icons.grid_4x4_rounded,
      );
    },
    growable: false,
  );

  static String _subtitle(int stage, int chapter, {required bool english}) {
    if (chapter == 2 && stage <= 6) {
      return english
          ? 'Read a denser board, then prove the unique mating move.'
          : 'Daha yoğun tahtada tek mat hamlesini okuyup doğrula.';
    }
    return switch (stage) {
      <= 3 =>
        english
            ? 'Scan the king’s escape squares before choosing your move.'
            : 'Hamleni seçmeden önce şahın kaçış karelerini tara.',
      <= 6 =>
        english
            ? 'Check every legal reply: only one move delivers mate.'
            : 'Tüm yasal cevapları düşün: yalnız bir hamle mat eder.',
      7 || 8 =>
        english
            ? 'Advanced: combine piece coordination with a safe king net.'
            : 'İleri düzey: taş uyumunu güvenli şah ağıyla birleştir.',
      9 =>
        english
            ? 'Expert board: compare candidate checks and quiet geometry.'
            : 'Uzman tahtası: aday şahları ve sessiz geometrileri karşılaştır.',
      _ =>
        english
            ? 'Master study: identify the only legal immediate checkmate.'
            : 'Usta etüdü: yasal tek mat hamlesini bul ve uygula.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forId('mini_chess_tactics');
    return ParkurLevelHub(
      gameId: 'mini_chess_tactics',
      progressPrefix: 'mini_chess_tactics',
      titleTr: 'Satranç Matı',
      titleEn: 'Chess Mate',
      taglineTr: 'Şahı oku • Aday hamleleri tara • Matı kanıtla',
      taglineEn: 'Read the king • Scan candidates • Prove the mate',
      accent: skin.accent,
      icon: Icons.grid_4x4_rounded,
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
          ) => ChessMatePlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class ChessMatePlayPage extends StatefulWidget {
  const ChessMatePlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<ChessMatePlayPage> createState() => _ChessMatePlayPageState();
}

class _ChessMatePlayPageState extends State<ChessMatePlayPage> {
  static const Color _accent = Color(0xFF866139);
  static const Color _ivory = Color(0xFFF2EBDD);
  static const Color _sage = Color(0xFF82948B);
  static const Color _ink = StudioVisuals.ink;
  static const Color _selected = Color(0xFFD8AF68);
  static const Color _error = Color(0xFFBD6562);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.strategy,
  );
  late ChessMatePuzzle _puzzle;
  late ChessPosition _position;
  late StudioGameSession _session;
  int? _selectedSquare;
  int? _lastFrom;
  int? _lastTo;
  int? _hintTarget;
  int _hintStage = 0;
  int _mistakes = 0;
  int _hints = 0;
  bool _ready = false;
  bool _finished = false;
  bool _english = false;
  String? _notice;

  int get _score => math.max(0, 5000 - _hints * 300 - _mistakes * 180);

  int get _stars {
    if (_hints == 0 && _mistakes == 0) return 3;
    if (_hints <= 2 && _mistakes <= 2) return 2;
    return 1;
  }

  @override
  void initState() {
    super.initState();
    unawaited(_audioProfile.preload(_audio));
    unawaited(_preparePuzzle());
  }

  Future<void> _preparePuzzle() async {
    ChessMatePuzzle puzzle = (widget.level.poolIndex != null
        ? ChessMatePuzzle.forPracticeBoard(widget.level.contentIndex)
        : ChessMatePuzzle.forLevel(widget.level.contentLevel));
    try {
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      final String visitKey =
          'mini_chess_tactics_level_${widget.level.number}_visits';
      final int visits = await preferences.getInt(visitKey) ?? 0;
      if (widget.level.poolIndex == null && visits > 0) {
        final int played =
            await preferences.getInt('mini_chess_tactics_practice_index') ?? 0;
        if (played < ChessMatePuzzle.maximumVerifiedBoards) {
          final int next = played + 1;
          await preferences.setInt('mini_chess_tactics_practice_index', next);
          puzzle = ChessMatePuzzle.forPracticeBoard(next);
        }
      }
      await preferences.setInt(visitKey, visits + 1);
    } catch (_) {
      puzzle = (widget.level.poolIndex != null
          ? ChessMatePuzzle.forPracticeBoard(widget.level.contentIndex)
          : ChessMatePuzzle.forLevel(widget.level.contentLevel));
    }
    if (!mounted) return;
    setState(() => _loadPuzzle(puzzle));
  }

  void _loadPuzzle(ChessMatePuzzle puzzle) {
    _puzzle = puzzle;
    _position = puzzle.position;
    _session = StudioGameSession(level: widget.level.number, seed: puzzle.seed)
      ..start();
    _selectedSquare = null;
    _lastFrom = null;
    _lastTo = null;
    _hintTarget = null;
    _hintStage = 0;
    _mistakes = 0;
    _hints = 0;
    _notice = null;
    _finished = false;
    _ready = true;
  }

  List<ChessMove> get _selectedMoves => _selectedSquare == null
      ? const <ChessMove>[]
      : _position
            .legalMoves()
            .where((ChessMove move) => move.from == _selectedSquare)
            .toList(growable: false);

  Set<int> get _targetSquares =>
      _selectedMoves.map((ChessMove move) => move.to).toSet();

  void _tapSquare(int square) {
    if (!_ready || _finished || !_session.acceptsInput) return;
    final List<ChessMove> candidates = _selectedMoves
        .where((ChessMove move) => move.to == square)
        .toList(growable: false);
    if (candidates.isNotEmpty) {
      final ChessMove chosen = candidates.firstWhere(
        (ChessMove move) => move.promotion == ChessPieceType.queen,
        orElse: () => candidates.first,
      );
      _tryMove(chosen);
      return;
    }
    final ChessPiece? piece = _position.board[square];
    if (piece?.side == ChessSide.white) {
      setState(() {
        _selectedSquare = square;
        _notice = _english
            ? 'Choose one of the softly marked legal destination squares.'
            : 'Yumuşak vurgulu karelerden bir yasal hedef seç.';
      });
      _audio.hapticSelection();
      unawaited(
        _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .22),
      );
      return;
    }
    if (_selectedSquare != null) {
      setState(() {
        _selectedSquare = null;
        _notice = _english
            ? 'That square is not a legal destination.'
            : 'Bu kare seçili taş için yasal hedef değil.';
      });
    }
  }

  void _tryMove(ChessMove move) {
    final ChessPosition after = _position.play(move);
    if (!after.isCheckmate(ChessSide.black)) {
      _session.recordMistake();
      _audio.hapticLight();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .22));
      setState(() {
        _mistakes++;
        _selectedSquare = null;
        _notice = _english
            ? 'Legal move, but not mate. Re-scan the king’s escape squares.'
            : 'Hamle yasal ama mat değil. Şahın kaçış karelerini yeniden tara.';
      });
      return;
    }
    setState(() {
      _position = after;
      _selectedSquare = null;
      _lastFrom = move.from;
      _lastTo = move.to;
      _hintTarget = null;
      _notice = _english
          ? 'Checkmate confirmed by the chess engine.'
          : 'Şah matı satranç motoruyla doğrulandı.';
    });
    _audio.hapticMedium();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .36));
    unawaited(_finish());
  }

  void _undoSelection() {
    if (_finished || _selectedSquare == null) return;
    setState(() {
      _selectedSquare = null;
      _notice = _english ? 'Selection cleared.' : 'Taş seçimi kaldırıldı.';
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .2));
  }

  void _showHint() {
    if (!_ready || _finished || !_session.canUseHint) return;
    _session.useHint(pointCost: 300);
    setState(() {
      _hints++;
      _hintStage = (_hintStage + 1).clamp(1, 2);
      _hintTarget = _hintStage == 1
          ? _puzzle.solution.from
          : _puzzle.solution.to;
      _selectedSquare = _hintStage == 1 ? _puzzle.solution.from : null;
      _notice = _hintStage == 1
          ? (_english
                ? 'The mating piece is highlighted.'
                : 'Mat edecek taş vurgulandı.')
          : (_english
                ? 'Its mating destination is highlighted.'
                : 'Mat hedef karesi vurgulandı.');
    });
    _audio.hapticSelection();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .28));
  }

  Future<void> _confirmReset() async {
    if (!_ready || _finished) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(
          _english ? 'Restart this study?' : 'Etüt yeniden başlasın mı?',
        ),
        content: Text(
          _english
              ? 'The same verified chess position will be restored.'
              : 'Aynı doğrulanmış satranç konumu yeniden kurulacak.',
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
    setState(() => _loadPuzzle(_puzzle));
  }

  Future<void> _finish() async {
    if (_finished || !mounted) return;
    _finished = true;
    final int score = _score;
    final int stars = _stars;
    _session.recordAccepted(points: 45);
    _session.complete(
      stars: stars,
      action: widget.level.number < ChessMateGamePage.totalCases
          ? StudioResultAction.next
          : StudioResultAction.map,
    );
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
      titleTr: 'ŞAH MAT',
      titleEn: 'CHECKMATE',
      detailTr:
          '${ChessSquare.name(_puzzle.solution.from).toUpperCase()} → ${ChessSquare.name(_puzzle.solution.to).toUpperCase()} · $_hints ipucu.',
      detailEn:
          '${ChessSquare.name(_puzzle.solution.from).toUpperCase()} → ${ChessSquare.name(_puzzle.solution.to).toUpperCase()} · $_hints hints.',
      stars: stars,
      score: score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < ChessMateGamePage.totalCases,
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

  void _showHowToPlay(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: StudioVisuals.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.castle_rounded, color: _accent, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            _english ? 'Chess Tactics Rules' : 'Satranç Taktiği Kuralları',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: StudioVisuals.ink,
                            ),
                          ),
                          Text(
                            _english ? 'Mate in one tactical puzzle' : 'Tek hamlede mat bulmacası',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              color: StudioVisuals.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: StudioVisuals.surfaceSoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _accent.withValues(alpha: 0.20)),
                  ),
                  child: Text(
                    _english
                        ? 'White to move. Select a white piece, then tap its legal destination square. Find the single decisive move that leaves the black king in check with zero legal escapes (checkmate)!'
                        : 'Beyaz oynar. Hamle yapmak için önce beyaz bir taşa, ardından gideceği yeşil noktalı hedef kareye dokun. Siyah şaha hiçbir yasal kaçış bırakmayan tek mat hamlesini bul!',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      height: 1.4,
                      color: StudioVisuals.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _english ? 'UNDERSTOOD' : 'ANLADIM, BAŞLA',
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
          elevation: 0,
          title: Text(
            _english ? 'CHESS MATE' : 'SATRANÇ MATI',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        body: const Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    final Set<int> targetSquares = _targetSquares;

    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 12,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _english ? 'CHESS MATE' : 'SATRANÇ MATI',
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
            Text(
              '${_english ? 'Level' : 'Bölüm'} ${widget.level.number} • ${_puzzle.difficultyTier}',
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: StudioVisuals.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: _english ? 'How to Play' : 'Nasıl Oynanır',
            icon: const Icon(Icons.help_outline_rounded, size: 22),
            onPressed: () => _showHowToPlay(context),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveGameFrame(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Kompakt Tek Satır Durum Çubuğu
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: StudioVisuals.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: StudioVisuals.line),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: StudioVisuals.teal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _english ? 'WHITE TO MOVE' : 'BEYAZ OYNAR',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            color: StudioVisuals.teal,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _puzzle.difficultyTier,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          color: StudioVisuals.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.error_outline_rounded,
                            size: 14,
                            color: _mistakes > 0 ? StudioVisuals.danger : StudioVisuals.muted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '$_mistakes',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: _mistakes > 0 ? StudioVisuals.danger : StudioVisuals.ink,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Genişletilmiş Satranç Tahtası (Kaydırmasız - Expanded)
                Expanded(
                  child: Center(
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints constraints) {
                        final double boardSize = math.min(constraints.maxWidth, constraints.maxHeight);
                        final double cellSize = (boardSize - 10) / 8;
                        return Container(
                          key: const ValueKey<String>('chess_mate_board'),
                          width: boardSize,
                          height: boardSize,
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0D7C9),
                            borderRadius: BorderRadius.circular(19),
                            border: Border.all(color: const Color(0xFFD0C5B5)),
                            boxShadow: StudioVisuals.softShadow,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemCount: 64,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 8,
                                mainAxisSpacing: 0,
                                crossAxisSpacing: 0,
                              ),
                              itemBuilder: (BuildContext context, int index) {
                                final int file = index % 8;
                                final int rank = 7 - index ~/ 8;
                                final int square = ChessSquare.index(file, rank);
                                return _ChessSquare(
                                  key: ValueKey<String>('chess-square-${ChessSquare.name(square)}'),
                                  square: square,
                                  piece: _position.board[square],
                                  cellSize: cellSize,
                                  selected: square == _selectedSquare,
                                  target: targetSquares.contains(square),
                                  lastMove: square == _lastFrom || square == _lastTo,
                                  hinted: square == _hintTarget,
                                  english: _english,
                                  onTap: () => _tapSquare(square),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (_notice != null) ...<Widget>[
                  const SizedBox(height: 4),
                  _ChessNotice(
                    text: _notice!,
                    warning: _notice!.contains(_english ? 'not mate' : 'mat değil'),
                  ),
                ],
                const SizedBox(height: 6),
                // Alt Kontrol Butonları
                _ChessActions(
                  canUndo: _selectedSquare != null,
                  busy: _finished,
                  english: _english,
                  onUndo: _undoSelection,
                  onHint: _showHint,
                  onReset: _confirmReset,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChessSquare extends StatelessWidget {
  const _ChessSquare({
    super.key,
    required this.square,
    required this.piece,
    required this.cellSize,
    required this.selected,
    required this.target,
    required this.lastMove,
    required this.hinted,
    required this.english,
    required this.onTap,
  });

  final int square;
  final ChessPiece? piece;
  final double cellSize;
  final bool selected;
  final bool target;
  final bool lastMove;
  final bool hinted;
  final bool english;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final int file = ChessSquare.file(square);
    final int rank = ChessSquare.rank(square);
    final Color base = (file + rank).isEven
        ? _ChessMatePlayPageState._ivory
        : _ChessMatePlayPageState._sage;
    final String label =
        '${piece == null ? (english ? 'Empty' : 'Boş') : '${piece!.side == ChessSide.white ? (english ? 'White' : 'Beyaz') : (english ? 'Black' : 'Siyah')} ${_pieceName(piece!.type, english)}'}, ${ChessSquare.name(square)}';
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: base,
        child: InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              color: selected
                  ? _ChessMatePlayPageState._selected.withValues(alpha: .66)
                  : hinted
                  ? const Color(0xFF76B8A6).withValues(alpha: .76)
                  : lastMove
                  ? const Color(0xFFE7C77D).withValues(alpha: .32)
                  : Colors.transparent,
              border: selected || hinted
                  ? Border.all(
                      color: _ChessMatePlayPageState._accent,
                      width: 2.2,
                    )
                  : null,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                if (piece != null)
                  Center(
                    child: CustomPaint(
                      key: ValueKey<String>(
                        'piece-${ChessSquare.name(square)}',
                      ),
                      size: Size.square(cellSize * .82),
                      painter: ChessPiecePainter(piece: piece!),
                    ),
                  ),
                if (target && piece == null)
                  Center(
                    child: Container(
                      width: cellSize * .22,
                      height: cellSize * .22,
                      decoration: const BoxDecoration(
                        color: Color(0x8A344C57),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                if (target && piece != null)
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.all(cellSize * .08),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xCCB85F59),
                            width: 2,
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                if (file == 0)
                  Positioned(
                    left: 2,
                    top: 1,
                    child: Text(
                      '${rank + 1}',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: math.max(7.0, cellSize * .17),
                        height: 1,
                        fontWeight: FontWeight.w800,
                        color: base == _ChessMatePlayPageState._ivory
                            ? _ChessMatePlayPageState._sage
                            : Colors.white.withValues(alpha: .86),
                      ),
                    ),
                  ),
                if (rank == 0)
                  Positioned(
                    right: 2,
                    bottom: 0,
                    child: Text(
                      String.fromCharCode(97 + file),
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: math.max(7.0, cellSize * .17),
                        height: 1,
                        fontWeight: FontWeight.w800,
                        color: base == _ChessMatePlayPageState._ivory
                            ? _ChessMatePlayPageState._sage
                            : Colors.white.withValues(alpha: .86),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _pieceName(ChessPieceType type, bool english) => switch (type) {
    ChessPieceType.king => english ? 'king' : 'şah',
    ChessPieceType.queen => english ? 'queen' : 'vezir',
    ChessPieceType.rook => english ? 'rook' : 'kale',
    ChessPieceType.bishop => english ? 'bishop' : 'fil',
    ChessPieceType.knight => english ? 'knight' : 'at',
    ChessPieceType.pawn => english ? 'pawn' : 'piyon',
  };
}

/// High-contrast, font-independent chessmen so white pieces stay readable on
/// the light squares and remain distinct across Android font configurations.

class _ChessActions extends StatelessWidget {
  const _ChessActions({
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
          label: english ? 'Undo' : 'Geri al',
          enabled: canUndo && !busy,
          onPressed: onUndo,
        ),
      ),
      const SizedBox(width: 7),
      Expanded(
        child: _ActionButton(
          icon: Icons.lightbulb_outline_rounded,
          label: english ? 'Hint' : 'İpucu',
          enabled: !busy,
          onPressed: onHint,
        ),
      ),
      const SizedBox(width: 7),
      Expanded(
        child: _ActionButton(
          icon: Icons.restart_alt_rounded,
          label: english ? 'Reset' : 'Sıfırla',
          enabled: !busy,
          onPressed: onReset,
        ),
      ),
    ],
  );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
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
    height: 48,
    child: OutlinedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 17),
      label: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
      style: OutlinedButton.styleFrom(
        foregroundColor: _ChessMatePlayPageState._ink,
        disabledForegroundColor: StudioVisuals.muted.withValues(alpha: .48),
        padding: const EdgeInsets.symmetric(horizontal: 5),
        side: const BorderSide(color: StudioVisuals.line),
        backgroundColor: StudioVisuals.surface,
        textStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}

class _ChessNotice extends StatelessWidget {
  const _ChessNotice({required this.text, required this.warning});
  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: warning ? const Color(0xFFFFF1EC) : const Color(0xFFF0F4F0),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: warning ? const Color(0xFFE9CDC6) : const Color(0xFFDCE6DE),
      ),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'Roboto',
        color: warning
            ? _ChessMatePlayPageState._error
            : _ChessMatePlayPageState._ink,
        fontSize: 12,
        height: 1.3,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}