import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/studio_visuals.dart';

import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../services/game_audio_service.dart';
import '../../services/replayability_service.dart';
import '../shared/parkur_game_kit.dart';
import '../shared/studio_game_contracts.dart';

class ShapePuzzleGamePage extends StatelessWidget {
  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  const ShapePuzzleGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  static const List<ShapePuzzleLevel> levels = <ShapePuzzleLevel>[
    ShapePuzzleLevel(
      number: 1,
      titleTr: 'İki Parça',
      titleEn: 'Two Pieces',
      subtitleTr: '6 soruda iki parçanın oluşturduğu şekli bul',
      subtitleEn: 'Find 6 silhouettes made by two pieces',
      difficulty: 'KOLAY',
      dimension: 3,
      pieceCount: 2,
      targetCells: 5,
      questionCount: 6,
      targetSeconds: 63,
    ),
    ShapePuzzleLevel(
      number: 2,
      titleTr: 'Köşe Birleşimi',
      titleEn: 'Corner Merge',
      subtitleTr: '7 soruda parçaları aynı zeminde düşün',
      subtitleEn: 'Merge pieces on the same grid 7 times',
      difficulty: 'KOLAY',
      dimension: 3,
      pieceCount: 2,
      targetCells: 6,
      questionCount: 7,
      targetSeconds: 70,
    ),
    ShapePuzzleLevel(
      number: 3,
      titleTr: 'Üçlü Parça',
      titleEn: 'Three Pieces',
      subtitleTr: '7 soruda üç rengi tek silüete dönüştür',
      subtitleEn: 'Turn three colors into 7 silhouettes',
      difficulty: 'ORTA',
      dimension: 3,
      pieceCount: 3,
      targetCells: 7,
      questionCount: 7,
      targetSeconds: 82,
    ),
    ShapePuzzleLevel(
      number: 4,
      titleTr: 'Eksik Hücre',
      titleEn: 'Missing Cell',
      subtitleTr: '8 soruda benzer silüetleri ayırt et',
      subtitleEn: 'Compare similar silhouettes 8 times',
      difficulty: 'ORTA',
      dimension: 3,
      pieceCount: 3,
      targetCells: 8,
      questionCount: 8,
      targetSeconds: 88,
    ),
    ShapePuzzleLevel(
      number: 5,
      titleTr: 'Büyük Zemin',
      titleEn: 'Larger Grid',
      subtitleTr: '8 soruda 4×4 zemin birleşimini tamamla',
      subtitleEn: 'Complete 8 merges on a 4×4 grid',
      difficulty: 'ORTA',
      dimension: 4,
      pieceCount: 2,
      targetCells: 8,
      questionCount: 8,
      targetSeconds: 96,
    ),
    ShapePuzzleLevel(
      number: 6,
      titleTr: 'Parça Ağı',
      titleEn: 'Piece Network',
      subtitleTr: '9 soruda üç parçayı zihninde birleştir',
      subtitleEn: 'Combine three pieces in 9 questions',
      difficulty: 'ZOR',
      dimension: 4,
      pieceCount: 3,
      targetCells: 9,
      questionCount: 9,
      targetSeconds: 104,
    ),
    ShapePuzzleLevel(
      number: 7,
      titleTr: 'Yoğun Silüet',
      titleEn: 'Dense Silhouette',
      subtitleTr: '9 soruda benzer silüetleri dikkatle ayır',
      subtitleEn: 'Separate similar silhouettes 9 times',
      difficulty: 'ZOR',
      dimension: 4,
      pieceCount: 3,
      targetCells: 10,
      questionCount: 9,
      targetSeconds: 114,
    ),
    ShapePuzzleLevel(
      number: 8,
      titleTr: 'Dört Parça',
      titleEn: 'Four Pieces',
      subtitleTr: '10 soruda dört rengi tek hedefte birleştir',
      subtitleEn: 'Merge four colors across 10 questions',
      difficulty: 'ZOR',
      dimension: 4,
      pieceCount: 4,
      targetCells: 11,
      questionCount: 10,
      targetSeconds: 123,
    ),
    ShapePuzzleLevel(
      number: 9,
      titleTr: 'Şekil Ustası',
      titleEn: 'Shape Master',
      subtitleTr: '11 karmaşık birleşimi dikkatle tamamla',
      subtitleEn: 'Complete 11 complex merges precisely',
      difficulty: 'ZOR',
      dimension: 4,
      pieceCount: 4,
      targetCells: 12,
      questionCount: 11,
      targetSeconds: 132,
    ),
    ShapePuzzleLevel(
      number: 10,
      titleTr: 'Silüet Finali',
      titleEn: 'Silhouette Final',
      subtitleTr: '12 dört parçalı final silüetini tamamla',
      subtitleEn: 'Complete 12 four-piece final silhouettes',
      difficulty: 'BOSS',
      dimension: 4,
      pieceCount: 4,
      targetCells: 13,
      questionCount: 12,
      targetSeconds: 144,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ParkurLevelHub(
      gameId: 'shape_puzzle',
      progressPrefix: 'shape_puzzle',
      titleTr: 'ŞEKİL BİRLEŞTİR',
      titleEn: 'SHAPE MERGE',
      taglineTr: 'İncele • Birleştir • Silüeti Bul',
      taglineEn: 'Observe • Merge • Find the Shape',
      accent: const Color(0xFF665AA2),
      icon: Icons.interests_rounded,
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
            return ShapePuzzlePlayPage(
              level: level as ShapePuzzleLevel,
              previousBestScore: previousBestScore,
              fixedSessionSeed: fixedSessionSeed ?? level.poolIndex,
              competitionMode: competitionMode,
            );
          },
    );
  }
}

class ShapePuzzleLevel extends ParkurLevelSpec {
  final int dimension;
  final int pieceCount;
  final int targetCells;
  final int questionCount;
  final int targetSeconds;

  const ShapePuzzleLevel({
    super.sourceNumber,
    super.poolIndex,
    required super.number,
    required super.titleTr,
    required super.titleEn,
    required super.subtitleTr,
    required super.subtitleEn,
    required super.difficulty,
    required this.dimension,
    required this.pieceCount,
    required this.targetCells,
    required this.questionCount,
    required this.targetSeconds,
  }) : super(icon: Icons.category_rounded);
  @override
  ShapePuzzleLevel campaignCopy({
    required int number,
    int? sourceNumber,
    int? poolIndex,
    String? titleTr,
    String? titleEn,
    String? difficulty,
  }) => ShapePuzzleLevel(
    number: number,
    sourceNumber: sourceNumber,
    poolIndex: poolIndex,
    titleTr: titleTr ?? this.titleTr,
    titleEn: titleEn ?? this.titleEn,
    subtitleTr: subtitleTr,
    subtitleEn: subtitleEn,
    difficulty: difficulty ?? this.difficulty,
    dimension: dimension,
    pieceCount: pieceCount,
    targetCells: targetCells,
    questionCount: questionCount,
    targetSeconds: targetSeconds,
  );
}

enum _ShapeQuestionMode { merge, rotate, mirror, negativeSpace }

class _ShapeQuestion {
  final List<Set<int>> pieces;
  final List<Set<int>> options;
  final int correctIndex;
  final _ShapeQuestionMode mode;
  final int quarterTurns;

  const _ShapeQuestion({
    required this.pieces,
    required this.options,
    required this.correctIndex,
    required this.mode,
    this.quarterTurns = 0,
  });
}

class ShapePuzzlePlayPage extends StatefulWidget {
  final ShapePuzzleLevel level;
  final int previousBestScore;
  final int? fixedSessionSeed;
  final bool competitionMode;

  const ShapePuzzlePlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
    this.fixedSessionSeed,
    this.competitionMode = false,
  });

  @override
  State<ShapePuzzlePlayPage> createState() => _ShapePuzzlePlayPageState();
}

class _ShapePuzzlePlayPageState extends State<ShapePuzzlePlayPage> {
  static const Color _accent = Color(0xFF665AA2);
  static String? _lastGeneratedSignature;
  static const List<Color> _pieceColors = <Color>[
    Color(0xFF3D7183),
    Color(0xFF9C5471),
    Color(0xFF8B622C),
    Color(0xFF34715D),
  ];

  late Random _random;
  final GameAudioService _audio = GameAudioService.instance;
  final ReplayabilityService _replayability = ReplayabilityService();
  Timer? _timer;

  late List<_ShapeQuestion> _questions;
  int _questionIndex = 0;
  int _correct = 0;
  int _mistakes = 0;
  int _elapsed = 0;
  late int _sessionBestScore;
  int _sessionBestStars = 0;
  int? _selected;
  bool _locked = false;
  bool _completed = false;
  bool _ready = false;

  _ShapeQuestion get _question => _questions[_questionIndex];

  @override
  void initState() {
    super.initState();
    _random = Random(widget.fixedSessionSeed);
    _sessionBestScore = widget.previousBestScore;
    unawaited(_initializeSession());
    unawaited(_audio.preload(GameAudioGroup.blocks));
  }

  Future<void> _initializeSession() async {
    final int seed =
        widget.fixedSessionSeed ??
        await _replayability.newSeed(
          gameId: 'shape_puzzle',
          level: widget.level.number,
        );
    _random = _replayability.randomFor(sessionSeed: seed, round: 0, salt: 607);
    if (!mounted) return;
    _startTest();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTest() {
    _timer?.cancel();
    List<_ShapeQuestion> nextQuestions = _generateQuestionSet();
    for (
      int attempt = 0;
      attempt < 5 &&
          widget.fixedSessionSeed == null &&
          _questionSetSignature(nextQuestions) == _lastGeneratedSignature;
      attempt++
    ) {
      nextQuestions = _generateQuestionSet();
    }
    _questions = nextQuestions;
    _lastGeneratedSignature = _questionSetSignature(nextQuestions);
    _questionIndex = 0;
    _correct = 0;
    _mistakes = 0;
    _elapsed = 0;
    _selected = null;
    _locked = false;
    _completed = false;
    _ready = true;
    if (widget.fixedSessionSeed == null) {
      unawaited(
        _replayability.registerFingerprint(
          gameId: 'shape_puzzle',
          level: widget.level.number,
          fingerprint: _questionSetSignature(nextQuestions),
          historyLimit: 200,
        ),
      );
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (mounted && !_completed) setState(() => _elapsed++);
    });
    if (mounted) setState(() {});
  }

  List<_ShapeQuestion> _generateQuestionSet() {
    final List<_ShapeQuestion> questions = <_ShapeQuestion>[];
    final Set<String> signatures = <String>{};

    for (int index = 0; index < widget.level.questionCount; index++) {
      _ShapeQuestion question = _generateQuestion();
      String signature = _questionSignature(question);
      for (
        int attempt = 0;
        attempt < 40 && signatures.contains(signature);
        attempt++
      ) {
        question = _generateQuestion();
        signature = _questionSignature(question);
      }
      questions.add(question);
      signatures.add(signature);
    }

    return questions;
  }

  String _questionSignature(_ShapeQuestion question) {
    final String pieces = question.pieces.map(_signature).join('/');
    final List<String> options =
        question.options.map(_signature).toList(growable: false)..sort();
    return '${question.mode.index}:${question.quarterTurns}:$pieces|'
        '${options.join('/')}';
  }

  String _questionSetSignature(List<_ShapeQuestion> questions) {
    return questions.map(_questionSignature).join('||');
  }

  _ShapeQuestion _generateQuestion() {
    final Set<int> target = _connectedShape(
      widget.level.dimension,
      widget.level.targetCells,
    );
    final List<_ShapeQuestionMode> modes = <_ShapeQuestionMode>[
      _ShapeQuestionMode.merge,
    ];
    if (widget.level.contentLevel >= 3) modes.add(_ShapeQuestionMode.rotate);
    if (widget.level.contentLevel >= 6) modes.add(_ShapeQuestionMode.mirror);
    if (widget.level.contentLevel >= 8) {
      modes.add(_ShapeQuestionMode.negativeSpace);
    }
    if (widget.level.contentLevel >= 10) {
      modes
        ..add(_ShapeQuestionMode.rotate)
        ..add(_ShapeQuestionMode.mirror);
    }
    final _ShapeQuestionMode mode = modes[_random.nextInt(modes.length)];
    final int quarterTurns = mode == _ShapeQuestionMode.rotate
        ? 1 + _random.nextInt(3)
        : 0;

    final List<int> shuffledCells = target.toList(growable: true)
      ..shuffle(_random);
    List<Set<int>> pieces = List<Set<int>>.generate(
      widget.level.pieceCount,
      (_) => <int>{},
    );
    for (int index = 0; index < shuffledCells.length; index++) {
      pieces[index % pieces.length].add(shuffledCells[index]);
    }

    Set<int> answer = target;
    switch (mode) {
      case _ShapeQuestionMode.merge:
        break;
      case _ShapeQuestionMode.rotate:
        pieces = <Set<int>>[target];
        answer = _rotateShape(target, widget.level.dimension, quarterTurns);
        break;
      case _ShapeQuestionMode.mirror:
        pieces = <Set<int>>[target];
        answer = _mirrorShape(target, widget.level.dimension);
        break;
      case _ShapeQuestionMode.negativeSpace:
        pieces = <Set<int>>[target];
        answer = <int>{
          for (
            int cell = 0;
            cell < widget.level.dimension * widget.level.dimension;
            cell++
          )
            if (!target.contains(cell)) cell,
        };
        break;
    }

    final Map<String, Set<int>> unique = <String, Set<int>>{
      _signature(answer): answer,
    };
    int guard = 0;
    while (unique.length < 4 && guard < 400) {
      guard++;
      final Set<int> distractor = _mutateShape(answer, widget.level.dimension);
      unique[_signature(distractor)] = distractor;
    }
    final List<Set<int>> options =
        unique.values
            .map((Set<int> value) => Set<int>.from(value))
            .toList(growable: true)
          ..shuffle(_random);
    return _ShapeQuestion(
      pieces: pieces,
      options: options,
      correctIndex: options.indexWhere(
        (Set<int> option) => _signature(option) == _signature(answer),
      ),
      mode: mode,
      quarterTurns: quarterTurns,
    );
  }

  Set<int> _rotateShape(Set<int> source, int dimension, int quarterTurns) {
    Set<int> result = Set<int>.from(source);
    for (int turn = 0; turn < quarterTurns; turn++) {
      result = result.map((int cell) {
        final int row = cell ~/ dimension;
        final int column = cell % dimension;
        return column * dimension + (dimension - 1 - row);
      }).toSet();
    }
    return result;
  }

  Set<int> _mirrorShape(Set<int> source, int dimension) {
    return source.map((int cell) {
      final int row = cell ~/ dimension;
      final int column = cell % dimension;
      return row * dimension + (dimension - 1 - column);
    }).toSet();
  }

  Set<int> _connectedShape(int dimension, int count) {
    final int start = _random.nextInt(dimension * dimension);
    final Set<int> cells = <int>{start};
    int guard = 0;
    while (cells.length < count && guard < 500) {
      guard++;
      final int anchor = cells.elementAt(_random.nextInt(cells.length));
      final List<int> neighbors = _orthogonalNeighbors(
        anchor,
        dimension,
      ).where((int value) => !cells.contains(value)).toList(growable: true);
      if (neighbors.isEmpty) continue;
      cells.add(neighbors[_random.nextInt(neighbors.length)]);
    }
    return cells;
  }

  List<int> _orthogonalNeighbors(int index, int dimension) {
    final int row = index ~/ dimension;
    final int column = index % dimension;
    return <Point<int>>[
          Point<int>(column - 1, row),
          Point<int>(column + 1, row),
          Point<int>(column, row - 1),
          Point<int>(column, row + 1),
        ]
        .where(
          (Point<int> point) =>
              point.x >= 0 &&
              point.x < dimension &&
              point.y >= 0 &&
              point.y < dimension,
        )
        .map((Point<int> point) => point.y * dimension + point.x)
        .toList(growable: false);
  }

  Set<int> _mutateShape(Set<int> source, int dimension) {
    final List<int> removable = source.toList(growable: true)..shuffle(_random);
    for (final int removed in removable) {
      final Set<int> result = Set<int>.from(source)..remove(removed);
      if (!_isConnected(result, dimension)) continue;
      final List<int> possibleAdds =
          <int>{
                for (final int cell in result)
                  ..._orthogonalNeighbors(cell, dimension),
              }
              .where((int value) => !result.contains(value) && value != removed)
              .toList(growable: true)
            ..shuffle(_random);
      if (possibleAdds.isEmpty) continue;
      result.add(possibleAdds.first);
      if (_signature(result) != _signature(source)) return result;
    }
    final List<int> active = source.toList(growable: true)..shuffle(_random);
    final List<int> inactive = <int>[
      for (int cell = 0; cell < dimension * dimension; cell++)
        if (!source.contains(cell)) cell,
    ]..shuffle(_random);
    if (active.isEmpty || inactive.isEmpty) return Set<int>.from(source);
    return Set<int>.from(source)
      ..remove(active.first)
      ..add(inactive.first);
  }

  bool _isConnected(Set<int> shape, int dimension) {
    if (shape.isEmpty) return false;
    final Set<int> visited = <int>{};
    final List<int> pending = <int>[shape.first];
    while (pending.isNotEmpty) {
      final int current = pending.removeLast();
      if (!visited.add(current)) continue;
      pending.addAll(
        _orthogonalNeighbors(current, dimension).where(
          (int value) => shape.contains(value) && !visited.contains(value),
        ),
      );
    }
    return visited.length == shape.length;
  }

  String _signature(Set<int> shape) {
    final List<int> values = shape.toList(growable: true)..sort();
    return values.join(',');
  }

  String _prompt(bool english) {
    return switch (_question.mode) {
      _ShapeQuestionMode.merge =>
        english
            ? 'Overlay the colored fragments. Which silhouette appears?'
            : 'Renkli parçaları aynı zeminde birleştir. Hangi silüet oluşur?',
      _ShapeQuestionMode.rotate =>
        english
            ? 'Rotate the shape ${_question.quarterTurns * 90}° clockwise.'
            : 'Şekli saat yönünde ${_question.quarterTurns * 90}° döndür.',
      _ShapeQuestionMode.mirror =>
        english
            ? 'Find the horizontal mirror image of the shape.'
            : 'Şeklin yatay ayna görüntüsünü bul.',
      _ShapeQuestionMode.negativeSpace =>
        english
            ? 'Choose the empty cells around the colored shape.'
            : 'Renkli şeklin çevresinde boş kalan hücreleri seç.',
    };
  }

  String _explanation(bool english) {
    return switch (_question.mode) {
      _ShapeQuestionMode.merge =>
        english
            ? 'The fragments keep their cells and form one combined silhouette.'
            : 'Parçalar hücrelerini koruyarak tek bir silüet oluşturur.',
      _ShapeQuestionMode.rotate =>
        english
            ? 'Every occupied cell moves ${_question.quarterTurns * 90}° clockwise.'
            : 'Dolu hücrelerin tamamı saat yönünde ${_question.quarterTurns * 90}° taşınır.',
      _ShapeQuestionMode.mirror =>
        english
            ? 'Left and right columns exchange places in a horizontal mirror.'
            : 'Yatay aynada sol ve sağ sütunlar karşılıklı yer değiştirir.',
      _ShapeQuestionMode.negativeSpace =>
        english
            ? 'The answer contains every cell not occupied by the colored shape.'
            : 'Cevap, renkli şeklin kaplamadığı bütün hücreleri içerir.',
    };
  }

  Future<void> _select(int index) async {
    if (_locked || _completed) return;
    _locked = true;
    _selected = index;
    if (index == _question.correctIndex) {
      _correct++;
      unawaited(_audio.play(GameSound.success));
      HapticFeedback.mediumImpact();
    } else {
      _mistakes++;
      unawaited(_audio.play(GameSound.numberWrong));
      HapticFeedback.lightImpact();
    }
    if (mounted) setState(() {});
    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (!mounted) return;
    if (_questionIndex + 1 >= _questions.length) {
      await _finish();
      return;
    }
    setState(() {
      _questionIndex++;
      _selected = null;
      _locked = false;
    });
  }

  Future<void> _finish() async {
    if (_completed) return;
    _completed = true;
    _timer?.cancel();
    final double accuracy = _correct / widget.level.questionCount;
    final int stars = accuracy >= 0.9 && _elapsed <= widget.level.targetSeconds
        ? 3
        : accuracy >= 0.7
        ? 2
        : 1;
    final int score = max(
      200,
      widget.level.number * 250 +
          _correct * 250 +
          widget.level.pieceCount * 130 +
          max(0, widget.level.targetSeconds - _elapsed) * 9 -
          _mistakes * 90,
    );
    unawaited(
      _audio.playLevelComplete(levelNumber: widget.level.number),
    );
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
      titleTr: 'Şekiller Birleşti!',
      titleEn: 'Shapes Merged!',
      detailTr:
          '$_correct/${widget.level.questionCount} doğru • $_elapsed sn • $_mistakes hata',
      detailEn:
          '$_correct/${widget.level.questionCount} correct • $_elapsed sec • $_mistakes misses',
      stars: stars,
      score: score,
      previousBestScore: _sessionBestScore,
      canGoNext: widget.level.number < GameContentPolicy.campaignLevels,
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
          '${context.l10n.gameUi(english ? widget.level.titleEn : widget.level.titleTr)}  •  ${widget.level.number}/${GameContentPolicy.campaignLevels}',
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints limits) {
            final bool compact = limits.maxHeight < 650;
            final ColorScheme colors = Theme.of(context).colorScheme;
            return ListView(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
              children: <Widget>[
                _ShapeHeader(
                  current: _questionIndex + 1,
                  total: _questions.length,
                  correct: _correct,
                  elapsed: _elapsed,
                  english: english,
                ),
                SizedBox(height: compact ? 9 : 14),
                Text(
                  _prompt(english),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: compact ? 9 : 14),
                Container(
                  padding: EdgeInsets.all(compact ? 10 : 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: <Color>[Color(0xFFFFFFFF), Color(0xFFEEF3F0)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _accent.withValues(alpha: 0.42)),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: List<Widget>.generate(
                            _question.pieces.length,
                            (int index) => SizedBox(
                              width: _question.pieces.length >= 4
                                  ? compact
                                        ? 58
                                        : 68
                                  : compact
                                  ? 72
                                  : 84,
                              height: _question.pieces.length >= 4
                                  ? compact
                                        ? 58
                                        : 68
                                  : compact
                                  ? 72
                                  : 84,
                              child: _MaskView(
                                mask: _question.pieces[index],
                                dimension: widget.level.dimension,
                                color: _pieceColors[index],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.double_arrow_rounded,
                          color: Color(0xFFBBAAFF),
                          size: 27,
                        ),
                      ),
                      Container(
                        width: compact ? 72 : 88,
                        height: compact ? 72 : 88,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(19),
                          border: Border.all(color: _accent),
                        ),
                        child: const Text(
                          '?',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            color: Color(0xFF665AA2),
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: compact ? 10 : 15),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _question.options.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    mainAxisExtent: compact ? 117 : 137,
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    final bool correct = index == _question.correctIndex;
                    final bool selected = index == _selected;
                    Color border = colors.outlineVariant;
                    Color background = colors.surface;
                    if (_locked && correct) {
                      border = const Color(0xFF27865A);
                      background = const Color(0xFFEAF7EF);
                    }
                    if (_locked && selected && !correct) {
                      border = const Color(0xFFD64F63);
                      background = const Color(0xFFFFEFF1);
                    } else if (selected && !_locked) {
                      border = const Color(0xFF4A84C5);
                      background = const Color(0xFFEEF5FC);
                    }
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _select(index),
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: background,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: border, width: 1.4),
                          ),
                          child: Stack(
                            children: <Widget>[
                              Center(
                                child: SizedBox.square(
                                  dimension: compact ? 78 : 98,
                                  child: _MaskView(
                                    mask: _question.options[index],
                                    dimension: widget.level.dimension,
                                    color: _locked && correct
                                        ? const Color(0xFF34715D)
                                        : const Color(0xFF665AA2),
                                  ),
                                ),
                              ),
                              Text(
                                String.fromCharCode(65 + index),
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  color: colors.onSurfaceVariant,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  _locked
                      ? _explanation(english)
                      : english
                      ? 'Inspect the grid positions before choosing.'
                      : 'Seçmeden önce hücre konumlarını dikkatle incele.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MaskView extends StatelessWidget {
  final Set<int> mask;
  final int dimension;
  final Color color;

  const _MaskView({
    required this.mask,
    required this.dimension,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: GridView.builder(
        primary: false,
        padding: EdgeInsets.zero,
        clipBehavior: Clip.none,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: dimension * dimension,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: dimension,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemBuilder: (BuildContext context, int index) {
          final bool active = mask.contains(index);
          return AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              gradient: active
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        Color.lerp(color, Colors.white, 0.34)!,
                        color,
                      ],
                    )
                  : null,
              color: active ? null : Colors.white.withValues(alpha: 0.035),
              borderRadius: BorderRadius.circular(3),
              boxShadow: active
                  ? <BoxShadow>[
                      BoxShadow(
                        color: color.withValues(alpha: 0.30),
                        blurRadius: 4,
                      ),
                    ]
                  : null,
            ),
          );
        },
      ),
    );
  }
}

class _ShapeHeader extends StatelessWidget {
  final int current;
  final int total;
  final int correct;
  final int elapsed;
  final bool english;

  const _ShapeHeader({
    required this.current,
    required this.total,
    required this.correct,
    required this.elapsed,
    required this.english,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: StudioVisuals.line),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              '${context.l10n.gameUi(english ? 'QUESTION' : 'SORU')} $current/$total',
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF34715D),
            size: 18,
          ),
          const SizedBox(width: 5),
          Text(
            '$correct',
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 13),
          const Icon(Icons.timer_outlined, color: Color(0xFF3D7183), size: 18),
          const SizedBox(width: 5),
          Text(
            '${elapsed}s',
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
