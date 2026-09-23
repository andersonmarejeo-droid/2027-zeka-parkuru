import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../services/game_audio_service.dart';
import '../../services/replayability_service.dart';
import '../shared/parkur_game_kit.dart';

class NumberSortGamePage extends StatelessWidget {
  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  const NumberSortGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  static const List<NumberSortLevel> levels = <NumberSortLevel>[
    NumberSortLevel(
      number: 1,
      titleTr: 'Sekizli Isınma',
      titleEn: 'Eight Tile Warm-Up',
      subtitleTr: '8 sayıyı kısa bir karışımdan çıkar',
      subtitleEn: 'Restore 8 numbers after a short shuffle',
      difficulty: 'KOLAY',
      dimension: 3,
      scrambleMoves: 8,
    ),
    NumberSortLevel(
      number: 2,
      titleTr: 'Petek Adımları',
      titleEn: 'Honeycomb Steps',
      subtitleTr: 'Komşu taşları boş hücreye kaydır',
      subtitleEn: 'Slide neighboring tiles into the gap',
      difficulty: 'KOLAY',
      dimension: 3,
      scrambleMoves: 14,
    ),
    NumberSortLevel(
      number: 3,
      titleTr: 'Karışan Sekizli',
      titleEn: 'Mixed Eight',
      subtitleTr: 'Daha uzun hamle zincirini çöz',
      subtitleEn: 'Solve a longer chain of moves',
      difficulty: 'ORTA',
      dimension: 3,
      scrambleMoves: 22,
    ),
    NumberSortLevel(
      number: 4,
      titleTr: 'Keskin Sıra',
      titleEn: 'Sharp Order',
      subtitleTr: '8 taşı az hamleyle sırala',
      subtitleEn: 'Order 8 tiles in fewer moves',
      difficulty: 'ORTA',
      dimension: 3,
      scrambleMoves: 34,
    ),
    NumberSortLevel(
      number: 5,
      titleTr: 'Sekizli Usta',
      titleEn: 'Eight Tile Master',
      subtitleTr: 'Küçük peteğin final düzeni',
      subtitleEn: 'The final small honeycomb',
      difficulty: 'ZOR',
      dimension: 3,
      scrambleMoves: 48,
    ),
    NumberSortLevel(
      number: 6,
      titleTr: 'On Beşli Geçiş',
      titleEn: 'Fifteen Tile Shift',
      subtitleTr: '15 sayılı büyük petek açıldı',
      subtitleEn: 'The large 15-number board opens',
      difficulty: 'ORTA',
      dimension: 4,
      scrambleMoves: 20,
    ),
    NumberSortLevel(
      number: 7,
      titleTr: 'Büyük Petek',
      titleEn: 'Large Honeycomb',
      subtitleTr: 'Dört satırda rotanı planla',
      subtitleEn: 'Plan your route across four rows',
      difficulty: 'ZOR',
      dimension: 4,
      scrambleMoves: 34,
    ),
    NumberSortLevel(
      number: 8,
      titleTr: 'Sayı Trafiği',
      titleEn: 'Number Traffic',
      subtitleTr: '15 taşı birbirine kilitlemeden sırala',
      subtitleEn: 'Order 15 tiles without blocking the path',
      difficulty: 'ZOR',
      dimension: 4,
      scrambleMoves: 52,
    ),
    NumberSortLevel(
      number: 9,
      titleTr: 'Petek Ustası',
      titleEn: 'Honeycomb Master',
      subtitleTr: 'Uzun karışımı kontrollü çöz',
      subtitleEn: 'Untangle a long controlled shuffle',
      difficulty: 'ZOR',
      dimension: 4,
      scrambleMoves: 74,
    ),
    NumberSortLevel(
      number: 10,
      titleTr: 'On Beşli Final',
      titleEn: 'Fifteen Tile Final',
      subtitleTr: '15 sayıyı kusursuz sıraya getir',
      subtitleEn: 'Restore all 15 numbers perfectly',
      difficulty: 'BOSS',
      dimension: 4,
      scrambleMoves: 100,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ParkurLevelHub(
      gameId: 'number_sort',
      progressPrefix: 'number_sort',
      titleTr: 'SAYI PETEĞİ',
      titleEn: 'NUMBER HIVE',
      taglineTr: 'Kaydır • Planla • Sırala',
      taglineEn: 'Slide • Plan • Order',
      accent: const Color(0xFFFFD334),
      icon: Icons.hive_rounded,
      levels: levels,
      dailyCourseMode: dailyCourseMode,
      competitionLevel: competitionLevel,
      competitionLayoutCode: competitionLayoutCode,
      playBuilder:
          (
            BuildContext context,
            ParkurLevelSpec level,
            int previousBestScore,
            int? fixedSessionSeed,
            bool competitionMode,
          ) {
            return NumberSortPlayPage(
              level: level as NumberSortLevel,
              previousBestScore: previousBestScore,
              fixedSessionSeed: fixedSessionSeed,
              competitionMode: competitionMode,
            );
          },
    );
  }
}

class NumberSortLevel extends ParkurLevelSpec {
  final int dimension;
  final int scrambleMoves;

  const NumberSortLevel({
    required super.number,
    required super.titleTr,
    required super.titleEn,
    required super.subtitleTr,
    required super.subtitleEn,
    required super.difficulty,
    required this.dimension,
    required this.scrambleMoves,
  }) : super(icon: Icons.hive_rounded);
}

class _NumberPuzzle {
  final List<int> tiles;
  final List<int> targetTiles;
  final List<int> solutionValues;

  const _NumberPuzzle({
    required this.tiles,
    required this.targetTiles,
    required this.solutionValues,
  });
}

class NumberSortPlayPage extends StatefulWidget {
  final NumberSortLevel level;
  final int previousBestScore;
  final int? fixedSessionSeed;
  final bool competitionMode;

  const NumberSortPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
    this.fixedSessionSeed,
    this.competitionMode = false,
  });

  @override
  State<NumberSortPlayPage> createState() => _NumberSortPlayPageState();
}

class _NumberSortPlayPageState extends State<NumberSortPlayPage> {
  static const Color _accent = Color(0xFFFFD334);
  static String? _lastGeneratedSignature;
  late Random _random;
  final GameAudioService _audio = GameAudioService.instance;
  final ReplayabilityService _replayability = ReplayabilityService();
  final List<List<int>> _history = <List<int>>[];
  Timer? _timer;

  late List<int> _tiles;
  late List<int> _initialTiles;
  late List<int> _targetTiles;
  List<int> _solutionValues = <int>[];
  List<int> _initialSolutionValues = <int>[];
  int _moves = 0;
  int _elapsed = 0;
  int _hints = 0;
  late int _sessionBestScore;
  int _sessionBestStars = 0;
  int? _hintTileIndex;
  bool _completed = false;
  bool _ready = false;

  int get _dimension => widget.level.dimension;
  int get _tileCount => _dimension * _dimension;
  bool get _usesAlternativeTarget {
    for (int index = 0; index < _targetTiles.length; index++) {
      final int standard = index + 1 == _targetTiles.length ? 0 : index + 1;
      if (_targetTiles[index] != standard) return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _random = Random(widget.fixedSessionSeed);
    _sessionBestScore = widget.previousBestScore;
    unawaited(_initializeSession());
    unawaited(_audio.preload(GameAudioGroup.numbers));
  }

  Future<void> _initializeSession() async {
    final int seed =
        widget.fixedSessionSeed ??
        await _replayability.newSeed(
          gameId: 'number_sort',
          level: widget.level.number,
        );
    _random = _replayability.randomFor(sessionSeed: seed, round: 0, salt: 907);
    if (!mounted) return;
    _newPuzzle();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _newPuzzle() {
    _timer?.cancel();
    final int minimumMisplaced = _dimension == 3 ? 4 : 8;
    _NumberPuzzle? bestCandidate;
    int bestMisplaced = -1;

    for (int attempt = 0; attempt < 24; attempt++) {
      final _NumberPuzzle candidate = _scrambleCandidate();
      final int misplaced = _misplacedCount(
        candidate.tiles,
        candidate.targetTiles,
      );
      final String signature =
          '${candidate.tiles.join(',')}>${candidate.targetTiles.join(',')}';
      if (misplaced > bestMisplaced &&
          (widget.fixedSessionSeed != null ||
              signature != _lastGeneratedSignature)) {
        bestMisplaced = misplaced;
        bestCandidate = candidate;
      }
      if (misplaced >= minimumMisplaced &&
          (widget.fixedSessionSeed != null ||
              signature != _lastGeneratedSignature)) {
        bestCandidate = candidate;
        break;
      }
    }

    final _NumberPuzzle puzzle = bestCandidate ?? _scrambleCandidate();
    _tiles = List<int>.from(puzzle.tiles);
    _targetTiles = List<int>.from(puzzle.targetTiles);
    _solutionValues = List<int>.from(puzzle.solutionValues);
    _lastGeneratedSignature = '${_tiles.join(',')}>${_targetTiles.join(',')}';
    _initialTiles = List<int>.from(_tiles);
    _initialSolutionValues = List<int>.from(_solutionValues);
    _history.clear();
    _moves = 0;
    _elapsed = 0;
    _hints = 0;
    _hintTileIndex = null;
    _completed = false;
    _ready = true;
    if (widget.fixedSessionSeed == null) {
      unawaited(
        _replayability.registerFingerprint(
          gameId: 'number_sort',
          level: widget.level.number,
          fingerprint: _lastGeneratedSignature!,
          historyLimit: 150,
        ),
      );
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (mounted && !_completed) setState(() => _elapsed++);
    });
    if (mounted) setState(() {});
  }

  _NumberPuzzle _scrambleCandidate() {
    final List<int> target = _targetForLevel();
    final List<int> candidate = List<int>.from(target);
    int empty = candidate.indexOf(0);
    int previousEmpty = -1;
    final List<int> movedValues = <int>[];
    for (int step = 0; step < widget.level.scrambleMoves; step++) {
      final List<int> options = _neighbors(empty)
          .where((int index) => index != previousEmpty)
          .toList(growable: true);
      if (options.isEmpty) options.addAll(_neighbors(empty));
      final int selected = options[_random.nextInt(options.length)];
      movedValues.add(candidate[selected]);
      candidate[empty] = candidate[selected];
      candidate[selected] = 0;
      previousEmpty = empty;
      empty = selected;
    }
    if (_isSolvedTiles(candidate, target)) {
      final int selected = _neighbors(empty).first;
      movedValues.add(candidate[selected]);
      candidate[empty] = candidate[selected];
      candidate[selected] = 0;
    }
    return _NumberPuzzle(
      tiles: candidate,
      targetTiles: target,
      solutionValues: movedValues.reversed.toList(growable: true),
    );
  }

  List<int> _targetForLevel() {
    final List<int> standard = List<int>.generate(
      _tileCount,
      (int index) => index + 1 == _tileCount ? 0 : index + 1,
    );
    final bool alternative =
        widget.level.number == 4 ||
        widget.level.number == 8 ||
        (widget.level.number >= 9 && _random.nextBool());
    if (!alternative) return standard;

    final List<int> target = <int>[];
    int value = 1;
    for (int row = 0; row < _dimension; row++) {
      final List<int> rowValues = <int>[];
      for (int column = 0; column < _dimension; column++) {
        rowValues.add(value == _tileCount ? 0 : value);
        value++;
      }
      target.addAll(row.isOdd ? rowValues.reversed : rowValues);
    }
    final int emptyIndex = target.indexOf(0);
    final int lastValue = target.last;
    target[emptyIndex] = lastValue;
    target[target.length - 1] = 0;
    return target;
  }

  int _misplacedCount(List<int> tiles, List<int> target) {
    int misplaced = 0;
    for (int index = 0; index < tiles.length; index++) {
      if (tiles[index] != target[index]) misplaced++;
    }
    return misplaced;
  }

  List<int> _neighbors(int index) {
    final int row = index ~/ _dimension;
    final int column = index % _dimension;
    final List<int> neighbors = <int>[];

    for (int rowOffset = -1; rowOffset <= 1; rowOffset++) {
      for (int columnOffset = -1; columnOffset <= 1; columnOffset++) {
        if (rowOffset == 0 && columnOffset == 0) continue;

        final int nextRow = row + rowOffset;
        final int nextColumn = column + columnOffset;

        if (nextRow < 0 ||
            nextRow >= _dimension ||
            nextColumn < 0 ||
            nextColumn >= _dimension) {
          continue;
        }

        neighbors.add(nextRow * _dimension + nextColumn);
      }
    }

    return neighbors;
  }

  Future<void> _tapTile(int index) async {
    if (_completed || _tiles[index] == 0) return;
    final int empty = _tiles.indexOf(0);
    if (!_neighbors(empty).contains(index)) {
      unawaited(_audio.play(GameSound.numberWrong, gain: 0.62));
      HapticFeedback.lightImpact();
      return;
    }
    _history.add(List<int>.from(_tiles));
    final int movedValue = _tiles[index];
    _tiles[empty] = _tiles[index];
    _tiles[index] = 0;
    if (_solutionValues.isNotEmpty && _solutionValues.first == movedValue) {
      _solutionValues.removeAt(0);
    } else {
      _solutionValues.clear();
    }
    _moves++;
    _hintTileIndex = null;
    unawaited(_audio.play(GameSound.numberSelect));
    HapticFeedback.selectionClick();
    setState(() {});
    if (_isSolved()) await _finish();
  }

  bool _isSolved() {
    return _isSolvedTiles(_tiles, _targetTiles);
  }

  bool _isSolvedTiles(List<int> tiles, List<int> target) {
    for (int index = 0; index < tiles.length; index++) {
      if (tiles[index] != target[index]) return false;
    }
    return true;
  }

  void _undo() {
    if (_history.isEmpty || _completed) return;
    setState(() {
      _tiles = _history.removeLast();
      _moves = max(0, _moves - 1);
      _solutionValues.clear();
      _hintTileIndex = null;
    });
    unawaited(_audio.play(GameSound.uiBack));
  }

  void _restart() {
    if (_completed) return;
    setState(() {
      _tiles = List<int>.from(_initialTiles);
      _solutionValues = List<int>.from(_initialSolutionValues);
      _history.clear();
      _moves = 0;
      _elapsed = 0;
      _hints = 0;
      _hintTileIndex = null;
    });
    unawaited(_audio.play(GameSound.uiBack));
  }

  int _distanceScore(List<int> tiles) {
    int distance = 0;
    for (int index = 0; index < tiles.length; index++) {
      final int tile = tiles[index];
      if (tile == 0) continue;
      final int target = _targetTiles.indexOf(tile);
      final int row = index ~/ _dimension;
      final int column = index % _dimension;
      final int targetRow = target ~/ _dimension;
      final int targetColumn = target % _dimension;
      distance += (row - targetRow).abs() + (column - targetColumn).abs();
    }
    return distance;
  }

  Future<void> _hint() async {
    if (_completed || _hints >= 3) return;
    final int empty = _tiles.indexOf(0);
    final List<int> options = _neighbors(empty);
    int? best;
    if (_solutionValues.isNotEmpty) {
      final int exactIndex = _tiles.indexOf(_solutionValues.first);
      if (options.contains(exactIndex)) best = exactIndex;
    }
    if (best == null) {
      int bestScore = 1 << 30;
      for (final int option in options) {
        final List<int> candidate = List<int>.from(_tiles);
        candidate[empty] = candidate[option];
        candidate[option] = 0;
        final int score = _distanceScore(candidate);
        if (score < bestScore) {
          bestScore = score;
          best = option;
        }
      }
    }
    _hints++;
    unawaited(_audio.play(GameSound.uiHint));
    setState(() => _hintTileIndex = best);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (mounted && !_completed) setState(() => _hintTileIndex = null);
  }

  Future<void> _finish() async {
    if (_completed) return;
    _completed = true;
    _timer?.cancel();
    final int threeStarLimit = (widget.level.scrambleMoves * 1.35).ceil();
    final int twoStarLimit = (widget.level.scrambleMoves * 2.0).ceil();
    final int stars = _moves <= threeStarLimit && _hints == 0
        ? 3
        : _moves <= twoStarLimit && _hints <= 1
        ? 2
        : 1;
    final int score = max(
      250,
      widget.level.number * 280 +
          (_tileCount - 1) * 115 +
          max(0, twoStarLimit - _moves) * 28 -
          _hints * 150,
    );
    unawaited(_audio.play(GameSound.levelComplete));
    _sessionBestScore = max(_sessionBestScore, score);
    _sessionBestStars = max(_sessionBestStars, stars);
    if (!mounted) return;
    if (widget.competitionMode) {
      Navigator.pop(
        context,
        ParkurGameResult(
          completed: true,
          stars: _sessionBestStars,
          score: _sessionBestScore,
          nextLevel: false,
        ),
      );
      return;
    }
    final ParkurResultAction? action = await showParkurResultDialog(
      context: context,
      accent: _accent,
      titleTr: 'Sayı Peteği Tamamlandı!',
      titleEn: 'Number Hive Complete!',
      detailTr: '${_tileCount - 1} sayı • $_moves hamle • $_elapsed sn',
      detailEn: '${_tileCount - 1} numbers • $_moves moves • $_elapsed sec',
      stars: stars,
      score: score,
      previousBestScore: _sessionBestScore,
      canGoNext: widget.level.number < NumberSortGamePage.levels.length,
    );
    if (!mounted || action == null) return;
    if (action == ParkurResultAction.replay) {
      Navigator.pop(
        context,
        ParkurGameResult(
          completed: true,
          stars: _sessionBestStars,
          score: _sessionBestScore,
          nextLevel: false,
          replayLevel: true,
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      ParkurGameResult(
        completed: true,
        stars: _sessionBestStars,
        score: _sessionBestScore,
        nextLevel: action == ParkurResultAction.next,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool english = context.l10n.isEnglish;
    if (!_ready) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          '${context.l10n.gameUi(english ? widget.level.titleEn : widget.level.titleTr)}  •  ${widget.level.number}/10',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints limits) {
            final double boardSize = min(limits.maxWidth - 28, 430);
            final bool compact = limits.maxHeight < 650;
            final bool narrow = limits.maxWidth < 380;
            final ButtonStyle compactOutlineStyle = OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: narrow ? 5 : 12),
              textStyle: TextStyle(fontSize: narrow ? 11 : 13),
            );
            return ListView(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
              children: <Widget>[
                _NumberSortHeader(
                  moves: _moves,
                  elapsed: _elapsed,
                  hints: 3 - _hints,
                  english: english,
                ),
                SizedBox(height: compact ? 10 : 17),
                Center(
                  child: SizedBox(
                    width: boardSize,
                    height: boardSize,
                    child: Container(
                      padding: EdgeInsets.all(_dimension == 3 ? 20 : 15),
                      decoration: BoxDecoration(
                        gradient: const RadialGradient(
                          colors: <Color>[Color(0xFF304062), Color(0xFF102644)],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _accent.withValues(alpha: 0.48),
                          width: 2,
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: _accent.withValues(alpha: 0.18),
                            blurRadius: 28,
                            spreadRadius: -10,
                          ),
                        ],
                      ),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _tiles.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _dimension,
                          crossAxisSpacing: _dimension == 3 ? 7 : 5,
                          mainAxisSpacing: _dimension == 3 ? 7 : 5,
                        ),
                        itemBuilder: (BuildContext context, int index) {
                          final int row = index ~/ _dimension;
                          final int value = _tiles[index];
                          return FractionalTranslation(
                            translation: Offset(row.isOdd ? 0.12 : -0.04, 0),
                            child: value == 0
                                ? _EmptyHex(size: _dimension)
                                : _NumberHex(
                                    value: value,
                                    correct: value == _targetTiles[index],
                                    hinted: _hintTileIndex == index,
                                    compact: _dimension == 4,
                                    onTap: () => _tapTile(index),
                                  ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(height: compact ? 10 : 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _history.isEmpty ? null : _undo,
                        style: compactOutlineStyle,
                        icon: const Icon(Icons.undo_rounded),
                        label: Text(
                          context.l10n.gameUi(english ? 'UNDO' : 'GERİ AL'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _restart,
                        style: compactOutlineStyle,
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(
                          context.l10n.gameUi(english ? 'RESET' : 'BAŞTAN'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _hints >= 3 ? null : _hint,
                        style: FilledButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: const Color(0xFF3A2A00),
                          padding: EdgeInsets.symmetric(
                            horizontal: narrow ? 5 : 12,
                          ),
                          textStyle: TextStyle(fontSize: narrow ? 11 : 13),
                        ),
                        icon: const Icon(Icons.lightbulb_rounded),
                        label: Text(
                          '${context.l10n.gameUi(english ? 'HINT' : 'İPUCU')} ${3 - _hints}',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  english
                      ? _usesAlternativeTarget
                            ? 'Snake target: ${_targetTiles.map((int value) => value == 0 ? '□' : value).join(' ')}'
                            : 'Tap a tile touching the empty cell. Green tiles are already in place.'
                      : _usesAlternativeTarget
                      ? 'Yılan hedefi: ${_targetTiles.map((int value) => value == 0 ? '□' : value).join(' ')}'
                      : 'Boş hücreye temas eden bir sayıya dokun. Yeşil taşlar doğru yerindedir.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HexClipper extends CustomClipper<Path> {
  const _HexClipper();

  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(size.width * 0.25, 0)
      ..lineTo(size.width * 0.75, 0)
      ..lineTo(size.width, size.height * 0.5)
      ..lineTo(size.width * 0.75, size.height)
      ..lineTo(size.width * 0.25, size.height)
      ..lineTo(0, size.height * 0.5)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _NumberHex extends StatelessWidget {
  final int value;
  final bool correct;
  final bool hinted;
  final bool compact;
  final VoidCallback onTap;

  const _NumberHex({
    required this.value,
    required this.correct,
    required this.hinted,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = hinted
        ? const Color(0xFFFFD334)
        : correct
        ? const Color(0xFF6CFF9B)
        : const Color(0xFF00D9FF);
    return GestureDetector(
      onTap: onTap,
      child: ClipPath(
        clipper: const _HexClipper(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color.lerp(color, Colors.white, 0.28)!,
                color.withValues(alpha: 0.72),
                Color.lerp(color, Colors.black, 0.30)!,
              ],
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 10),
            ],
          ),
          child: Text(
            '$value',
            style: TextStyle(
              color: const Color(0xFF06213A),
              fontSize: compact ? 19 : 25,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyHex extends StatelessWidget {
  final int size;

  const _EmptyHex({required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const _HexClipper(),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.22),
          border: Border.all(color: Colors.white10),
        ),
        child: Icon(
          Icons.hive_outlined,
          color: Colors.white10,
          size: size == 3 ? 30 : 22,
        ),
      ),
    );
  }
}

class _NumberSortHeader extends StatelessWidget {
  final int moves;
  final int elapsed;
  final int hints;
  final bool english;

  const _NumberSortHeader({
    required this.moves,
    required this.elapsed,
    required this.hints,
    required this.english,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFF102B50),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _HeaderValue(
            Icons.swap_horiz_rounded,
            '$moves',
            context.l10n.gameUi(english ? 'MOVES' : 'HAMLE'),
            const Color(0xFFFFD334),
          ),
          _HeaderValue(
            Icons.timer_outlined,
            '${elapsed}s',
            context.l10n.gameUi(english ? 'TIME' : 'SÜRE'),
            const Color(0xFF00D9FF),
          ),
          _HeaderValue(
            Icons.lightbulb_rounded,
            '$hints',
            context.l10n.gameUi(english ? 'HINTS' : 'İPUCU'),
            const Color(0xFF6CFF9B),
          ),
        ],
      ),
    );
  }
}

class _HeaderValue extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _HeaderValue(this.icon, this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              value,
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 7),
            ),
          ],
        ),
      ],
    );
  }
}
