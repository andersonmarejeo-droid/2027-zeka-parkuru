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
import 'shogi_mate_puzzle.dart';
import 'shogi_position.dart';

class ShogiMateGamePage extends StatelessWidget {
  const ShogiMateGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  static const int totalCases = ShogiMatePuzzle.maximumLevels;
  static const int totalStars = totalCases * 3;

  static final List<ParkurLevelSpec> _levels = List<ParkurLevelSpec>.generate(
    totalCases,
    (int index) {
      final int level = index + 1;
      final int stage = index % 10 + 1;
      final int chapter = index ~/ 10 + 1;
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Shogi Mat ${level.toString().padLeft(2, '0')}',
        titleEn: 'Shogi Mate ${level.toString().padLeft(2, '0')}',
        subtitleTr: _subtitle(stage, chapter, english: false),
        subtitleEn: _subtitle(stage, chapter, english: true),
        difficulty: switch (stage) {
          <= 6 => chapter == 1 ? 'USTALAŞMA' : 'DERİNLEŞME',
          7 || 8 => 'İLERİ',
          9 => 'UZMAN',
          _ => 'USTA',
        },
        icon: Icons.grid_on_rounded,
      );
    },
    growable: false,
  );

  static String _subtitle(int stage, int chapter, {required bool english}) {
    if (chapter == 2 && stage <= 6) {
      return english
          ? 'Read a busier board while keeping the drop and promotion rules.'
          : 'Daha yoğun tahtada taş düşürme ve terfi kurallarını birlikte oku.';
    }
    return switch (stage) {
      <= 3 =>
        english
            ? 'Place the hand piece on the only mating square.'
            : 'Eldeki taşı mat eden tek kareye bırak.',
      <= 6 =>
        english
            ? 'Check escape squares and the defender of each dropped piece.'
            : 'Kaçış karelerini ve düşürülen taşın korumasını tara.',
      7 || 8 =>
        english
            ? 'Advanced: distinguish legal drops from dead-rank traps.'
            : 'İleri: yasal taş düşürmeyi çıkmaz karelerden ayır.',
      9 =>
        english
            ? 'Expert: account for promotion and king-safety constraints.'
            : 'Uzman: terfi ve şah güvenliği kısıtlarını birlikte değerlendir.',
      _ =>
        english
            ? 'Master tsume: prove the only legal mating move.'
            : 'Usta tsume: mat eden tek yasal hamleyi kanıtla.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(
      StudioGameClass.strategy,
    );
    return ParkurLevelHub(
      gameId: 'shogi_mate',
      progressPrefix: 'shogi_mate',
      titleTr: 'Shogi Mat',
      titleEn: 'Shogi Mate',
      taglineTr: 'Şahı çevrele • Eli kullan • Matı doğrula',
      taglineEn: 'Net the king • Use the hand • Prove the mate',
      accent: skin.accent,
      icon: Icons.grid_on_rounded,
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
          ) => ShogiMatePlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class ShogiMatePlayPage extends StatefulWidget {
  const ShogiMatePlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<ShogiMatePlayPage> createState() => _ShogiMatePlayPageState();
}

class _ShogiMatePlayPageState extends State<ShogiMatePlayPage> {
  static const Color _accent = Color(0xFF6F7E68);
  static const Color _ink = Color(0xFF29373A);
  static const Color _board = Color(0xFFE9DCC3);
  static const Color _grid = Color(0xFF8A7962);
  static const Color _gold = Color(0xFFC4974E);
  static const Color _error = Color(0xFFB9655E);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.strategy,
  );

  late ShogiMatePuzzle _puzzle;
  late ShogiPosition _position;
  late StudioGameSession _session;
  late List<ShogiMove> _legalMoves;
  int? _selectedFrom;
  int? _hintedDestination;
  int? _wrongDestination;
  ShogiPieceType? _selectedDrop;
  int _hints = 0;
  int _mistakes = 0;
  bool _ready = false;
  bool _finished = false;
  bool _english = false;
  String? _notice;

  bool get _rotated => _puzzle.position.toMove == ShogiSide.white;
  int get _score => math.max(0, 5000 - _hints * 300 - _mistakes * 180);
  int get _stars => _hints == 0 && _mistakes == 0
      ? 3
      : _hints <= 2
      ? 2
      : 1;

  @override
  void initState() {
    super.initState();
    unawaited(_audioProfile.preload(_audio));
    unawaited(_preparePuzzle());
  }

  Future<void> _preparePuzzle() async {
    ShogiMatePuzzle puzzle = ShogiMatePuzzle.forLevel(widget.level.number);
    try {
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      final String visitKey = 'shogi_mate_level_${widget.level.number}_visits';
      final int visits = await preferences.getInt(visitKey) ?? 0;
      if (visits > 0) {
        final int index =
            await preferences.getInt('shogi_mate_practice_index') ?? 0;
        if (index < ShogiMatePuzzle.maximumVerifiedBoards) {
          final int next = index + 1;
          await preferences.setInt('shogi_mate_practice_index', next);
          puzzle = ShogiMatePuzzle.forPracticeBoard(next);
        }
      }
      await preferences.setInt(visitKey, visits + 1);
    } catch (_) {
      puzzle = ShogiMatePuzzle.forLevel(widget.level.number);
    }
    if (!mounted) return;
    setState(() {
      _puzzle = puzzle;
      _position = puzzle.position;
      _legalMoves = puzzle.position.legalMoves();
      _session = StudioGameSession(
        level: widget.level.number,
        seed: puzzle.seed,
      )..start();
      _selectedFrom = null;
      _hintedDestination = null;
      _wrongDestination = null;
      _selectedDrop = null;
      _hints = 0;
      _mistakes = 0;
      _notice = null;
      _finished = false;
      _ready = true;
    });
  }

  int? _squareAt(Offset local, Size size) {
    final double spacing = size.width / 10;
    final int viewRow = (local.dy / spacing).round() - 1;
    final int viewColumn = (local.dx / spacing).round() - 1;
    if (viewRow < 0 || viewRow >= 9 || viewColumn < 0 || viewColumn >= 9) {
      return null;
    }
    if ((local.dy - (viewRow + 1) * spacing).abs() > spacing * .47 ||
        (local.dx - (viewColumn + 1) * spacing).abs() > spacing * .47) {
      return null;
    }
    final int row = _rotated ? 8 - viewRow : viewRow;
    final int column = _rotated ? 8 - viewColumn : viewColumn;
    return ShogiSquare.index(row, column);
  }

  void _onBoardTap(TapUpDetails details, Size boardSize) {
    if (!_ready || _finished || !_session.acceptsInput) return;
    final int? square = _squareAt(details.localPosition, boardSize);
    if (square == null) return;
    _hintedDestination = null;
    final ShogiPiece? piece = _position.at(square);
    if (_selectedDrop != null) {
      final ShogiMove? drop = _legalMoves.cast<ShogiMove?>().firstWhere(
        (ShogiMove? move) => move?.drop == _selectedDrop && move?.to == square,
        orElse: () => null,
      );
      if (drop != null) {
        _tryMove(drop);
      } else {
        _reject(
          _english
              ? 'That drop is illegal under Shogi rules.'
              : 'Bu taş düşürme Shogi kurallarına göre yasak.',
        );
      }
      return;
    }
    if (_selectedFrom == null) {
      if (piece?.side == _position.toMove) {
        setState(() {
          _selectedFrom = square;
          _notice = _english
              ? 'Choose a highlighted legal destination.'
              : 'Vurgulanan yasal hedef karelerden birini seç.';
        });
      }
      return;
    }
    if (piece?.side == _position.toMove) {
      setState(() => _selectedFrom = square);
      return;
    }
    final List<ShogiMove> options = _legalMoves
        .where(
          (ShogiMove move) => move.from == _selectedFrom && move.to == square,
        )
        .toList(growable: false);
    if (options.isEmpty) {
      _reject(
        _english
            ? 'No legal move connects those squares.'
            : 'Bu iki kare arasında yasal hamle yok.',
      );
      return;
    }
    final ShogiMove move = options.length == 1
        ? options.single
        : options.firstWhere(
            (ShogiMove move) => move.promote,
            orElse: () => options.first,
          );
    _tryMove(move);
  }

  void _tryMove(ShogiMove move) {
    final ShogiPosition? next = _position.play(move);
    if (next == null) {
      _reject(_english ? 'Illegal move.' : 'Yasal olmayan hamle.');
      return;
    }
    if (!next.isCheckmate()) {
      _reject(
        _english
            ? 'Legal, but it does not mate. Keep the line and try another candidate.'
            : 'Yasal ama mat değil. Çıkmazı geri alıp başka adayı dene.',
      );
      setState(() {
        _wrongDestination = move.to;
        _selectedFrom = null;
        _selectedDrop = null;
      });
      return;
    }
    _session.recordAccepted(points: 60);
    _audio.hapticMedium();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .25));
    setState(() {
      _position = next;
      _selectedFrom = null;
      _selectedDrop = null;
      _wrongDestination = null;
      _notice = _english
          ? 'Checkmate confirmed. The defender has no legal answer.'
          : 'Şah mat doğrulandı. Savunmanın yasal cevabı kalmadı.';
    });
    unawaited(_finish());
  }

  void _reject(String message) {
    _session.recordMistake();
    _audio.hapticLight();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .18));
    setState(() {
      _mistakes++;
      _notice = message;
      _selectedFrom = null;
      _selectedDrop = null;
    });
  }

  void _selectDrop(ShogiPieceType type) {
    if (!_ready || _finished || !_session.acceptsInput) return;
    if ((_position.hands[_position.toMove]?[type] ?? 0) <= 0) return;
    setState(() {
      _selectedDrop = type;
      _selectedFrom = null;
      _hintedDestination = null;
      _notice = _english
          ? 'Tap an empty intersection to drop the selected piece.'
          : 'Seçili taşı bırakmak için boş bir kesişime dokun.';
    });
    _audio.hapticSelection();
  }

  void _undo() {
    if (!_ready || _finished) return;
    setState(() {
      _selectedFrom = null;
      _selectedDrop = null;
      _wrongDestination = null;
      _notice = _english ? 'Candidate cleared.' : 'Aday hamle temizlendi.';
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .2));
  }

  void _showHint() {
    if (!_ready || _finished || !_session.canUseHint) return;
    _session.useHint(pointCost: 300);
    setState(() {
      _hints++;
      _selectedDrop = ShogiPieceType.gold;
      _selectedFrom = null;
      _hintedDestination = _puzzle.solution.to;
      _notice = _english
          ? 'Gold marks the certified drop. Verify its cover and every king escape.'
          : 'Altın kare doğrulanmış taş düşürme noktasını gösterir. Korumasını ve tüm şah kaçışlarını doğrula.';
    });
    _audio.hapticSelection();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .25));
  }

  Future<void> _confirmReset() async {
    if (!_ready || _finished) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(
          _english
              ? 'Reset this Shogi study?'
              : 'Bu Shogi etüdü sıfırlansın mı?',
        ),
        content: Text(
          _english
              ? 'The same certified board will be restored.'
              : 'Aynı doğrulanmış tahta yeniden kurulacak.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(_english ? 'Keep reading' : 'Okumaya devam et'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(_english ? 'Reset' : 'Sıfırla'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _position = _puzzle.position;
      _legalMoves = _position.legalMoves();
      _selectedFrom = null;
      _selectedDrop = null;
      _hintedDestination = null;
      _wrongDestination = null;
      _hints = 0;
      _mistakes = 0;
      _notice = null;
    });
  }

  Future<void> _finish() async {
    if (_finished || !mounted) return;
    _finished = true;
    final int score = _score;
    final int stars = _stars;
    _session.complete(
      stars: stars,
      action: widget.level.number < ShogiMateGamePage.totalCases
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
      titleTr: 'SHOGI MAT',
      titleEn: 'SHOGI CHECKMATE',
      detailTr:
          '9×9 tahta · ${_puzzle.proofCandidateMoves} yasal aday · $_hints ipucu.',
      detailEn:
          '9×9 board · ${_puzzle.proofCandidateMoves} legal candidates · $_hints hints.',
      stars: stars,
      score: score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < ShogiMateGamePage.totalCases,
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
    if (!_ready) {
      return Scaffold(
        backgroundColor: StudioVisuals.canvas,
        appBar: AppBar(
          backgroundColor: StudioVisuals.canvas,
          foregroundColor: StudioVisuals.ink,
          title: Text(_english ? 'SHOGI MATE' : 'SHOGI MAT'),
        ),
        body: const Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    final Set<int> legalTargets = <int>{
      for (final ShogiMove move in _legalMoves)
        if (move.from == _selectedFrom && !move.isDrop) move.to,
      if (_selectedDrop != null)
        for (final ShogiMove move in _legalMoves)
          if (move.drop == _selectedDrop) move.to,
    };
    final int handCount = _position.hands[_position.toMove]!.values.fold<int>(
      0,
      (int sum, int count) => sum + count,
    );
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 14,
        title: Text(
          _english ? 'SHOGI MATE' : 'SHOGI MAT',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Center(child: _ShogiLevelPill(level: widget.level.number)),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(10, 3, 10, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _ShogiStatus(
                level: widget.level.number,
                tier: _puzzle.difficultyTier,
                candidates: _puzzle.proofCandidateMoves,
                english: _english,
              ),
              const SizedBox(height: 8),
              _ShogiInstruction(
                english: _english,
                handCount: handCount,
                selectedDrop: _selectedDrop,
              ),
              const SizedBox(height: 9),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double boardSize = math.min(
                    480.0,
                    constraints.maxWidth - 8,
                  );
                  final Size canvasSize = Size(boardSize, boardSize);
                  return Center(
                    child: Container(
                      key: const ValueKey<String>('shogi_mate_board_frame'),
                      width: boardSize + 14,
                      height: boardSize + 14,
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8CBB4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFC8B99F)),
                        boxShadow: StudioVisuals.softShadow,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: GestureDetector(
                          key: const ValueKey<String>('shogi_mate_board'),
                          behavior: HitTestBehavior.opaque,
                          onTapUp: (TapUpDetails details) =>
                              _onBoardTap(details, canvasSize),
                          child: Semantics(
                            label: _english
                                ? 'Nine by nine Shogi board. Tap a hand piece to drop or a board piece to select a legal move.'
                                : 'Dokuz çarpı dokuz Shogi tahtası. Elden taş düşürmek için ele, hamle seçmek için taştan birine dokun.',
                            child: CustomPaint(
                              painter: _ShogiBoardPainter(
                                position: _position,
                                rotated: _rotated,
                                selectedFrom: _selectedFrom,
                                legalTargets: legalTargets,
                                hintedDestination: _hintedDestination,
                                wrongDestination: _wrongDestination,
                              ),
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 9),
              _ShogiHand(
                count: handCount,
                selected: _selectedDrop,
                onTap: () => _selectDrop(ShogiPieceType.gold),
                english: _english,
              ),
              const SizedBox(height: 8),
              _ShogiActions(
                canUndo:
                    _selectedFrom != null ||
                    _selectedDrop != null ||
                    _wrongDestination != null,
                busy: _finished,
                english: _english,
                onUndo: _undo,
                onHint: _showHint,
                onReset: _confirmReset,
              ),
              if (_notice != null) ...<Widget>[
                const SizedBox(height: 8),
                _ShogiNotice(
                  text: _notice!,
                  warning: _wrongDestination != null,
                ),
              ],
              const SizedBox(height: 7),
              Text(
                _english
                    ? 'A captured piece changes sides and returns to its base type in hand. Promotion and drop restrictions are enforced by the move engine.'
                    : 'Yakalanan taş taraf değiştirerek terfisiz hâlde ele döner. Terfi ve düşürme kısıtlarını hamle motoru uygular.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF6B7472),
                  fontSize: 10,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShogiBoardPainter extends CustomPainter {
  const _ShogiBoardPainter({
    required this.position,
    required this.rotated,
    required this.selectedFrom,
    required this.legalTargets,
    required this.hintedDestination,
    required this.wrongDestination,
  });

  final ShogiPosition position;
  final bool rotated;
  final int? selectedFrom;
  final Set<int> legalTargets;
  final int? hintedDestination;
  final int? wrongDestination;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = _ShogiMatePlayPageState._board,
    );
    final double spacing = size.width / 10;
    final Offset first = Offset(spacing, spacing);
    final Offset last = Offset(size.width - spacing, size.height - spacing);
    final Paint grid = Paint()
      ..color = _ShogiMatePlayPageState._grid
      ..strokeWidth = 1.15
      ..style = PaintingStyle.stroke;
    for (int index = 0; index < 9; index++) {
      final double coordinate = (index + 1) * spacing;
      canvas.drawLine(
        Offset(coordinate, first.dy),
        Offset(coordinate, last.dy),
        grid,
      );
      canvas.drawLine(
        Offset(first.dx, coordinate),
        Offset(last.dx, coordinate),
        grid,
      );
    }
    final Paint star = Paint()..color = _ShogiMatePlayPageState._grid;
    for (final int row in <int>[2, 4, 6]) {
      for (final int column in <int>[2, 4, 6]) {
        final (int screenRow, int screenColumn) = rotated
            ? (8 - row, 8 - column)
            : (row, column);
        canvas.drawCircle(
          Offset((screenColumn + 1) * spacing, (screenRow + 1) * spacing),
          1.8,
          star,
        );
      }
    }
    for (int square = 0; square < 81; square++) {
      final int row = ShogiSquare.row(square);
      final int column = ShogiSquare.column(square);
      final int screenRow = rotated ? 8 - row : row;
      final int screenColumn = rotated ? 8 - column : column;
      final Offset center = Offset(
        (screenColumn + 1) * spacing,
        (screenRow + 1) * spacing,
      );
      final double radius = spacing * .42;
      if (square == selectedFrom) {
        canvas.drawCircle(
          center,
          radius + 3,
          Paint()..color = _ShogiMatePlayPageState._gold.withValues(alpha: .28),
        );
      }
      if (legalTargets.contains(square)) {
        canvas.drawCircle(
          center,
          radius * .22,
          Paint()
            ..color = _ShogiMatePlayPageState._accent.withValues(alpha: .88),
        );
      }
      if (square == hintedDestination) {
        canvas.drawCircle(
          center,
          radius + 3,
          Paint()..color = _ShogiMatePlayPageState._gold.withValues(alpha: .65),
        );
      }
      if (square == wrongDestination) {
        canvas.drawCircle(
          center,
          radius + 3,
          Paint()
            ..color = _ShogiMatePlayPageState._error.withValues(alpha: .55),
        );
      }
      final ShogiPiece? piece = position.at(square);
      if (piece != null) _drawPiece(canvas, center, radius, piece);
    }
  }

  void _drawPiece(
    Canvas canvas,
    Offset center,
    double radius,
    ShogiPiece piece,
  ) {
    final double width = radius * 1.55;
    final double height = radius * 1.72;
    final Path shape = Path()
      ..moveTo(center.dx, center.dy - height * .58)
      ..lineTo(center.dx + width * .5, center.dy - height * .26)
      ..lineTo(center.dx + width * .42, center.dy + height * .50)
      ..lineTo(center.dx - width * .42, center.dy + height * .50)
      ..lineTo(center.dx - width * .5, center.dy - height * .26)
      ..close();
    final bool black = piece.side == ShogiSide.black;
    canvas.drawShadow(shape, Colors.black.withValues(alpha: .25), 2, true);
    canvas.drawPath(
      shape,
      Paint()
        ..color = black ? const Color(0xFF314044) : const Color(0xFFFFFCF4),
    );
    canvas.drawPath(
      shape,
      Paint()
        ..color = piece.promoted
            ? const Color(0xFFBD7663)
            : const Color(0xFFAB9B82)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.05,
    );
    final TextPainter glyph = TextPainter(
      text: TextSpan(
        text: _glyph(piece.type),
        style: TextStyle(
          color: black ? Colors.white : const Color(0xFF384346),
          fontSize: radius * .79,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    glyph.paint(
      canvas,
      Offset(center.dx - glyph.width / 2, center.dy - glyph.height / 2 + 1),
    );
    if (piece.promoted) {
      canvas.drawCircle(
        center.translate(radius * .45, -radius * .42),
        radius * .11,
        Paint()..color = const Color(0xFFBD7663),
      );
    }
  }

  String _glyph(ShogiPieceType type) => switch (type) {
    ShogiPieceType.king => 'K',
    ShogiPieceType.rook => 'R',
    ShogiPieceType.bishop => 'B',
    ShogiPieceType.gold => 'G',
    ShogiPieceType.silver => 'S',
    ShogiPieceType.knight => 'N',
    ShogiPieceType.lance => 'L',
    ShogiPieceType.pawn => 'P',
  };

  @override
  bool shouldRepaint(covariant _ShogiBoardPainter oldDelegate) =>
      oldDelegate.position.signature != position.signature ||
      oldDelegate.rotated != rotated ||
      oldDelegate.selectedFrom != selectedFrom ||
      oldDelegate.legalTargets != legalTargets ||
      oldDelegate.hintedDestination != hintedDestination ||
      oldDelegate.wrongDestination != wrongDestination;
}

class _ShogiStatus extends StatelessWidget {
  const _ShogiStatus({
    required this.level,
    required this.tier,
    required this.candidates,
    required this.english,
  });
  final int level;
  final String tier;
  final int candidates;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0xFFE7E3DC)),
    ),
    child: Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${english ? 'TSUME' : 'TSUME'} ${level.toString().padLeft(2, '0')} · $tier',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF76817F),
                  fontSize: 9,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                english
                    ? '$candidates legal candidate moves'
                    : '$candidates yasal aday hamle',
                style: const TextStyle(
                  color: _ShogiMatePlayPageState._ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F4F1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            english ? '9 × 9' : '9 × 9',
            style: const TextStyle(
              color: _ShogiMatePlayPageState._accent,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ShogiInstruction extends StatelessWidget {
  const _ShogiInstruction({
    required this.english,
    required this.handCount,
    required this.selectedDrop,
  });
  final bool english;
  final int handCount;
  final ShogiPieceType? selectedDrop;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFFF7F5F0),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE8E3D9)),
    ),
    child: Row(
      children: <Widget>[
        const Icon(
          Icons.touch_app_rounded,
          color: _ShogiMatePlayPageState._accent,
          size: 17,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            english
                ? 'One move · drop the hand piece to mate'
                : 'Tek hamle · mat için eldeki taşı düşür',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ShogiMatePlayPageState._ink,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          selectedDrop == null
              ? '${english ? 'HAND' : 'EL'} $handCount'
              : (english ? 'SELECTED' : 'SEÇİLİ'),
          style: const TextStyle(
            color: _ShogiMatePlayPageState._accent,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _ShogiHand extends StatelessWidget {
  const _ShogiHand({
    required this.count,
    required this.selected,
    required this.onTap,
    required this.english,
  });
  final int count;
  final ShogiPieceType? selected;
  final VoidCallback onTap;
  final bool english;

  @override
  Widget build(BuildContext context) => InkWell(
    key: const ValueKey<String>('shogi_gold_hand'),
    onTap: count > 0 ? onTap : null,
    borderRadius: BorderRadius.circular(15),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: selected == ShogiPieceType.gold
              ? _ShogiMatePlayPageState._gold
              : const Color(0xFFE7E3DC),
          width: selected == ShogiPieceType.gold ? 2 : 1,
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF2E9D9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE4D6BC)),
            ),
            child: const Text(
              'G',
              style: TextStyle(
                color: Color(0xFF805F32),
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              english
                  ? 'GOLD IN HAND · tap to select'
                  : 'ELDEKİ ALTIN · seçmek için dokun',
              style: const TextStyle(
                color: _ShogiMatePlayPageState._ink,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Container(
            width: 27,
            height: 27,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F4F1),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: _ShogiMatePlayPageState._accent,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ShogiActions extends StatelessWidget {
  const _ShogiActions({
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
        child: OutlinedButton.icon(
          onPressed: canUndo && !busy ? onUndo : null,
          icon: const Icon(Icons.undo_rounded, size: 17),
          label: Text(english ? 'UNDO' : 'GERİ AL'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: _ShogiMatePlayPageState._ink,
            side: const BorderSide(color: Color(0xFFDCD9D2)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
        ),
      ),
      const SizedBox(width: 7),
      Expanded(
        child: FilledButton.icon(
          onPressed: busy ? null : onHint,
          icon: const Icon(Icons.lightbulb_outline_rounded, size: 17),
          label: Text(english ? 'HINT' : 'İPUCU'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            backgroundColor: _ShogiMatePlayPageState._accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
        ),
      ),
      const SizedBox(width: 7),
      IconButton.outlined(
        tooltip: english ? 'Reset' : 'Sıfırla',
        onPressed: busy ? null : onReset,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: _ShogiMatePlayPageState._ink,
          side: const BorderSide(color: Color(0xFFDCD9D2)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
    ],
  );
}

class _ShogiNotice extends StatelessWidget {
  const _ShogiNotice({required this.text, required this.warning});
  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
    decoration: BoxDecoration(
      color: warning ? const Color(0xFFFBF0EC) : const Color(0xFFF0F4F1),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(
        color: warning ? const Color(0xFFE9D0C9) : const Color(0xFFD9E6DE),
      ),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: warning ? const Color(0xFF925B50) : const Color(0xFF54766B),
        fontSize: 10,
        height: 1.35,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _ShogiLevelPill extends StatelessWidget {
  const _ShogiLevelPill({required this.level});
  final int level;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F4F1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      '${level.toString().padLeft(2, '0')} / 20',
      style: const TextStyle(
        color: _ShogiMatePlayPageState._accent,
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}
