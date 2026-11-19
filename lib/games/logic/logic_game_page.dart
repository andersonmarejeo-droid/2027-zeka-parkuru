import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/advanced_result_banner.dart';

import '../../services/daily_challenge_service.dart';
import '../../services/daily_course_service.dart';
import '../../services/game_audio_service.dart';
import '../../theme/app_visual_theme.dart';
import '../../theme/studio_visuals.dart';
import '../../services/local_progress_service.dart';
import '../../services/replayability_service.dart';
import '../shared/studio_game_contracts.dart';

Set<String> labirentBombaKonumlariniSec({
  required Set<String> engeller,
  required int bombaSayisi,
  required int seed,
}) {
  if (engeller.isEmpty || bombaSayisi <= 0) return <String>{};

  final List<String> adaylar = engeller.toList()..sort();
  adaylar.shuffle(Random(seed & 0x7fffffff));

  return Set<String>.unmodifiable(
    adaylar.take(min(bombaSayisi, adaylar.length)),
  );
}

int labirentKalanCan(int mevcutCan) => max(0, mevcutCan - 1);

class LogicGamePage extends StatefulWidget {
  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  const LogicGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  @override
  State<LogicGamePage> createState() => _LogicGamePageState();
}

class _LogicGamePageState extends State<LogicGamePage> {
  final LocalProgressService _progressService = LocalProgressService();

  bool yukleniyor = true;

  int acikSeviye = 1;

  List<int> kazanilanYildizlar = List<int>.filled(10, 0);

  List<int> enIyiPuanlar = List<int>.filled(10, 0);

  bool _competitionOpened = false;

  final List<LabirentSeviyesi> seviyeler = [
    const LabirentSeviyesi(
      numara: 1,
      baslik: 'İlk Adım',
      zorluk: 'KOLAY',
      oyuncuX: 0,
      oyuncuY: 0,
      hedefX: 5,
      hedefY: 5,
      engeller: {'1-0', '1-1', '1-2', '3-1', '3-2', '3-3', '4-3', '1-4', '2-4'},
    ),

    const LabirentSeviyesi(
      numara: 2,
      baslik: 'Kıvrımlı Yol',
      zorluk: 'KOLAY',
      oyuncuX: 0,
      oyuncuY: 5,
      hedefX: 5,
      hedefY: 0,
      engeller: {'1-1', '2-1', '3-1', '4-1', '1-3', '2-3', '3-3', '4-3', '4-4'},
    ),

    const LabirentSeviyesi(
      numara: 3,
      baslik: 'Dar Geçit',
      zorluk: 'ORTA',
      oyuncuX: 0,
      oyuncuY: 0,
      hedefX: 5,
      hedefY: 5,
      engeller: {'2-0', '2-1', '2-2', '4-2', '4-3', '4-4', '1-4', '2-4', '3-4'},
    ),

    const LabirentSeviyesi(
      numara: 4,
      baslik: 'Dört Köşe',
      zorluk: 'ORTA',
      oyuncuX: 5,
      oyuncuY: 5,
      hedefX: 0,
      hedefY: 0,
      engeller: {'1-1', '2-1', '3-1', '3-2', '3-3', '2-3', '1-3', '4-4'},
    ),

    const LabirentSeviyesi(
      numara: 5,
      baslik: 'Zihin Duvarı',
      zorluk: 'ZOR',
      oyuncuX: 0,
      oyuncuY: 0,
      hedefX: 5,
      hedefY: 5,
      engeller: {
        '1-0',
        '1-1',
        '3-1',
        '4-1',
        '1-3',
        '2-3',
        '3-3',
        '4-3',
        '4-4',
        '2-5',
      },
    ),

    const LabirentSeviyesi(
      numara: 6,
      baslik: 'Nefes',
      zorluk: 'KOLAY',
      oyuncuX: 0,
      oyuncuY: 5,
      hedefX: 5,
      hedefY: 5,
      engeller: {'1-4', '2-4', '3-4', '4-4', '4-2', '4-3'},
    ),

    const LabirentSeviyesi(
      numara: 7,
      baslik: 'Sarmal',
      zorluk: 'ORTA',
      oyuncuX: 0,
      oyuncuY: 0,
      hedefX: 3,
      hedefY: 3,
      engeller: {
        '1-1',
        '2-1',
        '3-1',
        '4-1',
        '4-2',
        '4-3',
        '4-4',
        '2-4',
        '1-4',
        '1-3',
        '1-2',
      },
    ),

    const LabirentSeviyesi(
      numara: 8,
      baslik: 'Keskin Dönüş',
      zorluk: 'ORTA',
      oyuncuX: 5,
      oyuncuY: 0,
      hedefX: 0,
      hedefY: 5,
      engeller: {
        '4-1',
        '3-1',
        '2-1',
        '1-1',
        '1-2',
        '1-3',
        '2-3',
        '3-3',
        '4-3',
        '4-4',
      },
    ),

    const LabirentSeviyesi(
      numara: 9,
      baslik: 'Zihin Kilidi',
      zorluk: 'ZOR',
      oyuncuX: 0,
      oyuncuY: 0,
      hedefX: 5,
      hedefY: 5,
      engeller: {
        '1-0',
        '1-1',
        '1-2',
        '3-1',
        '3-2',
        '3-3',
        '3-4',
        '5-3',
        '1-4',
        '1-5',
      },
    ),

    const LabirentSeviyesi(
      numara: 10,
      baslik: 'İlk Boss',
      zorluk: 'BOSS',
      oyuncuX: 0,
      oyuncuY: 5,
      hedefX: 5,
      hedefY: 0,
      engeller: {
        '1-0',
        '2-0',
        '3-0',
        '1-2',
        '2-2',
        '3-2',
        '4-2',
        '2-3',
        '4-3',
        '2-4',
        '4-4',
        '2-5',
      },
    ),
  ];

  @override
  void initState() {
    super.initState();

    // ZP_V9_0C_LOGIC_STARTUP_OPTIMIZED
    // Seviye çözülebilirlik taraması geliştirme sırasında bir kez doğrulandı.
    // Her ekran açılışında 10 labirenti yeniden taramak ilk kareyi geciktiriyordu.
    unawaited(ilerlemeyiYukle());
  }

  Future<void> ilerlemeyiYukle() async {
    final LogicProgressData veri = await _progressService
        .mantikIlerlemesiniYukle();

    if (!mounted) return;

    setState(() {
      acikSeviye = veri.acikSeviye;

      kazanilanYildizlar = List<int>.from(veri.yildizlar);

      enIyiPuanlar = List<int>.from(veri.enIyiPuanlar);

      yukleniyor = false;
    });

    _openCompetitionLevelIfNeeded();
  }

  void _openCompetitionLevelIfNeeded() {
    final int? level = widget.competitionLevel;
    if (_competitionOpened || level == null) return;
    _competitionOpened = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      seviyeAc((level - 1).clamp(0, seviyeler.length - 1).toInt());
    });
  }

  Future<void> ilerlemeyiKaydet() async {
    await _progressService.mantikIlerlemesiniKaydet(
      acikSeviye: acikSeviye,
      yildizlar: kazanilanYildizlar,
      enIyiPuanlar: enIyiPuanlar,
    );
  }

  int get toplamYildiz {
    return kazanilanYildizlar.fold(0, (toplam, deger) => toplam + deger);
  }

  int get toplamPuan {
    return enIyiPuanlar.fold(0, (toplam, deger) => toplam + deger);
  }

  Future<void> seviyeAc(int index) async {
    if (widget.competitionLevel == null && index + 1 > acikSeviye) {
      return;
    }

    final SeviyeSonucu? sonuc = await Navigator.push<SeviyeSonucu>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return LabirentOyunEkrani(
            seviye: seviyeler[index],
            toplamSeviye: seviyeler.length,
            previousBestScore: enIyiPuanlar[index],
            fixedSessionSeed: widget.competitionLayoutCode,
            competitionMode: widget.competitionLevel != null,
          );
        },
      ),
    );

    if (!mounted) return;

    if (widget.dailyCourseMode) {
      Navigator.pop(
        context,
        sonuc == null
            ? const DailyStageResult.exited(gameId: 'logic')
            : sonuc.tamamlandi
            ? DailyStageResult.completed(
                gameId: 'logic',
                stars: sonuc.yildiz,
                rawScore: sonuc.puan,
              )
            : const DailyStageResult.failed(gameId: 'logic'),
      );
      return;
    }

    if (sonuc == null || !sonuc.tamamlandi) {
      if (widget.competitionLevel != null && mounted) {
        Navigator.pop(context);
      }
      return;
    }

    if (widget.competitionLevel != null) {
      Navigator.pop(
        context,
        DailyCourseGameResult(
          gameId: 'logic',
          stars: sonuc.yildiz,
          score: sonuc.puan,
        ),
      );
      return;
    }

    setState(() {
      if (sonuc.yildiz > kazanilanYildizlar[index]) {
        kazanilanYildizlar[index] = sonuc.yildiz;
      }

      if (sonuc.puan > enIyiPuanlar[index]) {
        enIyiPuanlar[index] = sonuc.puan;
      }

      if (index + 1 == acikSeviye && acikSeviye < seviyeler.length) {
        acikSeviye++;
      }
    });

    await ilerlemeyiKaydet();

    await DailyChallengeService.instance.recordLevelCompleted(
      gameId: 'logic',
      stars: sonuc.yildiz,
      score: sonuc.puan,
    );

    if (sonuc.sonrakiSeviye && index + 1 < seviyeler.length) {
      await Future.delayed(const Duration(milliseconds: 180));

      if (!mounted) return;

      seviyeAc(index + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (yukleniyor) {
      return Scaffold(
        backgroundColor: StudioVisuals.canvas,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LText(
              'MANTIK LABİRENTİ',
              style: TextStyle(
                color: StudioVisuals.ink,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            LText(
              'Zihin yolculuğun',
              style: TextStyle(color: StudioVisuals.muted, fontSize: 12),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveGameFrame(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool darEkran = constraints.maxWidth < 360;
              final bool isLandscape = constraints.maxWidth > constraints.maxHeight;
              final double yatayBosluk = darEkran ? 12 : 18;
              final double izgaraBoslugu = darEkran ? 10 : 14;

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(yatayBosluk),
                      child: _IlerlemePaneli(
                        acikSeviye: acikSeviye,
                        toplamYildiz: toplamYildiz,
                        toplamPuan: toplamPuan,
                        darEkran: darEkran,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      yatayBosluk,
                      0,
                      yatayBosluk,
                      30,
                    ),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isLandscape ? 3 : 2,
                        crossAxisSpacing: izgaraBoslugu,
                        mainAxisSpacing: izgaraBoslugu,
                        mainAxisExtent:
                            104 *
                            MediaQuery.textScalerOf(context)
                                .scale(1)
                                .clamp(1.0, 1.6),
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final bool acik = index + 1 <= acikSeviye;

                          return _SeviyeKarti(
                            seviye: seviyeler[index],
                            acik: acik,
                            yildiz: kazanilanYildizlar[index],
                            enIyiPuan: enIyiPuanlar[index],
                            onTap: () {
                              seviyeAc(index);
                            },
                          );
                        },
                        childCount: seviyeler.length,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class LabirentOyunEkrani extends StatefulWidget {
  final LabirentSeviyesi seviye;
  final int toplamSeviye;
  final int previousBestScore;
  final int? fixedSessionSeed;
  final bool competitionMode;

  const LabirentOyunEkrani({
    super.key,
    required this.seviye,
    required this.toplamSeviye,
    required this.previousBestScore,
    this.fixedSessionSeed,
    this.competitionMode = false,
  });

  @override
  State<LabirentOyunEkrani> createState() => _LabirentOyunEkraniState();
}

class _LabirentOyunEkraniState extends State<LabirentOyunEkrani> {
  static const int satirSayisi = 6;
  static const int sutunSayisi = 6;
  static const int maksimumCan = 3;

  final ReplayabilityService _replayability = ReplayabilityService();

  final GameAudioService _audio = GameAudioService.instance;

  late LabirentSeviyesi aktifSeviye;
  late int oyuncuX;
  late int oyuncuY;

  List<Hucre> hedefler = <Hucre>[];
  List<int> hedefHamleleri = <int>[];
  final Set<String> tamamlananHedefKonumlari = <String>{};
  int aktifHedefIndex = 0;

  int sessionSeed = 0;
  bool labirentHazirlaniyor = false;

  final Set<String> bombaKonumlari = <String>{};
  final Set<String> patlayanBombaKonumlari = <String>{};
  String? patlamaKonumu;
  int patlamaToken = 0;
  int can = maksimumCan;
  bool basarisiz = false;
  Timer? _patlamaTimer;
  Timer? _basarisizlikTimer;

  int hamle = 0;

  bool tamamlandi = false;
  bool ipucuKullanildi = false;

  Hucre? ipucuHucresi;

  int get hedefSayisi => switch (widget.seviye.zorluk) {
    'ZOR' || 'BOSS' => 3,
    _ => 2,
  };

  Hucre get aktifHedef => hedefler[aktifHedefIndex];

  int get tamamlananHedefSayisi => tamamlananHedefKonumlari.length;

  int get bombaSayisi => switch (widget.seviye.zorluk) {
    'ZOR' || 'BOSS' => 4,
    _ => 3,
  };

  @override
  void initState() {
    super.initState();

    // İlk frame güvenli olsun diye mevcut sabit seviye ile başlıyoruz.
    aktifSeviye = widget.seviye;
    oyuncuX = aktifSeviye.oyuncuX;
    oyuncuY = aktifSeviye.oyuncuY;
    hedefler = <Hucre>[Hucre(aktifSeviye.hedefX, aktifSeviye.hedefY)];
    hedefHamleleri = <int>[
      (enKisaYolBul(
                seviye: aktifSeviye,
                baslangicX: aktifSeviye.oyuncuX,
                baslangicY: aktifSeviye.oyuncuY,
              )?.length ??
              1000) -
          1,
    ];

    unawaited(_audio.preload(GameAudioGroup.logic));
    unawaited(_audio.play(GameSound.gameOpen));

    _yeniLabirentHazirla();
  }

  @override
  void dispose() {
    _patlamaTimer?.cancel();
    _basarisizlikTimer?.cancel();
    super.dispose();
  }

  Future<void> _yeniLabirentHazirla() async {
    if (labirentHazirlaniyor) return;

    _patlamaTimer?.cancel();
    _basarisizlikTimer?.cancel();

    setState(() {
      labirentHazirlaniyor = true;
      patlamaKonumu = null;
    });

    sessionSeed =
        widget.fixedSessionSeed ??
        await _replayability.newSeed(
          gameId: 'logic',
          level: widget.seviye.numara,
        );

    final Random rng = _replayability.randomFor(
      sessionSeed: sessionSeed,
      round: 0,
      salt: 307,
    );

    LabirentSeviyesi? secilen;
    LabirentSeviyesi? yedek;
    _HedefRotasi? secilenRota;
    _HedefRotasi? yedekRota;

    for (int deneme = 0; deneme < 180; deneme++) {
      final LabirentSeviyesi aday = _rastgeleLabirentUret(rng);

      final List<Hucre>? yol = enKisaYolBul(
        seviye: aday,
        baslangicX: aday.oyuncuX,
        baslangicY: aday.oyuncuY,
      );

      if (yol == null) {
        continue;
      }

      final _HedefRotasi? rota = _hedefRotasiOlustur(seviye: aday, rng: rng);

      if (rota == null || rota.hedefler.length != hedefSayisi) {
        continue;
      }

      yedek ??= aday;
      yedekRota ??= rota;

      final int manhattan =
          (aday.oyuncuX - aday.hedefX).abs() +
          (aday.oyuncuY - aday.hedefY).abs();

      final int ekstraYol = switch (widget.seviye.zorluk) {
        'KOLAY' => 0,
        'ORTA' => 2,
        'ZOR' => 4,
        'BOSS' => 5,
        _ => 0,
      };

      if (yol.length - 1 < manhattan + ekstraYol) {
        continue;
      }

      final List<String> siraliEngeller = aday.engeller.toList()..sort();

      final String hedefParmakIzi = rota.hedefler
          .map((hedef) => '${hedef.x}-${hedef.y}')
          .join('>');

      final String fingerprint =
          '${aday.oyuncuX}-${aday.oyuncuY}|'
          '$hedefParmakIzi|'
          '${siraliEngeller.join(",")}';

      final bool yeniMi =
          widget.fixedSessionSeed != null ||
          await _replayability.registerFingerprint(
            gameId: 'logic',
            level: widget.seviye.numara,
            fingerprint: fingerprint,
            historyLimit: 150,
          );

      if (!yeniMi) {
        continue;
      }

      secilen = aday;
      secilenRota = rota;
      break;
    }

    final LabirentSeviyesi hazirSeviye = secilen ?? yedek ?? widget.seviye;
    final _HedefRotasi rota =
        secilenRota ??
        yedekRota ??
        _hedefRotasiOlustur(seviye: hazirSeviye, rng: rng) ??
        _tekHedefRotasi(hazirSeviye);

    final Set<String> bombalar = labirentBombaKonumlariniSec(
      engeller: hazirSeviye.engeller,
      bombaSayisi: bombaSayisi,
      seed: sessionSeed ^ (widget.seviye.numara * 7919) ^ 0x5A17,
    );

    if (!mounted) return;

    setState(() {
      aktifSeviye = hazirSeviye;
      oyuncuX = aktifSeviye.oyuncuX;
      oyuncuY = aktifSeviye.oyuncuY;
      hedefler = List<Hucre>.from(rota.hedefler);
      hedefHamleleri = List<int>.from(rota.hedefHamleleri);
      aktifHedefIndex = 0;
      tamamlananHedefKonumlari.clear();
      hamle = 0;
      tamamlandi = false;
      basarisiz = false;
      can = maksimumCan;
      bombaKonumlari
        ..clear()
        ..addAll(bombalar);
      patlayanBombaKonumlari.clear();
      patlamaKonumu = null;
      ipucuKullanildi = false;
      ipucuHucresi = null;
      labirentHazirlaniyor = false;
    });
  }

  LabirentSeviyesi _rastgeleLabirentUret(Random rng) {
    final List<Hucre> kenarHucreleri = [];

    for (int i = 0; i < 6; i++) {
      kenarHucreleri.add(Hucre(i, 0));
      kenarHucreleri.add(Hucre(i, 5));

      if (i != 0 && i != 5) {
        kenarHucreleri.add(Hucre(0, i));
        kenarHucreleri.add(Hucre(5, i));
      }
    }

    Hucre baslangic = kenarHucreleri[rng.nextInt(kenarHucreleri.length)];

    Hucre hedef = kenarHucreleri[rng.nextInt(kenarHucreleri.length)];

    int guvenlik = 0;

    while (((baslangic.x - hedef.x).abs() + (baslangic.y - hedef.y).abs()) <
            7 &&
        guvenlik < 100) {
      hedef = kenarHucreleri[rng.nextInt(kenarHucreleri.length)];
      guvenlik++;
    }

    final int engelSayisi = switch (widget.seviye.zorluk) {
      'KOLAY' => 6 + rng.nextInt(3),
      'ORTA' => 9 + rng.nextInt(3),
      'ZOR' => 11 + rng.nextInt(3),
      'BOSS' => 13 + rng.nextInt(3),
      _ => 8,
    };

    final Set<String> engeller = {};

    int deneme = 0;

    while (engeller.length < engelSayisi && deneme < 300) {
      deneme++;

      final int x = rng.nextInt(6);
      final int y = rng.nextInt(6);

      if ((x == baslangic.x && y == baslangic.y) ||
          (x == hedef.x && y == hedef.y)) {
        continue;
      }

      engeller.add('$x-$y');
    }

    return LabirentSeviyesi(
      numara: widget.seviye.numara,
      baslik: widget.seviye.baslik,
      zorluk: widget.seviye.zorluk,
      oyuncuX: baslangic.x,
      oyuncuY: baslangic.y,
      hedefX: hedef.x,
      hedefY: hedef.y,
      engeller: engeller,
    );
  }

  _HedefRotasi? _hedefRotasiOlustur({
    required LabirentSeviyesi seviye,
    required Random rng,
  }) {
    final List<Hucre>? ilkYol = enKisaYolBul(
      seviye: seviye,
      baslangicX: seviye.oyuncuX,
      baslangicY: seviye.oyuncuY,
    );

    if (ilkYol == null) return null;

    final List<Hucre> rotaHedefleri = <Hucre>[
      Hucre(seviye.hedefX, seviye.hedefY),
    ];
    final List<int> rotaHamleleri = <int>[ilkYol.length - 1];
    final Set<String> kullanilanKonumlar = <String>{
      '${seviye.oyuncuX}-${seviye.oyuncuY}',
      '${seviye.hedefX}-${seviye.hedefY}',
    };

    while (rotaHedefleri.length < hedefSayisi) {
      final Hucre mevcutHedef = rotaHedefleri.last;
      List<_HedefAdayi> adaylar = _ulasilabilirHedefleriBul(
        seviye: seviye,
        baslangic: mevcutHedef,
        kullanilanKonumlar: kullanilanKonumlar,
        enAzYol: switch (widget.seviye.zorluk) {
          'KOLAY' => 6,
          'ORTA' => 7,
          'ZOR' => 8,
          'BOSS' => 9,
          _ => 6,
        },
      );

      if (adaylar.isEmpty) {
        adaylar = _ulasilabilirHedefleriBul(
          seviye: seviye,
          baslangic: mevcutHedef,
          kullanilanKonumlar: kullanilanKonumlar,
          enAzYol: 4,
        );
      }

      if (adaylar.isEmpty) return null;

      adaylar.sort((a, b) => b.hamleSayisi.compareTo(a.hamleSayisi));

      final int ustGrup = min(4, adaylar.length);
      final _HedefAdayi secilenAday = adaylar[rng.nextInt(ustGrup)];

      rotaHedefleri.add(secilenAday.hucre);
      rotaHamleleri.add(secilenAday.hamleSayisi);
      kullanilanKonumlar.add('${secilenAday.hucre.x}-${secilenAday.hucre.y}');
    }

    return _HedefRotasi(hedefler: rotaHedefleri, hedefHamleleri: rotaHamleleri);
  }

  List<_HedefAdayi> _ulasilabilirHedefleriBul({
    required LabirentSeviyesi seviye,
    required Hucre baslangic,
    required Set<String> kullanilanKonumlar,
    required int enAzYol,
  }) {
    final List<_HedefAdayi> adaylar = <_HedefAdayi>[];

    for (int y = 0; y < satirSayisi; y++) {
      for (int x = 0; x < sutunSayisi; x++) {
        final String anahtar = '$x-$y';

        if (seviye.engeller.contains(anahtar) ||
            kullanilanKonumlar.contains(anahtar)) {
          continue;
        }

        final List<Hucre>? yol = enKisaYolBul(
          seviye: seviye,
          baslangicX: baslangic.x,
          baslangicY: baslangic.y,
          hedefX: x,
          hedefY: y,
        );

        if (yol == null || yol.length - 1 < enAzYol) {
          continue;
        }

        adaylar.add(
          _HedefAdayi(hucre: Hucre(x, y), hamleSayisi: yol.length - 1),
        );
      }
    }

    return adaylar;
  }

  _HedefRotasi _tekHedefRotasi(LabirentSeviyesi seviye) {
    final List<Hucre>? yol = enKisaYolBul(
      seviye: seviye,
      baslangicX: seviye.oyuncuX,
      baslangicY: seviye.oyuncuY,
    );

    return _HedefRotasi(
      hedefler: <Hucre>[Hucre(seviye.hedefX, seviye.hedefY)],
      hedefHamleleri: <int>[yol == null ? 999 : yol.length - 1],
    );
  }

  int get hedefHamle {
    return hedefHamleleri.fold<int>(0, (toplam, deger) => toplam + deger);
  }

  bool engelMi(int x, int y) {
    return aktifSeviye.engeller.contains('$x-$y');
  }

  bool aktifBombaMi(int x, int y) {
    final String konum = '$x-$y';
    return bombaKonumlari.contains(konum) &&
        !patlayanBombaKonumlari.contains(konum);
  }

  void _bombayaCarp(int x, int y) {
    if (tamamlandi || basarisiz || !aktifBombaMi(x, y)) return;

    final String konum = '$x-$y';
    final int kalanCan = labirentKalanCan(can);

    _patlamaTimer?.cancel();

    setState(() {
      patlayanBombaKonumlari.add(konum);
      patlamaKonumu = konum;
      patlamaToken++;
      can = kalanCan;
      basarisiz = kalanCan == 0;
      ipucuHucresi = null;
    });

    unawaited(_audio.play(GameSound.reflexBomb, gain: 0.76));
    _audio.hapticHeavy();

    final int gecerliToken = patlamaToken;
    _patlamaTimer = Timer(const Duration(milliseconds: 620), () {
      if (!mounted || patlamaToken != gecerliToken) return;
      setState(() => patlamaKonumu = null);
    });

    ScaffoldMessenger.of(context).clearSnackBars();

    if (kalanCan > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1150),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF8A2D35),
          content: Row(
            children: <Widget>[
              const Icon(Icons.heart_broken_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.l10n.isEnglish
                      ? 'Bomb exploded! $kalanCan lives left.'
                      : 'Bomba patladı! $kalanCan canın kaldı.',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    _basarisizlikTimer?.cancel();
    _basarisizlikTimer = Timer(const Duration(milliseconds: 720), () {
      if (mounted && basarisiz) basarisizlikPenceresi();
    });
  }

  Future<void> yenidenBaslat() async {
    _patlamaTimer?.cancel();
    _basarisizlikTimer?.cancel();
    ScaffoldMessenger.of(context).clearSnackBars();
    unawaited(_audio.play(GameSound.transition, gain: 0.70));
    await _yeniLabirentHazirla();
  }

  void hareketEt(int dx, int dy) {
    if (tamamlandi || basarisiz || labirentHazirlaniyor) {
      return;
    }

    final int yeniX = oyuncuX + dx;
    final int yeniY = oyuncuY + dy;

    if (yeniX < 0 ||
        yeniX >= sutunSayisi ||
        yeniY < 0 ||
        yeniY >= satirSayisi) {
      unawaited(_audio.play(GameSound.logicWall));
      return;
    }

    if (engelMi(yeniX, yeniY)) {
      if (aktifBombaMi(yeniX, yeniY)) {
        _bombayaCarp(yeniX, yeniY);
      } else {
        unawaited(_audio.play(GameSound.logicWall));
      }
      return;
    }

    unawaited(_audio.play(GameSound.logicMove));

    setState(() {
      oyuncuX = yeniX;
      oyuncuY = yeniY;
      hamle++;
      ipucuHucresi = null;
    });

    if (oyuncuX == aktifHedef.x && oyuncuY == aktifHedef.y) {
      final String tamamlananKonum = '${aktifHedef.x}-${aktifHedef.y}';

      unawaited(_audio.play(GameSound.logicGoal));

      if (aktifHedefIndex + 1 < hedefler.length) {
        setState(() {
          tamamlananHedefKonumlari.add(tamamlananKonum);
          aktifHedefIndex++;
          ipucuHucresi = null;
        });

        _audio.hapticMedium();

        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(milliseconds: 1450),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF1B5E45),
            content: Row(
              children: [
                const Icon(Icons.stars_rounded, color: Color(0xFFFFD334)),
                const SizedBox(width: 10),
                Expanded(
                  child: LText(
                    '$tamamlananHedefSayisi/${hedefler.length} hedef tamamlandı. Yeni hedef belirdi!',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        );
        return;
      }

      setState(() {
        tamamlananHedefKonumlari.add(tamamlananKonum);
        tamamlandi = true;
      });

      Future.delayed(const Duration(milliseconds: 520), sonucPenceresi);
    }
  }

  int yildizHesapla() {
    if (hamle <= hedefHamle) {
      return 3;
    }

    if (hamle <= hedefHamle + hedefler.length * 4) {
      return 2;
    }

    return 1;
  }

  int puanHesapla() {
    int puan = yildizHesapla() * 100;

    if (!ipucuKullanildi) {
      puan += 50;
    }

    if (widget.seviye.zorluk == 'ZOR') {
      puan += 50;
    }

    if (widget.seviye.zorluk == 'BOSS') {
      puan += 150;
    }

    return puan;
  }

  void ipucuGoster() {
    if (tamamlandi || basarisiz || labirentHazirlaniyor) return;

    final List<Hucre>? yol = enKisaYolBul(
      seviye: aktifSeviye,
      baslangicX: oyuncuX,
      baslangicY: oyuncuY,
      hedefX: aktifHedef.x,
      hedefY: aktifHedef.y,
    );

    if (yol == null || yol.length < 2) {
      return;
    }

    final Hucre sonraki = yol[1];

    final int dx = sonraki.x - oyuncuX;

    final int dy = sonraki.y - oyuncuY;

    String yon = '';

    IconData yonIkonu = Icons.arrow_forward_rounded;

    if (dx == 1) {
      yon = 'SAĞA';
      yonIkonu = Icons.arrow_forward_rounded;
    } else if (dx == -1) {
      yon = 'SOLA';
      yonIkonu = Icons.arrow_back_rounded;
    } else if (dy == 1) {
      yon = 'AŞAĞI';
      yonIkonu = Icons.arrow_downward_rounded;
    } else if (dy == -1) {
      yon = 'YUKARI';
      yonIkonu = Icons.arrow_upward_rounded;
    }

    setState(() {
      ipucuKullanildi = true;
      ipucuHucresi = sonraki;
    });

    unawaited(_audio.play(GameSound.logicHint));

    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1700),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF243F6B),
        content: Row(
          children: [
            const Icon(Icons.lightbulb_rounded, color: Color(0xFFFFD334)),
            const SizedBox(width: 10),
            Expanded(
              child: LText(
                'İpucu: Bir sonraki hamlen $yon.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Icon(yonIkonu, color: Colors.white),
          ],
        ),
      ),
    );
  }

  void basarisizlikPenceresi() {
    if (!mounted || !basarisiz) return;

    if (widget.competitionMode) {
      Navigator.pop(
        context,
        const SeviyeSonucu(
          tamamlandi: false,
          yildiz: 0,
          puan: 0,
          sonrakiSeviye: false,
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 24,
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Color(0xFF351A2A), Color(0xFF172441)],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFFF6B70), width: 2),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: const Color(0xFFFF454D).withValues(alpha: 0.25),
                    blurRadius: 28,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4D56).withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFF7B80),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.heart_broken_rounded,
                      color: Color(0xFFFF7B80),
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const LText(
                    'CANLAR TÜKENDİ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFFF8C90),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    context.l10n.isEnglish
                        ? 'You hit three bombs. Watch the black bombs in '
                              'the walls and try a safer route.'
                        : 'Üç bombaya çarptın. Duvarlardaki siyah bombaları '
                              'izleyerek yeni bir rota deneyebilirsin.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.heart_broken_rounded, color: Colors.white24),
                      SizedBox(width: 7),
                      Icon(Icons.heart_broken_rounded, color: Colors.white24),
                      SizedBox(width: 7),
                      Icon(Icons.heart_broken_rounded, color: Colors.white24),
                    ],
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1D65FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        unawaited(yenidenBaslat());
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const LText('Yeniden Başlat'),
                    ),
                  ),
                  const SizedBox(height: 7),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      Navigator.pop(
                        context,
                        const SeviyeSonucu(
                          tamamlandi: false,
                          yildiz: 0,
                          puan: 0,
                          sonrakiSeviye: false,
                        ),
                      );
                    },
                    child: const LText('BÖLÜMLER'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void sonucPenceresi() {
    if (!mounted) return;

    final int yildiz = yildizHesapla();
    final int puan = puanHesapla();

    unawaited(
      _audio.playVictory(
        stars: yildiz,
        boss: widget.seviye.zorluk == 'BOSS',
        levelNumber: widget.seviye.numara,
      ),
    );

    if (widget.competitionMode) {
      Navigator.pop(
        context,
        SeviyeSonucu(
          tamamlandi: true,
          yildiz: yildiz,
          puan: puan,
          sonrakiSeviye: false,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 22,
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ZpVisualPalette.of(context).surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFFFD334), width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    size: 62,
                    color: Color(0xFFFFD334),
                  ),
                  const SizedBox(height: 8),
                  LText(
                    widget.seviye.zorluk == 'BOSS'
                        ? 'BOSS YENİLDİ!'
                        : 'HARİKA!',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 27,
                      color: Color(0xFFFFD334),
                    ),
                  ),
                  const SizedBox(height: 11),
                  AdvancedResultBanner(
                    score: puan,
                    previousBestScore: widget.previousBestScore,
                    english: context.l10n.isEnglish,
                    accentColor: const Color(0xFFFFD334),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return Icon(
                        index < yildiz
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: const Color(0xFFFFD334),
                        size: 45,
                      );
                    }),
                  ),
                  const SizedBox(height: 14),
                  LText(
                    '${hedefler.length} hedef tamamlandı',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _SonucKutusu(
                          baslik: 'HAMLE',
                          deger: '$hamle',
                          ikon: Icons.swipe_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SonucKutusu(
                          baslik: 'EN KISA',
                          deger: '$hedefHamle',
                          ikon: Icons.route_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SonucKutusu(
                          baslik: 'PUAN',
                          deger: '$puan',
                          ikon: Icons.stars_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  if (widget.seviye.numara < widget.toplamSeviye)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF69CE14),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        onPressed: () {
                          Navigator.pop(dialogContext);

                          Navigator.pop(
                            context,
                            SeviyeSonucu(
                              tamamlandi: true,
                              yildiz: yildiz,
                              puan: puan,
                              sonrakiSeviye: true,
                            ),
                          );
                        },
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const LText('SONRAKİ SEVİYE'),
                      ),
                    ),

                  if (widget.seviye.numara == widget.toplamSeviye)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFE040FB),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        onPressed: () {
                          Navigator.pop(dialogContext);

                          Navigator.pop(
                            context,
                            SeviyeSonucu(
                              tamamlandi: true,
                              yildiz: yildiz,
                              puan: puan,
                              sonrakiSeviye: false,
                            ),
                          );
                        },
                        icon: const Icon(Icons.emoji_events_rounded),
                        label: const LText('PARKURU TAMAMLA'),
                      ),
                    ),

                  const SizedBox(height: 7),

                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);

                      Navigator.pop(
                        context,
                        SeviyeSonucu(
                          tamamlandi: true,
                          yildiz: yildiz,
                          puan: puan,
                          sonrakiSeviye: false,
                        ),
                      );
                    },
                    child: const LText('BÖLÜM LİSTESİ'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LText(
              context.l10n.uppercaseLabel(widget.seviye.baslik),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
            ),
            LText(
              'Seviye ${widget.seviye.numara} / ${widget.toplamSeviye}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Akıllı İpucu',
            onPressed: tamamlandi || basarisiz ? null : ipucuGoster,
            icon: const Icon(Icons.lightbulb_rounded, color: Color(0xFFFFD334)),
          ),
          IconButton(
            tooltip: 'Yeniden Başlat',
            onPressed: yenidenBaslat,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
              child: Column(
                children: [
                  _OyunBilgiPaneli(
                    tamamlananHedef: tamamlananHedefSayisi,
                    toplamHedef: hedefler.length,
                    hamle: hamle,
                    hedefHamle: hedefHamle,
                    can: can,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Center(
                      child: AspectRatio(aspectRatio: 1, child: oyunAlani()),
                    ),
                  ),
                  const SizedBox(height: 15),
                  yonTuslari(),
                ],
              ),
            ),
          ),
          if (labirentHazirlaniyor)
            Positioned.fill(
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor
                    .withValues(alpha: 0.72),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      LText(
                        'Yeni labirent hazırlanıyor...',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget oyunAlani() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1D38),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1B4D7B), width: 2),
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: satirSayisi * sutunSayisi,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: sutunSayisi,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemBuilder: (context, index) {
          final int x = index % sutunSayisi;
          final int y = index ~/ sutunSayisi;

          final bool oyuncu = x == oyuncuX && y == oyuncuY;

          // Yıldız her zaman o anda sıradaki gerçek hedefi gösterir.
          // Önceki hedefler tamamlanınca yeşil onaya dönüşür.
          final bool hedef = x == aktifHedef.x && y == aktifHedef.y;

          final bool tamamlananHedef = tamamlananHedefKonumlari.contains(
            '$x-$y',
          );

          final bool engel = engelMi(x, y);
          final String konum = '$x-$y';
          final bool bomba =
              engel &&
              bombaKonumlari.contains(konum) &&
              !patlayanBombaKonumlari.contains(konum);
          final bool patliyor = patlamaKonumu == konum;

          final bool ipucu =
              ipucuHucresi != null &&
              ipucuHucresi!.x == x &&
              ipucuHucresi!.y == y;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: engel
                  ? const Color(0xFF102540)
                  : ipucu
                  ? const Color(0xFF9C7A00)
                  : const Color(0xFF133359),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: ipucu
                    ? const Color(0xFFFFD334)
                    : engel
                    ? const Color(0xFF2B4C70)
                    : const Color(0xFF205084),
              ),
            ),
            child: Center(
              child: oyuncu
                  ? const _LabirentKasifi()
                  : hedef
                  ? _HedefIsareti(
                      sira: aktifHedefIndex + 1,
                      toplam: hedefler.length,
                    )
                  : ipucu
                  ? const Icon(
                      Icons.lightbulb_rounded,
                      color: Color(0xFFFFD334),
                    )
                  : tamamlananHedef
                  ? const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF52E86B),
                      size: 27,
                    )
                  : engel
                  ? _LabirentDuvari(
                      anaRenk: _duvarRengi(x, y),
                      bombali: bomba,
                      patliyor: patliyor,
                      patlamaToken: patlamaToken,
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  Color _duvarRengi(int x, int y) {
    const List<Color> palet = <Color>[
      Color(0xFF3565A8),
      Color(0xFF5B4AA7),
      Color(0xFF247A78),
      Color(0xFF8A4D68),
    ];
    return palet[(x * 3 + y * 5) % palet.length];
  }

  Widget yonTuslari() {
    Widget buton(IconData icon, int dx, int dy) {
      final bool etkin = !tamamlandi && !basarisiz && !labirentHazirlaniyor;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: etkin ? () => hareketEt(dx, dy) : null,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: etkin
                    ? const <Color>[Color(0xFF1D65FF), Color(0xFF754BFF)]
                    : const <Color>[Color(0xFF25364E), Color(0xFF2F3550)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: Colors.white, size: 38),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        buton(Icons.keyboard_arrow_up_rounded, 0, -1),
        const SizedBox(height: 7),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buton(Icons.keyboard_arrow_left_rounded, -1, 0),
            const SizedBox(width: 80),
            buton(Icons.keyboard_arrow_right_rounded, 1, 0),
          ],
        ),
        const SizedBox(height: 7),
        buton(Icons.keyboard_arrow_down_rounded, 0, 1),
      ],
    );
  }
}

List<Hucre>? enKisaYolBul({
  required LabirentSeviyesi seviye,
  required int baslangicX,
  required int baslangicY,
  int? hedefX,
  int? hedefY,
}) {
  const int satirSayisi = 6;
  const int sutunSayisi = 6;

  final int hedefKonumX = hedefX ?? seviye.hedefX;
  final int hedefKonumY = hedefY ?? seviye.hedefY;

  final Hucre baslangic = Hucre(baslangicX, baslangicY);

  final Queue<List<Hucre>> kuyruk = Queue<List<Hucre>>();

  final Set<String> ziyaretEdildi = {};

  kuyruk.add([baslangic]);

  ziyaretEdildi.add('$baslangicX-$baslangicY');

  const List<List<int>> yonler = [
    [1, 0],
    [-1, 0],
    [0, 1],
    [0, -1],
  ];

  while (kuyruk.isNotEmpty) {
    final List<Hucre> yol = kuyruk.removeFirst();

    final Hucre mevcut = yol.last;

    if (mevcut.x == hedefKonumX && mevcut.y == hedefKonumY) {
      return yol;
    }

    for (final yon in yonler) {
      final int yeniX = mevcut.x + yon[0];

      final int yeniY = mevcut.y + yon[1];

      if (yeniX < 0 ||
          yeniX >= sutunSayisi ||
          yeniY < 0 ||
          yeniY >= satirSayisi) {
        continue;
      }

      if (seviye.engeller.contains('$yeniX-$yeniY')) {
        continue;
      }

      final String anahtar = '$yeniX-$yeniY';

      if (ziyaretEdildi.contains(anahtar)) {
        continue;
      }

      ziyaretEdildi.add(anahtar);

      final List<Hucre> yeniYol = List<Hucre>.from(yol);

      yeniYol.add(Hucre(yeniX, yeniY));

      kuyruk.add(yeniYol);
    }
  }

  return null;
}

class Hucre {
  final int x;
  final int y;

  const Hucre(this.x, this.y);
}

class _HedefRotasi {
  final List<Hucre> hedefler;
  final List<int> hedefHamleleri;

  const _HedefRotasi({required this.hedefler, required this.hedefHamleleri});
}

class _HedefAdayi {
  final Hucre hucre;
  final int hamleSayisi;

  const _HedefAdayi({required this.hucre, required this.hamleSayisi});
}

class _IlerlemePaneli extends StatelessWidget {
  final int acikSeviye;
  final int toplamYildiz;
  final int toplamPuan;
  final bool darEkran;

  const _IlerlemePaneli({
    required this.acikSeviye,
    required this.toplamYildiz,
    required this.toplamPuan,
    required this.darEkran,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(darEkran ? 14 : 18),
      decoration: BoxDecoration(
        color: StudioVisuals.surface,
        borderRadius: StudioVisuals.cardRadius,
        border: Border.all(color: StudioVisuals.line),
        boxShadow: StudioVisuals.softShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: darEkran ? 42 : 52,
                height: darEkran ? 42 : 52,
                decoration: const BoxDecoration(
                  color: StudioVisuals.tealSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.extension_rounded,
                  size: darEkran ? 24 : 29,
                  color: StudioVisuals.teal,
                ),
              ),
              SizedBox(width: darEkran ? 8 : 12),
              Expanded(
                child: LText(
                  'ZİHİN YOLCULUĞU',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: StudioVisuals.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: darEkran ? 15 : 17,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: LText(
                    '$toplamPuan',
                    style: TextStyle(
                      color: StudioVisuals.amber,
                      fontWeight: FontWeight.w900,
                      fontSize: darEkran ? 17 : 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: StudioVisuals.amber),
                    const SizedBox(width: 5),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: LText(
                          '$toplamYildiz / 30',
                          style: const TextStyle(color: StudioVisuals.muted),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: LText(
                    'Seviye $acikSeviye / 10',
                    style: const TextStyle(color: StudioVisuals.muted),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SeviyeKarti extends StatelessWidget {
  final LabirentSeviyesi seviye;
  final bool acik;
  final int yildiz;
  final int enIyiPuan;
  final VoidCallback onTap;

  const _SeviyeKarti({
    required this.seviye,
    required this.acik,
    required this.yildiz,
    required this.enIyiPuan,
    required this.onTap,
  });

  Color renk() {
    switch (seviye.zorluk) {
      case 'KOLAY':
        return const Color(0xFF43CC54);
      case 'ORTA':
        return const Color(0xFFFFB020);
      case 'ZOR':
        return const Color(0xFFFF5252);
      case 'BOSS':
        return const Color(0xFFE040FB);
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color anaRenk = renk();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: acik ? onTap : null,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: acik ? StudioVisuals.surface : StudioVisuals.surfaceSoft,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: acik
                  ? anaRenk.withValues(alpha: 0.42)
                  : StudioVisuals.line,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  LText(
                    acik ? '${seviye.numara}' : '🔒',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  if (acik)
                    LText(
                      seviye.zorluk,
                      style: TextStyle(
                        color: anaRenk,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Icon(
                seviye.zorluk == 'BOSS'
                    ? Icons.local_fire_department_rounded
                    : Icons.route_rounded,
                color: acik ? anaRenk : StudioVisuals.line,
                size: 22,
              ),
              const SizedBox(height: 3),
              LText(
                seviye.baslik,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: acik ? StudioVisuals.ink : StudioVisuals.muted,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              if (enIyiPuan > 0)
                LText(
                  'En iyi: $enIyiPuan',
                  style: const TextStyle(
                    color: StudioVisuals.muted,
                    fontSize: 8,
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (index) => Icon(
                    index < yildiz
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: acik ? StudioVisuals.amber : StudioVisuals.line,
                    size: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabirentDuvari extends StatelessWidget {
  final Color anaRenk;
  final bool bombali;
  final bool patliyor;
  final int patlamaToken;

  const _LabirentDuvari({
    required this.anaRenk,
    required this.bombali,
    required this.patliyor,
    required this.patlamaToken,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.isEnglish
          ? bombali
                ? 'Wall with a bomb'
                : 'Closed wall'
          : bombali
          ? 'Bombalı duvar'
          : 'Kapalı duvar',
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: <Widget>[
          CustomPaint(painter: _LabirentDuvarPainter(anaRenk)),
          if (bombali)
            const Center(
              child: FractionallySizedBox(
                widthFactor: 0.64,
                heightFactor: 0.64,
                child: CustomPaint(painter: _LabirentBombaPainter()),
              ),
            ),
          if (patliyor)
            Positioned.fill(
              child: IgnorePointer(
                child: _BombaPatlamaEfekti(token: patlamaToken),
              ),
            ),
        ],
      ),
    );
  }
}

class _LabirentKasifi extends StatelessWidget {
  const _LabirentKasifi();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.isEnglish ? 'Mind explorer' : 'Zekâ kâşifi',
      child: SizedBox(
        width: 38,
        height: 38,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Color(0xFF00C8FF), Color(0xFF7357FF)],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.7),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: const Color(0xFF00C8FF).withValues(alpha: 0.42),
                    blurRadius: 11,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.psychology_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD334),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF07162E), width: 2),
                ),
                child: const Icon(
                  Icons.explore_rounded,
                  color: Color(0xFF372500),
                  size: 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BombaPatlamaEfekti extends StatelessWidget {
  final int token;

  const _BombaPatlamaEfekti({required this.token});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey<int>(token),
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 560),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double ilerleme, Widget? child) {
        return CustomPaint(painter: _LabirentPatlamaPainter(ilerleme));
      },
    );
  }
}

class _LabirentDuvarPainter extends CustomPainter {
  final Color anaRenk;

  const _LabirentDuvarPainter(this.anaRenk);

  @override
  void paint(Canvas canvas, Size size) {
    final RRect disSinir = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(9),
    );

    canvas.save();
    canvas.clipRRect(disSinir);

    final Paint zemin = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color.lerp(anaRenk, Colors.white, 0.22)!,
          anaRenk,
          Color.lerp(anaRenk, Colors.black, 0.32)!,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(disSinir, zemin);

    const int satir = 3;
    final double harc = max(1.2, size.shortestSide * 0.035);
    final double yukseklik = (size.height - harc * (satir + 1)) / satir;
    final double genislik = size.width * 0.54;
    final Paint tugla = Paint()..style = PaintingStyle.fill;
    final Paint kenar = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(0.8, size.shortestSide * 0.022)
      ..color = Colors.white.withValues(alpha: 0.17);

    for (int y = 0; y < satir; y++) {
      final double ust = harc + y * (yukseklik + harc);
      double sol = y.isOdd ? -genislik * 0.48 : harc;
      int parca = 0;

      while (sol < size.width) {
        final Rect rect = Rect.fromLTWH(sol, ust, genislik - harc, yukseklik);
        final RRect tuglaSiniri = RRect.fromRectAndRadius(
          rect,
          Radius.circular(max(1.5, size.shortestSide * 0.06)),
        );
        tugla.color = Color.lerp(
          anaRenk,
          parca.isEven ? Colors.white : Colors.black,
          parca.isEven ? 0.10 : 0.08,
        )!;
        canvas.drawRRect(tuglaSiniri, tugla);
        canvas.drawRRect(tuglaSiniri, kenar);
        sol += genislik;
        parca++;
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LabirentDuvarPainter oldDelegate) {
    return oldDelegate.anaRenk != anaRenk;
  }
}

class _LabirentBombaPainter extends CustomPainter {
  const _LabirentBombaPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double yaricap = size.shortestSide * 0.30;
    final Offset merkez = Offset(size.width * 0.48, size.height * 0.60);

    canvas.drawCircle(
      merkez,
      yaricap * 1.18,
      Paint()..color = const Color(0xFFFF3B45).withValues(alpha: 0.24),
    );

    final Rect bombaAlani = Rect.fromCircle(center: merkez, radius: yaricap);
    final Paint bomba = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.35, -0.40),
        colors: <Color>[Color(0xFF5A6070), Color(0xFF11141B), Colors.black],
        stops: <double>[0, 0.48, 1],
      ).createShader(bombaAlani);
    canvas.drawCircle(merkez, yaricap, bomba);

    canvas.drawCircle(
      merkez,
      yaricap,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.0, size.shortestSide * 0.055)
        ..color = Colors.white.withValues(alpha: 0.32),
    );

    final Path fitil = Path()
      ..moveTo(merkez.dx + yaricap * 0.42, merkez.dy - yaricap * 0.76)
      ..quadraticBezierTo(
        merkez.dx + yaricap * 0.95,
        merkez.dy - yaricap * 1.18,
        merkez.dx + yaricap * 0.82,
        merkez.dy - yaricap * 1.52,
      );
    canvas.drawPath(
      fitil,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = max(1.4, size.shortestSide * 0.085)
        ..color = const Color(0xFF4A2A13),
    );

    final Offset kivilcim = Offset(
      merkez.dx + yaricap * 0.82,
      merkez.dy - yaricap * 1.52,
    );
    canvas.drawCircle(
      kivilcim,
      max(1.8, size.shortestSide * 0.10),
      Paint()..color = const Color(0xFFFFD334),
    );
    canvas.drawCircle(
      kivilcim,
      max(1.0, size.shortestSide * 0.055),
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _LabirentBombaPainter oldDelegate) => false;
}

class _LabirentPatlamaPainter extends CustomPainter {
  final double ilerleme;

  const _LabirentPatlamaPainter(this.ilerleme);

  @override
  void paint(Canvas canvas, Size size) {
    final Offset merkez = size.center(Offset.zero);
    final double temel = size.shortestSide;
    final double gorunurluk = (1 - ilerleme).clamp(0.0, 1.0);
    final double dalga = sin(ilerleme * pi);

    canvas.drawCircle(
      merkez,
      temel * (0.16 + ilerleme * 0.48),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.5, temel * 0.075 * gorunurluk)
        ..color = const Color(0xFFFFD334).withValues(alpha: 0.82 * gorunurluk),
    );

    canvas.drawCircle(
      merkez,
      temel * (0.13 + dalga * 0.24),
      Paint()
        ..color = const Color(0xFFFF4B2B).withValues(alpha: 0.72 * gorunurluk),
    );

    final Paint isin = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = max(1.2, temel * 0.055)
      ..color = const Color(0xFFFFB020).withValues(alpha: 0.90 * gorunurluk);

    for (int i = 0; i < 10; i++) {
      final double aci = (pi * 2 * i / 10) + ilerleme * 0.35;
      final Offset yon = Offset(cos(aci), sin(aci));
      final Offset baslangic = merkez + yon * temel * 0.18;
      final Offset bitis = merkez + yon * temel * (0.28 + ilerleme * 0.34);
      canvas.drawLine(baslangic, bitis, isin);
    }

    final Paint duman = Paint()
      ..color = const Color(0xFF202631).withValues(alpha: 0.48 * gorunurluk);
    for (int i = 0; i < 4; i++) {
      final double aci = pi * 2 * i / 4 + 0.45;
      final Offset konum =
          merkez +
          Offset(cos(aci), sin(aci)) * temel * (0.12 + ilerleme * 0.18);
      canvas.drawCircle(konum, temel * (0.06 + ilerleme * 0.04), duman);
    }
  }

  @override
  bool shouldRepaint(covariant _LabirentPatlamaPainter oldDelegate) {
    return oldDelegate.ilerleme != ilerleme;
  }
}

class _OyunBilgiPaneli extends StatelessWidget {
  final int tamamlananHedef;
  final int toplamHedef;
  final int hamle;
  final int hedefHamle;
  final int can;

  const _OyunBilgiPaneli({
    required this.tamamlananHedef,
    required this.toplamHedef,
    required this.hamle,
    required this.hedefHamle,
    required this.can,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _BilgiKutusu(
            baslik: 'HEDEF',
            deger: '$tamamlananHedef/$toplamHedef',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _BilgiKutusu(baslik: 'HAMLE', deger: '$hamle'),
        ),
        const SizedBox(width: 8),
        Expanded(child: _CanGostergesi(can: can)),
        const SizedBox(width: 8),
        Expanded(
          child: _BilgiKutusu(baslik: '3 ⭐ HEDEF', deger: '$hedefHamle'),
        ),
      ],
    );
  }
}

class _CanGostergesi extends StatelessWidget {
  final int can;

  const _CanGostergesi({required this.can});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: ZpVisualPalette.of(context).surface,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        children: <Widget>[
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List<Widget>.generate(3, (int index) {
                final bool dolu = index < can;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 180),
                    scale: dolu ? 1 : 0.82,
                    child: Icon(
                      dolu ? Icons.favorite_rounded : Icons.favorite_border,
                      color: dolu
                          ? const Color(0xFFFF5C66)
                          : Theme.of(context).colorScheme.outlineVariant,
                      size: 16,
                    ),
                  ),
                );
              }),
            ),
          ),
          LText(
            'CAN',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _HedefIsareti extends StatelessWidget {
  final int sira;
  final int toplam;

  const _HedefIsareti({required this.sira, required this.toplam});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        const Icon(Icons.star_rounded, color: Color(0xFFFFD334), size: 38),
        Positioned(
          right: -5,
          top: -5,
          child: Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF1D65FF),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: LText(
              '$sira/$toplam',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 7,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BilgiKutusu extends StatelessWidget {
  final String baslik;
  final String deger;

  const _BilgiKutusu({required this.baslik, required this.deger});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: ZpVisualPalette.of(context).surface,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        children: [
          LText(
            deger,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          LText(
            baslik,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _SonucKutusu extends StatelessWidget {
  final String baslik;
  final String deger;
  final IconData ikon;

  const _SonucKutusu({
    required this.baslik,
    required this.deger,
    required this.ikon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(ikon, color: const Color(0xFFFFD334)),
          const SizedBox(height: 5),
          LText(
            deger,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          LText(
            baslik,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class LabirentSeviyesi {
  final int numara;
  final String baslik;
  final String zorluk;

  final int oyuncuX;
  final int oyuncuY;

  final int hedefX;
  final int hedefY;

  final Set<String> engeller;

  const LabirentSeviyesi({
    required this.numara,
    required this.baslik,
    required this.zorluk,
    required this.oyuncuX,
    required this.oyuncuY,
    required this.hedefX,
    required this.hedefY,
    required this.engeller,
  });
}

class SeviyeSonucu {
  final bool tamamlandi;
  final int yildiz;
  final int puan;
  final bool sonrakiSeviye;

  const SeviyeSonucu({
    required this.tamamlandi,
    required this.yildiz,
    required this.puan,
    required this.sonrakiSeviye,
  });
}
