import '../games/shared/studio_game_contracts.dart';

import 'package:shared_preferences/shared_preferences.dart';

class LogicProgressData {
  final int acikSeviye;
  final List<int> yildizlar;
  final List<int> enIyiPuanlar;

  const LogicProgressData({
    required this.acikSeviye,
    required this.yildizlar,
    required this.enIyiPuanlar,
  });

  int get toplamYildiz => yildizlar.fold(0, (toplam, deger) => toplam + deger);

  int get toplamPuan => enIyiPuanlar.fold(0, (toplam, deger) => toplam + deger);
}

class NumberProgressData {
  final int acikSeviye;
  final List<int> yildizlar;
  final List<int> enIyiPuanlar;

  const NumberProgressData({
    required this.acikSeviye,
    required this.yildizlar,
    required this.enIyiPuanlar,
  });

  int get toplamYildiz => yildizlar.fold(0, (toplam, deger) => toplam + deger);

  int get toplamPuan => enIyiPuanlar.fold(0, (toplam, deger) => toplam + deger);
}

class BlockProgressData {
  final int acikSeviye;
  final List<int> yildizlar;
  final List<int> enIyiPuanlar;

  const BlockProgressData({
    required this.acikSeviye,
    required this.yildizlar,
    required this.enIyiPuanlar,
  });

  int get toplamYildiz => yildizlar.fold(0, (toplam, deger) => toplam + deger);

  int get toplamPuan => enIyiPuanlar.fold(0, (toplam, deger) => toplam + deger);
}

class GenelProgressData {
  final int toplamPuan;
  final int toplamYildiz;

  final int mantikAcikSeviye;
  final int sayiAcikSeviye;
  final int blokAcikSeviye;

  final int mantikPuani;
  final int sayiPuani;
  final int blokPuani;

  const GenelProgressData({
    required this.toplamPuan,
    required this.toplamYildiz,
    required this.mantikAcikSeviye,
    required this.sayiAcikSeviye,
    required this.blokAcikSeviye,
    required this.mantikPuani,
    required this.sayiPuani,
    required this.blokPuani,
  });
}

class LocalProgressService {
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  // =========================================================
  // MANTIK LABİRENTİ
  // =========================================================

  static const String _logicAcikSeviyeKey = 'logic_acik_seviye';

  static const String _logicYildizlarKey = 'logic_yildizlar';

  static const String _logicPuanlarKey = 'logic_en_iyi_puanlar';

  Future<LogicProgressData> mantikIlerlemesiniYukle() async {
    final int acikSeviye = await _prefs.getInt(_logicAcikSeviyeKey) ?? 1;

    final List<String>? yildizKaydi = await _prefs.getStringList(
      _logicYildizlarKey,
    );

    final List<String>? puanKaydi = await _prefs.getStringList(
      _logicPuanlarKey,
    );

    return LogicProgressData(
      acikSeviye: acikSeviye.clamp(1, 10),
      yildizlar: _listeOku(yildizKaydi, 10),
      enIyiPuanlar: _listeOku(puanKaydi, 10),
    );
  }

  Future<void> mantikIlerlemesiniKaydet({
    required int acikSeviye,
    required List<int> yildizlar,
    required List<int> enIyiPuanlar,
  }) async {
    await _prefs.setInt(_logicAcikSeviyeKey, acikSeviye);

    await _prefs.setStringList(_logicYildizlarKey, _listeYaz(yildizlar));

    await _prefs.setStringList(_logicPuanlarKey, _listeYaz(enIyiPuanlar));
  }

  // =========================================================
  // SAYI USTASI
  // =========================================================

  static const String _numberAcikSeviyeKey = 'number_acik_seviye';

  static const String _numberYildizlarKey = 'number_yildizlar';

  static const String _numberPuanlarKey = 'number_en_iyi_puanlar';

  Future<NumberProgressData> sayiIlerlemesiniYukle() async {
    final int acikSeviye = await _prefs.getInt(_numberAcikSeviyeKey) ?? 1;

    final List<String>? yildizKaydi = await _prefs.getStringList(
      _numberYildizlarKey,
    );

    final List<String>? puanKaydi = await _prefs.getStringList(
      _numberPuanlarKey,
    );

    return NumberProgressData(
      acikSeviye: GameContentPolicy.safeUnlocked(
        acikSeviye,
        _listeOku(yildizKaydi, GameContentPolicy.campaignLevels),
      ),
      yildizlar: _listeOku(yildizKaydi, GameContentPolicy.campaignLevels),
      enIyiPuanlar: _listeOku(puanKaydi, GameContentPolicy.campaignLevels),
    );
  }

  Future<void> sayiIlerlemesiniKaydet({
    required int acikSeviye,
    required List<int> yildizlar,
    required List<int> enIyiPuanlar,
  }) async {
    await _prefs.setInt(_numberAcikSeviyeKey, acikSeviye);

    await _prefs.setStringList(_numberYildizlarKey, _listeYaz(yildizlar));

    await _prefs.setStringList(_numberPuanlarKey, _listeYaz(enIyiPuanlar));
  }

  // =========================================================
  // BLOK ATÖLYESİ
  // =========================================================

  static const String _blockAcikSeviyeKey = 'block_acik_seviye';

  static const String _blockYildizlarKey = 'block_yildizlar';

  static const String _blockPuanlarKey = 'block_en_iyi_puanlar';

  Future<BlockProgressData> blokIlerlemesiniYukle() async {
    final int acikSeviye = await _prefs.getInt(_blockAcikSeviyeKey) ?? 1;

    final List<String>? yildizKaydi = await _prefs.getStringList(
      _blockYildizlarKey,
    );

    final List<String>? puanKaydi = await _prefs.getStringList(
      _blockPuanlarKey,
    );

    return BlockProgressData(
      acikSeviye: GameContentPolicy.safeUnlocked(
        acikSeviye,
        _listeOku(yildizKaydi, GameContentPolicy.campaignLevels),
      ),
      yildizlar: _listeOku(yildizKaydi, GameContentPolicy.campaignLevels),
      enIyiPuanlar: _listeOku(puanKaydi, GameContentPolicy.campaignLevels),
    );
  }

  Future<void> blokIlerlemesiniKaydet({
    required int acikSeviye,
    required List<int> yildizlar,
    required List<int> enIyiPuanlar,
  }) async {
    await _prefs.setInt(_blockAcikSeviyeKey, acikSeviye);

    await _prefs.setStringList(_blockYildizlarKey, _listeYaz(yildizlar));

    await _prefs.setStringList(_blockPuanlarKey, _listeYaz(enIyiPuanlar));
  }

  // =========================================================
  // GENEL ZEKA PARKURU
  // =========================================================

  Future<GenelProgressData> genelIlerlemeyiYukle() async {
    final LogicProgressData mantik = await mantikIlerlemesiniYukle();

    final NumberProgressData sayi = await sayiIlerlemesiniYukle();

    final BlockProgressData blok = await blokIlerlemesiniYukle();

    return GenelProgressData(
      toplamPuan: mantik.toplamPuan + sayi.toplamPuan + blok.toplamPuan,

      toplamYildiz: mantik.toplamYildiz + sayi.toplamYildiz + blok.toplamYildiz,

      mantikAcikSeviye: mantik.acikSeviye,
      sayiAcikSeviye: sayi.acikSeviye,
      blokAcikSeviye: blok.acikSeviye,

      mantikPuani: mantik.toplamPuan,
      sayiPuani: sayi.toplamPuan,
      blokPuani: blok.toplamPuan,
    );
  }

  // =========================================================
  // YARDIMCI FONKSİYONLAR
  // =========================================================

  List<int> _listeOku(List<String>? kayit, int uzunluk) {
    return List<int>.generate(uzunluk, (index) {
      if (kayit == null || index >= kayit.length) {
        return 0;
      }

      return int.tryParse(kayit[index]) ?? 0;
    });
  }

  List<String> _listeYaz(List<int> liste) {
    return liste.map((deger) => deger.toString()).toList();
  }
}
