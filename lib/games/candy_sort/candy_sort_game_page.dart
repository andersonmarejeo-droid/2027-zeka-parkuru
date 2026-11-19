import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../services/game_audio_service.dart';
import '../../services/replayability_service.dart';
import '../../theme/studio_visuals.dart';
import '../reference_games/reference_game_support.dart';
import '../shared/parkur_game_kit.dart';
import '../shared/studio_game_contracts.dart';

class CandySortGamePage extends StatelessWidget {
  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  const CandySortGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  static const List<CandySortLevel> levels = <CandySortLevel>[
    CandySortLevel(
      number: 1,
      titleTr: 'Tatlı Başlangıç',
      titleEn: 'Sweet Start',
      subtitleTr: '3 rengi üçlü kavanozlarda ayır',
      subtitleEn: 'Sort 3 colors in small jars',
      difficulty: 'KOLAY',
      colorCount: 3,
      capacity: 3,
      scrambleMoves: 8,
    ),
    CandySortLevel(
      number: 2,
      titleTr: 'Dört Kat',
      titleEn: 'Four Layers',
      subtitleTr: 'Kavanozlar artık 4 şeker alıyor',
      subtitleEn: 'Each jar now holds 4 candies',
      difficulty: 'KOLAY',
      colorCount: 3,
      capacity: 4,
      scrambleMoves: 12,
    ),
    CandySortLevel(
      number: 3,
      titleTr: 'Yeni Aroma',
      titleEn: 'New Flavor',
      subtitleTr: 'Dördüncü renk oyuna katılıyor',
      subtitleEn: 'A fourth color joins the puzzle',
      difficulty: 'ORTA',
      colorCount: 4,
      capacity: 3,
      scrambleMoves: 16,
    ),
    CandySortLevel(
      number: 4,
      titleTr: 'Renk Karışımı',
      titleEn: 'Color Mix',
      subtitleTr: 'Dört renk ve daha derin kavanozlar',
      subtitleEn: 'Four colors and deeper jars',
      difficulty: 'ORTA',
      colorCount: 4,
      capacity: 4,
      scrambleMoves: 22,
    ),
    CandySortLevel(
      number: 5,
      titleTr: 'Dar Hamleler',
      titleEn: 'Tight Moves',
      subtitleTr: 'Boş alanı dikkatli kullan',
      subtitleEn: 'Use empty space carefully',
      difficulty: 'ORTA',
      colorCount: 4,
      capacity: 4,
      scrambleMoves: 30,
    ),
    CandySortLevel(
      number: 6,
      titleTr: 'Beşli Paket',
      titleEn: 'Five Flavors',
      subtitleTr: '5 rengi doğru kavanozlarda topla',
      subtitleEn: 'Group 5 colors into their jars',
      difficulty: 'ZOR',
      colorCount: 5,
      capacity: 4,
      scrambleMoves: 38,
    ),
    CandySortLevel(
      number: 7,
      titleTr: 'Şeker Ustası',
      titleEn: 'Candy Master',
      subtitleTr: 'Karışık katmanları planla',
      subtitleEn: 'Plan through mixed layers',
      difficulty: 'ZOR',
      colorCount: 5,
      capacity: 4,
      scrambleMoves: 48,
    ),
    CandySortLevel(
      number: 8,
      titleTr: 'Altıncı Renk',
      titleEn: 'Sixth Color',
      subtitleTr: '6 renkli büyük düzen',
      subtitleEn: 'A large puzzle with 6 colors',
      difficulty: 'ZOR',
      colorCount: 6,
      capacity: 4,
      scrambleMoves: 58,
    ),
    CandySortLevel(
      number: 9,
      titleTr: 'Tatlı Kaos',
      titleEn: 'Sweet Chaos',
      subtitleTr: 'Uzun hamle zincirini çöz',
      subtitleEn: 'Untangle a long chain of moves',
      difficulty: 'ZOR',
      colorCount: 6,
      capacity: 4,
      scrambleMoves: 72,
    ),
    CandySortLevel(
      number: 10,
      titleTr: 'Şeker Fabrikası',
      titleEn: 'Candy Factory',
      subtitleTr: 'En karmaşık şeker düzeni',
      subtitleEn: 'The most complex candy layout',
      difficulty: 'BOSS',
      colorCount: 6,
      capacity: 4,
      scrambleMoves: 88,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ParkurLevelHub(
      gameId: 'candy_sort',
      progressPrefix: 'candy_sort',
      titleTr: 'ŞEKER SIRALAMA',
      titleEn: 'CANDY SORT',
      taglineTr: 'Seç • Taşı • Renkleri Topla',
      taglineEn: 'Pick • Move • Group Colors',
      accent: const Color(0xFFC46D32),
      icon: Icons.cookie_rounded,
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
            return CandySortPlayPage(
              level: level as CandySortLevel,
              previousBestScore: previousBestScore,
              fixedSessionSeed: fixedSessionSeed,
              competitionMode: competitionMode,
            );
          },
    );
  }
}

class CandySortLevel extends ParkurLevelSpec {
  final int colorCount;
  final int capacity;
  final int scrambleMoves;

  const CandySortLevel({
    super.sourceNumber,
    super.poolIndex,
    required super.number,
    required super.titleTr,
    required super.titleEn,
    required super.subtitleTr,
    required super.subtitleEn,
    required super.difficulty,
    required this.colorCount,
    required this.capacity,
    required this.scrambleMoves,
  }) : super(icon: Icons.cookie_rounded);

  // Standard campaigns remap their authored level templates into the visible
  // 30-chapter list.  Keep the specialised CandySortLevel type during that
  // remap; ParkurLevelHub otherwise returns a plain ParkurLevelSpec and the
  // play builder's typed level would throw as soon as a chapter is opened.
  @override
  CandySortLevel campaignCopy({
    required int number,
    int? sourceNumber,
    int? poolIndex,
    String? titleTr,
    String? titleEn,
    String? difficulty,
  }) => CandySortLevel(
    number: number,
    sourceNumber: sourceNumber,
    poolIndex: poolIndex,
    titleTr: titleTr ?? this.titleTr,
    titleEn: titleEn ?? this.titleEn,
    subtitleTr: subtitleTr,
    subtitleEn: subtitleEn,
    difficulty: difficulty ?? this.difficulty,
    colorCount: colorCount,
    capacity: capacity,
    scrambleMoves: scrambleMoves,
  );
}

class _CandyPuzzle {
  final List<List<int>> jars;
  final int referenceMoves;

  const _CandyPuzzle({required this.jars, required this.referenceMoves});
}

bool candyJarIsComplete(List<int> candies, int capacity) {
  if (capacity <= 0 || candies.length != capacity) return false;

  final int color = candies.first;
  return candies.every((int candy) => candy == color);
}

class CandySortPlayPage extends StatefulWidget {
  final CandySortLevel level;
  final int previousBestScore;
  final int? fixedSessionSeed;
  final bool competitionMode;

  const CandySortPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
    this.fixedSessionSeed,
    this.competitionMode = false,
  });

  @override
  State<CandySortPlayPage> createState() => _CandySortPlayPageState();
}

class _CandySortPlayPageState extends State<CandySortPlayPage> {
  static const Color _accent = Color(0xFFC46D32);
  static String? _lastGeneratedSignature;
  static const List<Color> _candyColors = <Color>[
    Color(0xFFC74B5B),
    Color(0xFF2F9A96),
    Color(0xFFE1A04B),
    Color(0xFF6B9E77),
    Color(0xFF8270A9),
    Color(0xFFD47A45),
  ];

  late Random _random;
  final GameAudioService _audio = GameAudioService.instance;
  final ReplayabilityService _replayability = ReplayabilityService();
  Timer? _timer;
  Timer? _jarCelebrationTimer;

  late List<List<int>> _jars;
  late List<List<int>> _initialJars;
  final List<List<List<int>>> _history = <List<List<int>>>[];
  int? _selectedJar;
  int? _hintSource;
  int? _hintTarget;
  int? _celebratingJar;
  int _jarCelebrationToken = 0;
  int _moves = 0;
  int _elapsed = 0;
  int _hints = 0;
  int _invalidMoves = 0;
  int _referenceMoves = 1;
  late int _sessionBestScore;
  int _sessionBestStars = 0;
  bool _completed = false;
  bool _finishing = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _random = Random(widget.fixedSessionSeed);
    _sessionBestScore = widget.previousBestScore;
    unawaited(_initializeSession());
    unawaited(_audio.preload(GameAudioGroup.blocks));
  }

  Future<void> _initializeSession() async {
    final int variant = widget.fixedSessionSeed == null
        ? await ReferenceRoundStore.reserve(
            gameId: 'candy_sort',
            level: widget.level.number,
          )
        : widget.fixedSessionSeed! % ReferenceRoundStore.variantsPerLevel;
    final int seed =
        widget.fixedSessionSeed ??
        ReferenceRoundStore.seed('candy_sort', widget.level.number, variant);
    _random = _replayability.randomFor(sessionSeed: seed, round: 0, salt: 811);
    if (!mounted) return;
    _newPuzzle();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _jarCelebrationTimer?.cancel();
    super.dispose();
  }

  List<List<int>> _copyJars(List<List<int>> source) {
    return source
        .map((List<int> jar) => List<int>.from(jar))
        .toList(growable: false);
  }

  void _newPuzzle() {
    _timer?.cancel();
    _clearJarCelebration();
    _jarCelebrationToken = 0;
    _CandyPuzzle puzzle = _generatePuzzle(widget.level);
    for (
      int attempt = 0;
      attempt < 5 &&
          widget.fixedSessionSeed == null &&
          _puzzleSignature(puzzle) == _lastGeneratedSignature;
      attempt++
    ) {
      puzzle = _generatePuzzle(widget.level);
    }
    _lastGeneratedSignature = _puzzleSignature(puzzle);
    _jars = _copyJars(puzzle.jars);
    _initialJars = _copyJars(puzzle.jars);
    _referenceMoves = puzzle.referenceMoves;
    _history.clear();
    _selectedJar = null;
    _hintSource = null;
    _hintTarget = null;
    _moves = 0;
    _elapsed = 0;
    _hints = 0;
    _invalidMoves = 0;
    _completed = false;
    _finishing = false;
    _ready = true;
    if (widget.fixedSessionSeed == null) {
      unawaited(
        _replayability.registerFingerprint(
          gameId: 'candy_sort',
          level: widget.level.number,
          fingerprint: _puzzleSignature(puzzle),
          historyLimit: ReferenceRoundStore.variantsPerLevel,
        ),
      );
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (mounted && !_completed) setState(() => _elapsed++);
    });
    if (mounted) setState(() {});
  }

  String _puzzleSignature(_CandyPuzzle puzzle) {
    final Map<int, int> normalizedColors = <int, int>{};
    int nextColor = 0;
    return puzzle.jars
        .map((List<int> jar) {
          return jar.map((int color) {
            return normalizedColors.putIfAbsent(color, () => nextColor++);
          }).join();
        })
        .join('|');
  }

  _CandyPuzzle _generatePuzzle(CandySortLevel level) {
    _CandyPuzzle? bestFallback;
    int bestUsefulMoves = -1;
    for (int attempt = 0; attempt < 80; attempt++) {
      final List<List<int>> jars = <List<int>>[
        for (int color = 0; color < level.colorCount; color++)
          List<int>.filled(level.capacity, color, growable: true),
        <int>[],
        <int>[],
      ];
      int usefulMoves = 0;
      int performedMoves = 0;
      int lastSource = -1;
      int lastTarget = -1;

      for (int step = 0; step < level.scrambleMoves; step++) {
        final List<int> sources = <int>[
          for (int index = 0; index < jars.length; index++)
            if (jars[index].isNotEmpty &&
                (jars[index].length == 1 ||
                    jars[index][jars[index].length - 2] == jars[index].last))
              index,
        ]..shuffle(_random);
        bool moved = false;

        for (final int source in sources) {
          final int candy = jars[source].last;
          final List<int> targets = <int>[
            for (int index = 0; index < jars.length; index++)
              if (index != source &&
                  jars[index].length < level.capacity &&
                  !(source == lastTarget && index == lastSource))
                index,
          ]..shuffle(_random);

          targets.sort((int a, int b) {
            final bool aMixed = jars[a].isNotEmpty && jars[a].last != candy;
            final bool bMixed = jars[b].isNotEmpty && jars[b].last != candy;
            return (bMixed ? 1 : 0).compareTo(aMixed ? 1 : 0);
          });

          if (targets.isEmpty) continue;
          final int target = targets.first;
          if (jars[target].isNotEmpty && jars[target].last != candy) {
            usefulMoves++;
          }
          jars[source].removeLast();
          jars[target].add(candy);
          performedMoves++;
          lastSource = source;
          lastTarget = target;
          moved = true;
          break;
        }
        if (!moved) break;
      }

      if (!_isSolved(jars, level.capacity, level.colorCount) &&
          performedMoves > 0) {
        final _CandyPuzzle candidate = _CandyPuzzle(
          jars: jars,
          referenceMoves: max(level.colorCount * 3, performedMoves),
        );
        if (usefulMoves > bestUsefulMoves) {
          bestUsefulMoves = usefulMoves;
          bestFallback = candidate;
        }
        if (usefulMoves >= max(3, level.colorCount)) return candidate;
      }
    }
    if (bestFallback != null) return bestFallback;

    final List<List<int>> safeJars = <List<int>>[
      for (int color = 0; color < level.colorCount; color++)
        List<int>.filled(level.capacity, color, growable: true),
      <int>[],
      <int>[],
    ];
    safeJars.last.add(safeJars.first.removeLast());
    return _CandyPuzzle(jars: safeJars, referenceMoves: level.colorCount * 3);
  }

  bool _isSolved(List<List<int>> jars, int capacity, int colorCount) {
    int complete = 0;
    for (final List<int> jar in jars) {
      if (jar.isEmpty) continue;
      if (!candyJarIsComplete(jar, capacity)) {
        return false;
      }
      complete++;
    }
    return complete == colorCount;
  }

  void _clearJarCelebration() {
    _jarCelebrationTimer?.cancel();
    _jarCelebrationTimer = null;
    _celebratingJar = null;
  }

  void _startJarCelebration(int index) {
    _jarCelebrationTimer?.cancel();

    setState(() {
      _celebratingJar = index;
      _jarCelebrationToken++;
    });

    unawaited(_audio.play(GameSound.success, gain: 0.82));
    HapticFeedback.mediumImpact();

    final int token = _jarCelebrationToken;
    _jarCelebrationTimer = Timer(const Duration(milliseconds: 820), () {
      if (!mounted ||
          _celebratingJar != index ||
          _jarCelebrationToken != token) {
        return;
      }

      setState(() => _celebratingJar = null);
      _jarCelebrationTimer = null;
    });
  }

  bool _canMove(int source, int target) {
    if (source == target || _jars[source].isEmpty) return false;
    if (_jars[target].length >= widget.level.capacity) return false;
    return _jars[target].isEmpty || _jars[target].last == _jars[source].last;
  }

  Future<void> _tapJar(int index) async {
    if (_completed || _finishing) return;
    _hintSource = null;
    _hintTarget = null;
    if (_selectedJar == null) {
      if (_jars[index].isEmpty) {
        unawaited(_audio.play(GameSound.numberWrong, gain: 0.55));
        return;
      }
      setState(() => _selectedJar = index);
      unawaited(_audio.play(GameSound.blockPickup));
      HapticFeedback.selectionClick();
      return;
    }

    final int source = _selectedJar!;
    if (source == index) {
      setState(() => _selectedJar = null);
      return;
    }
    if (!_canMove(source, index)) {
      _invalidMoves++;
      setState(
        () => _selectedJar = index < _jars.length && _jars[index].isNotEmpty
            ? index
            : source,
      );
      unawaited(_audio.play(GameSound.numberWrong));
      HapticFeedback.lightImpact();
      return;
    }

    _history.add(_copyJars(_jars));
    final int candy = _jars[source].removeLast();
    _jars[index].add(candy);

    final bool completedJar = candyJarIsComplete(
      _jars[index],
      widget.level.capacity,
    );
    final bool solved = _isSolved(
      _jars,
      widget.level.capacity,
      widget.level.colorCount,
    );

    _moves++;
    _selectedJar = null;
    _finishing = solved;

    if (completedJar) {
      _startJarCelebration(index);
    } else {
      setState(() {});
      unawaited(_audio.play(GameSound.blockPlace));
      HapticFeedback.mediumImpact();
    }

    if (solved) {
      await Future<void>.delayed(const Duration(milliseconds: 720));
      if (!mounted) return;
      await _finish();
    }
  }

  void _undo() {
    if (_history.isEmpty || _completed || _finishing) return;
    _clearJarCelebration();
    setState(() {
      _jars = _history.removeLast();
      _moves = max(0, _moves - 1);
      _selectedJar = null;
      _hintSource = null;
      _hintTarget = null;
    });
    unawaited(_audio.play(GameSound.uiBack));
  }

  void _restart() {
    if (_completed || _finishing) return;
    _clearJarCelebration();
    setState(() {
      _finishing = false;
      _jars = _copyJars(_initialJars);
      _history.clear();
      _moves = 0;
      _elapsed = 0;
      _hints = 0;
      _invalidMoves = 0;
      _selectedJar = null;
      _hintSource = null;
      _hintTarget = null;
    });
    unawaited(_audio.play(GameSound.uiBack));
  }

  Future<void> _hint() async {
    if (_completed || _finishing || _hints >= 3) return;
    int? source;
    int? target;
    for (int from = 0; from < _jars.length; from++) {
      if (_jars[from].isEmpty) continue;
      for (int to = 0; to < _jars.length; to++) {
        if (!_canMove(from, to) || _jars[to].isEmpty) continue;
        source = from;
        target = to;
        break;
      }
      if (source != null) break;
    }
    if (source == null) {
      for (int from = 0; from < _jars.length; from++) {
        if (_jars[from].isEmpty) continue;
        for (int to = 0; to < _jars.length; to++) {
          if (_canMove(from, to)) {
            source = from;
            target = to;
            break;
          }
        }
        if (source != null) break;
      }
    }
    if (source == null || target == null) return;
    _hints++;
    unawaited(_audio.play(GameSound.uiHint));
    setState(() {
      _selectedJar = null;
      _hintSource = source;
      _hintTarget = target;
    });
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (mounted && !_completed) {
      setState(() {
        _hintSource = null;
        _hintTarget = null;
      });
    }
  }

  Future<void> _finish() async {
    if (_completed) return;
    _clearJarCelebration();
    _finishing = false;
    _completed = true;
    _timer?.cancel();
    final int threeStarLimit = (_referenceMoves * 1.25).ceil();
    final int twoStarLimit = (_referenceMoves * 1.75).ceil();
    final int stars = _moves <= threeStarLimit && _hints == 0
        ? 3
        : _moves <= twoStarLimit && _hints <= 1
        ? 2
        : 1;
    final int score = max(
      250,
      widget.level.number * 280 +
          widget.level.colorCount * 400 +
          max(0, twoStarLimit - _moves) * 35 -
          _hints * 160 -
          _invalidMoves * 35,
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
      titleTr: 'Şekerler Sıralandı!',
      titleEn: 'Candies Sorted!',
      detailTr: '$_moves hamle • $_elapsed sn • $_hints ipucu',
      detailEn: '$_moves moves • $_elapsed sec • $_hints hints',
      stars: stars,
      score: score,
      previousBestScore: _sessionBestScore,
      canGoNext: widget.level.number < CandySortGamePage.levels.length,
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

  void _showHowToPlay(BuildContext context, bool english) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: StudioVisuals.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: StudioVisuals.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.palette_rounded, color: _accent, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      english ? 'How to Play' : 'Nasıl Oynanır?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: StudioVisuals.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  english
                      ? '• Tap a jar to select its top candy.\n• Tap another jar to move the candy there.\n• You can only place a candy onto another candy of the SAME color, or into an EMPTY jar.\n• Complete each jar with one single color to win!'
                      : '• En üstteki şekeri seçmek için kavanoza dokunun.\n• Şekeri aktarmak istediğiniz hedef kavanoza dokunun.\n• Şeker yalnızca AYNI renkteki şekerin üzerine veya BOŞ bir kavanoza konabilir.\n• Her kavanozda tek bir renk toplayarak seviyeyi tamamlayın!',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: StudioVisuals.ink,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      english ? 'Got it' : 'Anladım',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
    final int columns = _jars.length <= 5 ? 3 : 4;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          '${context.l10n.gameUi(english ? widget.level.titleEn : widget.level.titleTr)}  •  ${widget.level.number}/10',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: english ? 'How to play' : 'Nasıl Oynanır?',
            onPressed: () => _showHowToPlay(context, english),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveGameFrame(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _CandyHeader(
                  moves: _moves,
                  elapsed: _elapsed,
                  hints: 3 - _hints,
                  english: english,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: <Color>[Color(0xFFFFFCF7), Color(0xFFF4EADF)],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: _accent.withValues(alpha: 0.42)),
                    ),
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints jarAreaConstraints) {
                        final int rows = (_jars.length / columns).ceil();
                        final double jarWidth = (jarAreaConstraints.maxWidth - (columns - 1) * 8) / columns;
                        final double jarHeight = (jarAreaConstraints.maxHeight - (rows - 1) * 10) / rows;
                        final double childAspectRatio = (jarWidth / jarHeight).clamp(0.35, 0.85);
                        return GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _jars.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 10,
                            childAspectRatio: childAspectRatio,
                          ),
                          itemBuilder: (BuildContext context, int index) {
                            return _CandyJar(
                              candies: _jars[index],
                              capacity: widget.level.capacity,
                              colors: _candyColors,
                              selected: _selectedJar == index,
                              hintSource: _hintSource == index,
                              hintTarget: _hintTarget == index,
                              celebrating: _celebratingJar == index,
                              celebrationToken: _celebratingJar == index
                                  ? _jarCelebrationToken
                                  : 0,
                              onTap: () => _tapJar(index),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _history.isEmpty || _finishing
                            ? null
                            : _undo,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.undo_rounded, size: 18),
                        label: Text(
                          context.l10n.gameUi(english ? 'UNDO' : 'GERİ AL'),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _finishing ? null : _restart,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: Text(
                          context.l10n.gameUi(english ? 'RESET' : 'BAŞTAN'),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _hints >= 3 || _finishing ? null : _hint,
                        style: FilledButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.lightbulb_rounded, size: 18),
                        label: Text(
                          '${context.l10n.gameUi(english ? 'HINT' : 'İPUCU')} ${3 - _hints}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
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

class _CandyJar extends StatelessWidget {
  final List<int> candies;
  final int capacity;
  final List<Color> colors;
  final bool selected;
  final bool hintSource;
  final bool hintTarget;
  final bool celebrating;
  final int celebrationToken;
  final VoidCallback onTap;

  const _CandyJar({
    required this.candies,
    required this.capacity,
    required this.colors,
    required this.selected,
    required this.hintSource,
    required this.hintTarget,
    required this.celebrating,
    required this.celebrationToken,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color celebrationColor = candies.isEmpty
        ? const Color(0xFFC46D32)
        : colors[candies.first];

    final Color border = celebrating
        ? Color.lerp(celebrationColor, Colors.white, 0.48)!
        : selected
        ? const Color(0xFFC46D32)
        : hintSource
        ? const Color(0xFFE0AA53)
        : hintTarget
        ? const Color(0xFF6B9E77)
        : const Color(0xFFD9C8B6);

    return TweenAnimationBuilder<double>(
      key: ValueKey<String>(
        celebrating
            ? 'candy-jar-celebration-$celebrationToken'
            : 'candy-jar-idle',
      ),
      tween: Tween<double>(begin: 0, end: celebrating ? 1 : 0),
      duration: const Duration(milliseconds: 720),
      curve: Curves.easeInOutCubic,
      builder: (BuildContext context, double animation, Widget? child) {
        final double pulse = celebrating ? sin(animation * pi) : 0;

        final double sparkleOpacity = (0.35 + pulse * 0.65)
            .clamp(0.0, 1.0)
            .toDouble();

        return Transform.scale(
          scale: 1 + pulse * 0.055,
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.fromLTRB(8, 7, 8, 9),
              transform: Matrix4.translationValues(0, selected ? -7 : 0, 0),
              decoration: BoxDecoration(
                color: celebrating
                    ? celebrationColor.withValues(alpha: 0.10 + pulse * 0.07)
                    : selected
                    ? const Color(0xFFFFF4E5)
                    : Colors.white.withValues(alpha: 0.84),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                  topLeft: Radius.circular(9),
                  topRight: Radius.circular(9),
                ),
                border: Border.all(
                  color: border,
                  width: celebrating
                      ? 2.3
                      : selected
                      ? 2
                      : 1.2,
                ),
                boxShadow: celebrating
                    ? <BoxShadow>[
                        BoxShadow(
                          color: celebrationColor.withValues(
                            alpha: 0.34 + pulse * 0.28,
                          ),
                          blurRadius: 14 + pulse * 18,
                          spreadRadius: 1 + pulse * 3,
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(
                            alpha: 0.10 + pulse * 0.20,
                          ),
                          blurRadius: 8 + pulse * 10,
                        ),
                      ]
                    : <BoxShadow>[
                        BoxShadow(
                          color: const Color(0xFF6D4B34).withValues(alpha: .11),
                          blurRadius: 9,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: <Widget>[
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      for (int slot = capacity - 1; slot >= 0; slot--)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: slot < candies.length
                                ? _Candy(
                                    color: colors[candies[slot]],
                                    flavor: candies[slot],
                                  )
                                : const SizedBox.expand(),
                          ),
                        ),
                    ],
                  ),
                  if (celebrating) ...<Widget>[
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Opacity(
                        opacity: sparkleOpacity,
                        child: Transform.rotate(
                          angle: pulse * 0.24,
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 1,
                      bottom: 3,
                      child: Opacity(
                        opacity: sparkleOpacity,
                        child: Transform.scale(
                          scale: 0.75 + pulse * 0.35,
                          child: Icon(
                            Icons.star_rounded,
                            color: Color.lerp(
                              celebrationColor,
                              Colors.white,
                              0.58,
                            ),
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                  Positioned(
                    left: 7,
                    right: 7,
                    top: 4,
                    child: IgnorePointer(
                      child: Container(
                        height: 7,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          color: Colors.white.withValues(alpha: .34),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .60),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Candy extends StatelessWidget {
  final Color color;
  final int flavor;

  const _Candy({required this.color, required this.flavor});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 0.88,
      child: CustomPaint(
        painter: _CandyPainter(color: color, flavor: flavor),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _CandyPainter extends CustomPainter {
  final Color color;
  final int flavor;

  const _CandyPainter({required this.color, required this.flavor});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final double w = size.width;
    final double h = size.height;
    final RRect bounds = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * .08, h * .12, w * .84, h * .76),
      Radius.circular(flavor.isEven ? h * .38 : h * .25),
    );
    final Paint shadow = Paint()
      ..color = const Color(0xFF5B3925).withValues(alpha: .18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawRRect(bounds.shift(const Offset(0, 1.5)), shadow);
    final Paint body = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color.lerp(color, Colors.white, .52)!,
          color,
          Color.lerp(color, Colors.black, .25)!,
        ],
      ).createShader(bounds.outerRect);
    canvas.drawRRect(bounds, body);
    final Paint rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = Colors.white.withValues(alpha: .56);
    canvas.drawRRect(bounds, rim);
    final Paint gloss = Paint()
      ..color = Colors.white.withValues(alpha: .55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.3);
    canvas.drawOval(
      Rect.fromLTWH(w * .24, h * .18, w * .27, h * .16),
      gloss,
    );
    final Paint streak = Paint()
      ..color = Colors.white.withValues(alpha: .20)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * .23, h * .69),
      Offset(w * .66, h * .69),
      streak,
    );
  }

  @override
  bool shouldRepaint(_CandyPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.flavor != flavor;
}

class _CandyHeader extends StatelessWidget {
  final int moves;
  final int elapsed;
  final int hints;
  final bool english;

  const _CandyHeader({
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EBE7)),
      ),
      child: Row(
        children: <Widget>[
          _CandyStat(
            icon: Icons.swap_horiz_rounded,
            value: '$moves',
            label: context.l10n.gameUi(english ? 'MOVES' : 'HAMLE'),
            color: const Color(0xFFC46D32),
          ),
          _CandyStat(
            icon: Icons.timer_outlined,
            value: '${elapsed}s',
            label: context.l10n.gameUi(english ? 'TIME' : 'SÜRE'),
            color: const Color(0xFF2F7E78),
          ),
          _CandyStat(
            icon: Icons.lightbulb_rounded,
            value: '$hints',
            label: context.l10n.gameUi(english ? 'HINTS' : 'İPUCU'),
            color: const Color(0xFFE0AA53),
          ),
        ],
      ),
    );
  }
}

class _CandyStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _CandyStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Icon(icon, color: color, size: 19),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF71837C), fontSize: 9),
          ),
        ],
      ),
    );
  }
}
