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
import '../shared/studio_game_skin.dart';
import 'mini_sudoku_puzzle.dart';

class MiniSudokuGamePage extends StatelessWidget {
  const MiniSudokuGamePage({
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
    GameContentPolicy.nativeStages('mini_sudoku'),
    (int index) {
      final int stage = (index % 10) + 1;
      return ParkurLevelSpec(
        number: index + 1,
        titleTr: 'Sudoku ${'${index + 1}'.padLeft(3, '0')}',
        titleEn: 'Sudoku ${'${index + 1}'.padLeft(3, '0')}',
        subtitleTr: '6×6 · 2×3 bölgeler · Her sayı bir kez',
        subtitleEn: '6×6 · 2×3 regions · Every digit once',
        difficulty: _stageName(stage, english: false),
        icon: Icons.grid_on_rounded,
      );
    },
  );

  static String _stageName(int stage, {required bool english}) => stage <= 2
      ? (english ? 'FOUNDATION' : 'BAŞLANGIÇ')
      : stage <= 6
      ? (english ? 'MASTERY' : 'USTALAŞMA')
      : stage <= 8
      ? (english ? 'ADVANCED' : 'İLERİ')
      : (english ? 'EXPERT' : 'UZMAN');

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forId('mini_sudoku');
    return ParkurLevelHub(
      gameId: 'mini_sudoku',
      progressPrefix: 'mini_sudoku',
      titleTr: 'Mini Sudoku 6×6',
      titleEn: 'Mini Sudoku 6×6',
      taglineTr: 'Satır • sütun • 2×3 bölge — her biri 1–6',
      taglineEn: 'Row • column • 2×3 region — each uses 1–6',
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
          ) => MiniSudokuPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class MiniSudokuPlayPage extends StatefulWidget {
  const MiniSudokuPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<MiniSudokuPlayPage> createState() => _MiniSudokuPlayPageState();
}

class _MiniSudokuPlayPageState extends State<MiniSudokuPlayPage> {
  static const Color _ink = StudioVisuals.ink;
  static const Color _muted = StudioVisuals.muted;
  static const Color _canvas = StudioVisuals.canvas;
  static const Color _accent = Color(0xFF247568);
  static const Color _brass = Color(0xFFB58A58);
  static const Color _coral = Color(0xFFC96E66);
  static const Color _line = Color(0xFF758B84);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.numbers,
  );
  final List<_SudokuSnapshot> _undo = <_SudokuSnapshot>[];
  late final MiniSudokuPuzzle _puzzle;
  late final List<int> _initialGivens;
  late final StudioGameSession _session;
  late List<int> _values;
  late List<Set<int>> _notes;
  int? _selectedIndex;
  bool _english = false;
  bool _noteMode = false;
  bool _finished = false;
  int _moves = 0;
  int _hints = 0;

  @override
  void initState() {
    super.initState();
    _puzzle = MiniSudokuPuzzle.forLevel(widget.level.contentIndex);
    _initialGivens = List<int>.unmodifiable(_puzzle.givens);
    _values = List<int>.from(_initialGivens);
    _notes = List<Set<int>>.generate(
      MiniSudokuPuzzle.cellCount,
      (_) => <int>{},
    );
    _selectedIndex = _initialGivens.indexWhere((int value) => value == 0);
    _session = StudioGameSession(
      level: widget.level.number,
      seed: widget.level.number,
    )..start();
    unawaited(_audioProfile.preload(_audio));
  }

  int get _filledCount => _values.where((int value) => value != 0).length;
  int get _conflictCount => _conflictedIndices.length;
  bool get _isComplete => _filledCount == MiniSudokuPuzzle.cellCount;

  Set<int> get _conflictedIndices {
    final Set<int> conflicts = <int>{};
    for (int index = 0; index < _values.length; index++) {
      final int value = _values[index];
      if (value == 0 || _initialGivens[index] != 0) continue;
      if (_puzzle.hasConflict(_values, index, value)) conflicts.add(index);
    }
    return conflicts;
  }

  void _selectCell(int index) {
    if (_finished || index < 0 || index >= _values.length) return;
    setState(() => _selectedIndex = index);
    _audio.hapticSelection();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .20),
    );
  }

  void _saveUndo() {
    _undo.add(
      _SudokuSnapshot(
        values: List<int>.from(_values),
        notes: <Set<int>>[
          for (final Set<int> cellNotes in _notes) Set<int>.from(cellNotes),
        ],
        selectedIndex: _selectedIndex,
      ),
    );
    if (_undo.length > 80) _undo.removeAt(0);
  }

  void _enterDigit(int digit) {
    final int? index = _selectedIndex;
    if (_finished || index == null) return;
    if (_initialGivens[index] != 0) {
      _showMessage(
        _english
            ? 'That clue is fixed. Select an empty cell.'
            : 'Bu ipucu sabit. Boş bir hücre seç.',
      );
      return;
    }
    if (_noteMode && _values[index] != 0) {
      _showMessage(
        _english
            ? 'Clear the value before adding pencil marks.'
            : 'Not eklemeden önce hücredeki sayıyı sil.',
      );
      return;
    }

    _saveUndo();
    if (_noteMode) {
      setState(() {
        if (!_notes[index].add(digit)) _notes[index].remove(digit);
        _moves++;
      });
      _session.recordAccepted();
      unawaited(
        _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .18),
      );
      return;
    }

    setState(() {
      _values[index] = digit;
      _notes[index].clear();
      _moves++;
      _selectedIndex = _nextEmptyAfter(index);
    });
    _session.recordAccepted();
    if (_puzzle.hasConflict(_values, index, digit)) {
      _session.recordMistake();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .3));
    } else {
      unawaited(
        _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .16),
      );
    }
  }

  int? _nextEmptyAfter(int index) {
    for (int offset = 1; offset <= _values.length; offset++) {
      final int candidate = (index + offset) % _values.length;
      if (_initialGivens[candidate] == 0 && _values[candidate] == 0) {
        return candidate;
      }
    }
    return index;
  }

  void _clearSelected() {
    final int? index = _selectedIndex;
    if (_finished || index == null || _initialGivens[index] != 0) return;
    if (_values[index] == 0 && _notes[index].isEmpty) return;
    _saveUndo();
    setState(() {
      _values[index] = 0;
      _notes[index].clear();
      _moves++;
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .25));
  }

  void _undoMove() {
    if (_finished || _undo.isEmpty) return;
    final _SudokuSnapshot snapshot = _undo.removeLast();
    setState(() {
      _values = List<int>.from(snapshot.values);
      _notes = <Set<int>>[
        for (final Set<int> cellNotes in snapshot.notes)
          Set<int>.from(cellNotes),
      ];
      _selectedIndex = snapshot.selectedIndex;
      _moves++;
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .25));
  }

  void _toggleNotes() {
    if (_finished) return;
    setState(() => _noteMode = !_noteMode);
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .2),
    );
  }

  void _hint() {
    if (_finished || !_session.canUseHint) return;
    final int? selected = _selectedIndex;
    final int index = selected != null && _values[selected] == 0
        ? selected
        : _values.indexWhere((int value) => value == 0);
    if (index < 0) return;
    _saveUndo();
    setState(() {
      _values[index] = _puzzle.solution[index];
      _notes[index].clear();
      _selectedIndex = _nextEmptyAfter(index);
      _moves++;
      _hints++;
    });
    _session.useHint(pointCost: 140);
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .32));
  }

  void _resetBoard() {
    if (_finished) return;
    setState(() {
      _values = List<int>.from(_initialGivens);
      _notes = List<Set<int>>.generate(
        MiniSudokuPuzzle.cellCount,
        (_) => <int>{},
      );
      _selectedIndex = _initialGivens.indexWhere((int value) => value == 0);
      _noteMode = false;
      _undo.clear();
      _moves = 0;
      _hints = 0;
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .25));
  }

  Future<void> _checkBoard() async {
    if (_finished) return;
    if (!_isComplete) {
      _showMessage(
        _english
            ? '${MiniSudokuPuzzle.cellCount - _filledCount} cells still need a value.'
            : '${MiniSudokuPuzzle.cellCount - _filledCount} hücre daha doldurulmalı.',
      );
      return;
    }
    if (_conflictCount > 0 || !_puzzle.isSolved(_values)) {
      _session.recordMistake();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .34));
      _showMessage(
        _english
            ? 'Check the highlighted row, column and 2×3 region.'
            : 'Vurgulanan satır, sütun ve 2×3 bölgeyi kontrol et.',
      );
      return;
    }
    await _complete();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1700),
        ),
      );
  }

  Future<void> _complete() async {
    if (_finished) return;
    _finished = true;
    final int stars = _hints == 0 && _session.mistakes == 0
        ? 3
        : _hints <= 2 && _session.mistakes <= 2
        ? 2
        : 1;
    final int score = math.max(
      220,
      2100 -
          math.max(0, _moves - _puzzle.blankCount) * 7 -
          _hints * 180 -
          _session.mistakes * 95,
    );
    _session.recordAccepted(points: score);
    final StudioGameResult result = _session.complete(
      stars: stars,
      action: widget.level.number < MiniSudokuGamePage.totalCases
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
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: _ink,
        icon: const Icon(Icons.grid_on_rounded, color: Color(0xFFE8C99B)),
        title: Text(
          _english ? 'GRID SOLVED' : 'SUDOKU TAMAMLANDI',
          style: const TextStyle(
            fontFamily: 'Roboto',
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          _english
              ? '$stars stars  •  $score points\nEvery row, column and region is complete.'
              : '$stars yıldız  •  $score puan\nSatır, sütun ve bölgeler tamamlandı.',
          style: const TextStyle(fontFamily: 'Roboto', color: Colors.white70),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop(
                StudioGameResult.completed(
                  score: score,
                  stars: stars,
                  action: StudioResultAction.map,
                ).toParkurResult(),
              );
            },
            child: Text(_english ? 'LEVEL BOARD' : 'BÖLÜM PANOSU'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop(result.toParkurResult());
            },
            child: Text(
              widget.level.number < MiniSudokuGamePage.totalCases
                  ? (_english ? 'NEXT SUDOKU' : 'SONRAKİ SUDOKU')
                  : (_english ? 'LEVEL BOARD' : 'BÖLÜM PANOSU'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _english = context.l10n.isEnglish;
    final int stage = _puzzle.localStage;
    final List<int> conflicts = _conflictedIndices.toList(growable: false);
    final double width = MediaQuery.sizeOf(context).width;
    final double boardSize = math.min(width - 24, 440);

    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        toolbarHeight: 50,
        backgroundColor: _canvas,
        foregroundColor: _ink,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 8,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _english ? 'MINI SUDOKU 6×6' : 'MİNİ SUDOKU 6×6',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: .65,
              ),
            ),
            Text(
              '${_english ? 'PUZZLE' : 'BULMACA'} ${widget.level.number.toString().padLeft(3, '0')} · ${MiniSudokuGamePage._stageName(stage, english: _english)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: _muted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('mini_sudoku_undo'),
            onPressed: _undo.isEmpty ? null : _undoMove,
            tooltip: _english ? 'Undo' : 'Geri al',
            icon: const Icon(Icons.undo_rounded),
          ),
          IconButton(
            onPressed: _resetBoard,
            tooltip: _english ? 'Restart puzzle' : 'Bulmacayı sıfırla',
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveGameFrame(
          maxContentWidth: 560,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double availableWidth = math.min(
                constraints.maxWidth - 24,
                440,
              );
              final double compactBoardSize = math.min(
                availableWidth,
                math.max(240, constraints.maxHeight - 210),
              );
              return SingleChildScrollView(
                key: const ValueKey<String>('mini_sudoku_scroll'),
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                child: Column(
                  children: <Widget>[
                    _SudokuSummary(
                      filled: _filledCount,
                      fixed: _puzzle.givenCount,
                      conflicts: conflicts.length,
                      stage: stage,
                      moves: _moves,
                      english: _english,
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: SizedBox.square(
                        dimension: math.min(compactBoardSize, boardSize),
                        child: _MiniSudokuBoard(
                          values: _values,
                          notes: _notes,
                          givens: _initialGivens,
                          selectedIndex: _selectedIndex,
                          conflicts: conflicts.toSet(),
                          onSelect: _selectCell,
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    _BoardStatus(
                      selectedIndex: _selectedIndex,
                      value: _selectedIndex == null
                          ? 0
                          : _values[_selectedIndex!],
                      noteMode: _noteMode,
                      conflicts: conflicts.length,
                      english: _english,
                    ),
                    const SizedBox(height: 6),
                    _SudokuActionRow(
                      noteMode: _noteMode,
                      onUndo: _undo.isEmpty ? null : _undoMove,
                      onToggleNotes: _toggleNotes,
                      onClear: _clearSelected,
                      onHint: _hint,
                      english: _english,
                    ),
                    const SizedBox(height: 5),
                    _SudokuNumberPad(noteMode: _noteMode, onDigit: _enterDigit),
                    const SizedBox(height: 6),
                    FilledButton.icon(
                      key: const ValueKey<String>('mini_sudoku_check'),
                      onPressed: _checkBoard,
                      icon: const Icon(Icons.fact_check_outlined),
                      label: Text(
                        _english ? 'CHECK THE GRID' : 'TABLOYU KONTROL ET',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(
                          GameInputPolicy.minimumTargetSize + 4,
                        ),
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        textStyle: const TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w900,
                          letterSpacing: .4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _english
                          ? 'Every digit 1–6 appears once in each row, column and 2×3 region.'
                          : 'Her satırda, sütunda ve 2×3 bölgede 1–6 sayıları birer kez yer alır.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        color: _muted,
                        fontSize: 11,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SudokuSnapshot {
  const _SudokuSnapshot({
    required this.values,
    required this.notes,
    required this.selectedIndex,
  });

  final List<int> values;
  final List<Set<int>> notes;
  final int? selectedIndex;
}

class _SudokuSummary extends StatelessWidget {
  const _SudokuSummary({
    required this.filled,
    required this.fixed,
    required this.conflicts,
    required this.stage,
    required this.moves,
    required this.english,
  });

  final int filled;
  final int fixed;
  final int conflicts;
  final int stage;
  final int moves;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE2E8E4)),
    ),
    child: Row(
      children: <Widget>[
        const Icon(
          Icons.grid_on_rounded,
          size: 18,
          color: _MiniSudokuPlayPageState._accent,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            english
                ? '$filled / 36 filled · $fixed clues'
                : '$filled / 36 dolu · $fixed ipucu',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: _MiniSudokuPlayPageState._ink,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        _StageChip(stage: stage, english: english),
        if (conflicts > 0) ...<Widget>[
          const SizedBox(width: 6),
          Icon(
            Icons.error_outline_rounded,
            size: 15,
            color: _MiniSudokuPlayPageState._coral,
          ),
        ],
      ],
    ),
  );
}

class _StageChip extends StatelessWidget {
  const _StageChip({required this.stage, required this.english});

  final int stage;
  final bool english;

  @override
  Widget build(BuildContext context) {
    final Color accent = stage >= 9
        ? _MiniSudokuPlayPageState._coral
        : stage >= 7
        ? _MiniSudokuPlayPageState._brass
        : _MiniSudokuPlayPageState._accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${english ? 'STAGE' : 'AŞAMA'} ${stage.toString().padLeft(2, '0')}',
        style: TextStyle(
          fontFamily: 'Roboto',
          color: accent,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: .35,
        ),
      ),
    );
  }
}

class _MiniSudokuBoard extends StatelessWidget {
  const _MiniSudokuBoard({
    required this.values,
    required this.notes,
    required this.givens,
    required this.selectedIndex,
    required this.conflicts,
    required this.onSelect,
  });

  final List<int> values;
  final List<Set<int>> notes;
  final List<int> givens;
  final int? selectedIndex;
  final Set<int> conflicts;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(13),
    child: DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x12283640),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          GridView.builder(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: MiniSudokuPuzzle.cellCount,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MiniSudokuPuzzle.size,
            ),
            itemBuilder: (BuildContext context, int index) {
              final int row = index ~/ MiniSudokuPuzzle.size;
              final int column = index % MiniSudokuPuzzle.size;
              final int? selected = selectedIndex;
              final bool sameUnit =
                  selected != null &&
                  (row == selected ~/ MiniSudokuPuzzle.size ||
                      column == selected % MiniSudokuPuzzle.size ||
                      (row ~/ MiniSudokuPuzzle.boxHeight ==
                              (selected ~/ MiniSudokuPuzzle.size) ~/
                                  MiniSudokuPuzzle.boxHeight &&
                          column ~/ MiniSudokuPuzzle.boxWidth ==
                              (selected % MiniSudokuPuzzle.size) ~/
                                  MiniSudokuPuzzle.boxWidth));
              final bool sameNumber =
                  selected != null &&
                  values[selected] != 0 &&
                  values[index] == values[selected];
              return _SudokuCell(
                key: ValueKey<String>('mini_sudoku_cell_$index'),
                index: index,
                value: values[index],
                notes: notes[index],
                fixed: givens[index] != 0,
                selected: index == selected,
                sameUnit: sameUnit,
                sameNumber: sameNumber,
                conflict: conflicts.contains(index),
                onTap: () => onSelect(index),
              );
            },
          ),
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _SudokuGridPainter()),
            ),
          ),
        ],
      ),
    ),
  );
}

class _SudokuCell extends StatelessWidget {
  const _SudokuCell({
    super.key,
    required this.index,
    required this.value,
    required this.notes,
    required this.fixed,
    required this.selected,
    required this.sameUnit,
    required this.sameNumber,
    required this.conflict,
    required this.onTap,
  });

  final int index;
  final int value;
  final Set<int> notes;
  final bool fixed;
  final bool selected;
  final bool sameUnit;
  final bool sameNumber;
  final bool conflict;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color background = conflict
        ? const Color(0xFFF9E9E6)
        : selected
        ? const Color(0xFFDDEFE9)
        : sameNumber
        ? const Color(0xFFF5EBDD)
        : sameUnit
        ? const Color(0xFFF1F5F2)
        : Colors.white;
    final int row = index ~/ MiniSudokuPuzzle.size;
    final int column = index % MiniSudokuPuzzle.size;
    return Semantics(
      button: true,
      selected: selected,
      label:
          'Row ${row + 1}, column ${column + 1}, ${value == 0 ? 'empty' : value}',
      child: Material(
        color: background,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: value == 0
                ? _CandidateMarks(notes: notes)
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$value',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: conflict
                            ? _MiniSudokuPlayPageState._coral
                            : fixed
                            ? _MiniSudokuPlayPageState._ink
                            : _MiniSudokuPlayPageState._accent,
                        fontSize: 22,
                        height: 1,
                        fontWeight: fixed ? FontWeight.w900 : FontWeight.w800,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _CandidateMarks extends StatelessWidget {
  const _CandidateMarks({required this.notes});

  final Set<int> notes;

  @override
  Widget build(BuildContext context) => GridView.count(
    padding: const EdgeInsets.all(2),
    crossAxisCount: 3,
    physics: const NeverScrollableScrollPhysics(),
    children: <Widget>[
      for (int value = 1; value <= MiniSudokuPuzzle.size; value++)
        Center(
          child: Text(
            notes.contains(value) ? '$value' : '',
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: _MiniSudokuPlayPageState._muted,
              fontSize: 10,
              height: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
    ],
  );
}

class _SudokuGridPainter extends CustomPainter {
  const _SudokuGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double cellWidth = size.width / MiniSudokuPuzzle.size;
    final double cellHeight = size.height / MiniSudokuPuzzle.size;
    for (int line = 0; line <= MiniSudokuPuzzle.size; line++) {
      final bool majorHorizontal = line % MiniSudokuPuzzle.boxHeight == 0;
      final bool majorVertical = line % MiniSudokuPuzzle.boxWidth == 0;
      final Paint horizontal = Paint()
        ..color = _MiniSudokuPlayPageState._line.withValues(
          alpha: majorHorizontal ? .78 : .24,
        )
        ..strokeWidth = majorHorizontal ? 2.0 : .65;
      final Paint vertical = Paint()
        ..color = _MiniSudokuPlayPageState._line.withValues(
          alpha: majorVertical ? .78 : .24,
        )
        ..strokeWidth = majorVertical ? 2.0 : .65;
      canvas.drawLine(
        Offset(0, line * cellHeight),
        Offset(size.width, line * cellHeight),
        horizontal,
      );
      canvas.drawLine(
        Offset(line * cellWidth, 0),
        Offset(line * cellWidth, size.height),
        vertical,
      );
    }
  }

  @override
  bool shouldRepaint(_SudokuGridPainter oldDelegate) => false;
}

class _BoardStatus extends StatelessWidget {
  const _BoardStatus({
    required this.selectedIndex,
    required this.value,
    required this.noteMode,
    required this.conflicts,
    required this.english,
  });

  final int? selectedIndex;
  final int value;
  final bool noteMode;
  final int conflicts;
  final bool english;

  @override
  Widget build(BuildContext context) {
    final String text = conflicts > 0
        ? (english
              ? '$conflicts conflicting cells — review the red marks.'
              : '$conflicts çakışan hücre — kırmızı işaretleri gözden geçir.')
        : noteMode
        ? (english
              ? 'Pencil marks · choose candidates for the selected cell.'
              : 'Not modu · seçili hücre için adayları işaretle.')
        : selectedIndex == null
        ? (english
              ? 'Select an empty cell, then choose 1–6.'
              : 'Boş bir hücre seç, sonra 1–6 arasından yaz.')
        : value != 0
        ? (english
              ? 'Selected cell: $value · tap another cell to continue.'
              : 'Seçili hücre: $value · devam etmek için başka hücreye dokun.')
        : (english
              ? 'Selected cell ready · enter a value from 1 to 6.'
              : 'Seçili hücre hazır · 1–6 arasında bir sayı gir.');
    return SizedBox(
      height: 27,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Roboto',
            color: conflicts > 0
                ? _MiniSudokuPlayPageState._coral
                : _MiniSudokuPlayPageState._muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SudokuActionRow extends StatelessWidget {
  const _SudokuActionRow({
    required this.noteMode,
    required this.onUndo,
    required this.onToggleNotes,
    required this.onClear,
    required this.onHint,
    required this.english,
  });

  final bool noteMode;
  final VoidCallback? onUndo;
  final VoidCallback onToggleNotes;
  final VoidCallback onClear;
  final VoidCallback onHint;
  final bool english;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: _SudokuAction(
          key: const ValueKey<String>('mini_sudoku_undo_action'),
          icon: Icons.undo_rounded,
          label: english ? 'UNDO' : 'GERİ AL',
          onPressed: onUndo,
        ),
      ),
      const SizedBox(width: 5),
      Expanded(
        flex: 2,
        child: _SudokuAction(
          key: const ValueKey<String>('mini_sudoku_notes'),
          icon: Icons.edit_note_rounded,
          label: noteMode
              ? (english ? 'NOTES ON' : 'NOT AÇIK')
              : (english ? 'NOTES' : 'NOT'),
          selected: noteMode,
          onPressed: onToggleNotes,
        ),
      ),
      const SizedBox(width: 5),
      Expanded(
        child: _SudokuAction(
          key: const ValueKey<String>('mini_sudoku_clear'),
          icon: Icons.backspace_outlined,
          label: english ? 'CLEAR' : 'SİL',
          onPressed: onClear,
        ),
      ),
      const SizedBox(width: 5),
      Expanded(
        child: _SudokuAction(
          key: const ValueKey<String>('mini_sudoku_hint'),
          icon: Icons.lightbulb_outline_rounded,
          label: english ? 'HINT' : 'İPUCU',
          onPressed: onHint,
        ),
      ),
    ],
  );
}

class _SudokuAction extends StatelessWidget {
  const _SudokuAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? const Color(0xFFE0EEE9) : Colors.white,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: GameInputPolicy.minimumTargetSize,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 15, color: _MiniSudokuPlayPageState._accent),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: _MiniSudokuPlayPageState._ink,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
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

class _SudokuNumberPad extends StatelessWidget {
  const _SudokuNumberPad({required this.noteMode, required this.onDigit});

  final bool noteMode;
  final ValueChanged<int> onDigit;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      const double gap = 5;
      final double buttonWidth = (constraints.maxWidth - gap * 2) / 3;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: <Widget>[
          for (int digit = 1; digit <= MiniSudokuPuzzle.size; digit++)
            SizedBox(
              width: buttonWidth,
              height: GameInputPolicy.minimumTargetSize,
              child: _NumberKey(
                key: ValueKey<String>('mini_sudoku_num_$digit'),
                digit: digit,
                noteMode: noteMode,
                onTap: () => onDigit(digit),
              ),
            ),
        ],
      );
    },
  );
}

class _NumberKey extends StatelessWidget {
  const _NumberKey({
    super.key,
    required this.digit,
    required this.noteMode,
    required this.onTap,
  });

  final int digit;
  final bool noteMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E7E3)),
        ),
        child: Text(
          '$digit',
          style: TextStyle(
            fontFamily: 'Roboto',
            color: noteMode
                ? _MiniSudokuPlayPageState._brass
                : _MiniSudokuPlayPageState._accent,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    ),
  );
}
