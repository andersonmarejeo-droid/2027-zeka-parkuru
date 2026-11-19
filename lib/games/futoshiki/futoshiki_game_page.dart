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
import 'futoshiki_puzzle.dart';

class FutoshikiGamePage extends StatelessWidget {
  const FutoshikiGamePage({
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
    GameContentPolicy.nativeStages('futoshiki'),
    (int index) {
      final int level = index + 1;
      final int stage = index % 10 + 1;
      final int chapter = index ~/ 10 + 1;
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Futoshiki ${level.toString().padLeft(2, '0')}',
        titleEn: 'Futoshiki ${level.toString().padLeft(2, '0')}',
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
          ? 'Read denser comparison chains with fewer starting values.'
          : 'Daha az başlangıç sayısıyla yoğun eşitsizlik zincirlerini çöz.';
    }
    return switch (stage) {
      <= 3 =>
        english
            ? 'Use each value once in every row and column.'
            : 'Her sayıyı satır ve sütunda bir kez kullan.',
      <= 6 =>
        english
            ? 'Combine the Latin-square rule with adjacent comparisons.'
            : 'Latin-kare kuralını komşu eşitsizliklerle birleştir.',
      7 || 8 =>
        english
            ? 'Advanced: infer values from intersecting comparison chains.'
            : 'İleri: kesişen eşitsizlik zincirlerinden değer çıkar.',
      9 =>
        english
            ? 'Expert: move to a six-value grid with fewer givens.'
            : 'Uzman: daha az başlangıç ipucuyla altı sayılı ızgaraya geç.',
      _ =>
        english
            ? 'Master grid: prove every row, column and inequality together.'
            : 'Usta ızgarası: satır, sütun ve eşitsizlikleri birlikte kanıtla.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forId('futoshiki');
    return ParkurLevelHub(
      gameId: 'futoshiki',
      progressPrefix: 'futoshiki',
      titleTr: 'Futoshiki',
      titleEn: 'Futoshiki',
      taglineTr: 'Sayıları yerleştir • Eşitsizlikleri kanıtla',
      taglineEn: 'Place each value • Prove every inequality',
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
          ) => FutoshikiPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class FutoshikiPlayPage extends StatefulWidget {
  const FutoshikiPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<FutoshikiPlayPage> createState() => _FutoshikiPlayPageState();
}

class _FutoshikiPlayPageState extends State<FutoshikiPlayPage> {
  static const Color _accent = Color(0xFF247568);
  static const Color _gold = Color(0xFFC39B56);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.numbers,
  );
  final List<List<int>> _undoStack = <List<int>>[];

  late FutoshikiPuzzle _puzzle;
  late List<int> _cells;
  late StudioGameSession _session;
  int? _selectedCell;
  int _hints = 0;
  int _mistakes = 0;
  bool _ready = false;
  bool _finished = false;
  bool _english = false;
  String? _notice;

  int get _emptyCount => _cells.where((int value) => value == 0).length;
  int get _score => math.max(0, 5000 - _hints * 340 - _mistakes * 190);
  int get _stars => _hints == 0 && _mistakes == 0
      ? 3
      : _hints <= 2 && _mistakes <= 2
      ? 2
      : 1;

  Set<int> get _invalidCells {
    final Set<int> invalid = <int>{};
    final int size = _puzzle.size;
    for (int row = 0; row < size; row++) {
      for (int first = 0; first < size; first++) {
        final int value = _cells[row * size + first];
        if (value == 0) continue;
        for (int second = first + 1; second < size; second++) {
          if (_cells[row * size + second] == value) {
            invalid
              ..add(row * size + first)
              ..add(row * size + second);
          }
        }
      }
    }
    for (int column = 0; column < size; column++) {
      for (int first = 0; first < size; first++) {
        final int value = _cells[first * size + column];
        if (value == 0) continue;
        for (int second = first + 1; second < size; second++) {
          if (_cells[second * size + column] == value) {
            invalid
              ..add(first * size + column)
              ..add(second * size + column);
          }
        }
      }
    }
    for (final FutoshikiRelation relation in _puzzle.relations) {
      final int lesser = _cells[relation.lessCell];
      final int greater = _cells[relation.greaterCell];
      if (lesser > 0 && greater > 0 && lesser >= greater) {
        invalid
          ..add(relation.lessCell)
          ..add(relation.greaterCell);
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
    FutoshikiPuzzle puzzle = (widget.level.poolIndex != null
        ? FutoshikiPuzzle.forPracticeBoard(widget.level.contentIndex)
        : FutoshikiPuzzle.forLevel(widget.level.contentLevel));
    try {
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      final String visitKey = 'futoshiki_level_${widget.level.number}_visits';
      final int visits = await preferences.getInt(visitKey) ?? 0;
      if (widget.level.poolIndex == null && visits > 0) {
        final int index =
            await preferences.getInt('futoshiki_practice_index') ?? 0;
        if (index < FutoshikiPuzzle.maximumVerifiedBoards) {
          final int next = index + 1;
          await preferences.setInt('futoshiki_practice_index', next);
          puzzle = FutoshikiPuzzle.forPracticeBoard(next);
        }
      }
      await preferences.setInt(visitKey, visits + 1);
    } catch (_) {
      puzzle = (widget.level.poolIndex != null
          ? FutoshikiPuzzle.forPracticeBoard(widget.level.contentIndex)
          : FutoshikiPuzzle.forLevel(widget.level.contentLevel));
    }
    if (!mounted) return;
    setState(() {
      _puzzle = puzzle;
      _cells = <int>[for (final int? given in puzzle.givens) given ?? 0];
      _session = StudioGameSession(
        level: widget.level.number,
        seed: puzzle.seed,
      )..start();
      _undoStack.clear();
      _selectedCell = null;
      _hints = 0;
      _mistakes = 0;
      _notice = null;
      _finished = false;
      _ready = true;
    });
  }

  void _selectCell(int index) {
    if (!_ready || _finished || !_session.acceptsInput) return;
    setState(() {
      _selectedCell = index;
      _notice = _puzzle.givens[index] != null
          ? (_english
                ? 'This starting value is locked.'
                : 'Başlangıç sayısı sabittir.')
          : (_english
                ? 'Choose a value that fits its row, column and comparison signs.'
                : 'Satır, sütun ve eşitsizlik işaretlerine uyan sayıyı seç.');
    });
    _audio.hapticSelection();
  }

  void _remember() {
    _undoStack.add(List<int>.of(_cells));
    if (_undoStack.length > 80) _undoStack.removeAt(0);
  }

  void _enterValue(int value) {
    final int? selected = _selectedCell;
    if (!_ready || _finished || selected == null) return;
    if (_puzzle.givens[selected] != null) {
      setState(() {
        _notice = _english
            ? 'Starting values cannot be changed.'
            : 'Başlangıç sayıları değiştirilemez.';
      });
      return;
    }
    _remember();
    setState(() {
      _cells[selected] = value;
      _notice = _invalidCells.isEmpty
          ? (_english ? 'Value placed.' : 'Sayı yerleştirildi.')
          : (_english
                ? 'This value conflicts with a row, column or inequality.'
                : 'Bu sayı satır, sütun veya eşitsizlikle çakışıyor.');
    });
    _audio.hapticLight();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .18));
  }

  void _clearSelected() {
    final int? selected = _selectedCell;
    if (selected == null || _puzzle.givens[selected] != null || _finished) {
      return;
    }
    if (_cells[selected] == 0) return;
    _remember();
    setState(() {
      _cells[selected] = 0;
      _notice = _english ? 'Value removed.' : 'Sayı silindi.';
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .18));
  }

  void _undo() {
    if (_undoStack.isEmpty || _finished) return;
    setState(() {
      _cells = _undoStack.removeLast();
      _notice = _english ? 'Last change undone.' : 'Son işlem geri alındı.';
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .2));
  }

  void _showHint() {
    if (!_ready || _finished || !_session.canUseHint) return;
    int target = _selectedCell ?? -1;
    if (target < 0 || _cells[target] != 0 || _puzzle.givens[target] != null) {
      target = _cells.indexWhere((int value) => value == 0);
    }
    if (target < 0) return;
    _remember();
    _session.useHint(pointCost: 340);
    _hints++;
    setState(() {
      _selectedCell = target;
      _cells[target] = _puzzle.solution[target];
      _notice = _english
          ? 'Certified hint: row ${target ~/ _puzzle.size + 1}, column ${target % _puzzle.size + 1} is ${_cells[target]}.'
          : 'Doğrulanmış ipucu: ${target ~/ _puzzle.size + 1}. satır, ${target % _puzzle.size + 1}. sütun ${_cells[target]} olmalı.';
    });
    _audio.hapticSelection();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .22));
  }

  void _checkBoard() {
    if (!_ready || _finished) return;
    if (_emptyCount > 0) {
      setState(() {
        _notice = _english
            ? 'Fill every empty cell before checking the grid.'
            : 'Izgarayı kontrol etmeden önce tüm boş hücreleri doldur.';
      });
      _audio.hapticLight();
      return;
    }
    if (_invalidCells.isNotEmpty) {
      _mistakes++;
      setState(() {
        _notice = _english
            ? 'Resolve the highlighted row, column or inequality conflict.'
            : 'Vurgulanan satır, sütun veya eşitsizlik çakışmasını düzelt.';
      });
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .2));
      return;
    }
    if (_puzzle.matches(<int?>[..._cells])) {
      _session.recordAccepted(points: 60);
      unawaited(_finish());
      return;
    }
    _mistakes++;
    setState(() {
      _notice = _english
          ? 'Re-read the comparison chains. One value still breaks the certified grid.'
          : 'Eşitsizlik zincirlerini yeniden oku; bir değer doğrulanmış ızgarayla uyuşmuyor.';
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .2));
  }

  Future<void> _confirmReset() async {
    if (!_ready || _finished) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(
          _english ? 'Reset this grid?' : 'Bu ızgara sıfırlansın mı?',
        ),
        content: Text(
          _english
              ? 'The same clues and inequalities will be restored.'
              : 'Aynı başlangıç ipuçları ve eşitsizlikler geri yüklenecek.',
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
      _cells = <int>[for (final int? given in _puzzle.givens) given ?? 0];
      _undoStack.clear();
      _selectedCell = null;
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
      action: widget.level.number < FutoshikiGamePage.totalCases
          ? StudioResultAction.next
          : StudioResultAction.map,
    );
    unawaited(
      _audioProfile.play(
        _audio,
        GameAudioEvent.levelComplete,
        levelNumber: widget.level.number,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    final ParkurResultAction? result = await showParkurResultDialog(
      context: context,
      accent: _accent,
      titleTr: 'EŞİTSİZLİKLER ÇÖZÜLDÜ',
      titleEn: 'INEQUALITIES SOLVED',
      detailTr:
          '${_puzzle.size}×${_puzzle.size} ızgara · ${_puzzle.horizontalAndVerticalRelations} eşitsizlik.',
      detailEn:
          '${_puzzle.size}×${_puzzle.size} grid · ${_puzzle.horizontalAndVerticalRelations} inequalities.',
      stars: stars,
      score: score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < FutoshikiGamePage.totalCases,
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
          title: const Text('FUTOSHIKI'),
        ),
        body: const Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    final Set<int> invalid = _invalidCells;
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 14,
        title: const Text(
          'FUTOSHIKI',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Center(
              child: _FutoshikiLevelPill(level: widget.level.number),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints _) => Padding(
            padding: const EdgeInsets.fromLTRB(12, 3, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _FutoshikiStatus(
                  level: widget.level.number,
                  tier: _puzzle.difficultyTier,
                  size: _puzzle.size,
                  emptyCount: _emptyCount,
                  relationCount: _puzzle.horizontalAndVerticalRelations,
                  english: _english,
                ),
                const SizedBox(height: 6),
                _FutoshikiInstruction(
                  english: _english,
                  size: _puzzle.size,
                  notice: _notice,
                  warning: invalid.isNotEmpty || _mistakes > 0,
                ),
                const SizedBox(height: 6),
                Expanded(
                  flex: 4,
                  child: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints boardSpace) {
                      final double side = math.min(
                        boardSpace.maxWidth,
                        boardSpace.maxHeight,
                      );
                      return Center(
                        child: SizedBox.square(
                          dimension: side,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Container(
                              key: const ValueKey<String>(
                                'futoshiki_board_frame',
                              ),
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE7E4DC),
                                borderRadius: BorderRadius.circular(17),
                                border: Border.all(
                                  color: const Color(0xFFD9D6CD),
                                ),
                                boxShadow: StudioVisuals.softShadow,
                              ),
                              child: _FutoshikiBoard(
                                key: const ValueKey<String>('futoshiki_board'),
                                puzzle: _puzzle,
                                cells: _cells,
                                selectedCell: _selectedCell,
                                invalidCells: invalid,
                                accent: _accent,
                                english: _english,
                                onTapCell: _selectCell,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 6),
                _FutoshikiKeypad(
                  size: _puzzle.size,
                  enabled: !_finished && _selectedCell != null,
                  selectedValue: _selectedCell == null
                      ? 0
                      : _cells[_selectedCell!],
                  english: _english,
                  onValue: _enterValue,
                  onClear: _clearSelected,
                ),
                const SizedBox(height: 6),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 5,
                  children: <Widget>[
                    _FutoshikiTool(
                      key: const ValueKey<String>('futoshiki_undo'),
                      icon: Icons.undo_rounded,
                      label: _english ? 'Undo' : 'Geri al',
                      enabled: _undoStack.isNotEmpty && !_finished,
                      onPressed: _undo,
                    ),
                    _FutoshikiTool(
                      key: const ValueKey<String>('futoshiki_hint'),
                      icon: Icons.lightbulb_outline_rounded,
                      label: _english ? 'Hint' : 'İpucu',
                      enabled: !_finished,
                      onPressed: _showHint,
                    ),
                    _FutoshikiTool(
                      key: const ValueKey<String>('futoshiki_reset'),
                      icon: Icons.restart_alt_rounded,
                      label: _english ? 'Reset' : 'Sıfırla',
                      enabled: !_finished,
                      onPressed: _confirmReset,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 44,
                  child: FilledButton.icon(
                    key: const ValueKey<String>('futoshiki_check'),
                    onPressed: _finished ? null : _checkBoard,
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    icon: const Icon(Icons.fact_check_outlined),
                    label: Text(
                      _english ? 'Check the grid' : 'Izgarayı kontrol et',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _english
                      ? 'Use every value once in each row and column. A rotated < sign points to the smaller value.'
                      : 'Her sayıyı satır ve sütunda bir kez kullan. Döndürülmüş < işareti küçük sayıyı gösterir.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: Color(0xFF6B7472),
                    fontSize: 10,
                    height: 1.15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FutoshikiBoard extends StatelessWidget {
  const _FutoshikiBoard({
    super.key,
    required this.puzzle,
    required this.cells,
    required this.selectedCell,
    required this.invalidCells,
    required this.accent,
    required this.english,
    required this.onTapCell,
  });

  final FutoshikiPuzzle puzzle;
  final List<int> cells;
  final int? selectedCell;
  final Set<int> invalidCells;
  final Color accent;
  final bool english;
  final ValueChanged<int> onTapCell;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      const double gap = 2;
      final int size = puzzle.size;
      final double cell = math.min(
        64,
        (constraints.maxWidth - (size - 1) * gap) / size,
      );
      final double boardSize = size * cell + (size - 1) * gap;
      final Set<int> related = <int>{
        if (selectedCell != null)
          for (int other = 0; other < size * size; other++)
            if (other != selectedCell &&
                (other ~/ size == selectedCell! ~/ size ||
                    other % size == selectedCell! % size))
              other,
      };
      return SizedBox(
        key: const ValueKey<String>('futoshiki_board_surface'),
        width: boardSize,
        height: boardSize,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: CustomPaint(
                painter: _FutoshikiBoardPainter(
                  puzzle: puzzle,
                  cells: cells,
                  selectedCell: selectedCell,
                  relatedCells: related,
                  invalidCells: invalidCells,
                  accent: accent,
                  cellSize: cell,
                  gap: gap,
                ),
              ),
            ),
            for (int index = 0; index < size * size; index++)
              Positioned(
                left: (index % size) * (cell + gap),
                top: (index ~/ size) * (cell + gap),
                width: cell,
                height: cell,
                child: Semantics(
                  button: true,
                  onTap: () => onTapCell(index),
                  selected: index == selectedCell,
                  label: _cellSemantics(index),
                  excludeSemantics: true,
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      key: ValueKey<String>('futoshiki_cell_$index'),
                      borderRadius: BorderRadius.circular(9),
                      onTap: () => onTapCell(index),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );

  String _cellSemantics(int index) {
    final int? value = puzzle.givens[index];
    final int current = cells[index];
    return english
        ? 'Row ${index ~/ puzzle.size + 1}, column ${index % puzzle.size + 1}, ${value != null
              ? 'starting value $value'
              : current == 0
              ? 'empty'
              : 'value $current'}'
        : '${index ~/ puzzle.size + 1}. satır, ${index % puzzle.size + 1}. sütun, ${value != null
              ? 'başlangıç sayısı $value'
              : current == 0
              ? 'boş'
              : '$current sayısı'}';
  }
}

class _FutoshikiBoardPainter extends CustomPainter {
  const _FutoshikiBoardPainter({
    required this.puzzle,
    required this.cells,
    required this.selectedCell,
    required this.relatedCells,
    required this.invalidCells,
    required this.accent,
    required this.cellSize,
    required this.gap,
  });

  final FutoshikiPuzzle puzzle;
  final List<int> cells;
  final int? selectedCell;
  final Set<int> relatedCells;
  final Set<int> invalidCells;
  final Color accent;
  final double cellSize;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final int dimension = puzzle.size;
    final double step = cellSize + gap;
    final Paint fill = Paint();
    final Paint border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (int index = 0; index < cells.length; index++) {
      final int row = index ~/ dimension;
      final int column = index % dimension;
      final Rect rect = Rect.fromLTWH(
        column * step,
        row * step,
        cellSize,
        cellSize,
      );
      fill.color = index == selectedCell
          ? accent.withValues(alpha: .17)
          : relatedCells.contains(index)
          ? accent.withValues(alpha: .055)
          : const Color(0xFFFCFBF8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(9)),
        fill,
      );
      border
        ..color = invalidCells.contains(index)
            ? const Color(0xFFCB766C)
            : index == selectedCell
            ? accent
            : const Color(0xFFD9D7D0)
        ..strokeWidth = index == selectedCell ? 1.8 : 1;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(9)),
        border,
      );
      final int current = cells[index];
      if (current == 0) continue;
      final bool fixed = puzzle.givens[index] != null;
      final TextPainter number = TextPainter(
        text: TextSpan(
          text: '$current',
          style: TextStyle(
            fontFamily: 'Roboto',
            color: invalidCells.contains(index)
                ? const Color(0xFF9D5149)
                : fixed
                ? const Color(0xFF25343A)
                : const Color(0xFF28685F),
            fontSize: math.min(26, cellSize * .48),
            fontWeight: fixed ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      number.paint(
        canvas,
        Offset(
          rect.center.dx - number.width / 2,
          rect.center.dy - number.height / 2,
        ),
      );
    }
    for (int row = 0; row < dimension; row++) {
      for (int column = 0; column < dimension; column++) {
        final int cell = row * dimension + column;
        if (column + 1 < dimension) {
          final FutoshikiRelation? relation = puzzle.relationBetween(
            cell,
            cell + 1,
          );
          if (relation != null) {
            _paintRelation(
              canvas,
              relation.lessCell == cell ? '<' : '>',
              Offset(
                column * step + cellSize + gap / 2,
                row * step + cellSize / 2,
              ),
              vertical: false,
            );
          }
        }
        if (row + 1 < dimension) {
          final FutoshikiRelation? relation = puzzle.relationBetween(
            cell,
            cell + dimension,
          );
          if (relation != null) {
            _paintRelation(
              canvas,
              relation.lessCell == cell ? '<' : '>',
              Offset(
                column * step + cellSize / 2,
                row * step + cellSize + gap / 2,
              ),
              vertical: true,
            );
          }
        }
      }
    }
  }

  void _paintRelation(
    Canvas canvas,
    String symbol,
    Offset center, {
    required bool vertical,
  }) {
    final RRect chip = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: 18, height: 18),
      const Radius.circular(6),
    );
    canvas.drawRRect(chip, Paint()..color = const Color(0xFFFCFBF8));
    final TextPainter marker = TextPainter(
      text: TextSpan(
        text: symbol,
        style: TextStyle(
          fontFamily: 'Roboto',
          color: _FutoshikiPlayPageState._gold,
          fontSize: 13,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(center.dx, center.dy);
    if (vertical) canvas.rotate(math.pi / 2);
    marker.paint(canvas, Offset(-marker.width / 2, -marker.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FutoshikiBoardPainter oldDelegate) =>
      oldDelegate.puzzle.signature != puzzle.signature ||
      oldDelegate.selectedCell != selectedCell ||
      oldDelegate.cellSize != cellSize ||
      oldDelegate.gap != gap ||
      Object.hashAll(oldDelegate.cells) != Object.hashAll(cells) ||
      !_sameSet(oldDelegate.relatedCells, relatedCells) ||
      !_sameSet(oldDelegate.invalidCells, invalidCells);

  bool _sameSet(Set<int> left, Set<int> right) =>
      left.length == right.length && left.containsAll(right);
}

class _FutoshikiStatus extends StatelessWidget {
  const _FutoshikiStatus({
    required this.level,
    required this.tier,
    required this.size,
    required this.emptyCount,
    required this.relationCount,
    required this.english,
  });

  final int level;
  final String tier;
  final int size;
  final int emptyCount;
  final int relationCount;
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
            color: const Color(0xFFEAF3F0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.grid_4x4_rounded,
            color: _FutoshikiPlayPageState._accent,
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
                    ? '$size×$size grid · $emptyCount empty · $relationCount signs'
                    : '$size×$size ızgara · $emptyCount boş · $relationCount işaret',
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
        Text(
          '${level.toString().padLeft(2, '0')} / ${GameContentPolicy.campaignLevels}',
          style: const TextStyle(
            fontFamily: 'Roboto',
            color: Color(0xFF53655E),
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _FutoshikiInstruction extends StatelessWidget {
  const _FutoshikiInstruction({
    required this.english,
    required this.size,
    this.notice,
    this.warning = false,
  });

  final bool english;
  final int size;
  final String? notice;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final bool hasNotice = notice != null && notice!.isNotEmpty;
    final Color bgColor = hasNotice
        ? (warning ? const Color(0xFFFFF3F0) : const Color(0xFFEEF3EF))
        : const Color(0xFFF5F7F4);
    final Color borderColor = hasNotice
        ? (warning ? const Color(0xFFFFDCD6) : const Color(0xFFD6E8E2))
        : const Color(0xFFE5EAE5);
    final Color iconColor = hasNotice
        ? (warning ? const Color(0xFFB9655E) : _FutoshikiPlayPageState._accent)
        : const Color(0xFF259C89);
    final Color textColor = hasNotice
        ? (warning ? const Color(0xFF8F514A) : const Color(0xFF4E645B))
        : const Color(0xFF4E625A);
    final IconData icon = hasNotice
        ? (warning ? Icons.info_outline_rounded : Icons.check_circle_outline)
        : Icons.compare_arrows_rounded;
    final String displayText = hasNotice
        ? notice!
        : (english
            ? 'Tap a cell, enter 1–$size and follow every < and > sign.'
            : 'Hücreye dokun, 1–$size gir ve her < > işaretini uygula.');

    return Container(
      key: const ValueKey<String>('futoshiki_instruction_banner'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: iconColor, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              displayText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Roboto',
                color: textColor,
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
}

class _FutoshikiKeypad extends StatelessWidget {
  const _FutoshikiKeypad({
    required this.size,
    required this.enabled,
    required this.selectedValue,
    required this.english,
    required this.onValue,
    required this.onClear,
  });

  final int size;
  final bool enabled;
  final int selectedValue;
  final bool english;
  final ValueChanged<int> onValue;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
    decoration: BoxDecoration(
      color: const Color(0xFFFCFBF8),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE8E5DF)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          english ? 'NUMBER BANK' : 'SAYI BANKASI',
          style: const TextStyle(
            fontFamily: 'Roboto',
            color: Color(0xFF697671),
            fontSize: 11,
            letterSpacing: 1.15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children: <Widget>[
            for (int value = 1; value <= size; value++)
              SizedBox(
                width: 48,
                height: 48,
                child: OutlinedButton(
                  key: ValueKey<String>('futoshiki_digit_$value'),
                  onPressed: enabled ? () => onValue(value) : null,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: selectedValue == value
                        ? const Color(0xFFEAF3F0)
                        : Colors.white,
                    foregroundColor: const Color(0xFF30443E),
                    side: BorderSide(
                      color: selectedValue == value
                          ? const Color(0xFF9CC5B9)
                          : const Color(0xFFE0E2DC),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '$value',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            SizedBox(
              width: 48,
              height: 48,
              child: OutlinedButton(
                key: const ValueKey<String>('futoshiki_clear'),
                onPressed: enabled ? onClear : null,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  foregroundColor: const Color(0xFF65736D),
                  side: const BorderSide(color: Color(0xFFE0E2DC)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Tooltip(
                  message: english
                      ? 'Clear selected cell'
                      : 'Seçili hücreyi sil',
                  child: const Icon(Icons.backspace_outlined, size: 18),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _FutoshikiTool extends StatelessWidget {
  const _FutoshikiTool({
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

class _FutoshikiLevelPill extends StatelessWidget {
  const _FutoshikiLevelPill({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF0EC),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: const Color(0xFFDCE5DF)),
    ),
    child: Text(
      '${level.toString().padLeft(2, '0')} / ${GameContentPolicy.campaignLevels}',
      style: const TextStyle(
        fontFamily: 'Roboto',
        color: Color(0xFF566B62),
        fontSize: 12,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}
