import 'daily_challenge_service.dart';
import 'daily_course_service.dart';
import 'player_profile_service.dart';
import 'unified_progress_service.dart';
import 'zeka_scoring_service.dart';

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
  final String emoji;
  final int current;
  final int target;
  final bool unlocked;
  final bool special;

  const PlayerAchievementData({
    required this.id,
    required this.title,
    required this.description,
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

  int get unlockedRegularAchievementCount => regularAchievements
      .where((item) => item.unlocked)
      .length;

  int get unlockedSpecialAchievementCount => specialAchievements
      .where((item) => item.unlocked)
      .length;
}

class PlayerProgressService {
  PlayerProgressService._();

  static final PlayerProgressService instance =
      PlayerProgressService._();

  final UnifiedProgressService _progress =
      UnifiedProgressService();

  final DailyChallengeService _daily =
      DailyChallengeService.instance;

  final DailyCourseService _dailyCourse =
      DailyCourseService.instance;

  final PlayerProfileService _profile =
      PlayerProfileService.instance;

  static const int _xpPerLevel = 550;

  static const List<PlayerLeagueData> _leagues =
      <PlayerLeagueData>[
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
    final UnifiedProgressData progress =
        await _progress.genelIlerlemeyiYukle();

    final DailyChallengeData daily =
        await _daily.loadToday();

    final PlayerProfileData profile =
        await _profile.load();

    final int completedDailyCourses =
        await _dailyCourse.loadLifetimeCompletedCount();

    final int threeStarLevels = progress.parkurlar.fold<int>(
      0,
      (total, parkur) =>
          total + parkur.yildizlar.where((star) => star >= 3).length,
    );

    final int playedGameCount = progress.parkurlar
        .where((parkur) => parkur.tamamlananSeviye > 0)
        .length;

    final int bossCount = progress.parkurlar.where(
      (parkur) =>
          parkur.yildizlar.length >= 10 &&
          parkur.yildizlar[9] > 0,
    ).length;

    final ZekaScoreBreakdown scoreBreakdown =
        ZekaScoringService.calculate(
      progress: progress,
      completedDailyCourses: completedDailyCourses,
      bestStreak: daily.bestStreak,
      perfectDays: daily.perfectDays,
    );
    final int xp = scoreBreakdown.total;

    final int level =
        (1 + (xp ~/ _xpPerLevel)).clamp(1, 50).toInt();

    final int xpIntoLevel =
        level >= 50 ? _xpPerLevel : xp % _xpPerLevel;

    final String rankTitle = _rankTitle(level);

    final int leagueIndex = _leagueIndexForXp(xp);
    final PlayerLeagueData league = _leagues[leagueIndex];

    final PlayerLeagueData? nextLeague =
        leagueIndex + 1 < _leagues.length
            ? _leagues[leagueIndex + 1]
            : null;

    final double leagueProgress =
        _leagueProgress(xp, league, nextLeague);

    final List<ParkurLeaderboardEntry> ranking =
        _buildParkurRanking(progress);

    final List<PlayerAchievementData> achievements =
        _buildAchievements(
      progress: progress,
      daily: daily,
      zekaScore: xp,
      threeStarLevels: threeStarLevels,
      playedGameCount: playedGameCount,
      bossCount: bossCount,
      completedDailyCourses: completedDailyCourses,
    );

    return PlayerDashboardData(
      profile: profile,
      progress: progress,
      daily: daily,
      zekaScore: xp,
      scoreBreakdown: scoreBreakdown,
      level: level,
      xpIntoLevel: xpIntoLevel,
      xpForNextLevel: _xpPerLevel,
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

    return ((xp - current.minXp) / range)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  List<ParkurLeaderboardEntry> _buildParkurRanking(
    UnifiedProgressData progress,
  ) {
    final List<ParkurLeaderboardEntry> items =
        <ParkurLeaderboardEntry>[
      _entry('logic', 'Mantık Labirenti', progress.mantik),
      _entry('numbers', 'Sayı Ustası', progress.sayi),
      _entry('blocks', 'Blok Fırtınası', progress.blok),
      _entry('memory', 'Hafıza Labirenti', progress.hafiza),
      _entry('hanoi', 'Hanoi Kulesi', progress.hanoi),
      _entry('word_hunt', 'Kelime Avı', progress.kelimeAvi),
      _entry('picture_iq', 'Görsel IQ', progress.gorselIq),
      _entry('candy_sort', 'Şeker Sıralama', progress.sekerSiralama),
      _entry('number_sort', 'Sayı Peteği', progress.sayiPetegi),
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
    required DailyChallengeData daily,
    required int zekaScore,
    required int threeStarLevels,
    required int playedGameCount,
    required int bossCount,
    required int completedDailyCourses,
  }) {
    final List<PlayerAchievementData> result =
        <PlayerAchievementData>[];

    void add({
      required String id,
      required String title,
      required String description,
      required String emoji,
      required int current,
      required int target,
      bool special = false,
    }) {
      result.add(
        PlayerAchievementData(
          id: id,
          title: title,
          description: description,
          emoji: emoji,
          current: current,
          target: target,
          unlocked: current >= target,
          special: special,
        ),
      );
    }

    add(
      id: 'first_step',
      title: 'İlk Adım',
      description: 'İlk bölümünü tamamla.',
      emoji: '👣',
      current: progress.tamamlananSeviye,
      target: 1,
    );
    add(
      id: 'stars_10',
      title: 'Yıldız Toplayıcı',
      description: 'Toplam 10 yıldız kazan.',
      emoji: '⭐',
      current: progress.toplamYildiz,
      target: 10,
    );
    add(
      id: 'stars_30',
      title: 'Yıldız Avcısı',
      description: 'Toplam 30 yıldız kazan.',
      emoji: '🌟',
      current: progress.toplamYildiz,
      target: 30,
    );
    add(
      id: 'stars_75',
      title: 'Parlayan Zihin',
      description: 'Toplam 75 yıldız kazan.',
      emoji: '✨',
      current: progress.toplamYildiz,
      target: 75,
    );
    add(
      id: 'stars_150',
      title: 'Yıldız Efsanesi',
      description: 'Toplam 150 yıldız kazan.',
      emoji: '👑',
      current: progress.toplamYildiz,
      target: 150,
    );
    add(
      id: 'stars_225',
      title: 'Galaksi Avcısı',
      description: 'Toplam 225 yıldız kazan.',
      emoji: '🌠',
      current: progress.toplamYildiz,
      target: 225,
    );
    add(
      id: 'stars_330',
      title: 'Kusursuz On Birli',
      description: '330 yıldızın tamamını kazan.',
      emoji: '🌌',
      current: progress.toplamYildiz,
      target: 330,
    );
    add(
      id: 'levels_5',
      title: 'Parkura Giriş',
      description: '5 bölüm tamamla.',
      emoji: '🚩',
      current: progress.tamamlananSeviye,
      target: 5,
    );
    add(
      id: 'levels_20',
      title: 'Dayanıklı Zihin',
      description: '20 bölüm tamamla.',
      emoji: '🧠',
      current: progress.tamamlananSeviye,
      target: 20,
    );
    add(
      id: 'levels_50',
      title: 'Yarı Yol Ustası',
      description: '50 bölüm tamamla.',
      emoji: '🏁',
      current: progress.tamamlananSeviye,
      target: 50,
    );
    add(
      id: 'levels_75',
      title: 'Parkur Uzmanı',
      description: '75 bölüm tamamla.',
      emoji: '🗺️',
      current: progress.tamamlananSeviye,
      target: 75,
    );
    add(
      id: 'levels_110',
      title: 'Tüm Parkurlar',
      description: '110 bölümün tamamını bitir.',
      emoji: '🚀',
      current: progress.tamamlananSeviye,
      target: 110,
    );
    add(
      id: 'three_stars_5',
      title: 'Kusursuz Beşli',
      description: '5 bölümü 3 yıldızla bitir.',
      emoji: '🎯',
      current: threeStarLevels,
      target: 5,
    );
    add(
      id: 'three_stars_20',
      title: 'Üç Yıldız Ustası',
      description: '20 bölümü 3 yıldızla bitir.',
      emoji: '💫',
      current: threeStarLevels,
      target: 20,
    );
    add(
      id: 'three_stars_50',
      title: 'Kusursuzluk Ustası',
      description: '50 bölümü 3 yıldızla bitir.',
      emoji: '🏹',
      current: threeStarLevels,
      target: 50,
    );
    add(
      id: 'three_stars_110',
      title: 'Mutlak Ustalık',
      description: '110 bölümün tamamını 3 yıldızla bitir.',
      emoji: '💠',
      current: threeStarLevels,
      target: 110,
    );
    add(
      id: 'score_2500',
      title: 'Zeka Kıvılcımı',
      description: '2.500 Zeka Puanı kazan.',
      emoji: '⚡',
      current: zekaScore,
      target: 2500,
    );
    add(
      id: 'score_7500',
      title: 'Zihin Motoru',
      description: '7.500 Zeka Puanı kazan.',
      emoji: '🚀',
      current: zekaScore,
      target: 7500,
    );
    add(
      id: 'score_15000',
      title: 'Zeka Şampiyonu',
      description: '15.000 Zeka Puanı kazan.',
      emoji: '🏆',
      current: zekaScore,
      target: 15000,
    );
    add(
      id: 'score_24000',
      title: 'Efsane Zihin',
      description: '24.000 Zeka Puanı kazan ve Efsane Ligi’ne ulaş.',
      emoji: '👑',
      current: zekaScore,
      target: 24000,
      special: true,
    );
    add(
      id: 'all_games',
      title: 'Çok Yönlü Zihin',
      description: '5 farklı parkurda en az bir bölüm bitir.',
      emoji: '🧩',
      current: playedGameCount,
      target: 5,
    );
    add(
      id: 'all_games_11',
      title: 'Parkur Koleksiyoncusu',
      description: '11 parkurun tamamında en az bir bölüm bitir.',
      emoji: '🌈',
      current: playedGameCount,
      target: 11,
    );
    add(
      id: 'boss_1',
      title: 'Boss Avcısı',
      description: 'İlk Boss bölümünü tamamla.',
      emoji: '🐉',
      current: bossCount,
      target: 1,
    );
    add(
      id: 'boss_5',
      title: 'Boss Ustası',
      description: '5 farklı Boss bölümünü tamamla.',
      emoji: '⚔️',
      current: bossCount,
      target: 5,
    );
    add(
      id: 'boss_11',
      title: 'Boss Fatihi',
      description: '11 parkurun Boss bölümünü de tamamla.',
      emoji: '🛡️',
      current: bossCount,
      target: 11,
    );
    add(
      id: 'streak_3',
      title: 'Alev Başladı',
      description: '3 günlük oynama serisine ulaş.',
      emoji: '🔥',
      current: daily.bestStreak,
      target: 3,
    );
    add(
      id: 'streak_7',
      title: 'Bir Hafta Zihin',
      description: '7 günlük oynama serisine ulaş.',
      emoji: '📅',
      current: daily.bestStreak,
      target: 7,
    );
    add(
      id: 'streak_30',
      title: 'Sarsılmaz Seri',
      description: '30 günlük oynama serisine ulaş.',
      emoji: '🌋',
      current: daily.bestStreak,
      target: 30,
      special: true,
    );
    add(
      id: 'perfect_day',
      title: 'Kusursuz Gün',
      description: 'Bir günün 3 görevini de tamamla.',
      emoji: '🏆',
      current: daily.perfectDays,
      target: 1,
    );

    final int completedShapeMatchLevels = <int>[3, 7]
        .where(
          (index) =>
              index < progress.hafiza.yildizlar.length &&
              progress.hafiza.yildizlar[index] > 0,
        )
        .length;

    add(
      id: 'shape_scout',
      title: 'Şekil Kaşifi',
      description: '8 kartlık şekil eşleştirmeyi tamamla.',
      emoji: '🔷',
      current: completedShapeMatchLevels,
      target: 1,
      special: true,
    );
    add(
      id: 'shape_master',
      title: 'Eşleştirme Ustası',
      description: '8 ve 16 kartlık eşleştirmeyi tamamla.',
      emoji: '🧿',
      current: completedShapeMatchLevels,
      target: 2,
      special: true,
    );
    add(
      id: 'daily_course_1',
      title: 'Günün Parkurcusu',
      description: 'Günün Zekâ Parkuru’nu tamamla.',
      emoji: '🏅',
      current: completedDailyCourses,
      target: 1,
      special: true,
    );
    add(
      id: 'daily_course_7',
      title: 'Parkur Müdavimi',
      description: 'Günün Zekâ Parkuru’nu 7 farklı gün tamamla.',
      emoji: '💎',
      current: completedDailyCourses,
      target: 7,
      special: true,
    );
    add(
      id: 'daily_course_30',
      title: 'Parkur Efsanesi',
      description: 'Günün Zekâ Parkuru’nu 30 farklı gün tamamla.',
      emoji: '🏵️',
      current: completedDailyCourses,
      target: 30,
      special: true,
    );

    return result;
  }
}
