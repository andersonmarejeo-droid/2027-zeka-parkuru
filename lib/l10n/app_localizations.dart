import 'package:flutter/widgets.dart';

part 'app_localizations_global.dart';

String uppercaseUiText(String value, {required bool english}) {
  if (english) return value.toUpperCase();
  return value.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();
}

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

  /// Uppercases UI labels with Turkish dotted and dotless i rules.
  String uppercaseLabel(String value) =>
      uppercaseUiText(value, english: isEnglish);

  String get appName => isEnglish ? 'Mind Arena' : 'Zeka Parkuru';
  String get categories => isEnglish ? 'Categories' : 'Kategoriler';
  String get challengeFriends =>
      isEnglish ? 'Challenge Your Friends' : 'Arkadaşlarına Meydan Oku';
  String get challengeFriendsSub => isEnglish
      ? 'Live duels, room codes & rank race'
      : 'WhatsApp veya kodla canlı düello';
  String get whatsappArena =>
      isEnglish ? 'WHATSAPP & ARENA' : 'WHATSAPP & MEYDAN OKU';
  String get todaysBrainCourse =>
      isEnglish ? "Today's Brain Course" : 'Günün Zekâ Parkuru';
  String get dailyCourseBadge =>
      isEnglish ? 'DAILY COURSE' : 'GÜNLÜK PARKUR';
  String dailyTasksProgress(int completed, int total) => isEnglish
      ? '$completed of $total tasks today'
      : 'Bugün $completed / $total görev';
  String gameCountLabel(int count) => isEnglish
      ? (count == 1 ? '1 game' : '$count games')
      : '$count oyun';
  String get playAction => isEnglish ? 'PLAY' : 'OYNA';

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
      case 'flow_connect':
        return isEnglish ? 'Flow Connect' : 'Akış Bağlantısı';
      case 'circuit_repair':
        return isEnglish ? 'Circuit Repair' : 'Devre Tamiri';
      case 'beam_director':
        return isEnglish ? 'Beam Director' : 'Işın Yönlendir';
      case 'detective_notes':
        return isEnglish ? 'Detective Notes' : 'Dedektif Notları';
      case 'mine_detective':
        return isEnglish ? 'Mine Detector' : 'Mayın Dedektifi';
      case 'warehouse_master':
        return isEnglish ? 'Warehouse Master' : 'Depo Ustası';
      case 'bridge_builder':
        return isEnglish ? 'Bridge Builder' : 'Köprü Kur';
      case 'gate_sequence':
        return isEnglish ? 'Gate Sequence' : 'Kapı Dizisi';
      case 'parking_puzzle':
        return isEnglish ? 'Parking Puzzle' : 'Park Yeri';
      case 'pin_unlock':
        return isEnglish ? 'Pin Unlock' : 'Kilit Aç';
      case 'balance_scale':
        return isEnglish ? 'Balance Scale' : 'Ağırlık Dengesi';
      case 'target_24':
        return isEnglish ? 'Target Number' : 'Bir İşlem';
      case 'mini_sudoku':
        return isEnglish ? 'Sudoku' : 'Su Doku';
      case 'kenken_cube':
        return isEnglish ? 'KenKen Cube' : 'KenKen Küpü';
      case 'mahjong_layers':
        return isEnglish ? 'Mahjong Layers' : 'Mahjong Katmanları';
      case 'numbers':
        return isEnglish ? 'Number Master' : 'Sayı Ustası';
      case 'blocks':
        return isEnglish ? 'Block Workshop' : 'Blok Atölyesi';
      case 'memory':
        return isEnglish ? 'Memory Maze' : 'Hafıza Labirenti';
      case 'card_pairs':
        return isEnglish ? 'Card Pairs' : 'Kart Çifti';
      case 'focus_filter':
        return isEnglish ? 'Focus Filter' : 'Odak Filtresi';
      case 'spot_change':
        return isEnglish ? 'Spot the Change' : 'Değişeni Bul';
      case 'rhythm_memory':
        return isEnglish ? 'Rhythm Memory' : 'Ritim Hafızası';
      case 'attention_tunnel':
        return isEnglish ? 'Attention Tunnel' : 'Dikkat Tüneli';
      case 'hanoi':
        return isEnglish ? 'Tower of Hanoi' : 'Hanoi Kulesi';
      case 'word_hunt':
        return isEnglish ? 'Word Hunt' : 'Kelime Avı';
      case 'meaning_match':
        return isEnglish ? 'Meaning Match' : 'Anlam Eşleştir';
      case 'proverb_finish':
        return isEnglish ? 'Finish the Proverb' : 'Atasözü Tamamla';
      case 'sentence_builder':
        return isEnglish ? 'Sentence Builder' : 'Cümle Kur';
      case 'near_meaning':
        return isEnglish ? 'Near Meaning' : 'Yakın Anlam';
      case 'letter_maze':
        return isEnglish ? 'Letter Maze' : 'Harf Labirenti';
      case 'language_detective':
        return isEnglish ? 'Language Detective' : 'Dil Dedektifi';
      case 'story_order':
        return isEnglish ? 'Story Order' : 'Hikâye Sırası';
      case 'word_wheel':
        return isEnglish ? 'Word Wheel' : 'Kelime Çarkı';
      case 'hidden_masses':
        return isEnglish ? 'Hidden Masses' : 'Gizli Kütleler';
      case 'kakuro':
        return isEnglish ? 'Kakuro Grid' : 'Kakuro Izgarası';
      case 'reversi_arena':
        return isEnglish ? 'Reversi Arena' : 'Reversi Arenası';
      case 'picross_master':
        return isEnglish ? 'Picross Master' : 'Picross Ustası';
      case 'tavla_master':
        return isEnglish ? 'Backgammon Master' : 'Tavla Ustası';
      case 'arrow_route':
        return isEnglish ? 'Arrow Route' : 'Ok Rotası';
      case 'mini_chess_tactics':
        return isEnglish ? 'Chess Mate' : 'Satranç Matı';
      case 'loop_master':
        return isEnglish ? 'Loop Master' : 'Döngü Ustası';
      case 'go_life_death':
        return isEnglish ? 'Go Life & Death' : 'Go Yaşam-Ölüm';
      case 'code_breaker':
        return isEnglish ? 'Code Breaker' : 'Kod Kırıcı';
      case 'shogi_mate':
        return isEnglish ? 'Shogi Mate' : 'Shogi Mat';
      case 'island_sea':
        return isEnglish ? 'Island & Sea' : 'Ada ve Deniz';
      case 'peg_solitaire':
        return isEnglish ? 'Peg Solitaire' : 'Tek Taş';
      case 'futoshiki':
        return 'Futoshiki';
      case 'hex_connection':
        return isEnglish ? 'Hex Connection' : 'Hex Bağlantısı';
      case 'skyscrapers':
        return isEnglish ? 'Skyscrapers' : 'Gökdelenler';
      case 'hitori':
        return 'Hitori';
      case 'balloon_pop':
        return isEnglish ? 'Balloon Catcher' : 'Balon Avcısı';
      case 'bottle_target':
        return isEnglish ? 'Bottle Target' : 'Şişe Kırmaca';
      case 'color_match':
        return isEnglish ? 'Color Reactor' : 'Renk Reaktörü';
      case 'ball_merge':
        return isEnglish ? 'Ball Merge' : 'Top Birleştir';
      case 'tower_balance':
        return isEnglish ? 'Tower Balance' : 'Kule Denge';
      case 'magnet_path':
        return isEnglish ? 'Magnet Path' : 'Mıknatıs Rotası';
      case 'mini_golf_route':
        return isEnglish ? 'Mini Golf Route' : 'Mini Golf Rota';
      case 'slide_sweets':
        return isEnglish ? 'Sweet Conveyor' : 'Şeker Konveyörü';
      case 'ring_toss':
        return isEnglish ? 'Ring Toss' : 'Halka At';
      case 'little_fisher':
        return isEnglish ? 'Little Fisher' : 'Küçük Balıkçı';
      case 'marble_route':
        return isEnglish ? 'Marble Route' : 'Mermer Rota';
      case 'block_flow':
        return isEnglish ? 'Block Flow' : 'Blok Akışı';
      case 'paper_flight':
        return isEnglish ? 'Paper Flight' : 'Kâğıt Uçak Şampiyonası';
      case 'neon_pinball':
        return 'Neon Pinball';
      case 'kite_runner':
        return isEnglish ? 'Kite Pilot' : 'Uçurtma Pilotu';
      case 'rhythm_drums':
        return isEnglish ? 'Rhythm Workshop' : 'Ritim Atölyesi';
      case 'skate_combo':
        return isEnglish ? 'Skate Flow' : 'Kaykay Akışı';
      case 'snowboard_slalom':
        return isEnglish ? 'Snowboard Slalom' : 'Kar Sörfü Slalomu';
      case 'jetpack_courier':
        return isEnglish ? 'Jetpack Courier' : 'Jetpack Kurye';
      case 'orbit_rescue':
        return isEnglish ? 'Orbit Rescue' : 'Yörünge Kurtarma';
      case 'drift_league':
        return isEnglish ? 'Drift League' : 'Drift Ligi';
      case 'table_tennis_rally':
        return isEnglish ? 'Table Tennis Rally' : 'Masa Tenisi Rallisi';
      case 'penalty_mindgame':
        return isEnglish ? 'Penalty Mindgame' : 'Penaltı Zihin Oyunu';
      case 'air_hockey_arena':
        return 'Air Hockey Arena';
      case 'relic_run':
        return isEnglish ? 'Relic Run' : 'Kalıntı Seferi';
      case 'lighthouse_defense':
        return isEnglish ? 'Lighthouse Defense' : 'Fener Savunması';
      case 'museum_after_hours':
        return isEnglish ? 'Museum: After Hours' : 'Müze: Gece Vardiyası';
      case 'deep_current':
        return isEnglish ? 'Deep Current' : 'Derin Akıntı';
      case 'cafe_shift':
        return isEnglish ? 'Cafe Shift' : 'Kafe Vardiyası';
      case 'interior_studio':
        return isEnglish ? 'Interior Studio' : 'İç Mekân Atölyesi';
      case 'tideglass_aquarium':
        return isEnglish ? 'Tideglass Aquarium' : 'Deniz Camı Akvaryumu';
      case 'pet_rescue_clinic':
        return isEnglish ? 'Pet Rescue Clinic' : 'Dostlar Kurtarma Kliniği';
      case 'boardwalk_builder':
        return isEnglish ? 'Boardwalk Builder' : 'Sahil Parkı Kurucusu';
      case 'moonbase_ops':
        return isEnglish ? 'Moonbase Operations' : 'Ay Üssü Operasyonları';
      case 'museum_curator':
        return isEnglish ? 'Museum Curator' : 'Müze Küratörü';
      case 'festival_producer':
        return isEnglish ? 'Festival Producer' : 'Festival Yapımcısı';
      case 'secret_room_party':
        return isEnglish
            ? 'Secret Room: Social Deduction'
            : 'Gizli Oda: Sosyal Çıkarım';
      case 'dice_bluff_arena':
        return isEnglish ? 'Dice & Dagger' : 'Zar ve Hançer';
      case 'signal_pair':
        return isEnglish ? 'Signal Partner' : 'Sinyal Ortağı';
      case 'deckforge_duel':
        return isEnglish ? 'Deckforge Duel' : 'Deste Ustası';
      case 'city_atlas':
        return isEnglish ? 'Turkey Atlas' : 'Şehir Atlası';
      case 'world_atlas':
        return isEnglish ? 'World Atlas' : 'Dünya Atlası';
      case 'katamino_workshop':
        return isEnglish ? 'Katamino Workshop' : 'Katamino Atölyesi';
      case 'single_stroke':
        return isEnglish ? 'One-Stroke Master' : 'Tek Çizgi Ustası';
      case 'arrow_maze':
        return isEnglish ? 'Arrow Maze' : 'Ok Labirenti';
      case 'bubble_shooter':
        return isEnglish ? 'Bubble Shooter' : 'Baloncuk Arenası';
      case 'picture_iq':
        return isEnglish ? 'Visual IQ' : 'Görsel IQ';
      case 'candy_sort':
        return isEnglish ? 'Candy Sort' : 'Şeker Sıralama';
      case 'number_sort':
        return isEnglish ? '15-Tile Master' : '15 Taş Ustası';
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
      case 'flow_connect':
        return isEnglish
            ? 'Connect matching terminals without crossing paths.'
            : 'Yollar kesişmeden aynı renkteki uçları bağla.';
      case 'circuit_repair':
        return isEnglish
            ? 'Rotate the parts and restore the energy route.'
            : 'Parçaları döndür ve enerji yolunu onar.';
      case 'beam_director':
        return isEnglish
            ? 'Turn the mirrors and guide the beam to its target.'
            : 'Aynaları çevir ve ışını hedefe ulaştır.';
      case 'detective_notes':
        return isEnglish
            ? 'Connect clues across people, rooms and relics to solve the case.'
            : 'Vakayı çözmek için kişi, oda ve eser ipuçlarını birleştir.';
      case 'mine_detective':
        return isEnglish
            ? 'Read adjacent clues and secure every safe cell without guessing.'
            : 'Komşu izlerini oku ve tahmin etmeden tüm güvenli hücreleri aç.';
      case 'warehouse_master':
        return isEnglish
            ? 'Route every crate to a goal without pushing it into a deadlock.'
            : 'Her kasayı çıkmaza sokmadan hedefe ulaştır.';
      case 'bridge_builder':
        return isEnglish
            ? 'Balance island counts, avoid crossings and connect every island.'
            : 'Ada sayılarını tuttur, kesişmeleri önle ve tüm adaları bağla.';
      case 'gate_sequence':
        return isEnglish
            ? 'Use layered clues to uncover the only valid vault-gate order.'
            : 'Katmanlı ipuçlarından kasanın tek doğru kapı sırasını çıkar.';
      case 'parking_puzzle':
        return isEnglish
            ? 'Slide traffic in its lanes and plan a clear route for the target car.'
            : 'Araçları raylarında kaydır, hedef araç için açık bir çıkış planla.';
      case 'pin_unlock':
        return isEnglish
            ? 'Combine pin sums, height relations and mechanical signals to release a unique lock.'
            : 'Tekil kilidi açmak için pim toplamlarını, yükseklik ilişkilerini ve mekanik sinyalleri birleştir.';
      case 'balance_scale':
        return isEnglish
            ? 'Match precision weights to each scale and use the shared clues to find the only balanced arrangement.'
            : 'Hassas ağırlıkları terazilere eşleştir ve tek doğru dizilimi bulmak için ortak ipuçlarını kullan.';
      case 'target_24':
        return isEnglish
            ? 'Combine four number cards with exact arithmetic to reach 24.'
            : 'Dört sayı kartını kesin işlemlerle birleştirerek 24’e ulaş.';
      case 'mini_sudoku':
        return isEnglish
            ? 'Fill each grid so every row, column and region contains each digit once. The board grows from 6×6 to 9×9.'
            : 'Her satır, sütun ve bölgeye her sayıyı bir kez yerleştir. Tahta 6×6’dan 9×9’a büyür.';
      case 'kenken_cube':
        return isEnglish
            ? 'Complete each Latin grid and solve every arithmetic cage with its target.'
            : 'Satır ve sütunlarda sayıları tekrarlamadan ilerle, işlem kafeslerinin hedeflerini bul.';
      case 'mahjong_layers':
        return isEnglish
            ? 'Plan the order of free matching tiles to reveal every layer.'
            : 'Serbest eş taşların sırasını planla ve tüm katmanları aç.';
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
      case 'card_pairs':
        return isEnglish
            ? 'Find evolving visual, color and meaning pairs while keeping the full board in memory.'
            : 'Görsel, renk ve anlam eşleşmelerini değişen kurallarla bul; tüm tahtayı aklında tut.';
      case 'focus_filter':
        return isEnglish
            ? 'Track a changing visual rule, reject near-misses and manage false alarms.'
            : 'Değişen görsel kuralı izle, yakın yanıltıcıları ele ve yanlış alarmı yönet.';
      case 'spot_change':
        return isEnglish
            ? 'Compare two abstract scenes and identify every changed position, including advanced relation swaps.'
            : 'İki soyut sahneyi karşılaştır; ileri seviyedeki yer değişimleri dâhil tüm farkları bul.';
      case 'rhythm_memory':
        return isEnglish
            ? 'Recall distinct notes, rhythmic gaps and accents; reverse the phrase in expert stages.'
            : 'Farklı notaları, ritmik araları ve vurguları hatırla; usta seviyelerinde diziyi tersten çal.';
      case 'attention_tunnel':
        return isEnglish
            ? 'Follow the same moving target through crossing rails and tunnel shutters.'
            : 'Aynı hareketli hedefi kesişen hatlarda ve tünel örtülmelerinde takip et.';
      case 'hanoi':
        return isEnglish
            ? 'Plan your moves and rebuild the colorful tower.'
            : 'Hamlelerini planla ve renkli kuleyi yeniden kur.';
      case 'word_hunt':
        return isEnglish
            ? 'Find hidden words in growing grids.'
            : 'Büyüyen tablolardaki gizli kelimeleri bul.';
      case 'meaning_match':
        return isEnglish
            ? 'Sort sixteen words into four hidden semantic groups.'
            : 'On altı sözcüğü dört gizli anlam kümesine ayır.';
      case 'proverb_finish':
        return isEnglish
            ? 'Complete a Turkish proverb, then see its meaning in context.'
            : 'Bir Türk atasözünü tamamla, ardından bağlam içindeki anlamını gör.';
      case 'sentence_builder':
        return isEnglish
            ? 'Rebuild contextual sentences from meaningful clause blocks.'
            : 'Bağlam ve bağlaç ipuçlarıyla cümle bloklarını yeniden kur.';
      case 'near_meaning':
        return isEnglish
            ? 'Distinguish close meanings through context, tone and evidence.'
            : 'Yakın anlamları bağlam, ton ve cümle kanıtıyla ayırt et.';
      case 'letter_maze':
        return isEnglish
            ? 'Trace a contextual word through a letter maze and its root gate.'
            : 'Bağlamdaki sözcüğü harf labirentinde ve kök kapısından geçirerek bul.';
      case 'language_detective':
        return isEnglish
            ? 'Inspect short sources, separate evidence from inference and explain each finding.'
            : 'Kısa kaynakları incele, kanıtla çıkarımı ayır ve her sonucu gerekçelendir.';
      case 'story_order':
        return isEnglish
            ? 'Read contextual clues, order events by cause and effect, and reject unsupported details.'
            : 'Bağlam ipuçlarını okuyup olayları neden-sonuç sırasına diz ve kanıtsız ayrıntıyı ele.';
      case 'word_wheel':
        return isEnglish
            ? 'Swipe through the letter wheel to find hidden words; longer words score more.'
            : 'Gizli kelimeleri bulmak için harf çarkında parmağını sürükle; uzun kelimeler daha çok puan kazandırır.';
      case 'hidden_masses':
        return isEnglish
            ? 'Compare balanced measurements and deduce each unknown object mass.'
            : 'Dengeli ölçümleri karşılaştır ve nesnelerin bilinmeyen kütlelerini çıkar.';
      case 'kakuro':
        return isEnglish
            ? 'Complete the crossing sum runs without repeating digits.'
            : 'Kesişen toplam dizilerini rakam tekrarı yapmadan tamamla.';
      case 'reversi_arena':
        return isEnglish
            ? 'Flip opposing lines, secure corners and control an 8×8 board.'
            : 'Rakip taşlarını çevir, köşeleri ele geçir ve 8×8 tahtayı yönet.';
      case 'picross_master':
        return isEnglish
            ? 'Use crossing run clues to reveal a uniquely solvable pixel silhouette.'
            : 'Tek çözümlü piksel silüetini satır ve sütun koşu ipuçlarıyla ortaya çıkar.';
      case 'tavla_master':
        return isEnglish
            ? 'Read the dice, make points, hit blots and bear off all fifteen checkers.'
            : 'Zarları değerlendir, kapı kur, açık pulları kır ve on beş pulunu topla.';
      case 'arrow_route':
        return isEnglish
            ? 'Trace each arrow to the boundary and clear its blockers in the only safe order.'
            : 'Her okun sınır rotasını izle ve engellerini tek güvenli sırayla temizle.';
      case 'mini_chess_tactics':
        return isEnglish
            ? 'Find the only legal move that checkmates the king.'
            : 'Şahı mat eden tek yasal hamleyi bul.';
      case 'loop_master':
        return isEnglish
            ? 'Use the clue totals to draw exactly one unbranched closed loop.'
            : 'İpucu toplamlarını kullanarak dallanmayan tek bir kapalı halka çiz.';
      case 'go_life_death':
        return isEnglish
            ? 'Count liberties and find the vital capture or rescue move.'
            : 'Özgürlükleri say ve yaşamsal yakalama ya da kurtarma hamlesini bul.';
      case 'code_breaker':
        return isEnglish
            ? 'Use exact and misplaced-symbol clues to crack the hidden code.'
            : 'Gizli kodu kırmak için yerinde ve yeri yanlış sembol ipuçlarını kullan.';
      case 'shogi_mate':
        return isEnglish
            ? 'Find the only legal mating move using promotion and captured-piece drops.'
            : 'Terfi ve ele geçen taşı oyuna geri koyma kurallarıyla tek yasal mat hamlesini bul.';
      case 'island_sea':
        return isEnglish
            ? 'Build the numbered islands, keep them diagonally separate and connect one sea without 2×2 water.'
            : 'Numaralı adaları kur, çapraz teması engelle ve 2×2 su olmadan tek deniz oluştur.';
      case 'peg_solitaire':
        return isEnglish
            ? 'Jump pegs over one another, remove each captured peg and leave exactly one on the center.'
            : 'Piyonları birbirinin üzerinden atlat, alınan taşı kaldır ve merkezde tam bir taş bırak.';
      case 'futoshiki':
        return isEnglish
            ? 'Fill each row and column with unique values while satisfying every adjacent inequality.'
            : 'Her satır ve sütuna farklı sayılar yerleştir; komşu hücrelerdeki eşitsizlikleri uygula.';
      case 'hex_connection':
        return isEnglish
            ? 'Connect coral edges with an unbroken path while blocking the rival’s blue connection.'
            : 'Rakibin lacivert bağlantısını keserken koral kenarları kesintisiz bir yolla birleştir.';
      case 'skyscrapers':
        return isEnglish
            ? 'Place each height once per row and column; edge clues count the towers visible from each direction.'
            : 'Her yüksekliği satır ve sütunda bir kez kullan; kenar ipuçları her yönden görünen kuleleri sayar.';
      case 'hitori':
        return isEnglish
            ? 'Shade repeated numbers, keep shaded cells apart, and preserve one connected white region.'
            : 'Tekrarlanan sayıları gölgele; siyah hücreleri ayır ve beyaz alanı tek parça bağlı tut.';
      case 'balloon_pop':
        return isEnglish
            ? 'Guide your basket through shifting winds, catch the outlined color and avoid storm decoys.'
            : 'Sepeti değişen rüzgârda yönet; çerçeveli balonları yakala, sis tuzaklarından kaç.';
      case 'bottle_target':
        return isEnglish
            ? 'Set your angle and power, use bank shots and hit the target bottles without breaking the display.'
            : 'Açıyı ve gücü ayarla, sekmeli atışları kullan; sahne eşyalarını koruyarak hedef şişeleri vur.';
      case 'color_match':
        return isEnglish
            ? 'Read each moving energy pulse and route it through the matching shape-and-color channel before it reaches the valve.'
            : 'Hareketli enerji darbesini oku; cam vanaya ulaşmadan şekil ve rengi eşleşen kanala yönlendir.';
      case 'ball_merge':
        return isEnglish
            ? 'Aim each orb into a changing physics chamber, fuse equal values and manage the rising stack before it crosses the overfill line.'
            : 'Küreleri değişen fizik haznesinde doğru rotaya bırak; eşit değerleri birleştir ve yığın taşma çizgisine ulaşmadan alanı yönet.';
      case 'tower_balance':
        return isEnglish
            ? 'Place asymmetric pieces on a swaying support by reading their mass, overlap and wind-driven center of gravity.'
            : 'Asimetrik parçaları salınan platforma yerleştirirken kütleyi, temas yüzeyini ve rüzgârla kayan ağırlık merkezini oku.';
      case 'magnet_path':
        return isEnglish
            ? 'Drag a horseshoe magnet to attract or repel an inertial puck through ordered gates and around metal shields.'
            : 'At nalı mıknatısı sürükleyerek ataletli bilyeyi çek veya it; sıralı kapılardan ve metal kalkanlardan geçir.';
      case 'mini_golf_route':
        return isEnglish
            ? 'Read turf and sand friction, choose power and spin, and time your putt through a moving gate.'
            : 'Çim ve kum sürtünmesini oku; güç/spin seçip vuruşunu hareketli kapının ritminde yap.';
      case 'slide_sweets':
        return isEnglish
            ? 'Route wrapped sweets through two live conveyor junctions, read the order wave and protect the line buffer.'
            : 'Sarma şekerleri iki hareketli konveyör kavşağından doğru pakete yönlendir; sipariş dalgasını okuyup bant kapasitesini koru.';
      case 'ring_toss':
        return isEnglish
            ? 'Set the pull-back angle, power and spin; read wind and catch a moving peg with a soft parabolic throw.'
            : 'Geri çekme açısı, güç ve dönüşü ayarla; rüzgârı okuyup hareketli direği yumuşak parabolik atışla yakala.';
      case 'little_fisher':
        return isEnglish
            ? 'Match bait and depth to the fish, then pulse the reel inside a live tension window as layered currents pull.'
            : 'Yem ve derinliği balığa uydur; katmanlı akıntı çekerken makarayı canlı misina gerilim aralığında darbeli yönet.';
      case 'marble_route':
        return isEnglish
            ? 'Tilt an inertia-driven marble through moving gates; manage ice, felt, bumpers and side pockets before easing into the cup.'
            : 'Ataletli bilyeyi hareketli geçitlerden geçir; çukura yumuşakça girmeden önce buz, keçe, tampon ve yan cepleri yönet.';
      case 'block_flow':
        return isEnglish
            ? 'Switch lanes through a geometric corridor, collect energy cubes and spend them at phase rifts to cross stacked routes.'
            : 'Geometrik koridorda şerit değiştir, enerji küplerini topla ve katman kapılarında harcayarak üst üste rotaları aş.';
      case 'paper_flight':
        return isEnglish
            ? 'Manage bank, pitch and thermals to glide through moving hoops, preserve altitude and flare onto a narrow runway.'
            : 'Yatış, burun açısı ve termikleri yönet; hareketli halkalardan süzül, irtifayı koru ve dar piste yumuşakça in.';
      case 'neon_pinball':
        return isEnglish
            ? 'Time both flippers, follow moving targets in sequence, chain bumper rebounds and release multiball from the lock.'
            : 'İki kanadı zamanla; hareketli hedef sırasını izle, bumper sekmelerini komboya bağla ve kilitten çift topu aç.';
      case 'kite_runner':
        return isEnglish
            ? 'Steer a fabric kite through shifting flag gates; trim the tether under gusts and avoid live power lines before the string snaps.'
            : 'Kumaş uçurtmayı kayan bayrak kapılarından geçir; rüzgâr hamlelerinde ipi ayarla ve kopmadan elektrik hatlarını aş.';
      case 'rhythm_drums':
        return isEnglish
            ? 'Read four percussion lanes, strike syncopated beats with precise timing and sustain long notes through changing bars.'
            : 'Dört davul şeridini izle; senkoplu vuruşları tam zamanında çal ve değişen ölçülerde uzun notaları basılı tut.';
      case 'skate_combo':
        return isEnglish
            ? 'Build speed into each ramp, spin a measured trick in the air and manage board balance to keep a clean landing combo.'
            : 'Rampaya hız taşı; havada ölçülü dönüş yap ve temiz iniş combo’su için gövde dengesini yönet.';
      case 'snowboard_slalom':
        return isEnglish
            ? 'Carve an inertial line through slalom flags, read changing snow grip and scrub speed before icy or mogul gates.'
            : 'Ataletli kavisle slalom kapılarından geç; değişen kar tutuşunu oku, buz ve tümsek kapılarından önce hızı kes.';
      case 'jetpack_courier':
        return isEnglish
            ? 'Balance thrust, fuel and heat to thread a courier pod through shifting air gates and dock the fragile cargo softly.'
            : 'İtki, yakıt ve ısıyı dengele; kurye kapsülünü değişen hava kapılarından geçirip hassas paketi yumuşakça indir.';
      case 'orbit_rescue':
        return isEnglish
            ? 'Read three gravity wells, spend limited impulse bursts and brake into a narrow rescue orbit.'
            : 'Üç kütleçekim kuyusunu oku; sınırlı itki darbelerini kullan ve dar kurtarma yörüngesine frenle.';
      case 'drift_league':
        return isEnglish
            ? 'Hold your line through shaped circuits, brake into corners and chain controlled drifts across changing road surfaces.'
            : 'Virajlı pistlerde çizgini koru; fren ve el frenini ayır, değişen zeminlerde kontrollü drift zinciri kur.';
      case 'table_tennis_rally':
        return isEnglish
            ? 'Read the bounce, move your paddle, then time a topspin, slice or block to outplay a moving opponent.'
            : 'Sekişi oku, raketini konumlandır; hareketli rakibe karşı zamanında üst spin, kesme ya da blok seç.';
      case 'penalty_mindgame':
        return isEnglish
            ? 'Take penalties with deliberate power and read shoulder, hip and plant-foot cues before diving as keeper.'
            : 'Gücü ayarlı şut çek; kaleci rolünde dalmadan önce omuz, kalça ve destek ayağı ipuçlarını oku.';
      case 'air_hockey_arena':
        return isEnglish
            ? 'Lead the puck with real-time mallet control, bank off the rails, read bumper rebounds and time one charged smash per point.'
            : 'Diski gerçek zamanlı raketle karşıla; kenarlardan açı al, tampon sekmesini oku ve her sayıda tek güçlü smaçı zamanla.';
      case 'relic_run':
        return isEnglish
            ? 'Clear three tactical rooms, read enemy strike tells, evade danger lanes and choose a relic between rooms.'
            : 'Üç taktik odayı temizle, düşman saldırı işaretlerini oku, tehlike hattından kaçın ve odalar arasında kalıntı seç.';
      case 'lighthouse_defense':
        return isEnglish
            ? 'Build ballista, frost and mortar towers around switchback paths, set target priorities and manage coins between enemy waves.'
            : 'Kıvrımlı kıyı yollarına balista, ayaz ve havan kuleleri kur; hedef önceliğini belirle ve dalgalar arasında altını yönet.';
      case 'museum_after_hours':
        return isEnglish
            ? 'Read guard sight cones and laser cycles, hide in gallery shadows, recover the collection and slip out before the alarm.'
            : 'Nöbetçi görüşünü ve lazer çevrimini oku; galeri gölgelerinde saklan, eserleri topla ve alarm çalmadan çık.';
      case 'deep_current':
        return isEnglish
            ? 'Pilot a compact submarine through live currents, sweep sonar for salvage and return to base with air, battery and hull intact.'
            : 'Mini denizaltıyı değişen akıntılarda sür; sonar ile enkazı bul ve oksijen, batarya, gövde payını koruyup üsse dön.';
      case 'cafe_shift':
        return isEnglish
            ? 'Read guest tickets, route recipes through concurrent cafe stations, protect ingredient stock and serve before patience runs out.'
            : 'Müşteri fişlerini oku, tarifleri eşzamanlı kafe istasyonlarına dağıt; stok ve sabrı yönetip doğru siparişi servis et.';
      case 'interior_studio':
        return isEnglish
            ? 'Design a room around a visible brief, budget, style, palette and accessible walkway.'
            : 'Görünür brief, bütçe, stil, renk paleti ve geçiş alanına göre oda tasarla.';
      case 'tideglass_aquarium':
        return isEnglish
            ? 'Build a compatible aquarium by balancing fish groups, tank volume, water temperature, oxygen, filter and plants.'
            : 'Canlı grupları, tank hacmi, su sıcaklığı, oksijen, filtre ve bitki dengesini kurarak uyumlu akvaryum tasarla.';
      case 'pet_rescue_clinic':
        return isEnglish
            ? 'Sequence gentle, fictional visit activities for a cartoon animal. This is a care-themed game, not veterinary guidance.'
            : 'Çizgi karakter hayvan için kurmaca ve nazik ziyaret etkinliklerini sırala. Bu bakım temalı bir oyundur, veteriner önerisi değildir.';
      case 'boardwalk_builder':
        return isEnglish
            ? 'Design a connected seaside park by balancing paths, guest capacity, food service, budget and weather-ready amenities.'
            : 'Yolları, ziyaretçi kapasitesini, yiyecek servisini, bütçeyi ve hava koşullarına uygun hizmetleri dengeleyerek bağlantılı bir sahil parkı tasarla.';
      case 'moonbase_ops':
        return isEnglish
            ? 'Connect a moonbase life-support network and balance power, oxygen, temperature, crew and mission hazards.'
            : 'Ay üssü yaşam destek ağını bağla; enerji, oksijen, sıcaklık, ekip ve görev tehditlerini dengele.';
      case 'museum_curator':
        return isEnglish
            ? 'Curate a themed exhibition by arranging artifacts in era order while protecting fragile objects and balancing visitor appeal and budget.'
            : 'Eserleri dönem sırasına koy; kırılgan parçaları koruyup ziyaretçi ilgisi ve bütçeyi dengeleyerek temalı sergi kur.';
      case 'festival_producer':
        return isEnglish
            ? 'Build a two-stage festival lineup around time windows, audience flow, crew, power, budget and weather.'
            : 'Zaman aralıkları, seyirci akışı, ekip, enerji, bütçe ve hava koşullarını dengeleyerek iki sahneli festival programı kur.';
      case 'secret_room_party':
        return isEnglish
            ? 'Pass one device around, reveal private roles safely, discuss a mystery and cast a sealed vote.'
            : 'Tek cihazı sırayla paylaş; özel rolleri güvenle aç, vakayı tartış ve kapalı oy kullan.';
      case 'dice_bluff_arena':
        return isEnglish
            ? 'Read a hidden dice pool, raise a legal probability claim or challenge the bid; the computer never sees your hand.'
            : 'Gizli zar havuzunu değerlendir, olasılığa dayalı yasal iddiayı yükselt ya da blöfe meydan oku; bilgisayar elini göremez.';
      case 'signal_pair':
        return isEnglish
            ? 'Two players share one device: the navigator sees a private route, the operator gets a cross-wired panel, and both restore a relay through communication.'
            : 'İki oyuncu tek cihazı paylaşır: gezgin özel rotayı, operatör çapraz bağlı paneli görür; röleyi iletişimle birlikte onarırlar.';
      case 'deckforge_duel':
        return isEnglish
            ? 'Build tactical plans from a compact deck, manage limited energy, read the rival’s open intent, and resolve attacks simultaneously.'
            : 'Kompakt desteden taktik plan kur, sınırlı enerjiyi yönet, rakibin açık niyetini oku ve saldırıları eşzamanlı çöz.';
      case 'city_atlas':
        return isEnglish
            ? 'Locate Turkish provinces by their real administrative boundaries.'
            : 'Türkiye illerini gerçek idari sınırları üzerinden bul.';
      case 'world_atlas':
        return isEnglish
            ? 'Identify countries from an offline world map with real borders.'
            : 'Çevrimdışı gerçek dünya haritasında ülkeleri sınırlarından tanı.';
      case 'katamino_workshop':
        return isEnglish
            ? 'Rotate, mirror and fit connected polyomino pieces into a complete board.'
            : 'Bağlantılı poliomino parçalarını döndürüp aynalayarak tahtayı eksiksiz döşe.';
      case 'single_stroke':
        return isEnglish
            ? 'Trace a connected network without repeating an edge; later circuits add loops and branching.'
            : 'Bağlantılı ağı bir kenarı yinelemeden çiz; ileri bölümlerde döngüler ve dallar artar.';
      case 'arrow_maze':
        return isEnglish
            ? 'Turn one-way floor arrows to navigate a growing, generated maze.'
            : 'Giderek karmaşıklaşan üretilmiş labirentte tek yönlü zemin oklarını çevir.';
      case 'bubble_shooter':
        return isEnglish
            ? 'Aim with a bounce shot, match color clusters and clear each board within its shot budget.'
            : 'Sekmeli atışlarla nişan al, renk kümelerini eşleştir ve tahtayı atış sınırında temizle.';
      case 'picture_iq':
        return isEnglish
            ? 'Decode visual transformations and analogies.'
            : 'Görsel dönüşümleri ve benzetmeleri çöz.';
      case 'candy_sort':
        return isEnglish
            ? 'Move the top candy onto the same color or into an empty jar until every color is grouped.'
            : 'Her renk gruplanana kadar üstteki şekeri aynı rengin üzerine veya boş kavanoza taşı.';
      case 'number_sort':
        return isEnglish
            ? 'Slide the 8- or 15-tile board into its numbered order using the empty space.'
            : 'Boş alanı kullanarak 8 ya da 15 taşı numaralı hedef dizilimine kaydır.';
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
    if (!isEnglish) {
      final String? tr = _gameUiTurkish[raw];
      if (tr != null) return tr;
      return raw;
    }

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

const Map<String, String> _gameUiTurkish = <String, String>{
  'Mind tools': 'Zihin Araçları',
  'Useful, personal tools alongside the games.':
      'Oyunların yanı sıra faydalı, kişisel araçlar.',
  'Smart Vocabulary Notebook': 'Akıllı Kelime Defteri',
  'Save your own words and review them on time.':
      'Kendi kelimelerini kaydet ve zamanında tekrar et.',
  'SHOPPING · TRAVEL · TO-DO': 'ALIŞVERİŞ · SEYAHAT · GÖREV',
  'Shopping & Prep Assistant': 'Alışveriş ve Hazırlık Asistanı',
  'Keep everyday lists together, right on your device.':
      'Günlük listelerini cihazında bir arada tut.',
  'READ · LISTEN · RECALL': 'OKU · DİNLE · HATIRLA',
  'Micro-stories & comprehension': 'Mikro Hikayeler ve Anlama',
  'Read or hear original short passages, then retrieve the details.':
      'Kısa metinleri oku veya dinle, ardından detayları hatırla.',
  'REAL-LIFE PRACTICE': 'GÜNLÜK YAŞAM PRATİĞİ',
  'Daily Conversation Tasks': 'Günlük Konuşma Görevleri',
  'Practice clear, considerate choices in useful scenarios.':
      'Faydalı senaryolarda net ve düşünceli seçimler yap.',
};

const Map<String, String> _gameUiEnglish = <String, String>{
  // Mind tools
  'Zihin Araçları': 'Mind tools',
  'Zihin araçları': 'Mind tools',
  'Oyunların yanı sıra faydalı, kişisel araçlar.':
      'Useful, personal tools alongside the games.',
  'Akıllı Kelime Defteri': 'Smart Vocabulary Notebook',
  'Kendi kelimelerini kaydet ve zamanında tekrar et.':
      'Save your own words and review them on time.',
  'ALIŞVERİŞ · SEYAHAT · GÖREV': 'SHOPPING · TRAVEL · TO-DO',
  'Alışveriş ve Hazırlık Asistanı': 'Shopping & Prep Assistant',
  'Günlük listelerini cihazında bir arada tut.':
      'Keep everyday lists together, right on your device.',
  'OKU · DİNLE · HATIRLA': 'READ · LISTEN · RECALL',
  'Mikro Hikayeler ve Anlama': 'Micro-stories & comprehension',
  'Kısa metinleri oku veya dinle, ardından detayları hatırla.':
      'Read or hear original short passages, then retrieve the details.',
  'GÜNLÜK YAŞAM PRATİĞİ': 'REAL-LIFE PRACTICE',
  'Günlük Konuşma Görevleri': 'Daily Conversation Tasks',
  'Faydalı senaryolarda net ve düşünceli seçimler yap.':
      'Practice clear, considerate choices in useful scenarios.',

  // Generic difficulty / game labels
  'KOLAY': 'EASY',
  'ORTA': 'MEDIUM',
  'ZOR': 'HARD',
  'USTALAŞMA': 'MASTERY',
  'İLERİ': 'ADVANCED',
  'UZMAN': 'EXPERT',
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
  'BÖLÜM': 'CHAPTER',
  'Bölüm': 'Chapter',
  'TEKRAR OYNA': 'PLAY AGAIN',
  'Yeniden Başlat': 'Restart',
  'Yeniden başlat': 'Restart',
  'YENİ REKOR': 'NEW RECORD',
  'Yeni Rekor': 'New Record',
  'YENİ TUR': 'NEW ROUND',
  'Yeni Tur': 'New Round',
  'SONRAKİ': 'NEXT',
  'Sonraki': 'Next',
  'HARİTA': 'MAP',
  'Harita': 'Map',
  'TEKRAR DENE': 'RETRY',
  'Tekrar Dene': 'Retry',
  'Tekrar dene': 'Retry',
  'OYNA': 'PLAY',
  'Oyna': 'Play',
  'BAŞLA': 'START',
  'Başla': 'Start',
  'DEVAM ET': 'CONTINUE',
  'Devam Et': 'Continue',
  'Devam et': 'Continue',
  'DURDURULDU': 'PAUSED',
  'Durduruldu': 'Paused',
  'OYUNA DÖN': 'RESUME',
  'Oyuna Dön': 'Resume',
  'Oyuna dön': 'Resume',
  'ÇIKIŞ': 'EXIT',
  'Çıkış': 'Exit',
  'İPTAL': 'CANCEL',
  'İptal': 'Cancel',
  'KAPAT': 'CLOSE',
  'Kapat': 'Close',
  'TAMAM': 'OK',
  'Tamam': 'OK',
  'EVET': 'YES',
  'Evet': 'Yes',
  'HAYIR': 'NO',
  'Hayır': 'No',
  'KONTROL ET': 'CHECK',
  'Kontrol Et': 'Check',
  'Kontrol et': 'Check',
  'CEVABI KONTROL ET': 'CHECK ANSWER',
  'Cevabı Kontrol Et': 'Check Answer',
  'Cevabı kontrol et': 'Check answer',
  'CEVAP DOĞRU': 'CORRECT ANSWER',
  'Cevap doğru': 'Correct answer',
  'İPUCU AL': 'TAKE HINT',
  'İpucu Al': 'Take Hint',
  'İpucu al': 'Take hint',
  'İPUÇLARI TAMAMLANDI': 'HINTS COMPLETE',
  'İpuçları tamamlandı': 'Hints complete',
  'SIFIRLA': 'RESET',
  'Sıfırla': 'Reset',
  'GERİ AL': 'UNDO',
  'Geri Al': 'Undo',
  'Geri al': 'Undo',
  'TEMİZLE': 'CLEAR',
  'Temizle': 'Clear',
  'VAKAYI ÇÖZ': 'SOLVE CASE',
  'Vakayı Çöz': 'Solve Case',
  'Vakayı çöz': 'Solve case',
  'KİLİDİ AÇ': 'UNLOCK',
  'Kilidi Aç': 'Unlock',
  'Kilidi aç': 'Unlock',
  'NASIL OYNANIR?': 'HOW TO PLAY',
  'Nasıl oynanır?': 'How to play',
  'Nasıl Oynanır?': 'How to Play',
  'Nasıl Oynanır': 'How to Play',
  'Alan yeniden kurulsun mu?': 'Restart this field?',
  'Aynı doğrulanmış ok yerleşimi yeniden kurulacak.': 'The same certified arrow layout will be restored.',
  'Bu ızgara sıfırlansın mı?': 'Reset this grid?',
  'Aynı başlangıç ipuçları ve eşitsizlikler geri yüklenecek.': 'The same clues and inequalities will be restored.',
  'Bu bulmaca sıfırlansın mı?': 'Reset this puzzle?',
  'Bu tsumego sıfırlansın mı?': 'Reset this tsumego?',
  'Aynı doğrulanmış konum yeniden kurulacak.': 'The same certified position will be restored.',
  'Hedef kayboldu': 'Target lost',
  'Deneme hakkın doldu. Kartları sıfırla ve hedefi yeniden izle.': 'Your attempts are used. Reset the cards and follow the target again.',
  'DENGE SAĞLANDI': 'BALANCE ACHIEVED',
  'Denge sağlandı': 'Balance achieved',
  'KASA AÇILDI': 'VAULT OPENED',
  'Kasa açıldı': 'Vault opened',
  'Arena tamamlandı': 'Arena point',
  'SEVİYE TAMAMLANDI': 'LEVEL COMPLETED',
  'Seviye tamamlandı': 'Level completed',
  'Seviye Tamamlandı': 'Level completed',
  'REKOR': 'RECORD',
  'Rekor': 'Record',
  'SÜRE': 'TIME',
  'Süre': 'Time',
  'KALAN': 'REMAINING',
  'Kalan': 'Remaining',
  'YANLIŞ': 'WRONG',
  'Yanlış': 'Wrong',
  'TEBRİKLER!': 'CONGRATULATIONS!',
  'Tebrikler!': 'Congratulations!',
  'ZAFER!': 'VICTORY!',
  'Zafer!': 'Victory!',
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
