import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';
import '../../services/daily_challenge_service.dart';
import '../../services/daily_course_service.dart';
import '../../services/game_audio_service.dart';
import '../../services/replayability_service.dart';
import '../../widgets/advanced_result_banner.dart';

class HanoiGamePage extends StatefulWidget {
  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  const HanoiGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  @override
  State<HanoiGamePage> createState() => _HanoiGamePageState();
}

class _HanoiGamePageState extends State<HanoiGamePage> {
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
  final GameAudioService _audio = GameAudioService.instance;

  // The Hanoi hub must never wait on platform storage before it can render.
  // Safe defaults are shown immediately and saved progress hydrates in background.
  bool loading = false;
  int unlockedLevel = 1;
  List<int> stars = List<int>.filled(10, 0);
  List<int> bestScores = List<int>.filled(10, 0);
  List<int> bestMoves = List<int>.filled(10, 0);
  bool _competitionOpened = false;

  static const List<HanoiLevel> levels = <HanoiLevel>[
    HanoiLevel(
      number: 1,
      titleTr: 'İlk Taşıma',
      titleEn: 'First Move',
      subtitleTr: '3 halkayla kuralları öğren',
      subtitleEn: 'Learn the rules with 3 rings',
      difficulty: 'KOLAY',
      diskCount: 3,
      startPeg: 0,
      targetPeg: 2,
      twoStarLimit: 10,
      tutorial: true,
    ),
    HanoiLevel(
      number: 2,
      titleTr: 'Sağ Kule Hedefi',
      titleEn: 'Right Tower Goal',
      subtitleTr: 'En kısa yolu kendin bul',
      subtitleEn: 'Find the shortest route',
      difficulty: 'KOLAY',
      diskCount: 3,
      startPeg: 0,
      targetPeg: 2,
      twoStarLimit: 9,
    ),
    HanoiLevel(
      number: 3,
      titleTr: 'Ters Rota',
      titleEn: 'Reverse Route',
      subtitleTr: 'Sağdan sola doğru plan yap',
      subtitleEn: 'Plan from right to left',
      difficulty: 'ORTA',
      diskCount: 3,
      startPeg: 2,
      targetPeg: 0,
      twoStarLimit: 8,
    ),
    HanoiLevel(
      number: 4,
      titleTr: 'Dört Halka',
      titleEn: 'Four Rings',
      subtitleTr: '15 hamlelik gerçek sınav',
      subtitleEn: 'The real 15-move test',
      difficulty: 'ORTA',
      diskCount: 4,
      startPeg: 0,
      targetPeg: 2,
      twoStarLimit: 21,
    ),
    HanoiLevel(
      number: 5,
      titleTr: 'Orta Kule',
      titleEn: 'Center Tower',
      subtitleTr: 'Hedef bu kez merkezde',
      subtitleEn: 'The target is in the center',
      difficulty: 'ORTA',
      diskCount: 4,
      startPeg: 0,
      targetPeg: 1,
      twoStarLimit: 19,
    ),
    HanoiLevel(
      number: 6,
      titleTr: 'Keskin Plan',
      titleEn: 'Sharp Plan',
      subtitleTr: 'Gereksiz hamleleri azalt',
      subtitleEn: 'Cut unnecessary moves',
      difficulty: 'ZOR',
      diskCount: 4,
      startPeg: 2,
      targetPeg: 0,
      twoStarLimit: 18,
    ),
    HanoiLevel(
      number: 7,
      titleTr: 'Kusursuz Dörtlü',
      titleEn: 'Perfect Four',
      subtitleTr: '15 hamleye mümkün olduğunca yaklaş',
      subtitleEn: 'Get as close as possible to 15 moves',
      difficulty: 'ZOR',
      diskCount: 4,
      startPeg: 1,
      targetPeg: 2,
      twoStarLimit: 17,
    ),
    HanoiLevel(
      number: 8,
      titleTr: 'Beş Halka',
      titleEn: 'Five Rings',
      subtitleTr: '31 hamlelik büyük kule',
      subtitleEn: 'The great 31-move tower',
      difficulty: 'ZOR',
      diskCount: 5,
      startPeg: 0,
      targetPeg: 2,
      twoStarLimit: 43,
    ),
    HanoiLevel(
      number: 9,
      titleTr: 'Usta Rotası',
      titleEn: 'Master Route',
      subtitleTr: 'Beş halkayı farklı hedefe taşı',
      subtitleEn: 'Move five rings to a new target',
      difficulty: 'ZOR',
      diskCount: 5,
      startPeg: 2,
      targetPeg: 1,
      twoStarLimit: 37,
    ),
    HanoiLevel(
      number: 10,
      titleTr: 'Hanoi Ustası',
      titleEn: 'Hanoi Master',
      subtitleTr: '31 hamlede kusursuz çözüm',
      subtitleEn: 'A perfect solution in 31 moves',
      difficulty: 'BOSS',
      diskCount: 5,
      startPeg: 0,
      targetPeg: 2,
      twoStarLimit: 34,
      boss: true,
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Render the level hub immediately. Platform storage is optional hydration,
    // never a prerequisite for entering the game.
    _openCompetitionLevelIfNeeded();
    unawaited(_loadProgressInBackground());
    unawaited(_audio.preload(GameAudioGroup.logic));
  }

  static const Duration _progressLoadTimeout = Duration(milliseconds: 1600);
  static const Duration _progressSaveTimeout = Duration(milliseconds: 1800);

  Future<void> _loadProgressInBackground() async {
    try {
      final List<Object?> values = await Future.wait<Object?>(<Future<Object?>>[
        _prefs.getInt('hanoi_unlocked_level'),
        _prefs.getStringList('hanoi_stars'),
        _prefs.getStringList('hanoi_best_scores'),
        _prefs.getStringList('hanoi_best_moves'),
      ]).timeout(_progressLoadTimeout);

      if (!mounted) return;

      final int savedLevel = (values[0] as int?) ?? 1;
      final List<String>? savedStars = values[1] as List<String>?;
      final List<String>? savedScores = values[2] as List<String>?;
      final List<String>? savedMoves = values[3] as List<String>?;

      setState(() {
        unlockedLevel = savedLevel.clamp(1, levels.length).toInt();
        stars = _decodeList(savedStars);
        bestScores = _decodeList(savedScores);
        bestMoves = _decodeList(savedMoves);
        loading = false;
      });
    } on TimeoutException catch (error) {
      debugPrint(
        'Hanoi progress hydration timed out; safe defaults remain active: $error',
      );
      _openWithSafeDefaults();
    } catch (error, stackTrace) {
      debugPrint(
        'Hanoi progress hydration failed; safe defaults remain active: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      _openWithSafeDefaults();
    }
  }

  // Kept as a compatibility/safety contract from the V12.2 recovery line.
  // The hub already renders with these defaults on the first frame; this
  // method is only used when background hydration times out or fails.
  void _openWithSafeDefaults() {
    if (!mounted) return;
    setState(() {
      unlockedLevel = 1;
      stars = List<int>.filled(levels.length, 0);
      bestScores = List<int>.filled(levels.length, 0);
      bestMoves = List<int>.filled(levels.length, 0);
      loading = false;
    });
  }

  void _openCompetitionLevelIfNeeded() {
    final int? level = widget.competitionLevel;
    if (_competitionOpened || level == null) return;
    _competitionOpened = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openLevel(
        (level - 1).clamp(0, levels.length - 1).toInt(),
        ignoreLock: true,
      );
    });
  }

  List<int> _decodeList(List<String>? source) {
    return List<int>.generate(levels.length, (index) {
      if (source == null || index >= source.length) return 0;
      return max(0, int.tryParse(source[index]) ?? 0);
    });
  }

  Future<void> _saveProgress() async {
    try {
      await Future.wait<void>(<Future<void>>[
        _prefs.setInt('hanoi_unlocked_level', unlockedLevel),
        _prefs.setStringList(
          'hanoi_stars',
          stars.map((value) => '$value').toList(),
        ),
        _prefs.setStringList(
          'hanoi_best_scores',
          bestScores.map((value) => '$value').toList(),
        ),
        _prefs.setStringList(
          'hanoi_best_moves',
          bestMoves.map((value) => '$value').toList(),
        ),
      ]).timeout(_progressSaveTimeout);
    } on TimeoutException catch (error) {
      debugPrint('Hanoi progress save timed out; gameplay continues: $error');
    } catch (error, stackTrace) {
      debugPrint('Hanoi progress save failed; gameplay continues: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  int get totalStars => stars.fold<int>(0, (a, b) => a + b);
  int get totalScore => bestScores.fold<int>(0, (a, b) => a + b);

  Future<void> _openLevel(int index, {bool ignoreLock = false}) async {
    if (index < 0 ||
        index >= levels.length ||
        (!ignoreLock && index + 1 > unlockedLevel)) {
      return;
    }

    unawaited(_audio.play(GameSound.uiClick));

    final HanoiLevelResult? result = await Navigator.push<HanoiLevelResult>(
      context,
      MaterialPageRoute(
        builder: (_) => HanoiPlayPage(
          level: levels[index],
          totalLevels: levels.length,
          savedBestMoves: bestMoves[index],
          previousBestScore: bestScores[index],
          fixedSessionSeed: widget.competitionLayoutCode,
          competitionMode: widget.competitionLevel != null,
        ),
      ),
    );

    if (!mounted) return;

    if (widget.dailyCourseMode) {
      Navigator.pop(
        context,
        result == null
            ? const DailyStageResult.exited(gameId: 'hanoi')
            : result.completed
            ? DailyStageResult.completed(
                gameId: 'hanoi',
                stars: result.stars,
                rawScore: result.score,
              )
            : const DailyStageResult.failed(gameId: 'hanoi'),
      );
      return;
    }

    if (result == null || !result.completed) {
      if (widget.competitionLevel != null && mounted) {
        Navigator.pop(context);
      }
      return;
    }

    if (widget.competitionLevel != null) {
      Navigator.pop(
        context,
        DailyCourseGameResult(
          gameId: 'hanoi',
          stars: result.stars,
          score: result.score,
        ),
      );
      return;
    }

    setState(() {
      stars[index] = max(stars[index], result.stars);
      bestScores[index] = max(bestScores[index], result.score);

      if (bestMoves[index] == 0 || result.moves < bestMoves[index]) {
        bestMoves[index] = result.moves;
      }

      if (index + 1 == unlockedLevel && unlockedLevel < levels.length) {
        unlockedLevel++;
      }
    });

    // Persistence must not block the result flow or the next level.
    unawaited(_saveProgress());

    await DailyChallengeService.instance.recordLevelCompleted(
      gameId: 'hanoi',
      stars: result.stars,
      score: result.score,
    );

    if (!widget.dailyCourseMode && index + 1 == levels.length) {
      await GameAudioService.instance.playMashallahCelebration();
    }

    if (result.nextLevel && index + 1 < levels.length && mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 160));
      if (mounted) await _openLevel(index + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool english = context.l10n.isEnglish;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.gameUi(english ? 'TOWER OF HANOI' : 'HANOİ KULESİ'),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 0.4,
              ),
            ),
            Text(
              context.l10n.gameUi(
                english ? 'Plan • Move • Complete' : 'Planla • Taşı • Tamamla',
              ),
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: loading || widget.competitionLevel != null
            ? const _HanoiLoadingView()
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                    child: _HanoiProgressPanel(
                      totalScore: totalScore,
                      totalStars: totalStars,
                      unlockedLevel: unlockedLevel,
                      english: english,
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
                      itemCount: levels.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            mainAxisExtent: 184,
                          ),
                      itemBuilder: (context, index) {
                        return _HanoiLevelCard(
                          level: levels[index],
                          unlocked: index + 1 <= unlockedLevel,
                          stars: stars[index],
                          bestMoves: bestMoves[index],
                          english: english,
                          onTap: () => _openLevel(index),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class HanoiPlayPage extends StatefulWidget {
  final HanoiLevel level;
  final int totalLevels;
  final int savedBestMoves;
  final int previousBestScore;
  final int? fixedSessionSeed;
  final bool competitionMode;

  const HanoiPlayPage({
    super.key,
    required this.level,
    required this.totalLevels,
    required this.savedBestMoves,
    required this.previousBestScore,
    this.fixedSessionSeed,
    this.competitionMode = false,
  });

  @override
  State<HanoiPlayPage> createState() => _HanoiPlayPageState();
}

class _HanoiPlayPageState extends State<HanoiPlayPage> {
  final GameAudioService _audio = GameAudioService.instance;
  final ReplayabilityService _replayability = ReplayabilityService();

  late List<List<int>> pegs;
  late List<List<int>> _initialPegs;
  final List<HanoiMove> history = <HanoiMove>[];

  static const int _maxHintsPerLevel = 4;

  int moveCount = 0;
  int _hintsUsed = 0;
  int? selectedPeg;
  int? hintTargetPeg;
  int? invalidPeg;
  HanoiMove? lastMove;
  bool completed = false;
  bool _ready = false;
  int _optimalMoves = 0;

  String statusTr = '';
  String statusEn = '';

  HanoiLevel get level => widget.level;
  int get optimalMoves => _optimalMoves;
  int get _remainingHints => max(0, _maxHintsPerLevel - _hintsUsed);

  @override
  void initState() {
    super.initState();

    // Build the playable puzzle synchronously. Hanoi must not depend on
    // SharedPreferences/replay history before showing its board.
    _initializeProblemImmediately();
    unawaited(_audio.preload(GameAudioGroup.logic));

    if (level.boss) {
      unawaited(_audio.play(GameSound.bossIntro));
    }
  }

  void _initializeProblemImmediately() {
    final int seed =
        widget.fixedSessionSeed ??
        ((DateTime.now().microsecondsSinceEpoch ^
                (level.number * 7919) ^
                level.diskCount) &
            0x7fffffff);

    final Random random = _replayability.randomFor(
      sessionSeed: seed,
      round: 0,
      salt: 709,
    );

    final List<List<int>> initial = level.number <= 4
        ? _classicStart()
        : _randomizedLegalStart(random);

    final int minimumMoves = HanoiSolver.minimumMoves(
      pegs: initial,
      diskCount: level.diskCount,
      targetPeg: level.targetPeg,
    );

    _initialPegs = _copyPegs(initial);
    pegs = _copyPegs(initial);
    _optimalMoves = max(1, minimumMoves);
    _ready = true;
    _resetBoard(playSound: false);

    if (widget.fixedSessionSeed == null) {
      unawaited(_registerFingerprintSafely(initial));
    }
  }

  Future<void> _registerFingerprintSafely(List<List<int>> initial) async {
    try {
      await _replayability
          .registerFingerprint(
            gameId: 'hanoi',
            level: level.number,
            fingerprint: _problemFingerprint(initial),
            historyLimit: 100,
          )
          .timeout(const Duration(milliseconds: 1600));
    } on TimeoutException catch (error) {
      debugPrint('Hanoi replay history timed out; gameplay continues: $error');
    } catch (error, stackTrace) {
      debugPrint('Hanoi replay history failed; gameplay continues: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  List<List<int>> _classicStart() {
    final List<List<int>> result = List<List<int>>.generate(3, (_) => <int>[]);
    result[level.startPeg] = List<int>.generate(
      level.diskCount,
      (int index) => level.diskCount - index - 1,
    );
    return result;
  }

  List<List<int>> _randomizedLegalStart(Random random) {
    final List<List<int>> result = _classicStart();
    HanoiMove? previous;
    final int steps = level.number * 2 + random.nextInt(level.number + 3);
    for (int step = 0; step < steps; step++) {
      final List<HanoiMove> legal = HanoiSolver.legalMoves(result)
          .where(
            (HanoiMove move) =>
                previous == null ||
                move.from != previous.to ||
                move.to != previous.from,
          )
          .toList(growable: true);
      final List<HanoiMove> candidates = legal.isEmpty
          ? HanoiSolver.legalMoves(result)
          : legal;
      final HanoiMove move = candidates[random.nextInt(candidates.length)];
      final int disk = result[move.from].removeLast();
      result[move.to].add(disk);
      previous = move;
    }
    if (result[level.targetPeg].length == level.diskCount) {
      final HanoiMove move = HanoiSolver.legalMoves(
        result,
      ).firstWhere((HanoiMove candidate) => candidate.from == level.targetPeg);
      final int disk = result[move.from].removeLast();
      result[move.to].add(disk);
    }
    return result;
  }

  List<List<int>> _copyPegs(List<List<int>> source) {
    return source
        .map((List<int> peg) => List<int>.from(peg))
        .toList(growable: false);
  }

  String _problemFingerprint(List<List<int>> source) {
    return '${source.map((List<int> peg) => peg.join(',')).join('/')}>'
        '${level.targetPeg}';
  }

  void _resetBoard({bool playSound = true}) {
    pegs = _copyPegs(_initialPegs);
    history.clear();
    moveCount = 0;
    selectedPeg = null;
    hintTargetPeg = null;
    invalidPeg = null;
    lastMove = null;
    completed = false;
    statusTr = level.tutorial
        ? 'İlk halkayı seçmek için bir kuleye dokun.'
        : level.number >= 5
        ? 'Dağıtılmış halkaları hedef kulede topla.'
        : 'Bütün halkaları hedef kulede topla.';
    statusEn = level.tutorial
        ? 'Tap a tower to select its top ring.'
        : level.number >= 5
        ? 'Collect the distributed rings on the target tower.'
        : 'Collect every ring on the target tower.';

    if (playSound) {
      unawaited(_audio.play(GameSound.uiBack));
      _audio.hapticSelection();
      if (mounted) setState(() {});
    }
  }

  void _setStatus(String tr, String en) {
    statusTr = tr;
    statusEn = en;
  }

  void _tapPeg(int pegIndex) {
    if (completed) return;

    final int? source = selectedPeg;

    if (source == null) {
      if (pegs[pegIndex].isEmpty) {
        _showInvalid(
          pegIndex,
          'Bu kule boş. Halkası olan bir kule seç.',
          'This tower is empty. Choose a tower with a ring.',
        );
        return;
      }

      setState(() {
        selectedPeg = pegIndex;
        hintTargetPeg = null;
        _setStatus(
          'Taşımak için hedef kuleye dokun.',
          'Tap the destination tower to move the ring.',
        );
      });
      unawaited(_audio.play(GameSound.numberSelect));
      _audio.hapticSelection();
      return;
    }

    if (source == pegIndex) {
      setState(() {
        selectedPeg = null;
        hintTargetPeg = null;
        _setStatus('Seçim kaldırıldı.', 'Selection cleared.');
      });
      unawaited(_audio.play(GameSound.uiBack, gain: 0.7));
      _audio.hapticSelection();
      return;
    }

    final int movingDisk = pegs[source].last;
    final int? targetTop = pegs[pegIndex].isEmpty ? null : pegs[pegIndex].last;

    if (targetTop != null && targetTop < movingDisk) {
      _showInvalid(
        pegIndex,
        'Büyük halka küçük halkanın üzerine gelemez.',
        'A larger ring cannot be placed on a smaller ring.',
      );
      return;
    }

    final HanoiMove move = HanoiMove(
      from: source,
      to: pegIndex,
      disk: movingDisk,
    );

    setState(() {
      pegs[source].removeLast();
      pegs[pegIndex].add(movingDisk);
      history.add(move);
      moveCount++;
      selectedPeg = null;
      hintTargetPeg = null;
      invalidPeg = null;
      lastMove = move;
      _setStatus(
        'Harika hamle! Sıradaki halkayı seç.',
        'Great move! Select the next ring.',
      );

      if (pegs[level.targetPeg].length == level.diskCount) {
        completed = true;
        _setStatus(
          'Hanoi Kulesi tamamlandı!',
          'The Tower of Hanoi is complete!',
        );
      }
    });

    unawaited(_audio.play(GameSound.blockPlace, gain: 0.82));
    _audio.hapticLight();

    if (completed) {
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 420), () {
          if (mounted) _showResult();
        }),
      );
    }
  }

  void _showInvalid(int pegIndex, String tr, String en) {
    setState(() {
      invalidPeg = pegIndex;
      _setStatus(tr, en);
    });
    unawaited(_audio.play(GameSound.logicWall));
    _audio.hapticMedium();

    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 360), () {
        if (!mounted || invalidPeg != pegIndex) return;
        setState(() => invalidPeg = null);
      }),
    );
  }

  void _undoMove() {
    if (completed || history.isEmpty) return;

    setState(() {
      final HanoiMove move = history.removeLast();
      final int disk = pegs[move.to].removeLast();
      pegs[move.from].add(disk);
      moveCount = max(0, moveCount - 1);
      selectedPeg = null;
      hintTargetPeg = null;
      invalidPeg = null;
      lastMove = null;
      _setStatus('Son hamle geri alındı.', 'The last move was undone.');
    });
    unawaited(_audio.play(GameSound.uiBack));
    _audio.hapticSelection();
  }

  void _showHint() {
    if (completed || _remainingHints == 0) return;

    final HanoiMove? hint = HanoiSolver.nextMove(
      pegs: pegs,
      diskCount: level.diskCount,
      targetPeg: level.targetPeg,
    );

    if (hint == null) return;

    setState(() {
      _hintsUsed++;
      selectedPeg = hint.from;
      hintTargetPeg = hint.to;
      invalidPeg = null;

      final int remainingHints = _remainingHints;
      _setStatus(
        remainingHints == 0
            ? 'Son ipucu: Parlayan halkayı yeşil kuleye taşı. '
                  'Artık ipucu hakkın kalmadı.'
            : 'İpucu: Parlayan halkayı yeşil kuleye taşı. '
                  'Kalan hak: $remainingHints.',
        remainingHints == 0
            ? 'Final hint: Move the glowing ring to the green tower. '
                  'No hints remain.'
            : 'Hint: Move the glowing ring to the green tower. '
                  '$remainingHints remaining.',
      );
    });
    unawaited(_audio.play(GameSound.uiHint));
    _audio.hapticSelection();
  }

  int _starsForMoves() {
    if (moveCount <= optimalMoves) return 3;
    final int twoStarLimit = max(
      level.twoStarLimit,
      optimalMoves + max(2, (optimalMoves * 0.35).ceil()),
    );
    if (moveCount <= twoStarLimit) return 2;
    return 1;
  }

  int _scoreForResult(int stars) {
    final int efficiency = max(0, level.twoStarLimit - moveCount) * 25;
    return stars * 1000 + efficiency + level.number * 40;
  }

  Future<void> _showResult() async {
    final int earnedStars = _starsForMoves();
    final int score = _scoreForResult(earnedStars);
    final bool english = context.l10n.isEnglish;

    unawaited(_audio.playVictory(stars: earnedStars, boss: level.boss));

    if (widget.competitionMode) {
      Navigator.pop(
        context,
        HanoiLevelResult(
          completed: true,
          stars: earnedStars,
          score: score,
          moves: moveCount,
          nextLevel: false,
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 22,
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Color(0xFF12365E), Color(0xFF0A203D)],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: level.boss
                      ? const Color(0xFFFFD334)
                      : const Color(0xFF54E56B),
                  width: 2,
                ),
                boxShadow: const <BoxShadow>[
                  BoxShadow(color: Color(0x5500D9FF), blurRadius: 26),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    level.boss
                        ? Icons.emoji_events_rounded
                        : Icons.account_tree_rounded,
                    color: const Color(0xFFFFD334),
                    size: 48,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    level.boss
                        ? english
                              ? 'HANOI MASTER!'
                              : 'HANOİ USTASI!'
                        : english
                        ? 'TOWER COMPLETED!'
                        : 'KULE TAMAMLANDI!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 10),
                  AdvancedResultBanner(
                    score: score,
                    previousBestScore: widget.previousBestScore,
                    english: english,
                    accentColor: const Color(0xFF00D9FF),
                  ),
                  const SizedBox(height: 11),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List<Widget>.generate(
                      3,
                      (index) => Icon(
                        index < earnedStars
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: const Color(0xFFFFD334),
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _HanoiResultBox(
                          label: context.l10n.gameUi(
                            english ? 'MOVES' : 'HAMLE',
                          ),
                          value: '$moveCount',
                          icon: Icons.swap_horiz_rounded,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: _HanoiResultBox(
                          label: context.l10n.gameUi(
                            english ? 'OPTIMAL' : 'İDEAL',
                          ),
                          value: '$optimalMoves',
                          icon: Icons.auto_awesome_rounded,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: _HanoiResultBox(
                          label: context.l10n.gameUi(
                            english ? 'SCORE' : 'PUAN',
                          ),
                          value: '$score',
                          icon: Icons.bolt_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        Navigator.pop(
                          context,
                          HanoiLevelResult(
                            completed: true,
                            stars: earnedStars,
                            score: score,
                            moves: moveCount,
                            nextLevel: level.number < widget.totalLevels,
                          ),
                        );
                      },
                      icon: Icon(
                        level.number < widget.totalLevels
                            ? Icons.arrow_forward_rounded
                            : Icons.flag_rounded,
                      ),
                      label: Text(
                        context.l10n.gameUi(
                          level.number < widget.totalLevels
                              ? english
                                    ? 'NEXT LEVEL'
                                    : 'SONRAKİ SEVİYE'
                              : english
                              ? 'FINISH HANOI COURSE'
                              : 'HANOİ PARKURUNU TAMAMLA',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      Navigator.pop(
                        context,
                        HanoiLevelResult(
                          completed: true,
                          stars: earnedStars,
                          score: score,
                          moves: moveCount,
                          nextLevel: false,
                        ),
                      );
                    },
                    child: Text(
                      context.l10n.gameUi(english ? 'LEVELS' : 'BÖLÜMLER'),
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

  Future<void> _showRules() async {
    final bool english = context.l10n.isEnglish;
    unawaited(_audio.play(GameSound.uiHint));

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF102A4A),
        title: Text(
          context.l10n.gameUi(english ? 'HOW TO PLAY' : 'NASIL OYNANIR?'),
        ),
        content: Text(
          english
              ? '1. Tap a tower to select its top ring.\n'
                    '2. Tap the destination tower to move it.\n'
                    '3. Move only one ring at a time.\n'
                    '4. Never place a larger ring on a smaller one.\n'
                    '5. Collect all rings on the glowing target tower.'
              : '1. En üstteki halkayı seçmek için kuleye dokun.\n'
                    '2. Taşımak için hedef kuleye dokun.\n'
                    '3. Her hamlede yalnızca bir halka taşı.\n'
                    '4. Büyük halkayı küçük halkanın üzerine koyma.\n'
                    '5. Bütün halkaları parlayan hedef kulede topla.',
          style: const TextStyle(height: 1.55),
        ),
        actions: <Widget>[
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.gameUi(english ? 'GOT IT' : 'ANLADIM')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool english = context.l10n.isEnglish;

    if (!_ready) {
      return const Scaffold(
        backgroundColor: Color(0xFF06142A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF54E56B)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF06142A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              level.title(english).toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            Text(
              english
                  ? 'Level ${level.number} / ${widget.totalLevels}'
                  : 'Seviye ${level.number} / ${widget.totalLevels}',
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: context.l10n.gameUi(
              english ? 'How to play' : 'Nasıl oynanır?',
            ),
            onPressed: _showRules,
            icon: const Icon(Icons.help_outline_rounded),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Theme.of(context).scaffoldBackgroundColor,
              const Color(0xFF081C35),
              const Color(0xFF06142A),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double boardHeight = (constraints.maxHeight * 0.55)
                  .clamp(285.0, 390.0)
                  .toDouble();

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: max(0.0, constraints.maxHeight - 28),
                  ),
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _HanoiTopStat(
                              label: context.l10n.gameUi(
                                english ? 'MOVES' : 'HAMLE',
                              ),
                              value: '$moveCount',
                              icon: Icons.swap_horiz_rounded,
                              color: const Color(0xFF00D9FF),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _HanoiTopStat(
                              label: context.l10n.gameUi(
                                english ? 'OPTIMAL' : 'İDEAL',
                              ),
                              value: '$optimalMoves',
                              icon: Icons.auto_awesome_rounded,
                              color: const Color(0xFFFFD334),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _HanoiTopStat(
                              label: context.l10n.gameUi(
                                english ? 'BEST' : 'EN İYİ',
                              ),
                              value: widget.savedBestMoves == 0
                                  ? '-'
                                  : '${widget.savedBestMoves}',
                              icon: Icons.emoji_events_rounded,
                              color: const Color(0xFF54E56B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF102A4A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0x6654E56B)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Icon(
                              Icons.flag_rounded,
                              color: Color(0xFF54E56B),
                              size: 18,
                            ),
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                english
                                    ? 'TARGET: ${HanoiLevel.pegName(level.targetPeg)} TOWER'
                                    : 'HEDEF: ${HanoiLevel.pegName(level.targetPeg)} KULESİ',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 11),
                      SizedBox(
                        height: boardHeight,
                        child: _HanoiBoard(
                          pegs: pegs,
                          diskCount: level.diskCount,
                          startPeg: level.startPeg,
                          targetPeg: level.targetPeg,
                          selectedPeg: selectedPeg,
                          hintTargetPeg: hintTargetPeg,
                          invalidPeg: invalidPeg,
                          lastMove: lastMove,
                          english: english,
                          onPegTap: _tapPeg,
                        ),
                      ),
                      const SizedBox(height: 11),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 46),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: invalidPeg != null
                              ? const Color(0x33FF5E57)
                              : selectedPeg != null
                              ? const Color(0x3300D9FF)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: invalidPeg != null
                                ? const Color(0x99FF5E57)
                                : selectedPeg != null
                                ? const Color(0x9900D9FF)
                                : Colors.white12,
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              invalidPeg != null
                                  ? Icons.warning_amber_rounded
                                  : selectedPeg != null
                                  ? Icons.touch_app_rounded
                                  : Icons.lightbulb_outline_rounded,
                              color: invalidPeg != null
                                  ? const Color(0xFFFF7474)
                                  : selectedPeg != null
                                  ? const Color(0xFF00D9FF)
                                  : const Color(0xFFFFD334),
                              size: 20,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                english ? statusEn : statusTr,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 11),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _HanoiControlButton(
                              label: context.l10n.gameUi(
                                english ? 'UNDO' : 'GERİ AL',
                              ),
                              icon: Icons.undo_rounded,
                              enabled: history.isNotEmpty && !completed,
                              color: const Color(0xFF00D9FF),
                              onTap: _undoMove,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _HanoiControlButton(
                              label: english
                                  ? 'HINT $_remainingHints/$_maxHintsPerLevel'
                                  : 'İPUCU $_remainingHints/$_maxHintsPerLevel',
                              icon: Icons.lightbulb_rounded,
                              enabled: !completed && _remainingHints > 0,
                              color: const Color(0xFFFFD334),
                              onTap: _showHint,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _HanoiControlButton(
                              label: context.l10n.gameUi(
                                english ? 'RESTART' : 'YENİDEN',
                              ),
                              icon: Icons.refresh_rounded,
                              enabled: !completed,
                              color: const Color(0xFFFF8A65),
                              onTap: () => _resetBoard(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HanoiBoard extends StatelessWidget {
  final List<List<int>> pegs;
  final int diskCount;
  final int startPeg;
  final int targetPeg;
  final int? selectedPeg;
  final int? hintTargetPeg;
  final int? invalidPeg;
  final HanoiMove? lastMove;
  final bool english;
  final ValueChanged<int> onPegTap;

  const _HanoiBoard({
    required this.pegs,
    required this.diskCount,
    required this.startPeg,
    required this.targetPeg,
    required this.selectedPeg,
    required this.hintTargetPeg,
    required this.invalidPeg,
    required this.lastMove,
    required this.english,
    required this.onPegTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 10, 7, 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF102B4D), Color(0xFF081B34)],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0x3349CFFF)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x4400AEEF),
            blurRadius: 22,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CustomPaint(
          painter: const _HanoiBoardPainter(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List<Widget>.generate(3, (index) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _HanoiTower(
                    index: index,
                    disks: pegs[index],
                    totalDiskCount: diskCount,
                    selected: selectedPeg == index,
                    hintTarget: hintTargetPeg == index,
                    invalid: invalidPeg == index,
                    start: startPeg == index,
                    target: targetPeg == index,
                    recentlyMoved: lastMove?.to == index,
                    english: english,
                    onTap: () => onPegTap(index),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _HanoiTower extends StatelessWidget {
  static const List<Color> _diskColors = <Color>[
    Color(0xFFFFD334),
    Color(0xFFFF6B6B),
    Color(0xFFB06CFF),
    Color(0xFF00D9FF),
    Color(0xFF54E56B),
  ];

  final int index;
  final List<int> disks;
  final int totalDiskCount;
  final bool selected;
  final bool hintTarget;
  final bool invalid;
  final bool start;
  final bool target;
  final bool recentlyMoved;
  final bool english;
  final VoidCallback onTap;

  const _HanoiTower({
    required this.index,
    required this.disks,
    required this.totalDiskCount,
    required this.selected,
    required this.hintTarget,
    required this.invalid,
    required this.start,
    required this.target,
    required this.recentlyMoved,
    required this.english,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = target
        ? const Color(0x8854E56B)
        : Colors.white.withValues(alpha: 0.08);
    Color backgroundColor = target
        ? const Color(0x1254E56B)
        : Colors.transparent;

    if (recentlyMoved) borderColor = const Color(0x6600D9FF);
    if (hintTarget) {
      borderColor = const Color(0xFF54E56B);
      backgroundColor = const Color(0x2454E56B);
    }
    if (selected) {
      borderColor = const Color(0xFF00D9FF);
      backgroundColor = const Color(0x2400D9FF);
    }
    if (invalid) {
      borderColor = const Color(0xFFFF5E57);
      backgroundColor = const Color(0x30FF5E57);
    }

    return Semantics(
      button: true,
      label: english
          ? '${HanoiLevel.pegName(index)} tower'
          : '${HanoiLevel.pegName(index)} kulesi',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: borderColor,
                width: selected || hintTarget || invalid ? 2 : 1,
              ),
            ),
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 7, 4, 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      if (target)
                        const Padding(
                          padding: EdgeInsets.only(right: 3),
                          child: Icon(
                            Icons.flag_rounded,
                            size: 12,
                            color: Color(0xFF54E56B),
                          ),
                        ),
                      Text(
                        HanoiLevel.pegName(index),
                        style: TextStyle(
                          color: target
                              ? const Color(0xFF8CFF9D)
                              : Colors.white70,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (start || target)
                  Text(
                    target
                        ? english
                              ? 'TARGET'
                              : 'HEDEF'
                        : english
                        ? 'START'
                        : 'BAŞLANGIÇ',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: target ? const Color(0xAA54E56B) : Colors.white38,
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  )
                else
                  const SizedBox(height: 9),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double diskHeight = totalDiskCount >= 5 ? 25 : 28;
                      final double gap = totalDiskCount >= 5 ? 4 : 5;
                      final double maximumWidth = constraints.maxWidth * 0.91;
                      final double minimumWidth = constraints.maxWidth * 0.46;

                      return Stack(
                        alignment: Alignment.bottomCenter,
                        clipBehavior: Clip.none,
                        children: <Widget>[
                          Positioned(
                            top: 13,
                            bottom: 17,
                            child: Container(
                              width: 8,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: <Color>[
                                    Color(0xFF8FB5D8),
                                    Color(0xFF345A7D),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: const <BoxShadow>[
                                  BoxShadow(
                                    color: Color(0x5500D9FF),
                                    blurRadius: 7,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 5,
                            right: 5,
                            bottom: 7,
                            child: Container(
                              height: 12,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: <Color>[
                                    Color(0xFF52789A),
                                    Color(0xFF1B3C5D),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(color: Colors.white12),
                              ),
                            ),
                          ),
                          for (int order = 0; order < disks.length; order++)
                            Builder(
                              builder: (context) {
                                final int disk = disks[order];
                                final bool selectedDisk =
                                    selected && order == disks.length - 1;
                                final double ratio = totalDiskCount <= 1
                                    ? 1
                                    : disk / (totalDiskCount - 1);
                                final double width =
                                    minimumWidth +
                                    (maximumWidth - minimumWidth) * ratio;
                                final Color color =
                                    _diskColors[disk % _diskColors.length];

                                return AnimatedPositioned(
                                  key: ValueKey<String>('tower_${index}_$disk'),
                                  duration: const Duration(milliseconds: 155),
                                  curve: Curves.easeOutCubic,
                                  width: width,
                                  height: diskHeight,
                                  bottom:
                                      19 +
                                      order * (diskHeight + gap) +
                                      (selectedDisk ? 12 : 0),
                                  child: AnimatedScale(
                                    duration: const Duration(milliseconds: 140),
                                    scale: selectedDisk ? 1.04 : 1,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: <Color>[
                                            Color.lerp(
                                              color,
                                              Colors.white,
                                              0.30,
                                            )!,
                                            color,
                                            Color.lerp(
                                              color,
                                              Colors.black,
                                              0.28,
                                            )!,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(99),
                                        border: Border.all(
                                          color: selectedDisk
                                              ? Colors.white
                                              : color.withValues(alpha: 0.92),
                                          width: selectedDisk ? 2.2 : 1.2,
                                        ),
                                        boxShadow: <BoxShadow>[
                                          BoxShadow(
                                            color: color.withValues(
                                              alpha: selectedDisk ? 0.72 : 0.35,
                                            ),
                                            blurRadius: selectedDisk ? 14 : 7,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Container(
                                          width: 15,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF07162E),
                                            borderRadius: BorderRadius.circular(
                                              99,
                                            ),
                                            border: Border.all(
                                              color: Colors.white24,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      );
                    },
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

class _HanoiControlButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final Color color;
  final VoidCallback onTap;

  const _HanoiControlButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(15),
          child: Ink(
            decoration: BoxDecoration(
              color: enabled
                  ? color.withValues(alpha: 0.13)
                  : Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: enabled ? color.withValues(alpha: 0.55) : Colors.white10,
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      icon,
                      size: 18,
                      color: enabled ? color : Colors.white24,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: TextStyle(
                        color: enabled ? Colors.white : Colors.white30,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HanoiTopStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _HanoiTopStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 61,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF102A4A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, size: 19, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  value,
                  maxLines: 1,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontWeight: FontWeight.w800,
                    fontSize: 7,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HanoiResultBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _HanoiResultBox({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, color: const Color(0xFF00D9FF), size: 20),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 7,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HanoiProgressPanel extends StatelessWidget {
  final int totalScore;
  final int totalStars;
  final int unlockedLevel;
  final bool english;

  const _HanoiProgressPanel({
    required this.totalScore,
    required this.totalStars,
    required this.unlockedLevel,
    required this.english,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF173A63), Color(0xFF10254A)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x5554E56B)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x3300D9FF),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0x2200D9FF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0x6600D9FF)),
            ),
            child: const _MiniHanoiIcon(diskCount: 4),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  english ? 'HANOI MASTERY' : 'HANOİ USTALIĞI',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  english
                      ? 'Level $unlockedLevel / 10  •  ⭐ $totalStars / 30'
                      : 'Seviye $unlockedLevel / 10  •  ⭐ $totalStars / 30',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: totalStars / 30,
                    minHeight: 7,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF54E56B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 11),
          Column(
            children: <Widget>[
              const Icon(
                Icons.bolt_rounded,
                color: Color(0xFFFFD334),
                size: 21,
              ),
              FittedBox(
                child: Text(
                  '$totalScore',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HanoiLevelCard extends StatelessWidget {
  final HanoiLevel level;
  final bool unlocked;
  final int stars;
  final int bestMoves;
  final bool english;
  final VoidCallback onTap;

  const _HanoiLevelCard({
    required this.level,
    required this.unlocked,
    required this.stars,
    required this.bestMoves,
    required this.english,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = level.boss
        ? const Color(0xFFFFD334)
        : level.diskCount == 5
        ? const Color(0xFFB06CFF)
        : const Color(0xFF00D9FF);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: unlocked ? onTap : null,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: unlocked
                  ? <Color>[
                      const Color(0xFF14365B),
                      Color.lerp(const Color(0xFF0B2442), accent, 0.07)!,
                    ]
                  : const <Color>[Color(0xFF132238), Color(0xFF0D192B)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: unlocked ? accent.withValues(alpha: 0.46) : Colors.white10,
            ),
            boxShadow: unlocked
                ? <BoxShadow>[
                    BoxShadow(
                      color: accent.withValues(alpha: 0.12),
                      blurRadius: 13,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.45),
                            ),
                          ),
                          child: Text(
                            '${level.number}',
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          english ? level.difficultyEn : level.difficulty,
                          style: TextStyle(
                            color: accent.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w900,
                            fontSize: 8,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 48,
                      child: Opacity(
                        opacity: unlocked ? 1 : 0.35,
                        child: _MiniHanoiIcon(diskCount: level.diskCount),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      level.title(english),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      level.subtitle(english),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 8,
                        height: 1.15,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: <Widget>[
                        for (int index = 0; index < 3; index++)
                          Icon(
                            index < stars
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: const Color(0xFFFFD334),
                            size: 16,
                          ),
                        const Spacer(),
                        Icon(
                          Icons.swap_horiz_rounded,
                          color: Colors.white38,
                          size: 14,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          bestMoves == 0 ? '-' : '$bestMoves',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontWeight: FontWeight.w800,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!unlocked)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0x8807162E),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.lock_rounded,
                        color: Colors.white38,
                        size: 31,
                      ),
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

class _MiniHanoiIcon extends StatelessWidget {
  final int diskCount;

  const _MiniHanoiIcon({required this.diskCount});

  @override
  Widget build(BuildContext context) {
    const List<Color> colors = <Color>[
      Color(0xFFFFD334),
      Color(0xFFFF6B6B),
      Color(0xFFB06CFF),
      Color(0xFF00D9FF),
      Color(0xFF54E56B),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          Positioned(
            top: 1,
            bottom: 3,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF7FA6C8),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          Positioned(
            left: 2,
            right: 2,
            bottom: 0,
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFF52789A),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          for (int index = 0; index < diskCount; index++)
            Positioned(
              bottom: 5 + index * 7,
              width: 24 + (diskCount - index) * 8,
              height: 7,
              child: Container(
                decoration: BoxDecoration(
                  color: colors[(diskCount - index - 1) % colors.length],
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: colors[(diskCount - index - 1) % colors.length]
                          .withValues(alpha: 0.35),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HanoiLoadingView extends StatelessWidget {
  const _HanoiLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 110,
        height: 95,
        child: _MiniHanoiIcon(diskCount: 5),
      ),
    );
  }
}

class _HanoiBoardPainter extends CustomPainter {
  const _HanoiBoardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint dotPaint = Paint()..color = const Color(0x1200D9FF);
    const double step = 24;

    for (double x = 8; x < size.width; x += step) {
      for (double y = 8; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }

    final Paint glowPaint = Paint()
      ..shader =
          const RadialGradient(
            colors: <Color>[Color(0x2200D9FF), Color(0x0000D9FF)],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width / 2, size.height * 0.72),
              radius: size.width * 0.55,
            ),
          );

    canvas.drawRect(Offset.zero & size, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _HanoiBoardPainter oldDelegate) => false;
}

class HanoiSolver {
  const HanoiSolver._();

  static List<HanoiMove> legalMoves(List<List<int>> pegs) {
    final List<HanoiMove> moves = <HanoiMove>[];
    for (int from = 0; from < pegs.length; from++) {
      if (pegs[from].isEmpty) continue;
      final int movingDisk = pegs[from].last;
      for (int to = 0; to < pegs.length; to++) {
        if (from == to) continue;
        final int? targetTop = pegs[to].isEmpty ? null : pegs[to].last;
        if (targetTop != null && targetTop < movingDisk) continue;
        moves.add(HanoiMove(from: from, to: to, disk: movingDisk));
      }
    }
    return moves;
  }

  static int minimumMoves({
    required List<List<int>> pegs,
    required int diskCount,
    required int targetPeg,
  }) {
    final List<int> startPositions = List<int>.filled(
      diskCount,
      0,
      growable: false,
    );
    for (int peg = 0; peg < pegs.length; peg++) {
      for (final int disk in pegs[peg]) {
        startPositions[disk] = peg;
      }
    }

    final int startCode = _encode(startPositions);
    final int goalCode = _encode(
      List<int>.filled(diskCount, targetPeg, growable: false),
    );
    if (startCode == goalCode) return 0;

    final ListQueue<int> queue = ListQueue<int>()..add(startCode);
    final Map<int, int> distance = <int, int>{startCode: 0};
    while (queue.isNotEmpty) {
      final int code = queue.removeFirst();
      final int currentDistance = distance[code]!;
      final List<int> positions = _decode(code, diskCount);
      final List<int?> topDisks = List<int?>.filled(3, null);
      for (int disk = 0; disk < diskCount; disk++) {
        topDisks[positions[disk]] ??= disk;
      }

      for (int from = 0; from < 3; from++) {
        final int? movingDisk = topDisks[from];
        if (movingDisk == null) continue;
        for (int to = 0; to < 3; to++) {
          if (from == to) continue;
          final int? targetTop = topDisks[to];
          if (targetTop != null && targetTop < movingDisk) continue;
          final List<int> nextPositions = List<int>.from(positions);
          nextPositions[movingDisk] = to;
          final int nextCode = _encode(nextPositions);
          if (distance.containsKey(nextCode)) continue;
          final int nextDistance = currentDistance + 1;
          if (nextCode == goalCode) return nextDistance;
          distance[nextCode] = nextDistance;
          queue.add(nextCode);
        }
      }
    }
    return -1;
  }

  static HanoiMove? nextMove({
    required List<List<int>> pegs,
    required int diskCount,
    required int targetPeg,
  }) {
    final List<int> startPositions = List<int>.filled(
      diskCount,
      0,
      growable: false,
    );

    for (int peg = 0; peg < pegs.length; peg++) {
      for (final int disk in pegs[peg]) {
        startPositions[disk] = peg;
      }
    }

    final int startCode = _encode(startPositions);
    final int goalCode = _encode(
      List<int>.filled(diskCount, targetPeg, growable: false),
    );

    if (startCode == goalCode) return null;

    final ListQueue<int> queue = ListQueue<int>()..add(startCode);
    final Set<int> visited = <int>{startCode};
    final Map<int, HanoiMove> firstMoves = <int, HanoiMove>{};

    while (queue.isNotEmpty) {
      final int code = queue.removeFirst();
      final List<int> positions = _decode(code, diskCount);
      final List<int?> topDisks = List<int?>.filled(3, null);

      for (int disk = 0; disk < diskCount; disk++) {
        final int peg = positions[disk];
        topDisks[peg] ??= disk;
      }

      for (int from = 0; from < 3; from++) {
        final int? movingDisk = topDisks[from];
        if (movingDisk == null) continue;

        for (int to = 0; to < 3; to++) {
          if (from == to) continue;
          final int? targetTop = topDisks[to];
          if (targetTop != null && targetTop < movingDisk) continue;

          final List<int> nextPositions = List<int>.from(positions);
          nextPositions[movingDisk] = to;
          final int nextCode = _encode(nextPositions);

          if (!visited.add(nextCode)) continue;

          final HanoiMove move = HanoiMove(
            from: from,
            to: to,
            disk: movingDisk,
          );
          firstMoves[nextCode] = code == startCode ? move : firstMoves[code]!;

          if (nextCode == goalCode) return firstMoves[nextCode];
          queue.add(nextCode);
        }
      }
    }

    return null;
  }

  static int _encode(List<int> positions) {
    int code = 0;
    int factor = 1;
    for (final int peg in positions) {
      code += peg * factor;
      factor *= 3;
    }
    return code;
  }

  static List<int> _decode(int code, int diskCount) {
    int remaining = code;
    return List<int>.generate(diskCount, (_) {
      final int peg = remaining % 3;
      remaining ~/= 3;
      return peg;
    });
  }
}

class HanoiLevel {
  final int number;
  final String titleTr;
  final String titleEn;
  final String subtitleTr;
  final String subtitleEn;
  final String difficulty;
  final int diskCount;
  final int startPeg;
  final int targetPeg;
  final int twoStarLimit;
  final bool tutorial;
  final bool boss;

  const HanoiLevel({
    required this.number,
    required this.titleTr,
    required this.titleEn,
    required this.subtitleTr,
    required this.subtitleEn,
    required this.difficulty,
    required this.diskCount,
    required this.startPeg,
    required this.targetPeg,
    required this.twoStarLimit,
    this.tutorial = false,
    this.boss = false,
  });

  String title(bool english) => english ? titleEn : titleTr;
  String subtitle(bool english) => english ? subtitleEn : subtitleTr;

  String get difficultyEn {
    switch (difficulty) {
      case 'KOLAY':
        return 'EASY';
      case 'ORTA':
        return 'MEDIUM';
      case 'ZOR':
        return 'HARD';
      default:
        return difficulty;
    }
  }

  static String pegName(int index) => String.fromCharCode(65 + index);
}

class HanoiMove {
  final int from;
  final int to;
  final int disk;

  const HanoiMove({required this.from, required this.to, required this.disk});
}

class HanoiLevelResult {
  final bool completed;
  final int stars;
  final int score;
  final int moves;
  final bool nextLevel;

  const HanoiLevelResult({
    required this.completed,
    required this.stars,
    required this.score,
    required this.moves,
    required this.nextLevel,
  });
}
