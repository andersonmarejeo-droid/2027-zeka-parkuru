import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'app_analytics_service.dart';
import 'zeka_scoring_service.dart';

enum DailyTaskType {
  completeLevels,
  earnStars,
  playDifferentGames,
  earnScore,
  playSpecificGame,
  threeStarLevel,
}

class DailyTaskDefinition {
  final String id;
  final String title;
  final String description;
  final DailyTaskType type;
  final int target;
  final String? gameId;

  const DailyTaskDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.target,
    this.gameId,
  });
}

class DailyTaskProgress {
  final DailyTaskDefinition task;
  final int current;

  const DailyTaskProgress({
    required this.task,
    required this.current,
  });

  int get shownCurrent => current > task.target ? task.target : current;

  bool get completed => current >= task.target;

  double get ratio {
    if (task.target <= 0) return 1.0;
    return (current / task.target).clamp(0.0, 1.0).toDouble();
  }
}

class DailyChallengeData {
  final String dateKey;
  final int currentStreak;
  final int bestStreak;
  final int perfectDays;
  final bool activeToday;

  final int levelsCompleted;
  final int starsEarned;
  final int scoreEarned;
  final int threeStarLevels;
  final Set<String> uniqueGames;
  final Map<String, int> gameCounts;

  final List<DailyTaskProgress> tasks;

  const DailyChallengeData({
    required this.dateKey,
    required this.currentStreak,
    required this.bestStreak,
    required this.perfectDays,
    required this.activeToday,
    required this.levelsCompleted,
    required this.starsEarned,
    required this.scoreEarned,
    required this.threeStarLevels,
    required this.uniqueGames,
    required this.gameCounts,
    required this.tasks,
  });

  int get completedTaskCount =>
      tasks.where((task) => task.completed).length;

  bool get allTasksCompleted =>
      tasks.isNotEmpty && completedTaskCount == tasks.length;
}

class DailyRecordResult {
  final DailyChallengeData data;
  final int newlyCompletedTasks;
  final bool streakAdvanced;
  final bool perfectDayCompleted;

  const DailyRecordResult({
    required this.data,
    required this.newlyCompletedTasks,
    required this.streakAdvanced,
    required this.perfectDayCompleted,
  });
}

class DailyChallengeService {
  DailyChallengeService._();

  static final DailyChallengeService instance =
      DailyChallengeService._();

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  static const List<String> _gameIds = <String>[
    'logic',
    'numbers',
    'blocks',
    'memory',
    'hanoi',
    'word_hunt',
    'picture_iq',
    'candy_sort',
    'number_sort',
    'shape_puzzle',
    'reflex',
  ];

  static const Map<String, String> gameLabels = <String, String>{
    'logic': 'Mantık Labirenti',
    'numbers': 'Sayı Ustası',
    'blocks': 'Blok Fırtınası',
    'memory': 'Hafıza Labirenti',
    'hanoi': 'Hanoi Kulesi',
    'word_hunt': 'Kelime Avı',
    'picture_iq': 'Görsel IQ',
    'candy_sort': 'Şeker Sıralama',
    'number_sort': 'Sayı Peteği',
    'shape_puzzle': 'Şekil Birleştir',
    'reflex': 'Refleks Avı',
  };

  static const String _dailyDateKey = 'daily_v1_date';
  static const String _dailyLevelsKey = 'daily_v1_levels';
  static const String _dailyStarsKey = 'daily_v1_stars';
  static const String _dailyScoreKey = 'daily_v2_brain_score';
  static const String _dailyThreeStarsKey = 'daily_v1_three_stars';
  static const String _dailyGamesKey = 'daily_v1_unique_games';
  static const String _dailyPerfectRecordedKey =
      'daily_v1_perfect_recorded';

  static const String _streakCurrentKey = 'daily_v1_streak_current';
  static const String _streakBestKey = 'daily_v1_streak_best';
  static const String _streakLastDateKey = 'daily_v1_streak_last_date';
  static const String _perfectDaysKey = 'daily_v1_perfect_days';

  Future<DailyChallengeData> loadToday() async {
    final DateTime now = DateTime.now();
    await _ensureToday(now);
    await _normalizeExpiredStreak(now);

    return _buildData(now);
  }

  Future<DailyRecordResult> recordLevelCompleted({
    required String gameId,
    required int stars,
    required int score,
  }) async {
    if (!_gameIds.contains(gameId)) {
      return DailyRecordResult(
        data: await loadToday(),
        newlyCompletedTasks: 0,
        streakAdvanced: false,
        perfectDayCompleted: false,
      );
    }

    final DateTime now = DateTime.now();
    await _ensureToday(now);
    await _normalizeExpiredStreak(now);

    final DailyChallengeData before = await _buildData(now);
    final Set<String> beforeCompleted = before.tasks
        .where((task) => task.completed)
        .map((task) => task.task.id)
        .toSet();

    final String today = _dateKey(now);
    final String yesterday =
        _dateKey(now.subtract(const Duration(days: 1)));

    final String? lastActive =
        await _prefs.getString(_streakLastDateKey);

    bool streakAdvanced = false;

    if (lastActive != today) {
      final int current =
          await _prefs.getInt(_streakCurrentKey) ?? 0;

      final int next =
          lastActive == yesterday ? (current <= 0 ? 1 : current + 1) : 1;

      final int oldBest =
          await _prefs.getInt(_streakBestKey) ?? 0;

      await _prefs.setInt(_streakCurrentKey, next);
      await _prefs.setInt(
        _streakBestKey,
        next > oldBest ? next : oldBest,
      );
      await _prefs.setString(_streakLastDateKey, today);
      streakAdvanced = true;
    }

    final int oldLevels =
        await _prefs.getInt(_dailyLevelsKey) ?? 0;
    final int oldStars =
        await _prefs.getInt(_dailyStarsKey) ?? 0;
    final int oldScore =
        await _prefs.getInt(_dailyScoreKey) ?? 0;
    final int oldThreeStars =
        await _prefs.getInt(_dailyThreeStarsKey) ?? 0;

    await _prefs.setInt(_dailyLevelsKey, oldLevels + 1);
    await _prefs.setInt(
      _dailyStarsKey,
      oldStars + stars.clamp(0, 3).toInt(),
    );
    await _prefs.setInt(
      _dailyScoreKey,
      oldScore + ZekaScoringService.dailyResultPoints(stars),
    );

    if (stars >= 3) {
      await _prefs.setInt(
        _dailyThreeStarsKey,
        oldThreeStars + 1,
      );
    }

    final List<String> uniqueGames =
        List<String>.from(
          await _prefs.getStringList(_dailyGamesKey) ??
              const <String>[],
        );

    if (!uniqueGames.contains(gameId)) {
      uniqueGames.add(gameId);
      await _prefs.setStringList(_dailyGamesKey, uniqueGames);
    }

    final String gameCountKey = _gameCountKey(gameId);
    final int oldGameCount =
        await _prefs.getInt(gameCountKey) ?? 0;

    await _prefs.setInt(gameCountKey, oldGameCount + 1);

    DailyChallengeData after = await _buildData(now);

    final int newlyCompleted = after.tasks
        .where(
          (task) =>
              task.completed &&
              !beforeCompleted.contains(task.task.id),
        )
        .length;

    bool perfectDayCompleted = false;
    final bool perfectAlreadyRecorded =
        await _prefs.getBool(_dailyPerfectRecordedKey) ?? false;

    if (after.allTasksCompleted && !perfectAlreadyRecorded) {
      final int oldPerfectDays =
          await _prefs.getInt(_perfectDaysKey) ?? 0;

      await _prefs.setInt(_perfectDaysKey, oldPerfectDays + 1);
      await _prefs.setBool(_dailyPerfectRecordedKey, true);
      perfectDayCompleted = true;
      after = await _buildData(now);
    }

    await AppAnalyticsService.instance.logLevelComplete(
      gameId: gameId,
      stars: stars.clamp(0, 3).toInt(),
      score: score < 0 ? 0 : score,
      dailyTasksCompleted: after.completedTaskCount,
      streak: after.currentStreak,
    );

    return DailyRecordResult(
      data: after,
      newlyCompletedTasks: newlyCompleted,
      streakAdvanced: streakAdvanced,
      perfectDayCompleted: perfectDayCompleted,
    );
  }

  Future<void> _ensureToday(DateTime now) async {
    final String today = _dateKey(now);
    final String? savedDate =
        await _prefs.getString(_dailyDateKey);

    if (savedDate == today) return;

    await _prefs.setString(_dailyDateKey, today);
    await _prefs.setInt(_dailyLevelsKey, 0);
    await _prefs.setInt(_dailyStarsKey, 0);
    await _prefs.setInt(_dailyScoreKey, 0);
    await _prefs.setInt(_dailyThreeStarsKey, 0);
    await _prefs.setStringList(
      _dailyGamesKey,
      const <String>[],
    );
    await _prefs.setBool(_dailyPerfectRecordedKey, false);

    for (final String gameId in _gameIds) {
      await _prefs.setInt(_gameCountKey(gameId), 0);
    }
  }

  Future<void> _normalizeExpiredStreak(DateTime now) async {
    final String? lastActive =
        await _prefs.getString(_streakLastDateKey);

    if (lastActive == null) return;

    final String today = _dateKey(now);
    final String yesterday =
        _dateKey(now.subtract(const Duration(days: 1)));

    if (lastActive != today && lastActive != yesterday) {
      await _prefs.setInt(_streakCurrentKey, 0);
    }
  }

  Future<DailyChallengeData> _buildData(DateTime now) async {
    final String today = _dateKey(now);

    final int levels =
        await _prefs.getInt(_dailyLevelsKey) ?? 0;
    final int stars =
        await _prefs.getInt(_dailyStarsKey) ?? 0;
    final int? storedScore = await _prefs.getInt(_dailyScoreKey);
    final int score;
    if (storedScore == null) {
      score =
          (levels * ZekaScoringService.dailyCompletionBasePoints) +
          (stars * ZekaScoringService.dailyStarPoints);
      await _prefs.setInt(_dailyScoreKey, score);
    } else {
      score = storedScore;
    }
    final int threeStars =
        await _prefs.getInt(_dailyThreeStarsKey) ?? 0;

    final Set<String> uniqueGames =
        (await _prefs.getStringList(_dailyGamesKey) ??
                const <String>[])
            .where(_gameIds.contains)
            .toSet();

    final Map<String, int> gameCounts = <String, int>{};

    for (final String gameId in _gameIds) {
      gameCounts[gameId] =
          await _prefs.getInt(_gameCountKey(gameId)) ?? 0;
    }

    final int currentStreak =
        await _prefs.getInt(_streakCurrentKey) ?? 0;
    final int bestStreak =
        await _prefs.getInt(_streakBestKey) ?? 0;
    final int perfectDays =
        await _prefs.getInt(_perfectDaysKey) ?? 0;

    final String? lastActive =
        await _prefs.getString(_streakLastDateKey);

    final List<DailyTaskDefinition> definitions =
        _tasksForDate(now);

    final List<DailyTaskProgress> tasks =
        definitions.map((task) {
      int current = 0;

      switch (task.type) {
        case DailyTaskType.completeLevels:
          current = levels;
          break;
        case DailyTaskType.earnStars:
          current = stars;
          break;
        case DailyTaskType.playDifferentGames:
          current = uniqueGames.length;
          break;
        case DailyTaskType.earnScore:
          current = score;
          break;
        case DailyTaskType.playSpecificGame:
          current = gameCounts[task.gameId] ?? 0;
          break;
        case DailyTaskType.threeStarLevel:
          current = threeStars;
          break;
      }

      return DailyTaskProgress(
        task: task,
        current: current,
      );
    }).toList(growable: false);

    return DailyChallengeData(
      dateKey: today,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      perfectDays: perfectDays,
      activeToday: lastActive == today,
      levelsCompleted: levels,
      starsEarned: stars,
      scoreEarned: score,
      threeStarLevels: threeStars,
      uniqueGames: uniqueGames,
      gameCounts: gameCounts,
      tasks: tasks,
    );
  }

  List<DailyTaskDefinition> _tasksForDate(DateTime date) {
    final int seed =
        date.year * 372 + date.month * 31 + date.day;

    final List<DailyTaskDefinition> tasks =
        <DailyTaskDefinition>[
      const DailyTaskDefinition(
        id: 'complete_2',
        title: 'Isınma Turu',
        description: 'Bugün 2 bölüm tamamla.',
        type: DailyTaskType.completeLevels,
        target: 2,
      ),
      const DailyTaskDefinition(
        id: 'earn_5_stars',
        title: 'Yıldız Avcısı',
        description: 'Tamamladığın bölümlerden toplam 5 yıldız kazan.',
        type: DailyTaskType.earnStars,
        target: 5,
      ),
    ];

    switch (seed % 4) {
      case 0:
        tasks.add(
          const DailyTaskDefinition(
            id: 'different_2',
            title: 'Parkur Gezgini',
            description: '2 farklı zeka parkurunda bölüm tamamla.',
            type: DailyTaskType.playDifferentGames,
            target: 2,
          ),
        );
        break;
      case 1:
        tasks.add(
          const DailyTaskDefinition(
            id: 'score_700',
            title: 'Puan Hamlesi',
            description: 'Bugünkü bölümlerden toplam 700 Zeka Puanı kazan.',
            type: DailyTaskType.earnScore,
            target: 700,
          ),
        );
        break;
      case 2:
        tasks.add(
          const DailyTaskDefinition(
            id: 'three_star_1',
            title: 'Kusursuz Tur',
            description: 'Bir bölümü 3 yıldızla tamamla.',
            type: DailyTaskType.threeStarLevel,
            target: 1,
          ),
        );
        break;
      default:
        final List<String> shuffledGames = List<String>.from(_gameIds)
          ..shuffle(Random(seed * 97 + 41));
        final String gameId = shuffledGames.first;

        tasks.add(
          DailyTaskDefinition(
            id: 'specific_$gameId',
            title: 'Günün Parkuru',
            description:
                '${gameLabels[gameId]} bölümünü en az 1 kez tamamla.',
            type: DailyTaskType.playSpecificGame,
            target: 1,
            gameId: gameId,
          ),
        );
    }

    return tasks;
  }

  String _gameCountKey(String gameId) =>
      'daily_v1_game_count_$gameId';

  String _dateKey(DateTime date) {
    final String month =
        date.month.toString().padLeft(2, '0');
    final String day =
        date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }
}
