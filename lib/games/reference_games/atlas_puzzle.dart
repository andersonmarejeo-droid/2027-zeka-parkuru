import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

class AtlasFeature {
  const AtlasFeature({
    required this.code,
    required this.center,
    required this.rings,
  });

  final String code;
  final List<double> center;
  final List<List<List<double>>> rings;

  factory AtlasFeature.fromJson(Map<String, Object?> json) {
    final List<List<List<double>>> rings = <List<List<double>>>[];
    for (final Object? rawRing
        in (json['rings'] as List<Object?>? ?? const <Object?>[])) {
      final List<List<double>> ring = <List<double>>[];
      for (final Object? rawPoint in rawRing as List<Object?>) {
        final List<Object?> point = rawPoint as List<Object?>;
        ring.add(<double>[
          (point[0] as num).toDouble(),
          (point[1] as num).toDouble(),
        ]);
      }
      if (ring.length >= 4) rings.add(ring);
    }
    final List<double> center = json['center'] is List<Object?>
        ? (json['center'] as List<Object?>)
              .map((Object? n) => (n as num).toDouble())
              .toList()
        : _fallbackCenter(rings);
    return AtlasFeature(
      code: json['code']! as String,
      center: center,
      rings: rings,
    );
  }

  static List<double> _fallbackCenter(List<List<List<double>>> rings) {
    if (rings.isEmpty || rings.first.isEmpty) return const <double>[0, 0];
    final List<List<double>> ring = rings.reduce(
      (List<List<double>> a, List<List<double>> b) =>
          a.length >= b.length ? a : b,
    );
    double x = 0, y = 0;
    for (final List<double> point in ring) {
      x += point[0];
      y += point[1];
    }
    return <double>[x / ring.length, y / ring.length];
  }
}

enum AtlasKind { turkey, world }

class AtlasCulturalHint {
  const AtlasCulturalHint({required this.specialty, required this.landmark});

  final String specialty;
  final String landmark;
}

abstract final class AtlasScorePolicy {
  // Atlas is intentionally the exception to the global hint reduction. Its
  // six-step geography clue ladder is part of the game's identity: region →
  // position → cultural clue → detail → name structure → first/last letter.
  static const int maxHintsPerQuestion = 6;
  static const int fullAnswerPoints = 100;
  static const int pointsLostPerHint = 15;
  static const int minimumAnswerPoints = 10;

  static int pointsForHints(int hintsUsed) {
    final int safeHints = hintsUsed.clamp(0, maxHintsPerQuestion).toInt();
    return (fullAnswerPoints - safeHints * pointsLostPerHint)
        .clamp(minimumAnswerPoints, fullAnswerPoints)
        .toInt();
  }
}

abstract final class AtlasDataset {
  static final Map<AtlasKind, Future<List<AtlasFeature>>> _datasets = {};
  static final Map<AtlasKind, List<AtlasFeature>> _features = {};

  static List<AtlasFeature>? cached(AtlasKind kind) => _features[kind];

  // Hubs, card previews and play screens share one decoded map in memory.
  static Future<List<AtlasFeature>> load(AtlasKind kind) =>
      _datasets.putIfAbsent(kind, () => _read(kind));

  static Future<List<AtlasFeature>> _read(AtlasKind kind) async {
    final String path = kind == AtlasKind.turkey
        ? 'assets/maps/turkey_provinces.json'
        : 'assets/maps/world_countries.json';
    final String source = await rootBundle.loadString(path);
    final Map<String, Object?> decoded =
        jsonDecode(source) as Map<String, Object?>;
    final features = (decoded['features']! as List<Object?>)
        .cast<Map<String, Object?>>()
        .map(AtlasFeature.fromJson)
        .toList(growable: false);
    _features[kind] = List<AtlasFeature>.unmodifiable(features);
    return _features[kind]!;
  }

  static const List<String> provinces = <String>[
    'Adana',
    'Adıyaman',
    'Afyonkarahisar',
    'Ağrı',
    'Amasya',
    'Ankara',
    'Antalya',
    'Artvin',
    'Aydın',
    'Balıkesir',
    'Bilecik',
    'Bingöl',
    'Bitlis',
    'Bolu',
    'Burdur',
    'Bursa',
    'Çanakkale',
    'Çankırı',
    'Çorum',
    'Denizli',
    'Diyarbakır',
    'Edirne',
    'Elazığ',
    'Erzincan',
    'Erzurum',
    'Eskişehir',
    'Gaziantep',
    'Giresun',
    'Gümüşhane',
    'Hakkâri',
    'Hatay',
    'Isparta',
    'Mersin',
    'İstanbul',
    'İzmir',
    'Kars',
    'Kastamonu',
    'Kayseri',
    'Kırklareli',
    'Kırşehir',
    'Kocaeli',
    'Konya',
    'Kütahya',
    'Malatya',
    'Manisa',
    'Kahramanmaraş',
    'Mardin',
    'Muğla',
    'Muş',
    'Nevşehir',
    'Niğde',
    'Ordu',
    'Rize',
    'Sakarya',
    'Samsun',
    'Siirt',
    'Sinop',
    'Sivas',
    'Tekirdağ',
    'Tokat',
    'Trabzon',
    'Tunceli',
    'Şanlıurfa',
    'Uşak',
    'Van',
    'Yozgat',
    'Zonguldak',
    'Aksaray',
    'Bayburt',
    'Karaman',
    'Kırıkkale',
    'Batman',
    'Şırnak',
    'Bartın',
    'Ardahan',
    'Iğdır',
    'Yalova',
    'Karabük',
    'Kilis',
    'Osmaniye',
    'Düzce',
  ];

  static const Map<String, String> countries = <String, String>{
    'AFG': 'Afganistan',
    'ARG': 'Arjantin',
    'AUS': 'Avustralya',
    'AUT': 'Avusturya',
    'AZE': 'Azerbaycan',
    'BRA': 'Brezilya',
    'CAN': 'Kanada',
    'CHL': 'Şili',
    'CHN': 'Çin',
    'COL': 'Kolombiya',
    'CUB': 'Küba',
    'CZE': 'Çekya',
    'DEU': 'Almanya',
    'EGY': 'Mısır',
    'FIN': 'Finlandiya',
    'FRA': 'Fransa',
    'GRC': 'Yunanistan',
    'ISL': 'İzlanda',
    'IND': 'Hindistan',
    'IDN': 'Endonezya',
    'IRN': 'İran',
    'IRQ': 'Irak',
    'ITA': 'İtalya',
    'JPN': 'Japonya',
    'KAZ': 'Kazakistan',
    'KEN': 'Kenya',
    'MYS': 'Malezya',
    'MEX': 'Meksika',
    'MNG': 'Moğolistan',
    'MAR': 'Fas',
    'NPL': 'Nepal',
    'NZL': 'Yeni Zelanda',
    'NGA': 'Nijerya',
    'NOR': 'Norveç',
    'PAK': 'Pakistan',
    'PER': 'Peru',
    'PHL': 'Filipinler',
    'POL': 'Polonya',
    'RUS': 'Rusya',
    'SAU': 'Suudi Arabistan',
    'ZAF': 'Güney Afrika',
    'KOR': 'Güney Kore',
    'ESP': 'İspanya',
    'SWE': 'İsveç',
    'CHE': 'İsviçre',
    'THA': 'Tayland',
    'TUR': 'Türkiye',
    'UKR': 'Ukrayna',
    'GBR': 'Birleşik Krallık',
    'USA': 'Amerika Birleşik Devletleri',
    'VNM': 'Vietnam',
  };

  static const Map<String, String> countriesEn = <String, String>{
    'AFG': 'Afghanistan',
    'ARG': 'Argentina',
    'AUS': 'Australia',
    'AUT': 'Austria',
    'AZE': 'Azerbaijan',
    'BRA': 'Brazil',
    'CAN': 'Canada',
    'CHL': 'Chile',
    'CHN': 'China',
    'COL': 'Colombia',
    'CUB': 'Cuba',
    'CZE': 'Czechia',
    'DEU': 'Germany',
    'EGY': 'Egypt',
    'FIN': 'Finland',
    'FRA': 'France',
    'GRC': 'Greece',
    'ISL': 'Iceland',
    'IND': 'India',
    'IDN': 'Indonesia',
    'IRN': 'Iran',
    'IRQ': 'Iraq',
    'ITA': 'Italy',
    'JPN': 'Japan',
    'KAZ': 'Kazakhstan',
    'KEN': 'Kenya',
    'MYS': 'Malaysia',
    'MEX': 'Mexico',
    'MNG': 'Mongolia',
    'MAR': 'Morocco',
    'NPL': 'Nepal',
    'NZL': 'New Zealand',
    'NGA': 'Nigeria',
    'NOR': 'Norway',
    'PAK': 'Pakistan',
    'PER': 'Peru',
    'PHL': 'Philippines',
    'POL': 'Poland',
    'RUS': 'Russia',
    'SAU': 'Saudi Arabia',
    'ZAF': 'South Africa',
    'KOR': 'South Korea',
    'ESP': 'Spain',
    'SWE': 'Sweden',
    'CHE': 'Switzerland',
    'THA': 'Thailand',
    'TUR': 'Turkey',
    'UKR': 'Ukraine',
    'GBR': 'United Kingdom',
    'USA': 'United States',
    'VNM': 'Vietnam',
  };

  static const Map<String, List<String>> _provinceCodesByRegion =
      <String, List<String>>{
        'Marmara': <String>[
          '10',
          '11',
          '16',
          '17',
          '22',
          '34',
          '39',
          '41',
          '54',
          '59',
          '77',
        ],
        'Ege': <String>['03', '09', '20', '35', '43', '45', '48', '64'],
        'Akdeniz': <String>[
          '01',
          '07',
          '15',
          '31',
          '32',
          '33',
          '46',
          '79',
          '80',
        ],
        'İç Anadolu': <String>[
          '06',
          '18',
          '26',
          '38',
          '40',
          '42',
          '50',
          '51',
          '58',
          '66',
          '68',
          '70',
          '71',
        ],
        'Karadeniz': <String>[
          '05',
          '08',
          '14',
          '19',
          '28',
          '29',
          '37',
          '52',
          '53',
          '55',
          '57',
          '60',
          '61',
          '67',
          '69',
          '74',
          '78',
          '81',
        ],
        'Doğu Anadolu': <String>[
          '04',
          '12',
          '13',
          '23',
          '24',
          '25',
          '30',
          '36',
          '44',
          '49',
          '62',
          '65',
          '75',
          '76',
        ],
        'Güneydoğu Anadolu': <String>[
          '02',
          '21',
          '27',
          '47',
          '56',
          '63',
          '72',
          '73',
        ],
      };

  static const Map<String, String> _regionNamesEn = <String, String>{
    'Marmara': 'Marmara',
    'Ege': 'Aegean',
    'Akdeniz': 'Mediterranean',
    'İç Anadolu': 'Central Anatolia',
    'Karadeniz': 'Black Sea',
    'Doğu Anadolu': 'Eastern Anatolia',
    'Güneydoğu Anadolu': 'Southeastern Anatolia',
  };

  static const Map<String, List<String>> _countryCodesByArea =
      <String, List<String>>{
        'Africa': <String>['EGY', 'KEN', 'MAR', 'NGA', 'ZAF'],
        'Asia': <String>[
          'AFG',
          'CHN',
          'IND',
          'IDN',
          'IRN',
          'IRQ',
          'JPN',
          'MYS',
          'MNG',
          'NPL',
          'PAK',
          'PHL',
          'SAU',
          'KOR',
          'THA',
          'VNM',
        ],
        'Europe': <String>[
          'AUT',
          'CZE',
          'DEU',
          'FIN',
          'FRA',
          'GRC',
          'ISL',
          'ITA',
          'NOR',
          'POL',
          'SWE',
          'CHE',
          'ESP',
          'UKR',
          'GBR',
        ],
        'North America': <String>['CAN', 'CUB', 'MEX', 'USA'],
        'South America': <String>['ARG', 'BRA', 'CHL', 'COL', 'PER'],
        'Oceania': <String>['AUS', 'NZL'],
        'Europe and Asia': <String>['AZE', 'KAZ', 'RUS', 'TUR'],
      };

  static const Map<String, String> _countryAreasTr = <String, String>{
    'Africa': 'Afrika',
    'Asia': 'Asya',
    'Europe': 'Avrupa',
    'North America': 'Kuzey Amerika',
    'South America': 'Güney Amerika',
    'Oceania': 'Okyanusya',
    'Europe and Asia': 'Avrupa ile Asya’nın kesişimi',
  };

  // Cultural clues are deliberately kept separate from geography clues. The
  // player gets a recognizable dish or local specialty first, followed by a
  // landmark or cultural detail; neither clue exposes the answer directly.
  static const Map<String, AtlasCulturalHint> _culturalHints =
      <String, AtlasCulturalHint>{
        'TR-01': AtlasCulturalHint(
          specialty: 'acı kıymalı kebap',
          landmark: 'Seyhan Nehri ve Taşköprü',
        ),
        'TR-02': AtlasCulturalHint(
          specialty: 'Nemrut Dağı gün doğumu manzarası',
          landmark: 'Kommagene kral heykelleri',
        ),
        'TR-03': AtlasCulturalHint(
          specialty: 'kaymaklı ekmek kadayıfı ve sucuk',
          landmark: 'Frig Vadisi kaya anıtları',
        ),
        'TR-04': AtlasCulturalHint(
          specialty: 'Türkiye’nin en yüksek dağı',
          landmark: 'İshak Paşa Sarayı',
        ),
        'TR-05': AtlasCulturalHint(
          specialty: 'şekerpare elması',
          landmark: 'Kral Kaya Mezarları',
        ),
        'TR-06': AtlasCulturalHint(
          specialty: 'sac kavurma',
          landmark: 'Anıtkabir',
        ),
        'TR-07': AtlasCulturalHint(
          specialty: 'tahinli piyaz',
          landmark: 'Düden Şelalesi',
        ),
        'TR-08': AtlasCulturalHint(
          specialty: 'kuymak ve yöresel bal',
          landmark: 'Kaçkar Dağları',
        ),
        'TR-09': AtlasCulturalHint(
          specialty: 'kuru incir',
          landmark: 'Efes Antik Kenti',
        ),
        'TR-10': AtlasCulturalHint(
          specialty: 'höşmerim tatlısı',
          landmark: 'Kazdağları',
        ),
        'TR-11': AtlasCulturalHint(
          specialty: 'üzüm pekmezi',
          landmark: 'Şeyh Edebali Türbesi',
        ),
        'TR-12': AtlasCulturalHint(
          specialty: 'çiçek balı',
          landmark: 'Yüzen Ada',
        ),
        'TR-13': AtlasCulturalHint(
          specialty: 'büryan kebabı',
          landmark: 'Ahlat Selçuklu mezar taşları',
        ),
        'TR-14': AtlasCulturalHint(
          specialty: 'patatesli ekmek',
          landmark: 'Abant Gölü',
        ),
        'TR-15': AtlasCulturalHint(
          specialty: 'ceviz ezmesi',
          landmark: 'Salda Gölü',
        ),
        'TR-16': AtlasCulturalHint(
          specialty: 'İskender kebabı',
          landmark: 'Uludağ',
        ),
        'TR-17': AtlasCulturalHint(
          specialty: 'peynir helvası',
          landmark: 'Troya Antik Kenti',
        ),
        'TR-18': AtlasCulturalHint(
          specialty: 'kaya tuzu',
          landmark: 'Ilgaz Dağları',
        ),
        'TR-19': AtlasCulturalHint(
          specialty: 'leblebi',
          landmark: 'Hattuşa Antik Kenti',
        ),
        'TR-20': AtlasCulturalHint(
          specialty: 'kuzu kebabı',
          landmark: 'Pamukkale travertenleri',
        ),
        'TR-21': AtlasCulturalHint(
          specialty: 'burma kadayıf',
          landmark: 'surlarıyla çevrili tarihi şehir',
        ),
        'TR-22': AtlasCulturalHint(
          specialty: 'tava ciğeri',
          landmark: 'Selimiye Camii',
        ),
        'TR-23': AtlasCulturalHint(
          specialty: 'Harput köftesi',
          landmark: 'Harput Kalesi',
        ),
        'TR-24': AtlasCulturalHint(
          specialty: 'tulum peyniri',
          landmark: 'Girlevik Şelalesi',
        ),
        'TR-25': AtlasCulturalHint(
          specialty: 'cağ kebabı',
          landmark: 'Palandöken Dağları',
        ),
        'TR-26': AtlasCulturalHint(
          specialty: 'çiğ börek',
          landmark: 'Odunpazarı evleri',
        ),
        'TR-27': AtlasCulturalHint(
          specialty: 'Antep baklavası',
          landmark: 'Zeugma Mozaik Müzesi',
        ),
        'TR-28': AtlasCulturalHint(
          specialty: 'Karadeniz fındığı',
          landmark: 'Kümbet Yaylası ve mavi göller',
        ),
        'TR-29': AtlasCulturalHint(
          specialty: 'pestil ve köme',
          landmark: 'Karaca Mağarası',
        ),
        'TR-30': AtlasCulturalHint(
          specialty: 'yöresel bal ve otlu peynir',
          landmark: 'Sümbül Dağı',
        ),
        'TR-31': AtlasCulturalHint(
          specialty: 'künefe',
          landmark: 'Titus Tüneli',
        ),
        'TR-32': AtlasCulturalHint(
          specialty: 'gül lokumu ve gül ürünleri',
          landmark: 'Eğirdir Gölü ve lavanta tarlaları',
        ),
        'TR-33': AtlasCulturalHint(
          specialty: 'tantuni',
          landmark: 'Kızkalesi',
        ),
        'TR-34': AtlasCulturalHint(
          specialty: 'simit ve balık ekmek',
          landmark: 'Boğaziçi ve tarihi yarımada',
        ),
        'TR-35': AtlasCulturalHint(
          specialty: 'boyoz',
          landmark: 'tarihi Saat Kulesi',
        ),
        'TR-36': AtlasCulturalHint(
          specialty: 'kaz eti',
          landmark: 'Ani Harabeleri',
        ),
        'TR-37': AtlasCulturalHint(
          specialty: 'çekme helva',
          landmark: 'Ilgaz Dağı ve ahşap konaklar',
        ),
        'TR-38': AtlasCulturalHint(
          specialty: 'mantı',
          landmark: 'Erciyes Dağı',
        ),
        'TR-39': AtlasCulturalHint(
          specialty: 'hardaliye',
          landmark: 'İğneada longozları',
        ),
        'TR-40': AtlasCulturalHint(
          specialty: 'çömlek yemekleri',
          landmark: 'Cacabey Medresesi',
        ),
        'TR-41': AtlasCulturalHint(
          specialty: 'İzmit pişmaniyesi',
          landmark: 'Kartepe',
        ),
        'TR-42': AtlasCulturalHint(
          specialty: 'etli ekmek',
          landmark: 'Mevlana Müzesi',
        ),
        'TR-43': AtlasCulturalHint(
          specialty: 'cimcik hamuru',
          landmark: 'çini sanatı',
        ),
        'TR-44': AtlasCulturalHint(
          specialty: 'kayısı',
          landmark: 'Aslantepe Höyüğü',
        ),
        'TR-45': AtlasCulturalHint(
          specialty: 'mesir macunu',
          landmark: 'Sardes Antik Kenti',
        ),
        'TR-46': AtlasCulturalHint(
          specialty: 'Maraş dondurması',
          landmark: 'Başkonuş Yaylası',
        ),
        'TR-47': AtlasCulturalHint(
          specialty: 'kibe dolması',
          landmark: 'taş evleri',
        ),
        'TR-48': AtlasCulturalHint(
          specialty: 'Milas köftesi',
          landmark: 'Bodrum Kalesi',
        ),
        'TR-49': AtlasCulturalHint(
          specialty: 'yöresel köfte',
          landmark: 'Malazgirt Ovası',
        ),
        'TR-50': AtlasCulturalHint(
          specialty: 'testi kebabı',
          landmark: 'Kapadokya balonları',
        ),
        'TR-51': AtlasCulturalHint(
          specialty: 'fırın tava',
          landmark: 'Aladağlar',
        ),
        'TR-52': AtlasCulturalHint(
          specialty: 'fındık',
          landmark: 'Boztepe',
        ),
        'TR-53': AtlasCulturalHint(
          specialty: 'mıhlama ve çay',
          landmark: 'çay bahçeleri',
        ),
        'TR-54': AtlasCulturalHint(
          specialty: 'ıslama köfte',
          landmark: 'Sapanca Gölü',
        ),
        'TR-55': AtlasCulturalHint(
          specialty: 'Karadeniz pidesi',
          landmark: 'Bandırma Vapuru',
        ),
        'TR-56': AtlasCulturalHint(
          specialty: 'büryan kebabı',
          landmark: 'Tillo',
        ),
        'TR-57': AtlasCulturalHint(
          specialty: 'nokul',
          landmark: 'tarihi cezaevi',
        ),
        'TR-58': AtlasCulturalHint(
          specialty: 'köfte',
          landmark: 'Divriği Ulu Camii',
        ),
        'TR-59': AtlasCulturalHint(
          specialty: 'köfte',
          landmark: 'Rákóczi Müzesi',
        ),
        'TR-60': AtlasCulturalHint(
          specialty: 'sebzeli kebap',
          landmark: 'Ballıca Mağarası',
        ),
        'TR-61': AtlasCulturalHint(
          specialty: 'kuymak',
          landmark: 'Sümela Manastırı',
        ),
        'TR-62': AtlasCulturalHint(
          specialty: 'ceviz ve yöresel bal',
          landmark: 'Munzur Vadisi',
        ),
        'TR-63': AtlasCulturalHint(
          specialty: 'çiğ köfte',
          landmark: 'Balıklıgöl',
        ),
        'TR-64': AtlasCulturalHint(
          specialty: 'tarhana',
          landmark: 'Ulubey Kanyonları',
        ),
        'TR-65': AtlasCulturalHint(
          specialty: 'otlu peynir',
          landmark: 'Akdamar Adası ve taş kilise',
        ),
        'TR-66': AtlasCulturalHint(
          specialty: 'arabaşı',
          landmark: 'Çapanoğlu Camii',
        ),
        'TR-67': AtlasCulturalHint(
          specialty: 'mancar yemeği',
          landmark: 'maden ocakları ve sahil kıyısı',
        ),
        'TR-68': AtlasCulturalHint(
          specialty: 'soğanlama',
          landmark: 'Ihlara Vadisi',
        ),
        'TR-69': AtlasCulturalHint(
          specialty: 'lor dolması',
          landmark: 'tarihi kale',
        ),
        'TR-70': AtlasCulturalHint(
          specialty: 'calla yemeği',
          landmark: 'Taşkale tahıl ambarları',
        ),
        'TR-71': AtlasCulturalHint(
          specialty: 'keskek',
          landmark: 'Çeşnigir Köprüsü',
        ),
        'TR-72': AtlasCulturalHint(
          specialty: 'şambörek',
          landmark: 'Hasankeyf',
        ),
        'TR-73': AtlasCulturalHint(
          specialty: 'perde pilavı',
          landmark: 'Cudi Dağı',
        ),
        'TR-74': AtlasCulturalHint(
          specialty: 'pumpum çorbası',
          landmark: 'Amasra',
        ),
        'TR-75': AtlasCulturalHint(
          specialty: 'kaşar peyniri',
          landmark: 'Çıldır Gölü',
        ),
        'TR-76': AtlasCulturalHint(
          specialty: 'bozbaş',
          landmark: 'Tuzluca tuz mağaraları',
        ),
        'TR-77': AtlasCulturalHint(
          specialty: 'sütlü tatlı',
          landmark: 'Termal kaplıcaları',
        ),
        'TR-78': AtlasCulturalHint(
          specialty: 'Safranbolu lokumu',
          landmark: 'Safranbolu evleri',
        ),
        'TR-79': AtlasCulturalHint(
          specialty: 'katmer',
          landmark: 'Ravanda Kalesi ve üzüm bağları',
        ),
        'TR-80': AtlasCulturalHint(
          specialty: 'yer fıstığı',
          landmark: 'Karatepe-Aslantaş',
        ),
        'TR-81': AtlasCulturalHint(
          specialty: 'melengücceği tatlısı',
          landmark: 'Akçakoca sahili',
        ),
        'AFG': AtlasCulturalHint(
          specialty: 'mantu',
          landmark: 'Bamiyan heykelleri',
        ),
        'ARG': AtlasCulturalHint(
          specialty: 'asado',
          landmark: 'Iguazú Şelaleleri',
        ),
        'AUS': AtlasCulturalHint(
          specialty: 'meat pie',
          landmark: 'Büyük Set Resifi',
        ),
        'AUT': AtlasCulturalHint(
          specialty: 'Wiener schnitzel',
          landmark: 'Alpler',
        ),
        'AZE': AtlasCulturalHint(
          specialty: 'pilav',
          landmark: 'Bakü İçerişehir',
        ),
        'BRA': AtlasCulturalHint(
          specialty: 'feijoada',
          landmark: 'Amazon yağmur ormanları',
        ),
        'CAN': AtlasCulturalHint(
          specialty: 'akçaağaç şurubu',
          landmark: 'Niagara Şelalesi',
        ),
        'CHL': AtlasCulturalHint(
          specialty: 'empanada',
          landmark: 'Atacama Çölü',
        ),
        'CHN': AtlasCulturalHint(
          specialty: 'Pekin ördeği',
          landmark: 'Terracotta Ordusu ve İpek Yolu',
        ),
        'COL': AtlasCulturalHint(
          specialty: 'yüksek rakım kahvesi',
          landmark: 'Cartagena surları',
        ),
        'CUB': AtlasCulturalHint(
          specialty: 'ropa vieja',
          landmark: 'Eski Havana',
        ),
        'CZE': AtlasCulturalHint(
          specialty: 'trdelník',
          landmark: 'Prag Kalesi',
        ),
        'DEU': AtlasCulturalHint(
          specialty: 'sosis ve pretzel',
          landmark: 'Brandenburg Kapısı',
        ),
        'EGY': AtlasCulturalHint(
          specialty: 'koshari',
          landmark: 'Gize piramitleri',
        ),
        'FIN': AtlasCulturalHint(
          specialty: 'somon çorbası',
          landmark: 'Kuzey ışıkları',
        ),
        'FRA': AtlasCulturalHint(
          specialty: 'kruvasan',
          landmark: 'Eyfel Kulesi',
        ),
        'GRC': AtlasCulturalHint(
          specialty: 'musakka',
          landmark: 'Akropolis',
        ),
        'ISL': AtlasCulturalHint(
          specialty: 'skyr',
          landmark: 'Mavi Lagün',
        ),
        'IND': AtlasCulturalHint(
          specialty: 'köri yemekleri',
          landmark: 'Tac Mahal',
        ),
        'IDN': AtlasCulturalHint(
          specialty: 'nasi goreng',
          landmark: 'Bali adası',
        ),
        'IRN': AtlasCulturalHint(
          specialty: 'safranlı pilav',
          landmark: 'Persepolis',
        ),
        'IRQ': AtlasCulturalHint(
          specialty: 'masgouf',
          landmark: 'Babil kalıntıları',
        ),
        'ITA': AtlasCulturalHint(
          specialty: 'pizza',
          landmark: 'Kolezyum',
        ),
        'JPN': AtlasCulturalHint(
          specialty: 'suşi',
          landmark: 'Fuji Dağı',
        ),
        'KAZ': AtlasCulturalHint(
          specialty: 'beşparmak',
          landmark: 'Çarın Kanyonu',
        ),
        'KEN': AtlasCulturalHint(
          specialty: 'ugali',
          landmark: 'Masai Mara',
        ),
        'MYS': AtlasCulturalHint(
          specialty: 'nasi lemak',
          landmark: 'Petronas Kuleleri',
        ),
        'MEX': AtlasCulturalHint(
          specialty: 'tako',
          landmark: 'Chichén Itzá',
        ),
        'MNG': AtlasCulturalHint(
          specialty: 'buuz',
          landmark: 'Gobi Çölü',
        ),
        'MAR': AtlasCulturalHint(
          specialty: 'kuskus',
          landmark: 'Marakeş çarşıları',
        ),
        'NPL': AtlasCulturalHint(
          specialty: 'momo',
          landmark: 'Everest',
        ),
        'NZL': AtlasCulturalHint(
          specialty: 'pavlova',
          landmark: 'Milford Sound',
        ),
        'NGA': AtlasCulturalHint(
          specialty: 'jollof pilavı',
          landmark: 'Zuma Kayası',
        ),
        'NOR': AtlasCulturalHint(
          specialty: 'somon',
          landmark: 'Geiranger fiyordu ve kuzey ışıkları',
        ),
        'PAK': AtlasCulturalHint(
          specialty: 'biryani',
          landmark: 'Badşahi Camii',
        ),
        'PER': AtlasCulturalHint(
          specialty: 'ceviche',
          landmark: 'Machu Picchu',
        ),
        'PHL': AtlasCulturalHint(
          specialty: 'adobo',
          landmark: 'Banaue pirinç terasları',
        ),
        'POL': AtlasCulturalHint(
          specialty: 'pierogi',
          landmark: 'Wawel Kalesi',
        ),
        'RUS': AtlasCulturalHint(
          specialty: 'pelmeni',
          landmark: 'Kremlin',
        ),
        'SAU': AtlasCulturalHint(
          specialty: 'kabsa',
          landmark: 'El-Ula kayalıkları',
        ),
        'ZAF': AtlasCulturalHint(
          specialty: 'bobotie',
          landmark: 'Masa Dağı',
        ),
        'KOR': AtlasCulturalHint(
          specialty: 'kimchi',
          landmark: 'Gyeongbokgung Sarayı',
        ),
        'ESP': AtlasCulturalHint(
          specialty: 'paella',
          landmark: 'Sagrada Família',
        ),
        'SWE': AtlasCulturalHint(
          specialty: 'tarçınlı çörek',
          landmark: 'Vasa Müzesi ve kuzey takımadaları',
        ),
        'CHE': AtlasCulturalHint(
          specialty: 'peynir fondüsü',
          landmark: 'Matterhorn',
        ),
        'THA': AtlasCulturalHint(
          specialty: 'pad thai',
          landmark: 'Büyük Saray',
        ),
        'TUR': AtlasCulturalHint(
          specialty: 'baklava',
          landmark: 'Kapadokya',
        ),
        'UKR': AtlasCulturalHint(
          specialty: 'varenyky',
          landmark: 'Aziz Sofya Katedrali',
        ),
        'GBR': AtlasCulturalHint(
          specialty: 'fish and chips',
          landmark: 'Big Ben',
        ),
        'USA': AtlasCulturalHint(
          specialty: 'barbekü',
          landmark: 'Özgürlük Heykeli',
        ),
        'VNM': AtlasCulturalHint(
          specialty: 'pho',
          landmark: 'Ha Long Körfezi',
        ),
      };

  static String areaClue(AtlasKind kind, String code, {bool english = false}) {
    if (kind == AtlasKind.turkey) {
      final String suffix = code.startsWith('TR-') ? code.substring(3) : '';
      final String? region = _provinceRegion(suffix);
      if (region == null) {
        return english
            ? 'This place is somewhere in Türkiye.'
            : 'Bu şehir Türkiye sınırları içindedir.';
      }
      return english
          ? 'This province is in the ${_regionNamesEn[region]} region of Türkiye.'
          : 'Bu il, Türkiye’nin $region Bölgesi’ndedir.';
    }

    final String? area = _countryArea(code);
    if (area == null) {
      return english
          ? 'This country is somewhere on the world map.'
          : 'Bu ülke dünya haritasında yer alır.';
    }
    final String areaName = english ? area : _countryAreasTr[area]!;
    return english
        ? 'This country is in $areaName.'
        : 'Bu ülke $areaName bölgesindedir.';
  }

  static String positionClue(
    AtlasKind kind,
    AtlasFeature feature, {
    bool english = false,
  }) {
    final List<double> center = _boundsCenter(feature);
    if (kind == AtlasKind.turkey) {
      final double longitudeFromMapCenter = center[0] - 35.2;
      final double latitudeFromMapCenter = center[1] - 38.95;
      if (longitudeFromMapCenter.abs() < .65 &&
          latitudeFromMapCenter.abs() < .45) {
        return english
            ? 'It is close to the center of the Türkiye map.'
            : 'Türkiye haritasının merkezine yakın bir konumdadır.';
      }
      final String direction = _direction(
        north: latitudeFromMapCenter >= 0,
        east: longitudeFromMapCenter >= 0,
        english: english,
      );
      return english
          ? 'It is in the $direction of the Türkiye map.'
          : 'Türkiye haritasının $direction tarafında kalır.';
    }

    final String latitude = center[1] > 8
        ? (english ? 'north of the equator' : 'Ekvator’un kuzeyinde')
        : center[1] < -8
        ? (english ? 'south of the equator' : 'Ekvator’un güneyinde')
        : (english ? 'close to the equator' : 'Ekvator çevresinde');
    final String longitude = center[0] > 18
        ? (english
              ? 'east of the prime meridian'
              : 'başlangıç meridyeninin doğusunda')
        : center[0] < -18
        ? (english
              ? 'west of the prime meridian'
              : 'başlangıç meridyeninin batısında')
        : (english
              ? 'near the prime meridian'
              : 'başlangıç meridyeni yakınında');
    return english
        ? 'Its map position is $latitude and $longitude.'
        : 'Haritadaki konumu $latitude ve $longitude yönündedir.';
  }

  static String culturalClue(
    AtlasKind kind,
    String code, {
    bool english = false,
  }) {
    final AtlasCulturalHint? hint = _culturalHints[code];
    if (hint == null) {
      return english
          ? 'This place is known for a distinctive local specialty.'
          : 'Bu yer, kendine özgü yöresel bir lezzetiyle tanınır.';
    }
    return english
        ? 'It is known for ${hint.specialty}.'
        : 'Meşhur olduğu şeylerden biri: ${hint.specialty}.';
  }

  static String culturalDetailClue(
    AtlasKind kind,
    String code, {
    bool english = false,
  }) {
    final AtlasCulturalHint? hint = _culturalHints[code];
    if (hint == null) {
      return english
          ? 'Look for a place associated with a memorable landmark.'
          : 'Ünlü bir simge veya tarihî yerle ilişkilendirilir.';
    }
    return english
        ? 'A well-known landmark here is ${hint.landmark}.'
        : 'Öne çıkan simgesi veya yeri: ${hint.landmark}.';
  }

  static String firstLetterClue(
    AtlasKind kind,
    String code, {
    bool english = false,
  }) {
    final String answer = label(kind, code, english: english);
    final int firstRune = answer.runes.first;
    final String letter = String.fromCharCode(firstRune).toUpperCase();
    return english
        ? 'The answer starts with “$letter”.'
        : 'Cevap “$letter” harfiyle başlıyor.';
  }

  static String coordinateClue(
    AtlasKind kind,
    AtlasFeature feature, {
    bool english = false,
  }) {
    final List<double> center = _boundsCenter(feature);
    final String latitudeDirection = english
        ? (center[1] >= 0 ? 'N' : 'S')
        : (center[1] >= 0 ? 'K' : 'G');
    final String longitudeDirection = english
        ? (center[0] >= 0 ? 'E' : 'W')
        : (center[0] >= 0 ? 'D' : 'B');
    final String latitude = center[1].abs().toStringAsFixed(1);
    final String longitude = center[0].abs().toStringAsFixed(1);
    final String subject = kind == AtlasKind.turkey
        ? (english ? 'The province' : 'İlin')
        : (english ? 'The country' : 'Ülkenin');
    return english
        ? '$subject’s approximate center is $latitude°$latitudeDirection, $longitude°$longitudeDirection.'
        : '$subject yaklaşık olarak $latitude°$latitudeDirection, $longitude°$longitudeDirection konumundadır.';
  }

  static String nameStructureClue(
    AtlasKind kind,
    String code, {
    bool english = false,
  }) {
    final String answer = label(kind, code, english: english).trim();
    final int wordCount = answer.split(RegExp(r'\s+')).length;
    final int letterCount = normalizeAnswer(answer).length;
    return english
        ? 'The name has $wordCount ${wordCount == 1 ? 'word' : 'words'} and $letterCount letters.'
        : 'Adı $wordCount kelime ve $letterCount harften oluşuyor.';
  }

  static String lastLetterClue(
    AtlasKind kind,
    String code, {
    bool english = false,
  }) {
    final String answer = label(kind, code, english: english);
    final String letter = String.fromCharCode(answer.runes.last).toUpperCase();
    return english
        ? 'The answer ends with “$letter”.'
        : 'Cevap “$letter” harfiyle bitiyor.';
  }

  static const Map<String, List<String>> _answerAliases =
      <String, List<String>>{
        'USA': <String>[
          'ABD',
          'Amerika',
          'United States of America',
          'US',
          'U.S.',
          'USA',
        ],
        'GBR': <String>[
          'Birleşik Krallık',
          'İngiltere',
          'Britanya',
          'United Kingdom',
          'Great Britain',
          'Britain',
          'UK',
        ],
        'TUR': <String>['Türkiye', 'Turkiye', 'Turkey'],
        'RUS': <String>['Russian Federation'],
        'CZE': <String>['Çek Cumhuriyeti', 'Czech Republic'],
        'KOR': <String>['Korea', 'Republic of Korea', 'South Korea'],
        'ZAF': <String>['Republic of South Africa', 'RSA'],
        'NZL': <String>['Aotearoa'],
        'TR-03': <String>['Afyon'],
        'TR-27': <String>['Antep'],
        'TR-33': <String>['İçel'],
        'TR-46': <String>['Maraş'],
        'TR-63': <String>['Urfa'],
      };

  static bool answerMatches(AtlasKind kind, String code, String answer) {
    final String normalized = normalizeAnswer(answer);
    if (normalized.isEmpty) return false;
    final Iterable<String> accepted = <String>[
      label(kind, code),
      if (kind == AtlasKind.world) label(kind, code, english: true),
      ...?_answerAliases[code],
    ];
    return accepted.any(
      (String candidate) => normalizeAnswer(candidate) == normalized,
    );
  }

  static String normalizeAnswer(String answer) => answer
      .trim()
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('ş', 's')
      .replaceAll('ğ', 'g')
      .replaceAll('ç', 'c')
      .replaceAll('ö', 'o')
      .replaceAll('ü', 'u')
      .replaceAll('\u0307', '')
      .replaceAll(RegExp(r'[^a-z0-9]'), '');

  static List<double> _boundsCenter(AtlasFeature feature) {
    double minLongitude = double.infinity;
    double maxLongitude = double.negativeInfinity;
    double minLatitude = double.infinity;
    double maxLatitude = double.negativeInfinity;
    for (final List<List<double>> ring in feature.rings) {
      for (final List<double> point in ring) {
        minLongitude = minLongitude < point[0] ? minLongitude : point[0];
        maxLongitude = maxLongitude > point[0] ? maxLongitude : point[0];
        minLatitude = minLatitude < point[1] ? minLatitude : point[1];
        maxLatitude = maxLatitude > point[1] ? maxLatitude : point[1];
      }
    }
    if (!minLongitude.isFinite || !minLatitude.isFinite) {
      return feature.center;
    }
    return <double>[
      (minLongitude + maxLongitude) / 2,
      (minLatitude + maxLatitude) / 2,
    ];
  }

  static String _direction({
    required bool north,
    required bool east,
    required bool english,
  }) {
    if (north && east) return english ? 'northeast' : 'kuzeydoğu';
    if (north) return english ? 'northwest' : 'kuzeybatı';
    if (east) return english ? 'southeast' : 'güneydoğu';
    return english ? 'southwest' : 'güneybatı';
  }

  static String? _provinceRegion(String suffix) {
    for (final MapEntry<String, List<String>> entry
        in _provinceCodesByRegion.entries) {
      if (entry.value.contains(suffix)) return entry.key;
    }
    return null;
  }

  static String? _countryArea(String code) {
    for (final MapEntry<String, List<String>> entry
        in _countryCodesByArea.entries) {
      if (entry.value.contains(code)) return entry.key;
    }
    return null;
  }

  static String label(AtlasKind kind, String code, {bool english = false}) {
    if (kind == AtlasKind.world) {
      return (english ? countriesEn : countries)[code] ?? code;
    }
    final int? number = int.tryParse(code.replaceFirst('TR-', ''));
    return number != null && number >= 1 && number <= provinces.length
        ? provinces[number - 1]
        : code;
  }

  static bool isTarget(AtlasKind kind, String code) => kind == AtlasKind.turkey
      ? code.startsWith('TR-') && int.tryParse(code.substring(3)) != null
      : countries.containsKey(code);
}

List<String> atlasQuestionCodes({
  required AtlasKind kind,
  required Iterable<String> codes,
  required int level,
  required int variant,
}) {
  final List<String> targets =
      codes.where((String code) => AtlasDataset.isTarget(kind, code)).toList()
        ..sort();
  targets.shuffle(Random(0x41544C41 ^ level * 7919 ^ variant * 104729));
  final int count = level <= 3
      ? 5
      : level <= 6
      ? 7
      : level <= 8
      ? 9
      : level == 9
      ? 11
      : 13;
  return targets.take(count).toList(growable: false);
}

bool atlasPointInFeature(
  double longitude,
  double latitude,
  AtlasFeature feature,
) {
  for (final List<List<double>> ring in feature.rings) {
    bool inside = false;
    for (int i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      final double xi = ring[i][0], yi = ring[i][1];
      final double xj = ring[j][0], yj = ring[j][1];
      final bool crosses =
          (yi > latitude) != (yj > latitude) &&
          longitude <
              (xj - xi) *
                      (latitude - yi) /
                      ((yj - yi) == 0 ? 1e-12 : (yj - yi)) +
                  xi;
      if (crosses) inside = !inside;
    }
    if (inside) return true;
  }
  return false;
}
