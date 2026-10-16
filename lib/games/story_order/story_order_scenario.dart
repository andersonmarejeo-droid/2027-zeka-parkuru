import 'dart:math' as math;

import '../shared/content_seed.dart';

class StorySequenceDefinition {
  const StorySequenceDefinition({
    required this.id,
    required this.minimumStage,
    required this.titleTr,
    required this.titleEn,
    required this.setupTr,
    required this.setupEn,
    required this.eventsTr,
    required this.eventsEn,
    required this.decoyTr,
    required this.decoyEn,
    required this.explanationTr,
    required this.explanationEn,
  });

  final String id;
  final int minimumStage;
  final String titleTr;
  final String titleEn;
  final String setupTr;
  final String setupEn;
  final List<String> eventsTr;
  final List<String> eventsEn;
  final String decoyTr;
  final String decoyEn;
  final String explanationTr;
  final String explanationEn;
}

class StorySequenceCard {
  const StorySequenceCard({
    required this.id,
    required this.text,
    required this.isDecoy,
    required this.canonicalOrder,
  });

  final String id;
  final String text;
  final bool isDecoy;
  final int canonicalOrder;
}

class StoryOrderVariant {
  const StoryOrderVariant({
    required this.id,
    required this.personTr,
    required this.personEn,
    required this.momentTr,
    required this.momentEn,
  });

  final int id;
  final String personTr;
  final String personEn;
  final String momentTr;
  final String momentEn;
}

/// Cause-and-effect ordering scenarios with an optional unsupported side note.
class StoryOrderScenario {
  const StoryOrderScenario({
    required this.story,
    required this.variant,
    required this.stage,
    required this.english,
    required this.isPractice,
    required this.round,
    required this.cards,
    required this.expectedIds,
    required this.setup,
    required this.title,
    required this.explanation,
  });

  static const int campaignLevels = 20;
  static const int uniquePracticeRounds = 300;

  static const List<StoryOrderVariant> _variants = <StoryOrderVariant>[
    StoryOrderVariant(
      id: 0,
      personTr: 'Deniz',
      personEn: 'Deniz',
      momentTr: 'ilk kontrolde',
      momentEn: 'during the first check',
    ),
    StoryOrderVariant(
      id: 1,
      personTr: 'Ece',
      personEn: 'Ece',
      momentTr: 'sabah vardiyasında',
      momentEn: 'on the morning shift',
    ),
    StoryOrderVariant(
      id: 2,
      personTr: 'Mert',
      personEn: 'Mert',
      momentTr: 'yağmur dindikten sonra',
      momentEn: 'after the rain stopped',
    ),
    StoryOrderVariant(
      id: 3,
      personTr: 'Aylin',
      personEn: 'Aylin',
      momentTr: 'kapanıştan hemen önce',
      momentEn: 'just before closing',
    ),
    StoryOrderVariant(
      id: 4,
      personTr: 'Can',
      personEn: 'Can',
      momentTr: 'ikinci ölçüm sırasında',
      momentEn: 'during the second measurement',
    ),
    StoryOrderVariant(
      id: 5,
      personTr: 'Selin',
      personEn: 'Selin',
      momentTr: 'ekip yeniden toplandığında',
      momentEn: 'when the team regrouped',
    ),
    StoryOrderVariant(
      id: 6,
      personTr: 'Emre',
      personEn: 'Emre',
      momentTr: 'öğleden sonraki denemede',
      momentEn: 'in the afternoon trial',
    ),
    StoryOrderVariant(
      id: 7,
      personTr: 'Duru',
      personEn: 'Duru',
      momentTr: 'yeni kayıt açılırken',
      momentEn: 'as a new record was opened',
    ),
    StoryOrderVariant(
      id: 8,
      personTr: 'Baran',
      personEn: 'Baran',
      momentTr: 'planlı bakım gününde',
      momentEn: 'on the scheduled maintenance day',
    ),
    StoryOrderVariant(
      id: 9,
      personTr: 'İpek',
      personEn: 'Ipek',
      momentTr: 'istasyon sakinleşince',
      momentEn: 'once the station quieted down',
    ),
    StoryOrderVariant(
      id: 10,
      personTr: 'Ozan',
      personEn: 'Ozan',
      momentTr: 'ikinci teslimat turunda',
      momentEn: 'during the second delivery run',
    ),
    StoryOrderVariant(
      id: 11,
      personTr: 'Lara',
      personEn: 'Lara',
      momentTr: 'gece nöbetinde',
      momentEn: 'during the night watch',
    ),
    StoryOrderVariant(
      id: 12,
      personTr: 'Arda',
      personEn: 'Arda',
      momentTr: 'son kontrol listesini işlerken',
      momentEn: 'while completing the final checklist',
    ),
    StoryOrderVariant(
      id: 13,
      personTr: 'Nehir',
      personEn: 'Nehir',
      momentTr: 'yedek sistem açıldıktan sonra',
      momentEn: 'after the backup system came online',
    ),
    StoryOrderVariant(
      id: 14,
      personTr: 'Eylül',
      personEn: 'Eylul',
      momentTr: 'deney tekrarlanırken',
      momentEn: 'while the experiment was repeated',
    ),
    StoryOrderVariant(
      id: 15,
      personTr: 'Bora',
      personEn: 'Bora',
      momentTr: 'sonuçlar karşılaştırıldığında',
      momentEn: 'when the results were compared',
    ),
  ];

  static const List<StorySequenceDefinition> _bank = <StorySequenceDefinition>[
    StorySequenceDefinition(
      id: 'library_return',
      minimumStage: 1,
      titleTr: 'Kütüphane fişi',
      titleEn: 'The library slip',
      setupTr: 'Bir kitap görünmez oldu; teslim kaydı bunun nerede bulunduğunu gösteriyor.',
      setupEn: 'A book went missing; the return record shows how it was found.',
      eventsTr: <String>[
        '{person}, {moment}, çalışma masasındaki kitabın rafta görünmediğini fark etti.',
        'Ödünç kaydında kitabın en son sessiz çalışma odasına götürüldüğü görüldü.',
        'Masa ve sandalye çevresi kontrol edildi; atlasın altında kitabın köşesi bulundu.',
        'Barkod fişteki numarayla karşılaştırıldı ve aynı kitap olduğu doğrulandı.',
        'Kitap görevliye teslim edildi; iade fişi oluşturuldu.',
      ],
      eventsEn: <String>[
        '{person} noticed during {moment} that the book was missing from its shelf.',
        'The loan record showed that it had last been taken to the quiet study room.',
        'The desk area was checked, and a corner of the book appeared beneath an atlas.',
        'Its barcode was compared with the receipt and matched.',
        'The book was handed to the librarian, who issued a return slip.',
      ],
      decoyTr:
          'Görevli, kitabın yeni baskısının gelecek ay çıkacağını söyledi.',
      decoyEn:
          'The librarian mentioned that a new edition would arrive next month.',
      explanationTr: 'Kayıt son konumu gösterir; atlasın altındaki köşe bulunur, barkod doğrulanır ve teslim tamamlanır.',
      explanationEn: 'The record narrows the location; the book is found, its barcode checked and the return logged.',
    ),
    StorySequenceDefinition(
      id: 'greenhouse_drain',
      minimumStage: 1,
      titleTr: 'Seradaki damla',
      titleEn: 'The greenhouse drip',
      setupTr:
          'Sulama bitse de fidelerin altındaki tepsi yeniden suyla doluyor.',
      setupEn:
          'The trays beneath the seedlings keep filling after watering ends.',
      eventsTr: <String>[
        '{person}, {moment}, fidelerin altındaki tepside taze su biriktiğini gördü.',
        'Sulama vanası kapatıldı; damlama bir süre daha sürdü.',
        'Besleme hortumunun ek yerinde gevşek bir bağlantı bulundu.',
        'Bağlantı sıkıldı ve hortum kuru bezle silindi.',
        'Vana kısa süre açıldı; ek yerinin kuru kaldığı ve tepsinin dolmadığı doğrulandı.',
      ],
      eventsEn: <String>[
        '{person} saw fresh water collecting below the seedlings during {moment}.',
        'The irrigation valve was closed, but the dripping continued briefly.',
        'A loose joint was found on the supply hose.',
        'The joint was tightened and the hose was wiped dry.',
        'The valve was reopened briefly; the joint stayed dry and the tray remained empty.',
      ],
      decoyTr: 'Fidelerin yaprak rengi o hafta normalden daha koyuydu.',
      decoyEn: 'The seedling leaves looked darker than usual that week.',
      explanationTr: 'Su, vana kapandıktan sonra da aktığı için gevşek ek yeri aranır; onarım ancak kısa testten sonra doğrulanır.',
      explanationEn: 'Continued dripping points to the loose joint; the repair is confirmed only by a short retest.',
    ),
    StorySequenceDefinition(
      id: 'bicycle_chain',
      minimumStage: 1,
      titleTr: 'Zincir neden attı?',
      titleEn: 'The slipped chain',
      setupTr: 'Bisiklet yokuşta ilerlemez oldu; bakım notları sorunun nasıl çözüldüğünü anlatıyor.',
      setupEn: 'A bicycle stopped climbing a hill; the repair notes explain how it was fixed.',
      eventsTr: <String>[
        '{person}, {moment}, pedalın boşa döndüğünü ve zincirin dişliden çıktığını fark etti.',
        'Bisiklet güvenli biçimde kenara alınıp ters çevrildi.',
        'Zincirin arka dişlinin dışına sıkıştığı görüldü.',
        'Zincir dişliye oturtulup gerginliği ayarlandı.',
        'Pedal elle birkaç tur çevrildi; zincir yerinde kaldı.',
      ],
      eventsEn: <String>[
        '{person} noticed during {moment} that the pedal spun freely and the chain had slipped.',
        'The bicycle was moved safely aside and turned upside down.',
        'The chain was found caught outside the rear gear.',
        'It was reseated on the gear and its tension adjusted.',
        'The pedal was turned by hand; the chain stayed in place.',
      ],
      decoyTr: 'Bisikletin ön lambasının pili de azalmıştı.',
      decoyEn: 'The front light battery was also running low.',
      explanationTr: 'Önce bisiklet güvene alınır, sıkışma görülür, zincir oturtulur ve son olarak elle denenir.',
      explanationEn: 'The bicycle is secured first, the jam found, the chain reseated and then tested by hand.',
    ),
    StorySequenceDefinition(
      id: 'parcel_wrong_route',
      minimumStage: 1,
      titleTr: 'Yanlış aktarma',
      titleEn: 'The misrouted parcel',
      setupTr:
          'Paket beklenen şubeye gelmedi; tarama geçmişi rotayı açıklıyor.',
      setupEn: 'A parcel did not reach its expected branch; scan records reveal the route.',
      eventsTr: <String>[
        '{person}, {moment}, teslimat panosunda paketin planlanan saatte görünmediğini fark etti.',
        'Son tarama başka bir aktarma merkezinden geldi.',
        'Manifestodaki adresle etiket üzerindeki adres karşılaştırıldı.',
        'Etiketteki şube kodunun bir rakamı yanlış çıktı ve etiket yenilendi.',
        'Paket doğru araca yüklendi; sonraki taramada hedef şubeye ulaştığı görüldü.',
      ],
      eventsEn: <String>[
        '{person} noticed during {moment} that the parcel was absent from the delivery board.',
        'Its latest scan came from a different transfer hub.',
        'The address on the manifest was compared with the parcel label.',
        'One digit in the branch code was wrong, so the label was replaced.',
        'The parcel was loaded onto the correct van and later scanned at its destination branch.',
      ],
      decoyTr: 'Aynı gün şubeye üç yeni dağıtım aracı geldi.',
      decoyEn: 'Three new delivery vans arrived at the branch that day.',
      explanationTr: 'Son tarama yanlış aktarmayı buldurur; adres karşılaştırması kod hatasını ortaya çıkarır ve yeni tarama teslimi doğrular.',
      explanationEn: 'The scan points to a misroute; checking the label reveals the code error, and a later scan confirms delivery.',
    ),
    StorySequenceDefinition(
      id: 'allergy_order',
      minimumStage: 1,
      titleTr: 'Mutfak notu',
      titleEn: 'The kitchen note',
      setupTr: 'Bir müşteri alerjisini belirtti; mutfak siparişin nasıl güvenle hazırlandığını kaydetti.',
      setupEn: 'A guest disclosed an allergy; the kitchen logged how the order was prepared safely.',
      eventsTr: <String>[
        '{person}, {moment}, siparişi alan görevliye alerjisini söyledi.',
        'Görevli malzeme listesini kontrol edip mutfağa özel not iletti.',
        'Aşçı etiketi doğruladı ve temiz bir tava ayırdı.',
        'İkinci görevli tabak ve hazırlama yüzeyini çapraz bulaşma açısından kontrol etti.',
        'Sipariş notla birlikte servis edildi; müşteri içeriği görevliyle yeniden doğruladı.',
      ],
      eventsEn: <String>[
        '{person} told the server about an allergy during {moment}.',
        'The server checked the ingredient list and sent a clear kitchen note.',
        'The cook verified the label and set aside a clean pan.',
        'A second worker checked the plate and surface for cross-contact.',
        'The dish was served with its note, and the guest confirmed it with staff.',
      ],
      decoyTr: 'Müşteri masayı pencere kenarına almak istedi.',
      decoyEn: 'The guest asked to move the table near the window.',
      explanationTr: 'Alerji bilgisi siparişten önce kaydedilir; içerik ve temiz ekipman kontrolü servis öncesi yapılır.',
      explanationEn: 'The allergy is logged before preparation; ingredients and clean equipment are checked before serving.',
    ),
    StorySequenceDefinition(
      id: 'bridge_sensor',
      minimumStage: 3,
      titleTr: 'Köprü sensörü',
      titleEn: 'The bridge sensor',
      setupTr: 'Sensör değerleri önceki günle uyuşmadı; ekip ölçüm kaydını yeniden kurdu.',
      setupEn: 'Sensor readings disagreed with the prior day; the team reconstructed the measurement check.',
      eventsTr: <String>[
        '{person}, {moment}, sensörün beklenenden farklı sıfır değeri verdiğini kaydetti.',
        'Aynı noktadan bağımsız referans ölçümü alındı.',
        'Referans ile sensör arasındaki sabit kayma hesaplandı.',
        'Sensör bu kaymaya göre yeniden kalibre edildi.',
        'Aynı ölçüm tekrarlandı ve iki sonuç tolerans içinde eşleşti.',
      ],
      eventsEn: <String>[
        '{person} recorded an unexpected zero reading during {moment}.',
        'An independent reference reading was taken at the same point.',
        'The fixed offset between the reference and sensor was calculated.',
        'The sensor was recalibrated to account for that offset.',
        'The measurement was repeated and both readings matched within tolerance.',
      ],
      decoyTr: 'Köprüdeki trafik o sabah önceki günden daha yoğundu.',
      decoyEn: 'Traffic on the bridge was heavier than the day before.',
      explanationTr: 'Referans ölçüm kaymayı gösterir; kalibrasyon ancak tekrar ölçümle doğrulanır.',
      explanationEn: 'The reference exposes the offset; only a repeated reading can verify the calibration.',
    ),
    StorySequenceDefinition(
      id: 'water_sample',
      minimumStage: 3,
      titleTr: 'Su numunesi',
      titleEn: 'The water sample',
      setupTr: 'İlk sonuç şüpheliydi; saha ekibi numune zincirini denetledi.',
      setupEn: 'The first result was suspicious; the field team audited the sample chain.',
      eventsTr: <String>[
        '{person}, {moment}, ölçümde beklenmeyen bir değer gördü.',
        'Kayıt formundaki saat ile şişe etiketi karşılaştırıldı.',
        'Kontrol şişesinin açık bırakıldığı ve örneğe karışma olabileceği bulundu.',
        'Şüpheli numune sonuçtan çıkarılıp yeniden örnekleme planlandı.',
        'Yeni şişe kapatılıp etiketlendi; laboratuvara teslim saati forma yazıldı.',
      ],
      eventsEn: <String>[
        '{person} saw an unexpected reading during {moment}.',
        'The time on the form was compared with the bottle label.',
        'A control bottle had been left open, creating a contamination risk.',
        'The suspect sample was excluded and a resample arranged.',
        'The new bottle was sealed and labeled; its lab handoff time was logged.',
      ],
      decoyTr: 'Numune alınırken kıyıda bir tekne görülmüştü.',
      decoyEn: 'A boat had been visible near the shore during sampling.',
      explanationTr: 'Açık kontrol şişesi güvenilirliği bozar; doğru adım şüpheli sonucu dışlayıp izlenebilir yeni numune almaktır.',
      explanationEn: 'An open control compromises the result; the suspect sample is excluded and a traceable resample is taken.',
    ),
    StorySequenceDefinition(
      id: 'stage_projector',
      minimumStage: 3,
      titleTr: 'Sahne ışığı',
      titleEn: 'The stage light',
      setupTr: 'Prova sırasında projektör karardı; bakım notları arızanın giderilişini gösteriyor.',
      setupEn: 'A projector dimmed during rehearsal; maintenance notes trace the repair.',
      eventsTr: <String>[
        '{person}, {moment}, görüntünün prova ortasında solduğunu bildirdi.',
        'Operatör güç ve bağlantı kablolarını kontrol etti.',
        'Gevşek kablo sabitlendi; ışık kısa süre normale döndü.',
        'Cihaz ısınınca parlaklığın yine düştüğü gözlendi.',
        'Hava kanalı temizlendi ve tam prova boyunca parlaklık yeniden izlendi.',
      ],
      eventsEn: <String>[
        '{person} reported a dim image midway through rehearsal during {moment}.',
        'The operator checked power and connection cables.',
        'A loose cable was secured, briefly restoring the image.',
        'As the device warmed up, the brightness fell again.',
        'The air vent was cleaned and brightness monitored through a full rehearsal.',
      ],
      decoyTr: 'Sahne perdesinin rengi aynı gün değiştirildi.',
      decoyEn: 'The stage curtain color was changed that day.',
      explanationTr: 'Kablo düzeltmesi geçici iyileşme sağlar; ısınmayla yinelenen sorun havalandırma tıkanıklığını gösterir.',
      explanationEn: 'The cable fix is temporary; a repeat after warming points to blocked ventilation.',
    ),
    StorySequenceDefinition(
      id: 'archive_photo',
      minimumStage: 3,
      titleTr: 'Arşiv fotoğrafı',
      titleEn: 'The archive photo',
      setupTr:
          'Bir fotoğrafa tarih etiketi konmadan önce kanıtlar karşılaştırıldı.',
      setupEn: 'Evidence was compared before a date was assigned to an archive photo.',
      eventsTr: <String>[
        '{person}, {moment}, etiketsiz fotoğrafı arşiv kutusunda buldu.',
        'Arka yüzdeki stüdyo damgası kayda geçirildi.',
        'Damga tarihi, o stüdyonun açık olduğu yıllarla karşılaştırıldı.',
        'Fotoğraftaki bina ayrıntısı eski şehir planında eşleştirildi.',
        'İki ipucu birbiriyle uyuşunca tarih aralığı kaynaklarıyla etiketlendi.',
      ],
      eventsEn: <String>[
        '{person} found an undated photograph in an archive box during {moment}.',
        'The studio stamp on its back was recorded.',
        'The stamp date was checked against the years the studio operated.',
        'A building detail in the photo was matched to an old city map.',
        'When both clues agreed, the date range was labeled with its sources.',
      ],
      decoyTr: 'Kutudaki diğer fotoğrafların çoğu siyah beyazdı.',
      decoyEn: 'Most of the other photographs in the box were black and white.',
      explanationTr: 'Tek bir ipucuna yaslanmak yerine stüdyo kaydı ve bina ayrıntısı bağımsız biçimde eşleştirilir.',
      explanationEn: 'The studio record and building detail provide independent checks rather than relying on one clue.',
    ),
    StorySequenceDefinition(
      id: 'night_radar',
      minimumStage: 7,
      titleTr: 'Radar paraziti',
      titleEn: 'The radar interference',
      setupTr: 'Gece vardiyası ekranda kısa bir iz gördü; ekip hemen hedef varsayımı yapmadı.',
      setupEn: 'A night shift saw a brief trace on screen; the team did not assume it was a target.',
      eventsTr: <String>[
        '{person}, {moment}, ekranda kısa ve düzensiz bir iz gördü.',
        'İz, aynı saatteki hava ve cihaz günlükleriyle karşılaştırıldı.',
        'Yakındaki vericinin tam o sırada yeniden başladığı anlaşıldı.',
        'Anten yönü değiştirilince iz kayboldu; başka bir kanalda görünmedi.',
        'Ekip olayı hedef olarak değil, olası verici paraziti olarak kayda aldı.',
      ],
      eventsEn: <String>[
        '{person} saw a brief, irregular trace on screen during {moment}.',
        'The trace was compared with weather and equipment logs for the same time.',
        'A nearby transmitter had restarted at that exact moment.',
        'The trace vanished when the antenna direction changed and appeared on no other channel.',
        'The team logged possible transmitter interference, not a confirmed target.',
      ],
      decoyTr: 'Uzak istasyondan o saatte doğrulanmamış bir mesaj geldi.',
      decoyEn:
          'An unconfirmed message arrived from a distant station at that time.',
      explanationTr: 'Zaman eşleşmesi ve yön değişince kaybolma paraziti destekler; tek iz hedef doğrulaması değildir.',
      explanationEn: 'The timing and disappearance after reorientation support interference; one trace does not confirm a target.',
    ),
    StorySequenceDefinition(
      id: 'delivery_cold_chain',
      minimumStage: 7,
      titleTr: 'Soğuk teslimat',
      titleEn: 'The cold-chain delivery',
      setupTr: 'Isı kaydı sınırı aştı; ekip ürünü teslim etmeden önce zinciri inceledi.',
      setupEn: 'A temperature log crossed its limit; the team checked the chain before delivery.',
      eventsTr: <String>[
        '{person}, {moment}, kayıt cihazında sıcaklık sınırının aşıldığını gördü.',
        'Saat damgası teslim fişiyle eşleştirildi ve sapmanın taşıma sırasında başladığı bulundu.',
        'Mühür numarası çıkış kaydıyla karşılaştırıldı; numaralar eşleşti.',
        'Ürün teslim alanından ayrılmadan karantinaya alındı ve sorumluya haber verildi.',
        'Yedek kayıt cihazı doğrulanınca olay raporu ve teslim kararı güncellendi.',
      ],
      eventsEn: <String>[
        '{person} saw that the temperature limit had been crossed during {moment}.',
        'The timestamp was matched to the handoff slip; the deviation began in transit.',
        'The seal number was checked against dispatch records and matched.',
        'The item was held before leaving receiving, and the supervisor was notified.',
        'After the backup logger was verified, the incident report and release decision were updated.',
      ],
      decoyTr: 'Depo çalışanı o gün farklı bir koridorda görevlendirilmişti.',
      decoyEn:
          'A warehouse worker had been assigned to a different aisle that day.',
      explanationTr: 'Önce sapmanın zamanı ve mühür doğrulanır; ardından ürün korunur, yedek kayıt teyidiyle karar verilir.',
      explanationEn: 'The time and seal are checked first; the item is held while the backup record informs the decision.',
    ),
    StorySequenceDefinition(
      id: 'wind_turbine',
      minimumStage: 7,
      titleTr: 'Türbin titreşimi',
      titleEn: 'The turbine vibration',
      setupTr: 'Titreşim uyarısı rüzgâr arttığında çıktı; bakım ekibi parçayı hemen değiştirmedi.',
      setupEn: 'A vibration alert appeared as wind increased; maintenance did not replace a part immediately.',
      eventsTr: <String>[
        '{person}, {moment}, sensör uyarısının rüzgâr hızındaki artışla çakıştığını kaydetti.',
        'Titreşim, aynı rüzgâr aralığındaki önceki kayıtlarla karşılaştırıldı.',
        'Kule dibindeki referans sensörde aynı örüntü görülmedi.',
        'Teknik ekip kanadı durdurup gevşek bağlantı ve buzlanmayı inceledi.',
        'Bağlantı torku düzeltildikten sonra kontrollü çalıştırmada uyarı tekrarlanmadı.',
      ],
      eventsEn: <String>[
        '{person} noted during {moment} that the alert coincided with rising wind.',
        'Vibration was compared with earlier records at the same wind range.',
        'The reference sensor at the tower base showed no matching pattern.',
        'Technicians stopped the blade and inspected the joint and for icing.',
        'After torque was corrected, a controlled run produced no repeat alert.',
      ],
      decoyTr: 'Komşu türbinin üretimi o gün normalin üzerindeydi.',
      decoyEn: 'A neighboring turbine produced more power than usual that day.',
      explanationTr: 'Önce koşul eşleştirilir, referansla yerel sorun ayrılır, fiziksel inceleme yapılır ve kontrollü çalıştırma sonucu doğrular.',
      explanationEn: 'Conditions are matched, a reference separates local behavior, inspection guides repair, and a controlled run verifies it.',
    ),
    StorySequenceDefinition(
      id: 'science_control',
      minimumStage: 7,
      titleTr: 'Deney kontrolü',
      titleEn: 'The controlled experiment',
      setupTr: 'Yeni gübre denemesinde iki tepsi farklı büyüdü; ekip değişkenleri ayırdı.',
      setupEn: 'Two trays grew differently in a fertilizer trial; the team separated the variables.',
      eventsTr: <String>[
        '{person}, {moment}, tepsilerden birine gübre uygulanacağını ve diğerinin kontrol olacağını kaydetti.',
        'Aynı tür tohumlar eşit sayıda iki tepsiye dağıtıldı.',
        'Işık, su ve sıcaklık her iki tepside aynı tutuldu.',
        'Gübre yalnızca deneme tepsisine ölçülü biçimde eklendi.',
        'Büyüme aynı günlerde ölçüldü; sonuç farkı uygulama kaydıyla birlikte raporlandı.',
      ],
      eventsEn: <String>[
        '{person} logged that one tray would receive fertilizer and the other would be a control during {moment}.',
        'Equal numbers of the same seed type were placed in both trays.',
        'Light, water and temperature were kept the same for both.',
        'A measured amount of fertilizer was added only to the test tray.',
        'Growth was measured on the same days and reported with the application record.',
      ],
      decoyTr: 'Deneme tepsisinin rengi kontrol tepsisinden daha açıktı.',
      decoyEn: 'The test tray was a lighter color than the control tray.',
      explanationTr: 'Adil deneyde önce eşit başlangıç ve aynı koşullar kurulur; sonra tek değişken uygulanıp aynı yöntemle ölçülür.',
      explanationEn: 'A fair test establishes equal starting conditions, changes one variable, and measures both the same way.',
    ),
    StorySequenceDefinition(
      id: 'book_conservation',
      minimumStage: 7,
      titleTr: 'Kâğıt dalgalanması',
      titleEn: 'The rippled page',
      setupTr: 'Arşiv kitabının sayfaları dalgalandı; koruma ekibi müdahaleyi kayıtla yürüttü.',
      setupEn: 'Pages in an archive book rippled; conservators followed a documented process.',
      eventsTr: <String>[
        '{person}, {moment}, sayfa kenarlarındaki dalgalanmayı fotoğraflayıp kaydetti.',
        'Oda nemi kalibre edilmiş ayrı bir ölçerle kontrol edildi.',
        'Kitabın yakınında nemlendiricinin yanlışlıkla açık kaldığı bulundu.',
        'Nemlendirici kapatıldı; kitap doğrudan ısıdan uzakta kararlı ortama alındı.',
        'Nem kademeli değişirken sayfalar yeniden izlendi; fotoğraflar önceki kayıtla karşılaştırıldı.',
      ],
      eventsEn: <String>[
        '{person} photographed and logged the page rippling during {moment}.',
        'Room humidity was checked with a separate calibrated meter.',
        'A humidifier near the book had been left on by mistake.',
        'It was turned off, and the book was moved away from direct heat to a stable area.',
        'Pages were monitored as humidity changed gradually and compared with the first photos.',
      ],
      decoyTr: 'Kitabın kapağındaki renk solması geçen yıl fark edilmişti.',
      decoyEn: 'Fading on the cover had been noticed the previous year.',
      explanationTr: 'Hasar önce kaydedilir, ortam bağımsız ölçülür, kaynak bulunup kontrollü biçimde kaldırılır ve değişim izlenir.',
      explanationEn: 'The damage is documented, conditions independently measured, the source removed carefully, and changes monitored.',
    ),
    StorySequenceDefinition(
      id: 'message_relay',
      minimumStage: 9,
      titleTr: 'Mesaj zinciri',
      titleEn: 'The message relay',
      setupTr: 'Ekipler farklı talimat aldı; gönderim kayıtları doğru mesajı bulmayı sağladı.',
      setupEn: 'Teams received conflicting instructions; dispatch records identified the valid message.',
      eventsTr: <String>[
        '{person}, {moment}, iki ekipten birbiriyle çelişen talimat geldiğini duydu.',
        'Her mesajın gönderim saati ve onay kodu kaydedildi.',
        'Daha eski mesajın, yeni plan onaylanmadan önce yola çıktığı anlaşıldı.',
        'Vardiya sorumlusu geçerli planı tek kanaldan yeniden yayımladı.',
        'Ekipler yeni kodu geri okuyup onayladı; eski talimat iptal edildi.',
      ],
      eventsEn: <String>[
        '{person} heard two teams report conflicting instructions during {moment}.',
        'The send time and approval code for each message were recorded.',
        'The older message had left before the revised plan was approved.',
        'The shift lead reissued the valid plan through one channel.',
        'Teams read back the new code; the older instruction was cancelled.',
      ],
      decoyTr: 'Mesajlardan birinde yazım hatası bulunuyordu.',
      decoyEn: 'One of the messages contained a spelling mistake.',
      explanationTr: 'Önce zaman ve onay izlenir; geçerli plan tek kanaldan tekrarlanıp geri okuma ile doğrulanır.',
      explanationEn: 'Approval and timing establish the valid plan; a single-channel reissue is confirmed by read-back.',
    ),
    StorySequenceDefinition(
      id: 'invoice_mismatch',
      minimumStage: 9,
      titleTr: 'Fatura farkı',
      titleEn: 'The invoice mismatch',
      setupTr: 'Faturadaki toplam, sipariş kaydıyla uyuşmadı; muhasebe kalemleri geriye doğru izledi.',
      setupEn: 'An invoice total did not match the order record; accounting traced the line items.',
      eventsTr: <String>[
        '{person}, {moment}, fatura toplamının onaylanan siparişten yüksek olduğunu fark etti.',
        'Sipariş satırları teslim fişindeki miktarlarla tek tek karşılaştırıldı.',
        'Fişte bulunmayan ek birim ücretin faturaya işlendiği görüldü.',
        'Ücretin dayanağı sağlayıcıya soruldu ve sözleşmede karşılığı bulunmadı.',
        'Düzeltilmiş fatura istendi; yeni toplam sipariş ve teslim kayıtlarıyla eşleştirildi.',
      ],
      eventsEn: <String>[
        '{person} noticed during {moment} that the invoice exceeded the approved order.',
        'Order lines were checked one by one against the delivery slip.',
        'An extra unit fee not shown on the slip appeared on the invoice.',
        'The provider was asked for its basis; no matching contract term was found.',
        'A corrected invoice was requested and reconciled with order and delivery records.',
      ],
      decoyTr: 'Fatura, sağlayıcının yeni logosuyla basılmıştı.',
      decoyEn: 'The invoice carried the provider’s new logo.',
      explanationTr: 'Toplamdan doğrudan itiraz etmek yerine miktar, ücret dayanağı ve sözleşme sırasıyla kontrol edilir.',
      explanationEn: 'Rather than disputing the total alone, quantity, fee basis and contract are checked in sequence.',
    ),
    StorySequenceDefinition(
      id: 'satellite_shadow',
      minimumStage: 9,
      titleTr: 'Haritadaki gölge',
      titleEn: 'The map shadow',
      setupTr: 'Uydu görüntüsünde yeni bir yapı sanılan koyu şekil görüldü; analist ikinci kanıt aradı.',
      setupEn: 'A dark shape in satellite imagery looked like a new structure; an analyst sought another check.',
      eventsTr: <String>[
        '{person}, {moment}, görüntüde önceki haritada olmayan koyu bir şekil işaretledi.',
        'Görüntünün çekim saati ve güneş açısı kaydından bulundu.',
        'Yakın tarihli ikinci görüntü aynı bölgeyi farklı açıdan gösterdi.',
        'Şeklin bina değil, güneş açısıyla uzayan mevcut ağacın gölgesi olduğu anlaşıldı.',
        'Harita notu düzeltildi ve ilk yorum kesin yapı tespiti olarak yayımlanmadı.',
      ],
      eventsEn: <String>[
        '{person} marked a dark shape absent from the earlier map during {moment}.',
        'The image capture time and sun angle were retrieved.',
        'A recent second image showed the same area from another angle.',
        'The shape proved to be the existing tree’s shadow, lengthened by the sun angle.',
        'The map note was corrected and the first reading was not published as a confirmed structure.',
      ],
      decoyTr: 'Bölgeye giden ana yol o hafta onarıma alınmıştı.',
      decoyEn: 'The main road to the area was under repair that week.',
      explanationTr: 'Görüntü zamanı ve ikinci açı, şeklin yapı değil gölge olduğunu gösterir; ilk izlenim doğrulanmadan kesinleştirilmez.',
      explanationEn: 'Capture time and a second angle reveal a shadow, so the first impression is not stated as fact.',
    ),
    StorySequenceDefinition(
      id: 'air_filter_alarm',
      minimumStage: 10,
      titleTr: 'Filtre uyarısı',
      titleEn: 'The filter alarm',
      setupTr: 'Hava akışı alarmı aralıklı çaldı; ekip sensörü ve filtreyi ayrı ayrı sınadı.',
      setupEn: 'An airflow alarm sounded intermittently; the team tested the sensor and filter separately.',
      eventsTr: <String>[
        '{person}, {moment}, alarmın yalnızca yüksek fan hızında çaldığını kaydetti.',
        'Sensör değeri bağımsız ölçerle karşılaştırıldı ve sensör doğru bulundu.',
        'Filtre çıkarılmadan önce basınç farkı giriş ve çıkışta ölçüldü.',
        'Filtredeki tıkanma temizlendi; aynı hızda hava akışı yeniden ölçüldü.',
        'Alarm sınırın altında kaldı; bakım kaydı ölçümlerle kapatıldı.',
      ],
      eventsEn: <String>[
        '{person} logged during {moment} that the alarm sounded only at high fan speed.',
        'The sensor was compared with an independent meter and found accurate.',
        'Pressure difference was measured on both sides before removing the filter.',
        'The blockage was cleared and airflow remeasured at the same speed.',
        'The reading stayed below the alarm threshold, and the logged measurements closed the service record.',
      ],
      decoyTr: 'Fan motorunun dış yüzeyinde toz birikmişti.',
      decoyEn: 'Dust had collected on the outside of the fan motor.',
      explanationTr: 'Sensör doğrulanınca basınç farkı filtreyi işaret eder; aynı hızdaki tekrar ölçümü onarımın etkisini sınar.',
      explanationEn: 'Once the sensor is verified, the pressure difference points to the filter; a same-speed retest checks the repair.',
    ),
    StorySequenceDefinition(
      id: 'power_backup',
      minimumStage: 10,
      titleTr: 'Yedek güç',
      titleEn: 'The backup power',
      setupTr: 'Kısa kesintide yedek sistem devreye girmedi; ekip bataryayı hemen suçlamadı.',
      setupEn: 'A backup system failed to engage during a short outage; the team did not blame the battery immediately.',
      eventsTr: <String>[
        '{person}, {moment}, ana güç kesilince kayıt sisteminin kapandığını gördü.',
        'Kesinti kaydı ve yedek sistemin başlama komutu zaman damgasıyla karşılaştırıldı.',
        'Komutun bataryaya ulaştığı, ancak aktarım rölesinin açılmadığı bulundu.',
        'Röle bağlantısı üretici şemasına göre kontrol edilip gevşek uç sabitlendi.',
        'Kısa, denetimli güç kesintisinde yedek sistem doğru sırayla devreye girdi.',
      ],
      eventsEn: <String>[
        '{person} saw the logging system shut down when main power failed during {moment}.',
        'The outage record was compared with the backup start command timestamp.',
        'The command reached the battery, but the transfer relay did not open.',
        'The relay connection was checked against the wiring diagram and a loose terminal secured.',
        'A brief supervised outage showed the backup engaging in the correct order.',
      ],
      decoyTr: 'Batarya kutusunun üretim tarihi geçen yıldı.',
      decoyEn: 'The battery casing had been manufactured the previous year.',
      explanationTr: 'Zaman kayıtları komutun ulaştığını gösterir; arıza aktarım rölesindedir ve kontrollü kesinti onarımı doğrular.',
      explanationEn: 'The timestamps show the command arrived; the fault is at the transfer relay, confirmed by a supervised test.',
    ),
    StorySequenceDefinition(
      id: 'signal_false_alarm',
      minimumStage: 10,
      titleTr: 'Yanlış alarm',
      titleEn: 'The false alarm',
      setupTr: 'Aynı kapı sensörü iki kez alarm verdi; ekip olayları tek tek eşleştirdi.',
      setupEn: 'The same door sensor alarmed twice; the team aligned the events before deciding.',
      eventsTr: <String>[
        '{person}, {moment}, ilk alarm saatini güvenlik kaydına yazdı.',
        'Kamera görüntüsü kapının açılmadığını, fakat yan panelin sallandığını gösterdi.',
        'İkinci alarm saati havalandırma fanının çalışmasıyla eşleştirildi.',
        'Panel bağlantısı sıkıldı; fan çalışırken sensör açıklığı yeniden ölçüldü.',
        'Yeni denemede alarm oluşmadı; kayıt “yetkisiz giriş” değil titreşim uyarısı olarak düzeltildi.',
      ],
      eventsEn: <String>[
        '{person} entered the first alarm time in the security log during {moment}.',
        'Video showed the door stayed shut while its side panel shook.',
        'The second alarm time matched the ventilation fan starting.',
        'The panel was secured and sensor clearance remeasured with the fan running.',
        'A retest produced no alarm, and the record was corrected from entry to vibration alert.',
      ],
      decoyTr: 'Güvenlik görevlisi alarmdan önce koridor ışığını açmıştı.',
      decoyEn: 'The guard had turned on the hallway light before the alarm.',
      explanationTr: 'Görüntü ve fan zamanlaması kapı açılmasını desteklemez; panel titreşimi giderilip olay kaydı buna göre düzeltilir.',
      explanationEn: 'Video and fan timing do not support an entry; the panel vibration is corrected and the record updated.',
    ),
  ];

  final StorySequenceDefinition story;
  final StoryOrderVariant variant;
  final int stage;
  final bool english;
  final bool isPractice;
  final int round;
  final List<StorySequenceCard> cards;
  final List<String> expectedIds;
  final String setup;
  final String title;
  final String explanation;

  bool get hasDecoy => cards.any((StorySequenceCard card) => card.isDecoy);
  int get requiredEvents => expectedIds.length;

  String get boardSignature {
    final List<String> textCards =
        cards.map((StorySequenceCard card) => card.text).toList()..sort();
    return <String>[story.id, '${variant.id}', ...textCards].join('|');
  }

  bool acceptsSequence(List<String> ids) {
    if (ids.length != expectedIds.length) return false;
    for (int index = 0; index < ids.length; index++) {
      if (ids[index] != expectedIds[index]) return false;
    }
    return true;
  }

  static StoryOrderScenario forCampaignLevel(
    int level, {
    bool english = false,
  }) {
    if (level < 1 || level > campaignLevels) {
      throw RangeError.range(level, 1, campaignLevels);
    }
    return _build(
      storyIndex: level - 1,
      variantIndex: 0,
      stage: level,
      english: english,
      isPractice: false,
      round: level,
      seed: ContentSeed.forLevel(gameId: 'story_order:campaign', level: level),
    );
  }

  static StoryOrderScenario forPracticeRound(
    int round, {
    bool english = false,
  }) {
    if (round < 1 || round > uniquePracticeRounds) {
      throw RangeError.range(round, 1, uniquePracticeRounds);
    }
    return _build(
      storyIndex: (round - 1) % _bank.length,
      variantIndex: ((round - 1) ~/ _bank.length) + 1,
      stage: ((round - 1) % campaignLevels) + 1,
      english: english,
      isPractice: true,
      round: round,
      seed: ContentSeed.forLevel(gameId: 'story_order:practice', level: round),
    );
  }

  static StoryOrderScenario _build({
    required int storyIndex,
    required int variantIndex,
    required int stage,
    required bool english,
    required bool isPractice,
    required int round,
    required int seed,
  }) {
    final StorySequenceDefinition story = _bank[storyIndex];
    final StoryOrderVariant variant = _variants[variantIndex];
    final bool expert = stage >= 7;
    final List<String> sourceEvents = english ? story.eventsEn : story.eventsTr;
    if (sourceEvents.length != 5 ||
        (english ? story.eventsTr : story.eventsEn).length != 5) {
      throw StateError('Story ${story.id} must have five bilingual steps.');
    }
    final List<String> eventTexts = sourceEvents
        .map((String value) => _personalize(value, variant, english))
        .toList(growable: false);
    final int eventCount = expert ? 5 : 4;
    final List<StorySequenceCard> cards = List<StorySequenceCard>.generate(
      eventCount,
      (int index) => StorySequenceCard(
        id: '${story.id}_step_$index',
        text: eventTexts[index],
        isDecoy: false,
        canonicalOrder: index,
      ),
      growable: true,
    );
    if (expert) {
      cards.add(
        StorySequenceCard(
          id: '${story.id}_side_note',
          text: _personalize(
            english ? story.decoyEn : story.decoyTr,
            variant,
            english,
          ),
          isDecoy: true,
          canonicalOrder: -1,
        ),
      );
    }
    cards.shuffle(math.Random(seed));
    return StoryOrderScenario(
      story: story,
      variant: variant,
      stage: stage,
      english: english,
      isPractice: isPractice,
      round: round,
      cards: List<StorySequenceCard>.unmodifiable(cards),
      expectedIds: List<String>.unmodifiable(
        List<String>.generate(
          eventCount,
          (int index) => '${story.id}_step_$index',
        ),
      ),
      setup: _personalize(
        english ? story.setupEn : story.setupTr,
        variant,
        english,
      ),
      title: english ? story.titleEn : story.titleTr,
      explanation: english ? story.explanationEn : story.explanationTr,
    );
  }

  static String _personalize(
    String source,
    StoryOrderVariant variant,
    bool english,
  ) {
    return source
        .replaceAll('{person}', english ? variant.personEn : variant.personTr)
        .replaceAll('{moment}', english ? variant.momentEn : variant.momentTr);
  }
}
