import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/advanced_result_banner.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../services/replayability_service.dart';
import '../../services/daily_challenge_service.dart';
import '../../services/daily_course_service.dart';
import '../../services/game_audio_service.dart';
import '../../theme/app_visual_theme.dart';
import 'shape_match_game_page.dart';

class MemoryGamePage extends StatefulWidget {
  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  const MemoryGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  @override
  State<MemoryGamePage> createState() => _MemoryGamePageState();
}

class _MemoryGamePageState extends State<MemoryGamePage> {
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  bool loading = true;
  int unlockedLevel = 1;

  List<int> stars = List<int>.filled(10, 0);
  List<int> bestScores = List<int>.filled(10, 0);
  bool _competitionOpened = false;

  final List<MemoryLevel> levels = const [
    MemoryLevel(
      number: 1,
      title: 'İlk Işık',
      subtitle: '5 tur boyunca kısa ışık dizisini hatırla',
      difficulty: 'KOLAY',
      gridSize: 3,
      sequenceLength: 3,
      previewMs: 620,
      rounds: 5,
      lives: 4,
    ),
    MemoryLevel(
      number: 2,
      title: 'Renk Yolu',
      subtitle: '5 turda uzayan diziyi takip et',
      difficulty: 'KOLAY',
      gridSize: 3,
      sequenceLength: 4,
      previewMs: 560,
      rounds: 5,
      lives: 4,
    ),
    MemoryLevel(
      number: 3,
      title: 'Hızlanan Zihin',
      subtitle: '5 hızlı turda daha çok kareyi hatırla',
      difficulty: 'ORTA',
      gridSize: 4,
      sequenceLength: 5,
      previewMs: 500,
      rounds: 5,
      lives: 4,
    ),
    MemoryLevel(
      number: 4,
      title: 'Şekil Eşleştirme',
      titleEn: 'Shape Matching',
      subtitle: 'İki aşamada 8 karttaki çiftleri bul',
      subtitleEn: 'Match the 8 cards across two stages',
      difficulty: 'ORTA',
      gridSize: 4,
      sequenceLength: 5,
      previewMs: 500,
      rounds: 2,
      lives: 3,
      matchCardCount: 8,
    ),
    MemoryLevel(
      number: 5,
      title: 'Sahte Işıklar',
      subtitle: '5 tur boyunca sahte ışıklara aldanma',
      difficulty: 'ZOR',
      gridSize: 4,
      sequenceLength: 6,
      previewMs: 460,
      rounds: 5,
      lives: 4,
      decoys: 2,
    ),
    MemoryLevel(
      number: 6,
      title: 'Nefes',
      subtitle: '6 tur boyunca ritmi ve seriyi koru',
      difficulty: 'KOLAY',
      gridSize: 4,
      sequenceLength: 5,
      previewMs: 540,
      rounds: 6,
      lives: 5,
    ),
    MemoryLevel(
      number: 7,
      title: 'Neon İz',
      subtitle: '6 tur boyunca uzun dizileri çöz',
      difficulty: 'ORTA',
      gridSize: 4,
      sequenceLength: 7,
      previewMs: 430,
      rounds: 6,
      lives: 4,
    ),
    MemoryLevel(
      number: 8,
      title: 'Büyük Eşleştirme',
      titleEn: 'Grand Matching',
      subtitle: 'İki aşamada 16 karttaki çiftleri bul',
      subtitleEn: 'Match the 16 cards across two stages',
      difficulty: 'ZOR',
      gridSize: 5,
      sequenceLength: 7,
      previewMs: 390,
      rounds: 2,
      lives: 3,
      matchCardCount: 16,
    ),
    MemoryLevel(
      number: 9,
      title: 'Zihin Fırtınası',
      subtitle: '6 tur boyunca uzun, hızlı ve ters',
      difficulty: 'ZOR',
      gridSize: 5,
      sequenceLength: 8,
      previewMs: 360,
      rounds: 6,
      lives: 4,
      reverseRecall: true,
      decoys: 3,
    ),
    MemoryLevel(
      number: 10,
      title: 'Hafıza Boss',
      subtitle: '7 turluk usta hafıza sınavı',
      difficulty: 'BOSS',
      gridSize: 5,
      sequenceLength: 9,
      previewMs: 330,
      rounds: 7,
      lives: 4,
      reverseRecall: true,
      decoys: 4,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final int savedLevel = await _prefs.getInt('memory_unlocked_level') ?? 1;

    final List<String>? savedStars = await _prefs.getStringList('memory_stars');

    final List<String>? savedScores = await _prefs.getStringList(
      'memory_best_scores',
    );

    if (!mounted) return;

    setState(() {
      unlockedLevel = savedLevel.clamp(1, 10);
      stars = _decodeList(savedStars);
      bestScores = _decodeList(savedScores);
      loading = false;
    });

    _openCompetitionLevelIfNeeded();
  }

  void _openCompetitionLevelIfNeeded() {
    final int? level = widget.competitionLevel;
    if (_competitionOpened || level == null) return;
    _competitionOpened = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openLevel((level - 1).clamp(0, levels.length - 1).toInt());
    });
  }

  List<int> _decodeList(List<String>? source) {
    return List<int>.generate(10, (index) {
      if (source == null || index >= source.length) return 0;
      return int.tryParse(source[index]) ?? 0;
    });
  }

  Future<void> _saveProgress() async {
    await _prefs.setInt('memory_unlocked_level', unlockedLevel);

    await _prefs.setStringList('memory_stars', stars.map((e) => '$e').toList());

    await _prefs.setStringList(
      'memory_best_scores',
      bestScores.map((e) => '$e').toList(),
    );
  }

  int get totalStars => stars.fold(0, (a, b) => a + b);
  int get totalScore => bestScores.fold(0, (a, b) => a + b);

  Future<void> _openLevel(int index) async {
    if (widget.competitionLevel == null && index + 1 > unlockedLevel) return;

    GameAudioService.instance.play(GameSound.uiClick);

    final MemoryLevel level = levels[index];
    final MemoryLevelResult? result;

    if (level.isShapeMatch) {
      final ShapeMatchResult? matchResult =
          await Navigator.push<ShapeMatchResult>(
            context,
            MaterialPageRoute(
              builder: (_) => ShapeMatchGamePage(
                levelNumber: level.number,
                totalLevels: levels.length,
                cardCount: level.matchCardCount,
                stageCount: level.rounds,
                previousBestScore: bestScores[index],
                fixedSessionSeed: widget.competitionLayoutCode,
                competitionMode: widget.competitionLevel != null,
              ),
            ),
          );

      result = matchResult == null
          ? null
          : MemoryLevelResult(
              completed: matchResult.completed,
              stars: matchResult.stars,
              score: matchResult.score,
              nextLevel: matchResult.nextLevel,
            );
    } else {
      result = await Navigator.push<MemoryLevelResult>(
        context,
        MaterialPageRoute(
          builder: (_) => MemoryPlayPage(
            level: level,
            totalLevels: levels.length,
            previousBestScore: bestScores[index],
            fixedSessionSeed: widget.competitionLayoutCode,
            competitionMode: widget.competitionLevel != null,
          ),
        ),
      );
    }

    if (!mounted) return;

    if (widget.dailyCourseMode) {
      final bool failed =
          result != null &&
          (!result.completed || (result.stars == 0 && result.score == 0));
      Navigator.pop(
        context,
        result == null
            ? const DailyStageResult.exited(gameId: 'memory')
            : failed
            ? const DailyStageResult.failed(gameId: 'memory')
            : DailyStageResult.completed(
                gameId: 'memory',
                stars: result.stars,
                rawScore: result.score,
              ),
      );
      return;
    }

    if (result == null || !result.completed) {
      if (widget.competitionLevel != null && mounted) {
        Navigator.pop(context);
      }
      return;
    }
    final MemoryLevelResult completedResult = result;
    if (widget.competitionLevel != null) {
      Navigator.pop(
        context,
        DailyCourseGameResult(
          gameId: 'memory',
          stars: completedResult.stars,
          score: completedResult.score,
        ),
      );
      return;
    }

    setState(() {
      stars[index] = max(stars[index], completedResult.stars);
      bestScores[index] = max(bestScores[index], completedResult.score);

      if (index + 1 == unlockedLevel && unlockedLevel < levels.length) {
        unlockedLevel++;
      }
    });

    await _saveProgress();

    await DailyChallengeService.instance.recordLevelCompleted(
      gameId: 'memory',
      stars: completedResult.stars,
      score: completedResult.score,
    );

    if (!widget.dailyCourseMode && index + 1 == levels.length) {
      await GameAudioService.instance.playMashallahCelebration();
    }

    if (completedResult.nextLevel && index + 1 < levels.length && mounted) {
      await Future.delayed(const Duration(milliseconds: 180));

      if (mounted) {
        _openLevel(index + 1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading || widget.competitionLevel != null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LText(
              'HAFIZA LABİRENTİ',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            LText(
              'Gör • Hatırla • Tekrarla',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: _MemoryProgressPanel(
                totalScore: totalScore,
                totalStars: totalStars,
                unlockedLevel: unlockedLevel,
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
                itemCount: levels.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  mainAxisExtent: 172,
                ),
                itemBuilder: (context, index) {
                  return _MemoryLevelCard(
                    level: levels[index],
                    unlocked: index + 1 <= unlockedLevel,
                    stars: stars[index],
                    bestScore: bestScores[index],
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

class MemoryPlayPage extends StatefulWidget {
  final MemoryLevel level;
  final int totalLevels;
  final int previousBestScore;
  final int? fixedSessionSeed;
  final bool competitionMode;

  const MemoryPlayPage({
    super.key,
    required this.level,
    required this.totalLevels,
    required this.previousBestScore,
    this.fixedSessionSeed,
    this.competitionMode = false,
  });

  @override
  State<MemoryPlayPage> createState() => _MemoryPlayPageState();
}

class _MemoryPlayPageState extends State<MemoryPlayPage>
    with TickerProviderStateMixin {
  late Random random;
  final ReplayabilityService _replayability = ReplayabilityService();
  final GameAudioService _audio = GameAudioService.instance;

  int sessionSeed = 0;

  late int lives;

  int score = 0;
  int round = 0;
  int combo = 0;
  int bestCombo = 0;

  bool locked = true;
  bool showingSequence = false;
  bool levelFinished = false;

  int? activeCell;
  int? wrongCell;
  int? correctCell;

  List<int> sequence = [];
  List<int> expected = [];
  List<int> playerInput = [];

  String headline = 'HAZIRLAN';
  String subline = 'Işık yolunu dikkatle izle';

  String floatingText = '';
  bool showFloating = false;

  int confettiSeed = 0;
  bool showConfetti = false;

  final List<Color> neonColors = const [
    Color(0xFF00D9FF),
    Color(0xFF745CFF),
    Color(0xFFFF4F9A),
    Color(0xFFFF9F1C),
    Color(0xFFFFD93D),
    Color(0xFF52E86B),
    Color(0xFFFF5E57),
  ];

  bool get _reverseThisRound {
    if (!widget.level.reverseRecall) return false;
    return widget.level.number < 10 || round.isOdd;
  }

  @override
  void initState() {
    super.initState();
    lives = widget.level.lives;

    _audio.preload(GameAudioGroup.memory);
    _audio.playMusic(GameMusic.calm);

    if (widget.level.difficulty == 'BOSS') {
      _audio.play(GameSound.bossIntro);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeSession());
  }

  @override
  void dispose() {
    _audio.stopMusic();
    super.dispose();
  }

  Future<void> _initializeSession() async {
    sessionSeed =
        widget.fixedSessionSeed ??
        await _replayability.newSeed(
          gameId: 'memory',
          level: widget.level.number,
        );

    random = _replayability.randomFor(
      sessionSeed: sessionSeed,
      round: 0,
      salt: 11,
    );

    if (!mounted) return;

    _startRound();
  }

  Future<void> _startRound() async {
    if (!mounted || levelFinished) return;

    setState(() {
      locked = true;
      showingSequence = false;
      playerInput.clear();
      activeCell = null;
      wrongCell = null;
      correctCell = null;
      headline = 'HAZIRLAN';
      subline = _reverseThisRound
          ? 'Bu tur diziyi TERSTEN gireceksin'
          : 'Işık yolunu dikkatle izle';
    });

    _audio.play(GameSound.memoryRoundStart);

    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;

    _generateSequence();

    setState(() {
      headline = 'İZLE';
      subline = 'Sırayı zihninde tut';
      showingSequence = true;
    });

    await Future.delayed(const Duration(milliseconds: 220));

    for (int i = 0; i < sequence.length; i++) {
      if (!mounted) return;

      final int cell = sequence[i];

      setState(() {
        activeCell = cell;
      });

      _audio.playMemoryNote(cell % 8);

      await Future.delayed(Duration(milliseconds: widget.level.previewMs));

      if (!mounted) return;

      setState(() {
        activeCell = null;
      });

      await Future.delayed(const Duration(milliseconds: 105));

      if (widget.level.decoys > 0 &&
          i < sequence.length - 1 &&
          random.nextDouble() < 0.36) {
        await _showDecoy();
      }
    }

    if (!mounted) return;

    expected = _reverseThisRound
        ? sequence.reversed.toList()
        : List<int>.from(sequence);

    setState(() {
      showingSequence = false;
      locked = false;
      headline = _reverseThisRound ? 'TERSTEN TEKRARLA' : 'TEKRARLA';
      subline = 'Sıra sende • ${expected.length} dokunuş';
    });

    _audio.hapticSelection();
  }

  void _generateSequence() {
    random = _replayability.randomFor(
      sessionSeed: sessionSeed,
      round: round,
      salt: 31,
    );

    final int cellCount = widget.level.gridSize * widget.level.gridSize;

    final int extra = min(round, widget.level.number >= 7 ? 2 : 1);

    final int length = min(widget.level.sequenceLength + extra, cellCount - 1);

    sequence = [];

    int? previous;

    while (sequence.length < length) {
      final int candidate =
          previous != null &&
              (widget.level.number == 3 || widget.level.number == 6)
          ? _adjacentCell(previous, random)
          : random.nextInt(cellCount);

      if (candidate == previous) continue;

      sequence.add(candidate);
      previous = candidate;
    }
    if (widget.fixedSessionSeed == null) {
      final List<int> normalized = <int>[...sequence];
      final List<int> reversed = normalized.reversed.toList(growable: false);
      final String forwardKey = normalized.join('-');
      final String reverseKey = reversed.join('-');
      unawaited(
        _replayability.registerFingerprint(
          gameId: 'memory',
          level: widget.level.number,
          fingerprint: forwardKey.compareTo(reverseKey) <= 0
              ? forwardKey
              : reverseKey,
          historyLimit: 150,
        ),
      );
    }
  }

  int _adjacentCell(int cell, Random rng) {
    final int size = widget.level.gridSize;
    final int row = cell ~/ size;
    final int column = cell % size;
    final List<int> options = <int>[
      if (row > 0) cell - size,
      if (row + 1 < size) cell + size,
      if (column > 0) cell - 1,
      if (column + 1 < size) cell + 1,
    ];
    return options[rng.nextInt(options.length)];
  }

  Future<void> _showDecoy() async {
    final int cellCount = widget.level.gridSize * widget.level.gridSize;

    int decoy = random.nextInt(cellCount);

    int guard = 0;
    while (sequence.contains(decoy) && guard < 30) {
      decoy = random.nextInt(cellCount);
      guard++;
    }

    setState(() {
      activeCell = decoy;
    });

    _audio.play(GameSound.memoryDecoy);

    await Future.delayed(
      Duration(milliseconds: max(120, widget.level.previewMs ~/ 2)),
    );

    if (!mounted) return;

    setState(() {
      activeCell = null;
    });

    await Future.delayed(const Duration(milliseconds: 80));
  }

  Future<void> _tapCell(int index) async {
    if (locked ||
        showingSequence ||
        levelFinished ||
        playerInput.length >= expected.length) {
      return;
    }

    final int expectedIndex = playerInput.length;
    final int expectedCell = expected[expectedIndex];

    // Önizlemede hangi hücre hangi notayı çalıyorsa,
    // oyuncu dokunduğunda da aynı nota duyulur.
    _audio.playMemoryNote(index % 8, gain: 0.86);

    if (index == expectedCell) {
      _audio.hapticLight();

      setState(() {
        playerInput.add(index);
        correctCell = index;
        score += 20 + combo * 2;
      });

      await Future.delayed(const Duration(milliseconds: 105));

      if (!mounted) return;

      setState(() {
        correctCell = null;
      });

      if (playerInput.length == expected.length) {
        await _roundSuccess();
      }
    } else {
      await _wrongAnswer(index);
    }
  }

  Future<void> _roundSuccess() async {
    locked = true;
    combo++;
    bestCombo = max(bestCombo, combo);
    round++;

    final int roundBonus = 150 + combo * 35 + widget.level.number * 15;

    score += roundBonus;

    _audio.hapticMedium();

    if (combo >= 3) {
      _audio.play(GameSound.memoryStreak);
    } else {
      _audio.play(GameSound.memoryCorrect);
    }

    await _floating(
      combo >= 3 ? '🔥 COMBO x$combo  +$roundBonus' : '✨ HARİKA!  +$roundBonus',
    );

    if (round >= widget.level.rounds) {
      await _completeLevel();
      return;
    }

    if (!mounted) return;

    setState(() {
      headline = 'DOĞRU!';
      subline = 'Sıradaki yol hazırlanıyor';
    });

    await Future.delayed(const Duration(milliseconds: 420));

    _startRound();
  }

  Future<void> _wrongAnswer(int index) async {
    locked = true;
    combo = 0;
    lives--;

    _audio.hapticHeavy();
    _audio.play(GameSound.memoryWrong);

    setState(() {
      wrongCell = index;
      headline = 'DİKKAT!';
      subline = lives > 0 ? 'Bir can gitti • tekrar dene' : 'Canların tükendi';
    });

    await _floating(lives > 0 ? '💔 -1 CAN' : '⚠ SON HAK');

    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    setState(() {
      wrongCell = null;
    });

    if (lives <= 0) {
      if (widget.competitionMode) {
        await Future<void>.delayed(const Duration(milliseconds: 850));
        if (!mounted) return;
        Navigator.pop(
          context,
          const MemoryLevelResult(
            completed: true,
            stars: 0,
            score: 0,
            nextLevel: false,
          ),
        );
        return;
      }
      _showGameOver();
      return;
    }

    await Future.delayed(const Duration(milliseconds: 400));

    _startRound();
  }

  Future<void> _floating(String text) async {
    if (!mounted) return;

    setState(() {
      floatingText = text;
      showFloating = true;
    });

    await Future.delayed(const Duration(milliseconds: 650));

    if (!mounted) return;

    setState(() {
      showFloating = false;
    });
  }

  int _calculateStars() {
    final int lostLives = widget.level.lives - lives;

    if (lostLives == 0 && bestCombo >= widget.level.rounds) {
      return 3;
    }

    if (lostLives <= 1) {
      return 2;
    }

    return 1;
  }

  Future<void> _completeLevel() async {
    if (levelFinished) return;

    levelFinished = true;
    locked = true;

    final int stars = _calculateStars();
    final int finalScore = score + lives * 100 + bestCombo * 40;

    setState(() {
      confettiSeed++;
      showConfetti = true;
      headline = 'MUHTEŞEM!';
      subline = 'Hafıza parkurunu tamamladın';
    });

    _audio.hapticHeavy();

    _audio.playVictory(stars: stars, boss: widget.level.difficulty == 'BOSS');

    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;

    if (widget.competitionMode) {
      Navigator.pop(
        context,
        MemoryLevelResult(
          completed: true,
          stars: stars,
          score: finalScore,
          nextLevel: false,
        ),
      );
      return;
    }

    showDialog(
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF123D73), Color(0xFF522C83)],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFFFFD93D), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF745CFF).withValues(alpha: 0.32),
                    blurRadius: 30,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.psychology_alt_rounded,
                    size: 66,
                    color: Color(0xFFFFD93D),
                  ),
                  const SizedBox(height: 8),
                  LText(
                    widget.level.difficulty == 'BOSS'
                        ? '👑 HAFIZA BOSS YENİLDİ!'
                        : '🎉 HAFIZA USTASI!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 23,
                    ),
                  ),
                  const SizedBox(height: 11),
                  AdvancedResultBanner(
                    score: finalScore,
                    previousBestScore: widget.previousBestScore,
                    english: context.l10n.isEnglish,
                    accentColor: const Color(0xFFE748CF),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (index) => Icon(
                        index < stars
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: const Color(0xFFFFD93D),
                        size: 48,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _MemoryResultBox(
                          title: 'PUAN',
                          value: '$finalScore',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MemoryResultBox(title: 'CAN', value: '$lives'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MemoryResultBox(
                          title: 'COMBO',
                          value: 'x$bestCombo',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF745CFF),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        Navigator.pop(
                          context,
                          MemoryLevelResult(
                            completed: true,
                            stars: stars,
                            score: finalScore,
                            nextLevel: widget.level.number < widget.totalLevels,
                          ),
                        );
                      },
                      icon: Icon(
                        widget.level.number < widget.totalLevels
                            ? Icons.arrow_forward_rounded
                            : Icons.workspace_premium_rounded,
                      ),
                      label: LText(
                        widget.level.number < widget.totalLevels
                            ? 'SONRAKİ SEVİYE'
                            : 'HAFIZA PARKURUNU TAMAMLA',
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      Navigator.pop(
                        context,
                        MemoryLevelResult(
                          completed: true,
                          stars: stars,
                          score: finalScore,
                          nextLevel: false,
                        ),
                      );
                    },
                    child: const LText('BÖLÜM LİSTESİ'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showGameOver() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: ZpVisualPalette.of(dialogContext).surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          title: const Column(
            children: [
              Icon(
                Icons.favorite_border_rounded,
                color: Color(0xFFFF5E57),
                size: 52,
              ),
              SizedBox(height: 8),
              LText(
                'CANLAR TÜKENDİ',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          content: LText(
            'Puan: $score\n'
            'Tamamlanan tur: $round / ${widget.level.rounds}\n\n'
            'Yeni bir diziyle tekrar deneyebilirsin.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                _restartLevel();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const LText('TEKRAR OYNA'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(context);
              },
              child: const LText('BÖLÜMLER'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _restartLevel() async {
    sessionSeed =
        widget.fixedSessionSeed ??
        await _replayability.newSeed(
          gameId: 'memory',
          level: widget.level.number,
        );

    random = _replayability.randomFor(
      sessionSeed: sessionSeed,
      round: 0,
      salt: widget.fixedSessionSeed == null ? 17 : 11,
    );

    if (!mounted) return;

    setState(() {
      lives = widget.level.lives;
      score = 0;
      round = 0;
      combo = 0;
      bestCombo = 0;
      levelFinished = false;
      showConfetti = false;
      playerInput.clear();
    });

    _startRound();
  }

  @override
  Widget build(BuildContext context) {
    final double progress = (round / widget.level.rounds).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFF06152B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LText(
              widget.level.title.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
            ),
            LText(
              'Seviye ${widget.level.number} / ${widget.totalLevels}',
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Yeniden başlat',
            onPressed: _restartLevel,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _MemoryBackgroundPainter()),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
              child: Column(
                children: [
                  _MemoryGameHeader(
                    score: score,
                    round: round,
                    totalRounds: widget.level.rounds,
                    lives: lives,
                    combo: combo,
                  ),
                  const SizedBox(height: 9),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF52E86B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: Column(
                      key: ValueKey('$headline-$subline'),
                      children: [
                        LText(
                          headline,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 23,
                            letterSpacing: 1.2,
                            color: showingSequence
                                ? const Color(0xFF00D9FF)
                                : const Color(0xFFFFD93D),
                          ),
                        ),
                        const SizedBox(height: 3),
                        LText(
                          subline,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _buildGrid(),
                        IgnorePointer(
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 130),
                            opacity: showFloating ? 1 : 0,
                            child: TweenAnimationBuilder<double>(
                              key: ValueKey(floatingText),
                              tween: Tween<double>(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, -62 * value),
                                  child: Transform.scale(
                                    scale: 0.78 + min(value * 1.7, 1.0) * 0.30,
                                    child: child,
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .scaffoldBackgroundColor
                                      .withValues(alpha: 0.94),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: const Color(0xFFFFD93D),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFFD93D)
                                          .withValues(alpha: 0.24),
                                      blurRadius: 18,
                                    ),
                                  ],
                                ),
                                child: LText(
                                  floatingText,
                                  style: const TextStyle(
                                    color: Color(0xFFFFD93D),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _MemoryInputProgress(
                    current: playerInput.length,
                    total: expected.isEmpty
                        ? widget.level.sequenceLength
                        : expected.length,
                    active: !locked && !showingSequence,
                  ),
                  const SizedBox(height: 8),
                  LText(
                    _reverseThisRound
                        ? '↩ Bu bölümde diziyi tersten hatırla'
                        : widget.level.decoys > 0
                        ? '⚠ Bazı kısa flaşlar dikkat dağıtıcıdır'
                        : '🧠 Işıkların sırasını zihninde tut',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
          if (showConfetti)
            Positioned.fill(
              child: IgnorePointer(
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(confettiSeed),
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1500),
                  builder: (context, value, child) {
                    return CustomPaint(
                      painter: _MemoryConfettiPainter(
                        progress: value,
                        seed: confettiSeed,
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxSize = min(constraints.maxWidth, constraints.maxHeight);

        return Center(
          child: SizedBox(
            width: maxSize,
            height: maxSize,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.level.gridSize * widget.level.gridSize,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: widget.level.gridSize,
                crossAxisSpacing: 7,
                mainAxisSpacing: 7,
              ),
              itemBuilder: (context, index) {
                final bool active = activeCell == index;
                final bool wrong = wrongCell == index;
                final bool correct = correctCell == index;

                final Color color = neonColors[index % neonColors.length];

                return _MemoryCell(
                  index: index,
                  color: color,
                  active: active,
                  wrong: wrong,
                  correct: correct,
                  enabled: !locked && !showingSequence,
                  onTap: () => _tapCell(index),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _MemoryCell extends StatelessWidget {
  final int index;
  final Color color;
  final bool active;
  final bool wrong;
  final bool correct;
  final bool enabled;
  final VoidCallback onTap;

  const _MemoryCell({
    required this.index,
    required this.color,
    required this.active,
    required this.wrong,
    required this.correct,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = Colors.white10;
    Color fillColor = const Color(0xFF102949);

    if (active) {
      borderColor = color;
      fillColor = color;
    }

    if (correct) {
      borderColor = const Color(0xFF76FF03);
      fillColor = const Color(0xFF52E86B);
    }

    if (wrong) {
      borderColor = const Color(0xFFFF5E57);
      fillColor = const Color(0xFFFF5E57);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 125),
        curve: Curves.easeOutBack,
        scale: active
            ? 1.08
            : correct
            ? 1.05
            : wrong
            ? 0.92
            : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 135),
          decoration: BoxDecoration(
            gradient: active || correct || wrong
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(fillColor, Colors.white, 0.32) ?? fillColor,
                      fillColor,
                      Color.lerp(fillColor, Colors.black, 0.18) ?? fillColor,
                    ],
                  )
                : const LinearGradient(
                    colors: [Color(0xFF132F52), Color(0xFF0E2341)],
                  ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: active || correct || wrong ? 2.2 : 1,
            ),
            boxShadow: active || correct || wrong
                ? [
                    BoxShadow(
                      color: borderColor.withValues(alpha: 0.46),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ]
                : [
                    const BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 120),
              child: wrong
                  ? const Icon(
                      Icons.close_rounded,
                      key: ValueKey('wrong'),
                      color: Colors.white,
                      size: 30,
                    )
                  : correct
                  ? const Icon(
                      Icons.check_rounded,
                      key: ValueKey('correct'),
                      color: Colors.white,
                      size: 29,
                    )
                  : active
                  ? Icon(
                      Icons.auto_awesome_rounded,
                      key: const ValueKey('active'),
                      color: Colors.white.withValues(alpha: 0.90),
                      size: 28,
                    )
                  : Container(
                      key: const ValueKey('idle'),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        shape: BoxShape.circle,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MemoryGameHeader extends StatelessWidget {
  final int score;
  final int round;
  final int totalRounds;
  final int lives;
  final int combo;

  const _MemoryGameHeader({
    required this.score,
    required this.round,
    required this.totalRounds,
    required this.lives,
    required this.combo,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MemoryTopStat(
            title: 'PUAN',
            value: '$score',
            color: const Color(0xFFFFD93D),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _MemoryTopStat(
            title: 'TUR',
            value: '$round/$totalRounds',
            color: const Color(0xFF00D9FF),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _MemoryTopStat(
            title: 'CAN',
            value: '♥ $lives',
            color: const Color(0xFFFF5E57),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _MemoryTopStat(
            title: 'COMBO',
            value: 'x$combo',
            color: const Color(0xFF52E86B),
          ),
        ),
      ],
    );
  }
}

class _MemoryTopStat extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _MemoryTopStat({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: ZpVisualPalette.of(context).surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          LText(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          LText(
            title,
            style: const TextStyle(color: Colors.white38, fontSize: 7),
          ),
        ],
      ),
    );
  }
}

class _MemoryInputProgress extends StatelessWidget {
  final int current;
  final int total;
  final bool active;

  const _MemoryInputProgress({
    required this.current,
    required this.total,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final int safeTotal = max(1, total);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(safeTotal, (index) {
        final bool done = index < current;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: done ? 15 : 9,
          height: 9,
          decoration: BoxDecoration(
            color: done
                ? const Color(0xFF52E86B)
                : active
                ? const Color(0xFF00D9FF).withValues(alpha: 0.30)
                : Colors.white12,
            borderRadius: BorderRadius.circular(20),
            boxShadow: done
                ? [
                    BoxShadow(
                      color: const Color(0xFF52E86B).withValues(alpha: 0.35),
                      blurRadius: 6,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

class _MemoryProgressPanel extends StatelessWidget {
  final int totalScore;
  final int totalStars;
  final int unlockedLevel;

  const _MemoryProgressPanel({
    required this.totalScore,
    required this.totalStars,
    required this.unlockedLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6D2C91), Color(0xFF173E9A)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE748CF).withValues(alpha: 0.16),
            blurRadius: 24,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF4F9A), Color(0xFF745CFF)],
              ),
              borderRadius: BorderRadius.circular(19),
            ),
            child: const Icon(Icons.psychology_alt_rounded, size: 36),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LText(
                  'HAFIZA USTALIĞI',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                ),
                const SizedBox(height: 4),
                LText(
                  'Seviye $unlockedLevel / 10   •   ⭐ $totalStars / 30',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              LText(
                '$totalScore',
                style: const TextStyle(
                  color: Color(0xFFFFD93D),
                  fontWeight: FontWeight.w900,
                  fontSize: 21,
                ),
              ),
              const LText(
                'PUAN',
                style: TextStyle(color: Colors.white54, fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MemoryLevelCard extends StatelessWidget {
  final MemoryLevel level;
  final bool unlocked;
  final int stars;
  final int bestScore;
  final VoidCallback onTap;

  const _MemoryLevelCard({
    required this.level,
    required this.unlocked,
    required this.stars,
    required this.bestScore,
    required this.onTap,
  });

  Color get color {
    switch (level.difficulty) {
      case 'KOLAY':
        return const Color(0xFF52E86B);
      case 'ORTA':
        return const Color(0xFFFF9F1C);
      case 'ZOR':
        return const Color(0xFFFF5E57);
      case 'BOSS':
        return const Color(0xFFFF4F9A);
      default:
        return const Color(0xFF00D9FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: unlocked ? onTap : null,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            gradient: unlocked
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF122B50), Color(0xFF102340)],
                  )
                : const LinearGradient(
                    colors: [Color(0xFF0B1A31), Color(0xFF091526)],
                  ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: unlocked ? color.withValues(alpha: 0.60) : Colors.white12,
            ),
            boxShadow: unlocked
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.07),
                      blurRadius: 14,
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: unlocked ? color : Colors.white12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: unlocked
                        ? LText(
                            '${level.number}',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          )
                        : const Icon(
                            Icons.lock_rounded,
                            size: 18,
                            color: Colors.white30,
                          ),
                  ),
                  const Spacer(),
                  if (unlocked)
                    LText(
                      level.difficulty,
                      style: TextStyle(
                        color: color,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Icon(
                level.difficulty == 'BOSS'
                    ? Icons.psychology_alt_rounded
                    : level.isShapeMatch
                    ? Icons.style_rounded
                    : level.reverseRecall
                    ? Icons.u_turn_left_rounded
                    : level.decoys > 0
                    ? Icons.flash_on_rounded
                    : Icons.auto_awesome_rounded,
                color: unlocked ? color : Colors.white12,
                size: 34,
              ),
              const SizedBox(height: 5),
              Text(
                level.localizedTitle(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: unlocked ? Colors.white : Colors.white24,
                ),
              ),
              Text(
                level.localizedSubtitle(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white38, fontSize: 8),
              ),
              const Spacer(),
              if (bestScore > 0)
                LText(
                  'En iyi: $bestScore',
                  style: const TextStyle(color: Colors.white54, fontSize: 9),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (index) => Icon(
                    index < stars
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: unlocked ? const Color(0xFFFFD93D) : Colors.white12,
                    size: 18,
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

class _MemoryResultBox extends StatelessWidget {
  final String title;
  final String value;

  const _MemoryResultBox({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          LText(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
          ),
          LText(
            title,
            style: const TextStyle(color: Colors.white54, fontSize: 8),
          ),
        ],
      ),
    );
  }
}

class _MemoryBackgroundPainter extends CustomPainter {
  const _MemoryBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint glow = Paint()
      ..shader =
          const RadialGradient(colors: [Color(0x28745CFF), Color(0x00000000)])
              .createShader(
                Rect.fromCircle(
                  center: Offset(size.width * 0.18, size.height * 0.20),
                  radius: size.width * 0.65,
                ),
              );

    canvas.drawRect(Offset.zero & size, glow);

    final Paint glow2 = Paint()
      ..shader =
          const RadialGradient(colors: [Color(0x1A00D9FF), Color(0x00000000)])
              .createShader(
                Rect.fromCircle(
                  center: Offset(size.width * 0.85, size.height * 0.70),
                  radius: size.width * 0.55,
                ),
              );

    canvas.drawRect(Offset.zero & size, glow2);

    final Random random = Random(42);
    final Paint starPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12);

    for (int i = 0; i < 48; i++) {
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        random.nextDouble() * 1.4 + 0.3,
        starPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MemoryBackgroundPainter oldDelegate) {
    return false;
  }
}

class _MemoryConfettiPainter extends CustomPainter {
  final double progress;
  final int seed;

  const _MemoryConfettiPainter({required this.progress, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final Random random = Random(seed);

    const List<Color> colors = [
      Color(0xFF00D9FF),
      Color(0xFF745CFF),
      Color(0xFFFF4F9A),
      Color(0xFFFF9F1C),
      Color(0xFFFFD93D),
      Color(0xFF52E86B),
      Color(0xFFFF5E57),
    ];

    for (int i = 0; i < 80; i++) {
      final double startX = random.nextDouble() * size.width;

      final double delay = random.nextDouble() * 0.28;

      final double local = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);

      final double y =
          -30 + local * (size.height + 80) + sin(local * pi * 4 + i) * 12;

      final double x = startX + sin(local * pi * 2 + i) * 24;

      final Paint paint = Paint()
        ..color = colors[i % colors.length].withValues(
          alpha: (1 - local * 0.35).clamp(0.0, 1.0),
        );

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(local * 8 + i);

      if (i.isEven) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-4, -8, 8, 16),
            const Radius.circular(3),
          ),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, 5, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _MemoryConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.seed != seed;
  }
}

class MemoryLevel {
  final int number;
  final String title;
  final String? titleEn;
  final String subtitle;
  final String? subtitleEn;
  final String difficulty;

  final int gridSize;
  final int sequenceLength;
  final int previewMs;
  final int rounds;
  final int lives;

  final bool reverseRecall;
  final int decoys;
  final int matchCardCount;

  const MemoryLevel({
    required this.number,
    required this.title,
    this.titleEn,
    required this.subtitle,
    this.subtitleEn,
    required this.difficulty,
    required this.gridSize,
    required this.sequenceLength,
    required this.previewMs,
    required this.rounds,
    required this.lives,
    this.reverseRecall = false,
    this.decoys = 0,
    this.matchCardCount = 0,
  });

  bool get isShapeMatch => matchCardCount == 8 || matchCardCount == 16;

  String localizedTitle(BuildContext context) {
    if (context.l10n.isEnglish && titleEn != null) return titleEn!;
    return context.l10n.gameUi(title);
  }

  String localizedSubtitle(BuildContext context) {
    if (context.l10n.isEnglish && subtitleEn != null) return subtitleEn!;
    return context.l10n.gameUi(subtitle);
  }
}

class MemoryLevelResult {
  final bool completed;
  final int stars;
  final int score;
  final bool nextLevel;

  const MemoryLevelResult({
    required this.completed,
    required this.stars,
    required this.score,
    required this.nextLevel,
  });
}
