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
import 'kenken_cube_puzzle.dart';

class KenKenCubeGamePage extends StatelessWidget {
  const KenKenCubeGamePage({
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
    GameContentPolicy.nativeStages('kenken_cube'),
    (int index) {
      final int stage = (index % 10) + 1;
      final int size = KenKenPuzzle.sizeForStage(stage);
      return ParkurLevelSpec(
        number: index + 1,
        titleTr: 'KenKen ${'${index + 1}'.padLeft(3, '0')}',
        titleEn: 'KenKen ${'${index + 1}'.padLeft(3, '0')}',
        subtitleTr: '$size×$size · Kafes işlemleri · Tek çözüm',
        subtitleEn: '$size×$size · Cage arithmetic · One solution',
        difficulty: _stageName(stage, english: false),
        icon: Icons.functions_rounded,
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
    final StudioGameSkin skin = StudioGameSkin.forId('kenken_cube');
    return ParkurLevelHub(
      gameId: 'kenken_cube',
      progressPrefix: 'kenken_cube',
      titleTr: 'KenKen Küpü',
      titleEn: 'KenKen Cube',
      taglineTr: 'Satır ve sütunları koru, kafes hedeflerini çöz.',
      taglineEn: 'Keep rows and columns unique; solve each cage target.',
      accent: skin.accent,
      icon: Icons.functions_rounded,
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
          ) => KenKenCubePlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class KenKenCubePlayPage extends StatefulWidget {
  const KenKenCubePlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<KenKenCubePlayPage> createState() => _KenKenCubePlayPageState();
}

class _KenKenCubePlayPageState extends State<KenKenCubePlayPage> {
  static const Color _ink = StudioVisuals.ink;
  static const Color _muted = StudioVisuals.muted;
  static const Color _canvas = StudioVisuals.canvas;
  static const Color _accent = Color(0xFF247568);
  static const Color _brass = Color(0xFFB58A58);
  static const Color _coral = Color(0xFFC96E66);
  static const Color _line = Color(0xFF71827E);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.numbers,
  );
  final List<_KenKenSnapshot> _undo = <_KenKenSnapshot>[];
  late final KenKenPuzzle _puzzle;
  late final List<int> _values;
  late final List<int> _initialValues;
  late final StudioGameSession _session;
  int? _selected;
  bool _english = false;
  bool _finished = false;
  int _moves = 0;
  int _hints = 0;

  @override
  void initState() {
    super.initState();
    _puzzle = KenKenPuzzle.forLevel(widget.level.contentIndex);
    _initialValues = List<int>.filled(_puzzle.cellCount, 0);
    _values = List<int>.from(_initialValues);
    _selected = 0;
    _session = StudioGameSession(
      level: widget.level.number,
      seed: widget.level.number,
    )..start();
    unawaited(_audioProfile.preload(_audio));
  }

  int get _filled => _values.where((int value) => value != 0).length;
  int get _blankCount => _puzzle.cellCount - _filled;
  int get _conflictCount => _conflicts.length;

  Set<int> get _conflicts {
    final Set<int> conflicts = <int>{};
    for (int index = 0; index < _values.length; index++) {
      final int value = _values[index];
      if (value == 0) continue;
      final int row = index ~/ _puzzle.size;
      final int column = index % _puzzle.size;
      for (int other = index + 1; other < _values.length; other++) {
        if (_values[other] != value) continue;
        if (other ~/ _puzzle.size == row || other % _puzzle.size == column) {
          conflicts
            ..add(index)
            ..add(other);
        }
      }
    }
    return conflicts;
  }

  void _select(int index) {
    if (_finished) return;
    setState(() => _selected = index);
    _audio.hapticSelection();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .18),
    );
  }

  void _saveUndo() {
    _undo.add(_KenKenSnapshot(List<int>.from(_values), _selected));
    if (_undo.length > 80) _undo.removeAt(0);
  }

  void _enter(int digit) {
    final int? index = _selected;
    if (_finished || index == null) return;
    _saveUndo();
    setState(() {
      _values[index] = digit;
      _moves++;
      _selected = _nextEmpty(index);
    });
    _session.recordAccepted();
    if (_conflicts.contains(index)) {
      _session.recordMistake();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .28));
    } else {
      unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .20));
    }
  }

  int? _nextEmpty(int from) {
    for (int step = 1; step <= _values.length; step++) {
      final int index = (from + step) % _values.length;
      if (_values[index] == 0) return index;
    }
    return from;
  }

  void _clear() {
    final int? index = _selected;
    if (_finished || index == null || _values[index] == 0) return;
    _saveUndo();
    setState(() {
      _values[index] = 0;
      _moves++;
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .24));
  }

  void _undoMove() {
    if (_finished || _undo.isEmpty) return;
    final _KenKenSnapshot snapshot = _undo.removeLast();
    setState(() {
      for (int index = 0; index < _values.length; index++) {
        _values[index] = snapshot.values[index];
      }
      _selected = snapshot.selected;
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .24));
  }

  void _reset() {
    if (_finished) return;
    setState(() {
      for (int index = 0; index < _values.length; index++) {
        _values[index] = _initialValues[index];
      }
      _selected = _values.indexWhere((int value) => value == 0);
      _undo.clear();
      _moves = 0;
      _hints = 0;
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .24));
  }

  void _hint() {
    final int? index = _selected;
    if (_finished || index == null || !_session.canUseHint) return;
    if (_values[index] != 0) {
      _showMessage(
        _english ? 'Choose an empty cell first.' : 'Önce boş bir hücre seç.',
      );
      return;
    }
    _saveUndo();
    setState(() {
      _values[index] = _puzzle.solution[index];
      _hints++;
      _moves++;
      _selected = _nextEmpty(index);
    });
    _session.useHint(pointCost: 140);
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .25));
  }

  Future<void> _check() async {
    if (_finished) return;
    if (_blankCount > 0) {
      _showMessage(
        _english
            ? 'Fill the remaining $_blankCount cells.'
            : 'Kalan $_blankCount hücreyi doldur.',
      );
      return;
    }
    if (_conflictCount > 0 || !_puzzle.isSolved(_values)) {
      _session.recordMistake();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .32));
      _showMessage(
        _english
            ? 'Check row, column and cage arithmetic.'
            : 'Satır, sütun ve kafes işlemlerini kontrol et.',
      );
      return;
    }
    await _complete();
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1600),
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
      250,
      2300 - _moves * 5 - _hints * 170 - _session.mistakes * 100,
    );
    _session.recordAccepted(points: score);
    final StudioGameResult result = _session.complete(
      stars: stars,
      action: widget.level.number < KenKenCubeGamePage.totalCases
          ? StudioResultAction.next
          : StudioResultAction.map,
    );
    _audio.hapticMedium();
    unawaited(
      _audioProfile.play(
        _audio,
        GameAudioEvent.levelComplete,
        levelNumber: widget.level.number,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: _ink,
        icon: const Icon(Icons.functions_rounded, color: Color(0xFFE8C99B)),
        title: Text(
          _english ? 'KENKEN SOLVED' : 'KENKEN TAMAMLANDI',
          style: const TextStyle(
            fontFamily: 'Roboto',
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          _english
              ? '$stars stars  •  $score points\nEvery row, column and arithmetic cage is correct.'
              : '$stars yıldız  •  $score puan\nSatırlar, sütunlar ve işlem kafesleri doğru.',
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
              widget.level.number < KenKenCubeGamePage.totalCases
                  ? (_english ? 'NEXT KENKEN' : 'SONRAKİ KENKEN')
                  : (_english ? 'LEVEL BOARD' : 'BÖLÜM PANOSU'),
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
                  const Icon(
                    Icons.help_outline_rounded,
                    color: _accent,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _english ? 'HOW TO PLAY?' : 'NASIL OYNANIR?',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: _ink,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _english
                    ? '• Fill the grid so that each row and column contains numbers from 1 to ${_puzzle.size} without repeating.\n• Each heavily outlined group of cells is a "cage".\n• The numbers in each cage must combine using the given math operator (+, −, ×, ÷) to match the target clue.\n• Single-cell cages simply take the clue number.'
                    : '• Her satır ve sütunda 1 ile ${_puzzle.size} arasındaki sayılar tekrarsız olarak yer almalıdır.\n• Kalın çizgilerle çevrili hücre gruplarına "kafes" denir.\n• Kafes içindeki sayılar, köşedeki işlem işaretiyle (+, −, ×, ÷) birleştiğinde hedef sonucu vermelidir.\n• İşaretsiz tek hücreli kafeslerde doğrudan hedef sayı yazılır.',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  height: 1.5,
                  color: _ink,
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
    final Set<int> conflicts = _conflicts;
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        toolbarHeight: 50,
        backgroundColor: _canvas,
        foregroundColor: _ink,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 10,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _english
                  ? 'KENKEN CUBE · ${_puzzle.size}×${_puzzle.size}'
                  : 'KENKEN KÜPÜ · ${_puzzle.size}×${_puzzle.size}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: .55,
              ),
            ),
            Text(
              '${_english ? 'PUZZLE' : 'BULMACA'} ${widget.level.number.toString().padLeft(3, '0')} · ${KenKenCubeGamePage._stageName(stage, english: _english)}',
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
            key: const ValueKey<String>('kenken_reset'),
            onPressed: _reset,
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
              final double availableWidth = constraints.maxWidth;
              final double availableHeight = constraints.maxHeight;
              final double boardSize = math
                  .min(availableWidth - 24, availableHeight - 220)
                  .clamp(180.0, 400.0);
              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                child: Column(
                  children: <Widget>[
                    _KenKenSummary(
                      filled: _filled,
                      total: _puzzle.cellCount,
                      cages: _puzzle.cages.length,
                      stage: stage,
                      moves: _moves,
                      english: _english,
                    ),
                    Expanded(
                      child: Center(
                        child: SizedBox.square(
                          dimension: boardSize,
                          child: _KenKenBoard(
                            puzzle: _puzzle,
                            values: _values,
                            selected: _selected,
                            conflicts: conflicts,
                            onSelect: _select,
                          ),
                        ),
                      ),
                    ),
                    _KenKenStatus(
                      selected: _selected,
                      puzzle: _puzzle,
                      value: _selected == null ? 0 : _values[_selected!],
                      conflicts: conflicts.length,
                      english: _english,
                    ),
                    const SizedBox(height: 6),
                    // Sayılar üstte ve yan yana satır olarak
                    SizedBox(
                      width: double.infinity,
                      child: _KenKenKeypad(size: _puzzle.size, onDigit: _enter),
                    ),
                    const SizedBox(height: 6),
                    // İşlem Kontrol Butonları Satırı
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _ToolButton(
                            key: const ValueKey<String>('kenken_undo_action'),
                            icon: Icons.undo_rounded,
                            label: _english ? 'UNDO' : 'GERİ AL',
                            onTap: _undo.isEmpty ? null : _undoMove,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _ToolButton(
                            key: const ValueKey<String>('kenken_clear'),
                            icon: Icons.backspace_outlined,
                            label: _english ? 'CLEAR' : 'SİL',
                            onTap: _clear,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _ToolButton(
                            key: const ValueKey<String>('kenken_hint'),
                            icon: Icons.lightbulb_outline_rounded,
                            label: _english ? 'HINT' : 'İPUCU',
                            onTap: _hint,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      key: const ValueKey<String>('kenken_check'),
                      onPressed: _check,
                      icon: const Icon(Icons.fact_check_outlined, size: 18),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _english ? 'CHECK GRID' : 'TABLOYU KONTROL ET',
                          maxLines: 1,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w900,
                          letterSpacing: .35,
                          fontSize: 13,
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

class _KenKenSnapshot {
  const _KenKenSnapshot(this.values, this.selected);
  final List<int> values;
  final int? selected;
}

class _KenKenSummary extends StatelessWidget {
  const _KenKenSummary({
    required this.filled,
    required this.total,
    required this.cages,
    required this.stage,
    required this.moves,
    required this.english,
  });
  final int filled;
  final int total;
  final int cages;
  final int stage;
  final int moves;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE1E7E4)),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color(0x0B1C2E32),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: <Widget>[
        const Icon(
          Icons.grid_4x4_rounded,
          color: _KenKenCubePlayPageState._accent,
          size: 19,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${english ? 'STAGE' : 'AŞAMA'} $stage  ·  $cages ${english ? 'CAGES' : 'KAFES'}',
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: _KenKenCubePlayPageState._ink,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: .25,
            ),
          ),
        ),
        Text(
          '$filled/$total',
          style: const TextStyle(
            fontFamily: 'Roboto',
            color: _KenKenCubePlayPageState._accent,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${english ? 'MOVE' : 'HAMLE'} $moves',
          style: const TextStyle(
            fontFamily: 'Roboto',
            color: _KenKenCubePlayPageState._muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _KenKenBoard extends StatelessWidget {
  const _KenKenBoard({
    required this.puzzle,
    required this.values,
    required this.selected,
    required this.conflicts,
    required this.onSelect,
  });
  final KenKenPuzzle puzzle;
  final List<int> values;
  final int? selected;
  final Set<int> conflicts;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD7DEDA)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x111B332F),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double cell = constraints.maxWidth / puzzle.size;
          return Stack(
            children: <Widget>[
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: puzzle.cellCount,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: puzzle.size,
                ),
                itemBuilder: (BuildContext context, int index) {
                  final int cageIndex = puzzle.cageIndexAt(index);
                  final KenKenCage cage = puzzle.cages[cageIndex];
                  final int firstCell = cage.cells.reduce(math.min);
                  final bool isClueCell = index == firstCell;
                  final bool isSelected = selected == index;
                  final bool sameRowOrColumn =
                      selected != null &&
                      (index ~/ puzzle.size == selected! ~/ puzzle.size ||
                          index % puzzle.size == selected! % puzzle.size);
                  final Color fill = conflicts.contains(index)
                      ? const Color(0xFFFFEBE8)
                      : isSelected
                      ? const Color(0xFFDDEFEA)
                      : sameRowOrColumn
                      ? const Color(0xFFF3F8F6)
                      : Colors.white;
                  return GestureDetector(
                    key: ValueKey<String>('kenken_cell_$index'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onSelect(index),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: fill,
                        border: Border.all(
                          color: const Color(0xFFE6EBE8),
                          width: .45,
                        ),
                      ),
                      child: Stack(
                        children: <Widget>[
                          if (isClueCell)
                            Positioned(
                              left: 3,
                              top: 1,
                              child: Text(
                                cage.label,
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  color: _KenKenCubePlayPageState._brass,
                                  fontSize: math.max(
                                    7,
                                    math.min(9, cell * .15),
                                  ),
                                  height: 1,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          Center(
                            child: Text(
                              values[index] == 0 ? '' : '${values[index]}',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                color: conflicts.contains(index)
                                    ? _KenKenCubePlayPageState._coral
                                    : _KenKenCubePlayPageState._ink,
                                fontSize: math.min(28, cell * .45),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              IgnorePointer(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _CageBoundaryPainter(
                    puzzle: puzzle,
                    line: _KenKenCubePlayPageState._line,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CageBoundaryPainter extends CustomPainter {
  const _CageBoundaryPainter({required this.puzzle, required this.line});
  final KenKenPuzzle puzzle;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    final double cell = size.width / puzzle.size;
    final Paint paint = Paint()
      ..color = line.withValues(alpha: .82)
      ..strokeWidth = math.max(1.25, cell * .035)
      ..style = PaintingStyle.stroke;
    for (int row = 0; row < puzzle.size; row++) {
      for (int column = 0; column < puzzle.size; column++) {
        final int index = row * puzzle.size + column;
        final int cage = puzzle.cageIndexAt(index);
        if (row == 0 || puzzle.cageIndexAt(index - puzzle.size) != cage) {
          canvas.drawLine(
            Offset(column * cell, row * cell),
            Offset((column + 1) * cell, row * cell),
            paint,
          );
        }
        if (column == 0 || puzzle.cageIndexAt(index - 1) != cage) {
          canvas.drawLine(
            Offset(column * cell, row * cell),
            Offset(column * cell, (row + 1) * cell),
            paint,
          );
        }
        if (row == puzzle.size - 1 ||
            puzzle.cageIndexAt(index + puzzle.size) != cage) {
          canvas.drawLine(
            Offset(column * cell, (row + 1) * cell),
            Offset((column + 1) * cell, (row + 1) * cell),
            paint,
          );
        }
        if (column == puzzle.size - 1 ||
            puzzle.cageIndexAt(index + 1) != cage) {
          canvas.drawLine(
            Offset((column + 1) * cell, row * cell),
            Offset((column + 1) * cell, (row + 1) * cell),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_CageBoundaryPainter oldDelegate) =>
      oldDelegate.puzzle != puzzle || oldDelegate.line != line;
}

class _KenKenStatus extends StatelessWidget {
  const _KenKenStatus({
    required this.selected,
    required this.puzzle,
    required this.value,
    required this.conflicts,
    required this.english,
  });
  final int? selected;
  final KenKenPuzzle puzzle;
  final int value;
  final int conflicts;
  final bool english;

  @override
  Widget build(BuildContext context) {
    final KenKenCage? cage = selected == null
        ? null
        : puzzle.cages[puzzle.cageIndexAt(selected!)];
    final Color color = conflicts > 0
        ? _KenKenCubePlayPageState._coral
        : _KenKenCubePlayPageState._muted;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: <Widget>[
        if (cage != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF6E9),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: const Color(0xFFE9D5B8)),
            ),
            child: Text(
              '${english ? 'CAGE' : 'KAFES'} ${cage.label}',
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: _KenKenCubePlayPageState._brass,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        Text(
          conflicts > 0
              ? (english
                    ? '$conflicts row/column conflicts'
                    : '$conflicts satır/sütun çakışması')
              : value == 0
              ? (english
                    ? 'Select a cell, then choose a value'
                    : 'Hücreyi seç, ardından sayı tuşuna bas')
              : (english ? 'Selected value: $value' : 'Seçili sayı: $value'),
          style: TextStyle(
            fontFamily: 'Roboto',
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _KenKenKeypad extends StatelessWidget {
  const _KenKenKeypad({required this.size, required this.onDigit});
  final int size;
  final ValueChanged<int> onDigit;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (int digit = 1; digit <= size; digit++) ...<Widget>[
          if (digit > 1) const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 46,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
                elevation: 0,
                child: InkWell(
                  key: ValueKey<String>('kenken_num_$digit'),
                  borderRadius: BorderRadius.circular(13),
                  onTap: () => onDigit(digit),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFDCE4E0),
                        width: 1.3,
                      ),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$digit',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: _KenKenCubePlayPageState._ink,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 16),
    label: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
    style: OutlinedButton.styleFrom(
      foregroundColor: _KenKenCubePlayPageState._accent,
      side: const BorderSide(color: Color(0xFFD5E4DF)),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      minimumSize: const Size(0, 42),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
