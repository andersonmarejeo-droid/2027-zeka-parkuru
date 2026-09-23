import 'package:flutter/widgets.dart';

part 'app_localizations_global.dart';

class AppLocalizations {
  final Locale locale;

  const AppLocalizations(this.locale);

  static const List<Locale> supportedLocales = <Locale>[
    Locale('tr'),
    Locale('en'),
    Locale('ar'),
    Locale('id'),
    Locale('pt', 'BR'),
    Locale('es'),
    Locale('fr'),
    Locale('de'),
  ];

  static AppLocalizations of(BuildContext context) {
    final Locale locale = Localizations.localeOf(context);
    switch (locale.languageCode.toLowerCase()) {
      case 'ar':
      case 'id':
      case 'pt':
      case 'es':
      case 'fr':
      case 'de':
        return GlobalAppLocalizations(locale);
      default:
        return AppLocalizations(locale);
    }
  }

  /// Eski iki dilli ekranlarda yeni dillerin Turkceye dusmesini engeller.
  /// Tam cevirisi bulunmayan metinler guvenli bicimde Ingilizceye doner.
  bool get isEnglish => locale.languageCode.toLowerCase() != 'tr';

  bool get isRtl => locale.languageCode.toLowerCase() == 'ar';

  String get appName => 'Zeka Parkuru';

  // Common
  String get settings => isEnglish ? 'Settings' : 'Ayarlar';
  String get home => isEnglish ? 'Home' : 'Ana Sayfa';
  String get tasks => isEnglish ? 'Challenges' : 'Görevler';
  String get leaderboard => isEnglish ? 'Leaderboard' : 'Liderlik';
  String get profile => isEnglish ? 'Profile' : 'Profil';
  String get level => isEnglish ? 'Level' : 'Seviye';
  String get score => isEnglish ? 'Score' : 'Puan';
  String get stars => isEnglish ? 'Stars' : 'Yıldız';
  String get completedLevels => isEnglish ? 'Levels' : 'Bölüm';
  String get generalProgress =>
      isEnglish ? 'OVERALL PROGRESS' : 'GENEL İLERLEME';
  String get mindScore => isEnglish ? 'BRAIN SCORE' : 'ZEKA PUANI';
  String get player => isEnglish ? 'Player' : 'Oyuncu';
  String get comingSoon => isEnglish ? 'COMING SOON' : 'YAKINDA';
  String levelValue(int value) => isEnglish ? 'Level $value' : 'Seviye $value';
  String levelOutOf(int value, int max) =>
      isEnglish ? 'Level $value / $max' : 'Seviye $value / $max';
  String starOutOf(int value, int max) => '$value / $max';
  String points(int value) => isEnglish ? '$value BP' : '$value ZP';
  String dayCount(int value) => isEnglish ? '$value days' : '$value gün';
  String taskCount(int value) =>
      isEnglish ? '$value/3 tasks' : '$value/3 görev';

  // Main
  String get coursesTitle => isEnglish ? 'COURSES' : 'PARKURLAR';
  String get coursesSubtitle => isEnglish
      ? 'Train your mind across 11 different skill areas.'
      : '11 farklı zeka alanında kendini geliştir.';
  String get courseUnavailable => isEnglish
      ? 'This course is not available yet.'
      : 'Bu parkur çok yakında açılacak.';
  String get dailyCourse => isEnglish ? 'DAILY COURSE' : 'GÜNLÜK PARKUR';
  String streakTitle(int value) =>
      isEnglish ? '$value DAY STREAK' : '$value GÜNLÜK SERİ';
  String dailySummary(int completed) => isEnglish
      ? '$completed / 3 challenges completed  •  View challenges'
      : '$completed / 3 görev tamamlandı  •  Görevleri görüntüle';

  String gameTitle(String gameId) {
    switch (gameId) {
      case 'logic':
        return isEnglish ? 'Logic Maze' : 'Mantık Labirenti';
      case 'numbers':
        return isEnglish ? 'Number Master' : 'Sayı Ustası';
      case 'blocks':
        return isEnglish ? 'Block Workshop' : 'Blok Atölyesi';
      case 'memory':
        return isEnglish ? 'Memory Maze' : 'Hafıza Labirenti';
      case 'hanoi':
        return isEnglish ? 'Tower of Hanoi' : 'Hanoi Kulesi';
      case 'word_hunt':
        return isEnglish ? 'Word Hunt' : 'Kelime Avı';
      case 'picture_iq':
        return isEnglish ? 'Visual IQ' : 'Görsel IQ';
      case 'candy_sort':
        return isEnglish ? 'Candy Sort' : 'Şeker Sıralama';
      case 'number_sort':
        return isEnglish ? 'Number Hive' : 'Sayı Peteği';
      case 'shape_puzzle':
        return isEnglish ? 'Shape Merge' : 'Şekil Birleştir';
      case 'reflex':
        return isEnglish ? 'Reflex Hunt' : 'Refleks Avı';
      default:
        return appName;
    }
  }

  String gameDescription(String gameId) {
    switch (gameId) {
      case 'logic':
        return isEnglish
            ? 'Explore the paths and reach the goal.'
            : 'Yolları keşfet ve hedefe ulaş.';
      case 'numbers':
        return isEnglish
            ? 'Solve sequences and number patterns.'
            : 'Dizileri ve sayı desenlerini çöz.';
      case 'blocks':
        return isEnglish
            ? 'Drag the pieces and complete the target pattern.'
            : 'Parçaları sürükle ve hedef deseni tamamla.';
      case 'memory':
        return isEnglish
            ? 'Observe, remember and make the right choice.'
            : 'Gör, hatırla ve doğru seçimi yap.';
      case 'hanoi':
        return isEnglish
            ? 'Plan your moves and rebuild the colorful tower.'
            : 'Hamlelerini planla ve renkli kuleyi yeniden kur.';
      case 'word_hunt':
        return isEnglish
            ? 'Find hidden words in growing grids.'
            : 'Büyüyen tablolardaki gizli kelimeleri bul.';
      case 'picture_iq':
        return isEnglish
            ? 'Decode visual transformations and analogies.'
            : 'Görsel dönüşümleri ve benzetmeleri çöz.';
      case 'candy_sort':
        return isEnglish
            ? 'Group colorful candies with smart moves.'
            : 'Renkli şekerleri akıllı hamlelerle grupla.';
      case 'number_sort':
        return isEnglish
            ? 'Slide 8 and 15 tiles into order.'
            : '8 ve 15 taşı petek üzerinde sırala.';
      case 'shape_puzzle':
        return isEnglish
            ? 'Combine fragments and find the final silhouette.'
            : 'Parçaları birleştir ve oluşan silüeti bul.';
      case 'reflex':
        return isEnglish
            ? 'React quickly and avoid misleading targets.'
            : 'Hızlı tepki ver ve yanıltıcı hedeflerden kaçın.';
      default:
        return '';
    }
  }

  // Settings
  String get settingsTitle => isEnglish ? 'SETTINGS' : 'AYARLAR';
  String get gameExperience => isEnglish ? 'GAME EXPERIENCE' : 'OYUN DENEYİMİ';
  String get language => isEnglish ? 'Language' : 'Dil';
  String get languageDescription => isEnglish
      ? 'Choose the app language or follow your phone language.'
      : 'Uygulama dilini seç veya telefon dilini otomatik kullan.';
  String get systemDefault =>
      isEnglish ? 'Automatic (System)' : 'Otomatik (Sistem)';
  String get turkish => 'Türkçe';
  String get english => 'English';
  String get arabic => 'العربية';
  String get indonesian => 'Bahasa Indonesia';
  String get brazilianPortuguese => 'Português (Brasil)';
  String get spanish => 'Español';
  String get french => 'Français';
  String get german => 'Deutsch';
  String get languageSaved => isEnglish
      ? 'Your language preference is saved on this device.'
      : 'Dil tercihin bu cihazda saklanır.';

  String get soundEffects => isEnglish ? 'Sound Effects' : 'Ses Efektleri';
  String get soundEffectsDescription => isEnglish
      ? 'Tap, correct answer, combo and level-complete sounds.'
      : 'Dokunuş, doğru cevap, combo ve bölüm sonu efektleri.';
  String get useEffects => isEnglish ? 'Use sound effects' : 'Efektleri kullan';
  String get on => isEnglish ? 'On' : 'Açık';
  String get off => isEnglish ? 'Off' : 'Kapalı';
  String get effectVolume => isEnglish ? 'Effects volume' : 'Efekt seviyesi';
  String get testEffect => isEnglish ? 'TEST EFFECT' : 'EFEKTİ DENE';

  String get music => isEnglish ? 'Music' : 'Müzik';
  String get musicDescription => isEnglish
      ? 'Game music plays at a lower level than sound effects.'
      : 'Oyun müzikleri efektlerden daha düşük seviyede çalar.';
  String get useMusic => isEnglish ? 'Use music' : 'Müziği kullan';
  String get musicVolume => isEnglish ? 'Music volume' : 'Müzik seviyesi';
  String get stopMusic => isEnglish ? 'STOP MUSIC' : 'MÜZİĞİ DURDUR';
  String get testMusic => isEnglish ? 'TEST MUSIC' : 'MÜZİĞİ DENE';

  String get haptics => isEnglish ? 'Haptics' : 'Titreşim';
  String get hapticsDescription => isEnglish
      ? 'Tactile feedback during selections, moves and correct answers.'
      : 'Seçim, hamle ve doğru cevaplarda dokunsal geri bildirim.';
  String get useHaptics => isEnglish ? 'Use haptics' : 'Titreşimi kullan';
  String get resetDefaults =>
      isEnglish ? 'RESTORE DEFAULT SETTINGS' : 'VARSAYILAN AYARLARA DÖN';
  String get settingsStored => isEnglish
      ? 'Your settings are saved automatically on this device.'
      : 'Ayarların otomatik olarak bu cihazda saklanır.';

  String settingsSummary({
    required bool effects,
    required bool musicEnabled,
    required bool hapticsEnabled,
  }) {
    if (isEnglish) {
      return '${effects ? "Effects on" : "Effects off"}  •  '
          '${musicEnabled ? "Music on" : "Music off"}  •  '
          '${hapticsEnabled ? "Haptics on" : "Haptics off"}';
    }

    return '${effects ? "Efekt açık" : "Efekt kapalı"}  •  '
        '${musicEnabled ? "Müzik açık" : "Müzik kapalı"}  •  '
        '${hapticsEnabled ? "Titreşim açık" : "Titreşim kapalı"}';
  }

  // Daily challenges
  String get dailyChallenges =>
      isEnglish ? 'DAILY CHALLENGES' : 'GÜNLÜK GÖREVLER';
  String get todaysGoals => isEnglish ? "TODAY'S GOALS" : 'BUGÜNÜN HEDEFLERİ';
  String get dailyResetInfo => isEnglish
      ? 'Challenges reset every day at 00:00 according to your device time. '
            'Your streak becomes active when you complete a level that day.'
      : 'Görevler her gün cihazının yerel saatine göre 00:00’da yenilenir. '
            'Bir bölüm tamamladığın gün seri sayacın aktif olur.';
  String get backToGame => isEnglish ? 'BACK TO GAME' : 'OYUNA DÖN';
  String get streakDoneToday => isEnglish
      ? "Today's streak is secured."
      : 'Bugünkü seri hakkın tamamlandı.';
  String get keepStreak => isEnglish
      ? 'Complete a level today to keep your streak alive.'
      : 'Seriyi sürdürmek için bugün bir bölüm tamamla.';
  String get streak => isEnglish ? 'DAILY STREAK' : 'GÜNLÜK SERİ';
  String get bestStreak => isEnglish ? 'BEST STREAK' : 'EN İYİ SERİ';
  String get perfectDay => isEnglish ? 'PERFECT DAY' : 'KUSURSUZ GÜN';
  String get today => isEnglish ? 'TODAY' : 'BUGÜN';
  String get dailyCourseCompleted =>
      isEnglish ? 'DAILY COURSE COMPLETED' : 'GÜNLÜK PARKUR TAMAMLANDI';
  String get perfectDayEarned => isEnglish
      ? 'You completed all 3 challenges. +1 Perfect Day earned.'
      : '3 görevi de bitirdin. Kusursuz gün sayına +1 eklendi.';
  String get completeDailyCourse => isEnglish
      ? 'Complete all 3 challenges to earn a Perfect Day.'
      : '3 görevi tamamla ve Kusursuz Gün kazan.';

  String dailyTaskTitle(String id) {
    switch (id) {
      case 'complete_2':
        return isEnglish ? 'Warm-Up' : 'Isınma Turu';
      case 'earn_5_stars':
        return isEnglish ? 'Star Hunter' : 'Yıldız Avcısı';
      case 'different_2':
        return isEnglish ? 'Course Explorer' : 'Parkur Gezgini';
      case 'score_700':
        return isEnglish ? 'Score Rush' : 'Puan Hamlesi';
      case 'three_star_1':
        return isEnglish ? 'Perfect Run' : 'Kusursuz Tur';
      default:
        if (id.startsWith('specific_')) {
          return isEnglish ? "Today's Course" : 'Günün Parkuru';
        }
        return isEnglish ? 'Daily Challenge' : 'Günlük Görev';
    }
  }

  String dailyTaskDescription(String id, String? gameId) {
    switch (id) {
      case 'complete_2':
        return isEnglish
            ? 'Complete 2 levels today.'
            : 'Bugün 2 bölüm tamamla.';
      case 'earn_5_stars':
        return isEnglish
            ? 'Earn a total of 5 stars from completed levels.'
            : 'Tamamladığın bölümlerden toplam 5 yıldız kazan.';
      case 'different_2':
        return isEnglish
            ? 'Complete levels in 2 different mind courses.'
            : '2 farklı zeka parkurunda bölüm tamamla.';
      case 'score_700':
        return isEnglish
            ? 'Earn a total of 700 Brain Points from today’s levels.'
            : 'Bugünkü bölümlerden toplam 700 Zeka Puanı kazan.';
      case 'three_star_1':
        return isEnglish
            ? 'Complete one level with 3 stars.'
            : 'Bir bölümü 3 yıldızla tamamla.';
      default:
        if (id.startsWith('specific_') && gameId != null) {
          return isEnglish
              ? 'Complete at least 1 ${gameTitle(gameId)} level.'
              : '${gameTitle(gameId)} bölümünü en az 1 kez tamamla.';
        }
        return '';
    }
  }

  // Leaderboard
  String get leaderboardCenter =>
      isEnglish ? 'LEADERBOARD CENTER' : 'LİDERLİK MERKEZİ';
  String get personalPodium => isEnglish ? 'PERSONAL PODIUM' : 'KİŞİSEL PODYUM';
  String get podiumDescription => isEnglish
      ? 'Courses are ranked by their fair Brain Score.'
      : 'Parkurlar adil Zeka Puanı değerine göre sıralanır.';
  String get fiveCourseRanking =>
      isEnglish ? '11-COURSE RANKING' : '11 PARKUR SIRALAMASI';
  String get backHome => isEnglish ? 'BACK TO HOME' : 'ANA SAYFAYA DÖN';
  String get highestLeague =>
      isEnglish ? 'Highest league reached' : 'En yüksek lige ulaştın';
  String nextLeague(String league, int score) =>
      isEnglish ? '$league: $score BP' : '$league: $score ZP';
  String get worldFriendsLeaderboard =>
      isEnglish ? 'WORLD & FRIENDS LEADERBOARD' : 'DÜNYA & ARKADAŞ LİDERLİĞİ';
  String get onlineLeaderboardInfo => isEnglish
      ? 'This area will unlock when real Firebase player data is connected. '
            'We do not show fake players or fake rankings.'
      : 'Bu alan gerçek Firebase oyuncu verileri bağlandığında açılacak. '
            'Şimdilik sahte oyuncu ve sahte sıralama göstermiyoruz.';
  String completedOutOf(int value, int max) =>
      isEnglish ? '$value/$max levels' : '$value/$max bölüm';
  String completedAndLevel(int completed, int levelValue) => isEnglish
      ? '$completed/10 levels  •  Level $levelValue'
      : '$completed/10 bölüm  •  Seviye $levelValue';

  // Firebase / online leaderboard
  String get worldRanking => isEnglish ? 'WORLD RANKING' : 'DÜNYA SIRALAMASI';
  String get liveLeaderboard =>
      isEnglish ? 'LIVE LEADERBOARD' : 'CANLI LİDERLİK';
  String get online => isEnglish ? 'ONLINE' : 'ÇEVRİMİÇİ';
  String get offline => isEnglish ? 'OFFLINE' : 'ÇEVRİMDIŞI';
  String get cached => isEnglish ? 'CACHED' : 'ÖNBELLEK';
  String get cachedLeaderboardInfo => isEnglish
      ? 'Showing the last verified world ranking. Reconnection is automatic.'
      : 'Son doğrulanmış dünya sıralaması gösteriliyor. Yeniden bağlanma otomatiktir.';
  String get scoreWaitingToSync => isEnglish
      ? 'Your latest score is waiting to sync'
      : 'Son puanın aktarılmayı bekliyor';
  String get lastUpdateUnknown => isEnglish
      ? 'Last update time unavailable'
      : 'Son güncelleme zamanı bilinmiyor';
  String get updatedJustNow =>
      isEnglish ? 'Updated just now' : 'Az önce güncellendi';
  String updatedMinutesAgo(int value) =>
      isEnglish ? 'Updated $value min ago' : '$value dk önce güncellendi';
  String updatedHoursAgo(int value) =>
      isEnglish ? 'Updated $value hr ago' : '$value saat önce güncellendi';
  String updatedDaysAgo(int value) =>
      isEnglish ? 'Updated $value days ago' : '$value gün önce güncellendi';
  String get retryNow => isEnglish ? 'Retry now' : 'Şimdi yeniden dene';
  String get you => isEnglish ? 'YOU' : 'SEN';
  String get noOnlinePlayers => isEnglish
      ? 'No online players are visible yet. Be the first player on the board.'
      : 'Henüz çevrimiçi sıralamada oyuncu görünmüyor. İlk oyuncu sen ol.';
  String get firebaseSetupNeeded => isEnglish
      ? 'Firebase is not connected yet. The personal leaderboard still works; '
            'complete Firebase setup to activate real world rankings.'
      : 'Firebase henüz bağlı değil. Kişisel liderlik çalışmaya devam eder; '
            'gerçek dünya sıralamasını açmak için Firebase kurulumunu tamamla.';
  String get leaderboardSyncInfo => isEnglish
      ? 'Your public leaderboard card contains only your player name, avatar and game statistics.'
      : 'Herkese açık liderlik kartında yalnızca oyuncu adın, avatarın ve oyun istatistiklerin bulunur.';
  String globalTop(int count) =>
      isEnglish ? 'GLOBAL TOP $count' : 'DÜNYA İLK $count';

  // Profile
  String get editProfile => isEnglish ? 'EDIT PROFILE' : 'PROFİLİ DÜZENLE';
  String get playerName => isEnglish ? 'PLAYER NAME' : 'OYUNCU ADI';
  String get playerNameHint => isEnglish ? 'Player name' : 'Oyuncu adı';
  String get avatar => isEnglish ? 'AVATAR' : 'AVATAR';
  String get save => isEnglish ? 'SAVE' : 'KAYDET';
  String get profileTitle => isEnglish ? 'PROFILE' : 'PROFİL';
  String get edit => isEnglish ? 'EDIT' : 'DÜZENLE';
  String get achievements => isEnglish ? 'ACHIEVEMENTS' : 'BAŞARIMLAR';
  String get achievementsInfo => isEnglish
      ? 'Badges unlock from the same progress used by your Brain Score and ranking.'
      : 'Rozetler Zeka Puanı ve sıralamayla aynı ilerleme verisinden açılır.';
  String get specialBadges => isEnglish ? 'SPECIAL BADGES' : 'ÖZEL ROZETLER';
  String get specialBadgesInfo => isEnglish
      ? 'Rare badges earned from special course goals.'
      : 'Özel parkur hedefleriyle kazanılan nadir rozetler.';
  String get courseStats =>
      isEnglish ? 'COURSE STATISTICS' : 'PARKUR İSTATİSTİKLERİ';
  String get playerLevel => isEnglish ? 'PLAYER LEVEL' : 'OYUNCU SEVİYESİ';
  String totalXp(int score) =>
      isEnglish ? '$score total Brain Points' : '$score toplam Zeka Puanı';
  String get maxLevel => isEnglish ? 'Maximum level' : 'Maksimum seviye';
  String openLevel(int levelValue) => isEnglish
      ? 'Unlocked level $levelValue/10'
      : 'Açık seviye $levelValue/10';

  String rankLabel(String raw) {
    if (!isEnglish) return raw;

    switch (raw) {
      case 'ZEKA ÇIRAĞI':
        return 'MIND ROOKIE';
      case 'KAŞİF':
        return 'EXPLORER';
      case 'STRATEJİST':
        return 'STRATEGIST';
      case 'UZMAN':
        return 'EXPERT';
      case 'ZEKA USTASI':
        return 'MIND MASTER';
      case 'PARKUR ŞAMPİYONU':
        return 'COURSE CHAMPION';
      case 'ZEKA EFSANESİ':
        return 'MIND LEGEND';
      default:
        return raw;
    }
  }

  String leagueLabel(String shortName) {
    switch (shortName) {
      case 'BAŞLANGIÇ':
        return isEnglish ? 'Starter League' : 'Başlangıç Ligi';
      case 'BRONZ':
        return isEnglish ? 'Bronze League' : 'Bronz Lig';
      case 'GÜMÜŞ':
        return isEnglish ? 'Silver League' : 'Gümüş Lig';
      case 'ALTIN':
        return isEnglish ? 'Gold League' : 'Altın Lig';
      case 'PLATİN':
        return isEnglish ? 'Platinum League' : 'Platin Lig';
      case 'ELMAS':
        return isEnglish ? 'Diamond League' : 'Elmas Lig';
      case 'USTA':
        return isEnglish ? 'Master League' : 'Usta Ligi';
      case 'EFSANE':
        return isEnglish ? 'Legend League' : 'Efsane Ligi';
      default:
        return shortName;
    }
  }

  String achievementTitle(String id) {
    final Map<String, List<String>> map = <String, List<String>>{
      'first_step': <String>['İlk Adım', 'First Step'],
      'stars_10': <String>['Yıldız Toplayıcı', 'Star Collector'],
      'stars_30': <String>['Yıldız Avcısı', 'Star Hunter'],
      'stars_75': <String>['Parlayan Zihin', 'Shining Mind'],
      'stars_150': <String>['Yıldız Efsanesi', 'Star Legend'],
      'stars_225': <String>['Galaksi Avcısı', 'Galaxy Hunter'],
      'stars_330': <String>['Kusursuz On Birli', 'Perfect Eleven'],
      'levels_5': <String>['Parkura Giriş', 'Course Beginner'],
      'levels_20': <String>['Dayanıklı Zihin', 'Enduring Mind'],
      'levels_50': <String>['Yarı Yol Ustası', 'Halfway Master'],
      'levels_75': <String>['Parkur Uzmanı', 'Course Expert'],
      'levels_110': <String>['Tüm Parkurlar', 'All Courses'],
      'three_stars_5': <String>['Kusursuz Beşli', 'Perfect Five'],
      'three_stars_20': <String>['Üç Yıldız Ustası', 'Three-Star Master'],
      'three_stars_50': <String>['Kusursuzluk Ustası', 'Perfection Master'],
      'three_stars_110': <String>['Mutlak Ustalık', 'Absolute Mastery'],
      'score_2500': <String>['Zeka Kıvılcımı', 'Brain Spark'],
      'score_7500': <String>['Zihin Motoru', 'Mind Engine'],
      'score_15000': <String>['Zeka Şampiyonu', 'Brain Champion'],
      'score_24000': <String>['Efsane Zihin', 'Legendary Mind'],
      'all_games': <String>['Çok Yönlü Zihin', 'Versatile Mind'],
      'all_games_11': <String>['Parkur Koleksiyoncusu', 'Course Collector'],
      'boss_1': <String>['Boss Avcısı', 'Boss Hunter'],
      'boss_5': <String>['Boss Ustası', 'Boss Master'],
      'boss_11': <String>['Boss Fatihi', 'Boss Conqueror'],
      'streak_3': <String>['Alev Başladı', 'Spark Ignited'],
      'streak_7': <String>['Bir Hafta Zihin', 'Seven-Day Mind'],
      'streak_30': <String>['Sarsılmaz Seri', 'Unbreakable Streak'],
      'perfect_day': <String>['Kusursuz Gün', 'Perfect Day'],
      'shape_scout': <String>['Şekil Kaşifi', 'Shape Scout'],
      'shape_master': <String>['Eşleştirme Ustası', 'Match Master'],
      'daily_course_1': <String>['Günün Parkurcusu', 'Daily Runner'],
      'daily_course_7': <String>['Parkur Müdavimi', 'Course Regular'],
      'daily_course_30': <String>['Parkur Efsanesi', 'Course Legend'],
    };

    final List<String>? item = map[id];
    if (item == null) return id;
    return item[isEnglish ? 1 : 0];
  }

  String achievementDescription(String id) {
    final Map<String, List<String>> map = <String, List<String>>{
      'first_step': <String>[
        'İlk bölümünü tamamla.',
        'Complete your first level.',
      ],
      'stars_10': <String>[
        'Toplam 10 yıldız kazan.',
        'Earn a total of 10 stars.',
      ],
      'stars_30': <String>[
        'Toplam 30 yıldız kazan.',
        'Earn a total of 30 stars.',
      ],
      'stars_75': <String>[
        'Toplam 75 yıldız kazan.',
        'Earn a total of 75 stars.',
      ],
      'stars_150': <String>[
        'Toplam 150 yıldız kazan.',
        'Earn a total of 150 stars.',
      ],
      'stars_225': <String>[
        'Toplam 225 yıldız kazan.',
        'Earn a total of 225 stars.',
      ],
      'stars_330': <String>[
        '330 yıldızın tamamını kazan.',
        'Earn all 330 stars.',
      ],
      'levels_5': <String>['5 bölüm tamamla.', 'Complete 5 levels.'],
      'levels_20': <String>['20 bölüm tamamla.', 'Complete 20 levels.'],
      'levels_50': <String>['50 bölüm tamamla.', 'Complete 50 levels.'],
      'levels_75': <String>['75 bölüm tamamla.', 'Complete 75 levels.'],
      'levels_110': <String>[
        '110 bölümün tamamını bitir.',
        'Complete all 110 levels.',
      ],
      'three_stars_5': <String>[
        '5 bölümü 3 yıldızla bitir.',
        'Finish 5 levels with 3 stars.',
      ],
      'three_stars_20': <String>[
        '20 bölümü 3 yıldızla bitir.',
        'Finish 20 levels with 3 stars.',
      ],
      'three_stars_50': <String>[
        '50 bölümü 3 yıldızla bitir.',
        'Finish 50 levels with 3 stars.',
      ],
      'three_stars_110': <String>[
        '110 bölümün tamamını 3 yıldızla bitir.',
        'Finish all 110 levels with 3 stars.',
      ],
      'score_2500': <String>[
        '2.500 Zeka Puanı kazan.',
        'Earn 2,500 Brain Points.',
      ],
      'score_7500': <String>[
        '7.500 Zeka Puanı kazan.',
        'Earn 7,500 Brain Points.',
      ],
      'score_15000': <String>[
        '15.000 Zeka Puanı kazan.',
        'Earn 15,000 Brain Points.',
      ],
      'score_24000': <String>[
        '24.000 Zeka Puanı kazan ve Efsane Ligi’ne ulaş.',
        'Earn 24,000 Brain Points and reach the Legend League.',
      ],
      'all_games': <String>[
        '5 farklı parkurda en az bir bölüm bitir.',
        'Complete at least one level in 5 courses.',
      ],
      'all_games_11': <String>[
        '11 parkurun tamamında en az bir bölüm bitir.',
        'Complete at least one level in all 11 courses.',
      ],
      'boss_1': <String>[
        'İlk Boss bölümünü tamamla.',
        'Complete your first Boss level.',
      ],
      'boss_5': <String>[
        '5 farklı Boss bölümünü tamamla.',
        'Complete 5 different Boss levels.',
      ],
      'boss_11': <String>[
        '11 parkurun Boss bölümünü de tamamla.',
        'Complete the Boss level in all 11 courses.',
      ],
      'streak_3': <String>[
        '3 günlük oynama serisine ulaş.',
        'Reach a 3-day play streak.',
      ],
      'streak_7': <String>[
        '7 günlük oynama serisine ulaş.',
        'Reach a 7-day play streak.',
      ],
      'streak_30': <String>[
        '30 günlük oynama serisine ulaş.',
        'Reach a 30-day play streak.',
      ],
      'perfect_day': <String>[
        'Bir günün 3 görevini de tamamla.',
        'Complete all 3 daily challenges in one day.',
      ],
      'shape_scout': <String>[
        '8 kartlık şekil eşleştirmeyi tamamla.',
        'Complete the 8-card shape matching level.',
      ],
      'shape_master': <String>[
        '8 ve 16 kartlık eşleştirmeyi tamamla.',
        'Complete both 8-card and 16-card matching levels.',
      ],
      'daily_course_1': <String>[
        'Günün Zekâ Parkuru’nu bir kez tamamla.',
        'Complete the Daily Brain Course once.',
      ],
      'daily_course_7': <String>[
        'Günün Zekâ Parkuru’nu 7 farklı gün tamamla.',
        'Complete the Daily Brain Course on 7 different days.',
      ],
      'daily_course_30': <String>[
        'Günün Zekâ Parkuru’nu 30 farklı gün tamamla.',
        'Complete the Daily Brain Course on 30 different days.',
      ],
    };

    final List<String>? item = map[id];
    if (item == null) return '';
    return item[isEnglish ? 1 : 0];
  }

  String gameUi(String raw) {
    if (!isEnglish) return raw;

    final String? exact = _gameUiEnglish[raw];
    if (exact != null) return exact;

    // Common dynamic text patterns.
    Match? match;

    match = RegExp(r'^Seviye (\d+) / (\d+)$').firstMatch(raw);
    if (match != null) {
      return 'Level ${match.group(1)} / ${match.group(2)}';
    }

    match = RegExp(r'^Seviye (\d+) / 10\s+•\s+⭐\s+(\d+) / 30$').firstMatch(raw);
    if (match != null) {
      return 'Level ${match.group(1)} / 10   •   ⭐ ${match.group(2)} / 30';
    }

    match = RegExp(r'^Seviye (\d+) tamamlandı$').firstMatch(raw);
    if (match != null) {
      return 'Level ${match.group(1)} completed';
    }

    match = RegExp(r'^Seviye (\d+) / 10$').firstMatch(raw);
    if (match != null) {
      return 'Level ${match.group(1)} / 10';
    }

    match = RegExp(r'^Soru (\d+) / (\d+)$').firstMatch(raw);
    if (match != null) {
      return 'Question ${match.group(1)} / ${match.group(2)}';
    }

    match = RegExp(r'^(\d+) doğru$').firstMatch(raw);
    if (match != null) {
      return '${match.group(1)} correct';
    }

    match = RegExp(r'^(\d+) puan$').firstMatch(raw);
    if (match != null) {
      return '${match.group(1)} pts';
    }

    match = RegExp(r'^En iyi: (.+)$').firstMatch(raw);
    if (match != null) {
      return 'Best: ${match.group(1)}';
    }

    match = RegExp(r'^Hedef: (.+)$').firstMatch(raw);
    if (match != null) {
      return 'Target: ${match.group(1)}';
    }

    match = RegExp(r'^Ortalama (.+) ms$').firstMatch(raw);
    if (match != null) {
      return 'Average ${match.group(1)} ms';
    }

    match = RegExp(r'^Sıra sende • (\d+) dokunuş$').firstMatch(raw);
    if (match != null) {
      return 'Your turn • ${match.group(1)} taps';
    }

    match = RegExp(r'^İpucu: Bir sonraki hamlen (.+)\.$').firstMatch(raw);
    if (match != null) {
      return 'Hint: Your next move is ${gameUi(match.group(1)!)}.';
    }

    match = RegExp(r'^✕ Doğru cevap: (.+)$').firstMatch(raw);
    if (match != null) {
      return '✕ Correct answer: ${match.group(1)}';
    }

    match = RegExp(r'^İSTENEN RENK: (.+)$').firstMatch(raw);
    if (match != null) {
      return 'TARGET COLOR: ${gameUi(match.group(1)!)}';
    }

    match = RegExp(r'^Tamamlanan tur: (.+)$')
        .firstMatch(raw.replaceAll('\n', ' ').trim());
    if (match != null) {
      return 'Completed round: ${match.group(1)}';
    }

    match = RegExp(r'^Tur: (.+)$').firstMatch(raw.replaceAll('\n', ' ').trim());
    if (match != null) {
      return 'Round: ${match.group(1)}';
    }

    match = RegExp(r'^Puan: (.+)$')
        .firstMatch(raw.replaceAll('\n', ' ').trim());
    if (match != null) {
      return 'Score: ${match.group(1)}';
    }

    if (raw.contains(' + ')) {
      final List<String> parts = raw.split(' + ');
      if (parts.length == 2) {
        final String left = gameUi(parts[0]);
        final String right = gameUi(parts[1]);

        if (left != parts[0] || right != parts[1]) {
          return '$left + $right';
        }
      }
    }

    return raw;
  }
}

const Map<String, String> _gameUiEnglish = <String, String>{
  // Generic difficulty / game labels
  'KOLAY': 'EASY',
  'ORTA': 'MEDIUM',
  'ZOR': 'HARD',
  'BOSS': 'BOSS',
  'PUAN': 'SCORE',
  'HEDEF': 'TARGET',
  'HAMLE': 'MOVES',
  'EN KISA': 'SHORTEST',
  'EN İYİ': 'BEST',
  'ORT.': 'AVG.',
  'ORTALAMA': 'AVERAGE',
  'CAN': 'LIVES',
  'COMBO': 'COMBO',
  'TUR': 'ROUND',
  'SEVİYE': 'LEVEL',
  'SONRAKİ SEVİYE': 'NEXT LEVEL',
  'BÖLÜM LİSTESİ': 'LEVEL LIST',
  'BÖLÜMLER': 'LEVELS',
  'TEKRAR OYNA': 'PLAY AGAIN',
  'Yeniden Başlat': 'Restart',
  'Yeniden başlat': 'Restart',
  'PARKURU TAMAMLA': 'FINISH COURSE',
  '3 ⭐ HEDEF': '3 ⭐ TARGET',
  'İpucu': 'Hint',
  'Akıllı İpucu': 'Smart Hint',
  'HAZIR': 'READY',
  'HAZIRLAN': 'GET READY',
  'BEKLE!': 'WAIT!',
  'DOKUN!': 'TAP!',
  'ŞİMDİ!': 'NOW!',
  'DOĞRU': 'CORRECT',
  'DOĞRU!': 'CORRECT!',
  '✓ Doğru!': '✓ Correct!',
  'HARİKA!': 'GREAT!',
  'MÜKEMMEL!': 'PERFECT!',
  'MUHTEŞEM!': 'AMAZING!',
  'İYİ!': 'GOOD!',
  'DİKKAT!': 'WATCH OUT!',
  'GEÇ KALDIN!': 'TOO LATE!',
  'ÇOK ERKEN!': 'TOO EARLY!',
  'YANLIŞ HEDEF!': 'WRONG TARGET!',
  'DOĞRU KARAR!': 'RIGHT DECISION!',
  'HAMLE KALMADI': 'NO MOVES LEFT',
  'CANLAR TÜKENDİ': 'OUT OF LIVES',
  'Canların tükendi': 'You are out of lives',
  '⚠ SON HAK': '⚠ LAST CHANCE',
  '💔 -1 CAN': '💔 -1 LIFE',

  // Directions
  'SAĞA': 'RIGHT',
  'SOLA': 'LEFT',
  'YUKARI': 'UP',
  'AŞAĞI': 'DOWN',

  // Colors / shapes
  'MAVİ': 'BLUE',
  'YEŞİL': 'GREEN',
  'KIRMIZI': 'RED',
  'SARI': 'YELLOW',
  'MOR': 'PURPLE',
  'PEMBE': 'PINK',
  'TURUNCU': 'ORANGE',
  'DAİRE': 'CIRCLE',
  'KARE': 'SQUARE',

  // Logic Maze
  'MANTIK LABİRENTİ': 'LOGIC MAZE',
  'Zihin yolculuğun': 'Your mind journey',
  'ZİHİN YOLCULUĞU': 'MIND JOURNEY',
  'İlk Adım': 'First Step',
  'İLK ADIM': 'FIRST STEP',
  'Kıvrımlı Yol': 'Winding Path',
  'KIVRIMLI YOL': 'WINDING PATH',
  'Dar Geçit': 'Narrow Passage',
  'DAR GEÇİT': 'NARROW PASSAGE',
  'Dört Köşe': 'Four Corners',
  'DÖRT KÖŞE': 'FOUR CORNERS',
  'Zihin Duvarı': 'Mind Wall',
  'ZİHİN DUVARI': 'MIND WALL',
  'Nefes': 'Breather',
  'NEFES': 'BREATHER',
  'Sarmal': 'Spiral',
  'SARMAL': 'SPIRAL',
  'Keskin Dönüş': 'Sharp Turn',
  'KESKİN DÖNÜŞ': 'SHARP TURN',
  'Zihin Kilidi': 'Mind Lock',
  'ZİHİN KİLİDİ': 'MIND LOCK',
  'İlk Boss': 'First Boss',
  'İLK BOSS': 'FIRST BOSS',
  'BOSS YENİLDİ!': 'BOSS DEFEATED!',
  'Yeni labirent hazırlanıyor...': 'Preparing a new maze...',

  // Number Master
  'SAYI USTASI': 'NUMBER MASTER',
  'Sayıların dünyasını fethet': 'Conquer the world of numbers',
  'SAYI YOLCULUĞU': 'NUMBER JOURNEY',
  'Desenleri bul, işlemleri çöz.': 'Find patterns and solve operations.',
  'Eksik Sayı': 'Missing Number',
  'EKSİK SAYI': 'MISSING NUMBER',
  'Çift Adımlar': 'Even Steps',
  'ÇİFT ADIMLAR': 'EVEN STEPS',
  'Gizli Desen': 'Hidden Pattern',
  'GİZLİ DESEN': 'HIDDEN PATTERN',
  'Sayı Zinciri': 'Number Chain',
  'SAYI ZİNCİRİ': 'NUMBER CHAIN',
  'Hızlı Zincir': 'Fast Chain',
  'HIZLI ZİNCİR': 'FAST CHAIN',
  'İşlem Ustası': 'Operation Master',
  'İŞLEM USTASI': 'OPERATION MASTER',
  'İşlem Fırtınası': 'Operation Storm',
  'İŞLEM FIRTINASI': 'OPERATION STORM',
  'Mini Sudoku': 'Mini Sudoku',
  'MİNİ SUDOKU': 'MINI SUDOKU',
  'Sayı Boss': 'Number Boss',
  'SAYI BOSS': 'NUMBER BOSS',
  'ZİNCİR': 'CHAIN',
  'İŞLEM': 'OPERATION',
  'SUDOKU': 'SUDOKU',
  'Sayılar arasındaki artış veya azalış miktarını karşılaştır.':
      'Compare how much the numbers increase or decrease.',
  'Her adımdaki çarpma, bölme veya toplama kuralını bul.':
      'Find the multiplication, division or addition rule at each step.',
  'Önce çarpma ve bölme işlemlerini yapmayı unutma.':
      'Remember to do multiplication and division first.',
  'Her satırda 1, 2, 3 ve 4 sayıları yalnızca bir kez bulunmalı.':
      'Each row must contain 1, 2, 3 and 4 exactly once.',
  'Boss bölümünde önce sorunun türünü belirle, sonra çözüm kuralını uygula.': 'In the Boss level, identify the question type first, then apply the rule.',
  'Sorudaki düzeni adım adım incele.': 'Study the pattern step by step.',
  'Doğru cevabı seç.': 'Choose the correct answer.',
  'SEVİYE TAMAMLANDI!': 'LEVEL COMPLETED!',
  'SAYI BOSS YENİLDİ!': 'NUMBER BOSS DEFEATED!',
  'SAYI PARKURUNU TAMAMLA': 'FINISH NUMBER COURSE',

  // Block
  'BLOK FIRTINASI': 'BLOCK STORM',
  'Sürükle • Yerleştir • Patlat': 'Drag • Place • Clear',
  'Blok Başlangıç': 'Block Start',
  'BLOK BAŞLANGIÇ': 'BLOCK START',
  'Renk Patlaması': 'Color Burst',
  'RENK PATLAMASI': 'COLOR BURST',
  'Çift Çizgi': 'Double Line',
  'ÇİFT ÇİZGİ': 'DOUBLE LINE',
  'Combo Avı': 'Combo Hunt',
  'COMBO AVI': 'COMBO HUNT',
  'Dar Alan': 'Tight Space',
  'DAR ALAN': 'TIGHT SPACE',
  'Hız Turu': 'Speed Round',
  'HIZ TURU': 'SPEED ROUND',
  'Zincir Ustası': 'Chain Master',
  'ZİNCİR USTASI': 'CHAIN MASTER',
  'Mega Temizleme': 'Mega Clear',
  'MEGA TEMİZLEME': 'MEGA CLEAR',
  'Blok Fırtınası': 'Block Storm',
  'Blok Boss': 'Block Boss',
  'BLOK BOSS': 'BLOCK BOSS',
  'Bloğa dokunduğun anda kalkar. Parmağını bırakınca otomatik yerleşir.': 'The block lifts as soon as you touch it. Release your finger to place it automatically.',
  '🎉 HEDEF TAMAMLANDI!': '🎉 TARGET COMPLETED!',
  '🔥 BLOK BOSS!': '🔥 BLOCK BOSS!',
  '⚡ ÇİFT ÇİZGİ': '⚡ DOUBLE LINE',

  // Memory
  'HAFIZA LABİRENTİ': 'MEMORY MAZE',
  'Gör • Hatırla • Tekrarla': 'Watch • Remember • Repeat',
  'HAFIZA USTALIĞI': 'MEMORY MASTERY',
  'İlk Işık': 'First Light',
  'İLK IŞIK': 'FIRST LIGHT',
  'Kısa ışık dizisini hatırla': 'Remember the short light sequence',
  'Renk Yolu': 'Color Path',
  'RENK YOLU': 'COLOR PATH',
  'Dizi uzuyor, dikkatini koru': 'The sequence grows, stay focused',
  'Hızlanan Zihin': 'Speeding Mind',
  'HIZLANAN ZİHİN': 'SPEEDING MIND',
  'Daha kısa sürede daha çok kare': 'More tiles in less time',
  'Ters Hafıza': 'Reverse Memory',
  'TERS HAFIZA': 'REVERSE MEMORY',
  'Gördüğün diziyi tersten gir': 'Enter the sequence in reverse',
  'Sahte Işıklar': 'Fake Lights',
  'SAHTE IŞIKLAR': 'FAKE LIGHTS',
  'Dikkat dağıtıcılara aldanma': 'Do not fall for distractions',
  'Ritmi yakala ve seriyi koru': 'Find the rhythm and keep the streak',
  'Neon İz': 'Neon Trail',
  'NEON İZ': 'NEON TRAIL',
  'Uzun diziyi tek seferde çöz': 'Solve the long sequence in one go',
  'Karanlık Yol': 'Dark Path',
  'KARANLIK YOL': 'DARK PATH',
  'Işıklar hızlanıyor': 'The lights are speeding up',
  'Zihin Fırtınası': 'Mind Storm',
  'ZİHİN FIRTINASI': 'MIND STORM',
  'Uzun, hızlı ve ters': 'Long, fast and reversed',
  'Hafıza Boss': 'Memory Boss',
  'HAFIZA BOSS': 'MEMORY BOSS',
  'Usta hafızanın son sınavı': 'The final test of a master memory',
  'Işık yolunu dikkatle izle': 'Watch the light path carefully',
  'İZLE': 'WATCH',
  'Sırayı zihninde tut': 'Keep the sequence in your mind',
  'Sıradaki yol hazırlanıyor': 'Preparing the next path',
  'Bu tur diziyi TERSTEN gireceksin':
      'Enter the sequence in REVERSE this round',
  'TERSTEN TEKRARLA': 'REPEAT IN REVERSE',
  'TEKRARLA': 'REPEAT',
  '↩ Bu bölümde diziyi tersten hatırla':
      '↩ Remember the sequence in reverse in this level',
  '⚠ Bazı kısa flaşlar dikkat dağıtıcıdır':
      '⚠ Some short flashes are distractions',
  '🧠 Işıkların sırasını zihninde tut':
      '🧠 Keep the order of the lights in your mind',
  'Hafıza parkurunu tamamladın': 'You completed the memory course',
  'HAFIZA PARKURUNU TAMAMLA': 'FINISH MEMORY COURSE',
  '👑 HAFIZA BOSS YENİLDİ!': '👑 MEMORY BOSS DEFEATED!',
  '🎉 HAFIZA USTASI!': '🎉 MEMORY MASTER!',

  // Hanoi
  'HANOİ KULESİ': 'TOWER OF HANOI',
  'Planla • Taşı • Tamamla': 'Plan • Move • Complete',
  'HANOİ USTALIĞI': 'HANOI MASTERY',
  'İlk Taşıma': 'First Move',
  'Sağ Kule Hedefi': 'Right Tower Goal',
  'Ters Rota': 'Reverse Route',
  'Dört Halka': 'Four Rings',
  'Orta Kule': 'Center Tower',
  'Keskin Plan': 'Sharp Plan',
  'Kusursuz Dörtlü': 'Perfect Four',
  'Beş Halka': 'Five Rings',
  'Usta Rotası': 'Master Route',
  'Hanoi Ustası': 'Hanoi Master',
  'GERİ AL': 'UNDO',
  'İPUCU': 'HINT',
  'YENİDEN': 'RESTART',
  'KULE TAMAMLANDI!': 'TOWER COMPLETED!',
  'HANOİ USTASI!': 'HANOI MASTER!',
  'HANOİ PARKURUNU TAMAMLA': 'FINISH HANOI COURSE',
};

class LText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;

  const LText(
    this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      AppLocalizations.of(context).gameUi(data),
      style: style,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );
  }
}

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
