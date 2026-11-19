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

  static ParkurLevelSpec levelSpec(int index) {
    final int safeLevel = GameContentPolicy.endlessHighChapter(index + 1);
    final int stage = ((safeLevel - 1) % 30) + 1;
    final String subtitleTr = stage <= 6
        ? '4×4 · 2×2 bölgeler · Kolay Isınma'
        : stage <= 19
        ? '6×6 · 2×3 bölgeler · Hız & Mantık'
        : '9×9 · 3×3 bölgeler · Klasik Sudoku';
    final String subtitleEn = stage <= 6
        ? '4×4 · 2×2 regions · Easy Warm-up'
        : stage <= 19
        ? '6×6 · 2×3 regions · Speed & Logic'
        : '9×9 · 3×3 regions · Classic Sudoku';

    return ParkurLevelSpec(
      number: index + 1,
      titleTr: '${stage <= 6 ? 'Mini Sudoku' : 'Sudoku'} ${'${index + 1}'.padLeft(2, '0')}',
      titleEn: '${stage <= 6 ? 'Mini Sudoku' : 'Sudoku'} ${'${index + 1}'.padLeft(2, '0')}',
      subtitleTr: subtitleTr,
      subtitleEn: subtitleEn,
      difficulty: _stageName(stage, english: false),
      icon: Icons.grid_on_rounded,
    );
  }

  static final List<ParkurLevelSpec> _levels = List<ParkurLevelSpec>.generate(
    totalCases,
    levelSpec,
  );

  static String _stageName(int stage, {required bool english}) =>
      switch (stage) {
        <= 6 => english ? 'FOUNDATION 4×4' : 'BAŞLANGIÇ 4×4',
        <= 12 => english ? 'EASY 6×6' : 'KOLAY 6×6',
        <= 19 => english ? 'MEDIUM 6×6' : 'GELİŞİM 6×6',
        <= 24 => english ? 'CLASSIC 9×9' : 'KLASİK 9×9',
        <= 28 => english ? 'EXPERT 9×9' : 'UZMAN 9×9',
        _ => english ? 'MASTER 9×9' : 'USTA 9×9',
      };

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forId('mini_sudoku');
    return ParkurLevelHub(
      gameId: 'mini_sudoku',
      progressPrefix: 'mini_sudoku',
      titleTr: 'Mini Su Doku',
      titleEn: 'Mini Sudoku 6×6',
      taglineTr: '1–6: 4×4 başlangıç, 7–19: 6×6 gelişim, 20+: klasik 9×9.',
      taglineEn: '1–6: 4×4 start, 7–19: 6×6 medium, 20+: classic 9×9.',
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
  late Set<int> _cachedConflicts;
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
    _notes = List<Set<int>>.generate(_puzzle.cellCount, (_) => <int>{});
    _selectedIndex = _initialGivens.indexWhere((int value) => value == 0);
    _recalculateConflicts();
    _session = StudioGameSession(
      level: widget.level.number,
      seed: widget.level.number,
    )..start();
    unawaited(_audioProfile.preload(_audio));
  }

  void _recalculateConflicts() {
    final Set<int> conflicts = <int>{};
    for (int index = 0; index < _values.length; index++) {
      final int value = _values[index];
      if (value == 0 || _initialGivens[index] != 0) continue;
      if (_puzzle.hasConflict(_values, index, value)) conflicts.add(index);
    }
    _cachedConflicts = conflicts;
  }

  int get _filledCount => _values.where((int value) => value != 0).length;
  int get _conflictCount => _cachedConflicts.length;
  bool get _isComplete => _filledCount == _puzzle.cellCount;

  void _selectCell(int index) {
    if (_finished || index < 0 || index >= _values.length) return;
    if (_selectedIndex == index) return;
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

    final bool hadConflictBefore = _cachedConflicts.contains(index);
    setState(() {
      _values[index] = digit;
      _notes[index].clear();
      _moves++;
      _selectedIndex = _nextEmptyAfter(index);
      _recalculateConflicts();
    });
    _session.recordAccepted();
    if (_cachedConflicts.contains(index) && !hadConflictBefore) {
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
      _recalculateConflicts();
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .24));
  }

  void _toggleNotes() {
    if (_finished) return;
    setState(() => _noteMode = !_noteMode);
    _audio.hapticSelection();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .22),
    );
  }

  void _undoMove() {
    if (_finished || _undo.isEmpty) return;
    final _SudokuSnapshot last = _undo.removeLast();
    setState(() {
      _values = List<int>.from(last.values);
      _notes = <Set<int>>[
        for (final Set<int> cellNotes in last.notes) Set<int>.from(cellNotes),
      ];
      _selectedIndex = last.selectedIndex;
      _moves++;
      _recalculateConflicts();
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .3));
  }

  void _hint() {
    if (_finished || !_session.canUseHint || _hints >= 3) return;

    int? candidateIndex;
    final int? current = _selectedIndex;
    if (current != null &&
        _initialGivens[current] == 0 &&
        _values[current] != _puzzle.solution[current]) {
      candidateIndex = current;
    } else {
      for (int index = 0; index < _puzzle.cellCount; index++) {
        if (_initialGivens[index] == 0 &&
            _values[index] != _puzzle.solution[index]) {
          candidateIndex = index;
          break;
        }
      }
    }

    if (candidateIndex == null) return;
    _saveUndo();
    final int target = _puzzle.solution[candidateIndex];
    setState(() {
      _values[candidateIndex!] = target;
      _notes[candidateIndex].clear();
      _selectedIndex = candidateIndex;
      _hints++;
      _moves++;
      _recalculateConflicts();
    });
    _session.useHint(pointCost: 160);
    _audio.hapticSelection();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .38));
    _showMessage(
      _english
          ? 'Hint placed: $target in cell ${candidateIndex + 1}.'
          : 'İpucu eklendi: ${candidateIndex + 1}. hücreye $target yerleştirildi.',
    );
  }

  void _resetBoard() {
    if (_finished) return;
    setState(() {
      _values = List<int>.from(_initialGivens);
      _notes = List<Set<int>>.generate(_puzzle.cellCount, (_) => <int>{});
      _selectedIndex = _initialGivens.indexWhere((int value) => value == 0);
      _undo.clear();
      _noteMode = false;
      _moves = 0;
      _hints = 0;
      _recalculateConflicts();
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .3));
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

  Future<void> _checkBoard() async {
    if (_finished) return;

    // Eğer boş hücrelerde tek bir taslak not varsa, kontrol anında
    // kullanıcıyı mağdur etmemek için otomatik olarak asıl sayıya dönüştür.
    bool promoted = false;
    for (int i = 0; i < _values.length; i++) {
      if (_values[i] == 0 && _notes[i].length == 1) {
        _values[i] = _notes[i].first;
        _notes[i].clear();
        promoted = true;
      }
    }
    if (promoted) {
      _recalculateConflicts();
      if (_isComplete) {
        _noteMode = false;
      }
      setState(() {});
    }

    if (!_isComplete) {
      final bool hasAnyNotes = _notes.any((Set<int> n) => n.isNotEmpty);
      _showMessage(
        hasAnyNotes
            ? (_english
                ? 'Some cells only have pencil notes. Turn off NOT mode to enter final numbers.'
                : 'Bazı hücrelerde sadece taslak notlar var. "NOT" modunu kapatıp sayıları kesinleştirin.')
            : (_english
                ? 'Fill all cells before checking the board.'
                : 'Kontrol etmeden önce tüm boşlukları doldur.'),
      );
      return;
    }
    if (_conflictCount > 0) {
      _session.recordMistake();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .38));
      _showMessage(
        _english
            ? 'There are conflicting numbers highlighted in red.'
            : 'Kırmızıyla işaretlenen çakışan sayılar var.',
      );
      return;
    }
    if (_puzzle.isSolved(_values)) {
      await _complete();
    } else {
      _session.recordMistake();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .38));
      _showMessage(
        _english
            ? 'Some numbers do not match the unique solution.'
            : 'Bazı sayılar benzersiz çözümle uyuşmuyor.',
      );
    }
  }

  Future<void> _complete() async {
    if (_finished) return;
    _finished = true;
    final int mistakes = _session.mistakes;
    final int stars = _hints == 0 && mistakes == 0
        ? 3
        : _hints <= 1 && mistakes <= 2
        ? 2
        : 1;
    final int score = math.max(
      220,
      2100 -
          math.max(0, _moves - _puzzle.blankCount) * 14 -
          mistakes * 65 -
          _hints * 190,
    );
    _session.recordAccepted(points: score);
    final StudioGameResult result = _session.complete(
      stars: stars,
      action: widget.level.number < MiniSudokuGamePage.totalCases
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
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: _ink,
        icon: const Icon(Icons.grid_on_rounded, color: Color(0xFFE8C99B)),
        title: Text(
          context.l10n.gameUi(
            _english ? 'SUDOKU COMPLETED' : 'SUDOKU TAMAMLANDI',
          ),
          style: const TextStyle(
            fontFamily: 'Roboto',
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          context.l10n.gameUi(
            _english
                ? '$stars stars  •  $score points\nEvery row, column, and box is uniquely solved.'
                : '$stars yıldız  •  $score puan\nTüm satırlar, sütunlar ve bölgeler benzersiz tamamlandı.',
          ),
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
            child: Text(context.l10n.gameUi(_english ? 'MAP' : 'PARKUR')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop(result.toParkurResult());
            },
            child: Text(
              context.l10n.gameUi(
                widget.level.number < MiniSudokuGamePage.totalCases
                    ? (_english ? 'NEXT PUZZLE' : 'SONRAKİ BULMACA')
                    : (_english ? 'LEVEL BOARD' : 'BÖLÜM PANOSU'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHowToPlay() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.help_outline_rounded, color: _accent, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _english ? 'HOW TO PLAY SUDOKU?' : 'SUDOKU NASIL OYNANIR?',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: _ink,
                      ),
                    ),
                  ),
                  IconButton(
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _english
                    ? '• 4×4 Boards (Levels 1–6): Fill digits 1–4 so each row, column, and 2×2 box contains no repeats.\n• 6×6 Boards (Levels 7–19): Fill digits 1–6 in 2×3 regions.\n• 9×9 Boards (Levels 20+): Classic Sudoku with digits 1–9 and 3×3 regions.\n• Tap any cell to select it instantly, then tap a number below.\n• Use "NOTE" mode to write small candidate numbers.'
                    : '• 4×4 Izgara (1–6. Seviyeler): 1–4 arası rakamları her satır, sütun ve 2×2 bölgede bir kez kullanın.\n• 6×6 Izgara (7–19. Seviyeler): 1–6 arası rakamları 2×3 bölgelerde kullanın.\n• 9×9 Izgara (20+. Seviyeler): 1–9 arası rakamlarla klasik 3×3 Sudoku.\n• Hücreye dokununca gecikmesiz seçilir; alttaki klavyeden sayıyı girin.\n• İhtimalleri yazmak için "NOT" modunu kullanabilirsiniz.',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  height: 1.5,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _english
                    ? 'Current Grid: ${_puzzle.size}×${_puzzle.size}  •  ${_puzzle.difficultyTier}'
                    : 'Mevcut Izgara: ${_puzzle.size}×${_puzzle.size}  •  ${_puzzle.difficultyTier}',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _english = context.l10n.isEnglish;
    final int stage = _puzzle.localStage;

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
              context.l10n.gameUi(
                _english
                    ? '${_puzzle.size <= 6 ? 'MINI ' : ''}SUDOKU ${_puzzle.size}×${_puzzle.size}'
                    : '${_puzzle.size <= 6 ? 'MİNİ ' : ''}SU DOKU ${_puzzle.size}×${_puzzle.size}',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: .65,
              ),
            ),
            Text(
              '${context.l10n.gameUi(_english ? 'PUZZLE' : 'BULMACA')} ${widget.level.number.toString().padLeft(3, '0')} · ${context.l10n.gameUi(_puzzle.difficultyTier)}',
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
            onPressed: _showHowToPlay,
            tooltip: _english ? 'How to play' : 'Nasıl oynanır',
            icon: const Icon(Icons.help_outline_rounded),
          ),
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
                constraints.maxWidth - 20,
                420,
              );
              final double maxBoardHeight = constraints.maxHeight - 215;
              final double fittedBoardSize = math.min(
                availableWidth,
                math.max(200, maxBoardHeight),
              );
              return SingleChildScrollView(
                key: const ValueKey<String>('mini_sudoku_scroll'),
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
                child: Column(
                  children: <Widget>[
                    _SudokuSummary(
                      filled: _filledCount,
                      fixed: _puzzle.givenCount,
                      size: _puzzle.size,
                      conflicts: _conflictCount,
                      stage: stage,
                      moves: _moves,
                      english: _english,
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: SizedBox.square(
                        dimension: fittedBoardSize,
                        child: _MiniSudokuBoard(
                          values: _values,
                          notes: _notes,
                          givens: _initialGivens,
                          size: _puzzle.size,
                          boxHeight: _puzzle.boxHeight,
                          boxWidth: _puzzle.boxWidth,
                          selectedIndex: _selectedIndex,
                          conflicts: _cachedConflicts,
                          onSelect: _selectCell,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    _BoardStatus(
                      selectedIndex: _selectedIndex,
                      value: _selectedIndex == null
                          ? 0
                          : _values[_selectedIndex!],
                      maxDigit: _puzzle.size,
                      noteMode: _noteMode,
                      conflicts: _conflictCount,
                      english: _english,
                    ),
                    const SizedBox(height: 5),
                    _SudokuActionRow(
                      noteMode: _noteMode,
                      onUndo: _undo.isEmpty ? null : _undoMove,
                      onToggleNotes: _toggleNotes,
                      onClear: _clearSelected,
                      onHint: _hint,
                      english: _english,
                    ),
                    const SizedBox(height: 6),
                    _SudokuNumberPad(
                      size: _puzzle.size,
                      noteMode: _noteMode,
                      onDigit: _enterDigit,
                    ),
                    const SizedBox(height: 6),
                    FilledButton.icon(
                      key: const ValueKey<String>('mini_sudoku_check'),
                      onPressed: _checkBoard,
                      icon: const Icon(Icons.fact_check_outlined, size: 18),
                      label: Text(
                        context.l10n.gameUi(
                          _english ? 'CHECK THE GRID' : 'TABLOYU KONTROL ET',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(40),
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: .4,
                        ),
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
    required this.size,
    required this.conflicts,
    required this.stage,
    required this.moves,
    required this.english,
  });

  final int filled;
  final int fixed;
  final int size;
  final int conflicts;
  final int stage;
  final int moves;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8E4)),
    ),
    child: Row(
      children: <Widget>[
        const Icon(
          Icons.grid_on_rounded,
          size: 16,
          color: _MiniSudokuPlayPageState._accent,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            context.l10n.gameUi(
              english
                  ? '$filled / ${size * size} filled · $fixed clues'
                  : '$filled / ${size * size} dolu · $fixed ipucu',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: _MiniSudokuPlayPageState._ink,
            ),
          ),
        ),
        if (conflicts > 0) ...<Widget>[
          const SizedBox(width: 6),
          Text(
            context.l10n.gameUi(
              english ? '$conflicts conflict' : '$conflicts çakışma',
            ),
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: _MiniSudokuPlayPageState._coral,
            ),
          ),
        ],
        const SizedBox(width: 6),
        _StageBadge(stage: stage, english: english),
      ],
    ),
  );
}

class _StageBadge extends StatelessWidget {
  const _StageBadge({required this.stage, required this.english});

  final int stage;
  final bool english;

  @override
  Widget build(BuildContext context) {
    final Color accent = stage <= 6
        ? const Color(0xFF2E7D32)
        : stage <= 19
        ? _MiniSudokuPlayPageState._accent
        : _MiniSudokuPlayPageState._coral;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        context.l10n.gameUi(
          '${english ? 'STAGE' : 'AŞAMA'} ${stage.toString().padLeft(2, '0')}',
        ),
        style: TextStyle(
          fontFamily: 'Roboto',
          color: accent,
          fontSize: 11,
          fontWeight: FontWeight.w900,
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
    required this.size,
    required this.boxHeight,
    required this.boxWidth,
    required this.selectedIndex,
    required this.conflicts,
    required this.onSelect,
  });

  final List<int> values;
  final List<Set<int>> notes;
  final List<int> givens;
  final int size;
  final int boxHeight;
  final int boxWidth;
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
            itemCount: values.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: size,
            ),
            itemBuilder: (BuildContext context, int index) {
              final int row = index ~/ size;
              final int column = index % size;
              final int? selected = selectedIndex;
              final bool sameUnit =
                  selected != null &&
                  (row == selected ~/ size ||
                      column == selected % size ||
                      (row ~/ boxHeight == (selected ~/ size) ~/ boxHeight &&
                          column ~/ boxWidth == (selected % size) ~/ boxWidth));
              final bool sameNumber =
                  selected != null &&
                  values[selected] != 0 &&
                  values[index] == values[selected];
              return _SudokuCell(
                key: ValueKey<String>('mini_sudoku_cell_$index'),
                index: index,
                size: size,
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
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _SudokuGridPainter(
                  size: size,
                  boxHeight: boxHeight,
                  boxWidth: boxWidth,
                ),
              ),
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
    required this.size,
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
  final int size;
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
    final int row = index ~/ size;
    final int column = index % size;
    return Semantics(
      button: true,
      selected: selected,
      label:
          'Row ${row + 1}, column ${column + 1}, ${value == 0 ? 'empty' : value}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => onTap(),
        child: Container(
          color: background,
          child: Center(
            child: value == 0
                ? _CandidateMarks(notes: notes, size: size)
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
                        fontSize: size == 4 ? 26 : (size == 6 ? 22 : 18),
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
  const _CandidateMarks({required this.notes, required this.size});

  final Set<int> notes;
  final int size;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) return const SizedBox.shrink();
    final int subSize = size == 4 ? 2 : 3;
    return Padding(
      padding: const EdgeInsets.all(2),
      child: GridView.count(
        crossAxisCount: subSize,
        physics: const NeverScrollableScrollPhysics(),
        children: <Widget>[
          for (int digit = 1; digit <= size; digit++)
            Center(
              child: Text(
                notes.contains(digit) ? '$digit' : '',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: size == 4 ? 11 : (size == 6 ? 8.5 : 7.5),
                  fontWeight: FontWeight.w800,
                  color: _MiniSudokuPlayPageState._line,
                  height: 1,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SudokuGridPainter extends CustomPainter {
  const _SudokuGridPainter({
    required this.size,
    required this.boxHeight,
    required this.boxWidth,
  });

  final int size;
  final int boxHeight;
  final int boxWidth;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final double step = canvasSize.width / size;
    final Paint thin = Paint()
      ..color = const Color(0xFFD3DDD7)
      ..strokeWidth = 1.0;
    final Paint thick = Paint()
      ..color = _MiniSudokuPlayPageState._ink.withValues(alpha: 0.65)
      ..strokeWidth = 2.4;

    for (int line = 1; line < size; line++) {
      final double position = line * step;
      final bool thickCol = line % boxWidth == 0;
      final bool thickRow = line % boxHeight == 0;

      canvas.drawLine(
        Offset(position, 0),
        Offset(position, canvasSize.height),
        thickCol ? thick : thin,
      );
      canvas.drawLine(
        Offset(0, position),
        Offset(canvasSize.width, position),
        thickRow ? thick : thin,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SudokuGridPainter oldDelegate) =>
      oldDelegate.size != size ||
      oldDelegate.boxHeight != boxHeight ||
      oldDelegate.boxWidth != boxWidth;
}

class _BoardStatus extends StatelessWidget {
  const _BoardStatus({
    required this.selectedIndex,
    required this.value,
    required this.maxDigit,
    required this.noteMode,
    required this.conflicts,
    required this.english,
  });

  final int? selectedIndex;
  final int value;
  final int maxDigit;
  final bool noteMode;
  final int conflicts;
  final bool english;

  @override
  Widget build(BuildContext context) {
    final String text;
    if (selectedIndex == null) {
      text = context.l10n.gameUi(
        english
            ? 'Tap a cell to place a number.'
            : 'Sayı girmek için bir hücreye dokun.',
      );
    } else if (value != 0) {
      text = context.l10n.gameUi(
        english
            ? 'Selected: $value. Tap another number to change.'
            : 'Seçili: $value. Değiştirmek için başka sayıya dokun.',
      );
    } else if (noteMode) {
      text = context.l10n.gameUi(
        english
            ? 'Note mode active: toggle candidate numbers.'
            : 'Not modu aktif: olası sayıları ekle/kaldır.',
      );
    } else {
      text = context.l10n.gameUi(
        english
            ? 'Cell ready: enter 1–$maxDigit.'
            : 'Seçili hücre hazır · 1–$maxDigit arasında bir sayı gir.',
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: noteMode
              ? _MiniSudokuPlayPageState._brass.withValues(alpha: 0.5)
              : const Color(0xFFE2E7E4),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: noteMode
              ? _MiniSudokuPlayPageState._brass
              : _MiniSudokuPlayPageState._muted,
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
        child: _MiniActionButton(
          key: const ValueKey<String>('mini_sudoku_undo_btn'),
          icon: Icons.undo_rounded,
          label: context.l10n.gameUi(english ? 'UNDO' : 'GERİ AL'),
          onTap: onUndo,
        ),
      ),
      const SizedBox(width: 4),
      Expanded(
        child: _MiniActionButton(
          key: const ValueKey<String>('mini_sudoku_notes'),
          icon: Icons.edit_note_rounded,
          label: context.l10n.gameUi(english ? 'NOTE' : 'NOT'),
          active: noteMode,
          onTap: onToggleNotes,
        ),
      ),
      const SizedBox(width: 4),
      Expanded(
        child: _MiniActionButton(
          key: const ValueKey<String>('mini_sudoku_clear'),
          icon: Icons.backspace_outlined,
          label: context.l10n.gameUi(english ? 'CLEAR' : 'SİL'),
          onTap: onClear,
        ),
      ),
      const SizedBox(width: 4),
      Expanded(
        child: _MiniActionButton(
          key: const ValueKey<String>('mini_sudoku_hint'),
          icon: Icons.lightbulb_outline_rounded,
          label: context.l10n.gameUi(english ? 'HINT' : 'İPUCU'),
          onTap: onHint,
        ),
      ),
    ],
  );
}

class _MiniActionButton extends StatelessWidget {
  const _MiniActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.active = false,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg = active
        ? _MiniSudokuPlayPageState._brass
        : Colors.white;
    final Color fg = active
        ? Colors.white
        : onTap == null
        ? const Color(0xFFACB7B2)
        : _MiniSudokuPlayPageState._ink;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: active
                  ? _MiniSudokuPlayPageState._brass
                  : const Color(0xFFDCE5E0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 15, color: fg),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: fg,
                    letterSpacing: .3,
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

class _SudokuNumberPad extends StatelessWidget {
  const _SudokuNumberPad({
    required this.size,
    required this.noteMode,
    required this.onDigit,
  });

  final int size;
  final bool noteMode;
  final ValueChanged<int> onDigit;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final double gap = size == 9 ? 3.5 : (size == 6 ? 5.0 : 8.0);
      final double buttonWidth =
          (constraints.maxWidth - (size - 1) * gap) / size;
      final double buttonHeight = size == 9 ? 42.0 : (size == 6 ? 46.0 : 50.0);
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          for (int digit = 1; digit <= size; digit++)
            SizedBox(
              width: buttonWidth,
              height: buttonHeight,
              child: _NumberKey(
                key: ValueKey<String>('mini_sudoku_num_$digit'),
                digit: digit,
                noteMode: noteMode,
                fontSize: size == 4 ? 22 : (size == 6 ? 19 : 16),
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
    this.fontSize = 18,
    required this.onTap,
  });

  final int digit;
  final bool noteMode;
  final double fontSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTapDown: (_) => onTap(),
    child: Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: noteMode
              ? _MiniSudokuPlayPageState._brass.withValues(alpha: 0.6)
              : const Color(0xFFDCE5E0),
          width: noteMode ? 1.5 : 1.0,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 3,
            offset: Offset(0, 1.5),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '$digit',
          style: TextStyle(
            fontFamily: 'Roboto',
            color: noteMode
                ? _MiniSudokuPlayPageState._brass
                : _MiniSudokuPlayPageState._accent,
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    ),
  );
}
