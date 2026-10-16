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
import 'loop_puzzle.dart';

class LoopMasterGamePage extends StatelessWidget {
  const LoopMasterGamePage({
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
    GameContentPolicy.nativeStages('loop_master'),
    (int index) {
      final int level = index + 1;
      final int stage = index % 10 + 1;
      final int chapter = index ~/ 10 + 1;
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Döngü Ustası ${level.toString().padLeft(2, '0')}',
        titleEn: 'Loop Master ${level.toString().padLeft(2, '0')}',
        subtitleTr: _subtitle(stage, chapter, english: false),
        subtitleEn: _subtitle(stage, chapter, english: true),
        difficulty: switch (stage) {
          <= 6 => chapter == 1 ? 'USTALAŞMA' : 'DERİNLEŞME',
          7 || 8 => 'İLERİ',
          9 => 'UZMAN',
          _ => 'USTA',
        },
        icon: Icons.loop_rounded,
      );
    },
    growable: false,
  );

  static String _subtitle(int stage, int chapter, {required bool english}) {
    if (chapter == 2 && stage <= 6) {
      return english
          ? 'More clues are hidden; use loop topology and intersections.'
          : 'Daha fazla ipucu gizli; döngü topolojisini ve kesişimleri kullan.';
    }
    return switch (stage) {
      <= 3 =>
        english
            ? 'Read the clue totals and begin a single closed route.'
            : 'Sayı ipuçlarını oku ve tek kapalı rotayı başlat.',
      <= 6 =>
        english
            ? 'Track every touched vertex: it must end with zero or two lines.'
            : 'Çizgi değen her noktayı izle: sıfır ya da iki çizgide kalmalı.',
      7 || 8 =>
        english
            ? 'Advanced: connect distant clue deductions without a branch.'
            : 'İleri düzey: uzak ipuçlarını dal oluşturmadan birleştir.',
      9 =>
        english
            ? 'Expert loop: rule out premature cycles and false branches.'
            : 'Uzman döngü: erken halkaları ve yanlış dalları ele.',
      _ =>
        english
            ? 'Master grid: prove the only loop across a dense clue network.'
            : 'Usta ızgarası: yoğun ipucu ağında tek döngüyü kanıtla.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forId('loop_master');
    return ParkurLevelHub(
      gameId: 'loop_master',
      progressPrefix: 'loop_master',
      titleTr: 'Döngü Ustası',
      titleEn: 'Loop Master',
      taglineTr: 'İpuçlarını çöz • Dalları ele • Tek halkayı kapat',
      taglineEn: 'Read the clues • Reject branches • Close one loop',
      accent: skin.accent,
      icon: Icons.loop_rounded,
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
          ) => LoopMasterPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class LoopMasterPlayPage extends StatefulWidget {
  const LoopMasterPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<LoopMasterPlayPage> createState() => _LoopMasterPlayPageState();
}

class _LoopMasterPlayPageState extends State<LoopMasterPlayPage> {
  static const Color _accent = Color(0xFF665AA2);
  static const Color _paper = Color(0xFFF7F4ED);
  static const Color _line = Color(0xFF334C52);
  static const Color _clue = Color(0xFF283940);
  static const Color _hint = Color(0xFFC5964C);
  static const Color _warning = Color(0xFFB9655E);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.logic,
  );
  final Set<int> _selectedEdges = <int>{};
  final List<({int edge, int previousAnchor})> _undoStack =
      <({int edge, int previousAnchor})>[];

  late LoopPuzzle _puzzle;
  late StudioGameSession _session;
  int? _anchorVertex;
  int? _startVertex;
  int? _hintedEdge;
  int _mistakes = 0;
  int _hints = 0;
  bool _ready = false;
  bool _finished = false;
  bool _english = false;
  String? _notice;

  int get _score => math.max(0, 5000 - _hints * 260 - _mistakes * 150);

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
    LoopPuzzle puzzle = (widget.level.poolIndex != null
        ? LoopPuzzle.forPracticeBoard(widget.level.contentIndex)
        : LoopPuzzle.forLevel(widget.level.contentLevel));
    try {
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      final String visitKey = 'loop_master_level_${widget.level.number}_visits';
      final int visits = await preferences.getInt(visitKey) ?? 0;
      if (widget.level.poolIndex == null && visits > 0) {
        final int played =
            await preferences.getInt('loop_master_practice_index') ?? 0;
        if (played < LoopPuzzle.maximumVerifiedBoards) {
          final int next = played + 1;
          await preferences.setInt('loop_master_practice_index', next);
          puzzle = LoopPuzzle.forPracticeBoard(next);
        }
      }
      await preferences.setInt(visitKey, visits + 1);
    } catch (_) {
      puzzle = (widget.level.poolIndex != null
          ? LoopPuzzle.forPracticeBoard(widget.level.contentIndex)
          : LoopPuzzle.forLevel(widget.level.contentLevel));
    }
    if (!mounted) return;
    setState(() => _loadPuzzle(puzzle));
  }

  void _loadPuzzle(LoopPuzzle puzzle) {
    _puzzle = puzzle;
    _session = StudioGameSession(level: widget.level.number, seed: puzzle.seed)
      ..start();
    _selectedEdges.clear();
    _undoStack.clear();
    _anchorVertex = null;
    _startVertex = null;
    _hintedEdge = null;
    _mistakes = 0;
    _hints = 0;
    _notice = null;
    _finished = false;
    _ready = true;
  }

  int? _pointAt(Offset location, Size boardSize) {
    if (location.dx < -boardSize.width * .025 ||
        location.dy < -boardSize.height * .025 ||
        location.dx > boardSize.width * 1.025 ||
        location.dy > boardSize.height * 1.025) {
      return null;
    }
    final double cellWidth = boardSize.width / _puzzle.size;
    final double cellHeight = boardSize.height / _puzzle.size;
    final int column = (location.dx / cellWidth)
        .round()
        .clamp(0, _puzzle.size)
        .toInt();
    final int row = (location.dy / cellHeight)
        .round()
        .clamp(0, _puzzle.size)
        .toInt();
    final double dx = (location.dx - column * cellWidth).abs();
    final double dy = (location.dy - row * cellHeight).abs();
    if (dx > cellWidth * .42 || dy > cellHeight * .42) return null;
    return _puzzle.vertexId(row, column);
  }

  void _onPointerDown(PointerDownEvent event, Size boardSize) {
    if (!_ready || _finished || !_session.acceptsInput) return;
    final int? vertex = _pointAt(event.localPosition, boardSize);
    if (vertex == null) return;
    final int? anchor = _anchorVertex;
    if (anchor != null && anchor != vertex) {
      final LoopPoint from = _puzzle.point(anchor);
      final LoopPoint to = _puzzle.point(vertex);
      final int distance =
          (from.row - to.row).abs() + (from.column - to.column).abs();
      if (distance > 1) {
        if (_selectedEdges.isEmpty) {
          setState(() {
            _anchorVertex = vertex;
            _startVertex = vertex;
            _notice = _english
                ? 'Start on any dot, then connect neighboring dots.'
                : 'Herhangi bir noktadan başla, sonra komşu noktaları bağla.';
          });
        } else {
          _recordError(
            _english
                ? 'Continue from the highlighted end of your open route.'
                : 'Açık rotanın vurgulu ucundan devam et.',
          );
        }
        return;
      }
    }
    _travelTo(vertex);
  }

  void _onPointerMove(PointerMoveEvent event, Size boardSize) {
    if (!_ready || _finished || !_session.acceptsInput) return;
    final int? vertex = _pointAt(event.localPosition, boardSize);
    if (vertex == null) return;
    _travelTo(vertex);
  }

  void _travelTo(int targetVertex) {
    final int? current = _anchorVertex;
    if (current == null) {
      setState(() {
        _anchorVertex = targetVertex;
        _startVertex = targetVertex;
        _hintedEdge = null;
        _notice = _english
            ? 'Continue to an adjacent dot to draw a side.'
            : 'Bir kenar çizmek için komşu noktaya ilerle.';
      });
      _audio.hapticSelection();
      return;
    }
    if (current == targetVertex) return;
    final LoopPoint from = _puzzle.point(current);
    final LoopPoint to = _puzzle.point(targetVertex);
    int row = from.row;
    int column = from.column;
    while (row != to.row || column != to.column) {
      final int remainingRows = (to.row - row).abs();
      final int remainingColumns = (to.column - column).abs();
      if (remainingRows > remainingColumns) {
        row += to.row > row ? 1 : -1;
      } else if (remainingColumns > 0) {
        column += to.column > column ? 1 : -1;
      } else {
        row += to.row > row ? 1 : -1;
      }
      final int next = _puzzle.vertexId(row, column);
      if (!_connectOne(next)) return;
    }
  }

  bool _connectOne(int nextVertex) {
    if (_finished) return false;
    final int? previous = _anchorVertex;
    if (previous == null) return false;
    final LoopPoint from = _puzzle.point(previous);
    final LoopPoint to = _puzzle.point(nextVertex);
    final int distance =
        (from.row - to.row).abs() + (from.column - to.column).abs();
    if (distance != 1) {
      _recordError(
        _english
            ? 'Follow neighboring dots; diagonal edges are not part of the loop.'
            : 'Komşu noktaları izle; çapraz kenarlar döngüye dahil değil.',
      );
      return false;
    }
    final int edge = from.row == to.row
        ? _puzzle.horizontalEdge(from.row, math.min(from.column, to.column))
        : _puzzle.verticalEdge(math.min(from.row, to.row), from.column);
    if (_selectedEdges.contains(edge)) {
      _recordError(
        _english ? 'That side is already drawn. Use Undo to retrace safely.' : 'Bu kenar zaten çizili. Güvenle geri izlemek için Geri al kullan.',
      );
      return false;
    }
    if (!_puzzle.canAddEdge(_selectedEdges, edge)) {
      _recordError(
        _english
            ? 'That side breaks a clue or creates a branch.'
            : 'Bu kenar bir ipucunu bozuyor ya da dal oluşturuyor.',
      );
      return false;
    }
    final Set<int> proposed = <int>{..._selectedEdges, edge};
    if (_puzzle.formsSingleClosedLoop(proposed) &&
        !_puzzle.isSolved(proposed)) {
      _recordError(
        _english
            ? 'A smaller loop closes too early; undo its last edge.'
            : 'Küçük halka erken kapandı; son kenarı geri al.',
      );
      return false;
    }
    _undoStack.add((edge: edge, previousAnchor: previous));
    _audio.hapticLight();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .16));
    setState(() {
      _selectedEdges.add(edge);
      _anchorVertex = nextVertex;
      _hintedEdge = null;
      _notice = _english
          ? '${_selectedEdges.length} sides drawn. Keep the loop connected.'
          : '${_selectedEdges.length} kenar çizildi. Halkayı bağlı tut.';
    });
    if (_puzzle.isSolved(_selectedEdges)) unawaited(_finish());
    return true;
  }

  void _recordError(String message) {
    _session.recordMistake();
    _audio.hapticLight();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .2));
    setState(() {
      _mistakes++;
      _notice = message;
    });
  }

  void _undo() {
    if (_finished || _undoStack.isEmpty) return;
    final ({int edge, int previousAnchor}) step = _undoStack.removeLast();
    setState(() {
      _selectedEdges.remove(step.edge);
      _anchorVertex = step.previousAnchor;
      if (_undoStack.isEmpty) _startVertex = null;
      _hintedEdge = null;
      _notice = _english ? 'Last side removed.' : 'Son kenar geri alındı.';
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .2));
  }

  void _showHint() {
    if (!_ready || _finished || !_session.canUseHint) return;
    final List<int> missing = _puzzle.solutionEdges
        .where((int edge) => !_selectedEdges.contains(edge))
        .toList(growable: false);
    if (missing.isEmpty) return;
    _session.useHint(pointCost: 260);
    setState(() {
      _hints++;
      _hintedEdge = missing.first;
      _notice = _english
          ? 'Gold marks one certified side. Connect it without making a branch.'
          : 'Altın vurgu sertifikalı bir kenarı gösterir. Dalsız biçimde bağla.';
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
          _english ? 'Restart this loop?' : 'Döngü yeniden başlasın mı?',
        ),
        content: Text(
          _english
              ? 'The same certified clue grid will be restored.'
              : 'Aynı doğrulanmış ipucu ızgarası yeniden kurulacak.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(_english ? 'Keep drawing' : 'Çizmeye devam et'),
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
    _session.recordAccepted(points: 60);
    _session.complete(
      stars: stars,
      action: widget.level.number < LoopMasterGamePage.totalCases
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
      titleTr: 'DÖNGÜ KAPANDI',
      titleEn: 'LOOP CLOSED',
      detailTr: '${_puzzle.size}×${_puzzle.size} ızgara · $_hints ipucu.',
      detailEn: '${_puzzle.size}×${_puzzle.size} grid · $_hints hints.',
      stars: stars,
      score: score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < LoopMasterGamePage.totalCases,
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
          surfaceTintColor: Colors.transparent,
          title: Text(_english ? 'LOOP MASTER' : 'DÖNGÜ USTASI'),
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
          _english ? 'LOOP MASTER' : 'DÖNGÜ USTASI',
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Center(child: _LoopLevelPill(level: widget.level.number)),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 3, 14, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _LoopStatus(
                level: widget.level.number,
                tier: _puzzle.difficultyTier,
                edgeCount: _selectedEdges.length,
                mistakes: _mistakes,
                english: _english,
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double boardSize = math.min(
                    520.0,
                    constraints.maxWidth - 4,
                  );
                  return Center(
                    child: Container(
                      key: const ValueKey<String>('loop_master_board_frame'),
                      width: boardSize + 14,
                      height: boardSize + 14,
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2DDD2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFD0C9BC)),
                        boxShadow: StudioVisuals.softShadow,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox.square(
                          dimension: boardSize,
                          child: LayoutBuilder(
                            builder:
                                (
                                  BuildContext context,
                                  BoxConstraints boardConstraints,
                                ) {
                                  final Size size = Size(
                                    boardConstraints.maxWidth,
                                    boardConstraints.maxHeight,
                                  );
                                  return Semantics(
                                    label: _english
                                        ? 'Slitherlink loop drawing board, ${_puzzle.size} by ${_puzzle.size}. Clue numbers show how many surrounding sides belong to the single loop.'
                                        : 'Döngü çizim tahtası, ${_puzzle.size} çarpı ${_puzzle.size}. Sayılar tek halkada çevrede kaç kenar bulunduğunu gösterir.',
                                    value: _english
                                        ? '${_selectedEdges.length} sides drawn'
                                        : '${_selectedEdges.length} kenar çizili',
                                    child: Listener(
                                      behavior: HitTestBehavior.opaque,
                                      onPointerDown: (PointerDownEvent event) =>
                                          _onPointerDown(event, size),
                                      onPointerMove: (PointerMoveEvent event) =>
                                          _onPointerMove(event, size),
                                      child: CustomPaint(
                                        key: const ValueKey<String>(
                                          'loop_master_board',
                                        ),
                                        painter: _LoopBoardPainter(
                                          puzzle: _puzzle,
                                          selected: Set<int>.unmodifiable(
                                            _selectedEdges,
                                          ),
                                          anchorVertex: _anchorVertex,
                                          startVertex: _startVertex,
                                          hintedEdge: _hintedEdge,
                                        ),
                                        child: const SizedBox.expand(),
                                      ),
                                    ),
                                  );
                                },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _LoopActions(
                canUndo: _undoStack.isNotEmpty,
                busy: _finished,
                english: _english,
                onUndo: _undo,
                onHint: _showHint,
                onReset: _confirmReset,
              ),
              if (_notice != null) ...<Widget>[
                const SizedBox(height: 8),
                _LoopNotice(
                  text: _notice!,
                  warning:
                      _notice!.contains(_english ? 'breaks' : 'bozuyor') ||
                      _notice!.contains(
                        _english ? 'closes too early' : 'erken kapandı',
                      ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                _english
                    ? 'Draw along neighboring dots. Each touched dot must finish with two lines; the numbered cells must match, and all lines must form one loop.'
                    : 'Komşu noktalar arasında çiz. Çizgi değen her noktada iki kenar kalmalı; hücre sayıları tutmalı ve çizgilerin tümü tek halka oluşturmalı.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: StudioVisuals.muted,
                  fontSize: 12,
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

class _LoopLevelPill extends StatelessWidget {
  const _LoopLevelPill({required this.level});
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
      context.l10n.levelOutOf(level, LoopMasterGamePage.totalCases),
      style: const TextStyle(
        fontFamily: 'Roboto',
        color: StudioVisuals.ink,
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _LoopStatus extends StatelessWidget {
  const _LoopStatus({
    required this.level,
    required this.tier,
    required this.edgeCount,
    required this.mistakes,
    required this.english,
  });

  final int level;
  final String tier;
  final int edgeCount;
  final int mistakes;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
    decoration: BoxDecoration(
      color: StudioVisuals.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: StudioVisuals.line),
      boxShadow: StudioVisuals.softShadow,
    ),
    child: Row(
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: _LoopMasterPlayPageState._accent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                english ? 'SINGLE LOOP' : 'TEK HALKA',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: StudioVisuals.ink,
                  fontSize: 12,
                  letterSpacing: .45,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${english ? 'STUDY' : 'ETÜT'} ${level.toString().padLeft(2, '0')} · ${_tierLabel(tier, english)}',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: StudioVisuals.muted,
                  fontSize: 10,
                  letterSpacing: .4,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        _LoopMiniStat(value: '$edgeCount', label: english ? 'LINES' : 'ÇİZGİ'),
        const SizedBox(width: 12),
        _LoopMiniStat(value: '$mistakes', label: english ? 'ERROR' : 'HATA'),
      ],
    ),
  );

  static String _tierLabel(String tier, bool english) => switch (tier) {
    'ADVANCED' => english ? 'ADVANCED' : 'İLERİ',
    'EXPERT' => english ? 'EXPERT' : 'UZMAN',
    'MASTER' => english ? 'MASTER' : 'USTA',
    _ => english ? 'FOUNDATION' : 'USTALAŞMA',
  };
}

class _LoopMiniStat extends StatelessWidget {
  const _LoopMiniStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: <Widget>[
      Text(
        value,
        style: const TextStyle(
          fontFamily: 'Roboto',
          color: StudioVisuals.ink,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
      Text(
        label,
        style: const TextStyle(
          fontFamily: 'Roboto',
          color: StudioVisuals.muted,
          fontSize: 10,
          letterSpacing: .4,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

class _LoopBoardPainter extends CustomPainter {
  const _LoopBoardPainter({
    required this.puzzle,
    required this.selected,
    required this.anchorVertex,
    required this.startVertex,
    required this.hintedEdge,
  });

  final LoopPuzzle puzzle;
  final Set<int> selected;
  final int? anchorVertex;
  final int? startVertex;
  final int? hintedEdge;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = _LoopMasterPlayPageState._paper,
    );
    final double cellWidth = size.width / puzzle.size;
    final double cellHeight = size.height / puzzle.size;
    final Paint gridPaint = Paint()
      ..color = const Color(0xFFD8D4CA)
      ..strokeWidth = 1;
    for (int index = 0; index <= puzzle.size; index++) {
      final double x = index * cellWidth;
      final double y = index * cellHeight;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    for (int row = 0; row < puzzle.size; row++) {
      for (int column = 0; column < puzzle.size; column++) {
        final int? clue = puzzle.clues[row * puzzle.size + column];
        if (clue == null) continue;
        final TextPainter text = TextPainter(
          text: TextSpan(
            text: '$clue',
            style: TextStyle(
              fontFamily: 'Roboto',
              color: _LoopMasterPlayPageState._clue,
              fontSize: math.min(cellWidth, cellHeight) * .31,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: cellWidth);
        text.paint(
          canvas,
          Offset(
            column * cellWidth + (cellWidth - text.width) / 2,
            row * cellHeight + (cellHeight - text.height) / 2,
          ),
        );
      }
    }

    final Paint linePaint = Paint()
      ..color = _LoopMasterPlayPageState._line
      ..strokeWidth = math.max(3.0, math.min(cellWidth, cellHeight) * .105)
      ..strokeCap = StrokeCap.round;
    for (final int edge in selected) {
      _drawEdge(canvas, size, edge, linePaint);
    }
    if (hintedEdge != null && !selected.contains(hintedEdge)) {
      final Paint hintPaint = Paint()
        ..color = _LoopMasterPlayPageState._hint
        ..strokeWidth = math.max(4.0, math.min(cellWidth, cellHeight) * .13)
        ..strokeCap = StrokeCap.round;
      _drawEdge(canvas, size, hintedEdge!, hintPaint);
    }

    final Paint dotPaint = Paint()..color = const Color(0xFF8D9993);
    for (int row = 0; row <= puzzle.size; row++) {
      for (int column = 0; column <= puzzle.size; column++) {
        final int vertex = puzzle.vertexId(row, column);
        final Offset center = Offset(column * cellWidth, row * cellHeight);
        canvas.drawCircle(center, math.max(1.5, cellWidth * .055), dotPaint);
        if (vertex == startVertex) {
          canvas.drawCircle(
            center,
            math.max(4.2, cellWidth * .16),
            Paint()
              ..color = _LoopMasterPlayPageState._accent.withValues(alpha: .7),
          );
        }
        if (vertex == anchorVertex) {
          canvas.drawCircle(
            center,
            math.max(3.4, cellWidth * .13),
            Paint()..color = _LoopMasterPlayPageState._hint,
          );
        }
      }
    }
  }

  void _drawEdge(Canvas canvas, Size size, int edge, Paint paint) {
    final (int first, int second) = puzzle.edgeEndpoints(edge);
    final LoopPoint a = puzzle.point(first);
    final LoopPoint b = puzzle.point(second);
    canvas.drawLine(
      Offset(
        a.column * size.width / puzzle.size,
        a.row * size.height / puzzle.size,
      ),
      Offset(
        b.column * size.width / puzzle.size,
        b.row * size.height / puzzle.size,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_LoopBoardPainter oldDelegate) =>
      !identical(oldDelegate.selected, selected) ||
      oldDelegate.anchorVertex != anchorVertex ||
      oldDelegate.startVertex != startVertex ||
      oldDelegate.hintedEdge != hintedEdge;
}

class _LoopActions extends StatelessWidget {
  const _LoopActions({
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
        child: _LoopActionButton(
          icon: Icons.undo_rounded,
          label: english ? 'Undo' : 'Geri al',
          enabled: canUndo && !busy,
          onPressed: onUndo,
        ),
      ),
      const SizedBox(width: 7),
      Expanded(
        child: _LoopActionButton(
          icon: Icons.lightbulb_outline_rounded,
          label: english ? 'Hint' : 'İpucu',
          enabled: !busy,
          onPressed: onHint,
        ),
      ),
      const SizedBox(width: 7),
      Expanded(
        child: _LoopActionButton(
          icon: Icons.restart_alt_rounded,
          label: english ? 'Reset' : 'Sıfırla',
          enabled: !busy,
          onPressed: onReset,
        ),
      ),
    ],
  );
}

class _LoopActionButton extends StatelessWidget {
  const _LoopActionButton({
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
        foregroundColor: _LoopMasterPlayPageState._line,
        disabledForegroundColor: StudioVisuals.muted.withValues(alpha: .45),
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

class _LoopNotice extends StatelessWidget {
  const _LoopNotice({required this.text, required this.warning});
  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: warning ? const Color(0xFFFFF0EC) : const Color(0xFFEEF4F0),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: warning ? const Color(0xFFE9CBC6) : const Color(0xFFD9E5DC),
      ),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'Roboto',
        color: warning
            ? _LoopMasterPlayPageState._warning
            : _LoopMasterPlayPageState._line,
        fontSize: 12,
        height: 1.3,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
