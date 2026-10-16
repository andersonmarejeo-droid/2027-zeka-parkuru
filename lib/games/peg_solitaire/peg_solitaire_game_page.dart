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
import 'peg_solitaire_puzzle.dart';

class PegSolitaireGamePage extends StatelessWidget {
  const PegSolitaireGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  static const int totalCases = PegSolitairePuzzle.maximumLevels;
  static const int totalStars = totalCases * 3;

  static final List<ParkurLevelSpec> _levels = List<ParkurLevelSpec>.generate(
    totalCases,
    (int index) {
      final int level = index + 1;
      final int stage = index % 10 + 1;
      final int chapter = index ~/ 10 + 1;
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Tek Taş ${level.toString().padLeft(2, '0')}',
        titleEn: 'Peg Solitaire ${level.toString().padLeft(2, '0')}',
        subtitleTr: _subtitle(stage, chapter, english: false),
        subtitleEn: _subtitle(stage, chapter, english: true),
        difficulty: switch (stage) {
          <= 6 => chapter == 1 ? 'USTALAŞMA' : 'DERİNLEŞME',
          7 || 8 => 'İLERİ',
          9 => 'UZMAN',
          _ => 'USTA',
        },
        icon: Icons.circle_outlined,
      );
    },
    growable: false,
  );

  static String _subtitle(int stage, int chapter, {required bool english}) {
    if (chapter == 2 && stage <= 6) {
      return english
          ? 'More pegs and a longer elimination chain; preserve the route.'
          : 'Daha fazla piyon ve uzun eleme zinciri; rotayı koru.';
    }
    return switch (stage) {
      <= 3 =>
        english
            ? 'Jump one peg over another into an empty hole.'
            : 'Bir piyonu diğerinin üzerinden boş yuvaya atlat.',
      <= 6 =>
        english
            ? 'Plan the next landing before clearing a corridor.'
            : 'Bir koridoru kapatmadan sonraki inişi planla.',
      7 || 8 =>
        english
            ? 'Advanced: keep the center reachable while branching.'
            : 'İleri: dallanırken merkezi erişilebilir tut.',
      9 =>
        english
            ? 'Expert: sequence a long chain without isolating pegs.'
            : 'Uzman: piyonları izole etmeden uzun zinciri sırala.',
      _ =>
        english
            ? 'Master board: leave exactly one peg on the gold goal.'
            : 'Usta tahtası: altın hedefte tam bir piyon bırak.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(
      StudioGameClass.strategy,
    );
    return ParkurLevelHub(
      gameId: 'peg_solitaire',
      progressPrefix: 'peg_solitaire',
      titleTr: 'Tek Taş',
      titleEn: 'Peg Solitaire',
      taglineTr: 'Atla • Piyonları azalt • Merkezde tek taş bırak',
      taglineEn: 'Jump • Reduce the pegs • Leave one on the center',
      accent: skin.accent,
      icon: Icons.circle_outlined,
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
          ) => PegSolitairePlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class PegSolitairePlayPage extends StatefulWidget {
  const PegSolitairePlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<PegSolitairePlayPage> createState() => _PegSolitairePlayPageState();
}

class _PegSolitairePlayPageState extends State<PegSolitairePlayPage> {
  static const Color _accent = Color(0xFF687C73);
  static const Color _gold = Color(0xFFC39B56);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.strategy,
  );
  final List<PegSolitairePosition> _undoStack = <PegSolitairePosition>[];

  late PegSolitairePuzzle _puzzle;
  late PegSolitairePosition _position;
  late StudioGameSession _session;
  int? _selectedPeg;
  int _hints = 0;
  int _mistakes = 0;
  int _moveCount = 0;
  bool _ready = false;
  bool _finished = false;
  bool _english = false;
  String? _notice;

  int get _score => math.max(
    0,
    5000 -
        math.max(0, _moveCount - _puzzle.solution.length) * 100 -
        _hints * 320 -
        _mistakes * 140,
  );

  int get _stars => _hints == 0 && _moveCount == _puzzle.solution.length
      ? 3
      : _hints <= 1 && _moveCount <= _puzzle.solution.length + 4
      ? 2
      : 1;

  Set<int> get _legalTargets => <int>{
    if (_selectedPeg != null)
      for (final PegMove move in _position.legalMoves())
        if (move.from == _selectedPeg) move.to,
  };

  @override
  void initState() {
    super.initState();
    unawaited(_audioProfile.preload(_audio));
    unawaited(_preparePuzzle());
  }

  Future<void> _preparePuzzle() async {
    PegSolitairePuzzle puzzle = PegSolitairePuzzle.forLevel(
      widget.level.number,
    );
    try {
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      final String visitKey =
          'peg_solitaire_level_${widget.level.number}_visits';
      final int visits = await preferences.getInt(visitKey) ?? 0;
      if (visits > 0) {
        final int index =
            await preferences.getInt('peg_solitaire_practice_index') ?? 0;
        if (index < PegSolitairePuzzle.maximumVerifiedBoards) {
          final int next = index + 1;
          await preferences.setInt('peg_solitaire_practice_index', next);
          puzzle = PegSolitairePuzzle.forPracticeBoard(next);
        }
      }
      await preferences.setInt(visitKey, visits + 1);
    } catch (_) {
      puzzle = PegSolitairePuzzle.forLevel(widget.level.number);
    }
    if (!mounted) return;
    setState(() {
      _puzzle = puzzle;
      _position = puzzle.start;
      _session = StudioGameSession(
        level: widget.level.number,
        seed: puzzle.seed,
      )..start();
      _undoStack.clear();
      _selectedPeg = null;
      _hints = 0;
      _mistakes = 0;
      _moveCount = 0;
      _notice = null;
      _finished = false;
      _ready = true;
    });
  }

  void _handleCell(int cell) {
    if (!_ready || _finished || !_session.acceptsInput) return;
    if (_legalTargets.contains(cell)) {
      _tryMove(cell);
      return;
    }
    if (_position.contains(cell)) {
      setState(() {
        _selectedPeg = cell;
        _notice = _english
            ? 'Choose a highlighted landing hole.'
            : 'Vurgulanan iniş yuvalarından birini seç.';
      });
      _audio.hapticSelection();
      return;
    }
    if (_selectedPeg != null) {
      _mistakes++;
      setState(() {
        _notice = _english
            ? 'A jump must cross exactly one peg into an empty hole.'
            : 'Atlayış tam bir piyonun üzerinden geçip boş yuvaya inmelidir.';
        _selectedPeg = null;
      });
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .18));
    }
  }

  void _tryMove(int destination) {
    final int? from = _selectedPeg;
    if (from == null) return;
    PegMove? move;
    for (final PegMove candidate in _position.legalMoves()) {
      if (candidate.from == from && candidate.to == destination) {
        move = candidate;
        break;
      }
    }
    if (move == null) return;
    final PegSolitairePosition? next = _position.play(move);
    if (next == null) return;
    _undoStack.add(_position);
    setState(() {
      _position = next;
      _moveCount++;
      _selectedPeg = null;
      _notice = _english
          ? '${next.pegCount} pegs remain.'
          : '${next.pegCount} piyon kaldı.';
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .22));
    if (_position.isWon(_puzzle.goal)) {
      _session.recordAccepted(points: 60);
      unawaited(_finish());
    } else if (_position.legalMoves().isEmpty) {
      setState(() {
        _notice = _english
            ? 'No jump remains. Undo a move or reset this board.'
            : 'Atlayış kalmadı. Bir hamleyi geri al veya tahtayı sıfırla.';
      });
    }
  }

  void _undo() {
    if (_undoStack.isEmpty || _finished) return;
    setState(() {
      _position = _undoStack.removeLast();
      _moveCount = math.max(0, _moveCount - 1);
      _selectedPeg = null;
      _notice = _english ? 'Last jump undone.' : 'Son atlayış geri alındı.';
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .2));
  }

  void _showHint() {
    if (!_ready || _finished || !_session.canUseHint) return;
    final PegMove? hint = _puzzle.hintFor(_position);
    if (hint == null) {
      setState(() {
        _notice = _english
            ? 'This position is outside the certified route. Undo to an earlier step or restart.'
            : 'Bu konum sertifikalı rotanın dışında. Önceki adıma dön veya yeniden başlat.';
      });
      return;
    }
    _session.useHint(pointCost: 320);
    _hints++;
    setState(() {
      _selectedPeg = hint.from;
      _notice = _english
          ? 'Certified hint: jump the highlighted peg to the gold target.'
          : 'Doğrulanmış ipucu: vurgulanan piyonu altın hedefe atlat.';
    });
    _audio.hapticSelection();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .24));
  }

  Future<void> _confirmReset() async {
    if (!_ready || _finished) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(
          _english ? 'Restart this board?' : 'Bu tahta baştan başlasın mı?',
        ),
        content: Text(
          _english
              ? 'The same peg layout and certified route will be restored.'
              : 'Aynı piyon düzeni ve sertifikalı çözüm rotası geri yüklenecek.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(_english ? 'Keep playing' : 'Oynamaya devam et'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(_english ? 'Restart' : 'Baştan başla'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _position = _puzzle.start;
      _undoStack.clear();
      _selectedPeg = null;
      _moveCount = 0;
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
      action: widget.level.number < PegSolitaireGamePage.totalCases
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
      titleTr: 'TEK TAŞ KALDI',
      titleEn: 'ONE PEG REMAINS',
      detailTr:
          '$_moveCount atlayış · ${_puzzle.targetPegCount} başlangıç piyonu.',
      detailEn: '$_moveCount jumps · ${_puzzle.targetPegCount} starting pegs.',
      stars: stars,
      score: score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < PegSolitaireGamePage.totalCases,
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
          title: Text(_english ? 'PEG SOLITAIRE' : 'TEK TAŞ'),
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
          _english ? 'PEG SOLITAIRE' : 'TEK TAŞ',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Center(child: _PegLevelPill(level: widget.level.number)),
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
              _PegStatus(
                level: widget.level.number,
                tier: _puzzle.difficultyTier,
                pegs: _position.pegCount,
                target: _puzzle.targetPegCount,
                moveCount: _moveCount,
                english: _english,
              ),
              const SizedBox(height: 9),
              _PegInstruction(
                english: _english,
                selected: _selectedPeg != null,
              ),
              const SizedBox(height: 11),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double boardSize = math.min(520, constraints.maxWidth);
                  return Center(
                    child: Container(
                      key: const ValueKey<String>('peg_solitaire_board_frame'),
                      width: boardSize + 12,
                      height: boardSize + 12,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8E3DA),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFD9D3C8)),
                        boxShadow: StudioVisuals.softShadow,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: GestureDetector(
                          key: const ValueKey<String>('peg_solitaire_board'),
                          behavior: HitTestBehavior.opaque,
                          onTapUp: (TapUpDetails details) {
                            final double cell = boardSize / 7;
                            final int row = (details.localPosition.dy / cell)
                                .floor();
                            final int column = (details.localPosition.dx / cell)
                                .floor();
                            if (row >= 0 &&
                                row < 7 &&
                                column >= 0 &&
                                column < 7) {
                              _handleCell(PegSquare.index(row, column));
                            }
                          },
                          child: Semantics(
                            label: _english
                                ? 'English Peg Solitaire board, 33 holes. Select a peg and tap a highlighted landing hole.'
                                : 'İngiliz Tek Taş tahtası, 33 yuva. Bir piyon seç ve vurgulanan iniş yuvasına dokun.',
                            child: CustomPaint(
                              key: const ValueKey<String>(
                                'peg_solitaire_canvas',
                              ),
                              painter: _PegBoardPainter(
                                position: _position,
                                goal: _puzzle.goal,
                                selectedPeg: _selectedPeg,
                                legalTargets: _legalTargets,
                                goldAccent: _gold,
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
              const SizedBox(height: 11),
              _PegActions(
                canUndo: _undoStack.isNotEmpty,
                busy: _finished,
                english: _english,
                onUndo: _undo,
                onHint: _showHint,
                onReset: _confirmReset,
              ),
              if (_notice != null) ...<Widget>[
                const SizedBox(height: 8),
                _PegNotice(
                  text: _notice!,
                  warning: _mistakes > 0 && !_position.isWon(_puzzle.goal),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                _english
                    ? 'Jump horizontally or vertically over exactly one peg into an empty hole. The jumped peg is removed. Finish with one peg on the gold-marked center.'
                    : 'Yatay veya dikey yönde tam bir piyonun üzerinden boş yuvaya atla; üzerinden atlanan piyon kalkar. Altın merkezde tek piyonla bitir.',
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

class _PegBoardPainter extends CustomPainter {
  const _PegBoardPainter({
    required this.position,
    required this.goal,
    required this.selectedPeg,
    required this.legalTargets,
    required this.goldAccent,
  });

  final PegSolitairePosition position;
  final int goal;
  final int? selectedPeg;
  final Set<int> legalTargets;
  final Color goldAccent;

  @override
  void paint(Canvas canvas, Size size) {
    final double cell = size.width / 7;
    final Paint board = Paint()..color = const Color(0xFFFAF8F4);
    final RRect field = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(12),
    );
    canvas.drawRRect(field, board);
    for (int cellIndex = 0; cellIndex < 49; cellIndex++) {
      if (!PegSolitairePosition.isBoardHole(cellIndex)) continue;
      final int row = PegSquare.row(cellIndex);
      final int column = PegSquare.column(cellIndex);
      final Offset center = Offset((column + .5) * cell, (row + .5) * cell);
      final double radius = cell * .34;
      canvas.drawCircle(
        center.translate(0, cell * .035),
        radius,
        Paint()..color = const Color(0xFFDCD7CE),
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = const Color(0xFFECE8E0),
      );
      if (cellIndex == goal) {
        canvas.drawCircle(
          center,
          radius * .82,
          Paint()
            ..color = goldAccent.withValues(alpha: .8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(1.3, cell * .045),
        );
        canvas.drawCircle(
          center,
          radius * .22,
          Paint()..color = goldAccent.withValues(alpha: .25),
        );
      }
      if (legalTargets.contains(cellIndex)) {
        canvas.drawCircle(
          center,
          radius * .43,
          Paint()..color = const Color(0xFF70988D).withValues(alpha: .82),
        );
        canvas.drawCircle(
          center,
          radius * .43,
          Paint()
            ..color = Colors.white.withValues(alpha: .75)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      }
      if (!position.contains(cellIndex)) continue;
      final Rect pegRect = Rect.fromCircle(
        center: center,
        radius: radius * .78,
      );
      canvas.drawCircle(
        center.translate(0, cell * .035),
        radius * .8,
        Paint()
          ..color = const Color(0xFF304A46).withValues(alpha: .23)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
      canvas.drawCircle(
        center,
        radius * .78,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-.3, -.42),
            radius: .9,
            colors: <Color>[
              Color(0xFF91ADA4),
              Color(0xFF64857A),
              Color(0xFF415D56),
            ],
            stops: <double>[0, .5, 1],
          ).createShader(pegRect),
      );
      if (cellIndex == selectedPeg) {
        canvas.drawCircle(
          center,
          radius * .92,
          Paint()
            ..color = goldAccent
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(2, cell * .07),
        );
      }
      canvas.drawCircle(
        center.translate(-radius * .2, -radius * .23),
        radius * .12,
        Paint()..color = Colors.white.withValues(alpha: .55),
      );
    }
  }

  @override
  bool shouldRepaint(_PegBoardPainter oldDelegate) =>
      oldDelegate.position.signature != position.signature ||
      oldDelegate.goal != goal ||
      oldDelegate.selectedPeg != selectedPeg ||
      oldDelegate.goldAccent != goldAccent ||
      !_sameSet(oldDelegate.legalTargets, legalTargets);

  bool _sameSet(Set<int> left, Set<int> right) =>
      left.length == right.length && left.containsAll(right);
}

class _PegStatus extends StatelessWidget {
  const _PegStatus({
    required this.level,
    required this.tier,
    required this.pegs,
    required this.target,
    required this.moveCount,
    required this.english,
  });

  final int level;
  final String tier;
  final int pegs;
  final int target;
  final int moveCount;
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
            color: const Color(0xFFEEF0E9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.circle_outlined, color: Color(0xFF687C73)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                english ? 'STUDY $level · $tier' : 'ETÜT $level · $tier',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF29373A),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .55,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                english
                    ? '$pegs / $target pegs · $moveCount jumps'
                    : '$pegs / $target piyon · $moveCount atlayış',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF76817C),
                  fontSize: 10,
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

class _PegInstruction extends StatelessWidget {
  const _PegInstruction({required this.english, required this.selected});

  final bool english;
  final bool selected;

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
        const Icon(Icons.touch_app_rounded, color: Color(0xFF687C73), size: 19),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            selected
                ? english
                      ? 'Choose one of the highlighted landing holes.'
                      : 'Vurgulanan iniş yuvalarından birini seç.'
                : english
                ? 'Select a peg, then choose its legal landing hole.'
                : 'Bir piyon seç, ardından yasal iniş yuvasına dokun.',
            style: const TextStyle(
              color: Color(0xFF455651),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
        ),
        const Icon(Icons.adjust_rounded, color: Color(0xFFC39B56), size: 18),
      ],
    ),
  );
}

class _PegActions extends StatelessWidget {
  const _PegActions({
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
        tooltip: english ? 'Restart board' : 'Tahtayı baştan başlat',
        onPressed: busy ? null : onReset,
        icon: const Icon(Icons.refresh_rounded),
        style: IconButton.styleFrom(
          minimumSize: const Size(46, 46),
          backgroundColor: const Color(0xFFE9EFEB),
          foregroundColor: const Color(0xFF687C73),
        ),
      ),
    ],
  );
}

class _PegNotice extends StatelessWidget {
  const _PegNotice({required this.text, required this.warning});

  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: warning ? const Color(0xFFFFF3F0) : const Color(0xFFEEF2EE),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: <Widget>[
        Icon(
          warning ? Icons.info_outline_rounded : Icons.check_circle_outline,
          color: warning ? const Color(0xFFB9655E) : const Color(0xFF687C73),
          size: 17,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: warning
                  ? const Color(0xFF8F514A)
                  : const Color(0xFF4E645B),
              fontSize: 10,
              height: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _PegLevelPill extends StatelessWidget {
  const _PegLevelPill({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xFFEEF0E9),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      '${level.toString().padLeft(2, '0')} / 20',
      style: const TextStyle(
        color: Color(0xFF566B62),
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: .5,
      ),
    ),
  );
}
