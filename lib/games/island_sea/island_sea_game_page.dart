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
import 'island_sea_puzzle.dart';

class IslandSeaGamePage extends StatelessWidget {
  const IslandSeaGamePage({
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
    GameContentPolicy.nativeStages('island_sea'),
    (int index) {
      final int level = index + 1;
      final int stage = index % 10 + 1;
      final int chapter = index ~/ 10 + 1;
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Ada ve Deniz ${level.toString().padLeft(2, '0')}',
        titleEn: 'Island & Sea ${level.toString().padLeft(2, '0')}',
        subtitleTr: _subtitle(stage, chapter, english: false),
        subtitleEn: _subtitle(stage, chapter, english: true),
        difficulty: switch (stage) {
          <= 6 => chapter == 1 ? 'USTALAŞMA' : 'DERİNLEŞME',
          7 || 8 => 'İLERİ',
          9 => 'UZMAN',
          _ => 'USTA',
        },
        icon: Icons.waves_rounded,
      );
    },
    growable: false,
  );

  static String _subtitle(int stage, int chapter, {required bool english}) {
    if (chapter == 2 && stage <= 6) {
      return english
          ? 'Read a denser archipelago while preserving one connected sea.'
          : 'Tek ve bağlı denizi koruyarak daha yoğun takımadayı çöz.';
    }
    return switch (stage) {
      <= 3 =>
        english
            ? 'Grow each numbered island; keep the sea connected.'
            : 'Numaralı adaları tamamla; denizi bağlı tut.',
      <= 6 =>
        english
            ? 'Separate islands diagonally and track every coastline.'
            : 'Adaları çapraz temastan ayır; kıyı çizgilerini izle.',
      7 || 8 =>
        english
            ? 'Advanced: remove every forbidden 2×2 sea block.'
            : 'İleri: yasak 2×2 deniz bloklarını ele.',
      9 =>
        english
            ? 'Expert: prove the only map consistent with all island sizes.'
            : 'Uzman: ada ölçülerine uyan tek haritayı kanıtla.',
      _ =>
        english
            ? 'Master map: connect the sea through a dense archipelago.'
            : 'Usta haritası: yoğun takımadada denizi tek parça bağla.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forId('island_sea');
    return ParkurLevelHub(
      gameId: 'island_sea',
      progressPrefix: 'island_sea',
      titleTr: 'Ada ve Deniz',
      titleEn: 'Island & Sea',
      taglineTr: 'Adaları ölç • Denizi bağla • Haritayı çöz',
      taglineEn: 'Size the islands • Connect the sea • Solve the map',
      accent: skin.accent,
      icon: Icons.waves_rounded,
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
          ) => IslandSeaPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

enum _IslandSeaTool { island, sea }

class IslandSeaPlayPage extends StatefulWidget {
  const IslandSeaPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<IslandSeaPlayPage> createState() => _IslandSeaPlayPageState();
}

class _IslandSeaPlayPageState extends State<IslandSeaPlayPage> {
  static const Color _accent = Color(0xFF3D7183);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.logic,
  );
  final List<List<int>> _undoStack = <List<int>>[];

  late IslandSeaPuzzle _puzzle;
  late List<int> _board;
  late StudioGameSession _session;
  _IslandSeaTool _tool = _IslandSeaTool.island;
  int _hints = 0;
  int _mistakes = 0;
  bool _ready = false;
  bool _finished = false;
  bool _english = false;
  String? _notice;

  int get _score => math.max(0, 5000 - _hints * 340 - _mistakes * 170);
  int get _stars => _hints == 0 && _mistakes == 0
      ? 3
      : _hints <= 2
      ? 2
      : 1;
  int get _unknownCount =>
      _board.where((int cell) => cell == IslandSeaPuzzle.unknown).length;

  @override
  void initState() {
    super.initState();
    unawaited(_audioProfile.preload(_audio));
    unawaited(_preparePuzzle());
  }

  Future<void> _preparePuzzle() async {
    IslandSeaPuzzle puzzle = (widget.level.poolIndex != null
        ? IslandSeaPuzzle.forPracticeBoard(widget.level.contentIndex)
        : IslandSeaPuzzle.forLevel(widget.level.contentLevel));
    try {
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      final String visitKey = 'island_sea_level_${widget.level.number}_visits';
      final int visits = await preferences.getInt(visitKey) ?? 0;
      if (widget.level.poolIndex == null && visits > 0) {
        final int index =
            await preferences.getInt('island_sea_practice_index') ?? 0;
        if (index < IslandSeaPuzzle.maximumVerifiedBoards) {
          final int next = index + 1;
          await preferences.setInt('island_sea_practice_index', next);
          puzzle = IslandSeaPuzzle.forPracticeBoard(next);
        }
      }
      await preferences.setInt(visitKey, visits + 1);
    } catch (_) {
      puzzle = (widget.level.poolIndex != null
          ? IslandSeaPuzzle.forPracticeBoard(widget.level.contentIndex)
          : IslandSeaPuzzle.forLevel(widget.level.contentLevel));
    }
    if (!mounted) return;
    setState(() {
      _puzzle = puzzle;
      _board = <int>[
        for (int cell = 0; cell < puzzle.cellCount; cell++)
          puzzle.clues[cell] > 0
              ? IslandSeaPuzzle.island
              : IslandSeaPuzzle.unknown,
      ];
      _session = StudioGameSession(
        level: widget.level.number,
        seed: puzzle.seed,
      )..start();
      _undoStack.clear();
      _tool = _IslandSeaTool.island;
      _hints = 0;
      _mistakes = 0;
      _notice = null;
      _finished = false;
      _ready = true;
    });
  }

  void _rememberBoard() {
    _undoStack.add(List<int>.of(_board));
    if (_undoStack.length > 80) _undoStack.removeAt(0);
  }

  void _markCell(int index) {
    if (!_ready || _finished || _puzzle.clues[index] > 0) return;
    final int next = _tool == _IslandSeaTool.island
        ? IslandSeaPuzzle.island
        : IslandSeaPuzzle.sea;
    if (_board[index] == next) return;
    _rememberBoard();
    setState(() {
      _board[index] = next;
      _notice = null;
    });
    _audio.hapticSelection();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .14));
  }

  void _undo() {
    if (_undoStack.isEmpty || _finished) return;
    setState(() {
      _board = _undoStack.removeLast();
      _notice = _english
          ? 'Last cell mark undone.'
          : 'Son hücre işareti geri alındı.';
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .2));
  }

  void _clearCell(int index) {
    if (!_ready ||
        _finished ||
        _puzzle.clues[index] > 0 ||
        _board[index] == IslandSeaPuzzle.unknown) {
      return;
    }
    _rememberBoard();
    setState(() {
      _board[index] = IslandSeaPuzzle.unknown;
      _notice = null;
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .18));
  }

  void _showHint() {
    if (!_ready || _finished || !_session.canUseHint) return;
    final List<int>? answer = _puzzle.hintCell(_board);
    if (answer == null) return;
    _rememberBoard();
    _session.useHint(pointCost: 340);
    _hints++;
    setState(() {
      _board[answer[0]] = answer[1];
      _notice = _english
          ? 'Certified hint: cell ${answer[0] + 1} belongs to the ${answer[1] == IslandSeaPuzzle.island ? 'island' : 'sea'}.'
          : 'Doğrulanmış ipucu: ${answer[0] + 1}. hücre ${answer[1] == IslandSeaPuzzle.island ? 'adaya' : 'denize'} aittir.';
    });
    _audio.hapticSelection();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .23));
  }

  void _checkBoard() {
    if (!_ready || _finished) return;
    if (_unknownCount > 0) {
      setState(() {
        _notice = _english
            ? 'Classify every open cell before checking the map.'
            : 'Haritayı kontrol etmeden önce tüm boş hücreleri sınıflandır.';
      });
      _audio.hapticLight();
      return;
    }
    if (_puzzle.isCorrect(_board)) {
      _session.recordAccepted(points: 60);
      unawaited(_finish());
      return;
    }
    _mistakes++;
    setState(() {
      _notice = _english
          ? 'Not solved yet. Check island sizes, diagonal separation and the connected sea.'
          : 'Henüz çözülmedi. Ada ölçülerini, çapraz ayrımı ve bağlı denizi tekrar kontrol et.';
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .22));
  }

  Future<void> _confirmReset() async {
    if (!_ready || _finished) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(_english ? 'Reset this map?' : 'Bu harita sıfırlansın mı?'),
        content: Text(
          _english
              ? 'The same numbered islands and same solution will be restored.'
              : 'Aynı numaralı adalar ve aynı çözüm yeniden kurulacak.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(_english ? 'Keep solving' : 'Çözmeye devam et'),
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
      _board = <int>[
        for (int cell = 0; cell < _puzzle.cellCount; cell++)
          _puzzle.clues[cell] > 0
              ? IslandSeaPuzzle.island
              : IslandSeaPuzzle.unknown,
      ];
      _undoStack.clear();
      _notice = null;
      _mistakes = 0;
    });
  }

  Future<void> _finish() async {
    if (_finished || !mounted) return;
    _finished = true;
    final int score = _score;
    final int stars = _stars;
    _session.complete(
      stars: stars,
      action: widget.level.number < IslandSeaGamePage.totalCases
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
      titleTr: 'DENİZ AÇILDI',
      titleEn: 'SEA CONNECTED',
      detailTr:
          '${_puzzle.islandCount} ada · ${_puzzle.size}×${_puzzle.size} harita.',
      detailEn:
          '${_puzzle.islandCount} islands · ${_puzzle.size}×${_puzzle.size} map.',
      stars: stars,
      score: score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < IslandSeaGamePage.totalCases,
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
          title: Text(_english ? 'ISLAND & SEA' : 'ADA VE DENİZ'),
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
        titleSpacing: 14,
        title: Text(
          _english ? 'ISLAND & SEA' : 'ADA VE DENİZ',
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Center(child: _IslandLevelPill(level: widget.level.number)),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 3, 12, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _IslandStatus(
                level: widget.level.number,
                tier: _puzzle.difficultyTier,
                islands: _puzzle.islandCount,
                seaCells: _puzzle.seaCount,
                english: _english,
              ),
              const SizedBox(height: 9),
              _IslandInstruction(english: _english, tool: _tool),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double boardSize = math.min(520, constraints.maxWidth);
                  return Center(
                    child: Container(
                      key: const ValueKey<String>('island_sea_board_frame'),
                      width: boardSize + 12,
                      height: boardSize + 12,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7E2D9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFD9D3C8)),
                        boxShadow: StudioVisuals.softShadow,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: GestureDetector(
                          key: const ValueKey<String>('island_sea_board'),
                          behavior: HitTestBehavior.opaque,
                          onTapUp: (TapUpDetails details) {
                            final int column =
                                (details.localPosition.dx /
                                        (boardSize / _puzzle.size))
                                    .floor();
                            final int row =
                                (details.localPosition.dy /
                                        (boardSize / _puzzle.size))
                                    .floor();
                            if (row >= 0 &&
                                row < _puzzle.size &&
                                column >= 0 &&
                                column < _puzzle.size) {
                              _markCell(row * _puzzle.size + column);
                            }
                          },
                          onLongPressStart: (LongPressStartDetails details) {
                            final int column =
                                (details.localPosition.dx /
                                        (boardSize / _puzzle.size))
                                    .floor();
                            final int row =
                                (details.localPosition.dy /
                                        (boardSize / _puzzle.size))
                                    .floor();
                            if (row >= 0 &&
                                row < _puzzle.size &&
                                column >= 0 &&
                                column < _puzzle.size) {
                              _clearCell(row * _puzzle.size + column);
                            }
                          },
                          child: Semantics(
                            label: _english
                                ? '${_puzzle.size} by ${_puzzle.size} Nurikabe board. Tap cells to mark island or sea. Long press to clear.'
                                : '${_puzzle.size} çarpı ${_puzzle.size} Ada ve Deniz tahtası. Ada veya deniz işaretlemek için dokun. Temizlemek için uzun bas.',
                            child: CustomPaint(
                              key: const ValueKey<String>('island_sea_canvas'),
                              painter: _IslandSeaPainter(
                                size: _puzzle.size,
                                clues: _puzzle.clues,
                                board: _board,
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
              const SizedBox(height: 10),
              _IslandToolSelector(
                selected: _tool,
                english: _english,
                onChanged: (_IslandSeaTool tool) => setState(() {
                  _tool = tool;
                }),
              ),
              const SizedBox(height: 8),
              _IslandActions(
                canUndo: _undoStack.isNotEmpty,
                busy: _finished,
                english: _english,
                onUndo: _undo,
                onHint: _showHint,
                onReset: _confirmReset,
                onCheck: _checkBoard,
              ),
              if (_notice != null) ...<Widget>[
                const SizedBox(height: 8),
                _IslandNotice(
                  text: _notice!,
                  warning: _mistakes > 0 && _unknownCount == 0,
                ),
              ],
              const SizedBox(height: 8),
              Text(
                _english
                    ? 'Each island is orthogonally connected and separate, even diagonally. The sea is one orthogonal region and contains no 2×2 water square.'
                    : 'Her ada yatay/dikey bağlıdır ve çapraz dâhil ayrı kalır. Deniz tek ortogonal bölgedir; 2×2 su karesi içermez.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: Color(0xFF6B7472),
                  fontSize: 12,
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

class _IslandSeaPainter extends CustomPainter {
  const _IslandSeaPainter({
    required this.size,
    required this.clues,
    required this.board,
  });

  final int size;
  final List<int> clues;
  final List<int> board;

  static const Color _ink = StudioVisuals.ink;
  static const Color _grid = Color(0xFFD6D9D3);
  static const Color _sea = Color(0xFFC6DAD6);
  static const Color _island = Color(0xFFF1E7D5);
  static const Color _unknown = Color(0xFFFFFEFC);

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final double cell = canvasSize.width / size;
    for (int index = 0; index < size * size; index++) {
      final int row = index ~/ size;
      final int column = index % size;
      final Rect rect = Rect.fromLTWH(column * cell, row * cell, cell, cell);
      final int clue = clues[index];
      final int mark = board[index];
      final Color color = clue > 0 || mark == IslandSeaPuzzle.island
          ? _island
          : mark == IslandSeaPuzzle.sea
          ? _sea
          : _unknown;
      canvas.drawRect(rect, Paint()..color = color);
      if (mark == IslandSeaPuzzle.sea && clue == 0) {
        _drawWave(canvas, rect, cell);
      } else if (mark == IslandSeaPuzzle.island && clue == 0) {
        _drawLandDetail(canvas, rect, cell);
      }
      if (clue > 0) {
        final TextPainter text = TextPainter(
          text: TextSpan(
            text: '$clue',
            style: TextStyle(
              fontFamily: 'Roboto',
              color: _ink,
              fontSize: cell * .43,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: cell);
        text.paint(
          canvas,
          Offset(
            rect.center.dx - text.width / 2,
            rect.center.dy - text.height / 2,
          ),
        );
      }
      canvas.drawRect(
        rect,
        Paint()
          ..color = _grid
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
    canvas.drawRect(
      Offset.zero & canvasSize,
      Paint()
        ..color = const Color(0xFF9EA9A4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }

  void _drawWave(Canvas canvas, Rect rect, double cell) {
    final Paint wave = Paint()
      ..color = const Color(0xFF8EAAA5).withValues(alpha: .75)
      ..strokeWidth = math.max(1, cell * .025)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final double left = rect.left + cell * .24;
    final double right = rect.right - cell * .24;
    for (int row = 0; row < 2; row++) {
      final double y = rect.top + cell * (.39 + row * .22);
      final Path path = Path()..moveTo(left, y);
      final double mid = (left + right) / 2;
      path.quadraticBezierTo(mid - cell * .12, y - cell * .08, mid, y);
      path.quadraticBezierTo(mid + cell * .12, y + cell * .08, right, y);
      canvas.drawPath(path, wave);
    }
  }

  void _drawLandDetail(Canvas canvas, Rect rect, double cell) {
    final Paint detail = Paint()
      ..color = const Color(0xFFB8A989).withValues(alpha: .42)
      ..strokeWidth = math.max(1, cell * .025)
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(
      Offset(rect.left + cell * .28, rect.top + cell * .3),
      cell * .035,
      detail,
    );
    canvas.drawCircle(
      Offset(rect.left + cell * .7, rect.top + cell * .72),
      cell * .035,
      detail,
    );
  }

  @override
  bool shouldRepaint(_IslandSeaPainter oldDelegate) =>
      oldDelegate.size != size ||
      !_same(oldDelegate.clues, clues) ||
      !_same(oldDelegate.board, board);

  bool _same(List<int> left, List<int> right) {
    if (left.length != right.length) return false;
    for (int index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }
}

class _IslandStatus extends StatelessWidget {
  const _IslandStatus({
    required this.level,
    required this.tier,
    required this.islands,
    required this.seaCells,
    required this.english,
  });

  final int level;
  final String tier;
  final int islands;
  final int seaCells;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xFFE8E5DF)),
    ),
    child: Row(
      children: <Widget>[
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F0ED),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.waves_rounded, color: Color(0xFF557C78)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                english ? 'MAP $level · $tier' : 'HARİTA $level · $tier',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: Color(0xFF29373A),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .55,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                english
                    ? '$islands numbered islands · $seaCells sea cells'
                    : '$islands numaralı ada · $seaCells deniz hücresi',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: Color(0xFF76817C),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _IslandInstruction extends StatelessWidget {
  const _IslandInstruction({required this.english, required this.tool});

  final bool english;
  final _IslandSeaTool tool;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFF7F7F3),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE9EAE4)),
    ),
    child: Row(
      children: <Widget>[
        Icon(
          tool == _IslandSeaTool.island
              ? Icons.terrain_rounded
              : Icons.waves_rounded,
          color: const Color(0xFF557C78),
          size: 19,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            english
                ? 'Tap a cell to mark ${tool == _IslandSeaTool.island ? 'ISLAND' : 'SEA'}. Long press clears it.'
                : 'Dokunarak ${tool == _IslandSeaTool.island ? 'ADA' : 'DENİZ'} işaretle. Uzun basış temizler.',
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: Color(0xFF455651),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
        ),
      ],
    ),
  );
}

class _IslandToolSelector extends StatelessWidget {
  const _IslandToolSelector({
    required this.selected,
    required this.english,
    required this.onChanged,
  });

  final _IslandSeaTool selected;
  final bool english;
  final ValueChanged<_IslandSeaTool> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: _ToolButton(
          selected: selected == _IslandSeaTool.island,
          key: const ValueKey<String>('island_sea_tool_island'),
          icon: Icons.terrain_rounded,
          label: english ? 'ISLAND' : 'ADA',
          background: const Color(0xFFF1E7D5),
          onTap: () => onChanged(_IslandSeaTool.island),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _ToolButton(
          selected: selected == _IslandSeaTool.sea,
          key: const ValueKey<String>('island_sea_tool_sea'),
          icon: Icons.waves_rounded,
          label: english ? 'SEA' : 'DENİZ',
          background: const Color(0xFFC6DAD6),
          onTap: () => onChanged(_IslandSeaTool.sea),
        ),
      ),
    ],
  );
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    super.key,
    required this.selected,
    required this.icon,
    required this.label,
    required this.background,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? background : Colors.white,
    borderRadius: BorderRadius.circular(13),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected ? const Color(0xFF557C78) : const Color(0xFFE6E7E2),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 18, color: const Color(0xFF3C5753)),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: Color(0xFF344449),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: .45,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _IslandActions extends StatelessWidget {
  const _IslandActions({
    required this.canUndo,
    required this.busy,
    required this.english,
    required this.onUndo,
    required this.onHint,
    required this.onReset,
    required this.onCheck,
  });

  final bool canUndo;
  final bool busy;
  final bool english;
  final VoidCallback onUndo;
  final VoidCallback onHint;
  final VoidCallback onReset;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Row(
        children: <Widget>[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: canUndo && !busy ? onUndo : null,
              icon: const Icon(Icons.undo_rounded, size: 17),
              label: Text(english ? 'Undo' : 'Geri al'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                foregroundColor: const Color(0xFF596864),
                side: const BorderSide(color: Color(0xFFDDE2DC)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: busy ? null : onHint,
              icon: const Icon(Icons.lightbulb_outline_rounded, size: 17),
              label: Text(english ? 'Hint' : 'İpucu'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                foregroundColor: const Color(0xFF596864),
                side: const BorderSide(color: Color(0xFFDDE2DC)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: english ? 'Reset map' : 'Haritayı sıfırla',
            onPressed: busy ? null : onReset,
            icon: const Icon(Icons.refresh_rounded),
            style: IconButton.styleFrom(
              minimumSize: const Size(46, 46),
              backgroundColor: const Color(0xFFE9EFEB),
              foregroundColor: const Color(0xFF557C78),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      FilledButton.icon(
        key: const ValueKey<String>('island_sea_check'),
        onPressed: busy ? null : onCheck,
        icon: const Icon(Icons.fact_check_outlined, size: 18),
        label: Text(english ? 'CHECK THE MAP' : 'HARİTAYI KONTROL ET'),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(49),
          backgroundColor: const Color(0xFF557C78),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: .65,
          ),
        ),
      ),
    ],
  );
}

class _IslandNotice extends StatelessWidget {
  const _IslandNotice({required this.text, required this.warning});

  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: warning ? const Color(0xFFFFF3F0) : const Color(0xFFE9F2EF),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: <Widget>[
        Icon(
          warning ? Icons.info_outline_rounded : Icons.check_circle_outline,
          color: warning ? const Color(0xFFB9655E) : const Color(0xFF557C78),
          size: 17,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Roboto',
              color: warning
                  ? const Color(0xFF8F514A)
                  : const Color(0xFF3E6259),
              fontSize: 12,
              height: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _IslandLevelPill extends StatelessWidget {
  const _IslandLevelPill({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xFFE8F0ED),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      '${level.toString().padLeft(2, '0')} / ${GameContentPolicy.campaignLevels}',
      style: const TextStyle(
        fontFamily: 'Roboto',
        color: Color(0xFF496A64),
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: .5,
      ),
    ),
  );
}
