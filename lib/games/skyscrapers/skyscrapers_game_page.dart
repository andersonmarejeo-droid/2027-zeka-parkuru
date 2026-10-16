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
import 'skyscrapers_puzzle.dart';

class SkyscrapersGamePage extends StatelessWidget {
  const SkyscrapersGamePage({
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
    GameContentPolicy.nativeStages('skyscrapers'),
    (int index) {
      final int level = index + 1;
      final int chapter = index ~/ 10 + 1;
      final int stage = index % 10 + 1;
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Gökdelen ${level.toString().padLeft(2, '0')}',
        titleEn: 'Skyline ${level.toString().padLeft(2, '0')}',
        subtitleTr: _subtitle(stage, chapter, english: false),
        subtitleEn: _subtitle(stage, chapter, english: true),
        difficulty: switch (stage) {
          <= 6 => chapter == 1 ? 'USTALAŞMA' : 'DERİNLEŞME',
          7 || 8 => 'İLERİ',
          9 => 'UZMAN',
          _ => 'USTA',
        },
        icon: Icons.location_city_outlined,
      );
    },
    growable: false,
  );

  static String _subtitle(int stage, int chapter, {required bool english}) {
    if (chapter == 2 && stage <= 6) {
      return english
          ? 'Use intersecting sightlines to narrow the remaining skyline.'
          : 'Kesişen görüş çizgileriyle olası yükseklikleri daralt.';
    }
    return switch (stage) {
      <= 3 =>
        english
            ? 'Each row and column uses every height once.'
            : 'Her satır ve sütunda her yüksekliği bir kez kullan.',
      <= 6 =>
        english
            ? 'Read the visible-building counts from all four edges.'
            : 'Dört kenardaki görünen bina sayılarını birlikte oku.',
      7 || 8 =>
        english
            ? 'Advanced: intersect skyline clues with Latin-square logic.'
            : 'İleri: gökyüzü ipuçlarını Latin-kare mantığıyla kesiştir.',
      9 =>
        english
            ? 'Expert: larger grid, fewer visible clues.'
            : 'Uzman: daha geniş ızgara, daha az görüş ipucu.',
      _ =>
        english
            ? 'Master skyline: prove every row, column and sightline.'
            : 'Usta silüeti: satırları, sütunları ve görüşleri kanıtla.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forId('skyscrapers');
    return ParkurLevelHub(
      gameId: 'skyscrapers',
      progressPrefix: 'skyscrapers',
      titleTr: 'Gökdelenler',
      titleEn: 'Skyscrapers',
      taglineTr: 'Görüş ipuçlarını çöz • Silüeti tamamla',
      taglineEn: 'Read each sightline • Complete the skyline',
      accent: skin.accent,
      icon: Icons.location_city_outlined,
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
          ) => SkyscrapersPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class SkyscrapersPlayPage extends StatefulWidget {
  const SkyscrapersPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<SkyscrapersPlayPage> createState() => _SkyscrapersPlayPageState();
}

class _SkyscrapersPlayPageState extends State<SkyscrapersPlayPage> {
  static const Color _accent = Color(0xFF3D7183);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.logic,
  );
  final List<List<int>> _undoStack = <List<int>>[];

  late SkyscrapersPuzzle _puzzle;
  late List<int> _cells;
  late StudioGameSession _session;
  int? _selectedCell;
  int _hints = 0;
  int _mistakes = 0;
  int _edits = 0;
  bool _ready = false;
  bool _finished = false;
  bool _english = false;
  Set<int> _errorCells = <int>{};
  String? _notice;

  int get _emptyCount => _cells.where((int value) => value == 0).length;
  int get _score =>
      math.max(0, 5200 - _edits * 7 - _hints * 360 - _mistakes * 190);
  int get _stars => _hints == 0 && _mistakes == 0
      ? 3
      : _hints <= 2 && _mistakes <= 2
      ? 2
      : 1;

  Set<int> get _duplicateCells {
    final Set<int> invalid = <int>{};
    final int size = _puzzle.size;
    for (int row = 0; row < size; row++) {
      final Map<int, List<int>> cellsForHeight = <int, List<int>>{};
      for (int column = 0; column < size; column++) {
        final int index = row * size + column;
        final int height = _cells[index];
        if (height > 0) {
          cellsForHeight.putIfAbsent(height, () => <int>[]).add(index);
        }
      }
      for (final List<int> duplicates in cellsForHeight.values) {
        if (duplicates.length > 1) invalid.addAll(duplicates);
      }
    }
    for (int column = 0; column < size; column++) {
      final Map<int, List<int>> cellsForHeight = <int, List<int>>{};
      for (int row = 0; row < size; row++) {
        final int index = row * size + column;
        final int height = _cells[index];
        if (height > 0) {
          cellsForHeight.putIfAbsent(height, () => <int>[]).add(index);
        }
      }
      for (final List<int> duplicates in cellsForHeight.values) {
        if (duplicates.length > 1) invalid.addAll(duplicates);
      }
    }
    return invalid;
  }

  @override
  void initState() {
    super.initState();
    unawaited(_audioProfile.preload(_audio));
    unawaited(_preparePuzzle());
  }

  Future<void> _preparePuzzle() async {
    SkyscrapersPuzzle puzzle = (widget.level.poolIndex != null
        ? SkyscrapersPuzzle.forPracticeBoard(widget.level.contentIndex)
        : SkyscrapersPuzzle.forLevel(widget.level.contentLevel));
    try {
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      final String visitKey = 'skyscrapers_level_${widget.level.number}_visits';
      final int visits = await preferences.getInt(visitKey) ?? 0;
      if (widget.level.poolIndex == null && visits > 0) {
        final int index =
            await preferences.getInt('skyscrapers_practice_index') ?? 0;
        if (index < SkyscrapersPuzzle.maximumVerifiedBoards) {
          final int next = index + 1;
          await preferences.setInt('skyscrapers_practice_index', next);
          puzzle = SkyscrapersPuzzle.forPracticeBoard(next);
        }
      }
      await preferences.setInt(visitKey, visits + 1);
    } catch (_) {
      puzzle = (widget.level.poolIndex != null
          ? SkyscrapersPuzzle.forPracticeBoard(widget.level.contentIndex)
          : SkyscrapersPuzzle.forLevel(widget.level.contentLevel));
    }
    if (!mounted) return;
    setState(() {
      _puzzle = puzzle;
      _cells = List<int>.filled(puzzle.size * puzzle.size, 0);
      _session = _newSession(puzzle);
      _undoStack.clear();
      _selectedCell = null;
      _errorCells = <int>{};
      _hints = 0;
      _mistakes = 0;
      _edits = 0;
      _notice = null;
      _finished = false;
      _ready = true;
    });
  }

  StudioGameSession _newSession(SkyscrapersPuzzle puzzle) =>
      StudioGameSession(level: widget.level.number, seed: puzzle.seed)..start();

  void _remember() {
    _undoStack.add(List<int>.of(_cells));
    if (_undoStack.length > 80) _undoStack.removeAt(0);
  }

  void _selectCell(int index) {
    if (!_ready || _finished || !_session.acceptsInput) return;
    setState(() {
      _selectedCell = index;
      _notice = _cells[index] == 0
          ? (_english
                ? 'Choose a height that fits the row, column and edge clues.'
                : 'Satır, sütun ve kenar ipuçlarına uyan yüksekliği seç.')
          : (_english
                ? 'Height ${_cells[index]} is selected; choose a replacement or clear it.'
                : '${_cells[index]} yüksekliği seçili; yenisini seç ya da sil.');
    });
    _audio.hapticSelection();
  }

  void _enterHeight(int height) {
    final int? selected = _selectedCell;
    if (!_ready || _finished || selected == null) return;
    _remember();
    setState(() {
      _cells[selected] = height;
      _edits++;
      _errorCells = _duplicateCells;
      _notice = _errorCells.isEmpty
          ? (_english ? 'Height placed.' : 'Yükseklik yerleştirildi.')
          : (_english
                ? 'This height already appears in its row or column.'
                : 'Bu yükseklik aynı satır veya sütunda zaten var.');
    });
    _session.recordAccepted(points: 8);
    _audio.hapticLight();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .18));
  }

  void _clearSelected() {
    final int? selected = _selectedCell;
    if (!_ready || selected == null || _finished || _cells[selected] == 0) {
      return;
    }
    _remember();
    setState(() {
      _cells[selected] = 0;
      _edits++;
      _errorCells = _duplicateCells;
      _notice = _english ? 'Height removed.' : 'Yükseklik silindi.';
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .18));
  }

  void _undo() {
    if (_undoStack.isEmpty || _finished) return;
    setState(() {
      _cells = _undoStack.removeLast();
      _errorCells = _duplicateCells;
      _notice = _english ? 'Last change undone.' : 'Son işlem geri alındı.';
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .2));
  }

  void _showHint() {
    if (!_ready || _finished) return;
    int target = _selectedCell ?? -1;
    if (target < 0 || _cells[target] != 0) {
      target = _cells.indexWhere((int value) => value == 0);
    }
    if (target < 0 || !_session.canUseHint) return;
    _remember();
    _session.useHint(pointCost: 360);
    _hints++;
    setState(() {
      _selectedCell = target;
      _cells[target] = _puzzle.solution[target];
      _edits++;
      _errorCells = _duplicateCells;
      _notice = _english
          ? 'Certified hint: row ${target ~/ _puzzle.size + 1}, column ${target % _puzzle.size + 1} is ${_cells[target]}.'
          : 'Doğrulanmış ipucu: ${target ~/ _puzzle.size + 1}. satır, ${target % _puzzle.size + 1}. sütun ${_cells[target]} olmalı.';
    });
    _audio.hapticSelection();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .22));
  }

  Set<int> _clueConflictCells() {
    final int size = _puzzle.size;
    final Set<int> invalid = _duplicateCells;
    for (int row = 0; row < size; row++) {
      final List<int> line = _cells.skip(row * size).take(size).toList();
      if ((_puzzle.left[row] > 0 && _visible(line) != _puzzle.left[row]) ||
          (_puzzle.right[row] > 0 &&
              _visible(line.reversed) != _puzzle.right[row])) {
        invalid.addAll(
          List<int>.generate(size, (int column) => row * size + column),
        );
      }
    }
    for (int column = 0; column < size; column++) {
      final List<int> line = <int>[
        for (int row = 0; row < size; row++) _cells[row * size + column],
      ];
      if ((_puzzle.top[column] > 0 && _visible(line) != _puzzle.top[column]) ||
          (_puzzle.bottom[column] > 0 &&
              _visible(line.reversed) != _puzzle.bottom[column])) {
        invalid.addAll(
          List<int>.generate(size, (int row) => row * size + column),
        );
      }
    }
    return invalid;
  }

  void _checkGrid() {
    if (!_ready || _finished) return;
    if (_emptyCount > 0) {
      final int empty = _cells.indexOf(0);
      setState(() {
        _selectedCell = empty;
        _notice = _english
            ? 'Fill every cell before checking the skyline.'
            : 'Gökdelenleri kontrol etmeden önce tüm hücreleri doldur.';
      });
      _audio.hapticLight();
      return;
    }
    final Set<int> conflicts = _clueConflictCells();
    if (!_puzzle.isSolved(_cells) || conflicts.isNotEmpty) {
      _mistakes++;
      setState(() {
        _errorCells = conflicts;
        _notice = conflicts.isNotEmpty
            ? (_english
                  ? 'Inspect the highlighted row, column or skyline clue.'
                  : 'Vurgulanan satırı, sütunu veya silüet ipucunu incele.')
            : (_english
                  ? 'Re-read the edge counts. The Latin grid is not the certified skyline.'
                  : 'Kenar sayılarını yeniden oku; Latin ızgarası doğrulanmış silüetle uyuşmuyor.');
      });
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .2));
      return;
    }
    _session.recordAccepted(points: 80);
    unawaited(_finish());
  }

  Future<void> _confirmReset() async {
    if (!_ready || _finished) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(
          _english ? 'Reset this skyline?' : 'Silüet sıfırlansın mı?',
        ),
        content: Text(
          _english
              ? 'The same four-edge clues will be restored.'
              : 'Aynı dört kenar ipucu korunarak tahta boşaltılacak.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(_english ? 'Keep solving' : 'Devam et'),
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
      _cells = List<int>.filled(_puzzle.size * _puzzle.size, 0);
      _undoStack.clear();
      _selectedCell = null;
      _errorCells = <int>{};
      _mistakes = 0;
      _edits = 0;
      _notice = null;
      _session = _newSession(_puzzle);
    });
  }

  static int _visible(Iterable<int> line) {
    int maximum = 0;
    int visible = 0;
    for (final int height in line) {
      if (height <= maximum) continue;
      maximum = height;
      visible++;
    }
    return visible;
  }

  Future<void> _finish() async {
    if (_finished || !mounted) return;
    _finished = true;
    final int score = _score;
    final int stars = _stars;
    _session.complete(
      stars: stars,
      action: widget.level.number < SkyscrapersGamePage.totalCases
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
      titleTr: 'SİLÜET TAMAMLANDI',
      titleEn: 'SKYLINE COMPLETE',
      detailTr:
          '${_puzzle.size}×${_puzzle.size} ızgara · ${_puzzle.clueCount} görüş ipucu.',
      detailEn:
          '${_puzzle.size}×${_puzzle.size} grid · ${_puzzle.clueCount} sightline clues.',
      stars: stars,
      score: score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < SkyscrapersGamePage.totalCases,
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
          title: Text(_english ? 'SKYSCRAPERS' : 'GÖKDELENLER'),
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
          _english ? 'SKYSCRAPERS' : 'GÖKDELENLER',
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Center(child: _SkyLevelPill(level: widget.level.number)),
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
              _SkyStatus(
                tier: _puzzle.difficultyTier,
                size: _puzzle.size,
                clues: _puzzle.clueCount,
                filled: _puzzle.size * _puzzle.size - _emptyCount,
                english: _english,
              ),
              const SizedBox(height: 9),
              _SkyInstruction(english: _english, size: _puzzle.size),
              const SizedBox(height: 10),
              Center(
                child: Container(
                  key: const ValueKey<String>('skyscrapers_board_frame'),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7E9),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFD6DADD)),
                    boxShadow: StudioVisuals.softShadow,
                  ),
                  child: _SkyscrapersBoard(
                    key: const ValueKey<String>('skyscrapers_board'),
                    puzzle: _puzzle,
                    cells: _cells,
                    selectedCell: _selectedCell,
                    errorCells: _errorCells,
                    accent: _accent,
                    english: _english,
                    onTapCell: _selectCell,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _SkyKeypad(
                size: _puzzle.size,
                enabled: !_finished && _selectedCell != null,
                selectedValue: _selectedCell == null
                    ? 0
                    : _cells[_selectedCell!],
                onValue: _enterHeight,
                onClear: _clearSelected,
              ),
              const SizedBox(height: 9),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 7,
                children: <Widget>[
                  _SkyAction(
                    key: const ValueKey<String>('skyscrapers_undo'),
                    icon: Icons.undo_rounded,
                    label: _english ? 'Undo' : 'Geri al',
                    enabled: _undoStack.isNotEmpty && !_finished,
                    onPressed: _undo,
                  ),
                  _SkyAction(
                    key: const ValueKey<String>('skyscrapers_hint'),
                    icon: Icons.lightbulb_outline_rounded,
                    label: _english ? 'Hint' : 'İpucu',
                    enabled: !_finished,
                    onPressed: _showHint,
                  ),
                  _SkyAction(
                    key: const ValueKey<String>('skyscrapers_reset'),
                    icon: Icons.restart_alt_rounded,
                    label: _english ? 'Reset' : 'Sıfırla',
                    enabled: !_finished,
                    onPressed: _confirmReset,
                  ),
                ],
              ),
              const SizedBox(height: 9),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  key: const ValueKey<String>('skyscrapers_check'),
                  onPressed: _finished ? null : _checkGrid,
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  icon: const Icon(Icons.fact_check_outlined),
                  label: Text(
                    _english ? 'Check skyline' : 'Silüeti kontrol et',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              if (_notice != null) ...<Widget>[
                const SizedBox(height: 8),
                _SkyNotice(text: _notice!, warning: _errorCells.isNotEmpty),
              ],
              const SizedBox(height: 8),
              Text(
                _english
                    ? 'A clue counts buildings visible from that edge. Taller buildings hide every shorter one behind them.'
                    : 'Kenar ipucu, o yönden görünen bina sayısını verir. Öndeki yüksek binalar arkadaki kısaları gizler.',
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

class _SkyscrapersBoard extends StatelessWidget {
  const _SkyscrapersBoard({
    super.key,
    required this.puzzle,
    required this.cells,
    required this.selectedCell,
    required this.errorCells,
    required this.accent,
    required this.english,
    required this.onTapCell,
  });

  final SkyscrapersPuzzle puzzle;
  final List<int> cells;
  final int? selectedCell;
  final Set<int> errorCells;
  final Color accent;
  final bool english;
  final ValueChanged<int> onTapCell;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final int size = puzzle.size;
      final double clueSize =
          32 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6);
      final double cellSize = math.min(
        56,
        (constraints.maxWidth - clueSize * 2) / size,
      );
      final double boardWidth = cellSize * size + clueSize * 2;
      final double boardHeight = boardWidth;
      return Semantics(
        label: english
            ? 'Skyscrapers grid with clues on each side.'
            : 'Dört kenarında görüş ipuçları bulunan Gökdelenler ızgarası.',
        child: SizedBox(
          key: const ValueKey<String>('skyscrapers_board_surface'),
          width: boardWidth,
          height: boardHeight,
          child: Column(
            children: <Widget>[
              SizedBox(
                height: clueSize,
                child: Row(
                  children: <Widget>[
                    SizedBox(width: clueSize),
                    for (int column = 0; column < size; column++)
                      SizedBox(
                        width: cellSize,
                        height: clueSize,
                        child: _SkyEdgeClue(
                          value: puzzle.top[column],
                          arrow: Icons.arrow_downward_rounded,
                          direction: 'top',
                          english: english,
                        ),
                      ),
                    SizedBox(width: clueSize),
                  ],
                ),
              ),
              for (int row = 0; row < size; row++)
                SizedBox(
                  height: cellSize,
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: clueSize,
                        height: cellSize,
                        child: _SkyEdgeClue(
                          value: puzzle.left[row],
                          arrow: Icons.arrow_forward_rounded,
                          direction: 'left',
                          english: english,
                        ),
                      ),
                      for (int column = 0; column < size; column++)
                        SizedBox(
                          width: cellSize,
                          child: _SkyCell(
                            index: row * size + column,
                            size: size,
                            height: cells[row * size + column],
                            selected: selectedCell == row * size + column,
                            error: errorCells.contains(row * size + column),
                            accent: accent,
                            onTap: onTapCell,
                          ),
                        ),
                      SizedBox(
                        width: clueSize,
                        height: cellSize,
                        child: _SkyEdgeClue(
                          value: puzzle.right[row],
                          arrow: Icons.arrow_back_rounded,
                          direction: 'right',
                          english: english,
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(
                height: clueSize,
                child: Row(
                  children: <Widget>[
                    SizedBox(width: clueSize),
                    for (int column = 0; column < size; column++)
                      SizedBox(
                        width: cellSize,
                        height: clueSize,
                        child: _SkyEdgeClue(
                          value: puzzle.bottom[column],
                          arrow: Icons.arrow_upward_rounded,
                          direction: 'bottom',
                          english: english,
                        ),
                      ),
                    SizedBox(width: clueSize),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _SkyCell extends StatelessWidget {
  const _SkyCell({
    required this.index,
    required this.size,
    required this.height,
    required this.selected,
    required this.error,
    required this.accent,
    required this.onTap,
  });

  final int index;
  final int size;
  final int height;
  final bool selected;
  final bool error;
  final Color accent;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label:
        'Row ${index ~/ size + 1}, column ${index % size + 1}, '
        '${height == 0 ? 'empty' : 'height $height'}',
    excludeSemantics: true,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey<String>('skyscrapers_cell_$index'),
        borderRadius: BorderRadius.circular(8),
        onTap: () => onTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: selected
                  ? <Color>[
                      accent.withValues(alpha: .20),
                      accent.withValues(alpha: .10),
                    ]
                  : error
                  ? const <Color>[Color(0xFFFFE8E5), Color(0xFFFFF7F5)]
                  : <Color>[
                      const Color(0xFFFFFEFB),
                      height == 0
                          ? const Color(0xFFF9F8F4)
                          : const Color(0xFFF0F2F2),
                    ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: error
                  ? const Color(0xFFD67365)
                  : selected
                  ? accent.withValues(alpha: .72)
                  : const Color(0xFFD7DDE0),
              width: selected || error ? 1.5 : .8,
            ),
            boxShadow: <BoxShadow>[
              if (height > 0 && !selected && !error)
                BoxShadow(
                  color: const Color(0xFF47545A).withValues(alpha: .09),
                  blurRadius: 3,
                  offset: const Offset(0, 1.5),
                ),
            ],
          ),
          child: Center(
            child: Text(
              height == 0 ? '' : '$height',
              key: ValueKey<String>('skyscrapers_value_$index'),
              style: TextStyle(
                fontFamily: 'Roboto',
                color: error ? const Color(0xFFB94F42) : StudioVisuals.ink,
                fontSize: 19,
                fontWeight: height == 0 ? FontWeight.w500 : FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _SkyEdgeClue extends StatelessWidget {
  const _SkyEdgeClue({
    required this.value,
    required this.arrow,
    required this.direction,
    required this.english,
  });

  final int value;
  final IconData arrow;
  final String direction;
  final bool english;

  @override
  Widget build(BuildContext context) {
    final bool horizontal = direction == 'left' || direction == 'right';
    return Semantics(
      label: english
          ? '${value == 0 ? 'No' : value} visible-building clue from $direction'
          : '${direction == 'top'
                ? 'Üst'
                : direction == 'bottom'
                ? 'Alt'
                : direction == 'left'
                ? 'Sol'
                : 'Sağ'} kenardan ${value == 0 ? 'gizli' : value} görünür bina',
      child: Container(
        alignment: Alignment.center,
        child: horizontal
            ? FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(arrow, size: 10, color: const Color(0xFF6F63C8)),
                    Text(
                      value == 0 ? '·' : '$value',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: value == 0
                            ? const Color(0xFFADB3B5)
                            : const Color(0xFF48545B),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(arrow, size: 8, color: const Color(0xFF665AA2)),
                  Text(
                    value == 0 ? '·' : '$value',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      color: value == 0
                          ? const Color(0xFFADB3B5)
                          : const Color(0xFF48545B),
                      fontSize: 12,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SkyStatus extends StatelessWidget {
  const _SkyStatus({
    required this.tier,
    required this.size,
    required this.clues,
    required this.filled,
    required this.english,
  });

  final String tier;
  final int size;
  final int clues;
  final int filled;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFFCFBF8),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE8E5DF)),
    ),
    child: Row(
      children: <Widget>[
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFEFEDF9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.location_city_outlined,
            color: _SkyscrapersPlayPageState._accent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                tier,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: Color(0xFF526660),
                  fontSize: 12,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                english
                    ? '$size×$size · $clues clues · $filled filled'
                    : '$size×$size · $clues ipucu · $filled dolu',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: Color(0xFF78827D),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SkyInstruction extends StatelessWidget {
  const _SkyInstruction({required this.english, required this.size});

  final bool english;
  final int size;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFFEFEDF9),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: const Color(0xFFDFDDF2)),
    ),
    child: Row(
      children: <Widget>[
        const Icon(
          Icons.visibility_outlined,
          size: 17,
          color: _SkyscrapersPlayPageState._accent,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            english
                ? 'Place 1–$size once per row and column. Edge numbers count visible towers.'
                : '1–$size yüksekliklerini satır/sütunda bir kez kullan. Kenar sayısı görünen kuleleri sayar.',
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: Color(0xFF596260),
              fontSize: 11,
              height: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SkyKeypad extends StatelessWidget {
  const _SkyKeypad({
    required this.size,
    required this.enabled,
    required this.selectedValue,
    required this.onValue,
    required this.onClear,
  });

  final int size;
  final bool enabled;
  final int selectedValue;
  final ValueChanged<int> onValue;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 6,
    runSpacing: 6,
    children: <Widget>[
      for (int height = 1; height <= size; height++)
        SizedBox(
          width: math.min(
            42,
            (MediaQuery.sizeOf(context).width - 48) / size - 6,
          ),
          height: 43,
          child: FilledButton(
            key: ValueKey<String>('skyscrapers_height_$height'),
            onPressed: enabled ? () => onValue(height) : null,
            style: FilledButton.styleFrom(
              backgroundColor: selectedValue == height
                  ? _SkyscrapersPlayPageState._accent
                  : const Color(0xFFFCFBF8),
              foregroundColor: selectedValue == height
                  ? Colors.white
                  : const Color(0xFF48545B),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE0E1E1)),
              ),
            ),
            child: Text(
              '$height',
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      SizedBox(
        width: 45,
        height: 43,
        child: OutlinedButton(
          key: const ValueKey<String>('skyscrapers_clear'),
          onPressed: enabled ? onClear : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF68716F),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Icon(Icons.backspace_outlined, size: 17),
        ),
      ),
    ],
  );
}

class _SkyAction extends StatelessWidget {
  const _SkyAction({
    super.key,
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
    height: 46,
    child: OutlinedButton.icon(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF596A64),
        side: const BorderSide(color: Color(0xFFDDE2DC)),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
      icon: Icon(icon, size: 17),
      label: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class _SkyNotice extends StatelessWidget {
  const _SkyNotice({required this.text, required this.warning});

  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
    decoration: BoxDecoration(
      color: warning ? const Color(0xFFFFF0ED) : const Color(0xFFF0EFF9),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: <Widget>[
        Icon(
          warning ? Icons.warning_amber_rounded : Icons.location_city_outlined,
          size: 17,
          color: warning
              ? const Color(0xFFBD6255)
              : _SkyscrapersPlayPageState._accent,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: Color(0xFF586761),
              fontSize: 11,
              height: 1.25,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SkyLevelPill extends StatelessWidget {
  const _SkyLevelPill({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xFFEFEDF9),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: const Color(0xFFDEDDF0)),
    ),
    child: Text(
      'S ${level.toString().padLeft(2, '0')}/20',
      style: const TextStyle(
        fontFamily: 'Roboto',
        color: Color(0xFF625AA2),
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}
