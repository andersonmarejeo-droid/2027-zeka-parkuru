import 'dart:math' as math;

enum SecretRoomPersona {
  archivist,
  guard,
  conservator,
  technician,
  courier,
  host,
}

extension SecretRoomPersonaLabel on SecretRoomPersona {
  String label(bool english) => switch (this) {
    SecretRoomPersona.archivist => english ? 'ARCHIVIST' : 'ARŞİVCİ',
    SecretRoomPersona.guard => english ? 'NIGHT GUARD' : 'GECE GÖREVLİSİ',
    SecretRoomPersona.conservator => english ? 'CONSERVATOR' : 'RESTORATÖR',
    SecretRoomPersona.technician => english ? 'TECHNICIAN' : 'TEKNİSYEN',
    SecretRoomPersona.courier => english ? 'COURIER' : 'KURYE',
    SecretRoomPersona.host => english ? 'HOST' : 'EV SAHİBİ',
  };
}

class SecretPlayerCard {
  const SecretPlayerCard({
    required this.persona,
    required this.isSaboteur,
    required this.privateBriefTr,
    required this.privateBriefEn,
    required this.cardCode,
  });

  final SecretRoomPersona persona;
  final bool isSaboteur;
  final String privateBriefTr;
  final String privateBriefEn;
  final String cardCode;

  String privateBrief(bool english) =>
      english ? privateBriefEn : privateBriefTr;
}

class SecretRoomScenario {
  SecretRoomScenario._({
    required this.level,
    required this.playerCount,
    required this.seed,
    required this.caseId,
    required this.variant,
    required this.titleTr,
    required this.titleEn,
    required this.locationTr,
    required this.locationEn,
    required this.incidentTr,
    required this.incidentEn,
    required this.publicEvidenceTr,
    required this.publicEvidenceEn,
    required this.playerCards,
    required this.requiredVotes,
  });

  static const int campaignLevels = 20;
  static const int practiceCases = 300;
  static const List<_SecretCaseSeed> _cases = <_SecretCaseSeed>[
    _SecretCaseSeed(
      'amber_clock',
      'Kehribar Saat',
      'The Amber Clock',
      'Saat Odası',
      'Clock Room',
      'Kehribar saatin kurma anahtarı kayboldu.',
      'The winding key for the amber clock has vanished.',
      <String>[
        'Duvar saati 21.10’da iki kez çaldı.',
        'Koridor kamerası 21.08’de kısa süre karardı.',
        'Vitrin mührü sağlam, fakat anahtar yuvası boş.',
        'Yağmur 21.00’den sonra başladı.',
      ],
      <String>[
        'The wall clock chimed twice at 9:10.',
        'The corridor camera blinked at 9:08.',
        'The case seal is intact, but its key slot is empty.',
        'Rain began after 9:00.',
      ],
      'Kurma anahtarını kesinti sırasında aldın; saatin önünde değildin.',
      'You took the winding key during the camera outage; you were not near the clock.',
    ),
    _SecretCaseSeed(
      'glass_orchid',
      'Cam Orkide',
      'The Glass Orchid',
      'Kış Bahçesi',
      'Winter Garden',
      'Cam orkide gece sayımından önce yer değiştirdi.',
      'The glass orchid moved before the night inventory.',
      <String>[
        'Kuzey kapısı 20.42’de açıldı.',
        'Saksı altındaki keçe kuru kaldı.',
        'Pencere mandalı içeriden kapalıydı.',
        'Sulama çizelgesi 20.30’da imzalandı.',
      ],
      <String>[
        'The north door opened at 8:42.',
        'The felt beneath the pot stayed dry.',
        'The window latch was locked from inside.',
        'The watering log was signed at 8:30.',
      ],
      'Orkideyi kuzey kapısı açılmadan önce taşıdın; ıslak eldivenini sakla.',
      'You moved the orchid before the north door opened; hide your damp glove.',
    ),
    _SecretCaseSeed(
      'blueprint',
      'Mavi Plan',
      'The Blue Blueprint',
      'Harita Arşivi',
      'Map Archive',
      'Liman planının son sayfası dosyadan çıktı.',
      'The final page of the harbor plan is missing.',
      <String>[
        'Dosya bağı kopmamış.',
        'Mavi mürekkep yalnızca masanın doğu kenarında bulundu.',
        'Arşiv lambası 19.26’da söndü.',
        'Pencere tozunda yeni iz yok.',
      ],
      <String>[
        'The file tie is unbroken.',
        'Blue ink was found only at the east desk edge.',
        'The archive lamp went dark at 7:26.',
        'No fresh marks cross the window dust.',
      ],
      'Son sayfayı mavi kılıfa aldın; masada mürekkep izi bırakmadığını söyle.',
      'You slipped the last page into a blue sleeve; deny leaving ink at the desk.',
    ),
    _SecretCaseSeed(
      'silent_bell',
      'Sessiz Çan',
      'The Silent Bell',
      'Kule Fuayesi',
      'Tower Foyer',
      'Eski çanın tokmağı prova başlamadan kayboldu.',
      'The old bell clapper vanished before rehearsal.',
      <String>[
        'Kule kapısı 18.05’te içeriden kilitlendi.',
        'Tokmak yuvasında taze pirinç tozu var.',
        'Prova listesinde bir satır silinmiş.',
        'Merdiven korkuluğu hâlâ ıslak.',
      ],
      <String>[
        'The tower door was locked from inside at 6:05.',
        'Fresh brass dust sits in the clapper cradle.',
        'One line was erased from the rehearsal list.',
        'The stair rail is still wet.',
      ],
      'Tokmağı zil sesi denemek için aldın ve geri koymadın.',
      'You borrowed the clapper to test its tone and never returned it.',
    ),
    _SecretCaseSeed(
      'velvet_glove',
      'Kadife Eldiven',
      'The Velvet Glove',
      'Kostüm Atölyesi',
      'Costume Studio',
      'Kırmızı kadife eldiven final kostümünden eksik.',
      'A red velvet glove is missing from the finale costume.',
      <String>[
        'Askı numarası 14 boş.',
        'Dikiş kutusu açık bırakılmış.',
        'Sahne tozu sadece sağ manşette.',
        'Prova aynasında tek bir parmak izi var.',
      ],
      <String>[
        'Hanger 14 is empty.',
        'The sewing case was left open.',
        'Stage dust appears only on the right cuff.',
        'There is one fingerprint on the rehearsal mirror.',
      ],
      'Eldiveni prova için aldın; terziye geri verdiğini iddia et.',
      'You took the glove for rehearsal; claim you returned it to the tailor.',
    ),
    _SecretCaseSeed(
      'tidal_key',
      'Gelgit Anahtarı',
      'The Tidal Key',
      'Deniz Feneri',
      'Lighthouse',
      'Fenerin bakım anahtarı gün batımından sonra bulunamadı.',
      'The lighthouse service key is missing after sunset.',
      <String>[
        'Işık üç kez kısa kesildi.',
        'Dış basamaklarda iki farklı ayakkabı izi var.',
        'Yağ kutusu yeni açılmış.',
        'Kapı iç sürgüsü kapalıydı.',
      ],
      <String>[
        'The beam flickered briefly three times.',
        'Two different shoe prints mark the outer steps.',
        'The oil tin was freshly opened.',
        'The inside bolt was closed.',
      ],
      'Anahtarı ışık kesintisinde aldın; basamaklardaki izlerden söz etme.',
      'You took the key during a beam flicker; do not mention the prints on the steps.',
    ),
    _SecretCaseSeed(
      'paper_moon',
      'Kâğıt Ay',
      'The Paper Moon',
      'Planetaryum',
      'Planetarium',
      'Kâğıt ay maketi sunumdan önce yırtıldı.',
      'The paper moon model was torn before the presentation.',
      <String>[
        'Projektör 17.50’de soğutmaya geçti.',
        'Yırtık lifleri masanın altına düştü.',
        'Maket kutusunun kilidi sağlam.',
        'Sahnede gümüş boya izi var.',
      ],
      <String>[
        'The projector entered cooldown at 5:50.',
        'Torn fibers fell beneath the table.',
        'The model box lock is intact.',
        'A trace of silver paint is on the stage.',
      ],
      'Maketin bir parçasını cebine aldın; yırtığın kazara olduğunu savun.',
      'You pocketed part of the model; insist the tear was an accident.',
    ),
    _SecretCaseSeed(
      'copper_leaf',
      'Bakır Yaprak',
      'The Copper Leaf',
      'Heykel Avlusu',
      'Sculpture Court',
      'Bakır yaprak heykelin kaidesinden ayrıldı.',
      'A copper leaf came loose from its sculpture base.',
      <String>[
        'Kaide çevresindeki ip kesilmemiş.',
        'Bakır talaşı doğu bankında.',
        'Avlu lambası 20.16’da yanmış.',
        'Güvenlik defterinde teslim imzası yok.',
      ],
      <String>[
        'The cord around the base was not cut.',
        'Copper filings lie by the east bench.',
        'The courtyard lamp came on at 8:16.',
        'The security ledger has no handover signature.',
      ],
      'Bakır yaprağı cebine koydun; bankta oturmadığını söyle.',
      'You pocketed the copper leaf; claim you never sat on the bench.',
    ),
    _SecretCaseSeed(
      'red_index',
      'Kırmızı Fiş',
      'The Red Index',
      'Okuma Salonu',
      'Reading Room',
      'Kırmızı katalog fişi doğru raftan çıkarıldı.',
      'The red catalog card was removed from its correct shelf.',
      <String>[
        'Raf etiketi yerinde.',
        'Fişin arkasında kömür tozu var.',
        'Salon saati beş dakika geri.',
        'Sözlük açık bırakılmış.',
      ],
      <String>[
        'The shelf label is untouched.',
        'Charcoal dust marks the back of the card.',
        'The reading-room clock is five minutes slow.',
        'A dictionary was left open.',
      ],
      'Fişi aradığın kitabın arasına koydun; kömür tozunu açıklama.',
      'You tucked the card inside a book you wanted; do not explain the charcoal.',
    ),
    _SecretCaseSeed(
      'winter_mask',
      'Kış Maskesi',
      'The Winter Mask',
      'Maske Galerisi',
      'Mask Gallery',
      'Beyaz maske kapanışta yüzünden çevrilmiş bulundu.',
      'The white mask was found facing the wall at closing.',
      <String>[
        'Askı zinciri gevşememiş.',
        'Maske arkasındaki etikette yeni bir çizik var.',
        'Galeri kapısı iki kez açıldı.',
        'Zemin temizleme izi kuzey duvarında bitiyor.',
      ],
      <String>[
        'The display chain is not loose.',
        'A new scratch marks the label behind the mask.',
        'The gallery door opened twice.',
        'A cleaning streak ends at the north wall.',
      ],
      'Maskeyi duvara sen çevirdin; zincire dokunmadığını iddia et.',
      'You turned the mask toward the wall; insist you never touched its chain.',
    ),
    _SecretCaseSeed(
      'hollow_token',
      'Oyuk Jeton',
      'The Hollow Token',
      'Oyun Arşivi',
      'Game Archive',
      'Oyuk pirinç jeton koleksiyon kutusundan eksik.',
      'A hollow brass token is missing from the collection box.',
      <String>[
        'Kutu kapağında çizik yok.',
        'Mavi tebeşir izi girişte başlıyor.',
        'Sayaç 31 ziyaretçi göstermiş.',
        'Jeton yuvası diğerlerinden daha temiz.',
      ],
      <String>[
        'The box lid has no scratches.',
        'A blue chalk mark begins at the entrance.',
        'The counter shows 31 visitors.',
        'The token slot is cleaner than the others.',
      ],
      'Jetonu avucunda çevirdin; kutuya yaklaşmadığını söyle.',
      'You turned the token in your palm; claim you never approached the box.',
    ),
    _SecretCaseSeed(
      'frost_letter',
      'Buzlu Mektup',
      'The Frost Letter',
      'Posta Odası',
      'Mail Room',
      'Mühürlü mektubun zarfı açılmadan hafifledi.',
      'The sealed letter became lighter without its envelope opening.',
      <String>[
        'Mühür mumu çatlak değil.',
        'Terazi 12 gram fark gösteriyor.',
        'Mektup terazisinin pili yeni.',
        'Kar izi yalnızca arka paspasta.',
      ],
      <String>[
        'The wax seal is not cracked.',
        'The scale shows a 12-gram difference.',
        'The letter scale has a fresh battery.',
        'Snow marks only the rear mat.',
      ],
      'Mektubu ışığa tuttun ve iç kartı çıkardın; tartıdan söz etme.',
      'You held the letter to the light and removed its insert; say nothing about the scale.',
    ),
    _SecretCaseSeed(
      'bronze_compass',
      'Bronz Pusula',
      'The Bronze Compass',
      'Keşif Odası',
      'Discovery Room',
      'Bronz pusula kuzeyi göstermeyi bıraktı.',
      'The bronze compass stopped pointing north.',
      <String>[
        'Vitrin mıknatısı kapalı.',
        'Pusula iğnesinde ince bir eğrilik var.',
        'Harita masası 18.32’de taşındı.',
        'Tavan fanı duruyor.',
      ],
      <String>[
        'The display magnet is switched off.',
        'The compass needle has a slight bend.',
        'The map table moved at 6:32.',
        'The ceiling fan is still.',
      ],
      'Pusulayı yere düşürdün; masayı kimseye taşıtmadığını söyle.',
      'You dropped the compass; claim the table was never moved.',
    ),
    _SecretCaseSeed(
      'last_cassette',
      'Son Kaset',
      'The Last Cassette',
      'Dinleme Kabini',
      'Listening Booth',
      'Son konser kaydının kaseti yanlış kutuya kondu.',
      'The final concert tape was placed in the wrong case.',
      <String>[
        'Kaset kabuğunda yeni etiket yok.',
        'Kulaklık sol kanaldan ses vermiyor.',
        'Raf lambası 22.03’te açık kalmış.',
        'Kutuda nane kokusu var.',
      ],
      <String>[
        'The cassette shell has no new label.',
        'The left headphone channel is silent.',
        'The shelf light stayed on at 10:03.',
        'The case smells faintly of mint.',
      ],
      'Kaseti eve götürmek için çantana aldın; nane kokusunu fark etmediğini söyle.',
      'You packed the tape to take home; claim you did not notice the mint scent.',
    ),
    _SecretCaseSeed(
      'silver_thread',
      'Gümüş İplik',
      'The Silver Thread',
      'Dokuma Galerisi',
      'Weaving Gallery',
      'Gümüş iplik duvar dokumasından söküldü.',
      'A silver thread was pulled from the wall tapestry.',
      <String>[
        'Dokuma çivileri yerinde.',
        'Yerde tek bir gümüş lif var.',
        'Onarım makası kapalı.',
        'Galerideki nem ölçeri yükselmiş.',
      ],
      <String>[
        'The tapestry nails are all in place.',
        'One silver fiber lies on the floor.',
        'The repair shears are closed.',
        'Humidity is higher than usual.',
      ],
      'İpliği hatıra olarak kestin; onarım makasını kullanmadığını söyle.',
      'You cut the thread as a keepsake; insist you never touched the repair shears.',
    ),
    _SecretCaseSeed(
      'green_lantern',
      'Yeşil Fener',
      'The Green Lantern',
      'Avlu Geçidi',
      'Courtyard Passage',
      'Yeşil fener sabah nöbetinden önce söndü.',
      'The green lantern went dark before the morning watch.',
      <String>[
        'Yağ haznesi dolu.',
        'Fitil kenarında su damlası var.',
        'Kapı mandalı içeriden açık.',
        'Merdiven altında bir kibrit başı bulundu.',
      ],
      <String>[
        'The oil reservoir is full.',
        'A water bead sits on the wick.',
        'The door latch is open from inside.',
        'A spent match head was found below the stairs.',
      ],
      'Feneri bilerek söndürdün; kibrit yerine suyu suçla.',
      'You deliberately extinguished the lantern; blame the water, not the match.',
    ),
    _SecretCaseSeed(
      'opal_stair',
      'Opal Basamak',
      'The Opal Stair',
      'Kuzey Merdiveni',
      'North Staircase',
      'Opal düğme basamak boşluğunda bulundu.',
      'An opal button was found in the stairwell.',
      <String>[
        'Düğme, üçüncü basamağın altına yuvarlanmış.',
        'Korkulukta kumaş lifi var.',
        'Merdiven ışığı 19.11’de yenilendi.',
        'Basamaklarda toz dağılımı bozulmamış.',
      ],
      <String>[
        'The button rolled beneath the third step.',
        'A fabric fiber clings to the rail.',
        'The stair light was replaced at 7:11.',
        'Dust on the steps is otherwise undisturbed.',
      ],
      'Düğmeyi cebinden düşürdün; merdivenleri kullanmadığını söyle.',
      'You dropped the button from your pocket; claim you never used the stairs.',
    ),
    _SecretCaseSeed(
      'echo_room',
      'Yankı Odası',
      'The Echo Room',
      'Akustik Laboratuvar',
      'Acoustics Lab',
      'Deney kaydında duyulmayan bir alkış var.',
      'An applause appears in the experiment log but not on tape.',
      <String>[
        'Mikrofon 2 sessizdeymiş.',
        'Kayıt saati 18.44’te sıfırlanmış.',
        'Ses kabini kapısı aralık.',
        'Dalga grafiğinde tek bir keskin tepe var.',
      ],
      <String>[
        'Microphone 2 was muted.',
        'The recorder clock reset at 6:44.',
        'The booth door is ajar.',
        'One sharp peak appears in the waveform.',
      ],
      'Alkışı sen ekledin; mikrofon 2’nin kapalı olduğunu sakla.',
      'You added the applause; hide that microphone 2 was muted.',
    ),
    _SecretCaseSeed(
      'paper_bridge',
      'Kâğıt Köprü',
      'The Paper Bridge',
      'Model Atölyesi',
      'Model Workshop',
      'Kâğıt köprü yük testinden önce çöktü.',
      'The paper bridge collapsed before its load test.',
      <String>[
        'Tutkal kapağı kapalı.',
        'Model altındaki gölge yana kaymış.',
        'Üç ağırlığın etiketi karışmış.',
        'Maket bıçağı kılıfında.',
      ],
      <String>[
        'The glue cap is closed.',
        'The shadow beneath the model shifted sideways.',
        'Three weight labels were swapped.',
        'The craft knife is in its sheath.',
      ],
      'Köprü desteğini sen gevşettin; test ağırlıklarını suçla.',
      'You loosened the bridge support; blame the test weights.',
    ),
    _SecretCaseSeed(
      'velour_stage',
      'Son Perde',
      'The Final Curtain',
      'Küçük Sahne',
      'Small Stage',
      'Sahne perdesi son selamdan önce kapandı.',
      'The curtain closed before the final bow.',
      <String>[
        'İp makarası kilitli değil.',
        'Sahne ışıkları açık kalmış.',
        'Sol kuliste bir ayakkabı izi var.',
        'Zil üç dakika erken çalmış.',
      ],
      <String>[
        'The rope spool is not locked.',
        'The stage lights were left on.',
        'One shoe print marks the left wing.',
        'The bell rang three minutes early.',
      ],
      'Perde ipini sen çektin; erken çalan zili teknik arızaya bağla.',
      'You pulled the curtain rope; blame the early bell on a technical fault.',
    ),
  ];

  final int level;
  final int playerCount;
  final int seed;
  final String caseId;
  final int variant;
  final String titleTr;
  final String titleEn;
  final String locationTr;
  final String locationEn;
  final String incidentTr;
  final String incidentEn;
  final List<String> publicEvidenceTr;
  final List<String> publicEvidenceEn;
  final List<SecretPlayerCard> playerCards;
  final int requiredVotes;

  int get saboteurCount =>
      playerCards.where((SecretPlayerCard card) => card.isSaboteur).length;

  int get playerCountMinimum => 3;
  int get playerCountMaximum => 6;

  bool isSaboteur(int player) => playerCards[player].isSaboteur;

  String signature() => <String>[
    caseId,
    variant.toString(),
    playerCount.toString(),
    requiredVotes.toString(),
    publicEvidenceTr.join('|'),
    for (final SecretPlayerCard card in playerCards)
      '${card.persona.name}:${card.isSaboteur}:${card.cardCode}:${card.privateBriefTr}',
  ].join('::');

  static SecretRoomScenario forLevel(int level, {int playerCount = 4}) {
    if (level < 1 || level > campaignLevels) {
      throw RangeError.range(level, 1, campaignLevels, 'level');
    }
    return _create(
      level: level,
      playerCount: playerCount,
      caseIndex: level - 1,
      variant: (level - 1) % 15,
      evidenceCount: (4 - ((level - 1) ~/ 5)).clamp(1, 4),
      seed: 2401 + level * 97 + playerCount * 13,
    );
  }

  static SecretRoomScenario forPractice(int index, {int playerCount = 4}) {
    if (index < 1 || index > practiceCases) {
      throw RangeError.range(index, 1, practiceCases, 'index');
    }
    final int caseIndex = (index - 1) % _cases.length;
    final int variant = (index - 1) ~/ _cases.length;
    return _create(
      level: 20,
      playerCount: playerCount,
      caseIndex: caseIndex,
      variant: variant,
      evidenceCount: 1 + (variant % 4),
      seed: 5101 + index * 113 + playerCount * 19,
    );
  }

  static SecretRoomScenario _create({
    required int level,
    required int playerCount,
    required int caseIndex,
    required int variant,
    required int evidenceCount,
    required int seed,
  }) {
    if (playerCount < 3 || playerCount > 6) {
      throw RangeError.range(playerCount, 3, 6, 'playerCount');
    }
    final _SecretCaseSeed story = _cases[caseIndex];
    final math.Random random = math.Random(seed);
    final List<int> playerOrder = List<int>.generate(
      playerCount,
      (int index) => index,
    )..shuffle(random);
    final int saboteur = playerOrder.first;
    final List<SecretRoomPersona> personas = SecretRoomPersona.values.toList(
      growable: false,
    );
    final List<int> personaOrder = List<int>.generate(
      personas.length,
      (int index) => index,
    )..shuffle(random);
    final List<SecretPlayerCard> cards = List<SecretPlayerCard>.generate(
      playerCount,
      (int player) {
        final bool isSaboteur = player == saboteur;
        final int clueIndex = (player + variant * 3 + caseIndex) % 4;
        return SecretPlayerCard(
          persona: personas[personaOrder[player]],
          isSaboteur: isSaboteur,
          privateBriefTr: isSaboteur
              ? story.saboteurBriefTr
              : 'Özel ipucun: ${story.evidenceTr[clueIndex]}',
          privateBriefEn: isSaboteur
              ? story.saboteurBriefEn
              : 'Your private clue: ${story.evidenceEn[clueIndex]}',
          cardCode: 'P${player + 1}-V$variant-C$caseIndex',
        );
      },
      growable: false,
    );
    final List<int> evidenceOrder = List<int>.generate(
      story.evidenceTr.length,
      (int index) => index,
    )..shuffle(random);
    final List<int> chosen = evidenceOrder.take(evidenceCount).toList();
    return SecretRoomScenario._(
      level: level,
      playerCount: playerCount,
      seed: seed,
      caseId: story.id,
      variant: variant,
      titleTr: story.titleTr,
      titleEn: story.titleEn,
      locationTr: story.locationTr,
      locationEn: story.locationEn,
      incidentTr: story.incidentTr,
      incidentEn: story.incidentEn,
      publicEvidenceTr: List<String>.unmodifiable(
        chosen.map((int index) => story.evidenceTr[index]),
      ),
      publicEvidenceEn: List<String>.unmodifiable(
        chosen.map((int index) => story.evidenceEn[index]),
      ),
      playerCards: List<SecretPlayerCard>.unmodifiable(cards),
      requiredVotes: (playerCount + 1) ~/ 2,
    );
  }
}

class _SecretCaseSeed {
  const _SecretCaseSeed(
    this.id,
    this.titleTr,
    this.titleEn,
    this.locationTr,
    this.locationEn,
    this.incidentTr,
    this.incidentEn,
    this.evidenceTr,
    this.evidenceEn,
    this.saboteurBriefTr,
    this.saboteurBriefEn,
  );

  final String id;
  final String titleTr;
  final String titleEn;
  final String locationTr;
  final String locationEn;
  final String incidentTr;
  final String incidentEn;
  final List<String> evidenceTr;
  final List<String> evidenceEn;
  final String saboteurBriefTr;
  final String saboteurBriefEn;
}
