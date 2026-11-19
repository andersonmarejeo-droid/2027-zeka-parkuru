import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../widgets/studio_chapter_card.dart';

import '../../l10n/app_localizations.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../services/replayability_service.dart';
import '../../services/daily_challenge_service.dart';
import '../../services/daily_course_service.dart';
import '../../services/game_audio_service.dart';
import '../../services/common_level_score_service.dart';
import '../../theme/app_visual_theme.dart';
import '../../theme/studio_visuals.dart';
import '../shared/studio_game_contracts.dart';

class ReflexGamePage extends StatefulWidget {
  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  const ReflexGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  @override
  State<ReflexGamePage> createState() => _ReflexGamePageState();
}

class _ReflexGamePageState extends State<ReflexGamePage> {
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  bool loading = true;
  int unlockedLevel = 1;

  List<int> stars = List<int>.filled(GameContentPolicy.campaignLevels, 0);
  List<int> bestScores = List<int>.filled(GameContentPolicy.campaignLevels, 0);
  bool _competitionOpened = false;

  final List<ReflexLevel> _nativeLevels = const [
    ReflexLevel(
      number: 1,
      title: 'Yeşil Işık',
      subtitle: 'Yeşil olunca dokun',
      difficulty: 'KOLAY',
      mode: ReflexMode.reaction,
      rounds: 6,
      lives: 3,
      timeLimitMs: 1200,
      targetMs: 520,
    ),
    ReflexLevel(
      number: 2,
      title: 'Hedef Avı',
      subtitle: 'Beliren hedefe en hızlı dokun',
      difficulty: 'KOLAY',
      mode: ReflexMode.targets,
      rounds: 8,
      lives: 3,
      timeLimitMs: 1050,
      targetMs: 490,
    ),
    ReflexLevel(
      number: 3,
      title: 'Düşen Hedef',
      subtitle: 'Yukarıdan akan hedefi yakala',
      difficulty: 'ORTA',
      mode: ReflexMode.falling,
      rounds: 9,
      lives: 3,
      timeLimitMs: 1250,
      targetMs: 520,
    ),
    ReflexLevel(
      number: 4,
      title: 'Hızlı Akış',
      subtitle: 'Hedef daha hızlı düşüyor',
      difficulty: 'ZOR',
      mode: ReflexMode.falling,
      rounds: 10,
      lives: 3,
      timeLimitMs: 850,
      targetMs: 430,
      distractors: 2,
    ),
    ReflexLevel(
      number: 5,
      title: 'Maymun Çık!',
      subtitle: 'Delikten çıkan maymuna vur',
      difficulty: 'ORTA',
      mode: ReflexMode.whack,
      rounds: 11,
      lives: 3,
      timeLimitMs: 900,
      targetMs: 440,
    ),
    ReflexLevel(
      number: 6,
      title: 'Maymun Kaosu',
      subtitle: 'Maymuna vur, bombaya dokunma',
      difficulty: 'ZOR',
      mode: ReflexMode.whack,
      rounds: 12,
      lives: 4,
      timeLimitMs: 760,
      targetMs: 390,
      distractors: 3,
    ),
    ReflexLevel(
      number: 7,
      title: 'Renk Komutu',
      subtitle: 'Sadece istenen renge dokun',
      difficulty: 'ORTA',
      mode: ReflexMode.colorChoice,
      rounds: 12,
      lives: 3,
      timeLimitMs: 720,
      targetMs: 380,
      distractors: 3,
    ),
    ReflexLevel(
      number: 8,
      title: 'Kaçan Hedef',
      subtitle: 'Hareketli hedefi yakala',
      difficulty: 'ZOR',
      mode: ReflexMode.moving,
      rounds: 13,
      lives: 3,
      timeLimitMs: 680,
      targetMs: 360,
    ),
    ReflexLevel(
      number: 9,
      title: 'Çift Karar',
      subtitle: 'Renk + şekil kuralını uygula',
      difficulty: 'ZOR',
      mode: ReflexMode.dualRule,
      rounds: 14,
      lives: 3,
      timeLimitMs: 620,
      targetMs: 340,
      distractors: 5,
    ),
    ReflexLevel(
      number: 10,
      title: 'Refleks Boss',
      subtitle: 'Tüm refleks oyunları karışık',
      difficulty: 'BOSS',
      mode: ReflexMode.boss,
      rounds: 16,
      lives: 3,
      timeLimitMs: 580,
      targetMs: 320,
      distractors: 6,
    ),
  ];

  final ScrollController _scrollController = ScrollController();
  late List<ReflexLevel> levels;

  List<ReflexLevel> _generateLevels(int targetLevel) {
    final int count = targetLevel >= 26
        ? max(GameContentPolicy.campaignLevels, targetLevel + 5)
        : GameContentPolicy.campaignLevels;
    return List.generate(
      count,
      (index) {
        final chapter = index + 1;
        final base = _nativeLevels[GameContentPolicy.nativeLevel(chapter) - 1];
        final int extraChapters = max(0, chapter - GameContentPolicy.campaignLevels);
        final int extraTier = extraChapters == 0 ? 0 : (extraChapters - 1) ~/ 4 + 1;
        return ReflexLevel(
          number: chapter,
          sourceNumber: base.number,
          difficulty: GameContentPolicy.difficulty(chapter),
          title: extraChapters > 0
              ? '${base.title} • Faz $extraChapters'
              : base.title,
          subtitle: extraChapters > 0
              ? 'Usta Kademesi: ${base.subtitle}'
              : base.subtitle,
          mode: base.mode,
          rounds: min(22, base.rounds + extraTier),
          lives: base.lives,
          timeLimitMs: max(450, base.timeLimitMs - min(90, extraTier * 15)),
          targetMs: max(270, base.targetMs - min(40, extraTier * 8)),
          distractors: min(8, base.distractors + (extraTier ~/ 2)),
        );
      },
      growable: false,
    );
  }

  @override
  void initState() {
    super.initState();
    levels = _generateLevels(1);
    _loadProgress();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    final int savedLevel = await _prefs.getInt('reflex_unlocked_level') ?? 1;

    final List<String>? savedStars = await _prefs.getStringList('reflex_stars');

    final List<String>? savedScores = await _prefs.getStringList(
      'reflex_best_scores',
    );

    if (!mounted) return;

    final int star30 = savedStars != null &&
            savedStars.length >= GameContentPolicy.campaignLevels
        ? (int.tryParse(savedStars[GameContentPolicy.campaignLevels - 1]) ?? 0)
        : 0;
    final int targetLength = star30 > 0
        ? [
            GameContentPolicy.campaignLevels,
            savedLevel,
            savedStars?.length ?? 0,
            savedScores?.length ?? 0,
          ].reduce((a, b) => a > b ? a : b)
        : GameContentPolicy.campaignLevels;
    final List<int> decodedStars = _decodeList(savedStars, targetLength);
    final int effectiveUnlocked = GameContentPolicy.safeUnlocked(
      savedLevel,
      decodedStars,
    );
    final nextLevels = _generateLevels(effectiveUnlocked);

    setState(() {
      unlockedLevel = effectiveUnlocked;
      levels = nextLevels;
      stars = _decodeList(savedStars, nextLevels.length);
      bestScores = _decodeList(savedScores, nextLevels.length);
      loading = false;
    });

    _openCompetitionLevelIfNeeded();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      if (unlockedLevel > 2) {
        final double targetOffset = (unlockedLevel - 2) * 110.0;
        _scrollController.animateTo(
          targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
      }
    });
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

  List<int> _decodeList(List<String>? source, int targetCount) {
    return List<int>.generate(targetCount, (index) {
      if (source == null || index >= source.length) return 0;
      return int.tryParse(source[index]) ?? 0;
    });
  }

  Future<void> _saveProgress() async {
    await _prefs.setInt('reflex_unlocked_level', unlockedLevel);

    await _prefs.setStringList('reflex_stars', stars.map((e) => '$e').toList());

    await _prefs.setStringList(
      'reflex_best_scores',
      bestScores.map((e) => '$e').toList(),
    );
  }

  int get totalStars => stars.fold(0, (a, b) => a + b);
  int get totalScore => bestScores.fold(0, (a, b) => a + b);

  Future<void> _openLevel(int index) async {
    if (widget.competitionLevel == null && index + 1 > unlockedLevel) {
      return;
    }

    GameAudioService.instance.play(GameSound.uiClick);

    final List<int> previousStars = List<int>.from(stars);
    final CommonLevelScoreSession scoring = CommonLevelScoreSession.begin();
    final ReflexLevelResult? result;
    try {
      result = await Navigator.push<ReflexLevelResult>(
        context,
        MaterialPageRoute(
          builder: (_) => ReflexPlayPage(
            level: levels[index],
            totalLevels: levels.length,
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
            ? const DailyStageResult.exited(gameId: 'reflex')
            : result.completed
            ? DailyStageResult.completed(
                gameId: 'reflex',
                stars: result.stars,
                rawScore: commonPoints,
              )
            : const DailyStageResult.failed(gameId: 'reflex'),
      );
      return;
    }

    if (result == null || !result.completed) {
      if (widget.competitionLevel != null && mounted) {
        Navigator.pop(context);
      }
      return;
    }
    final ReflexLevelResult completedResult = result;

    if (widget.competitionLevel != null) {
      Navigator.pop(
        context,
        DailyCourseGameResult(
          gameId: 'reflex',
          stars: completedResult.stars,
          score: commonPoints,
        ),
      );
      return;
    }

    setState(() {
      stars[index] = max(stars[index], completedResult.stars);
      bestScores[index] = max(bestScores[index], completedResult.score);

      if (index + 1 == unlockedLevel) {
        unlockedLevel++;
        if (unlockedLevel + 3 >= levels.length) {
          levels = _generateLevels(unlockedLevel);
          stars = List<int>.generate(
            levels.length,
            (i) => i < stars.length ? stars[i] : 0,
          );
          bestScores = List<int>.generate(
            levels.length,
            (i) => i < bestScores.length ? bestScores[i] : 0,
          );
        }
      }
    });

    await _saveProgress();
    await CommonLevelScoreStore.recordBest(
      gameId: 'reflex',
      levelIndex: index,
      points: commonPoints,
      levelCount: levels.length,
      completedStars: previousStars,
    );

    await DailyChallengeService.instance.recordLevelCompleted(
      gameId: 'reflex',
      stars: completedResult.stars,
      score: commonPoints,
    );

    if (completedResult.nextLevel && mounted) {
      await Future.delayed(const Duration(milliseconds: 180));

      if (mounted) {
        if (index + 1 >= levels.length) {
          setState(() {
            levels = _generateLevels(index + 2);
            stars = List<int>.generate(
              levels.length,
              (i) => i < stars.length ? stars[i] : 0,
            );
            bestScores = List<int>.generate(
              levels.length,
              (i) => i < bestScores.length ? bestScores[i] : 0,
            );
          });
        }
        _openLevel(index + 1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading || widget.competitionLevel != null) {
      return Scaffold(
        backgroundColor: StudioVisuals.canvas,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LText(
              'REFLEKS ARENASI',
              style: TextStyle(
                fontFamily: 'Roboto',
                color: StudioVisuals.ink,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            LText(
              'Gör • Karar Ver • Dokun',
              style: TextStyle(
                fontFamily: 'Roboto',
                color: StudioVisuals.muted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveGameFrame(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints limits) {
              final bool compact = limits.maxWidth < 360;
              final bool isLandscape = limits.maxWidth > limits.maxHeight;

              return CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
                          child: _ReflexProgressPanel(
                            totalScore: totalScore,
                            totalStars: totalStars,
                            unlockedLevel: unlockedLevel,
                            levelCount: levels.length,
                          ),
                        ),
                        if (unlockedLevel <= levels.length)
                          _ReflexQuickResumeCard(
                            levelNumber: unlockedLevel,
                            levelTitle: levels[unlockedLevel - 1].title,
                            difficulty: levels[unlockedLevel - 1].difficulty,
                            onPlay: () => _openLevel(unlockedLevel - 1),
                          ),
                      ],
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isLandscape ? 2 : 1,
                        crossAxisSpacing: compact ? 10 : 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent:
                            104 *
                            MediaQuery.textScalerOf(context)
                                .scale(1)
                                .clamp(1.0, 1.6),
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return _ReflexLevelCard(
                            level: levels[index],
                            unlocked: index + 1 <= unlockedLevel,
                            stars: stars[index],
                            bestScore: bestScores[index],
                            onTap: () => _openLevel(index),
                          );
                        },
                        childCount: levels.length,
                      ),
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

class ReflexPlayPage extends StatefulWidget {
  final ReflexLevel level;
  final int totalLevels;
  final int? fixedSessionSeed;
  final bool competitionMode;

  const ReflexPlayPage({
    super.key,
    required this.level,
    required this.totalLevels,
    this.fixedSessionSeed,
    this.competitionMode = false,
  });

  @override
  State<ReflexPlayPage> createState() => _ReflexPlayPageState();
}

class _ReflexPlayPageState extends State<ReflexPlayPage>
    with TickerProviderStateMixin {
  static const int _competitionLives = 3;
  late Random random;
  final ReplayabilityService _replayability = ReplayabilityService();
  final GameAudioService _audio = GameAudioService.instance;

  int sessionSeed = 0;

  late int lives;

  int round = 0;
  int score = 0;
  int combo = 0;
  int bestCombo = 0;

  int bestReaction = 9999;
  int totalReaction = 0;
  int successfulHits = 0;

  bool locked = true;
  bool waiting = false;
  bool targetVisible = false;
  bool isGoTarget = true;
  bool levelFinished = false;
  bool _mistakeInProgress = false;
  bool _competitionResultDelivered = false;

  ReflexMode currentMode = ReflexMode.reaction;

  Stopwatch? _reactionClock;
  List<ReflexMode> _bossSchedule = <ReflexMode>[];

  Alignment targetAlignment = Alignment.center;
  Alignment previousAlignment = Alignment.center;

  Color targetColor = const Color(0xFF34715D);
  Color requestedColor = const Color(0xFF34715D);

  ReflexShape targetShape = ReflexShape.circle;
  ReflexShape requestedShape = ReflexShape.circle;

  Timer? timeoutTimer;
  Timer? warningTimer;

  // Gecikmiş tur işlemlerinin yeni bir turun üzerine binmesini engeller.
  int _roundGeneration = 0;

  String headline = 'HAZIRLAN';
  String subline = 'Refleks testin başlıyor';

  String floatingText = '';
  bool showFloating = false;

  int burstSeed = 0;
  bool showBurst = false;
  bool showFlash = false;
  bool showConfetti = false;

  final List<Color> colors = const [
    Color(0xFF3D7183),
    Color(0xFF665AA2),
    Color(0xFFFF4F9A),
    Color(0xFFFF9F1C),
    Color(0xFF8B622C),
    Color(0xFF34715D),
    Color(0xFFA84640),
  ];

  int get _initialLives =>
      widget.competitionMode ? _competitionLives : widget.level.lives;

  @override
  void initState() {
    super.initState();
    lives = _initialLives;

    _audio.preload(GameAudioGroup.reflex);
    _audio.playMusic(GameMusic.action);

    if (widget.level.contentLevel == 10) {
      _audio.play(GameSound.bossIntro);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeSession());
  }

  @override
  void dispose() {
    timeoutTimer?.cancel();
    warningTimer?.cancel();
    _audio.stopMusic();
    super.dispose();
  }

  Future<void> _initializeSession() async {
    sessionSeed =
        widget.fixedSessionSeed ??
        await _replayability.newSeed(
          gameId: 'reflex',
          level: widget.level.number,
        );

    random = _replayability.randomFor(
      sessionSeed: sessionSeed,
      round: 0,
      salt: 43,
    );

    _bossSchedule = _buildBossSchedule();
    if (widget.fixedSessionSeed == null) {
      await _replayability.registerFingerprint(
        gameId: 'reflex',
        level: widget.level.number,
        fingerprint: _bossSchedule
            .map((ReflexMode mode) => mode.index)
            .join('-'),
        historyLimit: 150,
      );
    }

    if (!mounted) return;

    _nextRound();
  }

  Future<void> _nextRound() async {
    if (!mounted ||
        levelFinished ||
        _mistakeInProgress ||
        _competitionResultDelivered) {
      return;
    }

    final int generation = ++_roundGeneration;

    random = _replayability.randomFor(
      sessionSeed: sessionSeed,
      round: round,
      salt: 59,
    );

    timeoutTimer?.cancel();
    warningTimer?.cancel();

    setState(() {
      locked = true;
      waiting = true;
      targetVisible = false;
      headline = 'HAZIR';
      subline = _instructionText();
    });

    // Düşen hedef bölümlerinde ritmi özellikle canlı tut. Diğer modlarda
    // erken dokunmayı ölçebilmek için bekleme hâlâ öngörülemez kalır.
    final bool fastFallingFlow = widget.level.mode == ReflexMode.falling;
    final int waitMs = fastFallingFlow
        ? widget.level.contentLevel >= 4
              ? 160 + random.nextInt(280)
              : 240 + random.nextInt(340)
        : 600 + random.nextInt(800);

    await Future.delayed(Duration(milliseconds: waitMs));

    if (!mounted || levelFinished || generation != _roundGeneration) {
      return;
    }

    _prepareTarget();

    setState(() {
      locked = false;
      waiting = false;
      targetVisible = true;
      headline = 'ŞİMDİ!';
      subline = _actionText();
      _reactionClock = Stopwatch()..start();
    });

    _audio.play(GameSound.reflexSpawn);
    _audio.hapticSelection();

    if (currentMode == ReflexMode.falling) {
      // İlk frame'de tepeden başlasın, hemen ardından aşağı doğru aksın.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !targetVisible || locked) return;

        setState(() {
          targetAlignment = Alignment(targetAlignment.x, 0.80);
        });
      });
    }

    if (isGoTarget) {
      final int warningMs = max(120, (widget.level.timeLimitMs * 0.68).round());

      warningTimer = Timer(Duration(milliseconds: warningMs), () {
        if (mounted && targetVisible && !locked && !levelFinished) {
          _audio.play(GameSound.reflexTimeWarning);
        }
      });
    }

    timeoutTimer = Timer(
      Duration(milliseconds: widget.level.timeLimitMs),
      _timeOut,
    );
  }

  List<ReflexMode> get _bossModePool => const [
    ReflexMode.reaction,
    ReflexMode.targets,
    ReflexMode.falling,
    ReflexMode.whack,
    ReflexMode.colorChoice,
    ReflexMode.moving,
    ReflexMode.dualRule,
    ReflexMode.noGo,
  ];

  List<ReflexMode> _buildBossSchedule() {
    if (widget.level.mode != ReflexMode.boss) {
      return List<ReflexMode>.filled(widget.level.rounds, widget.level.mode);
    }
    final Random scheduleRandom = _replayability.randomFor(
      sessionSeed: sessionSeed,
      round: 0,
      salt: 83,
    );
    final List<ReflexMode> schedule = <ReflexMode>[
      for (int index = 0; index < widget.level.rounds; index++)
        _bossModePool[index % _bossModePool.length],
    ]..shuffle(scheduleRandom);
    for (int index = 1; index < schedule.length; index++) {
      if (schedule[index] != schedule[index - 1]) continue;
      final int swapIndex = schedule.indexWhere(
        (ReflexMode mode) =>
            mode != schedule[index] &&
            (index + 1 >= schedule.length || mode != schedule[index + 1]),
        index + 1,
      );
      if (swapIndex > index) {
        final ReflexMode current = schedule[index];
        schedule[index] = schedule[swapIndex];
        schedule[swapIndex] = current;
      }
    }
    return schedule;
  }

  void _prepareTarget() {
    currentMode = widget.level.mode == ReflexMode.boss
        ? _bossSchedule[round.clamp(0, _bossSchedule.length - 1).toInt()]
        : widget.level.mode;

    final ReflexMode mode = currentMode;

    final Color goodColor = colors[random.nextInt(colors.length)];

    requestedColor = goodColor;
    targetColor = goodColor;

    targetShape = ReflexShape.values[random.nextInt(ReflexShape.values.length)];
    requestedShape = targetShape;

    isGoTarget = true;

    if (mode == ReflexMode.reaction) {
      targetAlignment = Alignment.center;
      targetColor = const Color(0xFF34715D);
      requestedColor = targetColor;
      targetShape = ReflexShape.circle;
      requestedShape = targetShape;
    }

    if (mode == ReflexMode.targets || mode == ReflexMode.moving) {
      targetAlignment = _randomAlignment();
    }

    if (mode == ReflexMode.falling) {
      final double x = -0.78 + random.nextDouble() * 1.56;
      targetAlignment = Alignment(x, -0.88);
      targetShape = ReflexShape.circle;
      requestedShape = targetShape;
      targetColor = colors[random.nextInt(colors.length)];
      requestedColor = targetColor;
      isGoTarget = true;
    }

    if (mode == ReflexMode.whack) {
      final List<Alignment> holes = const [
        Alignment(-0.68, -0.48),
        Alignment(0.0, -0.48),
        Alignment(0.68, -0.48),
        Alignment(-0.68, 0.48),
        Alignment(0.0, 0.48),
        Alignment(0.68, 0.48),
      ];

      targetAlignment = holes[random.nextInt(holes.length)];
      targetShape = ReflexShape.circle;
      requestedShape = targetShape;

      // 6. seviyede ve Boss'ta zaman zaman bomba/tuzak çıkar.
      final bool allowTrap =
          widget.level.contentLevel >= 6 ||
          widget.level.mode == ReflexMode.boss;

      isGoTarget = !allowTrap || random.nextDouble() > 0.24;

      targetColor = isGoTarget
          ? const Color(0xFFFFB84D)
          : const Color(0xFFA84640);

      requestedColor = targetColor;
    }

    if (mode == ReflexMode.colorChoice) {
      targetAlignment = _randomAlignment();

      if (random.nextDouble() < 0.35) {
        targetColor = colors
            .where((c) => c != requestedColor)
            .toList()[random.nextInt(colors.length - 1)];
        isGoTarget = false;
      }
    }

    if (mode == ReflexMode.noGo) {
      targetAlignment = _randomAlignment();
      isGoTarget = random.nextDouble() > 0.28;
      targetColor = isGoTarget
          ? const Color(0xFF34715D)
          : const Color(0xFFA84640);
    }

    if (mode == ReflexMode.dualRule) {
      targetAlignment = _randomAlignment();

      if (random.nextDouble() < 0.38) {
        if (random.nextBool()) {
          targetColor = colors
              .where((c) => c != requestedColor)
              .toList()[random.nextInt(colors.length - 1)];
        } else {
          targetShape = ReflexShape.values
              .where((s) => s != requestedShape)
              .toList()[random.nextInt(ReflexShape.values.length - 1)];
        }
        isGoTarget = false;
      }
    }

    if (mode == ReflexMode.moving) {
      previousAlignment = targetAlignment;
    }
  }

  Alignment _randomAlignment() {
    double x = -0.78 + random.nextDouble() * 1.56;
    double y = -0.70 + random.nextDouble() * 1.40;

    return Alignment(x, y);
  }

  String _instructionText() {
    switch (currentMode) {
      case ReflexMode.reaction:
        return 'Yeşil ışığı bekle';
      case ReflexMode.targets:
        return 'Hedef belirince vur';
      case ReflexMode.colorChoice:
        return 'İstenen renge dikkat et';
      case ReflexMode.noGo:
        return 'Kırmızı hedefe DOKUNMA';
      case ReflexMode.falling:
        return 'Yukarıdan gelen hedefi doğru anda vur';
      case ReflexMode.whack:
        return widget.level.contentLevel >= 6
            ? 'Maymuna vur • bombaya dokunma'
            : 'Delikten çıkan maymuna vur';
      case ReflexMode.moving:
        return 'Hareketli hedefi yakala';
      case ReflexMode.dualRule:
        return 'Renk + şekil kuralını uygula';
      case ReflexMode.boss:
        return 'Kural her tur değişebilir';
    }
  }

  String _actionText() {
    switch (currentMode) {
      case ReflexMode.colorChoice:
        return 'İSTENEN RENK: ${_colorName(requestedColor)}';
      case ReflexMode.dualRule:
        return '${_colorName(requestedColor)} + ${_shapeName(requestedShape)}';
      case ReflexMode.noGo:
        return isGoTarget ? 'DOKUN!' : 'BEKLE!';
      case ReflexMode.falling:
        return 'AKAN HEDEFİ VUR!';
      case ReflexMode.whack:
        return isGoTarget ? 'MAYMUNA VUR!' : 'BOMBAYA DOKUNMA!';
      default:
        return 'HEDEFİ VUR!';
    }
  }

  String _colorName(Color color) {
    if (color == const Color(0xFF3D7183)) return 'MAVİ';
    if (color == const Color(0xFF665AA2)) return 'MOR';
    if (color == const Color(0xFFFF4F9A)) return 'PEMBE';
    if (color == const Color(0xFFFF9F1C)) return 'TURUNCU';
    if (color == const Color(0xFF8B622C)) return 'SARI';
    if (color == const Color(0xFF34715D)) return 'YEŞİL';
    return 'KIRMIZI';
  }

  String _shapeName(ReflexShape shape) {
    switch (shape) {
      case ReflexShape.circle:
        return 'DAİRE';
      case ReflexShape.square:
        return 'KARE';
      case ReflexShape.diamond:
        return 'ELMAS';
    }
  }

  Future<void> _tapTarget() async {
    if (locked ||
        !targetVisible ||
        _reactionClock == null ||
        levelFinished ||
        _mistakeInProgress ||
        _competitionResultDelivered) {
      return;
    }

    // Pointer aşağı iner inmez bu turu sahiplen. Böylece ekranın altına
    // yaklaşan hedefte parmağı kaldırmayı beklerken zaman aşımı oluşmaz.
    _roundGeneration++;

    timeoutTimer?.cancel();
    warningTimer?.cancel();

    _reactionClock!.stop();
    final int reactionMs = _reactionClock!.elapsedMilliseconds;
    _reactionClock = null;

    if (!isGoTarget) {
      await _wrong(
        'TUZAK!',
        sound: currentMode == ReflexMode.whack
            ? GameSound.reflexBomb
            : GameSound.reflexMiss,
      );
      return;
    }

    final bool ruleCorrect = _ruleIsCorrect();

    if (!ruleCorrect) {
      await _wrong('YANLIŞ HEDEF!');
      return;
    }

    successfulHits++;
    totalReaction += reactionMs;
    bestReaction = min(bestReaction, reactionMs);

    combo++;
    bestCombo = max(bestCombo, combo);

    final int speedBonus = max(0, widget.level.targetMs - reactionMs);

    final int gained = 100 + speedBonus * 2 + combo * 15;

    score += gained;
    round++;

    setState(() {
      targetVisible = false;
      locked = true;
      headline = reactionMs <= widget.level.targetMs ? 'MÜKEMMEL!' : 'İYİ!';
      subline = '$reactionMs ms';
      burstSeed++;
      showBurst = true;
      showFlash = true;
    });

    _audio.hapticMedium();

    _audio.play(
      currentMode == ReflexMode.whack
          ? GameSound.reflexMonkey
          : GameSound.reflexHit,
    );

    Future.delayed(const Duration(milliseconds: 90), () {
      if (mounted) {
        setState(() {
          showFlash = false;
        });
      }
    });

    await _floating(
      combo >= 4 ? '🔥 COMBO x$combo  +$gained' : '+$gained • ${reactionMs}ms',
    );

    if (round >= widget.level.rounds) {
      await _completeLevel();
      return;
    }

    await Future.delayed(
      Duration(milliseconds: currentMode == ReflexMode.falling ? 90 : 180),
    );

    _nextRound();
  }

  bool _ruleIsCorrect() {
    if (currentMode == ReflexMode.colorChoice) {
      return targetColor == requestedColor;
    }

    if (currentMode == ReflexMode.dualRule) {
      return targetColor == requestedColor && targetShape == requestedShape;
    }

    return true;
  }

  Future<void> _tapArenaBackground() async {
    if (levelFinished || _mistakeInProgress || _competitionResultDelivered) {
      return;
    }

    if (waiting) {
      await _wrong('ÇOK ERKEN!');
      return;
    }

    if (targetVisible && !isGoTarget) {
      return;
    }
  }

  Future<void> _timeOut() async {
    if (!mounted ||
        levelFinished ||
        locked ||
        !targetVisible ||
        _mistakeInProgress ||
        _competitionResultDelivered) {
      return;
    }

    if (!isGoTarget) {
      _reactionClock?.stop();
      _reactionClock = null;
      combo++;
      bestCombo = max(bestCombo, combo);
      score += 120 + combo * 10;
      round++;

      setState(() {
        targetVisible = false;
        locked = true;
        headline = 'DOĞRU KARAR!';
        subline = 'Tuzak hedefe dokunmadın';
      });

      _audio.play(GameSound.reflexCorrect);
      _audio.hapticLight();

      await _floating('🛡 +${120 + combo * 10}');

      if (round >= widget.level.rounds) {
        await _completeLevel();
        return;
      }

      await Future.delayed(const Duration(milliseconds: 250));

      _nextRound();
      return;
    }

    await _wrong('GEÇ KALDIN!');
  }

  Future<void> _wrong(
    String text, {
    GameSound sound = GameSound.reflexMiss,
  }) async {
    if (!mounted ||
        levelFinished ||
        _mistakeInProgress ||
        _competitionResultDelivered) {
      return;
    }

    _mistakeInProgress = true;
    _roundGeneration++;
    timeoutTimer?.cancel();
    warningTimer?.cancel();
    _reactionClock?.stop();
    _reactionClock = null;

    combo = 0;
    lives = max(0, lives - 1);
    final bool exhausted = lives == 0;

    if (exhausted) {
      levelFinished = true;
    }

    setState(() {
      targetVisible = false;
      locked = true;
      headline = text;
      subline = lives > 0 ? 'Bir can gitti' : 'Canların tükendi';
      showFlash = true;
    });

    _audio.hapticHeavy();
    _audio.play(sound);

    Future.delayed(const Duration(milliseconds: 110), () {
      if (mounted) {
        setState(() {
          showFlash = false;
        });
      }
    });

    await _floating('💔 -1 CAN');

    if (exhausted) {
      await _showGameOver();
      return;
    }

    await Future.delayed(
      Duration(milliseconds: currentMode == ReflexMode.falling ? 180 : 300),
    );

    if (!mounted) return;
    _mistakeInProgress = false;
    _nextRound();
  }

  Future<void> _floating(String text) async {
    if (!mounted) return;

    setState(() {
      floatingText = text;
      showFloating = true;
    });

    await Future.delayed(
      Duration(milliseconds: currentMode == ReflexMode.falling ? 320 : 520),
    );

    if (!mounted) return;

    setState(() {
      showFloating = false;
    });
  }

  int get averageReaction {
    if (successfulHits == 0) return 0;
    return totalReaction ~/ successfulHits;
  }

  int _calculateStars() {
    final int lostLives = _initialLives - lives;

    if (lostLives == 0 &&
        averageReaction > 0 &&
        averageReaction <= widget.level.targetMs) {
      return 3;
    }

    if (lostLives <= 1) {
      return 2;
    }

    return 1;
  }

  Future<void> _completeLevel() async {
    if (levelFinished || _competitionResultDelivered) return;

    _roundGeneration++;
    levelFinished = true;
    locked = true;

    final int stars = _calculateStars();
    final int finalScore =
        score + lives * 120 + bestCombo * 45 + max(0, 700 - averageReaction);

    setState(() {
      showConfetti = true;
      headline = 'ARENA TAMAMLANDI!';
      subline = averageReaction > 0
          ? 'Ortalama $averageReaction ms'
          : 'Refleks görevi tamamlandı';
    });

    _audio.hapticHeavy();

    _audio.playVictory(
      stars: stars,
      boss: widget.level.contentLevel == 10,
      levelNumber: widget.level.number,
    );

    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;

    if (widget.competitionMode) {
      if (_competitionResultDelivered) return;
      _competitionResultDelivered = true;
      Navigator.pop(
        context,
        ReflexLevelResult(
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
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [StudioVisuals.surface, StudioVisuals.surfaceSoft],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFF8B622C), width: 2),
              boxShadow: [
                BoxShadow(
                  color: StudioVisuals.ink.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.bolt_rounded,
                  size: 70,
                  color: Color(0xFF8B622C),
                ),
                const SizedBox(height: 8),
                LText(
                  widget.level.contentLevel == 10
                      ? '⚡ REFLEKS BOSS YENİLDİ!'
                      : '🏆 REFLEKS USTASI!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w900,
                    fontSize: 23,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (index) => Icon(
                      index < stars
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: const Color(0xFF8B622C),
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _ReflexResultBox(
                        title: 'ORT.',
                        value: averageReaction > 0
                            ? '${averageReaction}ms'
                            : '-',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ReflexResultBox(
                        title: 'EN İYİ',
                        value: bestReaction < 9999 ? '${bestReaction}ms' : '-',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ReflexResultBox(
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
                      backgroundColor: const Color(0xFFA84640),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      Navigator.pop(
                        context,
                        ReflexLevelResult(
                          completed: true,
                          stars: stars,
                          score: finalScore,
                          nextLevel: true,
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const LText('SONRAKİ SEVİYE'),
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    Navigator.pop(
                      context,
                      ReflexLevelResult(
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
        );
      },
    );
  }

  Future<void> _showGameOver() async {
    if (!mounted || _competitionResultDelivered) return;

    _roundGeneration++;
    timeoutTimer?.cancel();
    warningTimer?.cancel();
    _reactionClock?.stop();
    _reactionClock = null;
    levelFinished = true;
    locked = true;
    waiting = false;
    targetVisible = false;
    if (widget.competitionMode) {
      _competitionResultDelivered = true;
      Navigator.pop(
        context,
        const ReflexLevelResult(
          completed: false,
          stars: 0,
          score: 0,
          nextLevel: false,
        ),
      );
      return;
    }

    await showDialog<void>(
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
                color: Color(0xFFA84640),
                size: 52,
              ),
              SizedBox(height: 8),
              LText(
                'ARENA BİTTİ',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          content: LText(
            'Puan: $score\n'
            'Tur: $round / ${widget.level.rounds}\n'
            'En iyi tepki: ${bestReaction < 9999 ? '$bestReaction ms' : '-'}',
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
    _roundGeneration++;
    timeoutTimer?.cancel();
    warningTimer?.cancel();

    sessionSeed =
        widget.fixedSessionSeed ??
        await _replayability.newSeed(
          gameId: 'reflex',
          level: widget.level.number,
        );

    random = _replayability.randomFor(
      sessionSeed: sessionSeed,
      round: 0,
      salt: 61,
    );

    _bossSchedule = _buildBossSchedule();
    if (widget.fixedSessionSeed == null) {
      await _replayability.registerFingerprint(
        gameId: 'reflex',
        level: widget.level.number,
        fingerprint: _bossSchedule
            .map((ReflexMode mode) => mode.index)
            .join('-'),
        historyLimit: 150,
      );
    }

    if (!mounted) return;

    setState(() {
      lives = _initialLives;
      round = 0;
      score = 0;
      combo = 0;
      bestCombo = 0;
      bestReaction = 9999;
      totalReaction = 0;
      successfulHits = 0;
      levelFinished = false;
      _mistakeInProgress = false;
      _competitionResultDelivered = false;
      targetVisible = false;
      showConfetti = false;
    });

    _nextRound();
  }

  @override
  Widget build(BuildContext context) {
    final double progress = (round / widget.level.rounds).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LText(
              context.l10n.uppercaseLabel(widget.level.title),
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
            LText(
              'Seviye ${widget.level.number} / ${widget.totalLevels}',
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: StudioVisuals.muted,
                fontSize: 11,
              ),
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
              child: CustomPaint(painter: _ReflexBackgroundPainter()),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
              child: Column(
                children: [
                  _ReflexGameHeader(
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
                      backgroundColor: StudioVisuals.line,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFA84640),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Column(
                      key: ValueKey('$headline-$subline'),
                      children: [
                        LText(
                          headline,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                            letterSpacing: 1.2,
                            color: waiting
                                ? const Color(0xFF8B622C)
                                : const Color(0xFF34715D),
                          ),
                        ),
                        const SizedBox(height: 4),
                        LText(
                          subline,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            color: StudioVisuals.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _tapArenaBackground,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFEEF3F0), Color(0xFFEEF3F0)],
                              ),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: const Color(0xFFDDE7DF),
                                width: 2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black38,
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                          ),
                          if (currentMode == ReflexMode.whack)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: _WhackHoles(
                                  activeAlignment: targetVisible
                                      ? targetAlignment
                                      : null,
                                ),
                              ),
                            ),

                          if (targetVisible)
                            AnimatedAlign(
                              duration: currentMode == ReflexMode.falling
                                  ? Duration(
                                      // Hedef alt bölgeye zaman aşımından önce
                                      // ulaşır ve burada dokunulabilir kalır.
                                      milliseconds: max(
                                        360,
                                        (widget.level.timeLimitMs * 0.68)
                                            .round(),
                                      ),
                                    )
                                  : currentMode == ReflexMode.moving
                                  ? const Duration(milliseconds: 260)
                                  : Duration.zero,
                              curve: Curves.easeInOut,
                              alignment: targetAlignment,
                              child: Listener(
                                behavior: HitTestBehavior.translucent,
                                onPointerDown: (_) {
                                  unawaited(_tapTarget());
                                },
                                child: SizedBox(
                                  // Görsel 72–80 px kalır; dokunma alanı
                                  // başparmak kullanımına uygun şekilde büyür.
                                  width: 112,
                                  height: 112,
                                  child: Center(
                                    child: _ReflexTarget(
                                      color: targetColor,
                                      shape: targetShape,
                                      goTarget: isGoTarget,
                                      boss: widget.level.contentLevel == 10,
                                      whack: currentMode == ReflexMode.whack,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (currentMode == ReflexMode.moving && targetVisible)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0, end: 1),
                                  duration: const Duration(milliseconds: 700),
                                  onEnd: () {
                                    if (mounted && targetVisible && !locked) {
                                      setState(() {
                                        previousAlignment = targetAlignment;
                                        targetAlignment = _randomAlignment();
                                      });
                                    }
                                  },
                                  builder: (context, value, child) {
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                            ),
                          if (showBurst)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: TweenAnimationBuilder<double>(
                                  key: ValueKey(burstSeed),
                                  tween: Tween<double>(begin: 0, end: 1),
                                  duration: const Duration(milliseconds: 500),
                                  onEnd: () {
                                    if (mounted) {
                                      setState(() {
                                        showBurst = false;
                                      });
                                    }
                                  },
                                  builder: (context, value, child) {
                                    return CustomPaint(
                                      painter: _ReflexBurstPainter(
                                        progress: value,
                                        seed: burstSeed,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          Positioned.fill(
                            child: IgnorePointer(
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 90),
                                opacity: showFlash ? 0.28 : 0,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: RadialGradient(
                                      colors: [
                                        Color(0xFFFFFFFF),
                                        Color(0x558B622C),
                                        Color(0x00000000),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          IgnorePointer(
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 120),
                              opacity: showFloating ? 1 : 0,
                              child: TweenAnimationBuilder<double>(
                                key: ValueKey(floatingText),
                                tween: Tween<double>(begin: 0, end: 1),
                                duration: const Duration(milliseconds: 600),
                                builder: (context, value, child) {
                                  return Transform.translate(
                                    offset: Offset(0, -62 * value),
                                    child: Transform.scale(
                                      scale:
                                          0.80 + min(value * 1.6, 1.0) * 0.28,
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
                                      color: const Color(0xFF8B622C),
                                      width: 2,
                                    ),
                                  ),
                                  child: LText(
                                    floatingText,
                                    style: const TextStyle(
                                      fontFamily: 'Roboto',
                                      color: Color(0xFF8B622C),
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
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _MiniMetric(
                        label: 'ORTALAMA',
                        value: averageReaction > 0
                            ? '${averageReaction}ms'
                            : '--',
                      ),
                      _MiniMetric(
                        label: 'EN İYİ',
                        value: bestReaction < 9999 ? '${bestReaction}ms' : '--',
                      ),
                      _MiniMetric(
                        label: 'HEDEF',
                        value: '${widget.level.targetMs}ms',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (showConfetti)
            Positioned.fill(
              child: IgnorePointer(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1500),
                  builder: (context, value, child) {
                    return CustomPaint(
                      painter: _ReflexConfettiPainter(
                        progress: value,
                        seed: widget.level.number * 97,
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
}

class _ReflexTarget extends StatelessWidget {
  final Color color;
  final ReflexShape shape;
  final bool goTarget;
  final bool boss;
  final bool whack;

  const _ReflexTarget({
    required this.color,
    required this.shape,
    required this.goTarget,
    required this.boss,
    required this.whack,
  });

  @override
  Widget build(BuildContext context) {
    final double size = boss ? 80 : 72;

    BorderRadius borderRadius;

    switch (shape) {
      case ReflexShape.circle:
        borderRadius = BorderRadius.circular(100);
        break;
      case ReflexShape.square:
        borderRadius = BorderRadius.circular(17);
        break;
      case ReflexShape.diamond:
        borderRadius = BorderRadius.circular(14);
        break;
    }

    Widget target = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(color, Colors.white, 0.32) ?? color,
            color,
            Color.lerp(color, Colors.black, 0.20) ?? color,
          ],
        ),
        borderRadius: borderRadius,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.50),
          width: 2.3,
        ),
        boxShadow: [
          BoxShadow(
            color: StudioVisuals.ink.withValues(alpha: 0.16),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: whack
            ? LText(
                goTarget ? '🐵' : '💣',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: boss ? 42 : 38,
                ),
              )
            : Icon(
                goTarget ? Icons.bolt_rounded : Icons.block_rounded,
                color: Colors.white,
                size: 34,
              ),
      ),
    );

    if (shape == ReflexShape.diamond) {
      target = Transform.rotate(
        angle: pi / 4,
        child: Transform.rotate(angle: -pi / 4, child: target),
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.55, end: 1.0),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: target,
    );
  }
}

class _WhackHoles extends StatelessWidget {
  final Alignment? activeAlignment;

  const _WhackHoles({required this.activeAlignment});

  static const List<Alignment> holes = [
    Alignment(-0.68, -0.48),
    Alignment(0.0, -0.48),
    Alignment(0.68, -0.48),
    Alignment(-0.68, 0.48),
    Alignment(0.0, 0.48),
    Alignment(0.68, 0.48),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: holes.map((alignment) {
        final bool active = activeAlignment == alignment;

        return Align(
          alignment: alignment,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: active ? 94 : 88,
            height: active ? 48 : 42,
            decoration: BoxDecoration(
              color: const Color(0xFF6B614E),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: active
                    ? const Color(0xFFFFB84D)
                    : const Color(0xFFC6B088),
                width: active ? 2.2 : 1.3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 68,
                height: 10,
                margin: const EdgeInsets.only(bottom: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFAD9877),
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ReflexGameHeader extends StatelessWidget {
  final int score;
  final int round;
  final int totalRounds;
  final int lives;
  final int combo;

  const _ReflexGameHeader({
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
          child: _ReflexTopStat(
            title: 'PUAN',
            value: '$score',
            color: const Color(0xFF8B622C),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _ReflexTopStat(
            title: 'TUR',
            value: '$round/$totalRounds',
            color: const Color(0xFF3D7183),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _ReflexTopStat(
            title: 'CAN',
            value: '♥ $lives',
            color: const Color(0xFFA84640),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _ReflexTopStat(
            title: 'COMBO',
            value: 'x$combo',
            color: const Color(0xFF34715D),
          ),
        ),
      ],
    );
  }
}

class _ReflexTopStat extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _ReflexTopStat({
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
              fontFamily: 'Roboto',
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          LText(
            title,
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: StudioVisuals.muted,
              fontSize: 7,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;

  const _MiniMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LText(
          value,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w900,
            fontSize: 14,
            color: Color(0xFF3D7183),
          ),
        ),
        const SizedBox(height: 2),
        LText(
          label,
          style: const TextStyle(
            fontFamily: 'Roboto',
            color: StudioVisuals.muted,
            fontSize: 8,
          ),
        ),
      ],
    );
  }
}

class _ReflexProgressPanel extends StatelessWidget {
  final int totalScore;
  final int totalStars;
  final int unlockedLevel;
  final int levelCount;

  const _ReflexProgressPanel({
    required this.totalScore,
    required this.totalStars,
    required this.unlockedLevel,
    required this.levelCount,
  });

  @override
  Widget build(BuildContext context) {
    final int maxLevels = max(GameContentPolicy.campaignLevels, levelCount);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: StudioVisuals.surface,
        borderRadius: StudioVisuals.cardRadius,
        border: Border.all(color: StudioVisuals.line),
        boxShadow: StudioVisuals.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: StudioVisuals.amberSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bolt_rounded,
              size: 38,
              color: StudioVisuals.amber,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LText(
                  'REFLEKS USTALIĞI',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: StudioVisuals.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 4),
                LText(
                  'Seviye $unlockedLevel / $maxLevels   •   ⭐ $totalStars / ${maxLevels * 3}',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: StudioVisuals.muted,
                    fontSize: 11,
                  ),
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
                  fontFamily: 'Roboto',
                  color: StudioVisuals.amber,
                  fontWeight: FontWeight.w900,
                  fontSize: 21,
                ),
              ),
              const LText(
                'PUAN',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  color: StudioVisuals.muted,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReflexQuickResumeCard extends StatelessWidget {
  final int levelNumber;
  final String levelTitle;
  final String difficulty;
  final VoidCallback onPlay;

  const _ReflexQuickResumeCard({
    required this.levelNumber,
    required this.levelTitle,
    required this.difficulty,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    const Color accent = Color(0xFFA84640);
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: StudioVisuals.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bolt_rounded, color: accent, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 2,
                  children: [
                    const LText(
                      'SIRADAKİ PARKUR',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: accent,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: LText(
                        difficulty,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          color: accent,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                LText(
                  'Bölüm $levelNumber • $levelTitle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: StudioVisuals.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onPlay,
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_arrow_rounded, size: 16),
                SizedBox(width: 2),
                LText(
                  'OYNA',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReflexLevelCard extends StatelessWidget {
  final ReflexLevel level;
  final bool unlocked;
  final int stars;
  final int bestScore;
  final VoidCallback onTap;

  const _ReflexLevelCard({
    required this.level,
    required this.unlocked,
    required this.stars,
    required this.bestScore,
    required this.onTap,
  });

  Color get color {
    switch (level.difficulty) {
      case 'KOLAY':
        return const Color(0xFF34715D);
      case 'ORTA':
        return const Color(0xFFFF9F1C);
      case 'ZOR':
        return const Color(0xFFA84640);
      case 'BOSS':
        return const Color(0xFFFF4F9A);
      default:
        return const Color(0xFF3D7183);
    }
  }

  IconData get icon {
    switch (level.mode) {
      case ReflexMode.reaction:
        return Icons.timer_rounded;
      case ReflexMode.targets:
        return Icons.gps_fixed_rounded;
      case ReflexMode.colorChoice:
        return Icons.palette_rounded;
      case ReflexMode.noGo:
        return Icons.pan_tool_alt_rounded;
      case ReflexMode.falling:
        return Icons.vertical_align_bottom_rounded;
      case ReflexMode.whack:
        return Icons.sports_esports_rounded;
      case ReflexMode.moving:
        return Icons.open_with_rounded;
      case ReflexMode.dualRule:
        return Icons.hub_rounded;
      case ReflexMode.boss:
        return Icons.bolt_rounded;
    }
  }

  @override
  Widget build(BuildContext context) => StudioChapterCard(
    gameId: 'reflex',
    number: level.number,
    title: level.title,
    detail: level.subtitle,
    difficulty: GameContentPolicy.difficulty(level.number),
    unlocked: unlocked,
    stars: stars,
    best: bestScore,
    onTap: onTap,
  );
}

class _ReflexResultBox extends StatelessWidget {
  final String title;
  final String value;

  const _ReflexResultBox({required this.title, required this.value});

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
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          LText(
            title,
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: StudioVisuals.muted,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReflexBackgroundPainter extends CustomPainter {
  const _ReflexBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint glow = Paint()
      ..shader =
          const RadialGradient(colors: [Color(0x22A84640), Color(0x00000000)])
              .createShader(
                Rect.fromCircle(
                  center: Offset(size.width * 0.18, size.height * 0.22),
                  radius: size.width * 0.68,
                ),
              );

    canvas.drawRect(Offset.zero & size, glow);

    final Paint gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 1;

    const double step = 34;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ReflexBackgroundPainter oldDelegate) {
    return false;
  }
}

class _ReflexBurstPainter extends CustomPainter {
  final double progress;
  final int seed;

  const _ReflexBurstPainter({required this.progress, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final Random rng = Random(seed);
    final Offset center = Offset(size.width / 2, size.height / 2);

    const List<Color> colors = [
      Color(0xFF3D7183),
      Color(0xFF8B622C),
      Color(0xFFA84640),
      Color(0xFF34715D),
      Color(0xFFFF4F9A),
    ];

    final double fade = (1 - progress).clamp(0.0, 1.0);

    for (int i = 0; i < 42; i++) {
      final double angle = rng.nextDouble() * pi * 2;

      final double distance =
          (18 + rng.nextDouble() * 145) * Curves.easeOut.transform(progress);

      final Offset point =
          center + Offset(cos(angle) * distance, sin(angle) * distance);

      final Paint paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: fade);

      canvas.drawCircle(point, 3 + rng.nextDouble() * 5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ReflexBurstPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.seed != seed;
  }
}

class _ReflexConfettiPainter extends CustomPainter {
  final double progress;
  final int seed;

  const _ReflexConfettiPainter({required this.progress, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final Random rng = Random(seed);

    const List<Color> colors = [
      Color(0xFF3D7183),
      Color(0xFF665AA2),
      Color(0xFFFF4F9A),
      Color(0xFFFF9F1C),
      Color(0xFF8B622C),
      Color(0xFF34715D),
      Color(0xFFA84640),
    ];

    for (int i = 0; i < 90; i++) {
      final double x = rng.nextDouble() * size.width;

      final double delay = rng.nextDouble() * 0.25;

      final double local = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);

      final double y =
          -40 + local * (size.height + 90) + sin(local * pi * 4 + i) * 14;

      final Paint paint = Paint()
        ..color = colors[i % colors.length].withValues(
          alpha: (1 - local * 0.30).clamp(0.0, 1.0),
        );

      canvas.save();
      canvas.translate(x + sin(local * pi * 2 + i) * 24, y);
      canvas.rotate(local * 8 + i);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-4, -8, 8, 16),
          const Radius.circular(3),
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ReflexConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.seed != seed;
  }
}

enum ReflexMode {
  reaction,
  targets,
  colorChoice,
  noGo,
  falling,
  whack,
  moving,
  dualRule,
  boss,
}

enum ReflexShape { circle, square, diamond }

class ReflexLevel {
  final int number;
  final int? sourceNumber;
  int get contentLevel => sourceNumber ?? number;
  final String title;
  final String subtitle;
  final String difficulty;

  final ReflexMode mode;

  final int rounds;
  final int lives;
  final int timeLimitMs;
  final int targetMs;

  final int distractors;

  const ReflexLevel({
    required this.number,
    this.sourceNumber,
    required this.title,
    required this.subtitle,
    required this.difficulty,
    required this.mode,
    required this.rounds,
    required this.lives,
    required this.timeLimitMs,
    required this.targetMs,
    this.distractors = 0,
  });
}

class ReflexLevelResult {
  final bool completed;
  final int stars;
  final int score;
  final bool nextLevel;

  const ReflexLevelResult({
    required this.completed,
    required this.stars,
    required this.score,
    required this.nextLevel,
  });
}
