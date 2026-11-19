import 'daily_challenge_service.dart';
import 'daily_course_service.dart';
import 'player_profile_service.dart';
import 'unified_progress_service.dart';
import 'zeka_scoring_service.dart';
import '../features/catalog/domain/studio_game_catalog.dart';
import '../games/shared/studio_game_contracts.dart';

class PlayerLeagueData {
  final String name;
  final String shortName;
  final int minXp;
  final int? nextMinXp;

  const PlayerLeagueData({
    required this.name,
    required this.shortName,
    required this.minXp,
    required this.nextMinXp,
  });
}

class ParkurLeaderboardEntry {
  final String gameId;
  final String name;
  final int stars;
  final int score;
  final int completedLevels;
  final int unlockedLevel;

  const ParkurLeaderboardEntry({
    required this.gameId,
    required this.name,
    required this.stars,
    required this.score,
    required this.completedLevels,
    required this.unlockedLevel,
  });
}

class PlayerAchievementData {
  final String id;
  final String title;
  final String description;
  final String? titleEn;
  final String? descriptionEn;
  final String emoji;
  final int current;
  final int target;
  final bool unlocked;
  final bool special;

  const PlayerAchievementData({
    required this.id,
    required this.title,
    required this.description,
    this.titleEn,
    this.descriptionEn,
    required this.emoji,
    required this.current,
    required this.target,
    required this.unlocked,
    this.special = false,
  });

  double get progress {
    if (target <= 0) return 1.0;
    return (current / target).clamp(0.0, 1.0).toDouble();
  }
}

class PlayerDashboardData {
  final PlayerProfileData profile;
  final UnifiedProgressData progress;
  final DailyChallengeData daily;

  final int zekaScore;
  final ZekaScoreBreakdown scoreBreakdown;
  final int level;
  final int xpIntoLevel;
  final int xpForNextLevel;
  final String rankTitle;

  final PlayerLeagueData league;
  final PlayerLeagueData? nextLeague;
  final double leagueProgress;

  final int threeStarLevels;
  final int playedGameCount;
  final int bossCount;
  final int completedDailyCourses;

  final List<ParkurLeaderboardEntry> parkurRanking;
  final List<PlayerAchievementData> achievements;

  const PlayerDashboardData({
    required this.profile,
    required this.progress,
    required this.daily,
    required this.zekaScore,
    required this.scoreBreakdown,
    required this.level,
    required this.xpIntoLevel,
    required this.xpForNextLevel,
    required this.rankTitle,
    required this.league,
    required this.nextLeague,
    required this.leagueProgress,
    required this.threeStarLevels,
    required this.playedGameCount,
    required this.bossCount,
    required this.completedDailyCourses,
    required this.parkurRanking,
    required this.achievements,
  });

  // Eski ekranlarla geriye uyumluluk. V7.2'de XP ve resmi puan aynı
  // merkezi Zeka Puanı değeridir.
  int get xp => zekaScore;

  int get unlockedAchievementCount =>
      achievements.where((item) => item.unlocked).length;

  List<PlayerAchievementData> get regularAchievements =>
      achievements.where((item) => !item.special).toList(growable: false);

  List<PlayerAchievementData> get specialAchievements =>
      achievements.where((item) => item.special).toList(growable: false);

  int get unlockedRegularAchievementCount =>
      regularAchievements.where((item) => item.unlocked).length;

  int get unlockedSpecialAchievementCount =>
      specialAchievements.where((item) => item.unlocked).length;
}

class PlayerProgressService {
  PlayerProgressService._();

  static final PlayerProgressService instance = PlayerProgressService._();

  final UnifiedProgressService _progress = UnifiedProgressService();

  final DailyChallengeService _daily = DailyChallengeService.instance;

  final DailyCourseService _dailyCourse = DailyCourseService.instance;

  final PlayerProfileService _profile = PlayerProfileService.instance;

  static const int _maximumPlayerLevel = 50;

  static const List<PlayerLeagueData> _leagues = <PlayerLeagueData>[
    PlayerLeagueData(
      name: 'Başlangıç Ligi',
      shortName: 'BAŞLANGIÇ',
      minXp: 0,
      nextMinXp: 1500,
    ),
    PlayerLeagueData(
      name: 'Bronz Lig',
      shortName: 'BRONZ',
      minXp: 1500,
      nextMinXp: 3500,
    ),
    PlayerLeagueData(
      name: 'Gümüş Lig',
      shortName: 'GÜMÜŞ',
      minXp: 3500,
      nextMinXp: 6500,
    ),
    PlayerLeagueData(
      name: 'Altın Lig',
      shortName: 'ALTIN',
      minXp: 6500,
      nextMinXp: 10000,
    ),
    PlayerLeagueData(
      name: 'Platin Lig',
      shortName: 'PLATİN',
      minXp: 10000,
      nextMinXp: 14500,
    ),
    PlayerLeagueData(
      name: 'Elmas Lig',
      shortName: 'ELMAS',
      minXp: 14500,
      nextMinXp: 19000,
    ),
    PlayerLeagueData(
      name: 'Usta Ligi',
      shortName: 'USTA',
      minXp: 19000,
      nextMinXp: 24000,
    ),
    PlayerLeagueData(
      name: 'Efsane Ligi',
      shortName: 'EFSANE',
      minXp: 24000,
      nextMinXp: null,
    ),
  ];

  Future<PlayerDashboardData> load() async {
    final UnifiedProgressData progress = await _progress.genelIlerlemeyiYukle();

    final DailyChallengeData daily = await _daily.loadToday();

    final PlayerProfileData profile = await _profile.load();

    final int completedDailyCourses = await _dailyCourse
        .loadLifetimeCompletedCount();

    final int threeStarLevels = progress.parkurlar.fold<int>(
      0,
      (total, parkur) =>
          total + parkur.yildizlar.where((star) => star >= 3).length,
    );

    final int playedGameCount = progress.parkurlar
        .where((parkur) => parkur.tamamlananSeviye > 0)
        .length;

    final int bossCount = progress.parkurlar
        .where(
          (parkur) => parkur.yildizlar.length >= 10 && parkur.yildizlar[9] > 0,
        )
        .length;

    final ZekaScoreBreakdown scoreBreakdown = ZekaScoringService.calculate(
      progress: progress,
    );
    final int xp = scoreBreakdown.total;

    final int level = levelForScore(xp);
    final int levelStart = scoreForLevel(level);
    final int xpIntoLevel = xp - levelStart;
    final int xpForNextLevel = level >= _maximumPlayerLevel
        ? 0
        : scoreForLevel(level + 1) - levelStart;

    final String rankTitle = _rankTitle(level);

    final int leagueIndex = _leagueIndexForXp(xp);
    final PlayerLeagueData league = _leagues[leagueIndex];

    final PlayerLeagueData? nextLeague = leagueIndex + 1 < _leagues.length
        ? _leagues[leagueIndex + 1]
        : null;

    final double leagueProgress = _leagueProgress(xp, league, nextLeague);

    final List<ParkurLeaderboardEntry> ranking = _buildParkurRanking(progress);

    final List<PlayerAchievementData> achievements = _buildAchievements(
      progress: progress,
    );

    return PlayerDashboardData(
      profile: profile,
      progress: progress,
      daily: daily,
      zekaScore: xp,
      scoreBreakdown: scoreBreakdown,
      level: level,
      xpIntoLevel: xpIntoLevel,
      xpForNextLevel: xpForNextLevel,
      rankTitle: rankTitle,
      league: league,
      nextLeague: nextLeague,
      leagueProgress: leagueProgress,
      threeStarLevels: threeStarLevels,
      playedGameCount: playedGameCount,
      bossCount: bossCount,
      completedDailyCourses: completedDailyCourses,
      parkurRanking: ranking,
      achievements: achievements,
    );
  }

  /// Required common points to reach a player level. The increment grows by
  /// 25 points each level, so level 13 needs 3,450 points and level 15 needs
  /// 4,375; hints therefore make higher levels meaningfully harder to reach.
  static int scoreForLevel(int level) {
    if (level <= 1) return 0;
    final int steps = level - 1;
    return (steps * 150) + ((steps * (steps - 1) ~/ 2) * 25);
  }

  static int levelForScore(int score) {
    int level = 1;
    while (level < _maximumPlayerLevel && score >= scoreForLevel(level + 1)) {
      level++;
    }
    return level;
  }

  String _rankTitle(int level) {
    if (level >= 40) return 'ZEKA EFSANESİ';
    if (level >= 30) return 'PARKUR ŞAMPİYONU';
    if (level >= 20) return 'ZEKA USTASI';
    if (level >= 15) return 'UZMAN';
    if (level >= 10) return 'STRATEJİST';
    if (level >= 5) return 'KAŞİF';
    return 'ZEKA ÇIRAĞI';
  }

  int _leagueIndexForXp(int xp) {
    int index = 0;

    for (int i = 0; i < _leagues.length; i++) {
      if (xp >= _leagues[i].minXp) {
        index = i;
      }
    }

    return index;
  }

  double _leagueProgress(
    int xp,
    PlayerLeagueData current,
    PlayerLeagueData? next,
  ) {
    if (next == null) return 1.0;

    final int range = next.minXp - current.minXp;
    if (range <= 0) return 1.0;

    return ((xp - current.minXp) / range).clamp(0.0, 1.0).toDouble();
  }

  List<ParkurLeaderboardEntry> _buildParkurRanking(
    UnifiedProgressData progress,
  ) {
    final List<ParkurLeaderboardEntry> items = <ParkurLeaderboardEntry>[
      _entry('logic', 'Mantık Labirenti', progress.mantik),
      _entry('numbers', 'Sayı Ustası', progress.sayi),
      _entry('blocks', 'Blok Fırtınası', progress.blok),
      _entry('memory', 'Hafıza Labirenti', progress.hafiza),
      _entry('hanoi', 'Hanoi Kulesi', progress.hanoi),
      _entry('word_hunt', 'Kelime Avı', progress.kelimeAvi),
      _entry('candy_sort', 'Şeker Sıralama', progress.sekerSiralama),
      _entry('number_sort', '15 Taş Ustası', progress.sayiPetegi),
      _entry('shape_puzzle', 'Şekil Birleştir', progress.sekilBirlestir),
      _entry('reflex', 'Refleks Avı', progress.refleks),
    ];

    items.sort((a, b) {
      final int scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;

      return b.stars.compareTo(a.stars);
    });

    return items;
  }

  ParkurLeaderboardEntry _entry(
    String id,
    String name,
    ParkurProgressData data,
  ) {
    return ParkurLeaderboardEntry(
      gameId: id,
      name: name,
      stars: data.toplamYildiz,
      score: ZekaScoringService.courseScore(data),
      completedLevels: data.tamamlananSeviye,
      unlockedLevel: data.acikSeviye,
    );
  }

  List<PlayerAchievementData> _buildAchievements({
    required UnifiedProgressData progress,
  }) {
    const Map<StudioGameClass, String> emoji = <StudioGameClass, String>{
      StudioGameClass.logic: '🧩',
      StudioGameClass.numbers: '🔢',
      StudioGameClass.visual: '🧭',
      StudioGameClass.memory: '🧠',
      StudioGameClass.strategy: '♟️',
      StudioGameClass.language: '📚',
      StudioGameClass.speed: '⚡',
      StudioGameClass.fun: '🎮',
    };
    return StudioGameClass.values
        .map((StudioGameClass category) {
          final Set<String> categoryGameIds = StudioGameCatalog.games
              .where(
                (game) =>
                    game.gameClass == category &&
                    GameContentPolicy.standardGames.contains(game.id) &&
                    !game.isRetired,
              )
              .map((game) => game.id)
              .toSet();
          final int completed = categoryGameIds.fold<int>(
            0,
            (total, gameId) =>
                total +
                (progress.gameProgressById[gameId]?.tamamlananSeviye ?? 0),
          );
          return PlayerAchievementData(
            id: 'category_${category.name}',
            title: category.title(english: false),
            titleEn: category.title(english: true),
            description: 'Bu oyun grubunda 30 bölüm tamamla.',
            descriptionEn: 'Complete 30 levels in this game group.',
            emoji: emoji[category] ?? '🏅',
            current: completed,
            target: 30,
            unlocked: completed >= 30,
          );
        })
        .toList(growable: false);
  }
}
