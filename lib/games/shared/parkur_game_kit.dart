import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';
import '../../services/daily_challenge_service.dart';
import '../../services/daily_course_service.dart';
import '../../services/game_audio_service.dart';
import '../../services/common_level_score_service.dart';
import '../../theme/studio_visuals.dart';
import '../../widgets/studio_game_artwork.dart';
import 'game_instruction_catalog.dart';
import 'game_visual_design.dart';
import 'studio_game_contracts.dart';
import 'campaign_round_store.dart';
import 'campaign_asset_bank.dart';

class ParkurLevelSpec {
  final int number;
  final String titleTr;
  final String titleEn;
  final String subtitleTr;
  final String subtitleEn;
  final String difficulty;
  final IconData icon;
  final int? sourceNumber;
  final int? poolIndex;
  int get contentLevel => sourceNumber ?? number;
  int get contentIndex => poolIndex ?? number;

  const ParkurLevelSpec({
    required this.number,
    required this.titleTr,
    required this.titleEn,
    required this.subtitleTr,
    required this.subtitleEn,
    required this.difficulty,
    required this.icon,
    this.sourceNumber,
    this.poolIndex,
  });

  String title(bool english) => english ? titleEn : titleTr;
  String subtitle(bool english) => english ? subtitleEn : subtitleTr;

  ParkurLevelSpec campaignCopy({
    required int number,
    int? sourceNumber,
    int? poolIndex,
    String? titleTr,
    String? titleEn,
    String? difficulty,
  }) => ParkurLevelSpec(
    number: number,
    sourceNumber: sourceNumber,
    poolIndex: poolIndex,
    titleTr: titleTr ?? this.titleTr,
    titleEn: titleEn ?? this.titleEn,
    subtitleTr: subtitleTr,
    subtitleEn: subtitleEn,
    difficulty: difficulty ?? this.difficulty,
    icon: icon,
  );
}

class ParkurGameResult {
  final bool completed;
  final int stars;
  final int score;
  final bool nextLevel;
  final bool replayLevel;

  const ParkurGameResult({
    required this.completed,
    required this.stars,
    required this.score,
    required this.nextLevel,
    this.replayLevel = false,
  });
}

class ParkurProgressSnapshot {
  final int unlockedLevel;
  final List<int> stars;
  final List<int> bestScores;
  final List<int> commonPoints;

  const ParkurProgressSnapshot({
    required this.unlockedLevel,
    required this.stars,
    required this.bestScores,
    this.commonPoints = const <int>[],
  });
}

class ParkurProgressStore {
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
  final String prefix;
  final int levelCount;
  final bool endless;

  ParkurProgressStore({
    required this.prefix,
    required this.levelCount,
    this.endless = false,
  });

  Future<ParkurProgressSnapshot> load() async {
    final int unlocked = await _prefs.getInt('${prefix}_unlocked_level') ?? 1;
    final List<String>? storedStars = await _prefs.getStringList(
      '${prefix}_stars',
    );
    final List<String>? storedScores = await _prefs.getStringList(
      '${prefix}_best_scores',
    );
    final List<String>? storedCommonPoints = await _prefs.getStringList(
      '${prefix}_common_points',
    );

    final int star30 = storedStars != null &&
            storedStars.length >= GameContentPolicy.campaignLevels
        ? (int.tryParse(storedStars[GameContentPolicy.campaignLevels - 1]) ?? 0)
        : 0;
    final bool hasGenuinePost30 = endless && star30 > 0;
    final int effectiveLength = hasGenuinePost30
        ? max(
            levelCount,
            max(
              unlocked,
              max(storedStars?.length ?? 0, storedScores?.length ?? 0),
            ),
          )
        : levelCount;

    final decodedStars = _decode(storedStars, effectiveLength, stars: true);
    final int safeUnlocked = hasGenuinePost30
        ? max(1, unlocked)
        : unlocked.clamp(1, levelCount).toInt();
    return ParkurProgressSnapshot(
      unlockedLevel: safeUnlocked,
      stars: decodedStars,
      bestScores: _decode(storedScores, effectiveLength),
      commonPoints: _decodeCommonPoints(
        storedCommonPoints,
        decodedStars,
        effectiveLength,
      ),
    );
  }

  List<int> _decodeCommonPoints(
    List<String>? source,
    List<int> stars,
    int targetLength,
  ) {
    return List<int>.generate(targetLength, (int index) {
      if (source != null && index < source.length) {
        return (int.tryParse(source[index]) ?? 0)
            .clamp(0, CommonLevelScoreSession.pointsPerLevel)
            .toInt();
      }
      // Existing completed levels predate the common scale. Preserve their
      // progress with the full base score; new assisted attempts store zero.
      return index < stars.length && stars[index] > 0
          ? CommonLevelScoreSession.pointsPerLevel
          : 0;
    }, growable: false);
  }

  List<int> _decode(List<String>? source, int targetLength, {bool stars = false}) {
    return List<int>.generate(targetLength, (int index) {
      if (source == null || index >= source.length) return 0;
      final int value = max(0, int.tryParse(source[index]) ?? 0);
      return stars ? value.clamp(0, 3).toInt() : value;
    });
  }

  Future<void> save(ParkurProgressSnapshot data) async {
    final String unlockedKey = '${prefix}_unlocked_level';
    final String starsKey = '${prefix}_stars';
    final String scoresKey = '${prefix}_best_scores';
    final String commonPointsKey = '${prefix}_common_points';
    final int storedUnlocked = await _prefs.getInt(unlockedKey) ?? 1;
    final List<String>? storedStars = await _prefs.getStringList(starsKey);
    final List<String>? storedScores = await _prefs.getStringList(scoresKey);
    final List<String>? storedCommonPoints = await _prefs.getStringList(
      commonPointsKey,
    );
    final int effectiveMaxLevel = endless
        ? max(levelCount, max(data.unlockedLevel, data.stars.length))
        : levelCount;
    final int retainedLength = max(
      effectiveMaxLevel,
      max(
        max(storedStars?.length ?? 0, storedScores?.length ?? 0),
        storedCommonPoints?.length ?? 0,
      ),
    );

    // A shorter campaign may hide old levels, but must not erase their local
    // records. If the campaign is expanded again, the archived tail survives.
    final int clampedStoredUnlock = storedUnlocked
        .clamp(1, retainedLength)
        .toInt();
    final int targetUnlock = endless
        ? max(1, data.unlockedLevel)
        : data.unlockedLevel.clamp(1, levelCount).toInt();
    await _prefs.setInt(
      unlockedKey,
      max(clampedStoredUnlock, targetUnlock),
    );
    await _prefs.setStringList(
      starsKey,
      _mergeStoredTail(data.stars, storedStars),
    );
    await _prefs.setStringList(
      scoresKey,
      _mergeStoredTail(data.bestScores, storedScores),
    );
    final List<int> commonPoints = data.commonPoints.isEmpty
        ? List<int>.generate(effectiveMaxLevel, (int index) {
            return index < data.stars.length && data.stars[index] > 0
                ? CommonLevelScoreSession.pointsPerLevel
                : 0;
          }, growable: false)
        : data.commonPoints;
    await _prefs.setStringList(
      commonPointsKey,
      _mergeStoredTail(commonPoints, storedCommonPoints),
    );
  }

  List<String> _mergeStoredTail(
    List<int> currentValues,
    List<String>? storedValues,
  ) {
    final int length = max(
      levelCount,
      max(currentValues.length, storedValues?.length ?? 0),
    );
    return List<String>.generate(length, (int index) {
      if (index < currentValues.length) return '${currentValues[index]}';
      if (storedValues != null && index < storedValues.length) {
        return storedValues[index];
      }
      return '0';
    }, growable: false);
  }
}

typedef ParkurPlayBuilder = Widget Function(
  BuildContext context,
  ParkurLevelSpec level,
  int previousBestScore,
  int? competitionLayoutCode,
  bool competitionMode,
);

class ParkurLevelHub extends StatefulWidget {
  final String gameId;
  final String progressPrefix;
  final String titleTr;
  final String titleEn;
  final String taglineTr;
  final String taglineEn;
  final Color accent;
  final IconData icon;
  final List<ParkurLevelSpec> levels;
  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;
  final Widget? hubAction;
  final bool emphasizeLevelCards;
  final ParkurPlayBuilder playBuilder;

  const ParkurLevelHub({
    super.key,
    required this.gameId,
    required this.progressPrefix,
    required this.titleTr,
    required this.titleEn,
    required this.taglineTr,
    required this.taglineEn,
    required this.accent,
    required this.icon,
    required this.levels,
    required this.dailyCourseMode,
    this.competitionLevel,
    this.competitionLayoutCode,
    this.hubAction,
    this.emphasizeLevelCards = false,
    required this.playBuilder,
  });

  @override
  State<ParkurLevelHub> createState() => _ParkurLevelHubState();
}

class _ParkurLevelHubState extends State<ParkurLevelHub> {
  late final ParkurProgressStore _store;
  late List<ParkurLevelSpec> _levels;
  final ScrollController _scrollController = ScrollController();
  bool _opening = false;
  bool get _standard => GameContentPolicy.standardGames.contains(widget.gameId);
  final GameAudioService _audio = GameAudioService.instance;

  bool _loading = true;
  int _unlockedLevel = 1;
  List<int> _stars = const <int>[];
  List<int> _bestScores = const <int>[];
  List<int> _commonPoints = const <int>[];
  bool _competitionOpened = false;

  int get _totalStars => _stars.fold<int>(0, (int a, int b) => a + b);
  int get _totalScore => _bestScores.fold<int>(0, (int a, int b) => a + b);
  int get _totalCommonPoints => _commonPoints.fold<int>(0, (int a, int b) => a + b);

  List<ParkurLevelSpec> _generateLevels(int targetLevel) {
    final int count = targetLevel >= 26
        ? max(GameContentPolicy.campaignLevels, targetLevel + 5)
        : GameContentPolicy.campaignLevels;
    if (!_standard) {
      if (widget.levels.length >= count) {
        return widget.levels.take(count).toList();
      }
      return List<ParkurLevelSpec>.generate(count, (index) {
        final chapter = index + 1;
        final source = GameContentPolicy.endlessHighChapter(chapter);
        final base = widget.levels[(source - 1) % widget.levels.length];
        return base.campaignCopy(
          number: chapter,
          difficulty: GameContentPolicy.difficulty(chapter),
        );
      });
    }
    final int stages = GameContentPolicy.nativeStages(widget.gameId);
    return List<ParkurLevelSpec>.generate(count, (index) {
      final chapter = index + 1;
      final source = GameContentPolicy.nativeLevel(
        chapter,
        stages: stages,
      );
      final base =
          widget.levels[(source - 1).clamp(0, widget.levels.length - 1)];
      String title(String value) => value.replaceFirst(
        RegExp(r'\s+\d+$'),
        ' ${chapter.toString().padLeft(2, '0')}',
      );
      return base.campaignCopy(
        number: chapter,
        sourceNumber: source,
        titleTr: title(base.titleTr),
        titleEn: title(base.titleEn),
        difficulty: GameContentPolicy.difficulty(chapter),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _levels = _generateLevels(1);
    _store = ParkurProgressStore(
      prefix: widget.progressPrefix,
      levelCount: GameContentPolicy.campaignLevels,
      endless: true,
    );
    unawaited(_load());
    unawaited(_audio.preload(GameAudioGroup.ui));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final ParkurProgressSnapshot data = await _store.load();
    if (!mounted) return;
    final levels = _generateLevels(data.unlockedLevel);
    final stars = List<int>.from(data.stars);
    final bestScores = List<int>.from(data.bestScores);
    final commonPoints = List<int>.from(data.commonPoints);
    while (stars.length < levels.length) {
      stars.add(0);
    }
    while (bestScores.length < levels.length) {
      bestScores.add(0);
    }
    while (commonPoints.length < levels.length) {
      commonPoints.add(0);
    }

    setState(() {
      _unlockedLevel = data.unlockedLevel;
      _levels = levels;
      _stars = stars;
      _bestScores = bestScores;
      _commonPoints = commonPoints;
      _loading = false;
    });

    _openCompetitionLevelIfNeeded();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      if (_unlockedLevel > 2) {
        final double targetOffset = (_unlockedLevel - 2) * 110.0;
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
      _openLevel((level - 1).clamp(0, _levels.length - 1).toInt());
    });
  }

  Future<void> _openLevel(int index) async {
    if (_loading ||
        _opening ||
        index < 0 ||
        index >= _levels.length ||
        (widget.competitionLevel == null && index + 1 > _unlockedLevel)) {
      return;
    }

    unawaited(_audio.play(GameSound.uiClick));
    _opening = true;
    int activeIndex = index;
    final NavigatorState navigator = Navigator.of(context);

    while (mounted) {
      final base = _levels[activeIndex];
      final pool = _standard
          ? widget.competitionLayoutCode != null
                ? GameContentPolicy.poolIndexForGame(
                    widget.gameId,
                    base.number,
                    widget.competitionLayoutCode!.abs() %
                        GameContentPolicy.variantsForChapter(
                          widget.gameId,
                          base.number,
                        ),
                    stages: GameContentPolicy.nativeStages(widget.gameId),
                  )
                : await CampaignRoundStore.reserve(widget.gameId, base.number)
          : null;
      try {
        await CampaignAssetBank.prepare(widget.gameId);
      } catch (_) {
        _opening = false;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.l10n.isEnglish
                    ? 'This chapter could not be loaded. Please try again.'
                    : 'Bölüm yüklenemedi. Lütfen yeniden deneyin.',
              ),
            ),
          );
        }
        return;
      }
      if (!mounted) return;
      final playable = base.campaignCopy(
        number: base.number,
        sourceNumber: base.sourceNumber,
        poolIndex: pool,
      );
      final CommonLevelScoreSession scoring = CommonLevelScoreSession.begin();
      Object? rawResult;
      try {
        rawResult = await navigator.push<Object?>(
          MaterialPageRoute<Object?>(
            builder: (BuildContext context) => StudioGameTheme(
              gameId: widget.gameId,
              child: widget.playBuilder(
                context,
                playable,
                _bestScores[activeIndex],
                _standard ? null : widget.competitionLayoutCode,
                widget.competitionLevel != null,
              ),
            ),
          ),
        );
      } finally {
        scoring.finish();
      }
      final int commonPoints = scoring.points;
      if (!mounted) return;
      _opening = false;
      final ParkurGameResult? result = rawResult is ParkurGameResult
          ? rawResult
          : null;

      // Reference games already return a DailyStageResult in course mode;
      // older games return ParkurGameResult. The inner route accepts both,
      // and this hub forwards one course result to the outer coordinator.
      if (widget.dailyCourseMode) {
        final DailyStageResult dailyResult;
        if (rawResult is DailyStageResult &&
            rawResult.gameId == widget.gameId) {
          dailyResult = rawResult.outcome == DailyStageOutcome.completed
              ? DailyStageResult.completed(
                  gameId: widget.gameId,
                  stars: rawResult.stars,
                  rawScore: commonPoints,
                )
              : rawResult;
        } else {
          dailyResult = result == null
              ? DailyStageResult.exited(gameId: widget.gameId)
              : result.completed
              ? DailyStageResult.completed(
                  gameId: widget.gameId,
                  stars: result.stars,
                  rawScore: commonPoints,
                )
              : DailyStageResult.failed(gameId: widget.gameId);
        }
        navigator.pop(dailyResult);
        return;
      }

      if (result == null || !result.completed) {
        if (widget.competitionLevel != null && mounted) {
          navigator.pop();
        }
        return;
      }
      final ParkurGameResult completedResult = result;

      if (widget.competitionLevel != null) {
        navigator.pop(
          DailyCourseGameResult(
            gameId: widget.gameId,
            stars: completedResult.stars,
            score: commonPoints,
          ),
        );
        return;
      }

      setState(() {
        _stars[activeIndex] = max(_stars[activeIndex], completedResult.stars);
        _bestScores[activeIndex] = max(
          _bestScores[activeIndex],
          completedResult.score,
        );
        _commonPoints[activeIndex] = max(
          _commonPoints[activeIndex],
          commonPoints,
        );
        if (activeIndex + 1 == _unlockedLevel) {
          _unlockedLevel++;
          if (_unlockedLevel + 3 >= _levels.length) {
            final nextLevels = _generateLevels(_unlockedLevel);
            while (_stars.length < nextLevels.length) {
              _stars.add(0);
            }
            while (_bestScores.length < nextLevels.length) {
              _bestScores.add(0);
            }
            while (_commonPoints.length < nextLevels.length) {
              _commonPoints.add(0);
            }
            _levels = nextLevels;
          }
        }
      });

      await _store.save(
        ParkurProgressSnapshot(
          unlockedLevel: _unlockedLevel,
          stars: _stars,
          bestScores: _bestScores,
          commonPoints: _commonPoints,
        ),
      );

      await DailyChallengeService.instance.recordLevelCompleted(
        gameId: widget.gameId,
        stars: completedResult.stars,
        score: commonPoints,
      );

      if (completedResult.replayLevel) {
        _opening = true;
        await Future<void>.delayed(const Duration(milliseconds: 160));
        continue;
      }

      if (completedResult.nextLevel) {
        _opening = true;
        activeIndex++;
        if (activeIndex >= _levels.length) {
          final nextLevels = _generateLevels(activeIndex + 1);
          while (_stars.length < nextLevels.length) {
            _stars.add(0);
          }
          while (_bestScores.length < nextLevels.length) {
            _bestScores.add(0);
          }
          while (_commonPoints.length < nextLevels.length) {
            _commonPoints.add(0);
          }
          setState(() {
            _levels = nextLevels;
          });
        }
        await Future<void>.delayed(const Duration(milliseconds: 160));
        continue;
      }
      return;
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
          children: <Widget>[
            Text(
              context.l10n.gameUi(english ? widget.titleEn : widget.titleTr),
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
                english ? widget.taglineEn : widget.taglineTr,
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
          child: _loading || widget.competitionLevel != null
              ? const Center(child: CircularProgressIndicator())
              : LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints limits) {
                    final bool compact = limits.maxWidth < 360;
                    final bool isLandscape = limits.maxWidth > limits.maxHeight;

                    return CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: <Widget>[
                        SliverToBoxAdapter(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                                child: _ProgressPanel(
                                  gameId: widget.gameId,
                                  accent: widget.accent,
                                  icon: widget.icon,
                                  totalScore: _totalScore,
                                  totalCommonPoints: _totalCommonPoints,
                                  totalStars: _totalStars,
                                  unlockedLevel: _unlockedLevel,
                                  levelCount: _levels.length,
                                  english: english,
                                ),
                              ),
                              if (_unlockedLevel <= _levels.length)
                                _ParkurQuickResumeCard(
                                  levelNumber: _unlockedLevel,
                                  levelTitle:
                                      _levels[_unlockedLevel - 1].title(english),
                                  difficulty: _levels[_unlockedLevel - 1].difficulty,
                                  accent: widget.accent,
                                  onPlay: () => _openLevel(_unlockedLevel - 1),
                                ),
                              if (GameInstructionCatalog.forGame(widget.gameId) !=
                                  null)
                                GameInstructionCard(
                                  gameId: widget.gameId,
                                  english: english,
                                  initiallyExpanded: false,
                                ),
                              if (!_standard && widget.hubAction != null)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: widget.hubAction,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            compact ? 12 : 16,
                            0,
                            compact ? 12 : 16,
                            30,
                          ),
                          sliver: SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isLandscape ? 2 : 1,
                              crossAxisSpacing: compact ? 10 : 14,
                              mainAxisSpacing: 10,
                              mainAxisExtent:
                                  104 *
                                  MediaQuery.textScalerOf(context)
                                      .scale(1)
                                      .clamp(1.0, 1.6),
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (BuildContext context, int index) {
                                return _LevelCard(
                                  gameId: widget.gameId,
                                  level: _levels[index],
                                  accent: widget.accent,
                                  unlocked:
                                      index + 1 <= _unlockedLevel,
                                  stars: _stars[index],
                                  bestScore: _bestScores[index],
                                  commonPoints: _commonPoints[index],
                                  english: english,
                                  prominent: true,
                                  onTap: () => _openLevel(index),
                                );
                              },
                              childCount: _levels.length,
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

class _ProgressPanel extends StatelessWidget {
  final String gameId;
  final Color accent;
  final IconData icon;
  final int totalScore;
  final int totalCommonPoints;
  final int totalStars;
  final int unlockedLevel;
  final int levelCount;
  final bool english;

  const _ProgressPanel({
    required this.gameId,
    required this.accent,
    required this.icon,
    required this.totalScore,
    required this.totalCommonPoints,
    required this.totalStars,
    required this.unlockedLevel,
    required this.levelCount,
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
            width: 84,
            height: 76,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: accent.withValues(alpha: 0.28)),
            ),
            child: StudioGameArtwork(gameId: gameId),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _HubStat(
                  label: context.l10n.gameUi(english ? 'STARS' : 'YILDIZ'),
                  value: '$totalStars/${levelCount * 3}',
                  color: StudioVisuals.amberInk,
                ),
                _HubStat(
                  label: 'ZP',
                  value: '$totalCommonPoints',
                  color: StudioVisuals.tealInk,
                ),
                _HubStat(
                  label: context.l10n.gameUi(english ? 'OPEN' : 'AÇIK'),
                  value: '$unlockedLevel/$levelCount',
                  color: StudioVisuals.ink,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HubStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HubStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: StudioVisuals.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Roboto',
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: StudioVisuals.muted,
              fontWeight: FontWeight.w800,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParkurQuickResumeCard extends StatelessWidget {
  final int levelNumber;
  final String levelTitle;
  final String difficulty;
  final Color accent;
  final VoidCallback onPlay;

  const _ParkurQuickResumeCard({
    required this.levelNumber,
    required this.levelTitle,
    required this.difficulty,
    required this.accent,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
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
            child: Icon(Icons.bolt_rounded, color: accent, size: 20),
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
                    Text(
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
                      child: Text(
                        difficulty,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
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
                Text(
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
                Text(
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

class _LevelCard extends StatelessWidget {
  final String gameId;
  final ParkurLevelSpec level;
  final Color accent;
  final bool unlocked;
  final int stars;
  final int bestScore;
  final int commonPoints;
  final bool english;
  final bool prominent;
  final VoidCallback onTap;

  const _LevelCard({
    required this.gameId,
    required this.level,
    required this.accent,
    required this.unlocked,
    required this.stars,
    required this.bestScore,
    this.commonPoints = 0,
    required this.english,
    required this.prominent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color shownAccent = unlocked ? accent : Colors.blueGrey;
    if (prominent) {
      return _buildProminentCard(context, shownAccent);
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: unlocked ? onTap : null,
        borderRadius: StudioVisuals.cardRadius,
        child: Ink(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: StudioVisuals.surface,
            borderRadius: StudioVisuals.cardRadius,
            border: Border.all(color: StudioVisuals.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: shownAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      unlocked ? level.icon : Icons.lock_rounded,
                      color: shownAccent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: shownAccent.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          context.l10n.gameUi(level.difficulty),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            color: shownAccent,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${level.number}. ${context.l10n.gameUi(level.title(english))}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  color: unlocked ? StudioVisuals.ink : StudioVisuals.muted,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  context.l10n.gameUi(
                    unlocked
                        ? level.subtitle(english)
                        : english
                        ? 'Complete the previous level.'
                        : 'Önceki bölümü tamamla.',
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: StudioVisuals.muted,
                    fontSize: 10,
                    height: 1.25,
                  ),
                ),
              ),
              if (unlocked)
                Row(
                  children: <Widget>[
                    for (int index = 0; index < 3; index++)
                      Icon(
                        index < stars
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: index < stars
                            ? const Color(0xFFFFD334)
                            : StudioVisuals.line,
                        size: 18,
                      ),
                    const Spacer(),
                    if (commonPoints > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: StudioVisuals.tealSoft,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '+$commonPoints ZP',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            color: StudioVisuals.tealInk,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      )
                    else if (bestScore > 0)
                      Text(
                        '$bestScore',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          color: StudioVisuals.ink,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProminentCard(BuildContext context, Color shownAccent) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: unlocked ? onTap : null,
        borderRadius: StudioVisuals.cardRadius,
        child: Ink(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: StudioVisuals.surface,
            borderRadius: StudioVisuals.cardRadius,
            border: Border.all(color: StudioVisuals.line),
            boxShadow: StudioVisuals.softShadow,
          ),
          child: Row(
            children: <Widget>[
              Container(
                key: ValueKey<String>('parkur_level_art_${level.number}'),
                width: MediaQuery.sizeOf(context).width < 360 ? 60 : 68,
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      shownAccent.withValues(alpha: unlocked ? .20 : .12),
                      shownAccent.withValues(alpha: .07),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: shownAccent.withValues(alpha: .20)),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: shownAccent.withValues(alpha: .10),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: StudioGameArtwork(
                  gameId: gameId,
                  variant: level.number,
                  locked: !unlocked,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: shownAccent.withValues(alpha: .10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          context.l10n.gameUi(level.difficulty),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            color: shownAccent,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${level.number}. ${context.l10n.gameUi(level.title(english))}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: unlocked
                            ? StudioVisuals.ink
                            : StudioVisuals.muted,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      context.l10n.gameUi(
                        unlocked
                            ? level.subtitle(english)
                            : english
                            ? 'Complete the previous level.'
                            : 'Önceki bölümü tamamla.',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        color: StudioVisuals.muted,
                        fontSize: 11,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Row(
                      children: <Widget>[
                        for (int star = 0; star < 3; star++)
                          Padding(
                            padding: const EdgeInsets.only(right: 2),
                            child: Icon(
                              star < stars
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 15,
                              color: star < stars
                                  ? StudioVisuals.amberInk
                                  : StudioVisuals.line,
                            ),
                          ),
                        const Spacer(),
                        if (commonPoints > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: StudioVisuals.tealSoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '+$commonPoints ZP',
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                color: StudioVisuals.tealInk,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          )
                        else if (bestScore > 0)
                          Text(
                            '$bestScore',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              color: StudioVisuals.ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum ParkurResultAction { replay, map, next }

Future<ParkurResultAction?> showParkurResultDialog({
  required BuildContext context,
  required Color accent,
  required String titleTr,
  required String titleEn,
  required String detailTr,
  required String detailEn,
  required int stars,
  required int score,
  required int previousBestScore,
  required bool canGoNext,
}) {
  final bool english = context.l10n.isEnglish;
  final bool newRecord = score > previousBestScore;

  return showDialog<ParkurResultAction>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 22),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(21),
            decoration: BoxDecoration(
              color: StudioVisuals.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: StudioVisuals.line),
              boxShadow: StudioVisuals.softShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (newRecord)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: StudioVisuals.amberSoft,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      context.l10n.gameUi(
                        english ? 'NEW RECORD' : 'YENİ REKOR',
                      ),
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        color: Color(0xFF4E3500),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                if (newRecord) const SizedBox(height: 10),
                Text(
                  context.l10n.gameUi(english ? titleEn : titleTr),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: StudioVisuals.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  context.l10n.gameUi(english ? detailEn : detailTr),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: StudioVisuals.muted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    for (int index = 0; index < 3; index++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Icon(
                          index < stars
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: index < stars
                              ? StudioVisuals.amberInk
                              : StudioVisuals.line,
                          size: 38,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Builder(
                  builder: (BuildContext context) {
                    final int earnedZp = CommonLevelScoreSession.isActive
                        ? CommonLevelScoreSession.activePoints
                        : (stars == 3 ? 10 : (stars == 2 ? 8 : (stars >= 1 ? 6 : 0)));
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: StudioVisuals.tealSoft,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: StudioVisuals.teal.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Text(
                        '+$earnedZp ZP',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          color: StudioVisuals.tealInk,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    );
                  },
                ),
                if (score > 0) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    '$score ${context.l10n.gameUi(english ? 'POINTS' : 'PUAN')}',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: StudioVisuals.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 17),
                StudioGameActions(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(
                          dialogContext,
                          ParkurResultAction.replay,
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                          minimumSize: const Size(48, 48),
                          textStyle: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 14,
                          ),
                        ),
                        icon: const Icon(Icons.autorenew_rounded),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            context.l10n.gameUi(
                              english ? 'NEW ROUND' : 'YENİ TUR',
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(
                          dialogContext,
                          canGoNext
                              ? ParkurResultAction.next
                              : ParkurResultAction.map,
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                          minimumSize: const Size(48, 48),
                          textStyle: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 14,
                          ),
                        ),
                        icon: Icon(
                          canGoNext
                              ? Icons.arrow_forward_rounded
                              : Icons.map_rounded,
                        ),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            context.l10n.gameUi(
                              canGoNext
                                  ? english
                                        ? 'NEXT'
                                        : 'SONRAKİ'
                                  : english
                                  ? 'MAP'
                                  : 'HARİTA',
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
