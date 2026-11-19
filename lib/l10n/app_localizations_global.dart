part of 'app_localizations.dart';

/// Arabic, Indonesian, Brazilian Portuguese, Latin American Spanish, French
/// and German translations. Missing game-specific copy deliberately falls
/// back to English so a newly selected language never exposes mixed Turkish
/// content.
class GlobalAppLocalizations extends AppLocalizations {
  const GlobalAppLocalizations(super.locale);

  int get _languageIndex {
    switch (locale.languageCode.toLowerCase()) {
      case 'ar':
        return 0;
      case 'id':
        return 1;
      case 'pt':
        return 2;
      case 'es':
        return 3;
      case 'fr':
        return 4;
      case 'de':
        return 5;
      default:
        return 1;
    }
  }

  String _t(String english) {
    final List<String>? row = _globalText[english];
    if (row == null || _languageIndex >= row.length) return english;
    return row[_languageIndex];
  }

  @override
  String get appName => _t('Mind Arena');
  @override
  String get categories => _t('Categories');
  @override
  String get challengeFriends => _t('Challenge Your Friends');
  @override
  String get challengeFriendsSub => _t('Live duels, room codes & rank race');
  @override
  String get whatsappArena => _t('WHATSAPP & ARENA');
  @override
  String get todaysBrainCourse => _t("Today's Brain Course");
  @override
  String get dailyCourseBadge => _t('DAILY COURSE');
  @override
  String dailyTasksProgress(int completed, int total) {
    switch (locale.languageCode.toLowerCase()) {
      case 'ar':
        return 'اليوم $completed من $total مهام';
      case 'es':
        return 'Hoy $completed de $total tareas';
      case 'de':
        return 'Heute $completed von $total Aufgaben';
      case 'fr':
        return '$completed sur $total tâches';
      case 'pt':
        return 'Hoje $completed de $total tarefas';
      case 'id':
        return 'Hari ini $completed dari $total tugas';
      default:
        return '$completed of $total tasks today';
    }
  }
  @override
  String gameCountLabel(int count) {
    switch (locale.languageCode.toLowerCase()) {
      case 'ar':
        return count == 1 ? '1 لعبة' : '$count ألعاب';
      case 'es':
        return count == 1 ? '1 juego' : '$count juegos';
      case 'de':
        return count == 1 ? '1 Spiel' : '$count Spiele';
      case 'fr':
        return count == 1 ? '1 jeu' : '$count jeux';
      case 'pt':
        return count == 1 ? '1 jogo' : '$count jogos';
      case 'id':
        return '$count game';
      default:
        return count == 1 ? '1 game' : '$count games';
    }
  }
  @override
  String get playAction => _t('PLAY');

  @override
  String get settings => _t('Settings');
  @override
  String get home => _t('Home');
  @override
  String get tasks => _t('Challenges');
  @override
  String get leaderboard => _t('Leaderboard');
  @override
  String get profile => _t('Profile');
  @override
  String get level => _t('Level');
  @override
  String get score => _t('Score');
  @override
  String get stars => _t('Stars');
  @override
  String get completedLevels => _t('Levels');
  @override
  String get generalProgress => _t('OVERALL PROGRESS');
  @override
  String get mindScore => _t('BRAIN SCORE');
  @override
  String get player => _t('Player');
  @override
  String get comingSoon => _t('COMING SOON');

  @override
  String levelValue(int value) => '${_t('Level')} $value';
  @override
  String levelOutOf(int value, int max) => '${_t('Level')} $value / $max';
  @override
  String points(int value) => '$value BP';
  @override
  String dayCount(int value) => '$value ${_t('days')}';
  @override
  String taskCount(int value) => '$value/3 ${_t('challenges')}';

  @override
  String get coursesTitle => _t('COURSES');
  @override
  String get coursesSubtitle =>
      _t('Train your mind across 11 different skill areas.');
  @override
  String get courseUnavailable => _t('This course is not available yet.');
  @override
  String get dailyCourse => _t('DAILY COURSE');
  @override
  String streakTitle(int value) => '$value ${_t('DAY STREAK')}';
  @override
  String dailySummary(int completed) =>
      '$completed / 3 ${_t('challenges completed')}  •  ${_t('View challenges')}';

  @override
  String gameTitle(String gameId) => _t(super.gameTitle(gameId));
  @override
  String gameDescription(String gameId) => _t(super.gameDescription(gameId));

  @override
  String get settingsTitle => _t('SETTINGS');
  @override
  String get gameExperience => _t('GAME EXPERIENCE');
  @override
  String get language => _t('Language');
  @override
  String get languageDescription =>
      _t('Choose the app language or follow your phone language.');
  @override
  String get systemDefault => _t('Automatic (System)');
  @override
  String get languageSaved =>
      _t('Your language preference is saved on this device.');
  @override
  String get soundEffects => _t('Sound Effects');
  @override
  String get soundEffectsDescription =>
      _t('Tap, correct answer, combo and level-complete sounds.');
  @override
  String get useEffects => _t('Use sound effects');
  @override
  String get on => _t('On');
  @override
  String get off => _t('Off');
  @override
  String get effectVolume => _t('Effects volume');
  @override
  String get testEffect => _t('TEST EFFECT');
  @override
  String get music => _t('Music');
  @override
  String get musicDescription =>
      _t('Game music plays at a lower level than sound effects.');
  @override
  String get useMusic => _t('Use music');
  @override
  String get musicVolume => _t('Music volume');
  @override
  String get stopMusic => _t('STOP MUSIC');
  @override
  String get testMusic => _t('TEST MUSIC');
  @override
  String get haptics => _t('Haptics');
  @override
  String get hapticsDescription =>
      _t('Tactile feedback during selections, moves and correct answers.');
  @override
  String get useHaptics => _t('Use haptics');
  @override
  String get resetDefaults => _t('RESTORE DEFAULT SETTINGS');
  @override
  String get settingsStored =>
      _t('Your settings are saved automatically on this device.');

  @override
  String settingsSummary({
    required bool effects,
    required bool musicEnabled,
    required bool hapticsEnabled,
  }) {
    return '${_t(effects ? 'Effects on' : 'Effects off')}  •  '
        '${_t(musicEnabled ? 'Music on' : 'Music off')}  •  '
        '${_t(hapticsEnabled ? 'Haptics on' : 'Haptics off')}';
  }

  @override
  String get dailyChallenges => _t('DAILY CHALLENGES');
  @override
  String get todaysGoals => _t("TODAY'S GOALS");
  @override
  String get dailyResetInfo => _t(
    'Challenges reset every day at 00:00 according to your device time. '
    'Your streak becomes active when you complete a level that day.',
  );
  @override
  String get backToGame => _t('BACK TO GAME');
  @override
  String get streakDoneToday => _t("Today's streak is secured.");
  @override
  String get keepStreak =>
      _t('Complete a level today to keep your streak alive.');
  @override
  String get streak => _t('DAILY STREAK');
  @override
  String get bestStreak => _t('BEST STREAK');
  @override
  String get perfectDay => _t('PERFECT DAY');
  @override
  String get today => _t('TODAY');
  @override
  String get dailyCourseCompleted => _t('DAILY COURSE COMPLETED');
  @override
  String get perfectDayEarned =>
      _t('You completed all 3 challenges. +1 Perfect Day earned.');
  @override
  String get completeDailyCourse =>
      _t('Complete all 3 challenges to earn a Perfect Day.');
  @override
  String dailyTaskTitle(String id) => _t(super.dailyTaskTitle(id));

  @override
  String dailyTaskDescription(String id, String? gameId) {
    if (id.startsWith('specific_') && gameId != null) {
      return '${_t('Complete at least one level in')} ${gameTitle(gameId)}.';
    }
    return _t(super.dailyTaskDescription(id, gameId));
  }

  @override
  String get leaderboardCenter => _t('LEADERBOARD CENTER');
  @override
  String get personalPodium => _t('PERSONAL PODIUM');
  @override
  String get podiumDescription =>
      _t('Courses are ranked by their fair Brain Score.');
  @override
  String get fiveCourseRanking => _t('11-COURSE RANKING');
  @override
  String get backHome => _t('BACK TO HOME');
  @override
  String get highestLeague => _t('Highest league reached');
  @override
  String nextLeague(String league, int score) => '$league: $score BP';
  @override
  String get worldFriendsLeaderboard => _t('WORLD & FRIENDS LEADERBOARD');
  @override
  String get onlineLeaderboardInfo => _t(
    'This area will unlock when real Firebase player data is connected. '
    'We do not show fake players or fake rankings.',
  );
  @override
  String completedOutOf(int value, int max) =>
      '$value/$max ${_t('levels').toLowerCase()}';
  @override
  String completedAndLevel(int completed, int levelValue) =>
      '$completed/10 ${_t('levels').toLowerCase()}  •  ${_t('Level')} $levelValue';
  @override
  String get worldRanking => _t('WORLD RANKING');
  @override
  String get liveLeaderboard => _t('LIVE LEADERBOARD');
  @override
  String get online => _t('ONLINE');
  @override
  String get offline => _t('OFFLINE');
  @override
  String get cached => _t('CACHED');
  @override
  String get cachedLeaderboardInfo =>
      _t('Showing the last verified world ranking. Reconnection is automatic.');
  @override
  String get scoreWaitingToSync => _t('Your latest score is waiting to sync');
  @override
  String get lastUpdateUnknown => _t('Last update time unavailable');
  @override
  String get updatedJustNow => _t('Updated just now');
  @override
  String updatedMinutesAgo(int value) =>
      '${_t('Updated')} $value ${_t('min ago')}';
  @override
  String updatedHoursAgo(int value) =>
      '${_t('Updated')} $value ${_t('hr ago')}';
  @override
  String updatedDaysAgo(int value) =>
      '${_t('Updated')} $value ${_t('days ago')}';
  @override
  String get retryNow => _t('Retry now');
  @override
  String get you => _t('YOU');
  @override
  String get noOnlinePlayers => _t(
    'No online players are visible yet. Be the first player on the board.',
  );
  @override
  String get firebaseSetupNeeded => _t(
    'Firebase is not connected yet. The personal leaderboard still works; '
    'complete Firebase setup to activate real world rankings.',
  );
  @override
  String get leaderboardSyncInfo => _t(
    'Your public leaderboard card contains only your player name, avatar and game statistics.',
  );
  @override
  String globalTop(int count) => '${_t('GLOBAL TOP')} $count';

  @override
  String get editProfile => _t('EDIT PROFILE');
  @override
  String get playerName => _t('PLAYER NAME');
  @override
  String get playerNameHint => _t('Player name');
  @override
  String get avatar => _t('AVATAR');
  @override
  String get save => _t('SAVE');
  @override
  String get profileTitle => _t('PROFILE');
  @override
  String get edit => _t('EDIT');
  @override
  String get achievements => _t('ACHIEVEMENTS');
  @override
  String get achievementsInfo => _t(
    'Badges unlock from the same progress used by your Brain Score and ranking.',
  );
  @override
  String get specialBadges => _t('SPECIAL BADGES');
  @override
  String get specialBadgesInfo =>
      _t('Rare badges earned from special course goals.');
  @override
  String get courseStats => _t('COURSE STATISTICS');
  @override
  String get playerLevel => _t('PLAYER LEVEL');
  @override
  String totalXp(int score) => '$score ${_t('total Brain Points')}';
  @override
  String get maxLevel => _t('Maximum level');
  @override
  String openLevel(int levelValue) => '${_t('Unlocked level')} $levelValue/10';
  @override
  String rankLabel(String raw) => _t(super.rankLabel(raw));
  @override
  String leagueLabel(String shortName) => _t(super.leagueLabel(shortName));
  @override
  String achievementTitle(String id) => _t(super.achievementTitle(id));
  @override
  String achievementDescription(String id) =>
      _t(super.achievementDescription(id));

  @override
  String gameUi(String raw) {
    final String english = super.gameUi(raw);
    final String exact = _t(english);
    if (exact != english) return exact;

    Match? match;
    match = RegExp(r'^Level (\d+) / (\d+)$').firstMatch(english);
    if (match != null) {
      return levelOutOf(int.parse(match.group(1)!), int.parse(match.group(2)!));
    }
    match = RegExp(r'^Level (\d+) completed$').firstMatch(english);
    if (match != null) {
      return '${_t('Level completed')} ${match.group(1)}';
    }
    match = RegExp(r'^Question (\d+) / (\d+)$').firstMatch(english);
    if (match != null) {
      return '${_t('Question')} ${match.group(1)} / ${match.group(2)}';
    }
    match = RegExp(r'^(\d+) correct$').firstMatch(english);
    if (match != null) return '${match.group(1)} ${_t('correct')}';
    match = RegExp(r'^(\d+) pts$').firstMatch(english);
    if (match != null) return '${match.group(1)} ${_t('pts')}';
    match = RegExp(r'^Best: (.+)$').firstMatch(english);
    if (match != null) return '${_t('Best')}: ${match.group(1)}';
    match = RegExp(r'^Target: (.+)$').firstMatch(english);
    if (match != null) return '${_t('Target')}: ${match.group(1)}';
    match = RegExp(r'^Average (.+) ms$').firstMatch(english);
    if (match != null) return '${_t('Average')} ${match.group(1)} ms';
    match = RegExp(r'^Score: (.+)$').firstMatch(english);
    if (match != null) return '${_t('Score')}: ${match.group(1)}';
    match = RegExp(r'^Round: (.+)$').firstMatch(english);
    if (match != null) return '${_t('Round')}: ${match.group(1)}';
    match = RegExp(r'^(\d+) / (\d+) filled · (\d+) clues$').firstMatch(english);
    if (match != null) {
      final String f = match.group(1)!;
      final String total = match.group(2)!;
      final String clues = match.group(3)!;
      switch (locale.languageCode.toLowerCase()) {
        case 'ar':
          return '$f / $total مكتمل · $clues أدلة';
        case 'es':
          return '$f / $total llenas · $clues pistas';
        case 'de':
          return '$f / $total gefüllt · $clues Hinweise';
        case 'fr':
          return '$f / $total remplies · $clues indices';
        case 'pt':
          return '$f / $total preenchidas · $clues dicas';
        case 'id':
          return '$f / $total terisi · $clues petunjuk';
        default:
          return '$f / $total filled · $clues clues';
      }
    }
    match = RegExp(r'^Selected cell ready · enter a value from 1 to (\d+)\.?$').firstMatch(english);
    if (match != null) {
      final String m = match.group(1)!;
      switch (locale.languageCode.toLowerCase()) {
        case 'ar':
          return 'الخلية جاهزة · أدخل رقماً من 1 إلى $m';
        case 'es':
          return 'Casilla lista · ingresa del 1 al $m';
        case 'de':
          return 'Feld bereit · Zahl von 1 bis $m eingeben';
        case 'fr':
          return 'Case prête · entrez de 1 à $m';
        case 'pt':
          return 'Célula pronta · digite de 1 a $m';
        case 'id':
          return 'Sel siap · masukkan nilai 1 sampai $m';
        default:
          return 'Selected cell ready · enter a value from 1 to $m';
      }
    }
    match = RegExp(r'^Select an empty cell, then choose 1[–-](\d+)\.?$').firstMatch(english);
    if (match != null) {
      final String m = match.group(1)!;
      switch (locale.languageCode.toLowerCase()) {
        case 'ar':
          return 'اختر خلية فارغة ثم رقم من 1 إلى $m';
        case 'es':
          return 'Elige una casilla vacía y luego 1–$m';
        case 'de':
          return 'Leeres Feld wählen, dann 1–$m';
        case 'fr':
          return 'Sélectionnez une case vide puis 1–$m';
        case 'pt':
          return 'Escolha uma célula vazia e depois 1–$m';
        case 'id':
          return 'Pilih sel kosong, lalu 1–$m';
        default:
          return 'Select an empty cell, then choose 1–$m';
      }
    }
    match = RegExp(r'^STAGE (\d+)$').firstMatch(english);
    if (match != null) {
      return '${_t('STAGE')} ${match.group(1)}';
    }
    match = RegExp(r'^PUZZLE (\d+)$').firstMatch(english);
    if (match != null) {
      return '${_t('PUZZLE')} ${match.group(1)}';
    }
    match = RegExp(r'^Completed round: (.+)$').firstMatch(english);
    if (match != null) return '${_t('Completed round')}: ${match.group(1)}';
    return english;
  }
}

// Order: Arabic, Indonesian, Brazilian Portuguese, Latin American Spanish,
// French, German.
const Map<String, List<String>> _globalText = <String, List<String>>{
  'EXPERT 9×9': <String>[
    'خبير 9×9',
    'AHLI 9×9',
    'ESPECIALISTA 9×9',
    'EXPERTO 9×9',
    'EXPERT 9×9',
    'EXPERTE 9×9',
  ],
  'CLASSIC 9×9': <String>[
    'كلاسيكي 9×9',
    'KLASIK 9×9',
    'CLÁSSICO 9×9',
    'CLÁSICO 9×9',
    'CLASSIQUE 9×9',
    'KLASSISCH 9×9',
  ],
  'MASTER 9×9': <String>[
    'أستاذ 9×9',
    'MASTER 9×9',
    'MESTRE 9×9',
    'MAESTRO 9×9',
    'MAÎTRE 9×9',
    'MEISTER 9×9',
  ],
  'ADVANCED 6×6': <String>[
    'متقدم 6×6',
    'LANJUTAN 6×6',
    'AVANÇADO 6×6',
    'AVANZADO 6×6',
    'AVANCÉ 6×6',
    'FORTGESCHRITTEN 6×6',
  ],
  'FOUNDATION': <String>[
    'أساسي',
    'DASAR',
    'FUNDAÇÃO',
    'FUNDAMENTO',
    'FONDATION',
    'GRUNDLAGEN',
  ],
  'MASTERY': <String>[
    'إتقان',
    'PENGUASAAN',
    'DOMÍNIO',
    'MAESTRÍA',
    'MAÎTRISE',
    'MEISTERSCHAFT',
  ],
  'SUDOKU 9×9': <String>[
    'سودوكو 9×9',
    'SUDOKU 9×9',
    'SUDOKU 9×9',
    'SUDOKU 9×9',
    'SUDOKU 9×9',
    'SUDOKU 9×9',
  ],
  'SUDOKU 6×6': <String>[
    'سودوكو 6×6',
    'SUDOKU 6×6',
    'SUDOKU 6×6',
    'SUDOKU 6×6',
    'SUDOKU 6×6',
    'SUDOKU 6×6',
  ],
  'GRID SOLVED': <String>[
    'تم حل الشبكة',
    'PAPAN SELESAI',
    'GRADE RESOLVIDA',
    'TABLERO RESUELTO',
    'GRILLE RESUELTE',
    'GITTER GELÖST',
  ],
  'LEVEL BOARD': <String>[
    'لوحة المراحل',
    'PAPAN LEVEL',
    'TABELA DE NÍVEIS',
    'TABLERO DE NIVELES',
    'TABLEAU DES NIVEAUX',
    'LEVEL-ÜBERSICHT',
  ],
  'NEXT SUDOKU': <String>[
    'السودوكو التالي',
    'SUDOKU BERIKUTNYA',
    'PRÓXIMO SUDOKU',
    'SIGUIENTE SUDOKU',
    'SUDOKU SUIVANT',
    'NÄCHSTES SUDOKU',
  ],
  'CHECK THE GRID': <String>[
    'تحقق من الشبكة',
    'PERIKSA KISI',
    'VERIFICAR GRADE',
    'COMPROBAR TABLERO',
    'VÉRIFIER LA GRILLE',
    'GITTER PRÜFEN',
  ],
  'NOTES': <String>[
    'ملاحظات',
    'CATATAN',
    'NOTAS',
    'NOTAS',
    'NOTES',
    'NOTIZEN',
  ],
  'NOTES ON': <String>[
    'ملاحظات مفعلة',
    'CATATAN AKTIF',
    'NOTAS ATIVAS',
    'NOTAS ACTIVAS',
    'NOTES ACTIVÉES',
    'NOTIZEN AN',
  ],
  'STAGE': <String>[
    'المرحلة',
    'TAHAP',
    'FASE',
    'ETAPA',
    'ÉTAPE',
    'STUFE',
  ],
  'PUZZLE': <String>[
    'لغز',
    'TEKA-TEKI',
    'ENIGMA',
    'PUZZLE',
    'PUZZLE',
    'RÄTSEL',
  ],
  'Selected cell ready · enter a value from 1 to 9.': <String>[
    'الخلية المحددة جاهزة · أدخل رقمًا من 1 إلى 9.',
    'Sel siap · masukkan angka 1 hingga 9.',
    'Célula pronta · digite de 1 a 9.',
    'Casilla lista · ingresa de 1 a 9.',
    'Case prête · entrez un chiffre de 1 à 9.',
    'Feld bereit · Zahl von 1 bis 9 eingeben.',
  ],
  'Pencil marks · choose candidates for the selected cell.': <String>[
    'وضع الملاحظات · اختر الأرقام المرشحة للخلية.',
    'Tanda pensil · pilih kandidat untuk sel terpilih.',
    'Modo rascunho · escolha candidatos para a célula.',
    'Modo lápiz · elige candidatos para la casilla.',
    'Mode crayon · choisissez des candidats.',
    'Notizen · Wähle Kandidaten für das Feld.',
  ],
  'Mind tools': <String>[
    'أدوات العقل',
    'Alat Pikiran',
    'Ferramentas Mentais',
    'Herramientas Mentales',
    'Outils de l’Esprit',
    'Denkwerkzeuge',
  ],
  'Useful, personal tools alongside the games.': <String>[
    'أدوات مفيدة وشخصية إلى جانب الألعاب.',
    'Alat yang berguna dan personal selain permainan.',
    'Ferramentas úteis e pessoais ao lado dos jogos.',
    'Herramientas útiles y prácticas junto a los juegos.',
    'Des outils utiles et personnels en plus des jeux.',
    'Nützliche persönliche Werkzeuge neben den Spielen.',
  ],
  'Smart Vocabulary Notebook': <String>[
    'دفتر المفردات الذكي',
    'Buku Kosakata Pintar',
    'Caderno Inteligente de Vocabulário',
    'Cuaderno de Vocabulario Inteligente',
    'Cahier de Vocabulaire Intelligent',
    'Intelligentes Vokabelheft',
  ],
  'Save your own words and review them on time.': <String>[
    'احفظ كلماتك الخاصة وراجعها في الوقت المناسب.',
    'Simpan kata-kata Anda sendiri dan tinjau tepat waktu.',
    'Guarde suas palavras e revise-as no momento certo.',
    'Guarda tus propias palabras y repásalas a tiempo.',
    'Enregistrez vos mots et révisez-les au bon moment.',
    'Speichere deine Wörter und wiederhole sie rechtzeitig.',
  ],
  'SHOPPING · TRAVEL · TO-DO': <String>[
    'تسوق · سفر · مهام',
    'BELANJA · PERJALANAN · TUGAS',
    'COMPRAS · VIAGEM · TAREFAS',
    'COMPRAS · VIAJES · TAREAS',
    'COURSES · VOYAGE · TÂCHES',
    'EINKAUFEN · REISEN · AUFGABEN',
  ],
  'Shopping & Prep Assistant': <String>[
    'مساعد التسوق والتحضير',
    'Asisten Belanja & Persiapan',
    'Assistente de Compras e Preparação',
    'Asistente de Compras y Preparación',
    'Assistant Courses et Préparatifs',
    'Einkaufs- und Vorbereitungsassistent',
  ],
  'Keep everyday lists together, right on your device.': <String>[
    'احتفظ بقوائمك اليومية معًا على جهازك.',
    'Satukan daftar harian langsung di perangkat Anda.',
    'Mantenha suas listas diárias juntas neste dispositivo.',
    'Mantén tus listas diarias juntas en este dispositivo.',
    'Gardez vos listes quotidiennes réunies sur votre appareil.',
    'Behalte deine täglichen Listen direkt auf diesem Gerät.',
  ],
  'READ · LISTEN · RECALL': <String>[
    'اقرأ · استمع · تذكر',
    'BACA · DENGAR · INGAT',
    'LEIA · OUÇA · RECORDE',
    'LEE · ESCUCHA · RECUERDA',
    'LIRE · ÉCOUTER · SE RAPPELER',
    'LESEN · HÖREN · ERINNERN',
  ],
  'Micro-stories & comprehension': <String>[
    'قصص قصيرة وفهم واستيعاب',
    'Cerita mikro & pemahaman',
    'Micro-histórias e compreensão',
    'Micro-historias y comprensión',
    'Micro-récits et compréhension',
    'Mikro-Geschichten & Verstehen',
  ],
  'Read or hear original short passages, then retrieve the details.': <String>[
    'اقرأ أو استمع لنصوص قصيرة ثم استرجع التفاصيل.',
    'Baca atau dengar teks pendek, lalu ingat detailnya.',
    'Leia ou ouça textos curtos e depois lembre-se dos detalhes.',
    'Lee o escucha textos breves y luego recuerda los detalles.',
    'Lisez ou écoutez de courts textes puis retrouvez les détails.',
    'Lies oder höre kurze Texte und rufe die Details ab.',
  ],
  'REAL-LIFE PRACTICE': <String>[
    'ممارسة من واقع الحياة',
    'LATIHAN KEHIDUPAN NYATA',
    'PRÁTICA DA VIDA REAL',
    'PRÁCTICA DE LA VIDA REAL',
    'PRATIQUE DU QUOTIDIEN',
    'ALLTAGSPRAXIS',
  ],
  'Daily Conversation Tasks': <String>[
    'مهام المحادثة اليومية',
    'Tugas Percakapan Harian',
    'Tarefas Diárias de Diálogo',
    'Tareas de Conversación Diaria',
    'Exercices de Dialogue Quotidien',
    'Tägliche Gesprächsaufgaben',
  ],
  'Practice clear, considerate choices in useful scenarios.': <String>[
    'تدرّب على خيارات واضحة ومراعية في مواقف مفيدة.',
    'Latih pilihan yang jelas dan penuh pertimbangan.',
    'Pratique escolhas claras e atenciosas em cenários úteis.',
    'Practica decisiones claras y consideradas en situaciones útiles.',
    'Exercez des choix clairs et bienveillants en situation réelle.',
    'Übe klare, umsichtige Entscheidungen in nützlichen Szenarien.',
  ],
  'Mind Arena': <String>[
    'مضمار الذكاء',
    'Arena Otak',
    'Arena Mental',
    'Pista Mental',
    'Arène Mentale',
    'Geist Arena',
  ],
  'Categories': <String>[
    'الفئات',
    'Kategori',
    'Categorias',
    'Categorías',
    'Catégories',
    'Kategorien',
  ],
  'Challenge Your Friends': <String>[
    'تحدَّ أصدقاءك',
    'Tantang Teman Anda',
    'Desafie seus Amigos',
    'Desafía a tus Amigos',
    'Défiez vos Amis',
    'Fordere Freunde heraus',
  ],
  'Live duels, room codes & rank race': <String>[
    'مبارزات حية ورموز الغرف',
    'Duel langsung & kode ruangan',
    'Duelos ao vivo e códigos de sala',
    'Duelos en vivo y códigos de sala',
    'Duels en direct et codes de salon',
    'Live-Duelle & Raumcodes',
  ],
  'WHATSAPP & ARENA': <String>[
    'واتساب والمضمار',
    'WHATSAPP & ARENA',
    'WHATSAPP & ARENA',
    'WHATSAPP Y ARENA',
    'WHATSAPP & ARÈNE',
    'WHATSAPP & ARENA',
  ],
  "Today's Brain Course": <String>[
    'مسار العقل اليومي',
    'Sirkuit Otak Harian',
    'Circuito Mental Diário',
    'Circuito Mental Diario',
    'Parcours Cérébral du Jour',
    'Täglicher Gehirnparcours',
  ],
  'Settings': <String>[
    'الإعدادات',
    'Pengaturan',
    'Configurações',
    'Ajustes',
    'Paramètres',
    'Einstellungen',
  ],
  'Home': <String>[
    'الرئيسية',
    'Beranda',
    'Início',
    'Inicio',
    'Accueil',
    'Start',
  ],
  'Challenges': <String>[
    'التحديات',
    'Tantangan',
    'Desafios',
    'Desafíos',
    'Défis',
    'Herausforderungen',
  ],
  'Leaderboard': <String>[
    'لوحة الصدارة',
    'Papan Peringkat',
    'Classificação',
    'Clasificación',
    'Classement',
    'Bestenliste',
  ],
  'Profile': <String>[
    'الملف الشخصي',
    'Profil',
    'Perfil',
    'Perfil',
    'Profil',
    'Profil',
  ],
  'Level': <String>['المستوى', 'Level', 'Nível', 'Nivel', 'Niveau', 'Level'],
  'Score': <String>[
    'النقاط',
    'Skor',
    'Pontuação',
    'Puntuación',
    'Score',
    'Punkte',
  ],
  'Stars': <String>[
    'النجوم',
    'Bintang',
    'Estrelas',
    'Estrellas',
    'Étoiles',
    'Sterne',
  ],
  'Levels': <String>[
    'المستويات',
    'Level',
    'Níveis',
    'Niveles',
    'Niveaux',
    'Level',
  ],
  'levels': <String>[
    'مستويات',
    'level',
    'níveis',
    'niveles',
    'niveaux',
    'Level',
  ],
  'OVERALL PROGRESS': <String>[
    'التقدم العام',
    'PROGRES KESELURUHAN',
    'PROGRESSO GERAL',
    'PROGRESO GENERAL',
    'PROGRESSION GLOBALE',
    'GESAMTFORTSCHRITT',
  ],
  'BRAIN SCORE': <String>[
    'نقاط الذكاء',
    'SKOR OTAK',
    'PONTUAÇÃO MENTAL',
    'PUNTUACIÓN MENTAL',
    'SCORE CÉRÉBRAL',
    'DENKPUNKTE',
  ],
  'Player': <String>[
    'اللاعب',
    'Pemain',
    'Jogador',
    'Jugador',
    'Joueur',
    'Spieler',
  ],
  'COMING SOON': <String>[
    'قريبًا',
    'SEGERA HADIR',
    'EM BREVE',
    'PRÓXIMAMENTE',
    'BIENTÔT',
    'BALD VERFÜGBAR',
  ],
  'days': <String>['أيام', 'hari', 'dias', 'días', 'jours', 'Tage'],
  'challenges': <String>[
    'تحديات',
    'tantangan',
    'desafios',
    'desafíos',
    'défis',
    'Aufgaben',
  ],
  'COURSES': <String>[
    'المسارات',
    'JALUR',
    'PERCURSOS',
    'RECORRIDOS',
    'PARCOURS',
    'PARCOURS',
  ],
  'Train your mind across 11 different skill areas.': <String>[
    'درّب عقلك في 11 مجالًا مختلفًا.',
    'Latih pikiranmu di 11 bidang kemampuan berbeda.',
    'Treine sua mente em 11 áreas diferentes.',
    'Entrena tu mente en 11 áreas diferentes.',
    'Entraîne ton esprit dans 11 domaines différents.',
    'Trainiere deinen Geist in 11 verschiedenen Bereichen.',
  ],
  'This course is not available yet.': <String>[
    'هذا المسار غير متاح بعد.',
    'Jalur ini belum tersedia.',
    'Este percurso ainda não está disponível.',
    'Este recorrido aún no está disponible.',
    'Ce parcours n’est pas encore disponible.',
    'Dieser Parcours ist noch nicht verfügbar.',
  ],
  'DAILY COURSE': <String>[
    'المسار اليومي',
    'JALUR HARIAN',
    'PERCURSO DIÁRIO',
    'RECORRIDO DIARIO',
    'PARCOURS DU JOUR',
    'TAGESPARCOURS',
  ],
  'DAY STREAK': <String>[
    'سلسلة أيام',
    'HARI BERUNTUN',
    'DIAS SEGUIDOS',
    'DÍAS SEGUIDOS',
    'JOURS DE SUITE',
    'TAGE IN FOLGE',
  ],
  'challenges completed': <String>[
    'تحديات مكتملة',
    'tantangan selesai',
    'desafios concluídos',
    'desafíos completados',
    'défis terminés',
    'Aufgaben erledigt',
  ],
  'View challenges': <String>[
    'عرض التحديات',
    'Lihat tantangan',
    'Ver desafios',
    'Ver desafíos',
    'Voir les défis',
    'Aufgaben ansehen',
  ],

  'Logic Maze': <String>[
    'متاهة المنطق',
    'Labirin Logika',
    'Labirinto Lógico',
    'Laberinto Lógico',
    'Labyrinthe Logique',
    'Logik-Labyrinth',
  ],
  'Number Master': <String>[
    'سيد الأرقام',
    'Ahli Angka',
    'Mestre dos Números',
    'Maestro de Números',
    'Maître des Nombres',
    'Zahlenmeister',
  ],
  'Block Workshop': <String>[
    'ورشة المكعبات',
    'Bengkel Blok',
    'Oficina de Blocos',
    'Taller de Bloques',
    'Atelier de Blocs',
    'Block-Werkstatt',
  ],
  'Memory Maze': <String>[
    'متاهة الذاكرة',
    'Labirin Memori',
    'Labirinto da Memória',
    'Laberinto de Memoria',
    'Labyrinthe de Mémoire',
    'Gedächtnis-Labyrinth',
  ],
  'Tower of Hanoi': <String>[
    'برج هانوي',
    'Menara Hanoi',
    'Torre de Hanói',
    'Torre de Hanói',
    'Tours de Hanoï',
    'Turm von Hanoi',
  ],
  'Word Hunt': <String>[
    'البحث عن الكلمات',
    'Perburuan Kata',
    'Caça-Palavras',
    'Caza de Palabras',
    'Chasse aux Mots',
    'Wörtersuche',
  ],
  'Visual IQ': <String>[
    'الذكاء البصري',
    'IQ Visual',
    'QI Visual',
    'CI Visual',
    'QI Visuel',
    'Visueller IQ',
  ],
  'Candy Sort': <String>[
    'فرز الحلوى',
    'Susun Permen',
    'Classificar Doces',
    'Ordenar Dulces',
    'Tri de bonbons',
    'Bonbons sortieren',
  ],
  '15-Tile Master': <String>[
    'لغز 15 قطعة',
    'Teka-teki 15 ubin',
    'Quebra-cabeça de 15 peças',
    'Rompecabezas de 15 fichas',
    'Puzzle à 15 cases',
    '15er-Schiebepuzzle',
  ],
  'Shape Merge': <String>[
    'دمج الأشكال',
    'Gabung Bentuk',
    'Combinar Formas',
    'Combinar Formas',
    'Fusion de Formes',
    'Formen verbinden',
  ],
  'Reflex Hunt': <String>[
    'تحدي رد الفعل',
    'Perburuan Refleks',
    'Caça ao Reflexo',
    'Caza de Reflejos',
    'Chasse aux Réflexes',
    'Reflexjagd',
  ],
  'Explore the paths and reach the goal.': <String>[
    'استكشف المسارات واصل إلى الهدف.',
    'Jelajahi jalur dan capai tujuan.',
    'Explore os caminhos e alcance o objetivo.',
    'Explora los caminos y llega a la meta.',
    'Explore les chemins et atteins l’objectif.',
    'Erkunde die Wege und erreiche das Ziel.',
  ],
  'Solve sequences and number patterns.': <String>[
    'حل المتتاليات وأنماط الأرقام.',
    'Pecahkan urutan dan pola angka.',
    'Resolva sequências e padrões numéricos.',
    'Resuelve secuencias y patrones numéricos.',
    'Résous des suites et des motifs numériques.',
    'Löse Zahlenfolgen und Zahlenmuster.',
  ],
  'Drag the pieces and complete the target pattern.': <String>[
    'اسحب القطع وأكمل النمط المطلوب.',
    'Seret kepingan dan selesaikan pola target.',
    'Arraste as peças e complete o padrão.',
    'Arrastra las piezas y completa el patrón.',
    'Fais glisser les pièces et complète le motif.',
    'Ziehe die Teile und vervollständige das Muster.',
  ],
  'Observe, remember and make the right choice.': <String>[
    'راقب وتذكر واختر بشكل صحيح.',
    'Amati, ingat, lalu pilih dengan benar.',
    'Observe, memorize e faça a escolha certa.',
    'Observa, recuerda y elige correctamente.',
    'Observe, mémorise et fais le bon choix.',
    'Beobachte, merke dir alles und wähle richtig.',
  ],
  'Plan your moves and rebuild the colorful tower.': <String>[
    'خطط لحركاتك وأعد بناء البرج الملون.',
    'Rencanakan langkah dan bangun kembali menara warna-warni.',
    'Planeje seus movimentos e reconstrua a torre colorida.',
    'Planifica tus movimientos y reconstruye la torre de colores.',
    'Planifie tes mouvements et reconstruis la tour colorée.',
    'Plane deine Züge und baue den bunten Turm neu auf.',
  ],
  'Find hidden words in growing grids.': <String>[
    'اعثر على الكلمات المخفية في شبكات متزايدة.',
    'Temukan kata tersembunyi di papan yang makin besar.',
    'Encontre palavras escondidas em grades crescentes.',
    'Encuentra palabras ocultas en cuadrículas crecientes.',
    'Trouve les mots cachés dans des grilles grandissantes.',
    'Finde versteckte Wörter in immer größeren Gittern.',
  ],
  'Decode visual transformations and analogies.': <String>[
    'حل التحولات والقياسات البصرية.',
    'Pecahkan transformasi dan analogi visual.',
    'Decifre transformações e analogias visuais.',
    'Descifra transformaciones y analogías visuales.',
    'Décode les transformations et analogies visuelles.',
    'Entschlüssle visuelle Veränderungen und Analogien.',
  ],
  'Group colorful candies with smart moves.': <String>[
    'اجمع الحلوى الملونة بحركات ذكية.',
    'Kelompokkan permen warna-warni dengan langkah cerdas.',
    'Agrupe os doces coloridos com movimentos inteligentes.',
    'Agrupa los dulces de colores con movimientos inteligentes.',
    'Regroupe les bonbons colorés avec des mouvements malins.',
    'Sortiere bunte Bonbons mit cleveren Zügen.',
  ],
  'Slide 8 and 15 tiles into order.': <String>[
    'رتب قطعتي 8 و15 بالتحريك.',
    'Geser ubin 8 dan 15 hingga berurutan.',
    'Deslize as peças 8 e 15 para colocá-las em ordem.',
    'Desliza las fichas 8 y 15 hasta ordenarlas.',
    'Fais glisser les tuiles 8 et 15 pour les remettre en ordre.',
    'Schiebe die 8er- und 15er-Steine in die richtige Reihenfolge.',
  ],
  'Combine fragments and find the final silhouette.': <String>[
    'ادمج الأجزاء واكتشف الشكل النهائي.',
    'Gabungkan potongan dan temukan siluet akhirnya.',
    'Combine os fragmentos e descubra a silhueta final.',
    'Combina los fragmentos y descubre la silueta final.',
    'Assemble les fragments et trouve la silhouette finale.',
    'Verbinde die Teile und finde die endgültige Silhouette.',
  ],
  'React quickly and avoid misleading targets.': <String>[
    'استجب بسرعة وتجنب الأهداف المضللة.',
    'Bereaksi cepat dan hindari target pengecoh.',
    'Reaja rápido e evite os alvos enganosos.',
    'Reacciona rápido y evita los objetivos engañosos.',
    'Réagis vite et évite les cibles trompeuses.',
    'Reagiere schnell und meide falsche Ziele.',
  ],

  'SETTINGS': <String>[
    'الإعدادات',
    'PENGATURAN',
    'CONFIGURAÇÕES',
    'AJUSTES',
    'PARAMÈTRES',
    'EINSTELLUNGEN',
  ],
  'GAME EXPERIENCE': <String>[
    'تجربة اللعب',
    'PENGALAMAN BERMAIN',
    'EXPERIÊNCIA DE JOGO',
    'EXPERIENCIA DE JUEGO',
    'EXPÉRIENCE DE JEU',
    'SPIELERLEBNIS',
  ],
  'Language': <String>[
    'اللغة',
    'Bahasa',
    'Idioma',
    'Idioma',
    'Langue',
    'Sprache',
  ],
  'Choose the app language or follow your phone language.': <String>[
    'اختر لغة التطبيق أو استخدم لغة هاتفك.',
    'Pilih bahasa aplikasi atau ikuti bahasa ponsel.',
    'Escolha o idioma do aplicativo ou use o idioma do celular.',
    'Elige el idioma de la aplicación o usa el del teléfono.',
    'Choisis la langue de l’application ou celle du téléphone.',
    'Wähle die App-Sprache oder übernimm die Systemsprache.',
  ],
  'Automatic (System)': <String>[
    'تلقائي (النظام)',
    'Otomatis (Sistem)',
    'Automático (Sistema)',
    'Automático (Sistema)',
    'Automatique (Système)',
    'Automatisch (System)',
  ],
  'Your language preference is saved on this device.': <String>[
    'يتم حفظ اختيار اللغة على هذا الجهاز.',
    'Pilihan bahasa disimpan di perangkat ini.',
    'Sua preferência de idioma é salva neste dispositivo.',
    'Tu preferencia de idioma se guarda en este dispositivo.',
    'Ton choix de langue est enregistré sur cet appareil.',
    'Deine Sprachauswahl wird auf diesem Gerät gespeichert.',
  ],
  'Sound Effects': <String>[
    'المؤثرات الصوتية',
    'Efek Suara',
    'Efeitos Sonoros',
    'Efectos de Sonido',
    'Effets Sonores',
    'Soundeffekte',
  ],
  'Tap, correct answer, combo and level-complete sounds.': <String>[
    'أصوات اللمس والإجابة الصحيحة والمجموعة وإكمال المستوى.',
    'Suara sentuhan, jawaban benar, kombo, dan level selesai.',
    'Sons de toque, resposta correta, combo e nível concluído.',
    'Sonidos de toque, respuesta correcta, combo y nivel completado.',
    'Sons de toucher, bonne réponse, combo et niveau terminé.',
    'Töne für Tippen, richtige Antworten, Kombos und Levelabschluss.',
  ],
  'Use sound effects': <String>[
    'استخدام المؤثرات الصوتية',
    'Gunakan efek suara',
    'Usar efeitos sonoros',
    'Usar efectos de sonido',
    'Utiliser les effets sonores',
    'Soundeffekte verwenden',
  ],
  'On': <String>['مفعّل', 'Aktif', 'Ligado', 'Activado', 'Activé', 'Ein'],
  'Off': <String>[
    'متوقف',
    'Nonaktif',
    'Desligado',
    'Desactivado',
    'Désactivé',
    'Aus',
  ],
  'Effects volume': <String>[
    'مستوى المؤثرات',
    'Volume efek',
    'Volume dos efeitos',
    'Volumen de efectos',
    'Volume des effets',
    'Effektlautstärke',
  ],
  'TEST EFFECT': <String>[
    'اختبار المؤثر',
    'UJI EFEK',
    'TESTAR EFEITO',
    'PROBAR EFECTO',
    'TESTER L’EFFET',
    'EFFEKT TESTEN',
  ],
  'Music': <String>[
    'الموسيقى',
    'Musik',
    'Música',
    'Música',
    'Musique',
    'Musik',
  ],
  'Game music plays at a lower level than sound effects.': <String>[
    'تعمل موسيقى اللعبة بصوت أخفض من المؤثرات.',
    'Musik game diputar lebih pelan daripada efek suara.',
    'A música toca mais baixo que os efeitos sonoros.',
    'La música suena más baja que los efectos de sonido.',
    'La musique joue moins fort que les effets sonores.',
    'Die Spielmusik ist leiser als die Soundeffekte.',
  ],
  'Use music': <String>[
    'استخدام الموسيقى',
    'Gunakan musik',
    'Usar música',
    'Usar música',
    'Utiliser la musique',
    'Musik verwenden',
  ],
  'Music volume': <String>[
    'مستوى الموسيقى',
    'Volume musik',
    'Volume da música',
    'Volumen de música',
    'Volume de la musique',
    'Musiklautstärke',
  ],
  'STOP MUSIC': <String>[
    'إيقاف الموسيقى',
    'HENTIKAN MUSIK',
    'PARAR MÚSICA',
    'DETENER MÚSICA',
    'ARRÊTER LA MUSIQUE',
    'MUSIK STOPPEN',
  ],
  'TEST MUSIC': <String>[
    'اختبار الموسيقى',
    'UJI MUSIK',
    'TESTAR MÚSICA',
    'PROBAR MÚSICA',
    'TESTER LA MUSIQUE',
    'MUSIK TESTEN',
  ],
  'Haptics': <String>[
    'الاهتزاز',
    'Getaran',
    'Vibração',
    'Vibración',
    'Vibrations',
    'Haptik',
  ],
  'Tactile feedback during selections, moves and correct answers.': <String>[
    'اهتزاز عند الاختيار والحركة والإجابة الصحيحة.',
    'Umpan balik getar saat memilih, bergerak, dan menjawab benar.',
    'Retorno tátil em escolhas, movimentos e respostas corretas.',
    'Respuesta táctil en selecciones, movimientos y respuestas correctas.',
    'Retour tactile lors des choix, mouvements et bonnes réponses.',
    'Haptisches Feedback bei Auswahl, Zügen und richtigen Antworten.',
  ],
  'Use haptics': <String>[
    'استخدام الاهتزاز',
    'Gunakan getaran',
    'Usar vibração',
    'Usar vibración',
    'Utiliser les vibrations',
    'Haptik verwenden',
  ],
  'RESTORE DEFAULT SETTINGS': <String>[
    'استعادة الإعدادات الافتراضية',
    'PULIHKAN PENGATURAN AWAL',
    'RESTAURAR PADRÕES',
    'RESTAURAR AJUSTES',
    'RÉTABLIR LES PARAMÈTRES',
    'STANDARDEINSTELLUNGEN',
  ],
  'Your settings are saved automatically on this device.': <String>[
    'يتم حفظ إعداداتك تلقائيًا على هذا الجهاز.',
    'Pengaturan disimpan otomatis di perangkat ini.',
    'Suas configurações são salvas automaticamente neste dispositivo.',
    'Tus ajustes se guardan automáticamente en este dispositivo.',
    'Tes paramètres sont enregistrés automatiquement sur cet appareil.',
    'Deine Einstellungen werden automatisch auf diesem Gerät gespeichert.',
  ],
  'Effects on': <String>[
    'المؤثرات مفعّلة',
    'Efek aktif',
    'Efeitos ligados',
    'Efectos activados',
    'Effets activés',
    'Effekte ein',
  ],
  'Effects off': <String>[
    'المؤثرات متوقفة',
    'Efek nonaktif',
    'Efeitos desligados',
    'Efectos desactivados',
    'Effets désactivés',
    'Effekte aus',
  ],
  'Music on': <String>[
    'الموسيقى مفعّلة',
    'Musik aktif',
    'Música ligada',
    'Música activada',
    'Musique activée',
    'Musik ein',
  ],
  'Music off': <String>[
    'الموسيقى متوقفة',
    'Musik nonaktif',
    'Música desligada',
    'Música desactivada',
    'Musique désactivée',
    'Musik aus',
  ],
  'Haptics on': <String>[
    'الاهتزاز مفعّل',
    'Getaran aktif',
    'Vibração ligada',
    'Vibración activada',
    'Vibrations activées',
    'Haptik ein',
  ],
  'Haptics off': <String>[
    'الاهتزاز متوقف',
    'Getaran nonaktif',
    'Vibração desligada',
    'Vibración desactivada',
    'Vibrations désactivées',
    'Haptik aus',
  ],

  'DAILY CHALLENGES': <String>[
    'التحديات اليومية',
    'TANTANGAN HARIAN',
    'DESAFIOS DIÁRIOS',
    'DESAFÍOS DIARIOS',
    'DÉFIS QUOTIDIENS',
    'TÄGLICHE AUFGABEN',
  ],
  "TODAY'S GOALS": <String>[
    'أهداف اليوم',
    'TARGET HARI INI',
    'METAS DE HOJE',
    'OBJETIVOS DE HOY',
    'OBJECTIFS DU JOUR',
    'HEUTIGE ZIELE',
  ],
  'BACK TO GAME': <String>[
    'العودة إلى اللعبة',
    'KEMBALI KE GAME',
    'VOLTAR AO JOGO',
    'VOLVER AL JUEGO',
    'RETOUR AU JEU',
    'ZURÜCK ZUM SPIEL',
  ],
  "Today's streak is secured.": <String>[
    'تم الحفاظ على سلسلة اليوم.',
    'Rangkaian hari ini aman.',
    'A sequência de hoje está garantida.',
    'La racha de hoy está asegurada.',
    'La série du jour est assurée.',
    'Deine heutige Serie ist gesichert.',
  ],
  'Complete a level today to keep your streak alive.': <String>[
    'أكمل مستوى اليوم للحفاظ على السلسلة.',
    'Selesaikan satu level hari ini untuk menjaga rangkaian.',
    'Conclua um nível hoje para manter a sequência.',
    'Completa un nivel hoy para mantener la racha.',
    'Termine un niveau aujourd’hui pour conserver ta série.',
    'Schließe heute ein Level ab, um deine Serie zu halten.',
  ],
  'DAILY STREAK': <String>[
    'السلسلة اليومية',
    'RANGKAIAN HARIAN',
    'SEQUÊNCIA DIÁRIA',
    'RACHA DIARIA',
    'SÉRIE QUOTIDIENNE',
    'TAGESERIE',
  ],
  'BEST STREAK': <String>[
    'أفضل سلسلة',
    'RANGKAIAN TERBAIK',
    'MELHOR SEQUÊNCIA',
    'MEJOR RACHA',
    'MEILLEURE SÉRIE',
    'BESTE SERIE',
  ],
  'PERFECT DAY': <String>[
    'يوم مثالي',
    'HARI SEMPURNA',
    'DIA PERFEITO',
    'DÍA PERFECTO',
    'JOURNÉE PARFAITE',
    'PERFEKTER TAG',
  ],
  'TODAY': <String>['اليوم', 'HARI INI', 'HOJE', 'HOY', 'AUJOURD’HUI', 'HEUTE'],
  'DAILY COURSE COMPLETED': <String>[
    'اكتمل المسار اليومي',
    'JALUR HARIAN SELESAI',
    'PERCURSO DIÁRIO CONCLUÍDO',
    'RECORRIDO DIARIO COMPLETADO',
    'PARCOURS DU JOUR TERMINÉ',
    'TAGESPARCOURS ABGESCHLOSSEN',
  ],
  'Warm-Up': <String>[
    'إحماء',
    'Pemanasan',
    'Aquecimento',
    'Calentamiento',
    'Échauffement',
    'Aufwärmen',
  ],
  'Star Hunter': <String>[
    'صياد النجوم',
    'Pemburu Bintang',
    'Caçador de Estrelas',
    'Cazador de Estrellas',
    'Chasseur d’Étoiles',
    'Sternenjäger',
  ],
  'Course Explorer': <String>[
    'مستكشف المسارات',
    'Penjelajah Jalur',
    'Explorador de Percursos',
    'Explorador de Recorridos',
    'Explorateur de Parcours',
    'Parcours-Entdecker',
  ],
  'Score Rush': <String>[
    'اندفاع النقاط',
    'Kejar Skor',
    'Corrida de Pontos',
    'Carrera de Puntos',
    'Course aux Points',
    'Punktejagd',
  ],
  'Perfect Run': <String>[
    'جولة مثالية',
    'Putaran Sempurna',
    'Rodada Perfeita',
    'Ronda Perfecta',
    'Parcours Parfait',
    'Perfekte Runde',
  ],
  "Today's Course": <String>[
    'مسار اليوم',
    'Jalur Hari Ini',
    'Percurso de Hoje',
    'Recorrido de Hoy',
    'Parcours du Jour',
    'Heutiger Parcours',
  ],
  'Daily Challenge': <String>[
    'التحدي اليومي',
    'Tantangan Harian',
    'Desafio Diário',
    'Desafío Diario',
    'Défi Quotidien',
    'Tagesaufgabe',
  ],
  'Complete 2 levels today.': <String>[
    'أكمل مستويين اليوم.',
    'Selesaikan 2 level hari ini.',
    'Conclua 2 níveis hoje.',
    'Completa 2 niveles hoy.',
    'Termine 2 niveaux aujourd’hui.',
    'Schließe heute 2 Level ab.',
  ],
  'Earn a total of 5 stars from completed levels.': <String>[
    'اجمع 5 نجوم من المستويات المكتملة.',
    'Dapatkan total 5 bintang dari level yang selesai.',
    'Ganhe 5 estrelas nos níveis concluídos.',
    'Consigue 5 estrellas en los niveles completados.',
    'Gagne 5 étoiles dans les niveaux terminés.',
    'Sammle insgesamt 5 Sterne.',
  ],
  'Complete levels in 2 different mind courses.': <String>[
    'أكمل مستويات في مسارين مختلفين.',
    'Selesaikan level di 2 jalur pikiran berbeda.',
    'Conclua níveis em 2 percursos mentais diferentes.',
    'Completa niveles en 2 recorridos mentales distintos.',
    'Termine des niveaux dans 2 parcours différents.',
    'Schließe Level in 2 verschiedenen Parcours ab.',
  ],
  'Earn a total of 700 Brain Points from today’s levels.': <String>[
    'اجمع 700 نقطة ذكاء من مستويات اليوم.',
    'Raih total 700 Poin Otak dari level hari ini.',
    'Ganhe 700 Pontos Mentais nos níveis de hoje.',
    'Consigue 700 Puntos Mentales en los niveles de hoy.',
    'Gagne 700 Points Cérébraux dans les niveaux du jour.',
    'Erreiche heute insgesamt 700 Denkpunkte.',
  ],
  'Complete one level with 3 stars.': <String>[
    'أكمل مستوى واحدًا بثلاث نجوم.',
    'Selesaikan satu level dengan 3 bintang.',
    'Conclua um nível com 3 estrelas.',
    'Completa un nivel con 3 estrellas.',
    'Termine un niveau avec 3 étoiles.',
    'Schließe ein Level mit 3 Sternen ab.',
  ],
  'Complete at least one level in': <String>[
    'أكمل مستوى واحدًا على الأقل في',
    'Selesaikan setidaknya satu level di',
    'Conclua pelo menos um nível em',
    'Completa al menos un nivel en',
    'Termine au moins un niveau dans',
    'Schließe mindestens ein Level ab in',
  ],

  'LEADERBOARD CENTER': <String>[
    'مركز الصدارة',
    'PUSAT PERINGKAT',
    'CENTRAL DE CLASSIFICAÇÃO',
    'CENTRO DE CLASIFICACIÓN',
    'CENTRE DU CLASSEMENT',
    'BESTENLISTEN-ZENTRALE',
  ],
  'PERSONAL PODIUM': <String>[
    'منصتك الشخصية',
    'PODIUM PRIBADI',
    'PÓDIO PESSOAL',
    'PODIO PERSONAL',
    'PODIUM PERSONNEL',
    'PERSÖNLICHES PODEST',
  ],
  'Courses are ranked by their fair Brain Score.': <String>[
    'يتم ترتيب المسارات حسب نقاط الذكاء العادلة.',
    'Jalur diurutkan berdasarkan Skor Otak yang adil.',
    'Os percursos são classificados pela Pontuação Mental justa.',
    'Los recorridos se ordenan por su Puntuación Mental justa.',
    'Les parcours sont classés selon leur Score Cérébral équitable.',
    'Die Parcours werden nach fairen Denkpunkten sortiert.',
  ],
  '11-COURSE RANKING': <String>[
    'ترتيب 11 مسارًا',
    'PERINGKAT 11 JALUR',
    'RANKING DE 11 PERCURSOS',
    'CLASIFICACIÓN DE 11 RECORRIDOS',
    'CLASSEMENT DES 11 PARCOURS',
    'RANGLISTE DER 11 PARCOURS',
  ],
  'BACK TO HOME': <String>[
    'العودة للرئيسية',
    'KEMBALI KE BERANDA',
    'VOLTAR AO INÍCIO',
    'VOLVER AL INICIO',
    'RETOUR À L’ACCUEIL',
    'ZURÜCK ZUM START',
  ],
  'Highest league reached': <String>[
    'أعلى دوري وصلت إليه',
    'Liga tertinggi yang dicapai',
    'Liga mais alta alcançada',
    'Liga más alta alcanzada',
    'Plus haute ligue atteinte',
    'Höchste erreichte Liga',
  ],
  'WORLD & FRIENDS LEADERBOARD': <String>[
    'ترتيب العالم والأصدقاء',
    'PERINGKAT DUNIA & TEMAN',
    'RANKING MUNDIAL E DE AMIGOS',
    'CLASIFICACIÓN MUNDIAL Y DE AMIGOS',
    'CLASSEMENT MONDIAL ET AMIS',
    'WELT- & FREUNDE-BESTENLISTE',
  ],
  'WORLD RANKING': <String>[
    'الترتيب العالمي',
    'PERINGKAT DUNIA',
    'RANKING MUNDIAL',
    'CLASIFICACIÓN MUNDIAL',
    'CLASSEMENT MONDIAL',
    'WELTRANGLISTE',
  ],
  'LIVE LEADERBOARD': <String>[
    'لوحة صدارة مباشرة',
    'PERINGKAT LANGSUNG',
    'CLASSIFICAÇÃO AO VIVO',
    'CLASIFICACIÓN EN VIVO',
    'CLASSEMENT EN DIRECT',
    'LIVE-BESTENLISTE',
  ],
  'ONLINE': <String>[
    'متصل',
    'ONLINE',
    'ONLINE',
    'EN LÍNEA',
    'EN LIGNE',
    'ONLINE',
  ],
  'OFFLINE': <String>[
    'غير متصل',
    'OFFLINE',
    'OFFLINE',
    'SIN CONEXIÓN',
    'HORS LIGNE',
    'OFFLINE',
  ],
  'CACHED': <String>[
    'محفوظ',
    'CACHE',
    'EM CACHE',
    'EN CACHÉ',
    'EN CACHE',
    'ZWISCHENGESPEICHERT',
  ],
  'Updated': <String>[
    'تم التحديث منذ',
    'Diperbarui',
    'Atualizado há',
    'Actualizado hace',
    'Mis à jour il y a',
    'Aktualisiert vor',
  ],
  'min ago': <String>['دقيقة', 'mnt lalu', 'min', 'min', 'min', 'Min.'],
  'hr ago': <String>['ساعة', 'jam lalu', 'h', 'h', 'h', 'Std.'],
  'days ago': <String>['يومًا', 'hari lalu', 'dias', 'días', 'jours', 'Tagen'],
  'Retry now': <String>[
    'أعد المحاولة الآن',
    'Coba lagi sekarang',
    'Tentar novamente',
    'Reintentar ahora',
    'Réessayer',
    'Jetzt erneut versuchen',
  ],
  'YOU': <String>['أنت', 'KAMU', 'VOCÊ', 'TÚ', 'TOI', 'DU'],
  'GLOBAL TOP': <String>[
    'أفضل عالميًا',
    'TERATAS DUNIA',
    'TOP GLOBAL',
    'TOP MUNDIAL',
    'TOP MONDIAL',
    'WELTWEIT TOP',
  ],

  'EDIT PROFILE': <String>[
    'تعديل الملف الشخصي',
    'EDIT PROFIL',
    'EDITAR PERFIL',
    'EDITAR PERFIL',
    'MODIFIER LE PROFIL',
    'PROFIL BEARBEITEN',
  ],
  'PLAYER NAME': <String>[
    'اسم اللاعب',
    'NAMA PEMAIN',
    'NOME DO JOGADOR',
    'NOMBRE DEL JUGADOR',
    'NOM DU JOUEUR',
    'SPIELERNAME',
  ],
  'Player name': <String>[
    'اسم اللاعب',
    'Nama pemain',
    'Nome do jogador',
    'Nombre del jugador',
    'Nom du joueur',
    'Spielername',
  ],
  'AVATAR': <String>[
    'الصورة الرمزية',
    'AVATAR',
    'AVATAR',
    'AVATAR',
    'AVATAR',
    'AVATAR',
  ],
  'SAVE': <String>[
    'حفظ',
    'SIMPAN',
    'SALVAR',
    'GUARDAR',
    'ENREGISTRER',
    'SPEICHERN',
  ],
  'PROFILE': <String>[
    'الملف الشخصي',
    'PROFIL',
    'PERFIL',
    'PERFIL',
    'PROFIL',
    'PROFIL',
  ],
  'EDIT': <String>[
    'تعديل',
    'EDIT',
    'EDITAR',
    'EDITAR',
    'MODIFIER',
    'BEARBEITEN',
  ],
  'ACHIEVEMENTS': <String>[
    'الإنجازات',
    'PENCAPAIAN',
    'CONQUISTAS',
    'LOGROS',
    'SUCCÈS',
    'ERFOLGE',
  ],
  'SPECIAL BADGES': <String>[
    'الشارات الخاصة',
    'LENCANA KHUSUS',
    'EMBLEMAS ESPECIAIS',
    'INSIGNIAS ESPECIALES',
    'BADGES SPÉCIAUX',
    'SPEZIALABZEICHEN',
  ],
  'COURSE STATISTICS': <String>[
    'إحصاءات المسارات',
    'STATISTIK JALUR',
    'ESTATÍSTICAS DOS PERCURSOS',
    'ESTADÍSTICAS DE RECORRIDOS',
    'STATISTIQUES DES PARCOURS',
    'PARCOURS-STATISTIK',
  ],
  'PLAYER LEVEL': <String>[
    'مستوى اللاعب',
    'LEVEL PEMAIN',
    'NÍVEL DO JOGADOR',
    'NIVEL DEL JUGADOR',
    'NIVEAU DU JOUEUR',
    'SPIELERLEVEL',
  ],
  'total Brain Points': <String>[
    'إجمالي نقاط الذكاء',
    'total Poin Otak',
    'Pontos Mentais no total',
    'Puntos Mentales totales',
    'Points Cérébraux au total',
    'Denkpunkte insgesamt',
  ],
  'Maximum level': <String>[
    'المستوى الأقصى',
    'Level maksimum',
    'Nível máximo',
    'Nivel máximo',
    'Niveau maximal',
    'Maximales Level',
  ],
  'Unlocked level': <String>[
    'المستوى المفتوح',
    'Level terbuka',
    'Nível desbloqueado',
    'Nivel desbloqueado',
    'Niveau débloqué',
    'Freigeschaltetes Level',
  ],

  'EASY': <String>['سهل', 'MUDAH', 'FÁCIL', 'FÁCIL', 'FACILE', 'LEICHT'],
  'MEDIUM': <String>['متوسط', 'SEDANG', 'MÉDIO', 'MEDIO', 'MOYEN', 'MITTEL'],
  'HARD': <String>['صعب', 'SULIT', 'DIFÍCIL', 'DIFÍCIL', 'DIFFICILE', 'SCHWER'],
  'SCORE': <String>[
    'النقاط',
    'SKOR',
    'PONTUAÇÃO',
    'PUNTUACIÓN',
    'SCORE',
    'PUNKTE',
  ],
  'TARGET': <String>['الهدف', 'TARGET', 'ALVO', 'OBJETIVO', 'CIBLE', 'ZIEL'],
  'MOVES': <String>[
    'الحركات',
    'LANGKAH',
    'MOVIMENTOS',
    'MOVIMIENTOS',
    'MOUVEMENTS',
    'ZÜGE',
  ],
  'SHORTEST': <String>[
    'الأقصر',
    'TERPENDEK',
    'MAIS CURTO',
    'MÁS CORTO',
    'PLUS COURT',
    'KÜRZESTE',
  ],
  'BEST': <String>['الأفضل', 'TERBAIK', 'MELHOR', 'MEJOR', 'MEILLEUR', 'BESTE'],
  'LIVES': <String>['المحاولات', 'NYAWA', 'VIDAS', 'VIDAS', 'VIES', 'LEBEN'],
  'ROUND': <String>['الجولة', 'RONDE', 'RODADA', 'RONDA', 'MANCHE', 'RUNDE'],
  'NEXT LEVEL': <String>[
    'المستوى التالي',
    'LEVEL BERIKUTNYA',
    'PRÓXIMO NÍVEL',
    'SIGUIENTE NIVEL',
    'NIVEAU SUIVANT',
    'NÄCHSTES LEVEL',
  ],
  'LEVEL LIST': <String>[
    'قائمة المستويات',
    'DAFTAR LEVEL',
    'LISTA DE NÍVEIS',
    'LISTA DE NIVELES',
    'LISTE DES NIVEAUX',
    'LEVELLISTE',
  ],
  'PLAY AGAIN': <String>[
    'العب مجددًا',
    'MAIN LAGI',
    'JOGAR NOVAMENTE',
    'JUGAR DE NUEVO',
    'REJOUER',
    'NOCH EINMAL',
  ],
  'Restart': <String>[
    'إعادة البدء',
    'Mulai ulang',
    'Reiniciar',
    'Reiniciar',
    'Recommencer',
    'Neu starten',
  ],
  'Hint': <String>['تلميح', 'Petunjuk', 'Dica', 'Pista', 'Indice', 'Hinweis'],
  'Smart Hint': <String>[
    'تلميح ذكي',
    'Petunjuk Cerdas',
    'Dica Inteligente',
    'Pista Inteligente',
    'Indice Intelligent',
    'Cleverer Hinweis',
  ],
  'READY': <String>['جاهز', 'SIAP', 'PRONTO', 'LISTO', 'PRÊT', 'BEREIT'],
  'GET READY': <String>[
    'استعد',
    'BERSIAP',
    'PREPARE-SE',
    'PREPÁRATE',
    'PRÉPARE-TOI',
    'MACH DICH BEREIT',
  ],
  'WAIT!': <String>[
    'انتظر!',
    'TUNGGU!',
    'ESPERE!',
    '¡ESPERA!',
    'ATTENDS !',
    'WARTE!',
  ],
  'TAP!': <String>[
    'المس!',
    'KETUK!',
    'TOQUE!',
    '¡TOCA!',
    'TOUCHE !',
    'TIPPEN!',
  ],
  'NOW!': <String>[
    'الآن!',
    'SEKARANG!',
    'AGORA!',
    '¡AHORA!',
    'MAINTENANT !',
    'JETZT!',
  ],
  'CORRECT': <String>[
    'صحيح',
    'BENAR',
    'CORRETO',
    'CORRECTO',
    'CORRECT',
    'RICHTIG',
  ],
  'CORRECT!': <String>[
    'صحيح!',
    'BENAR!',
    'CORRETO!',
    '¡CORRECTO!',
    'CORRECT !',
    'RICHTIG!',
  ],
  'GREAT!': <String>[
    'رائع!',
    'HEBAT!',
    'ÓTIMO!',
    '¡GENIAL!',
    'SUPER !',
    'KLASSE!',
  ],
  'PERFECT!': <String>[
    'ممتاز!',
    'SEMPURNA!',
    'PERFEITO!',
    '¡PERFECTO!',
    'PARFAIT !',
    'PERFEKT!',
  ],
  'AMAZING!': <String>[
    'مذهل!',
    'LUAR BIASA!',
    'INCRÍVEL!',
    '¡INCREÍBLE!',
    'INCROYABLE !',
    'FANTASTISCH!',
  ],
  'GOOD!': <String>['جيد!', 'BAGUS!', 'BOM!', '¡BIEN!', 'BIEN !', 'GUT!'],
  'RIGHT': <String>['يمين', 'KANAN', 'DIREITA', 'DERECHA', 'DROITE', 'RECHTS'],
  'LEFT': <String>['يسار', 'KIRI', 'ESQUERDA', 'IZQUIERDA', 'GAUCHE', 'LINKS'],
  'UP': <String>['أعلى', 'ATAS', 'CIMA', 'ARRIBA', 'HAUT', 'OBEN'],
  'DOWN': <String>['أسفل', 'BAWAH', 'BAIXO', 'ABAJO', 'BAS', 'UNTEN'],
  'BLUE': <String>['أزرق', 'BIRU', 'AZUL', 'AZUL', 'BLEU', 'BLAU'],
  'GREEN': <String>['أخضر', 'HIJAU', 'VERDE', 'VERDE', 'VERT', 'GRÜN'],
  'RED': <String>['أحمر', 'MERAH', 'VERMELHO', 'ROJO', 'ROUGE', 'ROT'],
  'YELLOW': <String>['أصفر', 'KUNING', 'AMARELO', 'AMARILLO', 'JAUNE', 'GELB'],
  'PURPLE': <String>['بنفسجي', 'UNGU', 'ROXO', 'MORADO', 'VIOLET', 'LILA'],
  'PINK': <String>['وردي', 'MERAH MUDA', 'ROSA', 'ROSA', 'ROSE', 'ROSA'],
  'ORANGE': <String>[
    'برتقالي',
    'ORANYE',
    'LARANJA',
    'NARANJA',
    'ORANGE',
    'ORANGE',
  ],
  'CIRCLE': <String>[
    'دائرة',
    'LINGKARAN',
    'CÍRCULO',
    'CÍRCULO',
    'CERCLE',
    'KREIS',
  ],
  'SQUARE': <String>[
    'مربع',
    'PERSEGI',
    'QUADRADO',
    'CUADRADO',
    'CARRÉ',
    'QUADRAT',
  ],
  'NEW RECORD': <String>[
    'رقم قياسي جديد',
    'REKOR BARU',
    'NOVO RECORDE',
    'NUEVO RÉCORD',
    'NOUVEAU RECORD',
    'NEUER REKORD',
  ],
  'NEW ROUND': <String>[
    'جولة جديدة',
    'RONDE BARU',
    'NOVA RODADA',
    'NUEVA RONDA',
    'NOUVELLE MANCHE',
    'NEUE RUNDE',
  ],
  'POINTS': <String>['نقطة', 'POIN', 'PONTOS', 'PUNTOS', 'POINTS', 'PUNKTE'],
  'Question': <String>[
    'السؤال',
    'Soal',
    'Pergunta',
    'Pregunta',
    'Question',
    'Frage',
  ],
  'correct': <String>[
    'صحيحة',
    'benar',
    'corretas',
    'correctas',
    'correctes',
    'richtig',
  ],
  'pts': <String>['نقطة', 'poin', 'pts', 'pts', 'pts', 'Pkt.'],
  'Best': <String>[
    'الأفضل',
    'Terbaik',
    'Melhor',
    'Mejor',
    'Meilleur',
    'Bestwert',
  ],
  'Target': <String>['الهدف', 'Target', 'Alvo', 'Objetivo', 'Cible', 'Ziel'],
  'Average': <String>[
    'المتوسط',
    'Rata-rata',
    'Média',
    'Promedio',
    'Moyenne',
    'Durchschnitt',
  ],
  'Round': <String>['الجولة', 'Ronde', 'Rodada', 'Ronda', 'Manche', 'Runde'],
  'Completed round': <String>[
    'الجولة المكتملة',
    'Ronde selesai',
    'Rodada concluída',
    'Ronda completada',
    'Manche terminée',
    'Abgeschlossene Runde',
  ],
  'Level completed': <String>[
    'اكتمل المستوى',
    'Level selesai',
    'Nível concluído',
    'Nivel completado',
    'Niveau terminé',
    'Level abgeschlossen',
  ],
  'Simple game effects and one standard level-complete sound. Background music is disabled.':
      <String>[
        'مؤثرات بسيطة وصوت موحد لإكمال المستوى. موسيقى الخلفية متوقفة.',
        'Efek game sederhana dan satu suara standar saat level selesai. Musik latar dinonaktifkan.',
        'Efeitos simples e um som padrão ao concluir o nível. A música de fundo está desativada.',
        'Efectos sencillos y un sonido estándar al completar el nivel. La música de fondo está desactivada.',
        'Des effets simples et un son standard de fin de niveau. La musique de fond est désactivée.',
        'Einfache Spieleffekte und ein einheitlicher Levelabschluss-Ton. Hintergrundmusik ist deaktiviert.',
      ],
  'Background music': <String>[
    'موسيقى الخلفية',
    'Musik latar',
    'Música de fundo',
    'Música de fondo',
    'Musique de fond',
    'Hintergrundmusik',
  ],
  'Disabled. The game now uses only short sound effects.': <String>[
    'متوقفة. تستخدم اللعبة الآن مؤثرات صوتية قصيرة فقط.',
    'Dinonaktifkan. Game kini hanya memakai efek suara singkat.',
    'Desativada. O jogo agora usa apenas efeitos sonoros curtos.',
    'Desactivada. El juego ahora usa solo efectos de sonido breves.',
    'Désactivée. Le jeu utilise uniquement de courts effets sonores.',
    'Deaktiviert. Das Spiel verwendet nur noch kurze Soundeffekte.',
  ],
  'No music player is started during gameplay.': <String>[
    'لا يتم تشغيل أي مشغل موسيقى أثناء اللعب.',
    'Tidak ada pemutar musik yang dijalankan saat bermain.',
    'Nenhum reprodutor de música é iniciado durante o jogo.',
    'No se inicia ningún reproductor de música durante la partida.',
    'Aucun lecteur de musique ne démarre pendant la partie.',
    'Während des Spiels wird kein Musikplayer gestartet.',
  ],
  'Accessibility and motion': <String>[
    'إمكانية الوصول والحركة',
    'Aksesibilitas dan gerakan',
    'Acessibilidade e movimento',
    'Accesibilidad y movimiento',
    'Accessibilité et mouvements',
    'Bedienungshilfen und Bewegung',
  ],
  'Animation intensity, contrast and text size are stored only on this device.':
      <String>[
        'يتم حفظ شدة الحركة والتباين وحجم النص على هذا الجهاز فقط.',
        'Intensitas animasi, kontras, dan ukuran teks hanya disimpan di perangkat ini.',
        'A intensidade das animações, o contraste e o tamanho do texto são salvos apenas neste dispositivo.',
        'La intensidad de animación, el contraste y el tamaño del texto se guardan solo en este dispositivo.',
        'L’intensité des animations, le contraste et la taille du texte sont enregistrés uniquement sur cet appareil.',
        'Animationsstärke, Kontrast und Textgröße werden nur auf diesem Gerät gespeichert.',
      ],
  'Animation intensity': <String>[
    'شدة الحركة',
    'Intensitas animasi',
    'Intensidade da animação',
    'Intensidad de animación',
    'Intensité des animations',
    'Animationsstärke',
  ],
  'Follow device setting': <String>[
    'اتباع إعداد الجهاز',
    'Ikuti pengaturan perangkat',
    'Seguir configuração do dispositivo',
    'Usar ajuste del dispositivo',
    'Suivre le réglage de l’appareil',
    'Geräteeinstellung verwenden',
  ],
  'Full': <String>[
    'كاملة',
    'Penuh',
    'Completa',
    'Completa',
    'Complète',
    'Voll',
  ],
  'Balanced': <String>[
    'متوازنة',
    'Seimbang',
    'Equilibrada',
    'Equilibrada',
    'Équilibrée',
    'Ausgewogen',
  ],
  'Reduced': <String>[
    'مخفضة',
    'Dikurangi',
    'Reduzida',
    'Reducida',
    'Réduite',
    'Reduziert',
  ],
  'High contrast': <String>[
    'تباين عالٍ',
    'Kontras tinggi',
    'Alto contraste',
    'Alto contraste',
    'Contraste élevé',
    'Hoher Kontrast',
  ],
  'Strengthens focus and primary action colors.': <String>[
    'يعزز ألوان التركيز والإجراءات الرئيسية.',
    'Memperkuat warna fokus dan tindakan utama.',
    'Reforça as cores de foco e das ações principais.',
    'Refuerza los colores de enfoque y acciones principales.',
    'Renforce les couleurs de focus et des actions principales.',
    'Verstärkt Fokus- und Hauptaktionsfarben.',
  ],
  'Larger app text': <String>[
    'نص أكبر في التطبيق',
    'Teks aplikasi lebih besar',
    'Texto maior no aplicativo',
    'Texto más grande en la aplicación',
    'Texte plus grand dans l’application',
    'Größerer App-Text',
  ],
  'Keeps the device text setting and applies at least 115%.': <String>[
    'يحافظ على إعداد نص الجهاز ويطبق 115٪ على الأقل.',
    'Mempertahankan pengaturan teks perangkat dan menerapkan minimal 115%.',
    'Mantém a configuração de texto do dispositivo e aplica no mínimo 115%.',
    'Mantiene el ajuste de texto del dispositivo y aplica al menos 115%.',
    'Conserve le réglage de texte de l’appareil et applique au moins 115 %.',
    'Behält die Geräteeinstellung bei und verwendet mindestens 115 %.',
  ],
  'Reduced motion': <String>[
    'حركة مخفضة',
    'Gerakan dikurangi',
    'Movimento reduzido',
    'Movimiento reducido',
    'Mouvements réduits',
    'Weniger Bewegung',
  ],
  'Motion active': <String>[
    'الحركة مفعّلة',
    'Gerakan aktif',
    'Movimento ativo',
    'Movimiento activo',
    'Mouvements actifs',
    'Bewegung aktiv',
  ],
  'Standard contrast': <String>[
    'تباين قياسي',
    'Kontras standar',
    'Contraste padrão',
    'Contraste estándar',
    'Contraste standard',
    'Standardkontrast',
  ],

  // Shared game hubs and result actions.
  'CANDY SORT': <String>[
    'فرز الحلوى',
    'SUSUN PERMEN',
    'CLASSIFICAR DOCES',
    'ORDENAR DULCES',
    'TRI DE BONBONS',
    'BONBONS SORTIEREN',
  ],
  'NUMBER HIVE': <String>[
    'خلية الأرقام',
    'SARANG ANGKA',
    'COLMEIA NUMÉRICA',
    'COLMENA NUMÉRICA',
    'RUCHE NUMÉRIQUE',
    'ZAHLENWABE',
  ],
  'VISUAL IQ': <String>[
    'الذكاء البصري',
    'IQ VISUAL',
    'QI VISUAL',
    'CI VISUAL',
    'QI VISUEL',
    'VISUELLER IQ',
  ],
  'SHAPE MERGE': <String>[
    'دمج الأشكال',
    'GABUNG BENTUK',
    'COMBINAR FORMAS',
    'COMBINAR FORMAS',
    'FUSION DE FORMES',
    'FORMEN VERBINDEN',
  ],
  'WORD HUNT': <String>[
    'البحث عن الكلمات',
    'PERBURUAN KATA',
    'CAÇA-PALAVRAS',
    'CAZA DE PALABRAS',
    'CHASSE AUX MOTS',
    'WÖRTERSUCHE',
  ],
  'Pick • Move • Group Colors': <String>[
    'اختر • حرّك • اجمع الألوان',
    'Pilih • Pindah • Kelompokkan Warna',
    'Escolha • Mova • Agrupe as Cores',
    'Elige • Mueve • Agrupa Colores',
    'Choisis • Déplace • Regroupe les Couleurs',
    'Wählen • Bewegen • Farben Gruppieren',
  ],
  'Slide • Plan • Order': <String>[
    'حرّك • خطط • رتّب',
    'Geser • Rencanakan • Urutkan',
    'Deslize • Planeje • Ordene',
    'Desliza • Planifica • Ordena',
    'Glisse • Planifie • Ordonne',
    'Schieben • Planen • Ordnen',
  ],
  'Observe • Decode • Match': <String>[
    'راقب • حلّل • طابق',
    'Amati • Pecahkan • Cocokkan',
    'Observe • Decifre • Combine',
    'Observa • Descifra • Relaciona',
    'Observe • Décode • Associe',
    'Beobachten • Entschlüsseln • Zuordnen',
  ],
  'Observe • Merge • Find the Shape': <String>[
    'راقب • ادمج • اعثر على الشكل',
    'Amati • Gabungkan • Temukan Bentuk',
    'Observe • Combine • Encontre a Forma',
    'Observa • Combina • Encuentra la Forma',
    'Observe • Assemble • Trouve la Forme',
    'Beobachten • Verbinden • Form Finden',
  ],
  'Find • Swipe • Complete': <String>[
    'اعثر • اسحب • أكمل',
    'Temukan • Geser • Selesaikan',
    'Encontre • Deslize • Complete',
    'Encuentra • Desliza • Completa',
    'Trouve • Glisse • Termine',
    'Finden • Wischen • Abschließen',
  ],
  'Complete the previous level.': <String>[
    'أكمل المستوى السابق.',
    'Selesaikan level sebelumnya.',
    'Conclua o nível anterior.',
    'Completa el nivel anterior.',
    'Termine le niveau précédent.',
    'Schließe das vorherige Level ab.',
  ],
  'NEXT': <String>[
    'التالي',
    'LANJUT',
    'PRÓXIMO',
    'SIGUIENTE',
    'SUIVANT',
    'WEITER',
  ],
  'MAP': <String>['الخريطة', 'PETA', 'MAPA', 'MAPA', 'CARTE', 'KARTE'],

  // Word Hunt controls and instructions.
  'HINT': <String>['تلميح', 'PETUNJUK', 'DICA', 'PISTA', 'INDICE', 'HINWEIS'],
  'NEW BOARD': <String>[
    'لوحة جديدة',
    'PAPAN BARU',
    'NOVO TABULEIRO',
    'TABLERO NUEVO',
    'NOUVELLE GRILLE',
    'NEUES FELD',
  ],
  'BOARD': <String>[
    'اللوحة',
    'PAPAN',
    'TABULEIRO',
    'TABLERO',
    'GRILLE',
    'FELD',
  ],
  'FOUND': <String>[
    'المكتشفة',
    'DITEMUKAN',
    'ENCONTRADAS',
    'ENCONTRADAS',
    'TROUVÉS',
    'GEFUNDEN',
  ],
  'TIME': <String>['الوقت', 'WAKTU', 'TEMPO', 'TIEMPO', 'TEMPS', 'ZEIT'],
  'MISS': <String>['الأخطاء', 'SALAH', 'ERROS', 'FALLOS', 'ERREURS', 'FEHLER'],
  'STARS': <String>[
    'النجوم',
    'BINTANG',
    'ESTRELAS',
    'ESTRELLAS',
    'ÉTOILES',
    'STERNE',
  ],
  'OPEN': <String>[
    'المفتوح',
    'TERBUKA',
    'ABERTOS',
    'ABIERTOS',
    'OUVERTS',
    'OFFEN',
  ],
  'UNDO': <String>[
    'تراجع',
    'URUNGKAN',
    'DESFAZER',
    'DESHACER',
    'ANNULER',
    'RÜCKGÄNGIG',
  ],
  'RESET': <String>[
    'إعادة',
    'ATUR ULANG',
    'REINICIAR',
    'REINICIAR',
    'RÉINITIALISER',
    'ZURÜCKSETZEN',
  ],
  'HINTS': <String>[
    'التلميحات',
    'PETUNJUK',
    'DICAS',
    'PISTAS',
    'INDICES',
    'HINWEISE',
  ],
  'ATTEMPTS': <String>[
    'المحاولات',
    'PERCOBAAN',
    'TENTATIVAS',
    'INTENTOS',
    'ESSAIS',
    'VERSUCHE',
  ],
  'PAIRS': <String>[
    'الأزواج',
    'PASANGAN',
    'PARES',
    'PAREJAS',
    'PAIRES',
    'PAARE',
  ],
  'OPTIMAL': <String>[
    'المثالي',
    'OPTIMAL',
    'IDEAL',
    'ÓPTIMO',
    'OPTIMAL',
    'OPTIMAL',
  ],
  'RESTART': <String>[
    'إعادة البدء',
    'MULAI ULANG',
    'REINICIAR',
    'REINICIAR',
    'RECOMMENCER',
    'NEU STARTEN',
  ],
  'LEVELS': <String>[
    'المستويات',
    'LEVEL',
    'NÍVEIS',
    'NIVELES',
    'NIVEAUX',
    'LEVEL',
  ],
  'HOW TO PLAY': <String>[
    'كيفية اللعب',
    'CARA BERMAIN',
    'COMO JOGAR',
    'CÓMO JUGAR',
    'COMMENT JOUER',
    'SPIELANLEITUNG',
  ],
  'GOT IT': <String>[
    'فهمت',
    'MENGERTI',
    'ENTENDI',
    'ENTENDIDO',
    'COMPRIS',
    'VERSTANDEN',
  ],
  'How to play': <String>[
    'كيفية اللعب',
    'Cara bermain',
    'Como jogar',
    'Cómo jugar',
    'Comment jouer',
    'Spielanleitung',
  ],
  'TOWER OF HANOI': <String>[
    'برج هانوي',
    'MENARA HANOI',
    'TORRE DE HANÓI',
    'TORRE DE HANÓI',
    'TOURS DE HANOÏ',
    'TURM VON HANOI',
  ],
  'Plan • Move • Complete': <String>[
    'خطط • حرّك • أكمل',
    'Rencanakan • Pindah • Selesaikan',
    'Planeje • Mova • Complete',
    'Planifica • Mueve • Completa',
    'Planifie • Déplace • Termine',
    'Planen • Bewegen • Abschließen',
  ],
  'FINISH MEMORY COURSE': <String>[
    'إنهاء مسار الذاكرة',
    'SELESAIKAN JALUR MEMORI',
    'CONCLUIR PERCURSO DE MEMÓRIA',
    'TERMINAR RECORRIDO DE MEMORIA',
    'TERMINER LE PARCOURS MÉMOIRE',
    'GEDÄCHTNIS-PARCOURS ABSCHLIESSEN',
  ],
  'FINISH HANOI COURSE': <String>[
    'إنهاء مسار هانوي',
    'SELESAIKAN JALUR HANOI',
    'CONCLUIR PERCURSO DE HANÓI',
    'TERMINAR RECORRIDO DE HANÓI',
    'TERMINER LE PARCOURS HANOÏ',
    'HANOI-PARCOURS ABSCHLIESSEN',
  ],
  'GRAND MATCHING': <String>[
    'المطابقة الكبرى',
    'PENCOCOKAN BESAR',
    'GRANDE COMBINAÇÃO',
    'GRAN EMPAREJAMIENTO',
    'GRANDES PAIRES',
    'GROSSES ZUORDNEN',
  ],
  'SHAPE MATCHING': <String>[
    'مطابقة الأشكال',
    'COCOKKAN BENTUK',
    'COMBINAÇÃO DE FORMAS',
    'EMPAREJAR FORMAS',
    'PAIRES DE FORMES',
    'FORMEN ZUORDNEN',
  ],
  'QUESTION': <String>[
    'السؤال',
    'SOAL',
    'PERGUNTA',
    'PREGUNTA',
    'QUESTION',
    'FRAGE',
  ],
  'Move the top candy onto the same color or into an empty jar.': <String>[
    'انقل الحلوى العلوية فوق اللون نفسه أو إلى وعاء فارغ.',
    'Pindahkan permen teratas ke warna yang sama atau ke stoples kosong.',
    'Mova o doce de cima para a mesma cor ou para um pote vazio.',
    'Mueve el dulce superior al mismo color o a un frasco vacío.',
    'Déplace le bonbon du dessus sur la même couleur ou dans un bocal vide.',
    'Lege das oberste Bonbon auf dieselbe Farbe oder in ein leeres Glas.',
  ],
  'Swipe with direction snapping, or tap the first and last letters. Every new round creates a different board.':
      <String>[
        'اسحب باتجاه مستقيم، أو المس الحرف الأول والأخير. كل جولة جديدة تنشئ لوحة مختلفة.',
        'Geser mengikuti arah, atau ketuk huruf pertama dan terakhir. Setiap ronde baru membuat papan berbeda.',
        'Deslize seguindo uma direção ou toque na primeira e na última letra. Cada nova rodada cria um tabuleiro diferente.',
        'Desliza siguiendo una dirección o toca la primera y la última letra. Cada ronda nueva crea un tablero diferente.',
        'Glisse dans une direction ou touche la première et la dernière lettre. Chaque nouvelle manche crée une grille différente.',
        'Wische in einer Richtung oder tippe auf den ersten und letzten Buchstaben. Jede neue Runde erzeugt ein anderes Feld.',
      ],

  // --- Active Game Titles ---
  'Flow Connect': <String>[
    'توصيل التدفق',
    'Aliran Hubung',
    'Conexão de Fluxo',
    'Conexión de Flujo',
    'Connexion de Flux',
    'Fluss-Verbindung',
  ],
  'Circuit Repair': <String>[
    'إصلاح الدائرة',
    'Perbaikan Sirkuit',
    'Reparo de Circuito',
    'Reparación de Circuito',
    'Réparation de Circuit',
    'Schaltkreis-Reparatur',
  ],
  'Beam Director': <String>[
    'توجيه الشعاع',
    'Pengarah Berkas',
    'Diretor de Feixe',
    'Director de Rayo',
    'Directeur de Faisceau',
    'Strahl-Lenker',
  ],
  'Detective Notes': <String>[
    'ملاحظات المحقق',
    'Catatan Detektif',
    'Notas de Detetive',
    'Notas de Detective',
    'Notes de Détective',
    'Detektiv-Notizen',
  ],
  'Mine Detector': <String>[
    'كاشف الألغام',
    'Detektor Ranjau',
    'Detector de Minas',
    'Detector de Minas',
    'Détecteur de Mines',
    'Minensucher',
  ],
  'Warehouse Master': <String>[
    'خبير المستودع',
    'Ahli Gudang',
    'Mestre do Armazém',
    'Maestro del Almacén',
    'Maître de l’Entrepôt',
    'Lager-Meister',
  ],
  'Bridge Builder': <String>[
    'باني الجسور',
    'Pembangun Jembatan',
    'Construtor de Pontes',
    'Constructor de Puentes',
    'Constructeur de Ponts',
    'Brückenbauer',
  ],
  'Gate Sequence': <String>[
    'تسلسل البوابة',
    'Urutan Gerbang',
    'Sequência de Portões',
    'Secuencia de Puertas',
    'Séquence de Portes',
    'Tor-Sequenz',
  ],
  'Parking Puzzle': <String>[
    'لغز الموقف',
    'Teka-teki Parkir',
    'Quebra-cabeça de Estacionamento',
    'Rompecabezas de Estacionamiento',
    'Casse-tête de Parking',
    'Parkplatz-Puzzle',
  ],
  'Pin Unlock': <String>[
    'فتح الدبابيس',
    'Buka Kunci Pin',
    'Desbloqueio de Pinos',
    'Desbloqueo de Pines',
    'Déverrouillage de Goupilles',
    'Stift-Entsperrung',
  ],
  'Balance Scale': <String>[
    'ميزان التوازن',
    'Skala Keseimbangan',
    'Balança de Equilíbrio',
    'Balanza de Equilibrio',
    'Balance d’Équilibre',
    'Gleichgewichtswaage',
  ],
  'Target 24': <String>[
    'الهدف 24',
    'Target 24',
    'Alvo 24',
    'Objetivo 24',
    'Cible 24',
    'Ziel 24',
  ],
  'Sudoku': <String>[
    'سودوكو',
    'Sudoku',
    'Sudoku',
    'Sudoku',
    'Sudoku',
    'Sudoku',
  ],
  'KenKen Cube': <String>[
    'مكعب كين كين',
    'Kubus KenKen',
    'Cubo KenKen',
    'Cubo KenKen',
    'Cube KenKen',
    'KenKen-Würfel',
  ],
  'Mahjong Layers': <String>[
    'طبقات ما جونغ',
    'Lapisan Mahjong',
    'Camadas de Mahjong',
    'Capas de Mahjong',
    'Couches de Mahjong',
    'Mahjong-Schichten',
  ],
  'Card Pairs': <String>[
    'أزواج البطاقات',
    'Pasangan Kartu',
    'Pares de Cartas',
    'Pares de Cartas',
    'Paires de Cartes',
    'Kartenpaare',
  ],
  'Focus Filter': <String>[
    'مرشح التركيز',
    'Filter Fokus',
    'Filtro de Foco',
    'Filtro de Enfoque',
    'Filtre de Concentration',
    'Fokus-Filter',
  ],
  'Spot the Change': <String>[
    'اكتشف التغيير',
    'Temukan Perubahan',
    'Identifique a Mudança',
    'Encuentra el Cambio',
    'Trouvez le Changement',
    'Finde die Veränderung',
  ],
  'Rhythm Memory': <String>[
    'ذاكرة الإيقاع',
    'Memori Ritme',
    'Memória Rítmica',
    'Memoria de Ritmo',
    'Mémoire Rythmique',
    'Rhythmus-Gedächtnis',
  ],
  'Attention Tunnel': <String>[
    'نفق الانتباه',
    'Terowongan Perhatian',
    'Túnel de Atenção',
    'Túnel de Atención',
    'Tunnel d’Attention',
    'Aufmerksamkeits-Tunnel',
  ],
  'Meaning Match': <String>[
    'مطابقة المعاني',
    'Cocokkan Makna',
    'Correspondência de Significados',
    'Emparejar Significados',
    'Association de Sens',
    'Bedeutungspaare',
  ],
  'Finish the Proverb': <String>[
    'أكمل المثل',
    'Lengkapi Peribahasa',
    'Complete o Provérbio',
    'Completa el Proverbio',
    'Finis le Proverbe',
    'Sprichwort vervollständigen',
  ],
  'Sentence Builder': <String>[
    'بناء الجمل',
    'Pembangun Kalimat',
    'Construtor de Frases',
    'Constructor de Oraciones',
    'Constructeur de Phrases',
    'Satz-Bauer',
  ],
  'Near Meaning': <String>[
    'المعنى القريب',
    'Makna Mirip',
    'Sinônimos Próximos',
    'Significado Cercano',
    'Sens Proche',
    'Synonym-Finder',
  ],
  'Letter Maze': <String>[
    'متاهة الحروف',
    'Labirin Huruf',
    'Labirinto de Letras',
    'Laberinto de Letras',
    'Labyrinthe de Lettres',
    'Buchstaben-Labyrinth',
  ],
  'Language Detective': <String>[
    'محقق اللغة',
    'Detektif Bahasa',
    'Detetive da Linguagem',
    'Detective Lingüístico',
    'Détective de la Langue',
    'Sprach-Detektiv',
  ],
  'Story Order': <String>[
    'ترتيب القصة',
    'Urutan Cerita',
    'Ordem da História',
    'Orden de la Historia',
    'Ordre de l’Histoire',
    'Geschichten-Reihenfolge',
  ],
  'Word Wheel': <String>[
    'عجلة الكلمات',
    'Roda Kata',
    'Roda de Palavras',
    'Rueda de Palabras',
    'Roue des Mots',
    'Wort-Rad',
  ],
  'Hidden Masses': <String>[
    'الكتل الخفية',
    'Massa Tersembunyi',
    'Massas Ocultas',
    'Masas Ocultas',
    'Masses Cachées',
    'Verborgene Massen',
  ],
  'Kakuro Grid': <String>[
    'شبكة كاكورو',
    'Kisi Kakuro',
    'Grade Kakuro',
    'Cuadrícula Kakuro',
    'Grille de Kakuro',
    'Kakuro-Gitter',
  ],
  'Reversi Arena': <String>[
    'ساحة ريفيرسي',
    'Arena Reversi',
    'Arena Reversi',
    'Arena Reversi',
    'Arène Reversi',
    'Reversi-Arena',
  ],
  'Picross Master': <String>[
    'خبير بيكروس',
    'Ahli Picross',
    'Mestre do Picross',
    'Maestro del Picross',
    'Maître du Picross',
    'Picross-Meister',
  ],
  'Backgammon Master': <String>[
    'خبير الطاولة',
    'Ahli Backgammon',
    'Mestre do Gamão',
    'Maestro del Backgammon',
    'Maître du Backgammon',
    'Backgammon-Meister',
  ],
  'Arrow Route': <String>[
    'طريق الأسهم',
    'Rute Panah',
    'Rota das Flechas',
    'Ruta de Flechas',
    'Route des Flèches',
    'Pfeil-Route',
  ],
  'Chess Mate': <String>[
    'كش مات الشطرنج',
    'Skakmat Catur',
    'Xeque-mate',
    'Jaque Mate',
    'Échec et Mat',
    'Schach-Matt',
  ],
  'Loop Master': <String>[
    'خبير الحلقات',
    'Ahli Loop',
    'Mestre das Alças',
    'Maestro de Bucles',
    'Maître des Boucles',
    'Schleifen-Meister',
  ],
  'Go Life & Death': <String>[
    'غو: حياة وموت',
    'Go: Hidup & Mati',
    'Go: Vida e Morte',
    'Go: Vida y Muerte',
    'Go : Vie et Mort',
    'Go: Leben & Tod',
  ],
  'Code Breaker': <String>[
    'كاسر الشفرات',
    'Pemecah Kode',
    'Decifrador de Código',
    'Descifrador de Código',
    'Casseur de Code',
    'Code-Knacker',
  ],
  'Shogi Mate': <String>[
    'شوجي مات',
    'Skakmat Shogi',
    'Mate do Shogi',
    'Mate de Shogi',
    'Mat de Shogi',
    'Shogi-Matt',
  ],
  'Island & Sea': <String>[
    'الجزيرة والبحر',
    'Pulau & Laut',
    'Ilha e Mar',
    'Isla y Mar',
    'Île et Mer',
    'Insel & Meer',
  ],
  'Peg Solitaire': <String>[
    'سوليتير الأوتاد',
    'Solitaire Pasak',
    'Resta Um',
    'Solitario de Clavijas',
    'Solitaire',
    'Peg-Solitär',
  ],
  'Futoshiki': <String>[
    'فوتوشيكي',
    'Futoshiki',
    'Futoshiki',
    'Futoshiki',
    'Futoshiki',
    'Futoshiki',
  ],
  'Hex Connection': <String>[
    'توصيل سداسي',
    'Koneksi Heksagonal',
    'Conexão Hexagonal',
    'Conexión Hexagonal',
    'Connexion Hexagonale',
    'Hex-Verbindung',
  ],
  'Skyscrapers': <String>[
    'ناطحات السحاب',
    'Gedung Pencakar Langit',
    'Arranha-céus',
    'Rascacielos',
    'Gratte-ciel',
    'Wolkenkratzer',
  ],
  'Hitori': <String>[
    'هيتوري',
    'Hitori',
    'Hitori',
    'Hitori',
    'Hitori',
    'Hitori',
  ],
  'Balloon Catcher': <String>[
    'صائد البالونات',
    'Penangkap Balon',
    'Pegador de Balões',
    'Cazador de Globos',
    'Attrapeur de Ballons',
    'Ballon-Fänger',
  ],
  'Bottle Target': <String>[
    'هدف الزجاجات',
    'Target Botol',
    'Alvo de Garrafas',
    'Tiro a la Botella',
    'Cible de Bouteilles',
    'Flaschen-Ziel',
  ],
  'Color Reactor': <String>[
    'مفاعل الألوان',
    'Reaktor Warna',
    'Reator de Cores',
    'Reactor de Colores',
    'Réacteur de Couleurs',
    'Farben-Reaktor',
  ],
  'Ball Merge': <String>[
    'دمج الكرات',
    'Penggabungan Bola',
    'Fusão de Bolas',
    'Fusión de Bolas',
    'Fusion de Balles',
    'Ball-Verschmelzung',
  ],
  'Tower Balance': <String>[
    'توازن البرج',
    'Keseimbangan Menara',
    'Equilíbrio da Torre',
    'Equilibrio de Torre',
    'Équilibre de Tour',
    'Turm-Balance',
  ],
  'Magnet Path': <String>[
    'مسار المغناطيس',
    'Jalur Magnet',
    'Caminho Magnético',
    'Ruta Magnética',
    'Trajet Magnétique',
    'Magnet-Pfad',
  ],
  'Mini Golf Route': <String>[
    'مسار الغولف المصغر',
    'Rute Mini Golf',
    'Rota do Minigolfe',
    'Ruta de Minigolf',
    'Parcours de Minigolf',
    'Minigolf-Route',
  ],
  'Sweet Conveyor': <String>[
    'ناقل الحلوى',
    'Konveyor Manis',
    'Esteira de Doces',
    'Cinta de Dulces',
    'Convoyeur de Bonbons',
    'Süßigkeiten-Förderband',
  ],
  'Ring Toss': <String>[
    'رمي الحلقات',
    'Lempar Gelang',
    'Jogo das Argolas',
    'Lanzamiento de Anillos',
    'Lancer d’Anneaux',
    'Ringwurf',
  ],
  'Little Fisher': <String>[
    'الصياد الصغير',
    'Pemancing Kecil',
    'Pequeno Pescador',
    'Pequeño Pescador',
    'Petit Pêcheur',
    'Kleiner Fischer',
  ],
  'Marble Route': <String>[
    'مسار الكرات الرخامية',
    'Rute Kelereng',
    'Rota das Bolinhas',
    'Ruta de Canicas',
    'Parcours de Billes',
    'Murmel-Bahn',
  ],
  'Block Flow': <String>[
    'تدفق الكتل',
    'Aliran Balok',
    'Fluxo de Blocos',
    'Flujo de Bloques',
    'Flux de Blocs',
    'Block-Fluss',
  ],
  'Paper Flight': <String>[
    'طيران الورق',
    'Penerbangan Kertas',
    'Voo de Papel',
    'Vuelo de Papel',
    'Vol en Papier',
    'Papierflieger',
  ],
  'Neon Pinball': <String>[
    'بينبول نيون',
    'Pinball Neon',
    'Pinball Neon',
    'Pinball Neón',
    'Flipper Néon',
    'Neon-Flipper',
  ],
  'Kite Pilot': <String>[
    'طيار الطائرة الورقية',
    'Pilot Layang-layang',
    'Piloto de Pipa',
    'Piloto de Cometas',
    'Pilote de Cerf-volant',
    'Drachen-Pilot',
  ],
  'Rhythm Workshop': <String>[
    'ورشة الإيقاع',
    'Bengkel Ritme',
    'Oficina de Ritmo',
    'Taller de Ritmo',
    'Atelier de Rythme',
    'Rhythmus-Werkstatt',
  ],
  'Skate Flow': <String>[
    'انسياب التزلج',
    'Aliran Skate',
    'Fluxo de Skate',
    'Flujo de Skate',
    'Glisse Urbaine',
    'Skate-Flow',
  ],
  'Snowboard Slalom': <String>[
    'سباق التزلج على الجليد',
    'Slalom Seluncur Salju',
    'Slalom de Snowboard',
    'Eslalon de Snowboard',
    'Slalom en Snowboard',
    'Snowboard-Slalom',
  ],
  'Jetpack Courier': <String>[
    'ساعي النفاثة',
    'Kurir Jetpack',
    'Entregador de Jetpack',
    'Mensajero Jetpack',
    'Coursier Jetpack',
    'Raketenrucksack-Kurier',
  ],
  'Orbit Rescue': <String>[
    'إنقاذ المدار',
    'Penyelamatan Orbit',
    'Resgate Orbital',
    'Rescate Orbital',
    'Sauvetage Orbital',
    'Orbit-Rettung',
  ],
  'Drift League': <String>[
    'دوري الانجراف',
    'Liga Drift',
    'Liga de Drift',
    'Liga de Derrapes',
    'Ligue de Drift',
    'Drift-Liga',
  ],
  'Table Tennis Rally': <String>[
    'مباراة تنس الطاولة',
    'Rally Tenis Meja',
    'Rally de Tênis de Mesa',
    'Peloteo de Tenis de Mesa',
    'Échange de Tennis de Table',
    'Tischtennis-Rallye',
  ],
  'Penalty Mindgame': <String>[
    'حرب ضربات الجزاء النفسية',
    'Perang Mental Penalti',
    'Guerra Mental do Pênalti',
    'Duelo Mental de Penales',
    'Jeu Mental du Penalty',
    'Elfmeter-Kopfdell',
  ],
  'Air Hockey Arena': <String>[
    'ساحة هوكي الهواء',
    'Arena Hoki Udara',
    'Arena de Hóquei de Ar',
    'Arena de Air Hockey',
    'Arène d’Air Hockey',
    'Air-Hockey-Arena',
  ],
  'Relic Run': <String>[
    'سباق الآثار',
    'Lari Peninggalan',
    'Corrida das Relíquias',
    'Carrera de Reliquias',
    'Course aux Reliques',
    'Relikt-Lauf',
  ],
  'Lighthouse Defense': <String>[
    'دفاع المنارة',
    'Pertahanan Mercusuar',
    'Defesa do Farol',
    'Defensa del Faro',
    'Défense du Phare',
    'Leuchtturm-Verteidigung',
  ],
  'Museum: After Hours': <String>[
    'المتحف: بعد ساعات العمل',
    'Museum: Larut Malam',
    'Museu: Fora do Horário',
    'Museo: Turno Nocturno',
    'Musée : Heures Fermées',
    'Museum: Nach Feierabend',
  ],
  'Deep Current': <String>[
    'التيار العميق',
    'Arus Dalam',
    'Corrente Profunda',
    'Corriente Profunda',
    'Courant Profond',
    'Tiefenströmung',
  ],
  'Cafe Shift': <String>[
    'مناوبة المقهى',
    'Shift Kafe',
    'Turno no Café',
    'Turno en el Café',
    'Service au Café',
    'Café-Schicht',
  ],
  'Interior Studio': <String>[
    'استوديو التصميم الداخلي',
    'Studio Interior',
    'Estúdio de Interiores',
    'Estudio de Interior',
    'Studio d’Intérieur',
    'Innenarchitektur-Studio',
  ],
  'Tideglass Aquarium': <String>[
    'حوض زجاج المد والجزر',
    'Akuarium Kaca Pasang',
    'Aquário do Vidro da Maré',
    'Acuario Vidrio de Marea',
    'Aquarium Marée de Verre',
    'Gezeitenglas-Aquarium',
  ],
  'Pet Rescue Clinic': <String>[
    'عيادة إنقاذ الحيوانات',
    'Klinik Penyelamatan Hewan',
    'Clínica de Resgate Animal',
    'Clínica de Rescate de Mascotas',
    'Clinique Vétérinaire',
    'Tierrettungsklinik',
  ],
  'Boardwalk Builder': <String>[
    'باني ممشى الشاطئ',
    'Pembangun Boardwalk',
    'Construtor do Calçadão',
    'Constructor del Paseo',
    'Constructeur de Promenade',
    'Promenaden-Bauer',
  ],
  'Moonbase Operations': <String>[
    'عمليات قاعدة القمر',
    'Operasi Pangkalan Bulan',
    'Operações da Base Lunar',
    'Operaciones Base Lunar',
    'Opérations Base Lunaire',
    'Mondbasis-Operationen',
  ],
  'Museum Curator': <String>[
    'أمين المتحف',
    'Kurator Museum',
    'Curador do Museu',
    'Curador del Museo',
    'Conservateur de Musée',
    'Museumskurator',
  ],
  'Festival Producer': <String>[
    'منتج المهرجان',
    'Produser Festival',
    'Produtor de Festival',
    'Productor de Festivales',
    'Producteur de Festival',
    'Festival-Produzent',
  ],
  'Secret Room: Social Deduction': <String>[
    'الغرفة السرية: استنتاج اجتماعي',
    'Ruang Rahasia: Deduksi Sosial',
    'Sala Secreta: Dedução Social',
    'Sala Secreta: Deducción Social',
    'Chambre Secrète : Déduction Sociale',
    'Geheimraum: Soziale Deduktion',
  ],
  'Dice & Dagger': <String>[
    'النرد والخنجر',
    'Dadu & Belati',
    'Dados e Adaga',
    'Dados y Daga',
    'Dés et Dague',
    'Würfel & Dolch',
  ],
  'Signal Partner': <String>[
    'شريك الإشارة',
    'Mitra Sinyal',
    'Parceiro de Sinal',
    'Compañero de Señal',
    'Partenaire de Signal',
    'Signal-Partner',
  ],
  'Deckforge Duel': <String>[
    'مبارزة صانع البطاقات',
    'Duel Pembuat Kartu',
    'Duelo do Forjador de Decks',
    'Duelo de Barajas',
    'Duel de Forgeron de Deck',
    'Kartendeck-Duell',
  ],
  'Turkey Atlas': <String>[
    'أطلس تركيا',
    'Atlas Turki',
    'Atlas da Turquia',
    'Atlas de Turquía',
    'Atlas de Turquie',
    'Türkei-Atlas',
  ],
  'World Atlas': <String>[
    'أطلس العالم',
    'Atlas Dunia',
    'Atlas Mundial',
    'Atlas Mundial',
    'Atlas du Monde',
    'Weltatlas',
  ],
  'Katamino Workshop': <String>[
    'ورشة كاتامينو',
    'Bengkel Katamino',
    'Oficina de Katamino',
    'Taller de Katamino',
    'Atelier Katamino',
    'Katamino-Werkstatt',
  ],
  'One-Stroke Master': <String>[
    'خبير الخط الواحد',
    'Ahli Satu Goresan',
    'Mestre do Traço Único',
    'Maestro de Un Trazo',
    'Maître du Trait Unique',
    'Ein-Strich-Meister',
  ],
  'Arrow Maze': <String>[
    'متاهة الأسهم',
    'Labirin Panah',
    'Labirinto de Flechas',
    'Laberinto de Flechas',
    'Labyrinthe de Flèches',
    'Pfeil-Labyrinth',
  ],
  'Bubble Shooter': <String>[
    'قاذف الفقاعات',
    'Penembak Gelembung',
    'Atirador de Bolhas',
    'Tirador de Burbujas',
    'Lanceur de Bulles',
    'Blasen-Schießer',
  ],

  // --- Categories ---
  'Logic & solving': <String>[
    'المنطق والحلول',
    'Logika & Pemecahan',
    'Lógica e Solução',
    'Lógica y Resolución',
    'Logique et Résolution',
    'Logik & Lösen',
  ],
  'Numbers': <String>[
    'الأرقام',
    'Angka',
    'Números',
    'Números',
    'Nombres',
    'Zahlen',
  ],
  'Visual & spatial': <String>[
    'البصري والمكاني',
    'Visual & Spasial',
    'Visual e Espacial',
    'Visual y Espacial',
    'Visuel et Spatial',
    'Visuell & Räumlich',
  ],
  'Memory & focus': <String>[
    'الذاكرة والتركيز',
    'Memori & Fokus',
    'Memória e Foco',
    'Memoria y Concentración',
    'Mémoire et Concentration',
    'Gedächtnis & Fokus',
  ],
  'Planning & strategy': <String>[
    'التخطيط والاستراتيجية',
    'Perencanaan & Strategi',
    'Planejamento e Estratégia',
    'Planificación y Estrategia',
    'Planification et Stratégie',
    'Planung & Strategie',
  ],
  'Language & words': <String>[
    'اللغة والكلمات',
    'Bahasa & Kata',
    'Linguagem e Palavras',
    'Lenguaje y Palabras',
    'Langage et Mots',
    'Sprache & Wörter',
  ],
  'Speed & reaction': <String>[
    'السرعة ورد الفعل',
    'Kecepatan & Reaksi',
    'Velocidade e Reação',
    'Velocidad y Reacción',
    'Vitesse et Réaction',
    'Tempo & Reaktion',
  ],
  'Fun games': <String>[
    'ألعاب ترفيهية',
    'Game Seru',
    'Jogos Divertidos',
    'Juegos Divertidos',
    'Jeux Amusants',
    'Spaßspiele',
  ],

  // --- Common UI Actions, Buttons & Dialogs ---
  'PLAY': <String>[
    'العب',
    'MAIN',
    'JOGAR',
    'JUGAR',
    'JOUER',
    'SPIELEN',
  ],
  'Play': <String>[
    'العب',
    'Main',
    'Jogar',
    'Jugar',
    'Jouer',
    'Spielen',
  ],
  'START': <String>[
    'ابدأ',
    'MULAI',
    'INICIAR',
    'EMPEZAR',
    'COMMENCER',
    'STARTEN',
  ],
  'Start': <String>[
    'ابدأ',
    'Mulai',
    'Iniciar',
    'Empezar',
    'Commencer',
    'Starten',
  ],
  'PAUSE': <String>[
    'إيقاف مؤقت',
    'JEDA',
    'PAUSAR',
    'PAUSA',
    'PAUSE',
    'PAUSE',
  ],
  'PAUSED': <String>[
    'متوقف مؤقتاً',
    'DIJEDA',
    'PAUSADO',
    'PAUSADO',
    'EN PAUSE',
    'PAUSIERT',
  ],
  'Paused': <String>[
    'متوقف مؤقتاً',
    'Dijeda',
    'Pausado',
    'Pausado',
    'En pause',
    'Pausiert',
  ],
  'RESUME': <String>[
    'استئناف',
    'LANJUTKAN',
    'RETOMAR',
    'REANUDAR',
    'REPRENDRE',
    'FORTSETZEN',
  ],
  'Resume': <String>[
    'استئناف',
    'Lanjutkan',
    'Retomar',
    'Reanudar',
    'Reprendre',
    'Fortsetzen',
  ],
  'QUIT': <String>[
    'خروج',
    'KELUAR',
    'SAIR',
    'SALIR',
    'QUITTER',
    'BEENDEN',
  ],
  'Quit': <String>[
    'خروج',
    'Keluar',
    'Sair',
    'Salir',
    'Quitter',
    'Beenden',
  ],
  'EXIT': <String>[
    'خروج',
    'KELUAR',
    'SAIR',
    'SALIR',
    'QUITTER',
    'BEENDEN',
  ],
  'Exit': <String>[
    'خروج',
    'Keluar',
    'Sair',
    'Salir',
    'Quitter',
    'Beenden',
  ],
  'RETRY': <String>[
    'إعادة المحاولة',
    'COBA LAGI',
    'TENTAR NOVAMENTE',
    'REINTENTAR',
    'RÉESSAYER',
    'WIEDERHOLEN',
  ],
  'Retry': <String>[
    'إعادة المحاولة',
    'Coba Lagi',
    'Tentar Novamente',
    'Reintentar',
    'Réessayer',
    'Wiederholen',
  ],
  'Play Again': <String>[
    'العب مجدداً',
    'Main Lagi',
    'Jogar Novamente',
    'Jugar de Nuevo',
    'Rejouer',
    'Nochmal spielen',
  ],
  'CONTINUE': <String>[
    'متابعة',
    'LANJUTKAN',
    'CONTINUAR',
    'CONTINUAR',
    'CONTINUER',
    'WEITER',
  ],
  'Continue': <String>[
    'متابعة',
    'Lanjutkan',
    'Continuar',
    'Continuar',
    'Continuer',
    'Weiter',
  ],
  'CANCEL': <String>[
    'إلغاء',
    'BATAL',
    'CANCELAR',
    'CANCELAR',
    'ANNULER',
    'ABBRECHEN',
  ],
  'Cancel': <String>[
    'إلغاء',
    'Batal',
    'Cancelar',
    'Cancelar',
    'Annuler',
    'Abbrechen',
  ],
  'CLOSE': <String>[
    'إغلاق',
    'TUTUP',
    'FECHAR',
    'CERRAR',
    'FERMER',
    'SCHLIESSEN',
  ],
  'Close': <String>[
    'إغلاق',
    'Tutup',
    'Fechar',
    'Cerrar',
    'Fermer',
    'Schließen',
  ],
  'CONFIRM': <String>[
    'تأكيد',
    'KONFIRMASI',
    'CONFIRMAR',
    'CONFIRMAR',
    'CONFIRMER',
    'BESTÄTIGEN',
  ],
  'Confirm': <String>[
    'تأكيد',
    'Konfirmasi',
    'Confirmar',
    'Confirmar',
    'Confirmer',
    'Bestätigen',
  ],
  'OK': <String>[
    'حسناً',
    'OKE',
    'OK',
    'ACEPTAR',
    'OK',
    'OK',
  ],
  'Ok': <String>[
    'حسناً',
    'Oke',
    'OK',
    'Aceptar',
    'OK',
    'OK',
  ],
  'YES': <String>[
    'نعم',
    'YA',
    'SIM',
    'SÍ',
    'OUI',
    'JA',
  ],
  'Yes': <String>[
    'نعم',
    'Ya',
    'Sim',
    'Sí',
    'Oui',
    'Ja',
  ],
  'NO': <String>[
    'لا',
    'TIDAK',
    'NÃO',
    'NO',
    'NON',
    'NEIN',
  ],
  'No': <String>[
    'لا',
    'Tidak',
    'Não',
    'No',
    'Non',
    'Nein',
  ],
  'TAKE HINT': <String>[
    'خذ تلميحاً',
    'AMBIL PETUNJUK',
    'PEGAR DICA',
    'TOMAR PISTA',
    'PRENDRE UN INDICE',
    'HINWEIS NEHMEN',
  ],
  'Take Hint': <String>[
    'خذ تلميحاً',
    'Ambil Petunjuk',
    'Pegar Dica',
    'Tomar Pista',
    'Prendre un indice',
    'Hinweis nehmen',
  ],
  'Take hint': <String>[
    'خذ تلميحاً',
    'Ambil petunjuk',
    'Pegar dica',
    'Tomar pista',
    'Prendre un indice',
    'Hinweis nehmen',
  ],
  'SMART HINT': <String>[
    'تلميح ذكي',
    'PETUNJUK PINTAR',
    'DICA INTELIGENTE',
    'PISTA INTELIGENTE',
    'INDICE INTELLIGENT',
    'SCHLAUER HINWEIS',
  ],
  'HINTS COMPLETE': <String>[
    'اكتملت التلميحات',
    'PETUNJUK SELESAI',
    'DICAS CONCLUÍDAS',
    'PISTAS COMPLETAS',
    'INDICES ÉPUISÉS',
    'HINWEISE ERSCHÖPFT',
  ],
  'Hints complete': <String>[
    'اكتملت التلميحات',
    'Petunjuk selesai',
    'Dicas concluídas',
    'Pistas completas',
    'Indices épuisés',
    'Hinweise erschöpft',
  ],
  'Undo': <String>[
    'تراجع',
    'Urungkan',
    'Desfazer',
    'Deshacer',
    'Annuler',
    'Rückgängig',
  ],
  'Reset': <String>[
    'إعادة ضبط',
    'Atur Ulang',
    'Reiniciar',
    'Reiniciar',
    'Réinitialiser',
    'Zurücksetzen',
  ],
  'CLEAR': <String>[
    'مسح',
    'BERSIHKAN',
    'LIMPAR',
    'LIMPIAR',
    'EFFACER',
    'LÖSCHEN',
  ],
  'Clear': <String>[
    'مسح',
    'Bersihkan',
    'Limpar',
    'Limpiar',
    'Effacer',
    'Löschen',
  ],
  'CHECK': <String>[
    'تحقق',
    'PERIKSA',
    'VERIFICAR',
    'COMPROBAR',
    'VÉRIFIER',
    'PRÜFEN',
  ],
  'Check': <String>[
    'تحقق',
    'Periksa',
    'Verificar',
    'Comprobar',
    'Vérifier',
    'Prüfen',
  ],
  'CHECK ANSWER': <String>[
    'تحقق من الإجابة',
    'PERIKSA JAWABAN',
    'CONFERIR RESPOSTA',
    'COMPROBAR RESPUESTA',
    'VÉRIFIER LA RÉPONSE',
    'ANTWORT PRÜFEN',
  ],
  'Check Answer': <String>[
    'تحقق من الإجابة',
    'Periksa Jawaban',
    'Conferir Resposta',
    'Comprobar Respuesta',
    'Vérifier la Réponse',
    'Antwort prüfen',
  ],
  'Check answer': <String>[
    'تحقق من الإجابة',
    'Periksa jawaban',
    'Conferir resposta',
    'Comprobar respuesta',
    'Vérifier la réponse',
    'Antwort prüfen',
  ],
  'Correct': <String>[
    'صحيح',
    'Benar',
    'Correto',
    'Correcto',
    'Correct',
    'Richtig',
  ],
  'CORRECT ANSWER': <String>[
    'إجابة صحيحة',
    'JAWABAN BENAR',
    'RESPOSTA CORRETA',
    'RESPUESTA CORRECTA',
    'BONNE RÉPONSE',
    'RICHTIGE ANTWORT',
  ],
  'Correct answer': <String>[
    'إجابة صحيحة',
    'Jawaban benar',
    'Resposta correta',
    'Respuesta correcta',
    'Bonne réponse',
    'Richtige Antwort',
  ],
  'WRONG': <String>[
    'خطأ',
    'SALAH',
    'INCORRETO',
    'INCORRECTO',
    'FAUX',
    'FALSCH',
  ],
  'Wrong': <String>[
    'خطأ',
    'Salah',
    'Incorreto',
    'Incorrecto',
    'Faux',
    'Falsch',
  ],
  'CHAPTER': <String>[
    'الفصل',
    'BAB',
    'CAPÍTULO',
    'CAPÍTULO',
    'CHAPITRE',
    'KAPITEL',
  ],
  'Chapter': <String>[
    'الفصل',
    'Bab',
    'Capítulo',
    'Capítulo',
    'Chapitre',
    'Kapitel',
  ],
  'RECORD': <String>[
    'الرقم القياسي',
    'REKOR',
    'RECORDE',
    'RÉCORD',
    'RECORD',
    'REKORD',
  ],
  'Record': <String>[
    'الرقم القياسي',
    'Rekor',
    'Recorde',
    'Récord',
    'Record',
    'Rekord',
  ],
  'Time': <String>[
    'الوقت',
    'Waktu',
    'Tempo',
    'Tiempo',
    'Temps',
    'Zeit',
  ],
  'REMAINING': <String>[
    'المتبقي',
    'TERSISA',
    'RESTANTE',
    'RESTANTE',
    'RESTANT',
    'VERBLEIBEND',
  ],
  'Remaining': <String>[
    'المتبقي',
    'Tersisa',
    'Restante',
    'Restante',
    'Restant',
    'Verbleibend',
  ],
  'CONGRATULATIONS!': <String>[
    'تهانينا!',
    'SELAMAT!',
    'PARABÉNS!',
    '¡FELICITACIONES!',
    'FÉLICITATIONS !',
    'HERZLICHEN GLÜCKWUNSCH!',
  ],
  'Congratulations!': <String>[
    'تهانينا!',
    'Selamat!',
    'Parabéns!',
    '¡Felicitaciones!',
    'Félicitations !',
    'Herzlichen Glückwunsch!',
  ],
  'VICTORY!': <String>[
    'انتصار!',
    'KEMENANGAN!',
    'VITÓRIA!',
    '¡VICTORIA!',
    'VICTOIRE !',
    'SIEG!',
  ],
  'Victory!': <String>[
    'انتصار!',
    'Kemenangan!',
    'Vitória!',
    '¡Victoria!',
    'Victoire !',
    'Sieg!',
  ],
  'SOLVE CASE': <String>[
    'حل القضية',
    'PECAHKAN KASUS',
    'RESOLVER O CASO',
    'RESOLVER CASO',
    'RÉSOUDRE L’AFFAIRE',
    'FALL LÖSEN',
  ],
  'Solve Case': <String>[
    'حل القضية',
    'Pecahkan Kasus',
    'Resolver o Caso',
    'Resolver Caso',
    'Résoudre l’affaire',
    'Fall lösen',
  ],
  'Solve case': <String>[
    'حل القضية',
    'Pecahkan kasus',
    'Resolver o caso',
    'Resolver caso',
    'Résoudre l’affaire',
    'Fall lösen',
  ],
  'UNLOCK': <String>[
    'فتح القفل',
    'BUKA KUNCI',
    'DESBLOQUEAR',
    'DESBLOQUEAR',
    'DÉVERROUILLER',
    'ENTSPERREN',
  ],
  'Unlock': <String>[
    'فتح القفل',
    'Buka Kunci',
    'Desbloquear',
    'Desbloquear',
    'Déverrouiller',
    'Entsperren',
  ],
  'How to Play': <String>[
    'كيفية اللعب',
    'Cara Bermain',
    'Como Jogar',
    'Cómo Jugar',
    'Comment Jouer',
    'Spielanleitung',
  ],
  'Restart this field?': <String>[
    'هل تريد إعادة ضبط هذه الساحة؟',
    'Atur ulang bidang ini?',
    'Reiniciar este campo?',
    '¿Reiniciar este campo?',
    'Réinitialiser ce terrain ?',
    'Dieses Feld neu starten?',
  ],
  'The same certified arrow layout will be restored.': <String>[
    'سيتم استعادة نفس تخطيط الأسهم المعتمد.',
    'Tata letak panah bersertifikasi yang sama akan dipulihkan.',
    'O mesmo layout de flechas certificado será restaurado.',
    'Se restaurará la misma distribución de flechas certificada.',
    'La même disposition de flèches certifiée sera restaurée.',
    'Derselbe geprüfte Pfeilaufbau wird wiederhergestellt.',
  ],
  'Reset this grid?': <String>[
    'هل تريد إعادة ضبط هذه الشبكة؟',
    'Atur ulang kisi ini?',
    'Reiniciar esta grade?',
    '¿Reiniciar esta cuadrícula?',
    'Réinitialiser cette grille ?',
    'Dieses Gitter zurücksetzen?',
  ],
  'The same clues and inequalities will be restored.': <String>[
    'سيتم استعادة نفس التلميحات والمتباينات.',
    'Petunjuk dan pertidaksamaan yang sama akan dipulihkan.',
    'As mesmas pistas e desigualdades serão restauradas.',
    'Se restaurarán las mismas pistas y desigualdades.',
    'Les mêmes indices et inégalités seront restaurés.',
    'Dieselben Hinweise und Ungleichungen werden wiederhergestellt.',
  ],
  'Reset this puzzle?': <String>[
    'هل تريد إعادة ضبط هذا اللغز؟',
    'Atur ulang teka-teki ini?',
    'Reiniciar este quebra-cabeça?',
    '¿Reiniciar este rompecabezas?',
    'Réinitialiser ce puzzle ?',
    'Dieses Puzzle zurücksetzen?',
  ],
  'Reset this tsumego?': <String>[
    'هل تريد إعادة ضبط هذا اللغز؟',
    'Atur ulang tsumego ini?',
    'Reiniciar este tsumego?',
    '¿Reiniciar este tsumego?',
    'Réinitialiser ce tsumego ?',
    'Dieses Tsumego zurücksetzen?',
  ],
  'The same certified position will be restored.': <String>[
    'سيتم استعادة نفس الموضع المعتمد.',
    'Posisi bersertifikasi yang sama akan dipulihkan.',
    'A mesma posição certificada será restaurada.',
    'Se restaurará la misma posición certificada.',
    'La même position certifiée sera restaurée.',
    'Dieselbe geprüfte Stellung wird wiederhergestellt.',
  ],
  'Target lost': <String>[
    'فُقد الهدف',
    'Target hilang',
    'Alvo perdido',
    'Objetivo perdido',
    'Cible perdue',
    'Ziel verloren',
  ],
  'Your attempts are used. Reset the cards and follow the target again.': <String>[
    'استُنفدت محاولاتك. أعد ضبط البطاقات وتابع الهدف مرة أخرى.',
    'Kesempatanmu habis. Atur ulang kartu dan ikuti target lagi.',
    'Suas tentativas acabaram. Reinicie as cartas e siga o alvo novamente.',
    'Se agotaron tus intentos. Reinicia las cartas y sigue el objetivo de nuevo.',
    'Vos tentatives sont épuisées. Réinitialisez les cartes et suivez à nouveau la cible.',
    'Deine Versuche sind aufgebraucht. Setze die Karten zurück und folge dem Ziel erneut.',
  ],
  'BALANCE ACHIEVED': <String>[
    'تم تحقيق التوازن',
    'KESEIMBANGAN TERCAPAI',
    'EQUILÍBRIO ALCANÇADO',
    'EQUILIBRIO ALCANZADO',
    'ÉQUILIBRE ATTEINT',
    'GLEICHGEWICHT ERREICHT',
  ],
  'Balance achieved': <String>[
    'تم تحقيق التوازن',
    'Keseimbangan tercapai',
    'Equilíbrio alcançado',
    'Equilibrio alcanzado',
    'Équilibre atteint',
    'Gleichgewicht erreicht',
  ],
  'VAULT OPENED': <String>[
    'تم فتح الخزنة',
    'BRANKAS TERBUKA',
    'COFRE ABERTO',
    'CAJA FUERTE ABIERTA',
    'COFFRE-FORT OUVERT',
    'TRESOR GEÖFFNET',
  ],
  'Vault opened': <String>[
    'تم فتح الخزنة',
    'Brankas terbuka',
    'Cofre aberto',
    'Caja fuerte abierta',
    'Coffre-fort ouvert',
    'Tresor geöffnet',
  ],
  'Arena point': <String>[
    'نقطة الساحة',
    'Poin Arena',
    'Ponto de Arena',
    'Punto de Arena',
    'Point d’Arène',
    'Arena-Punkt',
  ],
  'This chapter could not be loaded. Please try again.': <String>[
    'تعذر تحميل هذا الفصل. يرجى المحاولة مرة أخرى.',
    'Bab ini tidak dapat dimuat. Silakan coba lagi.',
    'Não foi possível carregar este capítulo. Tente novamente.',
    'No se pudo cargar este capítulo. Inténtalo de nuevo.',
    'Impossible de charger ce chapitre. Veuillez réessayer.',
    'Dieses Kapitel konnte nicht geladen werden. Bitte versuche es erneut.',
  ],
};