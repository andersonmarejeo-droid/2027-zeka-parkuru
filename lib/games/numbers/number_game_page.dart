import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/advanced_result_banner.dart';

import '../../services/local_progress_service.dart';
import '../../services/daily_challenge_service.dart';
import '../../services/daily_course_service.dart';
import '../../services/game_audio_service.dart';
import '../../services/replayability_service.dart';
import '../../services/unified_progress_service.dart';
import '../../theme/app_visual_theme.dart';

class NumberGamePage extends StatefulWidget {
  final ParkurProgressData? initialProgress;
  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  const NumberGamePage({
    super.key,
    this.initialProgress,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  @override
  State<NumberGamePage> createState() => _NumberGamePageState();
}

class _NumberGamePageState extends State<NumberGamePage> {
  final LocalProgressService _progressService = LocalProgressService();
  final GameAudioService _audio = GameAudioService.instance;

  bool yukleniyor = true;
  int acikSeviye = 1;

  List<int> yildizlar = List<int>.filled(10, 0);
  List<int> enIyiPuanlar = List<int>.filled(10, 0);
  bool _competitionOpened = false;

  final List<SayiSeviyesi> seviyeler = [
    SayiSeviyesi(
      numara: 1,
      baslik: 'Eksik Sayı',
      tur: 'EKSİK SAYI',
      zorluk: 'KOLAY',
      oturumSoruSayisi: 6,
      sorular: [
        SayiSorusu(
          soru: '2, 4, 6, ?, 10',
          secenekler: [7, 8, 9, 12],
          dogruCevap: 8,
        ),
        SayiSorusu(
          soru: '5, 10, 15, ?, 25',
          secenekler: [18, 20, 22, 30],
          dogruCevap: 20,
        ),
        SayiSorusu(
          soru: '1, 3, 5, ?, 9',
          secenekler: [6, 7, 8, 10],
          dogruCevap: 7,
        ),
      ],
    ),
    SayiSeviyesi(
      numara: 2,
      baslik: 'Dönüşümlü Adımlar',
      tur: 'ALTERNATİF DİZİ',
      zorluk: 'KOLAY',
      oturumSoruSayisi: 6,
      sorular: [
        SayiSorusu(
          soru: '10, 12, 14, ?, 18',
          secenekler: [15, 16, 17, 20],
          dogruCevap: 16,
        ),
        SayiSorusu(
          soru: '20, 18, 16, ?, 12',
          secenekler: [14, 15, 13, 10],
          dogruCevap: 14,
        ),
        SayiSorusu(
          soru: '3, 6, 9, ?, 15',
          secenekler: [10, 11, 12, 13],
          dogruCevap: 12,
        ),
      ],
    ),
    SayiSeviyesi(
      numara: 3,
      baslik: 'Gizli Desen',
      tur: 'GELİŞMİŞ DİZİ',
      zorluk: 'ORTA',
      oturumSoruSayisi: 7,
      sorular: [
        SayiSorusu(
          soru: '2, 4, 8, ?, 32',
          secenekler: [10, 12, 16, 24],
          dogruCevap: 16,
        ),
        SayiSorusu(
          soru: '1, 4, 9, ?, 25',
          secenekler: [12, 14, 16, 20],
          dogruCevap: 16,
        ),
        SayiSorusu(
          soru: '3, 6, 12, ?, 48',
          secenekler: [18, 20, 24, 36],
          dogruCevap: 24,
        ),
      ],
    ),
    SayiSeviyesi(
      numara: 4,
      baslik: 'İşlem Zinciri',
      tur: 'İŞLEM',
      zorluk: 'ORTA',
      oturumSoruSayisi: 7,
      sorular: [
        SayiSorusu(
          soru: '4 → 8 → 16 → ?',
          secenekler: [20, 24, 30, 32],
          dogruCevap: 32,
        ),
        SayiSorusu(
          soru: '100 → 50 → 25 → ?',
          secenekler: [10, 12, 12.5, 15],
          dogruCevap: 12.5,
        ),
        SayiSorusu(
          soru: '7 → 14 → 21 → ?',
          secenekler: [24, 27, 28, 30],
          dogruCevap: 28,
        ),
      ],
    ),
    SayiSeviyesi(
      numara: 5,
      baslik: 'Sayı Piramidi',
      tur: 'PİRAMİT',
      zorluk: 'ZOR',
      oturumSoruSayisi: 8,
      sorular: [
        SayiSorusu(
          soru: '1 → 2 → 6 → 24 → ?',
          secenekler: [48, 60, 100, 120],
          dogruCevap: 120,
        ),
        SayiSorusu(
          soru: '81 → 27 → 9 → ?',
          secenekler: [1, 2, 3, 6],
          dogruCevap: 3,
        ),
        SayiSorusu(
          soru: '2 → 5 → 11 → 23 → ?',
          secenekler: [35, 41, 45, 47],
          dogruCevap: 47,
        ),
      ],
    ),
    SayiSeviyesi(
      numara: 6,
      baslik: 'Denge Noktası',
      tur: 'DENKLEM',
      zorluk: 'ORTA',
      oturumSoruSayisi: 8,
      sorular: [
        SayiSorusu(
          soru: '10, 20, 30, ?, 50',
          secenekler: [35, 40, 45, 60],
          dogruCevap: 40,
        ),
        SayiSorusu(
          soru: '2, 3, 4, ?, 6',
          secenekler: [5, 7, 8, 9],
          dogruCevap: 5,
        ),
        SayiSorusu(
          soru: '9, 8, 7, ?, 5',
          secenekler: [4, 6, 10, 12],
          dogruCevap: 6,
        ),
      ],
    ),
    SayiSeviyesi(
      numara: 7,
      baslik: 'Sayı Matrisi',
      tur: 'MATRİS',
      zorluk: 'ZOR',
      oturumSoruSayisi: 9,
      sorular: [
        SayiSorusu(
          soru: '8 + 4 × 2 = ?',
          secenekler: [16, 24, 20, 12],
          dogruCevap: 16,
        ),
        SayiSorusu(
          soru: '20 ÷ 4 + 7 = ?',
          secenekler: [10, 12, 14, 17],
          dogruCevap: 12,
        ),
        SayiSorusu(
          soru: '6 × 3 - 5 = ?',
          secenekler: [11, 12, 13, 18],
          dogruCevap: 13,
        ),
      ],
    ),
    SayiSeviyesi(
      numara: 8,
      baslik: 'Sayı Dedektifi',
      tur: 'SINIFLAMA',
      zorluk: 'ZOR',
      oturumSoruSayisi: 9,
      sorular: [
        SayiSorusu(
          soru: '1  2  3\n2  3  1\n3  ?  2',
          secenekler: [1, 2, 3],
          dogruCevap: 1,
          sudokuCevaplari: [1],
        ),
        SayiSorusu(
          soru: '2  3  1\n1  2  ?\n3  1  2',
          secenekler: [1, 2, 3],
          dogruCevap: 3,
          sudokuCevaplari: [3],
        ),
        SayiSorusu(
          soru: '3  1  2\n2  ?  1\n1  2  3',
          secenekler: [1, 2, 3],
          dogruCevap: 3,
          sudokuCevaplari: [3],
        ),
      ],
    ),
    SayiSeviyesi(
      numara: 9,
      baslik: 'Sudoku 4×4',
      tur: 'SUDOKU',
      zorluk: 'ZOR',
      sudokuBoyutu: 4,
      sudokuBoslukSayisi: 4,
      oturumSoruSayisi: 5,
      sorular: [
        SayiSorusu(
          soru: '?  3  1  ?\n1  4  2  3\n4  2  3  1\n?  1  ?  2',
          secenekler: [1, 2, 3, 4],
          dogruCevap: 2,
          sudokuCevaplari: [2, 4, 3, 4],
        ),
        SayiSorusu(
          soru: '3  4  1  2\n1  2  ?  ?\n4  1  2  3\n2  ?  ?  1',
          secenekler: [1, 2, 3, 4],
          dogruCevap: 3,
          sudokuCevaplari: [3, 4, 3, 4],
        ),
        SayiSorusu(
          soru: '3  4  2  ?\n2  1  3  4\n?  2  ?  3\n?  3  4  2',
          secenekler: [1, 2, 3, 4],
          dogruCevap: 1,
          sudokuCevaplari: [1, 4, 1, 1],
        ),
      ],
    ),
    SayiSeviyesi(
      numara: 10,
      baslik: 'Sayı Ustası Finali',
      tur: 'BOSS',
      zorluk: 'BOSS',
      sudokuBoyutu: 5,
      sudokuBoslukSayisi: 7,
      oturumSoruSayisi: 10,
      sorular: [
        SayiSorusu(
          soru: '4  1  3  5  2\n?  ?  ?  ?  5\n2  5  4  3  ?\n5  4  1  ?  3\n3  2  5  ?  4',
          secenekler: [1, 2, 3, 4, 5],
          dogruCevap: 1,
          sudokuCevaplari: [1, 3, 2, 4, 1, 2, 1],
        ),
        SayiSorusu(
          soru: '2  1  ?  3  5\n4  ?  ?  2  ?\n?  4  2  5  1\n5  2  ?  1  4\n?  3  5  4  2',
          secenekler: [1, 2, 3, 4, 5],
          dogruCevap: 4,
          sudokuCevaplari: [4, 5, 1, 3, 3, 3, 1],
        ),
        SayiSorusu(
          soru: '3  2  1  5  4\n4  1  3  2  ?\n?  ?  2  4  ?\n2  ?  5  3  1\n?  3  4  ?  2',
          secenekler: [1, 2, 3, 4, 5],
          dogruCevap: 5,
          sudokuCevaplari: [5, 1, 5, 3, 4, 5, 1],
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();

    final ParkurProgressData? initial = widget.initialProgress;
    if (initial != null) {
      acikSeviye = initial.acikSeviye;
      yildizlar = List<int>.from(initial.yildizlar);
      enIyiPuanlar = List<int>.from(initial.enIyiPuanlar);
      yukleniyor = false;
    }

    unawaited(ilerlemeyiYukle());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      unawaited(_audio.playMusic(GameMusic.calm));
      unawaited(_audio.preload(GameAudioGroup.numbers));
    });
  }

  @override
  void dispose() {
    unawaited(_audio.stopMusic());
    super.dispose();
  }

  Future<void> ilerlemeyiYukle() async {
    final NumberProgressData veri = await _progressService
        .sayiIlerlemesiniYukle();

    if (!mounted) return;

    setState(() {
      acikSeviye = veri.acikSeviye;
      yildizlar = List<int>.from(veri.yildizlar);
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
    await _progressService.sayiIlerlemesiniKaydet(
      acikSeviye: acikSeviye,
      yildizlar: yildizlar,
      enIyiPuanlar: enIyiPuanlar,
    );
  }

  int get toplamYildiz {
    return yildizlar.fold(0, (toplam, deger) => toplam + deger);
  }

  int get toplamPuan {
    return enIyiPuanlar.fold(0, (toplam, deger) => toplam + deger);
  }

  Future<void> seviyeAc(int index) async {
    if (widget.competitionLevel == null && index + 1 > acikSeviye) {
      return;
    }

    GameAudioService.instance.play(GameSound.uiClick);

    final SayiSeviyeSonucu? sonuc = await Navigator.push<SayiSeviyeSonucu>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return SayiOyunEkrani(
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
            ? const DailyStageResult.exited(gameId: 'numbers')
            : sonuc.tamamlandi
            ? DailyStageResult.completed(
                gameId: 'numbers',
                stars: sonuc.yildiz,
                rawScore: sonuc.puan,
              )
            : const DailyStageResult.failed(gameId: 'numbers'),
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
          gameId: 'numbers',
          stars: sonuc.yildiz,
          score: sonuc.puan,
        ),
      );
      return;
    }

    setState(() {
      if (sonuc.yildiz > yildizlar[index]) {
        yildizlar[index] = sonuc.yildiz;
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
      gameId: 'numbers',
      stars: sonuc.yildiz,
      score: sonuc.puan,
    );

    if (!widget.dailyCourseMode && index + 1 == seviyeler.length) {
      await GameAudioService.instance.playMashallahCelebration();
    }

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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LText(
              'SAYI USTASI',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            LText(
              'Sayıların dünyasını fethet',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool darEkran = constraints.maxWidth < 360;
            final double yatayBosluk = darEkran ? 12 : 18;
            final double izgaraBoslugu = darEkran ? 10 : 14;

            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(yatayBosluk),
                  child: _SayiIlerlemePaneli(
                    toplamPuan: toplamPuan,
                    toplamYildiz: toplamYildiz,
                    acikSeviye: acikSeviye,
                    darEkran: darEkran,
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.fromLTRB(
                      yatayBosluk,
                      0,
                      yatayBosluk,
                      30,
                    ),
                    itemCount: seviyeler.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: izgaraBoslugu,
                      mainAxisSpacing: izgaraBoslugu,
                      mainAxisExtent: 165,
                    ),
                    itemBuilder: (context, index) {
                      return _SayiSeviyeKarti(
                        seviye: seviyeler[index],
                        acik: index + 1 <= acikSeviye,
                        yildiz: yildizlar[index],
                        enIyiPuan: enIyiPuanlar[index],
                        onTap: () {
                          seviyeAc(index);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class SayiOyunEkrani extends StatefulWidget {
  final SayiSeviyesi seviye;
  final int toplamSeviye;
  final int previousBestScore;
  final int? fixedSessionSeed;
  final bool competitionMode;

  const SayiOyunEkrani({
    super.key,
    required this.seviye,
    required this.toplamSeviye,
    required this.previousBestScore,
    this.fixedSessionSeed,
    this.competitionMode = false,
  });

  @override
  State<SayiOyunEkrani> createState() => _SayiOyunEkraniState();
}

class _SayiOyunEkraniState extends State<SayiOyunEkrani> {
  final ReplayabilityService _replayability = ReplayabilityService();
  final GameAudioService _audio = GameAudioService.instance;

  int soruIndex = 0;
  int dogruSayisi = 0;
  int yanlisSayisi = 0;
  int dogruSerisi = 0;

  late List<SayiSorusu> oturumSorulari;
  int sessionSeed = 0;

  bool cevapVerildi = false;
  dynamic secilenCevap;
  List<dynamic> sudokuGirilenCevaplar = <dynamic>[];
  int aktifSudokuBosluk = 0;

  bool ipucuKullanildi = false;

  SayiSorusu get mevcutSoru {
    return oturumSorulari[soruIndex];
  }

  @override
  void initState() {
    super.initState();

    // Menüden çok hızlı geçilse bile sayı efektleri hazır olsun.
    unawaited(_audio.preload(GameAudioGroup.numbers));

    if (widget.seviye.zorluk == 'BOSS') {
      _audio.play(GameSound.bossIntro);
    }

    // Ekran ilk çizilirken boş kalmaması için geçici üretim.
    oturumSorulari = _sorulariUret(
      Random(DateTime.now().microsecondsSinceEpoch),
    );
    _sudokuDurumunuSifirla();

    _yeniOturumHazirla();
  }

  Future<void> _yeniOturumHazirla() async {
    sessionSeed =
        widget.fixedSessionSeed ??
        await _replayability.newSeed(
          gameId: 'numbers',
          level: widget.seviye.numara,
        );

    final Random rng = _replayability.randomFor(
      sessionSeed: sessionSeed,
      round: 0,
      salt: 211,
    );

    if (!mounted) return;

    final List<SayiSorusu> nextQuestions = _sorulariUret(rng);
    setState(() {
      oturumSorulari = nextQuestions;
      soruIndex = 0;
      dogruSayisi = 0;
      yanlisSayisi = 0;
      dogruSerisi = 0;
      cevapVerildi = false;
      secilenCevap = null;
      _sudokuDurumunuSifirla();
      ipucuKullanildi = false;
    });
    if (widget.fixedSessionSeed == null) {
      unawaited(
        _replayability.registerFingerprint(
          gameId: 'numbers',
          level: widget.seviye.numara,
          fingerprint: nextQuestions
              .map(
                (SayiSorusu question) =>
                    '${question.soru}:${question.dogruCevap}',
              )
              .join('|'),
          historyLimit: 250,
        ),
      );
    }
  }

  List<SayiSorusu> _sorulariUret(Random rng) {
    // Bölüm sayısı değişmeden, her seviyenin kendi oturum uzunluğu kullanılır.
    final int adet = widget.seviye.oturumSoruSayisi;

    if (widget.seviye.tur == 'SUDOKU') {
      return _benzersizSorularUret(
        adet: adet,
        uret: () => _miniSudokuUret(
          rng,
          boyut: widget.seviye.sudokuBoyutu ?? 3,
          boslukSayisi: widget.seviye.sudokuBoslukSayisi,
        ),
      );
    }

    if (widget.seviye.tur == 'EKSİK SAYI') {
      return _benzersizSorularUret(adet: adet, uret: () => _eksikSayiUret(rng));
    }

    if (widget.seviye.tur == 'ALTERNATİF DİZİ') {
      return _benzersizSorularUret(
        adet: adet,
        uret: () => _alternatifDiziUret(rng),
      );
    }

    if (widget.seviye.tur == 'GELİŞMİŞ DİZİ') {
      return _benzersizSorularUret(
        adet: adet,
        uret: () => _gelismisDiziUret(rng),
      );
    }

    if (widget.seviye.tur == 'ZİNCİR') {
      return _benzersizSorularUret(adet: adet, uret: () => _zincirUret(rng));
    }

    if (widget.seviye.tur == 'İŞLEM') {
      return _benzersizSorularUret(adet: adet, uret: () => _islemUret(rng));
    }

    if (widget.seviye.tur == 'PİRAMİT') {
      return _benzersizSorularUret(
        adet: adet,
        uret: () => _sayiPiramidiUret(rng),
      );
    }

    if (widget.seviye.tur == 'DENKLEM') {
      return _benzersizSorularUret(adet: adet, uret: () => _denklemUret(rng));
    }

    if (widget.seviye.tur == 'MATRİS') {
      return _benzersizSorularUret(
        adet: adet,
        uret: () => _sayiMatrisiUret(rng),
      );
    }

    if (widget.seviye.tur == 'SINIFLAMA') {
      return _benzersizSorularUret(
        adet: adet,
        uret: () => _siniflandirmaUret(rng),
      );
    }

    if (widget.seviye.tur == 'BOSS') {
      final List<SayiSorusu Function()> ureticiler = <SayiSorusu Function()>[
        () => _gelismisDiziUret(rng),
        () => _alternatifDiziUret(rng, zor: true),
        () => _islemUret(rng, zor: true),
        () => _sayiPiramidiUret(rng, zor: true),
        () => _denklemUret(rng, zor: true),
        () => _sayiMatrisiUret(rng, zor: true),
        () => _siniflandirmaUret(rng, zor: true),
        () => _miniSudokuUret(rng, boyut: 4, boslukSayisi: 4),
        () => _zincirUret(rng, zor: true),
        () => _eksikSayiUret(rng, zor: true),
      ]..shuffle(rng);
      final List<SayiSorusu> havuz = ureticiler
          .take(adet)
          .map((uret) => uret())
          .toList();
      havuz.shuffle(rng);
      return havuz;
    }

    final List<SayiSorusu> kopya = List<SayiSorusu>.from(widget.seviye.sorular);
    kopya.shuffle(rng);
    return kopya;
  }

  List<SayiSorusu> _benzersizSorularUret({
    required int adet,
    required SayiSorusu Function() uret,
  }) {
    final List<SayiSorusu> sonuc = <SayiSorusu>[];
    final Set<String> kullanilanSorular = <String>{};
    int deneme = 0;
    final int denemeSiniri = adet * 40;

    while (sonuc.length < adet && deneme < denemeSiniri) {
      deneme++;
      final SayiSorusu soru = uret();
      final String imza = soru.soru;

      if (kullanilanSorular.add(imza)) {
        sonuc.add(soru);
      }
    }

    while (sonuc.length < adet) {
      sonuc.add(uret());
    }

    return sonuc;
  }

  SayiSorusu _eksikSayiUret(Random rng, {bool zor = false}) {
    final int baslangic = 1 + rng.nextInt(zor ? 18 : 12);
    final int adim = 1 + rng.nextInt(zor ? 8 : 5);
    final bool azalan = rng.nextBool() && baslangic + adim * 4 <= 50;

    final List<int> dizi = List<int>.generate(
      5,
      (i) => azalan ? baslangic + adim * (4 - i) : baslangic + adim * i,
    );

    final int bosIndex = 1 + rng.nextInt(3);
    final int dogru = dizi[bosIndex];

    final List<int> yanlislar = <int>{
      dogru + adim,
      dogru - adim,
      dogru + (adim == 1 ? 2 : 1),
      dogru + adim * 2,
    }.where((e) => e >= 0 && e != dogru).toList();

    while (yanlislar.length < 3) {
      final int aday = dogru + rng.nextInt(9) - 4;
      if (aday >= 0 && aday != dogru && !yanlislar.contains(aday)) {
        yanlislar.add(aday);
      }
    }

    final List<dynamic> secenekler = [dogru, ...yanlislar.take(3)];
    secenekler.shuffle(rng);

    final List<String> gorunen = dizi
        .asMap()
        .entries
        .map((e) => e.key == bosIndex ? '?' : '${e.value}')
        .toList();

    return SayiSorusu(
      soru: gorunen.join(', '),
      secenekler: secenekler,
      dogruCevap: dogru,
      aciklamaTr:
          'Her adımda ${azalan ? '−' : '+'}$adim uygulanıyor. Eksik sayı $dogru.',
      aciklamaEn:
          'Each step applies ${azalan ? '−' : '+'}$adim. The missing number is $dogru.',
    );
  }

  SayiSorusu _alternatifDiziUret(Random rng, {bool zor = false}) {
    final int baslangic = 2 + rng.nextInt(zor ? 18 : 10);
    final int ilkAdim = 1 + rng.nextInt(zor ? 7 : 4);
    int ikinciAdim = 1 + rng.nextInt(zor ? 8 : 5);
    if (ikinciAdim == ilkAdim) ikinciAdim++;

    final List<int> dizi = <int>[baslangic];
    for (int index = 0; index < 5; index++) {
      final int adim = index.isEven ? ilkAdim : ikinciAdim;
      dizi.add(dizi.last + adim);
    }

    final int bosIndex = 2 + rng.nextInt(3);
    final int dogru = dizi[bosIndex];
    final List<dynamic> secenekler = _sayiSecenekleri(
      rng,
      dogru: dogru,
      sapmalar: <int>[ilkAdim, ikinciAdim, ilkAdim + ikinciAdim, 1],
    );
    final List<String> gorunen = dizi
        .asMap()
        .entries
        .map((entry) => entry.key == bosIndex ? '?' : '${entry.value}')
        .toList(growable: false);

    return SayiSorusu(
      soru: gorunen.join(', '),
      secenekler: secenekler,
      dogruCevap: dogru,
      aciklamaTr: 'Adımlar sırayla +$ilkAdim ve +$ikinciAdim olarak dönüşüyor.',
      aciklamaEn: 'The steps alternate between +$ilkAdim and +$ikinciAdim.',
    );
  }

  SayiSorusu _gelismisDiziUret(Random rng) {
    final int tip = rng.nextInt(4);
    late List<int> dizi;
    late String aciklamaTr;
    late String aciklamaEn;

    if (tip == 0) {
      final int baslangic = 1 + rng.nextInt(4);
      final int carpan = 2 + rng.nextInt(2);
      dizi = List<int>.generate(
        6,
        (index) => baslangic * pow(carpan, index).toInt(),
      );
      aciklamaTr = 'Her sayı $carpan ile çarpılıyor.';
      aciklamaEn = 'Each number is multiplied by $carpan.';
    } else if (tip == 1) {
      final int kaydirma = rng.nextInt(4);
      dizi = List<int>.generate(
        6,
        (index) => pow(index + 1, 2).toInt() + kaydirma,
      );
      aciklamaTr = 'Dizi ardışık sayıların karelerine $kaydirma ekliyor.';
      aciklamaEn = 'The sequence adds $kaydirma to consecutive squares.';
    } else if (tip == 2) {
      final int baslangic = 1 + rng.nextInt(3);
      dizi = <int>[baslangic, baslangic + 1];
      while (dizi.length < 6) {
        dizi.add(dizi[dizi.length - 1] + dizi[dizi.length - 2]);
      }
      aciklamaTr = 'Her sayı kendinden önceki iki sayının toplamıdır.';
      aciklamaEn = 'Each number is the sum of the previous two.';
    } else {
      final int baslangic = 2 + rng.nextInt(5);
      dizi = <int>[baslangic];
      for (int index = 1; index < 6; index++) {
        dizi.add(dizi.last + index + 1);
      }
      aciklamaTr = 'Artış miktarı her adımda 1 büyüyor.';
      aciklamaEn = 'The increase grows by 1 at each step.';
    }

    final int bosIndex = 2 + rng.nextInt(3);
    final int dogru = dizi[bosIndex];
    final List<String> gorunen = dizi
        .asMap()
        .entries
        .map((entry) => entry.key == bosIndex ? '?' : '${entry.value}')
        .toList(growable: false);

    return SayiSorusu(
      soru: gorunen.join(', '),
      secenekler: _sayiSecenekleri(
        rng,
        dogru: dogru,
        sapmalar: <int>[1, 2, max(3, dogru ~/ 3), max(4, dogru ~/ 2)],
      ),
      dogruCevap: dogru,
      aciklamaTr: '$aciklamaTr Eksik sayı $dogru.',
      aciklamaEn: '$aciklamaEn The missing number is $dogru.',
    );
  }

  SayiSorusu _zincirUret(Random rng, {bool zor = false}) {
    final int tip = rng.nextInt(zor ? 4 : 3);
    late List<int> dizi;

    if (tip == 0) {
      final int bas = 1 + rng.nextInt(8);
      final int artis = 2 + rng.nextInt(zor ? 8 : 5);
      dizi = List<int>.generate(5, (i) => bas + artis * i);
    } else if (tip == 1) {
      final int bas = 1 + rng.nextInt(5);
      final int carp = 2 + rng.nextInt(zor ? 3 : 2);
      dizi = List<int>.generate(5, (i) => bas * pow(carp, i).toInt());
    } else if (tip == 2) {
      final int bas = 2 + rng.nextInt(6);
      dizi = [bas];
      for (int i = 1; i < 5; i++) {
        dizi.add(dizi.last * 2 + 1);
      }
    } else {
      final int bas = 2 + rng.nextInt(5);
      dizi = [bas];
      for (int i = 1; i < 5; i++) {
        dizi.add(dizi.last * 2 + i);
      }
    }

    final int dogru = dizi.last;
    final List<int> yanlislar = <int>{
      dogru + 2,
      dogru - 2,
      dogru + (dizi[3] - dizi[2]),
      dogru + 5,
    }.where((e) => e > 0 && e != dogru).toList();

    while (yanlislar.length < 3) {
      final int aday = max(1, dogru + rng.nextInt(15) - 7);
      if (aday != dogru && !yanlislar.contains(aday)) {
        yanlislar.add(aday);
      }
    }

    final List<dynamic> secenekler = [dogru, ...yanlislar.take(3)];
    secenekler.shuffle(rng);

    return SayiSorusu(
      soru: '${dizi.take(4).join(' → ')} → ?',
      secenekler: secenekler,
      dogruCevap: dogru,
      aciklamaTr: 'Aynı işlem zinciri sürdürülünce sonuç $dogru olur.',
      aciklamaEn: 'Continuing the same operation chain gives $dogru.',
    );
  }

  SayiSorusu _islemUret(Random rng, {bool zor = false}) {
    final int a = 2 + rng.nextInt(zor ? 18 : 10);
    final int b = 2 + rng.nextInt(zor ? 9 : 7);
    final int c = 1 + rng.nextInt(zor ? 9 : 6);
    final int tip = rng.nextInt(3);

    late String soru;
    late int dogru;

    if (tip == 0) {
      dogru = a + b * c;
      soru = '$a + $b × $c = ?';
    } else if (tip == 1) {
      dogru = a * b - c;
      soru = '$a × $b - $c = ?';
    } else {
      dogru = (a + b) * c;
      soru = '($a + $b) × $c = ?';
    }

    final List<int> yanlislar = <int>{
      dogru + c,
      max(0, dogru - c),
      dogru + b,
      dogru + 2,
    }.where((e) => e != dogru).toList();

    while (yanlislar.length < 3) {
      final int aday = max(0, dogru + rng.nextInt(13) - 6);
      if (aday != dogru && !yanlislar.contains(aday)) {
        yanlislar.add(aday);
      }
    }

    final List<dynamic> secenekler = [dogru, ...yanlislar.take(3)];
    secenekler.shuffle(rng);

    return SayiSorusu(
      soru: soru,
      secenekler: secenekler,
      dogruCevap: dogru,
      aciklamaTr:
          'İşlem önceliği ve parantez sırası uygulandığında sonuç $dogru.',
      aciklamaEn: 'Using operation precedence and parentheses gives $dogru.',
    );
  }

  SayiSorusu _sayiPiramidiUret(Random rng, {bool zor = false}) {
    final int alt1 = 1 + rng.nextInt(zor ? 12 : 8);
    final int alt2 = 1 + rng.nextInt(zor ? 12 : 8);
    final int alt3 = 1 + rng.nextInt(zor ? 12 : 8);
    final int orta1 = alt1 + alt2;
    final int orta2 = alt2 + alt3;
    final int tepe = orta1 + orta2;
    final int tip = rng.nextInt(3);

    late String soru;
    late int dogru;
    if (tip == 0) {
      soru = '      ?\n   $orta1     $orta2\n$alt1     $alt2     $alt3';
      dogru = tepe;
    } else if (tip == 1) {
      soru = '      $tepe\n   ?     $orta2\n$alt1     $alt2     $alt3';
      dogru = orta1;
    } else {
      soru = '      $tepe\n   $orta1     ?\n$alt1     $alt2     $alt3';
      dogru = orta2;
    }

    return SayiSorusu(
      soru: soru,
      secenekler: _sayiSecenekleri(
        rng,
        dogru: dogru,
        sapmalar: <int>[alt1, alt2, alt3, max(1, dogru ~/ 2)],
      ),
      dogruCevap: dogru,
      aciklamaTr:
          'Her üst kutu altındaki iki komşu kutunun toplamıdır. Cevap $dogru.',
      aciklamaEn:
          'Each upper box is the sum of the two adjacent boxes below. The answer is $dogru.',
    );
  }

  SayiSorusu _denklemUret(Random rng, {bool zor = false}) {
    final int bilinmeyen = 2 + rng.nextInt(zor ? 14 : 9);
    final int carpan = 2 + rng.nextInt(zor ? 8 : 5);
    final int ek = 1 + rng.nextInt(zor ? 15 : 8);
    final bool cikar = rng.nextBool();
    final int sonuc = cikar
        ? bilinmeyen * carpan - ek
        : bilinmeyen * carpan + ek;
    final String isaret = cikar ? '−' : '+';

    return SayiSorusu(
      soru: '$carpan × □ $isaret $ek = $sonuc\n□ = ?',
      secenekler: _sayiSecenekleri(
        rng,
        dogru: bilinmeyen,
        sapmalar: <int>[1, 2, carpan, max(1, ek ~/ 2)],
      ),
      dogruCevap: bilinmeyen,
      aciklamaTr:
          'Önce $ek ${cikar ? 'eklenir' : 'çıkarılır'}, sonra $carpan sayısına bölünür. □ = $bilinmeyen.',
      aciklamaEn:
          'First ${cikar ? 'add' : 'subtract'} $ek, then divide by $carpan. □ = $bilinmeyen.',
    );
  }

  SayiSorusu _sayiMatrisiUret(Random rng, {bool zor = false}) {
    final int tip = rng.nextInt(3);
    final List<List<int>> satirlar = <List<int>>[];
    for (int satir = 0; satir < 3; satir++) {
      final int a = 1 + rng.nextInt(zor ? 12 : 8);
      final int b = 1 + rng.nextInt(zor ? 10 : 7);
      final int c = switch (tip) {
        0 => a + b,
        1 => a * 2 + b,
        _ => a * b,
      };
      satirlar.add(<int>[a, b, c]);
    }

    final int dogru = satirlar.last.last;
    final String soru = <String>[
      '${satirlar[0][0]}   ${satirlar[0][1]}   ${satirlar[0][2]}',
      '${satirlar[1][0]}   ${satirlar[1][1]}   ${satirlar[1][2]}',
      '${satirlar[2][0]}   ${satirlar[2][1]}   ?',
    ].join('\n');
    final String kuralTr = switch (tip) {
      0 => 'Üçüncü sayı ilk iki sayının toplamıdır.',
      1 => 'Üçüncü sayı, ilk sayının iki katına ikinci sayı eklenerek bulunur.',
      _ => 'Üçüncü sayı ilk iki sayının çarpımıdır.',
    };
    final String kuralEn = switch (tip) {
      0 => 'The third number is the sum of the first two.',
      1 => 'The third number is twice the first plus the second.',
      _ => 'The third number is the product of the first two.',
    };

    return SayiSorusu(
      soru: soru,
      secenekler: _sayiSecenekleri(
        rng,
        dogru: dogru,
        sapmalar: <int>[1, 2, satirlar.last.first, satirlar.last[1]],
      ),
      dogruCevap: dogru,
      aciklamaTr: '$kuralTr Cevap $dogru.',
      aciklamaEn: '$kuralEn The answer is $dogru.',
    );
  }

  SayiSorusu _siniflandirmaUret(Random rng, {bool zor = false}) {
    final int tip = rng.nextInt(3);
    late List<int> degerler;
    late int dogru;
    late String aciklamaTr;
    late String aciklamaEn;

    if (tip == 0) {
      final int carpan = 2 + rng.nextInt(zor ? 7 : 4);
      degerler = List<int>.generate(4, (index) => carpan * (index + 2));
      dogru = degerler.last + 1;
      degerler[rng.nextInt(degerler.length)] = dogru;
      aciklamaTr = '$dogru, $carpan sayısının katı değildir.';
      aciklamaEn = '$dogru is not a multiple of $carpan.';
    } else if (tip == 1) {
      const List<int> asalHavuzu = <int>[2, 3, 5, 7, 11, 13, 17, 19, 23, 29];
      degerler = List<int>.from(asalHavuzu)..shuffle(rng);
      degerler = degerler.take(4).toList(growable: true);
      dogru = <int>[9, 15, 21, 25, 27][rng.nextInt(5)];
      degerler[rng.nextInt(degerler.length)] = dogru;
      aciklamaTr =
          '$dogru asal değildir; diğerlerinin yalnız iki böleni vardır.';
      aciklamaEn = '$dogru is not prime; the others have exactly two divisors.';
    } else {
      final bool ciftler = rng.nextBool();
      final int bas = 2 + rng.nextInt(8);
      degerler = List<int>.generate(4, (index) {
        final int aday = bas + index * 2;
        return aday.isEven == ciftler ? aday : aday + 1;
      });
      dogru = degerler.last + 1;
      degerler[rng.nextInt(degerler.length)] = dogru;
      aciklamaTr = '$dogru, diğer sayıların tek/çift özelliğini taşımaz.';
      aciklamaEn = '$dogru does not share the odd/even property of the others.';
    }

    degerler.shuffle(rng);
    return SayiSorusu(
      soru: 'Hangisi diğerlerinden farklıdır?\n${degerler.join('   •   ')}',
      secenekler: List<dynamic>.from(degerler)..shuffle(rng),
      dogruCevap: dogru,
      aciklamaTr: aciklamaTr,
      aciklamaEn: aciklamaEn,
    );
  }

  List<dynamic> _sayiSecenekleri(
    Random rng, {
    required int dogru,
    required List<int> sapmalar,
  }) {
    final Set<int> adaylar = <int>{dogru};
    for (final int sapma in sapmalar) {
      final int guvenliSapma = max(1, sapma.abs());
      final int arti = dogru + guvenliSapma;
      final int eksi = dogru - guvenliSapma;
      adaylar.add(arti);
      if (eksi >= 0) adaylar.add(eksi);
      if (adaylar.length >= 4) break;
    }
    while (adaylar.length < 4) {
      adaylar.add(max(0, dogru + rng.nextInt(13) - 6));
    }
    final List<dynamic> secenekler = adaylar.take(4).toList();
    secenekler.shuffle(rng);
    return secenekler;
  }

  SayiSorusu _miniSudokuUret(
    Random rng, {
    required int boyut,
    required int boslukSayisi,
  }) {
    final int guvenliBoyut = boyut.clamp(3, 5).toInt();
    final int azamiBoslukSayisi = switch (guvenliBoyut) {
      3 => 1,
      4 => 4,
      _ => 7,
    };
    final int guvenliBoslukSayisi = boslukSayisi
        .clamp(1, azamiBoslukSayisi)
        .toInt();

    List<List<int>>? secilenTablo;
    List<int> bosHucreler = <int>[];

    // Her hücre silme denemesinde çözüm sayısı yeniden hesaplanır. Yalnızca
    // tek çözümü koruyan silmeler kabul edilir; bu nedenle çok boşluklu
    // sorular tahmine değil gerçek satır/sütun mantığına dayanır.
    for (int deneme = 0; deneme < 18; deneme++) {
      final List<List<int>> tablo = _sudokuTamTabloUret(rng, guvenliBoyut);
      final List<List<int?>> bulmaca = tablo
          .map((satir) => satir.map<int?>((deger) => deger).toList())
          .toList();
      final List<int> adayHucreler = List<int>.generate(
        guvenliBoyut * guvenliBoyut,
        (index) => index,
      )..shuffle(rng);
      final List<int> buDenemeninBosluklari = <int>[];

      for (final int hucre in adayHucreler) {
        final int satir = hucre ~/ guvenliBoyut;
        final int sutun = hucre % guvenliBoyut;
        final int eskiDeger = bulmaca[satir][sutun]!;

        bulmaca[satir][sutun] = null;

        final int cozumSayisi = _sudokuCozumSayisiniBul(
          bulmaca,
          boyut: guvenliBoyut,
        );

        if (cozumSayisi == 1) {
          buDenemeninBosluklari.add(hucre);
        } else {
          bulmaca[satir][sutun] = eskiDeger;
        }

        if (buDenemeninBosluklari.length == guvenliBoslukSayisi) {
          break;
        }
      }

      if (buDenemeninBosluklari.length > bosHucreler.length) {
        secilenTablo = tablo;
        bosHucreler = List<int>.from(buDenemeninBosluklari);
      }

      if (bosHucreler.length == guvenliBoslukSayisi) break;
    }

    // Çok düşük olasılıklı üretim çıkmazında tek çözümü kanıtlanmış sabit
    // hücre düzenine dönülür. Oyuncuya hiçbir zaman yarım soru gösterilmez.
    if (secilenTablo == null || bosHucreler.length < guvenliBoslukSayisi) {
      secilenTablo = _sudokuTemelTabloUret(guvenliBoyut);
      final List<int> guvenliBoslukSirasi = switch (guvenliBoyut) {
        3 => <int>[4],
        4 => <int>[0, 5, 10, 15],
        _ => <int>[0, 1, 6, 12, 20, 21, 23],
      };
      bosHucreler = guvenliBoslukSirasi.take(guvenliBoslukSayisi).toList();
    }

    bosHucreler.sort();
    final Set<int> bosHucreKumesi = bosHucreler.toSet();
    final List<dynamic> sudokuCevaplari = bosHucreler
        .map(
          (hucre) => secilenTablo![hucre ~/ guvenliBoyut][hucre % guvenliBoyut],
        )
        .toList();

    final String soru = List<String>.generate(guvenliBoyut, (satir) {
      return List<String>.generate(guvenliBoyut, (sutun) {
        final int hucre = satir * guvenliBoyut + sutun;
        return bosHucreKumesi.contains(hucre)
            ? '?'
            : '${secilenTablo![satir][sutun]}';
      }).join('  ');
    }).join('\n');

    final List<dynamic> secenekler = List<dynamic>.generate(
      guvenliBoyut,
      (index) => index + 1,
    )..shuffle(rng);

    return SayiSorusu(
      soru: soru,
      secenekler: secenekler,
      dogruCevap: sudokuCevaplari.first,
      sudokuCevaplari: sudokuCevaplari,
      aciklamaTr:
          'Her satır ve sütunda 1–$guvenliBoyut sayıları yalnız bir kez bulunur.',
      aciklamaEn: 'Each row and column contains 1–$guvenliBoyut exactly once.',
    );
  }

  List<List<int>> _sudokuTamTabloUret(Random rng, int boyut) {
    final List<int> semboller = List<int>.generate(boyut, (index) => index + 1)
      ..shuffle(rng);
    final List<int> satirSirasi = boyut == 4
        ? _dortluSudokuSirasiUret(rng)
        : (List<int>.generate(boyut, (index) => index)..shuffle(rng));
    final List<int> sutunSirasi = boyut == 4
        ? _dortluSudokuSirasiUret(rng)
        : (List<int>.generate(boyut, (index) => index)..shuffle(rng));

    return List<List<int>>.generate(
      boyut,
      (satir) => List<int>.generate(boyut, (sutun) {
        final int kaynakSatir = satirSirasi[satir];
        final int kaynakSutun = sutunSirasi[sutun];
        final int desen = boyut == 4
            ? (kaynakSatir * 2 + kaynakSatir ~/ 2 + kaynakSutun) % 4
            : (kaynakSatir + kaynakSutun) % boyut;
        return semboller[desen];
      }),
    );
  }

  List<int> _dortluSudokuSirasiUret(Random rng) {
    final List<int> grupSirasi = <int>[0, 1]..shuffle(rng);
    final List<int> sonuc = <int>[];

    for (final int grup in grupSirasi) {
      final List<int> grupIciSira = <int>[0, 1]..shuffle(rng);
      sonuc.addAll(grupIciSira.map((index) => grup * 2 + index));
    }

    return sonuc;
  }

  List<List<int>> _sudokuTemelTabloUret(int boyut) {
    return List<List<int>>.generate(
      boyut,
      (satir) => List<int>.generate(
        boyut,
        (sutun) => boyut == 4
            ? (satir * 2 + satir ~/ 2 + sutun) % 4 + 1
            : (satir + sutun) % boyut + 1,
      ),
    );
  }

  int _sudokuCozumSayisiniBul(
    List<List<int?>> bulmaca, {
    required int boyut,
    int sinir = 2,
  }) {
    final List<Set<int>> satirKullanilan = List<Set<int>>.generate(
      boyut,
      (_) => <int>{},
    );
    final List<Set<int>> sutunKullanilan = List<Set<int>>.generate(
      boyut,
      (_) => <int>{},
    );
    final List<Set<int>> blokKullanilan = List<Set<int>>.generate(
      boyut,
      (_) => <int>{},
    );
    final bool blokKurali = boyut == 4;

    for (int satir = 0; satir < boyut; satir++) {
      for (int sutun = 0; sutun < boyut; sutun++) {
        final int? deger = bulmaca[satir][sutun];
        if (deger == null) continue;

        final int blok = (satir ~/ 2) * 2 + sutun ~/ 2;
        if (satirKullanilan[satir].contains(deger) ||
            sutunKullanilan[sutun].contains(deger) ||
            (blokKurali && blokKullanilan[blok].contains(deger))) {
          return 0;
        }

        satirKullanilan[satir].add(deger);
        sutunKullanilan[sutun].add(deger);
        if (blokKurali) blokKullanilan[blok].add(deger);
      }
    }

    int cozumSayisi = 0;

    void cozumAra() {
      if (cozumSayisi >= sinir) return;

      int enIyiSatir = -1;
      int enIyiSutun = -1;
      int enIyiBlok = -1;
      List<int>? enIyiAdaylar;

      for (int satir = 0; satir < boyut; satir++) {
        for (int sutun = 0; sutun < boyut; sutun++) {
          if (bulmaca[satir][sutun] != null) continue;

          final int blok = (satir ~/ 2) * 2 + sutun ~/ 2;
          final List<int> adaylar = <int>[];

          for (int aday = 1; aday <= boyut; aday++) {
            final bool kullanilabilir =
                !satirKullanilan[satir].contains(aday) &&
                !sutunKullanilan[sutun].contains(aday) &&
                (!blokKurali || !blokKullanilan[blok].contains(aday));

            if (kullanilabilir) adaylar.add(aday);
          }

          if (adaylar.isEmpty) return;

          if (enIyiAdaylar == null || adaylar.length < enIyiAdaylar.length) {
            enIyiSatir = satir;
            enIyiSutun = sutun;
            enIyiBlok = blok;
            enIyiAdaylar = adaylar;
          }
        }
      }

      if (enIyiAdaylar == null) {
        cozumSayisi++;
        return;
      }

      for (final int aday in enIyiAdaylar) {
        bulmaca[enIyiSatir][enIyiSutun] = aday;
        satirKullanilan[enIyiSatir].add(aday);
        sutunKullanilan[enIyiSutun].add(aday);
        if (blokKurali) blokKullanilan[enIyiBlok].add(aday);

        cozumAra();

        bulmaca[enIyiSatir][enIyiSutun] = null;
        satirKullanilan[enIyiSatir].remove(aday);
        sutunKullanilan[enIyiSutun].remove(aday);
        if (blokKurali) blokKullanilan[enIyiBlok].remove(aday);

        if (cozumSayisi >= sinir) break;
      }
    }

    cozumAra();
    return cozumSayisi;
  }

  void _sudokuDurumunuSifirla() {
    sudokuGirilenCevaplar = List<dynamic>.filled(
      mevcutSoru.sudokuCevaplari.length,
      null,
      growable: false,
    );
    aktifSudokuBosluk = 0;
  }

  bool get _sudokuCevaplariDogru {
    final List<dynamic> dogruCevaplar = mevcutSoru.sudokuCevaplari;

    if (dogruCevaplar.isEmpty ||
        sudokuGirilenCevaplar.length != dogruCevaplar.length ||
        sudokuGirilenCevaplar.any((cevap) => cevap == null)) {
      return false;
    }

    for (int index = 0; index < dogruCevaplar.length; index++) {
      if (sudokuGirilenCevaplar[index] != dogruCevaplar[index]) {
        return false;
      }
    }

    return true;
  }

  void sudokuBoslukSec(int index) {
    if (cevapVerildi || index < 0 || index >= sudokuGirilenCevaplar.length) {
      return;
    }

    _audio.play(GameSound.numberSelect);

    setState(() {
      aktifSudokuBosluk = index;
    });
  }

  void sudokuCevapSec(dynamic cevap) {
    if (cevapVerildi ||
        mevcutSoru.sudokuCevaplari.isEmpty ||
        aktifSudokuBosluk < 0 ||
        aktifSudokuBosluk >= sudokuGirilenCevaplar.length) {
      return;
    }

    _audio.play(GameSound.numberSelect);

    bool tumHucrelerDolu = false;

    setState(() {
      final int doldurulanBosluk = aktifSudokuBosluk;
      sudokuGirilenCevaplar[doldurulanBosluk] = cevap;

      int siradakiBosluk = -1;
      for (int adim = 1; adim <= sudokuGirilenCevaplar.length; adim++) {
        final int adayIndex =
            (doldurulanBosluk + adim) % sudokuGirilenCevaplar.length;
        if (sudokuGirilenCevaplar[adayIndex] == null) {
          siradakiBosluk = adayIndex;
          break;
        }
      }

      if (siradakiBosluk >= 0) {
        aktifSudokuBosluk = siradakiBosluk;
      } else {
        tumHucrelerDolu = true;
      }
    });

    if (tumHucrelerDolu) {
      _cevabiSonuclandir(
        dogru: _sudokuCevaplariDogru,
        secilen: List<dynamic>.from(sudokuGirilenCevaplar),
      );
    }
  }

  void cevapSec(dynamic cevap) {
    if (cevapVerildi) return;

    _audio.play(GameSound.numberSelect);

    _cevabiSonuclandir(dogru: cevap == mevcutSoru.dogruCevap, secilen: cevap);
  }

  void _cevabiSonuclandir({required bool dogru, required dynamic secilen}) {
    if (cevapVerildi) return;

    final int yeniSeri = dogru ? dogruSerisi + 1 : 0;

    setState(() {
      cevapVerildi = true;
      secilenCevap = secilen;
      dogruSerisi = yeniSeri;

      if (dogru) {
        dogruSayisi++;
      } else {
        yanlisSayisi++;
      }
    });

    Future<void>.delayed(const Duration(milliseconds: 55), () {
      if (!mounted) return;

      if (dogru) {
        // Her doğru cevapta temel doğru sesi mutlaka duyulur.
        // Combo/streak bunun yerine geçmez; kısa bir bonus vurgu olarak eklenir.
        _audio.play(GameSound.numberCorrect);

        if (yeniSeri >= 5) {
          Future<void>.delayed(const Duration(milliseconds: 95), () {
            if (!mounted) return;
            _audio.play(GameSound.numberStreak, gain: .72);
          });
        } else if (yeniSeri >= 3) {
          Future<void>.delayed(const Duration(milliseconds: 95), () {
            if (!mounted) return;
            _audio.play(GameSound.numberCombo, gain: .72);
          });
        }
      } else {
        _audio.play(GameSound.numberWrong);
      }
    });

    final int sonucBeklemeSuresi = mevcutSoru.sudokuCevaplari.length > 1
        ? 1150
        : 850;

    Future.delayed(Duration(milliseconds: sonucBeklemeSuresi), () {
      if (!mounted) return;

      if (soruIndex < oturumSorulari.length - 1) {
        setState(() {
          soruIndex++;
          cevapVerildi = false;
          secilenCevap = null;
          _sudokuDurumunuSifirla();
        });
      } else {
        sonucGoster();
      }
    });
  }

  int yildizHesapla() {
    final int toplam = oturumSorulari.length;

    if (dogruSayisi == toplam) {
      return 3;
    }

    if (dogruSayisi >= toplam - 1) {
      return 2;
    }

    return 1;
  }

  int puanHesapla() {
    int puan = dogruSayisi * 100;

    if (!ipucuKullanildi) {
      puan += 50;
    }

    if (widget.seviye.zorluk == 'ZOR') {
      puan += 50;
    }

    if (widget.seviye.zorluk == 'BOSS') {
      puan += 200;
    }

    return puan;
  }

  void ipucuGoster() {
    _audio.play(GameSound.uiHint);

    setState(() {
      ipucuKullanildi = true;
    });

    String mesaj;

    switch (widget.seviye.tur) {
      case 'EKSİK SAYI':
        mesaj = 'Sayılar arasındaki artış veya azalış miktarını karşılaştır.';
        break;

      case 'ALTERNATİF DİZİ':
        mesaj = 'Tek ve çift adımlardaki artışları ayrı ayrı karşılaştır.';
        break;

      case 'GELİŞMİŞ DİZİ':
        mesaj = 'Toplama dışında çarpma, kare ve önceki iki sayıyı da dene.';
        break;

      case 'ZİNCİR':
        mesaj = 'Her adımdaki çarpma, bölme veya toplama kuralını bul.';
        break;

      case 'İŞLEM':
        mesaj = 'Önce çarpma ve bölme işlemlerini yapmayı unutma.';
        break;

      case 'PİRAMİT':
        mesaj = 'Her üst kutuyu altındaki iki komşu kutuyla karşılaştır.';
        break;

      case 'DENKLEM':
        mesaj = 'Kutuyu yalnız bırakmak için işlemleri ters sırada geri al.';
        break;

      case 'MATRİS':
        mesaj = 'İlk iki satırda üçüncü sayının nasıl üretildiğini bul.';
        break;

      case 'SINIFLAMA':
        mesaj = 'Üç sayının ortak özelliğini bulup uymayan sayıyı seç.';
        break;

      case 'SUDOKU':
        final int boyut = widget.seviye.sudokuBoyutu ?? 3;
        mesaj = boyut == 4
            ? 'Her satırda, sütunda ve kalın çizgili 2×2 bölgede 1 ile 4 arasındaki sayılar yalnızca bir kez bulunmalı.'
            : 'Her satır ve sütunda 1 ile $boyut arasındaki sayılar yalnızca bir kez bulunmalı.';
        break;

      case 'BOSS':
        mesaj = 'Boss bölümünde önce sorunun türünü belirle, sonra çözüm kuralını uygula.';
        break;

      default:
        mesaj = 'Sorudaki düzeni adım adım incele.';
    }

    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF243F6B),
        content: Row(
          children: [
            const Icon(Icons.lightbulb_rounded, color: Color(0xFFFFD334)),
            const SizedBox(width: 10),
            Expanded(child: LText(mesaj)),
          ],
        ),
      ),
    );
  }

  void sonucGoster() {
    final int yildiz = yildizHesapla();
    final int puan = puanHesapla();

    _audio.playVictory(stars: yildiz, boss: widget.seviye.zorluk == 'BOSS');

    if (widget.competitionMode) {
      Navigator.pop(
        context,
        SayiSeviyeSonucu(
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
                border: Border.all(color: const Color(0xFF54E56B), width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.seviye.zorluk == 'BOSS'
                        ? Icons.emoji_events_rounded
                        : Icons.calculate_rounded,
                    size: 62,
                    color: const Color(0xFF54E56B),
                  ),
                  const SizedBox(height: 10),
                  LText(
                    widget.seviye.zorluk == 'BOSS'
                        ? 'SAYI BOSS YENİLDİ!'
                        : 'SEVİYE TAMAMLANDI!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 23,
                      color: Color(0xFF54E56B),
                    ),
                  ),
                  const SizedBox(height: 11),
                  AdvancedResultBanner(
                    score: puan,
                    previousBestScore: widget.previousBestScore,
                    english: context.l10n.isEnglish,
                    accentColor: const Color(0xFF54E56B),
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
                        size: 44,
                      );
                    }),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _SayiSonucKutusu(
                          baslik: 'DOĞRU',
                          deger: '$dogruSayisi/${oturumSorulari.length}',
                          ikon: Icons.check_circle_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SayiSonucKutusu(
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
                          backgroundColor: const Color(0xFF54C96B),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        onPressed: () {
                          Navigator.pop(dialogContext);

                          Navigator.pop(
                            context,
                            SayiSeviyeSonucu(
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
                            SayiSeviyeSonucu(
                              tamamlandi: true,
                              yildiz: yildiz,
                              puan: puan,
                              sonrakiSeviye: false,
                            ),
                          );
                        },
                        icon: const Icon(Icons.emoji_events_rounded),
                        label: const LText('SAYI PARKURUNU TAMAMLA'),
                      ),
                    ),

                  const SizedBox(height: 6),

                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);

                      Navigator.pop(
                        context,
                        SayiSeviyeSonucu(
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
    final double ilerleme = (soruIndex + 1) / oturumSorulari.length;
    final bool miniSudokuGorunumu =
        _sudokuSatirlariniAyir(mevcutSoru.soru) != null;
    final bool mevcutCevapDogru = miniSudokuGorunumu
        ? _sudokuCevaplariDogru
        : secilenCevap == mevcutSoru.dogruCevap;
    final String aciklama = context.l10n.isEnglish
        ? mevcutSoru.aciklamaEn
        : mevcutSoru.aciklamaTr;
    final String durumMetni;
    final Color durumRengi;

    if (!cevapVerildi) {
      durumMetni = miniSudokuGorunumu
          ? 'Parlayan hücreyi seç ve sayıyı yerleştir.'
          : 'Doğru cevabı seç.';
      durumRengi = Colors.white54;
    } else if (mevcutCevapDogru) {
      durumMetni = aciklama.isEmpty ? '✓ Doğru!' : '✓ $aciklama';
      durumRengi = const Color(0xFF76FF03);
    } else {
      final String dogruMetni = miniSudokuGorunumu
          ? mevcutSoru.sudokuCevaplari.length > 2
                ? '✕ Doğru yerleşim tabloda gösterildi.'
                : '✕ Doğru sayılar: ${mevcutSoru.sudokuCevaplari.join(' • ')}'
          : '✕ Doğru cevap: ${mevcutSoru.dogruCevap}';
      durumMetni = aciklama.isEmpty ? dogruMetni : '$dogruMetni  $aciklama';
      durumRengi = const Color(0xFFFF7474);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LText(
              widget.seviye.baslik.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
            ),
            LText(
              'Soru ${soruIndex + 1} / ${oturumSorulari.length}',
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'İpucu',
            onPressed: ipucuGoster,
            icon: Icon(
              Icons.lightbulb_rounded,
              color: ipucuKullanildi ? Colors.white54 : const Color(0xFFFFD334),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: ilerleme,
                  minHeight: 9,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF54E56B),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _UstBilgiEtiketi(
                    ikon: Icons.calculate_rounded,
                    metin: widget.seviye.tur,
                  ),
                  const Spacer(),
                  _UstBilgiEtiketi(
                    ikon: Icons.check_rounded,
                    metin: '$dogruSayisi doğru',
                  ),
                ],
              ),
              const SizedBox(height: 25),
              Expanded(
                child: miniSudokuGorunumu
                    ? _MiniSudokuSoruKarti(
                        soru: mevcutSoru,
                        cevapVerildi: cevapVerildi,
                        girilenCevaplar: sudokuGirilenCevaplar,
                        aktifBoslukIndex: aktifSudokuBosluk,
                        onBoslukSec: sudokuBoslukSec,
                        onCevapSec: sudokuCevapSec,
                      )
                    : Center(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(25),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: <Color>[
                                ZpVisualPalette.of(context).surface,
                                ZpVisualPalette.of(context)
                                    .gamePanelGradientEnd,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: const Color(0xFF2E8256)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              LText(
                                mevcutSoru.soru,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 30,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 30),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: mevcutSoru.secenekler.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 2.0,
                                    ),
                                itemBuilder: (context, index) {
                                  final cevap = mevcutSoru.secenekler[index];

                                  Color renk = const Color(0xFF173D61);

                                  if (cevapVerildi) {
                                    if (cevap == mevcutSoru.dogruCevap) {
                                      renk = const Color(0xFF1D8C4D);
                                    } else if (cevap == secilenCevap) {
                                      renk = const Color(0xFFC74242);
                                    }
                                  }

                                  return Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        cevapSec(cevap);
                                      },
                                      borderRadius: BorderRadius.circular(18),
                                      child: Ink(
                                        decoration: BoxDecoration(
                                          color: renk,
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                          border: Border.all(
                                            color: Colors.white12,
                                          ),
                                        ),
                                        child: Center(
                                          child: LText(
                                            '$cevap',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 22,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 15),
              LText(
                durumMetni,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: durumRengi,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<List<String>>? _sudokuSatirlariniAyir(String soru) {
  final List<String> satirMetinleri = soru.trim().split('\n');
  final int boyut = satirMetinleri.length;

  if (boyut < 3 || boyut > 5) {
    return null;
  }

  final List<List<String>> satirlar = satirMetinleri
      .map(
        (satir) => satir
            .trim()
            .split(RegExp(r'\s+'))
            .where((hucre) => hucre.isNotEmpty)
            .toList(),
      )
      .toList();

  final Set<String> gecerliDegerler = <String>{
    '?',
    ...List<String>.generate(boyut, (index) => '${index + 1}'),
  };
  final bool temelYapiGecerli = satirlar.every(
    (satir) => satir.length == boyut && satir.every(gecerliDegerler.contains),
  );

  if (!temelYapiGecerli) return null;

  final int boslukSayisi = satirlar
      .expand((satir) => satir)
      .where((hucre) => hucre == '?')
      .length;

  final int azamiBoslukSayisi = switch (boyut) {
    3 => 1,
    4 => 4,
    _ => 7,
  };

  if (boslukSayisi < 1 || boslukSayisi > azamiBoslukSayisi) {
    return null;
  }

  bool tekrarYok(Iterable<String> hucreler) {
    final List<String> sayilar = hucreler
        .where((hucre) => hucre != '?')
        .toList();
    return sayilar.toSet().length == sayilar.length;
  }

  final bool satirlarGecerli = satirlar.every((satir) => tekrarYok(satir));
  final bool sutunlarGecerli = List<int>.generate(
    boyut,
    (index) => index,
  ).every((sutun) => tekrarYok(satirlar.map((satir) => satir[sutun])));
  final bool bloklarGecerli =
      boyut != 4 ||
      List<int>.generate(4, (index) => index).every((blok) {
        final int baslangicSatiri = (blok ~/ 2) * 2;
        final int baslangicSutunu = (blok % 2) * 2;
        final List<String> hucreler = <String>[];

        for (
          int satir = baslangicSatiri;
          satir < baslangicSatiri + 2;
          satir++
        ) {
          for (
            int sutun = baslangicSutunu;
            sutun < baslangicSutunu + 2;
            sutun++
          ) {
            hucreler.add(satirlar[satir][sutun]);
          }
        }

        return tekrarYok(hucreler);
      });

  return satirlarGecerli && sutunlarGecerli && bloklarGecerli ? satirlar : null;
}

class _MiniSudokuSoruKarti extends StatelessWidget {
  final SayiSorusu soru;
  final bool cevapVerildi;
  final List<dynamic> girilenCevaplar;
  final int aktifBoslukIndex;
  final ValueChanged<int> onBoslukSec;
  final ValueChanged<dynamic> onCevapSec;

  const _MiniSudokuSoruKarti({
    required this.soru,
    required this.cevapVerildi,
    required this.girilenCevaplar,
    required this.aktifBoslukIndex,
    required this.onBoslukSec,
    required this.onCevapSec,
  });

  @override
  Widget build(BuildContext context) {
    final List<List<String>> satirlar = _sudokuSatirlariniAyir(soru.soru)!;
    final int boyut = satirlar.length;
    final int eksikHucreSayisi = soru.sudokuCevaplari.length;
    final List<dynamic> dogruCevaplar = soru.sudokuCevaplari.isEmpty
        ? <dynamic>[soru.dogruCevap]
        : soru.sudokuCevaplari;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool darEkran = constraints.maxWidth < 340;
        final bool kisaEkran = constraints.maxHeight < 420;
        final double yatayBosluk = darEkran ? 13 : 20;
        final double dikeyBosluk = kisaEkran ? 12 : 18;
        final double genisligeGoreTahta =
            constraints.maxWidth - (yatayBosluk * 2);
        final double yuksekligeGoreTahta =
            constraints.maxHeight - (kisaEkran ? 132 : 150);
        final double azamiTahtaBoyutu = switch (boyut) {
          3 => 280.0,
          4 => 300.0,
          _ => 315.0,
        };
        final double tahtaBoyutu = min(
          genisligeGoreTahta,
          min(azamiTahtaBoyutu, yuksekligeGoreTahta),
        ).clamp(168.0, azamiTahtaBoyutu).toDouble();
        final double minIcerikYuksekligi = max(
          0.0,
          constraints.maxHeight - (dikeyBosluk * 2),
        );

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                ZpVisualPalette.of(context).surface,
                ZpVisualPalette.of(context).gamePanelGradientEnd,
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF2E8256)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3300D98B),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(27),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: yatayBosluk,
                vertical: dikeyBosluk,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minIcerikYuksekligi),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF071D37),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0x4454E56B)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.apps_rounded,
                            size: 17,
                            color: Color(0xFF54E56B),
                          ),
                          const SizedBox(width: 7),
                          Flexible(
                            child: LText(
                              '$boyut × $boyut SUDOKU  •  '
                              '$eksikHucreSayisi EKSİK',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: kisaEkran ? 9 : 13),
                    SizedBox.square(
                      dimension: tahtaBoyutu,
                      child: _MiniSudokuTahtasi(
                        satirlar: satirlar,
                        cevapVerildi: cevapVerildi,
                        girilenCevaplar: girilenCevaplar,
                        dogruCevaplar: dogruCevaplar,
                        aktifBoslukIndex: aktifBoslukIndex,
                        onBoslukSec: onBoslukSec,
                      ),
                    ),
                    SizedBox(height: kisaEkran ? 9 : 13),
                    LText(
                      cevapVerildi
                          ? 'Sudoku tamamlandı'
                          : eksikHucreSayisi > 1
                          ? '${aktifBoslukIndex + 1}/$eksikHucreSayisi  •  Parlayan hücreye sayı seç'
                          : 'Parlayan hücre için doğru sayıyı seç',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: kisaEkran ? 7 : 10),
                    Row(
                      children: [
                        for (
                          int index = 0;
                          index < soru.secenekler.length;
                          index++
                        ) ...[
                          if (index > 0) SizedBox(width: darEkran ? 6 : 9),
                          Expanded(
                            child: _SudokuCevapButonu(
                              cevap: soru.secenekler[index],
                              cevapVerildi: cevapVerildi,
                              secili:
                                  !cevapVerildi &&
                                  aktifBoslukIndex >= 0 &&
                                  aktifBoslukIndex < girilenCevaplar.length &&
                                  girilenCevaplar[aktifBoslukIndex] ==
                                      soru.secenekler[index],
                              dogruSecenek:
                                  cevapVerildi &&
                                  eksikHucreSayisi == 1 &&
                                  dogruCevaplar.contains(
                                    soru.secenekler[index],
                                  ),
                              yanlisSecenek:
                                  cevapVerildi &&
                                  eksikHucreSayisi == 1 &&
                                  girilenCevaplar.contains(
                                    soru.secenekler[index],
                                  ) &&
                                  !dogruCevaplar.contains(
                                    soru.secenekler[index],
                                  ),
                              kompakt: kisaEkran,
                              onTap: () => onCevapSec(soru.secenekler[index]),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MiniSudokuTahtasi extends StatelessWidget {
  final List<List<String>> satirlar;
  final bool cevapVerildi;
  final List<dynamic> girilenCevaplar;
  final List<dynamic> dogruCevaplar;
  final int aktifBoslukIndex;
  final ValueChanged<int> onBoslukSec;

  const _MiniSudokuTahtasi({
    required this.satirlar,
    required this.cevapVerildi,
    required this.girilenCevaplar,
    required this.dogruCevaplar,
    required this.aktifBoslukIndex,
    required this.onBoslukSec,
  });

  @override
  Widget build(BuildContext context) {
    final int boyut = satirlar.length;
    final Map<int, int> boslukSiralari = <int, int>{};
    int boslukSirasi = 0;

    for (int satir = 0; satir < boyut; satir++) {
      for (int sutun = 0; sutun < boyut; sutun++) {
        if (satirlar[satir][sutun] == '?') {
          boslukSiralari[satir * boyut + sutun] = boslukSirasi;
          boslukSirasi++;
        }
      }
    }

    final double hucreBosluk = boyut == 5 ? 3 : 5;
    final double sayiBoyutu = switch (boyut) {
      3 => 32.0,
      4 => 28.0,
      _ => 24.0,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A1F3A), Color(0xFF123B5C)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF54E56B), width: 2.4),
        boxShadow: const [
          BoxShadow(color: Color(0x4400E5A0), blurRadius: 18, spreadRadius: 1),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: CustomPaint(
          foregroundPainter: _SudokuIzgaraCizici(boyut: boyut),
          child: Column(
            children: List.generate(boyut, (satirIndex) {
              return Expanded(
                child: Row(
                  children: List.generate(boyut, (sutunIndex) {
                    final String hamDeger = satirlar[satirIndex][sutunIndex];
                    final int hucreSirasi = satirIndex * boyut + sutunIndex;
                    final int? eksikHucreIndex = boslukSiralari[hucreSirasi];
                    final bool eksikHucre = eksikHucreIndex != null;
                    final dynamic girilenCevap =
                        eksikHucreIndex != null &&
                            eksikHucreIndex < girilenCevaplar.length
                        ? girilenCevaplar[eksikHucreIndex]
                        : null;
                    final dynamic dogruCevap =
                        eksikHucreIndex != null &&
                            eksikHucreIndex < dogruCevaplar.length
                        ? dogruCevaplar[eksikHucreIndex]
                        : null;
                    final bool aktifHucre =
                        eksikHucre &&
                        !cevapVerildi &&
                        eksikHucreIndex == aktifBoslukIndex;
                    final bool hucreDogru =
                        eksikHucre &&
                        cevapVerildi &&
                        girilenCevap == dogruCevap;
                    final String gorunenDeger = eksikHucre
                        ? cevapVerildi && !hucreDogru
                              ? '$dogruCevap'
                              : girilenCevap == null
                              ? '?'
                              : '$girilenCevap'
                        : hamDeger;

                    Color yaziRengi = Colors.white;
                    Color vurguRengi = aktifHucre
                        ? const Color(0xFF00D9FF)
                        : const Color(0xFFFFD334);

                    if (eksikHucre && cevapVerildi) {
                      yaziRengi = hucreDogru
                          ? const Color(0xFF8CFF9D)
                          : const Color(0xFFFF9D9D);
                      vurguRengi = hucreDogru
                          ? const Color(0xFF54E56B)
                          : const Color(0xFFFF7474);
                    }

                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(hucreBosluk),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: eksikHucre && !cevapVerildi
                              ? () => onBoslukSec(eksikHucreIndex)
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            alignment: Alignment.center,
                            decoration: eksikHucre
                                ? BoxDecoration(
                                    color: vurguRengi.withValues(
                                      alpha: aktifHucre ? 0.22 : 0.13,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      boyut == 5 ? 9 : 12,
                                    ),
                                    border: Border.all(
                                      color: vurguRengi.withValues(alpha: 0.95),
                                      width: aktifHucre ? 2.4 : 1.8,
                                    ),
                                    boxShadow: aktifHucre
                                        ? <BoxShadow>[
                                            BoxShadow(
                                              color: vurguRengi.withValues(
                                                alpha: 0.38,
                                              ),
                                              blurRadius: 12,
                                            ),
                                          ]
                                        : null,
                                  )
                                : null,
                            child: Stack(
                              fit: StackFit.expand,
                              children: <Widget>[
                                if (eksikHucre)
                                  Positioned(
                                    top: 2,
                                    left: 3,
                                    child: LText(
                                      '${eksikHucreIndex + 1}',
                                      style: TextStyle(
                                        color: vurguRengi.withValues(
                                          alpha: 0.85,
                                        ),
                                        fontSize: boyut == 5 ? 7 : 8,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: LText(
                                      gorunenDeger,
                                      style: TextStyle(
                                        color: yaziRengi,
                                        fontSize: sayiBoyutu,
                                        fontWeight: FontWeight.w900,
                                        height: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _SudokuIzgaraCizici extends CustomPainter {
  final int boyut;

  const _SudokuIzgaraCizici({required this.boyut});

  @override
  void paint(Canvas canvas, Size size) {
    for (int cizgi = 1; cizgi < boyut; cizgi++) {
      final bool blokSiniri = boyut == 4 && cizgi == 2;
      final Paint boya = Paint()
        ..color = blokSiniri ? const Color(0xCC54E56B) : const Color(0x38FFFFFF)
        ..strokeWidth = blokSiniri ? 3 : 1
        ..style = PaintingStyle.stroke;
      final double x = size.width * cizgi / boyut;
      final double y = size.height * cizgi / boyut;

      canvas.drawLine(Offset(x, 0), Offset(x, size.height), boya);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), boya);
    }
  }

  @override
  bool shouldRepaint(covariant _SudokuIzgaraCizici oldDelegate) {
    return oldDelegate.boyut != boyut;
  }
}

class _SudokuCevapButonu extends StatelessWidget {
  final dynamic cevap;
  final bool cevapVerildi;
  final bool secili;
  final bool dogruSecenek;
  final bool yanlisSecenek;
  final bool kompakt;
  final VoidCallback onTap;

  const _SudokuCevapButonu({
    required this.cevap,
    required this.cevapVerildi,
    required this.secili,
    required this.dogruSecenek,
    required this.yanlisSecenek,
    required this.kompakt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color zeminRengi = const Color(0xFF173D61);
    Color cerceveRengi = const Color(0x5554E56B);

    if (cevapVerildi) {
      if (dogruSecenek) {
        zeminRengi = const Color(0xFF1D8C4D);
        cerceveRengi = const Color(0xFF8CFF9D);
      } else if (yanlisSecenek) {
        zeminRengi = const Color(0xFFC74242);
        cerceveRengi = const Color(0xFFFFA0A0);
      }
    } else if (secili) {
      zeminRengi = const Color(0xFF135D7A);
      cerceveRengi = const Color(0xFF00D9FF);
    }

    return SizedBox(
      height: kompakt ? 46 : 52,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: cevapVerildi ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              color: zeminRengi,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cerceveRengi),
              boxShadow: secili
                  ? const <BoxShadow>[
                      BoxShadow(color: Color(0x6600D9FF), blurRadius: 13),
                    ]
                  : const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: LText(
                  '$cevap',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SayiIlerlemePaneli extends StatelessWidget {
  final int toplamPuan;
  final int toplamYildiz;
  final int acikSeviye;
  final bool darEkran;

  const _SayiIlerlemePaneli({
    required this.toplamPuan,
    required this.toplamYildiz,
    required this.acikSeviye,
    required this.darEkran,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(darEkran ? 14 : 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF147D47), Color(0xFF0F526A)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: darEkran ? 44 : 55,
                height: darEkran ? 44 : 55,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(Icons.calculate_rounded, size: darEkran ? 28 : 34),
              ),
              SizedBox(width: darEkran ? 9 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LText(
                      'SAYI YOLCULUĞU',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: darEkran ? 15 : 17,
                      ),
                    ),
                    const LText(
                      'Desenleri bul, işlemleri çöz.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  LText(
                    '$toplamPuan',
                    style: TextStyle(
                      color: const Color(0xFFFFD334),
                      fontWeight: FontWeight.w900,
                      fontSize: darEkran ? 17 : 21,
                    ),
                  ),
                  const LText(
                    'PUAN',
                    style: TextStyle(color: Colors.white60, fontSize: 9),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFFD334)),
                    const SizedBox(width: 5),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: LText(
                          '$toplamYildiz / 30',
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
                    style: const TextStyle(fontWeight: FontWeight.bold),
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

class _SayiSeviyeKarti extends StatelessWidget {
  final SayiSeviyesi seviye;
  final bool acik;
  final int yildiz;
  final int enIyiPuan;
  final VoidCallback onTap;

  const _SayiSeviyeKarti({
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
        return Colors.green;
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: acik
                ? ZpVisualPalette.of(context).surface
                : ZpVisualPalette.of(context).surfaceAlternative,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: acik ? anaRenk.withValues(alpha: 0.65) : Colors.white12,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: acik ? anaRenk : Colors.white12,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: acik
                        ? LText(
                            '${seviye.numara}',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          )
                        : const Icon(
                            Icons.lock_rounded,
                            size: 20,
                            color: Colors.white30,
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
              const SizedBox(height: 7),
              Icon(
                seviye.zorluk == 'BOSS'
                    ? Icons.emoji_events_rounded
                    : Icons.calculate_rounded,
                color: acik ? anaRenk : Colors.white12,
                size: 32,
              ),
              const SizedBox(height: 5),
              LText(
                seviye.baslik,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: acik ? Colors.white : Colors.white24,
                ),
              ),
              LText(
                '${seviye.tur} • ${seviye.oturumSoruSayisi} SORU',
                style: const TextStyle(color: Colors.white38, fontSize: 8),
              ),
              const Spacer(),
              if (enIyiPuan > 0)
                LText(
                  'En iyi: $enIyiPuan',
                  style: const TextStyle(color: Colors.white54, fontSize: 9),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (index) => Icon(
                    index < yildiz
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: acik ? const Color(0xFFFFD334) : Colors.white12,
                    size: 19,
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

class _UstBilgiEtiketi extends StatelessWidget {
  final IconData ikon;
  final String metin;

  const _UstBilgiEtiketi({required this.ikon, required this.metin});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: ZpVisualPalette.of(context).surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(ikon, size: 17, color: const Color(0xFF54E56B)),
          const SizedBox(width: 5),
          LText(
            metin,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _SayiSonucKutusu extends StatelessWidget {
  final String baslik;
  final String deger;
  final IconData ikon;

  const _SayiSonucKutusu({
    required this.baslik,
    required this.deger,
    required this.ikon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(ikon, color: const Color(0xFF54E56B)),
          const SizedBox(height: 5),
          LText(
            deger,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
          ),
          LText(
            baslik,
            style: const TextStyle(color: Colors.white54, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class SayiSeviyesi {
  final int numara;
  final String baslik;
  final String tur;
  final String zorluk;
  final int oturumSoruSayisi;
  final List<SayiSorusu> sorular;
  final int? sudokuBoyutu;
  final int sudokuBoslukSayisi;

  const SayiSeviyesi({
    required this.numara,
    required this.baslik,
    required this.tur,
    required this.zorluk,
    required this.oturumSoruSayisi,
    required this.sorular,
    this.sudokuBoyutu,
    this.sudokuBoslukSayisi = 1,
  });
}

class SayiSorusu {
  final String soru;
  final List<dynamic> secenekler;
  final dynamic dogruCevap;
  final List<dynamic> sudokuCevaplari;
  final String aciklamaTr;
  final String aciklamaEn;

  const SayiSorusu({
    required this.soru,
    required this.secenekler,
    required this.dogruCevap,
    this.sudokuCevaplari = const <dynamic>[],
    this.aciklamaTr = '',
    this.aciklamaEn = '',
  });
}

class SayiSeviyeSonucu {
  final bool tamamlandi;
  final int yildiz;
  final int puan;
  final bool sonrakiSeviye;

  const SayiSeviyeSonucu({
    required this.tamamlandi,
    required this.yildiz,
    required this.puan,
    required this.sonrakiSeviye,
  });
}
