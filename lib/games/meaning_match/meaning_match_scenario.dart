import 'dart:math' as math;

import '../shared/content_seed.dart';

class MeaningCategory {
  const MeaningCategory({
    required this.id,
    required this.minimumStage,
    required this.titleTr,
    required this.titleEn,
    required this.clueTr,
    required this.clueEn,
    required this.wordsTr,
    required this.wordsEn,
  });

  final String id;
  final int minimumStage;
  final String titleTr;
  final String titleEn;
  final String clueTr;
  final String clueEn;
  final List<String> wordsTr;
  final List<String> wordsEn;

  String title(bool english) => english ? titleEn : titleTr;
  String clue(bool english) => english ? clueEn : clueTr;
  List<String> words(bool english) => english ? wordsEn : wordsTr;
}

class MeaningTile {
  const MeaningTile({
    required this.categoryId,
    required this.word,
    required this.stableId,
  });

  final String categoryId;
  final String word;
  final String stableId;
}

/// A four-way semantic classification board with a guaranteed unique set of
/// category groups. Campaign and practice boards have disjoint signatures.
class MeaningMatchScenario {
  const MeaningMatchScenario({
    required this.stage,
    required this.categories,
    required this.tiles,
    required this.isPractice,
    required this.round,
  });

  static const int campaignLevels = 20;
  static const int uniquePracticeRounds = 300;

  static const List<MeaningCategory> _categoryBank = <MeaningCategory>[
    MeaningCategory(
      id: 'fruits',
      minimumStage: 1,
      titleTr: 'Meyveler',
      titleEn: 'Fruits',
      clueTr: 'Taze ve tatlı meyveler',
      clueEn: 'Sweet and fresh fruits',
      wordsTr: <String>['Elma', 'Armut', 'Çilek', 'Muz'],
      wordsEn: <String>['Apple', 'Pear', 'Strawberry', 'Banana'],
    ),
    MeaningCategory(
      id: 'colors',
      minimumStage: 1,
      titleTr: 'Renkler',
      titleEn: 'Colors',
      clueTr: 'Temel renk tonları',
      clueEn: 'Common primary colors',
      wordsTr: <String>['Kırmızı', 'Mavi', 'Sarı', 'Yeşil'],
      wordsEn: <String>['Red', 'Blue', 'Yellow', 'Green'],
    ),
    MeaningCategory(
      id: 'animals',
      minimumStage: 1,
      titleTr: 'Sevimli hayvanlar',
      titleEn: 'Common animals',
      clueTr: 'Çok iyi bilinen evcil ve sevimli hayvanlar',
      clueEn: 'Well-known friendly animals',
      wordsTr: <String>['Kedi', 'Köpek', 'Tavşan', 'At'],
      wordsEn: <String>['Cat', 'Dog', 'Rabbit', 'Horse'],
    ),
    MeaningCategory(
      id: 'vehicles',
      minimumStage: 1,
      titleTr: 'Ulaşım araçları',
      titleEn: 'Vehicles',
      clueTr: 'Yolculukta kullanılan taşıtlar',
      clueEn: 'Common travel vehicles',
      wordsTr: <String>['Araba', 'Otobüs', 'Tren', 'Uçak'],
      wordsEn: <String>['Car', 'Bus', 'Train', 'Airplane'],
    ),
    MeaningCategory(
      id: 'school_supplies',
      minimumStage: 1,
      titleTr: 'Okul eşyaları',
      titleEn: 'School supplies',
      clueTr: 'Ders ve yazı araç gereçleri',
      clueEn: 'Common stationery items',
      wordsTr: <String>['Kalem', 'Defter', 'Silgi', 'Cetvel'],
      wordsEn: <String>['Pencil', 'Notebook', 'Eraser', 'Ruler'],
    ),
    MeaningCategory(
      id: 'bowed_strings',
      minimumStage: 1,
      titleTr: 'Yaylı çalgılar',
      titleEn: 'Bowed string instruments',
      clueTr: 'Yayla çalınan telli çalgılar',
      clueEn: 'String instruments played with a bow',
      wordsTr: <String>['Keman', 'Viyola', 'Çello', 'Kontrbas'],
      wordsEn: <String>['Violin', 'Viola', 'Cello', 'Double bass'],
    ),
    MeaningCategory(
      id: 'kitchen_tools',
      minimumStage: 1,
      titleTr: 'Mutfak araçları',
      titleEn: 'Kitchen utensils',
      clueTr: 'Hazırlık sırasında kullanılan araçlar',
      clueEn: 'Tools used during food preparation',
      wordsTr: <String>['Çırpıcı', 'Süzgeç', 'Rende', 'Kepçe'],
      wordsEn: <String>['Whisk', 'Strainer', 'Grater', 'Ladle'],
    ),
    MeaningCategory(
      id: 'weather',
      minimumStage: 1,
      titleTr: 'Hava olayları',
      titleEn: 'Weather phenomena',
      clueTr: 'Atmosferde görülen olaylar',
      clueEn: 'Events observed in the atmosphere',
      wordsTr: <String>['Çiseleme', 'Dolu', 'Kırağı', 'Sis'],
      wordsEn: <String>['Drizzle', 'Hail', 'Hoarfrost', 'Fog'],
    ),
    MeaningCategory(
      id: 'birds',
      minimumStage: 1,
      titleTr: 'Kuş türleri',
      titleEn: 'Birds',
      clueTr: 'Dört farklı kuş',
      clueEn: 'Four kinds of bird',
      wordsTr: <String>['Serçe', 'Kırlangıç', 'Martı', 'Baykuş'],
      wordsEn: <String>['Sparrow', 'Swallow', 'Gull', 'Owl'],
    ),
    MeaningCategory(
      id: 'fabrics',
      minimumStage: 1,
      titleTr: 'Kumaş türleri',
      titleEn: 'Fabrics',
      clueTr: 'Dokumada kullanılan kumaşlar',
      clueEn: 'Materials used to make clothing and textiles',
      wordsTr: <String>['Keten', 'Kadife', 'Denim', 'Fitilli kadife'],
      wordsEn: <String>['Linen', 'Velvet', 'Denim', 'Corduroy'],
    ),
    MeaningCategory(
      id: 'cooking_methods',
      minimumStage: 1,
      titleTr: 'Pişirme yöntemleri',
      titleEn: 'Cooking methods',
      clueTr: 'Yiyeceğe uygulanan pişirme biçimleri',
      clueEn: 'Ways of applying heat to food',
      wordsTr: <String>['Haşlama', 'Buğulama', 'Soteleme', 'Fırınlama'],
      wordsEn: <String>['Boiling', 'Steaming', 'Sautéing', 'Roasting'],
    ),
    MeaningCategory(
      id: 'landforms',
      minimumStage: 3,
      titleTr: 'Yeryüzü şekilleri',
      titleEn: 'Landforms',
      clueTr: 'Doğal kara şekilleri',
      clueEn: 'Natural features of the land',
      wordsTr: <String>['Yarımada', 'Delta', 'Kanyon', 'Plato'],
      wordsEn: <String>['Peninsula', 'Delta', 'Canyon', 'Plateau'],
    ),
    MeaningCategory(
      id: 'architecture',
      minimumStage: 3,
      titleTr: 'Mimari elemanlar',
      titleEn: 'Architectural elements',
      clueTr: 'Yapıların taşıyıcı veya örtü elemanları',
      clueEn: 'Structural or covering parts of buildings',
      wordsTr: <String>['Kemer', 'Tonoz', 'Lento', 'Payanda'],
      wordsEn: <String>['Arch', 'Vault', 'Lintel', 'Buttress'],
    ),
    MeaningCategory(
      id: 'watercraft',
      minimumStage: 3,
      titleTr: 'Su taşıtları',
      titleEn: 'Watercraft',
      clueTr: 'Suda ilerlemek için tasarlanmış taşıtlar',
      clueEn: 'Vehicles designed to travel on water',
      wordsTr: <String>['Kayık', 'Kano', 'Katamaran', 'Gondol'],
      wordsEn: <String>['Dinghy', 'Canoe', 'Catamaran', 'Gondola'],
    ),
    MeaningCategory(
      id: 'gems',
      minimumStage: 3,
      titleTr: 'Değerli taşlar',
      titleEn: 'Gemstones',
      clueTr: 'Takı ve süslemede kullanılan taşlar',
      clueEn: 'Stones used in jewellery and ornament',
      wordsTr: <String>['Opal', 'Oniks', 'Yeşim', 'Akik'],
      wordsEn: <String>['Opal', 'Onyx', 'Jade', 'Agate'],
    ),
    MeaningCategory(
      id: 'astronomy',
      minimumStage: 5,
      titleTr: 'Gök cisimleri',
      titleEn: 'Celestial objects',
      clueTr: 'Uzayda bulunan dört farklı oluşum',
      clueEn: 'Four different objects found in space',
      wordsTr: <String>['Kuyruklu yıldız', 'Asteroit', 'Bulutsu', 'Pulsar'],
      wordsEn: <String>['Comet', 'Asteroid', 'Nebula', 'Pulsar'],
    ),
    MeaningCategory(
      id: 'volcanic_rocks',
      minimumStage: 5,
      titleTr: 'Volkanik kayaçlar',
      titleEn: 'Volcanic rocks',
      clueTr: 'Volkanik süreçlerle oluşan kayaçlar',
      clueEn: 'Rocks formed through volcanic processes',
      wordsTr: <String>['Bazalt', 'Obsidyen', 'Pomza', 'Tüf'],
      wordsEn: <String>['Basalt', 'Obsidian', 'Pumice', 'Tuff'],
    ),
    MeaningCategory(
      id: 'navigation_tools',
      minimumStage: 5,
      titleTr: 'Seyir araçları',
      titleEn: 'Navigation instruments',
      clueTr: 'Yön ve konum bulmaya yardım eden araçlar',
      clueEn: 'Instruments used to find direction or position',
      wordsTr: <String>['Sekstant', 'Usturlap', 'Pusula', 'Kronometre'],
      wordsEn: <String>['Sextant', 'Astrolabe', 'Compass', 'Chronometer'],
    ),
    MeaningCategory(
      id: 'theatre_roles',
      minimumStage: 5,
      titleTr: 'Tiyatro görevleri',
      titleEn: 'Theatre roles',
      clueTr: 'Sahne yapımında görev alan uzmanlar',
      clueEn: 'Specialist roles in a theatre production',
      wordsTr: <String>['Dramaturg', 'Suflör', 'Işıkçı', 'Sahne amiri'],
      wordsEn: <String>[
        'Dramaturg',
        'Prompter',
        'Lighting operator',
        'Stage manager',
      ],
    ),
    MeaningCategory(
      id: 'flower_parts',
      minimumStage: 7,
      titleTr: 'Çiçeğin bölümleri',
      titleEn: 'Parts of a flower',
      clueTr: 'Çiçekte bulunan yapılar',
      clueEn: 'Structures found in a flower',
      wordsTr: <String>['Başçık', 'Sapçık', 'Taç yaprak', 'Çanak yaprak'],
      wordsEn: <String>['Anther', 'Filament', 'Petal', 'Sepal'],
    ),
    MeaningCategory(
      id: 'literary_devices',
      minimumStage: 7,
      titleTr: 'Söz sanatları',
      titleEn: 'Figures of speech',
      clueTr: 'Anlatımı etkili kılan söz sanatları',
      clueEn: 'Devices that make expression more vivid',
      wordsTr: <String>['Benzetme', 'Kişileştirme', 'Abartma', 'Mecaz'],
      wordsEn: <String>['Simile', 'Personification', 'Hyperbole', 'Metaphor'],
    ),
    MeaningCategory(
      id: 'mechanisms',
      minimumStage: 7,
      titleTr: 'Mekanik parçalar',
      titleEn: 'Mechanical components',
      clueTr: 'Hareket ileten makine parçaları',
      clueEn: 'Machine parts that transmit or guide motion',
      wordsTr: <String>['Dişli', 'Kam', 'Cırcır', 'Makara'],
      wordsEn: <String>['Cog', 'Cam', 'Ratchet', 'Pulley'],
    ),
    MeaningCategory(
      id: 'archaeology_terms',
      minimumStage: 7,
      titleTr: 'Arkeoloji terimleri',
      titleEn: 'Archaeology terms',
      clueTr: 'Kazı ve eski buluntularla ilgili terimler',
      clueEn: 'Terms used when studying excavations and finds',
      wordsTr: <String>['Tabaka', 'Mutfak çöplüğü', 'Kırık parça', 'Yazıt'],
      wordsEn: <String>['Stratum', 'Midden', 'Shard', 'Inscription'],
    ),
    MeaningCategory(
      id: 'poetry_forms',
      minimumStage: 9,
      titleTr: 'Şiir biçimleri',
      titleEn: 'Poetic forms',
      clueTr: 'Kendine özgü yapısı olan şiir türleri',
      clueEn: 'Poem forms with distinctive structures',
      wordsTr: <String>['Sone', 'Haiku', 'Ağıt', 'Limerik'],
      wordsEn: <String>['Sonnet', 'Haiku', 'Elegy', 'Limerick'],
    ),
    MeaningCategory(
      id: 'textile_stitches',
      minimumStage: 9,
      titleTr: 'Dikiş teknikleri',
      titleEn: 'Stitch techniques',
      clueTr: 'Kumaş üzerinde kullanılan el dikişleri',
      clueEn: 'Hand stitches used on fabric',
      wordsTr: <String>['Teyel', 'Battaniye dikişi', 'Geri dikiş', 'Kanaviçe'],
      wordsEn: <String>[
        'Running stitch',
        'Blanket stitch',
        'Backstitch',
        'Cross-stitch',
      ],
    ),
    MeaningCategory(
      id: 'acoustic_properties',
      minimumStage: 9,
      titleTr: 'Ses nitelikleri',
      titleEn: 'Acoustic properties',
      clueTr: 'Bir sesi tanımlayan akustik özellikler',
      clueEn: 'Acoustic qualities used to describe a sound',
      wordsTr: <String>['Tını', 'Perde', 'Rezonans', 'Üst ses'],
      wordsEn: <String>['Timbre', 'Pitch', 'Resonance', 'Overtone'],
    ),
    MeaningCategory(
      id: 'material_properties',
      minimumStage: 10,
      titleTr: 'Malzeme özellikleri',
      titleEn: 'Material properties',
      clueTr: 'Maddelerin fiziksel davranışını anlatan özellikler',
      clueEn: 'Properties describing how materials behave',
      wordsTr: <String>['Yoğunluk', 'Viskozite', 'Esneklik', 'İletkenlik'],
      wordsEn: <String>['Density', 'Viscosity', 'Elasticity', 'Conductivity'],
    ),
    MeaningCategory(
      id: 'linguistic_units',
      minimumStage: 10,
      titleTr: 'Sözcük yapısı',
      titleEn: 'Word structure',
      clueTr: 'Bir sözcüğün yapısını oluşturan dil birimleri',
      clueEn: 'Linguistic units that form a word',
      wordsTr: <String>['Kök', 'Gövde', 'Önek', 'Sonek'],
      wordsEn: <String>['Root', 'Stem', 'Prefix', 'Suffix'],
    ),
    MeaningCategory(
      id: 'rhetorical_patterns',
      minimumStage: 10,
      titleTr: 'Ses ve tekrar düzenleri',
      titleEn: 'Sound and repetition patterns',
      clueTr: 'Şiir ve söyleyişteki ses/tekrar düzenleri',
      clueEn: 'Sound and repetition patterns in verse and speech',
      wordsTr: <String>['Aliterasyon', 'Asonans', 'Ön yineleme', 'Kafiye'],
      wordsEn: <String>['Alliteration', 'Assonance', 'Anaphora', 'Rhyme'],
    ),
    MeaningCategory(
      id: 'geometric_transformations',
      minimumStage: 10,
      titleTr: 'Geometrik dönüşümler',
      titleEn: 'Geometric transformations',
      clueTr: 'Bir şeklin düzlemde değişmesini sağlayan işlemler',
      clueEn: 'Operations that change a shape on a plane',
      wordsTr: <String>['Öteleme', 'Dönme', 'Yansıma', 'Ölçekleme'],
      wordsEn: <String>['Translation', 'Rotation', 'Reflection', 'Scaling'],
    ),
    MeaningCategory(
      id: 'optical_phenomena',
      minimumStage: 10,
      titleTr: 'Optik olaylar',
      titleEn: 'Optical phenomena',
      clueTr: 'Işığın maddeyle etkileşirken gösterdiği olaylar',
      clueEn: 'Ways light behaves as it interacts with matter',
      wordsTr: <String>['Kırılma', 'Kırınım', 'Ayrışma', 'Kutuplanma'],
      wordsEn: <String>[
        'Refraction',
        'Diffraction',
        'Dispersion',
        'Polarization',
      ],
    ),
    MeaningCategory(
      id: 'logical_connectives',
      minimumStage: 10,
      titleTr: 'Mantıksal bağlaçlar',
      titleEn: 'Logical connectives',
      clueTr: 'Önerme mantığında kullanılan temel bağlaçlar',
      clueEn: 'Basic operators used in propositional logic',
      wordsTr: <String>['Ve', 'Veya', 'Değil', 'İse'],
      wordsEn: <String>['And', 'Or', 'Not', 'If–then'],
    ),
    MeaningCategory(
      id: 'probability_distributions',
      minimumStage: 10,
      titleTr: 'Olasılık dağılımları',
      titleEn: 'Probability distributions',
      clueTr: 'Olası sonuçların olasılıklarını modelleyen dağılımlar',
      clueEn: 'Models that assign probabilities to possible outcomes',
      wordsTr: <String>['Bernoulli', 'Binom', 'Poisson', 'Normal'],
      wordsEn: <String>['Bernoulli', 'Binomial', 'Poisson', 'Normal'],
    ),
    MeaningCategory(
      id: 'musical_intervals',
      minimumStage: 10,
      titleTr: 'Müzik aralıkları',
      titleEn: 'Musical intervals',
      clueTr: 'İki nota arasındaki uzaklık türleri',
      clueEn: 'Types of distance between two notes',
      wordsTr: <String>['Birli', 'Üçlü', 'Beşli', 'Oktav'],
      wordsEn: <String>['Unison', 'Third', 'Fifth', 'Octave'],
    ),
  ];

  static final List<List<int>> _allCombinations = _makeCombinations(
    List<int>.generate(_categoryBank.length, (int index) => index),
  );
  static final List<List<int>> _campaignCombinations = _makeCampaign();
  static final List<List<int>> _practiceCombinations = _makePractice();

  final int stage;
  final List<MeaningCategory> categories;
  final List<MeaningTile> tiles;
  final bool isPractice;
  final int round;

  int get wordsPerCategory =>
      categories.isEmpty ? 4 : tiles.length ~/ categories.length;

  String get groupSignature =>
      (categories.map((MeaningCategory category) => category.id).toList()
            ..sort())
          .join('|');

  String get boardSignature =>
      '$groupSignature#${tiles.map((MeaningTile tile) => tile.stableId).join('|')}';

  static MeaningMatchScenario forCampaignLevel(
    int level, {
    String languageCode = 'tr',
  }) {
    if (level < 1 || level > campaignLevels) {
      throw RangeError.range(level, 1, campaignLevels, 'level');
    }
    return _build(
      categoryIndices: _campaignCombinations[level - 1],
      stage: level,
      round: level,
      isPractice: false,
      languageCode: languageCode,
    );
  }

  static MeaningMatchScenario forPracticeRound(
    int round, {
    String languageCode = 'tr',
  }) {
    if (round < 1 || round > uniquePracticeRounds) {
      throw RangeError.range(round, 1, uniquePracticeRounds, 'round');
    }
    return _build(
      categoryIndices: _practiceCombinations[round - 1],
      stage: ((round - 1) % campaignLevels) + 1,
      round: round,
      isPractice: true,
      languageCode: languageCode,
    );
  }

  static MeaningMatchScenario _build({
    required List<int> categoryIndices,
    required int stage,
    required int round,
    required bool isPractice,
    required String languageCode,
  }) {
    final bool english = languageCode.toLowerCase() != 'tr';
    // Başlangıç bölümleri (Bölüm 1 - 3): 3'erli 3 grup (3 kategori, 3'er kelime)
    final bool isIntroLevel = !isPractice && stage <= 3;
    final int categoryCount = isIntroLevel ? 3 : 4;
    final int wordsPerCategory = isIntroLevel ? 3 : 4;

    final List<MeaningCategory> selected = categoryIndices
        .take(categoryCount)
        .map((int index) => _categoryBank[index])
        .toList(growable: false);
    final List<MeaningTile> tiles = <MeaningTile>[];
    for (final MeaningCategory category in selected) {
      final List<String> words =
          category.words(english).take(wordsPerCategory).toList();
      for (int index = 0; index < words.length; index++) {
        tiles.add(
          MeaningTile(
            categoryId: category.id,
            word: words[index],
            stableId: '${category.id}:$index',
          ),
        );
      }
    }
    tiles.shuffle(
      ContentSeed.randomFor(
        gameId: 'meaning_match:${isPractice ? 'practice' : 'campaign'}',
        level: round,
      ),
    );
    return MeaningMatchScenario(
      stage: stage,
      categories: List<MeaningCategory>.unmodifiable(selected),
      tiles: List<MeaningTile>.unmodifiable(tiles),
      isPractice: isPractice,
      round: round,
    );
  }

  static List<List<int>> _makeCampaign() {
    const List<int> maximumTierByLevel = <int>[
      1,
      1,
      1,
      3,
      3,
      3,
      5,
      5,
      5,
      7,
      7,
      7,
      9,
      9,
      9,
      10,
      10,
      10,
      10,
      10,
    ];
    final List<List<int>> chosen = <List<int>>[];
    final Set<String> used = <String>{};
    for (int level = 1; level <= campaignLevels; level++) {
      final int tier = maximumTierByLevel[level - 1];
      final List<int> eligible =
          List<int>.generate(_categoryBank.length, (int i) => i)
              .where((int index) => _categoryBank[index].minimumStage <= tier)
              .toList(growable: false);
      final List<List<int>> options = _makeCombinations(eligible)
          .where(
            (List<int> combination) => combination.any(
              (int index) => _categoryBank[index].minimumStage == tier,
            ),
          )
          .where((List<int> combination) {
            final int requiredTopTierGroups = level <= 3
                ? level
                : level <= 6
                ? level - 3
                : level <= 9
                ? level - 6
                : level <= 12
                ? level - 9
                : level <= 15
                ? level - 12
                : (level - 15).clamp(1, 4);
            final int topTierGroups = combination
                .where((int index) => _categoryBank[index].minimumStage == tier)
                .length;
            return topTierGroups >= requiredTopTierGroups;
          })
          .toList(growable: false);
      if (options.isEmpty) {
        throw StateError('No campaign board for level $level.');
      }
      final math.Random random = ContentSeed.randomFor(
        gameId: 'meaning_match:campaign',
        level: level,
      );
      int start = random.nextInt(options.length);
      List<int>? selected;
      for (int attempt = 0; attempt < options.length; attempt++) {
        final List<int> candidate = options[(start + attempt) % options.length];
        final String signature = _groupKey(candidate);
        if (!used.contains(signature)) {
          selected = candidate;
          used.add(signature);
          break;
        }
      }
      if (selected == null) {
        throw StateError('Campaign board repeated at $level.');
      }
      chosen.add(List<int>.unmodifiable(selected));
    }
    return List<List<int>>.unmodifiable(chosen);
  }

  static List<List<int>> _makePractice() {
    final Set<String> campaignKeys = _campaignCombinations
        .map(_groupKey)
        .toSet();
    final List<List<int>> candidates = _allCombinations
        .where(
          (List<int> combination) =>
              !campaignKeys.contains(_groupKey(combination)),
        )
        .map(List<int>.unmodifiable)
        .toList(growable: true);
    candidates.shuffle(
      ContentSeed.randomFor(gameId: 'meaning_match:practice-order', level: 1),
    );
    if (candidates.length < uniquePracticeRounds) {
      throw StateError('Not enough unique practice boards.');
    }
    return List<List<int>>.unmodifiable(candidates.take(uniquePracticeRounds));
  }

  static List<List<int>> _makeCombinations(List<int> source) {
    final List<List<int>> result = <List<int>>[];
    for (int a = 0; a < source.length - 3; a++) {
      for (int b = a + 1; b < source.length - 2; b++) {
        for (int c = b + 1; c < source.length - 1; c++) {
          for (int d = c + 1; d < source.length; d++) {
            result.add(<int>[source[a], source[b], source[c], source[d]]);
          }
        }
      }
    }
    return result;
  }

  static String _groupKey(List<int> indices) {
    final List<String> ids =
        indices.map((int index) => _categoryBank[index].id).toList()..sort();
    return ids.join('|');
  }
}
