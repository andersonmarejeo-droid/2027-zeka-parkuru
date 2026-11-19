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
import '../shared/game_instruction_catalog.dart';
import '../shared/parkur_game_kit.dart';
import '../shared/studio_game_session.dart';
import '../shared/studio_game_skin.dart';
import 'picross_puzzle.dart';

class PicrossGamePage extends StatelessWidget {
  const PicrossGamePage({
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
    GameContentPolicy.nativeStages('picross_master'),
    (int index) {
      final int number = index + 1;
      final int stage = (index % 10) + 1;
      final int chapter = index ~/ 10 + 1;
      final String difficulty = switch (number) {
        <= 6 => 'USTALAŞMA',
        7 || 8 => 'İLERİ',
        <= 16 => 'UZMAN',
        _ => 'USTA',
      };
      return ParkurLevelSpec(
        number: number,
        titleTr: 'Picross ${number.toString().padLeft(2, '0')}',
        titleEn: 'Picross ${number.toString().padLeft(2, '0')}',
        subtitleTr: _subtitle(number, stage, chapter, english: false),
        subtitleEn: _subtitle(number, stage, chapter, english: true),
        difficulty: difficulty,
        icon: Icons.grid_4x4_rounded,
      );
    },
    growable: false,
  );

  static String _subtitle(
    int level,
    int stage,
    int chapter, {
    required bool english,
  }) {
    if (level >= 17) {
      return english
          ? 'Master grids: test long run chains against every crossing.'
          : 'Ustalık ızgaraları: uzun koşu zincirlerini tüm kesişimlerle doğrula.';
    }
    if (chapter == 2 && stage <= 6) {
      return english
          ? 'A larger canvas adds layered deductions and tighter crossings.'
          : 'Genişleyen tuval, katmanlı çıkarım ve daha sıkı kesişimler ekler.';
    }
    return switch (stage) {
      <= 3 =>
        english
            ? 'Read the run clues and reveal a clean pixel silhouette.'
            : 'Koşu ipuçlarını oku, net bir piksel silüeti ortaya çıkar.',
      <= 6 => english ? 'Use both clue axes before committing a cell.' : 'Hücreyi doldurmadan önce iki yöndeki ipuçlarını birlikte kullan.',
      7 || 8 =>
        english
            ? 'Advanced: narrow ambiguous runs through their crossings.'
            : 'İleri: belirsiz koşuları kesişimlerinden daralt.',
      9 =>
        english
            ? 'Expert: longer runs leave little room for a casual guess.'
            : 'Uzman: uzun koşularda gelişigüzel tahmine yer yok.',
      _ =>
        english
            ? 'Expert finish: every row and column must agree.'
            : 'Uzman finali: her satır ve sütun aynı çözümde buluşmalı.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forId('picross_master');
    return ParkurLevelHub(
      gameId: 'picross_master',
      progressPrefix: 'picross_master',
      titleTr: 'Picross Ustası',
      titleEn: 'Picross Master',
      taglineTr: 'Koşuları çöz • Kesişimleri doğrula • Silüeti ortaya çıkar',
      taglineEn: 'Solve the runs • Verify crossings • Reveal the silhouette',
      accent: skin.accent,
      icon: Icons.grid_4x4_rounded,
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
      ) => PicrossPlayPage(level: level, previousBestScore: previousBestScore),
    );
  }
}

enum _PicrossMark { unknown, filled, empty }

class PicrossPlayPage extends StatefulWidget {
  const PicrossPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<PicrossPlayPage> createState() => _PicrossPlayPageState();
}

class _PicrossPlayPageState extends State<PicrossPlayPage> {
  static const Color _accent = Color(0xFF3D7183);
  static const Color _ink = StudioVisuals.ink;
  static const Color _tile = Color(0xFF314F60);
  static const Color _emptyMark = Color(0xFF8794A0);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.visual,
  );
  final List<List<_PicrossMark>> _undoStack = <List<_PicrossMark>>[];
  late PicrossPuzzle _puzzle;
  late StudioGameSession _session;
  late List<_PicrossMark> _marks;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _clock;
  _PicrossMark _activeMark = _PicrossMark.filled;
  String? _notice;
  int _hints = 0;
  int _checks = 0;
  int _elapsedSeconds = 0;
  double _zoom = 1;
  bool _finished = false;
  bool get _english => context.l10n.isEnglish;

  @override
  void initState() {
    super.initState();
    _puzzle = (widget.level.poolIndex != null
        ? PicrossPuzzle.forPracticeBoard(widget.level.contentIndex)
        : PicrossPuzzle.forLevel(widget.level.contentLevel));
    _marks = List<_PicrossMark>.filled(
      _puzzle.size * _puzzle.size,
      _PicrossMark.unknown,
    );
    _session = StudioGameSession(
      level: widget.level.number,
      seed: _puzzle.seed,
    )..start();
    _stopwatch.start();
    _clock = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (mounted && !_finished) {
        setState(() => _elapsedSeconds = _stopwatch.elapsed.inSeconds);
      }
    });
    unawaited(_audioProfile.preload(_audio));
    unawaited(_prepareLevel());
  }

  Future<void> _prepareLevel() async {
    PicrossPuzzle puzzle = _puzzle;
    try {
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      final String visitKey =
          'picross_master_level_${widget.level.number}_visits';
      final int visits = await preferences.getInt(visitKey) ?? 0;
      if (widget.level.poolIndex == null && visits > 0) {
        final int playedPracticeBoards =
            await preferences.getInt('picross_master_practice_index') ?? 0;
        if (playedPracticeBoards < PicrossPuzzle.maximumVerifiedBoards) {
          final int nextBoard = playedPracticeBoards + 1;
          await preferences.setInt('picross_master_practice_index', nextBoard);
          puzzle = PicrossPuzzle.forPracticeBoard(nextBoard);
        }
      }
      await preferences.setInt(visitKey, visits + 1);
    } catch (_) {
      // Progress storage must never prevent a puzzle from opening.
    }
    if (!mounted || puzzle == _puzzle) return;
    setState(() {
      _puzzle = puzzle;
      _marks = List<_PicrossMark>.filled(
        puzzle.size * puzzle.size,
        _PicrossMark.unknown,
      );
      _session = StudioGameSession(
        level: widget.level.number,
        seed: puzzle.seed,
      )..start();
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  int get _resolvedCells =>
      _marks.where((_PicrossMark mark) => mark != _PicrossMark.unknown).length;

  int get _score => math.max(
    0,
    3400 -
        _hints * 230 -
        _session.mistakes * 160 -
        math.max(0, _checks - 1) * 40 -
        math.max(0, _elapsedSeconds - 180) ~/ 3,
  );

  int get _stars {
    if (_hints == 0 && _session.mistakes == 0) return 3;
    if (_hints <= 2 && _session.mistakes <= 2) return 2;
    return 1;
  }

  int _cellIndex(int row, int column) => row * _puzzle.size + column;

  void _saveUndo() => _undoStack.add(List<_PicrossMark>.of(_marks));

  void _selectMark(_PicrossMark mark) {
    if (_finished) return;
    setState(() {
      _activeMark = mark;
      _notice = null;
    });
    _audio.hapticSelection();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .18),
    );
  }

  void _markCell(int row, int column) {
    if (_finished || !_session.acceptsInput) return;
    final int index = _cellIndex(row, column);
    final _PicrossMark current = _marks[index];
    final _PicrossMark next = current == _activeMark
        ? _PicrossMark.unknown
        : _activeMark;
    _saveUndo();
    setState(() {
      _marks[index] = next;
      _notice = null;
    });
    _audio.hapticLight();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .16),
    );
  }

  void _undo() {
    if (_finished || _undoStack.isEmpty) return;
    setState(() {
      _marks = _undoStack.removeLast();
      _notice = null;
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .2));
  }

  void _reset() {
    if (_finished || _resolvedCells == 0) return;
    _saveUndo();
    setState(() {
      _marks = List<_PicrossMark>.filled(
        _puzzle.size * _puzzle.size,
        _PicrossMark.unknown,
      );
      _notice = _english
          ? 'The board is clear. Your previous layout is available with Undo.'
          : 'Tahta temizlendi. Önceki düzeni Geri Al ile getirebilirsin.';
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .2));
  }

  void _showHint() {
    if (_finished || !_session.canUseHint) return;
    for (int index = 0; index < _marks.length; index++) {
      if (_marks[index] != _PicrossMark.unknown) continue;
      final int row = index ~/ _puzzle.size;
      final int column = index % _puzzle.size;
      final bool answer = _puzzle.isFilled(row, column);
      _saveUndo();
      setState(() {
        _marks[index] = answer ? _PicrossMark.filled : _PicrossMark.empty;
        _hints++;
        _notice = _english
            ? 'One verified cell is revealed. Follow both clue directions.'
            : 'Doğrulanmış bir hücre açıldı. İki yöndeki ipuçlarını izle.';
      });
      _session.useHint(pointCost: 230);
      _audio.hapticSelection();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .3));
      return;
    }
  }

  bool _lineIsResolved(int row) {
    for (int column = 0; column < _puzzle.size; column++) {
      if (_marks[_cellIndex(row, column)] == _PicrossMark.unknown) return false;
    }
    return true;
  }

  bool _rowIsCorrect(int row) {
    for (int column = 0; column < _puzzle.size; column++) {
      if ((_marks[_cellIndex(row, column)] == _PicrossMark.filled) !=
          _puzzle.isFilled(row, column)) {
        return false;
      }
    }
    return true;
  }

  bool _columnIsCorrect(int column) {
    for (int row = 0; row < _puzzle.size; row++) {
      if (_marks[_cellIndex(row, column)] == _PicrossMark.unknown) return false;
    }
    for (int row = 0; row < _puzzle.size; row++) {
      if ((_marks[_cellIndex(row, column)] == _PicrossMark.filled) !=
          _puzzle.isFilled(row, column)) {
        return false;
      }
    }
    return true;
  }

  void _checkBoard() {
    if (_finished || !_session.acceptsInput) return;
    _checks++;
    if (_resolvedCells < _marks.length) {
      setState(() {
        _notice = _english
            ? 'Resolve every cell: fill the picture or mark a confirmed blank.'
            : 'Her hücreyi karara bağla: resmi doldur veya boşluğu X ile işaretle.';
      });
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .2));
      return;
    }
    final bool correct = List<int>.generate(
      _puzzle.size,
      (int row) => row,
    ).every(_rowIsCorrect);
    if (!correct) {
      _session.recordMistake();
      setState(() {
        _notice = _english
            ? 'A marked cell conflicts with a crossing clue. Compare its row and column.'
            : 'Bir hücre, kesişen ipucuyla çelişiyor. Satır ve sütununu birlikte karşılaştır.';
      });
      _audio.hapticLight();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .26));
      return;
    }
    unawaited(_complete());
  }

  Future<void> _complete() async {
    if (_finished || !_session.acceptsInput) return;
    _finished = true;
    _clock?.cancel();
    _stopwatch.stop();
    final int score = _score;
    final int stars = _stars;
    _session.recordAccepted(points: score);
    _session.complete(
      stars: stars,
      action: widget.level.number < PicrossGamePage.totalCases
          ? StudioResultAction.next
          : StudioResultAction.map,
    );
    _audio.hapticMedium();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.accepted, gain: .38),
    );
    unawaited(_audioProfile.play(
      _audio,
      GameAudioEvent.levelComplete,
      levelNumber: widget.level.number,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 170));
    if (!mounted) return;
    final ParkurResultAction? result = await showParkurResultDialog(
      context: context,
      accent: _accent,
      titleTr: 'SİLÜET ORTAYA ÇIKTI',
      titleEn: 'SILHOUETTE REVEALED',
      detailTr: 'Kesişimler doğrulandı · $_checks kontrol · $_hints ipucu.',
      detailEn: 'Crossings verified · $_checks checks · $_hints hints.',
      stars: stars,
      score: score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < PicrossGamePage.totalCases,
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

  void _showHowToPlay() {
    final GameInstruction? guide = GameInstructionCatalog.forGame(
      'picross_master',
    );
    if (guide == null) return;
    final List<String> steps = guide.steps(_english);
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(
          _english ? 'How to solve Picross' : 'Picross nasıl çözülür?',
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(guide.summary(_english)),
              const SizedBox(height: 14),
              for (int index = 0; index < steps.length; index++) ...<Widget>[
                Text('${index + 1}. ${steps[index]}'),
                if (index < steps.length - 1) const SizedBox(height: 10),
              ],
              const SizedBox(height: 12),
              Text(
                _english
                    ? 'When every row and column agrees, tap “Verify Silhouette”.'
                    : 'Tüm satır ve sütunlar tutarlı olduğunda “Silüeti Doğrula”ya dokun.',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(_english ? 'GOT IT' : 'ANLADIM'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double clueWidth = (_puzzle.size >= 10 ? 44.0 : 36.0);
    final double available = math.max(160, screenWidth - clueWidth - 44);
    final double cellSide = (available / _puzzle.size).clamp(18, 36) * _zoom;
    final int progress = (_resolvedCells * 100 ~/ _marks.length).clamp(0, 100);
    final String time =
        '${(_elapsedSeconds ~/ 60).toString().padLeft(2, '0')}:${(_elapsedSeconds % 60).toString().padLeft(2, '0')}';

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
              _english ? 'PICROSS MASTER' : 'PICROSS USTASI',
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
            Text(
              '${_english ? 'Level' : 'Bölüm'} ${widget.level.number} • ${_puzzle.size}×${_puzzle.size}',
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
            onPressed: _showHowToPlay,
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
                          color: _accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_puzzle.size}×${_puzzle.size}',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            color: _accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$_resolvedCells/${_marks.length} ($progress%)',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          color: StudioVisuals.ink,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(Icons.timer_outlined, size: 14, color: StudioVisuals.muted),
                          const SizedBox(width: 3),
                          Text(
                            time,
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: StudioVisuals.ink,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Genişletilmiş Picross Tahtası (Expanded + SingleChildScrollView)
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: _BoardPanel(
                        puzzle: _puzzle,
                        marks: _marks,
                        cellSide: cellSide,
                        clueWidth: clueWidth,
                        english: _english,
                        lineIsResolved: _lineIsResolved,
                        rowIsCorrect: _rowIsCorrect,
                        columnIsCorrect: _columnIsCorrect,
                        onCellTap: _markCell,
                        onZoomOut: () => setState(
                          () => _zoom = (_zoom - .2).clamp(.8, 2.4).toDouble(),
                        ),
                        onZoomIn: () => setState(
                          () => _zoom = (_zoom + .2).clamp(.8, 2.4).toDouble(),
                        ),
                        zoom: _zoom,
                      ),
                    ),
                  ),
                ),
                if (_notice != null) ...<Widget>[
                  const SizedBox(height: 4),
                  _Notice(text: _notice!),
                ],
                const SizedBox(height: 6),
                // İşaret Seçici (Kompakt Bar)
                _MarkPicker(
                  active: _activeMark,
                  onSelect: _selectMark,
                  english: _english,
                ),
                const SizedBox(height: 6),
                // Alt Kontrol ve Doğrulama Butonları
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _ActionRow(
                        canUndo: _undoStack.isNotEmpty,
                        english: _english,
                        onUndo: _undo,
                        onReset: _reset,
                        onHint: _showHint,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _finished ? null : _checkBoard,
                      style: FilledButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 42),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.fact_check_outlined, size: 17),
                      label: Text(
                        _english ? 'VERIFY' : 'DOŞRULA',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BoardPanel extends StatelessWidget {
  const _BoardPanel({
    required this.puzzle,
    required this.marks,
    required this.cellSide,
    required this.clueWidth,
    required this.english,
    required this.lineIsResolved,
    required this.rowIsCorrect,
    required this.columnIsCorrect,
    required this.onCellTap,
    required this.onZoomOut,
    required this.onZoomIn,
    required this.zoom,
  });

  final PicrossPuzzle puzzle;
  final List<_PicrossMark> marks;
  final double cellSide;
  final double clueWidth;
  final bool english;
  final bool Function(int row) lineIsResolved;
  final bool Function(int row) rowIsCorrect;
  final bool Function(int column) columnIsCorrect;
  final void Function(int row, int column) onCellTap;
  final VoidCallback onZoomOut;
  final VoidCallback onZoomIn;
  final double zoom;

  @override
  Widget build(BuildContext context) {
    final int size = puzzle.size;
    final double clueBand = puzzle.columnClues
        .fold<int>(1, (int max, List<int> clue) => math.max(max, clue.length))
        .toDouble();
    final double clueRowHeight = math.max(15, cellSide * .82);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      decoration: BoxDecoration(
        color: StudioVisuals.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: StudioVisuals.line),
        boxShadow: StudioVisuals.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  english ? 'CLUE MATRIX' : 'İPUCU MATRİSİ',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: StudioVisuals.muted,
                    fontSize: 11,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _ZoomButton(icon: Icons.remove_rounded, onTap: onZoomOut),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7),
                child: Text(
                  '${(zoom * 100).round()}%',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: StudioVisuals.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _ZoomButton(icon: Icons.add_rounded, onTap: onZoomIn),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    SizedBox(
                      width: clueWidth,
                      height: clueBand * clueRowHeight,
                    ),
                    for (int column = 0; column < size; column++)
                      SizedBox(
                        width: cellSide,
                        height: clueBand * clueRowHeight,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: puzzle.columnClues[column]
                                .map(
                                  (int clue) => SizedBox(
                                    height: clueRowHeight,
                                    child: Center(
                                      child: Text(
                                        '$clue',
                                        style: TextStyle(
                                          fontFamily: 'Roboto',
                                          color: columnIsCorrect(column)
                                              ? _PicrossPlayPageState._accent
                                              : StudioVisuals.muted,
                                          fontSize: math.min(
                                            12,
                                            cellSide * .48,
                                          ),
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                          ),
                        ),
                      ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F9FA),
                    border: Border.all(
                      color: const Color(0xFFCBD5DC),
                      width: 1.2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      for (int row = 0; row < size; row++)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            SizedBox(
                              width: clueWidth - 4,
                              height: cellSide,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: puzzle.rowClues[row]
                                    .map(
                                      (int clue) => Padding(
                                        padding: const EdgeInsets.only(left: 3),
                                        child: Text(
                                          '$clue',
                                          style: TextStyle(
                                            fontFamily: 'Roboto',
                                            color:
                                                lineIsResolved(row) &&
                                                    rowIsCorrect(row)
                                                ? _PicrossPlayPageState._accent
                                                : StudioVisuals.muted,
                                            fontSize: math.min(
                                              12,
                                              cellSide * .5,
                                            ),
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                            ),
                            for (int column = 0; column < size; column++)
                              _PicrossCell(
                                mark: marks[row * size + column],
                                side: cellSide,
                                strongBorder:
                                    (row + 1) % 5 == 0 && row + 1 < size ||
                                    (column + 1) % 5 == 0 && column + 1 < size,
                                row: row,
                                column: column,
                                onTap: onCellTap,
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: <Widget>[
              const Icon(
                Icons.swipe_rounded,
                size: 15,
                color: StudioVisuals.muted,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  english
                      ? 'Zoom for precise marks; swipe sideways on wider boards.'
                      : 'Hassas işaretleme için yakınlaştır; geniş tahtayı yana kaydır.',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: StudioVisuals.muted,
                    fontSize: 11,
                    height: 1.25,
                  ),
                ),
              ),
              Text(
                '${puzzle.filledCellCount} ${english ? 'cells' : 'hücre'}',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: _PicrossPlayPageState._accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PicrossCell extends StatelessWidget {
  const _PicrossCell({
    required this.mark,
    required this.side,
    required this.strongBorder,
    required this.row,
    required this.column,
    required this.onTap,
  });

  final _PicrossMark mark;
  final double side;
  final bool strongBorder;
  final int row;
  final int column;
  final void Function(int row, int column) onTap;

  @override
  Widget build(BuildContext context) {
    final bool filled = mark == _PicrossMark.filled;
    final bool empty = mark == _PicrossMark.empty;
    final String label = context.l10n.isEnglish
        ? 'Row ${row + 1}, column ${column + 1}, ${filled
              ? 'filled'
              : empty
              ? 'marked empty'
              : 'unknown'}'
        : '${row + 1}. satır ${column + 1}. sütun, ${filled
              ? 'dolu'
              : empty
              ? 'boş işaretli'
              : 'belirsiz'}';
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: () => onTap(row, column),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 105),
          width: side,
          height: side,
          decoration: BoxDecoration(
            color: filled
                ? _PicrossPlayPageState._tile
                : empty
                ? const Color(0xFFF0F3F5)
                : Colors.white,
            border: Border.all(
              color: strongBorder
                  ? const Color(0xFFA7B5BF)
                  : const Color(0xFFDDE4E9),
              width: strongBorder ? 1.15 : .65,
            ),
          ),
          child: empty
              ? Center(
                  child: Icon(
                    Icons.close_rounded,
                    size: side * .62,
                    color: _PicrossPlayPageState._emptyMark,
                  ),
                )
              : filled
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        const Color(0xFF46697A),
                        _PicrossPlayPageState._tile,
                      ],
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class _MarkPicker extends StatelessWidget {
  const _MarkPicker({
    required this.active,
    required this.onSelect,
    required this.english,
  });

  final _PicrossMark active;
  final ValueChanged<_PicrossMark> onSelect;
  final bool english;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: _MarkButton(
          active: active == _PicrossMark.filled,
          icon: Icons.square_rounded,
          label: english ? 'FILL' : 'DOLDUR',
          onTap: () => onSelect(_PicrossMark.filled),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _MarkButton(
          active: active == _PicrossMark.empty,
          icon: Icons.close_rounded,
          label: english ? 'EMPTY' : 'BOŞ',
          onTap: () => onSelect(_PicrossMark.empty),
        ),
      ),
    ],
  );
}

class _MarkButton extends StatelessWidget {
  const _MarkButton({
    required this.active,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool active;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: active ? const Color(0xFFE7F0F0) : StudioVisuals.surface,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? _PicrossPlayPageState._accent : StudioVisuals.line,
            width: active ? 1.3 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 16, color: _PicrossPlayPageState._accent),
            const SizedBox(width: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: _PicrossPlayPageState._ink,
                    fontSize: 12,
                    letterSpacing: .4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.canUndo,
    required this.english,
    required this.onUndo,
    required this.onReset,
    required this.onHint,
  });

  final bool canUndo;
  final bool english;
  final VoidCallback onUndo;
  final VoidCallback onReset;
  final VoidCallback onHint;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: _SmallAction(
          icon: Icons.undo_rounded,
          label: english ? 'UNDO' : 'GERİ AL',
          onTap: canUndo ? onUndo : null,
        ),
      ),
      const SizedBox(width: 7),
      Expanded(
        child: _SmallAction(
          icon: Icons.restart_alt_rounded,
          label: english ? 'RESET' : 'SIFIRLA',
          onTap: onReset,
        ),
      ),
      const SizedBox(width: 7),
      Expanded(
        child: _SmallAction(
          icon: Icons.lightbulb_outline_rounded,
          label: english ? 'HINT' : 'İPUCU',
          onTap: onHint,
        ),
      ),
    ],
  );
}

class _SmallAction extends StatelessWidget {
  const _SmallAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      foregroundColor: StudioVisuals.ink,
      backgroundColor: StudioVisuals.surface,
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 2),
      visualDensity: VisualDensity.compact,
      side: const BorderSide(color: StudioVisuals.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14),
        const SizedBox(width: 2),
        Flexible(
          child: FittedBox(
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
        ),
      ],
    ),
  );
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: StudioVisuals.surfaceSoft,
    borderRadius: BorderRadius.circular(9),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(icon, size: 17, color: _PicrossPlayPageState._ink),
      ),
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
    decoration: BoxDecoration(
      color: StudioVisuals.amberSoft,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: StudioVisuals.amber.withValues(alpha: .28)),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontFamily: 'Roboto',
        color: _PicrossPlayPageState._ink,
        fontSize: 11,
        height: 1.35,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}