import 'package:shared_preferences/shared_preferences.dart';

import 'local_progress_service.dart';

class ParkurProgressData {
  final int acikSeviye;
  final List<int> yildizlar;
  final List<int> enIyiPuanlar;

  const ParkurProgressData({
    required this.acikSeviye,
    required this.yildizlar,
    required this.enIyiPuanlar,
  });

  int get toplamYildiz =>
      yildizlar.fold<int>(0, (toplam, deger) => toplam + deger);

  int get toplamPuan =>
      enIyiPuanlar.fold<int>(0, (toplam, deger) => toplam + deger);

  int get tamamlananSeviye =>
      yildizlar.where((deger) => deger > 0).length;
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
  });

  List<ParkurProgressData> get parkurlar => <ParkurProgressData>[
        mantik,
        sayi,
        blok,
        hafiza,
        hanoi,
        kelimeAvi,
        gorselIq,
        sekerSiralama,
        sayiPetegi,
        sekilBirlestir,
        refleks,
      ];

  int get toplamPuan => parkurlar.fold<int>(
        0,
        (toplam, parkur) => toplam + parkur.toplamPuan,
      );

  int get toplamYildiz => parkurlar.fold<int>(
        0,
        (toplam, parkur) => toplam + parkur.toplamYildiz,
      );

  int get tamamlananSeviye => parkurlar.fold<int>(
        0,
        (toplam, parkur) => toplam + parkur.tamamlananSeviye,
      );

  static const int maksimumYildiz = 330;
  static const int maksimumSeviye = 110;

  double get genelIlerlemeOrani {
    return (toplamYildiz / maksimumYildiz).clamp(0.0, 1.0).toDouble();
  }
}

class UnifiedProgressService {
  final LocalProgressService _localProgress = LocalProgressService();
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  Future<UnifiedProgressData> genelIlerlemeyiYukle() async {
    // İlk üç parkur mevcut LocalProgressService kayıtlarını aynen kullanır.
    // Böylece daha önce kazanılmış puan/yıldızlar kaybolmaz.
    final LogicProgressData mantikEski =
        await _localProgress.mantikIlerlemesiniYukle();

    final NumberProgressData sayiEski =
        await _localProgress.sayiIlerlemesiniYukle();

    final BlockProgressData blokEski =
        await _localProgress.blokIlerlemesiniYukle();

    // Hafıza ve Hanoi kendi SharedPreferences anahtarlarını
    // kullanıyordu. Ortak servis onları doğrudan okur.
    final ParkurProgressData hafiza =
        await _bagimsizParkurYukle('memory');

    final ParkurProgressData hanoi =
        await _bagimsizParkurYukle('hanoi');

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

    return UnifiedProgressData(
      mantik: ParkurProgressData(
        acikSeviye: mantikEski.acikSeviye.clamp(1, 10).toInt(),
        yildizlar: _listeyiNormalizeEt(mantikEski.yildizlar, yildizMi: true),
        enIyiPuanlar: _listeyiNormalizeEt(mantikEski.enIyiPuanlar),
      ),
      sayi: ParkurProgressData(
        acikSeviye: sayiEski.acikSeviye.clamp(1, 10).toInt(),
        yildizlar: _listeyiNormalizeEt(sayiEski.yildizlar, yildizMi: true),
        enIyiPuanlar: _listeyiNormalizeEt(sayiEski.enIyiPuanlar),
      ),
      blok: ParkurProgressData(
        acikSeviye: blokEski.acikSeviye.clamp(1, 10).toInt(),
        yildizlar: _listeyiNormalizeEt(blokEski.yildizlar, yildizMi: true),
        enIyiPuanlar: _listeyiNormalizeEt(blokEski.enIyiPuanlar),
      ),
      hafiza: hafiza,
      hanoi: hanoi,
      kelimeAvi: yeniParkurlar[0],
      gorselIq: yeniParkurlar[1],
      sekerSiralama: yeniParkurlar[2],
      sayiPetegi: yeniParkurlar[3],
      sekilBirlestir: yeniParkurlar[4],
      refleks: yeniParkurlar[5],
    );
  }

  Future<ParkurProgressData> _bagimsizParkurYukle(
    String prefix,
  ) async {
    final int acikSeviye =
        await _prefs.getInt('${prefix}_unlocked_level') ?? 1;

    final List<String>? yildizKaydi =
        await _prefs.getStringList('${prefix}_stars');

    final List<String>? puanKaydi =
        await _prefs.getStringList('${prefix}_best_scores');

    return ParkurProgressData(
      acikSeviye: acikSeviye.clamp(1, 10).toInt(),
      yildizlar: _stringListeyiCoz(yildizKaydi, yildizMi: true),
      enIyiPuanlar: _stringListeyiCoz(puanKaydi),
    );
  }

  List<int> _stringListeyiCoz(
    List<String>? kaynak, {
    bool yildizMi = false,
  }) {
    return List<int>.generate(
      10,
      (index) {
        if (kaynak == null || index >= kaynak.length) {
          return 0;
        }

        final int deger = int.tryParse(kaynak[index]) ?? 0;

        if (yildizMi) {
          return deger.clamp(0, 3).toInt();
        }

        return deger < 0 ? 0 : deger;
      },
    );
  }

  List<int> _listeyiNormalizeEt(
    List<int> kaynak, {
    bool yildizMi = false,
  }) {
    return List<int>.generate(
      10,
      (index) {
        if (index >= kaynak.length) {
          return 0;
        }

        final int deger = kaynak[index];

        if (yildizMi) {
          return deger.clamp(0, 3).toInt();
        }

        return deger < 0 ? 0 : deger;
      },
    );
  }
}
