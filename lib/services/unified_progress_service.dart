import '../games/shared/studio_game_contracts.dart';
import 'common_level_score_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'local_progress_service.dart';

class ParkurProgressData {
  final int acikSeviye;
  final List<int> yildizlar;
  final List<int> enIyiPuanlar;
  final List<int> commonPoints;

  const ParkurProgressData({
    required this.acikSeviye,
    required this.yildizlar,
    required this.enIyiPuanlar,
    this.commonPoints = const <int>[],
  });

  int get toplamYildiz =>
      yildizlar.fold<int>(0, (toplam, deger) => toplam + deger);

  int get toplamPuan =>
      enIyiPuanlar.fold<int>(0, (toplam, deger) => toplam + deger);

  int get tamamlananSeviye => yildizlar.where((deger) => deger > 0).length;

  int get toplamOrtakPuan => commonPoints.isEmpty
      ? tamamlananSeviye * 10
      : commonPoints.fold<int>(0, (total, value) => total + value);
}

class UnifiedProgressData {
  final ParkurProgressData mantik;
  final ParkurProgressData sayi;
  final ParkurProgressData blok;
  final ParkurProgressData hafiza;
  final ParkurProgressData hanoi;
  final ParkurProgressData kelimeAvi;
  final ParkurProgressData gorselIq;
  final ParkurProgressData sekerSiralama;
  final ParkurProgressData sayiPetegi;
  final ParkurProgressData sekilBirlestir;
  final ParkurProgressData refleks;
  final List<ParkurProgressData> additionalGames;
  final Map<String, ParkurProgressData> gameProgressById;

  const UnifiedProgressData({
    required this.mantik,
    required this.sayi,
    required this.blok,
    required this.hafiza,
    required this.hanoi,
    required this.kelimeAvi,
    required this.gorselIq,
    required this.sekerSiralama,
    required this.sayiPetegi,
    required this.sekilBirlestir,
    required this.refleks,
    this.additionalGames = const [],
    this.gameProgressById = const <String, ParkurProgressData>{},
  });

  List<ParkurProgressData> get parkurlar => <ParkurProgressData>[
    mantik,
    sekerSiralama,
    sayi,
    blok,
    hafiza,
    hanoi,
    kelimeAvi,
    gorselIq,
    sayiPetegi,
    sekilBirlestir,
    refleks,
    ...additionalGames,
  ];

  int get toplamPuan =>
      parkurlar.fold<int>(0, (toplam, parkur) => toplam + parkur.toplamPuan);

  int get toplamYildiz =>
      parkurlar.fold<int>(0, (toplam, parkur) => toplam + parkur.toplamYildiz);

  int get tamamlananSeviye => parkurlar.fold<int>(
    0,
    (toplam, parkur) => toplam + parkur.tamamlananSeviye,
  );

  int get toplamOrtakPuan => GameContentPolicy.standardGames.fold<int>(
    0,
    (total, gameId) => total + (gameProgressById[gameId]?.toplamOrtakPuan ?? 0),
  );

  static int get maksimumYildiz => maksimumSeviye * 3;
  static int get maksimumSeviye =>
      GameContentPolicy.standardGames.length * GameContentPolicy.campaignLevels;

  // Retired-game awards remain in lifetime totals, but must not fill the
  // visible progress bar of the active 44-game campaign.
  int get kampanyaYildizlari =>
      toplamYildiz - mantik.toplamYildiz - sekerSiralama.toplamYildiz;
  int get kampanyaTamamlananSeviye =>
      tamamlananSeviye -
      mantik.tamamlananSeviye -
      sekerSiralama.tamamlananSeviye;

  double get genelIlerlemeOrani {
    return (kampanyaYildizlari / maksimumYildiz).clamp(0.0, 1.0).toDouble();
  }
}

class UnifiedProgressService {
  final LocalProgressService _localProgress = LocalProgressService();
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  Future<UnifiedProgressData> genelIlerlemeyiYukle() async {
    // İlk üç parkur mevcut LocalProgressService kayıtlarını aynen kullanır.
    // Böylece daha önce kazanılmış puan/yıldızlar kaybolmaz.
    final LogicProgressData mantikEski = await _localProgress
        .mantikIlerlemesiniYukle();

    final NumberProgressData sayiEski = await _localProgress
        .sayiIlerlemesiniYukle();

    final BlockProgressData blokEski = await _localProgress
        .blokIlerlemesiniYukle();

    // Hafıza ve Hanoi kendi SharedPreferences anahtarlarını
    // kullanıyordu. Ortak servis onları doğrudan okur.
    final ParkurProgressData hafiza = await _bagimsizParkurYukle('memory');

    final ParkurProgressData hanoi = await _bagimsizParkurYukle('hanoi');

    final List<ParkurProgressData> yeniParkurlar = await Future.wait(
      <Future<ParkurProgressData>>[
        _bagimsizParkurYukle('word_hunt'),
        _bagimsizParkurYukle('picture_iq'),
        _bagimsizParkurYukle('candy_sort'),
        _bagimsizParkurYukle('number_sort'),
        _bagimsizParkurYukle('shape_puzzle'),
        _bagimsizParkurYukle('reflex'),
      ],
    );

    const Set<String> fixedIds = <String>{
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
    };
    final List<String> additionalIds = GameContentPolicy.standardGames
        .difference(fixedIds)
        .toList(growable: false);
    final additional = await Future.wait(
      additionalIds.map(_bagimsizParkurYukle),
    );
    final List<int> sayiStars = _listeyiNormalizeEt(
      sayiEski.yildizlar,
      yildizMi: true,
    );
    final List<int> blokStars = _listeyiNormalizeEt(
      blokEski.yildizlar,
      yildizMi: true,
    );
    final ParkurProgressData sayi = ParkurProgressData(
      acikSeviye: sayiEski.acikSeviye
          .clamp(1, GameContentPolicy.campaignLevels)
          .toInt(),
      yildizlar: sayiStars,
      enIyiPuanlar: _listeyiNormalizeEt(sayiEski.enIyiPuanlar),
      commonPoints: await CommonLevelScoreStore.load(
        gameId: 'numbers',
        levelCount: GameContentPolicy.campaignLevels,
        completedStars: sayiStars,
      ),
    );
    final ParkurProgressData blok = ParkurProgressData(
      acikSeviye: blokEski.acikSeviye
          .clamp(1, GameContentPolicy.campaignLevels)
          .toInt(),
      yildizlar: blokStars,
      enIyiPuanlar: _listeyiNormalizeEt(blokEski.enIyiPuanlar),
      commonPoints: await CommonLevelScoreStore.load(
        gameId: 'blocks',
        levelCount: GameContentPolicy.campaignLevels,
        completedStars: blokStars,
      ),
    );
    final Map<String, ParkurProgressData> gameProgressById =
        <String, ParkurProgressData>{
          'numbers': sayi,
          'blocks': blok,
          'memory': hafiza,
          'hanoi': hanoi,
          'word_hunt': yeniParkurlar[0],
          'picture_iq': yeniParkurlar[1],
          'candy_sort': yeniParkurlar[2],
          'number_sort': yeniParkurlar[3],
          'shape_puzzle': yeniParkurlar[4],
          'reflex': yeniParkurlar[5],
        };
    for (int index = 0; index < additionalIds.length; index++) {
      gameProgressById[additionalIds[index]] = additional[index];
    }
    return UnifiedProgressData(
      mantik: ParkurProgressData(
        acikSeviye: mantikEski.acikSeviye.clamp(1, 10).toInt(),
        yildizlar: _listeyiNormalizeEt(
          mantikEski.yildizlar,
          yildizMi: true,
          count: 10,
        ),
        enIyiPuanlar: _listeyiNormalizeEt(mantikEski.enIyiPuanlar, count: 10),
      ),
      sayi: sayi,
      blok: blok,
      hafiza: hafiza,
      hanoi: hanoi,
      kelimeAvi: yeniParkurlar[0],
      gorselIq: yeniParkurlar[1],
      sekerSiralama: yeniParkurlar[2],
      sayiPetegi: yeniParkurlar[3],
      sekilBirlestir: yeniParkurlar[4],
      refleks: yeniParkurlar[5],
      additionalGames: additional,
      gameProgressById: gameProgressById,
    );
  }

  Future<ParkurProgressData> _bagimsizParkurYukle(String prefix) async {
    final int acikSeviye = await _prefs.getInt('${prefix}_unlocked_level') ?? 1;

    final List<String>? yildizKaydi = await _prefs.getStringList(
      '${prefix}_stars',
    );

    final List<String>? puanKaydi = await _prefs.getStringList(
      '${prefix}_best_scores',
    );
    final List<String>? ortakPuanKaydi = await _prefs.getStringList(
      '${prefix}_common_points',
    );

    final int count = GameContentPolicy.standardGames.contains(prefix)
        ? GameContentPolicy.campaignLevels
        : 10;
    final stars = _stringListeyiCoz(yildizKaydi, yildizMi: true, count: count);
    final List<int> commonPoints = ortakPuanKaydi == null
        ? List<int>.generate(
            count,
            (int index) => stars[index] > 0 ? 10 : 0,
            growable: false,
          )
        : _stringListeyiCoz(ortakPuanKaydi, count: count)
              .map((int value) => value.clamp(0, 10).toInt())
              .toList(growable: false);
    return ParkurProgressData(
      acikSeviye: count == GameContentPolicy.campaignLevels
          ? GameContentPolicy.safeUnlocked(acikSeviye, stars)
          : acikSeviye.clamp(1, count).toInt(),
      yildizlar: stars,
      enIyiPuanlar: _stringListeyiCoz(puanKaydi, count: count),
      commonPoints: commonPoints,
    );
  }

  List<int> _stringListeyiCoz(
    List<String>? kaynak, {
    bool yildizMi = false,
    int count = GameContentPolicy.campaignLevels,
  }) {
    return List<int>.generate(count, (index) {
      if (kaynak == null || index >= kaynak.length) {
        return 0;
      }

      final int deger = int.tryParse(kaynak[index]) ?? 0;

      if (yildizMi) {
        return deger.clamp(0, 3).toInt();
      }

      return deger < 0 ? 0 : deger;
    });
  }

  List<int> _listeyiNormalizeEt(
    List<int> kaynak, {
    bool yildizMi = false,
    int count = GameContentPolicy.campaignLevels,
  }) {
    return List<int>.generate(count, (index) {
      if (index >= kaynak.length) {
        return 0;
      }

      final int deger = kaynak[index];

      if (yildizMi) {
        return deger.clamp(0, 3).toInt();
      }

      return deger < 0 ? 0 : deger;
    });
  }
}
