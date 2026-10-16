import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../widgets/studio_chapter_card.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';
import '../../services/daily_challenge_service.dart';
import '../../services/daily_course_service.dart';
import '../../services/game_audio_service.dart';
import '../../services/common_level_score_service.dart';
import '../../services/replayability_service.dart';
import '../../theme/studio_visuals.dart';
import '../../widgets/advanced_result_banner.dart';
import '../shared/studio_game_contracts.dart';
import '../shared/campaign_round_store.dart';
import '../shared/studio_game_session.dart';

abstract final class HanoiVisuals {
  static const List<Color> rings = <Color>[
    Color(0xFFFF4D6D),
    Color(0xFFFF9F1C),
    Color(0xFFFFD60A),
    Color(0xFF2EE6A6),
    Color(0xFF21C9F5),
    Color(0xFF5574FF),
    Color(0xFFA855F7),
    Color(0xFFFF4FD8),
  ];

  static const Color boardTop = Color(0xFF1A3153);
  static const Color boardBottom = Color(0xFF0D1930);
  static const Color towerLine = Color(0xFF476986);
  static const Color cyan = Color(0xFF21C9F5);
  static const Color mint = Color(0xFF2EE6A6);
  static const Color mintInk = Color(0xFF65FFD0);
  static const Color rodTop = Color(0xFFD9FBFF);
  static const Color rodBottom = Color(0xFF50A8D4);
  static const Color baseTop = Color(0xFF32E3D0);
  static const Color baseBottom = Color(0xFF167A9C);
}

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
  List<int> stars = List<int>.filled(GameContentPolicy.campaignLevels, 0);
  List<int> bestScores = List<int>.filled(GameContentPolicy.campaignLevels, 0);
  List<int> bestMoves = List<int>.filled(GameContentPolicy.campaignLevels, 0);
  bool _competitionOpened = false;

  static const List<HanoiLevel> _nativeLevels = <HanoiLevel>[
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

  static final List<HanoiLevel> levels = List.generate(
    GameContentPolicy.campaignLevels,
    (index) {
      final chapter = index + 1;
      final base = _nativeLevels[GameContentPolicy.nativeLevel(chapter) - 1];
      return HanoiLevel(
        number: chapter,
        sourceNumber: base.number,
        difficulty: GameContentPolicy.difficulty(chapter),
        titleTr: chapter == 1
            ? base.titleTr
            : 'Kule Planı ${chapter.toString().padLeft(2, '0')}',
        titleEn: chapter == 1
            ? base.titleEn
            : 'Tower Plan ${chapter.toString().padLeft(2, '0')}',
        subtitleTr: 'Halkaları en kısa hamle planıyla hedefe taşı',
        subtitleEn: 'Plan the shortest route to the target tower',
        diskCount: base.diskCount,
        startPeg: base.startPeg,
        targetPeg: base.targetPeg,
        twoStarLimit: base.twoStarLimit,
        tutorial: base.tutorial,
        boss: base.boss,
      );
    },
    growable: false,
  );

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
        stars = _decodeList(savedStars);
        unlockedLevel = GameContentPolicy.safeUnlocked(savedLevel, stars);
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

    final int poolIndex = widget.competitionLayoutCode != null
        ? GameContentPolicy.poolIndex(
            index + 1,
            widget.competitionLayoutCode!.abs() % 10,
            stages: 300,
          )
        : await CampaignRoundStore.reserve('hanoi', index + 1);
    if (!mounted) return;
    final playable = levels[index].withBoard(
      HanoiCampaignBoard.forPool(poolIndex),
    );
    final List<int> previousStars = List<int>.from(stars);
    final CommonLevelScoreSession scoring = CommonLevelScoreSession.begin();
    final HanoiLevelResult? result;
    try {
      result = await Navigator.push<HanoiLevelResult>(
        context,
        MaterialPageRoute(
          builder: (_) => HanoiPlayPage(
            level: playable,
            totalLevels: levels.length,
            savedBestMoves: bestMoves[index],
            previousBestScore: bestScores[index],
            fixedSessionSeed: widget.competitionLayoutCode,
            competitionMode: widget.competitionLevel != null,
          ),
        ),
      );
    } finally {
      scoring.finish();
    }
    final int commonPoints = scoring.points;

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
                rawScore: commonPoints,
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
    final HanoiLevelResult completedResult = result;

    if (widget.competitionLevel != null) {
      Navigator.pop(
        context,
        DailyCourseGameResult(
          gameId: 'hanoi',
          stars: completedResult.stars,
          score: commonPoints,
        ),
      );
      return;
    }

    setState(() {
      stars[index] = max(stars[index], completedResult.stars);
      bestScores[index] = max(bestScores[index], completedResult.score);

      if (bestMoves[index] == 0 || completedResult.moves < bestMoves[index]) {
        bestMoves[index] = completedResult.moves;
      }

      if (index + 1 == unlockedLevel && unlockedLevel < levels.length) {
        unlockedLevel++;
      }
    });

    await CommonLevelScoreStore.recordBest(
      gameId: 'hanoi',
      levelIndex: index,
      points: commonPoints,
      levelCount: levels.length,
      completedStars: previousStars,
    );

    // Persistence must not block the result flow or the next level.
    unawaited(_saveProgress());

    await DailyChallengeService.instance.recordLevelCompleted(
      gameId: 'hanoi',
      stars: completedResult.stars,
      score: commonPoints,
    );

    if (completedResult.nextLevel && index + 1 < levels.length && mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 160));
      if (mounted) await _openLevel(index + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool english = context.l10n.isEnglish;

    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.gameUi(english ? 'TOWER OF HANOI' : 'HANOİ KULESİ'),
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: StudioVisuals.ink,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 0.4,
              ),
            ),
            Text(
              context.l10n.gameUi(
                english ? 'Plan • Move • Complete' : 'Planla • Taşı • Tamamla',
              ),
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: StudioVisuals.muted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveGameFrame(
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
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 1,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          mainAxisExtent:
                              104 *
                              MediaQuery.textScalerOf(context)
                                  .scale(1)
                                  .clamp(1.0, 1.6),
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

  static const int _maxHintsPerLevel = StudioGameSession.defaultMaxHints;

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

    final List<List<int>> initial = level.initialPegs != null
        ? _copyPegs(level.initialPegs!)
        : level.contentLevel <= 4
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
    final int steps =
        level.contentLevel * 2 + random.nextInt(level.contentLevel + 3);
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
        : level.contentLevel >= 5
        ? 'Dağıtılmış halkaları hedef kulede topla.'
        : 'Bütün halkaları hedef kulede topla.';
    statusEn = level.tutorial
        ? 'Tap a tower to select its top ring.'
        : level.contentLevel >= 5
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

    unawaited(
      _audio.playVictory(
        stars: earnedStars,
        boss: level.boss,
        levelNumber: level.number,
      ),
    );

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
                  colors: <Color>[Color(0xFFFFFFFF), Color(0xFFEEF3F0)],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: level.boss
                      ? const Color(0xFF9A5C00)
                      : const Color(0xFF087B67),
                  width: 2,
                ),
                boxShadow: const <BoxShadow>[
                  BoxShadow(color: Color(0x554DCFFF), blurRadius: 26),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    level.boss
                        ? Icons.emoji_events_rounded
                        : Icons.account_tree_rounded,
                    color: const Color(0xFF9A5C00),
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
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 10),
                  AdvancedResultBanner(
                    score: score,
                    previousBestScore: widget.previousBestScore,
                    english: english,
                    accentColor: const Color(0xFF087FA8),
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
                        color: const Color(0xFF9A5C00),
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
        backgroundColor: const Color(0xFFFFFFFF),
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
          style: const TextStyle(fontFamily: 'Roboto', height: 1.55),
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
        backgroundColor: Color(0xFFF6F8F6),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF087B67)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
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
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            Text(
              english
                  ? 'Level ${level.number} / ${widget.totalLevels}'
                  : 'Seviye ${level.number} / ${widget.totalLevels}',
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: StudioVisuals.muted,
                fontSize: 10,
              ),
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
              const Color(0xFFEEF3F0),
              const Color(0xFFF6F8F6),
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
                              color: const Color(0xFF087FA8),
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
                              color: const Color(0xFF9A5C00),
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
                              color: const Color(0xFF087B67),
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
                          color: const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0x6600A987)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Icon(
                              Icons.flag_rounded,
                              color: Color(0xFF087B67),
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
                                  fontFamily: 'Roboto',
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
                              ? const Color(0x33A84640)
                              : selectedPeg != null
                              ? const Color(0x333D7183)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: invalidPeg != null
                                ? const Color(0x99A84640)
                                : selectedPeg != null
                                ? const Color(0x993D7183)
                                : StudioVisuals.line,
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
                                  ? const Color(0xFFA84640)
                                  : selectedPeg != null
                                  ? const Color(0xFF087FA8)
                                  : const Color(0xFF9A5C00),
                              size: 20,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                english ? statusEn : statusTr,
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  color: StudioVisuals.muted,
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
                              color: const Color(0xFF087FA8),
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
                              color: const Color(0xFF9A5C00),
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
                              color: const Color(0xFFD94367),
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
          colors: <Color>[HanoiVisuals.boardTop, HanoiVisuals.boardBottom],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFF3C7796), width: 1.5),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x303366FF),
            blurRadius: 22,
            offset: Offset(0, 8),
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
  static const List<Color> _diskColors = HanoiVisuals.rings;

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
        ? const Color(0xAA2EE6A6)
        : HanoiVisuals.towerLine;
    Color backgroundColor = target
        ? const Color(0x182EE6A6)
        : const Color(0x0D8BD8FF);

    if (recentlyMoved) borderColor = HanoiVisuals.cyan.withValues(alpha: .8);
    if (hintTarget) {
      borderColor = HanoiVisuals.mint;
      backgroundColor = const Color(0x282EE6A6);
    }
    if (selected) {
      borderColor = HanoiVisuals.cyan;
      backgroundColor = const Color(0x2821C9F5);
    }
    if (invalid) {
      borderColor = const Color(0xFFA84640);
      backgroundColor = const Color(0x30FF4D6D);
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
                            color: HanoiVisuals.mint,
                          ),
                        ),
                      Text(
                        HanoiLevel.pegName(index),
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          color: target
                              ? HanoiVisuals.mintInk
                              : const Color(0xFFD8E9FF),
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
                      fontFamily: 'Roboto',
                      color: target
                          ? HanoiVisuals.mintInk
                          : const Color(0xFFB6D0E8),
                      fontSize: 12,
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
                                    HanoiVisuals.rodTop,
                                    HanoiVisuals.rodBottom,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: const <BoxShadow>[
                                  BoxShadow(
                                    color: Color(0x664DCFFF),
                                    blurRadius: 10,
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
                                    HanoiVisuals.baseTop,
                                    HanoiVisuals.baseBottom,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                  color: const Color(0xFF8CFFF1),
                                  width: 1.1,
                                ),
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
                                              0.24,
                                            )!,
                                            color,
                                            Color.lerp(
                                              color,
                                              Colors.black,
                                              0.18,
                                            )!,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(99),
                                        border: Border.all(
                                          color: selectedDisk
                                              ? const Color(0xFFE8FFFF)
                                              : Color.lerp(
                                                  color,
                                                  Colors.white,
                                                  0.45,
                                                )!,
                                          width: selectedDisk ? 2.4 : 1.3,
                                        ),
                                        boxShadow: <BoxShadow>[
                                          BoxShadow(
                                            color: color.withValues(
                                              alpha: selectedDisk ? 0.55 : 0.32,
                                            ),
                                            blurRadius: selectedDisk ? 16 : 9,
                                            offset: const Offset(0, 3),
                                          ),
                                          const BoxShadow(
                                            color: Color(0x66061120),
                                            blurRadius: 4,
                                            offset: Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Container(
                                          width: 15,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEEF3F0),
                                            borderRadius: BorderRadius.circular(
                                              99,
                                            ),
                                            border: Border.all(
                                              color: StudioVisuals.line,
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
                color: enabled
                    ? color.withValues(alpha: 0.55)
                    : StudioVisuals.line,
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
                      color: enabled ? color : StudioVisuals.line,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: enabled
                            ? StudioVisuals.ink
                            : StudioVisuals.muted,
                        fontSize: 12,
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
        color: const Color(0xFFFFFFFF),
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
                    fontFamily: 'Roboto',
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
                    fontFamily: 'Roboto',
                    color: StudioVisuals.muted,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
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
          Icon(icon, color: const Color(0xFF3D7183), size: 20),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: StudioVisuals.muted,
              fontSize: 10,
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
        color: StudioVisuals.surface,
        borderRadius: StudioVisuals.cardRadius,
        border: Border.all(color: StudioVisuals.line),
        boxShadow: StudioVisuals.softShadow,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: StudioVisuals.tealSoft,
              shape: BoxShape.circle,
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
                    fontFamily: 'Roboto',
                    color: StudioVisuals.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  english
                      ? 'Level $unlockedLevel / ${GameContentPolicy.campaignLevels}  •  ⭐ $totalStars / ${GameContentPolicy.campaignLevels * 3}'
                      : 'Seviye $unlockedLevel / ${GameContentPolicy.campaignLevels}  •  ⭐ $totalStars / ${GameContentPolicy.campaignLevels * 3}',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: StudioVisuals.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: (totalStars / (GameContentPolicy.campaignLevels * 3))
                        .clamp(0.0, 1.0),
                    minHeight: 7,
                    backgroundColor: StudioVisuals.surfaceSoft,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      StudioVisuals.teal,
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
                color: StudioVisuals.amber,
                size: 21,
              ),
              FittedBox(
                child: Text(
                  '$totalScore',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: StudioVisuals.ink,
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
  Widget build(BuildContext context) => StudioChapterCard(
    gameId: 'hanoi',
    number: level.number,
    title: level.title(english),
    detail: level.subtitle(english),
    difficulty: english ? level.difficultyEn : level.difficulty,
    unlocked: unlocked,
    stars: stars,
    best: bestMoves,
    onTap: onTap,
  );
}

class _MiniHanoiIcon extends StatelessWidget {
  final int diskCount;

  const _MiniHanoiIcon({required this.diskCount});

  @override
  Widget build(BuildContext context) {
    const List<Color> colors = HanoiVisuals.rings;

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
                gradient: const LinearGradient(
                  colors: <Color>[HanoiVisuals.rodTop, HanoiVisuals.rodBottom],
                ),
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
                gradient: const LinearGradient(
                  colors: <Color>[
                    HanoiVisuals.baseTop,
                    HanoiVisuals.baseBottom,
                  ],
                ),
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
                          .withValues(alpha: 0.65),
                      blurRadius: 7,
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
    final Paint grain = Paint()
      ..color = const Color(0xFF66DDF7).withValues(alpha: .12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8;
    for (double y = 12; y < size.height; y += 16) {
      final Path line = Path()..moveTo(0, y);
      for (double x = 8; x <= size.width; x += 8) {
        line.lineTo(x, y + sin(x / 43 + y / 30) * 1.7);
      }
      canvas.drawPath(line, grain);
    }
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

/// A finite, verified bank: every legal state is reached by BFS from the goal.
/// Sampling the sorted distances gives 300 distinct, progressively harder
/// boards without asking the storage service to generate content.
class HanoiCampaignBoard {
  const HanoiCampaignBoard({
    required this.pegs,
    required this.diskCount,
    required this.optimalMoves,
    this.targetPeg = 2,
  });
  final List<List<int>> pegs;
  final int diskCount;
  final int optimalMoves;
  final int targetPeg;
  String get signature =>
      '$diskCount:${pegs.map((peg) => peg.join(',')).join('/')}';
  static final List<HanoiCampaignBoard> _pool = _build();
  static HanoiCampaignBoard forPool(int index) {
    RangeError.checkValueInInterval(index, 1, 300, 'index');
    return _pool[index - 1];
  }

  static List<HanoiCampaignBoard> _build() {
    final candidates = <HanoiCampaignBoard>[];
    for (int disks = 3; disks <= 6; disks++) {
      final goal = <List<int>>[
        [],
        [],
        List.generate(disks, (i) => disks - i - 1),
      ];
      String key(List<List<int>> pegs) =>
          pegs.map((peg) => peg.join(',')).join('/');
      final distances = <String, int>{key(goal): 0};
      final queue = Queue<List<List<int>>>()..add(goal);
      while (queue.isNotEmpty) {
        final state = queue.removeFirst();
        final distance = distances[key(state)]!;
        if (distance >= 3) {
          candidates.add(
            HanoiCampaignBoard(
              pegs: List.unmodifiable(
                state.map((peg) => List<int>.unmodifiable(peg)),
              ),
              diskCount: disks,
              optimalMoves: distance,
            ),
          );
        }
        for (final move in HanoiSolver.legalMoves(state)) {
          final next = state.map((peg) => List<int>.from(peg)).toList();
          next[move.to].add(next[move.from].removeLast());
          final signature = key(next);
          if (distances.containsKey(signature)) continue;
          distances[signature] = distance + 1;
          queue.add(next);
        }
      }
    }
    candidates.sort((a, b) {
      final distance = a.optimalMoves.compareTo(b.optimalMoves);
      if (distance != 0) return distance;
      final disks = a.diskCount.compareTo(b.diskCount);
      return disks != 0 ? disks : a.signature.compareTo(b.signature);
    });
    return List.unmodifiable(
      List.generate(300, (i) => candidates[i * (candidates.length - 1) ~/ 299]),
    );
  }
}

class HanoiLevel {
  final List<List<int>>? initialPegs;
  final int number;
  final int? sourceNumber;
  int get contentLevel => sourceNumber ?? number;
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
    this.sourceNumber,
    this.initialPegs,
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

  HanoiLevel withBoard(HanoiCampaignBoard board) => HanoiLevel(
    number: number,
    sourceNumber: sourceNumber,
    initialPegs: board.pegs,
    titleTr: titleTr,
    titleEn: titleEn,
    subtitleTr: subtitleTr,
    subtitleEn: subtitleEn,
    difficulty: difficulty,
    diskCount: board.diskCount,
    startPeg: startPeg,
    targetPeg: board.targetPeg,
    twoStarLimit: board.optimalMoves + max(2, board.optimalMoves ~/ 3),
    tutorial: number == 1,
    boss: number == GameContentPolicy.campaignLevels,
  );

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
