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
import 'hitori_puzzle.dart';

class HitoriGamePage extends StatelessWidget {
  const HitoriGamePage({
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
    GameContentPolicy.nativeStages('hitori'),
    (int index) {
      final int level = index + 1;
      final int stage = index % 10 + 1;
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Sayı Eleme ${level.toString().padLeft(2, '0')}',
        titleEn: 'Number Shade ${level.toString().padLeft(2, '0')}',
        subtitleTr: switch (stage) {
          <= 3 => 'Tekrarları bul; siyahları ayır, beyaz yolu koru.',
          <= 6 => 'Satır ve sütun çakışmalarını birlikte zincirle.',
          7 || 8 => 'İleri: gölgeleme kararlarını bağlantı kuralıyla kesiştir.',
          9 => 'Uzman: daha geniş tahtada çıkmazsız desen kur.',
          _ => 'Usta: tüm tekrarları, komşuluğu ve beyaz yolu kanıtla.',
        },
        subtitleEn: switch (stage) {
          <= 3 => 'Find repeats; shade them without breaking the white path.',
          <= 6 => 'Chain row and column conflicts together.',
          7 || 8 => 'Advanced: combine shading logic with connectivity.',
          9 => 'Expert: keep a wider board open without dead ends.',
          _ => 'Master: prove every repeat, neighbor and white path.',
        },
        difficulty: switch (stage) {
          <= 6 => level <= 10 ? 'USTALAŞMA' : 'DERİNLEŞME',
          7 || 8 => 'İLERİ',
          9 => 'UZMAN',
          _ => 'USTA',
        },
        icon: Icons.grid_view_rounded,
      );
    },
    growable: false,
  );

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forId('hitori');
    return ParkurLevelHub(
      gameId: 'hitori',
      progressPrefix: 'hitori',
      titleTr: 'Hitori',
      titleEn: 'Hitori',
      taglineTr: 'Tekrarları ele • Beyaz yolu açık tut',
      taglineEn: 'Shade repeats • Keep the white path connected',
      accent: skin.accent,
      icon: Icons.grid_view_rounded,
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
      ) => HitoriPlayPage(level: level, previousBestScore: previousBestScore),
    );
  }
}

class HitoriPlayPage extends StatefulWidget {
  const HitoriPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<HitoriPlayPage> createState() => _HitoriPlayPageState();
}

class _HitoriPlayPageState extends State<HitoriPlayPage> {
  static const Color _accent = Color(0xFF665AA2);
  static const Color _ink = StudioVisuals.ink;

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.logic,
  );
  final List<List<bool>> _undoStack = <List<bool>>[];

  late HitoriPuzzle _puzzle;
  late List<bool> _blackCells;
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

  int get _blackCount => _blackCells.where((bool black) => black).length;
  int get _score =>
      math.max(0, 5200 - _edits * 7 - _hints * 360 - _mistakes * 190);
  int get _stars => _hints == 0 && _mistakes == 0
      ? 3
      : _hints <= 2 && _mistakes <= 2
      ? 2
      : 1;

  @override
  void initState() {
    super.initState();
    unawaited(_audioProfile.preload(_audio));
    unawaited(_preparePuzzle());
  }

  Future<void> _preparePuzzle() async {
    HitoriPuzzle puzzle = (widget.level.poolIndex != null
        ? HitoriPuzzle.forPracticeBoard(widget.level.contentIndex)
        : HitoriPuzzle.forLevel(widget.level.contentLevel));
    try {
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      final String visitKey = 'hitori_level_${widget.level.number}_visits';
      final int visits = await preferences.getInt(visitKey) ?? 0;
      if (widget.level.poolIndex == null && visits > 0) {
        final int index =
            await preferences.getInt('hitori_practice_index') ?? 0;
        if (index < HitoriPuzzle.maximumVerifiedBoards) {
          final int next = index + 1;
          await preferences.setInt('hitori_practice_index', next);
          puzzle = HitoriPuzzle.forPracticeBoard(next);
        }
      }
      await preferences.setInt(visitKey, visits + 1);
    } catch (_) {
      puzzle = (widget.level.poolIndex != null
          ? HitoriPuzzle.forPracticeBoard(widget.level.contentIndex)
          : HitoriPuzzle.forLevel(widget.level.contentLevel));
    }
    if (!mounted) return;
    setState(() {
      _puzzle = puzzle;
      _blackCells = List<bool>.filled(puzzle.size * puzzle.size, false);
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

  StudioGameSession _newSession(HitoriPuzzle puzzle) =>
      StudioGameSession(level: widget.level.number, seed: puzzle.seed)..start();

  void _remember() => _undoStack.add(List<bool>.of(_blackCells));

  void _toggleCell(int index) {
    if (!_ready || _finished) return;
    _remember();
    setState(() {
      _selectedCell = index;
      _blackCells[index] = !_blackCells[index];
      _edits++;
      _errorCells = <int>{};
      _notice = _blackCells[index]
          ? (_english ? 'Cell shaded.' : 'Hücre gölgelendi.')
          : (_english ? 'Cell restored to white.' : 'Hücre beyaza döndü.');
    });
    _session.recordAccepted(points: 6);
    _audio.hapticLight();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .17));
  }

  void _undo() {
    if (_undoStack.isEmpty || _finished) return;
    setState(() {
      _blackCells = _undoStack.removeLast();
      _errorCells = <int>{};
      _notice = _english ? 'Last shade undone.' : 'Son gölgeleme geri alındı.';
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .2));
  }

  void _showHint() {
    if (!_ready || _finished) return;
    int target = -1;
    bool shouldShade = true;
    if (_selectedCell != null &&
        _puzzle.solution[_selectedCell!] &&
        !_blackCells[_selectedCell!]) {
      target = _selectedCell!;
    }
    if (target < 0) {
      for (int index = 0; index < _puzzle.solution.length; index++) {
        if (_puzzle.solution[index] && !_blackCells[index]) {
          target = index;
          break;
        }
      }
    }
    if (target < 0) {
      for (int index = 0; index < _blackCells.length; index++) {
        if (_blackCells[index] && !_puzzle.solution[index]) {
          target = index;
          shouldShade = false;
          break;
        }
      }
    }
    if (target < 0 || !_session.canUseHint) return;
    _remember();
    _session.useHint(pointCost: 360);
    _hints++;
    setState(() {
      _selectedCell = target;
      _blackCells[target] = shouldShade;
      _edits++;
      _errorCells = <int>{};
      _notice = _english
          ? shouldShade
                ? 'Verified hint: shade row ${target ~/ _puzzle.size + 1}, column ${target % _puzzle.size + 1}.'
                : 'Verified hint: restore row ${target ~/ _puzzle.size + 1}, column ${target % _puzzle.size + 1} to white.'
          : shouldShade
          ? 'Doğrulanmış ipucu: ${target ~/ _puzzle.size + 1}. satır, ${target % _puzzle.size + 1}. sütunu gölgele.'
          : 'Doğrulanmış ipucu: ${target ~/ _puzzle.size + 1}. satır, ${target % _puzzle.size + 1}. sütunu beyaza döndür.';
    });
    _audio.hapticSelection();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .22));
  }

  Set<int> _findErrors() {
    final int size = _puzzle.size;
    final Set<int> errors = <int>{};
    for (int row = 0; row < size; row++) {
      final Map<int, List<int>> positions = <int, List<int>>{};
      for (int column = 0; column < size; column++) {
        final int cell = row * size + column;
        if (_blackCells[cell]) continue;
        positions.putIfAbsent(_puzzle.values[cell], () => <int>[]).add(cell);
      }
      for (final List<int> group in positions.values) {
        if (group.length > 1) errors.addAll(group);
      }
    }
    for (int column = 0; column < size; column++) {
      final Map<int, List<int>> positions = <int, List<int>>{};
      for (int row = 0; row < size; row++) {
        final int cell = row * size + column;
        if (_blackCells[cell]) continue;
        positions.putIfAbsent(_puzzle.values[cell], () => <int>[]).add(cell);
      }
      for (final List<int> group in positions.values) {
        if (group.length > 1) errors.addAll(group);
      }
    }
    for (int row = 0; row < size; row++) {
      for (int column = 0; column < size; column++) {
        final int cell = row * size + column;
        if (!_blackCells[cell]) continue;
        if (row + 1 < size && _blackCells[cell + size]) {
          errors.addAll(<int>{cell, cell + size});
        }
        if (column + 1 < size && _blackCells[cell + 1]) {
          errors.addAll(<int>{cell, cell + 1});
        }
      }
    }
    final List<int> white = <int>[
      for (int cell = 0; cell < _blackCells.length; cell++)
        if (!_blackCells[cell]) cell,
    ];
    if (white.isNotEmpty) {
      final Set<int> reached = <int>{white.first};
      final List<int> queue = <int>[white.first];
      for (int cursor = 0; cursor < queue.length; cursor++) {
        final int cell = queue[cursor];
        final int row = cell ~/ size;
        final int column = cell % size;
        for (final int next in <int>[
          if (row > 0) cell - size,
          if (row + 1 < size) cell + size,
          if (column > 0) cell - 1,
          if (column + 1 < size) cell + 1,
        ]) {
          if (!_blackCells[next] && reached.add(next)) queue.add(next);
        }
      }
      if (reached.length != white.length) errors.addAll(white);
    }
    return errors;
  }

  void _check() {
    if (!_ready || _finished) return;
    if (_puzzle.isSolved(_blackCells)) {
      _session.recordAccepted(points: 80);
      unawaited(_finish());
      return;
    }
    final Set<int> errors = _findErrors();
    _mistakes++;
    setState(() {
      _errorCells = errors;
      _notice = errors.isEmpty
          ? (_english
                ? 'Check whether every repeat is resolved without isolating white cells.'
                : 'Tüm tekrarların silindiğini ve beyaz hücrelerin tek bölgede kaldığını kontrol et.')
          : (_english
                ? 'Highlighted cells break a Hitori rule.'
                : 'Vurgulanan hücreler Hitori kurallarından birini bozuyor.');
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .2));
  }

  Future<void> _reset() async {
    if (!_ready || _finished) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(_english ? 'Clear this board?' : 'Tahta temizlensin mi?'),
        content: Text(
          _english ? 'The same number layout will stay in place.' : 'Aynı sayı düzeni korunacak; yalnızca işaretlerin temizlenecek.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(_english ? 'Keep solving' : 'Devam et'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(_english ? 'Clear board' : 'Temizle'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _blackCells = List<bool>.filled(_puzzle.size * _puzzle.size, false);
      _undoStack.clear();
      _selectedCell = null;
      _errorCells = <int>{};
      _hints = 0;
      _mistakes = 0;
      _edits = 0;
      _notice = null;
      _session = _newSession(_puzzle);
    });
  }

  Future<void> _finish() async {
    if (_finished || !mounted) return;
    _finished = true;
    final int score = _score;
    final int stars = _stars;
    _session.complete(
      stars: stars,
      action: widget.level.number < HitoriGamePage.totalCases
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
      titleTr: 'HITORI TAMAMLANDI',
      titleEn: 'HITORI COMPLETE',
      detailTr:
          '${_puzzle.size}×${_puzzle.size} sayı eleme · $_blackCount gölgeli hücre.',
      detailEn:
          '${_puzzle.size}×${_puzzle.size} Hitori · $_blackCount shaded cells.',
      stars: stars,
      score: score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < HitoriGamePage.totalCases,
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
          title: const Text('HITORI'),
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
          _english ? 'HITORI' : 'HITORI • SAYI ELEME',
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(child: _HitoriLevelPill(level: widget.level.number)),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(10, 2, 10, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _HitoriStatus(
                tier: _puzzle.difficultyTier,
                size: _puzzle.size,
                shaded: _blackCount,
                total: _puzzle.size * _puzzle.size,
                english: _english,
              ),
              const SizedBox(height: 9),
              _HitoriInstruction(english: _english),
              const SizedBox(height: 10),
              Center(
                child: Container(
                  key: const ValueKey<String>('hitori_board_frame'),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7EBE8),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: const Color(0xFFD9E0DC)),
                    boxShadow: StudioVisuals.softShadow,
                  ),
                  child: _HitoriBoard(
                    key: const ValueKey<String>('hitori_board'),
                    puzzle: _puzzle,
                    blackCells: _blackCells,
                    selectedCell: _selectedCell,
                    errorCells: _errorCells,
                    english: _english,
                    onTapCell: _toggleCell,
                  ),
                ),
              ),
              const SizedBox(height: 9),
              _HitoriLegend(english: _english),
              const SizedBox(height: 9),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 7,
                children: <Widget>[
                  _HitoriAction(
                    key: const ValueKey<String>('hitori_undo'),
                    icon: Icons.undo_rounded,
                    label: _english ? 'Undo' : 'Geri al',
                    enabled: _undoStack.isNotEmpty && !_finished,
                    onPressed: _undo,
                  ),
                  _HitoriAction(
                    key: const ValueKey<String>('hitori_hint'),
                    icon: Icons.lightbulb_outline_rounded,
                    label: _english ? 'Hint' : 'İpucu',
                    enabled: !_finished,
                    onPressed: _showHint,
                  ),
                  _HitoriAction(
                    key: const ValueKey<String>('hitori_reset'),
                    icon: Icons.restart_alt_rounded,
                    label: _english ? 'Reset' : 'Sıfırla',
                    enabled: !_finished,
                    onPressed: _reset,
                  ),
                ],
              ),
              const SizedBox(height: 9),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  key: const ValueKey<String>('hitori_check'),
                  onPressed: _finished ? null : _check,
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  icon: const Icon(Icons.fact_check_outlined),
                  label: Text(
                    _english ? 'Check white path' : 'Çözümü kontrol et',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              if (_notice != null) ...<Widget>[
                const SizedBox(height: 8),
                _HitoriNotice(text: _notice!, warning: _errorCells.isNotEmpty),
              ],
              const SizedBox(height: 8),
              Text(
                _english
                    ? 'Shade repeats. Black cells never share an edge; every white cell must stay in one connected region.'
                    : 'Tekrarları gölgele. Siyah hücreler kenar paylaşmaz; beyaz alan tek parça bağlı kalır.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: Color(0xFF697572),
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

class _HitoriBoard extends StatelessWidget {
  const _HitoriBoard({
    super.key,
    required this.puzzle,
    required this.blackCells,
    required this.selectedCell,
    required this.errorCells,
    required this.english,
    required this.onTapCell,
  });

  final HitoriPuzzle puzzle;
  final List<bool> blackCells;
  final int? selectedCell;
  final Set<int> errorCells;
  final bool english;
  final ValueChanged<int> onTapCell;

  @override
  Widget build(BuildContext context) {
    const double cellExtent = 48;
    final double boardWidth = puzzle.size * cellExtent + (puzzle.size - 1) * 3;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double contentWidth = math.max(boardWidth, constraints.maxWidth);
        return SingleChildScrollView(
          key: const ValueKey<String>('hitori_board_horizontal_scroll'),
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: contentWidth,
            child: Center(
              child: SizedBox(
                width: boardWidth,
                height: boardWidth,
                child: GridView.builder(
                  key: const ValueKey<String>('hitori_cells'),
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: puzzle.size,
                    mainAxisSpacing: 3,
                    crossAxisSpacing: 3,
                  ),
                  itemCount: puzzle.size * puzzle.size,
                  itemBuilder: (BuildContext context, int index) {
                    final int row = index ~/ puzzle.size;
                    final int column = index % puzzle.size;
                    return _HitoriCell(
                      key: ValueKey<String>('hitori_cell_$index'),
                      value: puzzle.values[index],
                      shaded: blackCells[index],
                      selected: selectedCell == index,
                      error: errorCells.contains(index),
                      row: row,
                      column: column,
                      english: english,
                      onTap: () => onTapCell(index),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HitoriCell extends StatelessWidget {
  const _HitoriCell({
    super.key,
    required this.value,
    required this.shaded,
    required this.selected,
    required this.error,
    required this.row,
    required this.column,
    required this.english,
    required this.onTap,
  });

  final int value;
  final bool shaded;
  final bool selected;
  final bool error;
  final int row;
  final int column;
  final bool english;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: english
        ? 'Row ${row + 1}, column ${column + 1}, number $value, ${shaded ? 'shaded' : 'white'}'
        : '${row + 1}. satır, ${column + 1}. sütun, $value, ${shaded ? 'gölgeli' : 'beyaz'}',
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey<String>('hitori_cell_tap_${row * 100 + column}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 110),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: shaded ? const Color(0xFF37444A) : const Color(0xFFFFFEFC),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: error
                  ? const Color(0xFFD96F60)
                  : selected
                  ? _HitoriPlayPageState._accent
                  : const Color(0xFFD6DFDA),
              width: error || selected ? 2 : 1,
            ),
            boxShadow: shaded
                ? const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x20313F43),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: shaded
              ? const Icon(
                  Icons.close_rounded,
                  color: Color(0xFFC8D1D0),
                  size: 17,
                )
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$value',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      color: error
                          ? const Color(0xFFB14F44)
                          : _HitoriPlayPageState._ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    ),
  );
}

class _HitoriLevelPill extends StatelessWidget {
  const _HitoriLevelPill({required this.level});
  final int level;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFE7EFEB),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: const Color(0xFFD4E2DC)),
    ),
    child: Text(
      '${context.l10n.isEnglish ? 'LEVEL' : 'SEVİYE'} ${level.toString().padLeft(2, '0')}',
      style: const TextStyle(
        fontFamily: 'Roboto',
        color: Color(0xFF3E6D64),
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: .3,
      ),
    ),
  );
}

class _HitoriStatus extends StatelessWidget {
  const _HitoriStatus({
    required this.tier,
    required this.size,
    required this.shaded,
    required this.total,
    required this.english,
  });

  final String tier;
  final int size;
  final int shaded;
  final int total;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0xFFE2E8E5)),
    ),
    child: Row(
      children: <Widget>[
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2EE),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(
            Icons.grid_view_rounded,
            color: _HitoriPlayPageState._accent,
            size: 19,
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
                  color: Color(0xFF567D76),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .7,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                english
                    ? '$size × $size · $shaded shaded'
                    : '$size × $size · $shaded gölgeli',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: _HitoriPlayPageState._ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Text(
          '$shaded/$total',
          style: const TextStyle(
            fontFamily: 'Roboto',
            color: Color(0xFF667470),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _HitoriInstruction extends StatelessWidget {
  const _HitoriInstruction({required this.english});
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFFF2F5F1),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: const Color(0xFFE4EAE5)),
    ),
    child: Row(
      children: <Widget>[
        const Icon(
          Icons.touch_app_outlined,
          color: _HitoriPlayPageState._accent,
          size: 17,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            english
                ? 'Tap a duplicate to shade it. Keep all white cells connected.'
                : 'Tekrarlanan hücreye dokunup gölgele. Beyaz alanı bağlı tut.',
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: Color(0xFF4E5D59),
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

class _HitoriLegend extends StatelessWidget {
  const _HitoriLegend({required this.english});
  final bool english;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      _HitoriLegendItem(
        color: const Color(0xFFFFFEFC),
        borderColor: const Color(0xFFD8E0DC),
        label: english ? 'Keep' : 'Kalsın',
      ),
      const SizedBox(width: 16),
      _HitoriLegendItem(
        color: const Color(0xFF37444A),
        borderColor: const Color(0xFF37444A),
        label: english ? 'Shade' : 'Gölgele',
      ),
    ],
  );
}

class _HitoriLegendItem extends StatelessWidget {
  const _HitoriLegendItem({
    required this.color,
    required this.borderColor,
    required this.label,
  });
  final Color color;
  final Color borderColor;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Container(
        width: 15,
        height: 15,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: borderColor),
        ),
      ),
      const SizedBox(width: 5),
      Text(
        label,
        style: const TextStyle(
          fontFamily: 'Roboto',
          color: Color(0xFF67736F),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _HitoriAction extends StatelessWidget {
  const _HitoriAction({
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
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: enabled ? onPressed : null,
    icon: Icon(icon, size: 16),
    label: Text(label),
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(84, 46),
      foregroundColor: const Color(0xFF48625D),
      disabledForegroundColor: const Color(0xFFAAB2AE),
      side: const BorderSide(color: Color(0xFFDCE4E0)),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      textStyle: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _HitoriNotice extends StatelessWidget {
  const _HitoriNotice({required this.text, required this.warning});
  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: warning ? const Color(0xFFFFF1ED) : const Color(0xFFEAF3EF),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: warning ? const Color(0xFFF1D6CE) : const Color(0xFFD8E8E1),
      ),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'Roboto',
        color: warning ? const Color(0xFFA85346) : const Color(0xFF3D6D5F),
        fontSize: 11,
        height: 1.25,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
