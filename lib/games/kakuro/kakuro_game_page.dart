import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../features/catalog/domain/studio_game_catalog.dart';
import '../../l10n/app_localizations.dart';
import '../../services/game_audio_service.dart';
import '../../theme/studio_visuals.dart';
import '../shared/game_audio_profile.dart';
import '../shared/parkur_game_kit.dart';
import '../shared/studio_game_contracts.dart';
import '../shared/studio_game_session.dart';
import '../shared/studio_game_skin.dart';
import 'kakuro_puzzle.dart';

class KakuroGamePage extends StatelessWidget {
  const KakuroGamePage({
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
    GameContentPolicy.nativeStages('kakuro'),
    (int index) {
      final int number = index + 1;
      final int stage = (index % 10) + 1;
      final int chapter = index ~/ 10 + 1;
      final String difficulty = switch (stage) {
        <= 6 => chapter == 1 ? 'USTALAŞMA' : 'İLERİ',
        <= 8 => 'UZMAN',
        _ => 'UZMAN+',
      };
      return ParkurLevelSpec(
        number: number,
        titleTr: 'Kakuro ${number.toString().padLeft(2, '0')}',
        titleEn: 'Kakuro ${number.toString().padLeft(2, '0')}',
        subtitleTr: _subtitle(stage, chapter, english: false),
        subtitleEn: _subtitle(stage, chapter, english: true),
        difficulty: difficulty,
        icon: Icons.grid_on_rounded,
      );
    },
    growable: false,
  );

  static String _subtitle(int stage, int chapter, {required bool english}) {
    if (chapter == 2 && stage <= 6) {
      return english
          ? 'Longer crossings add a second layer of deduction.'
          : 'Uzayan kesişimler ikinci bir çıkarım katmanı ekler.';
    }
    return switch (stage) {
      <= 3 =>
        english
            ? 'Learn to read both sums in each clue cell.'
            : 'Her ipucu hücresindeki iki toplamı okumayı öğren.',
      <= 6 =>
        english
            ? 'Use crossing runs to narrow each digit.'
            : 'Kesişen dizilerle her rakamın adayını daralt.',
      <= 8 =>
        english
            ? 'Longer runs demand deliberate candidate checks.'
            : 'Uzun dizilerde adayları dikkatle ele.',
      9 =>
        english
            ? 'Resolve dense intersections without repeating digits.'
            : 'Yoğun kesişimleri rakam tekrarı yapmadan çöz.',
      _ =>
        english
            ? 'Expert board: every crossing contributes.'
            : 'Uzman tablosu: her kesişim belirleyici.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forId('kakuro');
    return ParkurLevelHub(
      gameId: 'kakuro',
      progressPrefix: 'kakuro',
      titleTr: 'Kakuro Izgarası',
      titleEn: 'Kakuro Grid',
      taglineTr: 'Kesişen toplamları çöz • Her dizide rakamları tekrarlama',
      taglineEn: 'Solve crossing sums • Never repeat a digit in a run',
      accent: skin.accent,
      icon: Icons.grid_on_rounded,
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
      ) => KakuroPlayPage(level: level, previousBestScore: previousBestScore),
    );
  }
}

class KakuroPlayPage extends StatefulWidget {
  const KakuroPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<KakuroPlayPage> createState() => _KakuroPlayPageState();
}

class _KakuroPlayPageState extends State<KakuroPlayPage> {
  static const Color _accent = Color(0xFF247568);
  static const Color _accentDark = Color(0xFF187464);
  static const Color _clueInk = Color(0xFF273849);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.numbers,
  );
  final List<Map<int, int>> _undoStack = <Map<int, int>>[];
  late final KakuroPuzzle _puzzle;
  late final StudioGameSession _session;
  late List<int> _entries;
  Set<int> _incorrectCells = <int>{};
  String? _notice;
  int? _selectedCell;
  bool _english = false;
  bool _finished = false;
  int _hints = 0;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    _puzzle = widget.level.poolIndex == null
        ? KakuroPuzzle.forLevel(widget.level.contentLevel)
        : KakuroPuzzle.forPool(widget.level.contentIndex);
    _entries = List<int>.filled(_puzzle.cells.length, 0);
    _selectedCell = _puzzle.cells.indexWhere(
      (KakuroCell cell) => cell.isPlayable,
    );
    _session = StudioGameSession(
      level: widget.level.number,
      seed: widget.level.number,
    )..start();
    unawaited(_audioProfile.preload(_audio));
  }

  int get _filledCount => _puzzle.cells
      .asMap()
      .entries
      .where((MapEntry<int, KakuroCell> entry) => entry.value.isPlayable)
      .where((MapEntry<int, KakuroCell> entry) => _entries[entry.key] != 0)
      .length;

  int get _score => math.max(
    0,
    3200 -
        _hints * 220 -
        _session.mistakes * 145 -
        math.max(0, _attempts - 1) * 25,
  );

  int get _stars {
    if (_hints == 0 && _session.mistakes == 0) return 3;
    if (_hints <= 2 && _session.mistakes <= 2) return 2;
    return 1;
  }

  KakuroRun? _runAt(int cell, KakuroRunDirection direction) {
    final List<KakuroRun> runs = direction == KakuroRunDirection.across
        ? _puzzle.acrossRuns
        : _puzzle.downRuns;
    for (final KakuroRun run in runs) {
      if (run.cells.contains(cell)) return run;
    }
    return null;
  }

  Set<int> get _relatedCells {
    final int? selected = _selectedCell;
    if (selected == null) return <int>{};
    return <int>{
      ...?_runAt(selected, KakuroRunDirection.across)?.cells,
      ...?_runAt(selected, KakuroRunDirection.down)?.cells,
    };
  }

  void _selectCell(int index) {
    if (_finished || !_puzzle.cells[index].isPlayable) return;
    setState(() {
      _selectedCell = index;
      _incorrectCells = <int>{};
      _notice = null;
    });
    _audio.hapticSelection();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .2),
    );
  }

  void _saveUndo() => _undoStack.add(
    List<int>.generate(_entries.length, (int index) => _entries[index]).asMap(),
  );

  void _enterDigit(int digit) {
    final int? selected = _selectedCell;
    if (_finished || selected == null || !_session.acceptsInput) return;
    _saveUndo();
    setState(() {
      _entries[selected] = digit;
      _incorrectCells = <int>{};
      _notice = null;
      _selectedCell = _nextEmptyAfter(selected);
    });
    _audio.hapticLight();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .2),
    );
  }

  int? _nextEmptyAfter(int current) {
    for (int offset = 1; offset <= _puzzle.cells.length; offset++) {
      final int candidate = (current + offset) % _puzzle.cells.length;
      if (_puzzle.cells[candidate].isPlayable && _entries[candidate] == 0) {
        return candidate;
      }
    }
    return current;
  }

  void _clearSelected() {
    final int? selected = _selectedCell;
    if (_finished || selected == null || _entries[selected] == 0) return;
    _saveUndo();
    setState(() {
      _entries[selected] = 0;
      _incorrectCells.remove(selected);
      _notice = null;
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .22));
  }

  void _undo() {
    if (_finished || _undoStack.isEmpty) return;
    final Map<int, int> snapshot = _undoStack.removeLast();
    setState(() {
      _entries = List<int>.generate(
        _entries.length,
        (int index) => snapshot[index] ?? 0,
      );
      _incorrectCells = <int>{};
      _notice = null;
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .22));
  }

  void _resetBoard() {
    if (_finished || _filledCount == 0) return;
    setState(() {
      _entries = List<int>.filled(_puzzle.cells.length, 0);
      _incorrectCells = <int>{};
      _undoStack.clear();
      _notice = null;
      _selectedCell = _puzzle.cells.indexWhere(
        (KakuroCell cell) => cell.isPlayable,
      );
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .22));
  }

  void _showHint() {
    if (_finished || !_session.canUseHint) return;
    int target = _selectedCell ?? -1;
    if (target < 0 || _entries[target] != 0) {
      target = _puzzle.cells.indexWhere(
        (KakuroCell cell) =>
            cell.isPlayable && _entries[_puzzle.cells.indexOf(cell)] == 0,
      );
    }
    if (target < 0) return;
    _saveUndo();
    setState(() {
      _hints++;
      _entries[target] = _puzzle.solution[target];
      _selectedCell = target;
      _incorrectCells = <int>{};
      _notice = _english
          ? 'A verified digit is revealed. Use its crossing sums to continue.'
          : 'Doğrulanmış bir rakam açıldı. Devam etmek için kesişen toplamları kullan.';
    });
    _session.useHint(pointCost: 220);
    _audio.hapticSelection();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .32));
  }

  void _checkBoard() {
    if (_finished || !_session.acceptsInput) return;
    _attempts++;
    if (_filledCount < _puzzle.playableCount) {
      setState(() {
        _notice = _english
            ? 'Fill every white cell before checking the grid.'
            : 'Izgarayı kontrol etmeden önce tüm beyaz hücreleri doldur.';
      });
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .22));
      return;
    }
    final Set<int> wrong = <int>{
      for (int index = 0; index < _entries.length; index++)
        if (_puzzle.cells[index].isPlayable &&
            _entries[index] != _puzzle.solution[index])
          index,
    };
    if (wrong.isNotEmpty) {
      _session.recordMistake();
      setState(() {
        _incorrectCells = wrong;
        _selectedCell = wrong.first;
        _notice = _english
            ? 'Some entries break a crossing sum or repeat a digit. Recheck the highlighted cells.'
            : 'Bazı girişler kesişen toplamı bozuyor veya rakamı tekrarlıyor. Vurgulu hücreleri yeniden incele.';
      });
      _audio.hapticLight();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .28));
      return;
    }
    unawaited(_complete());
  }

  Future<void> _complete() async {
    if (_finished || !_session.acceptsInput) return;
    _finished = true;
    final int score = _score;
    final int stars = _stars;
    _session.recordAccepted(points: score);
    _session.complete(
      stars: stars,
      action: widget.level.number < KakuroGamePage.totalCases
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
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    final ParkurResultAction? result = await showParkurResultDialog(
      context: context,
      accent: _accent,
      titleTr: 'KAKURO ÇÖZÜLDÜ',
      titleEn: 'KAKURO COMPLETE',
      detailTr: 'Kesişimler çözüldü · $_attempts kontrol · $_hints ipucu.',
      detailEn: 'Crossings resolved · $_attempts checks · $_hints hints.',
      stars: stars,
      score: score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < KakuroGamePage.totalCases,
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
    final bool compact = MediaQuery.sizeOf(context).width < 380;
    final Set<int> relatedCells = _relatedCells;
    final KakuroRun? across = _selectedCell == null
        ? null
        : _runAt(_selectedCell!, KakuroRunDirection.across);
    final KakuroRun? down = _selectedCell == null
        ? null
        : _runAt(_selectedCell!, KakuroRunDirection.down);
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 12,
        title: Text(
          _english ? 'KAKURO GRID' : 'KAKURO IZGARASI',
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: _english ? 'Verified hint' : 'Doğrulanmış ipucu',
            onPressed: _showHint,
            icon: const Icon(Icons.lightbulb_outline_rounded),
          ),
          IconButton(
            tooltip: _english ? 'Reset grid' : 'Izgarayı sıfırla',
            onPressed: _resetBoard,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveGameFrame(
          maxContentWidth: 660,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints limits) {
              final double side = limits.maxWidth < 380 ? 8 : 18;
              return ListView(
                key: const ValueKey<String>('kakuro_scroll'),
                padding: EdgeInsets.fromLTRB(side, 4, side, 20),
                children: <Widget>[
                  _KakuroStatusCard(
                    level: widget.level.number,
                    stage: _puzzle.stageInChapter,
                    chapter: _puzzle.chapter,
                    score: _score,
                    bestScore: widget.previousBestScore,
                    english: _english,
                  ),
                  SizedBox(height: compact ? 8 : 12),
                  _KakuroLegend(
                    filled: _filledCount,
                    total: _puzzle.playableCount,
                    english: _english,
                  ),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints boardLimits) {
                          final double boardWidth = math.min(
                            boardLimits.maxWidth,
                            520,
                          );
                          return Center(
                            child: Container(
                              width: boardWidth,
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE4E9ED),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: StudioVisuals.line),
                                boxShadow: StudioVisuals.softShadow,
                              ),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: GridView.builder(
                                  key: const ValueKey<String>('kakuro_board'),
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: EdgeInsets.zero,
                                  itemCount: _puzzle.cells.length,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: _puzzle.size,
                                        crossAxisSpacing: 1.5,
                                        mainAxisSpacing: 1.5,
                                      ),
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                        final KakuroCell cell =
                                            _puzzle.cells[index];
                                        return _KakuroBoardCell(
                                          key: ValueKey<String>(
                                            'kakuro_cell_$index',
                                          ),
                                          cell: cell,
                                          value: _entries[index],
                                          selected: _selectedCell == index,
                                          related: relatedCells.contains(index),
                                          incorrect: _incorrectCells.contains(
                                            index,
                                          ),
                                          english: _english,
                                          onTap: cell.isPlayable
                                              ? () => _selectCell(index)
                                              : null,
                                        );
                                      },
                                ),
                              ),
                            ),
                          );
                        },
                  ),
                  const SizedBox(height: 8),
                  _KakuroCrossingPanel(
                    across: across,
                    down: down,
                    entries: _entries,
                    selectedCell: _selectedCell,
                    english: _english,
                  ),
                  const SizedBox(height: 8),
                  _KakuroNumberPad(
                    onDigit: _enterDigit,
                    onClear: _clearSelected,
                    onUndo: _undo,
                    canUndo: _undoStack.isNotEmpty,
                    english: _english,
                  ),
                  if (_notice != null) ...<Widget>[
                    const SizedBox(height: 8),
                    _KakuroNotice(
                      message: _notice!,
                      isError: _incorrectCells.isNotEmpty,
                    ),
                  ],
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 50,
                    child: FilledButton.icon(
                      key: const ValueKey<String>('kakuro_check'),
                      onPressed: _checkBoard,
                      icon: const Icon(Icons.fact_check_outlined),
                      label: Text(
                        _english ? 'CHECK THE GRID' : 'IZGARAYI KONTROL ET',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .35,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _english
                        ? 'A digit may appear only once in each connected run. Both crossing clues must balance.'
                        : 'Her kesişen dizide rakam yalnızca bir kez bulunabilir. İki yöndeki toplam da tutmalıdır.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: StudioVisuals.muted,
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _KakuroStatusCard extends StatelessWidget {
  const _KakuroStatusCard({
    required this.level,
    required this.stage,
    required this.chapter,
    required this.score,
    required this.bestScore,
    required this.english,
  });

  final int level;
  final int stage;
  final int chapter;
  final int score;
  final int bestScore;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
    decoration: BoxDecoration(
      color: StudioVisuals.surface,
      borderRadius: StudioVisuals.cardRadius,
      border: Border.all(color: StudioVisuals.line),
      boxShadow: StudioVisuals.softShadow,
    ),
    child: Row(
      children: <Widget>[
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _KakuroPlayPageState._accent.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.grid_on_rounded,
            color: _KakuroPlayPageState._accent,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${english ? 'LEVEL' : 'BÖLÜM'} $level / ${GameContentPolicy.campaignLevels}',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: _KakuroPlayPageState._accentDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .4,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${english ? 'Kakuro' : 'Kakuro'} ${level.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: StudioVisuals.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              '${english ? 'SCORE' : 'PUAN'} $score',
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: StudioVisuals.ink,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${english ? 'BEST' : 'EN İYİ'} $bestScore',
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: StudioVisuals.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _KakuroLegend extends StatelessWidget {
  const _KakuroLegend({
    required this.filled,
    required this.total,
    required this.english,
  });

  final int filled;
  final int total;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFFF0F5F5),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: _KakuroPlayPageState._accent.withValues(alpha: .14),
      ),
    ),
    child: Row(
      children: <Widget>[
        const Icon(
          Icons.info_outline_rounded,
          size: 17,
          color: _KakuroPlayPageState._accent,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            english
                ? 'Across clue: upper-right · Down clue: lower-left'
                : 'Yatay ipucu: sağ üst · Dikey ipucu: sol alt',
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: StudioVisuals.ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          '$filled/$total',
          style: const TextStyle(
            fontFamily: 'Roboto',
            color: _KakuroPlayPageState._accentDark,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _KakuroBoardCell extends StatelessWidget {
  const _KakuroBoardCell({
    super.key,
    required this.cell,
    required this.value,
    required this.selected,
    required this.related,
    required this.incorrect,
    required this.english,
    required this.onTap,
  });

  final KakuroCell cell;
  final int value;
  final bool selected;
  final bool related;
  final bool incorrect;
  final bool english;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (!cell.isPlayable) {
      if (cell.acrossSum == null && cell.downSum == null) {
        return const ColoredBox(color: Color(0xFF344454));
      }
      return Semantics(
        label:
            '${english ? 'Across' : 'Yatay'} ${cell.acrossSum ?? '—'}, ${english ? 'down' : 'dikey'} ${cell.downSum ?? '—'}',
        child: CustomPaint(
          painter: _KakuroCluePainter(
            across: cell.acrossSum,
            down: cell.downSum,
            background: _KakuroPlayPageState._clueInk,
            line: const Color(0xFF708091),
          ),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double fontSize = constraints.maxWidth < 40 ? 7 : 9;
              return Stack(
                children: <Widget>[
                  if (cell.acrossSum != null)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Text(
                        '${cell.acrossSum}',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          color: Colors.white,
                          fontSize: fontSize,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  if (cell.downSum != null)
                    Positioned(
                      bottom: 2,
                      left: 2,
                      child: Text(
                        '${cell.downSum}',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          color: Colors.white,
                          fontSize: fontSize,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      );
    }
    final Color background = incorrect
        ? const Color(0xFFFFE7E3)
        : selected
        ? const Color(0xFFD8F2EB)
        : related
        ? const Color(0xFFF0F7F5)
        : Colors.white;
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${english ? 'Cell' : 'Hücre'} ${value == 0 ? (english ? 'empty' : 'boş') : value}${selected ? (english ? ', selected' : ', seçili') : ''}',
      child: Material(
        color: background,
        child: InkWell(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: incorrect
                    ? const Color(0xFFC95F52)
                    : selected
                    ? _KakuroPlayPageState._accent
                    : const Color(0xFFD7E0E4),
                width: selected || incorrect ? 1.4 : .65,
              ),
            ),
            child: Center(
              child: value == 0
                  ? (selected
                        ? Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: _KakuroPlayPageState._accent,
                              shape: BoxShape.circle,
                            ),
                          )
                        : const SizedBox.shrink())
                  : Text(
                      '$value',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: incorrect
                            ? const Color(0xFFAE4034)
                            : _KakuroPlayPageState._clueInk,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KakuroCluePainter extends CustomPainter {
  const _KakuroCluePainter({
    required this.across,
    required this.down,
    required this.background,
    required this.line,
  });

  final int? across;
  final int? down;
  final Color background;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, 0),
      Paint()
        ..color = line
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_KakuroCluePainter oldDelegate) => false;
}

class _KakuroCrossingPanel extends StatelessWidget {
  const _KakuroCrossingPanel({
    required this.across,
    required this.down,
    required this.entries,
    required this.selectedCell,
    required this.english,
  });

  final KakuroRun? across;
  final KakuroRun? down;
  final List<int> entries;
  final int? selectedCell;
  final bool english;

  String _summary(KakuroRun? run) {
    if (run == null) return '—';
    final int filled = run.cells.fold<int>(
      0,
      (int sum, int index) => sum + entries[index],
    );
    final int empty = run.cells
        .where((int index) => entries[index] == 0)
        .length;
    return '${run.targetSum - filled} ${english ? 'left' : 'kaldı'} · $empty ${english ? 'empty' : 'boş'}';
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: StudioVisuals.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: StudioVisuals.line),
    ),
    child: Row(
      children: <Widget>[
        Expanded(
          child: _KakuroRunSummary(
            label: english ? 'ACROSS' : 'YATAY',
            run: across,
            value: _summary(across),
            active:
                selectedCell != null &&
                across?.cells.contains(selectedCell) == true,
          ),
        ),
        Container(width: 1, height: 28, color: StudioVisuals.line),
        Expanded(
          child: _KakuroRunSummary(
            label: english ? 'DOWN' : 'DİKEY',
            run: down,
            value: _summary(down),
            active:
                selectedCell != null &&
                down?.cells.contains(selectedCell) == true,
          ),
        ),
      ],
    ),
  );
}

class _KakuroRunSummary extends StatelessWidget {
  const _KakuroRunSummary({
    required this.label,
    required this.run,
    required this.value,
    required this.active,
  });

  final String label;
  final KakuroRun? run;
  final String value;
  final bool active;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 7),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '$label ${run?.targetSum ?? '—'}',
          style: TextStyle(
            fontFamily: 'Roboto',
            color: active
                ? _KakuroPlayPageState._accentDark
                : StudioVisuals.muted,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: .4,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Roboto',
            color: StudioVisuals.ink,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _KakuroNumberPad extends StatelessWidget {
  const _KakuroNumberPad({
    required this.onDigit,
    required this.onClear,
    required this.onUndo,
    required this.canUndo,
    required this.english,
  });

  final ValueChanged<int> onDigit;
  final VoidCallback onClear;
  final VoidCallback onUndo;
  final bool canUndo;
  final bool english;

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      LayoutBuilder(
        builder: (BuildContext context, BoxConstraints limits) {
          const double gap = 6;
          final double width = (limits.maxWidth - gap * 2) / 3;
          return Wrap(
            spacing: gap,
            runSpacing: 6,
            children: <Widget>[
              for (int digit = 1; digit <= 9; digit++)
                SizedBox(
                  width: width,
                  height: 43,
                  child: OutlinedButton(
                    key: ValueKey<String>('kakuro_digit_$digit'),
                    onPressed: () => onDigit(digit),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _KakuroPlayPageState._clueInk,
                      side: const BorderSide(color: StudioVisuals.line),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      '$digit',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      const SizedBox(height: 7),
      Row(
        children: <Widget>[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: canUndo ? onUndo : null,
              icon: const Icon(Icons.undo_rounded, size: 17),
              label: Text(english ? 'UNDO' : 'GERİ AL'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                foregroundColor: StudioVisuals.ink,
                side: const BorderSide(color: StudioVisuals.line),
              ),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.backspace_outlined, size: 16),
              label: Text(english ? 'ERASE' : 'SİL'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                foregroundColor: StudioVisuals.ink,
                side: const BorderSide(color: StudioVisuals.line),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

class _KakuroNotice extends StatelessWidget {
  const _KakuroNotice({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final Color color = isError
        ? const Color(0xFFAE4034)
        : _KakuroPlayPageState._accentDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .2)),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            isError
                ? Icons.error_outline_rounded
                : Icons.tips_and_updates_outlined,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Roboto',
                color: color,
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
}
