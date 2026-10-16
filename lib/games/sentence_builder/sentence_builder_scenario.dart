import 'dart:math' as math;

import '../shared/content_seed.dart';

class SentenceCard {
  const SentenceCard({
    required this.id,
    required this.minimumStage,
    required this.partsTr,
    required this.partsEn,
    required this.contextTr,
    required this.contextEn,
    required this.clueTr,
    required this.clueEn,
    required this.noteTr,
    required this.noteEn,
  });

  final String id;
  final int minimumStage;
  final List<String> partsTr;
  final List<String> partsEn;
  final String contextTr;
  final String contextEn;
  final String clueTr;
  final String clueEn;
  final String noteTr;
  final String noteEn;
}

class SentenceBoardCard {
  const SentenceBoardCard({
    required this.sentence,
    required this.scrambledTr,
    required this.scrambledEn,
  });

  final SentenceCard sentence;
  final List<String> scrambledTr;
  final List<String> scrambledEn;
}

/// Rebuild short, contextual sentences from meaningful clause blocks.
/// Blocks—not letters—are shuffled, so higher stages test syntax and cohesion.
class SentenceBuilderScenario {
  const SentenceBuilderScenario({
    required this.stage,
    required this.cards,
    required this.isPractice,
    required this.round,
  });

  static const int campaignLevels = 20;
  static const int uniquePracticeRounds = 300;

  static const List<SentenceCard> _bank = <SentenceCard>[
    SentenceCard(
      id: 'daily_journal',
      minimumStage: 1,
      partsTr: <String>[
        'Her akşam',
        'kısa bir not yazar',
        've gününü değerlendirirdi.',
      ],
      partsEn: <String>[
        'Every evening,',
        'she wrote a short note',
        'and reflected on her day.',
      ],
      contextTr: 'Düzenli bir günlük alışkanlığı anlatılıyor.',
      contextEn: 'A steady journaling habit is being described.',
      clueTr: 'Zaman bildiren öbek başta; iki eylem “ve” ile bağlanıyor.',
      clueEn: 'The time phrase leads; two actions are joined by “and”.',
      noteTr: 'Zaman öbeği cümleyi açar; bağlı eylemler anlamca paraleldir.',
      noteEn: 'A time phrase opens the sentence; the two actions are parallel.',
    ),
    SentenceCard(
      id: 'rain_returns',
      minimumStage: 1,
      partsTr: <String>[
        'Yağmur diner dinmez',
        'ekip',
        'açık hava çalışmasına',
        'yeniden başladı.',
      ],
      partsEn: <String>[
        'As soon as the rain stopped,',
        'the team',
        'its outdoor work',
        'resumed.',
      ],
      contextTr: 'Hava koşulları yüzünden ara verilen bir çalışma.',
      contextEn: 'Work had paused because of the weather.',
      clueTr: '“-mez” yapılı zaman bölümü önce gelir; yüklem en sonda.',
      clueEn: 'The “as soon as” time clause comes first; the verb closes.',
      noteTr: '“Diner dinmez” iki olay arasındaki çok kısa aralığı belirtir.',
      noteEn: '“As soon as” marks the short interval between two events.',
    ),
    SentenceCard(
      id: 'quiet_library',
      minimumStage: 1,
      partsTr: <String>[
        'Kütüphane sessizleşince',
        'öğrenciler',
        'notlarını daha rahat',
        'gözden geçirdi.',
      ],
      partsEn: <String>[
        'When the library grew quiet,',
        'the students',
        'reviewed their notes',
        'more comfortably.',
      ],
      contextTr: 'Kalabalık dağıldıktan sonraki çalışma anı.',
      contextEn: 'A study moment after the crowd had left.',
      clueTr: '“-ince” zaman/koşul bölümünü, “öğrenciler” özneyi gösterir.',
      clueEn:
          'The “when” clause sets the scene; “the students” is the subject.',
      noteTr: 'Zarf-fiil eki “-ince” ana eylemin ne zaman olduğunu bağlar.',
      noteEn: 'The “when” clause tells us when the main action happened.',
    ),
    SentenceCard(
      id: 'small_steps',
      minimumStage: 1,
      partsTr: <String>[
        'Küçük adımlar',
        'zamanla',
        'büyük bir değişim',
        'yaratabilir.',
      ],
      partsEn: <String>[
        'Small steps',
        'over time',
        'can create',
        'a major change.',
      ],
      contextTr: 'Uzun vadeli ilerleme üzerine bir gözlem.',
      contextEn: 'An observation about long-term progress.',
      clueTr: 'Özne “küçük adımlar”; olasılık bildiren yüklem sondadır.',
      clueEn: '“Small steps” is the subject; the modal verb closes the Turkish line.',
      noteTr: 'Türkçede temel dizilim çoğunlukla özne + tümleç + yüklemdir.',
      noteEn: 'A common Turkish pattern places the predicate at the end.',
    ),
    SentenceCard(
      id: 'careful_reader',
      minimumStage: 1,
      partsTr: <String>[
        'Dikkatli bir okur',
        'önce başlığı inceler,',
        'sonra metindeki kanıtları',
        'karşılaştırır.',
      ],
      partsEn: <String>[
        'A careful reader',
        'first examines the title,',
        'then compares',
        'the evidence in the text.',
      ],
      contextTr: 'Bir metni incelemek için izlenen yöntem.',
      contextEn: 'A method for examining a text.',
      clueTr: '“Önce/sonra” sıralaması iki eylemin yerini belirler.',
      clueEn: '“First/then” fixes the order of the two actions.',
      noteTr:
          'Sıralama bağlaçları, eylemler arasındaki zaman ilişkisini kurar.',
      noteEn: 'Sequence words make the relationship between actions explicit.',
    ),
    SentenceCard(
      id: 'missed_train',
      minimumStage: 3,
      partsTr: <String>[
        'Otobüs beklenenden geç gelince,',
        'Mina',
        'treni kaçırmamak için',
        'istasyona yürüdü.',
      ],
      partsEn: <String>[
        'When the bus arrived later than expected,',
        'Mina',
        'walked to the station',
        'to avoid missing the train.',
      ],
      contextTr: 'Gecikme, yolcunun ulaşım planını değiştirdi.',
      contextEn: 'A delay changed a passenger’s travel plan.',
      clueTr: 'Sebep-sonuç sırası: otobüs gecikmesi → istasyona yürüme.',
      clueEn: 'Follow cause to response: bus delay → walk to the station.',
      noteTr: 'İlk zarf-fiil bölümü sebebi, “-mamak için” amacı açıklar.',
      noteEn:
          'The opening clause gives the cause; “to avoid” gives the purpose.',
    ),
    SentenceCard(
      id: 'garden_birds',
      minimumStage: 3,
      partsTr: <String>[
        'Sabah güneşi yükselirken',
        'bahçedeki kuşlar',
        'çitlerin üzerinde',
        'ötmeye başladı.',
      ],
      partsEn: <String>[
        'As the morning sun rose,',
        'the birds in the garden',
        'on top of the fences,',
        'began to sing.',
      ],
      contextTr: 'Günün başlangıcından sakin bir görüntü.',
      contextEn: 'A quiet scene at the start of the day.',
      clueTr: 'Zaman bölümü başta, özne ondan sonra gelir.',
      clueEn: 'The time clause leads, followed by the subject.',
      noteTr:
          '“-ken” eki, sürmekte olan bir eylem sırasında gerçekleşeni anlatır.',
      noteEn: '“As” links an action in progress with the event that follows.',
    ),
    SentenceCard(
      id: 'clear_instructions',
      minimumStage: 3,
      partsTr: <String>[
        'Talimatları dikkatle okuyup',
        'parçaları renklerine göre ayıran ekip,',
        'düzeni',
        'hızla tamamladı.',
      ],
      partsEn: <String>[
        'After reading the instructions carefully',
        'and sorting the pieces by color,',
        'the team',
        'finished the layout quickly.',
      ],
      contextTr: 'İyi planlama, ortak bir işi hızlandırdı.',
      contextEn: 'Good planning helped a group finish a task quickly.',
      clueTr: 'Özne “ayıran ekip”; önce iki hazırlık işi gerçekleşir.',
      clueEn: 'The team is the subject; two preparatory actions come first.',
      noteTr: 'Özne bir sıfat-fiil öbeği içerdiğinden tek parça tutulmalıdır.',
      noteEn:
          'The subject contains a relative clause and should stay together.',
    ),
    SentenceCard(
      id: 'returning_book',
      minimumStage: 3,
      partsTr: <String>[
        'Süresi dolmadan kitabı iade ettiği için,',
        'Ada',
        'başka bir kitabı',
        'aynı gün alabildi.',
      ],
      partsEn: <String>[
        'Because she returned the book before it was due,',
        'Ada',
        'could borrow',
        'another one that same day.',
      ],
      contextTr: 'Zamanında yapılan bir işlem yeni bir olanağı açtı.',
      contextEn: 'An on-time action opened up another opportunity.',
      clueTr: '“-dığı için” sebep bölümüdür; sonuç yüklemi son parçadadır.',
      clueEn: '“Because” gives the reason; the result is in the final block.',
      noteTr: 'Sebep bölümü ile sonuç cümlesi virgülle ayrılır.',
      noteEn: 'A comma separates the opening reason clause from its result.',
    ),
    SentenceCard(
      id: 'budget_choice',
      minimumStage: 5,
      partsTr: <String>[
        'Geliri bu ay azalınca,',
        'Deniz',
        'harcamalarını gözden geçirdi',
        've daha uygun bir plan seçti.',
      ],
      partsEn: <String>[
        'When her income fell this month,',
        'Deniz',
        'reviewed her spending',
        'and chose a more affordable plan.',
      ],
      contextTr: 'Değişen koşullar üzerine alınan bir karar.',
      contextEn: 'A decision made in response to changing circumstances.',
      clueTr: 'Önce koşul, sonra özne ve birbirine bağlı iki eylem gelir.',
      clueEn:
          'Put the condition first, then the subject and two linked actions.',
      noteTr: '“Ve” aynı öznenin yaptığı iki eylemi eş düzeyde bağlar.',
      noteEn: '“And” joins two actions performed by the same subject.',
    ),
    SentenceCard(
      id: 'museum_map',
      minimumStage: 5,
      partsTr: <String>[
        'Müzeye girmeden önce',
        'ziyaretçiler',
        'salonların yerini gösteren haritayı',
        'inceledi.',
      ],
      partsEn: <String>[
        'Before entering the museum,',
        'the visitors',
        'studied the map',
        'showing where the galleries were.',
      ],
      contextTr: 'Bir gezi başlamadan yapılan hazırlık.',
      contextEn: 'Preparation before a visit begins.',
      clueTr: '“-meden önce” bölümü zamanı, “ziyaretçiler” özneyi verir.',
      clueEn: '“Before” sets the timing; “the visitors” is the subject.',
      noteTr: '“-meden önce” eylemin ana eylemden daha önce olduğunu belirtir.',
      noteEn: '“Before” marks the action that happens earlier.',
    ),
    SentenceCard(
      id: 'prototype_test',
      minimumStage: 5,
      partsTr: <String>[
        'İlk prototipi hazırladıktan sonra,',
        'tasarımcı',
        'kullanıcıların geri bildirimlerini',
        'dikkatle sınıflandırdı.',
      ],
      partsEn: <String>[
        'After preparing the first prototype,',
        'the designer',
        'carefully grouped',
        'the users’ feedback.',
      ],
      contextTr: 'Bir ürün tasarımında test ve iyileştirme adımı.',
      contextEn: 'A testing and refinement step in product design.',
      clueTr: '“-dıktan sonra” hazırlık eylemini önceye yerleştirir.',
      clueEn: '“After” places the preparation before the main action.',
      noteTr: 'Zaman eki eylemler arasında açık bir önce-sonra ilişkisi kurar.',
      noteEn: 'The time marker makes the order of the two actions explicit.',
    ),
    SentenceCard(
      id: 'weather_plan',
      minimumStage: 5,
      partsTr: <String>[
        'Hava tahmini değiştiği hâlde,',
        'organizasyon ekibi',
        'etkinliği iptal etmek yerine',
        'kapalı salona taşıdı.',
      ],
      partsEn: <String>[
        'Although the forecast changed,',
        'the event team',
        'instead of cancelling the event,',
        'moved it indoors.',
      ],
      contextTr: 'Beklenmedik bir engel, planı tamamen durdurmadı.',
      contextEn: 'An unexpected obstacle did not stop the plan entirely.',
      clueTr: '“-dığı hâlde” karşıtlık bildirir; son eylem seçilen çözümdür.',
      clueEn:
          '“Although” introduces contrast; the final action is the solution.',
      noteTr: 'Karşıtlık bağlacı, tahmin ve ekibin tepkisini karşılaştırır.',
      noteEn:
          'The contrast marker sets the forecast against the team’s response.',
    ),
    SentenceCard(
      id: 'science_claim',
      minimumStage: 7,
      partsTr: <String>[
        'Ölçümlerin birbirini doğrulamadığını fark eden araştırmacı,',
        'sonucu açıklamadan önce',
        'ikinci bir deney düzenledi',
        've kayıtları yeniden denetledi.',
      ],
      partsEn: <String>[
        'After noticing that the measurements did not agree,',
        'the researcher',
        'ran a second experiment',
        'and checked the records again before explaining the result.',
      ],
      contextTr: 'Tutarsız veriye karşı temkinli bilimsel yaklaşım.',
      contextEn: 'A cautious scientific response to inconsistent data.',
      clueTr: 'Kanıt sorunu önce belirtilir; iki doğrulama eylemi yüklemi tamamlar.',
      clueEn:
          'The evidence problem comes first; two checks complete the response.',
      noteTr: 'Sıfat-fiil öbeği özneyi niteler; virgül yüklemden önceki uzun özneyi kapatır.',
      noteEn: 'A relative clause modifies the subject; punctuation closes the long subject.',
    ),
    SentenceCard(
      id: 'editor_source',
      minimumStage: 7,
      partsTr: <String>[
        'Metni yayıma göndermeden önce,',
        'editör',
        'tarihleri iki bağımsız kaynakla karşılaştırdı',
        've çelişen bilgiyi not etti.',
      ],
      partsEn: <String>[
        'Before sending the article to publication,',
        'the editor',
        'compared the dates against two independent sources',
        'and noted the conflicting detail.',
      ],
      contextTr: 'Yayımdan önce yapılan doğrulama işlemi.',
      contextEn: 'A fact-checking step before publication.',
      clueTr: '“-meden önce” hazırlığı başa alır; “ve” ikinci kontrolü ekler.',
      clueEn: '“Before” leads with preparation; “and” adds the second check.',
      noteTr: 'Eş görevli iki yüklem aynı özneye bağlıdır.',
      noteEn: 'The coordinated predicates share one subject.',
    ),
    SentenceCard(
      id: 'quiet_signal',
      minimumStage: 7,
      partsTr: <String>[
        'Konuşmacı önemli noktaya yaklaşırken',
        'salondaki uğultu',
        'yavaşça azaldı,',
        'ancak kimse',
        'telefonunu bırakmadı.',
      ],
      partsEn: <String>[
        'As the speaker approached the key point,',
        'the murmur in the room',
        'gradually faded,',
        'but no one',
        'put their phone away.',
      ],
      contextTr: 'Beklentinin tam karşılanmadığı bir sunum anı.',
      contextEn: 'A presentation moment that did not meet expectations.',
      clueTr:
          '“Ancak” beklentiyi tersine çevirir ve ikinci cümlenin başındadır.',
      clueEn: '“But” introduces the contrast and starts the second clause.',
      noteTr: 'Virgül ve “ancak” iki karşıt gözlemi birbirine bağlar.',
      noteEn: 'The comma and “but” link two contrasting observations.',
    ),
    SentenceCard(
      id: 'if_battery',
      minimumStage: 7,
      partsTr: <String>[
        'Pil tamamen bitmeden',
        'cihazını şarj eden kullanıcılar,',
        'uzun yolculukta',
        'beklenmedik kesintileri',
        'önleyebilir.',
      ],
      partsEn: <String>[
        'Users who charge their device',
        'before the battery runs out',
        'can avoid',
        'unexpected interruptions',
        'on a long trip.',
      ],
      contextTr: 'Yolculuk sırasında cihazın kapanmasını önleme.',
      contextEn: 'Preventing a device from shutting down during travel.',
      clueTr:
          'Özne “şarj eden kullanıcılar”; koşul tümleci ana eylemi sınırlar.',
      clueEn:
          'The users are the subject; the condition limits the main action.',
      noteTr: 'Özne içindeki sıfat-fiil, “kullanıcılar”ı tanımlar.',
      noteEn: 'The relative clause identifies which users are meant.',
    ),
    SentenceCard(
      id: 'map_mistake',
      minimumStage: 7,
      partsTr: <String>[
        'Haritadaki işaretin yanlış olduğunu anlayınca,',
        'rehber',
        'grubu geri çevirdi',
        've güvenli patikaya yönlendirdi.',
      ],
      partsEn: <String>[
        'When she realized the map marker was wrong,',
        'the guide',
        'turned the group around',
        'and directed them to the safe trail.',
      ],
      contextTr: 'Yanlış yön bilgisinin fark edilmesiyle alınan önlem.',
      contextEn: 'A corrective action after discovering wrong directions.',
      clueTr: 'Fark etme önce, iki ardışık yönlendirme eylemi sonra gelir.',
      clueEn: 'The discovery comes first, followed by two corrective actions.',
      noteTr: '“-ınca” olayın ardından gelen tepkiyi zaman bakımından bağlar.',
      noteEn: '“When” links the discovery to the response that followed.',
    ),
    SentenceCard(
      id: 'although_short',
      minimumStage: 9,
      partsTr: <String>[
        'Rapor kısa görünse de,',
        'her öneri',
        'ölçülebilir bir hedefe',
        've doğrulanmış bir kaynağa',
        'dayanıyordu.',
      ],
      partsEn: <String>[
        'Although the report looked brief,',
        'each recommendation',
        'was based on a measurable goal',
        'and a verified source.',
      ],
      contextTr: 'Kısa bir raporun arkasındaki kanıt standardı.',
      contextEn: 'The evidence standard behind a concise report.',
      clueTr: '“-se de” görünüş ile gerçek içerik arasında karşıtlık kurar.',
      clueEn: '“Although” contrasts how it looked with what supported it.',
      noteTr: 'Karşıtlık bölümünün ardından ana yargı gelir.',
      noteEn: 'The main clause follows the concessive opening.',
    ),
    SentenceCard(
      id: 'archive_found',
      minimumStage: 9,
      partsTr: <String>[
        'Arşivde beklenen belgeyi bulamayınca,',
        'ekip',
        'tarihli yazışmaları taradı,',
        'tanık notlarını karşılaştırdı',
        've araştırma sınırını yeniden belirledi.',
      ],
      partsEn: <String>[
        'When the expected document was missing from the archive,',
        'the team',
        'searched dated correspondence,',
        'compared witness notes,',
        'and reset the scope of the investigation.',
      ],
      contextTr: 'Bir araştırmada eksik kanıt karşısında izlenen yol.',
      contextEn: 'How a research team responds to missing evidence.',
      clueTr:
          '“-mayınca” sebep/koşul; virgülle ayrılan üç eylem çözüm zinciridir.',
      clueEn: 'The opening gives the problem; three coordinated actions form a response.',
      noteTr: 'Noktalama, uzun eylem dizisini okunur kılar.',
      noteEn: 'Punctuation keeps a long series of actions readable.',
    ),
    SentenceCard(
      id: 'unless_backup',
      minimumStage: 9,
      partsTr: <String>[
        'Düzenli yedek alınmadıkça,',
        'tek bir arıza',
        'uzun süreli veri kaybına',
        'yol açabilir.',
      ],
      partsEn: <String>[
        'Unless backups are made regularly,',
        'a single failure',
        'can lead',
        'to prolonged data loss.',
      ],
      contextTr: 'Veri güvenliği için sürekli alınması gereken önlem.',
      contextEn: 'An ongoing precaution for data security.',
      clueTr: '“-madıkça” gerçekleşmezse sonucu belirten koşul bölümüdür.',
      clueEn: '“Unless” introduces the condition that can cause the result.',
      noteTr: 'Koşul cümlesi, ana yargının hangi durumda geçerli olduğunu gösterir.',
      noteEn: 'The opening condition explains when the main claim applies.',
    ),
    SentenceCard(
      id: 'despite_warning',
      minimumStage: 9,
      partsTr: <String>[
        'Uyarıyı zamanında almasına rağmen,',
        'operatör',
        'eski ayarı değiştirmediği için',
        'sistem aynı hatayı',
        'yeniden verdi.',
      ],
      partsEn: <String>[
        'Despite receiving the warning in time,',
        'the operator',
        'left the old setting unchanged,',
        'so the system',
        'produced the same error again.',
      ],
      contextTr: 'Göz ardı edilen uyarının doğurduğu sonuç.',
      contextEn: 'The consequence of ignoring a warning.',
      clueTr: '“-mesine rağmen” karşıtlık, “için” sebep, “yeniden” tekrarı gösterir.',
      clueEn: 'Track contrast, cause and the repeated outcome in that order.',
      noteTr: 'Üç bağlayıcı ipucu cümlenin mantık zincirini belirler.',
      noteEn: 'Three linking cues establish the sentence’s reasoning chain.',
    ),
    SentenceCard(
      id: 'source_dispute',
      minimumStage: 10,
      partsTr: <String>[
        'İki kaynak aynı tarihte uzlaşmayınca,',
        'editör',
        'ilk yayımlanan kaydı esas aldı,',
        'belirsizliği metinde açıkça belirtti',
        've ikinci doğrulamayı bekledi.',
      ],
      partsEn: <String>[
        'When the two sources disagreed on the date,',
        'the editor',
        'used the earliest published record,',
        'stated the uncertainty clearly',
        'and waited for a second verification.',
      ],
      contextTr: 'Çelişen kaynaklarda editoryal karar ve şeffaflık.',
      contextEn: 'Editorial judgment and transparency when sources conflict.',
      clueTr:
          'Anlaşmazlık önce; karar, belirsizlik beyanı ve bekleme sonra gelir.',
      clueEn: 'The conflict precedes a decision, disclosure and follow-up.',
      noteTr: 'Noktalı virgül gerekmez; aynı özneye bağlı eylemler virgülle dizilir.',
      noteEn: 'The coordinated actions keep the same subject and remain comma-separated.',
    ),
    SentenceCard(
      id: 'while_reviewing',
      minimumStage: 10,
      partsTr: <String>[
        'Sonuçları yeniden üretmeye çalışırken,',
        'araştırma ekibi',
        'ham verideki eksik ölçümleri fark etti,',
        'analizi durdurdu',
        've kayıtları tamamlamadan hüküm vermedi.',
      ],
      partsEn: <String>[
        'While trying to reproduce the results,',
        'the research team',
        'noticed missing measurements in the raw data,',
        'paused the analysis',
        'and withheld judgment until the records were complete.',
      ],
      contextTr: 'Tekrarlanabilirlik için veriyi yeniden inceleyen bir ekip.',
      contextEn: 'A team rechecking data for reproducibility.',
      clueTr: '“-ken” sürmekte olan süreci; “ve” son eylemi zincire bağlar.',
      clueEn: '“While” sets the ongoing process; “and” links the final action.',
      noteTr: 'Ana eylemler, başlangıçtaki süreç bölümüne bağlanır.',
      noteEn: 'The main actions are anchored to the opening ongoing process.',
    ),
    SentenceCard(
      id: 'reviewed_contract',
      minimumStage: 10,
      partsTr: <String>[
        'Sözleşmeyi imzalamadan önce',
        'her iki taraf da',
        'sorumluluk maddelerini dikkatle inceledi,',
        'anlaşılmayan noktaları sordu',
        've değişiklikleri yazılı olarak onayladı.',
      ],
      partsEn: <String>[
        'Before signing the agreement,',
        'both parties',
        'carefully reviewed the responsibility clauses,',
        'asked about unclear points',
        'and approved the changes in writing.',
      ],
      contextTr: 'İmza öncesinde izlenen dikkatli anlaşma süreci.',
      contextEn: 'A careful agreement process before signing.',
      clueTr: 'İmza öncesi koşulu başta; üç ortak eylemi aynı özne yapar.',
      clueEn:
          'The pre-signing clause leads; one subject performs three actions.',
      noteTr: '“Her iki taraf da” çoğul özne, eylem zincirini yönetir.',
      noteEn: '“Both parties” is the shared subject of the action sequence.',
    ),
    SentenceCard(
      id: 'because_rehearsal',
      minimumStage: 10,
      partsTr: <String>[
        'Provalar sürekli ertelendiği için,',
        'yönetmen',
        'sahne sırasını sadeleştirdi,',
        'ek çalışmaları yeniden dağıttı',
        've açılış tarihini değiştirmeden önce ekiple görüştü.',
      ],
      partsEn: <String>[
        'Because rehearsals kept being postponed,',
        'the director',
        'simplified the stage order,',
        'redistributed extra sessions,',
        'and spoke with the team before changing the opening date.',
      ],
      contextTr: 'Gecikmeler karşısında değişiklikleri ölçülü yöneten ekip.',
      contextEn: 'A team managing changes carefully after repeated delays.',
      clueTr: 'Sebep başta, çözüm adımları sırayla; tarih değişikliği en son.',
      clueEn: 'The cause leads; responses follow, with the date decision last.',
      noteTr: 'Virgüller eş görevli eylemleri ayırır; son bağlaç “ve”dir.',
      noteEn: 'Commas separate coordinated actions; “and” marks the last.',
    ),
    SentenceCard(
      id: 'although_experiment',
      minimumStage: 10,
      partsTr: <String>[
        'İlk deney umut verici görünse de,',
        'ekip',
        'tek bir ölçüme dayanarak sonuç açıklamadı,',
        'daha geniş bir örneklem topladı',
        've bulguları bağımsız olarak denetletti.',
      ],
      partsEn: <String>[
        'Although the first experiment looked promising,',
        'the team',
        'did not announce a conclusion from one measurement,',
        'collected a broader sample',
        'and had the findings independently checked.',
      ],
      contextTr: 'Tek bulgudan genelleme yapmayan bilimsel tutum.',
      contextEn: 'Scientific caution against generalizing from one finding.',
      clueTr:
          'Karşıtlık başta; olumsuz yüklemi ve iki doğrulama eylemini koru.',
      clueEn:
          'Keep the contrast, the negated predicate and two checks in order.',
      noteTr: '“Se de” karşıt beklenti oluşturur; olumsuzluk ana yargıdadır.',
      noteEn:
          '“Although” sets a contrast; the main clause carries the negation.',
    ),
  ];

  static const List<int> _topTierByLevel = <int>[
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

  final int stage;
  final List<SentenceBoardCard> cards;
  final bool isPractice;
  final int round;

  String get boardSignature {
    final List<String> ids =
        cards.map((SentenceBoardCard item) => item.sentence.id).toList()
          ..sort();
    return ids.join('|');
  }

  static SentenceBuilderScenario forCampaignLevel(int level) {
    if (level < 1 || level > campaignLevels) {
      throw RangeError.range(level, 1, campaignLevels, 'level');
    }
    return _build(
      indices: _campaign[level - 1],
      stage: level,
      round: level,
      isPractice: false,
    );
  }

  static SentenceBuilderScenario forPracticeRound(int round) {
    if (round < 1 || round > uniquePracticeRounds) {
      throw RangeError.range(round, 1, uniquePracticeRounds, 'round');
    }
    return _build(
      indices: _practice[round - 1],
      stage: ((round - 1) % campaignLevels) + 1,
      round: round,
      isPractice: true,
    );
  }

  static SentenceBuilderScenario _build({
    required List<int> indices,
    required int stage,
    required int round,
    required bool isPractice,
  }) {
    final List<SentenceBoardCard> cards = <SentenceBoardCard>[];
    for (final int index in indices) {
      final SentenceCard sentence = _bank[index];
      final String mode = isPractice ? 'practice' : 'campaign';
      final List<String> scrambledTr = List<String>.from(sentence.partsTr)
        ..shuffle(
          ContentSeed.randomFor(
            gameId: 'sentence_builder:$mode:${sentence.id}:tr',
            level: round,
          ),
        );
      final List<String> scrambledEn = List<String>.from(sentence.partsEn)
        ..shuffle(
          ContentSeed.randomFor(
            gameId: 'sentence_builder:$mode:${sentence.id}:en',
            level: round,
          ),
        );
      cards.add(
        SentenceBoardCard(
          sentence: sentence,
          scrambledTr: List<String>.unmodifiable(scrambledTr),
          scrambledEn: List<String>.unmodifiable(scrambledEn),
        ),
      );
    }
    return SentenceBuilderScenario(
      stage: stage,
      cards: List<SentenceBoardCard>.unmodifiable(cards),
      isPractice: isPractice,
      round: round,
    );
  }

  static List<List<int>> _makeCampaign() {
    final List<List<int>> boards = <List<int>>[];
    final Set<String> used = <String>{};
    for (int level = 1; level <= campaignLevels; level++) {
      final int tier = _topTierByLevel[level - 1];
      final int requiredTier = level <= 3
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
      final List<List<int>> candidates =
          _combinations(List<int>.generate(_bank.length, (int index) => index))
              .where((List<int> board) {
                return board.every(
                      (int index) => _bank[index].minimumStage <= tier,
                    ) &&
                    board
                            .where(
                              (int index) => _bank[index].minimumStage == tier,
                            )
                            .length >=
                        requiredTier;
              })
              .toList(growable: false);
      if (candidates.isEmpty) {
        throw StateError('No sentence-builder board for level $level.');
      }
      final math.Random random = ContentSeed.randomFor(
        gameId: 'sentence_builder:campaign',
        level: level,
      );
      final int start = random.nextInt(candidates.length);
      List<int>? selected;
      for (int offset = 0; offset < candidates.length; offset++) {
        final List<int> candidate =
            candidates[(start + offset) % candidates.length];
        if (used.add(_signature(candidate))) {
          selected = candidate;
          break;
        }
      }
      if (selected == null) {
        throw StateError('Sentence-builder board repeated at $level.');
      }
      boards.add(List<int>.unmodifiable(selected));
    }
    return List<List<int>>.unmodifiable(boards);
  }

  static List<List<int>> _makePractice() {
    final Set<String> campaignSignatures = _campaign.map(_signature).toSet();
    final List<List<int>> candidates =
        _combinations(List<int>.generate(_bank.length, (int index) => index))
            .where((List<int> board) {
              return !campaignSignatures.contains(_signature(board));
            })
            .toList(growable: true);
    candidates.shuffle(
      ContentSeed.randomFor(
        gameId: 'sentence_builder:practice-order',
        level: 1,
      ),
    );
    return List<List<int>>.unmodifiable(candidates.take(uniquePracticeRounds));
  }

  static List<List<int>> _combinations(List<int> source) {
    final List<List<int>> combinations = <List<int>>[];
    for (int a = 0; a < source.length - 3; a++) {
      for (int b = a + 1; b < source.length - 2; b++) {
        for (int c = b + 1; c < source.length - 1; c++) {
          for (int d = c + 1; d < source.length; d++) {
            combinations.add(<int>[source[a], source[b], source[c], source[d]]);
          }
        }
      }
    }
    return combinations;
  }

  static String _signature(List<int> indices) =>
      (indices.map((int index) => _bank[index].id).toList()..sort()).join('|');

  static final List<List<int>> _campaign = _makeCampaign();
  static final List<List<int>> _practice = _makePractice();
}
